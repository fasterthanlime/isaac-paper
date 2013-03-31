

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math, anim]

use gnaar
import gnaar/[utils, deck]

// our stuff
import isaac/[game, level, tear, shadow, bomb, collectible, options,
    explosion, walls]

/*
 * Dat Isaac...
 */
Hero: class extends Entity {

    logger := static Log getLogger(This name)

    group: GlGroup
    bodyDelta := 1
    bodyDeck: Deck
    spriteYOffset := 10

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    shootCount := 0

    shadow: Shadow
    shadowFactor := 0.8
    shadowYOffset := 8

    webCount := 0

    invicibilityCount := 0
    invicibilityCountMax := 40

    hitBackCount := 0
    hitBackCountMax := 3

    stats: HeroStats

    door: Door
    doorCount := 0
    doorCountThreshold := 10

    init: func (.level, .pos, =stats) {
        super(level, pos)

        shadow = Shadow new(level, 30)

        group = GlGroup new()
        group scale set!(0.3, 0.3)
        level charGroup add(group)

        bodyDeck = Deck new("assets/decks/body.yml")
        group add(bodyDeck group)
        bodyDeck play("walk-side")

        initPhysx()
    }

    setOpacity: func (opacity: Float) {
        // TODO: opacity/color
        //group opacity = opacity
        shadow setOpacity(opacity)
    }

    update: func -> Bool {
        if (hitBackCount > 0) {
            hitBackCount -= 1
        }

        bodyPos := body getPos()
        pos set!(bodyPos)
        shadow setPos(pos x, pos y - shadowYOffset)
        group pos set!(bodyPos x, bodyPos y + spriteYOffset)

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

        bodyVel := vec2(body getVel())
        threshold := 10.0
        if (bodyVel norm() > threshold) {
            bodyDeck update()
        } else {
            bodyDeck group current rewind()
        }

        true
    }

    setPos: func (.pos) {
        this pos set!(pos)
        body setPos(cpv(pos))
        group pos set!(pos x, pos y + spriteYOffset)
        shadow setPos(pos x, pos y - shadowYOffset)
    }

    initPhysx: func {
        radius := 20.0
        mass := 10.0
        moment := cpMomentForCircle(mass, 0, radius, cpv(radius, radius))

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpCircleShape new(body, radius, cpv(0, 0))
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

        level charGroup remove(bodyDeck group)
    }

    move: func (dir: Vec2) {
        if (hitBackCount > 0) {
            return // can't move yet!
        }

        vel := dir mul(getSpeed())
        currVel := vec2(body getVel())
        currVel interpolate!(vel, 1 - 0.8)
        body setVel(cpv(currVel))

        epsilon := 0.1
        if (dir x > epsilon) {
            bodyDeck group scale x = 1.0
            bodyDeck play("walk-side")
            bodyDelta = 1
        } else if (dir x < -epsilon) {
            bodyDeck group scale x = -1.0
            bodyDeck play("walk-side")
            bodyDelta = 1
        } else if (dir y > epsilon) {
            bodyDeck group scale x = 1.0
            bodyDeck play("walk-front")
            bodyDelta = 1
        } else {
            bodyDeck play("walk-front")
            bodyDeck group scale x = 1.0
            bodyDelta = -1
        }

        if (door) {
            if (door dir along?(dir)) {
                // pressing against a door
                doorCount += 1
            }
        }
    }

    getSpeed: func -> Float {
        result := stats actualSpeed

        if (webCount > 0 && !flying?()) {
            result *= 0.5
        }

        result
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

        tear := Tear new(level, pos add(0, 10), vel, TearType HERO, stats actualDamage, stats actualShootRange)
        level add(tear)
    }

    /*
     * Harm the hero. Damage is counted in half-hearts
     */
    harmHero: func (damage: Int) -> Bool {
        if (invicibilityCount > 0) {
            return false // invincible, biatch!
        }
        invicibilityCount = invicibilityCountMax

        // ouch
        level game playRandomSound("hero-hurt", 3)
        stats takeDamage(damage)
        true
    }

    bombHarm: func (explosion: Explosion) {
        harmHero(2)
    }

    hitBack: func (hitPos: Vec2) {
        hitBackCount = hitBackCountMax
        dir := pos sub(hitPos) normalized()
        hitbackSpeed := 150
        vel := dir mul(hitbackSpeed)
        body setVel(cpv(vel))
    }

}

HeroStats: class {

    speed := 2
    actualSpeed : Float { get { 150.0 * speed } }

    shotSpeed := 350.0

    shootRange := 2
    actualShootRange: Int { get { shootRange * 110.0 } }

    shootRate := 2
    shootRateInv: Int { get { 50 / shootRate } }

    damage := 2
    actualDamage: Int { get { damage * 2 } }

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
        if (game options testLevel) {
            bombCount = 99
            keyCount = 99
            coinCount = 99
        }
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

        if (coinCount > 99) {
            coinCount = 99
        }
    }

    pickupKey: func (key: CollectibleKey) {
        keyCount += 1

        if (keyCount > 99) {
            keyCount = 99
        }
    }

    pickupBomb: func (bomb: CollectibleBomb) {
        bombCount += bomb worth

        if (bombCount > 99) {
            bombCount = 99
        }
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
                eternalLife += 1
                handleEternalLife()
        }

        healthChanged = true
        true
    }

    useKey: func {
        // shall we check for < 0 ? Or trust the rest of the code?
        keyCount -= 1
    }

    takeDamage: func (damage: Int) {
        if (game floor hard?()) {
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

    onFloorEnd: func {
        if (eternalLife > 0) {
            eternalLife += 1
            handleEternalLife()
        }
    }

    handleEternalLife: func {
        if (eternalLife >= 2) {
            containers += 1
            eternalLife = 0
            redLife += 2
            healthChanged = true
        }
    }

}

