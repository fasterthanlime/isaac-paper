
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
import isaac/[level, explosion, tear, hero, walls, tiles]

/*
 * Any type of enemy
 */
Enemy: abstract class extends Entity {

    life := 10.0

    z := 0.0

    damageCount := 0
    damageLength := 20

    shape: CpShape
    body: CpBody

    hitbackSpeed := 200
    
    redish: Bool

    heroHandler, wallsHandler, blockHandler: static CollisionHandler

    init: func (.level, .pos) {
        super(level, pos)

        initHandlers()
    }

    harm: func (damage: Float) {
        if (damageCount <= 0) {
            damageCount = damageLength
            life -= damage
        }
    }

    bombHarm: func (explosion: Explosion) {
        harm(explosion damage)            
    }

    update: func -> Bool {
        if (damageCount > 0) {
            damageCount -= 1
            intval := damageCount / (damageLength * 0.4)
            if (intval % 2 == 0) {
                redish = true
            } else {
                redish = false
            }
        } else {
            redish = false
        }

        if (life <= 0.1) {
            onDeath()
            return false
        }

        true
    }

    setOpacity: abstract func (opacity: Float)

    grounded?: func -> Bool {
        z < level groundLevel
    }

    fixed?: func -> Bool {
        // override for stuff like sacks etc.
        false
    }

    hitBack: func (tear: Tear) {
        if (fixed?()) {
            return
        }

        // TODO: make blast dependant on tear damage
        bodyVel := body getVel()
        dir := pos sub(tear pos) normalized()
        vel := dir mul(hitbackSpeed)

        bodyVel x += vel x
        bodyVel y += vel y
        body setVel(bodyVel)
    }

    onDeath: func {
        // normally, die in peace
    }

    touchHero: func (hero: Hero) -> Bool {
        // override if the enemy doesn't hurt on touch
        // (most enemies do, though..)
        hero harmHero(1)
        true
    }

    touchWalls: func (door: Door) -> Bool {
        // most enemies stay within the wall & don't
        // do anything special there
        true
    }

    touchBlock: func (tile: Tile) -> Bool {
        // most enemies are constrained by blocks
        true
    }

    initHandlers: func {
        if (!heroHandler) {
            heroHandler = EnemyHeroHandler new()
        }
        heroHandler ensure(level)

        if (!wallsHandler) {
            wallsHandler = EnemyWallsHandler new()
        }
        wallsHandler ensure(level)

        if (!blockHandler) {
            blockHandler = EnemyBlockHandler new()
        }
        blockHandler ensure(level)
    }

    blocksRoom?: func -> Bool {
        // override to false for stuff like grimaces, slides and poky
        true
    }

}

Mob: class extends Enemy {

    sprite: GlSprite

    init: func (.level, .pos) {
        super(level, pos)
    }

    setOpacity: func (opacity: Float) {
        sprite opacity = opacity
    }

    update: func -> Bool {
        if (redish) {
            sprite color set!(255, 30, 30)
        } else {
            sprite color set!(255, 255, 255)
        }

        super()
    }

}

EnemyHeroHandler: class extends CollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        enemy := shape1 getUserData() as Enemy
        hero := shape2 getUserData() as Hero

        enemy touchHero(hero)
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes ENEMY, CollisionTypes HERO)
    }

}

EnemyWallsHandler: class extends CollisionHandler {

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        enemy := shape1 getUserData() as Enemy
        door := shape2 getUserData() as Door

        enemy touchWalls(door)
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes ENEMY, CollisionTypes WALL)
    }

}

EnemyBlockHandler: class extends CollisionHandler {

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        enemy := shape1 getUserData() as Enemy
        tile := shape2 getUserData() as Tile

        enemy touchBlock(tile)
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes ENEMY, CollisionTypes WALL)
    }

}

