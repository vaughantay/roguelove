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
    success = layouts[whichLayout](build,width,height)
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
  print('creation complete',tostring(os.clock()-pTime))
  --Connect rooms:
  print('connecting rooms')
  if not whichMap.noConnectRooms and not build.rooms_connected and count(build.rooms) > 0 then
    build:connect_rooms(whichMap.connector_arguments)
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
  print('starting content population',tostring(os.clock()-pTime))
  print('populating rooms',tostring(os.clock()-pTime))
  build:populate_rooms()
  print('populating stores',tostring(os.clock()-pTime))
  build:populate_stores()
  print('populating factions',tostring(os.clock()-pTime))
  build:populate_factions()
  print('populating items',tostring(os.clock()-pTime))
  build:populate_items()
  print('populating creatures',tostring(os.clock()-pTime))
  build:populate_creatures()
  print('refreshing pathfinder',tostring(os.clock()-pTime))
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
  data = data or {}
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
  if build.possible_exits then
    build.possible_exits = shuffle(build.possible_exits)
    for _,tile in ipairs(build.possible_exits) do
      if not build:tile_has_feature(tile.x,tile.y,'exit') and (build.stairsUp.x ~= tile.x or build.stairsUp.y ~= tile.y) and (build.stairsDown.x ~= tile.x or build.stairsDown.y ~= tile.y) then
        if not build.stairsUp or (build.stairsUp.x == 0 and build.stairsUp.y == 0) then
          build.stairsUp.x, build.stairsUp.y = tile.x,tile.y
        elseif not build.stairsDown or (build.stairsDown.x == 0 and build.stairsDown.y == 0) then
          build.stairsDown.x, build.stairsDown.y = tile.x,tile.y
        end
      end
      if build.stairsUp.x ~= 0 and build.stairsUp.y ~= 0 and build.stairsDown.x ~= 0 and build.stairsDown.y ~= 0 then
        return true
      end
    end
  end
  if count(build.rooms) >= 2 then
    local farthest = 0
    local farthest1 = nil
    local farthest2 = nil
    for _,room in ipairs(build.rooms) do
      for _,partner in ipairs(build.rooms) do
        local dist = calc_distance_squared(room.midX,room.midY,partner.midX,partner.midY)
        if dist >= farthest then
          farthest = dist
          farthest1,farthest2 = room,partner
        end
      end
    end
    if farthest > 0 then
      local upRoom = farthest1
      local downRoom = farthest2
      if build.stairsUp.x == 0 and build.stairsUp.y == 0 then
        build.stairsUp.x,build.stairsUp.y = upRoom.midX,upRoom.midY
        farthest1.exit = true
      end
      if build.stairsDown.x == 0 and build.stairsDown.y == 0 then
        build.stairsDown.x,build.stairsDown.y = downRoom.midX,downRoom.midY
        farthest2.exit = true
      end
      return
    end
  end
  --No rooms? Just put them in the farthest apart rooms
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
    if build.stairsDown.x == 0 and build.stairsDown.y == 0 then
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
    end

    --Place up stairs:
    if build.stairsUp.x == 0 and build.stairsUp.y == 0 then
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
    end

    -- Make sure there's a clear path (shouldn't be a problem), and that they're far enough apart:
    if build.stairsDown.x ~= 0 and build.stairsDown.y ~= 0 and build.stairsUp.x ~= 0 and build.stairsUpy ~= 0 then
      local p = build:findPath(build.stairsDown.x,build.stairsDown.y,build.stairsUp.x,build.stairsUp.y)
      if p ~= false then
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
  if map.possible_exits then
    map.possible_exits = shuffle(map.possible_exits)
    for _,tile in ipairs(map.possible_exits) do
      if map:isClear(tile.x,tile.y) and not map:tile_has_feature(tile.x,tile.y,'exit') then
        return tile.x,tile.y
      end
    end
  end
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

---Gets a list of all types of content
--@param content_type String. The type of content to look for. Creature, feature, item, spell, store, faction, roomDecorator, roomShape, recipe
--@param tags Table. Content that has ANY of these tags will be included.
--@param args Table. Other potential arguments. Can include:
--@param forbiddenTags Table. Content with ANY these tags will be excluded
--@param requiredTags Table. Content that doesn't have ALL of these tags will be excluded
--@param mapTags Table. The tags from the map. Not used to search for content, but used for the item's own requiredMapTags and forbiddenMapTags
--@param searchSet Table. A list of IDs to search through for the given content_type. If blank, search through all of the possibilities in the game
function mapgen:get_content_list_from_tags(content_type,tags,args)
  local content_list
  local contents = {}
  args = args or {}
  local forbiddenTags = args.forbiddenTags
  local requiredTags = args.requiredTags
  local searchSet = args.searchSet
  local mapTags = args.mapTags
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

