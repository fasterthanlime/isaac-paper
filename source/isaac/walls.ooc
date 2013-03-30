
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
import isaac/[level, game, map, bomb, plan, explosion, hero]

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
        ulk := vec2(75, 300)
        urk := vec2(725, 300)

        // bottom center
        blk := vec2(75, 200)
        brk := vec2(725, 200)

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
        tile := level tile
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

    eachInRadius: func (pos: Vec2, radius: Float, f: Func (Entity)) {
        level _radiusTest(upDoor, pos, radius, f)
        level _radiusTest(downDoor, pos, radius, f)
        level _radiusTest(leftDoor, pos, radius, f)
        level _radiusTest(rightDoor, pos, radius, f)
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

    opacityIncr := 0.075

    scale := 1.0

    padding := 30

    init: func (=level, =dir) {
        match dir {
            case Direction UP =>
                pos = vec2(400, 425 + padding)
            case Direction DOWN =>
                pos = vec2(400, 75 - padding)
            case Direction LEFT =>
                pos = vec2(75 - padding, 250)
            case Direction RIGHT =>
                pos = vec2(725 + padding, 250)
        }
        super(level, pos)

        group = GlGroup new()
        level doorGroup add(group)

        closedSprite = GlSprite new(getClosedSpritePath())
        closedSprite angle = dir toAngle()
        closedSprite pos set!(pos)
        closedSprite opacity = 1.0
        closedSprite scale set!(scale, scale)
        group add(closedSprite)

        holeSprite = GlSprite new("assets/png/door-hole.png")
        holeSprite color set!(128, 128, 128)
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

    updateGfx: func {
        fgSprite setTexture(getFgSpritePath())
        closedSprite setTexture(getClosedSpritePath())
    }

    holeVisible?: func -> Bool {
        open && (!connection || !connection locked)
    }

    walkable?: func -> Bool {
        if (!open) {
            // closed? (ie. in combat) - no good
            return false
        }

        if (connection && connection locked) {
            if (level game heroStats keyCount <= 0) {
                // if locked & no key, no good
                return false
            }
        }

        // all good
        true
    }

    getClosedSpritePath: func -> String {
        if (connection && connection locked) {
            "assets/png/door-locked.png"
        } else {
            "assets/png/door-closed.png"
        }
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

    setOpen: func (=open)

    initPhysx: func {
        body = CpBody new(INFINITY, INFINITY)
        body setPos(cpv(pos))

        length := 100
        thickness := padding * 2
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
        updateGfx()
    }

    update: func -> Bool {
        if (walkthrough) {
            walkthrough = false
            if (connection locked) {
                level game heroStats useKey()
                connection locked = false
            }
            level game changeRoom(dir)
        }

        if (level cleared?() && visible) {
            setOpen(true)
        }

        holeVisible := holeVisible?()
        if (holeVisible) {
            if (holeSprite opacity < 1.0) {
                holeSprite opacity += opacityIncr
            } else {
                holeSprite opacity = 1.0
            }
        } else if (!holeVisible) {
            if (holeSprite opacity > 0.0) {
                holeSprite opacity -= opacityIncr
            } else {
                holeSprite opacity = 0.0
            }
        }

        true
    }

    bombHarm: func (explosion: Explosion) {
        if (!visible) {
            // TODO: what about secret rooms?
            return
        }

        if (blowable?()) {
            // fuck yeah
            setOpen(true)
        }
    }

    blowable?: func -> Bool {
        if (connection type == RoomType BOSS || tile type == RoomType BOSS) {
            // either one is a boss room, you're fucked.
            return false
        }

        if (level game floor type == FloorType CHEST) {
            // HAHA. You can't bomb anything in the chest
            return false
        }

        // TODO: what if it's locked?
        true
    }

}

IsaacDoorHandler: class extends CollisionHandler {

    preSolve: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        hero := shape1 getUserData() as Hero
        ent := shape2 getUserData() as Entity
        match ent {
            case door: Door =>
                if (door walkable?()) {
                    if (hero door == door) {
                        // all good
                    } else {
                        hero door = door
                        hero doorCount = 0
                    }

                    if (hero doorCount > hero doorCountThreshold) {
                        hero doorCount = 0
                        door walkthrough = true
                    }
                    return false
                }
                return true
        }

        true
    }

    separate: func (arbiter: CpArbiter, space: CpSpace) {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        hero := shape1 getUserData() as Hero
        ent := shape2 getUserData() as Entity
        match ent {
            case door: Door =>
                if (hero door == door) {
                    hero door = null
                    hero doorCount = 0
                }
        }
    }

    add: func (f: Func (Int, Int)) {
        f(CollisionTypes HERO, CollisionTypes WALL)
    }

}

