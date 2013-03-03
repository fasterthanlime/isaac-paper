
// third-party stuff
use dye
import dye/[core, loop, input]

Game: class {

    dye: DyeContext

    init: func {
        dye = DyeContext new(800, 600, "Paper Isaac")
        dye setClearColor(Color white())

        initEvents()

        loop := FixedLoop new(dye, 30.0)
        loop run(||
            update()
        )
    }

    initEvents: func {
        dye input onKeyPress(KeyCode ESC, |kp|
            quit()
        )
    }

    update: func {
    }

    quit: func {
        dye quit()
        exit(0)
    }

}
