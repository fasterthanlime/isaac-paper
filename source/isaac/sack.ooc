
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
import isaac/[level, shadow, enemy, hero, utils, spider]

/*
 * Spiderer.
 */
Sack: class extends Mob {

    shape: CpShape
    body: CpBody
    rotateConstraint, springConstraint: CpConstraint

    spawnCount := 80
    spawnCountMax := 80
    radius := 180

    damage := 4.0
    scale := 0.8

    shadow: Shadow

    init: func (.level, .pos) {
        super(level, pos)

        life = 8.0

        sprite = GlSprite new("assets/png/sack.png")
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale * 0.5)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
    }

    update: func -> Bool {
        if (spawnCount > 0) {
            spawnCount -= 1
        } else {
            spawn()
        }

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 4 + z)
        pos set!(body getPos())
        shadow setPos(pos)

        super()
    }

    spawn: func {
        level add(Spider new(level, pos))
        spawnCount = spawnCountMax + Random randInt(-20, 120)
    }

    initPhysx: func {
        (width, height) := (10, 10)
        mass := 20.0
        moment := cpMomentForBox(mass, width, height)

        body = CpBody new(mass, moment)
        bodyPos := cpv(pos)
        body setPos(bodyPos)
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        springConstraint = CpDampedSpring new(body,
            level space getStaticBody(), cpv(0, 0), bodyPos, 0, 30_000, 5_000)
        level space addConstraint(springConstraint)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes ENEMY)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
    }

    destroy: func {
        shadow destroy()
        level space removeShape(shape)
        level space removeBody(body)
        level charGroup remove(sprite)
    }

}

