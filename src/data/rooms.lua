roomShapes = {}

local rectangle = {
  tags={'constructed','fullspace'}
}
function rectangle.build(minX,minY,maxX,maxY,map,room)
  if not room then room = Room(minX,minY,maxX,maxY,map,false) end
  local floors = {}
  local midX,midY = (room.midX or math.floor((maxX+minX)/2)),(room.midY or math.floor((maxY+minY)/2))
  for x=minX+1,maxX-1,1 do
    for y=minY+1,maxY-1,1 do
      if (x>1 and y>1 and x<map.width and y<map.height) then
        map[x][y] = "."
        floors[#floors+1] = {x=x,y=y}
      end
    end --end fory
  end --end forx
  --Store the walls. Simple in this case because it's a rectangle, just go around the perimeter
  local walls = {}
  local checked = {}
  local dirWalls = {n={},s={},e={},w={}}
  for x = minX,maxX,1 do
    if not checked[x .. ',' .. minY] then
      walls[#walls+1] = {x=x,y=minY}
      checked[x .. ',' .. minY] = true
    end
    if not checked[x .. ',' .. maxY] then
      walls[#walls+1] = {x=x,y=maxY}
      checked[x .. ',' .. maxY] = true
    end
    dirWalls.n[#dirWalls.n+1] = {x=x,y=minY}
    dirWalls.s[#dirWalls.s+1] = {x=x,y=maxY}
  end
  for y = minY,maxY,1 do
    if not checked[minX .. ',' .. y] then
      walls[#walls+1] = {x=minX,y=y}
      checked[minX .. ',' .. y] = true
    end
    if not checked[maxX .. ',' .. y] then
      walls[#walls+1] = {x=maxX,y=y}
      checked[maxX .. ',' .. y] = true
    end
    dirWalls.w[#dirWalls.w+1] = {x=minX,y=y}
    dirWalls.e[#dirWalls.e+1] = {x=maxX,y=y}
  end
  room.walls = walls
  room.floors = floors
  room.dirWalls = dirWalls
  return room
end
roomShapes['rectangle'] = rectangle

local circle = {
  tags={'constructed','fullspace'}
}
function circle.build(minX,minY,maxX,maxY,map,room)
  if not room then room = Room(minX,minY,maxX,maxY,map,false) end
  local floors = {}
  local walls = {}
  local dirWalls = {n={},s={},e={},w={}}
  local alreadyDoneWalls={} --this isn't sent anywhere, it just stores the walls we've already checked, so that if two floors are next to the same wall it won't be stored twice
  local midX,midY = math.floor((maxX+minX)/2),math.floor((maxY+minY)/2)
  local radius = math.max(midX-minX,midY-minY)
  for x=minX+1,maxX-1,1 do
    for y=minY+1,maxY-1,1 do
      if (x>1 and y>1 and x<map.width and y<map.height) and calc_distance(midX,midY,x,y) < radius then
        map[x][y] = "."
        floors[#floors+1] = {x=x,y=y}
      end
    end --end fory
  end --end forx
  --Find the walls:
  for _,floor in pairs(floors) do
    for x=floor.x-1,floor.x+1,1 do
      for y=floor.y-1,floor.y+1,1 do
        if calc_distance(midX,midY,x,y) >= radius and not alreadyDoneWalls[x .. ',' .. y] then
          walls[#walls+1] = {x=x,y=y}
          alreadyDoneWalls[x .. ',' .. y] = true --store this so checking a different square next to this wall won't do anything
          if x < midX then dirWalls.w[#dirWalls.w+1] = {x=x,y=y} end
          if x > midX then dirWalls.e[#dirWalls.e+1] = {x=x,y=y} end
          if y < midY then dirWalls.n[#dirWalls.n+1] = {x=x,y=y} end
          if y > midY then dirWalls.s[#dirWalls.s+1] = {x=x,y=y} end
        end --end wallcheck
      end --end fory
    end --end forx
  end --end floor for
  room.walls = walls
  room.floors = floors
  room.dirWalls = dirWalls
  return room
end
roomShapes['circle'] = circle

local plus = {
  tags={'constructed','fullspace'}
}
function plus.build(minX,minY,maxX,maxY,map,room)
  if not room then room = Room(minX,minY,maxX,maxY,map,false) end
  local floors = {}
  local walls = {}
  local dirWalls = {n={},s={},e={},w={}}
  local width = math.floor((maxX-minX)/3)
  local height = math.floor((maxY-minY)/3)
  local midX,midY = math.floor((maxX+minX)/2),math.floor((maxY+minY)/2)
  for x=minX+1,maxX-1,1 do
    for y=minY+1,maxY-1,1 do
      local xDist,yDist = math.abs(x-midX),math.abs(y-midY)
      if (x>1 and y>1 and x<map.width and y<map.height) and xDist < width or yDist < height then
        map[x][y] = "."
        floors[#floors+1] = {x=x,y=y}
      end
    end --end fory
  end --end forx
  --Find the walls:
  local checked = {}
  for x=minX,maxX,1 do
    if math.abs(x-midX) < width then
      if not checked[x .. "," .. minY] then
        walls[#walls+1] = {x=x,y=minY}
        checked[x .. "," .. minY] = true
      end
      if not checked[x .. "," .. maxY] then
        walls[#walls+1] = {x=x,y=maxY}
        checked[x .. "," .. maxY] = true
      end
      dirWalls.n[#dirWalls.n+1] = {x=x,y=minY}
      dirWalls.s[#dirWalls.s+1] = {x=x,y=maxY}
    else
      if not checked[x .. "," .. midY+height] then
        walls[#walls+1] = {x=x,y=midY+height}
        checked[x .. "," .. midY+height] = true
      end
      if not checked[x .. "," .. midY-height] then
        walls[#walls+1] = {x=x,y=midY-height}
        checked[x .. "," .. midY-height] = true
      end
      dirWalls.n[#dirWalls.n+1] = {x=x,y=midY+height}
      dirWalls.s[#dirWalls.s+1] = {x=x,y=midY-height}
    end
  end
  for y=minY,maxY,1 do
    if math.abs(y-midY) < height then
      if not checked[minX .. "," .. y] then
        walls[#walls+1] = {x=minX,y=y}
        checked[minX .. "," .. y] = true
      end
      if not checked[maxX .. "," .. y] then
        walls[#walls+1] = {x=maxX,y=y}
        checked[maxX .. "," .. y] = true
      end
      dirWalls.w[#dirWalls.w+1] = {x=minX,y=y}
      dirWalls.e[#dirWalls.e+1] = {x=maxX,y=y}
    else
      if not checked[midX-width .. "," .. y] then
        walls[#walls+1] = {x=midX-width,y=y}
        checked[midX-width .. "," .. y] = true
      end
      if not checked[midX+width .. "," .. y] then
        walls[#walls+1] = {x=midX+width,y=y}
        checked[midX+width .. "," .. y] = true
      end
      dirWalls.w[#dirWalls.w+1] = {x=midX-width,y=y}
      dirWalls.e[#dirWalls.e+1] = {x=midX+width,y=y}
    end
  end
  room.walls = walls
  room.floors = floors
  room.dirWalls = dirWalls
  return room
end
roomShapes['plus'] = plus

--"Blob" room type. Starts in the middle of the room, then randomly spreads in all directions
local blob = {
  tags = {'natural'}
}
function blob.build(minX,minY,maxX,maxY,map,room)
  if not room then room = Room(minX,minY,maxX,maxY,map,false) end
  local floors = {}
  local walls = {}
  local dirWalls = {n={},s={},e={},w={}}
  local midX,midY = math.floor((maxX+minX)/2),math.floor((maxY+minY)/2)
  local points = {{x=midX,y=midY,spreadChance=100}}
  local size = math.min(maxX-minX,maxY-minY)
  while count(points) > 0 do
    local pID = next(points)
    local point = points[pID]
    table.remove(points,pID)
    map[point.x][point.y] = "."
    floors[#floors+1] = {x=point.x,y=point.y}
    if random(1,100) <= point.spreadChance then
      for x=point.x-1,point.x+1,1 do
        for y=point.y-1,point.y+1,1 do
          if x > minX and x < maxX and y > minY and y < maxY and (x == point.x or y == point.y) and not (x==point.x and y==point.y)and random(1,100) <= point.spreadChance then
            points[#points+1] = {x=x,y=y,spreadChance=point.spreadChance-10-(point.spreadChance/(size))}
          end --end if
        end --end fory
      end --end forx
    end --end spreadchance if
  end

--Find the walls:
  local alreadyDoneWalls = {}
  for _,floor in pairs(floors) do
    for x=floor.x-1,floor.x+1,1 do
      for y=floor.y-1,floor.y+1,1 do
        if map[x][y] == "#" and not alreadyDoneWalls[x .. ',' .. y] then
          walls[#walls+1] = {x=x,y=y}
          alreadyDoneWalls[x .. ',' .. y] = true --store this so checking a different square next to this wall won't do anything
          if x < midX then dirWalls.w[#dirWalls.w+1] = {x=x,y=y} end
          if x > midX then dirWalls.e[#dirWalls.e+1] = {x=x,y=y} end
          if y < midY then dirWalls.n[#dirWalls.n+1] = {x=x,y=y} end
          if y > midY then dirWalls.s[#dirWalls.s+1] = {x=x,y=y} end
        end --end wallcheck
      end --end fory
    end --end forx
  end --end floor for
  
  room.walls = walls
  room.floors = floors
  room.dirWalls = dirWalls
  return room
end
roomShapes['blob'] = blob

--"Drunk Walker" room type. Starts in the middle, then "walks" to a random adjacent tile
local drunkwalker = {
  tags = {'natural'}
}
function drunkwalker.build(minX,minY,maxX,maxY,map,room)
  if not room then room = Room(minX,minY,maxX,maxY,map,false) end
  local floors = {}
  local walls = {}
  local dirWalls = {n={},s={},e={},w={}}
  local midX,midY = math.floor((maxX+minX)/2),math.floor((maxY+minY)/2)
  local walkerX,walkerY = midX,midY
  local totalTiles = ((maxX-minX)*(maxY-minY))
  local doneTiles = 0
  local openPercent = random(50,85)
  local alreadyDoneFloors = {}
  while (doneTiles/totalTiles)*100 < openPercent do
    if map[walkerX][walkerY] ~= "." then --only count it if it's a new floor
      map[walkerX][walkerY] = "."
      floors[#floors+1] = {x=walkerX,y=walkerY}
      alreadyDoneFloors[walkerX .. ',' .. walkerY] = true --store this for later
    end
    doneTiles = doneTiles + 1
    if random(1,2) == 1 then --x walk
      walkerX = walkerX + 1 * (random(1,2) == 1 and -1 or 1)
    else
      walkerY = walkerY + 1 * (random(1,2) == 1 and -1 or 1)
    end
    --Make sure we're not going out of bounds:
    walkerX = math.min(math.max(walkerX,minX+1),maxX-1)
    walkerY = math.min(math.max(walkerY,minY+1),maxY-1)
  end --end while
  
  --Find the walls:
  local alreadyDoneWalls = {}
  for _,floor in pairs(floors) do
    for x=floor.x-1,floor.x+1,1 do
      for y=floor.y-1,floor.y+1,1 do
        if map[x][y] == "#" and not alreadyDoneWalls[x .. ',' .. y] and not ((map[x-1][y] == "." and map[x+1][y] == ".") and (map[x][y-1] == "." and map[x][y+1] == ".")) then
          walls[#walls+1] = {x=x,y=y}
          alreadyDoneWalls[x .. ',' .. y] = true --store this so checking a different square next to this wall won't do anything
          if x < midX then dirWalls.w[#dirWalls.w+1] = {x=x,y=y} end
          if x > midX then dirWalls.e[#dirWalls.e+1] = {x=x,y=y} end
          if y < midY then dirWalls.n[#dirWalls.n+1] = {x=x,y=y} end
          if y > midY then dirWalls.s[#dirWalls.s+1] = {x=x,y=y} end
        elseif (map[x-1][y] == "." and map[x+1][y] == ".") and (map[x][y-1] == "." and map[x][y+1] == ".") and not alreadyDoneFloors[x .. ',' .. y] then
          map[x][y] = "."
          floors[#floors+1] = {x=x,y=y}
          alreadyDoneFloors[x .. ',' .. y] = true
        end --end wallcheck
      end --end fory
    end --end forx
  end --end floor for
  
  room.walls = walls
  room.floors = floors
  room.dirWalls = dirWalls
  return room
end
roomShapes['drunkwalker'] = drunkwalker

--[[Not working very well:
local cave = function(minX,minY,maxX,maxY,map)
  local floors = {}
  local walls = {}
  local dirWalls = {n={},s={},e={},w={}}
  local width = math.floor((maxX-minX)/3)
  local height = math.floor((maxY-minY)/3)
  local midX,midY = math.floor((maxX+minX)/2),math.floor((maxY+minY)/2)
  --if width < 10 or height < 10 then return mapgen:generate_room(minX,minY,maxX,maxY,map) end --too small, don't make a cave
  
  local wallchance = wallchance or random(40,45)
	for x = minX, maxX, 1 do
		for y = minX, maxX, 1 do
			if (x == minX or x == maxX or y == minY or y == maxY) then
				map[x][y] = "#"
			elseif (random(0,100) < wallchance) then
				map[x][y] = "#"
			else
				map[x][y] = "."
			end -- end if
		end -- end yFor
	end -- end xFor
	
	local checkTile = function(map,x,y)
		local neighbors = 0
		for ix=x-1,x+1,1 do
			for iy=y-1,y+1,1 do
				if (map[ix][iy] == "#") then neighbors = neighbors + 1 end
			end -- end yfor
		end -- end xfor
		return neighbors
	end -- end checkTile
	
	for i = 1, 3, 1 do
		for x=minX+1,maxX-1,1 do
			for y=minY+1,minY-1,1 do
				local neighbors = checkTile(map,x,y)
				if (neighbors >= 5 or random(1,100) <= 5 and map[x][y] ~= "<") then
					map[x][y] = "#"
				else
					map[x][y] = "."
				end -- end neighbors if
			end -- end yfor
		end -- end xfor
	end -- end i
  
  --Find the walls:
  local alreadyDoneWalls = {}
  for _,floor in pairs(floors) do
    for x=floor.x-1,floor.x+1,1 do
      for y=floor.y-1,floor.y+1,1 do
        if map[x][y] == "#" and not alreadyDoneWalls[x .. ',' .. y] then
          walls[#walls+1] = {x=x,y=y}
          alreadyDoneWalls[x .. ',' .. y] = true --store this so checking a different square next to this wall won't do anything
          if x < midX then dirWalls.w[#dirWalls.w+1] = {x=x,y=y} end
          if x > midX then dirWalls.e[#dirWalls.e+1] = {x=x,y=y} end
          if y < midY then dirWalls.n[#dirWalls.n+1] = {x=x,y=y} end
          if y > midY then dirWalls.s[#dirWalls.s+1] = {x=x,y=y} end
        end --end wallcheck
      end --end fory
    end --end forx
  end --end floor for
  
  return {minX=minX,maxX=maxX,minY=minY,maxY=maxY,midX=midX,midY=midY,walls=walls,dirWalls=dirWalls,floors=floors}
end
roomShapes['cave'] = cave --]]