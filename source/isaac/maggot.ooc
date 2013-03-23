

// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

// sdk stuff
import math, math/Random

// our stuff
import isaac/[level, shadow, enemy, hero, utils, paths]

MaggotType: enum {
    MAGGOT
    CHARGER
    SPITY
}

MaggotState: enum {
    STROLL
    CHARGE
}

/**
 * Maggot.
 */
Maggot: class extends Enemy {

    rotateConstraint: CpConstraint

    type: MaggotType

    dir := Direction LEFT
    state := MaggotState STROLL

    sprite: MaggotSprite

    shadow: Shadow
    shadowFactor := 0.4
    shadowYOffset := 10

    init: func (.level, .pos, =type) {
        super(level, pos)

        life = match type {
            case MaggotType MAGGOT =>
                dir = Direction RIGHT
                12.0
            case MaggotType CHARGER =>
                dir = Direction UP
                20.0
            case MaggotType SPITY =>
                dir = Direction DOWN
                16.0
            case =>
                0.0 // dafuk?
        }

        sprite = MaggotSprite new(level, type)
        level charGroup add(sprite)

        shadow = Shadow new(level, 30)

        initPhysx()
    }

    update: func -> Bool {
        // TODO: physx

        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y)
        pos set!(bodyPos)
        sprite update(dir, state == MaggotState CHARGE)
        shadow setPos(pos sub(0, shadowYOffset))

        true
    }

    initPhysx: func {
        (width, height) := (40, 20)
        mass := 15.0
        moment := cpMomentForBox(mass, width, height)

        body = CpBody new(mass, moment)
        body setPos(cpv(pos))
        level space addBody(body)

        rotateConstraint = CpRotaryLimitJoint new(body, level space getStaticBody(), 0, 0)
        level space addConstraint(rotateConstraint)

        shape = CpBoxShape new(body, width, height)
        shape setUserData(this)
        shape setCollisionType(CollisionTypes ENEMY)
        level space addShape(shape)
    }

    setOpacity: func (opacity: Float) {
        sprite opacity = opacity
    }

    destroy: func {
        shadow destroy()
        level space removeShape(shape)
        shape free()
        level space removeBody(body)
        body free()
        level charGroup remove(sprite)
    }

}

MaggotSprite: class extends GlDrawable {

    level: Level
    type: MaggotType

    front, left, back: GlSprite
    frontCharging, leftCharging, backCharging: GlSprite

    current: GlSprite

    opacity := 1.0
    color := Color white()

    xswap := false

    init: func (=level, =type) {
        factor := 0.9
        scale set!(factor, factor)

        match type {
            case MaggotType MAGGOT =>
                front = loadSprite("maggot-front")
                left = loadSprite("maggot-left")
                back = loadSprite("maggot-back")

                // technically, maggots don't charge, so
                // we don't initialize the 'charging' variants
            case MaggotType CHARGER || MaggotType SPITY =>
                front = loadSprite("charger-front")
                left = loadSprite("charger-left")
                back = loadSprite("maggot-back") // they look similar
                frontCharging = loadSprite("charger-front")
                leftCharging = loadSprite("charger-left-charging") // filler
                backCharging = loadSprite("maggot-back")
        }
    }

    loadSprite: func (name: String) -> GlSprite {
        GlSprite new("assets/png/%s.png" format(name))
    }

    update: func (dir: Direction, charging: Bool) {
        match dir {
            case Direction UP    =>
                current = (charging ? backCharging : back) 
                xswap = false
            case Direction DOWN  =>
                current = (charging ? frontCharging : front) 
                xswap = false
            case Direction LEFT  =>
                current = (charging ? leftCharging : left) 
                xswap = false
            case Direction RIGHT =>
                current = (charging ? leftCharging : left) 
                xswap = true
        }
    }

    draw: func (dye: DyeContext, modelView: Matrix4) {
        if (current) {
            current opacity = opacity
            current color = color
            current scale x = xswap ? -1.0 : 1.0
            current render(dye, modelView)
        }
    }

}
