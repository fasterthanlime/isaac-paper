
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
    ballbehavior, tear]

DukeOfFlies: class extends Boss {

    init: func (.level, .pos) {
        super(level, pos)

        part := DukePart new(level, pos)
        level add(part)
        parts add(part)
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

    init: func (.level, .pos) {
        super(level, pos)

        life = 80.0

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

}
