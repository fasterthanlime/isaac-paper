
// third-party stuff
use dye
import dye/[core, primitives, sprite, math]

use gnaar
import gnaar/[grid, utils]

use deadlogger
import deadlogger/[Log, Logger]

// sdk stuff
import math/Random
import structs/[HashMap, List, ArrayList]

// our stuff
import isaac/[level, plan, rooms, game, boss, freezer]

RoomType: enum {
    FIRST
    NORMAL

    BOSS
    TREASURE

    SECRET
    SUPERSECRET

    SHOP
    MINIBOSS
    LIBRARY
    CURSE
    ARENA

    ANGEL
    DEVIL

    toString: func -> String {
        match this {
            case This FIRST        => "first"
            case This NORMAL       => "normal"

            case This BOSS         => "boss"
            case This TREASURE     => "treasure"

            case This SECRET       => "secret"
            case This SUPERSECRET  => "supersecret"

            case This SHOP         => "shop"
            case This MINIBOSS     => "miniboss"
            case This LIBRARY      => "library"
            case This CURSE        => "curse"
            case This ARENA        => "arena"
            
            case This ANGEL        => "angel"
            case This DEVIL        => "devil"

            case => "<unknown room type %d>" format(this)
        }
    }
}

/*
 * The mini-map, and, incidently, what holds
 * information about the current floor
 */
