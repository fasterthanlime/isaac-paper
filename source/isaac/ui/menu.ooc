
// third-party stuff
use dye
import dye/[core, loop, input, primitives, math, sprite, text]

use deadlogger
import deadlogger/[Log, Logger]

use gnaar
import gnaar/[grid, utils]

// our stuff
import isaac/[game, options]

Menu: class {

    game: Game

    group: GlGroup
    bg: GlRectangle

    lightBg: GlRectangle

    enabled := false

    init: func (=game) {
        group = GlGroup new()

        screenSize := vec2(game dye size x, game dye size y)

        bg = GlRectangle new(screenSize)
        bg color set!(0, 0, 0)
        bg opacity = 0.5
        bg center = false
        group add(bg)


        lightBg = GlRectangle new(vec2(460, 330))
        lightBg color set!(226, 221, 220)
        lightBg pos set!(screenSize mul(0.5))
        group add(lightBg)

        group visible = false
        game menuGroup add(group)
    }

    setEnabled: func (=enabled) {
        group visible = enabled
    }

    update: func {
        // handle events and the shiznit
    }

}
