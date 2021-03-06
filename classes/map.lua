---@classmod Map
Map = Class{}

---Initiates a map. Don't call this explicitly, it's called when you create a new map with Map(50,50).
--@param width Number. The width of the map
--@param height Number. The height of the map
--@param gridOnly Boolean. If set to true, then extra tables (eg creatures, lights, pathfinders) will not be created for the map (optional)
--@return Map. The map itself.
function Map:init(width,height,gridOnly)
  if not gridOnly then
    self.creatures,self.contents,self.effects,self.projectiles,self.seenMap,self.lightMap,self.lights,self.pathfinders,self.grids,self.collisionMaps,self.exits={},{},{},{},{},{},{},{},{},{},{}
    self.boss=nil
    self.stairsUp,self.stairsDown = {x=0,y=0},{x=0,y=0}
  end
  self.width,self.height=width,height
	for x = 1, width, 1 do
		self[x] = {}
    if not gridOnly then
      self.contents[x] = {}
      self.seenMap[x] = {}
      self.lightMap[x] = {}
    end
		for y = 1, height, 1 do
      if not gridOnly then
        self.seenMap[x][y] = false
        self.contents[x][y] = {}
        self.lightMap[x][y] = false
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
      if open and x ~= 1 and x ~= self.width and y ~= 1 and y ~= self.height then
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
    end
    for y = 1, self.height, 1 do
      self.seenMap[x][y] = false
      self.contents[x][y] = {}
      self.lightMap[x][y] = false
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
--@return Boolean. Whether the tile is clear
function Map:isClear(x,y,ctype,ignoreCreats,ignore_safety,projectile)
  if x < 2 or y < 2 or x >= self.width or y >= self.height then return false end
	if (self[x][y] == "#") then return false end --if there's a wall there, it's not clear
  if ignoreCreats ~= true and self:get_tile_creature(x,y) then return false end --if there's a creature there, it's not clear
  if ctype ~= nil then return self:is_passable_for(x,y,ctype,false,ignore_safety,projectile) end --if you're asking about a specific creature type, pass it off
  --Otherwise, generic:
  if type(self[x][y]) == "table" and (self[x][y].blocksMovement == true or self[x][y].impassable == true) then return false end --if the square is a special tile and said tile is generally impassable, it's not clear
	for id, entity in pairs(self.contents[x][y]) do
		if entity.blocksMovement == true or entity.impassable == true then
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
	if (self[x][y] == "#") then return false end --if there's a wall there, it's not clear
  if lookAtBaseTile == true and type(self[x][y]) == "table" then return false end
  if ignoreCreats ~= true and self:get_tile_creature(x,y) then return false end --if there's a creature there, it's not clear
	for id, entity in pairs(self.contents[x][y]) do
		if entity.baseType == "feature" then
			return false
		end
	end
	return true
end

---Gets contents of a map tile
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Table. A table of all the contents of the tile
function Map:get_contents(x,y)
  return self.contents[x][y]
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
  for id, entity in pairs(self.contents[x][y]) do --make sure you can enter the features at the new tile
    if (entity.baseType == "feature") then
      if (entity:enter(creature,fromX,fromY) == false) then canEnter = false break end
    end
  end -- end feature for
  if type(self[x][y]) == "table" and self[x][y]:enter(creature,fromX,fromY) == false then canEnter = false end
  return canEnter
end

---Determines if a given tile blocks vision
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param args Unused for now, leave blank.
--@return Boolean. Whether or not the tile blocks vosopm
function Map:can_see_through(x,y,args)
	if (x<2 or y<2 or x>self.width-1 or y>self.height-1 or self[x][y] == "#") then
		return false
	end
  for id,entity in pairs(self.contents[x][y]) do
    if entity.blocksSight == true then return false end
    --if args.reducedSight and entity.sightReduction then args.reducedSight = args.reducedSight-entity.sightReduction end
  end --end for loop
  for _,eff in pairs(self:get_tile_effects(x,y)) do
    if eff.blocksSight == true then return false end
    --if args.reducedSight and eff.sightReduction then reducedSight = args.reducedSight-eff.sightReduction end
  end --end effect loop
  --if args.reducedSight and args.reducedSight <= 0 then return false end
	return true
