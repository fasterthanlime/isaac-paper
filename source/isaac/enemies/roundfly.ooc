
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
import isaac/[game, level, paths, shadow, enemy, hero, utils, tear,
    explosion, walls, tiles]
import isaac/behaviors/[ballbehavior]

RoundFlyType: enum {
    BOOM
    RED
}

/**
 * You see me flyin', you hatin.
 */
RoundFly: class extends Mob {

    scale := 0.7

    type: RoundFlyType

    fireSpeed := 280.0

    behavior: BallBehavior

    init: func (.level, .pos, =type) {
        super(level, pos)

        life = 20.0

        loadSprite(getSpriteName(), level charGroup, scale)
        if (type == RoundFlyType RED) {
            baseColor = Color new(255, 140, 140)
        }

        shadowYOffset = 3
        createShadow(30)

        createCircle(/* radius */ 20.0, /* mass */ 20.0)
        // so that we bounce back
        shape setElasticity(0.7)

        behavior = BallBehavior new(this)
    }

    hitBack: func (tear: Tear) {
        // we bounce naturally
    }

    getSpriteName: func -> String {
        match type {
            case RoundFlyType BOOM =>
                "boom-fly"
            case =>
                "red-boom-fly"
        }
    }

    onDeath: func {
        match type {
            case RoundFlyType BOOM =>
                // explode
                level add(Explosion new(level, pos))
            case RoundFlyType RED =>
                // spawn tears in 6 directions
                spawnSixTears(fireSpeed)
        }
        super()
    }

    update: func -> Bool {
        behavior update()
        super()
    }

    tearVulnerable?: func -> Bool {
        // always!
        true
    }

    grounded?: func -> Bool {
        // nevar!
        false
    }

    touchBlock: func (tile: Tile) -> Bool {
        // round flies can't pass blocks, swarmer can
        true
    }

    destroy: func {
        shadow destroy()
        super()
    }

}

