dungeonBranches = {}

--Stairs: {branch="branch",depth=1,min_depth=1,max_depth=1,replace_upstairs=false,replace_downstairs=false,exit_depth=1,oneway=false,chance=100}

local main = {
  name = "Dungeon",
  max_depth=3,
  depthName="Depth",
  mapTypes = {'dungeon','caves','forest'},
  creatureTags={'mainbranch'},
  possibleExits = {{branch="town",depth=1,replace_upstairs=true},{branch="demonruins",min_depth=2,max_depth=3,name="Dark Portal"},{branch="endgame",depth=3,replace_downstairs=true}},
  forceMapTypes = {},
  allMapsUnique=true, --If this is set to true, map types will not be repeated when maps are created for this level
  noBacktrack=false, --If this is set to true, exits leading back to previous levels will not be created
  event_chance=50,
  event_cooldown=10,
  min_level_base=1,
  max_level_base=3,
  level_increase_per_depth=1,
}
dungeonBranches['main'] = main

local town = {
  name = "Town",
  max_depth=1,
  hideDepth=true, --Don't show the depth you're on when displaying the name of the map
  hideName=true, --If this is set to true, the name of the branch will not be shown when displaying the name of the map
  forceMapTypes={[1]="town"},
  possibleExits = {{branch="main",depth=1,replace_downstairs=true},{branch="wilderness",depth=1},{branch="graveyard",depth=1}},
  creatures={"townsperson"},
  factionTags={"organized"},
  min_level_base=0,
  max_level_base=0,
  level_increase_per_depth=0
}
dungeonBranches['town'] = town

local demonruins = {
  name = "Demon Ruins",
  max_depth=3,
  forceMapTypes = {[1]="lavacave",[2]="demonruins",[3]="demoncitadel"}, --Specific map types will be forced for the given depths
  mapTypes = {'lavacave','demonruins'}, --These map types will be used to generate levels in this branch
  creatureTypes = {'demon'}, --Creatures of these types will be added to the list of potential creatures in this branch
  creatureFactions = {'lightchurch'}, --Creatures belonging to these factions will be added to the list of potential creatures in this branch
  creatureTags = {'demon','fire','demonruins'}, --Creatures with these tags will be added to the list of potential creatures in this branch
  itemTags = {'magic','unholy','demon','fire'}, --Items with these tags will be added to the list of potential items in this branch
  passedTags = {'holy','unholy','demon','fire'}, --These tags will be given priority for enchantments, and passed to items/creatures to do with what they will (ex: scrolls, to put preference on spells with these tags)
  creatures = {}, --These specific creatures will be added to the list of potential creatures in this branch
  items = {}, --These specific items will be added to the list of potential items in this branch
  bosses = {},
  min_level_base=3,
  max_level_base=5,
  level_increase_per_depth=2,
  noBacktrack=false
}
dungeonBranches['demonruins'] = demonruins

local wilderness = {
  name = "The Wilds",
  max_depth=2,
  noMapNames=true,
  contentTags={"wild"}, -- This value will be used for any content tag list (ie creatureTags, itemTags, etc) unless a more specific tag list is set
  mapTags = {'plants'}, --Map types with these tags will be added to the list of map types possible in this branch
  creatureTypes={'animal'},
  possibleExits = {{branch="town",depth=1,replace_upstairs=true},{branch="main",depth=1}},
  forceMapTypes = {},
}
dungeonBranches['wilderness'] = wilderness

local graveyard = {
  name = "The Graveyard",
  max_depth=2,
  forceMapTypes = {[1]="graveyard",[2]="mausoleum"},
  mapTypes = {'graveyard','mausoleum'}, --These map types will be used to generate levels in this branch
  contentTags={"undead"}, -- This value will be used for any content tag list (ie creatureTags, itemTags, etc) unless a more specific tag list is set
  creatureTypes={'undead'},
  itemTags = {'magic','unholy','undead','vampire','death','necromancy'}, --Items with these tags will be added to the list of potential items in this branch
  passedTags = {'unholy','undead','vampire','death','necromancy'}, --These tags will be given priority for enchantments, and passed to items/creatures to do with what they will (ex: scrolls, to put preference on spells with these tags)
  min_level_base=1,
  max_level_base=3,
  level_increase_per_depth=3
}
dungeonBranches['graveyard'] = graveyard

local endgame = {
  name = "The Hall of Heroes",
  forceMapTypes = {[1]="endgame"},
  max_depth=1,
  hideName=true, --If this is set to true, the name of the branch will not be shown when displaying the name of the map
  hideDepth=true,
  noCreatures=true, --No creatures will be generated on this branch
  noItems=true, --No items will be generated on this branch
  noStores=true,
  noFactions=true
}
dungeonBranches['endgame'] = endgame