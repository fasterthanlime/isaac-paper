
// third-party stuff
use bleep
import bleep

// our stuff
import isaac/[game, options]

Music: class {

    game: Game
    bleep: Bleep { get { game bleep } }

    currentName: String

    init: func (=game)

    setMusic: func (name: String) {
        if (currentName == name) {
            return
        }

        currentName = name
        path := "assets/ogg/%s.ogg" format(name)

        if (game options music && !game options mute) {
            bleep playMusic(path, -1)
        }
    }

}
