
// third-party stuff
use dye
import dye/[core, math]

use gnaar
import gnaar/[utils, physics]

// sdk stuff
import math, math/Random

// our stuff
import isaac/[level, enemy, tear, utils, paths]

HopBehavior: class {

    level: Level
    enemy: Enemy

    // state
    fireCount := 20
    parabola: Parabola

    scale := vec2(1, 1) // you need to sync yourself. Dummy.
    baseSpeed := 230.0

    // adjustable parameters
    targetType := TargetType RANDOM

    speed := 230.0

    jumpCount := 30
    jumpCountMax := 35
    jumpCountWiggle := 5
    chosenJumpCountMax := 0

    jumpDistance := 180.0
    jumpDistanceWiggle := 10.0

    jumpHeight := 90.0
    radius := 250.0

    landListener: LandListener

    init: func (=enemy) {
        level = enemy level
    }

    onLand: func (f: Func) {
        landListener = LandListener new(f)
    }

    update: func {
        // handle height
        if (parabola) {
            enemy z = parabola eval()
            if (parabola done?()) {
                parabola = null
                if (landListener) {
                    landListener call()
                }
            }
        } else {
            if (jumpCount > 0) {
                jumpCount -= 1
            } else {
                jump()
            }
        }

        scale x = (0.6 + (0.4 * (1.0 - (enemy z / jumpHeight))))
        scale y = (1.3 - (0.3 * (1.0 - (enemy z / jumpHeight))))

        // friction
        if (enemy grounded?()) {
            friction := 0.9
            vel := enemy body getVel()
            vel x *= friction
            vel y *= friction
            enemy body setVel(vel)
        }

        enemy pos set!(enemy body getPos())
    }

    jump: func {
        jumpCount = jumpCountMax + Random randInt(0, jumpCountWiggle)
        chosenJumpCountMax = jumpCount

        number := Random randInt(0, 100)
        target := match {
            case (number < 50) =>
                Target choose(enemy pos, level, radius) add(Vec2 random(2))
            case =>
                enemy pos add(Vec2 random(100))
        }
        jumpSpeed := speed

        diff := target sub(enemy pos)
        norm := diff norm()

        if (norm > jumpDistanceWiggle) {
            norm = jumpDistance + Random randInt(0, jumpDistanceWiggle)
            diff = diff normalized() mul(norm)
        }

        factor := 0.7
        distSpeed := speed * factor

        if (norm < distSpeed) {
            jumpSpeed *= (norm / distSpeed)
        }

        enemy body setVel(cpv(diff normalized() mul(jumpSpeed)))

        parabola = Parabola new(jumpHeight, 60.0 * baseSpeed / speed)
        parabola incr = 1.0
    }

}

LandListener: class {

    f: Func

    init: func (=f)

    call: func { f() }

}

