
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
import isaac/[level, shadow, enemy, hero, utils, paths, boss,
    ballbehavior, tear, explosion]

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

    update: func -> Bool {
        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y + 4 + z)
        pos set!(body getPos())
        shadow setPos(pos sub(0, shadowYOffset))

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
