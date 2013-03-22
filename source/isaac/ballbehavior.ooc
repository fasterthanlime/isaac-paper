
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


/**
 * The behavior boom flies & the such have
 */
BallBehavior: class {

    level: Level
    enemy: Enemy

    rotateConstraint: CpConstraint

    dir: Vec2
    speed := 120.0

    init: func (=enemy) {
        level = enemy level
        dir = vec2(oneOrMinusOne(), oneOrMinusOne())
    }

    setDir: func (.dir) {
        dir set!(dir)
    }

    applyDir: func {
        enemy body setVel(cpv(dir normalized() mul(speed)))
    }

    oneOrMinusOne: func -> Int {
        Random randInt(0, 1) * 2 - 1
    }

    initPhysx: func (radius: Float, mass: Float) {
        moment := cpMomentForCircle(mass, 0, radius, cpv(radius, radius))

        body := CpBody new(mass, moment)
        body setPos(cpv(enemy pos))
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape := CpCircleShape new(body, radius, cpv(0, 0))
        shape setUserData(enemy)
        shape setCollisionType(CollisionTypes ENEMY)
        shape setElasticity(0.7)
        level space addShape(shape)

        // assign to our master
        enemy body = body
        enemy shape = shape

        applyDir()
    }

    update: func {
        bodyVel := vec2(enemy body getVel())
        angle := bodyVel angle() toDegrees()

        match {
            case angle > 0.0 && angle < 90.0 =>
                dir set!(1, 1)
            case angle > 90.0 && angle < 180.0 =>
                dir set!(-1, 1)
            case angle > 180.0 && angle < 270.0 =>
                dir set!(-1, -1)
            case angle =>
                dir set!(1, -1)
        }

        idealVel := dir mul(speed)
        alpha := 0.85
        bodyVel interpolate!(idealVel, 1 - alpha)
        enemy body setVel(cpv(bodyVel))
    }

}
