

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
    dummySprite: GlSprite

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

        dummySprite = GlSprite new("assets/png/cross.png")
        level charGroup add(dummySprite)
    }

    update: func -> Bool {
        // TODO: physx

        sprite pos set!(pos)
        sprite update(dir, state == MaggotState CHARGE)

        dummySprite pos set!(pos)

        true
    }

    setOpacity: func (opacity: Float) {
        sprite opacity = opacity
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

    myAngle := 0.0

    init: func (=level, =type) {
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

        if (type == MaggotType MAGGOT) {
            myAngle += 1.0
        } else {
            angle -= 1.0
        }
    }

    draw: func (dye: DyeContext, modelView: Matrix4) {
        // TODO: xswap support
        if (current) {
            current opacity = opacity
            current color = color
            current angle = myAngle
            current pos set!(32, 32)
            current render(dye, modelView)
        }
    }

}
