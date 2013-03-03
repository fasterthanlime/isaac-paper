
// third-party stuff
use chipmunk
import chipmunk

use dye
import dye/[core, math, input]

use gnaar
import gnaar/[utils]

use deadlogger
import deadlogger/[Log, Logger]

// sdk stuff
import structs/[List, ArrayList, HashMap]
import math/Random

// our stuff
import isaac/[game, hero]

Level: class {

    logger := static Log getLogger(This name)

    game: Game

    space: CpSpace
    physicSteps := 10
    entities := ArrayList<Entity> new()

    group: GlGroup

    dye: DyeContext { get { game dye } }
    input: Input { get { game dye input } }

    init: func (=game) {
        group = GlGroup new()

        initPhysx()

        add(Hero new(this, vec2(300, 300)))
    }

    initPhysx: func {
        space = CpSpace new()
    }

    add: func (e: Entity) {
        entities add(e)
    }

    update: func {
        updatePhysics()

        iter := entities iterator()
        while (iter hasNext?()) {
            e := iter next()
            if (!e update()) {
                iter remove()
                e destroy()
            }
        }
    }

    updatePhysics: func {
        timeStep: CpFloat = 1.0 / game loop fpsGoal
        realStep := timeStep / physicSteps as Float
        for (i in 0..physicSteps) {
            space step(realStep)
        }
    }

}

Entity: class {

    level: Level

    init: func (=level) {
    }

    update: func -> Bool {
        true
    }

    destroy: func {
    }

}

CollisionTypes: enum from Int {
    HEROES
    ENEMIES
    WALLS
}

