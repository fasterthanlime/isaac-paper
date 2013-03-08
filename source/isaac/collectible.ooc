
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
import isaac/[level, bomb]

/**
 * All that can be picked up
 */
Collectible: abstract class extends Entity {

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    sprite: GlSprite

    mass := 10.0
    radius := 15.0

    friction := 0.95

    yOffset := 5

    collected := false

    collectibleHandler: static CpCollisionHandler

    init: func (.level, .pos) {
        super(level, pos)

        sprite = GlSprite new(getSpritePath())
        level charGroup add(sprite)

        initPhysx()
    }

    getSpritePath: abstract func -> String

    update: func -> Bool {
        if (collected) {
            return false
        }

        pos set!(body getPos())
        sprite pos set!(pos x, pos y + yOffset)

        // friction
        vel := body getVel()
        vel x *= friction
        vel y *= friction
        body setVel(vel)

        true
    }

    initPhysx: func {
        moment := cpMomentForCircle(mass, radius, 0, cpv(radius, radius))
        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        shape = CpCircleShape new(body, radius, cpv(0, 0))
        shape setUserData(this)
        shape setCollisionType(CollisionTypes COLLECTIBLE)
        shape setGroup(CollisionGroups COLLECTIBLE)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        if (!collectibleHandler) {
            collectibleHandler = CollectibleHeroHandler new()
            level space addCollisionHandler(CollisionTypes COLLECTIBLE,
                CollisionTypes HERO, collectibleHandler)
        }
    }

    destroy: func {
        level space removeShape(shape)
        level space removeBody(body)
        level charGroup remove(sprite)
    }

    bombHarm: func (bomb: Bomb) {
        dir := pos sub(bomb pos) normalized()
        explosionSpeed := 400
        vel := dir mul(explosionSpeed)
        body setVel(cpv(vel))
    }

    // well, what happens now?
    collect: abstract func
}

CoinType: enum {
    PENNY
    NICKEL
    DIME
}

CollectibleCoin: class extends Collectible {

    type: CoinType
    worth: Int

    init: func (.level, .pos, type := CoinType PENNY) {
        this type = type
        worth = match type {
            case CoinType DIME   => 10
            case CoinType NICKEL => 5
            case => 1
        }

        super(level, pos)
    }

    getSpritePath: func -> String {
        "assets/png/collectible-coin.png"
    }

    collect: func {
        level game pickupCoin(this)
    }

}

BombType: enum {
    ONE
    TWO
}

CollectibleBomb: class extends Collectible {

    type: BombType
    worth: Int

    init: func (.level, .pos, type := BombType ONE) {
        radius = 20.0
        this type = type
        worth = match type {
            case BombType TWO => 2
            case => 1
        }

        super(level, pos)

        scale := 0.9
        sprite scale set!(scale, scale)
    }

    getSpritePath: func -> String {
        "assets/png/collectible-bomb.png"
    }

    collect: func {
        level game pickupBomb(this)
    }

}

CollectibleKey: class extends Collectible {

    init: func (.level, .pos) {
        super(level, pos)
    }

    getSpritePath: func -> String {
        "assets/png/collectible-key.png"
    }

    collect: func {
        level game pickupKey(this)
    }

}

CollectibleHeroHandler: class extends CpCollisionHandler {

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        collectible := shape1 getUserData() as Collectible
        if (!collectible collected) {
            collectible collected = true
            collectible collect()
        }

        false
    }

}

