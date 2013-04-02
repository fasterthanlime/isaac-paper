
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
import isaac/[level, plan, rooms, game, boss, freezer, options, boss, options]
import isaac/bosses/[duke]

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
    CHALLENGE
    ARCADE

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
            case This CHALLENGE    => "challenge"
            case This ARCADE       => "arcade"
            
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

    group, outlineGroup, roomGroup: GlGroup

    currentTile: MapTile

    mapSize: Vec2i

    takenBosses := ArrayList<BossType> new()

    init: func (=game) {
        group = GlGroup new()
        game mapGroup add(group)

        outlineGroup = GlGroup new()
        group add(outlineGroup)

        roomGroup = GlGroup new()
        group add(roomGroup)
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
        // second XL room will be placed accordingly

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
                RoomType CURSE, RoomType CHALLENGE]
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

            if (special == RoomType BOSS && game floor xl) {
                shuffled := lonelies shuffle()

                // this is gonna be a bit hard
                for (l in shuffled) {
                    if (neighborCount(l pos) == 1) {
                        path := getPath(l pos, null, 3)
                        if (path) {
                            logger error("Found path: ")
                            for (p in path) {
                                logger error(" - %s", p toString())

                                add(p, special)
                                adjacencyMap update(p x, p y, false)
                            }

                            lonelies = adjacencyMap getLonelies()

                            break // we're done looking
                        }
                    }
                }
            } else {
                lonely := Random choice(lonelies)
                add(lonely pos, special)

                adjacencyMap update(lonely pos x, lonely pos y, false)
                lonelies = adjacencyMap getLonelies()
            }
        }

        bounds := grid getBounds()
        mapSize = vec2i(bounds width, bounds height)
        logger info("Generated a map with bounds %s. Size = %dx%d",
            bounds _, bounds width, bounds height)
    }

    reveal: func {
        currentTile revealed = true

        maybeReveal := func (col, row: Int) {
            if (grid contains?(col, row)) {
                tile := grid get(col, row)
                tile revealAsNeighbor()
            }
        }

        maybeReveal(currentTile pos x - 1, currentTile pos y)
        maybeReveal(currentTile pos x + 1, currentTile pos y)
        maybeReveal(currentTile pos x, currentTile pos y - 1)
        maybeReveal(currentTile pos x, currentTile pos y + 1)
    }

    setup: func {
        outlineGroup clear()
        roomGroup clear()

        grid each(|col, row, tile|
            tile reset()
            tile active = false
        )
        currentTile active = true

        bounds := getRevealedBounds()
        gridOffset := vec2i(bounds xMin, bounds yMin)

        gWidth := (bounds width + 1)
        gHeight := (bounds height + 1)

        tileSize := vec2(
            screenSize x / gWidth as Float,
            screenSize y / gHeight as Float
        )

        idealTileSize := vec2(25, 12)
        centerOffset := vec2(0, 0)

        logger warn("tileSize = %s, idealTileSize = %s",
            tileSize toString(), idealTileSize toString())

        realWidth := tileSize x * gWidth
        realHeight := tileSize y * gHeight

        if (realWidth > screenSize x || realHeight > screenSize y ||
                (tileSize x > idealTileSize x && tileSize y > idealTileSize y)) {
            // our tiles are too big - use ideal tile size, and center
            // properly

            tileSize set!(idealTileSize)

            realWidth = tileSize x * gWidth
            realHeight = tileSize y * gHeight

            centerOffset x = (screenSize x / 2.0 - realWidth / 2.0)
            centerOffset y = (screenSize y / 2.0 - realHeight / 2.0)
        } else {
            // our tiles are too small - make sure they're the right aspect
            // ratio, and center properly
            ratio := tileSize x / tileSize y
            idealRatio := idealTileSize x / idealTileSize y

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
        }

        logger warn("In the end: tileSize = %s, centerOffset = %s",
            tileSize toString(), centerOffset toString())

        {
            y := bounds yMax
            while (y >= bounds yMin) {
                x := bounds xMin
                while (x <= bounds xMax) {
                    if (grid contains?(x, y)) {
                        tile := grid get(x, y)
                        if (tile revealed) {
                            tile setup(x, y, tileSize, gridOffset, centerOffset)
                        }
                    }

                    x += 1
                }

                y -= 1
            }
        }
    }

    getRevealedBounds: func -> AABB2i {
        result := AABB2i new()

        grid each(|col, row, tile|
            if (tile revealed) {
                result expand!(tile pos)
            }
        )

        result
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
            
        // TODO: Well, we only have one boss so far... 
        //if (takenBosses contains?(type)) {
        //    return pickBoss()
        //}

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

        bossType := BossType NONE

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
                bossType = pickBoss()
                bossType identifier()
            case =>
                game floor type identifier()
        }

        if (game options testLevel) {
            identifier = "test" // huhu
        }

        logger warn("Generating room with identifier %s", identifier)

        roomSet := game rooms getSet(identifier)
        room := Random choice(roomSet rooms)
        if (roomType == RoomType FIRST) {
            room = roomSet rooms first()
        }

        tile := MapTile new(this, pos, room, roomType)
        grid put(pos x, pos y, tile)

        if (bossType != BossType NONE) {
            tile bossType = bossType
        }

        tile
    }

    getPath: func (current, previous: Vec2i, length: Int) -> List<Vec2i> {
        // here's what this method should do:
        // given a lonely tile that has only 1 neighbor..
        // we'll try to find a path that's made entirely of
        // lonelies

        threshold := previous == null ? 1 : 0
        if (neighborCount(current) > threshold) {
            return null
        }

        if (length <= 1) {
            list := ArrayList<Vec2i> new()
            list add(current)
            return list
        } else {
            tryPath := func (pos: Vec2i) -> List<Vec2i> {
                if (previous &&
                        (previous x == pos x && previous y == pos y)) {
                    // disregard
                    return null
                }

                path := getPath(pos, current, length - 1)
                if (path) {
                    path add(0, current)
                }
                return path
            }

            tries := ArrayList<Vec2i> new()
            tries add(current add(0, 1))
            tries add(current add(0, -1))
            tries add(current add(-1, 0))
            tries add(current add(1, 0))
            tries = tries shuffle()

            "tries = %s" printfln(tries map(|x| x toString()) join(", "))

            for (t in tries) {
                list := tryPath(t)
                if (list) return list
            }
        }

        null
    }
}

