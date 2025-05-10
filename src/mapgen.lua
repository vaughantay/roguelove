---@module mapgen
mapgen = {}

---Create and populate a map
--@param branchID Text. The branch ID the map is part of
--@param depth Number. At what depth of said branch the map occurs on
--@param force Text. The ID of a mapType to force this map to be. Optional
--@return Map. The fresh new map
function mapgen:generate_map(branchID, depth,force)
  --set the random generator to use the seeded generator
  local mapRandom = love.math.newRandomGenerator(currGame.seed)
  if currGame.seedState then mapRandom:setState(currGame.seedState) end
  random = function(...) return mapRandom:random(...) end

  local branch = currWorld.branches[branchID]
  local forceMapType = branch.forceMapTypes and branch.forceMapTypes[depth]
  if not forceMapType and force then forceMapType = force end --game will default to the branch's forced maps. But if the game definition has no forced map, then you can potentially pass in a forced map instead
  local whichMap = nil
  local id = nil
  local mapTypeIndex
  if forceMapType then --If forced map creation, assign the ID as appropriate
    if forceMapType and mapTypes[forceMapType] then -- if the branch is forcing us to use a specific map
      id = forceMapType
    end
    whichMap = mapTypes[id]
  else --Non-forced map generation:
    mapTypeIndex = get_random_key(branch.mapTypes)
    id = branch.mapTypes[mapTypeIndex]
    whichMap = mapTypes[id]
  end

  --Figure out width and height. Order of preference: 1) mapType's dimensions, 2) branch's map dimensions, 3) game's default map dimensions
  local width,height = whichMap.width or branch.mapWidth or gamesettings.default_map_width, whichMap.height or branch.mapHeight or gamesettings.default_map_height
  if whichMap.min_width and whichMap.max_width then --if the branch has random values, use those
    width = random(whichMap.min_width,whichMap.max_width)
  elseif not whichMap.width and branch.min_map_width and branch.max_map_width then --if the map doesn't definine a specific width, but the branch has a random map width, use the branch's min and max values
    width = random(branch.min_map_width,branch.max_map_width)
  end
  if whichMap.min_height and whichMap.max_height then
    width = random(whichMap.min_width,whichMap.max_width)
  elseif not whichMap.height and branch.min_map_height and branch.max_map_height then --if the map doesn't definine a specific width, but the branch has a random map width, use the branch's min and max values
    width = random(branch.min_map_height,branch.max_map_height)
  end

  --Basic initialization of empty map
  local pTime = os.clock()
  print('generating map for branch:',branch.id,'depth:',depth,'mapType:',id)
  local build = Map(width,height)
  build.depth = depth
  build.branch = branchID
  build.branchType = branch.id
  build.id = branchID .. "_" .. depth --the ID for this individual map
  build.mapType = id --the ID of the mapType used to create the map
  --End initialization
  --Pull over the mapType's info
  if not branch.noMapNames then build.name = whichMap.name or (whichMap.generateName and whichMap.generateName()) or (whichMap.nameType and namegen:generate_name(whichMap.nameType)) or false end
  build.fullName = build:get_name()
  build.description = whichMap.description or (whichMap.generateDesc and whichMap.generateDesc()) or (whichMap.descType and namegen:generate_description(whichMap.descType)) or false
  build.bossID = whichMap.bossID or (branch.bossIDs and branch.bossIDs[depth])
  build.tileset = whichMap.tileset or branch.tileset or "default"
  build.playlist = whichMap.playlist or id
  build.bossPlaylist = whichMap.bossPlaylist or id .. "boss"
  build.lit = whichMap.lit or branch.lit
  build.noCreatures = whichMap.noCreatures or branch.noCreatures
  build.noItems = whichMap.noItems or branch.noItems
  build.noStores = whichMap.noStores or branch.noStores
  build.noFactions = whichMap.noFactions or branch.noFactions
  build.noRooms = whichMap.noRooms or branch.noRooms
  build.noExits = whichMap.noExits or branch.noExits
  build.noBoss = whichMap.noBoss or branch.noBosses
  build.noDesc = whichMap.noDesc or branch.noDesc
  build.generate_boss_on_entry = whichMap.generate_boss_on_entry or branch.generate_boss_on_entry
  build.event_chance = whichMap.event_chance or branch.event_chance
  build.event_cooldown = whichMap.event_cooldown or branch.event_cooldown
  build.enchantment_chance = whichMap.enchantment_chance or branch.enchantment_chance
  build.artifact_chance = whichMap.artifact_chance or branch.artifact_chance
  build.tags = whichMap.tags or {}
  build.contentTags = copy_table(whichMap.contentTags or {})
  build.creatureTags = copy_table(whichMap.creatureTags or {})
  build.itemTags = copy_table(whichMap.itemTags or {})
  build.factionTags = copy_table(whichMap.factionTags or {})
  build.roomTags = copy_table(whichMap.roomTags or {})
  build.storeTags = copy_table(whichMap.storeTags or {})
  build.passedTags = copy_table(whichMap.passedTags or {})
  build.requiredTags = copy_table(whichMap.requiredTags or {})
  build.forbiddenTags = copy_table(whichMap.forbiddenTags or {})
  build.timeTags = copy_table(whichMap.timeTags or {})
  build.forbid_faction_events = whichMap.forbid_faction_events or branch.forbid_faction_events
  build.above_ground = whichMap.above_ground or branch.above_ground
  build.aware_factions = whichMap.aware_factions or branch.aware_factions
  build.resident_factions = whichMap.resident_factions or branch.resident_factions
  build.resident_use_faction_reputation = whichMap.resident_use_faction_reputation or branch.resident_use_faction_reputation
  build.trespassing = whichMap.trespassing or branch.trespassing
  build.disguise_impressions = whichMap.disguise_impressions or branch.disguise_impressions
  build.trespassing_impressions = whichMap.trespassing_impressions or branch.trespassing_impressions
  build.bonuses = whichMap.bonuses or branch.bonuses
  build.wall_feature = whichMap.wall_feature or branch.wall_feature
  --Generate the map itself:
  local success = true
  if whichMap.create then
    print('running create() code')
    success = whichMap.create(build,width,height)
  elseif whichMap.layouts then
    local whichLayout = get_random_element(whichMap.layouts)
    local whichModifier = whichMap.modifiers and get_random_element(whichMap.modifiers) or false
    print('creating via layout',whichLayout)
    success = layouts[whichLayout](build)
    if success ~= false and whichModifier then
      print('applying modifier',whichModifier)
      local args = whichMap.modifier_arguments and whichMap.modifier_arguments[whichModifier] or {}
      if mapModifiers[whichModifier](build,unpack(args)) == false then
        print('failed to apply modifier')
      end
    end
  end
  if success == false then
    print('failed to create map, trying again')
    return mapgen:generate_map(branchID, depth,force)
  end
  --Add tombstones:
  if gamesettings.player_tombstones then mapgen:addTombstones(build) end
  --Add the pathfinder:
  build:refresh_pathfinder()
  -- define where the stairs should do, if they're not already added
  if (build.stairsUp.x == 0 or build.stairsUp.y == 0 or build.stairsDown.x == 0 or build.stairsDown.y == 0) then
    --build.stairsUp = {x=5,y=5}
    --build.stairsDown = {x=10,y=10}
    print('making generic stairs',build.stairsUp.x,build.stairsUp.y,build.stairsDown.x,build.stairsDown.y)
    local s = mapgen:addGenericStairs(build,width,height,depth)
    if s == false then
      currGame.seedState = mapRandom:getState()
      random = love.math.random
      return mapgen:generate_map(branchID, depth,force)
    end
  end --end if stairs already exist

  --Add exits:
  if not build.noExits then
    print('adding exits')
    local branchDirection = branch.stair_direction or gamesettings.default_stair_direction or "down"
    --Do generic up and down stairs first, although they may be replaced by other exits later:
    local up_depth = (branchDirection == "down" and (build.depth == 1 and -1 or build.depth-1) or (build.depth == -1 and 1 or build.depth+1))
    local down_depth = (branchDirection == "down" and (build.depth == -1 and 1 or build.depth+1) or (build.depth == 1 and -1 or build.depth-1))
    local can_up = (up_depth >= (branch.min_depth or 1) and up_depth <= (branch.max_depth or 1)) or (branchDirection == "down" and build.infinite_negative_depth) or (branchDirection == "up" and build.infinite_depth)
    local can_down = (down_depth >= (branch.min_depth or 1) and down_depth <= (branch.max_depth or 1)) or (branchDirection == "down" and build.infinite_depth) or (branchDirection == "up" and build.infinite_negative_depth)
    
    if can_up then
      local upStairs = Feature('exit',{branch=build.branch,depth=up_depth})
      build:add_feature(upStairs,build.stairsUp.x,build.stairsUp.y)
    end
    if can_down then
      local downStairs = Feature('exit',{branch=build.branch,depth=down_depth})
      build:add_feature(downStairs,build.stairsDown.x,build.stairsDown.y)
    end
    if branch.exits[build.depth] then
      for depth,exit in pairs(branch.exits[build.depth]) do
        local whichX,whichY = nil,nil
        if exit.replace_upstairs then
          whichX,whichY = build.stairsUp.x,build.stairsUp.y
        elseif exit.replace_downstairs then
          whichX,whichY = build.stairsDown.x,build.stairsDown.y
        end
        if not whichX or not whichY then
          whichX,whichY = self:get_stair_location(build)
        end
        local branchStairs = Feature('exit',{branch=exit.branch,depth=exit.exit_depth or 1,oneway=exit.oneway,name=exit.name})
        build:add_feature(branchStairs,whichX,whichY)
        --TODO: make sure non-oneway exits are reciprocal
      end
    end
  end

  --Add content:
  build:populate_stores()
  build:populate_factions()
  build:populate_creatures()
  build:populate_items()
  build:refresh_pathfinder()

  if whichMap.start_revealed or branch.start_revealed then
    build:reveal()
  end

  --if the branch doesn't allow repeated levels
  if branch.allMapsUnique then
    table.remove(branch.mapTypes,mapTypeIndex)
  end
  
  if build.wall_feature then
    for x=1,build.width,1 do
      for y=1,build.height,1 do
        if build[x][y] == "#" then
          build:change_tile(Feature(build.wall_feature),x,y)
        end
      end
    end
  end

  if not branch.maps then branch.maps = {} end
  branch.maps[depth] = build
  print('total creation time:',tostring(os.clock()-pTime))
  return build
