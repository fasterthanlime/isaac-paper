
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
import isaac/[level, hero, utils, bomb, tear, freezer, map, explosion,
    game, plan]

/*
 * Pointy, shiny, spiky things.
 */
Spikes: class extends Entity {

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    sprite: GlSprite
    spikesHeroHandler: static CollisionHandler

    init: func (.level, .pos) {
        super(level, pos)

        sprite = GlSprite new(getSpritePath())
        level holeGroup add(sprite)

        sprite pos set!(pos)
        scale := 0.9
        sprite scale set!(scale, scale)

        initPhysx()
    }

    getSpritePath: func -> String {
        index := level game floor type level()
        match {
            case index < 3 =>
                "assets/png/spikes.png"
            case =>
                "assets/png/spikes-curvy.png"
        }
    }

    update: func -> Bool {
        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y)

        super()
    }

    initPhysx: func {
        (width, height) := (20, 20)

        body = CpBody new(INFINITY, INFINITY)
        bodyPos := cpv(pos)
        body setPos(bodyPos)
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes SPIKES)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        if (!spikesHeroHandler) {
            spikesHeroHandler = SpikesHeroHandler new()
        }
        spikesHeroHandler ensure(level)
    }

    destroy: func {
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
    }

    shouldFreeze: func -> Bool {
        true
    }

}

SpikesHeroHandler: class extends CollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        spikes := shape1 getUserData() as Spikes
        hero := shape2 getUserData() as Hero

        hero harmHero(2)
        false
    }

    add: func (f: Func(Int, Int)) {
        f(CollisionTypes SPIKES, CollisionTypes HERO)
    }

}



