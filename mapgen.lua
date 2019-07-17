mapgen = {}

function mapgen:floodFill(map,lookFor,startX,startY)
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
	while (map[startX][startY] ~= lookFor) do --if it's a wall, try again
		startX,startY = random(1,map.width),random(1,map.height)
	end
  local check = {{startX,startY}}
  while #check > 0 do
    local checkX,checkY=check[1][1],check[1][2]
    table.remove(check,1)
    floodFill, numTiles, check = mapgen:floodTile(map,checkX,checkY,floodFill,lookFor,numTiles,check) -- only needs to be called once, because it recursively calls itself
  end
	return floodFill,numTiles
end

function mapgen:floodTile(map, x,y,floodFill,lookFor,numTiles,check)
	-- Cycles through a tile and its immediate neighbors. Sets clear spaces in floodFill to true, non-clear spaces to false.
	for ix=x-1,x+1,1 do
		for iy=y-1,y+1,1 do
			if (ix >= 1 and iy >= 1 and ix <= map.width and iy <= map.height and floodFill[ix][iy] == nil) then --important: check to make sure floodFill hasn't looked at this tile before, to prevent infinite loop
				if map[ix][iy] == lookFor then
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

function mapgen:addRiver(map, tile, noBridges,bridgeData,minDist,clearTiles)
  local shores = {}
  
  map:refresh_pathfinder()
  if (random(1,2) == 1) then --north-south river
    local currX = random(math.ceil(map.width/4),math.floor((map.width/4)*3))
    local spread = random(1,3)
    for y=2,map.height-1,1 do
      currX = math.max(math.min(currX+(random(-1,1)),map.width-1),2)
      spread = math.max(math.min(spread+random(-1,1),3),1)
      --track shore tiles. We'll need them later to build bridges:
      local s = {{x=currX-spread-1,y=y},{x=currX+spread+1,y=y}}
      shores[#shores+1] = s
      --Add the water:
      for x=currX-spread,currX+spread,1 do
        if (x>2 and x<map.width-1) then
          for id,feature in pairs(map.contents[x][y]) do
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
    for x=2,map.width-1,1 do
      currY = math.max(math.min(currY+(random(-1,1)),map.width-1),2)
      spread = math.max(math.min(spread+random(-1,1),3),1)
      --track shore tiles. We'll need them later to build bridges:
      local s = {{x=x,y=currY-spread-1},{x=x,y=currY+spread+1}}
      shores[#shores+1] = s
      --Add the water:
      for y=currY-spread,currY+spread,1 do
        if (y>2 and y<map.height-1) then
          for id,feature in pairs(map.contents[x][y]) do
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
            if (s1xDist < 2 and s1yDist < 2) or (s2xDist < 2 and s2yDist < 2) or (map:tile_has_feature(shore[1].x,shore[1].y,"door") == false and map:tile_has_feature(shore[2].x,shore[2].y,"door") == false) then
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
    --[[for id, shore in ipairs(shores) do
      if (shore[1].x > 2 and shore[1].x < map.width-1 and shore[1].y > 2 and shore[1].y < map.height-1 and shore[2].x > 2 and shore[2].x < map.width-1 and shore[2].y > 2 and shore[2].y < map.height-1 and map:isClear(shore[1].x,shore[1].y) and map:isClear(shore[2].x,shore[2].y)) then
        local path = map:findPath(shore[1].x,shore[1].y,shore[2].x,shore[2].y)
        if path == false or #path > 15 then
          local _,size1 = mapgen:floodFill(map,".",shore[1].x,shore[1].y)
          local _,size2 = mapgen:floodFill(map,".",shore[2].x,shore[2].y)
          if (size1 > 10 and size2 > 10) then
            mapgen:buildBridge(map,shore[1].x,shore[1].y,shore[2].x,shore[2].y)
            if (shore[1].x == shore[2].x) then
              local s1,s2 = math.min(shore[1].y,shore[2].y),math.max(shore[1].y,shore[2].y)
              for y=s1+1,s2-1,1 do
                --map.contents[shore[1].x][y] = {}
                map:add_feature(Feature('bridge',{dir='ns'}),shore[1].x,y)
                map.collisionMaps['basic'][y][shore[1].x] = 0
                map[shore[1].x][y].impassable = false
                map[shore[1].x][y].hazard = false
              end --end for y=s1,s2,1
            else
              --local s1,s2 = math.min(shore[1].x,shore[2].x),math.max(shore[1].x,shore[2].x)
              for x=s1,s2,1 do
                --map.contents[x][shore[1].y] = {}
                local b = Feature('bridge',{dir='ew'})
                map:add_feature(b,x,shore[1].y)
                map.collisionMaps['basic'][shore[1].y][x] = 0
                if type(map[x][shore[1].y]) ~= "string" then
                  map[x][shore[1].y].impassable = false
                  map[x][shore[1].y].hazard = false
                end
                if (x==s1) then b.image_name="woodbridgee" elseif (x==s2) then b.image_name = "woodbridgew" end
              end --end for x=s1,s2,1
            end
          end --end size check if
        end --end findPath if
      end --end if
    end --end shore for]]
  end --end nobridges if
  map:refresh_pathfinder()
  return shores
end -- end function

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
          map[bridge.x][bridge.y].walkedOnImage = nil
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
          map[bridge.x][bridge.y].walkedOnImage = nil
        end -- end table if
      end --end forx
    end --end if xMod ~= 0
  end
end

function mapgen:makeEdges(map,width,height,onlyFeature)
  local topThick,bottomThick = 1,1
  for x=2,width-1,1 do
    local leftThick,rightThick = 1,1
    for y=2,height-1,1 do
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

function mapgen:addGenericStairs(build,width,height,depth)
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
          if x > 1 and y > 1 and x < width and y < height and build:isEmpty(x,y) and calc_distance(x,y,build.stairsDown.x,build.stairsDown.y) > math.min(width,height) then
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
        build[build.stairsUp.x][build.stairsUp.y] = "<"
        build[build.stairsDown.x][build.stairsDown.y] = ">"
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

function mapgen:addTombstones(map)
  local graves = load_graveyard()
  if graves[map.depth] == nil then return false end
  for i=1,random(#graves[map.depth]),1 do
    local grave = get_random_element(graves[map.depth])
    local x,y = random(2,map.width-1),random(2,map.height-1)
    local tries = 0
    while map:isEmpty(x,y,true) and tries < 100 do
      x,y = random(2,map.width-1),random(2,map.height-1)
      tries = tries+1
    end
    local text = (random(0,1) == 1 and "R.I.P " or "Here Lies ") .. grave.name .. "\n" .. os.date("%x",grave.time)
    if grave.killer then
      text = text .. "\n Killed by " .. grave.killer
    end
    map:add_feature(Feature('gravestone',text),x,y)
  end
end

function mapgen:clear_map(map,open)
  for x = 1, map.width, 1 do
		for y = 1, map.height, 1 do
			map.seenMap[x][y] = false
			map:clear_tile(x,y)
      if open and x ~= 1 and x ~= map.width and y ~= 1 and y ~= map.height then
        map[x][y] = "."
      else
        map[x][y] = "#"
      end
		end
	end
end

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
        if x > 1 and x < map.width and y > 1 and y < map.height and (x == point.x or y == point.y) and not (x==point.x and y==point.y) and (includeWalls or map[x][y] ~= "#") and doneHolder[x .. "," .. y] ~= true and random(1,100) <= point.spreadChance then
          points[#points+1] = {x=x,y=y,spreadChance=point.spreadChance-decay}
        end --end bounds check
      end --end fory
    end --end forx
    tries = tries+1
  end --end points while
  return finalPoints
end

function mapgen:generate_map(width, height, depth,force)
  local mapRandom = love.math.newRandomGenerator(currGame.seed)
  if currGame.seedState then mapRandom:setState(currGame.seedState) end
  --set the random generator to use the seeded generator
  random = function(...) return mapRandom:random(...) end
  --Basic initialization of empty map
  local build = Map(width,height)
  build.depth = depth
  --End initialization
  
  local levels = specialLevels.index[depth]
  local specialCreats = nil
  local forceLevel = gamesettings.force_special_levels[depth]
  if not forceLevel and force then forceLevel = force end --game will default to the game definition's force levels. But if the game definition has no forced level, then you can potentially pass in a forced level instead
  if levels and #levels > 0 and (forceLevel or random(1,2) == 1) and forceLevel ~="generic" then
    local id = get_random_element(levels)
    local l = specialLevels[id]
    if forceLevel and specialLevels[forceLevel] then -- if the game settings are forcing us to use a specific level for this level
      l = specialLevels[forceLevel]
      id = forceLevel
    elseif force and specialLevels[force] then
      l = specialLevels[force]
      id=force
    end
    specialCreats = l.creatures
    build.name = (l.generateName and l.generateName() or generate_cave_name())
    build.tileset = (l.tileset or 'cave')
    build.bossID = l.boss
    build.description = l.description
    build.levelID = id
    build.playlist = (l.playlist or id)
    build.bossPlaylist = (l.bossPlaylist or id .. "boss")
    build.lit = l.lit
    build.noCreats = l.noCreats
    build.id = forceLevel or force or id
    l.create(build,width,height)
  else --Generic level generation:
    build.id = "generic" .. depth
    if (depth == 11) then
      layouts['caves'](build,width,height)
      if levelModifiers['surface'](build) == false then return mapgen:generate_map(width, height, depth,force) end
      build.name = "The Surface"
    else --seriously generic level gen
      local mapType = random(1,3) -- 1: forest, 2: dungeon, 3: cave
      if (mapType == 1) then --forest
        build.playlist = "genericforest"
        build.bossPlaylist = "genericforestboss"
        local newMap = get_random_element({'connectednodes','cavemaze','caves','drunkwalker','noise'}) --forest can only be cave-looking layouts
        layouts[newMap](build,width,height)
        if newMap == "connectednodes" then
          mapgen:contourBomb(build)
        end
        build.tileset = "forest"
        build.name = namegen:generate_forest_name()
        build.description = namegen:generate_forest_description()
        --build.description = "Somehow, a small forest has sprouted up undergound. The fact that all these plants and trees are able to grow without the sun would be fascinating to a botanist, but you're not one, so you don't think much of it."
        if levelModifiers['forest'](build) == false then
          print('failed to do modifier, regening')
          currGame.seedState = mapRandom:getState()
          random = love.math.random
          return mapgen:generate_map(width, height, depth,force)
        end
      elseif mapType == 2 then  --dungeon
        build.playlist = "genericdungeon"
        build.bossPlaylist = "genericdungeonboss"
        local rooms,hallways = layouts['bsptree'](build,width,height) --"dungeon" only uses BSP tree
        build.tileset = "dungeon"
        build.name = namegen:generate_dungeon_name()
        build.description = namegen:generate_dungeon_description()
        if levelModifiers['dungeon'](build,rooms,hallways) == false then
          print('failed to do modifier, regening')
          currGame.seedState = mapRandom:getState()
          random = love.math.random
          return mapgen:generate_map(width, height, depth,force)
        end
      elseif mapType == 3 then --cave
        build.playlist = "genericcave"
        build.bossPlaylist = "genericcaveboss"
        local newMap = get_random_element({'connectednodes','cavemaze','caves','drunkwalker','noise'}) --"cave" can only be cave-looking layouts
        layouts[newMap](build,width,height)
        if newMap == "connectednodes" then
          mapgen:contourBomb(build)
        end
        build.tileset = "cave"
        build.name = namegen:generate_cave_name()
        build.description = namegen:generate_cave_description()
        if levelModifiers['cave'](build) == false then
          print('failed to do modifier, regening')
          currGame.seedState = mapRandom:getState()
          random = love.math.random
          return mapgen:generate_map(width, height, depth,force)
        end
      end --end forest vs. cave if
      --mapgen:addTombstones(build)
    end --end special modifiers if
    --Add the pathfinder:
    build:refresh_pathfinder()
  end --end generic level generation
  -- add stairs, if they're not already added
  if (build.stairsUp.x == 0 or build.stairsUp.y == 0 or build.stairsDown.x == 0 or build.stairsDown.y == 0) then
    --build.stairsUp = {x=5,y=5}
    --build.stairsDown = {x=10,y=10}
    print('making generic stairs! Why?',build.stairsUp.x,build.stairsUp.y,build.stairsDown.x,build.stairsDown.y)
    local s = mapgen:addGenericStairs(build,width,height,depth)
    if s == false then
      currGame.seedState = mapRandom:getState()
      random = love.math.random
      return mapgen:generate_map(width, height, depth,force)
    end
  end --end if stairs already exist
  if depth ~=11 then build[build.stairsUp.x][build.stairsUp.y] = "<" end
  build[build.stairsDown.x][build.stairsDown.y] = ">"
	
	-- add creatures:
	if not build.noCreats then
    local highest = math.max(width,height)
		for creat_amt=1,random(highest,highest),1 do
			local nc = mapgen:generate_creature(depth,specialCreats)
      if nc == false then break end
      local cx,cy = random(2,build.width-1),random(2,build.height-1)
      local tries = 0
      while (build:is_passable_for(cx,cy,nc.pathType) == false or build:tile_has_feature(cx,cy,'door') or build:tile_has_feature(cx,cy,'gate') or calc_distance(cx,cy,build.stairsDown.x,build.stairsDown.y) < 3) or build[cx][cy] == "<" do
        cx,cy = random(2,build.width-1),random(2,build.height-1)
        tries = tries+1
        if tries > 100 then break end
      end
      if tries ~= 100 then 
        if random(1,4) == 1 then nc:give_condition('asleep',random(10,100)) end
        build:add_creature(nc,cx,cy)
      end --end tries if
		end --end creature while
	end --end depth if
  currGame.seedState = mapRandom:getState()
  random = love.math.random
	return build
end

-- This initializes and creates a new creature at the given level, applying a class if necessary and returning the creature object
function mapgen:generate_creature(level,list,allowAll)
  --Prevent an infinite loop if there are no creatures on a given level:
  if not list then
    local noCreats = true
    for _,creat in pairs(possibleMonsters) do
      if creat.level == level then noCreats = false break end
    end
    if noCreats == true then return false end
  end
  
	-- This selects a random creature from the table of possible creatures, and compares the desired creature level to this creature's level. If it's a match, continue, otherwise select another one
	while (1 == 1) do -- endless loop, broken by the "return"
		local n = (list and get_random_element(list) or get_random_key(possibleMonsters))
		if (list or possibleMonsters[n].level == level) and possibleMonsters[n].isBoss ~= true and possibleMonsters[n].neverSpawn ~= true and (allowAll or list or possibleMonsters[n].specialOnly ~= true) then
			return Creature(n,level)
		end
	end
end

--Possible types: "wall": next to wall only, "noWalls": not next to wall, "wallsCorners": open walls and corners only, "corners": corners only
function mapgen:is_safe_to_block(map,startX,startY,safeType)
  local minX,minY,maxX,maxY=startX-1,startY-1,startX+1,startY+1
  local cardinals,corners = {},{}
  local cardinalWalls,cornerWalls = {},{}
  local n,s,e,w = false,false,false,false
  local walls = false
  if (startX == map.stairsUp.x and startY == map.stairsUp.y) or (startX == map.stairsDown.x and startY == map.stairsDown.y) or map[startX][startY] == "#" then return false end
  
  for x=minX,maxX,1 do
    for y=minY,maxY,1 do
      if startX == x and startY == y and not map:isClear(x,y) then return false end -- already blocked, so can't block again, obvs
      local door = map:tile_has_feature(x,y,'door')
      if (map:isClear(x,y) or door) and not (x== startX and y == startY) then
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

function mapgen:get_all_safe_to_block(map,room,openType)
  local safe = {}
  for _,floor in pairs(room.floors) do
    if self:is_safe_to_block(map,floor.x,floor.y,openType) then
      safe[#safe+1] = {x=floor.x,y=floor.y}
    end --end if
  end --end for
  return safe
end

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
          if map[x][y] ~= "." then
            tiles[#tiles+1] = {x=x,y=y}
            newTiles[#tiles+1] = {x=x,y=y}
          end --end checking if this one's been done before
          map[x][y] = "."
        end --end distance/border check
      end --end fory
    end --end forx
  end --end adding circles
end

--Unused Digger Shit
digger={}
digger.__index = digger

function digger:new(x,y,direction)
	newDigger = {x=x,y=y,direction=direction or random(1,4),line=random(3,10)}
	setmetatable(newDigger,digger)
	return newDigger
end

function digger:dig(map)
	-- first of all, if a digger is stuck in the open, nowhere to dig, teleport it to some random place
	while (map[self.x][self.y] == "." and map[self.x-1][self.y] == "." and map[self.x+1][self.y] == "." and map[self.x][self.y-1] == "." and map[self.x][self.y+1] == ".") do
		self.x = random(2,map.width-1)
		self.y = random(2,map.height-1)
	end
	
	if (self.x > 1 and self.x < map.width and self.y > 1 and self.y < map.height and map[self.x][self.y] == "#") then --not on a border, and don't replace stairs or whatever
		map[self.x][self.y] = "." -- dig!
	end
	self.line = self.line - 1
	
	while ((self.line == 0) or (self.x == 2 and self.direction == 4) or (self.x == map.width-1 and self.direction == 2) or (self.y == 2 and self.direction == 1) or (self.y == map.height-1 and self.direction == 3)) do
		self:turn()
	end
	
	--move!
	if (self.direction == 1) then
		self.y = self.y - 1
	elseif (self.direction == 2) then
		self.x = self.x + 1
	elseif (self.direction == 3) then
		self.y = self.y + 1
	elseif (self.direction == 4) then
		self.x = self.x - 1
	end
	
	if (map[self.x][self.y] == ".") then
		return false
	end
end

function digger:turn()
	self.direction = self.direction + random(-1,1) -- CLEVER?!
	if (self.direction == 5) then self.direction = 1 end
	if (self.direction == 0) then self.direction = 4 end
	self.line = random(3,10)
end