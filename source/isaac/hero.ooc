

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

// our stuff
import isaac/[level, tear]

/*
 * Dat Isaac...
 */
Hero: class extends Entity {

    sprite: GlSprite

    pos: Vec2
    speed := 200.0

    shape: CpShape
    body: CpBody

    shotSpeed := 400.0

    shootCount := 0

    shootRate := 1
    shootRateInv: Int { get { shootRate * 30 } }

    init: func (.level, .pos) {
        super(level)

        sprite = GlSprite new("assets/png/isaac-down.png")
        level group add(sprite)

        this pos = vec2(pos)
        sprite pos set!(pos)

        initPhysx()
    }

    update: func -> Bool {
        sprite sync(body)
        pos set!(body getPos())

        if (shootCount > 0) {
            shootCount -= 1
        }

        true
    }

    initPhysx: func {
        (width, height) := (50, 70)
        mass := 10.0
        moment := cpMomentForBox(mass, width, height)

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes HEROES)
        level space addShape(shape)
    }

    destroy: func {
        level space removeShape(shape)
        level space removeBody(body)
        level group remove(sprite)
    }

    move: func (dir: Vec2) {
        vel := dir mul(speed)
        body setVel(cpv(vel))
    }

    shoot: func (dir: Direction) {
        if (shootCount > 0) {
            return
        }

        shootCount = shootRateInv
        vel := match (dir) {
            case Direction RIGHT => vec2( 1, 0)
            case Direction LEFT  => vec2(-1, 0)
            case Direction DOWN  => vec2( 0,-1)
            case Direction UP    => vec2( 0, 1)
        }
        vel = vel mul(shotSpeed)

        level add(Tear new(level, pos, vel))
    }

}

