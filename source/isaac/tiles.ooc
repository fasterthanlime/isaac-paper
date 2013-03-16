
// third-party stuff
use chipmunk
import chipmunk

use dye
import dye/[core, math, input, sprite]

use gnaar
import gnaar/[utils]

use deadlogger
import deadlogger/[Log, Logger]

// sdk stuff
import structs/[List, ArrayList, HashMap]
import math/Random

// our stuff
import isaac/[game, hero, walls, hopper, bomb, rooms, enemy, map, level,
    hole]

Tile: abstract class extends Entity {

    posi: Vec2i
    sprite: GlSprite
    body: CpBody
    shape: CpShape
    side := 50
    padding := 8

    alive := true

    init: func (.level) {
        super(level, vec2(0, 0))
        sprite = GlSprite new(getSprite())
        getLayer() add(sprite)

        initPhysx()
    }

    initPhysx: func {
        body = CpBody new(INFINITY, INFINITY)

        radius := 0.5 * (side - padding)
        shape = CpCircleShape new(body, radius, cpv(0, 0))
        shape setUserData(this)
        level space addShape(shape)
    }

    update: func -> Bool {
        if (!alive) {
            return false
        }

        sprite sync(body)

        true
    }

    destroy: func {
        getLayer() remove(sprite)
        level space removeShape(shape)
        shape free()
        body free()
    }

    setPos: func (=posi, .pos) {
        this pos set!(pos)
        sprite pos set!(pos)
        body setPos(cpv(pos))
    }

    bombHarm: func (bomb: Bomb) {
        alive = false
    }

    getSprite: abstract func -> String

    getLayer: abstract func -> GlGroup

}

Block: class extends Tile {

    number: Int

    init: func (.level, =number) {
        super(level)
        shape setCollisionType(CollisionTypes BLOCK)
    }

    getSprite: func -> String {
        "assets/png/block-%d.png" format(number)
    }

    getLayer: func -> GlGroup {
        level blockGroup
    }

    bombHarm: func (bomb: Bomb) {
        super()

        maxRadius := 80.0
        dist := bomb pos dist(pos)
        if (dist > maxRadius) {
            return
        }

        angle := pos sub(bomb pos) angle() toDegrees()
        dir := match {
            case (angle > 45.0 && angle <= 135.0) =>
                Direction UP
            case (angle > 135.0 && angle <= 225.0) =>
                Direction LEFT
            case (angle > 225.0 && angle <= 315.0) =>
                Direction DOWN
            case (angle < 45.0 || angle > 315.0) =>
                Direction RIGHT
            case =>
                return // dafuk
                Direction LEFT
        }

        holePos := dir toDelta() add(posi)
        if (level tileGrid contains?(holePos x, holePos y)) {
            tile := level tileGrid get(holePos x, holePos y)
            match tile {
                case hole: Hole =>
                    // He's dead, jim
                    hole alive = false
            }
        }
    }

}

Poop: class extends Tile {

    maxLife, life: Float
    damageCount := 0

    init: func (.level) {
        super(level)
        shape setCollisionType(CollisionTypes BLOCK)

        maxLife = 12.0
        life = maxLife
    }

    getSprite: func -> String {
        "assets/png/poop.png"
    }

    getLayer: func -> GlGroup {
        level blockGroup
    }

    update: func -> Bool {
        sprite opacity = sprite opacity * 0.9 + (0.1 * (life / maxLife))

        if (damageCount > 0) {
            damageCount -= 1
        }

        if (life <= 0.0) {
            onDeath()
            return false
        }

        super()
    }

    onDeath: func {
        if (Random randInt(0, 100) < 20) {
            level tile room spawnCollectible(pos, level)
        }
    }

    harm: func (damage: Int) {
        if (damageCount <= 0) {
            life -= damage
            damageCount = 10
        }
    }

}
