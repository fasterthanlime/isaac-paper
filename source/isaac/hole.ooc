
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
import isaac/[game, hero, walls, hopper, bomb, rooms, enemy, map, level, tiles,
    explosion]

Hole: class extends Tile {

    top, bottom, left, right: GlSprite
    neighbored := false

    init: func (.level) {
        super(level)
        shape setCollisionType(CollisionTypes HOLE)

        top    = GlSprite new("assets/png/hole-border-top.png")
        bottom = GlSprite new("assets/png/hole-border-bottom.png")
        left   = GlSprite new("assets/png/hole-border-left.png")
        right  = GlSprite new("assets/png/hole-border-right.png")

        getLayer() add(top)
        getLayer() add(bottom)
        getLayer() add(left)
        getLayer() add(right)

        top visible = false
        bottom visible = false
        left visible = false
        right visible = false
    }

    getSprite: func -> String {
        match (top && top visible) {
            case true =>
                "assets/png/hole-top.png"
            case =>
                "assets/png/hole-bottom.png"
        }
    }

    updateGfx: func {
        sprite setTexture(getSprite())
    }

    getLayer: func -> GlGroup {
        level holeGroup
    }

    reneighborize: func {
        neighbored = false
    }

    update: func -> Bool {
        if (!neighbored) {
            neighbored = true
            top    visible = !level tileGrid hasNeighborOfType?(posi x, posi y + 1, This)
            bottom visible = !level tileGrid hasNeighborOfType?(posi x, posi y - 1, This)
            left   visible = !level tileGrid hasNeighborOfType?(posi x - 1, posi y, This)
            right  visible = !level tileGrid hasNeighborOfType?(posi x + 1, posi y, This)
            updateGfx()
        }

        super()
    }

    setPos: func (.posi, .pos) {
        super(posi, pos)
        top pos set!(pos)
        left pos set!(pos)
        bottom pos set!(pos)
        right pos set!(pos)
    }

    bombHarm: func (explosion: Explosion) {
        // holes don't get destroyed by bombs
    }

    destroy: func {
        super()
        getLayer() remove(top)
        getLayer() remove(bottom)
        getLayer() remove(left)
        getLayer() remove(right)

        level tileGrid eachNeighbor(posi x, posi y, |neighbor|
            match neighbor {
                case hole: Hole =>
                    hole reneighborize()
            }
        )
    }

}
