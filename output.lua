output = {text={},targetLine={},targetTiles={},potentialTargets={},cursorX=0,cursorY=0,mouseX=0,mouseY=0,buffer={},toDisp={{},{},{}},camera={x=1,y=1,xMod=0,yMod=0},shakeTimer=0,shakeDist=0}

function output:out(txt)
  if action ~= "dying" then
    local tid = #self.text+1
    self.text[tid] = txt
    self.buffer[#self.buffer+1] = tid
  end
end

function output.print_minimap()
  
end

function output.display_entity(entity,x,y, seen,ignoreDistMods,scale)
  if entity.noDraw then return end
  scale = scale or 1
  local alpha = (entity.invisible and 0 or (entity.color.a or 255))
  if (prefs['noImages'] == true or images[(entity.imageType or entity.baseType) .. (entity.image_name or entity.id)] == nil or entity.id == nil) then --if the creature has no image or images are off, then print symbol
    local oldFont = love.graphics.getFont()
    love.graphics.setFont((prefs['noImages'] and fonts.mapFont or fonts.mapFontWithImages))
    if seen then
      if prefs['tileImages'] == true and prefs['creatureShadows'] == true then
        setColor(0,0,0,alpha) --draw a shadow first
        love.graphics.print(entity.symbol,x+(not ignoreDistMods and entity.xMod or 0),y+(not ignoreDistMods and entity.yMod or 0))
      end
      local colorMod = 1
      if entity.baseType == "creature" and seen ~= "force" and not entity.isPlayer and entity.master ~= player and (not entity.notices[player] or not entity.shitlist[player]) then
        colorMod = 1.5
      end
      if entity.temporaryColor then setColor(round(entity.temporaryColor.r/colorMod),round(entity.temporaryColor.g/colorMod),round(entity.temporaryColor.b/colorMod),(entity.temporaryColor.a or alpha))
      else setColor(round(entity.color.r/colorMod),round(entity.color.g/colorMod),round(entity.color.b/colorMod),alpha) end
    else setColor(50,50,50,alpha) end
    love.graphics.print(entity.symbol,x+(not ignoreDistMods and entity.xMod or 0),y+(not ignoreDistMods and entity.yMod or 0))
    setColor(255,255,255,255)
    love.graphics.setFont(oldFont)
    return true --ignore the rest
  end
  -- Image display code:
  if (images[(entity.imageType or entity.baseType) .. (entity.image_name or entity.id)] and images[(entity.imageType or entity.baseType) .. (entity.image_name or entity.id)] ~= nil) then --if image is already loaded, display it
    if entity.baseType == "creature" and prefs['creatureShadows'] then
      setColor(0,0,0,alpha) --draw a shadow first
      if entity.tilemap or entity.spritesheet then
        love.graphics.draw(images[(entity.imageType or entity.baseType) .. (entity.image_name or entity.id)],output:get_spritesheet_quad(entity.image_frame,entity.image_max),x+18*scale+(not ignoreDistMods and entity.xMod or 0),y+16*scale+(not ignoreDistMods and entity.yMod or 0),entity.angle,(entity.faceLeft and -1 or 1)*(entity.scale or 1)*scale,1*(entity.scale or 1)*scale,16,16)
      else
        love.graphics.draw(images[(entity.imageType or entity.baseType) .. (entity.image_name or entity.id)],x+18*scale+(not ignoreDistMods and entity.xMod or 0),y+16*scale+(not ignoreDistMods and entity.yMod or 0),entity.angle,(entity.faceLeft and -1 or 1)*(entity.scale or 1)*scale,1*(entity.scale or 1)*scale,16,16)
      end
    end
    local colorMod = 1
    if not seen then
      colorMod = 2.5
    elseif entity.baseType == "creature" and seen ~= "force" and not entity.isPlayer and entity.master ~= player and (not entity.notices[player] or not entity.shitlist[player]) then
      colorMod = 1.5
    end
    if entity.temporaryColor then setColor(round(entity.temporaryColor.r/colorMod),round(entity.temporaryColor.g/colorMod),round(entity.temporaryColor.b/colorMod),(entity.temporaryColor.a or alpha))
    elseif entity.use_color_with_tiles then setColor(round(entity.color.r/colorMod),round(entity.color.g/colorMod),round(entity.color.b/colorMod),alpha)
    elseif seen then setColor(round(255/colorMod),round(255/colorMod),round(255/colorMod),alpha)
    else setColor(100,100,100,alpha) end
    
    if entity.tilemap and entity.tileDirection then --if it's a tileset, use the quad
      love.graphics.draw(images[(entity.imageType or entity.baseType) .. (entity.image_name or entity.id)],quads[entity.tileDirection],x+16*scale+(not ignoreDistMods and entity.xMod or 0),y+(entity.baseType == "creature" and 14 or 16)*scale+(not ignoreDistMods and entity.yMod or 0),entity.angle,(entity.faceLeft and -1 or 1)*(entity.scale or 1)*scale,1*(entity.scale or 1)*scale,16,16)
    elseif (entity.tilemap or entity.spritesheet) then --if it's a regular spritesheet, use the quad for the frame
      love.graphics.draw(images[(entity.imageType or entity.baseType) .. (entity.image_name or entity.id)],output:get_spritesheet_quad(entity.image_frame,entity.image_max),x+16*scale+(not ignoreDistMods and entity.xMod or 0),y+(entity.baseType == "creature" and 14 or 16)*scale+(not ignoreDistMods and entity.yMod or 0),entity.angle,(entity.faceLeft and -1 or 1)*(entity.scale or 1)*scale,1*(entity.scale or 1)*scale,16,16)
    else --draw the basic image
      love.graphics.draw(images[(entity.imageType or entity.baseType) .. (entity.image_name or entity.id)],x+16*scale+(not ignoreDistMods and entity.xMod or 0),y+(entity.baseType == "creature" and 14 or 16)*scale+(not ignoreDistMods and entity.yMod or 0),entity.angle,(entity.faceLeft and -1 or 1)*(entity.scale or 1)*scale,1*(entity.scale or 1)*scale,16,16)
    end
    if (Gamestate.current() == game or Gamestate.current() == pausemenu) and ((entity.baseType == "creature" and entity:is_type("flyer") == false) or entity.useWalkedOnImage == true) then --for walking creatures (or special features), display features' walking image (splashes in water, bridge over top, etc)
      for _,feat in pairs(currMap:get_tile_features(entity.x,entity.y)) do
        if feat.walkedOnImage and (not entity.moveTween or not entity.fromX or not entity.fromY or currMap:tile_has_feature(entity.fromX,entity.fromY,feat.id)) then
          if images['feature' .. feat.walkedOnImage] == nil then
            --output:load_image(feat.walkedOnImage,"feature")
          end --end if image == nil if
          if images['feature' .. feat.walkedOnImage] ~= nil then
            if seen then setColor(255,255,255,255)
            else setColor(100,100,100,255) end
            if feat.walkedOnTilemap and feat.tileDirection then
              love.graphics.draw(images['feature' .. feat.walkedOnImage],quads[feat.tileDirection],x+16*scale+(feat.walkedOnNoFollow and (feat.xMod or 0) or (entity.xMod or 0)),y+16*scale+(feat.walkedOnNoFollow and (feat.yMod or 0) or (entity.yMod or 0)),feat.angle,(feat.faceLeft and -1 or 1)*(feat.scale or 1)*scale,1*(feat.scale or 1)*scale,16,16)
            else
              love.graphics.draw(images['feature' .. feat.walkedOnImage],x+16*scale+(feat.walkedOnNoFollow and (feat.xMod or 0) or (entity.xMod or 0)),y+16*scale+(feat.walkedOnNoFollow and (feat.yMod or 0) or (entity.yMod or 0)),feat.angle,(feat.faceLeft and -1 or 1)*(feat.scale or 1)*scale,1*(feat.scale or 1)*scale,16,16)
            end --end walked on quad if
          end --end if walked on image ~= -1
        end --end if feat.walkedonimage
      end --end feature for
    end --end creature if
    return true
  else --load image, then display it
    --output:load_image((entity.image_name or entity.id),(entity.imageType or entity.baseType))
  end
end

function output:load_image(name,image_type)
  if images[(image_type or "") .. name] then return true end
  if love.filesystem.getInfo("images/" .. image_type .. "/" .. name .. ".png",'file') then
    images[(image_type or "") .. name] = love.graphics.newImage("images/" .. image_type .. "/" .. name .. ".png")
  else
    images[(image_type or "") .. name] = -1
  end
end

function output:get_portrait(id)
  --If portrait holding table not set up yet, set it up:
  if images['portraits'] == nil then
    images['portraits'] = {}
    images['portraits']['unknown'] = love.graphics.newImage("images/portraits/unknown.png")
  end
  
  --Load portrait if not already loaded
  if images['portraits'][id] == nil then
    if love.filesystem.getInfo("images/portraits/" .. id .. ".png",'file') then
      images['portraits'][id] = love.graphics.newImage("images/portraits/" .. id .. ".png")
    else --if file does not exist, default to question mark
      images['portraits'][id] = images['portraits']['unknown']
    end
  end

  return images['portraits'][id]
end

function output:moveCursor(mx,my)
  return self:setCursor(self.cursorX+mx,self.cursorY+my)
end

function output:setCursor(x,y,force,allow_current_creature)
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
    if (x<2 or y <2 or x>currMap.width-1 or y>currMap.height-1) then return false end --if you'd move off the map, don't move cursor
    if newX < 0 then self:move_camera(-1,0) end
    if newY < 0 then self:move_camera(0,-1) end
    if newX > width then self:move_camera(1,0) end
    if newY > height then self:move_camera(0,1) end 
  end
  
  --If you're targeting a creature-targeting spell, snap to nearest creature
  if force ~= true and Gamestate.current() == game and action == "targeting" and actionResult and (actionResult.target_type == "creature" or actionResult.get_potential_targets) then
    local nearest = nil
    local nearestDist = nil
    if actionResult.target_type == "creature" then
      for _, creat in pairs(player:get_seen_creatures()) do
        if creat.x ~= output.cursorX or creat.y ~= output.cursorY or allow_current_creature then
          local dist = calc_distance(x,y,creat.x,creat.y)
          local xModo,yModo = get_unit_vector(output.cursorX,output.cursorY,x,y)
          local xModc,yModc = get_unit_vector(output.cursorX,output.cursorY,creat.x,creat.y)
          if (nearest == nil or nearestDist == nil or dist < nearestDist) and player:can_sense_creature(creat) and player:does_notice(creat)
            and ((xModo == xModc and (yModo == yModc or yModo == 0)) or (yModo == yModc and (xModo == xModc or xModo == 0))) then
            nearest = creat
            nearestDist = dist
          end --end nearest if
        end --end if not player target
      end --end creature for
    elseif actionResult.target_type and #self.potentialTargets > 0 then
      for _,tar in pairs(self.potentialTargets) do
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
  if Gamestate.current() == game and (actionResult == nil) and (player:can_move_to(x,y) or creat) and currMap:in_map(x,y) and currMap.seenMap[x][y] == true then --if you're moving, draw the path you'll take
    local tempLine = currMap:findPath(player.x,player.y,x,y,player.pathType) or {}
    for _, v in ipairs(tempLine) do
      self.targetLine[#self.targetLine+1] = {x=v.x,y=v.y}
    end --end for
  elseif Gamestate.current() == game and (actionResult and actionResult.projectile == true) and currMap:in_map(x,y) and currMap.seenMap[x][y] == true then --if you're targeting a projectile, draw a line to the target
    local tempLine,_ = currMap:get_line(player.x,player.y,x,y,false,'flyer',false,true,true)
    for _, v in ipairs(tempLine) do
      self.targetLine[#self.targetLine+1] = {x=v[1],y=v[2]}
    end --end for
  end --end action if
  if Gamestate.current() == game and action == "targeting" and actionResult ~= nil and actionResult.get_target_tiles ~= nil then
    local x,y = x,y
    if #self.targetLine > 0 then x,y = self.targetLine[#self.targetLine].x,self.targetLine[#self.targetLine].y end --draw the target box around the last time, not the actual pointed to tile (if they're different)
    self.targetTiles = actionResult:get_target_tiles({x=x,y=y},player)
  end
end

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
  
  --[[local printY = mapHeight/2-((self.camera.y-y)*tileSize)+self.camera.yMod
  local printX = mapWidth/2-((self.camera.x-x)*tileSize)+self.camera.xMod
  if not noRound then
    printX,printY = math.ceil(printX),math.ceil(printY)
  end
  return printX,printY]]
end

--[[function output:tile_to_coordinates(x,y,noRound)
  local mapWidth,mapHeight = self:get_map_dimensions()
  local tileSize = self:get_tile_size()
  
  local printY = mapHeight/2-((self.camera.y-y)*tileSize)+self.camera.yMod
  local printX = mapWidth/2-((self.camera.x-x)*tileSize)+self.camera.xMod
  if noRound then
    return printX,printY
  else
    return math.ceil(printX),math.ceil(printY)
  end
end]]

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

function output:coordinates_to_tile(x,y)
  local mapWidth,mapHeight = self:get_map_dimensions()
  local tileSize = self:get_tile_size()
  local tileY = math.floor(self.camera.y - (mapHeight/2-y)/tileSize)
  local tileX = math.floor(self.camera.x - (mapWidth/2-x)/tileSize)
  return tileX,tileY
end

function output:get_map_width()
  if self.mapWidth then return self.mapWidth end
  local width = love.graphics:getWidth()
  self.mapWidth = width-365
  return self.mapWidth
end

function output:get_map_height()
  if self.mapHeight then return self.mapHeight end
  local height = love.graphics:getHeight()
  self.mapHeight = height-30
  return self.mapHeight
end

function output:get_map_dimensions()
  if self.mapWidth and self.mapHeight then return self.mapWidth,self.mapHeight end
  return self:get_map_width(),self:get_map_height()
end

function output:get_tile_size()
  return math.floor((prefs['noImages'] and prefs['asciiSize'] or 32)*(currGame and currGame.zoom or 1))
end

function output:load_ui()
  images.borders = {borderImg=love.graphics.newImage("images/ui/borders.png"),ul = love.graphics.newQuad(0,0,32,32,96,96),ur = love.graphics.newQuad(64,0,32,32,96,96),ll = love.graphics.newQuad(0,64,32,32,96,96),lr = love.graphics.newQuad(64,64,32,32,96,96),u = love.graphics.newQuad(32,0,32,32,96,96),d = love.graphics.newQuad(32,64,32,32,96,96),l = love.graphics.newQuad(0,32,32,32,96,96),r = love.graphics.newQuad(64,32,32,32,96,96)}
  images.button = {image=love.graphics.newImage("images/ui/button.png"),hover=love.graphics.newImage("images/ui/buttonhover.png"),l=love.graphics.newQuad(0,0,32,32,128,32),middle=love.graphics.newQuad(32,0,32,32,128,32),r=love.graphics.newQuad(64,0,32,32,128,32),small=love.graphics.newQuad(96,0,32,32,128,32)}
  images.smallbutton = {image=love.graphics.newImage("images/ui/smallbutton.png"),hover=love.graphics.newImage("images/ui/smallbuttonhover.png"),disabled=love.graphics.newImage("images/ui/smallbuttondisabled.png"),l=love.graphics.newQuad(0,0,32,16,128,16),middle=love.graphics.newQuad(32,0,32,16,128,16),r=love.graphics.newQuad(64,0,32,16,128,16),small=love.graphics.newQuad(96,0,32,16,128,16)}
  images.largebutton = {image=love.graphics.newImage("images/ui/button.png"),hover=love.graphics.newImage("images/ui/buttonlarge.png"),l=love.graphics.newQuad(0,0,64,64,256,64),middle=love.graphics.newQuad(64,0,64,64,256,64),r=love.graphics.newQuad(128,0,64,64,256,64),small=love.graphics.newQuad(192,0,64,64,256,64)}
  images.closebutton = {image=love.graphics.newImage("images/ui/closebutton.png"),hover=love.graphics.newImage("images/ui/closebuttonhover.png")}
  images.cursors = {main = love.mouse.newCursor("images/ui/cursor.png",0,0)}
  --love.mouse.setCursor(images.cursors.main)
end

function output:load_all_images()
  local folders = love.filesystem.getDirectoryItems('images')
  for _,folderName in pairs(folders) do
    if love.filesystem.getInfo('images/' .. folderName,'directory') then
      local files = love.filesystem.getDirectoryItems('images/' .. folderName)
      for _,fileName in pairs(files) do
        local extension = string.sub(fileName, -4)
        if extension == ".png" then
          fileName = string.sub(fileName,1,-5)
          images[folderName .. fileName] = love.graphics.newImage("images/" .. folderName .. "/" .. fileName .. ".png")
        end --end extension check
      end --end fileName for
    end --end is folder if
  end --end folderName for
  for _,tileset in pairs(love.filesystem.getDirectoryItems('images/levels')) do
    local files = love.filesystem.getDirectoryItems('images/levels/' .. tileset)
    for _,fileName in pairs(files) do
      local extension = string.sub(fileName, -4)
      if extension == ".png" then
        fileName = string.sub(fileName,1,-5)
        images[tileset .. fileName] = love.graphics.newImage("images/levels/" .. tileset .. "/" .. fileName .. ".png")
      end --end extension check
    end --end fileName for
  end
  if images['uicursor'] and not prefs['noImages'] then
    love.mouse.setCursor(love.mouse.newCursor("images/ui/cursor.png"))
  end
end

function output:draw_health_bar(val,max_val,x,y,width,height)
  setColor(255,255,255,255)
  love.graphics.rectangle('line',x-1,y-1,width+2,height+2)
  if val < 1 then return end
  local barWidth = math.max(math.ceil((val/max_val)*width),1)
  if prefs['noImages'] == true then
    setColor(255,0,0,255)
    love.graphics.rectangle('fill',x,y,barWidth,height)
    setColor(255,255,255,255)
  else
    for px=x,x+barWidth,2 do
      if px+2 < x+barWidth then love.graphics.draw(images.uihealthbartiny,px,y) end
    end --end for
    love.graphics.draw(images.uihealthbartiny,x+barWidth-2,y)
  end --end images/noimages if
end

function output:sound(soundName,pitchDiff)
  if not pitchDiff then pitchDiff = 10 end
    
  -- Load sound first
  if not sounds[soundName] then
    if love.filesystem.getInfo("sounds/" .. soundName ..".ogg",'file') then
      sounds[soundName] = ripple.newSound({source=love.audio.newSource("sounds/" .. soundName ..".ogg",'static'),tags={soundTags.sfx}})
      elseif love.filesystem.getInfo("sounds/" .. soundName .. ".wav",'file') then
      sounds[soundName] = ripple.newSound({source=love.audio.newSource("sounds/" .. soundName ..".wav",'static'),tags={soundTags.sfx}})
    elseif love.filesystem.getInfo("sounds/" .. soundName .. ".mp3",'file') then
      sounds[soundName] = ripple.newSound({source=love.audio.newSource("sounds/" .. soundName ..".mp3",'static'),tags={soundTags.sfx}})
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

function output:make_playlist(name)
  --If there is only one track:
  if love.filesystem.getInfo('music/' .. name .. '.ogg','file') then
    return {'music/' .. name .. '.ogg'}
  elseif love.filesystem.getInfo('music/' .. name .. '.mp3','file') then
    return {'music/' .. name .. '.mp3'}
  elseif love.filesystem.getInfo('music/' .. name .. '.wav','file') then
    return {'music/' .. name .. '.wav'}
  elseif love.filesystem.getInfo('music/' .. name,'directory') then
    local files = love.filesystem.getDirectoryItems('music/' .. name)
    local tracks = {}
    for _,fileName in pairs(files) do
      local extension = string.sub(fileName, -4)
      if extension == ".mp3" or extension == ".ogg" or extension == ".wav" then
        tracks[#tracks+1] = name
        music[name] = ripple.newSound({source=love.audio.newSource('music/' .. name .. '/' .. fileName,'stream'),tags={soundTags.music}})
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

function output:scrollbar(x,startY,endY,scrollPerc,useScaling)
  local mouseX,mouseY = love.mouse.getPosition()
  local uiScale = 1
  if useScaling then
    uiScale = (prefs['uiScale'] or 1)
    mouseX,mouseY = math.ceil(mouseX/uiScale),math.ceil(mouseY/uiScale)
  end
  if prefs['noImages'] ~= true then
    setColor(100,100,100,255)
    for y=startY,endY-32,32 do
      love.graphics.draw(images.uidot,x,y)
    end
    setColor(255,255,255,255)
    --Draw up arrow:
    if mouseX > x and mouseX < x+32 and mouseY > startY and mouseY < startY+32 then love.graphics.draw(images.uiscrollarrowhighlight,x,startY)
    else love.graphics.draw(images.uiscrollarrow,x,startY) end
    --Draw down arrow:
    if mouseX > x and mouseX < x+32 and mouseY > endY-32 and mouseY < endY then love.graphics.draw(images.uiscrollarrowhighlight,x,endY,0,1,-1)
    else love.graphics.draw(images.uiscrollarrow,x,endY,0,1,-1) end
    --Draw "elevator"
    local elevatorY = startY+32+round(scrollPerc*(endY-startY-96))
    if mouseX > x and mouseX < x+32 and mouseY > elevatorY and mouseY < elevatorY+32 then love.graphics.draw(images.uiscrollelevatorhighlight,x,elevatorY)
    else love.graphics.draw(images.uiscrollelevator,x,elevatorY) end
    return {upArrow={startX=x*uiScale,endX=(x+32)*uiScale,startY=startY*uiScale,endY=(startY+32)*uiScale},downArrow={startX=x*uiScale,endX=(x+32)*uiScale,startY=(endY-32)*uiScale,endY=endY*uiScale},elevator={startX=x*uiScale,endX=(x+32)*uiScale,startY=elevatorY*uiScale,endY=(elevatorY+32)*uiScale}} -- return positions, for clicking
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
    return {upArrow={startX=x*uiScale,endX=(x+21)*uiScale,startY=startY*uiScale,endY=(startY+21)*uiScale},downArrow={startX=x*uiScale,endX=(x+21)*uiScale,startY=endY*uiScale,endY=(endY+21)*uiScale},elevator={startX=x*uiScale,endX=(x+21)*uiScale,startY=(elevatorY-7)*uiScale,endY=(elevatorY+21)*uiScale}}
  end
end

function output:button(x,y,width,small,special,text,useScaling)
  local mouseX,mouseY = love.mouse.getPosition()
  local uiScale = 1
  if useScaling then
    uiScale = (prefs['uiScale'] or 1)
    mouseX,mouseY = math.ceil(mouseX/uiScale),math.ceil(mouseY/uiScale)
  end
  local hover = false
  if prefs['noImages'] ~= true then
    local buttonname = (small and "smallbutton" or "button")
    local image = (special and images[buttonname][special] or images[buttonname].image)
    if mouseX > x and mouseX < x+math.max(width,64) and mouseY>y and mouseY<y+(small and 16 or 32) then
      if not special then image = images[buttonname].hover end
      hover = true
    end
    love.graphics.draw(image,images[buttonname].l,x,y)
    love.graphics.draw(image,images[buttonname].r,math.max(x+width-32,x+32),y)
    if width > 64 then
      love.graphics.draw(image,images[buttonname].middle,x+32,y)
      if width > 96 then
        for drawX = x+64,x+width-32,32 do
          love.graphics.draw(image,images[buttonname].middle,drawX,y)
        end
      end
    end
    if text then
      love.graphics.setFont(fonts.buttonFont)
      love.graphics.printf(text,math.floor(x),math.floor(y+4),width,"center")
      love.graphics.setFont(fonts.textFont)
    end
    return {minX=x*uiScale,maxX=(x+math.max(width,64))*uiScale,minY=y*uiScale,maxY=(y+(small and 16 or 32))*uiScale,hover=hover}
  else --imageless buttons
    if (mouseX > x and mouseX < x+math.max(width,64) and mouseY>y and mouseY<y+(small and 16 or 32)) or special == "hover" then
      hover = true
    end
    if hover then
      setColor(100,100,100,255)
    else
      setColor(33,33,33,255)
    end
    love.graphics.rectangle('fill',x,y,math.max(width,64),(small and 16 or 32))
    setColor(255,255,255,255)
    love.graphics.rectangle('line',x,y,math.max(width,64),(small and 16 or 32))
    if text then
      love.graphics.setFont(fonts.buttonFont)
      love.graphics.printf(text,math.floor(x),math.floor(y+4),width,"center")
      love.graphics.setFont(fonts.textFont)
    end
    return {minX=x*uiScale,maxX=(x+math.max(width,64))*uiScale,minY=y*uiScale,maxY=(y+(small and 16 or 32))*uiScale,hover=hover}
  end
end

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
    return {minX=x*uiScale,maxX=x+(math.max(width,128))*uiScale,minY=y*uiScale,maxY=(y+64)*uiScale,hover=hover}
  end
end

function output:closebutton(x,y,hover,useScaling)
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
    local image = (hover and images.closebutton.hover or images.closebutton.image)
    love.graphics.draw(image,x,y)
    return {minX=x,maxX=x+16,minY=y,maxY=y+16,hover=hover}
  else --imageless buttons
    if (mouseX > x and mouseX < x+16 and mouseY>y and mouseY<y+16) or special == "hover" then
      hover = true
    end
    if hover then
      setColor(100,100,100,255)
    else
      setColor(33,33,33,255)
    end
    love.graphics.rectangle('fill',x,y,16,16)
    setColor(255,255,255,255)
    love.graphics.rectangle('line',x,y,16,16)
    love.graphics.printf("X",x,y,16,"center")
    return {minX=x*uiScale,maxX=(x+16)*uiScale,minY=y*uiScale,maxY=(y+16)*uiScale,hover=hover}
  end
end

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

function output:set_camera(x,y,noTween)
  local xMove,yMove = x-self.camera.x,y-self.camera.y
  return self:move_camera(xMove,yMove,noTween)
end

function output:shake(distance,time)
  self.shakeTimer = time
  self.shakeDist = distance
end

function output:draw_window(startX,startY,endX,endY)
  setColor(0,0,0,200)
  love.graphics.rectangle('fill',startX+9,startY+9,(endX-startX-2)+(prefs['noImages'] and 0 or 16),(endY-startY-2)+(prefs['noImages'] and 0 or 16))
  setColor(255,255,255,255)
  if prefs['noImages'] ~= true then
    --local batch = love.graphics.newSpriteBatch(images.borders.borderImg,10000)
    for x=startX+16,endX-16,32 do
      --batch:add(images.borders.u,x,startY)
      --batch:add(images.borders.d,x,endY)
      love.graphics.draw(images.borders.borderImg,images.borders.u,x,startY)
      love.graphics.draw(images.borders.borderImg,images.borders.d,x,endY)
    end
    for y=startY+16,endY-16,32 do
      --batch:add(images.borders.l,startX,y)
      --batch:add(images.borders.r,endX,y)
      love.graphics.draw(images.borders.borderImg,images.borders.l,startX,y)
      love.graphics.draw(images.borders.borderImg,images.borders.r,endX,y)
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
    love.graphics.draw(images.borders.borderImg,images.borders.u,endX-16,startY)
    love.graphics.draw(images.borders.borderImg,images.borders.d,endX-16,endY)
    love.graphics.draw(images.borders.borderImg,images.borders.l,startX,endY-16)
    love.graphics.draw(images.borders.borderImg,images.borders.r,endX,endY-16)
    love.graphics.draw(images.borders.borderImg,images.borders.ul,startX,startY)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,endX,startY)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,startX,endY)
    love.graphics.draw(images.borders.borderImg,images.borders.lr,endX,endY)
    --love.graphics.draw(batch)
  else
    love.graphics.rectangle("line",startX+8,startY+8,endX-startX,endY-startY)
  end
  return {minX=startX,minY=startY,maxX=endX,maxY=endY}
end

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

function output.tween(...)
  return Timer.tween(unpack({...}))
end

function output.timer(...)
  return Timer.after(unpack({...}))
end

function output:show_achievement_popup(achievement)
  self.popup = AchievementPopup(achievement)
end