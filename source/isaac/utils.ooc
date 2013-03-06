
// third-party stuff
use dye
import dye/math

use chipmunk
import chipmunk

use gnaar
import gnaar/[utils]

// sdk stuff
import math/Random

// our stuff
import isaac/[level, hero]

Target: class {

    choose: static func (pos: Vec2, level: Level, radius: Float) -> Vec2 {
        diff, target: Vec2
        good := false
        count := 8

        heroDiff := level hero pos sub(pos)
        if (heroDiff norm() <= radius) {
            target = level hero pos
        } else {
            while (!good && count > 0) {
                x := Random randInt(-100, 100) as Float / 100.0
                y := Random randInt(-100, 100) as Float / 100.0
                diff = vec2(x, y) normalized()
                target = pos add(diff mul(radius))
                good = target inside?(level paddedBottomLeft, level paddedTopRight)
                count -= 1
            }
        }
        target = target clamp(level paddedBottomLeft, level paddedTopRight)

        target
    }

}

Mover: class {

    target: Vec2
    body: CpBody
    speed: Float

    moving := false

    init: func (=body, =speed) {
        target = vec2(body getPos())
    }

    update: func (pos: Vec2) {
        dist := pos dist(target)
        if (moving && dist > 20.0) {
            body setVel(cpv(target sub(pos) normalized() mul(speed)))
        } else {
            moving = false
            // friction
            friction := 0.8
            vel := body getVel()
            vel x *= friction
            vel y *= friction
            body setVel(vel)
        }
    }

    setTarget: func (=target) {
        moving = true
    }

}

