creatureTypes = {
  demon = {
    name = "Demon",
    description = "A twisted creature from the infernal realms.",
    friendlyTypes = {},
    enemyTypes = {"angel"},
    weaknesses = {holy=100},
    resistances = {unholy=100,fire=100},
    possible_death_items = {{item="demonblood",chance=100}}
  },
  undead = {
    name = "Undead",
    description = "A once-living creature, now animated by dark magic.",
    friendlyTypes = {},
    enemyTypes = {"angel"},
    weaknesses = {holy=50,fire=50},
    resistances = {unholy=50,poison=100}
  }
}