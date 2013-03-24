
// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use dye
import dye/[math]

use chipmunk
import chipmunk

use gnaar
import gnaar/[utils]

// sdk stuff
import math, math/Random

// our stuff
import isaac/[game, level, utils, enemy]

StrollState: enum {
    STROLL
    CHARGE
}

/**
 * The behavior of maggots, chargers, knights, leeches, etc.
 */
StrollBehavior: class {

    level: Level
    enemy: Enemy

    speed := 60.0

    rotateConstraint: CpConstraint

    dir := Direction LEFT

    state := StrollState STROLL

    init: func (=level, =enemy)

    initPhysx: func (width, height, mass: Float) {
        moment := cpMomentForBox(mass, width, height)

        body := CpBody new(mass, moment)
        body setPos(cpv(enemy pos))
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape := CpBoxShape new(body, width, height)
        shape setUserData(enemy)
        shape setCollisionType(CollisionTypes ENEMY)
        level space addShape(shape)

        // assign to our master
        enemy body = body
        enemy shape = shape
    }

    setDir: func (=dir)

    update: func {
        bodyVel := vec2(enemy body getVel())
        delta := dir toDeltaFloat()
        idealVel := delta mul(speed)
        alpha := 0.85
        bodyVel interpolate!(idealVel, 1 - alpha)
        enemy body setVel(cpv(bodyVel))
    }

    charging?: func -> Bool {
        state == StrollState CHARGE
    }

}


