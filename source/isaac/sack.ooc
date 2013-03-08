
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
import isaac/[level, shadow, enemy, hero, utils, spider, paths]

/*
 * Spiderer.
 */
Sack: class extends Mob {

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    spawnCount := 200
    spawnCountMax := 140
    radius := 180

    damage := 4.0

    shadow: Shadow
    maxLife := 30.0
    lifeIncr := 0.04

    init: func (.level, .pos) {
        super(level, pos)

        life = maxLife

        sprite = GlSprite new("assets/png/sack.png")
        shadow = Shadow new(level, sprite width * 0.5)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
    }

    update: func -> Bool {
        if (life < maxLife) {
           if (damageCount <= 0) {
                life += lifeIncr
           }
        } else {
            if (spawnCount > 0) {
                dist := level hero pos dist(pos)
                if (dist < radius) {
                    spawnCount -= Random randInt(1, 2)
                }
            } else {
                spawn()
            }
        }

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 4 + z)
        pos set!(body getPos())
        shadow setPos(pos)

        scale := 0.8 * life / maxLife
        sprite scale set!(scale, scale)

        if (life <= 8.0) {
            return false
        }

        super()
    }

    spawn: func {
        spider := Spider new(level, pos)
        spawnVel := 160.0
        spider parabola = Parabola new(50, 40)
        spider shape setSensor(true)
        spider body setVel(cpv(Target direction() mul(spawnVel)))
        level add(spider)
        resetSpawnCount()
    }

    resetSpawnCount: func {
        spawnCount = spawnCountMax + Random randInt(-20, 120)
    }

    initPhysx: func {
        (width, height) := (20, 20)

        body = CpBody new(INFINITY, INFINITY)
        bodyPos := cpv(pos)
        body setPos(bodyPos)
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

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

    harm: func (damage: Float) {
        super(damage)
        resetSpawnCount()
    }

}

