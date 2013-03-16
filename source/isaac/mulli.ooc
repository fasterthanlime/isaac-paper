

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
import isaac/[level, shadow, enemy, hero, utils, paths]

MulliType: enum {
    MULLIGAN
    MULLIGOON
    MULLIBOOM
    HIVE
}

/*
 * Mulligans, mulligoons, mullibooms, and hives
 */
Mulli: class extends Mob {

    rotateConstraint: CpConstraint

    moveCount := 60
    moveCountMax := 80
    radius := 180

    scale := 0.8

    shadow: Shadow
    shadowFactor := 0.7
    shadowYOffset := 8

    mover: Mover

    parabola: Parabola

    type: MulliType

    init: func (.level, .pos, =type) {
        super(level, pos)

        life = 14.0

        sprite = GlSprite new(getSpritePath())
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale * shadowFactor)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
        mover = Mover new(body, 140.0)
        mover alpha = 0.8
    }

    getSpritePath: func -> String {
        match type {
            case MulliType MULLIGAN =>
                "assets/png/mulligan.png"
            case MulliType MULLIGOON =>
                "assets/png/mulligoon.png"
            case MulliType MULLIBOOM =>
                "assets/png/mulliboom.png"
            case MulliType HIVE =>
                "assets/png/hive.png"
            case =>
                raise("Invalid mulli type: %d" format(type))
                ""
        }
    }

    update: func -> Bool {
        if (parabola) {
            // handle height
            z = parabola eval(moveCountMax - moveCount)
            if (parabola done?()) {
                z = parabola bottom
                parabola = null
                shape setSensor(true)
            }
        }

        if (moveCount > 0) {
            moveCount -= 1
        } else {
            updateTarget()
        }
        if (!parabola) {
            mover update(pos)
        }

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 4 + z)
        pos set!(body getPos())
        shadow setPos(pos sub(0, shadowYOffset))

        super()
    }

    updateTarget: func {
        if (type == MulliType MULLIBOOM) {
            mover setTarget(level hero pos)
            moveCount = 5
        }
    }

    initPhysx: func {
        (width, height) := (40, 40)
        mass := 15.0
        moment := cpMomentForBox(mass, width, height)

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes ENEMY)
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

}


