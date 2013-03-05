

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
import isaac/[level, hero, splash]


Tear: class extends Entity {

    range := 100.0
    radius := 1.0

    damage: Float

    pos, vel: Vec2

    body: CpBody
    shape: CpShape

    sprite: GlSprite

    type: TearType

    hit := false

    heroHandler, enemyHandler, blockHandler: static CpCollisionHandler

    init: func (.level, .pos, .vel, =type, =damage) {
        super(level)

        this pos = vec2(pos)
        this vel = vec2(vel)

        sprite = GlSprite new("assets/png/tears-1.png")

        scale := 0.3
        sprite scale set!(scale, scale)
        radius = scale * (sprite width as Float) * 0.5

        level group add(sprite)

        initPhysx()
    }

    update: func -> Bool {
        sprite sync(body)

        if (hit) {
            level add(Splash new(level, sprite pos))
            return false
        }

        true
    }

    initPhysx: func {
        mass := 2.0

        moment := cpMomentForCircle(mass, 0, radius, cpv(radius, radius))

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        body setVel(cpv(vel))
        level space addBody(body)

        shape = CpCircleShape new(body, radius, cpv(0, 0))
        shape setUserData(this)
        shape setCollisionType(CollisionTypes TEAR)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        if (!heroHandler) {
            heroHandler = HeroTearHandler new()
            level space addCollisionHandler(CollisionTypes TEAR, CollisionTypes HERO, heroHandler)
        }

        if (!enemyHandler) {
            enemyHandler = EnemyTearHandler new()
            level space addCollisionHandler(CollisionTypes TEAR, CollisionTypes ENEMY, enemyHandler)
        }

        if (!blockHandler) {
            blockHandler = BlockTearHandler new()
            level space addCollisionHandler(CollisionTypes TEAR, CollisionTypes BLOCK, blockHandler)
            level space addCollisionHandler(CollisionTypes TEAR, CollisionTypes WALL, blockHandler)
        }
    }

    destroy: func {
        level space removeShape(shape)
        level space removeBody(body)
        level group remove(sprite)
    }

}

TearType: enum {
    HERO
    ENEMY
}

HeroTearHandler: class extends CpCollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        bounce := true
        
        tear := shape1 getUserData() as Tear
        match (tear type) {
            case TearType HERO =>
               bounce = false 
            case =>
                tear hit = true
        }

        bounce
    }

}

EnemyTearHandler: class extends CpCollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        bounce := true
        
        tear := shape1 getUserData() as Tear
        match (tear type) {
            case TearType ENEMY =>
               bounce = false 
            case =>
                tear hit = true
        }

        bounce
    }

}

BlockTearHandler: class extends CpCollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        bounce := true
        
        tear := shape1 getUserData() as Tear
        tear hit = true

        tile := shape2 getUserData() as Tile
        match tile {
            case poop: Poop =>
                poop harm(tear damage)
        }

        true
    }

}

