Map = Class{}

--Initiates a map. Don't call this explicitly, it's called when you create a new map.
--@param self Map. The new map being created
--@param width Number. The width of the map
--@param height Number. The height of the map
--@param gridOnly True/False. If set to true, then extra tables (eg creatures, lights, pathfinders) will not be created for the map (optional)
--@return Map. The map itself.
function Map:init(width,height,gridOnly)
  if not gridOnly then
    self.creatures,self.contents,self.effects,self.projectiles,self.seenMap,self.lightMap,self.lights,self.pathfinders,self.grids,self.collisionMaps={},{},{},{},{},{},{},{},{},{}
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

--Checks whether a map tile is clear
--@param self Map. The map
--@param x Number. The x-coordinate to check
--@param y Number. The y-coordinate to check
--@param ctype String. The creature type to check for
--@param ignoreCreats True/False. Whether to ignore creatures when considering a tile clear (optional)
--@param ignore_safety True/False. Whether to ignore dangerous but transversable features (optional)
--@return True/False. Whether the tile is clear
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

--Checks whether a map tile is empty
--@param self Map. The map
--@param x Number. The x-coordinate to check
--@param y Number. The y-coordinate to check
--@param ignoreCreats True/False. Whether to ignore creatures when considering a tile clear (optional)
--@param lookAtBaseTile True/False. Whether to count base tile as a feature (optional)
--@return True/False. Whether the tile is clear
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

--Gets contents of a map tile
--@param self Map. The map
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Table. A table of all the contents of the tile
function Map:get_contents(x,y)
  return self.contents[x][y]
end

--Run the terrain enter callbacks for the creature's location
--@param self Map. The map
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param creature Creature. The creature entering the tile
--@param fromX Number. The x-coordinate the creature is leaving (optional)
--@param fromY Number. The y-coordinate the creature is leaving (optional)
--@return True/False. Whether or not the tile can be entered
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

--Determines if a given tile can be seen through
--@param self Map. The map
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param args Unused for now, leave blank.
--@return True/False. Whether or not the tile can be seen through.
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

--Gets the creature (if any) on a tile
--@param self Map. The map
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param get_attackable_features True/False. Whether to include attackable features or not (optional, defaults to false)
--@param ignoreNoDraw True/False. Whether creatures that have noDraw set will be included (optional, defaults to false)
--@return Either the entity, or FALSE if there's nothing there.
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

--Gets all features (if any) on a tile.
--@param self Map. The map
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

--Check if a tile has a specific feature
--@param self Map. The map
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param id String. The ID of the feature to check for.
--@return True/False. Whether or not the tile has this feature
function Map:tile_has_feature(x,y,id)
  if x<2 or y<2 or x>self.width-1 or y>self.height-1 then return false end
  if type(self[x][y]) == "table" and self[x][y].id == id then return self[x][y] end
  for _,entity in pairs(self:get_tile_features(x,y)) do
    if entity.id == id then return entity end
  end
  return false
end --end function

--Gets the first feature that blocks movement
--@param self Map. The map
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return True/False. Whether or not the tile has this feature
function Map:get_blocking_feature(x,y)
  if x<2 or y<2 or x>self.width-1 or y>self.height-1 then return false end
  if type(self[x][y]) == "table" and self[x][y].id == id and self[x][y].blocksMovement then return self[x][y] end
  for _,entity in pairs(self:get_tile_features(x,y)) do
    if entity.blocksMovement then return entity end
  end
  return false
end --end function

--Determines if you can draw a straight line between two tiles.
--@param self Map. The map
--@param startX Number. The x-coordinate of the first tile
--@param startY Number. The y-coordinate of the first tile
--@param endX Number. The x-coordinate of the second tile
--@param endY Number. The y-coordinate of the second tile
--@param pass_through_walls True/False. Ignore walls that block the line (optional)
--@param ctype String. The creature path type (eg flyer) (optional)
--@param ignoreCreats True/False. Ignore creatures that block the line (optional)
--@param ignoreSafety True/False. Ignore unsafe but transversable tiles that block the line (optional)
--@return True/False. Whether or not you can draw the line.
function Map:is_line(startX,startY,endX,endY,pass_through_walls,ctype,ignoreCreats,ignoreSafety,projectile)
  local bresenham = require 'lib.bresenham'
  if pass_through_walls then
    return bresenham.los(startX,startY,endX,endY, function() return true end)
  else
    return bresenham.los(startX,startY,endX,endY, function(map,x,y,ctype,ignoreCreats,ignoreSafety,projectile) return self:isClear(x,y,ctype,ignoreCreats,ignoreSafety,projectile) end,self,ctype,ignoreCreats,ignoreSafety,projectile)
  end -- end pass through walls if
