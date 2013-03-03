
// third-party stuff
use dye
import dye/[core, loop, input, primitives, math, sprite, text]

use deadlogger
import deadlogger/[Log, Logger]

import isaac/logging

/*
 * The game, duh.
 */
Game: class {

    dye: DyeContext
    scene: Scene

    uiGroup: GlGroup

    FONT := "assets/ttf/8-bit-wonder.ttf"

    init: func {
        Logging setup()

        dye = DyeContext new(800, 600, "Paper Isaac")
        dye setClearColor(Color white())

        scene = dye currentScene

        initEvents()
        initGfx()
        initUI()

        loop := FixedLoop new(dye, 30.0)
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

        doorUp := GlSprite new("assets/png/door-up.png")
        doorUp pos set!(400, 600 - 100 - 75 + 30)
        bgGroup add(doorUp)

        doorDown := GlSprite new("assets/png/door-down.png")
        doorDown pos set!(400, 75 - 30)
        bgGroup add(doorDown)

        doorLeft := GlSprite new("assets/png/door-left.png")
        doorLeft pos set!(40, 75 + 170)
        bgGroup add(doorLeft)

        doorRight := GlSprite new("assets/png/door-right.png")
        doorRight pos set!(800 - 40, 75 + 170)
        bgGroup add(doorRight)
    }

    update: func {
    }

    quit: func {
        dye quit()
        exit(0)
    }

}

