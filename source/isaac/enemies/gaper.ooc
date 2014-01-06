

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils, physics]

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

    fireCount := 20
    fireCountMax := 60
    fireSpeed := 140

    frownRadius := 160.0

    init: func (=level, =pos, =type) {
        super(level, pos)

        loadSprite(getSpriteName(), level charGroup, 0.8)
        spriteYOffset = 14

        createShadow(30)
        shadowYOffset = 10

        createBox(35, 35, 15.0)

        guideBehavior = GuideBehavior new(this, 80)
        strollBehavior = StrollBehavior new(this)
        strollBehavior canCharge = false

        changeType(type) // set initial values

        // gapers go through each other
        shape setGroup(CollisionGroups GAPER)

        shootRange = 80.0
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
            case GaperType PACER =>
                strollBehavior update()
            case GaperType GUSHER =>
                // same as pacer
                strollBehavior update()
                // and fire sometimes
                if (fireCount > 0) {
                    fireCount -= 1
                } else {
                    fireCount = fireCountMax + Random randInt(0, 50)
                    spawnTear(pos, Vec2 random(100) normalized(), fireSpeed)
                }
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

    onDeath: func {
        match type {
            case GaperType GAPER || GaperType FROWNING =>
                // so you're saying there's a chance?
                number := Random randInt(0, 100)
                type := match {
                    case (number < 40) =>
                        GaperType GUSHER
                    case =>
                        GaperType PACER
                }

                child := Gaper new(level, pos, type)
                level add(child)
        }
        super()
    }

    checkFire: func {
        if (type == GaperType GUSHER) {
        }
    }

    update: func -> Bool {
        updateBehaviors()
        checkFrown()
        checkFire()

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