end

---Initializes and creates a new creature at the given level. The creature itself must then actually be added to a map using Map:add_creature()
--@param min_level The lower level limit of the desired creature
--@param max_level The upper level limit of the desired creature
--@param list Table. A specific list of creatures to choose from. Optional
--@param tags Table. A list of tags to pass to the creature
--@param allowAll Boolean. If True, creatures with the specialOnly flag can still be chosen (but bosses or creatures with the neverSpawn flag set still cannot). Optional
--@return Creature. The new creature
function mapgen:generate_creature(min_level,max_level,list,tags,allowAll)
  if not list then return false end

  --Prevent an infinite loop if there are no creatures of a given level:
  local noCreatures = true
  for _,cid in pairs(list) do
    local creat = (type(cid) == "table" and cid or possibleMonsters[cid] or nil)
    local meets_min = not min_level or not creat.level or creat.level >= min_level or not creat.max_level or (creat.max_level and creat.max_level >= min_level)
    local meets_max = not max_level or not creat.level or creat.level <= max_level
    
    if creat and not creat.isBoss and not creat.neverSpawn and meets_min and meets_max then 
      noCreatures = false
      break
    end
  end
  if noCreatures == true then return false end

  -- This selects a random creature from the table of possible creatures, and compares the desired creature level to this creature's level. If it's a match, continue, otherwise select another one
  while (1 == 1) do -- endless loop, broken by the "return"
    local n = get_random_element(list)
    local creat = (type(n) == "table" and n or possibleMonsters[n])
    local meets_min = not min_level or not creat.level or creat.level >= min_level or not creat.max_level or (creat.max_level and creat.max_level >= min_level)
    local meets_max = not max_level or not creat.level or creat.level <= max_level
    
    if creat and not creat.isBoss and not creat.neverSpawn and random(1,100) >= (creat.rarity or 0) and meets_min and meets_max then
      local min = math.max((creat.level or min_level or 1),(min_level or creat.level or 1))
      local max = math.min((creat.max_level or creat.level or max_level or min_level or 1),(max_level or creat.max_level or creat.level or min_level or 1))
      local level = random(min,max)
      return Creature(n,level,tags)
    end
  end
end

---Initializes and creates a new item at the given level. The item itself must then actually be added to the map using Map:add_item()
--@param min_level The lower level limit of the desired item
--@param max_level The upper level limit of the desired item
--@param list Table. A list of possible items to pull from
--@param tags Table. A list of tags, potentially to pass to the item, or to use as preference for enchantments
--@param allowAll Boolean. If True, items with the specialOnly flag can still be chosen (but items with the neverSpawn flag set still cannot). Optional
--@param enchantment_chance Number. The chance of the item spawning with an enchantment
--@param artifact_chance Number. The chance of the item spawning as an artifact
--@return Item. The new item
function mapgen:generate_item(min_level,max_level,list,tags,allowAll,enchantment_chance,artifact_chance)
  local newItem = nil
  if not list then return false end

  --Prevent an infinite loop if there are no items of a given level:
  local noItems = true
  for _,iid in pairs(list) do
    local item = (type(iid) == "string" and possibleItems[iid] or iid)
    if not item.neverSpawn and (not item.level or (((not min_level or item.level >= min_level) and (not max_level or item.level <= max_level)) or (item.max_level and ((not min_level or item.max_level >= min_level) or (not max_level or item.max_level <= max_level)))))  then 
      noItems = false break
    end
  end
  if noItems == true then return false end
  
  ---- This selects a random item from the table of possible items, and compares the desired item level to this item's level. If it's a match, continue, otherwise select another one
  while (1 == 1) do -- endless loop, broken by the "return"
    local n = (list == possibleItems and get_random_key(list) or get_random_element(list))
    local item = (type(n) == "table" and n or possibleItems[n])
    if item and not item.neverSpawn and random(1,100) >= (item.rarity or 0) and (not item.level or (((not min_level or item.level >= min_level) and (not max_level or item.level <= max_level)) or (item.max_level and ((not min_level or item.max_level >= min_level) or (not max_level or item.max_level <= max_level))))) then
      newItem = n
      break
    end
  end
  
  -- Create the actual item:
  local item = Item(newItem,tags)
  --Add enchantments:
  artifact_chance = artifact_chance or gamesettings.artifact_chance or 0
  enchantment_chance = enchantment_chance or gamesettings.enchantment_chance or 0
  if random(1,100) <= artifact_chance then
    self:make_artifact(item,tags)
  elseif random(1,100) <= enchantment_chance then
    local possibles = item:get_possible_enchantments(true,true)
    if count(possibles) > 0 then
      local eid = get_random_element(possibles)
      item:apply_enchantment(eid,-1)
    end
  end

  --Level the item up if necessary:
  if item.level then
    local level = random(math.max(item.level,min_level),math.min(item.max_level or item.level,max_level))
    if level > item.level then
      for i=item.level+1,level,1 do
        item:level_up()
      end
    end
  end
  return item
end

