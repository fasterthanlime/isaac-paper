
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
import isaac/[game, hero, level, bomb, freezer]

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

    collectibleHandler: static CollisionHandler

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
        }
        collectibleHandler ensure(level)
    }

    destroy: func {
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
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
    worth: Int { get { getWorth() } } 

    init: func (.level, .pos, type := CoinType PENNY) {
        this type = type
        super(level, pos)
    }

    getWorth: func -> Int {
        match type {
            case CoinType DIME   => 10
            case CoinType NICKEL => 5
            case => 1
        }
    }

    getSpritePath: func -> String {
        // TODO: different colors for dime, nickel, etc.
        "assets/png/collectible-coin.png"
    }

    updateGfx: func {
        sprite setTexture(getSpritePath())
    }

    collect: func {
        level game heroStats pickupCoin(this)
    }

    shouldFreeze: func -> Bool {
        true
    }

    freeze: func (ent: FrozenEntity) {
        ent put("type", type)
    }

    unfreeze: func (ent: FrozenEntity) {
        type = ent attrs get("type", CoinType)
        updateGfx()
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
        // TODO: 1+1 free (double bombs)
        "assets/png/collectible-bomb.png"
    }

    updateGfx: func {
        sprite setTexture(getSpritePath())
    }

    collect: func {
        level game heroStats pickupBomb(this)
    }

    shouldFreeze: func -> Bool {
        true
    }

    freeze: func (ent: FrozenEntity) {
        ent put("type", type)
    }

    unfreeze: func (ent: FrozenEntity) {
        type = ent attrs get("type", BombType)
        updateGfx()
    }


}

CollectibleHeart: class extends Collectible {

    type: HeartType
    value: HeartValue

    init: func (.level, .pos, =type, =value) {
        super(level, pos)
        updateGfx()
    }

    getSpritePath: func -> String {
        match value {
            case HeartValue FULL =>
                "assets/png/collectible-heart.png"
            case =>
                "assets/png/collectible-half-heart.png"
        }
    }

    updateGfx: func {
        sprite setTexture(getSpritePath())

        match type {
            case HeartType RED =>
                sprite color set!(220, 0, 0)
            case HeartType SPIRIT =>
                sprite color set!(130, 130, 130)
            case HeartType ETERNAL =>
                sprite color set!(255, 255, 255)
        }
    }

    collect: func {
        if (!level game heroStats pickupHealth(this)) {
            // we did not get picked up!
            collected = false
        }
    }

    shouldFreeze: func -> Bool {
        true
    }

    freeze: func (ent: FrozenEntity) {
        ent put("type", type)
        ent put("value", value)
    }

    unfreeze: func (ent: FrozenEntity) {
        type = ent attrs get("type", HeartType)
        value = ent attrs get("value", HeartValue)
        updateGfx()
    }


}

HeartType: enum {
    RED
    SPIRIT
    ETERNAL
}

HeartValue: enum {
    EMPTY
    HALF
    FULL

    toInt: func -> Int {
        match this {
            case This FULL => 2
            case This HALF => 1
        }
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
        level game heroStats pickupKey(this)
    }

    shouldFreeze: func -> Bool {
        true
    }

}

CollectibleHeroHandler: class extends CollisionHandler {

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        collectible := shape1 getUserData() as Collectible
        if (!collectible collected) {
            collectible collected = true
            collectible collect()
        }

        // if we've been collected, ignore the collision
        // otherwise, move around
        !(collectible collected)
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes COLLECTIBLE, CollisionTypes HERO)
    }

}

