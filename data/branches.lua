dungeonBranches = {}

local demonruins = {
  name = "Demon Ruins",
  floors=3,
  forceMapTypes = {},
  mapTypes = {'lavacave','demonruins'},
  creatureTags = {'demon','fire'},
  itemTags = {'magic','evil','demon','fire'},
  creatures = {},
  bosses = {},
  exits = {},
  noBacktrack=false
}
demonruins.forceMapTypes[3] = "demoncitadel"
dungeonBranches['demonruins'] = demonruins

local main = {
  name = "Dungeon",
  floors=3,
  mapTypes = {'dungeon','caves','forest'},
  exits = {},
  forceMapTypes = {},
  noBacktrack=false,
  allMapsUnique=true
}
main.exits[2] = "demonruins"
dungeonBranches['main'] = main