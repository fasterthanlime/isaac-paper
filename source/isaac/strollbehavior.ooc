
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
import isaac/[game, level, utils, enemy, tiles]

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

    rotateConstraint: CpConstraint

    // state
    dir := Direction random()
    state := StrollState STROLL
    target: Vec2

    targetCounter := 0
    targetCounterMax := 30

    // adjustable stuff
    speed := 80.0
    chargeSpeed := 240.0
    canCharge := true
    backSight := false
    flies := false

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
        if (!target || reachedTarget?()) {
            targetCounter -= 1
            if (targetCounter <= 0) {
                targetCounter = targetCounterMax
                chooseTarget()
            }
        }

        if (canCharge && !charging?()) {
            maybeCharge()
        }

        delta := dir toDeltaFloat()
        idealVel := delta mul(speed)
        enemy body setVel(cpv(idealVel))
    }

    maybeCharge: func {
        snappedPos := level snappedPos(enemy pos)
        heroPos := level snappedPos(level hero pos)

        diffX := snappedPos x - heroPos x
        diffY := snappedPos y - heroPos y

        if (diffX == 0) {
            "Opportunity in X! diff = %d, %d" printfln(diffX, diffY)
        } else if (diffY == 0) {
            "Opportunity in Y! diff = %d, %d" printfln(diffX, diffY)
        }
    }

    reachedTarget?: func -> Bool {
        if (!charging?()) {
            threshold := 30.0
            dist := enemy pos dist(target)
            //"dist = %.2f" printfln(dist)
            if (dist < threshold) {
                return true // yes we did, brett.
            }
        }

        snappedPos := level snappedPos(enemy pos)
        next := snappedPos add(dir toDelta())
        walkable := walkable?(next)
        //"next = %s, walkable = %d" printfln(next toString(), walkable)

        !walkable
    }

    chooseTarget: func {
        candidate := Direction random()
        if (candidate == dir) {
            candidate = candidate next()
        }

        hw := headway(candidate)
        target = vec2(level gridPos(hw x, hw y))
        dir = candidate
    }

    headway: func (candidate: Direction) -> Vec2i {
        delta := candidate toDelta()
        coords := level snappedPos(enemy pos) 

        target := vec2i(coords)

        walking := true

        while (walkable?(coords) && walking) {
            target set!(coords)

            // 1/4 chance to stop here
            if (Random randInt(0, 100) < 25) {
                walking = false
            }

            coords add!(delta)
        }

        coords
    }

    walkable?: func ~coords (coords: Vec2i) -> Bool {
        walkable?(coords x, coords y)
    }

    walkable?: func (col, row: Int) -> Bool {
        if (!level tileGrid validCoords?(col, row)) {
            return false
        }

        tile := level tileGrid get(col, row)
        if (!tile) {
            return true
        }

        !obstacle?(tile)
    }

    obstacle?: func (tile: Tile) -> Bool {
        if (flies) {
            return false // there ain't nothing we cannot fly over
        }
    
        true // if we're on foot, everything is an obstacle
    }

    charging?: func -> Bool {
        state == StrollState CHARGE
    }

}


