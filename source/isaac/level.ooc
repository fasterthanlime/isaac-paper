
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
import isaac/[game, hero, walls, hopper, bomb, rooms, enemy, map, tiles]

Level: class {

    logger := static Log getLogger(This name)

    game: Game

    space: CpSpace
    physicSteps := 10

    // when locked, some operations are buffered
    locked := false
    addCount := 0
    removeCount := 0

    // actual entity list
    entities := ArrayList<Entity> new()

    // buffers
    addBuffer := ArrayList<Entity> new()

    hero: Hero
    walls: Walls

    // layers
    group: GlGroup
    floorGroup: GlGroup
    holeGroup: GlGroup
    blockGroup: GlGroup
    webGroup: GlGroup
    doorGroup: GlGroup
    shadowGroup: GlGroup
    charGroup: GlGroup

    // a few reference points
    bottomLeft := vec2(75, 75)
    topRight := vec2(725, 425)

    paddedBottomLeft := vec2(100, 100)
    paddedTopRight := vec2(700, 400)

    groundLevel := 3.0

    // grids
    tileGrid := Grid<Tile> new()

    dye: DyeContext { get { game dye } }
    input: Input { get { game dye input } }

    cleared := false

    tile: MapTile

    init: func (=game, =tile) {
        group = GlGroup new()

        initGroups()
        initPhysx()

        hero = Hero new(this, getHeroStartPos(), game heroStats)
        walls = Walls new(this)

        tile unfurl(this)
        walls setup()
    }
    
    gridPos: func (x, y: Int) -> Vec2 {
        vec2(paddedBottomLeft x + 50.0 * x,
             paddedBottomLeft y + 50.0 * y)
    }

    destroy: func {
        tileGrid clear()

        iter := entities iterator()
        while (iter hasNext?()) {
            e := iter next()
            iter remove()
            removeCount += 1
            e destroy()
        }
        space free()

        logger debug("Finished destroying, add / remove = %d / %d",
            addCount, removeCount)
    }

    getHeroStartPos: func -> Vec2 {
        vec2(300, 300)
    }

    initGroups: func {
        floorGroup = GlGroup new()
        group add(floorGroup)

        holeGroup = GlGroup new()
        group add(holeGroup)

        blockGroup = GlGroup new()
        group add(blockGroup)

        webGroup = GlGroup new()
        group add(webGroup)

        doorGroup = GlGroup new()
        group add(doorGroup)

        shadowGroup = GlGroup new()
        group add(shadowGroup)

        charGroup = GlSortedGroup new()
        group add(charGroup)
    }

    initPhysx: func {
        space = CpSpace new()
    }

    add: func (e: Entity) {
        addCount += 1
        if (locked) {
            addBuffer add(e)
        } else {
            entities add(e)
        }
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

    cleared?: func -> Bool {
        if (!cleared) {
            cleared = (blockingEnemyCount() <= 0)
        }

        cleared
    }

    blockingEnemyCount: func -> Int {
        count := 0

        for (e in entities) {
            match e {
                case enemy: Enemy =>
                    if (enemy blocksRoom?()) {
                        count += 1
                    }
            }
        }

        count
    }

    update: func {
        updatePhysics()
        updateEvents()

        updateLayers()

        locked = true
        hero update()
        walls update()

        iter := entities iterator()
        while (iter hasNext?()) {
            e := iter next()
            if (!e update()) {
                removeCount += 1
                logger debug("Destroying object %p (it's a %s) - add %d, remove %d",
                    e, e class name, addCount, removeCount)
                iter remove()
                e destroy()
            }
        }
        locked = false

        if (!addBuffer empty?()) {
            logger debug("Adding %d objects", addBuffer size)
            entities addAll(addBuffer)
            addBuffer clear()
        }
    }

    updateLayers: func {
        updateGrid(tileGrid)
    }

    updateGrid: func (grid: Grid) {
        grid each(|col, row, h|
            if (!h update()) {
                grid remove(col, row)
            }
        )
    }

    updatePhysics: func {
        timeStep: CpFloat = 1.0 / game loop fpsGoal
        realStep := timeStep / physicSteps as Float
        for (i in 0..physicSteps) {
            space step(realStep)
        }
    }

    eachInRadius: func (pos: Vec2, radius: Float, f: Func (Entity)) {
        test := func (e: Entity) {
            eRadius := pos dist(e pos)
            if (eRadius <= radius) {
                f(e)
            }
        }

        for (e in entities) {
            test(e)
        }

        tileGrid each(|col, row, e| test(e))
        test(hero)
    }

}

Entity: class {

    pos: Vec2
    level: Level

    init: func (=level, .pos) {
        this pos = vec2(pos)
    }

    update: func -> Bool {
        true
    }

    destroy: func {
    }

    bombHarm: func (bomb: Bomb) {
        // override here
    }

}

CollisionTypes: enum from Int {
    HERO
    ENEMY
    BLOCK
    HOLE
    WALL
    TEAR
    BOMB
    COBWEB
    FIRE
    COLLECTIBLE
}

CollisionGroups: enum from Int {
    TEAR
    COLLECTIBLE
}

CollisionHandler: abstract class extends CpCollisionHandler {

    cachedLevel: Level

    ensure: func (level: Level) {
        if (level != cachedLevel) {
            cachedLevel = level
            add(|a, b|
                level space addCollisionHandler(a, b, this)
            )
        }
    }

    add: abstract func (f: Func (Int, Int))

}

Direction: enum {
    LEFT
    RIGHT
    UP
    DOWN

    toString: func -> String {
        match this {
            case This UP    => "up"
            case This DOWN  => "down"
            case This LEFT  => "left"
            case This RIGHT => "right"
            case            => "<unknown direction>"
        }
    }

    toAngle: func -> Float {
        match this {
            case This UP     => 0
            case This LEFT   => 90
            case This DOWN   => 180
            case This RIGHT  => 270
            case => 45 // nonsensical value to make sure we notice it
        }
    }
}

Grid: class {
    list: Tile[]

    width := 13
    height := 7

    origin := vec2(100, 100)
    blockSide := 50.0

    init: func {
        initList()
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

    remove: func (col, row: Int) {
        index := _index(col, row)
        obj := list[index]
        obj destroy()
        list[index] = null
    }

    each: func (f: Func(Int, Int, Tile)) {
        for (col in 0..width) {
            for (row in 0..height) {
                obj := list[_index(col, row)]
                if (obj) {
                    f(col, row, obj)
                }
            }
        }
    }

    clear: func {
        each(|col, row, tile|
            tile destroy()
        ) 
        initList()
    }

    initList: func {
        list = Tile[width * height] new()
    }
}

