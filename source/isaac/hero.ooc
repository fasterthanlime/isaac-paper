

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
import isaac/[level, tear, shadow]

/*
 * Dat Isaac...
 */
Hero: class extends Entity {

    sprite: GlSprite

    speed := 200.0

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    shotSpeed := 400.0

    shootCount := 0

    shootRate := 1
    shootRateInv: Int { get { shootRate * 30 } }

    damage := 4.0

    shadow: Shadow

    webCount := 0

    init: func (.level, .pos) {
        super(level, pos)

        sprite = GlSprite new("assets/png/isaac-down.png")
        scale := 0.8
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale)

        level charGroup add(sprite)

        sprite pos set!(pos)

        initPhysx()
    }

    update: func -> Bool {
        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 20)
        pos set!(body getPos())
        shadow setPos(pos)

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
        level space removeBody(body)
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
            speed * 0.5
        } else {
            speed
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

        shootCount = shootRateInv
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
        vel = vel normalized() mul(shotSpeed)

        tear := Tear new(level, pos add(0, 10), vel, TearType HERO, damage)
        level add(tear)
    }

}

