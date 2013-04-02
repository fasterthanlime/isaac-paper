
// third-party stuff
use dye
import dye/[core, math]

use gnaar
import gnaar/[utils]

// sdk stuff
import math, math/Random

// our stuff
import isaac/[level, enemy, utils]

FrictionBehavior: class {

    level: Level
    enemy: Enemy

    // adjustable parameters
    friction := 0.9
    alwaysApplies := false

    init: func (=enemy) {
        level = enemy level 
    }

    update: func {
        if (alwaysApplies || enemy grounded?()) {
            vel := enemy body getVel()
            vel x *= friction
            vel y *= friction
            enemy body setVel(vel)
        }
    }

}

