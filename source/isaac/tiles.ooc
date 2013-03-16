
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
import isaac/[game, hero, walls, hopper, bomb, rooms, enemy, map, level]

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
