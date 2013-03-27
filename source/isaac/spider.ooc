

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

    scale := 0.8

    shadow: Shadow
    shadowFactor := 0.7
    shadowYOffset := 8

    mover: Mover

    parabola: Parabola

    type: SpiderType

    init: func (.level, .pos, type := SpiderType SMALL) {
        this type = type
        super(level, pos)

        life = 8.0

        sprite = GlSprite new(getSpritePath())
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale * shadowFactor)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
        mover = Mover new(level, body, 280.0)
        mover alpha = 0.8
    }

    getSpritePath: func -> String {
        match type {
            case SpiderType SMALL =>
                "assets/png/spider.png"
            case =>
                "assets/png/big-spider.png"
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

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 4 + z)
        pos set!(body getPos())
        shadow setPos(pos sub(0, shadowYOffset))

        super()
    }

    updateTarget: func {
        mover setTarget(Target choose(pos, level, radius))
        moveCount = moveCountMax + Random randInt(-10, 40)
    }

    initPhysx: func {
        (width, height) := (10, 10)
        mass := 15.0
        moment := cpMomentForBox(mass, width, height)

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes ENEMY)
        level space addShape(shape)
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

