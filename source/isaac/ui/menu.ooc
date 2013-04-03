
// third-party stuff
use dye
import dye/[core, loop, input, primitives, math, sprite, text]

use deadlogger
import deadlogger/[Log, Logger]

use gnaar
import gnaar/[grid, utils]

// sdk stuff
import structs/[ArrayList, List]

// our stuff
import isaac/[game, options]

Menu: class {

    game: Game

    group: GlGroup
    bg: GlRectangle

    lightBg: GlRectangle

    enabled := false

    screenSize: Vec2
    menuSize: Vec2
    bottomLeft: Vec2

    clickables := ArrayList<Clickable> new()

    init: func (=game) {
        group = GlGroup new()
        group visible = false
        game menuGroup add(group)

        screenSize = vec2(game dye size x, game dye size y)

        bg = GlRectangle new(screenSize)
        bg color set!(0, 0, 0)
        bg opacity = 0.5
        bg center = false
        group add(bg)

        menuSize = vec2(460, 330)
        bottomLeft = screenSize mul(0.5) sub(menuSize mul(0.5))

        lightBg = GlRectangle new(menuSize)
        lightBg color set!(226, 221, 220)
        lightBg pos set!(screenSize mul(0.5))
        group add(lightBg)

        {
            clickable := Clickable new(this, "paused",
                vec2(0, menuSize y - 30))
            clickable clickable = false
            addClickable(clickable)
        }

        {
            clickable := Clickable new(this, "exit-to-main-menu",
                vec2(0, 70))
            addClickable(clickable)
        }
    }

    addClickable: func (clickable: Clickable) {
        clickables add(clickable)
        group add(clickable group)
    }

    setEnabled: func (=enabled) {
        group visible = enabled
    }

    update: func {
        // handle events and the shiznit

        for (c in clickables) {
            c update()
        }
    }

}

Clickable: class {

    name: String

    group: GlGroup
    sprite: GlSprite

    menu: Menu

    pos: Vec2

    clickable := true

    init: func (=menu, =name, offset: Vec2) {
        group = GlGroup new()

        pos = vec2(
            menu screenSize x * 0.5 + offset x,
            menu bottomLeft y + offset y
        )

        path := "assets/png/menu-%s.png" format(name)
        sprite = GlSprite new(path)
        group add(sprite)

        if (!clickable) {
            sprite opacity = 0.6
        }

        group pos set!(pos)
    }

    update: func {
        if (!clickable) {
            return
        }

        // do stuff
    }

}

