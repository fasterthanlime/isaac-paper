

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
    scale := 0.65

    // parabola for jump
    parabola := Parabola new(1, 1)

    init: func (.level, .pos) {
        super(level, pos)

        life = 10.0

        loadSprite(getSpriteName(), level charGroup, scale)
        spriteYOffset = 12

        createShadow(30)

        createBox(24, 24, 10.0)
    }

    getSpriteName: func -> String {
        "hopper"
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
        jumpCount = jumpCountMax
        target := Target choose(pos, level, radius)
        body setVel(cpv(target sub(pos) normalized() mul(speed)))

        parabola = Parabola new(jumpHeight, jumpCountMax * 0.5)
    }

}

