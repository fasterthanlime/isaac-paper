

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
import isaac/[level, parabola]

Shadow: class extends Entity {

    sprite: GlSprite

    width: Float

    init: func (.level, =width) {
        sprite = GlSprite new("assets/png/shadow.png")
        scale := width / sprite width as Float
        sprite scale set!(scale, scale)

        level shadowGroup add(sprite)
    }

    setPos: func (pos: Vec2) {
        sprite pos set!(pos)
    }

}

