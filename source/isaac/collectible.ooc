
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
import math/Random

// our stuff
import isaac/[game, hero, level, bomb, freezer, map, shadow, explosion,
    paths]

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

    shadow: Shadow
    shadowYOffset := 10
    shadowFactor := 0.5

    parabola: Parabola
    z := 0

    init: func (.level, .pos) {
        super(level, pos)

        sprite = GlSprite new(getSpritePath())
        level charGroup add(sprite)

        shadow = Shadow new(level, sprite width * shadowFactor)
        initPhysx()
    }

    catapult: func {
        parabola = Parabola new(30.0, 2.0, 0)

        speed := 150
        body setVel(cpv(Vec2 random(speed)))
    }

    getSpritePath: abstract func -> String

    update: func -> Bool {
        if (collected) {
            return false
        }

        if (parabola) {
            // handle height
            z = parabola eval()
            if (parabola done?()) {
                z = parabola bottom
                parabola = null
            }
        }

        pos set!(body getPos())
        sprite pos set!(pos x, pos y + yOffset + z)
        shadow setPos(pos sub(0, shadowYOffset))

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
        shadow destroy()
        
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
    }

    bombHarm: func (explosion: Explosion) {
        dir := pos sub(explosion pos) normalized()
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

        shadowYOffset = 3
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
        shadowFactor = 0.7
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

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        collectible := shape1 getUserData() as Collectible
        if (!collectible collected && collectible z <= 1.0) {
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

ChestType: enum {
    REGULAR
    GOLDEN
    RED
}

CollectibleChest: class extends Collectible {

    type: ChestType

    init: func (.level, .pos, =type) {
        super(level, pos)
    }

    getSpritePath: func -> String {
        "assets/png/collectible-chest.png"
    }

    updateGfx: func {
        // colors for different chest types
    }

    update: func -> Bool {
        if (collected) {
            spill()
            return false
        }

        super()
    }

    collect: func {
        level hero hitBack(pos)
    }

    spill: func {
        // TODO: other types of drops

        match type {
            case => spillRegular()
        }
    }

    spillRegular: func {
        numDrops := Random randInt(1, 2)

        pickups := 0

        for (i in 0..100) {
            if (pickups >= numDrops) break

            num := Random randInt(0, 100)
            if (num < 35) {
                // drop 1-3 coins
                pickups += 1
                numCoins := Random randInt(1, 3)
                spawnCoins(numCoins)
            } else if (num < 55) {
                if (Random randInt(0, 100) < 50) {
                    // 0.5 chance to get -1 pickup
                    pickups += 1
                }
            } else if (num < 70) {
                pickups += 1
                spawnKey()
            } else if (num < 71 && i == 0) {
                pickups += 1
                spawnChest(ChestType REGULAR)
            } else if (num < 72 && i == 0) {
                pickups += 1
                spawnChest(ChestType GOLDEN)
            } else {
                pickups += 1
                spawnBomb()
            }
        }
    }

    shouldFreeze: func -> Bool {
        true
    }

    freeze: func (ent: FrozenEntity) {
        ent put("type", type)
    }

    unfreeze: func (ent: FrozenEntity) {
        type = ent attrs get("type", ChestType)
        updateGfx()
    }

}

