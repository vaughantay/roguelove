creatureTypes = {
  demon = {
    name = "Demon",
    description = "A twisted creature from the infernal realms.",
    friendly_types = {},
    enemy_types = {"angel"},
    weaknesses = {holy=50},
    resistances = {unholy=100,fire=50},
    possible_death_items = {{item="demonblood",chance=100}}
  },
  angel = {
    name = "Angel",
    description = "A holy being birthed from the raw energy of creation.",
    friendly_types = {},
    enemy_types = {"demon","undead","abomination"},
    resistances = {holy=100},
    weaknesses = {unholy=50},
    possible_death_items = {}
  },
  undead = {
    name = "Undead",
    description = "A once-living creature, now animated by dark magic.",
    friendly_types = {},
    enemy_types = {},
    weaknesses = {holy=50},
    resistances = {unholy=50,poison=100},
    armor = {unholy=5}
  }
}