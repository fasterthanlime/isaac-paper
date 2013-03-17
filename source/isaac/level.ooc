
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
import isaac/[game, hero, walls, hopper, bomb, rooms, enemy, map, tiles,
    freezer, explosion, collectible]

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

        // bypass the onClear callback if just spawned
        updateClearedCondition()

        // update once without drawing to set up everything correctly
        updateEntities()
    }
    
    gridPos: func (x, y: Int) -> Vec2 {
        vec2(paddedBottomLeft x + 50.0 * x,
             paddedBottomLeft y + 50.0 * y)
    }

    snappedPos: func (v: Vec2) -> Vec2i {
        snapped := v sub(paddedBottomLeft) snap(50.0)
        vec2i(snapped x / 50.0, snapped y / 50.0)
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
            updateClearedCondition()
            if (cleared) {
                onClear()
            }
        }

        cleared
    }

    updateClearedCondition: func {
        cleared = (blockingEnemyCount() <= 0)
    }

    onClear: func {
        if (tile roomDrop?()) {
            // spawn at the center of the room
            // TODO: algorithm to not spawn on top of rocks?
            pos := gridPos(6, 3)
            tile room spawnCollectible(pos, this)
        }

        if (tile trapDrop?()) {
            pos := gridPos(6, 5)
            tile room spawnTrapDoor(pos, this)
            game loadMusic()
        }
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

        updateEntities()
    }

    updateEntities: func {
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

            for (entity in addBuffer) {
                if (entity update()) {
                    entities add(entity)
                }
            }
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

        test(walls upDoor)
        test(walls downDoor)
        test(walls leftDoor)
        test(walls rightDoor)
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

    bombHarm: func (explosion: Explosion) {
        // override here
    }

    shouldFreeze: func -> Bool {
        // override if it should freeze!
        false
    }

    freeze: func (ent: FrozenEntity) {
        // override if you need to set up additional attributes
    }

    unfreeze: func (ent: FrozenEntity) {
        // override if you need to set up additional attributes
    }

    spawnCoins: func (count: Int) {
        for (i in 0..count) {
            x := Random randInt(-40, 40) as Float
            y := Random randInt(-40, 40) as Float
            coinPos := pos add(x, y)

            // TODO: other types of coins
            coin := CollectibleCoin new(level, coinPos)
            coin catapult()
            level add(coin)
        }
    }

    spawnChest: func (type: ChestType) {
        chest := CollectibleChest new(level, pos, type)
        chest catapult()
        level add(chest)
    }

    spawnKey: func {
        key := CollectibleKey new(level, pos)
        key catapult()
        level add(key)
    }

    spawnBomb: func {
        // 1+1 free
        bomb := CollectibleBomb new(level, pos)
        bomb catapult()
        level add(bomb)
    }

    spawnHeart: func {
        heart := level tile room spawnHeart(pos, level)
        heart catapult()
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
    TRAP_DOOR
    SPIKES

    COLLECTIBLE
}

CollisionGroups: enum from Int {
    TEAR
    COLLECTIBLE
}

CollisionHandler: abstract class extends CpCollisionHandler {

    logger := static Log getLogger(This name)

    cachedLevel: Level

    ensure: func (level: Level) {
        if (level != cachedLevel) {
            cachedLevel = level
            add(|a, b|
                logger warn("adding between %d and %d", a, b)
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

    toDelta: func -> Vec2i {
        match this {
            case This UP     => vec2i(0,  1)
            case This DOWN   => vec2i(0, -1)
            case This LEFT   => vec2i(-1, 0)
            case This RIGHT  => vec2i( 1, 0)
            case => vec2i(1, 1) // nonsensical value to make sure we notice it
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
        obj setPos(vec2i(col, row), origin add(vec2(col, row) mul(blockSide)))
    }

    get: func (col, row: Int) -> Tile {
        if (!validCoords?(col, row)) return null
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

    validCoords?: func (col, row: Int) -> Bool {
        if (col < 0 || col >= width) {
            return false     
        }

        if (row < 0 || row >= height) {
            return false
        }

        true
    }
    
    hasNeighborOfType?: func (col, row: Int, type: Class) -> Bool {
        if (!validCoords?(col, row)) {
            return false
        }

        tile := get(col, row)
        (tile != null && tile instanceOf?(type))
    }

    contains?: func (col, row: Int) -> Bool {
        if (!validCoords?(col, row)) {
            return false
        }

        tile := get(col, row)
        (tile != null)
    }

    eachNeighbor: func (col, row: Int, f: Func (Tile)) -> Bool {
        test := func (col, row: Int) {
            tile := get(col, row)
            if (tile) {
                f(tile)
            }
        }

        test(col + 1, row)
        test(col - 1, row)
        test(col, row + 1)
        test(col, row - 1)
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

