
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
import isaac/[level, explosion, tear, hero, walls, tiles]

/*
 * Any type of enemy
 */
Enemy: abstract class extends Entity {

    life := 10.0

    z := 0.0

    damageCount := 0
    damageLength := 12

    shape: CpShape
    body: CpBody
    rotateConstraint: CpConstraint

    hitbackSpeed := 200
    
    redish: Bool

    heroHandler, wallsHandler, blockHandler: static CollisionHandler

    init: func (.level, .pos) {
        super(level, pos)

        initHandlers()
    }

    /* DAMAGE STUFF
    ===========================*/

    harm: func (damage: Float) {
        if (damageCount <= 0) {
            damageCount = damageLength
            life -= damage
        }
    }

    bombHarm: func (explosion: Explosion) {
        harm(explosion damage)            
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

    /* UPDATE STUFF
    ===========================*/

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

        if (redish) {
            setColor(255, 30, 30)
        } else {
            setColor(255, 255, 255)
        }

        if (life <= 0.1) {
            onDeath()
            return false
        }

        true
    }

    /* SPRITE STUFF
    ===========================*/

    setOpacity: abstract func (opacity: Float)

    setColor: abstract func (r, g, b: Int)

    /* FLYING STUFF
    ===========================*/

    grounded?: func -> Bool {
        z < level groundLevel
    }

    /* COLLISION STUFF
    ===================== */

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

    /* PROPERTIES STUFF
    ===================== */

    fixed?: func -> Bool {
        // override for stuff like sacks etc.
        false
    }

    blocksRoom?: func -> Bool {
        // override to false for stuff like grimaces, slides and poky
        true
    }

    /* PHYSICS STUFF
    =======================*/

    createBody: func (mass, moment: Float) {
        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)
    }

    createBox: func (width, height: Float, mass: Float) {
        moment := cpMomentForBox(mass, width, height)
        createBody(mass, moment)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes ENEMY)
        level space addShape(shape)

        createConstraint()
    }

    createConstraint: func {
        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)
    }

    destroy: func {
        level space removeShape(shape)
        shape free()

        level space removeConstraint(rotateConstraint)
        rotateConstraint free()

        level space removeBody(body)
        body free()
    }

    /* SPAWN STUFF
     ======================*/

    spawnPlusTears: func (fireSpeed: Float) {
        spawnTear(pos, vec2(-1, 0), fireSpeed)
        spawnTear(pos, vec2(1, 0), fireSpeed)
        spawnTear(pos, vec2(0, -1), fireSpeed)
        spawnTear(pos, vec2(0, 1), fireSpeed)
    }

    spawnTwoTears: func (pos, diff: Vec2, fireSpeed: Float) {
        angle := diff angle()
        spread := PI / 10.0
        a1 := angle += spread
        a2 := angle -= spread
        offset := 4.0

        pos1 := pos add(Vec2 fromAngle(a1 + PI / 2.0) mul(offset))
        spawnTear(pos1, Vec2 fromAngle(a1), fireSpeed)

        pos2 := pos add(Vec2 fromAngle(a2 - PI / 2.0) mul(offset))
        spawnTear(pos2, Vec2 fromAngle(a2), fireSpeed)
    }

    spawnTear: func (pos, dir: Vec2, fireSpeed: Float) {
        vel := dir mul(fireSpeed)
        tear := Tear new(level, pos, vel, TearType ENEMY, 1)
        level add(tear)
    }

}

Mob: class extends Enemy {

    sprite: GlSprite
    spriteGroup: GlGroup

    init: func (.level, .pos) {
        super(level, pos)
    }

    setOpacity: func (opacity: Float) {
        sprite opacity = opacity
    }

    setColor: func (r, g, b: Int) {
        sprite color set!(r, g, b)
    }

    update: func -> Bool {
        super()
    }

    loadSprite: func (name: String, =spriteGroup, scale := 1.0) {
        path := "assets/png/%s.png" format(name)
        sprite = GlSprite new(path)
        sprite pos set!(pos)
        sprite scale set!(scale, scale)
        spriteGroup add(sprite)
    }

    destroy: func {
        super()

        if (sprite && spriteGroup) {
            spriteGroup remove(sprite)
        }
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
        f(CollisionTypes ENEMY, CollisionTypes BLOCK)
    }

}

