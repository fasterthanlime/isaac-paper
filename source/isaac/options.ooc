
// third-party
use yaml
import yaml/[Document, Parser]

use gnaar
import gnaar/[utils]

Options: class {

    // legit options
    music := true
    mute := false

    /*===========================
     * cheats
     */

    // NOTE: If you're reading the code and came here for
    // cheats, it's really cheap of you and I'm equal parts
    // proud and disappointed. But seriously, the game is
    // more fun without cheating.

    // use "assets/levels/test.yml" for room layouts
    testLevel := false

    // reveal whole map all the time
    mapCheat := false

    // always spawn XL floors
    permaXL := false

    init: func {
        load()
    }

    load: func {
        optionsPath := "config/options.yml"
        doc := parseYaml(optionsPath)

        if (!doc) {
            // skip that shiznit
            return
        } 

        map := doc toMap()
        map each(|key, value|
            match key {
                case "music" =>
                    music = value toBool()
                case "mute" =>
                    mute = value toBool()
                case "testLevel" =>
                    testLevel = value toBool()
                case "mapCheat" =>
                    mapCheat = value toBool()
                case "permaXL" =>
                    permaXL = value toBool()
            }
        )
    }

}
