
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
import isaac/[game, hero, walls, hopper, bomb, rooms, enemy, map, level,
    tiles]

FreezedRoom: class {

    mapTile: MapTile
    cleared: Bool

    tiles := ArrayList<FreezedTile> new()

    init: func (level: Level) {
        mapTile = level tile
        cleared = level cleared

        level tileGrid each(|col, row, e|
            tiles add(FreezedTile new(vec2i(col, row), e))
        )
    }

    unfreeze: func (level: Level) {
        for (tile in tiles) {
            res := tile unfreeze(level)
        }

        if (!cleared) {
            // spawn only creeps
            mapTile room spawn(level, true)
        }
    }

}

FreezedTile: class {

    pos: Vec2i
    type: String

    poopLife := 0.0
    blockNumber := 0

    init: func (=pos, tile: Tile) {
        type = tile class name 

        match tile {
            case poop: Poop =>
                poopLife = poop life
            case block: Block =>
                blockNumber = block number
        }
    }

    unfreeze: func (level: Level) -> Tile {
        result := match type {
            case "Hole" =>
                Hole new(level)
            case "Block" =>
                Block new(level, blockNumber)
            case "Poop" =>
                poop := Poop new(level)
                poop life = poopLife
                poop
            case =>
                null
        }

        if (result) {
            level tileGrid put(pos x, pos y, result)
        }

        result
    }

}

