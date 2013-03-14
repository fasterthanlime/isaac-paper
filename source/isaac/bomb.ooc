

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

// our stuff
import isaac/[level, tear, shadow, explosion, freezer]


Bomb: class extends Entity {

    sprite: GlSprite

    body: CpBody
    shape: CpShape

    countdown: Int
    maxCountdown := 120

    radius := 40
    explosionRadius := 105.0

    damage := 20

    init: func (.level, .pos) {
        super(level, pos)

        sprite = GlSprite new("assets/png/bomb.png")
        level charGroup add(sprite)

        countdown = maxCountdown

        initPhysx()
    }

    update: func -> Bool {
        sprite sync(body)
        pos set!(body getPos())

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

        // explode here
        level eachInRadius(pos, explosionRadius, |ent|
            ent bombHarm(this)
        )
    }

    destroy: func {
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
    }

    initPhysx: func {
        mass := 20.0
        radius := 8.0

        moment := cpMomentForCircle(mass, 0, radius, cpv(radius, radius))

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        shape = CpCircleShape new(body, radius, cpv(0, 0))
        shape setUserData(this)
        shape setCollisionType(CollisionTypes BOMB)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        // TODO: ignore collisions with some stuff?
    }

    shouldFreeze: func -> Bool {
        true
    }

}
