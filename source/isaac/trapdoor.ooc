
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
import isaac/[level, hero, utils, freezer]

/*
 * Will you make it to the next level?
 */
TrapDoor: class extends Entity {

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    sprite: GlSprite

    trapDoorHeroHandler: static CollisionHandler

    gracePeriod := 10

    init: func (.level, .pos) {
        super(level, pos)

        sprite = GlSprite new("assets/png/trap-door.png")
        level holeGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
    }

    update: func -> Bool {
        if (gracePeriod > 0) {
            gracePeriod -= 1
        }

        true
    }

    initPhysx: func {
        (width, height) := (10, 10)

        body = CpBody new(INFINITY, INFINITY)
        bodyPos := cpv(pos)
        body setPos(bodyPos)
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes TRAP_DOOR)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        if (!trapDoorHeroHandler) {
            trapDoorHeroHandler = TrapDoorHeroHandler new()
        }
        trapDoorHeroHandler ensure(level)
    }

    destroy: func {
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level holeGroup remove(sprite)
    }

    shouldFreeze: func -> Bool {
        true
    }

}

TrapDoorHeroHandler: class extends CollisionHandler {

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        trap := shape1 getUserData() as TrapDoor
        if (trap gracePeriod > 0) {
            return false
        }

        hero := shape2 getUserData() as Hero
        hero level game changeFloor()

        true
    }

    add: func (f: Func(Int, Int)) {
        f(CollisionTypes TRAP_DOOR, CollisionTypes HERO)
    }

}



