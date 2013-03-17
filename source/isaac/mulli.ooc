

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
    explosion]

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
        mover = Mover new(level, body, 180.0)
        mover alpha = 0.9
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

    onDeath: func {
        match type {
            case MulliType MULLIBOOM =>
                level add(Explosion new(level, pos))
        }
    }

    touchHero: func (hero: Hero) -> Bool {
        match type {
            case MulliType MULLIBOOM =>
                life = 0.0
                // return so we don't hurt him yet for half a heart..
                // we'll let the explosion hurt him for a full heart.
                // MWUHAHAHA
                return true
        }

        super(hero)
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
            a := level snappedPos(pos)
            b := level snappedPos(level hero pos)
            finder := PathFinder new(level, a, b)

            // remove first component in path, it's a snapped version of ourselves
            finder path removeAt(0)
            
            if (finder path) {
                mover setCellPath(finder path)
                moveCount = 60
            } else {
                moveCount = 30
            }
        }
    }

    initPhysx: func {
        (width, height) := (30, 30)
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


