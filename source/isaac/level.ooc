
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
import isaac/[game, hero, walls]

Level: class {

    logger := static Log getLogger(This name)

    game: Game

    space: CpSpace
    physicSteps := 10

    entities := ArrayList<Entity> new()
    hero: Hero
    walls: Walls

    // layers
    floorGroup: GlGroup
    holeGroup: GlGroup
    blockGroup: GlGroup
    charGroup: GlGroup

    group: GlGroup

    dye: DyeContext { get { game dye } }
    input: Input { get { game dye input } }

    doorState := DoorState new()

    init: func (=game) {
        group = GlGroup new()

        initPhysx()

        hero = Hero new(this, vec2(300, 300))
        walls = Walls new(this)
    }

    initPhysx: func {
        space = CpSpace new()
    }

    add: func (e: Entity) {
        entities add(e)
    }

    updateEvents: func {

        // Hero movement
        dir := vec2(0, 0)
        if (input isPressed(KeyCode W)) {
            dir y = 1
        }
        if (input isPressed(KeyCode A)) {
            dir x = -1
        }
        if (input isPressed(KeyCode S)) {
            dir y = -1
        }
        if (input isPressed(KeyCode D)) {
            dir x = 1
        }
        hero move(dir)

        // Hero shots
        if (input isPressed(KeyCode RIGHT)) {
            hero shoot(Direction RIGHT)
        } else if (input isPressed(KeyCode DOWN)) {
            hero shoot(Direction DOWN)
        } else if (input isPressed(KeyCode UP)) {
            hero shoot(Direction UP)
        } else if (input isPressed(KeyCode LEFT)) {
            hero shoot(Direction LEFT)
        }
    }

    update: func {
        updatePhysics()
        updateEvents()

        hero update()

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

Direction: enum {
    LEFT
    RIGHT
    UP
    DOWN

    toString: func -> String {
        match this {
            case This UP => "up"
            case This DOWN => "down"
            case This LEFT => "left"
            case This RIGHT => "right"
            case => "<unknown direction>"
        }
    }
}

DoorState: class {
    up: Bool
    left: Bool
    right: Bool
    down: Bool

    init: func

    operator == (other: This) -> Bool {
        up == other up && \
        down == other down && \
        left == other left && \
        right == other right
    }

    operator != (other: This) -> Bool {
        !(this == other)
    }
}

