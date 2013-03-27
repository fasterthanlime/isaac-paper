

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

    init: func (=level, =pos, =type) {
        super(level, pos)

        loadSprite(getSpriteName(), level charGroup, 0.8)

        createShadow(40)
        shadowYOffset = 13

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
        //behavior update()

        super()
    }

    destroy: func {
        super()
    }

}

