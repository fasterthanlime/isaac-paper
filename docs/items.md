
I'm trying to make Paper Isaac more of a "Binding of Isaac engine" and less of a
hardcoded clone. Also, having data files instead of hard code will make it easier
to reproduce the original - and later on, have mods that are completely different.

For that matter, here's a draft spec for a YAML-based item format for Paper Isaac.

### Basic idea

There are a few essential properties:

  * `image`: The image of the item as it appears on a pedestal
  and when Isaac picks it up
  * `icon`: A crude drawing of the item, as it appears in the pause and
  the game over screen
  * `type`: can be either `passive`, `pill`, `card`, `trinket`, or `spacebar`
  * `name`: the complete name of the item, for example `Anarchist Cookbook`
  * `quote`: a quote that appears when picking it up. For spacebar items, this is
  `Space to use` by default. Example: for Charm of the Vampire it's `Kills heal`

### Hooks

The hooks property is a map of strings to maps. The inner maps are effect names
and then their detail

The following hooks are available:

  * `pickup`: triggered when the item is picked up
  * `use`: for types `pill` and `card`, triggered when Q is pressed.
  For types `spacebar`, 
  * `enter`: triggered when entering any room
  * `clear`: triggered when the room is cleared
  * `floor`: triggered when a new floor is loaded
  * `hit`: triggered when Isaac takes damage

### Effects

#### Collectibles

  * `keys`: Picks up `number` keys
  * `bombs`: Picks up `number` bombs
  * `coins`: Picks up `number` coins
  * `hearts`: Spawns `red` red hearts, `spirit` spirit hearts,
  and `eternal` eternal hearts
  * `cards`: Spawn `number` regular cards
  * `tarotCards`: Spawn `number` tarot cards
  * `poop`: Spawn a poop

For example, the quarter could be implemented like that:

```yaml
image: something
icon: something
type: passive
name: A Quarter
quote: +25 Coins
hooks:
  pickup:
    coins:
      number: 25
```

#### Stats

  * `damage`: Increase/decrease damage by `number`
  * `firerate`: Increase/decrease fire rate by `number`
  * `range`: Increase/decrease range by `number`
  * `speed`: Increase/decrease speed by `number`
  * `containers`: Increase/decrease red heart containers
  by `number`
  * `heal`: Heal by `number` of red hearts (can be negative)

The property `mode`, by default set to `add`, can also take the
following values:

  * `set`: Sets the stat directly to `number`
  * `mul`: Multiply the stat by `number`

#### Tear modifiers

  * `ipecac`: Change isaac's tears to ipecac
  * `brimstone`: Change isaac's tears to brimstone
  * `serpentine`: Tear now serpentines
  * `reflection`: Effect from My Reflection
  * `laser`: Laser tears
  * `split`: Tears split when they hit something
  * `petrify`: Mom's contacts effect
  * `poison`: Poison shots
  * `poisontouch`: Poison touch
  * `bombshots`: Isaac shoots bombs
  * `missileshots`: Isaac shoots missiles
  * `piercing`: Piercing shots
  * `homing`: Homing shots

#### Other modifiers

  * `flylove`: Flies no longer harm you
  * `wafer`: Can only take one half-heart of damage at a time
  * `magnet`: Pulls collectibles towards Isaac

### Nested Effects

There are a few special effects which are listed here:

  * `onceEvery`: effect `effect` will apply once every `number` rooms
  * `withProba`: effect `effect` has a `percent` % chance of applying

For example, the relic could be implemented with:

```yaml
image: something
icon: something
type: passive
name: The Relic
hooks:
  clear:
    onceEvery:
      number: 4
      effect:
        hearts:
          spirit: 1
```

