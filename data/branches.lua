dungeonBranches = {}

local demonruins = {
  name = "Demon Ruins",
  floors=3,
  forceMapTypes = {},
  mapTypes = {'lavacave','demonruins'},
  creatureTypes = {'demon'},
  creatureFactions = {'lightchurch'},
  creatureTags = {'demon','fire'},
  itemTags = {'magic','evil','demon','fire'},
  creatures = {},
  bosses = {},
  exits = {},
  noBacktrack=false
}
demonruins.forceMapTypes[1] = "lavacave"
demonruins.forceMapTypes[2] = "demonruins"
demonruins.forceMapTypes[3] = "demoncitadel"
dungeonBranches['demonruins'] = demonruins

local main = {
  name = "Dungeon",
  floors=3,
  floorName="Depth",
  mapTypes = {'dungeon','caves','forest'},
  exits = {}, --This has to be defined as an empty
  forceMapTypes = {},
  allMapsUnique=true,
  noBacktrack=false,
  hideFloor=false,
  hideName=false,
}
main.exits[1] = "town"
main.exits[2] = "demonruins"
dungeonBranches['main'] = main

local town = {
  name = "The Surface",
  floors=1,
  hideFloor=true,
  forceMapTypes={},
  creatures={"townsperson"},
}
town.forceMapTypes[1] = "town"
dungeonBranches['town'] = town