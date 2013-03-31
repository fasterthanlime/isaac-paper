
// our stuff
import isaac/[level]
import isaac/enemies/hopper

Trite: class extends Hopper {

    init: func (.level, .pos) {
        super(level, pos)

        radius = 450.0
        jumpHeight = 110.0
        jumpCountMax = 25

        speed := 320.0

        spriteYOffset = 8
    }

    getSpriteName: func -> String {
        "trite"
    }

}
