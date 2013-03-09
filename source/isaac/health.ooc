
// third-party stuff
use dye
import dye/[core, loop, input, primitives, math, sprite, text]

use deadlogger
import deadlogger/[Log, Logger]

use gnaar
import gnaar/[grid, utils]

// sdk stuff
import math/Random

// our stuff
import isaac/[game, level, hero]

Health: class extends GlGroup {

    left := 587.0
    bottom := 554.0
    paddingY := 28.0

    game: Game

    init: func (=game) {
        super()
    }

    update: func {
        if (game heroStats healthChanged) {
            game heroStats healthChanged = false
            setup()
        }
    }

    setup: func {
        children clear()

        rest := game heroStats redLife
        index := 0

        for (i in 0..game heroStats containers) {
            if (rest >= 2) {
                add(Heart new(getPos(index), HeartType FULL))
                rest -= 2
            } else if (rest >= 1) {
                add(Heart new(getPos(index), HeartType HALF))
                rest -= 1
            } else {
                add(Heart new(getPos(index), HeartType EMPTY))
            }
            index += 1
        }
    }

    getPos: func (index: Int) -> Vec2 {
        y := bottom
        if (index >= 6) {
            y -= paddingY
            index -= 6
        }
        x := left + index * 34

        vec2(x, y)
    }

}

Heart: class extends GlSprite {

    type: HeartType

    init: func (pos: Vec2, =type) {
        super(getSpritePath())
        this pos set!(pos)
    }

    getSpritePath: func -> String {
        match type {
            case HeartType FULL =>
                "assets/png/heart-full.png"
            case HeartType HALF =>
                "assets/png/heart-half.png"
            case =>
                "assets/png/heart-empty.png"
        }
    }

}

HeartType: enum {
    EMPTY
    HALF
    FULL
}

