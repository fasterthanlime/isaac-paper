
// third-party stuff
use dye
import dye/[core, loop, input, primitives, math, sprite, text]

use deadlogger
import deadlogger/[Log, Logger]

use gnaar
import gnaar/[grid, utils]

// sdk stuff
import math/Random
import structs/[HashMap, ArrayList]

// our stuff
import isaac/[logging, level, bomb, hero, rooms, collectible, health]

/*
 * The game, duh.
 */
Game: class {

    dye: DyeContext
    scene: Scene

    loop: FixedLoop

    uiGroup, mapGroup, levelGroup: GlGroup

    level: Level

    logger := static Log getLogger(This name)

    FONT := "assets/ttf/8-bit-wonder.ttf"

    floor: String

    // map-related stuff
    map: Map
    rooms: Rooms

    // the hero's stats!
    heroStats: HeroStats

    // resources
    coinLabel, bombLabel, keyLabel, fpsLabel: GlText
    health: Health

    // state stuff
    state := GameState PLAY
    changeRoomDir := Direction UP
    changeRoomIncr := 30.0

    resetCount := 0
    resetCountThreshold := 40

    /* Initialization, duh */
    init: func {
        Logging setup()

        dye = DyeContext new(800, 600, "Paper Isaac")
        dye setClearColor(Color white())

        scene = dye currentScene

        rooms = Rooms new()

        initEvents()
        initGfx()
        initUI()
        map = Map new(this)

        startGame()

        loop = FixedLoop new(dye, 60.0)
        loop run(||
            update()
        )
    }

    startGame: func {
        // re-initialize our stats
        initStats()

        loadFloor()
    }

    loadFloor: func {
        chooseFloor()

        if (map) {
            map destroy()
        }
        map = Map new(this)
        map generate()
        loadRoom()
    }

    loadRoom: func {
        map setup()
        initLevel()
    }

    initLevel: func {
        if (level) {
            levelGroup remove(level group)
            level destroy()
            level = null
        }

        level = Level new(this)
        levelGroup add(level group)
        
        heroPos := match (changeRoomDir) {
            case Direction UP     => vec2(400, 100)
            case Direction DOWN   => vec2(400, 400)
            case Direction RIGHT  => vec2(100, 240)
            case Direction LEFT   => vec2(700, 240)
        }
        level hero setPos(heroPos)
    }

    reset: func {
        startGame()
    }

    chooseFloor: func {
        list := ArrayList<String> new()
        list add("cellar"). add("basement")
        floor = Random choice(list)
    }

    initStats: func {
        heroStats = HeroStats new(this)
    }

    initEvents: func {
        scene input onKeyPress(KeyCode ESC, |kp|
            quit()
        )

        scene input onExit(||
            quit()
        )

        scene input onKeyPress(KeyCode E, |kp|
            dropBomb()
        )
    }

    dropBomb: func {
        if (heroStats bombCount <= 0) return

        level add(Bomb new(level, level hero pos))
        heroStats bombCount -= 1
    }

    changeRoom: func (=changeRoomDir) {
        state = GameState CHANGEROOM
    }

    initUI: func {
        uiGroup = GlGroup new()
        scene add(uiGroup)

        uiBg := GlRectangle new(vec2(800, 105))
        uiBg center = false
        uiBg pos set!(0, 495)
        uiBg color set!(Color new(20, 20, 20))
        uiGroup add(uiBg)

        labelLeft := 340
        labelBottom := 500
        labelFontSize := 14
        labelPadding := 28

        coinLabel = GlText new(FONT, "*00", labelFontSize)
        coinLabel pos set!(labelLeft, labelBottom + labelPadding * 2)
        coinLabel color set!(Color white())
        uiGroup add(coinLabel)

        bombLabel = GlText new(FONT, "*01", labelFontSize)
        bombLabel pos set!(labelLeft, labelBottom + labelPadding)
        bombLabel color set!(Color white())
        uiGroup add(bombLabel)

        keyLabel = GlText new(FONT, "*03", labelFontSize)
        keyLabel pos set!(labelLeft, labelBottom)
        keyLabel color set!(Color white())
        uiGroup add(keyLabel)

        fpsLabel = GlText new(FONT, "60FPS", labelFontSize)
        fpsLabel pos set!(10, 40)
        fpsLabel color set!(Color new(30, 30, 30))
        uiGroup add(fpsLabel)

        iconLeft := 325
        iconBottom := 528
        iconPadding := labelPadding
        iconScale := 0.9

        coinIcon := GlSprite new("assets/png/mini-coin.png")
        coinIcon pos set!(iconLeft, iconBottom + iconPadding * 2)
        coinIcon scale set!(iconScale, iconScale)
        uiGroup add(coinIcon)

        bombIcon := GlSprite new("assets/png/mini-bomb.png")
        bombIcon pos set!(iconLeft, iconBottom + iconPadding)
        bombIcon scale set!(iconScale, iconScale)
        uiGroup add(bombIcon)

        keyIcon := GlSprite new("assets/png/mini-key.png")
        keyIcon pos set!(iconLeft, iconBottom)
        keyIcon scale set!(iconScale, iconScale)
        uiGroup add(keyIcon)

        outlineBottom := 548
        outlineScale := 0.9

        arrowsIcon := GlSprite new("assets/png/ui-arrows.png")
        arrowsIcon scale set!(outlineScale, outlineScale)
        arrowsIcon pos set!(432, outlineBottom)
        uiGroup add(arrowsIcon)

        spaceIcon := GlSprite new("assets/png/ui-space.png")
        spaceIcon scale set!(outlineScale, outlineScale)
        spaceIcon pos set!(510, outlineBottom)
        uiGroup add(spaceIcon)

        mapGroup = GlGroup new()
        uiGroup add(mapGroup)

        health = Health new(this)
        uiGroup add(health)

        lifeLabel := GlText new(FONT, "LIFE", labelFontSize)
        lifeLabel pos set!(650, 560)
        lifeLabel color set!(255, 255, 255)
        uiGroup add(lifeLabel)
    }

    initGfx: func {
        levelGroup = GlGroup new()
        scene add(levelGroup)

        bgGroup := GlGroup new()
        levelGroup add(bgGroup)
       
        bgPic := GlSprite new("assets/png/basement-bg.png")
        bgPic pos set!(0, 0)
        bgPic center = false
        bgGroup add(bgPic)

    }

    update: func {
        match state {
            case GameState PLAY =>
                level update()
                updateLabels()
                if (heroStats totalHealth() <= 0) {
                    reset()
                }
                if (level input isPressed(KeyCode R)) {
                    resetCount += 1
                    if (resetCount >= resetCountThreshold) {
                        resetCount = 0
                        reset()
                    }
                } else {
                    resetCount = 0
                }

            case GameState CHANGEROOM =>
                updateChangeRoom()
        }
    }

    updateChangeRoom: func {
        finished := false

        match changeRoomDir {
            case Direction UP =>
                levelGroup pos y -= changeRoomIncr
                finished = levelGroup pos y < -400
            case Direction DOWN =>
                levelGroup pos y += changeRoomIncr
                finished = levelGroup pos y > 400
            case Direction LEFT =>
                levelGroup pos x += changeRoomIncr
                finished = levelGroup pos x > 800
            case Direction RIGHT =>
                levelGroup pos x -= changeRoomIncr
                finished = levelGroup pos x < -800
        }

        if (finished) {
            finalizeChangeRoom()
        }
    }

    changeRoomDelta: func -> Vec2i {
        levelGroup pos set!(0, 0)

        match changeRoomDir {
            case Direction UP    => vec2i(0, 1)
            case Direction DOWN  => vec2i(0, -1)
            case Direction LEFT  => vec2i(-1, 0)
            case Direction RIGHT => vec2i(1, 0)
        }
    }

    finalizeChangeRoom: func {
        delta := changeRoomDelta()
        newPos := map currentTile pos add(delta)
        map currentTile = map grid get(newPos x, newPos y)
        loadRoom()

        state = GameState PLAY
    }

    updateLabels: func {
        coinLabel value = "*%02d" format(heroStats coinCount)
        bombLabel value = "*%02d" format(heroStats bombCount)
        keyLabel value = "*%02d" format(heroStats keyCount)
        fpsLabel value = "%.0fFPS" format(loop fps)

        health update()
    }

    // quitter!
    quit: func {
        dye quit()
        exit(0)
    }

    // floor info
    floorIndex: func -> Int {
        match floor {
            case "cellar" || "basement" => 0
            case "caves" || "catacombs" => 1
            case "the-depths" || "necropolis" => 2
            case "the-womb" || "utero" => 3
            case "sheol" || "cathedral" => 4
            case "chest" => 5
            case => 0 // unknown room? art thou testing, dev?
        }
    }

    xlFloor?: func -> Bool {
        // *no* idea how to really implement that
        false
    }

    hardFloor?: func -> Bool {
        floorIndex() >= 3 // from the womb / utero - it's a hard floor
    }

}

