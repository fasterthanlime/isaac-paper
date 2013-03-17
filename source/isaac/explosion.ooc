

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

// our stuff
import isaac/[level, splash]

Explosion: class extends Splash {

    harmed := false
    explosionRadius := 105.0
    damage := 30

    init: func (.level, .pos) {
        super(level, pos)

        incr := -0.05
        scaleB = 1.5
        sprite color set!(80, 80, 80)
        alphaFactor = 1.0
    }

    getSpritePath: func -> String {
        "assets/png/explosion.png"
    }

    update: func -> Bool {
        if (!harmed) {
            harmed = true

            // explode here
            level eachInRadius(pos, explosionRadius, |ent|
                ent bombHarm(this)
            )
        }

        super()
    }
        
}
