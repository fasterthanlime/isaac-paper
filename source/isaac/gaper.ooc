

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
import structs/[ArrayList, List, HashMap]

// our stuff
import isaac/[level, shadow, enemy, hero, utils, paths, pathfinding,
    explosion, tear]

GaperType: enum {
    GAPER
    FROWNING
    GUSHER
    PACER
    GURGLE 
}

/**
 * Awrrrgllll
 */
Gaper: class extends Mob {

    type: GaperType

    rotateConstraint: CpConstraint

    shadow: Shadow
    shadowFactor := 0.4
    shadowYOffset := 13

    scale := 0.8

    init: func (=level, =pos, =type) {
        super(level, pos)

        shadow = Shadow new(level, 40)

        sprite = GlSprite new("assets/png/%s.png" format(getSpriteName()))
        sprite scale set!(scale, scale)
        level charGroup add(sprite)

        initPhysx()
    }

    getSpriteName: func -> String {
        match type {
            case GaperType FROWNING =>
                "frowning-gaper"
            case GaperType GUSHER =>
                "gusher"
            case GaperType PACER =>
                "pacer"
            case => // fallback
                "gaper"
        }
    }

    update: func -> Bool {
        bodyPos := body getPos()
        pos set!(bodyPos)
        sprite pos set!(pos)
        shadow setPos(pos sub(0, shadowYOffset))

        //behavior update()

        super()
    }

    destroy: func {
        shadow destroy()

        level space removeShape(shape)
        shape free()

        level space removeConstraint(rotateConstraint)
        rotateConstraint free()

        level space removeBody(body)
        body free()

        level charGroup remove(sprite)
    }

    initPhysx: func {
        (width, height) := (35, 35)
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

}

