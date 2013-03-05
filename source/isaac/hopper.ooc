

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
import isaac/[level, parabola, shadow]

/*
 * JUMP JUMP JUMP JUMP JUMP - Jump around!
 */
Hopper: class extends Entity {

    sprite: GlSprite

    pos: Vec2
    z := 0.0

    speed := 230.0

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    jumpCount := 0
    jumpCountMax := 100
    radius := 250

    damage := 4.0

    parabola := Parabola new(1, 1)

    shadow: Shadow

    init: func (.level, .pos) {
        super(level)

        sprite = GlSprite new("assets/png/hopper.png")
        scale := 0.8
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale)

        level charGroup add(sprite)

        this pos = vec2(pos)
        sprite pos set!(pos)

        initPhysx()
    }

    update: func -> Bool {
        // handle height
        z = parabola eval(jumpCountMax - jumpCount)
        if (jumpCount > 0) {
            jumpCount -= 1
        } else {
            jump()
        }

        // friction
        if (z < level groundLevel) {
            friction := 0.95
            vel := body getVel()
            vel x *= friction
            vel y *= friction
            body setVel(vel)
        }

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 12 + z)
        pos set!(body getPos())
        shadow setPos(pos)

        true
    }

    initPhysx: func {
        (width, height) := (20, 20)
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
        diff, target: Vec2
        good := false
        count := 8

        while (!good && count > 0) {
            x := Random randInt(-100, 100) as Float / 100.0
            y := Random randInt(-100, 100) as Float / 100.0
            diff = vec2(x, y) normalized()
            target = pos add(diff mul(radius))
            good = target inside?(level paddedBottomLeft, level paddedTopRight)
            count -= 1
        }
        target = target clamp(level paddedBottomLeft, level paddedTopRight)
        //"target = %s, diff = %s" printfln(target _, target sub(pos) normalized() _)

        body setVel(cpv(target sub(pos) normalized() mul(speed)))

        parabola = Parabola new(90, jumpCountMax * 0.5)
        jumpCount = jumpCountMax
    }

}

