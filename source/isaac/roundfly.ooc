
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

        sprite = GlSprite new(getSpritePath())
        sprite scale set!(scale, scale)
        baseColor = match type {
            case RoundFlyType RED =>
                Color new(255, 140, 140)
            case =>
                Color white()
        }

        factor := 0.2
        shadow = Shadow new(level, sprite width * scale * factor)

        level charGroup add(sprite)
        sprite pos set!(pos)

        behavior = BallBehavior new(this)
        radius := 20.0
        mass := 20.0
        behavior initPhysx(radius, mass)
    }

    hitBack: func (tear: Tear) {
        // we bounce naturally
    }

    getSpritePath: func -> String {
        match type {
            case RoundFlyType BOOM =>
                "assets/png/boom-fly.png"
            case =>
                "assets/png/red-boom-fly.png"
        }
    }

    onDeath: func {
        match type {
            case RoundFlyType BOOM =>
                // explode
                level add(Explosion new(level, pos))
            case RoundFlyType RED =>
                // spawn tears in 6 directions
                angle := (Random randInt(0, 360) as Float) toRadians()
                for (i in 0..6) {
                    spawnTear(pos, Vec2 fromAngle(angle as Float), fireSpeed) 
                    angle += (PI * 0.33)
                }
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
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
    }

}

