
// third-party stuff
use dye
import dye/[math]

use chipmunk
import chipmunk

use gnaar
import gnaar/[utils]

// sdk stuff
import math/Random
import structs/[ArrayList]

// our stuff
import isaac/[level, hero, level]

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

    level: Level

    radius := 20.0

    target: Vec2
    body: CpBody
    speed: Float
    alpha := 0.95

    moving := false

    cellPath: ArrayList<Vec2i>

    init: func (=level, =body, =speed) {
        target = vec2(body getPos())
    }

    update: func (pos: Vec2) {
        dist := pos dist(target)
        if (moving && dist > radius) {
            vel := vec2(body getVel())
            idealVel := target sub(pos) normalized() mul(speed)
            vel interpolate!(idealVel, 1 - alpha)
            body setVel(cpv(vel))
        } else {
            if (cellPath) {
                popPath()
            } else {
                stop()
            }
        }
    }

    setCellPath: func (=cellPath) {
        popPath()
    }

    popPath: func {
        if (cellPath empty?()) {
            cellPath = null
        } else {
            posi := cellPath removeAt(0)
            //"Next stop: %s" printfln(posi _)
            setTarget(level gridPos(posi x, posi y))
        }
    }

    stop: func {
        moving = false
        // friction
        friction := 0.8
        vel := body getVel()
        vel x *= friction
        vel y *= friction
        body setVel(vel)
    }

    setTarget: func (=target) {
        moving = true
    }

}

