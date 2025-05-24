---@classmod Map
Map = Class{}

---Initiates a map. Don't call this explicitly, it's called when you create a new map with Map(50,50).
--@param width Number. The width of the map
--@param height Number. The height of the map
--@param gridOnly Boolean. If set to true, then extra tables (eg creatures, lights, pathfinders) will not be created for the map (optional)
--@return Map. The map itself.
function Map:init(width,height,gridOnly)
  if not gridOnly then
    self.creatures, self.contents, self.effects, self.projectiles, self.seenMap, self.lightMap, self.lights, self.pathfinders, self.grids, self.collisionMaps, self.exits, self.tile_info = {},{},{},{},{},{},{},{},{},{},{},{}
    self.sightblock_cache, self.creature_cache, self.feature_cache, self.effect_cache = {},{},{},{}
    pathfinders[self] = {}
    grids[self] = {}
    self.boss=nil
    self.stairsUp,self.stairsDown = {x=0,y=0},{x=0,y=0}
    self.creature_spawn_points, self.item_spawn_points = {},{}
    self.rooms,self.hallways = {},{}
    self.bonuses = {}
  end
  self.width,self.height=width,height
	for x = 1, width, 1 do
		self[x] = {}
    if not gridOnly then
      self.contents[x] = {}
      self.seenMap[x] = {}
      self.lightMap[x] = {}
      self.tile_info[x] = {}
    end
		for y = 1, height, 1 do
      if not gridOnly then
        self.seenMap[x][y] = false
        self.contents[x][y] = {}
        self.lightMap[x][y] = false
        self.tile_info[x][y] = {}
      end
			self[x][y] = "#"
		end
	end
  self.baseType = "map"
  return self
end

---Completely clear everything from a map.
--@param open Boolean. If True, make the whole map open floor. Otherwise, fill it with walls. Optional
--@param clearAll Boolean. If True, also clear out the various sub-tables of the map
function Map:clear(open,clearAll)
  for x = 1, self.width, 1 do
		for y = 1, self.height, 1 do
			self.seenMap[x][y] = false
			self:clear_tile(x,y)
      if open then
        self[x][y] = "."
      else
        self[x][y] = "#"
      end
		end
	end
  if clearAll then
    self.creatures,self.contents,self.effects,self.projectiles,self.seenMap,self.lightMap,self.lights,self.pathfinders,self.grids,self.collisionMaps,self.exits={},{},{},{},{},{},{},{},{},{},{}
    self.boss=nil
    self.stairsUp,self.stairsDown = {x=0,y=0},{x=0,y=0}
    for x = 1, self.width, 1 do
      self.contents[x] = {}
      self.seenMap[x] = {}
      self.lightMap[x] = {}
      for y = 1, self.height, 1 do
        self.seenMap[x][y] = false
        self.contents[x][y] = {}
        self.lightMap[x][y] = false
      end
    end
  end
end

---Checks whether a map tile is clear
--@param x Number. The x-coordinate to check
--@param y Number. The y-coordinate to check
--@param ctype String. The creature type to use when checking if the tile is passable (optional)
--@param ignoreCreats Boolean. Whether to ignore creatures when considering a tile clear (optional)
--@param ignore_safety Boolean. Whether to ignore dangerous but transversable features (optional)
--@param projectile Boolean. Whether to consider the tile free for a projectile vs a creature.
--@param ignoreAttackableFeatures Boolean. Whether to ignore attackable features when considering a tile clear (optional)
--@return Boolean. Whether the tile is clear
function Map:isClear(x,y,ctype,ignoreCreats,ignore_safety,projectile,ignoreAttackableFeatures)
  if x < 2 or y < 2 or x >= self.width or y >= self.height then return false end
	if self:isWall(x,y) then return false end --if there's a wall there, it's not clear
  if ignoreCreats ~= true and self:get_tile_creature(x,y) then return false end --if there's a creature there, it's not clear
  if ctype ~= nil then return self:is_passable_for(x,y,ctype,false,ignore_safety,projectile,ignoreAttackableFeatures) end --if you're asking about a specific creature type, pass it off
  --Otherwise, generic:
  if type(self[x][y]) == "table" and ((self[x][y].blocksMovement == true or self[x][y].impassable == true) and not (ignoreAttackableFeatures and self[x][y].attackable)) then return false end --if the square is a special tile and said tile is generally impassable, it's not clear
	for id, entity in pairs(self.contents[x][y]) do
		if (entity.blocksMovement == true or entity.impassable == true) and not (ignoreAttackableFeatures and entity.attackable) then
			return false
		end
	end
	return true
end

---Checks whether a map tile is totally empty (not just open for movement)
--@param x Number. The x-coordinate to check
--@param y Number. The y-coordinate to check
--@param ignoreCreats Boolean. Whether to ignore creatures when considering a tile empty (optional)
--@param lookAtBaseTile Boolean. Whether to count the base tile being a feature as "not empty" (optional)
--@return Boolean. Whether the tile is clear
function Map:isEmpty(x,y,ignoreCreats,lookAtBaseTile)
  if x < 2 or y < 2 or x >= self.width or y >= self.height then return false end
	if self:isWall(x,y) then return false end --if there's a wall there, it's not clear
  if lookAtBaseTile == true and type(self[x][y]) == "table" then return false end
  if ignoreCreats ~= true and self:get_tile_creature(x,y) then return false end --if there's a creature there, it's not clear
	for id, entity in pairs(self.contents[x][y]) do
		if entity.baseType == "feature" and not entity.noDisp then
			return false
		end
	end
	return true
end


---Determines if a tile is a wall
--@param x Number. The x-coordinate to check
--@param y Number. The y-coordinate to check
--@return boolean. Whether or not it is a wall tile
function Map:isWall(x,y)
  if not self:in_map(x,y) then return false end
  if self[x][y] == "#" then return true end
  if type(self[x][y]) == "table" and self[x][y].wall == true then return true end
  for _,f in pairs(self:get_contents(x,y)) do
    if f.wall then return true end
  end
  return false
end

---Determines if a tile's base is a floor. Does NOT check if the space is actually open
--@param x Number. The x-coordinate to check
--@param y Number. The y-coordinate to check
--@return boolean. Whether or not it is a floor tile
function Map:isFloor(x,y)
  if not self:in_map(x,y) then return false end
  if self[x][y] == "." then return true end
  if type(self[x][y]) == "table" and self[x][y].floor == true then return true end
  for _,f in pairs(self:get_contents(x,y)) do
    if f.floor then return true end
  end
  return false
end

---Checks if the tile_info of a tile has a certain tag set, or if any of the features in that tile have that tag set
--@param x Number. The x-coordinate to check
--@param y Number. The y-coordinate to check
--@param tag String. The tag to look for
--@return boolean. Whether or not it has the tag
--@return Feature. The feature that has the tag, if applicable
function Map:tile_has_tag(x,y,tag)
  if not self:in_map(x,y) then return false end
  if self.tile_info[x][y][tag] then return true end
  if type(self[x][y]) == "table" and self[x][y][tag] or (self[x][y].tags and in_table(tag,self[x][y].tags)) then
    return true,self[x][y]
  end
  for _,f in pairs(self:get_contents(x,y)) do
    if f[tag] or (f.tags and in_table(tag,f.tags)) then
      return true,f
    end
  end
end

---Gets contents of a map tile
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Table. A table of all the contents of the tile
function Map:get_contents(x,y)
  if self:in_map(x,y) then
    return self.contents[x][y]
  else
    return {}
  end
end

---Run the terrain can_enter() callbacks for the creature's location
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param creature Creature. The creature entering the tile
--@param fromX Number. The x-coordinate the creature is leaving (optional)
--@param fromY Number. The y-coordinate the creature is leaving (optional)
--@return Boolean. Whether or not the tile can be entered
function Map:can_enter(x,y,creature,fromX,fromY)
  local canEnter = true
  for id, entity in pairs(self:get_tile_features(x,y)) do --make sure you can enter the features at the new tile
    if (entity:can_enter(creature,fromX,fromY) == false) then canEnter = false break end
  end -- end feature for
  return canEnter
end

---Run the terrain enter() callbacks for the creature's location
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param creature Creature. The creature entering the tile
--@param fromX Number. The x-coordinate the creature is leaving (optional)
--@param fromY Number. The y-coordinate the creature is leaving (optional)
--@return Boolean. Whether or not the tile can be entered
function Map:enter(x,y,creature,fromX,fromY)
  local canEnter = true
  for id, entity in pairs(self:get_tile_features(x,y)) do
    entity:enter(creature,fromX,fromY)
  end -- end feature for
end

---Determines if a given tile blocks vision
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param args Unused for now, leave blank.
--@return Boolean. Whether or not the tile blocks vision
function Map:can_see_through(x,y,args)
  if self.sightblock_cache[x .. ',' .. y] ~= nil then return self.sightblock_cache[x .. ',' .. y] end
	if (not self:in_map(x,y) or self[x][y] == "#") then
    self.sightblock_cache[x .. ',' .. y] = false 
		return false
	end
  if type(self[x][y]) == "table" and self[x][y].blocksSight then
    self.sightblock_cache[x .. ',' .. y] = false
    return false
  end
  for id,entity in pairs(self.contents[x][y]) do
    if entity.blocksSight == true then
      self.sightblock_cache[x .. ',' .. y] = false
      return false
    end
    --if args.reducedSight and entity.sightReduction then args.reducedSight = args.reducedSight-entity.sightReduction end
  end --end for loop
  for _,eff in pairs(self:get_tile_effects(x,y)) do
    self.sightblock_cache[x .. ',' .. y] = false
    if eff.blocksSight == true then
      return false
    end
    --if args.reducedSight and eff.sightReduction then reducedSight = args.reducedSight-eff.sightReduction end
  end --end effect loop
  --if args.reducedSight and args.reducedSight <= 0 then return false end
  self.sightblock_cache[x .. ',' .. y] = true
	return true
end

---Gets what creature (if any) is on a tile
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param get_attackable_features Boolean. Whether to include attackable features (optional, defaults to false)
--@param ignoreNoDraw Boolean. Whether creatures that have noDraw set will be included (optional, defaults to false)
--@return Entity or Boolean. Will be FALSE if there's nothing there.
function Map:get_tile_creature(x,y,get_attackable_features,ignoreNoDraw)
  if not self:in_map(x,y) then return false end
  if not get_attackable_features and self.creature_cache[x .. ',' .. y] ~= nil then return self.creature_cache[x .. ',' .. y] end
	if (next(self.contents) == nil) then
    self.creature_cache[x .. ',' .. y] = false
		return false
	else
    local tileFeat = false
    if get_attackable_features and type(self[x][y]) == "table" and self[x][y].baseType == "feature" and (self[x][y].attackable == true or self[x][y].pushable == true) then
      tileFeat = self[x][y]
    end
		for id, entity in pairs(self.contents[x][y]) do
      if entity.x ~= x or entity.y ~= y or entity.isDead or (entity.hp and entity.hp < 0) then
        self.contents[x][y][entity] = nil
      elseif entity.baseType == "creature" and (ignoreNoDraw or entity.noDraw ~= true) then
        self.creature_cache[x .. ',' .. y] = entity
        return entity --immediately return the first creature you find
      elseif (get_attackable_features == true and entity.baseType == "feature" and (entity.attackable == true or entity.pushable == true)) then
				tileFeat = entity --don't immediately return a feature, because a creature may be standing on it
			end
		end
    if tileFeat then
      return tileFeat
    end
	end
  self.creature_cache[x .. ',' .. y] = false
	return false
