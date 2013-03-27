

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
    explosion, bomb, fly, tear, guidebehavior]

MulliType: enum {
    MULLIGAN
    MULLIGOON
    MULLIBOOM
    HIVE
}

/*
 * Mulligans, mulligoons, mullibooms, and hives
 */
Mulli: class extends Mob {

    fireSpeed := 280.0

    moveCount := 60
    moveCountMax := 80

    scale := 0.9

    shadow: Shadow
    shadowFactor := 0.4
    shadowYOffset := 25

    type: MulliType

    behavior: GuideBehavior

    init: func (.level, .pos, =type) {
        super(level, pos)

        life = 14.0

        loadSprite(getSpriteName(), level charGroup, scale)
        shadow = Shadow new(level, sprite width * scale * shadowFactor)

        createBox(35, 35, 15.0)

        behavior = GuideBehavior new(this, getSpeed())
        behavior flee = (type != MulliType MULLIBOOM)
    }

    getSpeed: func -> Float {
        match type {
            case MulliType MULLIBOOM =>
                180.0
            case =>
                120.0
        }
    }

    getSpriteName: func -> String {
        match type {
            case MulliType MULLIGAN =>
                "mulligan"
            case MulliType MULLIGOON =>
                "mulligoon"
            case MulliType MULLIBOOM =>
                "mulliboom"
            case MulliType HIVE =>
                "hive"
            case =>
                raise("Invalid mulli type: %d" format(type))
                ""
        }
    }

    onDeath: func {
        match type {
            case MulliType MULLIBOOM =>
                level add(Explosion new(level, pos))
            case MulliType MULLIGAN || MulliType HIVE =>
                spawnFlies(Random randInt(3, 5))
            case MulliType MULLIGOON =>
                spawnBombAndTears()
        }
    }

    spawnBombAndTears: func {
        level add(Bomb new(level, pos))
        spawnPlusTears(fireSpeed)
    }

    update: func -> Bool {
        behavior update(level hero pos)

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 4 + z)
        pos set!(bodyPos)
        shadow setPos(pos sub(0, shadowYOffset))

        super()
    }

    destroy: func {
        shadow destroy()
        super()
    }

}

