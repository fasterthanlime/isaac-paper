
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
import isaac/[level, shadow, enemy, hero, utils, paths, boss]

DukeOfFlies: class extends Boss {

    init: func (.level, .pos) {
        super(level, pos)

        part := DukePart new(level, pos)
        level add(part)
        parts add(part)
    }

}

DukePart: class extends Mob {

    rotateConstraint: CpConstraint
    scale := 0.8

    shadow: Shadow
    shadowFactor := 0.7
    shadowYOffset := 50

    mover: Mover

    moveCount := 60
    moveCountMax := 80

    init: func (.level, .pos) {
        super(level, pos)

        life = 120.0

        sprite = GlSprite new(getSpritePath())
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale * shadowFactor)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
        mover = Mover new(level, body, 140.0)
        mover alpha = 0.8
    }

    getSpritePath: func -> String {
        "assets/png/duke-of-flies-frame1.png"
    }

    update: func -> Bool {
        if (moveCount > 0) {
            moveCount -= 1
        } else {
            updateTarget()
        }
        mover update(pos)

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 4 + z)
        pos set!(body getPos())
        shadow setPos(pos sub(0, shadowYOffset))

        super()
    }

    updateTarget: func {
        // blah for now
        mover setTarget(level hero pos)
        moveCount = 5
    }

    initPhysx: func {
        (width, height) := (100, 100)
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
