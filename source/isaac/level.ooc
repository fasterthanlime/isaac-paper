
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
import isaac/[game, hero, walls, hopper, bomb]

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
    shadowGroup: GlGroup
    charGroup: GlGroup

    // a few reference points
    bottomLeft := vec2(75, 75)
    topRight := vec2(725, 425)

    paddedBottomLeft := vec2(100, 100)
    paddedTopRight := vec2(700, 400)

    groundLevel := 3.0

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

        hero = Hero new(this, getHeroStartPos())
        walls = Walls new(this)

        fillGrids()
    }

    fillGrids: func {
        for (col in 0..blockGrid width) {
            for (row in 0..blockGrid height) {
                if (Random randInt(0, 10) < 8) {
                    continue
                }

                if (Random randInt(0, 10) < 8) {
                    blockGrid put(col, row, Block new(this))
                } else {
                    blockGrid put(col, row, Poop new(this))
                }
            }
        }

        for (i in 0..3) {
            add(Hopper new(this, vec2(600, 300)))
        }

        walls setup()
    }

    reload: func (enterDir: Direction) {
        holeGrid clear()
        blockGrid clear()

        iter := entities iterator()
        while (iter hasNext?()) {
            e := iter next()
            iter remove()
            e destroy()
        }

        fillGrids()
        
        heroPos := match (enterDir) {
            case Direction UP     => vec2(400, 100)
            case Direction DOWN   => vec2(400, 400)
            case Direction RIGHT  => vec2(100, 200)
            case Direction LEFT   => vec2(700, 200)
        }
        hero setPos(heroPos)
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
        walls update()

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
        updateGrid(holeGrid)
        updateGrid(blockGrid)
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

    currentTile: MapTile { get {
        game map currentTile
    } }

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

        blockGrid each(|col, row, e| test(e))
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
            remove(col, row)
        ) 
    }
}

Tile: abstract class extends Entity {

    sprite: GlSprite
    body: CpBody
    shape: CpShape
    side := 50

    alive := true

    init: func (.level) {
        super(level, vec2(0, 0))
        sprite = GlSprite new(getSprite())
        getLayer() add(sprite)

        initPhysx()
    }

    initPhysx: func {
        body = CpBody new(INFINITY, INFINITY)

        shape = CpBoxShape new(body, side, side)
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
    }

    setPos: func (.pos) {
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

Hole: class extends Tile {

    init: func (.level) {
        super(level)
        shape setCollisionType(CollisionTypes HOLE)
    }

    getSprite: func -> String {
        "assets/png/hole.png"
    }

    getLayer: func -> GlGroup {
        level holeGroup
    }

    bombHarm: func (bomb: Bomb) {
        // holes don't get destroyed by bombs
    }

}

Block: class extends Tile {

    init: func (.level) {
        super(level)
        shape setCollisionType(CollisionTypes BLOCK)
    }

    getSprite: func -> String {
        num := Random randInt(1, 3)
        "assets/png/block-%d.png" format(num)
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
            return false
        }

        super()
    }

    harm: func (damage: Int) {
        if (damageCount <= 0) {
            life -= damage
            damageCount = 10
        }
    }

}

