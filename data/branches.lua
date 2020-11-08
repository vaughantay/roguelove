dungeonBranches = {}

local main = {
  name = "Dungeon",
  max_depth=3,
  depthName="Depth",
  mapTypes = {'dungeon','caves','forest'},
  possibleExits = {{branch="town",depth=1,replace_upstairs=true},{branch="demonruins",depth=1,min_depth=2,max_depth=3,name="Dark Portal"},{branch="swamp",min_depth=2,max_depth=3}},
  forceMapTypes = {},
  allMapsUnique=true,
  noBacktrack=false,
  hideDepth=false,
  hideName=false,
}
--{branch="branch",depth=1,min_depth=1,max_depth=1,replace_upstairs=false,replace_downstairs=false,exit_depth=1,oneway=false,chance=100}
dungeonBranches['main'] = main

local town = {
  name = "The Surface",
  max_depth=1,
  hideDepth=true,
  forceMapTypes={[1]="town"},
  creatures={"townsperson"},
}
dungeonBranches['town'] = town

local demonruins = {
  name = "Demon Ruins",
  max_depth=3,
  forceMapTypes = {[1]="lavacave",[2]="demonruins",[3]="demoncitadel"},
  mapTypes = {'lavacave','demonruins'},
  creatureTypes = {'demon'},
  creatureFactions = {'lightchurch'},
  creatureTags = {'demon','fire'},
  itemTags = {'magic','evil','demon','fire'},
  creatures = {},
  bosses = {},
  noBacktrack=false
}
dungeonBranches['demonruins'] = demonruins

local swamp = {
  name = "The Swamp",
  max_depth=2,
  noMapNames=true,
  mapTypes = {'swamp'},
  --nameType="swamp"
}
dungeonBranches['swamp'] = swamp