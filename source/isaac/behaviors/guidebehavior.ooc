
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
import isaac/[game, level, utils, enemy, paths, pathfinding]


/**
 * Mullis & friends have a guide behavior
 */
GuideBehavior: class {

    level: Level
    enemy: Enemy

    mover: Mover

    // adjustable properties
    speed: Float
    moveCount := 0
    flee := false
    fleeRadius := 400

    init: func (=enemy, =speed) {
        level = enemy level

        mover = Mover new(level, enemy body, speed)
        mover alpha = 0.9
    }

    update: func (targetPos: Vec2) {
        // the mover does the actual work, sync speed
        mover speed = speed

        if (moveCount > 0) {
            moveCount -= 1
            if (!flee && !mover moving) {
                moveCount = 0
            }
        } else {
            updateTarget(targetPos)
        }

        mover update(enemy pos)
    }

    updateTarget: func (targetPos: Vec2) {
        pos := enemy pos

        if (flee) {
            diff := pos sub(targetPos)
            if (diff norm() < fleeRadius) {
                dist := 80.0

                fleeDiff := diff normalized() mul(dist)
                target := pos add(fleeDiff)
                if (!target inside?(level paddedBottomLeft, level paddedTopRight)) {
                    // we're trapped! Let's rush on him 
                    target = pos sub(fleeDiff)
                }

                a := level snappedPos(pos)
                b := level snappedPos(target)
                b = b clamp(level gridBottomLeft, level gridTopRight)

                //"Trying to go from %s to %s!" printfln(a _, b _)
                finder := PathFinder new(level, a, b)

                if (finder path) {
                    mover setCellPath(finder path)
                } else {
                    //"No path to flee from %s to %s!" printfln(a _, b _)
                    moveCount = 60
                }
                moveCount = 40 + Random randInt(-10, 20)
            } else {
                mover setTarget(targetPos add(Vec2 random(40)))
                moveCount = 20
            }
        } else {
            a := level snappedPos(pos)
            b := level snappedPos(targetPos)
            finder := PathFinder new(level, a, b)
            
            if (finder path) {
                // remove first component in path, it's
                // a snapped version of ourselves
                finder path removeAt(0)
                mover setCellPath(finder path)
                moveCount = 60
            } else {
                mover setTarget(pos)
                moveCount = 30
            }
        }
    }

}