---Determines the largest free room area starting from a given point
--@param startX Number. The X coordinate to anchor off of
--@param startY Number. The Y coordinate to anchor off of
--@param direction String. The direction to look in
--@param map Map. The map to create the room on
--@info Table. Optional arguments including:
--@param max_width Number. The maximum width of the room
--@param max_height Number. The maximum height of the room
--@param min_width Number. The minimum width of the room
--@param min_height Number. The minimum height of the room
--@param centered Boolean. If true, the room must be centered on the anchor point
--@return Table or false. {minX=minX,minY=minY,maxX=maxX,maxY=maxY}
function mapgen:get_largest_room_from_anchor_point(startX,startY,direction,map,info)
  info = info or {}
  map = map or currMap
  local max_width = info.max_width or map.width
  local max_height = info.max_height or map.height
  local min_width = info.min_width or 3
  local min_height = info.min_height or 3
  local area_minX,area_minY,area_maxX,area_maxY = info.minX or 1,info.minY or 1,info.maxX or map.width,info.maxY or map.height
  local centered = info.centered
  
  if not direction or not (direction == "n" or direction == "s" or direction == "e" or direction == "w") then
    return false
  end
  if startX < area_minX or startX > area_maxX or startY < area_minY or startY > area_maxY then
    print('outside area',startX,startY,area_minX,area_minY,area_maxX,area_maxY)
    return false
  end
  
  local xMod,yMod = 0,0
  if direction == "n" then
    yMod = -1
  elseif direction == "s" then
    yMod = 1
  elseif direction == "w" then
    xMod = -1
  elseif direction == "e" then
    xMod = 1
  end
  
  local width,height = 0,0
  local minX,minY,maxX,maxY = startX,startY,startX,startY
  if xMod ~= 0 then --N/S primary direction
    local y = startY
    local check_startX,check_endX = startX+xMod,startX+max_width*xMod
    print('checking from X',check_startX,check_endX,xMod)
    for x=check_startX,check_endX,xMod do
      width = math.abs(startX-x)-1
      if not map:in_map(x,y) or map.tile_info[x][y].room or map.tile_info[x][y].room == false or x < area_minX or x > area_maxX then
        print('stopping at',x,y)
        break
      end
    end
    if width < min_width then
      print('too small of width',width,min_width)
      return false
    end
    minX = (xMod > 0 and startX or startX-width)
    maxX = (xMod > 0 and startX+width or startX)
    local x = startX+xMod
    minY,maxY=math.max(startY-min_height,area_minY),math.min(startY+min_height,area_maxY)
    print('checking Y',minY,maxY)
    for y=minY,maxY,1 do
      if not map:in_map(x,y) or map.tile_info[x][y].room or map.tile_info[x][y].room == false or y < area_minY or y > area_maxY then
        if y > startY then maxY = maxY-1
        elseif y < startY then minY = minY+1 end
      end
    end
    if centered then
      local smallest_diff = math.min(maxY-startY,startY-minY)
      minY = startY-smallest_diff
      maxY = startY+smallest_diff
    end
    height = maxY-minY
  elseif yMod ~= 0 then --N/S primary direction
    local x = startX
    local check_startY,check_endY = startY+yMod, startY+max_height*yMod
    print('checking from Y',check_startY,check_endY,yMod)
    for y=check_startY,check_endY,yMod do
      height = math.abs(startY-y)-1
      if not map:in_map(x,y) or map.tile_info[x][y].room or map.tile_info[x][y].room == false or y < area_minY or y > area_maxY then
        print('stopping at',x,y)
        break
      end
    end
    if height < min_height then
      print('too small of height',height,min_height)
      return false
    end
    minY = (xMod > 0 and startY or startY-height)
    maxY = (xMod > 0 and startY+height or startY)
    local y = startY+yMod
    minX,maxX=math.max(startX-min_height,area_minX),math.min(startX+min_height,area_maxX)
    print('checking X',minY,maxY)
    for x=minX,maxX,1 do
      if not map:in_map(x,y) or map.tile_info[x][y].room or map.tile_info[x][y].room == false or x < area_minX or x > area_maxX then
        if x > startX then maxX = maxX-1
        elseif x < startX then minX = minX+1 end
      end
    end
    if centered then
      local smallest_diff = math.min(maxX-startX,startX-minX)
      minX = startX-smallest_diff
      maxX = startX+smallest_diff
    end
    width = maxX-minX
    print(maxY,minY,height)
  end
  
  if width < min_width or height < min_height then
    print('too small of width or height')
    return false
  end
  
  return {minX=minX,maxX=maxX,minY=minY,maxY=maxY}
