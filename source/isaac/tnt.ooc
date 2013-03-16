
// third-party stuff
use chipmunk
import chipmunk

use dye
import dye/[core, math, input, sprite]

use gnaar
import gnaar/[utils]

use deadlogger
import deadlogger/[Log, Logger]

// sdk stuff
import structs/[List, ArrayList, HashMap]
import math/Random

// our stuff
import isaac/[game, hero, walls, bomb, rooms, enemy, map, level, tiles,
    explosion]

/**
 * Boom boom boom boom. (If you're singing, you lost).
 */
TNT: class extends Tile {

    maxLife, life: Float
    damageCount := 0
    explosionRadius := 105.0

    init: func (.level) {
        super(level)
        shape setCollisionType(CollisionTypes BLOCK)

        maxLife = 12.0
        life = maxLife
    }

    getSprite: func -> String {
        "assets/png/tnt.png"
    }

    getLayer: func -> GlGroup {
        level blockGroup
    }

    update: func -> Bool {
        sprite scale x = 1.4 - (0.4 * life / maxLife)

        if (damageCount > 0) {
            damageCount -= 1
        }

        if (life <= 0.0) {
            onDeath()
            return false
        }

        super()
    }

    onDeath: func {
        level add(Explosion new(level, sprite pos))
    }

    harm: func (damage: Int) {
        if (damageCount <= 0) {
            life -= damage
            damageCount = 10
        }
    }

    bombHarm: func (explosion: Explosion) {
        life = 0.0
    }

}
