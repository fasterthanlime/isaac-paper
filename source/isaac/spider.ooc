

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
 * Spidery... yum
 */
Spider: class extends Mob {

    speed := 280.0

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    moveCount := 80
    moveCountMax := 80
    radius := 180

    damage := 4.0
    scale := 0.8
    target: Vec2
    moving := false

    shadow: Shadow

    init: func (.level, .pos) {
        super(level, pos)

        // boldly going nowhere
        target = vec2(pos)

        life = 5.0

        sprite = GlSprite new("assets/png/spider.png")
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale * 0.5)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
    }

    update: func -> Bool {
        if (moveCount > 0) {
            moveCount -= 1
        } else {
            move()
        }

        dist := pos dist(target)
        if (moving && moveCount > 50 && dist > 20.0) {
            body setVel(cpv(target sub(pos) normalized() mul(speed)))
        } else {
            moving = false
            // friction
            friction := 0.8
            vel := body getVel()
            vel x *= friction
            vel y *= friction
            body setVel(vel)
        }

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 4 + z)
        pos set!(body getPos())
        shadow setPos(pos)

        super()
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

    move: func {
        target = Target choose(pos, level, radius)
        moving = true
        moveCount = moveCountMax + Random randInt(-10, 40)
    }

}

