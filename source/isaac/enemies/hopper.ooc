

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

    baseSpeed := 230.0
    speed := 230.0

    jumpCount := 30
    jumpCountMax := 35
    jumpCountWiggle := 5
    chosenJumpCountMax := 0

    jumpHeight := 90.0
    radius := 250

    damage := 4.0
    scale := 0.8

    // parabola for jump
    parabola: Parabola

    init: func (.level, .pos) {
        super(level, pos)

        life = 10.0

        loadSprite(getSpriteName(), level charGroup, scale)
        spriteYOffset = 16

        createShadow(41)

        createCircle(15, 10.0)
        shape setGroup(CollisionGroups HOPPER)
    }

    getSpriteName: func -> String {
        "hopper"
    }

    update: func -> Bool {
        // handle height
        if (parabola) {
            z = parabola eval()
            if (parabola done?()) {
                parabola = null
            }
        } else {
            if (jumpCount > 0) {
                jumpCount -= 1
            } else {
                jump()
            }
        }

        sprite scale x = scale * (0.6 + (0.4 * (1.0 - (z / jumpHeight))))
        sprite scale y = scale * (1.3 - (0.3 * (1.0 - (z / jumpHeight))))

        // friction
        if (grounded?()) {
            friction := 0.9
            vel := body getVel()
            vel x *= friction
            vel y *= friction
            body setVel(vel)
        }

        super()
    }

    touchHero: func (hero: Hero) -> Bool {
        // we can't hurt the hero if we're in the air
        if (grounded?()) {
            return super()
        }

        false
    }

    destroy: func {
        super()
    }

    touchBlock: func (tile: Tile) -> Bool {
        grounded?()
    }

    jump: func {
        jumpCount = jumpCountMax + Random randInt(0, jumpCountWiggle)
        chosenJumpCountMax = jumpCount
        target := Target choose(pos, level, radius)
        target add!(Vec2 random(20))

        jumpSpeed := speed

        diff := target sub(pos)
        norm := diff norm()
        if (norm < speed) {
            jumpSpeed *= (norm / speed)
        }

        body setVel(cpv(diff normalized() mul(jumpSpeed)))

        parabola = Parabola new(jumpHeight, 60.0 / baseSpeed * speed)
        parabola incr = 1.0
    }

}