end

---Gets a list of all features (if any) on a tile.
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return A table of features (may be empty)
function Map:get_tile_features(x,y)
  if not self:in_map(x,y) then return {} end
  if self.feature_cache[x .. "," .. y] then return self.feature_cache[x .. "," .. y] end
  
  local features = {}
  if type(self[x][y]) == "table" then features[1] = self[x][y] end
	for id, entity in pairs(self.contents[x][y]) do
		if (entity and entity.baseType == "feature") then
			features[#features+1] = entity
		end --end if
	end --end entity for
  self.feature_cache[x .. ',' .. y] = features
	return features
end

---Check if a tile has a specific feature
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param id String. The ID of the feature to check for.
--@return Boolean. Whether or not the tile has this feature
function Map:tile_has_feature(x,y,id)
  if not self:in_map(x,y) then return false end
  if type(self[x][y]) == "table" and self[x][y].id == id then return self[x][y] end
  for _,entity in pairs(self:get_tile_features(x,y)) do
    if entity.id == id then return entity end
  end
  return false
end --end function

---Returns the first feature that blocks movement
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Boolean. Whether or not the tile has this feature
function Map:get_blocking_feature(x,y)
  if x<2 or y<2 or x>self.width-1 or y>self.height-1 then return false end
  if type(self[x][y]) == "table" and self[x][y].id == id and self[x][y].blocksMovement then return self[x][y] end
  for _,entity in pairs(self:get_tile_features(x,y)) do
    if entity.blocksMovement then return entity end
  end
  return false
end --end function

---Gets a list of all items (if any) on a tile.
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param getAdjacent Boolean. Whether to also look at adjacent tiles (optional, defaults to false)
--@param ignoreContainers Boolean. Whether to ignore containers
--@return A table of items (may be empty)
function Map:get_tile_items(x,y,getAdjacent,ignoreContainers)
  if not self:in_map(x,y) then return {} end
  
  local items = {}
	for id, entity in pairs(self.contents[x][y]) do
		if (entity and entity.baseType == "item") then
			items[#items+1] = entity
    elseif entity and entity.baseType == "feature" and entity.inventory and not entity.inventory_inaccessible then
      for _,item in pairs(entity.inventory) do
        items[#items+1] = item
      end
		end --end if
	end --end entity for
  if getAdjacent then
    for x2=x-1,x+1,1 do
      for y2=y-1,y+1,1 do
        if (x ~= x2 or y ~= y2) and self:in_map(x2,y2) then
          for id, entity in pairs(self.contents[x2][y2]) do
            if (entity and entity.baseType == "item") then
              items[#items+1] = entity
            elseif entity and entity.baseType == "feature" and entity.inventory and not entity.inventory_inaccessible then
              for _,item in pairs(entity.inventory) do
                items[#items+1] = item
              end
            end --end if
          end --end entity for
        end --end no-double-dipping if
      end --end yfor
    end --end xfor
  end --end if get_adjacent
	return items
end

---Check if a tile has an item on it
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param id String. The ID of the item to check for.
--@return Item or false. The item, if it has it, otherwise false
function Map:tile_has_item(x,y,id,ignoreContainers)
  if not self:in_map(x,y) then return false end
  for _,eff in pairs(self:get_tile_items(x,y,false,ignoreContainers)) do
    if eff.id == id then return eff end
  end
  return false
end --end function

---Gets a list of all feature actions (if any) available at and around a tile.
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param user Creature. The user looking for actions. Optional, defaults to player
--@param noAdjacent Boolean. Whether to count adjacent tiles. Optional, defaults to false (ie adjacent tiles are counted)
--@param noCreature Boolean. If true, creature actions (such as speaking) don't count
--@return A table of items (may be empty)
function Map:get_tile_actions(x,y,user,noAdjacent,noCreature)
  if not self:in_map(x,y) then return {} end
  user = player or user
  
  local actions = {}
  if noAdjacent then
    for id, entity in pairs(self:get_tile_features(x,y)) do
      if entity.actions then
        for id,act in pairs(entity.actions) do
          local req = entity:action_requires(user,id)
          if req ~= false or act.show_when_disabled then
            actions[#actions+1] = {id=id,entity=entity,text=act.text,description=act.description,order=act.order,image=act.image,image_color=act.image_color,noDirection=act.noDirection,click_defaults_to_move=act.click_defaults_to_move,disabled = not req}
          end --end requires if
        end --end action for
      end --end if
    end --end entity for
    if not noCreature then
      local creat = self:get_tile_creature(x,y)
      if creat and creat ~= user then
        local dialogID = creat:get_dialog(user)
        if dialogID then
          local name = creat:get_name()
          actions[#actions+1] = {id='speak_' .. name, entity=creat, text="Talk to " .. name,dialogID = dialogID}
        end --end if dialogID
      end --end if creat
    end
  else
    for x2=x-1,x+1,1 do
      for y2=y-1,y+1,1 do
        for id, entity in pairs(self:get_tile_features(x2,y2)) do
          if entity.actions then
            for id,act in pairs(entity.actions) do
              local req = entity:action_requires(user,id)
              if (not act.noAdjacent or (x2 == x and y2 == y)) and (entity:action_requires(user,id) ~= false or act.show_when_disabled) then
                actions[#actions+1] = {id=id,entity=entity,text=act.text,description=act.description,order=act.order,image=act.image,image_color=act.image_color,noDirection=act.noDirection,click_defaults_to_move=act.click_defaults_to_move,disabled = not req}
              end --end requires if
            end --end action for
          end --end if
        end --end entity for
        if not noCreature then
          local creat = self:get_tile_creature(x2,y2)
          if creat and creat ~= user then
            local dialogID = creat:get_dialog(user)
            if dialogID then
              local name = creat:get_name()
              actions[#actions+1] = {id='speak_' .. name, entity=creat, text="Talk to " .. name,dialogID = dialogID}
            end --end if dialogID
          end --end if creat
        end
      end --end yfor
    end --end xfor
  end
	return actions
end

---Determines if you can draw a straight line between two tiles.
--@param startX Number. The x-coordinate of the first tile
--@param startY Number. The y-coordinate of the first tile
--@param endX Number. The x-coordinate of the second tile
--@param endY Number. The y-coordinate of the second tile
--@param pass_through_walls Boolean. Whether to ignore walls that block the line (optional)
--@param ctype String. The creature path type (eg flyer) (optional)
--@param ignoreCreats Boolean. Whether to ignore creatures that block the line (optional)
--@param ignoreSafety Boolean. Whether to ignore unsafe but transversable tiles that block the line (optional)
--@param ignoreAttackableFeatures Boolean. Whether to ignore attackable features when considering a tile clear (optional)
--@return Boolean. Whether or not you can draw the line.
function Map:is_line(startX,startY,endX,endY,pass_through_walls,ctype,ignoreCreats,ignoreSafety,projectile,ignoreAttackableFeatures)
  local bresenham = require 'lib.bresenham'
  if pass_through_walls then
    return bresenham.los(startX,startY,endX,endY, function() return true end)
  else
    return bresenham.los(startX,startY,endX,endY, function(map,x,y,ctype,ignoreCreats,ignoreSafety,projectile,ignoreAttackableFeatures) return self:isClear(x,y,ctype,ignoreCreats,ignoreSafety,projectile,ignoreAttackableFeatures) end,self,ctype,ignoreCreats,ignoreSafety,projectile,ignoreAttackableFeatures)
  end -- end pass through walls if
end

---Gets a line between two tiles, stopping when you encounter an obstacle.
--@param startX Number. The x-coordinate of the first tile
--@param startY Number. The y-coordinate of the first tile
--@param endX Number. The x-coordinate of the second tile
--@param endY Number. The y-coordinate of the second tile
--@param pass_through_walls Boolean. Ignore walls that block the line (optional)
--@param ctype String. The creature path type (eg flyer) (optional)
--@param ignoreCreats Boolean. Ignore creatures that block the line (optional)
--@param ignoreSafety Boolean. Ignore unsafe but transversable tiles that block the line (optional)
--@param ignoreAttackableFeatures Boolean. Whether to ignore attackable features when considering a tile clear (optional)
--@return A table full of tile values.
function Map:get_line(startX,startY,endX,endY,pass_through_walls,ctype,ignoreCreats,ignoreSafety,projectile,ignoreAttackableFeatures)
  local bresenham = require 'lib.bresenham'
  if pass_through_walls then
    return bresenham.line(startX,startY,endX,endY, function() return true end)
  else
    return bresenham.line(startX,startY,endX,endY, function(map,x,y,ctype,ignoreCreats,ignoreSafety,projectile,ignoreAttackableFeatures) return self:isClear(x,y,ctype,ignoreCreats,ignoreSafety,projectile,ignoreAttackableFeatures) end,self,ctype,ignoreCreats,ignoreSafety,projectile,ignoreAttackableFeatures)
  end --end pass_through_walls if
end

---Gets all effects (if any) on a tile.
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return A table of effects(may be empty)
function Map:get_tile_effects(x,y)
  if self.effect_cache[x .. "," .. y] then return self.effect_cache[x .. "," .. y] end
  local effects = {}
	for id, effect in pairs(self.effects) do
		if (effect.x == x and effect.y == y) then
			effects[#effects+1] = effect
		end	
	end
  self.effect_cache[x .. "," .. y] = effects
	return effects
end

---Check if a tile has a specific effect on it
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param id String. The ID of the effect to check for.
--@return Boolean. Whether or not the tile has this effect
function Map:tile_has_effect(x,y,id)
  if not self:in_map(x,y) then return false end
  for _,eff in pairs(self:get_tile_effects(x,y)) do
    if eff.id == id then return eff end
  end
  return false
end --end function

---Add a creature to a tile
--@param creature Creature. A specific creature object, NOT its ID. Usually a new creature, called using Creature('creatureID')
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param ignoreFunc Boolean. Whether to ignore the creature's new() function (optional)
--@return Creature. The creature placed
function Map:add_creature(creature,x,y,ignoreFunc)
  if not creature or type(creature) ~= "table" or creature.baseType ~= "creature" then
    output:out("Error: Tried to add non-existent creature to map " .. self:get_name() .. ' at ' .. x .. ', ' .. y)
    print("Tried to add non-existent creature to map " .. self:get_name() .. ' at ' .. x .. ', ' .. y)
    return false
  end
	creature.x, creature.y = x,y
	self.contents[x][y][creature] = creature
	self.creatures[creature] = creature
  if not ignoreFunc and possibleMonsters[creature.id].placed then
    local status,r = pcall(possibleMonsters[creature.id].placed,creature,self)
    if status == false then
      output:out("Error in creature " .. creature.id .. " placed code: " .. r)
      print("Error in creature " .. creature.id .. " placed code: " .. r)
    end
  end
  if creature.castsLight then self.lights[creature] = creature end
  self.creature_cache[x .. "," .. y] = creature
  if not creature.origin_map then
    creature.origin_map = self.id
    creature.origin_branch = self.branch
    for _,item in pairs(creature:get_inventory()) do
      item.origin_map = self.id
      item.origin_branch = self.branch
    end
  end
  return creature
end

---Add a feature to a tile
--@param feature Feature. A specific feature object, NOT its ID. Usually a new feature, called using Feature('featureID')
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param args Anything. Arguments to pass to the feature's placed() code
--@return Feature. The feature added
function Map:add_feature(feature,x,y,args)
  if not feature or type(feature) ~= "table"  or feature.baseType ~= "feature" then
    output:out("Error: Tried to add non-existent feature to map " .. self:get_name() .. ' at ' .. x .. ', ' .. y)
    print("Tried to add non-existent feature to map " .. self:get_name() .. ' at ' .. x .. ', ' .. y)
    return false
  end
  if not x or not y or not self:in_map(x,y) then
    return false
  end
  if feature.one_per_tile and self:tile_has_feature(x,y,feature.id) then
    return false
  end
	self.contents[x][y][feature] = feature
  feature.x,feature.y = x,y
  self.feature_cache[x .. ',' .. y] = nil
  if possibleFeatures[feature.id].placed then
    local status,r = pcall(possibleFeatures[feature.id].placed,feature,self,args)
    if status == false then
      output:out("Error in feature " .. feature.id .. " placed code: " .. r)
      print("Error in feature " .. feature.id .. " placed code: " .. r)
    end
  end
  if feature.castsLight then self.lights[feature] = feature end
  if feature.item_spawn_point then
    self.item_spawn_points[#self.item_spawn_points+1] = feature
  end
  if feature.creature_spawn_point then
    self.creature_spawn_points[#self.creature_spawn_points+1] = feature
  end
  feature:refresh_image_name(self)
  return feature --return the feature so if it's created when this function is called, you can still access it
end

---Add an effect to a tile
--@param effect Effect. A specific effect object, NOT its ID. Usually a new effect, called using Effect('effectID')
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param args Anything. Arguments to pass to the feature's placed() code
--@return Effect. The effect added
function Map:add_effect(effect,x,y,args)
  if not effect or type(effect) ~= "table" or effect.baseType ~= "effect" then
    output:out("Error: Tried to add non-existent effect to map " .. self:get_name() .. ' at ' .. x .. ', ' .. y)
    print("Tried to add non-existent effect to map " .. self:get_name() .. ' at ' .. x .. ', ' .. y)
    return false
  end
  if effect.one_per_tile and self:tile_has_effect(x,y,effect.id) then
    local oldeffect = self:tile_has_effect(x,y,effect.id)
    if oldeffect and oldeffect ~= effect then
      if oldeffect.turns_remaining and effect.turns_remaining and effect.turns_remaining ~= -1 then
        effect.turns_remaining = (oldeffect.turns_remaining == -1 and -1 or math.max(effect.turns_remaining,oldeffect.turns_remaining))
      end
      if effect.damage or oldeffect.damage then effect.damage = math.max(effect.damage or 0,oldeffect.damage or 0) end
    end
    oldeffect:delete()
  end
  effect.x,effect.y = x,y
  self.effect_cache[x .. ',' .. y] = nil
  if effects[effect.id].placed then
    local status,r = pcall(effects[effect.id].placed,effect,self,args)
    if status == false then
      output:out("Error in effect " .. effect.id .. " placed code: " .. r)
      print("Error in effect " .. effect.id .. " placed code: " .. r)
    end
  end
	self.effects[effect] = effect
  if effect.castsLight then self.lights[effect] = effect end
  effect:refresh_image_name(self)
  return effect --return the effect so if it's created when this function is called, you can still access it
end

---Add an item to a tile
--@param item Item. A specific item object, NOT its ID. Usually a new item, called using Item('itemID')
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param ignoreFunc Boolean. Whether to ignore the item's new() function (optional)
function Map:add_item(item,x,y,ignoreFunc)
  if not item or type(item) ~= "table" or item.baseType ~= "item" then
    output:out("Error: Tried to add non-existent item to map " .. self:get_name() .. ' at ' .. x .. ', ' .. y)
    print("Tried to add non-existent item to map " .. self:get_name() .. ' at ' .. x .. ', ' .. y)
    return false
  end
	item.x, item.y = x,y
	self.contents[x][y][item] = item
  if not ignoreFunc and possibleItems[item.id].placed then
    local status,r = pcall(possibleItems[item.id].placed,item,self)
    if status == false then
      output:out("Error in item " .. item.id .. " placed code: " .. r)
      print("Error in item " .. item.id .. " placed code: " .. r)
    end
  end
  if item.castsLight then self.lights[item] = item end
  
  if not item.origin_map and not ignoreFunc then
    item.origin_map = self.id
    item.origin_branch = self.branch
  end
  
  --Check for stacking:
  if item.stacks then
    for _,groundItem in pairs(self.contents[x][y]) do
      if item ~= groundItem and groundItem.baseType == "item" and groundItem.id == item.id and (not item.sortBy or item[item.sortBy] == groundItem[item.sortBy]) and (not groundItem.max_stack or groundItem.amount < groundItem.max_stack) then
        local max_stack = item.max_stack
        local space_in_stack = (max_stack and max_stack - groundItem.amount or nil)
        if not max_stack or space_in_stack >= item.amount then
          groundItem.amount = groundItem.amount + item.amount
          self.contents[x][y][item] = nil
          self.lights[item] = nil
        else
          groundItem.amount = max_stack
          local new_stack_amt = item.amount - space_in_stack
          item.amount = new_stack_amt
          return self:add_item(item,x,y,ignoreFunc) --run this again, so it'll look at the next stack
        end
      end --end checking if they should stack
    end --end item for
  end --end if item.stacks
  return item
end

---Set a map tile to be a certain feature
--@param feature Feature or String. A specific feature object, NOT its ID. Usually a new feature, called using Feature('featureID'). OR text representing floor (.) or wall (#)
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Feature or String. The feature added, or the string the tile was turned into.
function Map:change_tile(feature,x,y,dontRefreshSight)
  if not feature or (type(feature) ~= "table" and type(feature) ~= "string") or (type(feature) == "table" and feature.baseType ~= "feature") then
    output:out("Error: Tried to replace tile with non-existent feature on map " .. self:get_name() .. ' at ' .. x .. ', ' .. y)
    print("Tried to replace tile with non-existent feature on map " .. self:get_name() .. ' at ' .. x .. ', ' .. y)
    return false
  end
  if feature.never_replace_floor then
    return self:add_feature(feature,x,y)
  end
	self[x][y] = feature
  if type(feature) == "table" then
    feature.x,feature.y = x,y
    if possibleFeatures[feature.id].placed then
      local status,r = pcall(possibleFeatures[feature.id].placed,feature,self)
      if status == false then
        output:out("Error in feature " .. feature.id .. " placed code: " .. r)
        print("Error in feature " .. feature.id .. " placed code: " .. r)
      end
    end
    if feature.castsLight then
      self.lights[feature] = feature
      self:refresh_lightMap()
    end
  end
  if not dontRefreshSight and self == currMap then refresh_player_sight() end
  return feature --return the feature so if it's created when tis function is called, you can still access it
end

---Find a path between two points
--@param fromX Number. The x-coordinate, tile 1
--@param fromY Number. The y-coordinate, tile 1
--@param toX Number. The x-coordinate, tile 2
--@param toY Number. The y-coordinate, tile 2
--@param cType String. The creature path type (eg flyer) (optional)
--@param terrainLimit String. Limit pathfinding to tiles with a specific feature ID (optional)
--@return A table of tile entries, or FALSE if there is no path.
function Map:findPath(fromX,fromY,toX,toY,cType,terrainLimit)
  if not pathfinders[self] then pathfinders[self] = {} end
  if not grids[self] then grids[self] = {} end
  local pathLabel = (cType or 'basic') .. (terrainLimit or "")
  local toFromLabel = pathLabel .. "," .. fromX .. "," .. fromY .. "-to-" .. toX .. "," .. toY
  if pathfinders[self][pathLabel] == nil then
    self:refresh_pathfinder(cType,terrainLimit)
  end
  if not path_cache[pathLabel] then path_cache[pathLabel] = {} end
  local path = path_cache[pathLabel][toFromLabel]
  if path ~= nil then
    return (type(path) == 'table' and copy_table(path) or path)
  end
	path = pathfinders[self][pathLabel]:getPath(fromX,fromY,toX,toY,true)
	if not path then
    if pathfinders[self][pathLabel .. "unsafe"] == nil then self:refresh_pathfinder(cType,terrainLimit,true) end
    path = pathfinders[self][pathLabel .. "unsafe"]:getPath(fromX,fromY,toX,toY,true)
	end
  if path then
    --Sanitize the path so it's just coordinates, making it safe to save:
    if #path > 1 then path:fill() end
    local p = {}
    for i,coords in ipairs(path) do
      p[i] = {x=coords.x,y=coords.y}
    end
    path_cache[pathLabel][toFromLabel] = p
		return p
  end
  path_cache[pathLabel][toFromLabel] = false
	return false
end

---Check if two tiles are touching
--@param fromX Number. The x-coordinate, tile 1
--@param fromY Number. The y-coordinate, tile 1
--@param toX Number. The x-coordinate, tile 2
--@param toY Number. The y-coordinate, tile 2
--@return Boolean. If the tiles are touching.
function Map:touching(fromX,fromY,toX,toY)
  if (math.abs(fromX-toX) <= 1 and math.abs(fromY-toY) <= 1) then
		return true
	end
	return false
end

---Swap the positions of two creatures.
--@param creature1 Creature. The first creature
--@param creature2 Creature. The second creature
function Map:swap(creature1,creature2)
	local orig1x,orig1y = creature1.x,creature1.y
	local orig2x,orig2y = creature2.x,creature2.y
	creature1.x,creature1.y,creature2.x,creature2.y = orig1x,orig1y,orig2x,orig2y
	currMap.contents[orig1x][orig1y][creature1] = nil
	currMap.contents[orig2x][orig2y][creature2] = nil
  currMap.creature_cache[orig1x .. "," .. orig1y] = nil
  currMap.creature_cache[orig2x .. "," .. orig2y] = nil
  creature1.can_move_cache[orig2x .. ',' .. orig2y] = nil
  creature2.can_move_cache[orig1x .. ',' .. orig1y] = nil
	creature1:moveTo(orig2x,orig2y)
	creature2:moveTo(orig1x,orig1y)
end

---Refresh a pathfinder on the map
--@param cType String. The creature path type (eg flyer). (optional) Special values:
--  "walls" paths through walls only
--  "alltiles" completely open
--  "roomwalls" avoids rooms and digs through walls
--@param terrainLimit String. If you want to limit the pathfinder to a specific feature ID (optional)
--@param ignoreSafety Boolean. Whether to ignore hazards (optional)
function Map:refresh_pathfinder(cType,terrainLimit,ignoreSafety)
  if not pathfinders[self] then pathfinders[self] = {} end
  if not grids[self] then grids[self] = {} end
  local mapLabel = (cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")
  path_cache[mapLabel] = {}
  if (self.collisionMaps[mapLabel] == nil) then self.collisionMaps[mapLabel] = {} end
	for y = 1, self.height, 1 do
    if (self.collisionMaps[mapLabel][y] == nil) then self.collisionMaps[mapLabel][y] = {} end
		for x = 1, self.width, 1 do
      self.collisionMaps[mapLabel][y][x] = 0
      if cType == "walls" then
        if x == 1 or x == self.width or y == 1 or y == self.width or not self:isWall(x,y) then
          self.collisionMaps[mapLabel][y][x] = 1
        end
      elseif cType == "roomwalls" then
        if x == 1 or x == self.width or y == 1 or y == self.width then
          self.collisionMaps[mapLabel][y][x] = 1
        elseif self.tile_info[x][y].room then
          self.collisionMaps[mapLabel][y][x] = 1
        end
      elseif cType ~= "alltiles" then
        if self:is_passable_for(x,y,cType,false,ignoreSafety) == false or (terrainLimit and not self:tile_has_feature(x,y,terrainLimit)) then self.collisionMaps[mapLabel][y][x] = 1 end
      end
		end
	end
  
  if grids[self][mapLabel] == nil or pathfinders[self][mapLabel] == nil then
    local Grid = require('lib.jumper.grid')
    grids[self][mapLabel] = Grid(self.collisionMaps[mapLabel])
    local Pathfinder = require 'lib.jumper.pathfinder'
    pathfinders[self][mapLabel] = Pathfinder(grids[self][mapLabel],'ASTAR',0)
  end
end

---Delete all the pathfinders from the map
function Map:clear_all_pathfinders()
  pathfinders[self] = {}
  self.collisionMaps = {}
  grids[self] = {}
  path_cache = {}
end

---Checks if a tile is passable for a certain creature
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param cType String. The creature path type (eg flyer) (optional)
--@param include_effects Boolean. Whether to include effects in the passable check (optional)
--@param ignore_safety Boolean. Whether to ignore dangerous but transversable tiles (optional)
--@param ignoreAttackableFeatures Boolean. Whether to ignore attackable features when considering a tile clear (optional)
--@return Boolean. If it's passable.
function Map:is_passable_for(x,y,ctype,include_effects,ignore_safety,projectile,ignoreAttackableFeatures)
  if not self:in_map(x,y) then return false end
  if type(self[x][y]) == "string" then
    if self[x][y] == "#" then return false end
  elseif type(self[x][y]) == "table" then
    local tile = self[x][y]
    if not (self[x][y].attackable and ignoreAttackableFeatures) then
      if tile.blocksMovement == true and (projectile == true or tile.pathThrough ~= true) then return false end
      if tile.impassable and (ctype == nil or tile.passableFor[ctype] ~= true) then return false end
    end
    if not ignore_safety and tile.hazard and tile.hazard > 1 and ((tile.hazardousFor == nil and (ctype == nil or tile.safeFor == nil or tile.safeFor[ctype] ~= true)) or (ctype ~= nil and tile.hazardousFor and tile.hazardousFor[ctype] == true)) then return false end
  end
  --Check Features:
  for _,feat in pairs(self:get_tile_features(x,y)) do
    if not (feat.attackable and ignoreAttackableFeatures) then
      if feat.blocksMovement == true and (projectile == true or feat.pathThrough ~= true) then return false end
      if feat.impassable and (ctype == nil or feat.passableFor[ctype] ~= true) then return false end
    end
    if not ignore_safety and feat.hazard and feat.hazard > 1 and ((feat.hazardousFor == nil and (ctype == nil or feat.safeFor == nil or feat.safeFor[ctype] ~= true)) or (ctype ~= nil and feat.hazardousFor ~= nil and feat.hazardousFor[ctype] == true)) then return false end
  end
  --Check effects:
  if include_effects then
    for _,eff in pairs(self:get_tile_effects(x,y)) do
      if not ignore_safety and eff.hazard and ((eff.hazardousFor == nil and (ctype == nil or eff.safeFor == nil or eff.safeFor[ctype] ~= true)) or (ctype ~= nil and eff.hazardousFor ~= nil and eff.hazardousFor[ctype] == true)) then return false end
    end --end effect for
  end --end include effects
  return true
end

---Gets the potential hazards on a tile
function Map:get_tile_hazards(x,y,ctype,include_effects)
  local hazards = {}
  if not self:in_map(x,y) then return hazards end
  if type(self[x][y]) == "table" then
    local tile = self[x][y]
    if tile.hazard and tile.hazard > 1 and ((tile.hazardousFor == nil and (ctype == nil or tile.safeFor == nil or tile.safeFor[ctype] ~= true)) or (ctype ~= nil and tile.hazardousFor and tile.hazardousFor[ctype] == true)) then hazards[#hazards+1] = tile end
  end
   --Check Features:
  for _,feat in pairs(self:get_tile_features(x,y)) do
    if feat.hazard and feat.hazard > 1 and ((feat.hazardousFor == nil and (ctype == nil or feat.safeFor == nil or feat.safeFor[ctype] ~= true)) or (ctype ~= nil and feat.hazardousFor ~= nil and feat.hazardousFor[ctype] == true)) then hazards[#hazards+1] = feat end
  end
  --Check effects:
  if include_effects then
    for _,eff in pairs(self:get_tile_effects(x,y)) do
      if eff.hazard and ((eff.hazardousFor == nil and (ctype == nil or eff.safeFor == nil or eff.safeFor[ctype] ~= true)) or (ctype ~= nil and eff.hazardousFor ~= nil and eff.hazardousFor[ctype] == true)) then hazards[#hazards+1] = eff end
    end --end effect for
  end --end include effects
  return hazards
end
--@return Table. A list of the hazards

---Refresh all the tile images on the map
function Map:refresh_images()
  self.images = {}
  for x=1,self.width,1 do
    self.images[x] = {}
    for y=1,self.height,1 do
      self:refresh_tile_image(x,y)
    end --end fory
  end -- end forx
end

---Refresh a specific tile's tile image
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param contentsOnly Boolean. If true, don't refresh the base tile image, just the contents
function Map:refresh_tile_image(x,y,contentsOnly)
  if not self[x] or not self[x][y] then return end
  if not self.images then return self:refresh_images() end
  local name = ""
  local directions = ""
  local tileset = tilesets[self.tileset]
  if not tileset then return false end
  if type(self[x][y]) == "table" then
      self[x][y]:refresh_image_name(self)
      name = "floor" .. (tileset.different_outside_floor and self.tile_info[x][y].outside and "_outside" or "")
  elseif not contentsOnly then
    if self[x][y] == "." then
      name = "floor" .. (tileset.different_outside_floor and self.tile_info[x][y].outside and "_outside" or "")
    elseif self[x][y] == "#" then
      if not self:isWall(x,y-1) then directions = directions .. "n" end
      if not self:isWall(x,y+1) then directions = directions .. "s" end
      if not self:isWall(x+1,y) then directions = directions .. "e" end
      if not self:isWall(x-1,y) then directions = directions .. "w" end
      if tileset.southOnly then
        if directions:find('s') then name = 'walls' else name = 'wall' end
      elseif tileset.tilemap then --if all wall tiles are in a single image (uses quads)
        name = "wall"
      else
        name = "wall" .. directions
      end
    end --end tile type check
    if (tileset[name .. '_tiles']) then
      if random(1,100) <= (tileset[name .. '_tile_chance'] or 25) then name = name .. random(1,tileset[name .. '_tiles'])
      else name = name .. 1 end
    end -- end tileset if
    --OK, now that we figured out what image to load, go ahead and load it:
    --if images[self.tileset .. name] and images[self.tileset .. name] ~= -1 then --if image is already loaded, set it
    if tileset.tilemap and name:find('wall') then
      self.images[x][y] = {image=self.tileset .. name,direction=(directions == "" and "middle" or directions)}
    else
      self.images[x][y] = self.tileset .. name
    end
  end
  for _, feat in pairs(self.contents[x][y]) do
    if feat.baseType == "feature" then feat:refresh_image_name() end
  end
  for _,eff in pairs(self:get_tile_effects(x,y)) do
    eff:refresh_image_name()
  end
end
  
---Checks if a tile is within the map boundaries
--@param x Number. The x-coordinate
--@param yNumber.  The y-coordinate
--@param exclude_borders Boolean. Whether or not to exclude the tiles on the border of the map 
function Map:in_map(x,y,exclude_borders)
  if not x or not y then return false end
  if not exclude_borders and x >= 1 and y >= 1 and x <= self.width and y <= self.height then
    return true
  elseif exclude_borders and x > 1 and y > 1 and x < self.width and y < self.height then
    return true
  end
  return false --if x or y = 1 or width and height
end

---Refresh the light map of the map. Called every turn.
--@param true/false clear. Whether to clear all the lights
function Map:refresh_lightMap(clear) --I have a feeling this is a HORRIBLE and inefficient function that will be a total asshole on resources (relatively speaking). No wonder realtime 3D lighting is so fucking slow
  
  --First, clear all the lights and assume everywhere is dark
  if clear and (not self.lit or self.lightMap[2][2] == false) then
    for x=1,currMap.width,1 do
      for y=1,currMap.height,1 do
        self.lightMap[x][y] = (self.lit and true or false)
      end
    end
  end

  for lid,light in pairs(self.lights) do
    if not light.castsLight then
      self.lights[lid] = nil
    else
      if light.possessor then
        light.x,light.y = light.possessor.x,light.possessor.y
      end
      self:refresh_light(light,clear)
    end
  end --end for effect
end

---Refresh the light map based on a light-emitting entity's light.
--@param light Entity. The light source to refresh
--@param forceRefresh Boolean. Whether to force the light to refresh its lit tiles
function Map:refresh_light(light,forceRefresh)
  --First, see if this light source's light tiles are already set:
  if light.lightTiles and count(light.lightTiles) > 0 and not forceRefresh then
    for _,lt in pairs(light.lightTiles) do
      self.lightMap[lt.x][lt.y] = light.lightColor or true
    end
    return
  end
  --If not, then refresh its light tiles:
  if light.x and light.y then
    if not light.lightTiles or forceRefresh then light.lightTiles = {} end
    local dist = light.lightDist or 0
    for lx = light.x-dist,light.x+dist,1 do
      for ly = light.y-dist,light.y+dist,1 do
        if self:in_map(lx,ly) and (not self.lightMap[lx][ly] or self.lightMap[lx][ly] == true) then
          local dist2tile = calc_distance(light.x,light.y,lx,ly)
          local bresenham = require 'lib.bresenham'
          if dist2tile <= dist and bresenham.los(light.x,light.y,lx,ly, self.can_see_through,self) and (self[lx][ly] ~= "#" or bresenham.los(light.x,light.y,player.x,player.y, self.can_see_through,self)) then --if it's close enough, and there's LOS, it's lit!
            self.lightMap[lx][ly] = light.lightColor or true
            light.lightTiles[#light.lightTiles+1] = {x=lx,y=ly}
          end -- end distance if
        end --end if not self.lightMap
      end --end fory
    end--end forx
  end
end

---Checks if a tile is lit.
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Boolean. If the tile is lit.
function Map:is_lit(x,y)
  return self:is_in_map(x,y) and self.lightMap[x][y]
end

---Delete everything from a tile
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
function Map:clear_tile(x,y)
  if self:in_map(x,y) then
    for _,content in pairs(self.contents[x][y]) do
      if content.baseType == "effect" or content.baseType == "feature" or content.baseType == "item" then
        content:delete(self)
      elseif content.baseType == "creature" then
        content:remove(self)
      end --end content switch
    end --end for
    self.contents[x][y] = {} --just make sure that it's totally clear
  end --end in map if
end

---Mark every tile on the map as "seen" (the whole map will be revealed, but won't see creatures and effects outside of LOS)
function Map:reveal()
  for x=1,self.width,1 do
    for y=1,self.height,1 do
      self.seenMap[x][y] = true
    end
  end
end

---Get a list of possible creatures to spawn on this map. Stores the list, so when this is called in the future it just returns the list.
--@param self Map. The map to check
--@param force Boolean. Whether to force recalculation of the creature list (otherwise will return the stored list if it's already been calculated)
--@param allowAll Boolean. If True, creatures with the specialOnly flag can still be chosen based on their tags/factions/types. If not, they won't be chosen (unless already listed specifically in the map/branch lists)
--@return Table or nil. Either a table of creature IDs, or nil if there are no possible creatures
function Map:get_creature_list(force,allowAll)
  if self.creature_list and not force then
    return self.creature_list
  end
  local whichMap = mapTypes[self.mapType]
  local branch = currWorld.branches[self.branch]
  local specialCreats = nil
  local cTypes = nil
  local cFactions = nil
  local cTags = self:get_content_tags('creature')
  local fTags = self:get_content_tags('forbidden')
  local rTags = self:get_content_tags('required')
  
  --Look at specific creatures first:
  if whichMap.creatures then
    if (whichMap.noBranchCreatures or whichMap.noBranchContent) or not branch.creatures then
      specialCreats = copy_table(whichMap.creatures)
    else
      specialCreats =  merge_tables(whichMap.creatures,branch.creatures)
    end
  elseif not whichMap.noBranchCreatures and not whichMap.noBranchContent and branch.creatures then --if the mapTypes doesn't have creatures, fall back to the branch's creatures
    specialCreats = copy_table(branch.creatures) --if branch doesn't have creatures, this will set it to nil and just use regular creatures
  end
  if not specialCreats then
    specialCreats = {}
  end
  
  --Look at creature types, factions and tags next:
  if whichMap.creatureTypes then
    if (whichMap.noBranchCreatures or whichMap.noBranchContent) or not branch.creatureTypes then
      cTypes = whichMap.creatureTypes
    else
      cTypes =  merge_tables(whichMap.creatureTypes,branch.creatureTypes)
    end
  elseif not whichMap.noBranchCreatures and not whichMap.noBranchContent then --if the mapTypes doesn't have creatureTypes, fall back to the branch's creatureTypes
    cTypes = branch.creatureTypes --if branch doesn't have creatureTypes, this will keep it as nil
  end
  if whichMap.creatureFactions then
    if (whichMap.noBranchCreatures or whichMap.noBranchContent) or not branch.creatureFactions then
      cFactions = whichMap.creatureFactions
    else
      cFactions =  merge_tables(whichMap.creatureFactions,branch.creatureFactions)
    end
  elseif not whichMap.noBranchCreatures and not whichMap.noBranchContent then --if the mapTypes doesn't have creatureFactions, fall back to the branch's creatureFactions
    cFactions = branch.creatureFactions --if branch doesn't have creatureFactions, this will keep it as nil
  end
  
  --Add the types and factions to the specialCreats list
  for cid,creat in pairs(possibleMonsters) do
    local done = false
    if not creat.neverSpawn then
      if cTypes then
        for _,cType in pairs(cTypes) do
          if (allowAll or not creat.specialOnly) and Creature.is_type(creat,cType,true) then
            done = true
            break
          end
          if done == true then break end
        end --end cType for
      end --end cType if
      if cFactions and not done then
        for _,cFac in pairs(cFactions) do
          if (allowAll or not creat.specialOnly) and Creature.is_faction_member(creat,cFac) then
            done = true
            break
          end
          if done == true then break end
        end --end cFac for
      end --end faction if
      if cTags and not done then
        for _,cTag in pairs(cTags) do
          if (allowAll or not creat.specialOnly) and Creature.has_tag(creat,cTag) then
            done = true
            break
          end
          if done == true then break end
        end --end cFac for
      end --end faction if
      --Check for required tags:
      if done and #rTags > 0 then
        for _,rTag in pairs(rTags) do
          if not Creature.has_tag(creat,rTag) then
            done = false
            break
          end
        end
      end
      --Check for forbidden tags:
      if done and #fTags > 0 then
        for _,fTag in pairs(fTags) do
          if Creature.has_tag(creat,fTag) then
            done = false
            break
          end --end has_tag if
        end --end ftag for
      end --end if #ftag
      --Check for creatures' own required tags:
      if done and creat.requiredMapTags then
        for _, rTag in ipairs(creat.requiredMapTags) do
          if not in_table(rTag,cTags) then
            done = false
            break
          end
        end
      end
      if done and creat.forbiddenMapTags then
        for _, fTag in ipairs(creat.forbiddenMapTags) do
          if in_table(fTag,cTags) then
            done = false
            break
          end
        end
      end
      if done then
        specialCreats[#specialCreats+1] = cid
      end
    end --end neverspawn if
  end
  self.creature_list = specialCreats
  return specialCreats
end

---Get a list of possible items to spawn on the given map
--@param self Map. The map to check
--@param force Boolean. Whether or not to forcibly re-calculate it, rather than returning the pre-calculated value
--@param allowAll Boolean. If True, creatures with the specialOnly flag can still be chosen based on their tags/factions/types. If not, they won't be chosen (unless already listed specifically in the map/branch lists)
--@return Table or nil. Either a table of item IDs, or nil if there are no possible items
function Map:get_item_list(force,allowAll)
  if self.item_list and not force then
    return self.item_list
  end
  local whichMap = mapTypes[self.mapType]
  local branch = currWorld.branches[self.branch]
  local specialItems = nil
  local iTags = self:get_content_tags('item')
  local fTags = self:get_content_tags('forbidden')
  local rTags = self:get_content_tags('required')
  
  --Look at specific items first:
  if whichMap.items then
    if (whichMap.noBranchItems or whichMap.noBranchContent) or not branch.items then
      specialItems = copy_table(whichMap.items)
    else
      specialItems =  merge_tables(whichMap.items,branch.items)
    end
  elseif not whichMap.noBranchItems and not whichMap.noBranchContent and branch.items then --if the mapTypes doesn't have creatures, fall back to the branch's items
    specialItems = copy_table(branch.items) --if branch doesn't have creatures, this will set it to nil and just use regular items
  end
  
  local tagged_items = mapgen:get_content_list_from_tags('item',iTags,{forbiddenTags=fTags,requiredTags=rTags})
  specialItems = merge_tables(specialItems,tagged_items)
  
  self.item_list = specialItems
  return specialItems
end

---Get a list of possible stores to spawn on the given map.
--@param self Map. The map to check
--@param force Boolean. Whether or not to forcibly re-calculate it, rather than returning the pre-calculated value 
--@return Table or nil. Either a table of faction IDs, or nil if there are no possible stores
function Map:get_store_list(force)
  if self.store_list and not force then
    return self.store_list
  end
  local store_list = nil
  local whichMap = mapTypes[self.mapType]
  local branch = currWorld.branches[self.branch]
  local sTags = self:get_content_tags('store')
  local fTags = self:get_content_tags('forbidden')
  local rTags = self:get_content_tags('required')
  
  --Look at specific stores first:
  if whichMap.stores then
    if (whichMap.noBranchStores or whichMap.noBranchContent) or not branch.stores then
      store_list = copy_table(whichMap.stores)
    else
      store_list =  merge_tables(whichMap.stores,branch.stores)
    end
  elseif not whichMap.noBranchStores and not whichMap.noBranchContent and branch.stores then --if the mapTypes doesn't have stores, fall back to the branch's stores
    store_list = copy_table(branch.stores) --if branch doesn't have stores, this will set it to nil and just use regular stores
  end
  
  --Add the tagged stores to the store list
  local tagged_stores = mapgen:get_content_list_from_tags('store',sTags,{forbiddenTags=fTags,requiredTags=rTags})
  store_list = merge_tables(store_list,tagged_stores)
  self.store_list = store_list
  return store_list
end

---Get a list of possible factions to spawn on the given map
--@param self Map. The map to check
--@param force Boolean. Whether or not to forcibly re-calculate it, rather than returning the pre-calculated value 
--@return Table or nil. Either a table of faction IDs, or nil if there are no possible factions
function Map:get_faction_list(force)
  if self.faction_list and not force then
    return self.faction_list
  end
  local whichMap = mapTypes[self.mapType]
  local branch = currWorld.branches[self.branch]
  local faction_list = nil
  local fTags = self:get_content_tags('faction')
  local forbiddenTags = self:get_content_tags('forbidden')
  local rTags = self:get_content_tags('required')
  
  --Look at specific factions first:
  if whichMap.factions then
    if (whichMap.noBranchFactions or whichMap.noBranchContent) or not branch.factions then
      faction_list = copy_table(whichMap.factions)
    else
      faction_list =  merge_tables(whichMap.factions,branch.factions)
    end
  elseif not whichMap.noBranchFactions and not whichMap.noBranchContent and branch.factions then --if the mapTypes doesn't have factions, fall back to the branch's factions
    faction_list = copy_table(branch.factions) --if branch doesn't have factions, this will set it to nil and just use regular factions
  end
  
  --Add the tagged factions to the faction list
  local tagged_factions = mapgen:get_content_list_from_tags('faction',fTags,{forbiddenTags=forbiddenTags,requiredTags=rTags})
  faction_list = merge_tables(faction_list,tagged_factions)
  self.faction_list = faction_list
  return faction_list
end

---Get a list of possible room decorators to spawn on the given map
--@param self Map. The map to check
--@param force Boolean. Whether or not to forcibly re-calculate it, rather than returning the pre-calculated value 
--@return Table or nil. Either a table of room decorator IDs, or nil if there are no possible rooms
function Map:get_room_list(force)
  if self.room_list and not force then
    return self.room_list
  end
  local whichMap = mapTypes[self.mapType]
  local branch = currWorld.branches[self.branch]
  local room_list = nil
  local roomTags = self:get_content_tags('room')
  local forbiddenTags = self:get_content_tags('forbidden')
  local reqTags = self:get_content_tags('required')
  
  --Look at specific rooms first:
  if whichMap.roomDecorators then
    if (whichMap.noBranchRooms or whichMap.noBranchContent) or not branch.roomDecorators then
      room_list = copy_table(whichMap.roomDecorators)
    else
      room_list =  merge_tables(whichMap.roomDecorators,branch.roomDecorators)
    end
  elseif not whichMap.noBranchRooms and not whichMap.noBranchContent and branch.roomDecorators then --if the mapTypes doesn't have rooms, fall back to the branch's rooms
    room_list = copy_table(branch.roomDecorators) --if branch doesn't have rooms, this will set it to nil and just use regular rooms
  end
  
  --Add the tagged rooms to the room list
  local tagged_rooms = mapgen:get_content_list_from_tags('roomDecorator',roomTags,{forbiddenTags=forbiddenTags,requiredTags=reqTags})
  room_list = merge_tables(room_list,tagged_rooms)
  self.room_list = room_list
  return room_list
end

---Randomly add creatures to the map
--@param creatTotal Number. The number of creatures to add. Optional, if blank will generate enough to meet the necessary density
--@param forceGeneric Boolean. Whether to ignore any special populate_creatures() code in the map's mapType. Optional
function Map:populate_creatures(creatTotal,forceGeneric)
  local mapTypeID,branchID = self.mapType,self.branch
  local mapType,branch = mapTypes[mapTypeID],currWorld.branches[branchID]
  
  --If creatTotal is blank, set creatTotal based on the desired density
  if not creatTotal then
    local density = mapType.creature_density or branch.creature_density or gamesettings.creature_density
    local creatMax = math.ceil((self.width*self.height)*(density/100))
    creatTotal = creatMax-count(self.creatures)
  end
  
  --Populate based on rooms:
  if self.rooms and not self.noCreatures then
    for roomID,room in ipairs(self.rooms) do
      local decID = room.decorator
      if decID then
        local dec = roomDecorators[decID]
        if dec and not dec.noContent and not dec.noCreatures then
          print('populating creatures in room',room.decorator)
          room:populate_creatures()
        end --end dec nocontent if
      end --end if room.decotrator
    end --end room for
  end --end if self.rooms
  print('rooms finished')
  
  --Do special code if the mapType has it:
  if mapType.populate_creatures and not forceGeneric then
    return mapType.populate_creatures(self,creatTotal)
  end
  
  local passedTags = nil
  if mapType.passedTags then
    if mapType.noBranchItems or mapType.noBranchContent or not branch.passedTags then
      passedTags = mapType.passedTags
    else
      passedTags =  merge_tables(mapType.passedTags,branch.passedTags)
    end
  else --if the mapType doesn't have passedTags, fall back to the branch's items
    passedTags = branch.passedTags --if branch doesn't have creatures, this will set it to nil and just use regular items
  end
  
  if not self.noCreatures and creatTotal > 0 then
    local newCreats = {}
    local specialCreats = self:get_creature_list()
    local min_level = self:get_min_level()
    local max_level = self:get_max_level()
		for creat_amt=1,creatTotal,1 do
      if creat_amt > creatTotal then break end --creatTotal is decreased when group spawning happens, but the for loop still tries to run to its original value, so we're checking here to make sure whether or not it should still be running
			local nc = mapgen:generate_creature(min_level,max_level,specialCreats,passedTags)
      if nc == false then break end
      local placed = false
      
      --Spawn in designated spawn points first:
      local creature_spawn_points = {}
      if self.creature_spawn_points and #self.creature_spawn_points > 0 then
        for i,sp in ipairs(self.creature_spawn_points) do
          if not sp.used and not sp.boss and not self:tile_has_tag(sp.x,sp.y,'door') and not self:tile_has_feature(sp.x,sp.y,'exit') and not self:get_tile_creature(sp.x,sp.y) and not self.tile_info[sp.x][sp.y].noCreatures then
            creature_spawn_points[#creature_spawn_points+1] = sp
          end
        end
      end
        
      local sptries = 0
      while (#creature_spawn_points > 0) and sptries < 100 do
        sptries = sptries + 1
        local spk = get_random_key(creature_spawn_points)
        local sp = creature_spawn_points[spk]
        if nc:can_move_to(sp.x,sp.y,self) then
          if random(1,4) == 1 then nc:give_condition('asleep',random(10,100)) end
          local creat = self:add_creature(nc,sp.x,sp.y)
          newCreats[#newCreats+1] = creat
          placed = creat
          sp.used = true
          table.remove(creature_spawn_points,spk)
          break
        end
      end
      
      --If not spawned at a spawn point, find a spot to spawn:
      if not placed then
        local cx,cy = random(2,self.width-1),random(2,self.height-1)
        local tries = 0
        while nc:can_move_to(cx,cy,self) == false or self:tile_has_tag(cx,cy,'door') or self:tile_has_feature(cx,cy,'exit') or not self:isClear(cx,cy,nc:get_pathType()) or self.tile_info[cx][cy].noCreatures do
          cx,cy = random(2,self.width-1),random(2,self.height-1)
          tries = tries+1
          if tries > 100 then break end
        end
        
        --Place the actual creature:
        if tries < 100 then 
          if random(1,4) == 1 then nc:give_condition('asleep',random(10,100)) end
          local creat = self:add_creature(nc,cx,cy)
          newCreats[#newCreats+1] = creat
          placed = creat
        end --end tries if
      end
      
      --Place group spawns:
      if placed and (nc.group_spawn or nc.group_spawn_max) then
        local spawn_amt = (nc.group_spawn or random((nc.group_spawn_min or 1),nc.group_spawn_max))
        if not nc.group_spawn_no_tweak then spawn_amt = tweak(spawn_amt) end
        if spawn_amt < 1 then spawn_amt = 1 end
        local x,y = placed.x,placed.y
        for i=1,spawn_amt,1 do
          local tries = 1
          local cx,cy = random(x-tries,x+tries),random(y-tries,y+tries)
          while nc:can_move_to(cx,cy,self) == false or self:tile_has_tag(cx,cy,'door') or self:tile_has_feature(cx,cy,'exit') or not self:isClear(cx,cy,nc:get_pathType()) or self.tile_info[cx][cy].noCreatures do
            cx,cy = random(x-tries,x+tries),random(y-tries,y+tries)
            tries = tries + 1
            if tries > 10 then break end
          end --end while
          if tries <= 10 then
            local creat = mapgen:generate_creature(min_level,max_level,{nc.id},passedTags)
            self:add_creature(creat,cx,cy)
            newCreats[#newCreats+1] = creat
            creatTotal = creatTotal-0.5 --a group spawned creature only counts as half a creature for the purposes of creature totals, so group spawns won't eat up all the creature slots but also won't overwhelm the map
          end
        end
      end
		end --end creature for
    return newCreats
	end --end if not noCreatures
  return false
end

---Randomly add items to the map
--@param itemTotal Number. The number of items to add. Optional, if blank will generate enough to meet the necessary density
--@param forceGeneric Boolean. Whether to ignore any special populate_items() code in the map's mapType. Optional
function Map:populate_items(itemTotal,forceGeneric)
  local mapTypeID,branchID = self.mapType,self.branch
  local mapType,branch = mapTypes[mapTypeID],currWorld.branches[branchID]
  local newItems = {}
  local min_level = self:get_min_level()
  local max_level = self:get_max_level()
  
  --If itemTotal is blank, set itemTotal based on the desired density
  if not itemTotal then
    local density = mapType.item_density or branch.item_density or gamesettings.item_density
    local itemMax = math.ceil((self.width*self.height)*(density/100))
    itemTotal = tweak(itemMax)
  end
  
  --Populate based on rooms:
  if self.rooms and not self.noItems then
    for roomID,room in pairs(self.rooms) do
      local decID = room.decorator
      if decID then
        local dec = roomDecorators[decID]
        if dec and not dec.noContent and not dec.noItems then
          room:populate_items()
        end --end dec nocontent if
      end --end if room.decotrator
    end --end room for
  end --end if self.rooms

  local passedTags = nil
  if mapType.passedTags then
    if mapType.noBranchItems or mapType.noBranchContent or not branch.passedTags then
      passedTags = mapType.passedTags
    else
      passedTags =  merge_tables(mapType.passedTags,branch.passedTags)
    end
  else --if the mapType doesn't have passedTags, fall back to the branch's items
    passedTags = branch.passedTags --if branch doesn't have creatures, this will set it to nil and just use regular items
  end
  local item_list = self:get_item_list()
  
  --Spawn in designated spawn points first:
  local item_spawn_points = {}
  if self.item_spawn_points and #self.item_spawn_points > 0 then
    for i,sp in ipairs(self.item_spawn_points) do
      if not sp.used and not self:tile_has_feature(sp.x,sp.y,'exit') and ((sp.inventory and #sp:get_inventory() < (sp.inventory_space or 1)) or (self:isClear(sp.x,sp.y,nil,true) and #self:get_tile_items(sp.x,sp.y) == 0 and not self.tile_info[sp.x][sp.y].noItems)) then
        item_spawn_points[#item_spawn_points+1] = sp
      end
    end
  end
  
  for spk,sp in pairs(item_spawn_points) do
    if sp.baseType == "feature" then
      sp:populate_items(self)
      sp.used=true
      goto continue
    end
    
    local sp_item_list = {}
    local sp_passedTags = merge_tables(passedTags,(sp.passedTags or {}))
    local artifact_chance = sp.artifact_chance or self.artifact_chance or self.artifact_chance or branch.artifact_chance or gamesettings.artifact_chance or 0
    local enchantment_chance = sp.enchantment_chance or self.enchantment_chance or self.enchantment_chance or branch.enchantment_chance or gamesettings.enchantment_chance or 0
    
    --Create item list:
    if sp.items then
      sp_item_list = sp.items or {}
    end --end if items
    if sp.itemTags or sp.contentTags or sp.forbiddenTags then
      local tags = sp.itemTags or sp.contentTags or dec.itemTags or dec.contentTags or {}
      local required = sp.requiredTags
      local forbidden = sp.forbiddenTags
      local tagged_items = mapgen:get_content_list_from_tags('item',tags,{forbiddenTags=forbidden,requiredTags=required})
      sp_item_list = merge_tables(sp_item_list,tagged_items)
    elseif not sp.items then --if there's no item list or tag list set, just use the item list of the room
      sp_item_list = item_list
    end
    
    ::gen_item::
    local ni = mapgen:generate_item(min_level,max_level,sp_item_list,sp_passedTags,nil,enchantment_chance,artifact_chance)
    newItems[#newItems+1] = ni
    ni.origin_map = self.id
    ni.origin_branch = self.branch
    
    if sp.inventory then
      sp:give_item(ni)
      sp:modify_generated_item(ni)
      if #sp:get_inventory() >= (sp.inventory_space or 1) then
        sp.used = true
      else
        goto gen_item
      end
    else
      self:add_item(ni,sp.x,sp.y)
      sp.used = true
    end
    ::continue::
  end
  
  --Do special code if the mapType has it:
  if mapType.populate_items and not forceGeneric then
    return mapType.populate_items(self,itemTotal,item_list,passedTags)
  end
  
  --Generate items on floor:
  if not self.noItems and itemTotal > 0 then
    local artifact_chance = self.artifact_chance or gamesettings.artifact_chance or 0
    local enchantment_chance = self.enchantment_chance or gamesettings.enchantment_chance or 0
    
    for item_amt = 1,itemTotal,1 do
      local ni = mapgen:generate_item(min_level,max_level,item_list,passedTags,nil,enchantment_chance,artifact_chance)
      if ni == false then break end
      
      local ix,iy = random(2,self.width-1),random(2,self.height-1)
      local tries = 0
      while self:isClear(ix,iy) == false or self:tile_has_feature(ix,iy,"exit") or self.tile_info[ix][iy].noItems or #self:get_tile_items(ix,iy) ~= 0 do
        ix,iy = random(2,self.width-1),random(2,self.height-1)
        tries = tries+1
        if tries > 100 then break end
      end
      if tries ~= 100 then 
        newItems[#newItems+1] = self:add_item(ni,ix,iy)
      end --end tries if
    end
    return newItems
	end --end if not noItems
  return false
end

---Randomly add a store to the map. This only adds one store to the map
--@param forceGeneric Boolean. Whether to ignore any special populate_stores() code in the map's mapType. Optional
function Map:populate_stores(forceGeneric)
  local mapTypeID,branchID = self.mapType,self.branch
  local mapType,branch = mapTypes[mapTypeID],currWorld.branches[branchID]
  
  --Do special code if the mapType has it:
  if mapType.populate_stores and not forceGeneric then
    return mapType.populate_stores(self)
  end
  
  if not self.noStores then
    local stores = self:get_store_list()
    local selected = nil
    if stores then
      stores = shuffle(stores)
      for _,storeID in ipairs(stores) do
        if not currWorld.stores[storeID].isPlaced or currWorld.stores[storeID].multiple_locations then
          selected = storeID
          break
        end
      end
    end
    if selected then
      --If necessary, spawn a copy of the store with its own ID
      local store = currWorld.stores[selected]
      if store.isPlaced and store.multiple_locations then
        local s = Store(store.id)
        s.multiple_locations=nil
        selected = s
      end
      local newStore = Feature('store',selected)
      local tries = 0
      local ix,iy = random(2,self.width-1),random(2,self.height-1)
      while self:isClear(ix,iy) == false or self:tile_has_feature(ix,iy,"exit") do
        ix,iy = random(2,self.width-1),random(2,self.height-1)
        tries = tries+1
        if tries > 100 then break end
      end
      if tries ~= 100 then 
        self:add_feature(newStore,ix,iy)
      end --end tries if
    end
  end
end

---Randomly add an appropriate faction to the map. This only adds one faction to the map, and only factions that haven't previously been placed 
--@param forceGeneric Boolean. Whether to ignore any special populate_factions() code in the map's mapType. Optional
function Map:populate_factions(forceGeneric)
  local mapTypeID,branchID = self.mapType,self.branch
  local mapType,branch = mapTypes[mapTypeID],currWorld.branches[branchID]
  
  --Do special code if the mapType has it:
  if mapType.populate_factions and not forceGeneric then
    return mapType.populate_factions(self)
  end
  
  if not self.noFactions then
    local facs = self:get_faction_list()
    local selected = nil
    if facs then
      facs = shuffle(facs)
      for _,factionID in ipairs(facs) do
        if not currWorld.factions[factionID].isPlaced or currWorld.factions[factionID].multiple_locations then
          selected = factionID
          break
        end
      end
    end
    if selected then
      local hq = Feature('factionHQ',selected)
      local tries = 0
      local ix,iy = random(2,self.width-1),random(2,self.height-1)
      while self:isClear(ix,iy) == false or self:tile_has_feature(ix,iy,"exit") do
        ix,iy = random(2,self.width-1),random(2,self.height-1)
        tries = tries+1
        if tries > 100 then break end
      end
      if tries ~= 100 then 
        self:add_feature(hq,ix,iy)
      end --end tries if
    end
  end
end

---Decorate rooms on the map
function Map:populate_rooms(forceGeneric)
  local mapTypeID,branchID = self.mapType,self.branch
  local mapType,branch = mapTypes[mapTypeID],currWorld.branches[branchID]
  
  --Do special code if the mapType has it:
  if mapType.populate_rooms and not forceGeneric then
    return mapType.populate_rooms(self)
  end
  if not self.rooms or self.noRooms then
    return
  end
  
  local room_count = #self.rooms
  local decorated_rooms = 0
  
  --First, decorate using required rooms
  if mapType.required_rooms or branch.required_rooms then
    local reqRooms = merge_tables((mapType.required_rooms or {}),(not mapType.noBranchCreatures and not mapType.noBranchContent and branch.required_rooms or {}))
    for _,decID in ipairs(reqRooms) do
      shuffle(self.rooms)
      for _,room in ipairs(self.rooms) do
        if not room.decorator and room:can_decorate(decID) then
          room:decorate(decID)
          decorated_rooms = decorated_rooms+1
          if not room.noSecondary then
            --TODO: secondary decorators
          end
          break
        end
      end
    end
  end
  
  --Next, decorate once for every room in the list, to avoid repeats
  local decorator_list = shuffle(self:get_room_list())
  for _,decID in ipairs(decorator_list) do
    shuffle(self.rooms)
    for _,room in ipairs(self.rooms) do
      if not room.decorator and room:can_decorate(decID) then
        room:decorate(decID)
        decorated_rooms = decorated_rooms+1
        if not room.noSecondary then
          --TODO: secondary decorators
        end
        break
      end
    end
  end
  
  --Finally, if we still have rooms that are undecorated, decorate them randomly
  if decorated_rooms < room_count then
    for _, room in ipairs(self.rooms) do
      if not room.decorator then
        room:decorate(decorator_list)
      end
      if not room.noSecondary then
        --TODO: secondary decorators
      end
    end
  end
end

---Connect rooms together TODO: support custom connection code
--@param info Table. Information to pass to the connector
function Map:connect_rooms(info)
  self:refresh_pathfinder('roomwalls')
  pathfinders[self].roomwalls:setMode('ORTHOGONAL')
  info = copy_table(info or {})
  info.connections = info.connections or 1
  local connections = info.connections
  for _,room in ipairs(self.rooms) do
    local force_hallway_connections = info.force_hallway_connections or self.force_hallway_connections
    local force_room_connections = info.force_room_connections or self.force_room_connections
    local force_outside_connections = info.force_outside_connections or self.force_outside_connections
    local force_any = force_hallway_connections or force_room_connections or force_outside_connections
    if not connections or count(room.doors) < connections or (force_any and count(room.doors) < 4) then
      room:connect(info)
    end
  end
  --Now connect rooms to nearby adjacent hallways:
  if not info.no_build_hallways then
    local nhInfo = copy_table(info)
    nhInfo.no_build_hallways = true
    for _,room in ipairs(self.rooms) do
      room:connect(nhInfo)
    end
  end
  --If there are still any disconneted rooms, run connect() on them again
  if not info.no_build_hallways then
    local tries = 0
    local disconnected = self:get_disconnected_rooms()
    while count(disconnected) > 0 and tries < 100 do
      tries = tries+1
      local room = get_random_key(disconnected)
      room:connect(info)
      disconnected = self:get_disconnected_rooms()
    end
    if tries == 100 then
      print('disconnection timeout')
    end
  end
  --If there are STILL any disconneted rooms, specifically connect them to connected rooms
  if not info.no_build_hallways then
    local tries = 0
    local disconnected = self:get_disconnected_rooms()
    local connected = self:get_connected_rooms()
    local fhInfo = copy_table(info)
    fhInfo.forceHallways = true
    fhInfo.no_build_hallways = false
    while count(disconnected) > 0 and tries < 100 do
      tries = tries+1
      local room = get_random_key(disconnected)
      local distances = room:get_distances()
      for _,distInfo in ipairs(distances) do
        local partner = distInfo.room
        if partner ~= self and not room.connections[partner] then
          if room:connect_to_room(partner,info) then
            print('connected',room.midX,room.midY,'to',partner.midX,partner.midY)
            break
          end
        end
      end
      disconnected = self:get_disconnected_rooms()
    end
    if tries == 100 then
      print('disconnection timeout')
    end
  end
  --Finally, if there are any rooms with only one door, connect them again
  for _,room in ipairs(self.rooms) do
    local force_hallway_connections = info.force_hallway_connections or self.force_hallway_connections
    local force_room_connections = info.force_room_connections or self.force_room_connections
    local force_outside_connections = info.force_outside_connections or self.force_outside_connections
    local force_any = force_hallway_connections or force_room_connections or force_outside_connections
    if count(room.doors) < 2 or (force_any and count(room.doors) < 4) then
      room:connect(info)
    end
  end
  info.forceHallways = false
  
  self.rooms_connected = true
end

---Returns a list of connected rooms
--@return Table. A list of rooms connected to the 1st room in the room list
function Map:get_connected_rooms()
  local connected = {}
  local checked = {}
  
  local function check_connection(room)
    for connection,_ in pairs(room.connections) do
      if connection.baseType == "room" then
        connected[connection] = true
      end
      if not checked[connection] then
        checked[connection] = true
        check_connection(connection)
      end
    end
  end
  
  check_connection(self.rooms[1]) --start with room one, and and check all of its connections
  return connected
end

---Returns a list of unconnected rooms
--@return Table. A list of rooms not connected to the 1st room in the room list
function Map:get_disconnected_rooms()
  local disconnected = {}
  local checked = {}
  
  local function check_connection(room)
    for connection,_ in pairs(room.connections) do
      disconnected[connection] = nil
      if not checked[connection] then
        checked[connection] = true
        check_connection(connection)
      end
    end
  end
  
  for _,room in ipairs(self.rooms) do
    disconnected[room] = true
  end
  check_connection(self.rooms[1]) --start with room one, and and check all of its connections
  return disconnected
end

---Cleans up the map, removing effects with temporary durations, and entities with remove_on_cleanup=true
function Map:cleanup()
  --Clean up content:
  for _,eff in pairs(self.effects) do
    if eff.remove_on_cleanup == true or eff.turns_remaining then
      if eff.turns_remaining then
        eff.turns_remaining = 1
        eff:advance()
      end
      eff:delete(self)
    else
      eff:cleanup(self)
    end
  end --end effect for
  for x=1,self.width,1 do
    for y=1,self.height,1 do
      local contents = self:get_contents(x,y)
      for _,content in pairs(contents) do
        if content.remove_on_cleanup or content.summoned or (content.baseType == "creature" and content:has_condition('summoned')) then
          if content.delete then content:delete(self)
          elseif content.remove then content:remove(self) end
        elseif content.baseType == "item" then
          content:cleanup(self)
          --TODO: item cleanup
        elseif content.baseType == "creature" then
          content:callbacks('cleanup',self)
          content:refresh()
        else --if not a creature, just run its custom cleanup code if it has any
          if content.cleanup then
            content:cleanup(self)
          end
        end --end remove if
      end --end content for
    end --end fory
  end --end forx
  --Clear spawn points:
  if self.creature_spawn_points then
    for _,sp in pairs(self.creature_spawn_points) do
      sp.used=nil
    end
  end
  if self.item_spawn_points then
    for _,sp in pairs(self.item_spawn_points) do
      sp.used=nil
    end
  end
  --Run custom cleanup code:
  if mapTypes[self.mapType].cleanup then
    local status,r = pcall(mapTypes[self.mapType].cleanup,self)
    if status == false then
      output:out("Error in map " .. self.mapType .. " cleanup code: " .. r)
      print("Error in map " .. self.mapType .. " cleanup code: " .. r)
    end
    return r
  end
end

---Gets the full name string of the map (eg The Wilds Depth 2: The Forest of Horror)
--@param noBranch Boolean. Optional, if set to true, only returns the base name of the map without depth and branch info
function Map:get_name(noBranch)
  local branch = currWorld.branches[self.branch]
  local name = ""
  if not noBranch then
    if not branch.hideName and branch.name then
      name = name .. branch.name
    end
    if not branch.hideDepth then
      name = name .. ", " .. (branch.depthName or "Depth") .. " " .. self.depth
    end
    if self.name and name ~= "" then
      name = name .. ": "
    end
  end
  
  name = name .. (self.name or "")
  return name
end

---Get the minimum creature level for this map
function Map:get_min_level()
  local branch = currWorld.branches[self.branch]
  return round((branch.min_level_base or 1)+(self.depth-1)*(branch.level_increase_per_depth or 1)+(currGame.level_boost or 0))
end

---Get the maximum creature level for this map
function Map:get_max_level()
  local branch = currWorld.branches[self.branch]
  return round((branch.max_level_base or 1)+(self.depth-1)*(branch.level_increase_per_depth or 1)+(currGame.level_boost or 0))
end

---Get a map's content tags
--@param tagType String. The type of tag
--@param noBranch Boolean. If true, don't look at branch's tags
function Map:get_content_tags(tagType,noBranch)
  local tagLabel = (tagType and tagType .. "Tags" or "contentTags")
  local whichMap = mapTypes[self.mapType]
  noBranch = noBranch or whichMap.noBranchContent or (tagType and whichMap['noBranch' .. ucfirst(tagType) .. "s"])
  local tags = ((self[tagLabel] and count(self[tagLabel]) > 0 and self[tagLabel]) or (tagLabel ~= "passedTags" and tagLabel ~= "forbiddenTags" and tagLabel ~= "requiredTags" and self.contentTags) or {})
  if not noBranch then
    local branch = currWorld.branches[self.branch]
    local bTags = branch[tagLabel] or (tagLabel ~= "passedTags" and tagLabel ~= "forbiddenTags" and tagLabel ~= "requiredTags" and branch.contentTags)
    if bTags then
      tags = merge_tables(tags,bTags)
    end
  end
  return tags
end

---Checks if a map has a given content tag
--@param tag String. The tag to check for
--@param tagType String. The type of tag
--@return Boolean. Whether or not it has the tag.
function Map:has_content_tag(tag,tagType)
  if in_table(tag,self:get_content_tags(tagType)) then
    return true
  end
  return false
end

---Checks if a map has a descriptive tag.
--@param tag String. The tag to check for
--@return Boolean. Whether or not it has the tag.
function Map:has_tag(tag)
  if self.tags and in_table(tag,self.tags) then
    return true
  end
  if currGame.time and currGame.time.tags and in_table(tag,currGame.time.tags) then
    return true
  end
  return false
end


---Checks if a map has a room with the given decorator. Only returns the first one, not multiples if there are any
--@param decorator String. The decorator ID to look for
--@return Room. The first room found that matches the decorator ID
function Map:has_room(decorator)
  for _,room in pairs(self.rooms) do
    if room.decorator == decorator then
      return room
    end
  end
  return false
end


---Determines if a tile is safe to block. Useful in map generators for placing decorations
--@param startX Number. The X-coordinate we're looking at
--@param startY Number. The Y-coordinate we're looking at
--@param safeType Text. Determines what counts as safe to block. "wall": next to wall only, "noWalls": not next to wall, "wallsCorners": open walls and corners only, "corners": corners only
--@return Boolean. Whether the tile is safe to block or not.
function Map:is_safe_to_block(startX,startY,safeType)
  local minX,minY,maxX,maxY=startX-1,startY-1,startX+1,startY+1
  local cardinals,corners = {},{}
  local cardinalWalls,cornerWalls = {},{}
  local n,s,e,w = false,false,false,false
  local walls = false
  if self:tile_has_feature(startX,startY,'exit') or not self:isClear(startX,startY,nil,true) or self.tile_info[startX][startY].noBlock then return false end

  for x=minX,maxX,1 do
    for y=minY,maxY,1 do
      local door = self:tile_has_tag(x,y,'door')
      if (self:isClear(x,y) or door) and not (x == startX and y == startY) then
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
        if self[x][y] == "#" or self:isWall(x,y) then walls = true end
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
        if self:touching(tile.x,tile.y,card1X,card1Y) and self:touching(tile.x,tile.y,card2X,card2Y) then
          okOpen = true
        end
      end
      for _,tile in pairs(cardinalWalls) do --check to make sure that the corner next to the two cardinal openings is also open
        if self:touching(tile.x,tile.y,cardwall1X,cardwall1Y) and self:touching(tile.x,tile.y,cardwall2X,cardwall2Y) then
          okWall = true
        end
      end
      if okOpen == true and okWall == true then
        return true
      end --end okOpen/okWall if
    elseif #cardinalWalls == 1 then
      local cardX,cardY = cardinalWalls[1].x,cardinalWalls[1].y
      for _,tile in pairs(cornerWalls) do
        if not self:touching(tile.x,tile.y,cardX,cardY) then --if there's a corner that is not touching the only wall we're against, it's not OK
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
        if not self:touching(card1X,card1Y,tile.x,tile.y) and not self:touching(card2X,card2Y,tile.x,tile.y) then
          return false
        end --end if touching
      end --end tile for
    elseif #cardinals == 1 then
      local cardX,cardY = cardinals[1].x,cardinals[1].y
      for _, tile in pairs(corners) do --check to make sure all the corner openings touch the cardinal direction opening
        if not self:touching(cardX,cardY,tile.x,tile.y) then
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

---Applies damage to all creates and features in a tile
---Damage a creature
--@param x Number. The x-coordinate.
--@param y Number. The y-coordinate.
--@param amt Number. The damage to deal.
--@param attacker Entity. The source of the damage.
--@param damage_type String. The damage type of the attack. (optional)
--@param args Table. A table of other arguments. All the below arguments are options to include.
--@param armor_piercing Boolean, or Number. If set to true, it ignores all armor. If set to a number, ignores that much armor. (optional)
--@param noSound Boolean. If set to true, no damage type sound will be played. (optional)
--@param item Item. The weapon used to do the damage. (optional)
--@param ignoreWeakness Boolean. If true, don't apply weakness
--@param attackerSafe Boolean. If true, do not harm the attacker.
--@param tweak Boolean. If true, tweak the damage number.
--@param conditions Table. A table of conditions to possible inflict, in the same format as hitConditions elsewhere.
--@param source_name String. The name to display for the source of the damage.
--@param creatureSafe Boolean. If true, don't damage creatures
--@return Table. A table of all damaged entities and the damage done to them.
function Map:damage_all(x,y,damage,attacker,damage_type,args)
  args = args or {}
  local creat = currMap:get_tile_creature(x,y)
  if creat and not args.creatureSafe and (creat ~= attacker or not args.attackerSafe) then
    local dmg = creat:damage((args.tweak and tweak(damage) or damage),attacker,damage_type,args.armor_piercing,args.noSound,args.item,args.ignore_weakness)
    if dmg and dmg > 0 and player:can_sense_creature(creat) then
      output:out(creat:get_name() .. " takes " .. dmg .. " " .. (damage_type and damage_types[damage_type] and damage_types[damage_type].name and damage_types[damage_type].name .. " " or "") .. "damage" .. (args.source_name and " from the " .. args.source_name .. "." or "."))
    end
    if args.conditions then
      for _,conInfo in pairs(args.conditions) do
        if conInfo.chance and random(1,100) <= conInfo.chance then
          local turns = (conInfo.minTurns and conInfo.maxTurns and random(conInfo.minTurns,conInfo.maxTurns)) or tweak(conInfo.turns or 0)
          creat:give_condition(conInfo.condition,turns,attacker)
        end
      end
    end
  end --end creat
  for _,feat in pairs(currMap:get_tile_features(x,y)) do
    if feat.hp or feat.max_hp or feat.attackable then
      local dmg = feat:damage((args.tweak and tweak(damage) or damage),attacker,damage_type)
      if dmg and dmg > 0 and player:can_see_tile(x,y)  then
        output:out(feat:get_name() .. " takes " .. dmg .. " " .. (damage_type and damage_types[damage_type] and damage_types[damage_type].name and damage_types[damage_type].name .. " " or "") .. "damage" .. (args.source_name and " from the " .. args.source_name .. "." or "."))
      end
    end
  end --end feature for
end

---Registers an incident as having occured, to be processed by all other creatures who observe it
--@param incidentID String. The incident type
--@param actor Entity. The creature (or other entity) that caused the incident. Optional
--@param target Entity. The entity (or coordinates), that was the target of the incident. Optional
--@param args Table. Other information to use when processing this incident
function Map:register_incident(incidentID,actor,target,args)
  args = args or {}
  local seen_factions = {}
  for _,creat in pairs(self.creatures) do
    if not (creat.isDead or creat.hp < 1) and not creat:has_condition('asleep') then
      local can_see_actor = not actor or (actor.baseType ~= "creature" and creat:can_see_tile(actor.x,actor.y) or (actor.baseType == "creature" and creat:can_sense_creature(actor)))
      local can_see_target = not target or (target.baseType ~= "creature" and creat:can_see_tile(target.x,target.y) or (target.baseType == "creature" and creat:can_sense_creature(target)))
      if can_see_actor or can_see_target then
        creat:process_incident(incidentID,actor,target,args)
        if #creat.factions > 0 then
          for _,factionID in ipairs(creat.factions) do
            seen_factions[factionID] = currWorld.factions[factionID]
          end
        end
      end
    end
  end
  if actor and actor.baseType == "creature" then
    if currMap.aware_factions then
      for _,factionID in ipairs(currMap.aware_factions) do
        seen_factions[factionID] = currWorld.factions[factionID]
      end
    end
    for fid,faction in pairs(seen_factions) do
      faction:process_incident(incidentID,actor,target,args)
    end
  end
end

---Get a stat bonus provided by the map
--@param bonusType String. The type of bonus
--@param x Number. The x-coordinate of the asker. Used to look at the room they're in's bonus
--@param y Number. The y-coordinate of the asker. Used to look at the room they're in's bonus
function Map:get_bonus(bonusType,x,y)
  local bonus = 0
  if self.bonuses and self.bonuses[bonusType] then
    bonus = bonus + self.bonuses[bonusType]
  end
  local room = (self.tile_info[x] and self.tile_info[x][y] and self.tile_info[x][y].room)
  if room and not room.disabled and room.bonuses and room.bonuses[bonusType] then
    bonus = bonus + room.bonuses[bonusType]
  end
  return bonus
end

---Clear all map caches
function Map:clear_caches()
  currMap.sightblock_cache = {}
  currMap.creature_cache = {}
  currMap.feature_cache = {}
  currMap.effect_cache = {}
end