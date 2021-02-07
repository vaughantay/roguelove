dungeonBranches = {}

--Stairs: {branch="branch",depth=1,min_depth=1,max_depth=1,replace_upstairs=false,replace_downstairs=false,exit_depth=1,oneway=false,chance=100}

local main = {
  name = "Dungeon",
  max_depth=3,
  depthName="Depth",
  mapTypes = {'dungeon','caves','forest'},
  creatureTags={'mainbranch'},
  possibleExits = {{branch="town",depth=1,replace_upstairs=true},{branch="demonruins",depth=1,min_depth=2,max_depth=3,name="Dark Portal"}},
  forceMapTypes = {},
  allMapsUnique=true,
  noBacktrack=false,
  hideDepth=false,
  hideName=false,
}
dungeonBranches['main'] = main

local town = {
  name = "The Surface",
  max_depth=1,
  hideDepth=true,
  forceMapTypes={[1]="town"},
  creatures={"townsperson"}
}
dungeonBranches['town'] = town

local demonruins = {
  name = "Demon Ruins",
  max_depth=3,
  forceMapTypes = {[1]="lavacave",[2]="demonruins",[3]="demoncitadel"},
  mapTypes = {'lavacave','demonruins'},
  creatureTypes = {'demon'},
  creatureFactions = {'lightchurch'},
  creatureTags = {'demon','fire','demonruins'},
  itemTags = {'magic','unholy','demon','fire'},
  passedTags = {'holy','unholy','demon','fire'}, --These tags will be given priority for enchantments, and passed to items/creatures to do with what they will (ex: scrolls, to put preference on spells with these tags)
  creatures = {},
  bosses = {},
  noBacktrack=false
}
dungeonBranches['demonruins'] = demonruins

local wilderness = {
  name = "The Wilds",
  max_depth=2,
  noMapNames=true,
  mapTags = {'plants'},
  creatureTypes={'animal'}
}
dungeonBranches['wilderness'] = wilderness

local endgame = {
  name = "The Hall of Heroes",
  max_depth=1,
  hideDepth=true,
  noCreatures=true,
  noItems=true
}
dungeonBranches['endgame'] = endgame