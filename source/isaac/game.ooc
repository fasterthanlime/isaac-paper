
// third-party stuff
use dye
import dye/[core, loop, input, primitives, math]

Game: class {

    dye: DyeContext
    scene: Scene

    uiGroup: GlGroup

    init: func {
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

    update: func {
    }

    quit: func {
        dye quit()
        exit(0)
    }

}
