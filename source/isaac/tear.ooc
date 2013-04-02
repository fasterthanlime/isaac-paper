

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
import structs/[ArrayList]
import math/Random

// our stuff
import isaac/[level, hero, splash, enemy, fire, tiles, tnt, game, shadow,
    explosion, paths]

Tear: class extends Entity {

    // state
    vel: Vec2
    travelled := 0.0
    prevPos := vec2(0, 0)

    body: CpBody
    shape: CpShape

    sprite: GlSprite

    contactLevel := 14.0
    z := 12.0
    zInitial := 12.0
    zIncrement := 0.4

    shadowYOffset := 8.0

    // adjustable properties
    range := 100.0
    radius := 1.0
    damage: Float

    type: TearType

    hit := false

    shadow: Shadow
    parabola: Parabola

    heroHandler, enemyHandler, blockHandler, fireHandler, ignoreHandler: static CollisionHandler

    fromEnemy := false

    init: func (.level, .pos, .vel, =type, =damage, =range) {
        super(level, pos)

        this vel = vec2(vel)

        sprite = GlSprite new("assets/png/tears-1.png")

        if (type == TearType IPECAC) {
            range *= 0.8
            parabola = Parabola new(60, range)
        }

        scale := 0.23
        if (type == TearType IPECAC) {
            scale = 0.29
        }

        sprite scale set!(scale, scale)
        radius = scale * (sprite width as Float) * 0.5

        level group add(sprite)

        initPhysx()

        prevPos set!(pos)

        shadow = Shadow new(level, radius * 2.0)

        if (type == TearType HERO) {
            playEmit()
        }

        match type {
            case TearType HERO =>
                sprite color set!(224, 248, 254)
            case TearType IPECAC =>
                sprite color set!(153, 235, 155)
            case TearType ENEMY =>
                sprite color set!(255, 168, 168)
        }
    }

    playEmit: func {
        level game playRandomSound("tear-emit", 3)
    }

    update: func -> Bool {
        pos set!(body getPos())

        // keep count of how far we've travelled to splash when over
        travelled += prevPos dist(pos)

        if (parabola) {
            z = parabola eval(travelled)
        } else {
            if (travelled >= (range - zInitial / zIncrement)) {
                z -= zIncrement
            }
        }

        sprite pos set!(pos x, pos y + z)
        shadow setPos(pos x, pos y - shadowYOffset)

        due := (z <= 0.1)
        if (parabola && !parabola done?()) {
            due = false
        }

        if (hit || due) {
            onDeath()
            return false
        }

        prevPos set!(pos)

        true
    }

    onDeath: func {
        match type {
            case TearType IPECAC =>
                explosion := Explosion new(level, sprite pos)
                explosion fromEnemy = fromEnemy
                level add(explosion)
            case =>
                level add(Splash new(level, sprite pos))
        }
    }

    initPhysx: func {
        mass := 2.0

        moment := cpMomentForCircle(mass, 0, 2.0, cpv(2.0, 2.0))

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        body setVel(cpv(vel))
        level space addBody(body)

        shape = CpCircleShape new(body, 2.0, cpv(0, 0))
        shape setUserData(this)
        shape setCollisionType(CollisionTypes TEAR)
        shape setGroup(CollisionGroups TEAR)
        shape setElasticity(0.8)
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

        shadow destroy()
    }

}

TearType: enum {
    HERO
    ENEMY
    IPECAC
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
            case TearType HERO || TearType IPECAC =>
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

        if (tear type == TearType IPECAC) {
            return false
        }

        entity := shape2 getUserData() as Entity

        match (tear type) {
            case TearType ENEMY =>
                bounce = false 
            case =>
                match entity {
                    case enemy: Enemy =>
                        if (enemy tearVulnerable?()) {
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
        if (tear z < tear contactLevel) {
            tear hit = true
        } else {
            return false
        }

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
    }

}

FireTearHandler: class extends CollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        bounce := true
        
        tear := shape1 getUserData() as Tear
        entity := shape2 getUserData() as Entity

        match (tear type) {
            case TearType HERO =>
                tear hit = true
                match entity {
                    case fire: Fire =>
                        fire harm(tear damage)
                }
                true
            case TearType ENEMY =>
                false
        }
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes TEAR, CollisionTypes FIRE)
        f(CollisionTypes TEAR, CollisionTypes BOMB)
    }

}

IgnoreTearHandler: class extends CollisionHandler {

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        logger warn("begin called in IgnoreTearHandler")
        false
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes TEAR, CollisionTypes COLLECTIBLE)
        f(CollisionTypes TEAR, CollisionTypes TRAP_DOOR)
        f(CollisionTypes TEAR, CollisionTypes HOLE)
        f(CollisionTypes TEAR, CollisionTypes SPIKES)
    }

}

