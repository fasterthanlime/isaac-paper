
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
 * JUMP JUMP JUMP JUMP JUMP - Jump around!
 */
Hopper: class extends Mob {

    baseScale := 0.8

    behavior: HopBehavior

    init: func (.level, .pos) {
        super(level, pos)

        life = 10.0

        behavior = HopBehavior new(this)

        loadSprite(getSpriteName(), level charGroup, baseScale)
        spriteYOffset = 16

        createShadow(41)

        createCircle(15, 10.0)
        shape setGroup(CollisionGroups HOPPER)
    }

    getSpriteName: func -> String {
        "hopper"
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
        !behavior jumping?()
    }

    touchHole: func (tile: Tile) -> Bool {
        !behavior jumping?()
    }

}

