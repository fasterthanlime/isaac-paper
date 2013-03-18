
// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

// sdk stuff
import math, math/Random

// our stuff
import isaac/[game, level, paths, shadow, enemy, hero, utils, tear,
    explosion, walls]

RoundFlyType: enum {
    BOOM
    RED
}

/**
 * You see me flyin', you hatin.
 */
RoundFly: class extends Mob {

    rotateConstraint: CpConstraint

    radius := 350.0
    speedyRadius := 180.0

    scale := 0.8

    shadow: Shadow

    type: RoundFlyType

    fireSpeed := 280.0

    speed := 120.0

    dir: Vec2
    baseColor: Color

    init: func (.level, .pos, =type) {
        super(level, pos)

        life = 20.0

        sprite = GlSprite new(getSpritePath())
        sprite scale set!(scale, scale)
        baseColor = match type {
            case RoundFlyType RED =>
                Color new(255, 140, 140)
            case =>
                Color white()
        }

        factor := 0.2
        shadow = Shadow new(level, sprite width * scale * factor)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()

        dir = vec2(oneOrMinusOne(), oneOrMinusOne()) 
    }

    hitBack: func (tear: Tear) {
        // we bounce naturally
    }

    oneOrMinusOne: func -> Int {
        Random randInt(0, 1) * 2 - 1
    }

    getSpritePath: func -> String {
        match type {
            case RoundFlyType BOOM =>
                "assets/png/boom-fly.png"
            case =>
                "assets/png/red-boom-fly.png"
        }
    }

    onDeath: func {
        match type {
            case RoundFlyType BOOM =>
                // explode
                level add(Explosion new(level, pos))
            case RoundFlyType RED =>
                // spawn tears in 6 directions
                angle := (Random randInt(0, 360) as Float) toRadians()
                for (i in 0..6) {
                    spawnTear(pos, Vec2 fromAngle(angle as Float)) 
                    angle += (PI * 0.33)
                }
        }
    }

    update: func -> Bool {
        bodyVel := vec2(body getVel())
        angle := bodyVel angle() toDegrees()

        match {
            case angle > 0.0 && angle < 90.0 =>
                dir set!(1, 1)
            case angle > 90.0 && angle < 180.0 =>
                dir set!(-1, 1)
            case angle > 180.0 && angle < 270.0 =>
                dir set!(-1, -1)
            case angle =>
                dir set!(1, -1)
        }

        idealVel := dir mul(speed)
        alpha := 0.85
        bodyVel interpolate!(idealVel, 1 - alpha)
        body setVel(cpv(bodyVel))

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 8 + z)
        pos set!(body getPos())
        shadow setPos(pos sub(0.0, 3.0))

        retVal := super()
        if (!redish) {
            sprite color set!(baseColor)
        }
        retVal
    }

    grounded?: func -> Bool {
        // kinda..
        true
    }

    spawnTear: func (pos, dir: Vec2) {
        vel := dir mul(fireSpeed)
        tear := Tear new(level, pos, vel, TearType ENEMY, 1)
        level add(tear)
    }

    initPhysx: func {
        radius := 20.0
        mass := 20.0
        moment := cpMomentForCircle(mass, 0, radius, cpv(radius, radius))

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpCircleShape new(body, radius, cpv(0, 0))
        shape setUserData(this)
        shape setCollisionType(CollisionTypes ENEMY)
        shape setElasticity(0.7)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        super()
    }

    destroy: func {
        shadow destroy()
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
    }

}

