
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

    update: func {
    }

    quit: func {
        dye quit()
        exit(0)
    }

}
