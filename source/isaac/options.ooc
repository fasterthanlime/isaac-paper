
// third-party
use yaml
import yaml/[Document, Parser]

use gnaar
import gnaar/[utils]

Options: class {

    music := true
    mute := false
    testLevel := false

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
            }
        )
    }

}
