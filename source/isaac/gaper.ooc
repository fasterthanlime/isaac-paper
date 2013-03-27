

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
import structs/[ArrayList, List, HashMap]

// our stuff
import isaac/[level, shadow, enemy, hero, utils, paths, pathfinding,
    explosion, tear]

GaperType: enum {
    GAPER
    FROWNING
    GUSHER
    PACER
    GURGLE 
}

/**
 * Awrrrgllll
 */
Gaper: class extends Mob {

    type: GaperType

    shadow: Shadow
    shadowFactor := 0.4
    shadowYOffset := 13

    scale := 0.8

    init: func (=level, =pos, =type) {
        super(level, pos)

        shadow = Shadow new(level, 40)

        loadSprite(getSpriteName(), level charGroup, scale)

        createBox(35, 35, 15.0)
    }

    getSpriteName: func -> String {
        match type {
            case GaperType FROWNING =>
                "frowning-gaper"
            case GaperType GUSHER =>
                "gusher"
            case GaperType PACER =>
                "pacer"
            case => // fallback
                "gaper"
        }
    }

    update: func -> Bool {
        bodyPos := body getPos()
        pos set!(bodyPos)
        sprite pos set!(pos)
        shadow setPos(pos sub(0, shadowYOffset))

        //behavior update()

        super()
    }

    destroy: func {
        shadow destroy()
        super()
    }

}

