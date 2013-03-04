

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

// our stuff
import isaac/[level, hero]


Splash: class extends Entity {

    body: CpBody
    shape: CpShape

    sprite: GlSprite

    life := 1.0
    incr := -0.1

    scaleA := 0.4
    scaleB := 1.0

    init: func (.level, pos: Vec2) {
        super(level)

        sprite = GlSprite new("assets/png/tears-1.png")
        sprite pos set!(pos)
        level group add(sprite)
    }

    update: func -> Bool {
        life += incr
        if (life < 0) {
            return false
        }

        scale := scaleA * life + scaleB * (1.0 - life)
        sprite scale set!(scale, scale)
        sprite opacity = life

        true
    }

    destroy: func {
        level group remove(sprite)
    }

}

