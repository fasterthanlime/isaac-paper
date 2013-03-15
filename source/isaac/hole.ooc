
// third-party stuff
use chipmunk
import chipmunk

use dye
import dye/[core, math, input, sprite]

use gnaar
import gnaar/[utils]

use deadlogger
import deadlogger/[Log, Logger]

// sdk stuff
import structs/[List, ArrayList, HashMap]
import math/Random

// our stuff
import isaac/[game, hero, walls, hopper, bomb, rooms, enemy, map, level, tiles]

Hole: class extends Tile {

    init: func (.level) {
        super(level)
        shape setCollisionType(CollisionTypes HOLE)
    }

    getSprite: func -> String {
        "assets/png/hole-bottom.png"
    }

    getLayer: func -> GlGroup {
        level holeGroup
    }

    update: func -> Bool {
        super()
    }

    bombHarm: func (bomb: Bomb) {
        // holes don't get destroyed by bombs
    }

}
