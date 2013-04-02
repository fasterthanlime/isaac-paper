
// our stuff
import isaac/[level]
import isaac/enemies/hopper
import isaac/behaviors/[hopbehavior]

Trite: class extends Hopper {

    init: func (.level, .pos) {
        super(level, pos)

        behavior radius = 450.0
        behavior jumpHeight = 110.0
        behavior jumpCountMax = 25
        behavior speed = 300.0

        spriteYOffset = 8

        baseScale = 0.94
    }

    getSpriteName: func -> String {
        "trite"
    }

}
