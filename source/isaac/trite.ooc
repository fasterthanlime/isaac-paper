
// our stuff
import isaac/[level, hopper]

Trite: class extends Hopper {

    init: func (.level, .pos) {
        super(level, pos)

        radius = 300
        jumpHeight = 100
    }

    getSpriteName: func -> String {
        "trite"
    }

}
