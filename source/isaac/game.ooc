
// third-party stuff
use dye
import dye/[core, loop, input, primitives, math, sprite, text]

use deadlogger
import deadlogger/[Log, Logger]

use gnaar
import gnaar/[grid, utils]

// sdk stuff
import math/Random
import structs/[HashMap, List, ArrayList]

// our stuff
import isaac/[logging, level, bomb, hero, rooms, collectible, health, plan, map]

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

    // map-related stuff
    plan: Plan
    floor: PlanFloor
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

        generatePlan()
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

    generatePlan: func {
        plan = Plan generate()
        logger info("Generated plan: %s", plan toString())
        floor = plan floors first()
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

}


GameState: enum {
    PLAY
    CHANGEROOM
}

