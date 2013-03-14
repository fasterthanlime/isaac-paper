
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
import structs/[ArrayList, List, HashMap]

// our stuff
import isaac/[game, level, bomb, tear, hero, map, plan, rooms, enemy]

BossType: enum {
    NONE

    // basement
    DUKE_OF_FLIES
    LARRY_JR
    GEMINI
    MONSTRO
    FAMINE
    STEVEN

    // cellar
    WIDOW
    PIN
    BLIGHTED_OVUM
    GURDY_JR

    // caves
    FISTULA
    GURDY
    PEEP
    CHUB
    PESTILENCE
    CHAD

    // catacombs
    CARRION_QUEEN
    HUSK
    HOLLOW
    WRETCHED
    
    // depths
    MONSTRO_2
    LOKI
    WAR
    GISH

    // necropolis
    MASK_OF_INFAMY
    DADDY_LONG_LEGS
    TRIACHNID
    BLOAT

    // final boss of depths/necropolis
    MOM

    // womb
    SCOLEX
    BLASTOCYST
    DEATH
    CONQUEST

    // utero
    TERATOMA
    LOKI_2

    // final boss of womb
    MOMS_HEART
    IT_LIVES

    // sheol
    SATAN

    // cathedral
    ISAAC

    // chest
    BLUE_BABY

    identifier: func -> String {
        match this {
            case This DUKE_OF_FLIES      => "duke-of-flies"
            case This LARRY_JR           => "larry-jr"
            case => "<unsupported boss %d>" format(this)
        }
    }

    pool: static func (floorType: FloorType) -> This[] {
        match floorType {
            case FloorType BASEMENT => basement()
            case FloorType CELLAR => cellar()
            case => basement() // fallback
        }
    }

    basement: static func -> This[] {
        return [
            This DUKE_OF_FLIES,
            This LARRY_JR
        ]
    }

    cellar: static func -> This[] {
        return [
            This DUKE_OF_FLIES,
            This LARRY_JR
        ]
    }
}

Boss: abstract class extends Entity {

    parts := ArrayList<Enemy> new()
    type: BossType

    init: func (.level, .pos, =type) {
        super(level, pos)
    }

    totalHealth: func -> Float {
        total := 0.0
        for (part in parts) {
            total += part life
        }
        total
    }

    dead?: func -> Bool {
        parts empty?()
    }

}