end

--Gets a line between two tiles.
--@param self Map. The map
--@param startX Number. The x-coordinate of the first tile
--@param startY Number. The y-coordinate of the first tile
--@param endX Number. The x-coordinate of the second tile
--@param endY Number. The y-coordinate of the second tile
--@param pass_through_walls True/False. Ignore walls that block the line (optional)
--@param ctype String. The creature path type (eg flyer) (optional)
--@param ignoreCreats True/False. Ignore creatures that block the line (optional)
--@param ignoreSafety True/False. Ignore unsafe but transversable tiles that block the line (optional)
--@return A table full of tile values.
function Map:get_line(startX,startY,endX,endY,pass_through_walls,ctype,ignoreCreats,ignoreSafety,projectile)
  local bresenham = require 'lib.bresenham'
  if pass_through_walls then
    return bresenham.line(startX,startY,endX,endY, function() return true end)
  else
    return bresenham.line(startX,startY,endX,endY, function(map,x,y,ctype,ignoreCreats,ignoreSafety,projectile) return self:isClear(x,y,ctype,ignoreCreats,ignoreSafety,projectile) end,self,ctype,ignoreCreats,ignoreSafety,projectile)
  end --end pass_through_walls if
end

--Gets all effects (if any) on a tile.
--@param self Map. The map
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

--Check if a tile has a specific effect
--@param self Map. The map
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param id String. The ID of the effect to check for.
--@return True/False. Whether or not the tile has this effect
function Map:tile_has_effect(x,y,id)
  if x<2 or y<2 or x>self.width-1 or y>self.height-1 then return false end
  for _,eff in pairs(self:get_tile_effects(x,y)) do
    if eff.id == id then return eff end
  end
  return false
end --end function

--Add a creature to a tile
--@param self Map. The map
--@param creature Creature. A specific creature object, NOT its ID. Usually a new creature, called using Creature('creatureID')
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param ignoreFunc True/False. Whether to ignore the creature's new() function (optional)
function Map:add_creature(creature,x,y,ignoreFunc)
	creature.x, creature.y = x,y
	self.contents[x][y][creature] = creature
	self.creatures[creature] = creature
  if not ignoreFunc and possibleMonsters[creature.id].new then possibleMonsters[creature.id].new(creature,self) end
  if creature.castsLight then self.lights[creature] = creature end
end

--Add a feature to a tile
--@param self Map. The map
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

--Add an effect to a tile
--@param self Map. The map
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

