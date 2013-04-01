
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
import isaac/enemies/[roundfly]
import isaac/behaviors/[ballbehavior]

/**
 * Cough cough.
 */
Swarmer: class extends Mob {

    fireSpeed := 280.0

    maxLife: Float

    behavior: BallBehavior

    hairSprite: GlSprite

    coughCount := 250

    init: func (.level, .pos) {
        super(level, pos)

        maxLife = 30.0
        life = maxLife

        loadSprite("swarmer-head", level charGroup)
        hairSprite = loadSecondarySprite("swarmer-hair")
        spriteYOffset = 8

        createShadow(30)
        shadowYOffset = 3

        createCircle(20.0, 40.0)
        // so that we bounce back
        shape setElasticity(0.7)

        behavior = BallBehavior new(this)
        behavior speed = 80.0
    }

    hitBack: func (tear: Tear) {
        // we bounce naturally
    }

    onDeath: func {
        // spawn a boom fly
        roundFly := RoundFly new(level, pos, RoundFlyType BOOM)
        roundFly behavior setDir(behavior dir)
        level add(roundFly)
        super()
    }

    update: func -> Bool {
        behavior update()

        if (coughCount > 0) {
            coughCount -= 1
        } else {
            maxFlies := 1 + (3 * (life / maxLife)) as Int
            spawnFlies(Random randInt(1, maxFlies))
            coughCount = Random randInt(480, 600)
        }

        hairSprite pos set!(pos x, pos y + z + spriteYOffset + 1)

        hairScale := 0.5 + 0.5 * (life / maxLife)
        hairSprite scale set!(hairScale, hairScale)

        super()
    }

    grounded?: func -> Bool {
        // kinda..
        true
    }

    touchBlock: func (tile: Tile) -> Bool {
        // most enemies are constrained by blocks.. but not us!
        false
    }

    destroy: func {
        shadow destroy()
        spriteGroup remove(hairSprite)
        super()
    }

}


