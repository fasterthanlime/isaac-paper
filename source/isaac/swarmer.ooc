
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
    explosion, walls, tiles, ballbehavior, roundfly]

/**
 * Cough cough.
 */
Swarmer: class extends Mob {

    shadow: Shadow

    fireSpeed := 280.0

    maxLife: Float

    behavior: BallBehavior

    hairSprite: GlSprite

    coughCount := 250

    init: func (.level, .pos) {
        super(level, pos)

        maxLife = 30.0
        life = maxLife

        sprite = GlSprite new("assets/png/swarmer-head.png")
        hairSprite = GlSprite new("assets/png/swarmer-hair.png")

        factor := 0.2
        shadow = Shadow new(level, sprite width * factor)

        level charGroup add(sprite)
        level charGroup add(hairSprite)
        sprite pos set!(pos)

        behavior = BallBehavior new(this)
        behavior speed = 80.0

        radius := 20.0
        mass := 40.0
        behavior initPhysx(radius, mass)
    }

    hitBack: func (tear: Tear) {
        // we bounce naturally
    }

    onDeath: func {
        // spawn a boom fly
        roundFly := RoundFly new(level, pos, RoundFlyType BOOM)
        roundFly behavior setDir(behavior dir)
        level add(roundFly)
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

        bodyPos := body getPos()

        spriteX := bodyPos x
        spriteY := bodyPos y + 8 + z
        sprite pos set!(spriteX, spriteY)
        hairSprite pos set!(spriteX, spriteY + 1)

        hairScale := 0.5 + 0.5 * (life / maxLife)
        hairSprite scale set!(hairScale, hairScale)

        pos set!(body getPos())
        shadow setPos(pos sub(0.0, 3.0))

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
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
        level charGroup remove(hairSprite)
    }

}


