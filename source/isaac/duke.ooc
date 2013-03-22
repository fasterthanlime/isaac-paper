
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
import structs/[ArrayList, List]

// our stuff
import isaac/[level, shadow, enemy, hero, utils, paths, boss,
    ballbehavior, tear, explosion, fly]

DukeOfFlies: class extends Boss {

    part: DukePart

    init: func (.level, .pos) {
        super(level, pos)

        part = DukePart new(level, pos)
        parts add(part)
    }

    maxHealth: func -> Float {
        part maxLife
    }

    onDeath: func {
        part releaseFlies()
    }

}

DukePart: class extends Mob {

    scale := 0.8

    shadow: Shadow
    shadowFactor := 0.7
    shadowYOffset := 50

    moveCount := 60
    moveCountMax := 80

    behavior: BallBehavior
    maxLife := 80.0

    maxFlies := 8
    flies := ArrayList<Fly> new()

    flyCounter := 0
    flyCounterThreshold := 60

    baseAngle := 0.0
    baseAngleIncr := 1.2
    flyRadius := 70.0
    maxSpawns := 3

    init: func (.level, .pos) {
        super(level, pos)

        life = maxLife

        sprite = GlSprite new(getSpritePath())
        sprite scale set!(scale, scale)
        shadow = Shadow new(level, sprite width * scale * shadowFactor)

        level charGroup add(sprite)
        sprite pos set!(pos)

        behavior = BallBehavior new(this)
        behavior speed = 80.0

        radius := 50.0
        mass := 400.0
        behavior initPhysx(radius, mass)
        shape setElasticity(0.4)

        collisionRadius := 60.0
    }

    hitBack: func (tear: Tear) {
        // we bounce naturally
    }

    getSpritePath: func -> String {
        "assets/png/duke-of-flies-frame1.png"
    }

    spawnFly: func (autonomous := false) {
        number := Random randInt(0, 100)
        type := match number {
            case number < 20 =>
                FlyType BIG_ATTACK_FLY
            case =>
                FlyType ATTACK_FLY
        }

        fly := Fly new(level, pos, type)
        if (autonomous) {
            level add(fly)
        } else {
            fly autonomous = false
            fly mover alpha = 0.5
            fly mover speed = 220
            flies add(fly)
        }
    }

    releaseFlies: func {
        // TODO: apply speed
        for (f in flies) {
            f autonomous = true
            f mover alpha = 0.95
            f mover speed = 70

            dir := f pos sub(pos) normalized()
            releaseSpeed := 300
            vel := dir mul(releaseSpeed)
            f body setVel(cpv(vel))

            level add(f)
        }
        flies clear()
    }

    updateFlies: func {
        fliesCount := flies size

        if (fliesCount < maxFlies) {
            if (flyCounter < flyCounterThreshold) {
                flyCounter += 1
            } else {
                burpChance := Random randInt(0, 100)

                spawnDefense := true

                if (fliesCount > 3) {
                    match {
                        case (burpChance < 20) =>
                            releaseFlies()
                            spawnDefense = false
                        case (burpChance < 40) =>
                            spawnFly(true)
                            spawnDefense = false
                        case =>
                            // all good
                            spawnDefense = true
                    }
                }

                if (spawnDefense) {
                    flyCounter = Random randInt(-20, 10)
                    numFlies := Random randInt(0, maxSpawns < maxFlies ? maxSpawns : maxFlies)

                    for (i in 0..numFlies) {
                        spawnFly()
                    }
                }
            }
        }
        fliesCount = flies size
    
        // TODO: specify target
        baseAngle += baseAngleIncr
        step := 360.0 / maxFlies as Float

        angle := baseAngle
        for (f in flies) {
            diff := Vec2 fromAngle(angle toRadians()) mul(flyRadius)
            flyPos := pos add(diff)
            angle += step
            f mover setTarget(flyPos)
        }

        level updateList(flies)
    }

    update: func -> Bool {
        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 4 + z)
        pos set!(body getPos())
        shadow setPos(pos sub(0, shadowYOffset))

        updateFlies()

        behavior update()

        super()
    }

    destroy: func {
        shadow destroy()
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
    }

    bombHarm: func (explosion: Explosion) {
        harm(explosion damage * 5)
    }

}
