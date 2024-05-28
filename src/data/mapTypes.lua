mapTypes = {}

--noBranchItems, noBranchCreatures, and noBranchContent

local forest = {
  playlist = "genericforest",
  bossPlaylist = "genericforestboss",
  layouts = {'connectednodes','cavemaze','caves','drunkwalker','noise'},
  modifiers = {'forest'},
  tags = {'natural','plants'},
  tileset = "forest",
  nameType = "forest",
  descType = "forest"
}
mapTypes['forest'] = forest

local dungeon = {
  playlist = "genericdungeon",
  bossPlaylist = "genericdungeonboss",
  nameType = "dungeon",
  descType = "dungeon",
  tileset="dungeon",
  tags={'dungeon'}
}
function dungeon.create(map,width,height)
  local rooms,hallways = layouts['bsptree'](map,width,height)
  if mapModifiers['dungeon'](map,rooms,hallways) == false then
    print('failed to do dungeon modifier, regening')
    return false
  end
end
mapTypes['dungeon'] = dungeon

local caves = {
  playlist = "genericcave",
  bossPlaylist = "genericcaveboss",
  layouts = {'connectednodes','cavemaze','caves','drunkwalker','noise'},
  modifiers = {'cave'},
  tags = {'natural'},
  tileset="cave",
  nameType = "cave",
  descType = "cave"
}
mapTypes['caves'] = caves

local lavacave = {
  playlist = "genericcave",
  bossPlaylist = "genericcaveboss",
  layouts = {'connectednodes','cavemaze','caves','drunkwalker','noise'},
  modifiers = {'cave'},
  tags = {'natural','fire'},
  modifier_arguments = {cave={'lava'}},
  tileset="cave",
  nameType = "cave",
  descType = "cave"
}
mapTypes['lavacave'] = lavacave

local town = {
  nameType = "town",
  tileset = "village",
  description = "A quaint village that for some reason has a staircase in the middle leading into an underground dungeon complex.",
  width=25,
  height=25,
  noItems=true, --If true, no items will generate on this level
  noExits=true, --If true, the automatic code to generate exits won't run on this level. You should manually put in exits in the create() code or something, or the player will get stuck
  noBoss=true, --If true, the game will not attempt to generate a boss when the player leaves this map
  lit=true, --If true, the entire level will count as lit. Perception distance won't matter
  creature_density=10, --How many creatures should be generated per 100 tiles
  event_chance=100, --Likelihood that a non-faction random event will occur. Overrides the event_chance values in gamesettings and in the branch
  event_cooldown=100, --Turns that must pass between ranodm events. Overrides the event_cooldown values in gamesettings and in the branch
  forbid_faction_events=true, --If true, faction events won't occur on this map
  start_revealed=true, --If true, reveal the entire map when it's entered (LOS will still apply, so you can't necessarily actively see everything)
}
function town.create(map,width,height)
  width,height = map.width,map.height
  map:clear(true)
  
  --Add stairs in the middle:
  local midX, midY = round(width/2),round(height/2)
  local stairs = Feature('exit',{branch="main",exitName="Stairway"})
  map:change_tile(stairs,midX,midY)
  map.stairsUp.x,map.stairsUp.y = midX,midY
  map.stairsDown.x,map.stairsDown.y = midX,midY
  map:add_feature(Feature('statue'),midX-1,midY-1)
  map:add_feature(Feature('statue'),midX+1,midY-1)
  map:add_feature(Feature('statue'),midX-1,midY+1)
  map:add_feature(Feature('statue'),midX+1,midY+1)
  
  --Add gates to the wilderness:
  local gatesw = Feature('exit',{branch="wilderness",exitName="Gate"})
  map:change_tile(gatesw,midX,height-1)
  --Add gates to the graveyard:
  local gatesc = Feature('exit',{branch="graveyard",exitName="Gate"})
  map:change_tile(gatesc,midX,2)
  
  local guard = map:add_creature(Creature('townguard'),5,5)
  guard.guard_point = {x=2,y=2}
  local guard2 = map:add_creature(Creature('townguard'),6,6)
  guard2.patrol_points = {{x=3,y=3},{x=3,y=7},{x=7,y=7},{x=7,y=3}}
  
  --Add spawn points to corners (silly, but demonstrates the use of spawn points)
  map.spawn_points = {{x=2,y=2},{x=width-1,y=2},{x=2,y=height-1},{x=width-1,y=height-1}}
end
function town.check_building_footprint(ix,iy,map) --This is not a "normal" function for mapTypes, this is special to this one, called in its custom populate_factions and populate_stores code
  local midX, midY = round(map.width/2),round(map.height/2)
  for x=ix-3,ix+3,1 do
    for y=iy-3,iy+3,1 do
      if map[x][y] ~= "." or (x > midX-2 and x < midX+2 and y>midY-2 and y<midY-2) then
        return false
      end
    end
  end
  return true
