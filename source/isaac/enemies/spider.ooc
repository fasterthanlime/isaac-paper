

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
import isaac/[level, shadow, enemy, hero, utils, paths]

SpiderType: enum {
    SMALL
    BIG
}

/*
 * Spidery... yum
 */
Spider: class extends Mob {

    moveCount := 60
    moveCountMax := 80
    radius := 180

    mover: Mover

    parabola: Parabola

    type: SpiderType

    init: func (.level, .pos, type := SpiderType SMALL) {
        this type = type
        super(level, pos)

        life = 8.0

        loadSprite(getSpriteName(), level charGroup, 0.8)
        spriteYOffset = 4

        createShadow(30)
        shadowYOffset = 8

        createBox(10, 10, 15.0)

        mover = Mover new(level, body, 280.0)
        mover alpha = 0.8
    }

    getSpriteName: func -> String {
        match type {
            case SpiderType SMALL =>
                "spider"
            case =>
                "big-spider"
        }
    }

    onDeath: func {
        if (type == SpiderType BIG) {
            // spawn two children!
            spawnChild()
            spawnChild()
        }
    }

    spawnChild: func {
        s := Spider new(level, pos, SpiderType SMALL)
        s catapult()
        level add(s)
    }

    catapult: func {
        parabola = Parabola new(30.0, 2.0, 0)

        speed := 150
        body setVel(cpv(Vec2 random(speed)))
    }

    update: func -> Bool {
        if (parabola) {
            // handle height
            z = parabola eval()
            if (parabola done?()) {
                z = parabola bottom
                parabola = null
                shape setSensor(true)
            }
        }

        if (moveCount > 0) {
            moveCount -= 1
        } else {
            updateTarget()
        }
        if (!parabola) {
            mover update(pos)
        }

        super()
    }

    updateTarget: func {
        mover setTarget(Target choose(pos, level, radius))
        moveCount = moveCountMax + Random randInt(-10, 40)
    }

    destroy: func {
        super()
    }

}