---Generate an item from an item group
--@param groupID String. The item group list
--@param amount Number. The number of items to generate
--@param passedTags Table. A table of tags to pass to the new items
--@return Table. A table of generated items
function mapgen:generate_items_from_item_group(groupID,amount,info)
  info = info or {}
	amount = amount or 1
	local final_items = {}
	local group = item_group_list and item_group_list[groupID] and copy_table(item_group_list[groupID])
  if not group then return final_items end
  
  local enchantment_chance = info.enchantment_chance or group.enchantment_chance or gamesettings.default_enchantment_chance or 0
  local artifact_chance = info.artifact_chance or group.artifact_chance or gamesettings.default_artifact_chance or 0
  local enchantments = merge_tables(info.enchantments or {},group.enchantments or {})
  local tags = merge_tables(info.tags or {}, group.tags or {})
  local passedTags = merge_tables(info.passedTags or {},group.passedTags or {})
  local requiredTags = info.requiredTags or group.requiredTags
  local forbiddenTags = info.forbiddenTags or group.forbiddenTags

	local already_ids = {}
	if group.items then
    for _,info in ipairs(group.items) do
      already_ids[#already_ids+1] = group.item
    end
  else
    group.items = group.items or {}
  end
  if tags then
    local additions = mapgen:get_content_list_from_tags('item', tags, {requiredTags=requiredTags, forbiddenTags=forbiddenTags})
    for _,iid in ipairs(additions) do
      if not in_table(iid,already_ids) then
        group.items[#group.items+1] = {item=iid, chance=100-(possibleItems[iid].rarity or 0), passedTags=passedTags, enchantment_chance = enchantment_chance, artifact_chance = artifact_chance, enchantments = enchantments}
      end
    end
  end

	if count(group.items) == 0 then return final_items end

	local item_count = 0
	while item_count < amount do
    group.items = shuffle(group.items)
    local created = false
    for i,info in ipairs(group.items) do
      if not info.chance or random(1,100) < info.chance then
        if info.item_group then
          local items = self:generate_items_from_item_group(info.item_group,info.amount)
          local icount = count(items)
          if icount > 0 then
            for _,item in ipairs(items) do
              final_items[#final_items+1] = item
            end
            if not info.repeat_allowed and not group.repeat_allowed then
              table.remove(group.items,i)
            end
            item_count = item_count+1
            created = true
            break
          end
        else
          local item = Item(info.item,info.passedTags or passedTags,info.passedInfo)
          local artifact_chance = info.artifact_chance or artifact_chance
          local enchantment_chance = info.enchantment_chance or enchantment_chance
          if random(1,100) <= artifact_chance then
            mapgen:generate_artifact(item,passedTags)
          end
          if random(1,100) <= enchantment_chance then
            --TODO: apply enchantments
          end
      
          final_items[#final_items+1] = item
          if not info.repeat_allowed and not group.repeat_allowed then
            table.remove(group.items,i)
          end
          item_count = item_count+1
          created = true
          break
        end
      end
    end
    if not created then item_count = item_count+1 end --even if we didn't make an item, increase the count to avoid an infinite loop
	end
	return final_items
end


---Turns an item into a random artifact
--@param item Item. The item to turn into an artifact
--@param tags Table. A list of tags, used to prioritize enchantments which match said tags (optional)
function mapgen:make_artifact(item,tags)
  local possibles = item:get_possible_enchantments(true)
  local max = item.max_enchantments or 3
  local additions = random(math.ceil(max/2),max)
  local enchantment_count = 0
  if count(possibles) == 0 then
    return false
  end
  --First stop: Add an enchantment from the tag list
  if tags then
    local taggedPossibles = {}
    for _,eid in ipairs(possibles) do
      local ench = enchantments[eid]
      if not ench.neverArtifact and ench.tags then
        for _,tag in ipairs(tags) do
          if in_table(tag,ench.tags) then
            taggedPossibles[#taggedPossibles+1] = eid
            break
          end --end in_table if
        end --end tag for
      end --end if enchantment has tags if
    end --end enchantment for
    if #taggedPossibles > 0 then
      local eid = get_random_element(taggedPossibles)
      local tries = 0
      local applied = false
      while tries < 10 do
        if eid and item:qualifies_for_enchantment(eid,true) then
          item:apply_enchantment(eid,-1)
          applied = true
          enchantment_count = enchantment_count+1
          break
        end
      end
      if not applied then
        additions = additions+1 --if for some reason we get to this point and there's no enchantment, add an extra "generic" enchantment
      end
    else
      additions = additions+1 --if there are no enchantments matching the tags, add an extra "generic" enchantment
    end
  end --end tags if
  --Now add random other enchantments:
  local tries = 0
  local applied = false
  while enchantment_count < additions and tries < 10 do
    tries = tries + 1
    local eid = get_random_element(possibles)
    if eid and (not item.enchantments or not item.enchantments[eid]) and item:qualifies_for_enchantment(eid,true) and not enchantments[eid].neverArtifact then
      item:apply_enchantment(eid,-1)
      applied = true
      enchantment_count = enchantment_count+1
      tries = 0
    end
  end
  if not item.properName then
    local nameType = (item.nameType or item.category)
    item.properName = namegen:generate_item_name(nameType)
  end
end

---Creates an instance of a branch, to be attached to a given playthrough
--@param branchID Text. The ID of the branch
--@param args Anything. Arguments to pass to the branch
--@return Table. The information for the new branch
function mapgen:generate_branch(branchID,args)
  local newBranch = {}
  local data = dungeonBranches[branchID]
  for key, val in pairs(data) do
    if type(val) ~= "function" then
      newBranch[key] = data[key]
    end
  end
  if data.mapTypes then
    newBranch.mapTypes = copy_table(data.mapTypes)
  end
  if data.new then
    data.new(newBranch,args)
  end
  if data.generateName then
    newBranch.name = data.generateName(newBranch)
  elseif data.nameType then
    newBranch.name = namegen:generate_name(data.nameType)
  end
  newBranch.maps = {}

  --Add map types based on tags:
  local mTags = newBranch.mapTags or newBranch.contentTags
  if mTags then
    for id,mtype in pairs(mapTypes) do
      if mtype.tags and (not newBranch.mapTypes or not in_table(id,newBranch.mapTypes)) then
        for _,tag in ipairs(mTags) do
          if in_table(tag,mtype.tags) then
            if not newBranch.mapTypes then newBranch.mapTypes = {} end
            newBranch.mapTypes[#newBranch.mapTypes+1] = id
            break
          end --end map has tag if
        end --end tag for
      end --end maptype has tags if
    end --end mapType for
  end --end if branch.mapTags

  --Add exits:
  newBranch.exits = {}
  if newBranch.possibleExits then
    for _,exit in pairs(data.possibleExits) do
      if not exit.chance or random(1,100) <= exit.chance then
        local depth = exit.depth or random(exit.min_depth,exit.max_depth)
        if not newBranch.exits[depth] then newBranch.exits[depth] = {} end
        newBranch.exits[depth][#newBranch.exits[depth]+1] = {branch=exit.branch,replace_upstairs=exit.replace_upstairs,replace_downstairs=exit.replace_downstairs,oneway=exit.oneway,exit_depth=exit.exit_depth or 1}
      end -- end if exit chance
    end --enf possibleExits for
    newBranch.possibleExits = nil
  end --end if possibleExits exist
  newBranch.id = branchID
  newBranch.baseType = "branch"
  return newBranch
end

---Perform a floodfill operation, getting all walls or floor that touch. Only works for walls and floor, not features.
--@param map Map. The map to look at
--@param lookFor String. "." or "#" for floors or walls, or the ID of a feature. Defaults to "."
--@param startX Number. The X-coordinate to start at. Optional, will pick a randon tile if blank
--@param startY Number. The Y-coordinate to start at. Optional, will pick a random tile if blank
--@param noRandom Boolean. If true, don't hop to a random tile if the initial tile doesn't match
--@return Table. A table covering the whole map, in the format Table[x][y] = true or false, for whether the given tile matches lookFor
--@return Number. The number of tiles found
function mapgen:floodFill(map,lookFor,startX,startY,noRedirect)
  local floodFill = {}
  local numTiles = 0

  lookFor = lookFor or "."

  -- Initialize floodfill to contain entries corresponding to map tiles, but set them initially to nil
  for x=1,map.width,1 do
    floodFill[x] = {}
    for y=1,map.height,1 do
      floodFill[x][y] = nil
    end
  end
  -- Select random empty tile, and start flooding!
  startX,startY = startX or random(2,map.width-1), startY or random(2,map.height-1)
  local tries = 0
  while (map[startX][startY] ~= lookFor) and not map:tile_has_feature(startX,startY,lookFor) and not map:tile_has_effect(startX,startY,lookFor) and not noRedirect and tries < 100 do --if it's a wall, try again
    startX,startY = random(2,map.width-1),random(2,map.height-1)
    tries = tries + 1
  end
  local check = {{startX,startY}}
  while #check > 0 do
    local checkX,checkY=check[1][1],check[1][2]
    table.remove(check,1)
    floodFill, numTiles, check = mapgen:floodTile(map,checkX,checkY,floodFill,lookFor,numTiles,check) -- only needs to be called once, because it recursively calls itself
  end
  return floodFill,numTiles
end

---Looks at the tiles next to a given tile, to see if they match. Used by the floodFill() function, probably shouldn't be used by itself.
--@param map Map. The map to look at
--@param x Number. The X-coordinate to look at
--@param y Number. The Y-coordinate to look at
--@param floodFill Table. The table of floodFill values.
--@param lookFor String. "." or "#" for floors or walls, or the ID of a feature. Defaults to "."
--@param numTiles Number. The number of tiles currently matching the floodfill criteria
--@param check Table. A table full of values to be checked.
--@return Table. A table covering the whole map, in the format Table[x][y] = true or false, for whether the given tile matches lookFor
--@return Number. The number of tiles found
--@return Table. A table full of values that still need to be checked
function mapgen:floodTile(map, x,y,floodFill,lookFor,numTiles,check)
  -- Cycles through a tile and its immediate neighbors. Sets clear spaces in floodFill to true, non-clear spaces to false.
  for ix=x-1,x+1,1 do
    for iy=y-1,y+1,1 do
      if (ix >= 1 and iy >= 1 and ix <= map.width and iy <= map.height and floodFill[ix][iy] == nil) then --important: check to make sure floodFill hasn't looked at this tile before, to prevent infinite loop
        if map[ix][iy] == lookFor or map:tile_has_feature(ix,iy,lookFor) or map:tile_has_effect(ix,iy,lookFor) then
          numTiles = numTiles+1
          floodFill[ix][iy] = true
          check[#check+1] = {ix,iy} --add it to the list of tiles to be checked
        else 
          floodFill[ix][iy] = false
        end -- end tile check
      end -- end that checks we're within bounds and hasn't been done before
    end -- end y
  end -- end x
  return floodFill,numTiles,check
end -- end function

---Add a river to a map.
--@param map Map. The map to add the river to
--@param tile Feature. The feature to use to fill the river
--@param noBridges Boolean. If set to True, don't make bridges over the river. Otherwise, make bridges. Optional
--@param bridgeData Anything. Arguments to pass to the bridge's new() function. Optional
--@param minDist Number. The minimum distance that must be between bridges. Optional, defaults to 5.
--@return Table. A table of the tiles along the river's shore.
function mapgen:addRiver(map, tile, noBridges,bridgeData,minDist,clearTiles)
  local shores = {}

  map:refresh_pathfinder()
  if (random(1,2) == 1) then --north-south river
    local currX = random(math.ceil(map.width/4),math.floor((map.width/4)*3))
    local spread = random(1,3)
    for y=1,map.height,1 do
      currX = math.max(math.min(currX+(random(-1,1)),map.width),1)
      spread = math.max(math.min(spread+random(-1,1),3),1)
      --track shore tiles. We'll need them later to build bridges:
      local s = {{x=currX-spread-1,y=y},{x=currX+spread+1,y=y}}
      shores[#shores+1] = s
      --Add the water:
      for x=currX-spread,currX+spread,1 do
        if (x>1 and x<map.width) then
          for id,feature in pairs(map:get_contents(x,y)) do
            if feature.name == "Shallow Water" or feature.name == "Deep Water" then return end --if you run into a lake, stop
          end --end for
          map.collisionMaps['basic'][y][x] = 1
          map:clear_tile(x,y)
          local r = Feature(tile)
          r.x,r.y = x,y
          map[x][y] = r
        end
      end --end forx
    end -- end fory
  else --east-west river
    local currY = random(math.ceil(map.height/4),math.floor(map.height/4)*3)
    local spread = random(1,3)
    for x=1,map.width,1 do
      currY = math.max(math.min(currY+(random(-1,1)),map.width),1)
      spread = math.max(math.min(spread+random(-1,1),3),1)
      --track shore tiles. We'll need them later to build bridges:
      local s = {{x=x,y=currY-spread-1},{x=x,y=currY+spread+1}}
      shores[#shores+1] = s
      --Add the water:
      for y=currY-spread,currY+spread,1 do
        if (y>1 and y<map.height) then
          for id,feature in pairs(map:get_contents(x,y)) do
            if feature.name == "Shallow Water" or feature.name == "Deep Water" then return end --if you run into a lake, stop
          end --end for
          map.collisionMaps['basic'][y][x] = 1
          map:clear_tile(x,y)
          local r = Feature(tile)
          r.x,r.y = x,y
          map[x][y] = r
        end -- end if
      end -- end fory
    end -- end forx
  end -- end river code

  -- Iterate along shore. If you can cross, continue. If you can't, build a bridge, refresh the pathfinder, then check again.
  if noBridges ~= true then
    shores = shuffle(shores)
    local bridgeEnds = {}
    minDist = minDist or 5
    for _, shore in ipairs(shores) do
      if map:isClear(shore[1].x,shore[1].y) and map:isClear(shore[2].x,shore[2].y) and map[shore[1].x][shore[1].y] == "." and map[shore[2].x][shore[2].y] == "." then
        local makeBridge = true

        for _,bend in pairs(bridgeEnds) do
          local s1xDist,s1yDist = math.abs(shore[1].x-bend.x),math.abs(shore[1].y-bend.y)
          local s2xDist,s2yDist = math.abs(shore[2].x-bend.x),math.abs(shore[2].y-bend.y)
          if (s1xDist < minDist and s1yDist < minDist) or (s2xDist < minDist and s2yDist < minDist) and (map:is_line(shore[1].x,shore[1].y,bend.x,bend.y) and map:is_line(shore[2].x,shore[2].y,bend.x,bend.y)) then
            if (s1xDist < 2 and s1yDist < 2) or (s2xDist < 2 and s2yDist < 2) or (map:tile_has_tag(shore[1].x,shore[1].y,"door") == false and map:tile_has_tag(shore[2].x,shore[2].y,"door") == false) then
              makeBridge = false
              break
            end --end dist==2/door if
          end --end dist < minDist if
        end --end bridgeend for

        if makeBridge == true then --if, after all that, makeBridge is still true,
          mapgen:buildBridge(map,shore[1].x,shore[1].y,shore[2].x,shore[2].y,bridgeData)
          bridgeEnds[#bridgeEnds+1] = {x=shore[1].x,y=shore[1].y}
          bridgeEnds[#bridgeEnds+1] = {x=shore[2].x,y=shore[2].y}
        end --end if makebridge if
      end -- end map isclear if
    end --end shore for
  end --end nobridges if
  map:refresh_pathfinder()
  return shores
end -- end function

---Add a bridge
--@param map Map. The map to add edges to.
--@param fromX Number. The x-coordinate to start at
--@param fromY Number. The y-coordinate to start at
--@param toX Number. The x-coordinate to end at
--@param toY Number. The y-coordinate to end at
--@param data Anything. The data to pass to the bridge's new() function
function mapgen:buildBridge(map,fromX,fromY,toX,toY,data)
  if fromX == toX and fromY ~= toY then --vertical bridge
    local yMod = 0
    if fromY > toY then yMod = -1
    elseif toY > fromY then yMod = 1 end
    if yMod ~= 0 then
      for y = fromY,toY,yMod do
        local bridge = Feature('bridge',data)
        bridge.x,bridge.y = toX,y
        map:add_feature(bridge,bridge.x,bridge.y)
        map.collisionMaps['basic'][bridge.y][bridge.x] = 0
        if type(map[bridge.x][bridge.y]) == "table" then
          map[bridge.x][bridge.y].impassable = false
          map[bridge.x][bridge.y].hazard = false
          map[bridge.x][bridge.y].walkedOnImage = false
        end -- end table if
      end --end fory
    end --end if yMod ~= 0
  elseif fromY == toY and fromX ~= toX then --horizontal bridge
    local xMod = 0
    if fromX > toX then xMod = -1
    elseif toX > fromX then xMod = 1 end
    if xMod ~= 0 then
      for x = fromX,toX,xMod do
        local bridge = Feature('bridge',data)
        bridge.x,bridge.y = x,toY
        map:add_feature(bridge,bridge.x,bridge.y)
        map.collisionMaps['basic'][bridge.y][bridge.x] = 0
        if type(map[bridge.x][bridge.y]) == "table" then
          map[bridge.x][bridge.y].impassable = false
          map[bridge.x][bridge.y].hazard = false
          map[bridge.x][bridge.y].walkedOnImage = false
        end -- end table if
      end --end forx
    end --end if xMod ~= 0
  end
end

---Add jagged edges to the borders of the map, to make it more visually interesting than just flat walls.
--@param map Map. The map to add edges to.
--@param width Number. The width of the map.
--@param height Number. The height of the map.
--@param onlyFeature Text. If this is left blank, the new walls will be created no matter what. If it's the ID of a feature, the walls will only be created if the tile has that feature on it.
function mapgen:makeEdges(map,width,height,onlyFeature)
  local topThick,bottomThick = 1,1
  for x=1,width,1 do
    local leftThick,rightThick = 1,1
    for y=1,height,1 do
      leftThick = math.max(leftThick + random(-1*leftThick,1),1)
      rightThick = math.max(rightThick + random(-1*rightThick,1),1)
      for ix=1,1+leftThick,1 do
        if onlyFeature == nil or map:tile_has_feature(ix,y,onlyFeature) then map[ix][y] = "#" end
      end
      for ix=width,width-rightThick,-1 do
        if onlyFeature == nil or map:tile_has_feature(ix,y,onlyFeature) then map[ix][y] = "#" end
      end
    end -- end fory
    topThick = math.max(topThick + random(-1*topThick,1),1)
    bottomThick = math.max(bottomThick + random(-1*bottomThick,1),1)
    for iy=1,1+topThick,1 do
      if onlyFeature == nil or map:tile_has_feature(x,iy,onlyFeature) then map[x][iy] = "#" end
    end
    for iy=height,height-bottomThick,-1 do
      if onlyFeature == nil or map:tile_has_feature(x,iy,onlyFeature) then map[x][iy] = "#" end
    end
  end --end forx
end

---Randomly add stairs to the map, generally on opposite sides.
--@param build Map. The map to add the stairs to.
--@param width Number. The width of the map
--@param height Number. The height of the map
function mapgen:addGenericStairs(build,width,height)
  local acceptable = false
  local count = 1
  while (acceptable == false) do
    -- first, determine starting corners:
    local upStartX,upStartY,downStartX,downStartY
    if (random(1,2) == 1) then
      upStartX,downStartX = 2,width-1
    else
      upStartX,downStartX = width-1, 2
    end
    if (random(1,2) == 1) then
      upStartY,downStartY = 2,height-1
    else
      upStartY,downStartY = height-1,2
    end

    --Place down stairs::
    local placeddown = false
    local downDist = 1
    while placeddown == false do
      for x=downStartX-downDist,downStartX+downDist,1 do
        for y=downStartY-downDist,downStartY+downDist,1 do
          if x > 1 and y > 1 and x < width and y < height and build:isEmpty(x,y) and random(1,100) == 1 then
            build.stairsDown = {x=x,y=y}
            placeddown = true
          end --end if
        end --end yfor
      end --end xfor
      downDist = downDist + 1
      if downDist > math.min(width,height)/2 then print('couldnt make good downstairs') return false end
    end --end while

    --Place up stairs:
    local placedup = false
    local upDist = 1
    local tries = 0
    while placedup == false do
      local startX,startY = math.max(2,math.min(width-1,random(upStartX-upDist,upStartX+upDist))),math.max(2,math.min(height-1,random(upStartY-upDist,upStartY+upDist)))
      if random(1,2) == 1 then
        startX = random(2,width-1)--random(math.min(math.ceil(width*.66),upStartX),math.max(math.ceil(width*.66),upStartX))
      else
        startY = random(2,height-1)--random(math.min(math.ceil(height*.66),upStartY),math.max(math.ceil(height*.66),upStartY))
      end

      local breakOut = false
      for x=startX-upDist,startX+upDist,1 do
        if breakOut then break end
        for y=startY-upDist,startY+upDist,1 do
          if x > 1 and y > 1 and x < width and y < height and build:isEmpty(x,y) then
            build.stairsUp = {x=x,y=y}
            placedup = true
          end --end if
        end --end yfor
      end --end xfor
      tries = tries+1
      if not placedub and tries > math.min(width,height)/2 then
        upDist = upDist + 1
        tries = 0
        if upDist > math.min(width,height)/2 then print('couldnt make good upstairs') return false end
      end
    end --end while

    -- Make sure there's a clear path (shouldn't be a problem), and that they're far enough apart:
    if build.stairsDown.x ~= 0 and build.stairsDown.y ~= 0 and build.stairsUp.x ~= 0 and build.stairsUpy ~= 0 then
      local p = build:findPath(build.stairsDown.x,build.stairsDown.y,build.stairsUp.x,build.stairsUp.y)
      if p ~= false then
        if random(1,2) == 1 then build.stairsUp,build.stairsDown = build.stairsDown,build.stairsUp end --flip them sometimes for fun
        acceptable = true
        return true
      end
    end --end 0,0 if
    count = count + 1
    if (count > 20) then
      print("problem in stairgen")
      return false
    end
  end -- end while loop
end

---Get coordinates for a
--@param map Map. The map to look at to build stairs
function mapgen:get_stair_location(map)
  local tries = 0
  local done = false
  local x,y = random(2,map.width),random(2,map.height)
  while (tries < 50 and done == false) or not map:isEmpty(x,y) do
    tries = tries + 1
    x,y = random(2,map.width),random(2,map.height)
    local minDist,maxDist = nil,nil
    local reachable = true
    for _,exit in ipairs(map.exits) do --loop through all the exits, and determine if it's reachable and how far away it is
      local dist = calc_distance_squared(exit.x,exit.y,x,y)
      if not maxDist or dist > maxDist then maxDist = dist end
      if not minDist or dist < minDist then minDist = dist end
      local p = map:findPath(exit.x,exit.y,x,y) --check to make sure the new exit can reach all the other exits
      if p == false then --If you can't reach the exit from all other exits, stop checking and just create new coordinates
        reachable = false
        break
      end
    end --end exit for
    if reachable and (not minDist or not maxDist or (minDist*1.5 >= maxDist)) then
      done = true
      break
    end
  end --end tries while
  return x,y
end

---Add tombstones to the map of previous player characters who have died here.
--@param map Map. The map to add the tombstones to.
function mapgen:addTombstones(map)
  local allGraves = load_graveyard()
  local graves = {}
  for _,g in pairs(allGraves) do
    if g.branch == map.branch and g.depth == map.depth then
      graves[#graves+1] = g
    end
  end
  if #graves < 1 then return end
  for i=1,random(#graves),1 do
    local grave = get_random_element(graves)
    local x,y = random(2,map.width-1),random(2,map.height-1)
    local tries = 0
    while map:isEmpty(x,y,true) == false and tries < 100 do
      x,y = random(2,map.width-1),random(2,map.height-1)
      tries = tries+1
    end
    local text = (random(0,1) == 1 and "R.I.P " or "Here Lies ") .. grave.properName .. ", " .. grave.name .. "\n" .. os.date("%x",grave.date)
    if grave.killer then
      text = text .. "\n Killed by " .. grave.killer
    end
    if tries < 100 then map:add_feature(Feature('gravestone',text),x,y) end
  end
end

---Make a procedurally-generated blob on the map
--@param map Map. The map to make the blob on
--@param startX Number. The starting X coordinate
--@param startY Number. The starting Y coordinate
--@param feature Text. The ID of the feature to make the blob out of
--@param decay Number. The % by which to decrease the chance that after a tile is made part of the blob, the next tiles will also be made part of the blob. Optional, defaults to 10
--@param includeWalls Boolean. Whether or not walls will be absorbed by the blob. Optional, if blank, the blob will form around walls
--@return Table. A table of tile coordinates that are part of the blob
function mapgen:make_blob(map,startX,startY,feature,decay,includeWalls)
  decay = decay or 10
  local points = {{x=startX,y=startY,spreadChance=100}}
  local finalPoints = {}
  local doneHolder = {}
  local tries = 0
  while count(points) > 0 and tries < 1000 do
    local pID = next(points)
    local point = points[pID]
    table.remove(points,pID)
    finalPoints[#finalPoints+1] = {x=point.x,y=point.y}
    doneHolder[point.x .. "," .. point.y] = true
    if feature then
      local f = Feature(feature)
      f.x,f.y = point.x,point.y
      map[point.x][point.y] = f
    end --end feature if
    for x=point.x-1,point.x+1,1 do
      for y=point.y-1,point.y+1,1 do
        if x >= 1 and x <= map.width and y >= 1 and y <= map.height and (x == point.x or y == point.y) and not (x==point.x and y==point.y) and (includeWalls or map[x][y] ~= "#") and doneHolder[x .. "," .. y] ~= true and random(1,100) <= point.spreadChance then
          points[#points+1] = {x=x,y=y,spreadChance=point.spreadChance-decay}
        end --end bounds check
      end --end fory
    end --end forx
    tries = tries+1
  end --end points while
  return finalPoints
end

---Determines if a tile is safe to block. Useful in map generators for placing decorations. TODO: Maybe this should be moved to the Map class?
--@param map Map. The map on which we're operating
--@param startX Number. The X-coordinate we're looking at
--@param startY Number. The Y-coordinate we're looking at
--@param safeType Text. Determines what counts as safe to block. "wall": next to wall only, "noWalls": not next to wall, "wallsCorners": open walls and corners only, "corners": corners only
--@return Boolean. Whether the tile is safe to block or not.
function mapgen:is_safe_to_block(map,startX,startY,safeType)
  local minX,minY,maxX,maxY=startX-1,startY-1,startX+1,startY+1
  local cardinals,corners = {},{}
  local cardinalWalls,cornerWalls = {},{}
  local n,s,e,w = false,false,false,false
  local walls = false
  if map:tile_has_feature(startX,startY,'exit') or not map:isClear(startX,startY) or map.tile_info[startX][startY].noBlock then return false end

  for x=minX,maxX,1 do
    for y=minY,maxY,1 do
      local door = map:tile_has_tag(x,y,'door')
      if (map:isClear(x,y) or door) and not (x == startX and y == startY) then
        if (x == startX or y == startY) then --cardinal direction
          if door then return false end -- don't block the area next to a door
          cardinals[#cardinals+1] = {x=x,y=y}
          if x == startX-1 then w = true
          elseif x == startX+1 then e = true
          elseif y == startY-1 then n = true
          elseif y == startY+1 then s = true end
        else
          corners[#corners+1] = {x=x,y=y}
        end --end cardinal/corner if
      elseif not (x==startX and y==startY) then --if not clear
        if map[x][y] == "#" then walls = true end
        if (x == startX or y == startY) then --cardinal direction
          cardinalWalls[#cardinalWalls+1] = {x=x,y=y}
        else
          cornerWalls[#cornerWalls+1] = {x=x,y=y}
        end --end cardinal/corner if
      end --end isClear() if
    end --end fory
  end --end forx

  --If you have to be next to a wall and you're not, then don't go any further
  if (safeType == "wall" or safeType == "wallsCorners") and walls == false then return false end
  if safeType == "noWalls" then
    if walls == true then return false
    else return true end
  end
  if safeType == "corners" and #cardinals > 2 then return false end

  --Prepare for ugliness
  if safeType == "wallsCorners" then
    if #cardinals == 2 and not (n and s) and not (e and w) then
      local okOpen = false
      local okWall = false
      local card1X,card1Y = cardinals[1].x,cardinals[1].y
      local card2X,card2Y = cardinals[2].x,cardinals[2].y
      local cardwall1X,cardwall1Y = cardinalWalls[1].x,cardinalWalls[1].y
      local cardwall2X,cardwall2Y = cardinalWalls[2].x,cardinalWalls[2].y
      for _,tile in pairs(corners) do --check to make sure that the corner next to the two cardinal openings is also open
        if map:touching(tile.x,tile.y,card1X,card1Y) and map:touching(tile.x,tile.y,card2X,card2Y) then
          okOpen = true
        end
      end
      for _,tile in pairs(cardinalWalls) do --check to make sure that the corner next to the two cardinal openings is also open
        if map:touching(tile.x,tile.y,cardwall1X,cardwall1Y) and map:touching(tile.x,tile.y,cardwall2X,cardwall2Y) then
          okWall = true
        end
      end
      if okOpen == true and okWall == true then
        return true
      end --end okOpen/okWall if
    elseif #cardinalWalls == 1 then
      local cardX,cardY = cardinalWalls[1].x,cardinalWalls[1].y
      for _,tile in pairs(cornerWalls) do
        if not map:touching(tile.x,tile.y,cardX,cardY) then --if there's a corner that is not touching the only wall we're against, it's not OK
          return false
        end --end if not touching
      end --end cornerwall if
      return true
    end --end cardinals true if
    return false
  end

  --Do the simple checks that don't involve any calculations first:
  if #cardinals >= 3 or (#cardinals == 2 and not (n and s) and not (e and w)) or #cardinals == 1 then
    --Do more complicated checks here:
    if #cardinals == 2 then
      local card1X,card1Y = cardinals[1].x,cardinals[1].y
      local card2X,card2Y = cardinals[2].x,cardinals[2].y
      for _, tile in pairs(corners) do --check to make sure the corner openings all touch one of the cardinal direction openings
        if not map:touching(card1X,card1Y,tile.x,tile.y) and not map:touching(card2X,card2Y,tile.x,tile.y) then
          return false
        end --end if touching
      end --end tile for
    elseif #cardinals == 1 then
      local cardX,cardY = cardinals[1].x,cardinals[1].y
      for _, tile in pairs(corners) do --check to make sure all the corner openings touch the cardinal direction opening
        if not map:touching(cardX,cardY,tile.x,tile.y) then
          return false
        end --end if touching
      end --end tile for
    end --end if cardinals == 1
    --OK, if we haven't returned false yet, we're good!
    return true
  end --end main cardinal count if
  --If the cardinal count if is false, then it's not a safe place to block
  return false
end

---Gets all the "safe to block" tiles in a given room. Takes a list of tiles and runs mapgen:is_safe_to_block on them.
--@param map Map. The map we're operating on
--@param room Room. A room as returned by a roomGenerator. Can also pass in a custom table with a list of tiles in a subtable called floors.
--@param openType Text. Determines what counts as "safe." "wall": next to wall only, "noWalls": not next to wall, "wallsCorners": open walls and corners only, "corners": corners only
--@return Table. A table of tiles deemed safe to block.
function mapgen:get_all_safe_to_block(map,room,openType)
  local safe = {}
  for _,floor in pairs(room.floors) do
    if self:is_safe_to_block(map,floor.x,floor.y,openType) then
      safe[#safe+1] = {x=floor.x,y=floor.y}
    end --end if
  end --end for
  return safe
end

---"Contour-bombs" open tiles, basically drawing open circles around tiles to make a more organic-looking space.
--@param map Map. The map we're operating on.
--@param tiles Table. A table of the tiles to look at. Optional, defaults to all tiles in the map
--@param iterations The number of times to run the bombing. Optional, defaults to the count of the tiles multiplied by a number between 2 and 5.
function mapgen:contourBomb(map,tiles,iterations)
  local newTiles = {}
  --First, get all open tiles, if a list isn't provided:
  if not tiles then
    tiles = {}
    for x=2,map.width-1,1 do
      for y=2,map.height-1,1 do
        if map[x][y] == "." then
          tiles[#tiles+1] = {x=x,y=y}
        end --end tile check
      end --end fory
    end --end forx
  end

  --Now, contour bomb open tiles:
  iterations = iterations or #tiles*random(2,5)
  for i=1,iterations,1 do
    local tile
    if random(1,3) == 3 and #newTiles > 0 then --do it to a new tile
      tile = get_random_element(newTiles)
    else --do it to any random tile
      tile = get_random_element(tiles)
    end
    local size = random(1,2)
    for x=tile.x-size,tile.x+size,1 do
      for y=tile.y-size,tile.y+size,1 do
        if calc_distance(x,y,tile.x,tile.y) < size and x > 1 and y > 1 and x<map.width and y<map.height then
          if not map:isFloor(x,y) then
            tiles[#tiles+1] = {x=x,y=y}
            newTiles[#tiles+1] = {x=x,y=y}
          end --end checking if this one's been done before
          map[x][y] = "."
        end --end distance/border check
      end --end fory
    end --end forx
  end --end adding circles
end

---Decorate a room
--@param room Room. A table with, at least, minX,maxX,minY, and maxY values
--@param map Map. The map on which this room exists
--@param decID String or table. Either the ID of a specific room decorator, or a table of room decorator IDs. Optional
function mapgen:decorate_room(room,map,decID)
  decID = decID or room.decorator
  local branch = currWorld.branches[map.branch]
  local decorators = decID or map.roomDecorators or branch.roomDecorators or nil
  local dec = nil
  
  --If passed a specific decorator
  if roomDecorators[decID] then
    dec = roomDecorators[decID]
  end
  
  if not dec and decorators and type(decorators) == "table" then --if passed a list of decorators, or if the branch/map has set decorators
    --First check to make sure all the decorators listed actually exist:
    local possibles = {}
    for _,ID in ipairs(decorators) do
      local d = roomDecorators[ID]
      if roomDecorators[ID] and (not d.max_per_map or not map.decorator_count or (map.decorator_count[ID] or 0) < d.max_per_map) and (not d.max_per_branch or not branch.decorator_count or (branch.decorator_count[ID] or 0) < d.max_per_branch) and (not d.requires or d.requires(room,map) ~= false) then
        possibles[#possibles+1] = ID
      end
    end
    if #possibles > 0 then
      decID = get_random_element(possibles)
      dec = roomDecorators[decID]
    end
  end --end if decorators
  
  if not dec then
    local tags = map:get_content_tags()
    if #tags == 0 then tags = map.tags or branch.tags end
    if #tags > 0 then
      local possibles = {}
      for ID,d in pairs(roomDecorators) do
        if d.tags then
          for _,tag in ipairs(tags) do
            if in_table(tag,d.tags) and (not d.max_per_map or not map.decorator_count or (map.decorator_count[ID] or 0) < d.max_per_map) and (not d.max_per_branch or not branch.decorator_count or (branch.decorator_count[ID] or 0) < d.max_per_branch) and (not d.requires or d.requires(room,map) ~= false) then
              possibles[#possibles+1] = ID
              break
            end --end tag check if
          end --end tag for
        end --end if decorator has tags
      end --end roomDecorators for
      if #possibles > 0 then
        decID = get_random_element(possibles)
        dec = roomDecorators[decID]
      end
    end
  end --end if dec
  
  if dec then
    --Basic decorator:
    if dec.decorate then
      dec.decorate(room,map)
      room.decorator = decID
      
      if not map.decorator_count then map.decorator_count = {} end
      if not branch.decorator_count then branch.decorator_count = {} end
      map.decorator_count[decID] = (map.decorator_count[decID] or 0)+1
      branch.decorator_count[decID] = (branch.decorator_count[decID] or 0)+1
    end
    --Add content:
    --[[(I've blocked this out because content is added in map:populate_items/creatures instead now. But if you want it to populate BEFORE that happens for some reason, uncomment and it shouldn't break anything)
    if not noContent then
      --Add creatures:
      mapgen:populate_creatures_in_room(room,map,decID)
      
      --Add items:
      mapgen:populate_items_in_room(room,map,decID)
    end]]
  end
end

---Spawn creatures in a room, using a roomDecorator if desired
--@param room Room. A table with, at least, minX,maxX,minY, and maxY values
--@param map Map. The map on which this room exists
--@param decID String. The ID of a specific room decorator
function mapgen:populate_creatures_in_room(room,map,decID)
  decID = decID or room.decorator
  local dec = roomDecorators[decID]
  local creature_list = {}
  
  if dec and (dec.creature_repopulate_limit or dec.repopulate_limit) then
    local spawns = (room.creature_populated_count or 0)
    if spawns > (dec.creature_repopulate_limit or dec.repopulate_limit) then
      return
    end
    room.creature_populated_count = (room.creature_populated_count or 0) + 1
  end
  
  if not decID or not dec then
    creature_list = map:get_creature_list()
  else
    --If there's a special function, use that instead
    if dec.populate_creatures then
      return dec.populate_creatures(room,map)
    end
    --Add up list of creatures
    if dec.creatures then
      creature_list = dec.creatures or {}
    end --end if creatures
    if dec.creatureTypes or dec.creatureTags or dec.contentTags then
      local tags = dec.creatureTags or dec.contentTags
      for cid,creat in pairs(possibleMonsters) do
        local done = false
        if dec.creatureTypes then
          for _,cType in ipairs(dec.creatureTypes) do
            if not creat.specialOnly and Creature.is_type(creat,cType) then
              done = true
              break
            end --end is_type if
          end --end cType for
        end --end if dec.creatureTypes
        if tags and not done then
          for _,tag in ipairs(tags) do
            if not creat.specialOnly and Creature.has_tag(creat,tag) then
              done = true
              break
            end
          end --end tags for
        end --end tags if
        --TODO: check forbidden tags
        if done then
          creature_list[#creature_list+1] = cid
        end
      end --end creature for
    end --end if creature or tags listed in room decorator 
  end --end if decid
  
  --Now that we have a list, start working:
  if creature_list and #creature_list > 0 then
    local clearSpace = 0
    local current_creats = 0
    local branch = currWorld.branches[map.branch]
    
    --Passed tags:
    local passedTags = (dec and dec.passedTags or {})
    local mapPassed = map:get_content_tags('passed')
    passedTags = merge_tables(passedTags, mapPassed)
    
    for x = room.minX,room.maxX,1 do
      for y = room.minY,room.maxY,1 do
        if map:isClear(x,y) then
          clearSpace = clearSpace+1
        elseif map:get_tile_creature(x,y) then
          current_creats = current_creats+1
        end
      end
    end
    --Calculate density
    local density = (dec and dec.creature_density) or mapTypes[map.mapType].creature_density or branch.creature_density or gamesettings.creature_density
    local creatMax = math.ceil(clearSpace*(density/100))-current_creats
    
    --Calculate spawn points, because we'll use that as the max creature number if it's more than the regular number
    local creature_spawn_points = {}
    if map.creature_spawn_points and #map.creature_spawn_points > 0 then
      for i,sp in ipairs(map.creature_spawn_points) do
        if not sp.used and not sp.boss and map.tile_info[sp.x][sp.y].room == room and not map:tile_has_feature(sp.x,sp.y,'door') and not map:tile_has_feature(sp.x,sp.y,'gate') and not map:tile_has_feature(sp.x,sp.y,'exit') and not map:get_tile_creature(sp.x,sp.y) and not map.tile_info[sp.x][sp.y].noCreatures then
          creature_spawn_points[#creature_spawn_points+1] = sp
        end
      end
    end
    --creatMax = math.max(creatMax,#creature_spawn_points)
    --Do the actual spawning
    if creatMax > 0 then
      local newCreats = {}
      local creats_spawned = 0
      local tries = 0
      local min_level = map:get_min_level()
      local max_level = map:get_max_level()
      while creats_spawned < creatMax and tries < 100 do
        tries = 0 --tries are calculated later on
        local placed = false
        local nc = mapgen:generate_creature(min_level,max_level,creature_list,passedTags)
        if nc == false then break end
        
        --Spawn in designated spawn points first:
        local sptries = 0
        while (#creature_spawn_points > 0) and sptries < 100 do
          sptries = sptries + 1
          local spk = get_random_key(creature_spawn_points)
          local sp = creature_spawn_points[spk]
          if map:isClear(sp.x,sp.y,nc.pathType) then
            if random(1,4) == 1 then nc:give_condition('asleep',random(10,100)) end
            local creat = map:add_creature(nc,sp.x,sp.y)
            newCreats[#newCreats+1] = creat
            placed = creat
            sp.used = true
            table.remove(creature_spawn_points,spk)
            break
          end
        end
        
        --If not spawned at a spawn point, find a spot to spawn:
        if not placed then
          local cx,cy = random(room.minX,room.maxX),random(room.minY,room.maxY)
          while map:is_passable_for(cx,cy,nc.pathType) == false or map:tile_has_feature(cx,cy,'door') or map:tile_has_feature(cx,cy,'gate') or map:tile_has_feature(cx,cy,'exit') or not map:isClear(cx,cy,nc.pathType) or map.tile_info[cx][cy].noCreatures do
            cx,cy = random(room.minX,room.maxX),random(room.minY,room.maxY)
            tries = tries+1
            if tries > 100 then break end
          end
          
          --Place the actual creature:
          if tries ~= 100 then 
            if random(1,4) == 1 then nc:give_condition('asleep',random(10,100)) end
            local creat = map:add_creature(nc,cx,cy)
            creat.origin_room = room
            placed = creat
            newCreats[#newCreats+1] = creat
            creats_spawned = creats_spawned+1
          end --end tries if
        end
        
        --Place group spawns:
        if placed and (nc.group_spawn or nc.group_spawn_max) then
          local spawn_amt = (nc.group_spawn or random((nc.group_spawn_min or 1),nc.group_spawn_max))
          if not nc.group_spawn_no_tweak then spawn_amt = tweak(spawn_amt) end
          if spawn_amt < 1 then spawn_amt = 1 end
          local x,y = placed.x,placed.y
          for i=1,spawn_amt,1 do
            local tries2 = 1
            local cx,cy = random(x-tries,x+tries),random(y-tries,y+tries)
            while map:is_passable_for(cx,cy,nc.pathType) == false or map:tile_has_feature(cx,cy,'door') or map:tile_has_feature(cx,cy,'gate') or map:tile_has_feature(cx,cy,'exit') or not map:isClear(cx,cy,nc.pathType) or map.tile_info[cx][cy].noCreatures do
              cx,cy = random(x-tries,x+tries),random(y-tries,y+tries)
              tries2 = tries2 + 1
              if tries2 > 10 then break end
            end --end while
            if tries2 <= 10 then
              local creat = mapgen:generate_creature(min_level,max_level,{nc.id},passedTags)
              map:add_creature(creat,cx,cy)
              nc.origin_room = room
              newCreats[#newCreats+1] = creat
              creats_spawned = creats_spawned+0.5 --a group spawned creature only counts as half a creature for the purposes of creature totals, so group spawns won't eat up all the creature slots but also won't overwhelm the map
            end
          end
        end --end group spawn if  
      end
      return newCreats
    end
  end --end if creature list
  return false
end

---Spawn items in a room, using a roomDecorator if desired
--@param room Room. A table with, at least, minX,maxX,minY, and maxY values
--@param map Map. The map on which this room exists
--@param decID String. The ID of a specific room decorator
function mapgen:populate_items_in_room(room,map,decID)
  decID = decID or room.decorator
  local dec = roomDecorators[decID]
  local item_list = {}
  local newItems = {}
  
  if dec and (dec.item_repopulate_limit or dec.repopulate_limit) then
    local spawns = (room.item_populated_count or 0)
    if spawns > (dec.item_repopulate_limit or dec.repopulate_limit) then
      return
    end
    room.item_populated_count = (room.item_populated_count or 0) + 1
  end
  
  --Create list of items
  if not decID or not dec then
    item_list = map:get_item_list()
  else
    --Create the list
    if dec.items then
      item_list = dec.items or {}
    end --end if items
    if dec.itemTags or dec.contentTags then
      local tags = dec.itemTags or dec.contentTags
      local forbidden = dec.forbiddenTags
      local tagged_items = mapgen:get_content_list_from_tags('item',tags,forbidden)
      item_list = merge_tables(item_list,tagged_items)
    end --end if item or tags listed in room decorator 
  end --end if decid
  
  --Info for items (passed tags and levels):
  local passedTags = (dec and dec.passedTags or {})
  local mapPassed = map:get_content_tags('passed')
  passedTags = merge_tables(passedTags, mapPassed)
  local min_level = map:get_min_level()
  local max_level = map:get_max_level()
  
  --Spawn in designated spawn points first:
  local item_spawn_points = {}
  if map.item_spawn_points and #map.item_spawn_points > 0 then
    for i,sp in ipairs(map.item_spawn_points) do
      if not sp.used and map.tile_info[sp.x][sp.y].room == room and not map.tile_info[sp.x][sp.y].noItems and not map:tile_has_feature(sp.x,sp.y,'exit') and ((sp.inventory and #sp:get_inventory() < (sp.inventory_space or 1)) or (map:isClear(sp.x,sp.y,nil,true) and #map:get_tile_items(sp.x,sp.y) == 0)) then
        item_spawn_points[#item_spawn_points+1] = sp
      end
    end
  end
  
  for spk,sp in pairs(item_spawn_points) do
    if sp.baseType == "feature" and possibleFeatures[sp.id].populate_items then
      possibleFeatures[sp.id].populate_items(sp,map,room)
      goto continue
    end
    
    local sp_item_list = {}
    local sp_passedTags = merge_tables(passedTags,(sp.passedTags or {}))
    
    --Create item list:
    if sp.items then
      sp_item_list = sp.items or {}
    end --end if items
    if sp.itemTags or sp.contentTags or sp.forbiddenTags then
      local tags = sp.itemTags or sp.contentTags or dec.itemTags or dec.contentTags or {}
      local forbidden = sp.forbiddenTags
      local tagged_items = mapgen:get_content_list_from_tags('item',tags,forbidden)
      sp_item_list = merge_tables(sp_item_list,tagged_items)
    elseif not sp.items then --if there's no item list or tag list set, just use the item list of the room
      sp_item_list = item_list
    end
    
    ::gen_item::
    local ni = mapgen:generate_item(min_level,max_level,sp_item_list,sp_passedTags)
    newItems[#newItems+1] = ni
    ni.origin_room = room
    
    if sp.inventory then
      sp:give_item(ni)
      if #sp:get_inventory() >= (sp.inventory_space or 1) then
        sp.used = true
      else
        goto gen_item
      end
    else
      map:add_item(ni,sp.x,sp.y)
      sp.used = true
    end
    ::continue::
  end
  
  --If there's a special item population function for this room decorator, just use that
    if dec.populate_items then
      return dec.populate_items(room,map,item_list,passedTags)
    end
  
  --Spawn items in room from list:
  if item_list and #item_list > 0 then
    local branch = currWorld.branches[map.branch]
    
    --Spawn items in empty space:
    local clearSpace = 0
    local current_items = 0
    
    for x = room.minX,room.maxX,1 do
      for y = room.minY,room.maxY,1 do
        if map:isClear(x,y) then
          clearSpace = clearSpace+1
        end
        current_items = current_items + count(map:get_tile_items(x,y))
      end
    end
    --Calculate density
    local density = (dec and dec.item_density) or mapTypes[map.mapType].item_density or branch.item_density or gamesettings.item_density
    local itemMax = math.ceil(clearSpace*(density/100))-current_items
    
    --Do the actual spawning
    if itemMax > 0 then
      for i=1,itemMax,1 do
        local ni = mapgen:generate_item(min_level,max_level,item_list,passedTags)
        if ni == false then break end
        local ix,iy = random(room.minX,room.maxX),random(room.minY,room.maxY)
        local tries = 0
        while map:isClear(ix,iy) == false or map:tile_has_feature(ix,iy,"exit") or map.tile_info[ix][iy].noItems do
          ix,iy = random(room.minX,room.maxX),random(room.minY,room.maxY)
          tries = tries+1
          if tries > 100 then break end
        end
          
        --Place the actual item:
        if tries ~= 100 then 
          map:add_item(ni,ix,iy)
          newItems[#newItems+1] = ni
          ni.origin_room = room
        end --end tries if
      end
    end
  end --end if item list
  return newItems
end

function mapgen:get_content_list_from_tags(content_type,tags,forbiddenTags,requiredTags)
  local content_list
  local contents = {}
  if content_type == "creature" then
    content_list = possibleMonsters
  elseif content_type == "feature" then
    content_list = possibleFeatures
  elseif content_type == "item" then
    content_list = possibleItems
  elseif content_type == "spell" then
    content_list = possibleSpells
  elseif content_type == "store" then
    content_list = possibleStores
  elseif content_type == "faction" then
    content_list = possibleFactions
  elseif content_type == "roomDecorator" then
    content_list = roomDecorators
  elseif content_type == "roomShape" then
    content_list = roomShapes
  elseif content_type == "recipe" then
    content_list = possibleRecipes
  elseif content_type == "enchantment" then
    content_list = enchantments
  end
  if not content_list or count(content_list) < 1 or not tags or #tags < 1 then
    return contents
  end
  
  if searchSet then
    local newList = {}
    for _, id in ipairs(searchSet) do
      newList[id] = content_list[id]
    end
    if count(newList) < 1 then
      return contents
    end
    content_list = newList
  end
  
  for id,content in pairs(content_list) do
    if not content.neverSpawn and not content.specialOnly then
      local done = false
      local allowed = false
      if forbiddenTags then
        for _,tag in ipairs(forbiddenTags) do
          if content.tags and in_table(tag,content.tags) then
            done = true
            allowed = false
            break
          end
        end --end tag for
      end --end forbiddentags if
      if not done and requiredTags then
        for _, tag in ipairs(requiredTags) do
          if not content.tags or not in_table(tag,content.tags) then
            done = true
            allowed = false
            break
          end
        end
      end
      if not done and content.requiredMapTags then
        for _,tag in ipairs(content.requiredMapTags) do
          if not in_table(tag,tags) and (not mapTags or not in_table(tag,mapTags)) then
            done = true
            allowed = false
            break
          end
        end
      end
      if not done and content.forbiddenTags then
        for _,tag in ipairs(content.forbiddenTags) do
          if in_table(tag,tags) then
            done = true
            allowed = false
            break
          end
        end
      end
      if not done and content.forbiddenMapTags then
        for _,tag in ipairs(content.forbiddenMapTags) do
          if in_table(tag,tags) or (mapTags and in_table(tag,mapTags)) then
            done = true
            allowed = false
            break
          end
        end
      end
      if not done and content.tags then
        for _,tag in ipairs(tags) do
          if in_table(tag,content.tags) then
            done = true
            allowed = true
            break
          end
        end --end tags for
      end --end done if
      if allowed then
        contents[#contents+1] = id
      end
    end --end neverspawn if
  end --end content for
  return contents
end

---Generate a room on a map
--@param minX Number. The minimum X value of the room.
--@param minY Number. The minimum Y value of the room.
--@param maxX Number. The maximum X value of the room.
--@param maxY Number. The maximum Y value of the room.
--@param map Map. The map to create the room on.
--@param rectChance Number. Chance that the room will be a rectangle rather than any other room type
function mapgen:generate_room(minX,minY,maxX,maxY,map,rectChance)
  rectChance = rectChance or 50
  local ret
  if love.math.random(1,100) <= rectChance and roomTypes.rectangle then
    ret = roomTypes.rectangle(minX,minY,maxX,maxY,map)
  else
    local room = get_random_element(roomTypes)
    ret = room(minX,minY,maxX,maxY,map)
  end
  if ret.floors then
    for _,floor in pairs(ret.floors) do
      map.tile_info[floor.x][floor.y].room = ret
    end
  end
  if ret.walls then
    for _,wall in pairs(ret.walls) do
      map.tile_info[wall.x][wall.y].room = ret
    end
  end
  if not ret.midX or not ret.midY then
    ret.midX,ret.midY = ret.minX+round((ret.maxX-ret.minX)/2),ret.minY+round((ret.maxY-ret.minY)/2)
  end
  return ret
end

---Determines whether you can place a room in a location
--@param minX Number. The minimum X value of the room.
--@param minY Number. The minimum Y value of the room.
--@param maxX Number. The maximum X value of the room.
--@param maxY Number. The maximum Y value of the room.
--@param map Map. The map to create the room on.
function mapgen:can_place_room(minX,minY,maxX,maxY,map)
  for x=minX,maxX,1 do
    for y=minY,maxY,1 do
      if not map:in_map(x,y) or map.tile_info[x][y].room or map.tile_info[x][y].room == false then
        return false
      end
    end
  end
  return true
end