--Set a map tile to be a certain feature
--@param self Map. The map
--@param feature Feature or text. A specific feature object, NOT its ID. Usually a new feature, called using Feature('featureID'). OR text representing floor (.) or wall (#)
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Feature. The feature added
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

--Find a path between two points
--@param self Map. The map
--@param fromX Number. The x-coordinate, tile 1
--@param fromY Number. The y-coordinate, tile 1
--@param toX Number. The x-coordinate, tile 2
--@param toY Number. The y-coordinate, tile 2
--@param cType String. The creature path type (eg flyer) (optional)
--@param terrainLimit String. Limit pathfinding to tiles with a specific feature ID (optional)
--@return A table of tile entries, or FALSE if theres is no path.
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

--Check if two tiles are touching
--@param self Map. The map
--@param fromX Number. The x-coordinate, tile 1
--@param fromY Number. The y-coordinate, tile 1
--@param toX Number. The x-coordinate, tile 2
--@param toY Number. The y-coordinate, tile 2
--@return True/False. If the tiles are touching.
function Map:touching(fromX,fromY,toX,toY)
  if (math.abs(fromX-toX) <= 1 and math.abs(fromY-toY) <= 1) then
		return true
	end
	return false
end

--Swap the positions of two creatures.
--@param self Map. The map
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

--Refresh a pathfinder on the map
--@param self Map. The map
--@param cType String. The creature path type (eg flyer) (optional)
--@param terrainLimit String. If you want to limit the pathfinder to a specific feature ID (optional)
--@param ignoreSafety True/False. Whether to ignore hazards (optional)
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

--Delete all the pathfinders from the map
--@param self Map. The map
function Map:clear_all_pathfinders()
  self.pathfinders = {}
  self.collisionMaps = {}
  self.grids = {}
end

--Checks if a tile is passable for a certain creature
--@param self Map. The map
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param cType String. The creature path type (eg flyer) (optional)
--@param include_effects True/False. Whether to include effects in the passable check (optional)
--@param ignore_safety True/False. Whether to ignore dangerous but transversable tiles (optional)
--@param True/False. If it's passable.
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

--Set a tile as impassable on all collision maps
--@param self Map. The map
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param Number. 0 = open, 1 = blocked, blank = the opposite of what it already is (optional)
function Map:set_blocked(x,y,value)
  for ctype, cmap in pairs(self.collisionMaps) do
    if ctype == "basic" then ctype = nil end
    cmap[y][x] = (value or (self:is_passable_for(x,y,ctype) and 0 or 1))
  end
end

--Refresh all the tile images on the map
--@param self Map. The map
function Map:refresh_images()
  self.images = {}
  for x=1,self.width,1 do
    self.images[x] = {}
    for y=1,self.height,1 do
      self:refresh_tile_image(x,y)
    end --end fory
  end -- end forx
end

--Refresh a specific tile's tile image
--@param self Map. The map
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
  --[[elseif love.filesystem.isFile("images/levels/" .. self.tileset .. "/" .. name .. ".png") then --if image isn't loaded, try to load it
    if tileset.tilemap and name:find('wall') then
      self.images[x][y] = {image=self.tileset .. name,direction=(directions == "" and "middle" or directions)}
    else
      self.images[x][y] = self.tileset .. name
    end]]
    --images[self.tileset .. name] = love.graphics.newImage("images/levels/" .. self.tileset .. "/" .. name .. ".png")
  --[[else --if image doesn't exist, load generic wall if it's a wall, or set the image as nonexistant
    if name:find('wall') and love.filesystem.isFile("images/levels/" .. self.tileset .. "/wall.png") then -- generic wall tile?
      self.images[x][y] = self.tileset .. 'wall'
      --if images[self.tileset .. 'wall'] == nil then images[self.tileset .. 'wall'] = love.graphics.newImage("images/levels/" .. self.tileset .. "/wall.png") end
    else
      --images[self.tileset .. name] = -1
      self.images[x][y] = false
    end
  end --end loading images]]
  for _, feat in pairs(self.contents[x][y]) do
    feat:refresh_image_name()
  end
  for _,eff in pairs(self:get_tile_effects(x,y)) do
    eff:refresh_image_name()
  end
end
  
--Checks if a tile is even in the map boundaries
--@param self Map. The map
--@param x Number. The x-coordinate
--@param yNumber.  The y-coordinate
--@param include_borders True/False. Whether or not to include the tiles on the border of the map (optional)
function Map:in_map(x,y,include_borders)
  if not x or not y then return false end
  if include_borders and x >= 1 and y >= 1 and x <= self.width and y <= self.height then
    return true
  elseif not include_borders and x > 1 and y > 1 and x < self.width and y < self.height then
    return true
  end
  return false --if x or y = 1 or width and height
end

--Refresh the light map of the map. Called every turn.
--@param self Map. The map
--@param true/false clear. Whether to clear all the lights
function Map:refresh_lightMap(clear) --I have a feeling this is a HORRIBLE and inefficient function that will be a total asshole on resources (relatively speaking). No wonder realtime 3D lighting is so fucking slow
  
  --First, clear all the lights and assume everywhere is dark
  if clear and (not self.lit or self.lightMap[2][2] == false) then
    for x=2,currMap.width,1 do
      for y=2,currMap.height,1 do
        self.lightMap[x][y] = (self.lit and true or false)
      end
    end
  end
  if self.lit then return end

  for _,light in pairs(self.lights) do
    self:refresh_light(light,clear)
  end --end for effect
end

--Refresh the light map of a tile.
--@param self Map. The map
--@param light Entity. The light source to refresh
--@param forceRefresh true/false. Whether to force the light to refresh its lit tiles
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

--Checks if a tile is lit.
--@param self Map. The map
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param True/False. If the tile is lit.
function Map:is_lit(x,y)
  return self:is_in_map(x,y) and self.lightMap[x][y]
end

--Delete everything from a tile
--@param self Map. The map
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

--Mark every tile on the map as "seen"
--@param self Map. The map
function Map:reveal()
  for x=1,self.width,1 do
    for y=1,self.height,1 do
      self.seenMap[x][y] = true
    end
  end
end