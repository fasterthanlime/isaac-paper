
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
import isaac/[level, game, shadow, enemy, hero, utils, tiles]
import isaac/behaviors/[hopbehavior]

/*
 * Yer greed will lose you.
 */
Keeper: class extends Mob {

    baseScale := 1.0

    behavior: HopBehavior

    fireRadius := 280.0
    fireSpeed := 260.0

    init: func (.level, .pos) {
        super(level, pos)

        life = 10.0

        behavior = HopBehavior new(this)

        loadSprite(getSpriteName(), level charGroup, baseScale)
        spriteYOffset = 16

        createShadow(41)

        createCircle(15, 10.0)
        shape setGroup(CollisionGroups HOPPER)

        behavior radius = 200
        behavior jumpCountMax = 15
        behavior speed = 280.0
        behavior jumpHeight = 50.0
        behavior jumpDistance = 80.0

        behavior onLand(||
            maybeFire()
        )
    }

    maybeFire: func {
        number := Random randInt(0, 100)
        if (number > 60) {
            return
        }

        diff := level hero aimPos() sub(pos)
        if (diff norm() < fireRadius) {
            spawnTwoTears(pos, diff, fireSpeed)
        }
    }

    tearVulnerable?: func -> Bool {
        z < level groundLevel + 15
    }

    getSpriteName: func -> String {
        "keeper"
    }

    update: func -> Bool {
        behavior update()

        sprite scale set!(baseScale * behavior scale x,
                          baseScale * behavior scale y)

        super()
    }

    touchHero: func (hero: Hero) -> Bool {
        // we can't hurt the hero if we're in the air
        if (grounded?()) {
            return super()
        }

        false
    }

    destroy: func {
        super()
    }

    touchBlock: func (tile: Tile) -> Bool {
        grounded?()
    }

}