end
function town.populate_factions(map)
  local midX, midY = round(map.width/2),round(map.height/2)
  local newFacs = {}
  for _,fac in pairs(map:get_faction_list()) do
    if not fac.hidden and not fac.no_hq then
      local hq = Feature('factionHQ',fac)
      local tries = 0
      local ix,iy = random(4,map.width-3),random(5,map.height-5)
      while (town.check_building_footprint(ix,iy,map) == false) do
        ix,iy = random(4,map.width-3),random(5,map.height-5)
        tries = tries+1
        if tries > 100 then break end
      end
      if tries ~= 100 then
        local xDiff,yDiff = math.abs(ix-midX),math.abs(iy-midY)
        for x=ix-1,ix+1,1 do
          for y=iy-1,iy+1,1 do
            map[x][y] = "#"
          end
        end
        if xDiff > yDiff then
          map[(ix < midX and ix+1 or ix-1)][iy] = "."
          map:add_feature(hq,(ix < midX and ix+1 or ix-1),iy)
        else
          map[ix][(iy < midY and iy+1 or iy-1)] = "."
          map:add_feature(hq,ix,(iy < midY and iy+1 or iy-1))
        end
        newFacs[#newFacs+1] = hq
      end --end tries if
    end
  end
  return newFacs
end
function town.populate_stores(map)
  local midX, midY = round(map.width/2),round(map.height/2)
  local newStores = {}
  for _,store in pairs(map:get_store_list()) do
    local s = Feature('store',store)
    if not s.store.faction then s.store.faction = "village" end
    local tries = 0
    local ix,iy = random(4,map.width-3),random(4,map.height-3)
    while (town.check_building_footprint(ix,iy,map) == false) do
      ix,iy = random(4,map.width-3),random(4,map.height-3)
      tries = tries+1
      if tries > 100 then break end
    end
    if tries ~= 100 then 
      local xDiff,yDiff = math.abs(ix-midX),math.abs(iy-midY)
        for x=ix-1,ix+1,1 do
          for y=iy-1,iy+1,1 do
            map[x][y] = "#"
          end
        end
        if xDiff > yDiff then
          map[(ix < midX and ix+1 or ix-1)][iy] = "."
          map:add_feature(s,(ix < midX and ix+1 or ix-1),iy)
        else
          map[ix][(iy < midY and iy+1 or iy-1)] = "."
          map:add_feature(s,ix,(iy < midY and iy+1 or iy-1))
        end
      newStores[#newStores+1] = s
    end --end tries if
  end
  return newStores
end
mapTypes['town'] = town

local demonruins = {
  playlist = "genericcave",
  bossPlaylist = "genericcaveboss",
  tileset="dungeon",
  description="This city was once home to powerful sorcerers who sought to open a gateway to the Nether Regions in order to summon demons. They were successful.",
  tags={'fire','demon','unholy'}
}
function demonruins.generateName()
  local cityname = namegen:generate_demon_name()-- .. (random(1,10) == 1 and phonemes[num] or "")
  local adjectives = {"Abandoned","Ancient","Awful","Bloody","Burned","Damned","Dark","Deadly","Demon","Demonic","Devilish","Doomed","Dread","Dim","Evil","Forbidden","Forgotten","Horrible","Lost","Ruined","Shadowed","Twisted"}
  local sayCity = (random(1,3) == 1 and true or false)
  return (sayCity and "The " or "") .. adjectives[random(#adjectives)] .. " " .. (sayCity and "City " .. (random(1,3) and "of " or "") or "") .. cityname
end
function demonruins.create(map,width,height)
  local rooms,hallways = layouts['bsptree'](map,width,height,75)
  --put pits in the empty space:
  for x = 2, width-1, 1 do
		for y=2, height-1, 1 do
      if map[x][y] ~= "." then map[x][y] = "p" end
    end
  end
  
  --Find the boss room:
  local biggestSize = 0
  local biggestRoom = nil
  for id, room in ipairs(rooms) do
    local roomH = room.maxY-room.minY
    local roomW = room.maxX-room.minX
    if (roomW > 10 and roomH > 10) and (roomW % 2==0 and roomW % 2==0) and (roomH*roomW) > biggestSize then
      biggestSize = roomW*roomH
      biggestRoom = id
    end
  end --end room for
  --If no bossroom, regen map
  if not biggestRoom then map:clear() return demonruins.create(map,width,height) end
  
  local bossRoom = rooms[biggestRoom]
  
  --set farthest room from boss room to be the entry room:
  local farthestDist,farthestRoom = 0,nil
  for _, room in ipairs(rooms) do
    local dist = calc_distance_squared(room.minX,room.minY,bossRoom.minX,bossRoom.minY) --use squared one for speed since the actual distance isn't important, only as a comparison to other rooms
    if dist > farthestDist then
      farthestDist = dist
      farthestRoom = room
    end
  end
  rooms.entrance.entrance = nil
  rooms.entrance = farthestRoom
  farthestRoom.entrance = true
  local downX,downY = (farthestRoom.maxX-farthestRoom.minX)/2,(farthestRoom.maxY-farthestRoom.minY)/2
  map.stairsDown.x,map.stairsDown.y = farthestRoom.minX+(random(1,2) == 1 and math.ceil(downX) or math.floor(downX)), farthestRoom.minY+(random(1,2) == 1 and math.ceil(downY) or math.floor(downY))
  map:clear_tile(map.stairsDown.x,map.stairsDown.y)
  
  for id, room in ipairs(rooms) do
    --Handle boss room:
    local doorCount = 0
    if id == biggestRoom then
      for x=room.minX,room.maxX,1 do
        for y=room.minY,room.maxY,1 do
          if x==room.minX or x==room.maxX or y==room.minY or y==room.maxY then
            map[x][y] = "#"
            map:clear_tile(x,y)
          else
            map:clear_tile(x,y)
            map:change_tile(Feature('brokentiles'),x,y)
          end
        end --end forx
      end --end fory
      for doorID, door in ipairs(room.doors) do
        if (door.x == room.minX or door.x == room.maxX) and (door.y == room.minY or door.y == room.maxY) then
          map:change_tile(Feature('brokentiles'),door.x,door.y)
          local door = map:add_feature(Feature('door'),door.x,door.y)
          door.playerOnly = true
          doorCount = doorCount+1
        else
          table.remove(room.doors,doorID)
        end
      end
      while doorCount == 0 do
        --add more doors
        local randDoors = random(1,4)
        local sides = {"minX","maxX","minY","maxY"}
        for i = 1,randDoors,1 do
          local whichSide = get_random_element(sides)
          local x = ((whichSide == "minX" or whichSide == "maxX") and room[whichSide] or random(room.minX+1,room.maxX-1))
          local y = ((whichSide == "minY" or whichSide == "maxY") and room[whichSide] or random(room.minY+1,room.maxY-1))
          if map[x][y] == "#" and ((whichSide == "minX" and map[x-1][y] == ".") or (whichSide == "maxX" and map[x+1][y] == ".") or (whichSide == "minY" and map[x][y-1] == ".") or (whichSide == "maxY" and map[x][y+1] == ".")) then
            map:change_tile(Feature('brokentiles'),x,y)
            local door = map:add_feature(Feature('door'),x,y)
            door.playerOnly = true
            doorCount = doorCount + 1
          end --end if map == "#"
        end -- end door for
      end --end door count if
      local midX,midY = math.ceil((room.maxX+room.minX)/2),math.ceil((room.maxY+room.minY)/2)
      for x=midX-1,midX+1,1 do
        for y=midY-1,midY+1,1 do
          map:add_feature(Feature('giantpentagram'),x,y)
        end
      end
      map.stairsUp.x,map.stairsUp.y = midX,midY
      map[midX][midY] = "<"
      map:add_feature(Feature('candles'),midX-1,midY-2)
      map:add_feature(Feature('candles'),midX+1,midY-2)
      map:add_feature(Feature('candles'),midX-2,midY)
      map:add_feature(Feature('candles'),midX+2,midY)
      map:add_feature(Feature('candles'),midX,midY+2)
      --Add pews:
      for x = room.minX,room.maxX,1 do
        if (midX-x)%2 == 0 and math.abs(midX-x) >= 4 then
          for y = midY-2,midY+2,1 do
            if mapgen:is_safe_to_block(map,x,y) then
              local sitter = Feature("pew")
              map:add_feature(sitter,x,y)
              sitter.image_name = "pew" .. (sitter.x > midX and "e" or "w")
            end --end isClear if
          end -- end fory
        end --end if x is right
      end --end forx
      for y = room.minY,room.maxY,1 do
        if (midY-y)%2 == 0 and math.abs(midY-y) >= 4 then
          for x = midX-2,midX+2,1 do
            if mapgen:is_safe_to_block(map,x,y) then
              local sitter = Feature("pew")
              map:add_feature(sitter,x,y)
              sitter.image_name = "pew" .. (sitter.y > midY and "s" or "n")
            end --end isClear if
          end -- end fory
        end --end if x is right
      end --end forx
    else
      --put the walls back in the rooms:
      for _, wall in pairs(room.walls) do
        if map[wall.x][wall.y] ~= "." then
          if random(1,10) ~= 1 then
            map[wall.x][wall.y] = "#"
          elseif random(1,3) == 1 then
            map[wall.x][wall.y] = Feature('brokenwall',nil,wall.x,wall.y)
          --else
            map[wall.x][wall.y] = "b"
          end
        end --end wall if
      end --end wall for
      
      --Add decorations to rooms:
      local safeTiles = mapgen:get_all_safe_to_block(map,room)
      local wallTiles = mapgen:get_all_safe_to_block(map,room,"wallsCorners")
      local cornerTiles = mapgen:get_all_safe_to_block(map,room,"corners")
      local openTiles = mapgen:get_all_safe_to_block(map,room,"noWalls")
      --Add random gore:
      local gore = random(-3,math.ceil(count(safeTiles)/5))
      local goreTries = 0
      while gore > 0 and goreTries < 100 do
        goreTries = goreTries+1
        local tile = get_random_element(safeTiles)
        if not map:tile_has_feature(tile.x,tile.y,'chunk') then
          map:add_feature(Feature('chunk'),tile.x,tile.y)
          gore = gore -1
        end --end chunk if
      end --end gore while
    
      --Add furniture based on random room type
      if not room.entrance then
        local roomType = random(1,5)
        if roomType == 1 then --lab
          local bookshelves = random(0,4)
          for i=1,bookshelves,1 do
            local tile = get_random_element(wallTiles)
            if tile and mapgen:is_safe_to_block(map,tile.x,tile.y) then
              map:add_feature(Feature('bookshelf'),tile.x,tile.y)
            end --end tile if
          end --end bookshelves for
          local cages = random(0,2)
          for i=1,cages,1 do
            local tile = get_random_element(safeTiles)
            if tile then
              if mapgen:is_safe_to_block(map,tile.x,tile.y) then
                local cage = Feature('cage')
                local cageType = random(1,5)
                if cageType == 3 then
                  cage.image_name = "cage_broken"
                elseif cageType == 4 then
                  cage.image_name = "cage_skeleton"
                elseif cageType == 5 then
                  cage = Feature('torturedevice')
                end
                map:add_feature(cage,tile.x,tile.y)
              end --end isClear if
            end --end tile if
          end --end cage for
          --Add tables?
          local tries=1
          local tableStart = nil
          local tableTiles = {}
          while tries<10 do
            tableStart = get_random_element(wallTiles)
            if not tableStart then break end
            for x = tableStart.x,tableStart.x+random(1,3),1 do
              if mapgen:is_safe_to_block(map,x,tableStart.y,'wallsCorners') then
                if x~=tableStart.x then tableTiles[#tableTiles+1] = {x=x,y=tableStart.y} end
              else
                break
              end --end safe to block
            end --end + forx
            for x = tableStart.x,tableStart.x-random(1,3),-1 do
              if mapgen:is_safe_to_block(map,x,tableStart.y,'wallsCorners') then
                if x~=tableStart.x then tableTiles[#tableTiles+1] = {x=x,y=tableStart.y} end
              else
                break
              end --end safe to block
            end --end - forx
            --Y-table:
            if count(tableTiles) > 3 then
              break
            end
            for y = tableStart.y,tableStart.y+random(1,3),1 do
              if mapgen:is_safe_to_block(map,tableStart.x,y,'wallsCorners') then
                if y~=tableStart.y then tableTiles[#tableTiles+1] = {x=tableStart.x,y=y} end
              else
                break
              end --end safe to block
            end --end + fory
            for y = tableStart.y,tableStart.y-random(1,3),-1 do
              if mapgen:is_safe_to_block(map,tableStart.x,y,'wallsCorners') then
                if y~=tableStart.y then tableTiles[#tableTiles+1] = {x=tableStart.x,y=y} end
              else
                break
              end --end safe to block
            end --end - fory
            if count(tableTiles) > 3 then
              break
            end
            tries = tries+1
          end --end tries while
          if tableStart then
            local t = Feature('stonetable')
            local decoration = "gore"
            map:add_feature(t,tableStart.x,tableStart.y)
            t.image_name = "stonetable_" ..decoration
            for _,tile in pairs(tableTiles) do
              local t = Feature('stonetable')
              map:add_feature(t,tile.x,tile.y)
              t.image_name = "stonetable_" ..decoration
            end --end tile for
          end --end tablestart if
        elseif roomType == 2 then -- temple
          map:add_feature(Feature('altar',{decoration={"blood"},godName="demon",godAdjectiveChance=25,noGodTitle=true}),room.midX,room.midY)
        elseif roomType == 3 then --home
          local bedTile = get_random_key(cornerTiles)
          if bedTile then
            map:add_feature(Feature('bed'),cornerTiles[bedTile].x,cornerTiles[bedTile].y)
            table.remove(cornerTiles,bedTile)
          end
          local chestTile = get_random_key(wallTiles)
          if chestTile then
            map:add_feature(Feature('chest'),wallTiles[chestTile].x,wallTiles[chestTile].y)
            table.remove(wallTiles,chestTile)
          end
        elseif roomType == 4 then -- open area
          room.outdoors = true
          for _,wall in pairs(room.walls) do
            map[wall.x][wall.y] = "."
            local door = map:tile_has_feature(wall.x,wall.y,'door')
            if door then
               door:delete(map)
            end --end door if
          end --end wall for
          for i = 1,random(2,6),1 do
            local stick = get_random_element(safeTiles)
            if not map:tile_has_feature(stick.x,stick.y,'gorespike') then
              map:add_feature(Feature('gorespike'),stick.x,stick.y)
            end
          end
        end --end roomType if
      end --end if not entrance
      
      
      --Add broken tiles to non-outdoor rooms
      if not room.outdoors then
        for _,floor in pairs(room.floors) do
          map:change_tile(Feature('brokentiles'),floor.x,floor.y)
        end
        for _,wall in pairs(room.walls) do
          if map[wall.x][wall.y] == "." then
            map:change_tile(Feature('brokentiles'),wall.x,wall.y)
          end --end blank floor if
        end --end wall for
      end --end if not outdoors
      --All room types might get random decorations:
      local miscDecorations = math.ceil(#safeTiles/20)
      local tries = 0
      while miscDecorations > 0 and tries < 100 do
        tries = tries + 1
        local placeX,placeY = random(room.minX+1,room.maxX-1),random(room.minY+1,room.maxY-1)
        if mapgen:is_safe_to_block(map,placeX,placeY) then
          miscDecorations = miscDecorations - 1
          local decType = random(1,3)
          if decType == 1 then
            map:add_feature(Feature('pentagram'),placeX,placeY)
          elseif decType == 2 then
            map:add_feature(Feature('skullcandle'),placeX,placeY)
          elseif decType == 3 then
            map:add_feature(Feature('candelabra'),placeX,placeY)
          end --end decType if
        end --end isclear if
      end --end decorations while
    end --end bossroom/regular if
  end --end rooms for
  --look at all hallways to see if they intersect boss room, and put doors in if so
  for _,hallway in pairs(hallways) do
    local doneAlready = false
    for _,tile in pairs(hallway.base) do
      if not doneAlready and (((tile.x == bossRoom.minX or tile.x == bossRoom.maxX) and tile.y > bossRoom.minY and tile.y < bossRoom.maxY) or ((tile.y == bossRoom.minY or tile.y == bossRoom.maxY) and tile.x > bossRoom.minX and tile.x < bossRoom.maxX)) then
        if map[tile.x][tile.y] == "#" then
          local makeDoor = true
          --check neighbors to make sure you're not putting a door next to a door bc that's ridiculous
          for testX = tile.x-1,tile.x+1,1 do
            for testY = tile.y-1,tile.y+1,1 do
              if map:tile_has_feature(testX,testY,'door') then
                makeDoor = false
              end --end door test if
            end --end testy if
          end --end testx if
          if makeDoor then
            local door = map:add_feature(Feature('door'),tile.x,tile.y)
            door.playerOnly = true
            map[tile.x][tile.y] = "."
            doneAlready = true
          end --end makeDoor if
        end --end map == "#" if
      end --end tile in room if
    end --end tile for
  end --end hallway for
  
  --Put in the lava:
  for x=2,width-1,1 do
    for y=2,height-1,1 do
      if map[x][y] == "p" then
        map:change_tile(Feature('lava',nil,x,y),x,y)
      elseif map[x][y] == "b" then -- broken wall
        map[x][y] = (random(1,2) == 1 and "." or Feature('lava',nil,x,y))
        for nx=x-1,x+1,1 do --make the nearby walls broken
          for ny=y-1,y+1,1 do
            if nx > 1 and ny > 1 and nx < map.width and ny < map.height and (nx == x or ny == y) and map[nx][ny] == "#" then map[nx][ny] = Feature('brokenwall',nil,nx,ny) end --make it a broken wall
          end -- end for ny
        end --end for nx
      end --end if p or b check
    end --end forx
  end --end fory
  mapgen:makeEdges(map,width,height,"lava") --make the edges interesting
  
  --Add bubbles:
  for i=1,6,1 do
    local x,y = random(2,width-1),random(2,height-1)
    while not map:tile_has_feature(x,y,'lava') and not map:get_tile_creature(x,y) do
      x,y = random(2,width-1),random(2,height-1)
    end --end while
    map:add_effect(Effect('lavabubble'),x,y)
  end --end eye count
  
  --Add idols:
  local idols = 10
  local actualIdols = 0
  while idols > 0 do
    local room = get_random_element(rooms)
    local tries = 0
    while room.entrance or room.exit or (tries < 10 and room.idoled) do
      room = get_random_element(rooms)
      tries = tries + 1
    end
    --[[local idolX,idolY = random(2,width-1),random(2,height-1)
    while map[idolX][idolY] == "#" or map:tile_has_feature(idolX,idolY,"lava") or not map:isClear(idolX,idolY) or not mapgen:is_safe_to_block(map,idolX,idolY) or (idolX > bossRoom.minX and idolX < bossRoom.maxX and idolY > bossRoom.minY and idolY < bossRoom.maxY) or map[idolX][idolY+1] == "#" or map:tile_has_feature(idolX,idolY+1,"lava") or not map:isClear(idolX,idolY+1) do
      idolX,idolY = random(2,width-1),random(2,height-1)
    end --end idol safety check]]
    local tile = get_random_element(room.floors)
    local idolX,idolY = tile.x,tile.y
    tries = 0
    local makeIdol = true
    while map[idolX][idolY] == "#" or map:tile_has_feature(idolX,idolY,"lava") or not map:isClear(idolX,idolY) or not mapgen:is_safe_to_block(map,idolX,idolY) or (idolX > bossRoom.minX and idolX < bossRoom.maxX and idolY > bossRoom.minY and idolY < bossRoom.maxY) or map[idolX][idolY+1] == "#" or map:tile_has_feature(idolX,idolY+1,"lava") or not map:isClear(idolX,idolY+1) do
      tile = get_random_element(room.floors)
      idolX,idolY = tile.x,tile.y
      tries = tries + 1
      if tries == 50 then makeIdol = false break end
    end
    if makeIdol then
      room.idoled = true
      map:add_feature(Feature('idol'),idolX,idolY)
      map:add_feature(Feature('pentagram'),idolX,idolY+1)
      map:add_feature(Feature('chunk'),idolX,idolY+1)
      idols = idols-1
      actualIdols = actualIdols+1
    end
  end --end while idols > 0
  map.idolCount = actualIdols
  map.bossRoom = bossRoom
end --end function
mapTypes['demonruins'] = demonruins

local swamp = {
  tileset = "swamp",
  description="Swamps are generally disgusting and dangerous places. Underground swamps, doubly so.",
  tags={'natural','plants','water','swamp','poison'},
  passedTags={'natural','plants','water','poison'},
  creatures = {'dragonfly','mosquito','shroomman'},
  creatureTypes = {'bug'},
  creatureTags = {'plants','swamp','poison','bug'},
}
function swamp.create(map,width,height)
  layouts['caves'](map,width,height,40)
  local seed = random(0,10000)
  local xMod,yMod = random(1,20000),random(1,20000)
  for x=2,map.width-1,1 do
    for y=2,map.height-1,1 do
      --Add random trees:
      if (map[x][y] == "." and next(map.contents[x][y])== nil) then
        if(random(1,10) == 1) then
          map:add_feature((random(1,2) == 1 and Feature('tree') or Feature('mushroom')),x,y)
        end
      end --end check for empty space
      --Add swmap water:
      if map[x][y] == "." and love.math.noise((x+xMod)*.10,(y+yMod)*.10,seed) > .5 then
        map:change_tile(Feature('swampwater',nil,x,y),x,y)
      end
    end --end fory
  end --end forx
  
  --Add torches
  local torches = 10
  for i = 1,torches,1 do
    local tx,ty = random(2,width-1),random(2,height-1)
    local tries = 0
    while tries < 100 and not map:isClear(tx,ty) do
      tx,ty = random(2,width-1),random(2,height-1)
      tries = tries + 1
    end
    map:add_feature(Feature('plantedtorch'),tx,ty)
  end
end --end swamp generate
function swamp.generateName()
  local adjectives = {"Dark","Forbidden","Deadly","Depressing","Smelly","Forboding","Lush","Overgrown","Forgotten","Fragrant"}
  local swampnames = {"Swamp","Mire","Sludge","Murk","Quagmire","Bog","Marsh","Swampland","Heart","Mud","Stench","Stink","Slime"}
  local titles = {"Horror","Darkness","Madness","Torment","Sadness","Disease","Magic","Death","The Lost","The Grave","Decay","Love","Happiness"}
  return "The " .. (random(1,2) == 1 and (adjectives[random(#adjectives)] .. " " .. swampnames[random(#swampnames)]) or (swampnames[random(#swampnames)] .. " of " .. titles[random(#titles)]))
end
mapTypes['swamp'] = swamp

local graveyard = {
  tileset = "graveyard",
  description="Sometimes the dead don't stay buried.",
  tags={'undead','unholy','necromancy','surface'},
  passedTags={'undead','unholy','necromancy','poison'},
  creatureTypes = {'undead'},
  creatures = {'demonhunter'},
  creatureTags = {'undead','necromancy'},
  lit=true
}
function graveyard.create(map,width,height)
  layouts['noise'](map,width,height)
  --Stair fun:
  map:refresh_pathfinder()
  local s = mapgen:addGenericStairs(map,width,height,1)
  if s == false then return graveyard.create(map,width,height) end
  for x=map.stairsDown.x-1,map.stairsDown.x+1,1 do
    for y=map.stairsDown.y-1,map.stairsDown.y+1,1 do
      if x~=map.stairsDown.x and y~=map.stairsDown.y or map[x][y] == "#" then
        map[x][y] = "#"
        map:add_feature(Feature('brickwall'),x,y)
      else -- in a + shape from the center
        --Put walls in if the tile borders a wall:
        local wall = false
        if x==map.stairsUp.x-1 and map[x-1][y] == "#" then
          wall = true
        elseif x==map.stairsUp.x+1 and map[x+1][y] == "#" then
          wall = true
        elseif y==map.stairsUp.y-1 and map[x][y-1] == "#" then
          wall = true
        elseif y==map.stairsUp.y+1 and map[x][y+1] == "#" then
          wall = true
        end
        
        if wall then
          map[x][y] = "#"
          map:add_feature(Feature('brickwall'),x,y)
        else --For the remaining empty space:
          local tile = Feature('brokentiles')
          tile.fancy = true
          map:change_tile(tile,x,y)
          map:add_feature(Feature('bossactivator'),x,y)
          if (y~= map.stairsUp.y or x ~= map.stairsUp.x) then 
            local gate = map:add_feature(Feature('gate'),x,y)
            gate.playerOnly = true
          end
        end --end wall if
      end --end cross shape if
    end --end fory
  end --end forx
  
  --Decorations!
  --Add trees:
  for i=1,random(10,15),1 do
    local x,y = random(2,map.width-1),random(2,map.height-1)
    while (map:isEmpty(x,y,false,true) == false) do
      x,y = random(2,map.width-1),random(2,map.height-1)
    end
    local t = Feature('deadtree')
    t.image_name = "eldritchtree" .. random(1,4)
    t.description = "You're pretty sure this dead, twisted thing was once a tree.\nRelatively sure.\nYou hope it was a tree."
    map:add_feature(t,x,y)
  end --end for
  
  --Add gravestones:
  local min = math.ceil(math.max(map.width,map.height)/5)
  for i=1,random(min,min+5),1 do
    local x,y = random(2,map.width-1),random(2,map.height-1)
    while y % 3 ~= 0 or (map:isClear(x,y) == false or map[x][y] ~= ".") or (map:isClear(x,y+1) == false or map[x][y+1] ~= ".") or map:tile_has_feature(x,y,'gravestone') or map:tile_has_feature(x,y,'grave') --[[ or map:tile_has_feature(x,y+1,'gravestone') or map:tile_has_feature(x,y+1,'grave')]] do
      x,y = random(2,map.width-1),random(2,map.height-1)
    end
    local size = random(2,math.ceil(min/2))
    for x2 = x-size,x+size,1 do
      if map:in_map(x2,y) and map:in_map(x2,y+1) and random(1,4) ~= 1 and map[x2][y] == "." and map:isClear(x2,y) and map[x2][y+1] == "." and map:isClear(x2,y+1)  and not map:tile_has_feature(x2,y,'gravestone') and not map:tile_has_feature(x2,y,'grave') --[[and not map:tile_has_feature(x2,y+1,'gravestone') and not map:tile_has_feature(x2,y+1,'grave')]] then
        map:add_feature(Feature('gravestone'),x2,y)
        local grave = Feature('grave')
        map:add_feature(grave,x2,y+1)
        if random(1,8) == 1 then
          local graveshaker = Effect('graveshaker')
          graveshaker.grave = grave
          map:add_effect(graveshaker,x2,y+1)
        end
      end
    end
  end --end for
  
  --Check for connectivity:
  map:refresh_pathfinder()
  local p = map:findPath(map.stairsDown.x,map.stairsDown.y,map.stairsUp.x,map.stairsUp.y)
  if (p == false) then
    print("No path to stairs!")
    mapgen:clear_map(map)
    return graveyard.create(map,width,height)
  end
end --end function
mapTypes['graveyard'] = graveyard

local mausoleum = {
  tileset = "mausoleum",
  description="You shiver in the still, damp air. A slight smell of rot permeates this place.",
  tags={'undead','necromancy','unhoy','vampire','indoors','underground'},
  passedTags={'undead','unholy','necromancy','poison','vampire'},
  creatureTypes = {'undead','vampire'},
  creatures = {'demonhunter'},
  creatureTags = {'undead','necromancy','vampire'},
}
function mausoleum.create(map,width,height)
  local rooms,hallways = layouts['bsptree'](map,width,height,50,50,100)

  --Add coffins and other decorations to rooms:
  for _, room in pairs(rooms) do
    local safeTiles = mapgen:get_all_safe_to_block(map,room)
    local wallTiles = mapgen:get_all_safe_to_block(map,room,"wallsCorners")
    local cornerTiles = mapgen:get_all_safe_to_block(map,room,"corners")
    local openTiles = mapgen:get_all_safe_to_block(map,room,"noWalls")
    if random(1,4) == 1 then --random chance to have sarcophogi in the walls
      local sarcType = (random(1,3) ~= 1 and "coffin" or "urn")
      for _, tile in pairs(room.walls) do
        local cardinalWalls = 0
        local cando = true
        for x=tile.x-1,tile.x+1,1 do
          for y=tile.y-1,tile.y+1,1 do
            if map:in_map(x,y) and map[x][y] == "." and x ~= width and x ~= 1 and y ~= height and y ~= 1 then
              if (x == tile.x or y == tile.y) and not (x == tile.x and y == tile.y) then
                cardinalWalls = cardinalWalls+1
              end
              if x > room.maxX or x < room.minX or y > room.maxY or y < room.minY then
                cando = false
                break
              end
            end --end blank space check
          end --end fory
          if cando == false then break end
        end --end forx
        if cando and cardinalWalls == 1 and not map:tile_has_feature(tile.x,tile.y,'coffin') and not map:tile_has_feature(tile.x,tile.y,'urn') then
          map[tile.x][tile.y] = "."
          local grave = Feature(sarcType)
          map:add_feature(grave,tile.x,tile.y)
          if random(1,4) == 1 and sarcType == "coffin" then
            local graveshaker = Effect('graveshaker')
            graveshaker.grave = grave
            map:add_effect(graveshaker,tile.x,tile.y)
          end --end graveshaker if
        end --end cardinalwalls if
      end --end tile for
      --Redo corner tiles again, since they probably changed
      cornerTiles = mapgen:get_all_safe_to_block(map,room,"corners")
      for _,tile in pairs(cornerTiles) do
        if map:isEmpty(tile.x,tile.y) and (map:isEmpty(tile.x-1,tile.y) or map[tile.x-1][tile.y] == "#") and (map:isEmpty(tile.x+1,tile.y) or map[tile.x+1][tile.y] == "#") and (map:isEmpty(tile.x,tile.y-1) or map[tile.x][tile.y-1] == "#") and (map:isEmpty(tile.x,tile.y+1) or map[tile.x][tile.y+1] == "#") then
          local grave = map:add_feature(Feature(sarcType),tile.x,tile.y)
          if random(1,4) == 1 and sarcType == "coffin" then
            local graveshaker = Effect('graveshaker')
            graveshaker.grave = grave
            map:add_effect(graveshaker,tile.x,tile.y)
          end --end graveshaker if
        end 
      end --end tiles for
    end -- end sarcophagi if
    if random(1,4) == 1 and not room.exit and not room.entrance then --boneyard
      for _,tile in pairs(openTiles) do
        map:change_tile(Feature('gravedirtfloor'),tile.x,tile.y)
        if (room.maxY-tile.y) % 3 == 0 then
          if map:isEmpty(tile.x,tile.y) then
            local gravestone = map:add_feature(Feature('gravestone'),tile.x,tile.y-1) 
            local grave = map:add_feature(Feature('grave'),tile.x,tile.y)
            if random(1,8) == 1 then
              local graveshaker = Effect('graveshaker')
              graveshaker.grave = grave
              map:add_effect(graveshaker,tile.x,tile.y)
            end
          end --end 
        end --end tile.y if
      end --end openTiles for
    elseif not room.exit and not room.entrance then --generic room
      local decorations = math.ceil(#wallTiles/10)
      for i = 1,decorations,1 do
        local decs = {"statue","candelabra","candles","skullcandle","bonepile"}
        local tile = get_random_key(wallTiles)
        local tileX,tileY = wallTiles[tile].x,wallTiles[tile].y
        if tile and map:isEmpty(tileX,tileY) and map[tileX][tileY] == "." then
          map:add_feature(Feature(get_random_element(decs)),tileX,tileY)
          table.remove(wallTiles,tile)
        end --end empty tiles if
      end --end decoration for
    end --end roomtype if
  end --end room for
  
  --Add coffins to hallways:
  for _, hallway in pairs(hallways) do
    if random(1,4) == 1 then --random chance of adding sarcophogi to hallways
      local sarcType = (random(1,3) ~= 1 and "coffin" or "urn")
      local tiles = (hallway.wide and hallway.wide or hallway.base)
      for _, basetile in pairs(tiles) do
        for x = basetile.x-1,basetile.x+1,1 do
          for y = basetile.y-1,basetile.y+1,1 do
            if map[x][y] == "." or x == width or x == 1 or y == height or y == 1 then break end
            local tile = {x=x,y=y}
            local upTiles, downTiles, leftTiles, rightTiles = 0,0,0,0
            for x=tile.x-1,tile.x+1,1 do
              if map:in_map(x,tile.y-1) and map[x][tile.y-1] == "." then
                upTiles = upTiles + 1
              end
              if map:in_map(x,tile.y+1) and map[x][tile.y+1] == "." then
                downTiles = downTiles + 1
              end
            end --end forx
            for y=tile.y-1,tile.y+1,1 do
              if map:in_map(tile.x-1,y) and map[tile.x-1][y] == "." then
                leftTiles = leftTiles + 1
              end
              if map:in_map(tile.x+1,y) and map[tile.x+1][y] == "." then
                rightTiles = rightTiles + 1
              end
            end --end fory
            local sides = 0
            if upTiles > 1 then sides = sides + 1 end
            if downTiles > 1 then sides = sides + 1 end
            if leftTiles > 1 then sides = sides + 1 end
            if rightTiles > 1 then sides = sides + 1 end
            if sides <= 1 and map[tile.x][tile.y] == "#" and not map:tile_has_feature(tile.x,tile.y,'coffin') and not map:tile_has_feature(tile.x,tile.y,'urn') then
              map[tile.x][tile.y] = "."
              local grave = Feature(sarcType)
              map:add_feature(grave,tile.x,tile.y)
              if random(1,12) == 1 and sarcType == "coffin" then
                local graveshaker = Effect('graveshaker')
                graveshaker.grave = grave
                map:add_effect(graveshaker,tile.x,tile.y)
              end
            end
          end --end fory
        end --end forx
      end --end basetile for
    end --end random if
  end --end hallway for
  
  --Replace doors with gates:
  for x=2,map.width-1,1 do
    for y=2,map.height-1,1 do
      local door = map:tile_has_feature(x,y,'door')
      if door then
        door:delete(map)
        map:add_feature(Feature('gate'),x,y)
      end
    end
  end
  
  --Add some wall torches:
  for i=1,10,1 do
    local x,y = random(2,width-1),random(2,height-1)
    local placed = false
    while placed == false do
      x,y = random(2,width-1),random(2,height-1)
      if map[x][y] == "#" and map:isEmpty(x,y+1) then
        placed = true
      elseif map[x][y] == "#" and map:isEmpty(x+1,y) then
        x=x+1
        placed = true
      elseif map[x][y] == "#" and map:isEmpty(x-1,y) then
        x=x-1
        placed = true
      end
    end
    local torch = Feature('walltorch')
    map:add_feature(torch,x,y)
  end
  --Add grave plaques for coffins:
  for x=2,width-1,1 do
    for y=2,height-1,1 do
      if map:tile_has_feature(x,y,'coffin') or map:tile_has_feature(x,y,'urn') then
        local stone = false
        if map[x][y-1] == "#" then
          stone = map:add_feature(Feature('gravestone'),x,y-1) 
        elseif map[x-1][y] == "#" then
          stone = map:add_feature(Feature('gravestone'),x-1,y) 
        elseif map[x+1][y] == "#" then
          stone = map:add_feature(Feature('gravestone'),x+1,y) 
        end
        if stone then
          stone.image_name = "wallplaque"
          stone.name = "Plaque"
        end
      end --end if has coffin
    end --end fory
  end --end forx
end --end function
mapTypes['mausoleum'] = mausoleum

local endgame = {
  tileset = "dungeon",
  name = "The Hall of Heroes",
  description="In this hall, a true hero can ascend to valhalla.",
  width=9,
  height=25,
  noItems=true, --If true, no items will generate on this level
  noCreatures=true,
  noStores=true,
  noFactions=true,
  event_chance=0, --Likelihood that a non-faction random event will occur. Overrides the event_chance values in gamesettings and in the branch
  event_cooldown=0, --Turns that must pass between ranodm events. Overrides the event_cooldown values in gamesettings and in the branch
  forbid_faction_events=true, --If true, faction events won't occur on this map
}
function endgame.create(map,width,height)
  width,height = map.width,map.height
  map:clear(true)
  
  --Add stairs:
  local midX = round(width/2)
  local stairY = height-1
  local stairs = Feature('exit',{branch="main",exitName="Stairway",depth=3})
  map:change_tile(stairs,midX,stairY)
  map.stairsUp.x,map.stairsUp.y = midX,stairY
  map.stairsDown.x,map.stairsDown.y = midX,2
  local valhalla = Feature('valhalla')
  map:change_tile(valhalla,midX,2)
  local vgate1 = Feature('valhallagate')
  local vgate2 = Feature('valhallagate')
  map:change_tile(vgate1,midX,3)
  map:change_tile(vgate2,midX,5)
  for x=2,width-1,1 do
    if x ~= midX then
      map[x][2] = "#"
      map[x][3] = "#"
      map[x][4] = "#"
      map[x][5] = "#"
    end
  end
  --Statues:
  local wins = load_wins()
  local availableWins = copy_table(wins)
  for y=stairY,6,-2 do
    for i = 1,2,1 do
      local gender = get_random_element({"male","female","other"})
      local name = namegen:generate_human_name({gender=gender})
      local date = "in a Long-Ago, Forgotten Time"
      local class = "Hero"
      local pronoun = (gender == "male" and "He" or (gender == "female" and "She" or "They"))
      if #availableWins > 0 then
        local k = get_random_key(availableWins)
        local win = availableWins[k]
        name = win.name
        date = os.date("%b %d, %Y",win.date)
        class = ucfirst(win.player.name or "Hero")
        local gender = win.player.gender
        pronoun = (gender == "male" and "He" or (gender == "female" and "She" or "They"))
        table.remove(availableWins,k)
      end
      local statue = Feature('statue')
      statue.name = "Statue of " .. name
      local x = (i == 1 and 2 or width-1)
      map:add_feature(statue,x,y)
      if y > 5 then map:add_feature(Feature('candles'),x+(i==1 and 2 or -2),y) end
      statue.description = "A statue of " .. name .. ", " .. class .. ".\n" .. pronoun .. " ascended " .. date .. "."
      map[x][y-1] = "#"
      map[x][y+1] = "#"
    end
  end
end
mapTypes['endgame'] = endgame