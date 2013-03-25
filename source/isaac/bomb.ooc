

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

use bleep
import bleep

// sdk stuff
import structs/[ArrayList]

// our stuff
import isaac/[game, level, tear, shadow, explosion, freezer]


Bomb: class extends Entity {

    sprite: GlSprite

    body: CpBody
    shape: CpShape

    countdown: Int
    maxCountdown := 120

    bombHeroHandler: static CollisionHandler

    gracePeriod := 10

    // SFX
    bombDrop: static Sample

    init: func (.level, .pos) {
        super(level, pos)

        sprite = GlSprite new("assets/png/bomb.png")
        level charGroup add(sprite)

        countdown = maxCountdown

        initPhysx()
        initSamples()
        playDrop()
    }

    initSamples: func {
        if (!bombDrop) {
            bombDrop = level game bleep loadSample("assets/wav/bomb-drop.wav")
        }
    }

    playDrop: func {
        bombDrop play(0)
    }

    update: func -> Bool {
        sprite sync(body)
        pos set!(body getPos())

        if (gracePeriod > 0) {
            gracePeriod -= 1
        }

        countdown -= 1
        if (countdown <= 0) {
            explode()
            return false
        }

        yellowish := false
        redish := false

        if (countdown < 40) {
            if (countdown % 5 == 0) {
                yellowish = true
            }
            if (countdown % 4 == 0) {
                redish = true
            }
        } else {
            if (countdown % 12 == 0) {
                yellowish = true
            }
            if (countdown % 13 == 0) {
                redish = true
            }
        }

        sprite color set!(255, 255, 255)
        if (yellowish) {
            sprite color b = 30
        }
        if (redish) {
            sprite color g = 30
            sprite color b = 30
        }

        // friction
        {
            friction := 0.9
            vel := body getVel()
            vel x *= friction
            vel y *= friction
            body setVel(vel)
        }

        true
    }

    explode: func {
        level add(Explosion new(level, sprite pos))
    }

    bombHarm: func (explosion: Explosion) {
        if (countdown > 5) {
            countdown = 5
        }
    }

    destroy: func {
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
    }

    initPhysx: func {
        mass := 4.0
        radius := 23.0

        moment := cpMomentForCircle(mass, 0, radius, cpv(radius, radius))

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        shape = CpCircleShape new(body, radius, cpv(0, 0))
        shape setUserData(this)
        shape setCollisionType(CollisionTypes BOMB)
        shape setElasticity(0.6)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        if (!bombHeroHandler) {
            bombHeroHandler = BombHeroHandler new()
        }
        bombHeroHandler ensure(level)
    }

    shouldFreeze: func -> Bool {
        true
    }

}

BombHeroHandler: class extends CollisionHandler {

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        bomb := shape1 getUserData() as Bomb
        if (bomb gracePeriod > 0) {
            return false
        }

        true
    }

    add: func (f: Func(Int, Int)) {
        f(CollisionTypes BOMB, CollisionTypes HERO)
    }

}



