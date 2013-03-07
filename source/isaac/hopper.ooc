

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
 * JUMP JUMP JUMP JUMP JUMP - Jump around!
 */
Hopper: class extends Mob {

    speed := 230.0

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    jumpCount := 60
    jumpCountMax := 100
    jumpHeight := 90.0
    radius := 250

    damage := 4.0
    scale := 0.8

    // parabola for jump
    parabola := Parabola new(1, 1)

    shadow: Shadow

    blockHandler: static CpCollisionHandler

    init: func (.level, .pos) {
        super(level, pos)

        life = 10.0

        sprite = GlSprite new(getSpritePath())
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
    }

    getSpritePath: func -> String {
        "assets/png/hopper.png"
    }

    update: func -> Bool {
        // handle height
        z = parabola eval(jumpCountMax - jumpCount)
        if (jumpCount > 0) {
            jumpCount -= 1
        } else {
            jump()
        }

        sprite scale x = (0.6 + (0.4 * (1.0 - (z / jumpHeight))))
        sprite scale y = (1.3 - (0.3 * (1.0 - (z / jumpHeight))))

        // friction
        if (grounded?()) {
            friction := 0.9
            vel := body getVel()
            vel x *= friction
            vel y *= friction
            body setVel(vel)
        }

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 12 + z)
        pos set!(body getPos())
        shadow setPos(pos)

        super()
    }

    initPhysx: func {
        (width, height) := (24, 24)
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

        initHandlers()
    }

    initHandlers: func {
        if (!blockHandler) {
            blockHandler = BlockHopperHandler new()
            level space addCollisionHandler(CollisionTypes ENEMY, CollisionTypes BLOCK, blockHandler)
            level space addCollisionHandler(CollisionTypes ENEMY, CollisionTypes HERO, blockHandler)
        }
    }

    destroy: func {
        shadow destroy()
        level space removeShape(shape)
        level space removeBody(body)
        level charGroup remove(sprite)
    }

    jump: func {
        target := Target choose(pos, level, radius)
        body setVel(cpv(target sub(pos) normalized() mul(speed)))

        parabola = Parabola new(jumpHeight, jumpCountMax * 0.5)
        jumpCount = jumpCountMax
    }

}

BlockHopperHandler: class extends CpCollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        object := shape1 getUserData() as Entity
        match object {
            case hopper: Hopper =>
                hopper grounded?()
            case =>
                true
        }
    }

}

