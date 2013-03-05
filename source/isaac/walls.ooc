
// third-party stuff
use dye
import dye/[sprite, math]

use gnaar
import gnaar/[utils]

use chipmunk
import chipmunk

// sdk stuff
import structs/[ArrayList, List, HashMap]

// our stuff
import isaac/[level, game]

Walls: class extends Entity {

    doorState := DoorState new()
    shapes := ArrayList<CpShape> new()

    upDoor, downDoor, leftDoor, rightDoor: Door

    init: func (.level) {
        super(level, vec2(0, 0))

        initDoors()
        initPhysx()
        setup()
    }

    initDoors: func {
        upDoor    = Door new(level, Direction UP)
        leftDoor  = Door new(level, Direction LEFT)
        rightDoor = Door new(level, Direction RIGHT)
        downDoor  = Door new(level, Direction DOWN)
    }

    initPhysx: func {
        //  ul    ulc     urc    ur
        //
        // 
        // ulk                   urk
        //
        // blk                   brk
        //
        //
        //  bl    blc     brc    br

        // upper <--->
        ul  := vec2(75, 425)
        ulc := vec2(360, 425)
        urc := vec2(430, 425)
        ur  := vec2(725, 425)

        // upper center
        ulk := vec2(75, 280)
        urk := vec2(725, 280)

        // bottom center
        blk := vec2(75, 220)
        brk := vec2(725, 220)

        // bottom <--->
        bl  := vec2(75, 75)
        blc := vec2(360, 75)
        brc := vec2(430, 75)
        br  := vec2(725, 75)

        createSegment(ul, ulc)
        createSegment(urc, ur)
        createSegment(ur, urk)
        createSegment(brk, br)

        createSegment(br, brc)
        createSegment(blc, bl)
        createSegment(bl, blk)
        createSegment(ulk, ul)
    }

    createSegment: func (p1, p2: Vec2) {
        shape := CpSegmentShape new(level space getStaticBody(), cpv(p1), cpv(p2), 1.0)
        shape setFriction(0.9)
        shape setElasticity(0.9)
        shape setCollisionType(CollisionTypes WALL)
        level space addShape(shape)
        shapes add(shape)
    }

    setup: func {
        upDoor setup(level currentTile hasTop?())
        downDoor setup(level currentTile hasBottom?())
        leftDoor setup(level currentTile hasLeft?())
        rightDoor setup(level currentTile hasRight?())
    }

    update: func -> Bool {
        upDoor update()
        downDoor update()
        leftDoor update()
        rightDoor update()

        true
    }

}

Door: class extends Entity {

    dir: Direction

    sprite: GlSprite

    shape: CpShape
    body: CpBody

    init: func (=level, =dir) {
        match dir {
            case Direction UP =>
                pos = vec2(400, 600 - 100 - 75 + 30)
            case Direction DOWN =>
                pos = vec2(400, 75 - 30)
            case Direction LEFT =>
                pos = vec2(40, 75 + 170)
            case Direction RIGHT =>
                pos = vec2(800 - 40, 75 + 170)
        }
        super(level, pos)

        sprite = GlSprite new("assets/png/door-%s.png" format(dir toString()))
        sprite pos set!(pos)
        level doorGroup add(sprite)

        initPhysx()
    }

    initPhysx: func {
        body = CpBody new(INFINITY, INFINITY)
        body setPos(cpv(pos))

        size := match dir {
            case Direction UP || Direction DOWN =>
                vec2(100, 30)
            case =>
                vec2(30, 100)
        }

        shape = CpBoxShape new(body, 50, 50)
        shape setUserData(this)
        level space addShape(shape)
    }
    
    setup: func (visible: Bool) {
        sprite visible = visible
    }

}

