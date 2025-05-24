---@classmod Room
Room = Class{}

---Initiate a room. You shouldn't use this function, the game uses it at loadtime to instantiate the conditions.
--@param width Number. The width of the room.
--@param height Number. The height of the room.
--@param shape String, Table, or False. The name of the room shape, a table of possible shapes or False. Optional, if blank will just select a random one. If False, will not build the room at all yet, just create a blank room entry
--@param decorator String or Table. The name of the room decorator, or a table of possible decorators. Optional. If provided, the room will go ahead and decorate itself using it, if blank, it will just be an empty room
--@return Room. The room itself.
function Room:init(minX,minY,maxX,maxY,map,shape,decorator)
  self.baseType = "room"
  self.minX, self.minY, self.maxX, self.maxY = minX, minY, maxX, maxY
  self.width = maxX-minX
  self.height = maxY-minY
  self.midX = minX+round((maxX-minX)/2)
  self.midY = minY+round((maxY-minY)/2)
  self.map = map
  --Content info:
  self.floors = {}
  self.walls = {}
  self.dirWalls = {n={},s={},e={},w={}}
  self.doors = {}
  self.dirDoors = {n={},s={},e={},w={}}
  self.connections = {}
  self.neighbors = {}
  self.bonuses = {}
  --Build and decorate (if applicable)
  if shape ~= false then
    self:build(shape)
  end
  if decorator then
    self:decorate(decorator)
  end
	return self
end

---Creates the basic structure of the room and places it on the map
--@param shape
function Room:build(shape)
  local map = self.map
  if type(shape) == "table" then
    shape = get_random_element(shape)
  end
  if not shape or not roomShapes[shape] then
    shape = get_random_key(roomShapes)
  end
  self.shape = shape
  local shapeDef = roomShapes[shape]
  shapeDef.build(self.minX,self.minY,self.maxX,self.maxY,self.map,self)
  for _,floor in pairs(self.floors) do
    map.tile_info[floor.x][floor.y].room = self
  end
  for _,wall in pairs(self.walls) do
    if wall.x == nil or wall.y == nil then print('nil wall',wall.x,wall.y) end
    map.tile_info[wall.x][wall.y].room = self
  end
end

---Clear a room's decorator and remove all features
--@param noWalls Boolean. If true, don't call build_walls
--@param alsoItems Boolean. If true, delete items as well, otherwise preserve them
function Room:clear(noWalls,alsoItems)
  local map = self.map
  local branch = currWorld.branches[map.branch]
  map:clear_caches()
  if self.decorator then
    if not map.decorator_count then map.decorator_count = {} end
    if not branch.decorator_count then branch.decorator_count = {} end
    map.decorator_count[self.decorator] = (map.decorator_count[self.decorator] or 0)+1
    branch.decorator_count[self.decorator] = (branch.decorator_count[self.decorator] or 0)+1
    self.enchantment_chance = nil
    self.artifact_chance = nil
    self.no_room_connections = nil
    self.no_hallway_connections = nil
    self.no_outside_connections = nil
    self.bonuses = nil
    self.map_bonuses = nil
    self.game_bonuses = nil
    self.threat = nil
    self.decorator = nil
    self.noSecondary = nil
    self.decorated = nil
    self.upkeep = 0
  end
  for _,tile in pairs(self.floors) do
    for _,content in pairs(map.contents[tile.x][tile.y]) do
      if content.baseType == "feature" then
        if not alsoItems then
          content:drop_all_items()
        end
        content:delete()
      elseif content.baseType == "item" and alsoItems then
        content:delete()
      end
    end
    if map[tile.x][tile.y] ~= "." then
      map:change_tile(".",tile.x,tile.y)
    end
  end
  if not noWalls then
    for _,wall in pairs(self.walls) do
      local add_wall = true
      for _,content in pairs(map.contents[wall.x][wall.y]) do
        if content.baseType == "feature" and content:has_tag('wall') or content:has_tag('door') then
          add_wall = false
          if content.max_hp then
            content.hp = content.max_hp
          end
        elseif content.baseType == "feature" then
          if content.repair_feature then
            content:delete()
            local feat = Feature(content.repair_feature)
            map:add_feature(feat,wall.x,wall.y)
            add_wall = false
          else
            if not alsoItems then
              content:drop_all_items()
            end
            content:delete()
          end
        elseif content.baseType == "item" and alsoItems then
          content:delete()
        end
      end
      if add_wall then
        local featureID = self.wall_feature or map.wall_feature
        map:change_tile((featureID and Feature(featureID) or "#"),wall.x,wall.y)
      end
    end
  end
  for _,door in pairs(self.doors) do
    if not map:tile_has_tag(door.x,door.y,'door') then
      local door_feature = self.door_feature or map.door_feature or 'door'
      map:change_tile(".",door.x,door.y)
      map:add_feature(Feature(door_feature),door.x,door.y)
    end
  end
  --Refresh images:
  map:clear_caches()
  for x=self.minX-1,self.maxX+1,1 do
    for y=self.minY-1,self.maxY+1,1 do
      map:refresh_tile_image(x,y)
    end
  end
end

---Places walls in all the tiles in the room's walls table, in case the room was built somewhere without walls
--featureID String. The ID of the feature to use for the wall
function Room:build_walls(featureID)
  featureID = featureID or self.wall_feature
  local map = self.map
  for _,wall in pairs(self.walls) do
    map:clear_tile(wall.x,wall.y)
    map:change_tile((featureID and Feature(featureID) or "#"),wall.x,wall.y)
  end
end

---Determine if a given decorator can be used to decorate this room
--@param decID String. The ID of the given decorator
--@return Boolean. Whether or not this decorator can be used on this room
function Room:can_decorate(decID)
  local d = roomDecorators[decID]
  local map = self.map
  local branch = currWorld.branches[map.branch]
  
  if d and (not d.max_per_map or not map.decorator_count or (map.decorator_count[decID] or 0) < d.max_per_map) and (not d.max_per_branch or not branch.decorator_count or (branch.decorator_count[decID] or 0) < d.max_per_branch) and (not d.requires or d.requires(self,map) ~= false) and ((not d.min_width or d.min_width <= self.width) and (not d.min_height or d.min_height <= self.height)) and ((not d.max_width or d.max_width >= self.width) and (not d.max_height or d.max_height >= self.height)) and (not d.min_oneside or (self.width >= d.min_oneside or self.height >= d.min_oneside)) and (not d.max_oneside or (self.width <= d.max_oneside or self.height <= d.max_oneside)) and ((not d.max_depth or d.max_depth >= map.depth) and (not d.min_depth or d.min_depth <= map.depth)) then
    return true
  end
  return false
end

