
// sdk stuff
import structs/[ArrayList, List, HashMap]
import math/Random

import isaac/[game, options]

Plan: class {

    // cf. http://bindingofisaac.wikia.com/wiki/Curses#Chances_for_a_Curse_to_happen
    // we assume everything is unlocked for now
    XL_CHANCE := static 20

    floors := ArrayList<PlanFloor> new()

    init: func

    generate: static func (game: Game) -> This {
        floorPair := func (plan: This, a, b: FloorType) {
            // xl or not?
            if (Random randInt(0, 100) < XL_CHANCE || game options permaXL) {
                // a xl or b xl ?
                type := a
                if (Random randInt(0, 100) < 50) {
                    type = b
                }

                plan floors add(PlanFloor new(type, true, 0))
            } else {
                // a or b?
                type := a
                if (Random randInt(0, 100) < 50) {
                    type = b
                }

                plan floors add(PlanFloor new(type, false, 0))

                // aaand again.
                type = a
                if (Random randInt(0, 100) < 50) {
                    type = b
                }

                plan floors add(PlanFloor new(type, false, 1))
            }
        }

        plan := This new()
        floorPair(plan, FloorType BASEMENT, FloorType CELLAR)
        floorPair(plan, FloorType CAVES, FloorType CATACOMBS)
        floorPair(plan, FloorType DEPTHS, FloorType NECROPOLIS)
        floorPair(plan, FloorType WOMB, FloorType UTERO)

        plan
    }

    toString: func -> String {
       "[%s]" format(floors map(|f| f toString()) join(", "))
    }

}

PlanFloor: class {

    type: FloorType
    xl := false
    pairIndex := 0

    init: func (=type, =xl, =pairIndex)

    toString: func -> String {
        if (xl) {
            "%s XL" format(type toString())
        } else {
            "%s %d" format(type toString(), pairIndex + 1)
        }
    }

    hard?: func -> Bool {
        // from the womb / utero - it's a hard floor
        type level() >= 3
    }

}

FloorType: enum {
    BASEMENT
    CELLAR
    CAVES
    CATACOMBS
    DEPTHS
    NECROPOLIS
    WOMB
    UTERO
    SHEOL
    CATHEDRAL
    CHEST

    identifier: func -> String {
        match this {
            case This BASEMENT   => "basement"
            case This CELLAR     => "cellar"

            case This CAVES      => "caves"
            case This CATACOMBS  => "catacombs"

            case This DEPTHS     => "depths"
            case This NECROPOLIS => "necropolis"

            case This WOMB       => "womb"
            case This UTERO      => "utero"

            case This SHEOL      => "sheol"
            case This CATHEDRAL  => "cathedral"

            case This CHEST      => "chest"

            case => "<unknown floor type>"
        }
    }

    toString: func -> String {
        match this {
            case This BASEMENT   => "Basement"
            case This CELLAR     => "Cellar"

            case This CAVES      => "Caves"
            case This CATACOMBS  => "Catacombs"

            case This DEPTHS     => "The Depths"
            case This NECROPOLIS => "Necropolis"

            case This WOMB       => "The Womb"
            case This UTERO      => "Utero"

            case This SHEOL      => "Sheol"
            case This CATHEDRAL  => "Cathedral"

            case This CHEST      => "Chest"

            case => "<unknown floor type>"
        }
    }

    level: func -> Int {
        match this {
            case This BASEMENT   => 0
            case This CELLAR     => 0

            case This CAVES      => 1
            case This CATACOMBS  => 1

            case This DEPTHS     => 2
            case This NECROPOLIS => 2

            case This WOMB       => 3
            case This UTERO      => 3

            case This SHEOL      => 4
            case This CATHEDRAL  => 4

            case This CHEST      => 5
            case => -1
        }
    }

    budget: func -> Int {
        match this {
            case This BASEMENT   => 9
            case This CELLAR     => 9

            case This CAVES      => 11
            case This CATACOMBS  => 11

            case This DEPTHS     => 13
            case This NECROPOLIS => 13

            case This WOMB       => 15
            case This UTERO      => 15

            case This SHEOL      => 17
            case This CATHEDRAL  => 17

            case This CHEST      => 19
            case => 9
        }
    }
}