Map: class {
    logger := static Log getLogger(This name)

    game: Game
    screenSize := vec2(250, 85)
    offset := vec2(20, 505)

    grid := SparseGrid<MapTile> new()

    group: GlGroup

    currentTile: MapTile

    mapSize: Vec2i

    takenBosses := ArrayList<BossType> new()

    init: func (=game) {
        group = GlGroup new()
        game mapGroup add(group)
    }

    destroy: func {
        grid clear()
        game mapGroup remove(group)
    }

    getRoomBudget: func -> Int {
        value := game floor type budget()

        if (game floor xl) {
            // double it up, johnny!
            value += value
        }

        value
    }

    getSpecialRooms: func -> List<RoomType> {
        specialRoomBudget := 5
        if (game floor xl) {
            specialRoomBudget += 4
        }

        rooms := ArrayList<RoomType> new()

        room := func (type: RoomType) {
            if (specialRoomBudget > 0) {
                specialRoomBudget -= 1
                rooms add(type)
            }
        }

        // boss rooms are a must
        room(RoomType BOSS)
        if (game floor xl) {
            room(RoomType BOSS)
        }

        // so are treasure rooms, up to depths/necropolis
        if (game floor type level() < 3) {
            room(RoomType TREASURE)
            if (game floor xl) {
                room(RoomType TREASURE)
            }
        } else {
            specialRoomBudget -= 1
            if (game floor xl) {
                specialRoomBudget -= 1
            }
        }

        if (specialRoomBudget > 0) {
            // pick other specials from a pool of all the other ones:
            arr := [RoomType SHOP, RoomType MINIBOSS, RoomType LIBRARY,
                RoomType CURSE, RoomType ARENA]
            pool := ArrayList<RoomType> new(arr data, arr length)

            while (specialRoomBudget > 0 && pool size > 0) {
                type := Random choice(pool)
                pool remove(type)
                room(type)
            }
        }

        rooms
    }

    generate: func {
        roomBudget := getRoomBudget()
        maxLength := roomBudget / 3
        if (maxLength < 1) {
            maxLength = 1
        }

        specials := getSpecialRooms()
        roomBudget -= specials size

        logger info("Special rooms on this floor: ")
        for (s in specials) {
            logger info("%s", s toString())
        }

        pos := vec2i(0, 0)
        currentTile = add(pos, RoomType FIRST)
        roomBudget -= 1

        prevDir := 0
        globalCount := 80

        while (roomBudget > 0 && globalCount > 0) {
            globalCount -= 1

            length := Random randInt(1, maxLength)
            dir := Random randInt(0, 3)
            count := 3
            while (count > 0 && dir == prevDir) {
                dir = Random randInt(0, 3)
                count -= 1
            }
            prevDir = dir

            diff := vec2i(0, 0)
            match dir {
                case 0 => diff x = 1
                case 1 => diff x = -1
                case 2 => diff y = 1
                case 3 => diff y = -1
            }

            mypos := vec2i(pos)
            for (j in 0..length) {
                if (roomBudget <= 0) break

                mypos add!(diff)

                mapTile := add(mypos, RoomType NORMAL)
                if (mapTile) {
                    roomBudget -= 1
                } else {
                    break
                }

                if (Random randInt(0, 8) < 2) {
                    pos set!(mypos)
                }
            }
        }

        adjacencyMap := AdjacencyMap new(this)
        lonelies := adjacencyMap getLonelies()

        while (!lonelies empty?() && !specials empty?()) {
            special := specials removeAt(0)
            lonely := Random choice(lonelies)
            add(lonely pos, special)

            adjacencyMap update(lonely pos x, lonely pos y, false)
            lonelies = adjacencyMap getLonelies()
        }

        bounds := grid getBounds()
        mapSize = vec2i(bounds width, bounds height)
        logger info("Generated a map with bounds %s. Size = %dx%d",
            bounds _, bounds width, bounds height)
    }

    setup: func {
        group clear()

        grid each(|col, row, tile|
            tile reset()
            tile active = false
        )
        currentTile active = true

        bounds := grid getBounds()
        gridOffset := vec2i(bounds xMin, bounds yMin)

        gWidth := (bounds width + 1)
        gHeight := (bounds height + 1)

        tileSize := vec2(
            screenSize x / gWidth as Float,
            screenSize y / gHeight as Float
        )

        idealTileSize := vec2(25, 12)

        ratio := tileSize x / tileSize y
        idealRatio := idealTileSize x / idealTileSize y

        centerOffset := vec2(0, 0)

        // compute best size with ideal ratio, then re-center map
        // by adjusting offset
        if (ratio < idealRatio) {
            tileSize y = tileSize x / idealRatio

            realHeight := tileSize y * gHeight
            centerOffset y += screenSize y * 0.5 - realHeight * 0.5
        } else {
            tileSize x = tileSize y * idealRatio

            realWidth := tileSize x * gWidth
            centerOffset x += screenSize x * 0.5 - realWidth * 0.5
        }

        grid each(|col, row, tile|
            tile setup(col, row, tileSize, gridOffset, centerOffset)
        )
    }

    neighborCount: func (pos: Vec2i) -> Int {
        count := 0
        test := func (col, row: Int) {
            if (grid contains?(col, row)) {
                count += 1
            }
        }

        /*  Order:
         ************
         *     0   
         *  3  .  1
         *     2   
         ************
         */
        test(pos x    , pos y + 1) // top
        test(pos x + 1, pos y    ) // right
        test(pos x    , pos y - 1) // bottom
        test(pos x - 1, pos y    ) // left

        count
    }

    /*
     * Pick a boss type out of the available ones for
     * this floor.
     */
    pickBoss: func -> BossType {
        bosses := BossType pool(game floor type)
        type := bosses[Random randRange(0, bosses length)]
        
        if (takenBosses contains?(type)) {
            return pickBoss()
        }

        takenBosses add(type)
        type
    }
    
    add: func (pos: Vec2i, roomType: RoomType) -> MapTile {
        if (grid contains?(pos x, pos y)) {
            return null
        }

        if (neighborCount(pos) > 3 && !game floor xl) {
            return null
        }

        identifier := match roomType {
            case RoomType TREASURE =>
                "treasure"
            case RoomType SHOP =>
                "shop"
            case RoomType LIBRARY =>
                "library"
            case RoomType ANGEL =>
                "angel"
            case RoomType DEVIL =>
                "devil"
            case RoomType CURSE =>
                "curse"
            case RoomType BOSS =>
                boss := pickBoss()
                boss identifier()
            case =>
                game floor type identifier()
        }

        logger warn("Generating room with identifier %s", identifier)

        roomSet := game rooms getSet(identifier)
        room := Random choice(roomSet rooms)
        if (roomType == RoomType FIRST) {
            room = roomSet rooms first()
        }

        tile := MapTile new(this, pos, room, roomType)
        grid put(pos x, pos y, tile)
        tile
    }
}

