
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
import isaac/[game, hero, walls, bomb, rooms, enemy, map, tiles,
    freezer, explosion, collectible, boss, plan]
import isaac/enemies/[fly]

Level: class {

    logger := static Log getLogger(This name)

    game: Game

    space: CpSpace
    physicSteps := 10

    // when locked, some operations are buffered
    locked := false

    // actual entity list
    entities := ArrayList<Entity> new()

    // buffers
    addBuffer := ArrayList<Entity> new()

    hero: Hero
    walls: Walls

    // layers
    group: GlGroup
    bgGroup: GlGroup
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

    gridBottomLeft := vec2i(0, 0)
    gridTopRight := vec2i(12, 6)

    groundLevel := 3.0

    // grids
    tileGrid := Grid<Tile> new()

    dye: DyeContext { get { game dye } }
    input: Input { get { game dye input } }

    cleared := false

    tile: MapTile
    floor: PlanFloor

    init: func (=game, =tile, =floor) {
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

    loadBg: func {
        // TODO: special bgs for some rooms
        name := match (floor type) {
            case FloorType BASEMENT =>
                "basement"
            case FloorType CELLAR =>
                "cellar"
            case FloorType CAVES || FloorType CATACOMBS =>
                "caves"
            case FloorType DEPTHS || FloorType NECROPOLIS =>
                "depths"
            case FloorType WOMB || FloorType UTERO =>
                "womb"
            case FloorType CATHEDRAL =>
                "depths"
            case FloorType SHEOL =>
                "depths"
            case FloorType CHEST =>
                "basement"
            case =>
                "basement" // fallback
        }
        path := "assets/png/%s-bg.png" format(name)
        bgPic := GlSprite new(path)
        bgPic center = false
        bgGroup add(bgPic)
    }

    
    gridPos: func (x, y: Int) -> Vec2 {
        vec2(paddedBottomLeft x + 50.0 * x,
             paddedBottomLeft y + 50.0 * y)
    }

    snappedPos: func (v: Vec2) -> Vec2i {
        v sub(paddedBottomLeft) getColRow(50.0)
    }

    destroy: func {
        tileGrid clear()

        destroyList(entities)
        space free()
    }

    destroyList: func (list: List<Entity>) {
        iter := list iterator()
        while (iter hasNext?()) {
            e := iter next()
            iter remove()
            e destroy()
        }
    }

    getHeroStartPos: func -> Vec2 {
        vec2(300, 300)
    }

    initGroups: func {
        bgGroup = GlGroup new()
        group add(bgGroup)

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

        loadBg()
    }

    initPhysx: func {
        space = CpSpace new()
    }

    add: func (e: Entity) {
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
        hero move(dir normalized())

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
        game playSound("doors-open")

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
                case boss: Boss =>
                    count += 1
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

        updateList(entities)
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

    updateList: func (list: List<Entity>) {
        iter := list iterator()
        while (iter hasNext?()) {
            e := iter next()
            if (!e update()) {
                logger debug("Destroying object %p (it's a %s)", e, e class name)
                iter remove()
                e destroy()
            }
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
        _radiusTest(entities, pos, radius, f)
        tileGrid each(|col, row, e| _radiusTest(e, pos, radius, f))
        _radiusTest(hero, pos, radius, f)
        _radiusTest(walls, pos, radius, f)
    }

    _radiusTest: func ~single (e: Entity, pos: Vec2, radius: Float, f: Func (Entity)) {
        eRadius := pos dist(e pos)
        if (eRadius <= radius) {
            f(e)
        }
        e eachInRadius(pos, radius, f)
    }

    _radiusTest: func ~list (children: List<Entity>, pos: Vec2, radius: Float,
            f: Func (Entity)) {
        for (e in children) {
            _radiusTest(e, pos, radius, f)
        }
    }

    bossState: func -> (Float, Int) {
        count := 0
        total := 0.0

        for (e in entities) {
            match e {
                case boss: Boss =>
                    total += boss totalHealth() / boss maxHealth()
                    count += 1
            }
        }

        return (total / count as Float, count)
    }

}

Entity: class {

    pos: Vec2
    level: Level
    collisionRadius := 20.0

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

    spawnFlies: func (numFlies: Int) {
        for (i in 0..numFlies) {
            number := Random randInt(0, 100)
            type := match {
                case number < 20 =>
                    FlyType POOTER
                case number < 60 =>
                    FlyType ATTACK_FLY
                case =>
                    FlyType BLACK_FLY
            }

            vel := Vec2 random(100)
            diff := Vec2 random(40)

            fly := Fly new(level, pos add(diff), type)
            fly body setVel(cpv(vel))
            level add(fly)
        }
    }

    eachInRadius: func (pos: Vec2, radius: Float, f: Func (Entity)) {
        // by default we have no children. If you have some, implement that
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
    MAGGOT
    GAPER
    HOPPER
}

CollisionHandler: abstract class extends CpCollisionHandler {

    logger := static Log getLogger(This name)

    cachedLevel: Level

    ensure: func (level: Level) {
        if (level != cachedLevel) {
            cachedLevel = level
            add(|a, b|
                //logger warn("adding between %d and %d", a, b)
                level space addCollisionHandler(a, b, this)
            )
        }
    }

    add: abstract func (f: Func (Int, Int))

}

Direction: enum {
    LEFT
    UP
    RIGHT
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

    toDeltaFloat: func -> Vec2 {
        match this {
            case This UP     => vec2(0,  1)
            case This DOWN   => vec2(0, -1)
            case This LEFT   => vec2(-1, 0)
            case This RIGHT  => vec2( 1, 0)
            case => vec2(1, 1) // nonsensical value to make sure we notice it
        }
    }

    along?: func (v: Vec2, epsilon := 0.2) -> Bool {
        match this {
            case This UP    => v y > epsilon
            case This DOWN  => v y < -epsilon
            case This LEFT  => v x < -epsilon
            case This RIGHT => v x > epsilon
            case => false // nonsensical
        }
    }

    fromDelta: static func (deltaX, deltaY: Int) -> This {
        if (deltaX abs() > deltaY abs()) {
            if (deltaX > 0) {
                return This RIGHT
            } else {
                return This LEFT
            }
        } else {
            if (deltaY > 0) {
                return This UP
            } else {
                return This DOWN
            }
        }

        This UP // hmm.
    }

    random: static func -> This {
        Random randInt(1, 4) as This
    }

    next: func -> This {
        shift(1)
    }

    prev: func -> This {
        shift(-1)
    }

    opposite: func -> This {
        shift(2)
    }

    shift: func (offset: Int) -> This {
        (this as Int + offset) clamp(1, 4) as This
    }

    isOpposed?: func (other: This) -> Bool {
        (this as Int - other as Int) abs() == 2
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