MapTile: class {

    map: Map
    rect: GlMapTile

    pos: Vec2i
    room: Room
    type: RoomType

    frozenRoom: FrozenRoom
    bossType := BossType NONE

    revealed := false
    active := false
    locked := false

    init: func (=map, .pos, =room, =type) {
        this pos = vec2i(pos)

        match type {
            case RoomType LIBRARY || RoomType SHOP =>
                locked = true
            case RoomType TREASURE =>
                if (map game floorIndex > 0) {
                    // past Basement 1/Cellar 1, all item rooms are locked
                    locked = true 
                }
        }

        if (map game options mapCheat) {
            revealed = true // duh.
        }
    }

    revealAsNeighbor: func {
        if (secret?()) {
            return
        }

        revealed = true
    }

    secret?: func -> Bool {
        match type {
            case RoomType SECRET || RoomType SUPERSECRET =>
                true
            case =>
                false
        }
    }

    unfurl: func (level: Level) {
        if (frozenRoom) {
            frozenRoom unfreeze(level)
        } else {
            room spawn(level)
            spawnBoss(level)
        }
    }

    spawnBoss: func (level: Level) {
        if (bossType != BossType NONE) {
            // spawn a spider for now :D
            level add(DukeOfFlies new(level, level gridPos(6, 3)))
        }
    }

    furl: func (level: Level) {
        frozenRoom = FrozenRoom new(level)
    }

    reset: func {
        if (rect) {
            rect destroy()
            rect = null
        }
    }

    setup: func (col, row: Int, tileSize: Vec2, gridOffset: Vec2i, centerOffset: Vec2) {
        diff := vec2(
            (col - gridOffset x) * tileSize x + centerOffset x,
            (row - gridOffset y) * tileSize y + centerOffset y
        )
        offset := map offset add(diff)
        rect = GlMapTile new(tileSize, this)
        rect setPos(offset)
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

    cleared?: func -> Bool {
        if (!frozenRoom) {
            return false
        }

        frozenRoom cleared
    }

    roomDrop?: func -> Bool {
        normal?()
    }

    trapDrop?: func -> Bool {
        type == RoomType BOSS
    }

    normal?: func -> Bool {
        match type {
            case RoomType NORMAL || RoomType FIRST =>
                true
            case =>
                false
        }
    }
    
}

GlMapTile: class {

    tile: MapTile

    bgSprite: GlSprite
    roomSprite: GlSprite
    itemSprite: GlSprite

    group, roomGroup: GlGroup

    baseScale := 0.35
    tileScale: Float

    init: func (size: Vec2, =tile) {
        tileScale = size x / 25.0 
        realScale := baseScale * tileScale

        group = GlGroup new()
        group scale set!(realScale, realScale)
        tile map outlineGroup add(group)

        roomGroup = GlGroup new()
        roomGroup scale set!(realScale, realScale)
        tile map roomGroup add(roomGroup)

        /* Background */

        bgState := match {
            case tile active =>
                "white"
            case tile cleared?() =>
                "light"
            case =>
                "dark"
        }
        bgSprite = GlSprite new("assets/png/cell-%s.png" format(bgState))
        group add(bgSprite)

        /* Room sprite (crown, etc.) */
        
        roomSpriteName := match (tile type) {
            case RoomType BOSS =>
                "big-skull"
            case RoomType MINIBOSS =>
                "small-skull"
            case RoomType TREASURE =>
                "treasure"
            case RoomType SHOP =>
                "shop"
            case RoomType CURSE =>
                "curse"
            case RoomType CHALLENGE =>
                "challenge"
            case RoomType ARCADE =>
                "dice"
            case RoomType SECRET || RoomType SUPERSECRET =>
                "question"
            case =>
                ""
        }

        if (roomSpriteName != "") {
            roomSpritePath := "assets/png/room-%s.png" format(roomSpriteName)
            roomSprite = GlSprite new(roomSpritePath)
            roomGroup add(roomSprite)
        }
        
    }

    setPos: func (pos: Vec2) {
        offset := vec2(25, 12) mul(0.5 * tileScale)
        ourPos := pos add(offset)

        group pos set!(ourPos)
        roomGroup pos set!(ourPos)
    }

    destroy: func {
        tile map outlineGroup remove(group)
        tile map roomGroup remove(roomGroup)
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

