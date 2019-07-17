require "mapgen"

layouts = {}

local randomPaths = function (map,width,height,orthogonal,paths,iterations)
  paths = paths or math.ceil(math.min(width,height)/10)
  iterations = iterations or 5
  
  --Make an empty pathfinder:
  local Grid = require('lib.jumper.grid')
  local Pathfinder = require 'lib.jumper.pathfinder'
  local colMap = {}
  for y=1,height,1 do
    colMap[y] = (colMap[y] or {})
    for x=1,width,1 do
      if x==1 or y==1 or x==width or y==height then
        colMap[y][x] = 1
      else
        colMap[y][x] = 0
      end
    end --end forx
  end --end fory
  local useGrid = Grid(colMap)
  local finder = Pathfinder(useGrid,'JPS',0)
  if orthogonal then 
    finder:setMode('ORTHOGONAL')
  end
  
  --Build the basic paths:
  local tiles = {} --this will hold all the open tiles
  local newTiles = {} --this will hold all the open tiles that are not part of initial paths
  local ends = {}
  for i=1,paths,1 do
    --Set start and end points
    local startX,startY
    if i == 1 then
      startX,startY = random(2,width-1),random(2,height-1)
    else
      local p = get_random_element(tiles)
      startX,startY = p.x,p.y
    end
    local endX,endY = random(2,width-1),random(2,height-1)
    while calc_distance(startX,startY,endX,endY) < 10 or map[endX][endY] == "." do
      endX,endY = random(2,width-1),random(2,height-1)
    end
    ends[#ends+1] = {x=endX,y=endY}
    local path = finder:getPath(startX,startY,endX,endY,false)
    if path and #path > 1 then
      path:fill()
    end
    for _,node in pairs(path) do
      if (node.x and node.y) then
        if map[node.x][node.y] ~= "." then
          tiles[#tiles+1] = {x=node.x,y=node.y}
        end
        map[node.x][node.y] = "."
      end --end if node
    end --end node for
    --If this isn't the first time, also path to another ending tile
    if i ~= 1 then
      local newEnd = get_random_element(ends)
      local newEndX,newEndY = newEnd.x,newEnd.y
      local path = finder:getPath(startX,startY,endX,endY,false)
      if path and #path > 1 then
        path:fill()
      end
      for _,node in pairs(path) do
        if (node.x and node.y) then
          if map[node.x][node.y] ~= "." then
            tiles[#tiles+1] = {x=node.x,y=node.y}
          end
          map[node.x][node.y] = "."
        end --end if node
      end --end node for
    end
  end --end path for
end
layouts['randompaths'] = randomPaths

local connectedNodes = function (map,width,height,orthogonal,nodeCount,iterations)
  nodeCount = nodeCount or math.ceil(math.min(width,height)/10)
  iterations = iterations or 2
  
  --Make an empty pathfinder:
  local Grid = require('lib.jumper.grid')
  local Pathfinder = require 'lib.jumper.pathfinder'
  local colMap = {}
  for y=1,height,1 do
    colMap[y] = (colMap[y] or {})
    for x=1,width,1 do
      if x==1 or y==1 or x==width or y==height then
        colMap[y][x] = 1
      else
        colMap[y][x] = 0
      end
    end --end forx
  end --end fory
  local useGrid = Grid(colMap)
  local finder = Pathfinder(useGrid,'JPS',0)
  if orthogonal then 
    finder:setMode('ORTHOGONAL')
  end
  
  --local tiles = {} --this will hold all the open tiles
  --local newTiles = {} --this will hold all the open tiles that are not part of initial paths
  local nodes = {} -- this will hold the nodes that need to be connected
  --Create the nodes:
  for i=1,nodeCount,1 do
    local x,y = random(2,width-1),random(2,height-1)
    while map[x][y] == "." do
      x,y = random(2,width-1),random(2,height-1)
    end
    nodes[#nodes+1] = {x=x,y=y}
    map[x][y] = "."
  end

  --Now connect the nodes:
  for i=1,iterations,1 do
    for _,startNode in pairs(nodes) do
      local startX,startY = startNode.x,startNode.y
      local endNode = get_random_element(nodes)
      while calc_distance(startX,startY,endNode.x,endNode.y) < 10 do
        endNode = get_random_element(nodes)
      end
      local endX,endY = endNode.x,endNode.y
      --Now that we're settled, draw a path between the nodes:
      local path = finder:getPath(startX,startY,endX,endY,false)
      if path and #path > 1 then
        path:fill()
      end
      for _,node in pairs(path) do
        if (node.x and node.y) then
          map[node.x][node.y] = "."
        end --end if node
      end --end pathfinder node for
    end --end node for
  end --end iteration for
end
layouts['connectednodes'] = connectedNodes

local noise = function (map,width,height,size,threshold,seed)
  seed = seed or random(0,20000)
  size = size or (1/10)
  local xMod,yMod = random(1,20000),random(1,20000)
  for x = 2, width-1,1 do
    for y = 2,height-1,1 do
      map[x][y] = (love.math.noise((x+xMod)*size,(y+yMod)*size,seed) < (threshold or .45) and "#" or ".")
    end
  end
  --Add random edges to the side of the map, so there's less flat edges:
  mapgen:makeEdges(map,width,height)
  
  -- this clears out disconnected caves, and counts the number of open tiles, to make sure there's enough to be fun
	local floodFill = mapgen:floodFill(map)
	local openTiles = 0
	for x=2,width-1,1 do
		for y=2,width-1,1 do
			if (map[x][y] == "." and floodFill[x][y] == nil and map[x][y] ~= "<") then
				map[x][y] = "#"
			elseif (map[x][y] == "." and floodFill[x][y] == true) then
				openTiles = openTiles + 1
			end -- end if
		end -- end y
	end -- end x
	
	-- If the number of open tiles is less than 45% of the total map area, throw it out and try again.
	if (openTiles/(map.width*map.height) < .45) then
		layouts['noise'](map,width,height,size,threshold)
	end
end
layouts['noise'] = noise

local caves = function (map, width, height,wallchance,noClear)
	-- Cellular automata cave generation
	-- Initial randomized fill, default to 40-45% of being a wall:
  wallchance = wallchance or random(40,45)
	for x = 1, width, 1 do
		for y = 1, height, 1 do
			if (x == 1 or x == width or y == 1 or y == height) then
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
		for x=2,width-1,1 do
			for y=2,height-1,1 do
				local neighbors = checkTile(map,x,y)
				if (neighbors >= 5 or random(1,100) <= 5 and map[x][y] ~= "<") then
					map[x][y] = "#"
				else
					map[x][y] = "."
				end -- end neighbors if
			end -- end yfor
		end -- end xfor
	end -- end i
	
  if not noClear then
    -- this clears out disconnected caves, and counts the number of open tiles, to make sure there's enough to be fun
    local floodFill = mapgen:floodFill(map)
    local openTiles = 0
    for x=2,width-1,1 do
      for y=2,width-1,1 do
        if (map[x][y] == "." and floodFill[x][y] == nil and map[x][y] ~= "<") then
          map[x][y] = "#"
        elseif (map[x][y] == "." and floodFill[x][y] == true) then
          openTiles = openTiles + 1
        end -- end if
      end -- end y
    end -- end x
	
    -- If the number of open tiles is less than 45% of the total map area, throw it out and try again.
    if (openTiles/(map.width*map.height) < .45) then
      layouts['caves'](map,width,height)
    end
  end --end noClear if
end -- end function
layouts['caves'] = caves

--Working pretty well, but could use some tweaking
local drunktunnels = function (map,width,height)
  local walkers = {}
  
  local makeWalkers = function(x,y,main,spawnNum)
    local w = {size=random(1,3),life=random(25,40),spawns=spawnNum}
    if (main == "x" and main ~= "y") or random(1,2) == 1 then --determine orientation
      w.main = "x"
      w.secondary = "y"
      w.y = y or random(2,height-1)
      if random(1,2) == 1 then --determine direction
        w.dir=1
        w.x = x or 2
      else
        w.dir=-1
        w.x = x or width-1
      end --end determine direction
    else --determine orientation
      w.main = "y"
      w.secondary = "x"
      w.x = x or random(2,width-1)
      if random(1,2) == 1 then --determine direction
        w.dir=1
        w.y = y or 2 
      else
        w.dir=-1
        w.y = y or height-1 
      end  --end determine direction if
    end --end determine orientation if
    walkers[w] = w
  end --end makewalkers function
  
  for i=1,random(4,6),1 do
    makeWalkers(nil,nil,nil,3)
  end
 
  while (next(walkers) ~= nil) do
    for id, walker in pairs(walkers) do
      for z = walker[walker.secondary]-random(0,walker.size),walker[walker.secondary]+random(0,walker.size),1 do
        if (walker.main == "x") then 
          if walker.x > 1 and walker.x < width and z> 1 and z < height then map[walker.x][z] = "." end
        else
          if z>1 and z<width and walker.y>1 and walker.y<height then map[z][walker.y] = "." end
         end -- end x/y check
      end -- end for
      
      walker[walker.main] = walker[walker.main] + 1*walker.dir -- move along main track, example: w[x] = w[x] + -1)
      walker[walker.secondary] = walker[walker.secondary] + random(-1,1) --drunkwalk along secondary track
      walker.size = math.max(math.min(walker.size+random(-1,1),3),1)
      --[[This didn't really look too good:
      walker.x = math.max(math.min(walker.x + walker.xdir,width-1),2)
      walker.y = math.max(math.min(walker.y + walker.ydir,height-1),2)
      walker.size = math.min(math.max(walker.size + random(-1,1),1),3)
      for x=walker.x-walker.size,walker.x+walker.size,1 do
        for y=walker.y-walker.size,walker.y+walker.size,1 do
          if x>1 and x<map.width and y>1 and y<map.height then
            map[x][y] = "."
          else --if you hit the edge, die
            walkers[id] = nil
          end --end if
        end --end fory
      end --end forx]]
      walker.life = walker.life-1
      if (walker.life<1 or walker.x < 2 or walker.x > width-1 or walker.y < 2 or walker.y > height-1) then
        local newWalkers = random(0,2)
        while newWalkers > 0 do
          if (walker.spawns > 0) then makeWalkers(walker.x,walker.y,walker.secondary,walker.spawns-1) end
          newWalkers = newWalkers-1
          walkers[id] = nil
        end -- end while
      end --end death if
    end -- end for
  end -- end while
end -- end drunkwalker function
layouts['drunktunnels'] = drunktunnels

local drunkwalker = function(map,width,height,openAmt,tunnelChance)
  openAmt = openAmt or random(45,55)
  tunnelChance = tunnelChance or 10
  local totalTiles = (width-2)*(height-2) -- -2 because 1 and max are never going to be floors
  local midX,midY = math.max(width/2),math.max(height/2)
  local walkerX,walkerY = round(midX),round(midY)
  local floorAmt = 0
  local xDir,yDir = 0,0
  local tunnelDist = 0
  while (floorAmt/totalTiles)*100 < openAmt do
    if not map:in_map(walkerX,walkerY) then
      walkerX = math.min(math.max(walkerX,2),width-1)
      walkerY = math.min(math.max(walkerY,2),height-1)
    end
    if map[walkerX][walkerY] ~= "." then --only count it if it's a new floor tile
      floorAmt = floorAmt + 1
      map[walkerX][walkerY] = "."
    end
    if tunnelDist > 0 then
      walkerX,walkerY = walkerX+xDir,walkerY+yDir
      tunnelDist = tunnelDist - 1
      if tunnelDist < 1 then
        xDir,yDir = 0,0
      end --end tunneldist if
    else --no tunnels
      if random(1,100) <= tunnelChance then
        if random(1,2) == 1 then --x tunnel
          xDir = 1 * (random(1,2) == 1 and -1 or 1)
          tunnelDist = random(3,math.max(width/5))
        else --y tunnel
          yDir = 1 * (random(1,2) == 1 and -1 or 1)
          tunnelDist = random(3,math.max(height/5))
        end --end x/y tunnel if
      else --don't tunnel, just walk randomly
        if random(1,2) == 1 then --x walk
          walkerX = walkerX + 1 * (random(1,2) == 1 and -1 or 1)
        else --y tunnel
          walkerY = walkerY + 1 * (random(1,2) == 1 and -1 or 1)
        end
      end --end new tunnel or random if
    end --end tunnel/notunnel if
    --Make sure we're not going out of bounds:
    walkerX = math.min(math.max(walkerX,2),width-1)
    walkerY = math.min(math.max(walkerY,2),height-1)
  end
end
layouts['drunkwalker'] = drunkwalker

local blob = function(map,width,height,blobDecay,fillAmount)
  blobDecay = blobDecay or 10
  fillAmount = fillAmount or random(45,55)
  local midX,midY = math.max(width/2),math.max(height/2)
  local totalTiles = (width-2)*(height-2) -- -2 because 1 and max are never going to be floors
  local floorTiles = 0
  local points = {{x=round(midX),y=round(midY),spreadChance=100}}
  local borders = {}
  while count(points) >= 1 do
    local pID = next(points)
    local point = points[pID]
    table.remove(points,pID)
    if not map:in_map(point.x,point.y) then
      point.x = math.min(math.max(point.x,2),width-1)
      point.y = math.min(math.max(point.y,2),height-1)
    end
    map[point.x][point.y] = "."
    floorTiles = floorTiles + 1
    if 1==1 or random(1,100) <= point.spreadChance then
      for x=point.x-1,point.x+1,1 do
        for y=point.y-1,point.y+1,1 do
          if x > 1 and x < width and y > 1 and y < height and (x == point.x or y == point.y) and not (x==point.x and y==point.y) and map[x][y] ~= "." then
            if random(1,100) <= point.spreadChance then
              points[#points+1] = {x=x,y=y,spreadChance=point.spreadChance-blobDecay}
            end
          end --end bounds check
        end --end fory
      end --end forx
    end --end spread for
    if count(points) < 1 and (floorTiles/totalTiles)*100 < fillAmount then --if this blob is dead but we still haven't filled enough of the map, make a new blob!
      local x,y = random(2,width-1),random(2,height-1)
      while map[x][y] == "." do
        x,y = random(2,width-1),random(2,height-1)
      end
      points = {{x=x,y=y,spreadChance=100}}
    end --end fill amount if
  end --end point while
end
layouts['blob'] = blob

local maze = function (map,width,height,size,extraWallPercent,mazeOnly)
  size = size or 3
  extraWallPercent=0 or 0
  
  --First, create a maze full of cells that don't link to any other cells:
  local tilesX,tilesY = math.floor(width/(size+2)), math.floor(height/(size+2))
  local tiles = {}
  local deadEnds = {}
  local cells = 0
  for tx = 1,tilesX,1 do
    tiles[tx] = {}
    for ty = 1,tilesY,1 do
      --(tilesX-1)*(size+2) is the last tile's ending square. We add 1 because we're 1 after it,
      tiles[tx][ty] = {n=false,s=false,e=false,w=false,visited=false,tx=tx,ty=ty,startX=1+((tx-1)*(size+2)),endX=tx*(size+2),startY=1+((ty-1)*(size+2)),endY=ty*(size+2)}
      cells = cells + 1
    end --end ty for
  end -- end tx for
  
  --Now, actually travel through the maze, creating exits as you go:
  local cx,cy = random(tilesX),random(tilesY) --pick a random tyle
  local moves = {}
  local visited = 0
  while (visited<cells) do
    local possibilities = {}
    if (cx > 1 and tiles[cx-1][cy].visited == false) then possibilities.w=true end
    if (cx < tilesX and tiles[cx+1][cy].visited == false) then possibilities.e=true end
    if (cy > 1 and tiles[cx][cy-1].visited == false) then possibilities.n=true end
    if (cy < tilesY and tiles[cx][cy+1].visited == false) then possibilities.s=true end
    if (next(possibilities) ~= nil) then -- if there is anywhere to go
      moves[#moves+1] = {x=cx,y=cy}
      visited = visited+1
      local dir = get_random_key(possibilities)
      if (dir=="n") then
        tiles[cx][cy].n=true
        tiles[cx][cy-1].s=true
        cy=cy-1 --move to the new tile
      elseif (dir=="s") then
        tiles[cx][cy].s=true
        tiles[cx][cy+1].n=true
        cy=cy+1 --move to the new tile
      elseif (dir=="w") then
        tiles[cx][cy].w=true
        tiles[cx-1][cy].e=true
        cx=cx-1 --move to the new tile
      elseif (dir=="e") then
        tiles[cx][cy].e=true
        tiles[cx+1][cy].w=true
        cx=cx+1 --move to the new tile
      end --end direction check
      tiles[cx][cy].visited = true
    else --if there are no unvisited tiles near the current tile
      local tile = tiles[cx][cy]
      local exits = (tile.n and 1 or 0) + (tile.s and 1 or 0) + (tile.e and 1 or 0) + (tile.w and 1 or 0)
      if (exits == 1) then deadEnds[#deadEnds+1] = {x=cx,y=cy} end
      if moves[#moves-1] then cx,cy = moves[#moves-1].x,moves[#moves-1].y end --go back a space
      moves[#moves] = nil --remove reference to being where you were
    end --end if checking if there are places to go
  end --end while
  
  --Figure out which "rooms" are farthest from each other, and make them the entrance and exit
  local farthestDist = 0
  local farthest1 = {}
  local farthest2 = {}
  for id, coords in pairs(deadEnds) do
    local cx,cy = coords.x,coords.y
    local partner = deadEnds[next(deadEnds,id)]
    if (partner) then
      local px,py = partner.x,partner.y
      local dist = calc_distance_squared(cx,cy,px,py)
      if dist > farthestDist then
        farthest1 = {id=id, x=cx,y=cy}
        farthest2 = {id=id, x=px,y=py}
        farthestDist = dist
      end --end farthest if
    end --end partner if
  end
  
  if farthestDist > 0 then
    map.stairsUp.x,map.stairsUp.y = farthest1.x,farthest1.y
    map.stairsDown.x,map.stairsDown.y = farthest2.x,farthest2.y
    table.remove(deadEnds,farthest1.id)
    table.remove(deadEnds,farthest2.id)
  end
  
  --Add extra openings to the dead ends
  for _,coords in pairs(deadEnds) do
    local cx,cy = coords.x,coords.y
    local possibilities = {}
    if (cx > 1 and tiles[cx][cy].w ~= true and (map.stairsDown.x ~= cx-1 or map.stairsDown.y ~= cy) and (map.stairsUp.x ~= cx-1 or map.stairsUp.y ~= cy)) then possibilities.w=true end
    if (cx < tilesX and tiles[cx][cy].e ~= true and (map.stairsDown.x ~= cx+1 or map.stairsDown.y ~= cy) and (map.stairsUp.x ~= cx+1 or map.stairsUp.y ~= cy)) then possibilities.e=true end
    if (cy > 1 and tiles[cx][cy].n ~= true and (map.stairsDown.x ~= cx or map.stairsDown.y ~= cy-1) and (map.stairsUp.x ~= cx or map.stairsUp.y ~= cy-1)) then possibilities.n=true end
    if (cy < tilesY and tiles[cx][cy].s ~= true and (map.stairsDown.x ~= cx or map.stairsDown.y ~= cy+1) and (map.stairsUp.x ~= cx or map.stairsUp.y ~= cy+1)) then possibilities.s=true end
    if (next(possibilities) ~= nil) then -- if there is anywhere to go
      local dir = get_random_key(possibilities)
      if (dir=="n") then
        tiles[cx][cy].n=true
        tiles[cx][cy-1].s=true
      elseif (dir=="s") then
        tiles[cx][cy].s=true
        tiles[cx][cy+1].n=true
      elseif (dir=="w") then
        tiles[cx][cy].w=true
        tiles[cx-1][cy].e=true
      elseif (dir=="e") then
        tiles[cx][cy].e=true
        tiles[cx+1][cy].w=true
      end --end if checking direcitons
    end --end if next(possibilities)
  end --end deadends for
  
  --Add broken walls for some variety
  local brokenWalls = math.ceil(cells*(extraWallPercent/100))-- random(20,25)
  while (brokenWalls >= 1) do
    local cx,cy = random(tilesX),random(tilesY)
    local possibilities = {}
    if (cx > 1 and tiles[cx][cy].w ~= true) then possibilities.w=true end
    if (cx < tilesX and tiles[cx][cy].e ~= true) then possibilities.e=true end
    if (cy > 1 and tiles[cx][cy].n ~= true) then possibilities.n=true end
    if (cy < tilesY and tiles[cx][cy].s ~= true) then possibilities.s=true end
    if (next(possibilities) ~= nil) then -- if there is anywhere to go
      brokenWalls = brokenWalls-1
      local dir = get_random_key(possibilities)
      if (dir=="n") then
        tiles[cx][cy].n=true
        tiles[cx][cy-1].s=true
      elseif (dir=="s") then
        tiles[cx][cy].s=true
        tiles[cx][cy+1].n=true
      elseif (dir=="w") then
        tiles[cx][cy].w=true
        tiles[cx-1][cy].e=true
      elseif (dir=="e") then
        tiles[cx][cy].e=true
        tiles[cx+1][cy].w=true
      end --end if checking direcitons
    end --end if next(possibilities)
  end --end broken walls while
  if mazeOnly then return tiles,tilesX,tilesY end
  print('not maze only!')
  
  local placedUp = false
  local placedDown = false
  -- Actually draw the maze:
  for tx = 1,tilesX,1 do
    --(tilesX-1)*(size+2) is the last tile's ending square. We add 1 because we're 1 after it,
    local startX = 1+((tx-1)*(size+2))
    for ty = 1,tilesY,1 do
      local startY = 1+((ty-1)*(size+2))
      for x=startX,startX+size+1,1 do
        for y=startY,startY+size+1,1 do
          if ((y>startY and y<startY+size+1 and x>startX and x<startX+size+1) or (y==startY and x ~= startX and x~=startX+size+1 and tiles[tx][ty]['n'] == true) or (y==startY+size+1 and x~=startX and x ~= startX+size+1 and tiles[tx][ty]['s'] == true) or (x==startX and y~= startY and y~=startY+size+1 and tiles[tx][ty]['w'] == true) or (x==startX+size+1 and y~=startY and y~=startY+size+1 and tiles[tx][ty]['e'] == true)) and (y>1 and x>1 and y<height and x<width) then --oh dear god basically this is all to preserve the corners
            if map.stairsUp.x == tx and map.stairsUp.y == ty and placedUp == false then
              map.stairsUp.x,map.stairsUp.y = x,y
              placedUp = true
            elseif map.stairsDown.x == tx and map.stairsDown.y == ty and placedDown == false then
              map.stairsDown.x,map.stairsDown.y = x,y
              placedDown = true
            else map[x][y] = "." end --if it's not a stair, its a square
          end --end if
        end -- end y for
      end --end x for
    end -- end ty for
  end -- end tx for
  return tiles,tilesX,tilesY
end
layouts['maze'] = maze

local caveMaze =  function(map,width,height,size,extraWallPercent)
  size = size or 5
  local tiles,tilesX,tilesY = layouts['maze'](map,width,height,size,extraWallPercent,true)
  
  for tx = 1,tilesX,1 do
    for ty = 1,tilesY,1 do
      local startX = tiles[tx][ty].startX
      local endX = tiles[tx][ty].endX
      local midX = math.floor((startX+endX)/2)
      local startY = tiles[tx][ty].startY
      local endY = tiles[tx][ty].endY
      local midY = math.floor((startY+endY)/2)
      
      --Place stairs
      if map.stairsUp.x == tx and map.stairsUp.y == ty then
        map.stairsUp.x,map.stairsUp.y = midX,midY
        map[midX][midY] = "<"
      elseif map.stairsDown.x == tx and map.stairsDown.y == ty then
        map.stairsDown.x,map.stairsDown.y = midX,midY
        map[midX][midY] = ">"
      end
            
      
      if tiles[tx][ty].n then
        local hallwidth = random(1,2)
        for y = startY,midY,1 do
          hallwidth = math.max(math.min(hallwidth+random(-1,1),1),2)
          for x = midX-random(0,hallwidth),midX+random(0,hallwidth),1 do
            if x > 1 and y > 1 and x < width and y < height then map[x][y] = "." end
          end --end forx
        end --end fory
      end --end north
      
      if tiles[tx][ty].s then
        local hallwidth = random(1,2)
        for y = endY,midY,-1 do
          hallwidth = math.max(math.min(hallwidth+random(-1,1),1),2)
          for x = midX-random(0,hallwidth),midX+random(0,hallwidth),1 do
            if x > 1 and y > 1 and x < width and y < height then map[x][y] = "." end
          end --end forx
        end --end fory
      end
      
      if tiles[tx][ty].e then
        local hallwidth = random(1,2)
        for x = endX,midX,-1 do
          hallwidth = math.max(math.min(hallwidth+random(-1,1),1),2)
          for y = midY-random(0,hallwidth),midY+random(0,hallwidth),1 do
            if x > 1 and y > 1 and x < width and y < height then map[x][y] = "." end
          end --end forx
        end --end fory
      end
      
      if tiles[tx][ty].w then
        local hallwidth = random(1,2)
        for x = startX,midX,1 do
          hallwidth = math.max(math.min(hallwidth+random(-1,1),1),2)
          for y = midY-random(0,hallwidth),midY+random(0,hallwidth),1 do
            if x > 1 and y > 1 and x < width and y < height then map[x][y] = "." end
          end --end forx
        end --end fory
      end
    end
  end
  return tiles,tilesX,tilesY
end
layouts['cavemaze'] = caveMaze

local bspTree = function (map,width,height,doorChance,wideChance,rectChance,politeTunnelPasses,rudeTunnelPasses)
  doorChance = doorChance or 50
  wideChance = wideChance or 50
  rectChance = rectChance or 50
  politeTunnelPasses = politeTunnelPasses or 1
  rudeTunnelPasses = rudeTunnelPasses or 1
  local tree = {}
  --Initial split:
  if (random(1,2) == 1) then --ew split
    local splitLine = random(10,width-10)
    local branch1 = {x=2,y=2,maxX=splitLine-1,maxY=height-1}
    local branch2 = {x=splitLine+1,y=2,maxX=width-1,maxY=height-1}
    tree[1] = {branch1,branch2}
  else --ns split
    local splitLine = random(10,height-10)
    local branch1 = {x=2,y=2,maxX=width-1,maxY=splitLine-1}
    local branch2 = {x=2,y=splitLine+1,maxX=width-1,maxY=height-1}
    tree[1] = {branch1,branch2}
  end
  
  --Split the splits:
  for i=1,math.floor(((width+height)/2)/10),1 do --split it 1 time for every 10 size (avg x and y) eg. 50x50 split 5 times, 100x100 split 10 times
    if tree[i+1] == nil then tree[i+1] = {} end
    for _,branch in pairs(tree[i]) do
      local xSize,ySize = branch.maxX-branch.x,branch.maxY-branch.y
      --Only split x if (x is big enough and y isn't already too much bigger than x) AND (y is too small or x is too big or a coin flip tells you to)
      if (xSize >= 15 and ySize<=xSize*2) and (ySize < 15 or xSize>ySize*2 or random(1,2) == 1) then --ew split
        local splitLine = random(branch.x+4,branch.maxX-4)
        local branch1 = {x=branch.x,y=branch.y,maxX=splitLine-1,maxY=branch.maxY}
        local branch2 = {x=splitLine+1,y=branch.y,maxX=branch.maxX,maxY=branch.maxY}
        table.insert(tree[i+1],branch1)
        table.insert(tree[i+1],branch2)
      elseif (ySize >= 15) then --ns split, only if y is big enough
        local splitLine = random(branch.y+4,branch.maxY-4)
        local branch1 = {x=branch.x,y=branch.y,maxX=branch.maxX,maxY=splitLine-1}
        local branch2 = {x=branch.x,y=splitLine+1,maxX=branch.maxX,maxY=branch.maxY}
        table.insert(tree[i+1],branch1)
        table.insert(tree[i+1],branch2)
      else --if neither x nor y are big enough to split, don't split them, just add the room to the next-lowest branch
        table.insert(tree[i+1],branch)
      end --end direction if
    end --end branch for
  end --end for loop
  
  --Place rooms:
  local rooms = {}
  for id,branch in ipairs(tree[#tree]) do
    local minX,maxX = math.ceil(random(branch.x,branch.x+(branch.maxX-branch.x)/5)),math.floor(random(branch.x+(branch.maxX-branch.x)/5*4,branch.maxX))
    local minY,maxY = math.ceil(random(branch.y,branch.y+(branch.maxY-branch.y)/5)),math.floor(random(branch.y+(branch.maxY-branch.y)/5*4,branch.maxY))
    if (maxX-minX >= 4 and maxY-minY >= 4) then -- Only make a room if it's big enough
      rooms[#rooms+1] = generate_room(minX,minY,maxX,maxY,map,rectChance)
    end --end size check if
  end --end branch for

  --Make corridors:
  local hallways = {}
  --Make collision maps for the corridors and intialize pathfinder:
  local Grid = require('lib.jumper.grid')
  local Pathfinder = require 'lib.jumper.pathfinder'
  local colMap = {avoidEmpty={},anythingGoes={}}
  for y=1,height,1 do
    colMap.avoidEmpty[y] = (colMap.avoidEmpty[y] or {})
    colMap.anythingGoes[y] = (colMap.anythingGoes[y] or {})
    for x=1,width,1 do
      if x==1 or y==1 or x==width or y==height then
        colMap.avoidEmpty[y][x] = 1
        colMap.anythingGoes[y][x] = 1
      else
        colMap.avoidEmpty[y][x] = (map[x][y] == "#" and 0 or 1)
        if (map[x-1][y] == "." or map[x+1][y] == "." or map[x][y-1] == "." or map[x][y+1] == "." or map[x-1][y-1] == "." or map[x-1][y+1] == "." or map[x+1][y-1] == "." or map[x+1][y+1] == ".") then colMap.avoidEmpty[y][x] = 1 end --if you're directly next to an open space, count as an open space
        colMap.anythingGoes[y][x] = 0
      end
    end --end forx
  end --end fory
  
  --Holders for the "farthest" variables, used to determine which room to put the stairs in
  local farthest = 0
  local farthest1 = nil
  local farthest2 = nil

  --"Polite" tunnels that go around rooms (but can cross other tunnels):
  for i = 1,politeTunnelPasses,1 do
    rooms = shuffle(rooms)
    local avoidGrid = Grid(colMap.avoidEmpty)
    local avoidFinder = Pathfinder(avoidGrid,'JPS',0)
    avoidFinder:setMode('ORTHOGONAL')
    for id,room in pairs(rooms) do
      local partnerID = next(rooms,id)
      if partnerID then
        local partner = rooms[partnerID]
        --How far away is your partner? If they're farther than the farthest checked partners, set them as the stair rooms!
        local dist = calc_distance_squared((room.minX+room.maxX)/2,(room.minY+room.maxY)/2,(partner.minX+partner.maxX)/2,(partner.minY+partner.maxY)/2)
        if dist >= farthest then
          farthest = dist
          farthest1,farthest2 = room,partner
        end
        --Determine which possible walls would be best for the tunnel:
        local possibleWalls = {room={},partner={}}
        if partner.maxX>room.maxX then possibleWalls.room.e = true possibleWalls.partner.w = true end
        if partner.maxY>room.maxY then possibleWalls.room.n = true possibleWalls.partner.s = true end
        if partner.minX<room.minX then possibleWalls.room.w = true possibleWalls.partner.e = true end
        if partner.minY<room.minY then possibleWalls.room.s = true possibleWalls.partner.n = true end
        local roomWall = get_random_key(possibleWalls.room)
        local partnerWall = get_random_key(possibleWalls.partner)
        --Pick one of the walls and set starting locations:
        local startX,startY = 0,0
        local endX,endY = 0,0
        while startX == 0 and startY == 0 do
          local startWall = get_random_element(room.dirWalls[roomWall])
          if (startWall.x ~= room.minX and startWall.x ~= room.maxX) or (startWall.y ~= room.minY and startWall.y ~= room.maxY) then
            startX,startY = startWall.x,startWall.y
          end --end wall-not-on-corner check
        end --end startXY while
        while endX == 0 and endY == 0 do
          local endWall = get_random_element(partner.dirWalls[partnerWall])
          if (endWall.x ~= partner.minX and endWall.x ~= partner.maxX) or (endWall.y ~= partner.minY and endWall.y ~= partner.maxY) then
            endX,endY = endWall.x,endWall.y
          end --end wall-not-on-corner check
        end --end endXY while
        if (roomWall == "n" or roomWall == "s") then
          startY = (roomWall == "n" and startY-1 or startY+1)
        elseif (roomWall =="e" or roomWall == "w") then
          startX = (roomWall == "w" and startX-1 or startX+1)
        end
        if (partnerWall == "n" or partnerWall == "s") then
          endY = (partnerWall == "n" and endY-1 or endY+1)
        elseif (partnerWall =="e" or partnerWall == "w") then
          endX = (partnerWall == "w" and endX-1 or endX+1)
        end
        --Path, avoiding empty space
        colMap.avoidEmpty[startX][startY] = 0
        colMap.avoidEmpty[endX][endY] = 0
        local path = avoidFinder:getPath(startX,startY,endX,endY,false)
        local wideHall = random(1,100) <= wideChance and true or false
        if path then
          local hallID = #hallways+1
          hallways[hallID] = {base={},startRoom=room,endRoom=partner}
          for stepNum,node in pairs(path) do
            if (node.x and node.y) then
              map[node.x][node.y] = "."
              --colMap.avoidEmpty[node.y][node.x] = 1
              table.insert(hallways[hallID].base,{x=node.x,y=node.y})
              if (wideHall) then
                hallways[hallID].wide = {}
                for x=node.x-1,node.x+1,1 do
                  for y=node.y-1,node.y+1,1 do
                    if x>1 and y>1 and x<width and y<height then
                      local makeIt = true
                      for _, room in pairs(rooms) do
                        if (x>=room.minX and x<=room.maxX) and (y>=room.minY and y<=room.maxY) then
                          makeIt = false
                          break
                        end --end wall check if
                      end --end room for
                      if (makeIt) then
                        table.insert(hallways[hallID].wide,{x=x,y=y})
                        map[x][y] = "."
                        --colMap.avoidEmpty[y][x] = 1
                      end --end makeIt if
                    end --end x/y check
                  end --end fory
                end --end forx
              end --end wideHall if
            end --end node if
          end --end path for
          if startX>2 and map[startX-2][startY] == "." then map[startX-1][startY] = "." end
          if startX<width-2 and map[startX+2][startY] == "." then map[startX+1][startY] = "." end
          if endY>2 and map[startX][startY-2] == "." then map[startX][startY-1] = "." end
          if startY<height-2 and map[startX][startY+2] == "." then map[startX][startY+1] = "." end
          if endX>2 and map[endX-2][endY] == "." then map[endX-1][endY] = "." end
          if endX<width-2 and map[endX+2][endY] == "." then map[endX+1][endY] = "." end
          if endY>2 and map[endX][endY-2] == "." then map[endX][endY-1] = "." end
          if endY<height-2 and map[endX][endY+2] == "." then map[endX][endY+1] = "." end
        end --end path if
      end --end partner if
    end --end room for
  end --end politetunnelpasses for
    
  --"Rude" tunnels that can run through other rooms:
  for i = 1,rudeTunnelPasses,1 do
    rooms = shuffle(rooms)
    local anyGrid = Grid(colMap.anythingGoes)
    local anyFinder = Pathfinder(anyGrid,'JPS',0)
    anyFinder:setMode('ORTHOGONAL')
    for id,room in pairs(rooms) do
      local startTile = get_random_element(room.floors)
      local startX,startY = startTile.x,startTile.y
      local partner = rooms[next(rooms,id)]
      if partner then
        local hallID = #hallways+1
        hallways[hallID] = {base={},startRoom=room,endRoom=partner}
        --Set endpoint of tunnel to a random point in the partner room:
        local endTile = get_random_element(partner.floors)
        local endX,endY = endTile.x,endTile.y
        local path = anyFinder:getPath(startX,startY,endX,endY,false)
        local wideHall = (random(1,100) <= wideChance) and true or false
        for _,node in pairs(path) do
          if (node.x and node.y) then
            table.insert(hallways[hallID].base,{x=node.x,y=node.y})
            map[node.x][node.y] = "."
            if (wideHall) then
              hallways[hallID].wide = {}
              for x=node.x-1,node.x+1,1 do
                for y=node.y-1,node.y+1,1 do
                  if x>1 and y>1 and x<width and y<height then
                    local makeIt = true
                    for _, room in pairs(rooms) do
                      if (x>=room.minX and x<=room.maxX) and (y>=room.minY and y<=room.maxY) then
                        makeIt = false
                        break
                      end --end wall check if
                    end --end room for
                    if (makeIt) then
                      table.insert(hallways[hallID].wide,{x=x,y=y})
                      map[x][y] = "."
                      colMap.avoidEmpty[y][x] = 1
                    end --end makeIt if
                  end --end x/y check
                end --end fory
              end --end forx
            end --end wideHall if
          end --end node if
        end --end path for
      end --end partner if
    end --end room for
  end --end roomtunnelpassesfor
  
  --Put in the stairs
  if farthest > 0 then
    local upRoom = farthest1
    local downRoom = farthest2
    local point1x,point1y = math.floor(upRoom.minX+(upRoom.maxX-upRoom.minX)/2),math.floor(upRoom.minY+(upRoom.maxY-upRoom.minY)/2)
    local point2x,point2y = math.floor(downRoom.minX+(downRoom.maxX-downRoom.minX)/2),math.floor(downRoom.minY+(downRoom.maxY-downRoom.minY)/2)
    farthest1.exit = true
    rooms.exit = farthest1
    farthest2.entrance = true
    rooms.entrance = farthest2
    map.stairsUp.x,map.stairsUp.y = point1x,point1y
    map.stairsDown.x,map.stairsDown.y = point2x,point2y
  end
  
  --Finally, put in doors:
  if (doorChance > 0) then
    for id, room in ipairs(rooms) do
      local doors = {}
      if (random(1,100) <= doorChance) then
        for _,wall in pairs(room.walls) do
          if map[wall.x][wall.y] == "." and ((map[wall.x-1][wall.y] == "#" and map[wall.x+1][wall.y] == "#" and map[wall.x][wall.y-1] == "." and map[wall.x][wall.y+1] == ".") or (map[wall.x][wall.y-1] == "#" and map[wall.x][wall.y+1] == "#" and map[wall.x-1][wall.y] == "." and map[wall.x+1][wall.y] == ".")) then
            doors[#doors+1] = {x=wall.x,y=wall.y}
            map:add_feature(Feature('door'),wall.x,wall.y)
          end --end bordered-by-walls check
        end --end wall for
        --[[for x=room.minX+1,room.maxX-1,1 do
          if map[x][room.minY] == "." and map[x-1][room.minY] == "#" and map[x+1][room.minY] == "#" then
            doors[#doors+1] = {x=x,y=room.minY}
            map:add_feature(Feature('door'),x,room.minY)
          end
          if map[x][room.maxY] == "." and map[x-1][room.maxY] == "#" and map[x+1][room.maxY] == "#" then
            doors[#doors+1] = {x=x,y=room.maxY}
            map:add_feature(Feature('door'),x,room.maxY)
          end
        end --end xfor
        for y=room.minY+1,room.maxY-1,1 do
          if map[room.minX][y] == "." and map[room.minX][y-1] == "#" and map[room.minX][y+1] == "#" then
            doors[#doors+1] = {x=room.minX,y=y}
            map:add_feature(Feature('door'),room.minX,y)
          end
          if map[room.maxX][y] == "." and map[room.maxX][y-1] == "#" and map[room.maxX][y+1] == "#" then
            doors[#doors+1] = {x=room.maxX,y=y}
            map:add_feature(Feature('door'),room.maxX,y)
          end
        end --end yfor]]
      end --end door if
      room.doors = doors
    end --end room for
  end --end door if
  return rooms, hallways
end --end bsptree function
layouts['bsptree'] = bspTree

--Arguments: doorChance,corridorChance,wideChance,rectChance,maxRoomSize,maxCorridorlength
local broguelike = function(map,width,height,arguments)
  arguments = arguments or {}
  local doorChance = arguments.doorChance or 50
  local corridorChance = arguments.corridorChance or 50
  local wideChance = arguments.wideChance or 50
  local rectChance = arguments.rectChance or 100
  local maxRoomSize = arguments.maxDimensions or 10
  local maxCorridorLength = arguments.maxCorridorLength or 10
  
  local rooms = {}
  local roomMap = {}
  for x = 1,map.width,1 do
    roomMap[x] = {}
    for y = 1,map.height,1 do
      roomMap[x][y] = false
    end --end fory
  end --end forx
  
  local minX,minY = random(2,map.width-10),love.math.random(2,map.height-10)
  local maxX,maxY = math.min(love.math.random(minX,minX+10),map.width-1),math.min(love.math.random(minY,minY+10),map.height-1)
  rooms[#rooms+1] = generate_room(minX,minY,maxX,maxY,map,rectChance)
  
  for _,tile in pairs(rooms[1].floors) do
    roomMap[tile.x][tile.y] = 1
  end
  for _,tile in pairs(rooms[1].walls) do
    roomMap[tile.x][tile.y] = 1
  end
  
  local currRoom = rooms[1]
  local directions = {'n','s','e','w'}
  local newRoom = false
  local mapCount = 1
  while (mapCount < 100) do --try to make 100 rooms
    if newRoom then
      currRoom = rooms[random(#rooms)]
      --select a random new room
      newRoom = false
    end
    local made = false
    local roomCount = 1
    while (roomCount < 10 and made == false) do --try 10 tiles per room
      local roomGrid = Map(maxRoomSize,maxRoomSize,true)
      local dir = get_random_element(directions)
      local wallTile = get_random_element(currRoom.dirWalls[dir])
      local tileCount = 1
      local make = false
      while (tileCount < 5 and make == false) do --try 10 times per tile
        local sizeX, sizeY = random(3,maxRoomSize),random(3,maxRoomSize) --room dimensions can't be smaller than 3
        local room = generate_room(1,1,sizeX,sizeY,roomGrid,rectChance)
        local startX,startY = 2,2
        if dir == "n" then
          startY = wallTile.y-sizeY
          startX=wallTile.x-math.ceil(sizeX/2)
        elseif dir == "s" then
          startY = wallTile.y
          startX=wallTile.x-math.ceil(sizeX/2)
        elseif dir == "e" then
          startX = wallTile.x
          startY=wallTile.y-math.ceil(sizeY/2)
        elseif dir == "w" then
          startX = wallTile.x-sizeX
          startY=wallTile.y-math.ceil(sizeY/2)
        end
        if startX < 2 then
          startX=startX+(startX-1)
        end
        if startY < 2 then
          startY=startY+(startY-1)
        end
        if startX+sizeX >= map.width then
          startX=startX-(map.width-(startX+sizeX)-1)
        end
        if startY+sizeY >= map.height then
          startY=startY-(map.height-(startY+sizeY)-1)
        end
        make = true
        for x = 1,sizeX,1 do
          for y = 1,sizeY,1 do
            if map:in_map(startX+x,startY+y) == false or (roomGrid[x][y] == "." and roomMap[startX+x][startY+y] ~= false) then
              if (roomGrid[x][y] == "." and roomMap[startX+x][startY+y] ~= false) then
                print('not working: ' .. startX+x .. ", " .. startY+y)
              else
                print('out of range: ' .. startX+x .. ", " .. startY+y)
              end
              make = false
              break
            end --end check if
          end --end fory
          if make == false then break end
        end --end forx
        if make == true then
          if dir == "n" then startY=startY+1
          elseif dir == "s" then startY=startY-1
          elseif dir == "e" then startX=startX-1
          elseif dir == "w" then startX=startX+1 end
          for x = 1,sizeX,1 do
            for y = 1,sizeY,1 do
              if roomGrid[x][y] == "." then
                map[startX+x][startY+y] = #rooms+1
              end -- end if roomGrid
            end --end fory
          end --end forx
          for _,tile in pairs(room.floors) do
            tile.x=tile.x+startX
            tile.y=tile.y+startY
            roomMap[tile.x][tile.y] = #rooms+1
          end
          for _,tile in pairs(room.walls) do
            tile.x=tile.x+startX
            tile.y=tile.y+startY
            roomMap[tile.x][tile.y] = #rooms+1
          end
          for dir,_ in pairs(room.dirWalls) do
            for _, tile in pairs(room.dirWalls[dir]) do
              tile.x=tile.x+startX
              tile.y=tile.y+startY
            end
          end
          map:add_feature(Feature('door'),wallTile.x,wallTile.y)
          rooms[#rooms+1] = room
          currRoom = room
          made = true
        end --end make if
        tileCount = tileCount+1
      end --end tile for
      roomCount = roomCount+1
    end --end room while
    if made == false then --if you couldn't make a new room, start looking at a random room now
      newRoom = true
    else
      made = false
    end
    mapCount = mapCount+1
  end --end map for
end
--layouts['broguelike'] = broguelike

--This is actually not too terrible at providing a basic open space that doesn't look totally square.
--Just figure out how to put interesting stuff in the middle and you should be golden
local growOut = function(map,width,height,depth)
  for x=2,width-1,1 do
    for y=2,height-1,1 do
      map[x][y] = "."
    end
  end
  
  for x=2,width-1,1 do --go along top & bottom
    local growth = 1
    while (random(1,growth) < 5-(random(1,growth))) do
      if random(1,4) ~= 1 then map[x][1+growth] = "#" end
      growth = growth + 1
    end
    growth = 1
    while (random(1,growth) < 5-(random(1,growth))) do
      if random(1,4) ~= 1 then map[x][height-growth] = "#" end
      growth = growth + 1
    end
  end
  for y=2,height-1,1 do --go along left & right
    local growth = 1
    while (random(1,growth) < 5-(random(1,growth))) do
      if random(1,4) ~= 1 then map[1+growth][y] = "#" end
      growth = growth + 1
    end
    growth = 1
    while (random(1,growth) < 5-(random(1,growth))) do
      if random(1,4) ~= 1 then map[width-growth][y] = "#" end
      growth = growth + 1
    end
  end
  
  --Now drop some random shit down:
  for i=1,random(5,5),1 do
    local w,h = random(1,3),random(1,3)
    local centerX,centerY = random(w*2,width-w*2-1),random(h*2,height-h-1)
    for x=centerX-w,centerX+w,1 do
      for y=centerY-h,centerY+h,1 do
        map[x][y] = "#"
        local growth = 1
      while (random(1,growth) < 5-(random(1,growth)) and (centerX-w-growth) > 1) do
        if random(1,4) ~= 1 then map[centerX-w-growth][y] = "#" end
        growth = growth + 1
        centerX = centerX+random(-1,1)
      end --end while
      growth = 1
      while (random(1,growth) < 5-(random(1,growth)) and (centerX+w+growth) < width) do
        if random(1,4) ~= 1 then map[centerX+w+growth][y] = "#" end
        growth = growth + 1
        centerX = centerX+random(-1,1)
      end --end while
      end --end fory
      --Grow the X
      local growth = 1
      while (random(1,growth) < 5-(random(1,growth)) and (centerY-h-growth) > 1) do
        if random(1,4) ~= 1 then map[x][centerY-h-growth] = "#" end
        growth = growth + 1
        centerY = centerY+random(-1,1)
      end --end while
      growth = 1
      while (random(1,growth) < 5-(random(1,growth)) and (centerY+h+growth) < height) do
        if random(1,4) ~= 1 then map[x][centerY+h+growth] = "#" end
        growth = growth + 1
        centerY = centerY+random(-1,1)
      end --end while
    end --end forx
  end--end dropping shit loop
end
--layouts['growOut'] = growOut


--Unused layouts:
diggerMaze = function(build,width,height,depth)
	-- Tunnels made with Diggers, with random open spaces included
	-- first fill everything in:
	for x=1, width, 1 do
		for y=1,height,1 do
			if (depth > 1 and maps[depth-1][x][y] == ">") then -- if there's a stairway above us
				build[x][y] = "<"
			else
				build[x][y]="#"
			end
		end
	end
	
	local diggers = {}
		
	-- put in the stairs:
	for i=1,random(2,5),1 do
		local newX = random(2,width-1)
		local newY = random(2,width-1)
		build[newX][newY] = ">"
		local nD = digger:new(newX,newY)
		local nD2 = digger:new(newX,newY)
		while (nD2.direction == nD.direction) do
			nD2:turn()
		end
		table.insert(diggers,nD)
		table.insert(diggers,nD2)
	end
	
	-- put baby (diggers) in the corner
	table.insert(diggers,digger:new(2,2,2))
	table.insert(diggers,digger:new(2,2,3))
	table.insert(diggers,digger:new(width-1,2,3))
	table.insert(diggers,digger:new(width-1,2,4))
	table.insert(diggers,digger:new(2,height-1,1))
	table.insert(diggers,digger:new(2,height-1,2))
	table.insert(diggers,digger:new(width-1,height-1,1))
	table.insert(diggers,digger:new(width-1,height-1,4))
	for i=1,random(10,15),1 do
		local newX,newY = random(2,width-1),random(2,height-1)
		local nD,nD2 = digger:new(newX,newY),digger:new(newX,newY)
		while (nD2.direction == nD.direction) do
			nD2:turn()
		end
		table.insert(diggers,nD)
		table.insert(diggers,nD2)
	end
	while(#diggers > 0) do
		for id, diglet in ipairs(diggers) do
			if (diglet:dig(build) == false) then
				table.remove(diggers,id)
			elseif (random(1,2) == 1) then
				digger:new(diglet.x,diglet.y)
			end
		end
	end
	local caves = random(3,7)
	for c = 1, caves, 1 do
		local xSize = random(1,math.ceil(width/10))
		local ySize = random(1,math.ceil(height/10))
		local x = random(2,width-1)
		local y = random(2,height-1)
		while (build[x][y] ~= ".") do -- start from an existing branch, don't want caves in the middle of nowhere
			x = random(2,width-1)
			y = random(2,height-1)
		end
		
		for mineX = -xSize, xSize, 1 do
			if (x+mineX > 2 and x+mineX < width-1) then
				for mineY = -ySize, ySize, 1 do
					if (y+mineY > 2 and y+mineY < height-1) then
						build[x+mineX][y+mineY] = "."
					end
				end
			end
		end
	end
end
--table.insert(mapTypes,diggerMaze)
local open = function(build,width,height,depth)
	for x = 1, width, 1 do
		for y = 1, height, 1 do
			if (x == 1 or x == width) then
				build[x][y] = "#"
			elseif (y == 1 or y == height) then
				build[x][y] = "#"
			elseif (depth > 1 and maps[depth-1][x][y] == ">") then -- if there's a stairway above us
				build[x][y] = "<"
			else
				build[x][y] = "."
			end
		end
	end
	--[[for structs = 1, (width*height)/100,1 do
		local buildStruct = possibleStructures[random(#possibleStructures)]
		local structX = random(2,width-buildStruct.width-1)
		local structY = random(2,height-buildStruct.height-1)
		if check_structure(buildStruct,build,structX,structY,'.') == true then
			buildStruct:build(build,structX,structY)
		end
	end]]
	-- put in the stairs:
	for i=1,random(2,5),1 do
		local newX = random(2,width-1)
		local newY = random(2,width-1)
		while (build[newX][newY] ~= ".") do
			newX = random(2,width-1)
			newY = random(2,width-1)
		end
		build[newX][newY] = ">"
	end
end
--table.insert(mapTypes,open)

local hallway = function(build,width,height,depth)
	local halltop,hallbottom,hallwest,halleast = height/2-1,height/2+1,width/2-1,width/2+1
	for x=1,width,1 do
		for y = 1,height,1 do
			build[x][y] = "#"
			if (((y>=halltop and y<=hallbottom) or (x>=hallwest and x<=halleast)) and (x~=1 and x~=width and y~=1 and y~=height)) then build[x][y] = "." end
		end
	end
	
	-- Put in the rooms:
	--[[for x=1,build.width,1 do
		local struct = get_random_element(possibleStructures)
		if (struct.exits['s'] ~= nil) then --can link to the north
			local startX,startY = x-(struct.exits['s'][1]-1), halltop-struct.height-1
			if (check_structure(struct,build,startX,startY) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(build,startX,startY,'s')
			end
		end
		
		struct = get_random_element(possibleStructures)
		if (struct.exits['n'] ~= nil) then -- can link to the south
			local startX,startY = x-(struct.exits['n'][1]-1),hallbottom
			if (check_structure(struct,build,startX,startY+1) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(build,startX,startY,'n')
			end
		end
	end
	
	for y=1,build.height,1 do
		local struct = get_random_element(possibleStructures)
		if (struct.exits['e'] ~= nil) then --can link to the north
			local startX,startY = hallwest-struct.width-1, y-(struct.exits['e'][1]-1)
			if (check_structure(struct,build,startX,startY) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(build,startX,startY,'e')
			end
		end
		
		struct = get_random_element(possibleStructures)
		if (struct.exits['w'] ~= nil) then -- can link to the south
			local startX,startY = halleast,(y-struct.exits['w'][1]-1)
			if (check_structure(struct,build,startX+1,startY) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(build,startX,startY,'w')
			end
		end
	end]]
end
--table.insert(mapTypes,hallway)

local hallwayWithCenter = function(build,width,height,depth)
	local halltop,hallbottom,hallwest,halleast = height/2-1,height/2+1,width/2-1,width/2+1
	local radius = math.ceil(math.sqrt(width^2 + height^2)/10)
	local centerX, centerY = math.floor(width/2), math.floor(height/2)
	for x=1,width,1 do
		for y = 1,height,1 do
			build[x][y] = "#"
			if (((y>=halltop and y<=hallbottom) or (x>=hallwest and x<=halleast) or calc_distance(x,y,centerX,centerY) < radius) and (x~=1 and x~=width and y~=1 and y~=height)) then build[x][y] = "." end
		end
	end
	
	-- Put in the rooms:
	--[[for x=1,build.width,1 do
		local struct = get_random_element(possibleStructures)
		if (struct.exits ~= nil and struct.exits['s'] ~= nil) then --can link to the north
			local startX,startY = x-(struct.exits['s'][1]-1), halltop-struct.height-1
			if (check_structure(struct,build,startX,startY) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(build,startX,startY,'s')
			end
		end
		
		struct = get_random_element(possibleStructures)
		if (struct.exits ~= nil and struct.exits['n'] ~= nil) then -- can link to the south
			local startX,startY = x-(struct.exits['n'][1]-1),hallbottom
			if (check_structure(struct,build,startX,startY+1) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(build,startX,startY,'n')
			end
		end
	end
	
	for y=1,build.height,1 do
		local struct = get_random_element(possibleStructures)
		if (struct.exits ~= nil and struct.exits['e'] ~= nil) then --can link to the north
			local startX,startY = hallwest-struct.width-1, y-(struct.exits['e'][1]-1)
			if (check_structure(struct,build,startX,startY) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(build,startX,startY,'e')
			end
		end
		
		struct = get_random_element(possibleStructures)
		if (struct.exits ~= nil and struct.exits['w'] ~= nil) then -- can link to the south
			local startX,startY = halleast,(y-struct.exits['w'][1]-1)
			if (check_structure(struct,build,startX+1,startY) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(build,startX,startY,'w')
			end
		end
	end]]
end
--table.insert(mapTypes,hallwayWithCenter)

local circularHallway = function(map,width,height,depth)
	for x = 10, width-10, 1 do
		for y = 10, height-10, 1 do
			if ( ((y>10 and y<14) or (y>height-14 and y<height-10)) and (x>10 and x<width-10)) then
				map[x][y] = "."
			elseif( ((x>10 and x<14) or (x>width-14 and x<width-10)) and (y>10 and y<width-10)) then
				map[x][y] = "."
			end
		end
	end
	
	--[[for y=11,height-11,1 do
		local struct = get_random_element(possibleStructures)
		if (struct.exits['w'] ~= nil) then --can link to the west
			local startX,startY = width-11, y-(struct.exits['w'][2])
			if (check_structure(struct,map,startX,startY) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(map,startX,startY,'w')
			end
		end
		
		struct = get_random_element(possibleStructures)
		if (struct.exits['e'] ~= nil) then -- can link to the east
			local startX,startY = 10-struct.width,(y-struct.exits['e'][2])
			if (check_structure(struct,map,startX,startY) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(map,startX,startY,'e')
			end
		end
	end
	
	for x=11,width-11,1 do
		local struct = get_random_element(possibleStructures)
		if (struct.exits['n'] ~= nil) then --can link to the north
			local startX,startY = x-struct.exits['n'][1], height-11
			if (check_structure(struct,map,startX,startY) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(map,startX,startY,'n')
			end
		end
		
		struct = get_random_element(possibleStructures)
		if (struct.exits['s'] ~= nil) then -- can link to the south
			local startX,startY = x-struct.exits['s'][1],10-struct.height
			if (check_structure(struct,map,startX,startY) == true) then
				struct.alwaysDoors = true
				struct.min_exits = 1
				struct.max_exits = 1
				struct:build(map,startX,startY,'s')
			end
		end
	end]]
end
--table.insert(mapTypes,circularHallway)

local roomLinker = function(map,width,height,depth)
	for x=1,width,1 do
		for y = 1,height,1 do
			map[x][y] = "#"
		end
	end
	
	-- Build the first structure:
	while (1 == 1) do
		local struct = get_random_element(possibleStructures)
		if (struct.exits ~= nil--[[ and struct.min_exits > 1]]) then
			struct.exits['w'] = nil
			struct.exits['n'] = nil
			if (struct.exits ~= nil) then
				struct.max_exits = 2
				struct.min_exits = 2
				struct.alwaysDoors = true
				struct:build(map,5,5)
				break;
			end
		end
	end
	
	while (map.points ~= nil and #map.points > 0) do
		local newRooms = {}
		for id, point in ipairs(map.points) do
			local dist = random(2,10)
			if (point.direction == "n") then
				for c = 1, dist-1, 1 do map[point.x][point.y-c] = "." end
				table.insert(newRooms,{x=point.x,y=point.y+dist,forceExit = 's'})
				table.remove(map.points,id)
			elseif (point.direction == "s") then
				for c = 1, dist-1, 1 do map[point.x][point.y+c] = "." end
				table.insert(newRooms,{x=point.x,y=point.y+dist,forceExit = 'n'})
				table.remove(map.points,id)
			elseif (point.direction == "e") then
				for c = 1, dist-1, 1 do map[point.x+c][point.y] = "." end
				table.insert(newRooms,{x=point.x+dist,y=point.y,forceExit = 'w'})
				table.remove(map.points,id)
			elseif (point.direction == "w") then
				for c = 1, dist-1, 1 do map[point.x-c][point.y] = "." end
				table.insert(newRooms,{x=point.x-dist,y=point.y,forceExit = 'e'})
				table.remove(map.points,id)
			end
		end
		
		--while (newRooms ~= nil and #newRooms > 0) do
			for id, coords in ipairs(newRooms) do
				local struct = get_random_element(possibleStructures)
				if (struct.exits ~= nil and struct.exits[coords.forceExit] ~= nil) then
					local x,y = coords.x-(struct.exits[coords.forceExit][1] or 0),coords.y-(struct.exits[coords.forceExit][2] or 0)
					if (check_structure(struct,map,x,y) == true) then
						struct.min_exits=struct.max_exits
						struct.alwaysDoors = true
						output:out('building')
						struct:build(map,x,y,coords.forceExit)
						table.remove(newRooms,id)
					end
				end
			end
		end
	--end
end
--table.insert(mapTypes,roomLinker)

local dumbMaze = function(build,width,height,depth)
	-- first fill everything in:
	for x=1, width, 1 do
		build.items[x] = {}
		build[x] = {}
		build.seenMap[x] = {}
		for y=1,height,1 do
			build.items[x][y] = {}
			build.seenMap[x][y] = false
			build[x][y]=1
		end
	end
	
	local branches = random(5,10)
	for i = 1, branches, 1 do
		local turns = random(15,25)
		local x = random(2,width-1)
		local y = random(2,height-1)
		while (i ~= 1 and build[x][y] ~= 0) do -- if this isn't the first branch, start from an existing branch
			x = random(2,width-1)
			y = random(2,height-1)
		end
		build[x][y] = 0
		for t = 1, turns, 1 do
			local direction = random(1,4)
			if (direction == 1) then
				local length = random(5,20)
				for l = 0, length,1 do
					if (y-1 > 1) then
						y = y - 1
						build[x][y] = 0
					end
				end
			elseif (direction == 2) then
				local length = random(5,20)
				for l = 0, length,1 do
					if (x+1 < height) then
						x = x + 1
						build[x][y] = 0
					end
				end
			elseif (direction == 3) then
				local length = random(5,20)
				for l = 0, length,1 do
					if (y+1 < height) then
						y = y + 1
						build[x][y] = 0
					end
				end
			elseif (direction == 4) then
				local length = random(5,20)
				for l = 0, length,1 do
					if (x-1 > 1) then
						x = x - 1
						build[x][y] = 0
					end
				end
			end
		end
	end
	
	local caves = random(5,10)
	for c = 1, caves, 1 do
		local xSize = random(1,5)
		local ySize = random(1,5)
		local x = random(2,width-1)
		local y = random(2,height-1)
		while (build[x][y] ~= 0) do -- start from an existing branch, don't want caves in the middle of nowhere
			x = random(2,width-1)
			y = random(2,height-1)
		end
		
		for mineX = -xSize, xSize, 1 do
			if (x+mineX > 2 and x+mineX < width-1) then
				for mineY = -ySize, ySize, 1 do
					if (y+mineY > 2 and y+mineY < height-1) then
						build[x+mineX][y+mineY] = 0
					end
				end
			end
		end
	end
end
--table.insert(mapTypes,dumbMaze)