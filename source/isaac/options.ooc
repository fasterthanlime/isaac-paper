
// third-party
use yaml
import yaml/[Document, Parser]

use gnaar
import gnaar/[utils]

Options: class {

    music := true
    mute := false

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
        music = map get("music") toBool()
        mute = map get("mute") toBool()
    }

}
