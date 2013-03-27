
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
import structs/[List, ArrayList, HashMap, HashBag]
import math/Random

// our stuff
import isaac/[game, hero, walls, bomb, rooms, enemy, map, level,
    tiles, fire, cobweb, collectible, trapdoor, hole, tnt, spikes]

FrozenRoom: class {

    mapTile: MapTile
    cleared: Bool

    tiles := ArrayList<FrozenTile> new()
    entities := ArrayList<FrozenEntity> new()

    init: func (level: Level) {
        mapTile = level tile
        cleared = level cleared

        level tileGrid each(|col, row, e|
            tiles add(FrozenTile new(vec2i(col, row), e))
        )

        for (entity in level entities) {
            if (entity shouldFreeze()) {
                entities add(FrozenEntity new(entity))
            }
        }
    }

    unfreeze: func (level: Level) {
        if (cleared) {
            // bypass the 'cleared' hook - no drop when you just re-enter the room
            level cleared = true
        }

        for (tile in tiles) {
            tile unfreeze(level)
        }

        for (entity in entities) {
            entity unfreeze(level)
        }

        if (!cleared) {
            // spawn only creeps
            mapTile room spawn(level, true)
        }
    }

}

FrozenTile: class {

    pos: Vec2i
    type: String

    life := 0.0
    blockNumber := 0

    init: func (=pos, tile: Tile) {
        type = tile class name 

        match tile {
            case poop: Poop =>
                life = poop life
            case tnt: TNT =>
                life = tnt life
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
            case "Hole" =>
                Hole new(level)
            case "Poop" =>
                poop := Poop new(level)
                poop life = life
                poop
            case "TNT" =>
                tnt := TNT new(level)
                tnt life = life
                tnt
            case =>
                null
        }

        if (result) {
            level tileGrid put(pos x, pos y, result)
        }

        result
    }

}

FrozenEntity: class {

    attrs := HashBag new()
    type: String
    pos: Vec2

    init: func (entity: Entity) {
        type = entity class name
        pos = vec2(entity pos)
        entity freeze(this)
    }

    unfreeze: func (level: Level) {
        entity := match type {
            case "Fire" =>
                Fire new(level, pos, false)
            case "Bomb" =>
                Bomb new(level, pos)
            case "Cobweb" =>
                Cobweb new(level, pos)
            case "CollectibleHeart" =>
                CollectibleHeart new(level, pos, HeartType RED, HeartValue HALF)
            case "CollectibleKey" =>
                CollectibleKey new(level, pos)
            case "CollectibleBomb" =>
                CollectibleBomb new(level, pos, BombType ONE)
            case "CollectibleCoin" =>
                CollectibleCoin new(level, pos, CoinType PENNY)
            case "CollectibleChest" =>
                CollectibleChest new(level, pos, ChestType REGULAR)
            case "TrapDoor" =>
                TrapDoor new(level, pos)
            case "Spikes" =>
                Spikes new(level, pos)
            case =>
                null
        }

        if (entity) {
            entity unfreeze(this)
            level add(entity)
        }
    }

    put: func <T> (key: String, value: T) {
        attrs put(key, value)
    }

    getBool: func (key: String, res: Bool*) {
        res@ = attrs get(key, Bool)
    }

    getFloat: func (key: String, res: Float*) {
        res@ = attrs get(key, Float)
    }

    getInt: func (key: String, res: Int*) {
        res@ = attrs get(key, Int)
    }

}

