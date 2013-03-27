

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
import isaac/[level, shadow, enemy, hero, utils, paths,
    tear]
import isaac/behaviors/[strollbehavior]

MaggotType: enum {
    MAGGOT
    CHARGER
    SPITY
}

/**
 * Maggot.
 */
Maggot: class extends Enemy {

    type: MaggotType

    sprite: MaggotSprite

    shadow: Shadow
    shadowYOffset := 13

    behavior: StrollBehavior

    init: func (.level, .pos, =type) {
        super(level, pos)

        sprite = MaggotSprite new(level, type)
        level charGroup add(sprite)

        shadow = Shadow new(level, 30)
        behavior = StrollBehavior new(level, this)

        life = match type {
            case MaggotType MAGGOT =>
                behavior canCharge = false
                20.0
            case MaggotType CHARGER =>
                30.0
            case MaggotType SPITY =>
                behavior canCharge = false
                30.0
            case =>
                0.0 // dafuk?
        }

        createBox(40, 40, 15.0)

        // maggots go through each other
        shape setGroup(CollisionGroups MAGGOT)
    }

    update: func -> Bool {
        bodyPos := body getPos()
        sprite pos set!(bodyPos x, bodyPos y)
        pos set!(bodyPos)
        sprite update(behavior dir, behavior charging?())
        shadow setPos(pos sub(0, shadowYOffset))

        behavior update()

        super()
    }

    hitBack: func (tear: Tear) {
        return
    }

    setColor: func (r, g, b: Int) {
        sprite color set!(r, g, b)
    }

    setOpacity: func (opacity: Float) {
        sprite opacity = opacity
    }

    destroy: func {
        shadow destroy()
        level charGroup remove(sprite)

        super()
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
