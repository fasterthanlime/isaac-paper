

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

// sdk stuff
import math, math/Random

// our stuff
import isaac/[game, level, paths, shadow, enemy, hero, utils, tear]

FlyType: enum {
    ATTACK_FLY
    BIG_ATTACK_FLY
    BLACK_FLY
    MOTER
    POOTER 
    FAT_FLY
    SUCKER
    SPIT
}

/*
 * Bzzzzzz
 */
Fly: class extends Mob {

    moveCount := 0
    moveCountMax := 30

    radius := 600.0
    speedyRadius := 280.0

    scale := 0.8

    shadow: Shadow

    mover: Mover

    type: FlyType

    fireRadius := 350.0
    fireSpeed := 280.0

    fireCount := 40
    maxFireCount := 60

    sinus := Sinus new(2.0)

    rosish := false
    rosishCount := 0
    rosishCountMax := 25

    autonomous := true

    moverSpeed := 80.0

    init: func (.level, .pos, =type) {
        super(level, pos)

        match type {
            case FlyType BLACK_FLY =>
                life = 2.0
            case FlyType ATTACK_FLY =>
                life = 6.0
            case FlyType BIG_ATTACK_FLY =>
                life = 12.0
                scale := 1.4
            case FlyType MOTER =>
                life = 14.0
            case =>
                life = 8.0
        }

        if (attackFly?()) {
            moverSpeed = 110.0
        }

        sinus incr = 0.15

        loadSprite(getSpriteName(), level charGroup, scale)

        factor := 0.2

        if (type == FlyType FAT_FLY) {
            factor = 0.4
        }
        shadow = Shadow new(level, sprite width * scale * factor)

        createBox(15, 15, 15.0)
        shape setSensor(true)

        mover = Mover new(level, body, 70.0)
    }

    getSpriteName: func -> String {
        match type {
            case FlyType POOTER =>
                "pooter"
            case FlyType FAT_FLY =>
                "fat-fly"
            case FlyType SUCKER || FlyType SPIT =>
                "sucker-spit"
            case FlyType MOTER =>
                "moter"
            case FlyType ATTACK_FLY || FlyType BIG_ATTACK_FLY =>
                "attack-fly"
            case =>
                "black-fly"
        }
    }

    attackFly?: func -> Bool {
        match type {
            case FlyType ATTACK_FLY || FlyType BIG_ATTACK_FLY || FlyType MOTER =>
                // moters also blink and also zero in on
                // isaac so, it's all good. 
                true
            case =>
                false
        }
    }

    spawnAttackFly: func (pos: Vec2) {
        fly := Fly new(level, pos, FlyType ATTACK_FLY)
        level add(fly)
    }

    onDeath: func {
        match type {
            case FlyType MOTER =>
                // spawn two of our children!
                spread := 5.0
                spawnAttackFly(pos add(-spread, 0.0))
                spawnAttackFly(pos add( spread, 0.0))
            case FlyType SUCKER =>
                // spawn tears in the shape of a '+'
                spawnPlusTears(fireSpeed)
        }
    }

    update: func -> Bool {
        z = 5.0 + sinus eval()

        if (autonomous) {
            if (moveCount > 0) {
                moveCount -= 1
            } else {
                updateTarget()
            }
        }
        mover update(pos)

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 8 + z)
        pos set!(body getPos())
        shadow setPos(pos x, pos y - 3)

        if (fires?()) {
            dist := pos dist(level hero pos)
            if (dist < fireRadius) {
                fireCount -= 1
                if (fireCount <= 0) {
                    fire()
                }
            } else {
                resetFireCount()
            }
        }

        if (attackFly?()) {
            rosishCount -= 1
            if (rosishCount <= 0) {
                rosishCount = rosishCountMax
                rosish = !rosish
            }
        }

        retVal := super()

        if (rosish && !redish) {
            sprite color set!(255, 140, 140)
        }

        retVal
    }

    grounded?: func -> Bool {
        // kinda..
        true
    }

    fires?: func -> Bool {
        match type {
            case FlyType POOTER || FlyType FAT_FLY =>
                true
            case =>
                false
        }
    }

    fire: func {
        diff := level hero pos sub(pos) normalized()
        match type {
            case FlyType POOTER =>
                spawnTear(pos, diff, fireSpeed)
            case FlyType FAT_FLY =>
                spawnTwoTears(pos, diff, fireSpeed)
        }

        resetFireCount()
    }

    resetFireCount: func {
        fireCount = maxFireCount + Random randInt(-10, 20)
    }

    aggressive?: func -> Bool {
        type == FlyType ATTACK_FLY || FlyType BIG_ATTACK_FLY
    }

    updateTarget: func {
        if (aggressive?()) {
            tracks := true
            if (Random randInt(0, 8) < 3) {
                // sometimes, rarely, we just decide to leave
                // poor isaac alone.
                tracks = false
            }
            target := Target choose(pos, level, radius, tracks)

            clumsy := (Random randInt(0, 8) < 3)
            if (clumsy) {
                // woops, we can't aim very well, can we?
                clumsyRadius := Random randInt(-8, 8) as Float
                target = target add(Target direction() mul(clumsyRadius))
            }
            mover setTarget(target)

            dist := level hero pos dist(pos)
            if (dist < speedyRadius) {
                mover speed = Random randInt(130, 170) as Float
                moveCount = Random randInt(20, 40)
            } else {
                resetSpeedAndCount()
            }
        } else {
            // don't track hero, we're just moving around
            mover setTarget(Target choose(pos, level, radius, false))
            resetSpeedAndCount()
        }
    }
    
    resetSpeedAndCount: func {
        mover speed = moverSpeed
        moveCount = moveCountMax + Random randInt(-10, 40)
    }

    destroy: func {
        shadow destroy()
        super()
    }

    touchHero: func (hero: Hero) -> Bool {
        if (type == FlyType BLACK_FLY) {
            // we're innocuous
            return true
        }

        // TODO: fly love
        super(hero)
    }

}