end

---Creates an encounter at a given threat level
--@param threat Number.
--@param creature_list Table. A list of possible creatures.
--@param min_level The lower level limit of the desired creature
--@param max_level The upper level limit of the desired creature
--@param tags Table. A list of tags to pass to the creature
--@param max_creatures Number. The maximum number of creatures
--@return Table. A table of creatures to place.
function mapgen:generate_encounter(threat,creature_list,min_level,max_level,tags,max_creatures)
  if not max_creatures then max_creatures = 100 end --todo: change this
  local encounter_creatures = {}
  
  if gamesettings.encounter_threat_definitions and gamesettings.encounter_threat_definitions[threat] then
    local threatDef = gamesettings.encounter_threat_definitions[threat]
    if type(threatDef) == "number" then
      threat = threatDef
    elseif type(threatDef) == "table" then
      local min = threatDef.min or 1
      local max = threatDef.max
      if not max then
        threat = min
      else
        threat = random(min,max)
      end
    end
  end
  if type(threat) ~= "number" or threat < 1 or not creature_list then
    return false
  end
  
  local largest_threat = 0
  local smallest_threat = nil
  local largest_list = {}
  for _,creatID in pairs(creature_list) do
    local creat = possibleMonsters[creatID]
    local cthreat = Creature.get_threat(creat)
    if cthreat then
      if cthreat == largest_threat then
        largest_list[#largest_list+1] = creatID
      elseif cthreat > largest_threat then
        largest_threat = threat,largest_threat
        largest_list = {creatID}
      end
      smallest_threat = (smallest_threat and math.min(smallest_threat,cthreat) or cthreat)
    end
  end
  
  local tries = 0
  local creature_count = 0
  local created_threat = 0
  local threat_remaining = threat-created_threat
  
  --Create a larger threat first if there's a bunch of extra "threat room"
  if threat > largest_threat*2 or threat/smallest_threat >= max_creatures then
    local nc = mapgen:generate_creature(min_level,max_level,largest_list,tags)
    if nc then
      local creatThreat = nc:get_threat()
      encounter_creatures[#encounter_creatures+1] = nc
      created_threat = created_threat + creatThreat
      creature_count = creature_count + 1
    end
  end
  
  --Generate other creatures:
  while created_threat < threat and tries < 100 and (threat_remaining >= (smallest_threat or 0)) and (not max_creatures or creature_count < max_creatures) do
    tries = tries + 1
    threat_remaining = threat-created_threat
    local nc = mapgen:generate_creature(min_level,max_level,creature_list,tags)
    if nc then
      local creatThreat = nc:get_threat()
      if threat_remaining > 0 and creatThreat <= threat_remaining*1.1 then --The 1.1 is there to give a little bit of wiggle room
        encounter_creatures[#encounter_creatures+1] = nc
        created_threat = created_threat + creatThreat
        creature_count = creature_count + 1
        --Add extra threat based on creature count
        if creature_count > 1 and gamesettings.encounter_threat_per_creature then
          created_threat = created_threat + gamesettings.encounter_threat_per_creature
        end
        if gamesettings.encounter_threat_at_x_creatures and gamesettings.encounter_threat_at_x_creatures[creature_count] then
          created_threat = created_threat + gamesettings.encounter_threat_at_x_creatures[creature_count]
        end
        if gamesettings.encounter_threat_per_x_creatures then
          for ccount,tamount in pairs(gamesettings.encounter_threat_per_x_creatures) do
            if creature_count % ccount == 0 then
              created_threat = created_threat + tamount
            end
          end
        end
        if max_creatures and creature_count >= max_creatures then
          break
        end
      end
    else --if no creature was generated
      return encounter_creatures,created_threat
    end --end threat_remaining if
  end --end while
  return encounter_creatures,created_threat
end