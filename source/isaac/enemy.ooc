
// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

// our stuff
import isaac/[level]

/*
 * Any type of enemy
 */
Enemy: abstract class extends Entity {

    life := 10.0

    pos: Vec2
    z := 0.0

    damageCount := 0
    damageLength := 20

    init: func (.level, .pos) {
        super(level)

        this pos = vec2(pos)
    }

    harm: func (damage: Float) {
        if (damageCount <= 0) {
            damageCount = damageLength
            life -= damage
        }
    }

    update: func -> Bool {
        if (damageCount > 0) {
            damageCount -= 1
            intval := damageCount / (damageLength * 0.4)
            if (intval % 2 == 0) {
                setOpacity(0.2)
            } else {
                setOpacity(1.0)
            }
        } else {
            setOpacity(1.0)
        }

        if (life <= 0.0) {
            return false
        }

        true
    }

    setOpacity: abstract func (opacity: Float)

    grounded?: func -> Bool {
        z < level groundLevel
    }

}

Mob: class extends Enemy {

    sprite: GlSprite

    init: func (.level, .pos) {
        super(level, pos)
    }

    setOpacity: func (opacity: Float) {
        sprite opacity = opacity
    }

}

