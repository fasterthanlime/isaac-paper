

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
