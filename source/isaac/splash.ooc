

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
import math/Random

// our stuff
import isaac/[level, hero]


Splash: class extends Entity {

    body: CpBody
    shape: CpShape

    sprite: GlSprite

    life := 1.0
    incr := -0.1

    scaleA := 0.1
    scaleB := 0.5

    alphaFactor := 0.6

    init: func (.level, .pos) {
        super(level, pos)

        sprite = GlSprite new(getSpritePath())
        sprite pos set!(pos)
        sprite scale set!(scaleA, scaleB)
        sprite angle = Random randInt(1, 360) as Float
        level group add(sprite)
    }

    getSpritePath: func -> String {
        "assets/png/splash-%d.png" format(Random randInt(1, 4))
    }

    update: func -> Bool {
        life += incr
        if (life < 0) {
            return false
        }

        scale := scaleA * life + scaleB * (1.0 - life)
        sprite scale set!(scale, scale)
        sprite opacity = life * alphaFactor

        true
    }

    destroy: func {
        level group remove(sprite)
    }

}

