
// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use dye
import dye/[math]

// sdk stuff
import structs/[ArrayList, List, HashMap]
import io/[FileReader]
import math/Random

// our stuff
import isaac/[level, spider, sack, fly, hopper, trite, cobweb,
    fire, collectible, tiles]

Rooms: class {
    sets := HashMap<String, RoomSet> new()

    logger := static Log getLogger(This name)

    init: func {
        // floors
        load("basement")
        load("cellar")
        load("lust")

        // specials
        load("treasure")

        // bosses
        load("duke-of-flies")
        load("larry-jr")

        // testing
        load("test")
    }

    load: func (name: String) {
        logger info("Loading set %s", name)
        sets put(name, RoomSet new(name))
    }

}

RoomSet: class {
    name: String
    rooms := ArrayList<Room> new()

    logger := static Log getLogger(This name)

    init: func (=name) {
        read("assets/levels/%s.txt" format(name))
        logger info("Got %d rooms for room set %s", rooms size, name)
    }

    read: func (path: String) {
        lineno := 1

        reader := FileReader new(path)
        room := Room new()

        while (reader hasNext?()) {
            line := reader readLine()
            lineno += 1

            if (line size < 13) {
                if (reader hasNext?()) {
                    continue
                } else {
                    break
                }
            }

            if (line size != 13) {
                _err(path, lineno, "Expected 13 chars, got %d, '%s'" format(line size, line))
            }
            room rows add(line)

            if (room rows size >= 7) {
                line = reader readLine()
                lineno += 1

                if (line != "" && reader hasNext?()) {
                    _err(path, lineno, "Expected empty line, got '%s'" format(line))
                }
                rooms add(room)
                room = Room new()
            }
        }

        if (!rooms contains?(room) && room rows size == 7) {
            rooms add(room)
        }
    }

    _err: func (path: String, lineno: Int, message: String) {
        raise("[RoomSet] %s:%d - %s" format(path, lineno, message))
    }
}

Room: class {
    logger := static Log getLogger(This name)

    rows := ArrayList<String> new()

    width := 13
    height := 7

    init: func

    spawn: func (level: Level, onlyCreeps := false) {
        y := 0
        for (row in rows) {
            x := 0
            for (c in row) {
                spawn(x, height - 1 - y, c, level, onlyCreeps)
                x += 1
            }
            y += 1
        }
    }

    spawn: func ~specific (x, y: Int, c: Char, level: Level, onlyCreeps: Bool) {
        goodA := true
        goodB := true

        if (!onlyCreeps) {
            match c {
                case '.' || ' ' =>
                    // ignore
                case '#' =>
                    level tileGrid put(x, y, Block new(level, Random randInt(1, 3)))
                case 'c' =>
                    spawnCollectible(level gridPos(x, y), level)
                case 'p' =>
                    level tileGrid put(x, y, Poop new(level))
                case 'f' =>
                    level add(Fire new(level, level gridPos(x, y), false))
                case 'F' =>
                    level add(Fire new(level, level gridPos(x, y), true))
                case =>
                    goodA = false
            }
        }

        // now spawn all stuff enemy-like
        match c { 
            case 's' =>
                level add(Spider new(level, level gridPos(x, y)))
            case 'k' =>
                level add(Sack new(level, level gridPos(x, y)))
            case 'o' =>
                level add(Fly new(level, level gridPos(x, y), FlyType BLACK_FLY))
            case 'O' =>
                level add(Fly new(level, level gridPos(x, y), FlyType ATTACK_FLY))
            case '~' =>
                level add(Fly new(level, level gridPos(x, y), FlyType POOTER))
            case '^' =>
                level add(Fly new(level, level gridPos(x, y), FlyType FAT_FLY))
            case 'u' =>
                level add(Fly new(level, level gridPos(x, y), FlyType SUCKER))
            case 'U' =>
                level add(Fly new(level, level gridPos(x, y), FlyType SPIT))
            case '8' =>
                level add(Fly new(level, level gridPos(x, y), FlyType MOTER))
            case 'P' =>
                level add(Hopper new(level, level gridPos(x, y)))
            case 'Z' =>
                level add(Trite new(level, level gridPos(x, y)))
            case 'w' =>
                level add(Cobweb new(level, level gridPos(x, y)))
            case =>
                goodB = false
        }

        if (!goodA && !goodB) {
            logger warn("Unknown identifier: %c", c)
        }
    }

    spawnCollectible: func (pos: Vec2, level: Level) {
        number := Random randInt(0, 12)
        if (number < 4) {
            level add(CollectibleCoin new(level, pos))
        } else if (number < 6) {
            level add(CollectibleBomb new(level, pos))
        } else if (number < 8) {
            spawnHeart(pos, level) 
        } else {
            level add(CollectibleKey new(level, pos))
        }
    }

    spawnHeart: func (pos: Vec2, level: Level) {
        number := Random randInt(0, 100)
        type := HeartType RED
        value := HeartValue FULL

        if (number < 3) {
            type = HeartType ETERNAL
            value = HeartValue HALF
        } else if(number < 20) {
            type = HeartType SPIRIT
        } else {
            // 50/50 chance of half-heart
            if (Random randInt(0, 100) < 50) {
                value = HeartValue HALF
            }
        }

        level add(CollectibleHeart new(level, pos, type, value))
    }
}
