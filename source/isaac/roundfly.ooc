
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
    explosion]

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

    mover: Mover

    type: RoundFlyType

    fireSpeed := 280.0

    init: func (.level, .pos, =type) {
        super(level, pos)

        life = 8.0

        sprite = GlSprite new(getSpritePath())
        sprite scale set!(scale, scale)

        factor := 0.2
        shadow = Shadow new(level, sprite width * scale * factor)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
        mover = Mover new(level, body, 70.0)
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
        mover update(pos)

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 8 + z)
        pos set!(body getPos())
        shadow setPos(pos sub(0.0, 3.0))

        super()
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

    updateTarget: func {
        // don't track hero, we're just moving around
        mover setTarget(Target choose(pos, level, radius, false))
        resetSpeedAndCount()
    }
    
    resetSpeedAndCount: func {
        mover speed = Random randInt(80, 90) as Float
    }

    initPhysx: func {
        (width, height) := (30, 30)
        mass := 20.0
        moment := cpMomentForBox(mass, width, height)

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes ENEMY)
        // FIXME: that's not proper, dude.
        shape setSensor(true)
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

