
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
import isaac/[level, hero, utils, bomb, freezer]

/*
 * Slowww is the tempo
 */
Cobweb: class extends Entity {

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    sprite: GlSprite

    webHeroHandler: static CollisionHandler

    alive := true

    init: func (.level, .pos) {
        super(level, pos)

        sprite = GlSprite new("assets/png/cobweb.png")
        sprite opacity = 0.5

        level webGroup add(sprite)
        sprite pos set!(pos)

        initPhysx()
    }

    update: func -> Bool {
        if (!alive) {
            return false
        }

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y)
        pos set!(body getPos())

        scale := 0.8
        sprite scale set!(scale, scale)

        super()
    }

    initPhysx: func {
        (width, height) := (40, 40)

        body = CpBody new(INFINITY, INFINITY)
        bodyPos := cpv(pos)
        body setPos(bodyPos)
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setSensor(true)
        shape setCollisionType(CollisionTypes COBWEB)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        if (!webHeroHandler) {
            webHeroHandler = WebHeroHandler new()
        }
        webHeroHandler ensure(level)
    }

    destroy: func {
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level webGroup remove(sprite)
    }

    harm: func (damage: Float) {
        // blah
    }

    bombHarm: func (bomb: Bomb) {
        alive = false
    }

    shouldFreeze: func -> Bool {
        true
    }

}

WebHeroHandler: class extends CollisionHandler {

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        delta(arbiter, 1)
    }

    separate: func (arbiter: CpArbiter, space: CpSpace) {
        delta(arbiter, -1)
    }

    delta: func (arbiter: CpArbiter, diff: Int) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        hero := shape2 getUserData() as Hero
        hero webCount += diff

        false
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes COBWEB, CollisionTypes HERO)
    }

}

