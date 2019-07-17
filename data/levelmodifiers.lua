require "mapgen"

levelModifiers = {}

local surface = function(map)
	for x = 1, map.width, 1 do
		for y=1, map.height, 1 do
			if (calc_distance(x,y,map.stairsDown.x,map.stairsDown.y) <= 3) then
				if ((math.abs(x-map.stairsDown.x) == 3 and y==map.stairsDown.y) or (math.abs(y-map.stairsDown.y) == 3 and x==map.stairsDown.x)) then
					map:add_feature(Feature('statue'),x,y)
					if (x ~= 1 and y ~= 1 and x ~= width and y ~= height) then
						map[x][y] = "."
					end
				end
			elseif (x == map.stairsUp.x and y == map.stairsUp.y) then
				map:add_feature(Feature('yourCorpse'),x,y)
			elseif (map[x][y] == "#") then
				map:add_feature(Feature('deepwater'),x,y)
				map[x][y] = "≈"
			else
				if (random(1,10) == 1) then
					map:add_feature(Feature('flower'),x,y)
				else
					map:add_feature(Feature('grass'),x,y)
				end
			end
		end
	end
end
levelModifiers['surface'] = surface

local forest = function(map)
  local floodFill = mapgen:floodFill(map,"#",1,1) --gets all walls connected to the border of the map
  local water = 0
  
  if random(1,3) == 1 then --Turn unconnected walls into lakes
    for x=2,map.width-1,1 do
      for y=2,map.height-1,1 do
        if (map[x][y] == "#" and floodFill[x][y] == nil) then
          --[[local neighbors = 0
          for ix=x-1,x+1,1 do
            for iy=y-1,y+1,1 do
              if (map[ix][iy] == "#" or map:tile_has_feature(ix,iy,'shallowwater')) then neighbors = neighbors+1 end
             end --end yfor
           end --end xfor
          if (neighbors == 9) then
            local f = Feature('deepwater')
            f.x,f.y = x,y
            map[x][y] = f
            water = water + 1
          elseif (neighbors > 2) then]]
            local f = Feature('shallowwater')
            f.x,f.y = x,y
            map[x][y] = f
            water = water + 1
          --end --end neighbors if
        end -- end if checking if it's an unconnectedwall
      end -- end fory
    end --end forx
  else --add lakes another way:
    if random(1,2) == 1 then --use noise function to add lakes
      local seed = random(0,10000)
      local xMod,yMod = random(1,20000),random(1,20000)
      for x=2,map.width-1,1 do
        for y=2,map.height-1,1 do
          if map[x][y] ~= "#" and love.math.noise((x+xMod)*.10,(y+yMod)*.10,seed) > .65 then
            map[x][y] = Feature('shallowwater',nil,x,y)
          end
        end --end fory
      end --end forx
    else -- add random blobby lakes
      local lakes = tweak(math.ceil(math.max(map.height/10,map.width/10)))
      for i=1,lakes,1 do
        local x,y = random(2,map.width-1),random(2,map.height-1)
        while map[x][y] == "#" do
          x,y = random(2,map.width-1),random(2,map.height-1)
        end
        local tiles = mapgen:make_blob(map,x,y,'shallowwater')
        --[[for _,t in pairs(tiles) do
          
        end]]
      end
    end
  end
  
  --Add a river
 mapgen:addRiver(map, 'shallowwater')
  
  --Add grass and trees
  for x=2,map.width-1,1 do
    for y=2,map.height-1,1 do
      --Turn empty space into grass:
      if (map[x][y] == "." and next(map.contents[x][y])== nil) then
        if(random(1,5) ~= 1) then
          local g = Feature('grass')
          g.x,g.y = x,y
          map[x][y] = g
        end --end grass if
        if random(1,7) == 1 then 
          if random(1,2) == 1 then
            map:add_feature(Feature('bush'),x,y)
          else
            map:add_feature(Feature('tree'),x,y)
          end --end bush vs tree if
        end --end bush/tree? if
      end --end check for empty space
    end --end fory
  end --end forx
  local s = mapgen:addGenericStairs(map,map.width,map.height,map.depth)
  if s == false then print('failed to do stairs, regening') return false end
end
levelModifiers['forest'] = forest

