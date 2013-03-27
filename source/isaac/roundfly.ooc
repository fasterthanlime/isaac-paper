
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
    explosion, walls, tiles, ballbehavior]

RoundFlyType: enum {
    BOOM
    RED
}

/**
 * You see me flyin', you hatin.
 */
RoundFly: class extends Mob {

    scale := 0.75

    shadow: Shadow

    type: RoundFlyType

    fireSpeed := 280.0

    baseColor: Color

    behavior: BallBehavior

    init: func (.level, .pos, =type) {
        super(level, pos)

        life = 20.0

        loadSprite(getSpriteName(), level charGroup, scale)

        baseColor = match type {
            case RoundFlyType RED =>
                Color new(255, 140, 140)
            case =>
                Color white()
        }

        factor := 0.2
        shadow = Shadow new(level, sprite width * scale * factor)

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
    }

    update: func -> Bool {
        behavior update()

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 8 + z)
        pos set!(body getPos())
        shadow setPos(pos sub(0.0, 3.0))

        retVal := super()
        if (!redish) {
            sprite color set!(baseColor)
        }
        retVal
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
        super()
    }

}

