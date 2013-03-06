

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
import isaac/[level, parabola, shadow, enemy, hero, utils]

/*
 * Bzzzzzz
 */
Fly: class extends Mob {

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    moveCount := 0
    moveCountMax := 30

    radius := 180.0
    speedyRadius := 120.0

    scale := 0.8

    shadow: Shadow

    mover: Mover

    parabola: Parabola

    init: func (.level, .pos) {
        super(level, pos)

        life = 8.0

        sprite = GlSprite new("assets/png/fly.png")
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale * 0.5)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
        mover = Mover new(body, 70.0)
    }

    update: func -> Bool {
        if (moveCount > 0) {
            moveCount -= 1
        } else {
            updateTarget()
        }
        mover update(pos)

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 8 + z)
        pos set!(body getPos())
        shadow setPos(pos)

        super()
    }

    updateTarget: func {
        mover setTarget(Target choose(pos, level, radius))
        dist := level hero pos dist(pos)
        if (dist < speedyRadius) {
            mover speed = Random randInt(100, 120) as Float
            moveCount = 20
        } else {
            mover speed = Random randInt(80, 90) as Float
            moveCount = moveCountMax + Random randInt(-10, 40)
        }
    }

    initPhysx: func {
        (width, height) := (10, 10)
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
        shape setSensor(true)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
    }

    destroy: func {
        shadow destroy()
        level space removeShape(shape)
        level space removeBody(body)
        level charGroup remove(sprite)
    }

}