local cave = function(build)
  local width,height = build.width,build.height
  local hazardTypes = {"lava","chasm"}
  local hazardType = hazardTypes[random(#hazardTypes)]
  if hazardType == "lava" then
    build.description = build.description .. "\nThis area of the caverns feels much warmer than usual."
  elseif hazardType == "chasm" then
    build.description = build.description .. "\nYou can feel a heavy draft and hear the wind howl from somewhere nearby."
  elseif hazardType == "shallowwater" then
    build.description = build.description .. "\nThis area of the caverns feels more humid than usual."
  end --end hazard if
  local lakes = random(1,tweak(math.ceil(math.max(build.height/20,build.width/20))))
  for i=1,lakes,1 do
    local tries = 0
    local x,y = random(2,build.width-1),random(2,build.height-1)
    while build[x][y] == "#" and tries < 100 do
      x,y = random(2,build.width-1),random(2,build.height-1)
      tries = tries + 1
    end
    if tries < 100 then
      local tiles = mapgen:make_blob(build,x,y,hazardType)
      for _,t in pairs(tiles) do
        local feat = Feature(hazardType)
        feat.x,feat.y = x,y
        build[x][y] = feat
      end
    end
  end --end lake for
  mapgen:addRiver(build,hazardType)
  
  --Add random slime or spiderwebs
  local blobs = random(0,4)
  if blobs > 0 then
    local featureType = (random(1,2) == 1 and 'web' or "slime")
    for i=1,blobs,1 do
      local tries = 0
      local x,y = random(2,build.width-1),random(2,build.height-1)
      while build[x][y] ~= "." and tries < 100 do
        x,y = random(2,build.width-1),random(2,build.height-1)
        tries = tries+1
      end
      if tries < 100 then
        local tiles = mapgen:make_blob(build,x,y,false,25)
        for _,tile in pairs(tiles) do
          if not build:tile_has_feature(tile.x,tile.y,featureType) then
            local w = Feature(featureType)
            build:add_feature(w,tile.x,tile.y)
          end --end if not has feature
        end --end tile for
      end --end blobs for
    end
  end --end if blobs > 0
  
  --Add random blood stains:
  local blood = random(3,15)
  for i = 1,blood,1 do
    local tx,ty = random(2,width-1),random(2,height-1)
    local tries = 0
    while tries < 100 and not build:isEmpty(tx,ty,false,true) do
      tx,ty = random(2,width-1),random(2,height-1)
      tries = tries + 1
    end
    if build:isEmpty(tx,ty,false,true) then build:add_feature(Feature('chunk'),tx,ty) end
  end --end blood for
  
  --Add cave torches/crystals:
  local crystal = (random(1,4) == 1 and true or false)
  local torches = (crystal and random(0,5) or random(0,10))
  for i = 1,torches,1 do
    local tx,ty = random(2,width-1),random(2,height-1)
    local tries = 0
    while tries < 100 and not build:isClear(tx,ty) and not mapgen:is_safe_to_block(build,tx,ty) do
      tx,ty = random(2,width-1),random(2,height-1)
      tries = tries + 1
    end
    if build:isClear(tx,ty) and mapgen:is_safe_to_block(build,tx,ty) then build:add_feature(Feature((crystal and 'crystal' or 'plantedtorch')),tx,ty) end
  end --end torches for
  
  --Add a campfire:
  local fires = random(0,2)
  while fires > 0 do
    local cx,cy = random(2,width-1),random(2,height-1)
    
    local subtry = 0
    while not build:isEmpty(cx,cy,false,true) and subtry < 100 do
      cx,cy = random(2,width-1),random(2,height-1)
      subtry = subtry+1
    end
    if build:isEmpty(cx,cy,false,true) then
      fires = fires-1
      build:add_feature(Feature('campfire'),cx,cy)
      local creatID = nil
      for id,creat in pairs(possibleMonsters) do
        if creat.level == build.depth and not creat.isBoss and not creat.neverSpawn and not creat.specialOnly then
          creatID = id
          break
        end
      end --end creature for
      if creatID then
        local creats = random(2,5)
        local ctries = 0
        while creats > 0 and ctries < 10 do
          local x,y = random(cx-3,cx+3),random(cy-3,cy+3)
          if (x ~= cx or y ~= cy) and calc_distance(x,y,cx,cy) <= 3 and build:isClear(x,y) and build:is_line(x,y,cx,cy) then
            local c = Creature(creatID,build.depth)
            build:add_feature(Feature('bedroll'),x,y)
            build:add_creature(c,x,y)
            c:give_condition('asleep',random(10,100))
            creats = creats - 1
          end --end isclear if
          ctries = ctries+1
        end --end creats while
      end --end if creatID
    else
      break -- if you're unable to find a space for the fire in 100 tries, don't bother anymore
    end --end isempty if
  end --end campfire random
  
  --Add altars:
  if random(1,3) == 1 then
    local ax,ay = random(2,width-1),random(2,height-1)
    local tries = 0
    while tries < 100 and not build:isEmpty(ax,ay,false,true) and not mapgen:is_safe_to_block(build,ax,ay) do
      ax,ay = random(2,width-1),random(2,height-1)
      tries = tries+1
    end
    if build:isEmpty(ax,ay,false,true) and mapgen:is_safe_to_block(build,ax,ay) then
      build:add_feature(Feature('altar',{godName=true}),ax,ay)
    end
  end
  
  --Add spikes:
   if random(1,4) == 1 then
    local spikes = random(1,10)
    for i = 1,spikes,1 do
      local tx,ty = random(2,width-1),random(2,height-1)
      local tries = 0
      while tries < 100 and not build:isClear(tx,ty) do
        tx,ty = random(2,width-1),random(2,height-1)
        tries = tries + 1
      end
      if build:isClear(tx,ty) then build:add_feature(Feature('gorespike'),tx,ty) end
    end --end spikes for
  end --end random spikes if
  
  local s = mapgen:addGenericStairs(build,width,height,build.depth)
  if s == false then print('failed to do stairs, regening') return false end
  --Add a sign:
  local sx,sy = random(build.stairsDown.x-5,build.stairsDown.x+5),random(build.stairsDown.y-5,build.stairsDown.y+5)
  local tries = 0
  while tries < 100 and not build:isClear(sx,sy) do
    sx,sy = random(build.stairsDown.x-5,build.stairsDown.x+5),random(build.stairsDown.y-5,build.stairsDown.y+5)
    tries = tries+1
  end
  if build:isClear(sx,sy) then build:add_feature(Feature('sign'),sx,sy) end
  
  --Add lava bubbles if necessary:
  if hazardType == "lava" then
    for i=1,3,1 do
      local x,y = random(2,width-1),random(2,height-1)
      while not build:tile_has_feature(x,y,'lava') and not build:get_tile_creature(x,y) do
        x,y = random(2,width-1),random(2,height-1)
      end --end while
      build:add_effect(Effect('lavabubble'),x,y)
    end --end eye count
  end --end lava if
end
levelModifiers['cave'] = cave

local dungeon = function(build,rooms,hallways)
  local width,height = build.width,build.height
  for id, room in ipairs(rooms) do
    if not room.exit and not room.entrance and random(1,3) == 1 then
      decorate_room(room,build)
    end
  end
  local hazardType = (random(1,2) == 1 and "lava" or "chasm")
  if hazardType == "lava" then
    build.description = build.description .. "\nThis area of the dungeon feels much warmer than usual."
  elseif hazardType == "chasm" then
    build.description = build.description .. "\nYou can feel a heavy draft and hear the wind howl from somewhere nearby."
  end --end river if
  mapgen:addRiver(build,hazardType)
  
  --Add some wall torches:
  for i=1,10,1 do
    local x,y = random(2,width-1),random(2,height-1)
    local placed = false
    while placed == false do
      x,y = random(2,width-1),random(2,height-1)
      if build[x][y] == "#" and build[x][y+1] == "." then
        placed = true
      elseif build[x][y] == "#" and build[x+1][y] == "." then
        x=x+1
        placed = true
      elseif build[x][y] == "#" and build[x-1][y] == "." then
        x=x-1
        placed = true
      end
    end
    local torch = Feature('walltorch')
    build:add_feature(torch,x,y)
  end
end
levelModifiers['dungeon'] = dungeon