

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
import isaac/[level, hero, splash, enemy, fire, tiles, tnt]

Tear: class extends Entity {

    range := 100.0
    radius := 1.0

    damage: Float

    vel: Vec2

    body: CpBody
    shape: CpShape

    sprite: GlSprite

    type: TearType

    hit := false

    heroHandler, enemyHandler, blockHandler, fireHandler, ignoreHandler: static CollisionHandler

    init: func (.level, .pos, .vel, =type, =damage) {
        super(level, pos)

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
        mass := 8.0

        moment := cpMomentForCircle(mass, 0, 2.0, cpv(2.0, 2.0))

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        body setVel(cpv(vel))
        level space addBody(body)

        shape = CpCircleShape new(body, radius, cpv(0, 0))
        shape setUserData(this)
        shape setCollisionType(CollisionTypes TEAR)
        shape setGroup(CollisionGroups TEAR)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        if (!heroHandler) {
            heroHandler = HeroTearHandler new()
        }
        heroHandler ensure(level)

        if (!enemyHandler) {
            enemyHandler = EnemyTearHandler new()
        }
        enemyHandler ensure(level)

        if (!blockHandler) {
            blockHandler = BlockTearHandler new()
        }
        blockHandler ensure(level)

        if (!ignoreHandler) {
            ignoreHandler = IgnoreTearHandler new()
        }
        ignoreHandler ensure(level)

        if (!fireHandler) {
            fireHandler = FireTearHandler new()
        }
        fireHandler ensure(level)
    }

    destroy: func {
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level group remove(sprite)
    }

}

TearType: enum {
    HERO
    ENEMY
}

HeroTearHandler: class extends CollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        bounce := true
        
        tear := shape1 getUserData() as Tear
        if (tear hit) {
            return false
        }

        match (tear type) {
            case TearType HERO =>
                bounce = false 
            case =>
                hero := shape2 getUserData() as Hero
                hero harmHero(tear damage as Int)
                tear hit = true
        }

        bounce
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes TEAR, CollisionTypes HERO)
    }

}

EnemyTearHandler: class extends CollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        bounce := true
        
        tear := shape1 getUserData() as Tear
        if (tear hit) {
            return false
        }

        entity := shape2 getUserData() as Entity

        match (tear type) {
            case TearType ENEMY =>
                bounce = false 
            case =>
                match entity {
                    case enemy: Enemy =>
                        if (enemy grounded?()) {
                            tear hit = true
                            enemy harm(tear damage)
                            enemy hitBack(tear)
                        } else {
                            bounce = false
                        }
                }
        }

        bounce
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes TEAR, CollisionTypes ENEMY)
    }

}

BlockTearHandler: class extends CollisionHandler {

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
            case tnt: TNT =>
                tnt harm(tear damage)
        }

        true
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes TEAR, CollisionTypes BLOCK)
        f(CollisionTypes TEAR, CollisionTypes WALL)
        f(CollisionTypes TEAR, CollisionTypes BOMB)
    }

}

FireTearHandler: class extends CollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        bounce := true
        
        tear := shape1 getUserData() as Tear

        match (tear type) {
            case TearType HERO =>
                tear hit = true
                fire := shape2 getUserData() as Fire
                fire harm(tear damage)
                true
            case TearType ENEMY =>
                false
        }
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes TEAR, CollisionTypes FIRE)
    }

}

IgnoreTearHandler: class extends CollisionHandler {

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        false
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes TEAR, CollisionTypes COLLECTIBLE)
        f(CollisionTypes TEAR, CollisionTypes TRAP_DOOR)
        f(CollisionTypes TEAR, CollisionTypes HOLE)
    }

}

