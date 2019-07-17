local roomDecorators = {}

function decorate_room(room,map,roomDec,...)
  local dec = nil
  if roomDec == "random" or not roomDec then
    dec = get_random_element(roomDecorators)
  elseif roomDecorators[roomDec] then
    dec = roomDecorators[roomDec]
  elseif type(roomDec) == "table" then
    get_random_element(roomDec)
    if roomDecorators[roomDec] then
      dec = roomDecorators[roomDec]
    end
  end
  if dec then
    dec(room,map,unpack({...}))
  end
  return
end

function roomDecorators.temple(room,map,focusList,pewsOnly,altarArgs)
  local roomW,roomH = room.maxX-room.minX,room.maxY-room.minY
  local safeTiles = mapgen:get_all_safe_to_block(map,room)
  local wallTiles = mapgen:get_all_safe_to_block(map,room,"wallsCorners")
  local cornerTiles = mapgen:get_all_safe_to_block(map,room,"corners")
  local openTiles = mapgen:get_all_safe_to_block(map,room,"noWalls")
  local midX,midY = round(room.minX+roomW/2),round(room.minY+roomH/2)
  local focii = focusList or {'lectern','statue','pentagram','obelisk','sarcophagus','altar'}
  local focus = (type(focusList) == "string" and focusList or focii[random(#focii)])
  local sitType = {'chair','pew'}
  sitType = (pewsOnly and "pew" or sitType[random(#sitType)])
  local lightType = {'candles','candelabra','skullcandle','statue','bookshelf','gorespike'}
  lightType = lightType[random(#lightType)]
      
  if count(openTiles) > 9 then
    if roomW>roomH then --horizontal temple
      local closest,closestBackDist,closestMidDist = nil,nil,nil
      local dir = random(1,3) --1 == w, 2 == e, 3 == middle
      if dir ~= 3 then
        for _,tile in pairs(openTiles) do
          local backDist = math.abs(tile.x-(dir == 1 and room.minX or room.maxX))
          local midDist = math.abs(tile.y-(midY))
          if closest == nil or (backDist <= closestBackDist and midDist <= closestMidDist) then
            closestBackDist,closestMidDist=backDist,midDist
            closest = tile
          end
        end --end for
      else
        closest = {x=midX,y=midY}
      end
      
      map:add_feature(Feature(focus, (focus == "altar" and (altarArgs or {altarType="random",decoration="random",godName=true}) or nil)),closest.x,closest.y)
          
      for _,tile in pairs(openTiles) do
        if ((dir == 1 and tile.x > closest.x) or (dir == 2 and tile.x < closest.x) or (dir == 3 and tile.x ~= closest.x)) and (closest.x-tile.x) % 2 == 0 then
          local sitter = Feature(sitType)
          map:add_feature(sitter,tile.x,tile.y)
          sitter.image_name = sitter.id .. (sitter.x > closest.x and "e" or "w")
        end --end direction if
        if dir == 3 and tile.y ~= closest.y and (closest.y-tile.y) % 2 == 0 and (closest.x-tile.x) % 2 == 0 then
          if not map:tile_has_feature(tile.x,tile.y,sitType) then
            local sitter = Feature(sitType)
            map:add_feature(sitter,tile.x,tile.y)
            sitter.image_name = sitter.id .. (sitter.y > closest.y and "s" or "n")
          end
        end --end dir == 3
      end --end seats for
    else --vertical temple
      local closest,closestBackDist,closestMidDist = nil,nil,nil
      local dir = random(1,3) --1 == n, 2 == s, 3 == middle
      if dir ~= 3 then
        for _,tile in pairs(openTiles) do
          local backDist = math.abs(tile.y-(dir == 1 and room.minY or room.maxY))
          local midDist = math.abs(tile.x-(midX))
          if closest == nil or (backDist <= closestBackDist and midDist <= closestMidDist) then
            closestBackDist,closestMidDist=backDist,midDist
            closest = tile
          end
        end --end for
      else
        closest = {x=midX,y=midY}
      end

      map:add_feature(Feature(focus, (focus == "altar" and (altarArgs or {altarType="random",decoration="random",godName=true}) or nil)),closest.x,closest.y)

      for _,tile in pairs(openTiles) do
        if ((dir == 1 and tile.y > closest.y) or (dir == 2 and tile.y < closest.y) or (dir == 3 and tile.y ~= closest.y)) and (closest.y-tile.y) % 2 == 0 then
          local sitter = Feature(sitType)
          map:add_feature(sitter,tile.x,tile.y)
          sitter.image_name = sitter.id .. (sitter.y > closest.y and "s" or "n")
        end --end direction if
        if dir == 3 and tile.x ~= closest.x and (closest.x-tile.x) % 2 == 0 and (closest.y-tile.y) % 2 == 0 then
          if not map:tile_has_feature(tile.x,tile.y,sitType) then
            local sitter = Feature(sitType)
            map:add_feature(sitter,tile.x,tile.y)
            sitter.image_name = sitter.id .. (sitter.x > closest.x and "e" or "w")
          end
        end --end dir == 3
      end
    end --end n/s/e/w

    --Add lights to corners:
    for _,tile in pairs(cornerTiles) do
      map:add_feature(Feature(lightType),tile.x,tile.y)
    end
  else -- small temple
    map:add_feature(Feature(focus),midX,midY)
    for _,tile in pairs(cornerTiles) do
      map:add_feature(Feature(lightType),tile.x,tile.y)
    end
  end
end

function roomDecorators.tavern(room,map)
  local roomW,roomH = room.maxX-room.minX,room.maxY-room.minY
  local safeTiles = mapgen:get_all_safe_to_block(map,room)
  local wallTiles = mapgen:get_all_safe_to_block(map,room,"wallsCorners")
  local cornerTiles = mapgen:get_all_safe_to_block(map,room,"corners")
  local openTiles = mapgen:get_all_safe_to_block(map,room,"noWalls")
  local midX,midY = round(room.minX+roomW/2),round(room.minY+roomH/2)
  
  if roomW >= 7 and roomH >= 7 then
    --Add table:
    for _,tile in pairs(openTiles) do
      local nWall,sWall,wWall,eWall = map[tile.x][tile.y-2] == "#" or map:tile_has_feature(tile.x,tile.y-2,'door'),map[tile.x][tile.y+2] == "#" or map:tile_has_feature(tile.x,tile.y+2,'door'),map[tile.x-2][tile.y] == "#" or map:tile_has_feature(tile.x-2,tile.y,'door'),map[tile.x+2][tile.y] == "#" or map:tile_has_feature(tile.x+2,tile.y,'door')
      if not nWall and not sWall and not eWall and not wWall then
        map:add_feature(Feature('table'),tile.x,tile.y)
      elseif (nWall and not sWall and not wWall and not eWall) or (sWall and not nWall and not wWall and not eWall) or (eWall and not wWall and not nWall and not sWall) or (wWall and not eWall and not nWall and not sWall) then
        local chair = Feature('chair')
        local dirs = {}
        if nWall then dirs[#dirs+1] = "n" end
        if sWall then dirs[#dirs+1] = "s" end
        if eWall then dirs[#dirs+1] = "e" end
        if wWall then dirs[#dirs+1] = "w" end
        chair.image_name = "chair" .. dirs[random(#dirs)]
        map:add_feature(chair,tile.x,tile.y)
      end
    end
    local barrels = math.ceil(count(cornerTiles)/2)
    for i=1,barrels,1 do
      local tile = get_random_key(cornerTiles)
      if not map:tile_has_feature(cornerTiles[tile].x,cornerTiles[tile].y,'chair') then
        map:add_feature(Feature('keg'),cornerTiles[tile].x,cornerTiles[tile].y)
        table.remove(cornerTiles,tile)
        if count(cornerTiles) < 1 then break end
      end
    end
  else --small tavern, just scatter chairs
    local chairs = math.ceil(count(safeTiles)/4)
    for i=1,chairs,1 do
      local tile = get_random_key(safeTiles)
      local dirs = {'n','s','e','w'}
      local chair = Feature('chair')
      map:add_feature(chair,safeTiles[tile].x,safeTiles[tile].y)
      chair.image_name = "chair" .. dirs[random(#dirs)]
      table.remove(safeTiles,tile)
      if count(safeTiles) < 1 then break end
    end
    local barrels = math.ceil(count(cornerTiles)/2)
    for i=1,barrels,1 do
      local tile = get_random_key(cornerTiles)
      if not map:tile_has_feature(cornerTiles[tile].x,cornerTiles[tile].y,'chair') then
        map:add_feature(Feature('keg'),cornerTiles[tile].x,cornerTiles[tile].y)
        table.remove(cornerTiles,tile)
        if count(cornerTiles) < 1 then break end
      end
    end
  end
end

function roomDecorators.bedroom(room,map)
  local roomW,roomH = room.maxX-room.minX,room.maxY-room.minY
  local safeTiles = mapgen:get_all_safe_to_block(map,room)
  local wallTiles = mapgen:get_all_safe_to_block(map,room,"wallsCorners")
  local cornerTiles = mapgen:get_all_safe_to_block(map,room,"corners")
  local openTiles = mapgen:get_all_safe_to_block(map,room,"noWalls")
  local midX,midY = round(room.minX+roomW/2),round(room.minY+roomH/2)
  
  --Add bed:
  local bedTile = get_random_key(cornerTiles)
  if bedTile then
    map:add_feature(Feature('bed'),cornerTiles[bedTile].x,cornerTiles[bedTile].y)
    for k,t in pairs(wallTiles) do
      if t.x == cornerTiles[bedTile].x and t.y == cornerTiles[bedTile].y then
        table.remove(wallTiles,k)
        break
      end --end tx ty check
    end --end walltile for
    table.remove(cornerTiles,bedTile)
  end
  --Add chest:
  local chestTile = get_random_key(wallTiles)
  if chestTile then
    map:add_feature(Feature('chest'),wallTiles[chestTile].x,wallTiles[chestTile].y)
    table.remove(wallTiles,chestTile)
  end
  --Add chair:
  local chairTile = get_random_key(wallTiles)
  if chairTile then
    local chair = Feature('chair')
    map:add_feature(chair,wallTiles[chairTile].x,wallTiles[chairTile].y)
    --Try to add a table next to the chair:
    local nTile = mapgen:is_safe_to_block(map,wallTiles[chairTile].x,wallTiles[chairTile].y-1) and map:isClear(wallTiles[chairTile].x,wallTiles[chairTile].y-1)
    local sTile = mapgen:is_safe_to_block(map,wallTiles[chairTile].x,wallTiles[chairTile].y+1) and map:isClear(wallTiles[chairTile].x,wallTiles[chairTile].y+1)
    local eTile = mapgen:is_safe_to_block(map,wallTiles[chairTile].x+1,wallTiles[chairTile].y) and map:isClear(wallTiles[chairTile].x+1,wallTiles[chairTile].y)
    local wTile = mapgen:is_safe_to_block(map,wallTiles[chairTile].x-1,wallTiles[chairTile].y) and map:isClear(wallTiles[chairTile].x-1,wallTiles[chairTile].y)
    local dirs = {}
    if nTile then dirs['s'] = {x=wallTiles[chairTile].x,y=wallTiles[chairTile].y-1} end
    if sTile then dirs['n'] = {x=wallTiles[chairTile].x,y=wallTiles[chairTile].y+1} end
    if eTile then dirs['w'] = {x=wallTiles[chairTile].x+1,y=wallTiles[chairTile].y} end
    if wTile then dirs['e'] = {x=wallTiles[chairTile].x-1,y=wallTiles[chairTile].y} end
    if count(dirs) > 0 then
      local dir = get_random_key(dirs)
      map:add_feature(Feature('table'),dirs[dir].x,dirs[dir].y)
      chair.image_name = "chair" .. dir
    end
    table.remove(wallTiles,chairTile)
  end
  --Add bookshelves, if room big enough
  if count(wallTiles) > 5 then
    local shelves = random(1,math.ceil((count(wallTiles)-5)/5))
    for i=1,shelves,1 do
      local shelfTile = get_random_key(wallTiles)
      if shelfTile then
        map:add_feature(Feature('bookshelf'),wallTiles[shelfTile].x,wallTiles[shelfTile].y)
        table.remove(wallTiles,shelfTile)
      end
    end
  end
end

function roomDecorators.storeroom(room,map)
  local roomW,roomH = room.maxX-room.minX,room.maxY-room.minY
  local safeTiles = mapgen:get_all_safe_to_block(map,room)
  local wallTiles = mapgen:get_all_safe_to_block(map,room,"wallsCorners")
  local cornerTiles = mapgen:get_all_safe_to_block(map,room,"corners")
  local openTiles = mapgen:get_all_safe_to_block(map,room,"noWalls")
  local midX,midY = round(room.minX+roomW/2),round(room.minY+roomH/2)
  
  local decorations = math.ceil(count(safeTiles)/4)
  for i=1,decorations,1 do
    local tileID = get_random_key(safeTiles)
    local tile = safeTiles[tileID]
    local decorType = random(1,3)
    local decor = ""
    if decorType == 1 then
      decor = "crate"
    elseif decorType == 2 then
      decor = "barrel"
    elseif decorType == 3 then
      decor = "keg"
    end
    map:add_feature(Feature(decor),tile.x,tile.y)
    table.remove(safeTiles,tileID)
    if count(safeTiles) < 1 then break end
  end
end

function roomDecorators.trainingroom(room,map)
  local roomW,roomH = room.maxX-room.minX,room.maxY-room.minY
  local safeTiles = mapgen:get_all_safe_to_block(map,room)
  local wallTiles = mapgen:get_all_safe_to_block(map,room,"wallsCorners")
  local cornerTiles = mapgen:get_all_safe_to_block(map,room,"corners")
  local openTiles = mapgen:get_all_safe_to_block(map,room,"noWalls")
  local midX,midY = round(room.minX+roomW/2),round(room.minY+roomH/2)
  
  local wallDecs = math.min(math.ceil(count(wallTiles)/4),4)
  local firstX,firstY = nil
  local which = nil
  for i=1,wallDecs,1 do
    local tileID = get_random_key(wallTiles)
    local tile = wallTiles[tileID]
    if (which == nil or (which == "x" and tile.x == firstX) or (which == "y" and tile.y == firstY)) and map:isEmpty(tile.x,tile.y) then --only put archery targets along the same wall
      if which == nil then
        firstX,firstY = tile.x,tile.y
        which = (firstX == tile.x and "x" or "y")
      end
      if map:isEmpty(tile.x,tile.y) then map:add_feature(Feature('archerytarget'),tile.x,tile.y) end
    elseif map:isEmpty(tile.x,tile.y) then --put weapon and armor racks on different walls
      map:add_feature(Feature("weaponrack"),tile.x,tile.y)
    end
    table.remove(wallTiles,tileID)
    if count(wallTiles) < 1 then break end
  end
  
  local dummies = math.min(math.ceil(count(safeTiles)/10),6)
  firstX,firstY = nil
  local tries = 0
  while dummies > 0 and tries < 100 do
    local tileID = get_random_key(safeTiles)
    local tile = safeTiles[tileID]
    if (firstX == nil or tile.x == firstX or tile.y == firstY) and map:isEmpty(tile.x,tile.y) then
      if not firstX then firstX,firstY = tile.x,tile.y end
      local make = true
      for x=tile.x-1,tile.x+1 do
        for y=tile.y-1,tile.y+1 do
          if map[x][y] == "#" or not map:isEmpty(x,y) then make = false end
        end
      end
      if make then
        map:add_feature(Feature('trainingdummy'),tile.x,tile.y)
        dummies = dummies - 1
      end
    end
    table.remove(safeTiles,tileID)
    tries = tries + 1
    if count(safeTiles) < 1 or tries >= 100 then break end
  end
end