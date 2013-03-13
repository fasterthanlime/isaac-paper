
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
import isaac/[level, game, map]

Walls: class extends Entity {

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
        tile := level currentTile
        upDoor    setup(tile, tile neighbor( 0,  1))
        downDoor  setup(tile, tile neighbor( 0, -1))
        leftDoor  setup(tile, tile neighbor(-1,  0))
        rightDoor setup(tile, tile neighbor( 1,  0))
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

    group: GlGroup

    closedSprite: GlSprite
    holeSprite: GlSprite
    fgSprite: GlSprite

    shape: CpShape
    body: CpBody

    isaacHandler: static CollisionHandler

    walkthrough := false
    tile, connection: MapTile
    visible := false
    open := false

    opacityIncr := 0.05

    scale := 0.9

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

        group = GlGroup new()
        level doorGroup add(group)

        closedSprite = GlSprite new("assets/png/door-closed.png")
        closedSprite angle = dir toAngle()
        closedSprite pos set!(pos)
        closedSprite opacity = 1.0
        closedSprite scale set!(scale, scale)
        group add(closedSprite)

        holeSprite = GlSprite new("assets/png/door-hole.png")
        holeSprite angle = dir toAngle()
        holeSprite pos set!(pos)
        holeSprite opacity = 0.0
        holeSprite scale set!(scale, scale)
        group add(holeSprite)

        fgSprite = GlSprite new(getFgSpritePath())
        fgSprite angle = dir toAngle()
        fgSprite pos set!(pos)
        fgSprite scale set!(scale, scale)
        group add(fgSprite)

        initPhysx()
    }

    getFgSpritePath: func -> String {
        test := func (tile: MapTile) -> String {
            match tile {
                case null =>
                    "regular"
                case =>
                    match (tile type) {
                        case RoomType BOSS =>
                            "boss"
                        case RoomType TREASURE =>
                            "treasure"
                        case RoomType CURSE =>
                            "spikes"
                        case =>
                            "regular"
                    }
            }
        }

        name := test(connection)
        if (name == "regular") {
            name = test(tile)
        }

        "assets/png/door-%s.png" format(name)
    }

    updateFgSprite: func {
        fgSprite setTexture(getFgSpritePath())
    }

    setOpen: func (=open)

    initPhysx: func {
        body = CpBody new(INFINITY, INFINITY)
        body setPos(cpv(pos))

        length := 60
        thickness := 60
        size := match dir {
            case Direction UP || Direction DOWN =>
                vec2(length, thickness)
            case =>
                vec2(thickness, length)
        }

        shape = CpBoxShape new(body, size x, size y)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes WALL)
        level space addShape(shape)

        initHandlers()
    }

    initHandlers: func {
        if (!isaacHandler) {
            isaacHandler = IsaacDoorHandler new()
        }
        isaacHandler ensure(level)
    }
    
    setup: func (=tile, =connection) {
        visible = (connection != null)
        group visible = visible
        setOpen(false)
        updateFgSprite()
    }

    update: func -> Bool {
        if (walkthrough) {
            walkthrough = false
            level game changeRoom(dir)
        }

        if (level cleared?() && visible) {
            setOpen(true)
        }

        if (open && holeSprite opacity < 1.0) {
            holeSprite opacity += opacityIncr
        } else if (!open && holeSprite opacity > 0.0) {
            holeSprite opacity -= opacityIncr
        }

        true
    }

}

IsaacDoorHandler: class extends CollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        ent := shape2 getUserData() as Entity
        match ent {
            case door: Door =>
                if (door open) {
                    door walkthrough = true
                    return false
                } else {
                    return true
                }
        }

        true
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes HERO, CollisionTypes WALL)
    }

}