/*
 * The mini-map, and, incidently, what holds
 * information about the current floor
 */
Map: class {
    game: Game
    screenSize := vec2(250, 85)
    offset := vec2(20, 505)

    grid := SparseGrid<MapTile> new()

    group: GlGroup

    currentTile: MapTile

    mapSize: Vec2i

    init: func (=game) {
        group = GlGroup new()
        game mapGroup add(group)
    }

    destroy: func {
        grid clear()
        game mapGroup remove(group)
    }

    getRoomBudget: func -> Int {
        value := match (game floor) {
            case "cellar" || "basement" => 9
            case => 2
        }

        if (game xlFloor?()) {
            // double it up, johnny!
            value += value
        }

        value
    }

    treasureRoomCount: func -> Int {
        if (game hardFloor?()) {
            return 0
        }

        match (game xlFloor?()) {
            case true => 2
            case => 1
        }
    }

    generate: func {
        roomBudget := getRoomBudget()
        maxLength := roomBudget / 3

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
            //"dir = %d, diff = %s, length = %d" printfln(dir, diff _, length)

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

        bounds := grid getBounds()
        mapSize = vec2i(bounds width, bounds height)
        "Generated a map with bounds %s. Size = %dx%d" printfln(bounds _,
            bounds width, bounds height)
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
         *  0  1  2
         *  7  .  3
         *  6  5  4
         ************
         */
        test(pos x - 1, pos y - 1) // bottom left
        test(pos x - 1, pos y    ) // center left
        test(pos x - 1, pos y + 1) // top left
        test(pos x    , pos y + 1) // top center 
        test(pos x + 1, pos y + 1) // top right
        test(pos x + 1, pos y    ) // center right
        test(pos x + 1, pos y - 1) // bottom right
        test(pos x    , pos y - 1) // bottom center

        count
    }
    
    add: func (pos: Vec2i, roomType := RoomType NORMAL) -> MapTile {
        if (grid contains?(pos x, pos y)) {
            return null
        }

        if (neighborCount(pos) > 3 && !game xlFloor?()) {
            return null
        }

        roomSet := game rooms sets get(game floor)
        room := Random choice(roomSet rooms)
        if (roomType == RoomType FIRST) {
            room = roomSet rooms first()
        }

        tile := MapTile new(this, pos, room)
        grid put(pos x, pos y, tile)
        tile
    }
}

RoomType: enum {
    FIRST
    NORMAL
    BOSS
    TREASURE
    SHOP
    MINIBOSS
    SECRET
    SUPERSECRET
}

MapTile: class {

    map: Map
    rect: GlMapTile

    pos: Vec2i
    room: Room

    active := false

    init: func (=map, .pos, =room) {
        this pos = vec2i(pos)
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
        rect = GlMapTile new(tileSize, active)
        rect setPos(offset)
        map group add(rect)
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

    init: func (size: Vec2, active: Bool) {
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
            fill color set!(Color new(120, 120, 120))
        }
        fill center = false
        add(fill)
    }

    setPos: func (pos: Vec2) {
        fill pos set!(pos)
        outline pos set!(pos)
    }
    
}

GameState: enum {
    PLAY
    CHANGEROOM
}

