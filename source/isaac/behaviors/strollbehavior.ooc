
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
    chargeSpeed := 200.0

    chargeDist := 4
    frontChargeDist := 6
    canCharge := true
    backSight := false
    flies := false

    init: func (=enemy) {
        level = enemy level
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
        idealVel := delta mul(charging?() ? chargeSpeed : speed)
        enemy body setVel(cpv(idealVel))
    }

    maybeCharge: func {
        snappedPos := level snappedPos(enemy pos)
        heroPos := level snappedPos(level hero pos)

        diffX := heroPos x - snappedPos x
        diffY := heroPos y - snappedPos y

        if (diffX == 0 || diffY == 0) {
            oppDir := Direction fromDelta(diffX, diffY)

            if (!backSight && oppDir isOpposed?(dir)) {
                return
            }

            threshold := chargeDist
            if (oppDir == dir) {
                threshold = frontChargeDist
            }

            if (diffX > chargeDist || diffX < -chargeDist || \
                diffY > chargeDist || diffY < -chargeDist) {
                return
            }

            if (!hasPath?(snappedPos, heroPos, oppDir)) {
                return
            }

            dir = oppDir
            state = StrollState CHARGE
            target = vec2(level hero pos)
        }
    }

    hasPath?: func (a, b: Vec2i, dir: Direction) -> Bool {
        coords := vec2i(a x, a y)
        delta := dir toDelta()

        foolproof := 28

        while (!coords equals?(b) && foolproof > 0) {
            if (!walkable?(coords)) {
                return false
            }

            coords add!(delta)
            foolproof -= 1
        }

        true
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
        state = StrollState STROLL
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


