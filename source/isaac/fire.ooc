
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
import isaac/[level, hero, utils, bomb, tear]

/*
 * The fire! It burns!
 */
Fire: class extends Entity {

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    spriteWood, spriteFlame: GlSprite

    fireHeroHandler: static CpCollisionHandler

    damageCount := 0
    damageCountMax := 20

    fireSpeed := 120.0

    alive := true

    life, maxLife: Float

    evil: Bool

    fireCount := 40
    maxFireCount := 90

    radius := 120.0

    init: func (.level, .pos, =evil) {
        super(level, pos)

        life = 20.0 + Random randInt(-5, 5) as Float
        maxLife = life

        spriteWood = GlSprite new("assets/png/fire-wood.png")
        spriteWood opacity = 0.9
        level charGroup add(spriteWood)

        spriteFlame = GlSprite new("assets/png/fire-flame.png")
        level charGroup add(spriteFlame)

        spriteFlame pos set!(pos)
        spriteWood pos set!(pos)

        initPhysx()
    }

    update: func -> Bool {
        if (!alive || life <= 2.0) {
            return false
        }

        if (damageCount > 0) {
            damageCount -= 1
        }

        bodyPos := body getPos()
        spriteFlame pos set!(bodyPos x, bodyPos y - 4)
        spriteWood pos set!(bodyPos x, bodyPos y)
        pos set!(body getPos())

        spriteFlame opacity = life / (maxLife + 2.0)
    
        scale := 0.2 + 0.6 * spriteFlame opacity
        spriteFlame scale set!(scale, scale) 

        if (evil) {
            spriteFlame color set!(220, 100, 30)
        } else {
            spriteFlame color set!(200, 200, 30)
        }

        if (evil) {
            dist := pos dist(level hero pos)
            if (dist < radius) {
                fireCount -= 1
                if (fireCount <= 0) {
                    fire()
                }
            } else {
                resetFireCount()
            }
        }

        super()
    }

    resetFireCount: func {
        fireCount = maxFireCount
    }

    fire: func {
        diff := level hero pos sub(pos) normalized()
        tear := Tear new(level, pos, diff mul(fireSpeed), TearType ENEMY, 1)
        level add(tear)
        resetFireCount()
    }

    initPhysx: func {
        (width, height) := (30, 30)

        body = CpBody new(INFINITY, INFINITY)
        bodyPos := cpv(pos)
        body setPos(bodyPos)
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes FIRE)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        if (!fireHeroHandler) {
            fireHeroHandler = FireHeroHandler new()
            level space addCollisionHandler(CollisionTypes FIRE, CollisionTypes HERO,
                fireHeroHandler)
        }
    }

    destroy: func {
        level space removeShape(shape)
        level space removeBody(body)
        level charGroup remove(spriteWood)
        level charGroup remove(spriteFlame)
    }

    harm: func (damage: Float) {
        if (damageCount <= 0) {
            damageCount = damageCountMax
            life -= damage
        }
    }

    bombHarm: func (bomb: Bomb) {
        alive = false
    }

}

FireHeroHandler: class extends CpCollisionHandler {

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
        hero harmHero(1)

        false
    }

}

