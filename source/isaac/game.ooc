
// third-party stuff
use dye
import dye/[core, loop, input, primitives, math, sprite, text]

use deadlogger
import deadlogger/[Log, Logger]

use gnaar
import gnaar/[grid, utils]

use bleep
import bleep

// sdk stuff
import math/Random
import structs/[HashMap, List, ArrayList]

// our stuff
import isaac/[logging, level, bomb, hero, rooms, collectible, health, plan, map,
    music, options, trapdoor, spikes]

// debugging for fun
import isaac/[tear, enemy]

/*
 * The game, duh.
 */
Game: class {

    dye: DyeContext
    scene: Scene

    options: Options

    bleep: Bleep
    music: Music

    loop: FixedLoop

    uiGroup, mapGroup, levelGroup: GlGroup

    level: Level

    logger := static Log getLogger(This name)

    FONT := "assets/ttf/8-bit-wonder.ttf"

    // map-related stuff
    plan: Plan
    floor: PlanFloor
    floorIndex := 0

    map: Map
    rooms: Rooms

    // the hero's stats!
    heroStats: HeroStats

    // resources
    coinLabel, bombLabel, keyLabel, fpsLabel, floorLabel: GlText
    health: Health

    // state stuff
    state := GameState PLAY
    changeRoomDir := Direction UP
    changeRoomIncr := 30.0

    resetCount := 0
    resetCountThreshold := 40

    cheats := true

    classes: List<Class>

    /* Initialization, duh */
    init: func {
        // Just testing for fun
        {
            classes = ArrayList<Class> new()
            t := Tear
            classes add(t)
            e := Enemy
            classes add(e)
            m := Mob
            classes add(m)
            cl := Collectible
            classes add(cl)
            bo := Bomb
            classes add(bo)
            td := TrapDoor
            classes add(td)
            sp := Spikes
            classes add(sp)
        }

        Logging setup()

        options = Options new()

        dye = DyeContext new(800, 600, "Paper Isaac")
        dye setClearColor(Color white())

        scene = dye currentScene

        rooms = Rooms new()

        initEvents()
        initGfx()
        initUI()
        map = Map new(this)

        bleep = Bleep new()
        music = Music new(this)
        startGame()

        loop = FixedLoop new(dye, 60.0)
        loop run(||
            update()
        )
    }

    startGame: func {
        // re-initialize our stats
        initStats()

        // generate plan
        generatePlan()

        // choose floor
        floorIndex = 0
        floor = plan floors first()
        
        // load the actual floor
        loadFloor()
    }

    loadFloor: func {
        floorLabel value = floor toString()

        if (map) {
            map destroy()
        }
        map = Map new(this)
        map generate()
        loadRoom()
    }

    loadRoom: func {
        dumpRoomInfo()

        map setup()
        initLevel()
        loadMusic()
    }

    dumpRoomInfo: func {
        roomType := map currentTile type
        logger info("Entering a %s room", roomType toString())
    }

    loadMusic: func {
        // TODO: special music for some rooms

        name := match (floor type) {
            case FloorType BASEMENT =>
                "sacrificial"
            case FloorType CELLAR =>
                "sacrificial" // filler
            case FloorType CAVES =>
                "repentant"
            case FloorType CATACOMBS =>
                "atonement"
            case FloorType DEPTHS || FloorType NECROPOLIS =>
                "dreadful-latter-days"
            case FloorType WOMB || FloorType UTERO =>
                "apostate"
            case FloorType CATHEDRAL =>
                "lament-of-the-angel"
            case FloorType SHEOL =>
                "lament-of-the-angel" // backup
            case FloorType CHEST =>
                "lament-of-the-angel" // backup
            case =>
                "basement" // fallback
        }

        name = match (map currentTile type) {
            case RoomType BOSS =>
                // TODO: separate boss music for regular boss and wotl boss
                if (!level cleared) {
                    name = "divine-combat"
                }
                name
            case RoomType SECRET =>
                "respite"
            case RoomType SUPERSECRET =>
                "respite"
            case RoomType LIBRARY =>
                "tomes" // filler
            case RoomType SHOP =>
                "tomes" // filler
            case =>
                name
        }

        music setMusic(name)
    }

    initLevel: func {
        if (level) {
            levelGroup remove(level group)
            level destroy()
            level = null
        }

        level = Level new(this, map currentTile, floor)
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

    generatePlan: func {
        plan = Plan generate()
        logger info("Generated plan: %s", plan toString())
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

        scene input onKeyPress(KeyCode _1, |kp|
            if (cheats) {
                changeFloor()
            }
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

    changeFloor: func {
        if (state != GameState PLAY) {
            return // already doing something, sweetie
        }
        state = GameState CHANGEFLOOR
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

        floorLabel = GlText new(FONT, "", labelFontSize)
        floorLabel pos set!(10, 10)
        floorLabel color set!(Color new(30, 30, 30))
        uiGroup add(floorLabel)

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

            case GameState CHANGEFLOOR =>
                updateChangeFloor()
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

    updateChangeFloor: func {
        floorIndex += 1
        if (floorIndex >= plan floors size) {
            logger warn("Player won the game!")
            state = GameState PLAY

            // you win!
            startGame()
            return
        }

        floor = plan floors get(floorIndex)

        // don't re-init stats, they're carried over from the previous floor
        // however we want to do stuff about eternal hearts
        heroStats onFloorEnd()

        loadFloor()

        state = GameState PLAY
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
        // furl old room
        map currentTile furl(level)

        // set up new room
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

        //if (level) {
        //    (total, count) := level bossState()
        //    if (count > 0) {
        //        fpsLabel value = "boss health = %d" format((total * 100.0) as Int)
        //    } else {
        //        fpsLabel value = "no boss"
        //    }
        //}

        //if (level && level hero) {
        //    fpsLabel value = "doorCount = %d" format(level hero doorCount)
        //}

        health update()
    }

    // quitter!
    quit: func {
        dye quit()
        exit(0)
    }

}


GameState: enum {
    PLAY
    CHANGEROOM
    CHANGEFLOOR
}