---Decorate a room
--@param decID String or table. Either the ID of a specific room decorator, or a table of room decorator IDs. Optional
--@param notPrimary Boolean. If true, don't assign this decorator's ID to the room's decorator ID (ie this is PURELY for decoration, will not be used for creature/item generation)
--@param args Anything. Arguments to pass to the decorator
function Room:decorate(decID,notPrimary,args)
  decID = decID or self.decorator
  local map = self.map
  local branch = currWorld.branches[map.branch]
  local dec = nil
  
  --If passed a specific decorator
  if type(decID) == "string" then
    if roomDecorators[decID] and self:can_decorate(decID) then
      dec = roomDecorators[decID]
    else
      return false --if we were passed a specific decorator but can't use it, don't do anything
    end
  end
  
  local possibles = {}
  --if passed a list of decorators
  if not dec and decID and type(decID) == "table" then 
    --First check to make sure all the decorators listed actually exist:
    local possibles = {}
    for _,ID in ipairs(decID) do
      if self:can_decorate(ID) then
        possibles[#possibles+1] = ID
      end
    end --end if decorators
  end
  
  --If not passed a list, get from the map's list
  if not dec and #possibles < 1 then
    local rlist = map:get_room_list()
    for _,ID in pairs(rlist) do
      if self:can_decorate(ID) then
        possibles[#possibles+1] = ID
      end
    end
  end --end if dec
  
  if #possibles > 0 then
    decID = get_random_element(possibles)
    dec = roomDecorators[decID]
  end
  
  if dec then
    --Set room's target encounter threat value:
    local threat = dec.threat
    if threat then
      local threatDef = gamesettings.encounter_threat_definitions and gamesettings.encounter_threat_definitions[threat]
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
    elseif dec.min_threat or dec.max_threat then
      local min = dec.min_threat or 1
      local max = dec.max_threat
      if not max then
        threat = min
      else
        threat = random(min,max)
      end
    end
    self.threat = threat
    
    if not notPrimary and not dec.secondary then
      self.decorator = decID
      self.noSecondary = dec.noSecondary
    end
    
    if not map.decorator_count then map.decorator_count = {} end
    if not branch.decorator_count then branch.decorator_count = {} end
    map.decorator_count[decID] = (map.decorator_count[decID] or 0)+1
    branch.decorator_count[decID] = (branch.decorator_count[decID] or 0)+1
    
    --Apply some data from the decorator:
    self.enchantment_chance = dec.enchantment_chance
    self.artifact_chance = dec.artifact_chance
    self.no_room_connections = dec.no_room_connections 
    self.no_hallway_connections = dec.no_hallway_connections
    self.no_outside_connections = dec.no_outside_connections
    self.bonuses = dec.bonuses
    self.map_bonuses = dec.map_bonuses
    self.game_bonuses = dec.game_bonuses
    self.upkeep = dec.upkeep
    
    --Remove inappropriate connections:
    local doors_to_remove = {}
    if dec.no_outside_connections then
      for _,door in ipairs(self.doors) do
        if door.outside then
          doors_to_remove[#doors_to_remove+1] = door
        end
      end
    end
    for _,door in ipairs(doors_to_remove) do
      local has,doorFeat = map:tile_has_tag(door.x,door.y,'door')
      if doorFeat then doorFeat:delete(map) end
      map:change_tile('#',door.x,door.y)
      --Remove from door arrays:
      local i = 1
      while i <= #self.doors do
        if self.doors[i] == door then
          table.remove(self.doors,i)
        else
          i = i + 1
        end
      end
      for dir,doors in pairs(self.dirDoors) do
        local i = 1
        while i <= #doors do
          if doors[i] == door then
            table.remove(doors,i)
          else
            i = i + 1
          end
        end
      end
    end
    
    --Apply decorator:
    if dec.decorate then
      local status,ret = pcall(dec.decorate,self,map,args)
      if status == false then
        output:out("Error in room decorator " .. decID .. " decorate code: " .. ret)
        print("Error in room decorator " .. decID.. " decorate code: " .. ret)
      end
      if status == false or ret == false then return false end
    end
    
    --Apply floors and walls:
    if dec.floor_feature then
      for _,tile in ipairs(self.floors) do
        if map[tile.x][tile.y] == "." then
          map:change_tile(Feature(dec.floor_feature),tile.x,tile.y)
        end
      end
      for _,tile in ipairs(self.walls) do
        if map[tile.x][tile.y] == "." and not dec.no_floor_feature_on_walls then
          map:change_tile(Feature(dec.floor_feature),tile.x,tile.y)
        end
      end
    end
    if dec.wall_feature then
      for _,tile in ipairs(self.walls) do
        if map[tile.x][tile.y] == "#" then
          map:change_tile(Feature(dec.wall_feature),tile.x,tile.y)
        end
      end
    end
    
    self.decorated = true
    
    if self.map == currMap then
      map:clear_caches()
      for x=self.minX-1,self.maxX+1,1 do
        for y=self.minY-1,self.maxY+1,1 do
          map:refresh_tile_image(x,y)
        end
      end
    end
  end
end

---Randomly add creatures to the map
--@param creatTotal Number. The number of creatures to add. Optional, if blank will generate enough to meet the necessary density
--@param forceGeneric Boolean. Whether to ignore any special populate_creatures() code in the room decorator's code. Optional
function Room:populate_creatures(creatTotal,forceGeneric)
  local decID = self.decorator
  local map = self.map
  local dec = roomDecorators[decID]
  local creature_list = {}
  local min_level = map:get_min_level()
  local max_level = map:get_max_level()
  
  if dec and (dec.creature_repopulate_limit or dec.repopulate_limit) then
    local spawns = (self.creature_populated_count or 0)
    if spawns > (dec.creature_repopulate_limit or dec.repopulate_limit) then
      return
    end
    self.creature_populated_count = (self.creature_populated_count or 0) + 1
  end
  

  --If there's a special function, use that instead
  if dec and dec.populate_creatures and not forceGeneric then
    return dec.populate_creatures(self,map)
  end
  creature_list = self:get_creature_list()
  
  --Now that we have a list, start working:
  if creature_list and #creature_list > 0 then
    local clearSpace = 0
    local current_creats = 0
    local branch = currWorld.branches[map.branch]
    
    --Passed tags:
    local passedTags = (dec and dec.passedTags or {})
    local mapPassed = map:get_content_tags('passed')
    passedTags = merge_tables(passedTags, mapPassed)
    
    for x = self.minX,self.maxX,1 do
      for y = self.minY,self.maxY,1 do
        local creat = map:get_tile_creature(x,y)
        if map:isClear(x,y) then
          clearSpace = clearSpace+1
        elseif creat then
          current_creats = current_creats+1
        end
      end
    end
    --Calculate density
    if not creatTotal then
      local density = (dec and dec.creature_density) or mapTypes[map.mapType].creature_density or branch.creature_density or gamesettings.creature_density
      creatTotal = math.ceil(clearSpace*(density/100))-current_creats
    end
    local maxCreatures = math.ceil(clearSpace/4)
    creatTotal = math.min(creatTotal,maxCreatures)
    
    --Calculate spawn points, because we'll use that as the max creature number if it's more than the regular number
    local creature_spawn_points = {}
    if map.creature_spawn_points and #map.creature_spawn_points > 0 then
      for i,sp in ipairs(map.creature_spawn_points) do
        if not sp.used and not sp.boss and map.tile_info[sp.x][sp.y].room == self and not map:tile_has_tag(sp.x,sp.y,'door') and not map:tile_has_feature(sp.x,sp.y,'exit') and not map:get_tile_creature(sp.x,sp.y) and not map.tile_info[sp.x][sp.y].noCreatures then
          creature_spawn_points[#creature_spawn_points+1] = sp
        end
      end
    end
    --creatTotal = math.max(creatTotal,#creature_spawn_points)
    
    --Generate an encounter, if possible
    local creatures_to_place
    local threat_to_place = self:get_target_threat()
    if threat_to_place then
      threat_to_place = threat_to_place - self:get_current_threat()
      if threat_to_place < 1 then
        return newCreats
      else
        creatures_to_place = mapgen:generate_encounter(threat_to_place,creature_list,min_level,max_level,passedTags,maxCreatures)
      end
    end
    
    --Do the actual spawning
    if creatTotal > 0 or (creatures_to_place and #creatures_to_place > 0) then
      local newCreats = {}
      local creats_spawned = 0
      local tries = 0
      
      ::gen_creature::
      while ((not creatures_to_place and creats_spawned < creatTotal) or (creatures_to_place and #creatures_to_place > 0)) and tries < 100 do
        tries = 0 --tries are calculated later on
        local placed = false
        local nc
        local ncID
        if creatures_to_place then
          ncID = get_random_key(creatures_to_place)
          nc = creatures_to_place[ncID]
        else
          nc = mapgen:generate_creature(min_level,max_level,creature_list,passedTags)
        end
        if not nc then break end
        
        --Spawn in designated spawn points first:
        local sptries = 0
        while (#creature_spawn_points > 0) and sptries < 100 do
          sptries = sptries + 1
          local spk = get_random_key(creature_spawn_points)
          local sp = creature_spawn_points[spk]
          if nc:can_move_to(sp.x,sp.y,map) then
            if random(1,4) == 1 then nc:give_condition('asleep',random(10,100)) end
            local creat = map:add_creature(nc,sp.x,sp.y)
            newCreats[#newCreats+1] = creat
            placed = creat
            sp.used = true
            table.remove(creature_spawn_points,spk)
            if ncID and creatures_to_place then
              table.remove(creatures_to_place,ncID)
            end
            goto gen_creature
          end
        end
        
        --If not spawned at a spawn point, find a spot to spawn:
        if not placed then
          local cx,cy = random(self.minX,self.maxX),random(self.minY,self.maxY)
          while nc:can_move_to(cx,cy,map) == false or map:tile_has_tag(cx,cy,'door') or map:tile_has_feature(cx,cy,'exit') or not map:isClear(cx,cy,nc:get_pathType()) or map.tile_info[cx][cy].noCreatures do
            cx,cy = random(self.minX,self.maxX),random(self.minY,self.maxY)
            tries = tries+1
            if tries > 100 then
              if ncID and creatures_to_place then
                table.remove(creatures_to_place,ncID)
              end
              goto gen_creature
            end
          end
          
          --Place the actual creature:
          if tries < 100 then 
            if random(1,4) == 1 then nc:give_condition('asleep',random(10,100)) end
            local creat = map:add_creature(nc,cx,cy)
            --creat.origin_room = self
            placed = creat
            newCreats[#newCreats+1] = creat
            creats_spawned = creats_spawned+1
            if ncID and creatures_to_place then
              table.remove(creatures_to_place,ncID)
            end
          end --end tries if
        end
        
        --Place group spawns, if not placing creatures from an encounter:
        if placed and not creatures_to_place and (nc.group_spawn or nc.group_spawn_max) then
          local spawn_amt = (nc.group_spawn or random((nc.group_spawn_min or 1),nc.group_spawn_max))
          if not nc.group_spawn_no_tweak then spawn_amt = tweak(spawn_amt) end
          if spawn_amt < 1 then spawn_amt = 1 end
          local x,y = placed.x,placed.y
          for i=1,spawn_amt,1 do
            local tries2 = 1
            local cx,cy = random(x-tries,x+tries),random(y-tries,y+tries)
            while nc:can_move_to(cx,cy,map) == false or map:tile_has_tag(cx,cy,'door') or map:tile_has_feature(cx,cy,'exit') or not map:isClear(cx,cy,nc:get_pathType()) or map.tile_info[cx][cy].noCreatures do
              cx,cy = random(x-tries,x+tries),random(y-tries,y+tries)
              tries2 = tries2 + 1
              if tries2 > 10 then break end
            end --end while
            if tries2 <= 10 then
              local creat = mapgen:generate_creature(min_level,max_level,{nc.id},passedTags)
              map:add_creature(creat,cx,cy)
              --nc.origin_room = self
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

---Randomly add items to the room
--@param itemTotal Number. The number of items to add. Optional, if blank will generate enough to meet the necessary density
--@param forceGeneric Boolean. Whether to ignore any special populate_items() code in the room decorator's code. Optional
function Room:populate_items(itemTotal,forceGeneric)
  local decID = self.decorator
  local map = self.map
  local branch = currWorld.branches[map.branch]
  local dec = roomDecorators[decID]
  local item_list = {}
  local newItems = {}
  
  if dec and (dec.item_repopulate_limit or dec.repopulate_limit) then
    local spawns = (self.item_populated_count or 0)
    if spawns > (dec.item_repopulate_limit or dec.repopulate_limit) then
      return
    end
    self.item_populated_count = (self.item_populated_count or 0) + 1
  end
  
  --Create list of items
  item_list = self:get_item_list()
  
  --Info for items (passed tags and levels):
  local passedTags = (dec and dec.passedTags or {})
  local mapPassed = map:get_content_tags('passed')
  local mapTags = (not self.noMapTags and map:get_content_tags('item') or nil)
  passedTags = merge_tables(passedTags, mapPassed)
  local min_level = map:get_min_level(true)
  local max_level = map:get_max_level(true)
  
  --If there's a special item population function for this room decorator, use that
  if dec.populate_items and not forceGeneric then
    return dec.populate_items(self,map,item_list,passedTags,min_level,max_level)
  end
  
  --Spawn in designated spawn points first:
  local item_spawn_points = {}
  if map.item_spawn_points and #map.item_spawn_points > 0 then
    for i,sp in ipairs(map.item_spawn_points) do
      if not sp.used and map.tile_info[sp.x][sp.y].room == self and not map:tile_has_feature(sp.x,sp.y,'exit') and ((sp.inventory and #sp:get_inventory() < (sp.inventory_space or 1)) or (map:isClear(sp.x,sp.y,nil,true) and #map:get_tile_items(sp.x,sp.y) == 0 and not map.tile_info[sp.x][sp.y].noItems)) then
        item_spawn_points[#item_spawn_points+1] = sp
      end
    end
  end
  
  for spk,sp in pairs(item_spawn_points) do
    if sp.baseType == "feature" then
      sp:populate_items(map,self)
      sp.used=true
      goto continue
    end
    
    local sp_item_list = {}
    local sp_passedTags = merge_tables(passedTags,(sp.passedTags or {}))
    local artifact_chance = sp.artifact_chance or self.artifact_chance or map.artifact_chance or branch.artifact_chance or gamesettings.artifact_chance or 0
    local enchantment_chance = sp.enchantment_chance or self.enchantment_chance or map.enchantment_chance or branch.enchantment_chance or gamesettings.enchantment_chance or 0
    
    --Create item list:
    if sp.items then
      sp_item_list = sp.items or {}
    end --end if items
    if sp.itemTags or sp.contentTags or sp.forbiddenTags then
      local tags = sp.itemTags or sp.contentTags or dec.itemTags or dec.contentTags or {}
      local forbidden = sp.forbiddenTags
      local required = sp.requiredTags
      local tagged_items = mapgen:get_content_list_from_tags('item',tags,{forbiddenTags=forbidden,requiredTags=required,mapTags=mapTags})
      sp_item_list = merge_tables(sp_item_list,tagged_items)
    elseif not sp.items then --if there's no item list or tag list set, just use the item list of the room
      sp_item_list = item_list
    end
    
    ::gen_item::
    local ni = mapgen:generate_item(min_level,max_level,sp_item_list,sp_passedTags,nil,artifact_chance,enchantment_chance)
    newItems[#newItems+1] = ni
    ni.origin_map = map.id
    ni.origin_branch = map.branch
    --ni.origin_room = self
    
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
  
  --Spawn items in room from list:
  if item_list and #item_list > 0 then
    local artifact_chance = self.artifact_chance or map.artifact_chance or branch.artifact_chance or gamesettings.artifact_chance or 0
    local enchantment_chance = self.enchantment_chance or map.enchantment_chance or branch.enchantment_chance or gamesettings.enchantment_chance or 0
    
    --Spawn items in empty space:
    local clearSpace = 0
    local current_items = 0
    
    for x = self.minX,self.maxX,1 do
      for y = self.minY,self.maxY,1 do
        if map:isClear(x,y) then
          clearSpace = clearSpace+1
        end
        current_items = current_items + count(map:get_tile_items(x,y))
      end
    end
    --Calculate density
    if not itemTotal then
      local density = (dec and dec.item_density) or mapTypes[map.mapType].item_density or branch.item_density or gamesettings.item_density
      itemTotal = math.ceil(clearSpace*(density/100))-current_items
    end
    
    --Do the actual spawning
    if itemTotal > 0 then
      for i=1,itemTotal,1 do
        local ni = mapgen:generate_item(min_level,max_level,item_list,passedTags,nil,artifact_chance,enchantment_chance)
        if ni == false then break end
        local ix,iy = random(self.minX,self.maxX),random(self.minY,self.maxY)
        local tries = 0
        while map:isClear(ix,iy) == false or map:tile_has_feature(ix,iy,"exit") or map.tile_info[ix][iy].noItems do
          ix,iy = random(self.minX,self.maxX),random(self.minY,self.maxY)
          tries = tries+1
          if tries > 100 then break end
        end
          
        --Place the actual item:
        if tries ~= 100 then 
          map:add_item(ni,ix,iy)
          newItems[#newItems+1] = ni
          --ni.origin_room = self
        end --end tries if
      end
    end
  end --end if item list
  return newItems
end

---Gets a list of possible walls that could be turned into doors (ie there's open space on both sides)
--@paran exlude_rooms Boolean. If true, walls with rooms on the other side are exluded
--@paran exlude_hallways Boolean. If true, walls with hallways on the other side are exluded
--@return Table. A table of possible doors, in the format {n={{x=x,y=y},{x=x,y=y}},s={},e={},w={}}
function Room:get_possible_doors(exclude_rooms,exclude_hallways)
  local map = self.map
  local possibles={n={},s={},e={},w={}}
  
  for dir,walls in pairs(self.dirWalls) do
    local midDoor
    for _,wall in ipairs(walls) do
      local x1,x2,y1,y2=wall.x,wall.x,wall.y,wall.y --these are the coordinates that will be looked at to see if they're floors
      local xn1,xn2,yn1,yn2 = wall.x,wall.x,wall.y,wall.y -- these are the coordinates that will be looked at to see if they're walls
      if dir == "n" or dir == "s" then
        y1,y2=wall.y-1,wall.y+1
        xn1,xn2=wall.x-1,wall.x+1
      elseif dir == "e" or dir == "w" then
        x1,x2=wall.x-1,wall.x+1
        yn1,yn2=wall.y-1,wall.y+1
      end --end if dir == n
      if map:in_map(x1,y1) and map:in_map(x2,y2) and map:in_map(xn1,yn1) and map:in_map(xn2,yn2) and map:isClear(x1,y1) and map:isClear(x2,y2) and map:isWall(xn1,yn1) and map:isWall(xn2,yn2) then
        local room1,room2 = map.tile_info[x1][y1].room, map.tile_info[x2][y2].room
        local hallway = map.tile_info[x1][y1].hallway or map.tile_info[x2][y2].hallway
        local whichRoom = nil
        local outside = false
        if room1 and room1 ~= self then whichRoom = room1
        elseif room2 and room2 ~= self then whichRoom = room2 end
        if room1 == self and not room2 and map.tile_info[x2][y2].outside then outside = true
        elseif room2 == self and not room1 and map.tile_info[x1][y1].outside then outside = true end
        if (not exclude_rooms or not whichRoom) and (not exclude_hallways or not hallway) then
          possibles[dir][#possibles[dir]+1] = {x=wall.x,y=wall.y,room=whichRoom,hallway=hallway,outside=outside}
          if wall.x == self.midX or wall.y == self.midY then
            midDoor = possibles[dir][#possibles[dir]]
          end
        end
      end
    end
    possibles[dir] = shuffle(possibles[dir])
    if midDoor then
      table.insert(possibles[dir],1,midDoor)
    end
  end
  return possibles
end

---Gets a list of creatures that can spawn in the room.
--@param Table. A table listing the creatures
function Room:get_creature_list()
  local creature_list = {}
  local dec = roomDecorators[self.decorator]
  if not dec then return self.map:get_creature_list() end
  
  if dec.creatures then
    creature_list = copy_table(dec.creatures or {})
  end --end if creatures
  if dec.creatureTypes or dec.creatureTags or dec.contentTags then
    local tags = self:get_content_tags('creature')
    local ftags = merge_tables(self:get_content_tags('forbidden'),self.map:get_content_tags('forbidden'))
    local rtags = merge_tables(self:get_content_tags('required'),self.map:get_content_tags('required'))
    local mapTags = (not self.noMapTags and self.map:get_content_tags('creature') or nil)
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
      if done and rtags then
        for _, rtag in ipairs(rtags) do
          if not Creature.has_tag(creat,rtag) then
            done = false
            break
          end
        end
      end
      if done and ftags then
        for _,ftag in ipairs(ftags) do
          if Creature.has_tag(creat,ftag) then
            done = false
            break
          end
        end
      end
      if done and creat.requiredMapTags then
        for _,rtag in ipairs(creat.requiredMapTags) do
          if not in_table(rtag,tags) and (not mapTags or not in_table(rtag,mapTags)) then
            done = false
            break
          end
        end
      end
      if done and creat.forbiddenMapTags then
        for _,ftag in ipairs(creat.forbiddenMapTags) do
          if in_table(ftag,tags) or (mapTags and in_table(ftag,mapTags)) then
            done = false
            break
          end
        end
      end
      if done then
        creature_list[#creature_list+1] = cid
      end
    end --end creature for
  end --end if creature or tags listed in room decorator
  if #creature_list == 0 then
    creature_list = self.map:get_creature_list()
  end
  return creature_list
end

function Room:get_item_list()
  local item_list = {}
  local dec = roomDecorators[self.decorator]
  if not dec then return self.map:get_item_list() end

  if dec.items then
    item_list = copy_table(dec.items or {})
  end --end if items
  if dec.itemTags or dec.contentTags then
    local tags = self:get_content_tags('item')
    local ftags = merge_tables(self:get_content_tags('forbidden'),self.map:get_content_tags('forbidden'))
    local rtags = merge_tables(self:get_content_tags('required'),self.map:get_content_tags('required'))
    local mapTags = (not self.noMapTags and self.map:get_content_tags('item') or nil)
    local tagged_items = mapgen:get_content_list_from_tags('item',tags,{forbiddenTags=ftags,requiredTags=rtags,mapTags=mapTags})
    item_list = merge_tables(item_list,tagged_items)
  end --end if item or tags listed in room decorator
  if #item_list == 0 then
    item_list = self.map:get_item_list()
  end
  return item_list
end

---Returns the threat value that should populate in the room
--@return Number. The threat value that should be placed in the room
function Room:get_target_threat()
  if not self.threat then return false end
  local threat = self.threat
  for x = self.minX,self.maxX,1 do
    for y = self.minY,self.maxY,1 do
      for _,content in pairs(self.map:get_contents(x,y)) do
        if content.get_threat_modifier then
          threat = threat + content:get_threat_modifier()
        elseif content.threat_modifier then
          threat = threat + content.threat_modifier
        end
        if content.inventory then
          for _,item in pairs(content.inventory) do
            threat = threat + item:get_threat_modifier()
          end
        end --end inventory if
      end --end content for
    end --end y for
  end --end x for
  return threat
end

---Returns the current threat value in the room
--@return Number. The threat value of all content in the room
function Room:get_current_threat()
  local threat = 0
  local creature_count = 0
  for x = self.minX,self.maxX,1 do
    for y = self.minY,self.maxY,1 do
      local creat = self.map:get_tile_creature(x,y)
      if creat and not creat:is_friend(player) then
        threat = threat + creat:get_threat()
        creature_count = creature_count+1
        --Add extra threat based on creature count
        if creature_count > 1 and gamesettings.encounter_threat_per_creature then
          threat = threat + gamesettings.encounter_threat_per_creature
        end
        if gamesettings.encounter_threat_at_x_creatures and gamesettings.encounter_threat_at_x_creatures[creature_count] then
          threat = threat + gamesettings.encounter_threat_at_x_creatures[creature_count]
        end
        if gamesettings.encounter_threat_per_x_creatures then
          for ccount,tamount in pairs(gamesettings.encounter_threat_per_x_creatures) do
            if creature_count % ccount == 0 then
              threat = threat + tamount
            end
          end
        end
      end
      for _,content in pairs(self.map:get_contents(x,y)) do --TODO: test features and effects adding threat
        if content.threat and content.baseType ~= "creature" and content.baseType ~= "item" then --Items lying on the ground shoudln't add threat, they only add threat if equipped by a creature
          if content.get_threat then
            threat = threat + content:get_threat()
          else
            threat = threat + content.threat
          end
        end
      end
      if type(self.map[x][y]) == "table" then
        if self.map[x][y].get_threat then
          threat = threat + self.map[x][y]:get_threat()
        elseif self.map[x][y].threat then
          threat = threat + self.map[x][y].threat
        end
      end
      for _,effect in pairs(self.map:get_tile_effects(x,y)) do
        if effect.get_threat then
          threat = threat + effect:get_threat()
        elseif effect.threat then
          threat = threat + effect.threat
        end
      end
    end
  end
  return threat
end

---Returns the current value of all items the room
--@return Number. The value of all items in the room
function Room:get_current_value(printVals)
  local value = 0
  for x = self.minX,self.maxX,1 do
    for y = self.minY,self.maxY,1 do
      for _,content in pairs(self.map:get_contents(x,y)) do
        if content.baseType == "item" then
          if printVals then print(content.name,content:get_value()) end
          value = value + content:get_value()
        end
        if content.inventory and content ~= player then
          if printVals then print(content.name) end
          for _,item in ipairs(content.inventory) do
            if printVals then print(item.name,item:get_value()) end
            value = value + item:get_value()
          end
        end
        if content.creature then
          if printVals then print(content.creature.name) end
          for _,item in ipairs(content.creature.inventory) do
            if printVals then print(item.name,item:get_value()) end
            value = value + item:get_value()
          end
        end
      end
    end
  end
  return value
end

---Get a map's content tags
--@param tagType String. The type of tag
function Room:get_content_tags(tagType)
  local dec = roomDecorators[self.decorator]
  if not dec then return self.map:get_content_tags(tagType) end
  local tagLabel = (tagType and tagType .. "Tags" or "contentTags")
  local tags = (dec[tagLabel] or (tagLabel ~= "passedTags" and tagLabel ~= "forbiddenTags" and tagLabel ~= "requiredTags" and dec.contentTags) or {})
  return tags
end

---Checks if a map has a given content tag
--@param tag String. The tag to check for
--@param tagType String. The type of tag
--@return Boolean. Whether or not it has the tag.
function Room:has_content_tag(tag,tagType)
  if in_table(tag,self:get_content_tags(tagType)) then
    return true
  end
  return false
end

---Checks if a map has a descriptive tag.
--@param tag String. The tag to check for
--@return Boolean. Whether or not it has the tag.
function Room:has_tag(tag)
  local dec = roomDecorators[self.decorator]
  if not dec then return false end
  if dec.tags and in_table(tag,dec.tags) then
    return true
  end
  return false
end

---Gets all the "safe to block" tiles in a room. Takes a list of tiles and runs map:is_safe_to_block on them.
--@param openType Text. Determines what counts as "safe." "wall": next to wall only, "noWalls": not next to wall, "wallsCorners": open walls and corners only, "corners": corners only
--@return Table. A table of tiles deemed safe to block.
function Room:get_all_safe_to_block(openType)
  local map = self.map
  local safe = {}
  for _,floor in pairs(self.floors) do
    if map:is_safe_to_block(floor.x,floor.y,openType) then
      safe[#safe+1] = {x=floor.x,y=floor.y}
    end --end if
  end --end for
  return safe
end

---Gets the largest available rectangle in the room while 
function Room:get_largest_internal_rectangle()
  local map = self.map
  local minX,minY,maxX,maxY = self.midX-1,self.midY-1,self.midX+1,self.midY+1
  local finalized = false
  while finalized == false do
    finalized = true
    local moveUp,moveDown,moveLeft,moveRight = true,true,true,true
    
    for x = minX, maxX, 1 do
      if map.tile_info[x][minY-2].room ~= self or not map:is_safe_to_block(x,minY-2,'noWalls') then
        moveUp = false
      end
      if map.tile_info[x][minY+2].room ~= self or not map:is_safe_to_block(x,maxY+2,'noWalls') then
        moveDown = false
      end
    end
    for y = minY,maxY, 1 do
      if map.tile_info[minX-2][y].room ~= self or not map:is_safe_to_block(minX-2,y,'noWalls') then
        moveLeft= false
      end
      if map.tile_info[minX+2][y].room ~= self or not map:is_safe_to_block(maxX+2,y,'noWalls') then
        moveRight = false
      end
    end
    if moveUp then
      minY = minY-1
      finalized = false
    end
    if moveDown then
      maxY = maxY+1
      finalized = false
    end
    if moveLeft then
      minX = minX-1
      finalized = false
    end
    if moveRight then
      maxX = maxX+1
      finalized = false
    end
  end
  return minX,minY,maxX,maxY
end

---Gets a list of all rooms that border a room
--@param force_refresh. If true, calculate neighbors again
--@return Table. A table of rooms bordering this room
function Room:get_neighbors(force_refresh)
  if self.neighbors and count(self.neighbors) > 0 and not force_refresh then
    return self.neighbors
  end
  
  local rooms = {}
  for _,info in ipairs(self:get_possible_doors()) do
    if info.room then
      rooms[info.room] = true
    end
  end --end for wall
  
  return rooms
end

---Gets a list of distances to all rooms
--@param force_refresh. If true, calculate neighbors again
--@return Table. A table of rooms bordering this room
function Room:get_distances(force_refresh)
  if self.distances and count(self.distances) > 0 and not force_refresh then
    return self.distances
  end
  
  self.distances = {}
  for _,partner in ipairs(self.map.rooms) do
    if partner == self then
      --do nothing
    elseif partner.distances and partner.distances[self] and not force_refresh then
      self.distances[#self.distances+1] = {room=partner,distance=partner.distances[self]}
    else
      self.distances[#self.distances+1] = {room=partner,distance=calc_distance(self.midX,self.midY,partner.midX,partner.midY)}
    end
  end --end for wall
  sort_table(self.distances,'distance')
  return self.distances
end

---Connect a room to other rooms. First, checks any neighboring rooms, and creates doors between them. If it doesn't manage that, then create hallways
--@param info Table. A table of info
function Room:connect(info)
  info = info or {}
  local map = self.map
  local doorChance = info.doorChance or 100
  local doorFeature = info.doorFeature or "door"
  local connections = info.connections or 1
  local no_build_hallways = info.no_build_hallways
  local no_room_connections = info.no_room_connections or self.no_room_connections
  local no_hallway_connections = info.no_hallway_connections or self.no_hallway_connections
  local no_outside_connections = info.no_outside_connections or self.no_outside_connections
  local force_hallway_connections = info.force_hallway_connections or self.force_hallway_connections
  local force_room_connections = info.force_room_connections or self.force_room_connections
  local force_outside_connections = info.force_outside_connections or self.force_outside_connections
  local force_any = force_hallway_connections or force_room_connections or force_outside_connections
  local forceHallways = info.forceHallways
  
  --First, check to see if there are possible openings directly outside the room
  local doorDirs = {n=false,s=false,e=false,w=false}
  local possibleDoors = self:get_possible_doors()
  --local neighbors = self:get_neighbors()
  local placed = 0
  for dir,walls in pairs(possibleDoors) do
    if not doorDirs[dir] and count(walls) > 0 then
      for _,wall in ipairs(walls) do
        local place = true
        local connectedroom = nil
        --Check to make sure we don't already have a door into this room or hallway:
        local roomNo = (wall.room and ((self.connections[wall.room] or no_room_connections) or (placed >= connections and not force_room_connections)))
        local hallwayNo = (wall.hallway and ((self.connections[wall.hallway] and count(self.dirDoors[dir]) > 0) or no_hallway_connections) or (placed >= connections and not force_hallway_connections))
        local outsideNo = (wall.outside and (no_outside_connections or count(self.dirDoors[dir]) > 0 or (placed >= connections and not force_outside_connections)))
        if roomNo or hallwayNo or outsideNo then
          place = false
        end
        if map:tile_has_tag(wall.x,wall.y,'door') then
          place = false
        end
        if not (map:isWall(wall.x-1,wall.y) and map:isWall(wall.x+1,wall.y)) and not (map:isWall(wall.x,wall.y-1) and map:isWall(wall.x,wall.y+1)) then
          place = false
        end
        if place then
          placed = placed + 1
          map:clear_tile(wall.x,wall.y)
          map[wall.x][wall.y] = "."
          doorDirs[dir] = true
          self.doors[#self.doors+1] = {x=wall.x,y=wall.y,room=wall.room,hallway=wall.hallway,outside=wall.outside}
          self.dirDoors[dir][#self.dirDoors[dir]+1] = {x=wall.x,y=wall.y,room=wall.room,hallway=wall.hallway,outside=wall.outside}
          --Set tiles around the door as non-blockable
          for x=wall.x-1,wall.x+1,1 do
            for y=wall.y-1,wall.y+1,1 do
              if x == wall.x or y == wall.y then
                map.tile_info[x][y].noBlock = true
              end
            end
          end
          if random(1,100) <= doorChance and not map.tile_info[wall.x][wall.y].noDoor then
            local door = map:add_feature(Feature(doorFeature),wall.x,wall.y)
          end
          connectedroom = wall.room
          if connectedroom then
            self.connections[connectedroom] = true
            connectedroom.connections[self] = true
            connectedroom.doors[#connectedroom.doors+1] = {x=wall.x,y=wall.y,room=self}
          end
          if wall.hallway then
            wall.hallway.connections[self] = true
            self.connections[wall.hallway] = true
          end
          if connections and placed >= connections and not (force_any and connections < 4) then
            return true
          else
            break --break out of looking at this direction
          end --end connections if
        end --end place if
      end --end for ipairs(walls)
    end --end if direction set
  end --end dirwall for
  
  --If that didn't satisfy the number of connections, create hallways to the nearest non-connected rooms:
  if not no_build_hallways and (forceHallways or (count(self.doors) < connections)) then
    print('connecting via hallway',self.midX,self.midY,count(self.doors),connections,no_build_hallways)
    for i=count(self.doors),connections,1 do
      local connected = false
      local connectionCount = 1
      while connected == false and connectionCount < 5 do
        local distances = self:get_distances()
        for _,distInfo in ipairs(distances) do
          local partner = distInfo.room
          if partner ~= self and not self.connections[partner] and count(partner.doors) < connectionCount then
            if self:connect_to_room(partner,info) then
              placed = placed + 1
              connected = true
              break
            end
          end
        end --end distance for
        if not connected then
          connectionCount = connectionCount+1
        end
      end --end while
      --If connecting by distance didn't do it for whatever reason, just connect to a random room you haven't already connected to yet
      if not connected then
        print('unable to connect to nearby, connecting torandom')
        map.rooms = shuffle(map.rooms)
        for _,partner in pairs(map.rooms) do
          if partner ~= self and not self.connections[partner] then
            if self:connect_to_room(partner,info) then
              placed = placed + 1
              if not connections or count(self.doors) >= connections then
                break
              end
            end
          end
        end --end partner for
      end
    end
  end
  
  if placed == 0 and count(self.doors) == 0 and (no_hallway_connections or no_room_connections) then
    print('placed?',placed,self.midX,self.midY,'redoing')
    local newInfo = copy_table(info)
    newInfo.no_hallway_connections = nil
    newInfo.no_room_connections = nil
    self:connect(newInfo)
  end
  return placed
end

---Build a hallway from one room to another room
--@param partner Room. The room to connect it to
--@param info Table. Table of info
--@return Boolean. Whether the connection was successful
function Room:connect_to_room(partner,info)
  info = info or {}
  local map = self.map
  local doorChance = info.doorChance or 100
  local doorFeature = info.doorFeature or "door"
  local connections = info.connections
  local wideChance = info.wideChance or 0
  
  if not pathfinders[map].roomwalls then
    map:refresh_pathfinder('roomwalls')
    pathfinders[map].roomwalls:setMode('ORTHOGONAL')
  end
  --Determine which possible walls would be best for the tunnel:
  local possibleWalls = {room={},partner={}}
  --If a room is entirely to one side of another, choose the applicable walls
  if partner.minX>self.maxX then possibleWalls.room.e = true possibleWalls.partner.w = true end
  if partner.minY>self.maxY then possibleWalls.room.s = true possibleWalls.partner.n = true end
  if partner.maxX<self.minX then possibleWalls.room.w = true possibleWalls.partner.e = true end
  if partner.maxY<self.minY then possibleWalls.room.n = true possibleWalls.partner.s = true end
  
  --Pick one of the walls and set starting locations:
  local startX,startY = 0,0
  local endX,endY = 0,0
  --Select room's wall:
  local roomDirChosen = false
  local usingOldRoomDoor = false
  local usingOldPartnerDoor = false
  --Loop through possible directions
  for roomWall,_ in pairs(possibleWalls.room) do
    --first, look at doors that already exist in that direction 
    self.dirDoors[roomWall] = shuffle(self.dirDoors[roomWall])
    for _,door in ipairs(self.dirDoors[roomWall]) do
      startX,startY = door.x,door.y
      roomDirChosen = roomWall
      usingOldRoomDoor=true
      break
    end
    if not roomDirChosen then
      self.dirWalls[roomWall] = shuffle(self.dirWalls[roomWall])
      for _,startWall in ipairs(self.dirWalls[roomWall]) do
        if ((startWall.x ~= self.minX and startWall.x ~= self.maxX) or (startWall.y ~= self.minY and startWall.y ~= self.maxY)) and map:isWall(startWall.x,startWall.y) then
          local wallCardinals = {n=map:isWall(startWall.x,startWall.y-1),s=map:isWall(startWall.x,startWall.y+1),w=map:isWall(startWall.x-1,startWall.y),e=map:isWall(startWall.x+1,startWall.y)}
          local openCardinals = {n=map:isClear(startWall.x,startWall.y-1),s=map:isClear(startWall.x,startWall.y+1),w=map:isClear(startWall.x-1,startWall.y),e=map:isClear(startWall.x+1,startWall.y)}
          if (wallCardinals.n and wallCardinals.s and (openCardinals.e or openCardinals.w)) or (wallCardinals.e and wallCardinals.w and (openCardinals.n or openCardinals.s)) then
            startX,startY = startWall.x,startWall.y
            roomDirChosen = roomWall
            break
          end
        end --end wall-not-on-corner check
      end --end startWall for
    end --end if not roomDirChosen
    if roomDirChosen then break end
  end --end direction for
  if not roomDirChosen then
    --print('noRoomDirChosen')
    return false
  end
  --Select partner's wall:
  local partnerDirChosen = false
  if not partnerDirChosen then
    for partnerWall,_ in pairs(possibleWalls.partner) do
      --first, look at doors that already exist in that direction 
      partner.dirDoors[partnerWall] = shuffle(partner.dirDoors[partnerWall])
      for _,door in ipairs(partner.dirDoors[partnerWall]) do
        endX,endY = door.x,door.y
        map.collisionMaps.roomwalls[startY][startX] = 0
        map.collisionMaps.roomwalls[endY][endX] = 0
        --First, find the path:
        local path = pathfinders[map].roomwalls:getPath(startX,startY,endX,endY,false)
        if not path then
          map.collisionMaps.roomwalls[startY][startX] = 1
          map.collisionMaps.roomwalls[endY][endX] = 1
        else
          usingOldPartnerDoor=true
          partnerDirChosen = partnerWall
          break
        end
      end
      if not partnerDirChosen then
        partner.dirWalls[partnerWall] = shuffle(partner.dirWalls[partnerWall])
        for _,endWall in ipairs(partner.dirWalls[partnerWall]) do
          if ((endWall.x ~= partner.minX and endWall.x ~= partner.maxX) or (endWall.y ~= partner.minY and endWall.y ~= partner.maxY)) and map:isWall(endWall.x,endWall.y) then
            local wallCardinals = {n=map:isWall(endWall.x,endWall.y-1),s=map:isWall(endWall.x,endWall.y+1),w=map:isWall(endWall.x-1,endWall.y),e=map:isWall(endWall.x+1,endWall.y)}
          local openCardinals = {n=map:isClear(endWall.x,endWall.y-1),s=map:isClear(endWall.x,endWall.y+1),w=map:isClear(endWall.x-1,endWall.y),e=map:isClear(endWall.x+1,endWall.y)}
          if (wallCardinals.n and wallCardinals.s and (openCardinals.e or openCardinals.w)) or (wallCardinals.e and wallCardinals.w and (openCardinals.n or openCardinals.s)) then
              endX,endY = endWall.x,endWall.y
              partnerDirChosen = partnerWall
              break
            end
          end --end wall-not-on-corner check
        end --end endWall for
      end --end if not partnerDirChosen
      if partnerDirChosen then break end
    end --end direction for
  end
  if not partnerDirChosen then
    --print('no partnerDirChoesn')
    return false
  end
  --[[I don't think this is needed anymore, we can just start on the wall itself
  if (roomWall == "n" or roomWall == "s") then
    startY = (roomWall == "n" and startY-1 or startY+1)
  elseif (roomWall =="e" or roomWall == "w") then
    startX = (roomWall == "w" and startX-1 or startX+1)
  end
  if (partnerWall == "n" or partnerWall == "s") then
    endY = (partnerWall == "n" and endY-1 or endY+1)
  elseif (partnerWall =="e" or partnerWall == "w") then
    endX = (partnerWall == "w" and endX-1 or endX+1)
  end--]]
  --Path, avoiding empty space
  map.collisionMaps.roomwalls[startY][startX] = 0
  map.collisionMaps.roomwalls[endY][endX] = 0
  --First, find the path:
  local path = pathfinders[map].roomwalls:getPath(startX,startY,endX,endY,false)
  if not path then
    map.collisionMaps.roomwalls[startY][startX] = 1
    map.collisionMaps.roomwalls[endY][endX] = 1
    return false
  end
  --Set connection info and create hallway definition:
  local wideHall = (random(1,100) <= wideChance and true or false)
  local hallway = {floors={},connections={}}
  hallway.connections[self]=true
  hallway.connections[partner]=true
  self.connections[partner] = true
  self.connections[hallway] = true
  partner.connections[self] = true
  partner.connections[hallway] = true
  if not usingOldRoomDoor then
    if random(1,100) <= doorChance and not map:tile_has_tag(startX,startY,'door')  then
      map:clear_tile(startX,startY)
      map:add_feature(Feature(doorFeature),startX,startY)
    end
    self.doors[#self.doors+1] = {x=startX,y=startY,hallway=hallway}
    self.dirDoors[roomDirChosen][#self.dirDoors[roomDirChosen]+1] = {x=startX,y=startY,hallway=hallway}
    --Set tiles around the door non-blockable
    for x=startX-1,startX+1,1 do
      for y=startY-1,startY+1,1 do
        if x == startX or y == startY then
          map.tile_info[x][y].noBlock = true
        end
      end
    end
  end
  --print('pathing from',startX,startY,roomDirChosen,'to',endX,endY,partnerDirChosen)
  --Dig the hallway itself:
  local completed = false
  for stepNum,node in pairs(path) do
    if (node.x and node.y) then
      map[node.x][node.y] = "."
      table.insert(hallway.floors,{x=node.x,y=node.y})
      --If we connect to a hallway, set ourselves as a connected hallway to that hallway
      local currHall = map.tile_info[node.x][node.y].hallway
      if currHall and currHall ~= hallway then
        currHall.connections[self] = true
        self.connections[currHall] = true
        if currHall.connections[partner] then --if this hallway already goes to our partner, then stop digging
          hallway.stopped_due_to_hallway = currHall
          break
        end
      else
        map.tile_info[node.x][node.y].hallway = hallway
      end
      for x=node.x-1,node.x+1,1 do
        for y=node.y-1,node.y+1,1 do
          if x>1 and y>1 and x<map.width and y<map.height then
            --If we connect to a hallway, set ourselves as a connected hallway to that hallway
            local currHall = map.tile_info[x][y].hallway
            if currHall and currHall ~= hallway then
              currHall.connections[self] = true
              if currHall.connections[partner] then --if this hallway already goes to our partner, then stop digging
                hallway.stopped_due_to_hallway = currHall
                break
              end
            end
            if wideHall then
              local makeIt = true
              for _, room in pairs(map.rooms) do
                if (x>=room.minX and x<=room.maxX) and (y>=room.minY and y<=room.maxY) then
                  makeIt = false
                  break
                end --end wall check if
              end --end room for
              if (makeIt) then
                map[x][y] = "."
                table.insert(hallway.floors,{x=x,y=y})
                if not currHall then
                  map.tile_info[x][y].hallway = hallway
                end
              end --end makeIt if
            end --end widehall if
          end --end x/y check
        end --end fory
      end --end forx
      if hallway.stopped_due_to_hallway then
        break
      end
    end --end node if
    if stepNum == #path then
      completed = true
    end
  end --end path for
  --Add the hallway to the map's list of hallways
  map.hallways[#map.hallways+1] = hallway
  --Add doors
  if completed then --If the full path was dug, mark the end as a door (if the hallway stopped halfway, it means another entrance was already found with a door already marked)
    if not usingOldPartnerDoor then
      if random(1,100) <= doorChance and not map:tile_has_tag(endX,endY,'door') then
        map:clear_tile(endX,endY)
        map:add_feature(Feature(doorFeature),endX,endY)
      end
      partner.doors[#partner.doors+1] = {x=endX,y=endY,hallway=hallway}
      partner.dirDoors[partnerDirChosen][#partner.dirDoors[partnerDirChosen]+1] = {x=startX,y=startY,hallway=hallway}
      for x=endX-1,endX+1,1 do
        for y=endY-1,endY+1,1 do
          if x == endX or y == endY then
            map.tile_info[x][y].noBlock = true
          end
        end
      end
    end
  end
  --[[Not sure what this was for
  if startX>2 and map[startX-2][startY] == "." then map[startX-1][startY] = "." end
  if startX<map.width-2 and map[startX+2][startY] == "." then map[startX+1][startY] = "." end
  if startY>2 and map[startX][startY-2] == "." then map[startX][startY-1] = "." end
  if startY<map.height-2 and map[startX][startY+2] == "." then map[startX][startY+1] = "." end
  if endX>2 and map[endX-2][endY] == "." then map[endX-1][endY] = "." end
  if endX<map.width-2 and map[endX+2][endY] == "." then map[endX+1][endY] = "." end
  if endY>2 and map[endX][endY-2] == "." then map[endX][endY-1] = "." end
  if endY<map.height-2 and map[endX][endY+2] == "." then map[endX][endY+1] = "." end]]
  return true
end

---Checks the callbacks of the room
--@param callback_type String. The callback type to check.
--@param … Anything. Any info you want to pass to the callback. Each callback type is probably looking for something specific (optional)
--@return Boolean. If any of the callbacks returned true or false.
--@return Table. Any other information that the callbacks might return.
function Room:callbacks(callback_type,...)
  if not self.decorator or self.disabled then
    return false
  end
  local ret = nil
  if type(roomDecorators[self.decorator][callback_type]) == "function" then
    local status,r,other = pcall(roomDecorators[self.decorator][callback_type],self,unpack({...}))
    if status == false then
        output:out("Error in room " .. self.decorator .. " callback \"" .. callback_type .. "\": " .. r)
        print("Error in room " .. self.decorator .. " callback \"" .. callback_type .. "\": " .. r)
      end
		if (r == false) then return false,other end
    ret = other
  end
  return true,ret
end