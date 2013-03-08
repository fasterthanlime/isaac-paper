
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

    init: func (.level, .pos) {
        super(level, pos)

        sprite = GlSprite new(getSpritePath())
        level charGroup add(sprite)

        initPhysx()
    }

    getSpritePath: abstract func -> String

    update: func -> Bool {
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

}

CoinType: enum {
    PENNY
    NICKEL
    DIME
}

CollectibleCoin: class extends Collectible {

    init: func (.level, .pos) {
        super(level, pos)
    }

    // TODO: other coin types
    type := CoinType PENNY

    getSpritePath: func -> String {
        "assets/png/collectible-coin.png"
    }

}

BombType: enum {
    ONE
    TWO
}

CollectibleBomb: class extends Collectible {

    init: func (.level, .pos) {
        radius = 20.0

        super(level, pos)

        scale := 0.9
        sprite scale set!(scale, scale)
    }

    // TODO: other coin types
    type := BombType ONE

    getSpritePath: func -> String {
        "assets/png/collectible-bomb.png"
    }

}

CollectibleKey: class extends Collectible {

    init: func (.level, .pos) {
        super(level, pos)
    }

    getSpritePath: func -> String {
        "assets/png/collectible-key.png"
    }

}

