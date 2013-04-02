
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
import isaac/[game, level, hero, collectible]

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

        budget := 12

        for (i in 0..game heroStats containers) {
            if (rest >= 2) {
                add(Heart new(getPos(index), HeartValue FULL, HeartType RED))
                rest -= 2
            } else if (rest >= 1) {
                add(Heart new(getPos(index), HeartValue HALF, HeartType RED))
                rest -= 1
            } else {
                add(Heart new(getPos(index), HeartValue EMPTY, HeartType RED))
            }
            index += 1
            budget -= 1
        }

        rest = game heroStats eternalLife

        while (rest > 0 && budget > 0) {
            if (rest >= 2) {
                add(Heart new(getPos(index), HeartValue FULL, HeartType ETERNAL))
                rest -= 2
            } else if (rest >= 1) {
                add(Heart new(getPos(index), HeartValue HALF, HeartType ETERNAL))
                rest -= 1
            } else {
                add(Heart new(getPos(index), HeartValue EMPTY, HeartType ETERNAL))
            }
            index += 1
            budget -= 1
        }

        rest = game heroStats spiritLife

        while (rest > 0 && budget > 0) {
            if (rest >= 2) {
                add(Heart new(getPos(index), HeartValue FULL, HeartType SPIRIT))
                rest -= 2
            } else if (rest >= 1) {
                add(Heart new(getPos(index), HeartValue HALF, HeartType SPIRIT))
                rest -= 1
            } else {
                add(Heart new(getPos(index), HeartValue EMPTY, HeartType SPIRIT))
            }
            index += 1
            budget -= 1
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

    value: HeartValue
    type: HeartType

    init: func (pos: Vec2, =value, =type) {
        super(getSpritePath())
        this pos set!(pos)
    }

    getSpritePath: func -> String {
        match value {
            case HeartValue FULL =>
                match type {
                    case HeartType SPIRIT =>
                        "assets/png/heart-full-spirit.png"
                    case => // otherwise, red
                        "assets/png/heart-full-red.png"
                }
            case HeartValue HALF =>
                match type {
                    case HeartType SPIRIT =>
                        "assets/png/heart-half-spirit.png"
                    case HeartType ETERNAL =>
                        "assets/png/heart-half.png"
                    case => // otherwise, red
                        "assets/png/heart-half-red.png"
                }
            case =>
                "assets/png/heart-empty-red.png"
        }
    }

}