MapTile: class {

    map: Map
    rect: GlMapTile

    pos: Vec2i
    room: Room
    type: RoomType

    frozenRoom: FrozenRoom

    active := false

    init: func (=map, .pos, =room, =type) {
        this pos = vec2i(pos)
    }

    unfurl: func (level: Level) {
        if (frozenRoom) {
            frozenRoom unfreeze(level)
        } else {
            room spawn(level)
        }
    }

    furl: func (level: Level) {
        frozenRoom = FrozenRoom new(level)
    }

    reset: func {
        if (rect) {
            map group remove(rect)            
            rect = null
        }
    }

    setup: func (col, row: Int, tileSize: Vec2, gridOffset: Vec2i, centerOffset: Vec2) {
        diff := vec2(
            (col - gridOffset x) * tileSize x + centerOffset x,
            (row - gridOffset y) * tileSize y + centerOffset y
        )
        offset := map offset add(diff)
        rect = GlMapTile new(tileSize, this, active)
        rect setPos(offset)
        map group add(rect)
    }

    neighbor: func (deltaCol, deltaRow: Int) -> This {
        x := pos x + deltaCol
        y := pos y + deltaRow
        if (map grid contains?(x, y)) {
            return map grid get(x, y)
        }

        null
    }

    hasTop?: func -> Bool {
        hasNeighbor?(0, 1)
    }

    hasBottom?: func -> Bool {
        hasNeighbor?(0, -1)
    }

    hasLeft?: func -> Bool {
        hasNeighbor?(-1, 0)
    }

    hasRight?: func -> Bool {
        hasNeighbor?(1, 0)
    }

    hasNeighbor?: func (col, row: Int) -> Bool {
        map grid contains?(pos x + col, pos y + row)
    }
    
}

GlMapTile: class extends GlGroup {

    outline: GlRectangle
    fill: GlRectangle
    tile: MapTile

    init: func (size: Vec2, =tile, active: Bool) {
        super()

        outline = GlRectangle new(size)
        outline color set!(Color new(10, 10, 10))
        outline lineWidth = 4.0
        outline center = false
        add(outline)

        fill = GlRectangle new(size sub(2, 2))
        fill pos set!(1, 1)
        if (active) {
            fill color set!(Color new(255, 255, 255))
        } else {
            match (tile type) {
                case RoomType BOSS =>
                    fill color set!(Color new(255, 0, 0)) // red
                case RoomType TREASURE =>
                    fill color set!(Color new(255, 255, 0)) // yellow

                case RoomType SHOP =>
                    fill color set!(Color new(72, 60, 50)) // taupe
                case RoomType MINIBOSS =>
                    fill color set!(Color new(255, 128, 128)) // pink
                case RoomType LIBRARY =>
                    fill color set!(Color new(210, 180, 140)) // tan
                case RoomType CURSE =>
                    fill color set!(Color new(170, 0, 0)) // dark red
                case RoomType ARENA =>
                    fill color set!(Color new(255, 0, 255)) // magenta

                case =>
                    fill color set!(Color new(120, 120, 120)) // gray
            }
        }
        fill center = false
        add(fill)
    }

    setPos: func (pos: Vec2) {
        fill pos set!(pos)
        outline pos set!(pos)
    }
    
}

AdjacencyMap: class {

    map: Map
    grid := SparseGrid<AdjacencyTile> new()

    logger := static Log getLogger(This name)

    init: func (=map) {
        map grid each(|col, row, tile|
            update(col, row)
        ) 

        logger info("Finished computing adjacency map")
        dump()
    }

    test: func (col, row: Int, addNew: Bool) {
        if (map grid contains?(col, row)) {
            if (grid contains?(col, row)) {
                grid remove(col, row)
            }
            return
        }

        pos := vec2i(col, row)
        count := map neighborCount(pos)

        if (grid contains?(col, row)) {
            tile := grid get(col, row)
            tile count = count
        } else {
            if (addNew) {
                grid put(col, row, AdjacencyTile new(pos, count))
            }
        }
    }

    update: func (col, row: Int, addNew := true) {
        test(col    , row + 1, addNew) // top
        test(col + 1, row    , addNew) // right
        test(col    , row - 1, addNew) // bottom
        test(col - 1, row    , addNew) // left
    }

    dump: func {
        bounds := grid getBounds()
        logger info("Bounds = %s", bounds _)

        logger info("===================")
        row := bounds yMax
        while (row >= bounds yMin) {
            buffer := Buffer new()
            for (col in (bounds xMin)..(bounds xMax + 1)) {
                if (grid contains?(col, row)) {
                    tile := grid get(col, row)
                    buffer append("%d" format(tile count))
                } else {
                    buffer append(".")
                }
                buffer append(" ")
            }
            logger info(buffer toString())
            row -= 1
        }
        logger info("===================")
    }

    getLonelies: func -> ArrayList<AdjacencyTile> {
        list := ArrayList<AdjacencyTile> new()
        grid each(|col, row, tile|
            if (tile count == 1) {
                list add(tile)
            }
        )
        list
    }

}

AdjacencyTile: class {

    pos: Vec2i
    count: Int

    init: func (=pos, =count)

}