end

---Gets what creature (if any) is on a tile
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param get_attackable_features Boolean. Whether to include attackable features (optional, defaults to false)
--@param ignoreNoDraw Boolean. Whether creatures that have noDraw set will be included (optional, defaults to false)
--@return Entity or Boolean. Will be FALSE if there's nothing there.
function Map:get_tile_creature(x,y,get_attackable_features,ignoreNoDraw)
  if (x<2 or y<2 or x>=self.width or y>=self.height) then return false end
	if (next(self.contents) == nil) then
		return false
	else
    local tileFeat = false
		for id, entity in pairs(self.contents[x][y]) do
			if entity.baseType == "creature" and (ignoreNoDraw or entity.noDraw ~= true) then
        return entity --immediately return the first creature you find
      elseif (get_attackable_features == true and entity.baseType == "feature" and (entity.attackable == true or entity.pushable == true or entity.possessable == true)) then
				tileFeat = entity --don't immediately return a feature, because a creature may be standing on it
			end
		end
    if tileFeat then return tileFeat end
	end
	return false
end

---Gets a list of all features (if any) on a tile.
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return A table of features (may be empty)
function Map:get_tile_features(x,y)
  if not self:in_map(x,y) then return {} end
  
  local features = {}
  if type(self[x][y]) == "table" then features[1] = self[x][y] end
	for id, entity in pairs(self.contents[x][y]) do
		if (entity and entity.baseType == "feature") then
			features[#features+1] = entity
		end --end if
	end --end entity for
	return features
end

---Check if a tile has a specific feature
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param id String. The ID of the feature to check for.
--@return Boolean. Whether or not the tile has this feature
function Map:tile_has_feature(x,y,id)
  if x<2 or y<2 or x>self.width-1 or y>self.height-1 then return false end
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
--@return A table of items (may be empty)
function Map:get_tile_items(x,y,getAdjacent)
  if not self:in_map(x,y) then return {} end
  
  local items = {}
	for id, entity in pairs(self.contents[x][y]) do
		if (entity and entity.baseType == "item") then
			items[#items+1] = entity
		end --end if
	end --end entity for
  if getAdjacent then
    for x2=x-1,x+1,1 do
      for y2=y-1,y+1,1 do
        if x ~= x2 or y ~= y2 then
          for id, entity in pairs(self.contents[x2][y2]) do
            if (entity and entity.baseType == "item") then
              items[#items+1] = entity
            end --end if
          end --end entity for
        end --end no-double-dipping if
      end --end yfor
    end --end xfor
  end --end if get_adjacent
	return items
end

---Gets a list of all feature actions (if any) available at and around a tile.
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param user Creature. The user looking for actions. Optional, defaults to player
--@param noAdjacent Boolean. Whether to count adjacent tiles. Optional, defaults to false (ie adjacent tiles are counted)
--@return A table of items (may be empty)
function Map:get_tile_actions(x,y,user,noAdjacent)
  if not self:in_map(x,y) then return {} end
  user = player or user
  
  local actions = {}
  if noAdjacent then
    for id, entity in pairs(self:get_tile_features(x,y)) do
      if entity.actions then
        for id,act in pairs(entity.actions) do
          if not act.requires or act.requires(entity,user) then
            actions[#actions+1] = {id=id,entity=entity,text=act.text,description=act.description}
          end --end requires if
        end --end action for
      end --end if
    end --end entity for
  else
    for x2=x-1,x+1,1 do
      for y2=y-1,y+1,1 do
        for id, entity in pairs(self:get_tile_features(x2,y2)) do
          if entity.actions then
            for id,act in pairs(entity.actions) do
              if not act.requires or act.requires(entity,user) then
                actions[#actions+1] = {id=id,entity=entity,text=act.text,description=act.description}
              end --end requires if
            end --end action for
          end --end if
        end --end entity for
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
--@return Boolean. Whether or not you can draw the line.
function Map:is_line(startX,startY,endX,endY,pass_through_walls,ctype,ignoreCreats,ignoreSafety,projectile)
  local bresenham = require 'lib.bresenham'
  if pass_through_walls then
    return bresenham.los(startX,startY,endX,endY, function() return true end)
  else
    return bresenham.los(startX,startY,endX,endY, function(map,x,y,ctype,ignoreCreats,ignoreSafety,projectile) return self:isClear(x,y,ctype,ignoreCreats,ignoreSafety,projectile) end,self,ctype,ignoreCreats,ignoreSafety,projectile)
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
--@return A table full of tile values.
function Map:get_line(startX,startY,endX,endY,pass_through_walls,ctype,ignoreCreats,ignoreSafety,projectile)
  local bresenham = require 'lib.bresenham'
  if pass_through_walls then
    return bresenham.line(startX,startY,endX,endY, function() return true end)
  else
    return bresenham.line(startX,startY,endX,endY, function(map,x,y,ctype,ignoreCreats,ignoreSafety,projectile) return self:isClear(x,y,ctype,ignoreCreats,ignoreSafety,projectile) end,self,ctype,ignoreCreats,ignoreSafety,projectile)
  end --end pass_through_walls if
end

---Gets all effects (if any) on a tile.
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return A table of effects(may be empty)
function Map:get_tile_effects(x,y)
  local effects = {}
	for id, effect in pairs(self.effects) do
		if (effect.x == x and effect.y == y) then
			effects[#effects+1] = effect
		end	
	end
	return effects
end

---Check if a tile has a specific effect on it
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param id String. The ID of the effect to check for.
--@return Boolean. Whether or not the tile has this effect
function Map:tile_has_effect(x,y,id)
  if x<2 or y<2 or x>self.width-1 or y>self.height-1 then return false end
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
function Map:add_creature(creature,x,y,ignoreFunc)
	creature.x, creature.y = x,y
	self.contents[x][y][creature] = creature
	self.creatures[creature] = creature
  if not ignoreFunc and possibleMonsters[creature.id].new then possibleMonsters[creature.id].new(creature,self) end
  if creature.castsLight then self.lights[creature] = creature end
end

---Add a feature to a tile
--@param feature Feature. A specific feature object, NOT its ID. Usually a new feature, called using Feature('featureID')
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Feature. The feature added
function Map:add_feature(feature,x,y)
	x = (x or random(2,self.width-1))
	y = (y or random(2,self.height-1))
	self.contents[x][y][feature] = feature
  feature.x,feature.y = x,y
  if possibleFeatures[feature.id].placed then possibleFeatures[feature.id].placed(feature,self) end
  if feature.castsLight then self.lights[feature] = feature end
  return feature --return the feature so if it's created when tis function is called, you can still access it
end

---Add an effect to a tile
--@param effect Effect. A specific effect object, NOT its ID. Usually a new effect, called using Effect('effectID')
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Effect. The effect added
function Map:add_effect(effect,x,y)
  effect.x,effect.y = x,y
	self.effects[effect] = effect
  if effect.castsLight then self.lights[effect] = effect end
  return effect --return the effect so if it's created when tis function is called, you can still access it
end

---Add an item to a tile
--@param item Item. A specific item object, NOT its ID. Usually a new creature, called using Item('itemID')
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param ignoreFunc Boolean. Whether to ignore the item's new() function (optional)
function Map:add_item(item,x,y,ignoreFunc)
	item.x, item.y = x,y
	self.contents[x][y][item] = item
  if not ignoreFunc and possibleItems[item.id].placed then possibleItems[item.id].placed(item,self) end
  if item.castsLight then self.lights[item] = item end
  
  --Check for stacking:
  if item.stacks then
    for _,groundItem in pairs(self.contents[x][y]) do
      if item ~= groundItem and groundItem.baseType == "item" and groundItem.id == item.id and (not item.sortBy or item[item.sortBy] == groundItem[item.sortBy]) then
        groundItem.amount = groundItem.amount + item.amount
        self.contents[x][y][item] = nil
        self.lights[item] = nil
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
	self[x][y] = feature
  if type(feature) == "table" then
    feature.x,feature.y = x,y
    if possibleFeatures[feature.id].placed then possibleFeatures[feature.id].placed(feature,self) end
    if feature.castsLight then
      self.lights[feature] = feature
      self:refresh_lightMap()
    end
  end
  if not dontRefreshSight then refresh_player_sight() end
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
  if self.pathfinders[(cType or 'basic') .. (terrainLimit or "")] == nil then
    self:refresh_pathfinder(cType,terrainLimit)
  end
	local path = self.pathfinders[(cType or 'basic') .. (terrainLimit or "")]:getPath(fromX,fromY,toX,toY,true)
	if path then
    if #path > 1 then path:fill() end
		return path
  else
    if self.pathfinders[(cType or 'basic') .. (terrainLimit or "") .. "unsafe"] == nil then self:refresh_pathfinder(cType,terrainLimit,true) end
    local path = self.pathfinders[(cType or 'basic') .. (terrainLimit or "") .. "unsafe"]:getPath(fromX,fromY,toX,toY,true)
    if path then
      if #path > 1 then path:fill() end
      return path
    end
	end
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
	creature1:moveTo(orig2x,orig2y)
	creature2:moveTo(orig1x,orig1y)
end

---Refresh a pathfinder on the map
--@param cType String. The creature path type (eg flyer) (optional)
--@param terrainLimit String. If you want to limit the pathfinder to a specific feature ID (optional)
--@param ignoreSafety Boolean. Whether to ignore hazards (optional)
function Map:refresh_pathfinder(cType,terrainLimit,ignoreSafety)
  if (self.collisionMaps[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")] == nil) then self.collisionMaps[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")] = {} end
	for y = 1, self.height, 1 do
    if (self.collisionMaps[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")][y] == nil) then self.collisionMaps[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")][y] = {} end
		for x = 1, self.width, 1 do
			self.collisionMaps[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")][y][x] = 0
      if self:is_passable_for(x,y,cType,false,ignoreSafety) == false or (terrainLimit and not self:tile_has_feature(x,y,terrainLimit)) then self.collisionMaps[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")][y][x] = 1 end
		end
	end
  
  if self.grids[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")] == nil or self.pathfinders[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")] == nil then
    local Grid = require('lib.jumper.grid')
    self.grids[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")] = Grid(self.collisionMaps[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")])
    local Pathfinder = require 'lib.jumper.pathfinder'
    self.pathfinders[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")] = Pathfinder(self.grids[(cType or 'basic') .. (terrainLimit or "") .. (ignoreSafety and "unsafe" or "")],'ASTAR',0)
  end
end

---Delete all the pathfinders from the map
function Map:clear_all_pathfinders()
  self.pathfinders = {}
  self.collisionMaps = {}
  self.grids = {}
end

---Checks if a tile is passable for a certain creature
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param cType String. The creature path type (eg flyer) (optional)
--@param include_effects Boolean. Whether to include effects in the passable check (optional)
--@param ignore_safety Boolean. Whether to ignore dangerous but transversable tiles (optional)
--@return Boolean. If it's passable.
function Map:is_passable_for(x,y,ctype,include_effects,ignore_safety,projectile)
  if not self:in_map(x,y) then return false end
  if type(self[x][y]) == "string" then
    if self[x][y] == "#" then return false end
  elseif type(self[x][y]) == "table" then
    local tile = self[x][y]
    if tile.blocksMovement == true and (projectile == true or tile.pathThrough ~= true) then return false end
    if tile.impassable and (ctype == nil or tile.passableFor[ctype] ~= true) then return false end
    if not ignore_safety and tile.hazard and tile.hazard > 1 and ((tile.hazardousFor == nil and (ctype == nil or tile.safeFor == nil or tile.safeFor[ctype] ~= true)) or (ctype ~= nil and tile.hazardousFor and tile.hazardousFor[ctype] == true)) then return false end
  end
  --Check Features:
  for _,feat in pairs(self:get_tile_features(x,y)) do
    if feat.blocksMovement == true and (projectile == true or feat.pathThrough ~= true) then return false end
    if feat.impassable and (ctype == nil or feat.passableFor[ctype] ~= true) then return false end
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
function Map:refresh_tile_image(x,y)
  if not self.images then return self:refresh_images() end
  local name = ""
  local directions = ""
  local tileset = tilesets[self.tileset]
  if type(self[x][y]) == "table" then
    self[x][y]:refresh_image_name()
    name = "floor"
  elseif self[x][y] == "." then
    name = "floor"
  elseif self[x][y] == "#" then
    if self[x][y-1] and self[x][y-1] ~= "#" then directions = directions .. "n" end
    if self[x][y+1] and self[x][y+1] ~= "#" then directions = directions .. "s" end
    if self[x+1] and self[x+1][y] ~= "#" then directions = directions .. "e" end
    if self[x-1] and self[x-1][y] ~= "#" then directions = directions .. "w" end
    if tileset.southOnly then
      if directions:find('s') then name = 'walls' else name = 'wall' end
    elseif tileset.tilemap then --if all wall tiles are in a single image (uses quads)
      name = "wall"
    else
      name = "wall" .. directions
    end
  elseif self[x][y] == "<" then
    name = "stairsup"
  elseif self[x][y] == ">" then
    name = "stairsdown"
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
--@param include_borders Boolean. Whether or not to include the tiles on the border of the map 
function Map:in_map(x,y,include_borders)
  if not x or not y then return false end
  if include_borders and x >= 1 and y >= 1 and x <= self.width and y <= self.height then
    return true
  elseif not include_borders and x > 1 and y > 1 and x < self.width and y < self.height then
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
  if self.lit then return end

  for _,light in pairs(self.lights) do
    self:refresh_light(light,clear)
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
  if not light.lightTiles or forceRefresh then light.lightTiles = {} end
  local dist = light.lightDist or 0
  for lx = light.x-dist,light.x+dist,1 do
    for ly = light.y-dist,light.y+dist,1 do
      if self:in_map(lx,ly) and not self.lightMap[lx][ly] then
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
      if content.baseType == "effect" then
        content:delete(self)
      elseif content.baseType == "feature" then
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
  
  --Do special code if the mapType has it:
  if mapType.populate_creatures and not forceGeneric then
    return mapType:populate_creatures(creatTotal)
  end
  
  if not self.noCreatures and creatTotal > 0 then
    local newCreats = {}
    local specialCreats = mapgen:get_creature_list(self)
		for creat_amt=1,creatTotal,1 do
			local nc = mapgen:generate_creature(self.depth,specialCreats)
      if nc == false then break end
      local cx,cy = random(2,self.width-1),random(2,self.height-1)
      local tries = 0
      while (self:is_passable_for(cx,cy,nc.pathType) == false or self:tile_has_feature(cx,cy,'door') or self:tile_has_feature(cx,cy,'gate') or calc_distance(cx,cy,self.stairsDown.x,self.stairsDown.y) < 3) or self[cx][cy] == "<" do
        cx,cy = random(2,self.width-1),random(2,self.height-1)
        tries = tries+1
        if tries > 100 then break end
      end
      if tries ~= 100 then 
        if random(1,4) == 1 then nc:give_condition('asleep',random(10,100)) end
        newCreats[#newCreats+1] = self:add_creature(nc,cx,cy)
      end --end tries if
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
  
  --If itemTotal is blank, set itemTotal based on the desired density
  if not itemTotal then
    local density = mapType.item_density or branch.item_density or gamesettings.item_density
    local itemMax = math.ceil((self.width*self.height)*(density/100))
    itemTotal = itemMax --TODO: 
  end
  
  --Do special code if the mapType has it:
  if mapType.populate_items and not forceGeneric then
    return mapType.populate_items(self,itemTotal)
  end
  
  local passedTags = nil
  if mapType.passedTags then
    if mapType.noBranchItems or not branch.passedTags then
      passedTags = mapType.passedTags
    else
      passedTags =  merge_tables(mapType.passedTags,branch.passedTags)
    end
  else --if the mapType doesn't have passedTags, fall back to the branch's items
    passedTags = branch.passedTags --if branch doesn't have creatures, this will set it to nil and just use regular items
  end
  
  if not self.noItems and itemTotal > 0 then
    local newItems = {}
    local specialItems = mapgen:get_item_list(self,passedTags)
    for item_amt = 1,itemTotal,1 do
      local ni = mapgen:generate_item(self.depth,specialItems,passedTags)
      if ni == false then break end
      local ix,iy = random(2,self.width-1),random(2,self.height-1)
      local tries = 0
      while (self:isClear(ix,iy) == false or self[ix][iy] == "<" or self[ix][iy] == ">") do
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