
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
import isaac/[game, hero, walls]

Level: class {

    logger := static Log getLogger(This name)

    game: Game

    space: CpSpace
    physicSteps := 10

    entities := ArrayList<Entity> new()
    hero: Hero
    walls: Walls

    // layers
    group: GlGroup
    floorGroup: GlGroup
    holeGroup: GlGroup
    blockGroup: GlGroup
    doorGroup: GlGroup
    charGroup: GlGroup

    // grids
    holeGrid  := Grid<Hole> new()
    blockGrid := Grid<Block> new()

    dye: DyeContext { get { game dye } }
    input: Input { get { game dye input } }

    doorState := DoorState new()

    init: func (=game) {
        group = GlGroup new()

        initGroups()
        initPhysx()

        hero = Hero new(this, vec2(300, 300))
        walls = Walls new(this)

        for (col in 0..blockGrid width) {
            for (row in 0..blockGrid height) {
                if (Random randInt(0, 10) < 6) {
                    continue
                }
                blockGrid put(col, row, Block new(this))
            }
        }
    }

    initGroups: func {
        floorGroup = GlGroup new()
        group add(floorGroup)

        holeGroup = GlGroup new()
        group add(holeGroup)

        blockGroup = GlGroup new()
        group add(blockGroup)

        doorGroup = GlGroup new()
        group add(doorGroup)

        charGroup = GlGroup new()
        group add(charGroup)
    }

    initPhysx: func {
        space = CpSpace new()
    }

    add: func (e: Entity) {
        entities add(e)
    }

    updateEvents: func {

        // Hero movement
        dir := vec2(0, 0)
        if (input isPressed(KeyCode W)) {
            dir y = 1
        }
        if (input isPressed(KeyCode A)) {
            dir x = -1
        }
        if (input isPressed(KeyCode S)) {
            dir y = -1
        }
        if (input isPressed(KeyCode D)) {
            dir x = 1
        }
        hero move(dir)

        // Hero shots
        if (input isPressed(KeyCode RIGHT)) {
            hero shoot(Direction RIGHT)
        } else if (input isPressed(KeyCode DOWN)) {
            hero shoot(Direction DOWN)
        } else if (input isPressed(KeyCode UP)) {
            hero shoot(Direction UP)
        } else if (input isPressed(KeyCode LEFT)) {
            hero shoot(Direction LEFT)
        }
    }

    update: func {
        updatePhysics()
        updateEvents()

        updateLayers()

        hero update()

        iter := entities iterator()
        while (iter hasNext?()) {
            e := iter next()
            if (!e update()) {
                iter remove()
                e destroy()
            }
        }
    }

    updateLayers: func {
        holeGrid each(|h| h update())
        blockGrid each(|h| h update())
    }

    updatePhysics: func {
        timeStep: CpFloat = 1.0 / game loop fpsGoal
        realStep := timeStep / physicSteps as Float
        for (i in 0..physicSteps) {
            space step(realStep)
        }
    }

}

Entity: class {

    level: Level

    init: func (=level) {
    }

    update: func -> Bool {
        true
    }

    destroy: func {
    }

}

CollisionTypes: enum from Int {
    HEROES
    ENEMIES
    WALLS
}

Direction: enum {
    LEFT
    RIGHT
    UP
    DOWN

    toString: func -> String {
        match this {
            case This UP => "up"
            case This DOWN => "down"
            case This LEFT => "left"
            case This RIGHT => "right"
            case => "<unknown direction>"
        }
    }
}

DoorState: class {
    up: Bool
    left: Bool
    right: Bool
    down: Bool

    init: func

    operator == (other: This) -> Bool {
        up == other up && \
        down == other down && \
        left == other left && \
        right == other right
    }

    operator != (other: This) -> Bool {
        !(this == other)
    }
}

Grid: class {
    list: Tile[]

    width := 13
    height := 7

    origin := vec2(100, 100)
    blockSide := 50.0

    init: func {
        list = Tile[width * height] new()
    }

    _inside: func (col, row: Int) -> Bool {
        (col >= 0 && col < width && \
         row <= 0 && row < height)
    }

    _index: func (col, row: Int) -> Int {
        col  + row * width
    }

    put: func (col, row: Int, obj: Tile) {
        list[_index(col, row)] = obj
        obj setPos(origin add(vec2(col, row) mul(blockSide)))
    }

    get: func (col, row: Int) -> Tile {
        list[_index(col, row)]
    }

    each: func (f: Func(Tile)) {
        for (i in 0..list length) {
            obj := list[i]
            if (obj) {
                f(obj)
            }
        }
    }
}

Tile: abstract class extends Entity {

    sprite: GlSprite
    body: CpBody
    shape: CpShape
    side := 50

    init: func (.level) {
        super(level)
        sprite = GlSprite new(getSprite())
        getLayer() add(sprite)

        initPhysx()
    }

    initPhysx: func {
        body = CpBody new(INFINITY, INFINITY)
        level space addBody(body)

        shape = CpBoxShape new(body, side, side)
        shape setUserData(this)
        level space addShape(shape)
    }

    update: func -> Bool {
        sprite sync(body)

        true
    }

    destroy: func {
        getLayer() remove(sprite)
        level space removeShape(shape)
    }

    setPos: func (pos: Vec2) {
        sprite pos set!(pos)
        Game logger info("Moved shape to %s", pos _)
        body setPos(cpv(pos))
    }

    getSprite: abstract func -> String

    getLayer: abstract func -> GlGroup

}

Hole: class extends Tile {

    init: func (.level) {
        super(level)
    }

    getSprite: func -> String {
        "assets/png/hole.png"
    }

    getLayer: func -> GlGroup {
        level holeGroup
    }

}

Block: class extends Tile {

    init: func (.level) {
        super(level)
    }

    getSprite: func -> String {
        num := Random randInt(1, 3)
        "assets/png/block-%d.png" format(num)
    }

    getLayer: func -> GlGroup {
        level blockGroup
    }

}



