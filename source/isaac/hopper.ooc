

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
import isaac/[level]

/*
 * JUMP JUMP JUMP JUMP JUMP - Jump around!
 */
Hopper: class extends Entity {

    sprite: GlSprite

    pos: Vec2
    speed := 200.0

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    jumpCount := 0
    radius := 200

    damage := 4.0

    init: func (.level, .pos) {
        super(level)

        sprite = GlSprite new("assets/png/hopper.png")
        scale := 0.8
        sprite scale set!(scale, scale)

        level charGroup add(sprite)

        this pos = vec2(pos)
        sprite pos set!(pos)

        initPhysx()
    }

    update: func -> Bool {
        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 12)

        pos set!(body getPos())

        if (jumpCount > 0) {
            jumpCount -= 1
        } else {
            jump()
        }

        true
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
        shape setCollisionType(CollisionTypes ENEMY)
        level space addShape(shape)
    }

    destroy: func {
        level space removeShape(shape)
        level space removeBody(body)
        level charGroup remove(sprite)
    }

    move: func (dir: Vec2) {
        vel := dir mul(speed)
        body setVel(cpv(vel))
    }

    jump: func {
        angle := Random randInt(1, 360) as Float
        target := pos add(Vec2 fromAngle(angle toRadians()) mul(radius))
        target = target clamp(level paddedBottomLeft, level paddedTopRight)
        "target = %s" printfln(target _)
        body setPos(cpv(target))

        jumpCount = 200
    }

}

