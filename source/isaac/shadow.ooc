

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
import isaac/[level, paths]

Shadow: class extends Entity {

    sprite: GlSprite

    width: Float

    scale, baseScale: Float

    opacity := 1.0
    baseOpacity := 0.45

    init: func (.level, =width) {
        super(level, vec2(0, 0))

        sprite = GlSprite new("assets/png/shadow.png")
        setOpacity(1.0)

        baseScale = width / sprite width as Float
        setScale(1.0)

        level shadowGroup add(sprite)
    }

    setScale: func (=scale) {
        finalScale := baseScale * scale
        sprite scale set!(finalScale, finalScale)
    }

    setPos: func (pos: Vec2) {
        sprite pos set!(pos)
    }

    setPos: func ~floats (x, y: Float) {
        sprite pos set!(x, y)
    }

    setOpacity: func (=opacity) {
        sprite opacity = baseOpacity * opacity
    }

    destroy: func {
        level shadowGroup remove(sprite)
    }

}

