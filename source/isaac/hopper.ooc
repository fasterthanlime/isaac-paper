

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
import isaac/[level, game, paths, shadow, enemy, hero, utils, tiles]

/*
 * JUMP JUMP JUMP JUMP JUMP - Jump around!
 */
Hopper: class extends Mob {

    speed := 230.0

    jumpCount := 60
    jumpCountMax := 100
    jumpGracePeriod := 40
    jumpHeight := 90.0
    radius := 250

    damage := 4.0
    scale := 0.8

    // parabola for jump
    parabola := Parabola new(1, 1)

    shadow: Shadow

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

    grounded?: func -> Bool {
        super() && jumpCount < (jumpCountMax - jumpGracePeriod)
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

    touchHero: func (hero: Hero) -> Bool {
        // we can't hurt the hero if we're in the air
        if (grounded?()) {
            return super()
        }

        false
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
    }

    destroy: func {
        shadow destroy()
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
    }

    touchBlock: func (tile: Tile) -> Bool {
        grounded?()
    }

    jump: func {
        jumpCount = jumpCountMax
        target := Target choose(pos, level, radius)
        body setVel(cpv(target sub(pos) normalized() mul(speed)))

        parabola = Parabola new(jumpHeight, jumpCountMax * 0.5)
    }

}

