
// third-party stuff
use dye
import dye/[core, loop, input, primitives, math, sprite, text]

use deadlogger
import deadlogger/[Log, Logger]

use gnaar
import gnaar/[grid, utils]

// sdk stuff
import math/Random

// our stuff
import isaac/[logging, level]

/*
 * The game, duh.
 */
Game: class {

    dye: DyeContext
    scene: Scene

    loop: FixedLoop

    uiGroup: GlGroup

    level: Level

    logger := static Log getLogger(This name)

    FONT := "assets/ttf/8-bit-wonder.ttf"

    map: Map

    init: func {
        Logging setup()

        dye = DyeContext new(800, 600, "Paper Isaac")
        dye setClearColor(Color white())

        scene = dye currentScene

        initEvents()
        initGfx()
        initLevel()
        initUI()
        initMap()

        loop = FixedLoop new(dye, 60.0)
        loop run(||
            update()
        )
    }

    initEvents: func {
        scene input onKeyPress(KeyCode ESC, |kp|
            quit()
        )
    }

    initUI: func {
        uiGroup = GlGroup new()
        scene add(uiGroup)

        uiBg := GlRectangle new(vec2(800, 100))
        uiBg center = false
        uiBg pos set!(0, 500)
        uiBg color set!(Color new(20, 20, 20))
        uiGroup add(uiBg)

        labelLeft := 350
        labelBottom := 500
        labelFontSize := 18
        labelPadding := 28

        coinLabel := GlText new(FONT, "*00", labelFontSize)
        coinLabel pos set!(labelLeft, labelBottom + labelPadding * 2)
        coinLabel color set!(Color white())
        uiGroup add(coinLabel)

        bombLabel := GlText new(FONT, "*01", labelFontSize)
        bombLabel pos set!(labelLeft, labelBottom + labelPadding)
        bombLabel color set!(Color white())
        uiGroup add(bombLabel)

        keyLabel := GlText new(FONT, "*03", labelFontSize)
        keyLabel pos set!(labelLeft, labelBottom)
        keyLabel color set!(Color white())
        uiGroup add(keyLabel)

        iconLeft := 330
        iconBottom := 528
        iconPadding := labelPadding

        coinIcon := GlSprite new("assets/png/mini-coin.png")
        coinIcon pos set!(iconLeft, iconBottom + iconPadding * 2)
        uiGroup add(coinIcon)

        bombIcon := GlSprite new("assets/png/mini-bomb.png")
        bombIcon pos set!(iconLeft, iconBottom + iconPadding)
        uiGroup add(bombIcon)

        keyIcon := GlSprite new("assets/png/mini-key.png")
        keyIcon pos set!(iconLeft, iconBottom)
        uiGroup add(keyIcon)
    }

    initLevel: func {
        level = Level new(this)
        scene add(level group)
    }

    initGfx: func {
        bgGroup := GlGroup new()
        scene add(bgGroup)
       
        fullBg := GlRectangle new(vec2(800, 500)) 
        fullBg center = false
        fullBg pos set!(0, 0)
        fullBg color set!(Color new(200, 200, 200))
        bgGroup add(fullBg)
       
        arenaBg := GlRectangle new(vec2(650, 350)) 
        arenaBg center = false
        arenaBg pos set!(75, 75)
        arenaBg color set!(Color new(230, 230, 230))
        bgGroup add(arenaBg)
    }

    initMap: func {
        map = Map new()
    }

    update: func {
        level update()
    }

    quit: func {
        dye quit()
        exit(0)
    }

}

Map: class {
    grid := SparseGrid<MapTile> new()

    init: func {
        generate()
    }

    generate: func {
        pos := vec2i(0, 0)
        add(pos)

        for (i in 0..3) {
            length := Random randRange(3, 8)
            dir := Random randRange(0, 3)
            diff := vec2i(0, 0)

            match dir {
                case 0 => diff x = 1
                case 1 => diff x = -1
                case 2 => diff y = 1
                case 3 => diff y = -1
            }
            "dir = %d, diff = %s, length = %d" printfln(dir, diff _, length)

            mypos := vec2i(pos)
            for (j in 0..length) {
                mypos add!(diff)
                add(mypos)
            }
        }

        bounds := grid getBounds()
        "Generated a map with bounds %s" printfln(bounds _)
    }
    
    add: func (pos: Vec2i) {
        "Putting map tile at %s" printfln(pos _)
        grid put(pos x, pos y, MapTile new())
    }
}

MapTile: class {

}

