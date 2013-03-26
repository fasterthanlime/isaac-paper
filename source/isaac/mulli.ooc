

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

    rotateConstraint: CpConstraint

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

        sprite = GlSprite new(getSpritePath())
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale * shadowFactor)

        level charGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()

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

    getSpritePath: func -> String {
        match type {
            case MulliType MULLIGAN =>
                "assets/png/mulligan.png"
            case MulliType MULLIGOON =>
                "assets/png/mulligoon.png"
            case MulliType MULLIBOOM =>
                "assets/png/mulliboom.png"
            case MulliType HIVE =>
                "assets/png/hive.png"
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
        spawnTear(pos, vec2(-1, 0))
        spawnTear(pos, vec2(1, 0))
        spawnTear(pos, vec2(0, -1))
        spawnTear(pos, vec2(0, 1))
    }

    spawnTear: func (pos, dir: Vec2) {
        vel := dir mul(fireSpeed)
        tear := Tear new(level, pos, vel, TearType ENEMY, 1)
        level add(tear)
    }

    update: func -> Bool {
        behavior update(level hero pos)

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 4 + z)
        pos set!(bodyPos)
        shadow setPos(pos sub(0, shadowYOffset))

        super()
    }

    initPhysx: func {
        (width, height) := (35, 35)
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

        level space removeConstraint(rotateConstraint)
        rotateConstraint free()

        level space removeBody(body)
        body free()

        level charGroup remove(sprite)
    }

}


