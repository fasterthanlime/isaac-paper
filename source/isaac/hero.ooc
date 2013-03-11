

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

// our stuff
import isaac/[game, level, tear, shadow, bomb, collectible]

/*
 * Dat Isaac...
 */
Hero: class extends Entity {

    logger := static Log getLogger(This name)

    sprite: GlSprite

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    shootCount := 0

    shadow: Shadow

    webCount := 0

    invicibilityCount := 0
    invicibilityCountMax := 40

    stats: HeroStats

    init: func (.level, .pos, =stats) {
        super(level, pos)

        sprite = GlSprite new("assets/png/isaac-down.png")
        scale := 0.8
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale)

        level charGroup add(sprite)

        sprite pos set!(pos)

        initPhysx()
    }

    setOpacity: func (opacity: Float) {
        sprite opacity = opacity
        shadow sprite opacity = opacity
    }

    update: func -> Bool {
        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 20)
        pos set!(body getPos())
        shadow setPos(pos)

        setOpacity(1.0)
        if (invicibilityCount > 0) {
            invicibilityCount -= 1
            val := invicibilityCount / 8
            if (val % 2 == 0) {
                setOpacity(0.0)
            }
        }

        if (shootCount > 0) {
            shootCount -= 1
        }

        true
    }

    setPos: func (.pos) {
        this pos set!(pos)
        body setPos(cpv(pos))
    }

    initPhysx: func {
        (width, height) := (40, 40)
        mass := 10.0
        moment := cpMomentForBox(mass, width, height)

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes HERO)
        level space addShape(shape)
    }

    destroy: func {
        shadow destroy()
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
    }

    move: func (dir: Vec2) {
        vel := dir mul(getSpeed())
        currVel := vec2(body getVel())
        currVel interpolate!(vel, 0.95)
        body setVel(cpv(currVel))
    }

    getSpeed: func -> Float {
        if (webCount > 0 && !flying?()) {
            stats speed * 0.5
        } else {
            stats speed
        }
    }

    flying?: func -> Bool {
        // TODO: fly!
        false
    }

    shoot: func (dir: Direction) {
        if (shootCount > 0) {
            return
        }
        bodyVel := body getVel()

        skew := 0.3

        shootCount = stats shootRateInv
        vel := match (dir) {
            case Direction RIGHT =>
                vec2( 1, bodyVel y > 20 ? skew : (bodyVel y < -20 ? -skew : 0))
            case Direction LEFT  =>
                vec2(-1, bodyVel y > 20 ? skew : (bodyVel y < -20 ? -skew : 0))
            case Direction DOWN  =>
                vec2(bodyVel x > 20 ? skew : (bodyVel x < -20 ? -skew : 0),-1)
            case Direction UP    =>
                vec2(bodyVel x > 20 ? skew : (bodyVel x < -20 ? -skew : 0), 1)
        }
        vel = vel normalized() mul(stats shotSpeed)

        tear := Tear new(level, pos add(0, 10), vel, TearType HERO, stats damage)
        level add(tear)
    }

    /*
     * Harm the hero. Damage is counted in half-hearts
     */
    harmHero: func (damage: Int) {
        if (invicibilityCount > 0) {
            return // invincible, biatch!
        }
        invicibilityCount = invicibilityCountMax

        // ouch
        stats takeDamage(damage)
    }

    bombHarm: func (bomb: Bomb) {
        harmHero(2)
    }

}

HeroStats: class {

    speed := 200.0

    shotSpeed := 400.0

    //shootRate := 2
    shootRate := 6 // testing

    shootRateInv: Int { get { 60 / shootRate } }

    damage := 4.0

    containers := 3

    redLife := 6
    spiritLife := 0
    eternalLife := 0

    healthChanged := true

    coinCount := 0
    bombCount := 1
    keyCount := 0

    game: Game

    init: func (=game) {
    }

    totalHealth: func -> Int {
        redLife + spiritLife + eternalLife
    }

    hasWafer?: func -> Bool {
        // TODO: implement, duh
        false
    }

    // actions
    pickupCoin: func (coin: CollectibleCoin) {
        // TODO: lotsa modifiers (e.g. most of the trinkets)
        coinCount += coin worth
    }

    pickupKey: func (key: CollectibleKey) {
        keyCount += 1
    }

    pickupBomb: func (bomb: CollectibleBomb) {
        bombCount += bomb worth
    }

    pickupHealth: func (heart: CollectibleHeart) -> Bool {
        value := heart value toInt()

        match (heart type) {
            case HeartType RED =>
                if (redLife == containers * 2) {
                    return false // all good, mate
                }

                redLife += value
                if (redLife > containers * 2) {
                    // you can't have more red life than containers
                    redLife = containers * 2
                }
            case HeartType SPIRIT =>
                // TODO: two spirit hearts = one new container
                spiritLife += value
            case HeartType ETERNAL =>
                eternalLife += value
        }

        healthChanged = true
        true
    }

    takeDamage: func (damage: Int) {
        if (game hardFloor?()) {
            // takes a full heart of damage
            damage = 2
        }

        if (hasWafer?()) {
            // the wafer is an awesome item
            damage = 1
        }

        // spirit hearts go first

        if (spiritLife > 0) {
            if (spiritLife < damage) {
                damage -= spiritLife
                spiritLife = 0
                healthChanged = true
            } else {
                spiritLife -= damage
                damage = 0
                healthChanged = true
            }
        }

        if (damage == 0) { return }

        // then eternal, if any

        if (eternalLife > 0) {
            eternalLife = 0
            healthChanged = true
            damage -= 1
        }

        if (damage == 0) { return }

        // then red life, finally

        redLife -= damage
        healthChanged = true
    }

}

