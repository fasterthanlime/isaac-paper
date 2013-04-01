
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
    explosion, tear]
import isaac/behaviors/[firebehavior]

/**
 * Just standing there
 */
Horf: class extends Mob {
    
    fireBehavior: FireBehavior

    init: func (=level, =pos) {
        super(level, pos)

        loadSprite("horf", level charGroup)

        createShadow(30)
        shadowYOffset = 10

        createCircle(20, 80.0)

        fireBehavior = FireBehavior new(this)
        fireBehavior targetType = TargetType HERO

        fireBehavior onFire(||
            level game playRandomSound("horf-attack", 2)
        )
    }

    update: func -> Bool {
        fireBehavior update()
        super()
    }

    hitBack: func (tear: Tear) {
        // nuh-huh.
    }

}

