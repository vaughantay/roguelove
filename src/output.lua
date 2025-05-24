---@module output
output = {text={},targetLine={},targetTiles={},potentialTargets={},cursorX=0,cursorY=0,mouseX=0,mouseY=0,buffer={},toDisp={{},{},{}},camera={x=1,y=1,xMod=0,yMod=0},shakeTimer=0,shakeDist=0}

---Add text to the output buffer
--@param txt String. The text to print
function output:out(txt)
  if action ~= "dying" then
    local tid = #self.text+1
    self.text[tid] = txt
    self.buffer[#self.buffer+1] = tid
  end
end

---Display an entity. This accounts for ASCII mode, or ASCII if there's no sprite for this entity.
--@param entity Entity. The entity to display
--@param x Number. The X-coordinate (in pixels, not tiles) where the entity should be drawn.
--@param y Number. The Y-coordinate (in pixels, not tiles) where the entity should be drawn.
--@param seen Boolean. Whether or not the entity is seen by the player.
--@param ignoreDistMods Boolean. Whether to ignore the "xMod" and "yMod" pixel-coordinate modifiers applied to the entity. (optional)
--@param scale Number. The scale at which to draw the entity. (optional)
function output.display_entity(entity,x,y, seen,ignoreDistMods,scale)
  local tileSize = output:get_tile_size(true)
  if entity.noDraw then return end
  scale = scale or 1
  local color = entity.color or {r=255,g=255,b=255,a=255}
  local alpha = (entity.invisible and 0 or (color.a or 255))
  local image_name = (entity.imageType or entity.baseType) .. (entity.image_name or entity.id)
  if not images[image_name] then image_name = (entity.imageType or entity.baseType) .. 'default' end
  if entity.bonus_cache then
    entity.bonus_cache.xMod = nil
    entity.bonus_cache.yMod = nil
    entity.bonus_cache.scale = nil
    entity.bonus_cache.angle = nil
  end
  local xMod = (ignoreDistMods and 0 or (entity.get_stat and entity:get_stat('xMod') or entity.xMod or 0))
  local yMod = (ignoreDistMods and 0 or (entity.get_stat and entity:get_stat('yMod') or entity.yMod or 0))
  local angle = (entity.get_stat and entity:get_stat('angle') or entity.angle or 0)
  local entityScale = (entity.get_stat and entity:get_stat('scale') or entity.scale or 1)
  if entityScale == 0 then entityScale = 1 end
  if prefs['noImages'] == true or images[image_name] == nil then --if the creature has no image or images are off, then print symbol
    local oldFont = love.graphics.getFont()
    love.graphics.setFont((prefs['noImages'] and fonts.mapFont or fonts.mapFontWithImages))
    if seen then
      if prefs['tileImages'] == true and prefs['creatureShadows'] == true then
        setColor(0,0,0,alpha) --draw a shadow first
        love.graphics.print(entity.symbol,x+xMod,y+yMod)
      end
      local colorMod = 1
      if entity.baseType == "creature" and seen ~= "force" and not entity.isPlayer and entity.master ~= player and (not entity.notices[player] or not entity.shitlist[player]) then
        colorMod = 1.5
      end
      if entity.temporaryColor then setColor(round(entity.temporaryColor.r/colorMod),round(entity.temporaryColor.g/colorMod),round(entity.temporaryColor.b/colorMod),(entity.temporaryColor.a or alpha))
      else setColor(round(color.r/colorMod),round(color.g/colorMod),round(color.b/colorMod),alpha) end
    else setColor(50,50,50,alpha) end
    love.graphics.print(entity.symbol,x+xMod,y+yMod)
    setColor(255,255,255,255)
    love.graphics.setFont(oldFont)
    return true --ignore the rest
  end
  -- Image display code:
  if images[image_name] then --if image is already loaded, display it
    if images[image_name]:getWidth() > tileSize and (not entity.spritesheet or not entity.image_max) then
      local frames = images[image_name]:getWidth()/tileSize
      if frames > 1 then
        entity.spritesheet=true
        entity.image_max = math.ceil(frames)
        entity.image_frame=1
      end
    end
    if entity.baseType == "creature" and prefs['creatureShadows'] then
      setColor(0,0,0,alpha) --draw a shadow first
      if entity.spritesheet then
        love.graphics.draw(images[image_name],output:get_spritesheet_quad(entity.image_frame,entity.image_max),x+18*scale+xMod,y+16*scale+yMod,angle,(entity.faceLeft and -1 or 1)*entityScale*scale,1*entityScale*scale,16,16)
      else
        love.graphics.draw(images[image_name],x+18*scale+xMod,y+16*scale+yMod,angle,(entity.faceLeft and -1 or 1)*entityScale*scale,1*entityScale*scale,16,16)
      end
    end
    local colorMod = 1
    if not seen then
      colorMod = 2.5
    elseif entity.baseType == "creature" and seen ~= "force" and not entity.isPlayer and entity.master ~= player and (not entity.notices[player] or not entity.shitlist[player]) then
      colorMod = 1.5
    end
    if entity.temporaryColor then setColor(round(entity.temporaryColor.r/colorMod),round(entity.temporaryColor.g/colorMod),round(entity.temporaryColor.b/colorMod),(entity.temporaryColor.a or alpha))
    elseif entity.use_color_with_tiles or (gamesettings.always_use_color_with_tiles and entity.use_color_with_tiles ~= false) then setColor(round(color.r/colorMod),round(color.g/colorMod),round(color.b/colorMod),alpha)
    elseif seen then setColor(round(255/colorMod),round(255/colorMod),round(255/colorMod),alpha)
    else setColor(100,100,100,alpha) end
    
    if entity.tilemap and quads[entity.tileDirection or 'nsew'] then --if it's a tileset, use the quad
      love.graphics.draw(images[image_name],quads[entity.tileDirection or 'nsew'],x+16*scale+xMod,y+(entity.baseType == "creature" and 14 or 16)*scale+yMod,angle,(entity.faceLeft and -1 or 1)*entityScale*scale,1*entityScale*scale,16,16)
    elseif entity.spritesheet then --if it's a regular spritesheet, use the quad for the frame
      love.graphics.draw(images[image_name],output:get_spritesheet_quad(entity.image_frame,entity.image_max),x+16*scale+xMod,y+(entity.baseType == "creature" and 14 or 16)*scale+yMod,angle,(entity.faceLeft and -1 or 1)*entityScale*scale,1*entityScale*scale,16,16)
    else --draw the basic image
      love.graphics.draw(images[image_name],x+16*scale+xMod,y+(entity.baseType == "creature" and 14 or 16)*scale+yMod,angle,(entity.faceLeft and -1 or 1)*entityScale*scale,1*entityScale*scale,16,16)
    end
    if (Gamestate.current() == game or Gamestate.current() == pausemenu) and ((entity.baseType == "creature" and entity:is_type('airborne') == false) or entity.useWalkedOnImage == true) then --for walking creatures (or special features), display features' walking image (splashes in water, bridge over top, etc)
      for _,feat in pairs(currMap:get_tile_features(entity.x,entity.y)) do
        if feat.walkedOnImage ~= false and (not timers[tostring(entity) .. 'moveTween'] or not entity.fromX or not entity.fromY or currMap:tile_has_feature(entity.fromX,entity.fromY,feat.id)) then
          local featColor = feat.color or {r=255,g=255,b=255,a=255}
          local featTempColor = feat.temporaryColor
          local walkedOnImage = (feat.walkedOnImage or (feat.image_name or feat.id) .. "_walkedon")
          if images['feature' .. walkedOnImage] == nil then
            --output:load_image(feat.walkedOnImage,"feature")
          end --end if image == nil if
          if images['feature' .. walkedOnImage] ~= nil then
            local walkedOnColorMod = 1
            if not seen then
              walkedOnColorMod = 2.5
            end
            if feat.temporaryColor then setColor(featTempColor.r,featTempColor.g,featTempColor.b,featTempColor.a)
            elseif feat.use_color_with_tiles or (gamesettings.always_use_color_with_tiles and feat.use_color_with_tiles ~= false) then setColor(round(featColor.r/walkedOnColorMod),round(featColor.g/walkedOnColorMod),round(featColor.b/walkedOnColorMod),featColor.a)
            elseif seen then setColor(255,255,255,featColor.a)
            else setColor(100,100,100,featColor.a) end
            if feat.walkedOnTilemap and feat.tileDirection then
              love.graphics.draw(images['feature' .. walkedOnImage],quads[feat.tileDirection],x+16*scale+(feat.walkedOnNoFollow and (feat.xMod or 0) or (entity.xMod or 0)),y+16*scale+(feat.walkedOnNoFollow and (feat.yMod or 0) or (entity.yMod or 0)),feat.angle,(feat.faceLeft and -1 or 1)*(feat.scale or 1)*scale,1*(feat.scale or 1)*scale,16,16)
            else
              love.graphics.draw(images['feature' .. walkedOnImage],x+16*scale+(feat.walkedOnNoFollow and (feat.xMod or 0) or (entity.xMod or 0)),y+16*scale+(feat.walkedOnNoFollow and (feat.yMod or 0) or (entity.yMod or 0)),feat.angle,(feat.faceLeft and -1 or 1)*(feat.scale or 1)*scale,1*(feat.scale or 1)*scale,16,16)
            end --end walked on quad if
          end --end if walked on image ~= -1
        end --end if feat.walkedonimage
      end --end feature for
    end --end creature if
    setColor(255,255,255,255)
    return true
  end
end

---Load an image from the assets/images/ directory
--The resulting image will be loaded into images[image_typename], for example images['creaturezombie']
--@param name String. The name of the file.
--@param image_type String. The type of Entity the image is for. This determines what subdirectory in assets/images/ to look in, as well as what the final ID of the image will be when loaded into the game.
function output:load_image(name,image_type)
  if images[(image_type or "") .. name] then return true end
  if love.filesystem.getInfo("assets/images/" .. image_type .. "/" .. name .. ".png",'file') then
    images[(image_type or "") .. name] = love.graphics.newImage("assets/images/" .. image_type .. "/" .. name .. ".png")
  else
    images[(image_type or "") .. name] = -1
  end
end

---Move the cursor to another tile.
--@param mx Number The X-distance by which to move the cursor.
--@param my Number. The Y-distance by which to move the cursor.
function output:moveCursor(mx,my)
  return self:setCursor(self.cursorX+mx,self.cursorY+my)
end

---Set the cursor to a given tile.
--This function handles snapping between possible targets, if targeting something with a limited number of possible targets on screen.
--@param x Number. The X-coordinate of the new tile.
--@param y Number. The Y-coordinate of the new tile.
--@param force Boolean. If set to true, this will force the cursor to a certain location, even if it wouldn't normally be allowed.
--@param noScroll Boolean. If true, don't scroll the map
--@param allow_current_creature Boolean. If not set to true and the game is in targetting mode, will ignore the current target
function output:setCursor(x,y,force,allow_current_creature,noScroll)
  if (x == 0 or y == 0) then
    self.cursorX,self.cursorY = 0,0
    self.targetLine = {}
    self.targetTiles = {}
    return
  end
  
  --First, check to make sure the cursor is on the map if you're in game:
  if Gamestate.current() == game then
    local width,height = love.graphics.getWidth(),love.graphics.getHeight()
    local newX,newY = self:tile_to_coordinates(x,y)
    if (x<1 or y <1 or x>currMap.width or y>currMap.height) then return false end --if you'd move off the map, don't move cursor
    if not noScroll then
      if newX < 0 then self:move_camera(-1,0) end
      if newY < 0 then self:move_camera(0,-1) end
      if newX > width then self:move_camera(1,0) end
      if newY > height then self:move_camera(0,1) end
    end
  end
  
  --If you're targeting a creature-targeting spell, snap to nearest creature
  if force ~= true and Gamestate.current() == game and action == "targeting" and actionResult and #output.potentialTargets > 0 and not actionResult.free_aim then
    local nearest = nil
    local nearestDist = nil
    if #output.potentialTargets > 0 then
      for _,tar in pairs(output.potentialTargets) do
        if tar.x ~= output.cursorX or tar.y ~= output.cursorY or allow_current_creature then
          local dist = calc_distance(x,y,tar.x,tar.y)
          local xModo,yModo = get_unit_vector(output.cursorX,output.cursorY,x,y)
          local xModc,yModc = get_unit_vector(output.cursorX,output.cursorY,tar.x,tar.y)
          if (nearest == nil or nearestDist == nil or dist < nearestDist) and ((xModo == xModc and (yModo == yModc or yModo == 0)) or (yModo == yModc and (xModo == xModc or xModo == 0))) then
            nearest = tar
            nearestDist = dist
          end --end nearest if
        end --end if not player target
      end
    end
    if nearest then
      x,y = nearest.x,nearest.y
    else
      x,y = output.cursorX,output.cursorY
    end --end if nearest
  end --end snap-to-creature if
  
  self.cursorX, self.cursorY = x,y
  self.targetLine = {}
  self.targetTiles = {}
  
  local creat = (Gamestate.current() == game and currMap:get_tile_creature(x,y) or nil)
  if Gamestate.current() == game and (actionResult == nil) and currMap:in_map(x,y) and currMap.seenMap[x][y] == true then --if you're moving, draw the path you'll take
    if (player:can_move_to(x,y) or creat) then
      local tempPath = currMap:findPath(player.x,player.y,x,y,player:get_pathType()) or {}
      for _, v in ipairs(tempPath) do
        self.targetLine[#self.targetLine+1] = {x=v.x,y=v.y}
      end --end for
    else --if you can't move to the tile itself, check the adjacent tiles
      local shortestPath
      local shortestDist
      for xn=x-1,x+1,1 do
        for yn=y-1,y+1,1 do
          if currMap:in_map(xn,yn) then
            local tempPath = currMap:findPath(player.x,player.y,xn,yn,player:get_pathType())
            if tempPath then
              local tempSteps = #tempPath
              local tempDist = calc_distance_squared(player.x,player.y,xn,yn)
              if tempDist and (not shortestDist or tempDist < shortestDist) then
                shortestPath = tempPath
                shortestDist = tempDist
              end
            end
          end
        end
      end
      if shortestPath then
        for _, v in ipairs(shortestPath) do
          self.targetLine[#self.targetLine+1] = {x=v.x,y=v.y}
        end --end for
        if self.targetLine and (self.targetLine[#self.targetLine].x ~= x or self.targetLine[#self.targetLine].y ~= y) then
          self.targetLine[#self.targetLine+1] = {x=x,y=y}
        end
      end
    end
  elseif Gamestate.current() == game and (actionResult and actionResult.projectile == true) and currMap:in_map(x,y) and currMap.seenMap[x][y] == true then --if you're targeting a projectile, draw a line to the target
    local origin = player
    if actionResult.target_line_from_previous_target and game.targets and #game.targets > 0 then
      origin = game.targets[#game.targets]
    end
    local tempLine,_ = currMap:get_line(origin.x,origin.y,x,y,false,'airborne',false,true,true)
    for _, v in ipairs(tempLine) do
      self.targetLine[#self.targetLine+1] = {x=v[1],y=v[2]}
    end --end for
  end --end action if
  if Gamestate.current() == game and action == "targeting" and actionResult ~= nil and actionResult.get_target_tiles ~= nil then
    local x,y = x,y
    if #self.targetLine > 0 then x,y = self.targetLine[#self.targetLine].x,self.targetLine[#self.targetLine].y end --draw the target box around the last time, not the actual pointed to tile (if they're different)
    self.targetTiles = actionResult:get_target_tiles({x=x,y=y},player,game.targets) or {}
  end
end

---Get the pixel coordinates of a tile
--@param x Number. The tile's x-coordinate.
--@param y Number. The tile's y-coordinate.
--@param noRound Boolean. If TRUE, will not round the resulting value up to the next pixel. Otherwise it will.
--@return Number. The pixel's x-coordinate
--@return Number. The pixel's y-coordinate
function output:tile_to_coordinates(x,y,noRound)
  local mapWidth,mapHeight = self:get_map_dimensions()
  local tileSize = self:get_tile_size()
  
  if not self.coordinate_map then self.coordinate_map = {} end
  if not self.coordinate_map[x] then self.coordinate_map[x] = {} end
  local cMap = self.coordinate_map[x][y]
  if not cMap then
    cMap = {x = mapWidth/2-((self.camera.x-x)*tileSize), y = mapHeight/2-((self.camera.y-y)*tileSize)}
    self.coordinate_map[x][y] = cMap
  end
  local rx,ry = cMap.x,cMap.y
  rx,ry = (noRound and rx or math.ceil(rx)),(noRound and ry or math.ceil(ry))
  return rx,ry
end


---Refresh the stored map of pixel values for all the tiles in the map
function output:refresh_coordinate_map()
  local mapWidth,mapHeight = self:get_map_dimensions()
  local tileSize = self:get_tile_size()
  
  if not self.coordinate_map then self.coordinate_map = {} end
  for x=1, mapWidth,1 do
    if not self.coordinate_map[x] then self.coordinate_map[x] = {} end
    for y=1,mapHeight,1 do
      self.coordinate_map[x][y] = {x = mapWidth/2-((self.camera.x-x)*tileSize), y = mapHeight/2-((self.camera.y-y)*tileSize)}
    end
  end
end

---Convert pixel coordinates to a tile's coordinates.
--@param x Number. The x-coordinate of the pixel.
--@param y Number. The y-coordinate of the pixel.
--@return Number. The x-coordinate of the tile.
--@return Number. The y-coordinate of the tile.
function output:coordinates_to_tile(x,y)
  local mapWidth,mapHeight = self:get_map_dimensions()
  local tileSize = self:get_tile_size()
  local tileY = math.floor(self.camera.y - (mapHeight/2-y)/tileSize)
  local tileX = math.floor(self.camera.x - (mapWidth/2-x)/tileSize)
  return tileX,tileY
end

---Get the width (in pixels) used for the game map.
--@return Number. The width (in pixels) of the game map.
function output:get_map_width()
  if self.mapWidth then return self.mapWidth end
  local width = love.graphics:getWidth()
  self.mapWidth = width-365
  return self.mapWidth
end

---Get the height (in pixels) used for the game map.
--@return Number. The height (in pixels) of the game map.
function output:get_map_height()
  if self.mapHeight then return self.mapHeight end
  local height = love.graphics:getHeight()
  self.mapHeight = height-30
  return self.mapHeight
end

---Get the width and height(in pixels) used for the game map.
--@return Number. The width (in pixels) of the game map.
--@return Number. The height (in pixels) of the game map.
function output:get_map_dimensions()
  if self.mapWidth and self.mapHeight then return self.mapWidth,self.mapHeight end
  return self:get_map_width(),self:get_map_height()
end

---Get the width/height in pixels of a map tile. The game assumes that all pixels are square, so the single number returned is assumed to be used for both.
--@param ignoreZoom Boolean. If true, ignore zoom
--@return Number. The size of a map tile.
function output:get_tile_size(ignoreZoom)
  return math.floor((prefs['noImages'] and prefs['asciiSize'] or gamesettings.tilesize)*(currGame and Gamestate.current() == game and not ignoreZoom and currGame.zoom or 1))
end

---Load and initialize all UI-related images.
function output:load_ui()
  images.borders = {borderImg=love.graphics.newImage("assets/images/ui/borders.png"),ul = love.graphics.newQuad(0,0,32,32,96,96),ur = love.graphics.newQuad(64,0,32,32,96,96),ll = love.graphics.newQuad(0,64,32,32,96,96),lr = love.graphics.newQuad(64,64,32,32,96,96),u = love.graphics.newQuad(32,0,32,32,96,96),d = love.graphics.newQuad(32,64,32,32,96,96),l = love.graphics.newQuad(0,32,32,32,96,96),r = love.graphics.newQuad(64,32,32,32,96,96)}
  images.button = {image=love.graphics.newImage("assets/images/ui/button.png"),hover=love.graphics.newImage("assets/images/ui/buttonhover.png"),l=love.graphics.newQuad(0,0,32,32,128,32),middle=love.graphics.newQuad(32,0,32,32,128,32),r=love.graphics.newQuad(64,0,32,32,128,32),small=love.graphics.newQuad(96,0,32,32,128,32)}
  images.smallbutton = {image=love.graphics.newImage("assets/images/ui/smallbutton.png"),hover=love.graphics.newImage("assets/images/ui/smallbuttonhover.png"),disabled=love.graphics.newImage("assets/images/ui/smallbuttondisabled.png"),l=love.graphics.newQuad(0,0,32,16,128,16),middle=love.graphics.newQuad(32,0,32,16,128,16),r=love.graphics.newQuad(64,0,32,16,128,16),small=love.graphics.newQuad(96,0,32,16,128,16)}
  images.largebutton = {image=love.graphics.newImage("assets/images/ui/button.png"),hover=love.graphics.newImage("assets/images/ui/buttonlarge.png"),l=love.graphics.newQuad(0,0,64,64,256,64),middle=love.graphics.newQuad(64,0,64,64,256,64),r=love.graphics.newQuad(128,0,64,64,256,64),small=love.graphics.newQuad(192,0,64,64,256,64)}
  images.closebutton = {image=love.graphics.newImage("assets/images/ui/closebutton.png"),hover=love.graphics.newImage("assets/images/ui/closebuttonhover.png")}
  images.menubutton = {image=love.graphics.newImage("assets/images/ui/menubutton.png"),hover=love.graphics.newImage("assets/images/ui/menubuttonhover.png")}

  if love._os ~= "NX" and images['uicursor'] then
    images.cursors = {main = love.mouse.newCursor("assets/images/ui/cursor.png",0,0)}
  end
  --love.mouse.setCursor(images.cursors.main)
end

---Load all images in the assets/images/ directory
function output:load_all_images()
  local folders = love.filesystem.getDirectoryItems('assets/images')
  for _,folderName in pairs(folders) do
    if love.filesystem.getInfo('assets/images/' .. folderName,'directory') then
      local files = love.filesystem.getDirectoryItems('assets/images/' .. folderName)
      for _,fileName in pairs(files) do
        local extension = string.sub(fileName, -4)
        if extension == ".png" then
          fileName = string.sub(fileName,1,-5)
          images[folderName .. fileName] = love.graphics.newImage("assets/images/" .. folderName .. "/" .. fileName .. ".png")
        end --end extension check
      end --end fileName for
    end --end is folder if
  end --end folderName for
  for _,tileset in pairs(love.filesystem.getDirectoryItems('assets/images/maps')) do
    local files = love.filesystem.getDirectoryItems('assets/images/maps/' .. tileset)
    for _,fileName in pairs(files) do
      local extension = string.sub(fileName, -4)
      if extension == ".png" then
        fileName = string.sub(fileName,1,-5)
        images[tileset .. fileName] = love.graphics.newImage("assets/images/maps/" .. tileset .. "/" .. fileName .. ".png")
      end --end extension check
    end --end fileName for
  end
  if images['uicursor'] and not prefs['noImages'] then
    if love._os ~= "NX" then
      love.mouse.setCursor(love.mouse.newCursor("assets/images/ui/cursor.png"))
    end
  end
end

---Draw a bar
--@param val Number. The value at which to draw the bar
--@param max_val Number. The maximum value the bar could hold
--@param x Number. The x-coordinate to start at for the bar
--@param y Number. The Y-coordinate to start at for the bar
--@param width Number. The width of the bar
--@param height Number. The height of the bar
--@param color Table.
function output:draw_health_bar(val,max_val,x,y,width,height,color)
  setColor((color and color.r or 200),(color and color.g or 0),(color and color.b or 0),255)
  love.graphics.rectangle('line',x-1,y-1,width+2,height+2)
  if val < 1 then return end
  local barWidth = math.min(width,math.max(math.ceil((val/max_val)*width),1))
  if prefs['noImages'] == true then
    setColor((color and color.r or 255),(color and color.g or 255),(color and color.b or 255),255)
    love.graphics.rectangle('fill',x,y,barWidth,height)
  else
    for px=x,x+barWidth,2 do
      if px+2 < x+barWidth then love.graphics.draw(images.uihealthbartiny,px,y) end
    end --end for
    love.graphics.draw(images.uihealthbartiny,x+barWidth-2,y)
  end --end assets/images/noimages if
  setColor(255,255,255,255)
end

---Draw a bar
--@param val Number. The value at which to draw the bar
--@param max_val Number. The maximum value the bar could hold
--@param x Number. The x-coordinate to start at for the bar
--@param y Number. The Y-coordinate to start at for the bar
--@param width Number. The width of the bar
--@param height Number. The height of the bar
--@param color Table.
function output:draw_tiny_bar(val,max_val,x,y,width,height,color)
  setColor((color and color.r or 200),(color and color.g or 0),(color and color.b or 0),(color and color.a or 255))
  local barWidth = math.max(math.ceil((val/max_val)*width),1)
  love.graphics.rectangle('fill',x,y,barWidth,height)
  setColor(255,255,255,100)
  love.graphics.rectangle('line',x,y,width,height)
  setColor(255,255,255,255)
end

---Play a sound
--@param soundName Text. The name of the sound file, excluding file extension
--@param pitchDiff Number. The maximum % by which to randomly shift the pitch up or down. Optional, defaults to 10
--@return Boolean. Whether or not the sound exists or not
function output:sound(soundName,pitchDiff)
  if not soundName then return false end
  if not pitchDiff then pitchDiff = 10 end
    
  -- Load sound first
  if not sounds[soundName] then
    if love.filesystem.getInfo("assets/sounds/" .. soundName ..".ogg",'file') then
      sounds[soundName] = ripple.newSound({source=love.audio.newSource("assets/sounds/" .. soundName ..".ogg",'static'),tags={soundTags.sfx}})
      elseif love.filesystem.getInfo("assets/sounds/" .. soundName .. ".wav",'file') then
      sounds[soundName] = ripple.newSound({source=love.audio.newSource("assets/sounds/" .. soundName ..".wav",'static'),tags={soundTags.sfx}})
    elseif love.filesystem.getInfo("assets/sounds/" .. soundName .. ".mp3",'file') then
      sounds[soundName] = ripple.newSound({source=love.audio.newSource("assets/sounds/" .. soundName ..".mp3",'static'),tags={soundTags.sfx}})
    else
      sounds[soundName] = -1
      return false
    end
  end
  
    
  if sounds[soundName] ~= -1 then
    local variety = random(100-pitchDiff,100+pitchDiff)
    sounds[soundName]:play({pitch=variety/100})
    return true
  else --if sound doesn't exist
    return false
  end
end

---Make, but do not play, a music playlist
--@param name Text. The name of the folder within music/ to make the playlist from, or alternatively, the name of the single track to play (excluding filename extension)
--@return Table. A list of tracks for the playlist
function output:make_playlist(name)
  --If there is only one track:
  if love.filesystem.getInfo('assets/music/' .. name .. '.ogg','file') then
    return {'assets/music/' .. name .. '.ogg'}
  elseif love.filesystem.getInfo('assets/music/' .. name .. '.mp3','file') then
    return {'assets/music/' .. name .. '.mp3'}
  elseif love.filesystem.getInfo('assets/music/' .. name .. '.wav','file') then
    return {'assets/music/' .. name .. '.wav'}
  elseif love.filesystem.getInfo('assets/music/' .. name,'directory') then
    local files = love.filesystem.getDirectoryItems('assets/music/' .. name)
    local tracks = {}
    for _,fileName in pairs(files) do
      local extension = string.sub(fileName, -4)
      if extension == ".mp3" or extension == ".ogg" or extension == ".wav" then
        tracks[#tracks+1] = name
        music[name] = ripple.newSound({source=love.audio.newSource('assets/music/' .. name .. '/' .. fileName,'stream'),tags={soundTags.music}})
        music[name]:setLooping(true)
      end
    end
    if #tracks > 0 then
      return tracks
    else
      return false
    end
  else --folder nor files exist
    return false
  end
end

---Play a misic playlist
--@param name Text. The name of the folder within music/ to make the playlist from, or alternatively, the name of the single track to play (excluding filename extension). Or, "silence" to stop playing all music.
--@param useGeneric Boolean. If true, if the said playlist can't be created, just play from the generic playlist
function output:play_playlist(name,useGeneric)
  if name == "silence" then
    soundTags.music:stop()
    return
  end
  local playlist = output:make_playlist(name)
  if not playlist and useGeneric then playlist = output:make_playlist('generic') end
  if playlist and count(playlist) > 0 then
    soundTags.music:stop()
    shuffle(playlist)
    music[playlist[1]]:play()
  else
    self:play_playlist('silence')
  end
end

---Draw a scrollbar on the screen
--@param x Number. The x-coordinate of the scrollbar.
--@param startY Number. The y-coordinate for the top of the scrollbar
--@param endY Number. The y-coordinate for the bottom of the scrollbar
--@param scrollPerc Number. The position on the scrollbar for the elevator
--@param useScaling Boolean. Whether or not to take into account the game's UI scaling setting
--@return Table. A table containing the sub-tables upArrow, downArrow, and elevator, each of whichhas startX, endX, startY, and endY values corresponding to that part of the scrollbar's coordinates
function output:scrollbar(x,startY,endY,scrollPerc,useScaling)
  local mouseX,mouseY = love.mouse.getPosition()
  local uiScale = 1
  if useScaling then
    uiScale = (prefs['uiScale'] or 1)
    mouseX,mouseY = math.ceil(mouseX/uiScale),math.ceil(mouseY/uiScale)
  end
  if prefs['noImages'] ~= true then
    if gamesettings.scrollbarColor then
      local c = gamesettings.scrollbarColor
      setColor(c.r,c.g,c.b,c.a)
    else
      setColor(100,100,100,255)
    end
    for y=startY,endY-32,32 do
      love.graphics.draw(images.uiscrollbar,x+1,y)
    end
    --Draw up arrow:
    if gamesettings.scrollarrowColor then
      local c = gamesettings.scrollarrowColor
      setColor(c.r,c.g,c.b,c.a)
    else
      setColor(255,255,255,255)
    end
    if mouseX > x and mouseX < x+32 and mouseY > startY and mouseY < startY+32 then
      love.graphics.draw(images.uiscrollarrowhighlight,x,startY)
    else
      love.graphics.draw(images.uiscrollarrow,x,startY)
    end
    --Draw down arrow:
    if mouseX > x and mouseX < x+32 and mouseY > endY-32 and mouseY < endY then
      love.graphics.draw(images.uiscrollarrowhighlight,x,endY,0,1,-1)
    else
      love.graphics.draw(images.uiscrollarrow,x,endY,0,1,-1)
    end
    --Draw "elevator"
    if gamesettings.scrollelevatorColor then
      local c = gamesettings.scrollelevatorColor
      setColor(c.r,c.g,c.b,c.a)
    else
      setColor(255,255,255,255)
    end
    local elevatorY = startY+32+round(scrollPerc*(endY-startY-96))
    if mouseX > x and mouseX < x+32 and mouseY < endY-32 and mouseY > startY+32 then
      love.graphics.draw(images.uiscrollelevatorhighlight,x,elevatorY)
    else
      love.graphics.draw(images.uiscrollelevator,x,elevatorY)
    end
    setColor(255,255,255,255)
    return {upArrow={startX=x,endX=(x+32),startY=startY,endY=(startY+32)},downArrow={startX=x,endX=(x+32),startY=(endY-32),endY=endY},elevator={startX=x,endX=(x+32),startY=elevatorY,endY=(elevatorY+32)}} -- return positions, for clicking
  else --ASCII scroll
    setColor(200,200,200,255)
    for y = startY+14,endY-14,28 do
      love.graphics.print(".",x+9,y)
    end
    if mouseX > x and mouseX < x+21 and mouseY > startY and mouseY < startY+21 then setColor(255,255,255,255) else setColor(200,200,200,255) end
    love.graphics.print("/\\",x+7,startY)
    if mouseX > x and mouseX < x+21 and mouseY > endY and mouseY < endY+21 then setColor(255,255,255,255) else setColor(200,200,200,255) end
    love.graphics.print("\\/",x+7,endY)
    local elevatorY = startY+32+round(scrollPerc*(endY-startY-64))
    if mouseX > x and mouseX < x+21 and mouseY > elevatorY-7 and mouseY < elevatorY+21 then setColor(255,255,255,255) else setColor(200,200,200,255) end
    love.graphics.print("#",x+6,elevatorY-7)
    love.graphics.print("#",x+6,elevatorY+7)
    setColor(255,255,255,255)
    return {upArrow={startX=x,endX=(x+21),startY=startY,endY=(startY+21)},downArrow={startX=x,endX=(x+21),startY=endY,endY=(endY+21)},elevator={startX=x,endX=(x+21),startY=(elevatorY-7),endY=(elevatorY+21)}}
  end
end

---Draw a button
--@param x Number. The x-coordinate of the button
--@param y Number. The y-coordinate of the button
--@param width Number. The width of the button
--@param small Boolean. Whether or not to draw it as a small button
--@param special Text. The text of the style to force the button to use (eg. forcing hover, or forcing disabled). Optional
--@param text Text. The text to display on the button. Optional
--@param useScaling Boolean. Whether to take into account the game's UI scaling setting. Optional
--@param color 
--@return Table. A table with the values minX, maxX, minY, and maxY, containing the corresponding coordinates of the button, and hover, a boolean saying if the button is being hovered over
function output:button(x,y,width,small,special,text,useScaling,color)
  local mouseX,mouseY = love.mouse.getPosition()
  local uiScale = 1
  if useScaling then
    uiScale = (prefs['uiScale'] or 1)
    mouseX,mouseY = math.ceil(mouseX/uiScale),math.ceil(mouseY/uiScale)
  end
  local hover = false
  if not width and text then
    width = fonts.buttonFont:getWidth(text)
  end
  if mouseX > x and mouseX < x+width and mouseY>y and mouseY<y+(small and 16 or 32) and (special ~= false or special == "hover") then
    hover = true
  end
  if width < 32 then
    --function output:tinybutton(x,y,small,hover,text,useScaling)
    return output:tinybutton(x,y,small,(special == "hover" or hover or nil),text,useScaling)
  else
    width = math.max(64,width)
  end
  if prefs['noImages'] ~= true then
    local buttonname = (small and "smallbutton" or "button")
    local image = (special and images[buttonname][special] or images[buttonname].image)
    if mouseX > x and mouseX < x+math.max(width,64) and mouseY>y and mouseY<y+(small and 16 or 32) and special ~= false then
      if not special then image = images[buttonname].hover end
    end
    if width > 64 then
      love.graphics.draw(image,images[buttonname].middle,x+16,y)
      love.graphics.draw(image,images[buttonname].middle,x+width-48,y)
      if width > 96 then
        for drawX = x+48,x+width-48,32 do
          love.graphics.draw(image,images[buttonname].middle,drawX,y)
        end
      end
    end
    love.graphics.draw(image,images[buttonname].l,x,y)
    love.graphics.draw(image,images[buttonname].r,math.max(x+width-32,x+32),y)
    if text then
      local oldFont = love.graphics.getFont()
      love.graphics.setFont(fonts.buttonFont)
      love.graphics.printf(text,math.floor(x),math.floor(y+4),width,"center")
      love.graphics.setFont(oldFont)
    end
    return {minX=x,maxX=(x+math.max(width,64)),minY=y,maxY=(y+(small and 16 or 32)),hover=hover,width=width}
  else --imageless buttons
    if hover then
      setColor(100,100,100,255)
    else
      setColor(33,33,33,255)
    end
    love.graphics.rectangle('fill',x,y,math.max(width,64),(small and 16 or 32))
    setColor(255,255,255,255)
    love.graphics.rectangle('line',x,y,math.max(width,64),(small and 16 or 32))
    if text then
      local oldFont = love.graphics.getFont()
      love.graphics.setFont(fonts.buttonFont)
      love.graphics.printf(text,math.floor(x),math.floor(y+4),width,"center")
      love.graphics.setFont(oldFont)
    end
    return {minX=x,maxX=(x+math.max(width,64)),minY=y,maxY=(y+(small and 16 or 32)),hover=hover,width=width}
  end
end

---Draw a large button. I'm not entirely sure this actually works
--@param x Number. The x-coordinate of the button
--@param y Number. The y-coordinate of the button
--@param width Number. The width of the button
--@param special Text. The text of the style to force the button to use (eg. forcing hover, or forcing disabled). Optional
--@return Table. A table with the values minX, maxX, minY, and maxY, containing the corresponding coordinates of the button, and hover, a boolean saying if the button is being hovered over
function output:largebutton(x,y,width,special)
  local mouseX,mouseY = love.mouse.getPosition()
  local uiScale = 1
  if useScaling then
    uiScale = (prefs['uiScale'] or 1)
    mouseX,mouseY = math.ceil(mouseX/uiScale),math.ceil(mouseY/uiScale)
  end
  local hover = false
  if prefs['noImages'] ~= true then
    local image = (special and images['largebutton'][special] or images['largebutton'].image)
    if mouseX > x and mouseX < x+math.max(width,128) and mouseY>y and mouseY<y+64 then
      if not special then image = images['largebutton'].hover end
      hover = true
    end
    love.graphics.draw(image,images['largebutton'].l,x,y)
    love.graphics.draw(image,images['largebutton'].r,math.max(x+width-64,x+64),y)
    if width > 128 then
      love.graphics.draw(image,images['largebutton'].middle,x+64,y)
      if width > 192 then
        for drawX = x+128,x+width-64,64 do
          love.graphics.draw(image,images['largebutton'].middle,drawX,y)
        end
      end
    end
    return {minX=x,maxX=x+math.max(width,128),minY=y,maxY=y+64,hover=hover}
  else --imageless buttons
    if (mouseX > x and mouseX < x+math.max(width,128) and mouseY>y and mouseY<y+64) or special == "hover" then
      hover = true
    end
    if hover then
      setColor(100,100,100,255)
    else
      setColor(33,33,33,255)
    end
    love.graphics.rectangle('fill',x,y,math.max(width,128),64)
    setColor(255,255,255,255)
    love.graphics.rectangle('line',x,y,math.max(width,128),64)
    return {minX=x,maxX=x+(math.max(width,128)),minY=y,maxY=(y+64),hover=hover}
  end
end

---Draw a close button
--@param x Number. The x-coordinate of the button
--@param y Number. The y-coordinate of the button
--@param hover Boolean. Whether or not to draw the close button as if it's being hovered over. Optional
--@param useScaling Boolean. Whether to take into account the game's UI scaling setting. Optional
--@param imageBase Text. The name of the base image to use (defaults to "close")
--@return Table. A table with the values minX, maxX, minY, and maxY, containing the corresponding coordinates of the button, and hover, a boolean saying if the button is being hovered over
function output:closebutton(x,y,hover,useScaling,imageBase)
  imageBase = imageBase or "close"
  local mouseX,mouseY = love.mouse.getPosition()
  local uiScale = 1
  if useScaling then
    uiScale = (prefs['uiScale'] or 1)
    mouseX,mouseY = math.ceil(mouseX/uiScale),math.ceil(mouseY/uiScale)
  end
  hover = hover or false
  if prefs['noImages'] ~= true then
    if mouseX > x and mouseX < x+16 and mouseY>y and mouseY<y+16 then
      hover = true
    end
    local image = (hover and images[imageBase .. 'button'].hover or images[imageBase .. 'button'].image)
    love.graphics.draw(image,x,y)
    return {minX=x,maxX=x+16,minY=y,maxY=y+16,hover=hover}
  else --imageless buttons
    local fontSize = prefs['fontSize']
    if (mouseX > x and mouseX < x+fontSize+2 and mouseY>y and mouseY<y+fontSize+2) or hover then
      hover = true
    end
    if hover then
      setColor(100,100,100,255)
    else
      setColor(33,33,33,255)
    end
    love.graphics.rectangle('fill',x,y,fontSize+2,fontSize+2)
    setColor(255,255,255,255)
    love.graphics.rectangle('line',x,y,fontSize+2,fontSize+2)
    love.graphics.printf("<",x,y,fontSize,"center")
    return {minX=x,maxX=(x+fontSize+2),minY=y,maxY=(y+fontSize+2),hover=hover}
  end
end

---Draw a square button
--@param x Number. The x-coordinate of the button
--@param y Number. The y-coordinate of the button
--@param small Boolean. Whether or not to draw it as a small button
--@param hover Boolean. Whether to draw it as if it's being hovered over. Optional
--@param text Text. The text to display on the button. Optional
--@param useScaling Boolean. Whether to take into account the game's UI scaling setting. Optional
--@return Table. A table with the values minX, maxX, minY, and maxY, containing the corresponding coordinates of the button, and hover, a boolean saying if the button is being hovered over
function output:tinybutton(x,y,small,hover,text,useScaling)
  local mouseX,mouseY = love.mouse.getPosition()
  local uiScale = 1
  if useScaling then
    uiScale = (prefs['uiScale'] or 1)
    mouseX,mouseY = math.ceil(mouseX/uiScale),math.ceil(mouseY/uiScale)
  end
  if prefs['noImages'] ~= true then
    local buttonname = (small and "smallbutton" or "button")
    local image = images[buttonname].image
    if hover or (mouseX > x and mouseX < x+32 and mouseY>y and mouseY<y+(small and 16 or 32) and hover ~= false) then
      image = images[buttonname].hover
      hover = true
    end
    love.graphics.draw(image,images[buttonname].small,x,y)
    if text then
      local oldFont = love.graphics.getFont()
      love.graphics.setFont(fonts.buttonFont)
      love.graphics.printf(text,math.floor(x),math.floor(y+(small and -3 or 4)),32,"center")
      love.graphics.setFont(oldFont)
    end
    return {minX=x,maxX=(x+32),minY=y,maxY=(y+(small and 16 or 32)),hover=hover}
  else --imageless buttons
    if hover or (mouseX > x and mouseX < x+(small and 16 or 32) and mouseY>y and mouseY<y+(small and 16 or 32) and hover ~= false) then
      hover = true
    end
    if hover then
      setColor(100,100,100,255)
    else
      setColor(33,33,33,255)
    end
    love.graphics.rectangle('fill',x,y,(small and 16 or 32),(small and 16 or 32))
    setColor(255,255,255,255)
    love.graphics.rectangle('line',x,y,(small and 16 or 32),(small and 16 or 32))
    if text then
      local oldFont = love.graphics.getFont()
      love.graphics.setFont(fonts.buttonFont)
      love.graphics.printf(text,math.floor(x),math.floor(y+(small and -3 or 4)),(small and 16 or 32),"center")
      love.graphics.setFont(oldFont)
    end
    return {minX=x,maxX=(x+(small and 16 or 32)),minY=y,maxY=(y+(small and 16 or 32)),hover=hover}
  end
end

---Draw a description box
--@param text Text. The text to display
--@param x Number. The x-coordinate of the button
--@param y Number. The y-coordinate of the button
--@param maxWidth Number. The maximum width of the box
--@param scroll Number. The amount the screen requesting this box is scrolled
function output:description_box(text,x,y,maxWidth,scroll)
  local uiScale = prefs['uiScale']
  scroll = scroll or 0
  maxWidth = maxWidth or 300
  local oldFont = love.graphics.getFont()
  love.graphics.setFont(fonts.descFont)
  local textWidth, tlines = fonts.descFont:getWrap(text,maxWidth)
  local width = math.max(100,math.min(textWidth+16,maxWidth))
  local height = #tlines*(prefs['descFontSize']+3)+prefs['descFontSize']
  x,y = round(x),round(y)
  while (y+height-scroll > love.graphics.getHeight()) do
    y = y-prefs['descFontSize']
  end
  while(x+width > love.graphics.getWidth()) do
    x = x-prefs['descFontSize']
  end
  setColor(255,255,255,185)
  love.graphics.rectangle("line",x,y,width+2,height)
  setColor(0,0,0,185)
  love.graphics.rectangle("fill",x+1,y+1,width+1,height-1)
  setColor(255,255,255,255)
  love.graphics.printf(ucfirst(text),x+2,y+2,300)
  love.graphics.setFont(oldFont)
end

---Move the camera
--@param xAmt Number. The number of tiles by which to move the camera, x-coordinate
--@param yAmt Number. The number of tiles by which to move the camera, y-coordinate
--@param noTween Boolean. If true, instantly snap the camera to the new location rather than smoothly moving it
function output:move_camera(xAmt,yAmt,noTween)
  noTween = noTween or prefs['noSmoothCamera']
  if game.moveBlocked == true then return false end
  local width,height = love.graphics.getWidth(),love.graphics.getHeight()
  local tileSize = self:get_tile_size()
  local minX,minY = self:coordinates_to_tile(1,1)
  local maxX,maxY = self:coordinates_to_tile(width-12,height-12)
  local midX,midY = round((maxX+minX)/2),round((maxY+minY)/2)
  if (xAmt < 0 and midX < 0) or (xAmt > 0 and midX > currMap.width) then xAmt = 0 end
  if (yAmt < 0 and midY < 0) or (yAmt > 0 and midY > currMap.height) then yAmt = 0 end
  self.camera.x,self.camera.y = self.camera.x+xAmt,self.camera.y+yAmt
  if not noTween then
    if self.camera.tween then
      Timer.cancel(self.camera.tween)
    end
    self.camera.xMod,self.camera.yMod = self.camera.xMod+(xAmt*tileSize),self.camera.yMod+(yAmt*tileSize)
    self.camera.tween = tween(.1,self.camera,{xMod=0,yMod=0})
  end
  self.coordinate_map = {}
  --self:refresh_coordinate_map()
  --tween(.01,self.camera,{x=toX,y=toY})
end

---Set the camera to a coordinate.
--@param x Number. The new X-coordinate.
--@param y Number. The new Y-coordinate.
--@param noTween Boolean. If true, instantly snap the camera to the new location rather than smoothly moving it
function output:set_camera(x,y,noTween)
  local xMove,yMove = x-self.camera.x,y-self.camera.y
  return self:move_camera(xMove,yMove,noTween)
end

---Shake the screen.
--@param distance Number. The maximum distance of the shake.
--@param time Number. The amount of time (in seconds) to do the shaking.
function output:shake(distance,time)
  self.shakeTimer = time
  self.shakeDist = distance
end

---Draw a bordered window.
--@param startX Number. The X-coordinate of the upper left corner.
--@param startY Number. The Y-coordinate of the upper left corner.
--@param endX Number. The X-coordinate of the lower right corner.
--@param endY Number. The Y-coordinate of the lower right corner.
--@param color Table. A table, in the format {r=255,g=255,b=255,a=255}, to be applied to the window. The Alpha value is optional.
--@return Table. A table with the indices startX, startY, maxX, maxY, corresponding to the pixel coordinates of the start and end of the window as above.
function output:draw_window(startX,startY,endX,endY,color)
  color = color or gamesettings.windowColor
  local tileSize = output:get_tile_size(true)
  setColor((color and color.r or 0),(color and color.g or 0),(color and color.b or 0),255)
  love.graphics.rectangle('fill',startX+round(tileSize/2),startY+round(tileSize/2),(endX-startX-tileSize)+(prefs['noImages'] and 0 or tileSize),(endY-startY-tileSize)+(prefs['noImages'] and 0 or tileSize))
  setColor((color and color.r or 255),(color and color.g or 255),(color and color.b or 255),255)
  if prefs['noImages'] ~= true then
    --local batch = love.graphics.newSpriteBatch(images.borders.borderImg,10000)
    local img_max = images.borders.max
    local img_num = (img_max and 1 or false)
    for x=startX+tileSize,endX-(tileSize+1),tileSize do
      --batch:add(images.borders.u,x,startY)
      --batch:add(images.borders.d,x,endY)
      love.graphics.draw(images.borders['borderImg'],images.borders.u,x,startY)
      love.graphics.draw(images.borders['borderImg'],images.borders.d,x,endY)
    end
    for y=startY+tileSize,endY-(tileSize+1),tileSize do
      --batch:add(images.borders.l,startX,y)
      --batch:add(images.borders.r,endX,y)
      love.graphics.draw(images.borders['borderImg'],images.borders.l,startX,y)
      love.graphics.draw(images.borders['borderImg'],images.borders.r,endX,y)
      if img_num then
        img_num = (img_num < img_max and img_num + 1 or 1)
      end
    end
    --[[batch:add(images.borders.u,endX-16,startY)
    batch:add(images.borders.d,endX-16,endY)
    batch:add(images.borders.l,startX,endY-16)
    batch:add(images.borders.r,endX,endY-16)
    batch:add(images.borders.ul,startX,startY)
    batch:add(images.borders.ur,endX,startY)
    batch:add(images.borders.ll,startX,endY)
    batch:add(images.borders.lr,endX,endY)
    --]]
    love.graphics.draw(images.borders.borderImg,images.borders.u,endX-tileSize,startY)
    love.graphics.draw(images.borders.borderImg,images.borders.d,endX-tileSize,endY)
    love.graphics.draw(images.borders.borderImg,images.borders.l,startX,endY-tileSize)
    love.graphics.draw(images.borders.borderImg,images.borders.r,endX,endY-tileSize)
    love.graphics.draw(images.borders.borderImg,images.borders.ul,startX,startY)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,endX,startY)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,startX,endY)
    love.graphics.draw(images.borders.borderImg,images.borders.lr,endX,endY)
    --love.graphics.draw(batch)
  else
    love.graphics.rectangle("line",startX+8,startY+8,endX-startX,endY-startY)
  end
  setColor(255,255,255,255)
  return {minX=startX,minY=startY,maxX=endX,maxY=endY}
end

---Get the quad needed for a given spritesheet
--@param framenum Number. The number of frames in the animation.
--@param framecount Number. The frame in the animation to get
--@return quad. The quad needed for the spritesheet animation
function output:get_spritesheet_quad(framenum,framecount)
  if not quads.sprites[framecount] then --if a quad fitting this size of spritesheet doesn't exist yet, make it
    quads.sprites[framecount] = {}
    local q = quads.sprites[framecount]
    for i=1,framecount,1 do --loop through and make all the quads
      q[#q+1] = love.graphics.newQuad(32*(i-1), 0, 32, 32, 32*framecount, 32)
    end
  end
  return quads.sprites[framecount][framenum]
end

---Create a tweening process. Uses Timer from HUMP, see documentation at https://hump.readthedocs.io/en/latest/timer.html#Timer.tween for more info and examples.
--@param duration Number. Duration of the tween in seconds.
--@param subject Table. Object to be tweened.
--@param target Table. Target values.
--@param method Text. Tweening method, defaults to ‘linear’ (see here, optional).
--@param after Function. Function to execute after the tween has finished (optional).
--@param ... Anything. Additional arguments to the tweening function.
--@return Timer. A timer handle.
function output.tween(...)
  return Timer.tween(unpack({...}))
end

---Runs some code after a duration has passed Uses Timer from HUMP, see documentation at https://hump.readthedocs.io/en/latest/timer.html#Timer.after for more info and examples.
--@param delay Number. Duration of the timer in seconds.
--@param func Function. The function to run after the timer has expired.
--@return Timer. A timer handle.
function output.timer(...)
  return Timer.after(unpack({...}))
end

---Shows an achievement notification.
--@param achievement Text. The ID of the achievement to show.
function output:show_achievement_notification(achievement)
  if not self.notifications then self.notifications = {} end
  self.notifications[#self.notifications+1] = AchievementNotification(achievement)
end

---Shows a notification.
--@param achievemtextent Text. The text for the notificaiton
--@param image Image. The full image name to display (optional
function output:show_notification(text,image)
  if not self.notifications then self.notifications = {} end
  self.notifications[#self.notifications+1] = Notification(text,image)
end

---Shows a popup.
--@param achievement Text. The ID of the achievement to show.
function output:show_popup(text,header,extraLines,blackout,enterOnly,afterFunc,sound)
  if not self.popups then self.popups = {} end
  self.popups[#self.popups+1] = Popup(text,header,extraLines,blackout,enterOnly,afterFunc)
  if sound then output:sound('interface_bang') end
end