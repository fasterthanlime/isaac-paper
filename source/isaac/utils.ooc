
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

    direction: static func -> Vec2 {
        x := Random randInt(-100, 100) as Float / 100.0
        y := Random randInt(-100, 100) as Float / 100.0
        vec2(x, y) normalized()
    }

    choose: static func (pos: Vec2, level: Level, radius: Float, trackHero := true) -> Vec2 {
        diff, target: Vec2
        good := false
        count := 8

        if (trackHero) {
            heroDiff := level hero pos sub(pos)
            if (heroDiff norm() <= radius) {
                target = level hero pos
                good = true
            }
        }

        while (!good && count > 0) {
            diff = direction()
            target = pos add(diff mul(radius))
            good = target inside?(level paddedBottomLeft, level paddedTopRight)
            count -= 1
        }
        target = target clamp(level paddedBottomLeft, level paddedTopRight)

        target
    }

}

Mover: class {

    target: Vec2
    body: CpBody
    speed: Float
    alpha := 0.9

    moving := false

    init: func (=body, =speed) {
        target = vec2(body getPos())
    }

    update: func (pos: Vec2) {
        dist := pos dist(target)
        if (moving && dist > 20.0) {
            vel := vec2(body getVel())
            idealVel := target sub(pos) normalized() mul(speed)
            vel interpolate!(idealVel, alpha)
            body setVel(cpv(vel))
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

