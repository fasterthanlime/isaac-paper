
// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use dye
import dye/[math]

use chipmunk
import chipmunk

use gnaar
import gnaar/[utils, physics]

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
        alpha := 0.85f
        bodyVel lerp!(idealVel, 1.0f - alpha)
        enemy body setVel(cpv(bodyVel))
    }

}
