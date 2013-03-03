

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

// our stuff
import isaac/[level]

/*
 * Dat Isaac...
 */
Hero: class extends Entity {

    sprite: GlSprite

    pos: Vec2

    init: func (.level, .pos) {
        sprite = GlSprite new("assets/png/isaac-down.png")
        level group add(sprite)

        this pos = vec2(pos)
        sprite pos set!(pos)
    }

}

