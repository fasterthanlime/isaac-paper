

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
import isaac/behaviors/[guidebehavior, strollbehavior]

/**
 * Awrrrgllll
 */
Gaper: class extends Mob {

    type: GaperType

    guideBehavior: GuideBehavior
    strollBehavior: StrollBehavior

    frownRadius := 160.0

    init: func (=level, =pos, =type) {
        super(level, pos)

        loadSprite(getSpriteName(), level charGroup, 0.8)
        spriteYOffset = 14

        createShadow(40)
        shadowYOffset = 8

        createBox(35, 35, 15.0)

        guideBehavior = GuideBehavior new(this, 80)
        strollBehavior = StrollBehavior new(this)
        changeType(type) // set initial values
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

    updateBehaviors: func {
        match type {
            case GaperType GAPER || GaperType FROWNING || GaperType GURGLE =>
                guideBehavior update(level hero pos)
            case GaperType PACER || GaperType GUSHER =>
                strollBehavior update()
        }
    }

    changeType: func (=type) {
        match type {
            case GaperType GAPER || GaperType GURGLE =>
                guideBehavior speed = 160.0
            case GaperType FROWNING =>
                guideBehavior speed = 60.0
        }
        reloadSprite(getSpriteName())
    }

    checkFrown: func {
        if (type == GaperType FROWNING) {
            if (pos dist(level hero pos) < frownRadius) {
                level game playSound("gaper-rawr")
                changeType(GaperType GAPER)
            }
        }
    }

    update: func -> Bool {
        updateBehaviors()
        checkFrown()

        super()
    }

    destroy: func {
        super()
    }

}

GaperType: enum {
    GAPER
    FROWNING
    GUSHER
    PACER
    GURGLE 
}

