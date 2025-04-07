hotkey = {}

function hotkey:enter(previous,hotkeyItem)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=75})
  output:sound('stoneslideshort',2)
  self.previous = previous
  self.hotkeyItem = hotkeyItem
  self.descBox = nil
  self.hotkeyButtons = {}
  self.cursorX = 0
end

function hotkey:draw()
  self.previous:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local midY = math.floor(height/2/uiScale)
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = math.ceil(mouseX/uiScale),math.ceil(mouseY/uiScale)
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle("fill",0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = fonts.textFont:getHeight()
  local buttonFontSize = fonts.buttonFont:getHeight()
  local tileSize = output:get_tile_size()
  local hotkeyItem = self.hotkeyItem
  local name = (hotkeyItem.baseType == "item" and hotkeyItem:get_name(true) or self.hotkeyItem.name)
  local hktext = "Press a number key to use as hotkey for " .. name .. "."
  --Window size stuff
  local windowWidth = 600
  local startX = math.ceil(width/2-windowWidth/2)
  local endX=startX+windowWidth
  local wrapL = windowWidth-padding
  local _,tlines = fonts.textFont:getWrap(hktext,wrapL)
  local windowHeight = round(fontSize*#tlines)+padding*2+tileSize*2
  local startY = round(midY-windowHeight/2)
  local endY = startY+windowHeight
  self.x,self.y = startX,startY
  self.width,self.height = windowWidth,windowHeight
  output:draw_window(startX,startY,endX,endY)
  local printY = startY + padding
  local printX = startX + padding
  love.graphics.printf(hktext,printX,printY,wrapL,"center")
  printY = printY+fontSize+padding
  printX = (startX+math.ceil(windowWidth/2+padding/2))-(tileSize+6)*5
  --Buttons for hotkeys:
  for i = 1,10,1 do
    self.hotkeyButtons[i] = {minX=printX,minY=printY,maxX=printX+tileSize,maxY=printY+tileSize}
    if player.hotkeys[i] then
      local hotkeyInfo = player.hotkeys[i]
      local name = ""
      local canUse = true
      local canUseText = nil
      local hotkeyItem = hotkeyInfo.hotkeyItem
      if not hotkeyItem then
        player.hotkeys[i] = nil
      else
        local hover = self.cursorX == i or (mouseX > printX and mouseY > printY and mouseX < printX+tileSize and mouseY < printY+tileSize)
        if hover then
          if hover then
            self.descBox = {desc=hotkeyItem.name .. "\n" .. hotkeyItem:get_description(),x=printX,y=printY}
          end
          setColor(150,150,150,255)
          love.graphics.rectangle('fill',printX,printY,tileSize,tileSize)
          setColor(255,255,255,255)
        end
        --Draw image:
        if images[hotkeyInfo.type .. (hotkeyItem.image_name or hotkeyItem.id)] then
          if hotkeyItem.color then
            setColor(round(hotkeyItem.color.r/(canUse and 1 or 2)),round(hotkeyItem.color.g/(canUse and 1 or 2)),round(hotkeyItem.color.b/(canUse and 1 or 2)),hotkeyItem.color.a)
          end
          love.graphics.draw(images[hotkeyInfo.type .. (hotkeyItem.image_name or hotkeyItem.id)],printX,printY)
          setColor(255,255,255,255)
        end
        love.graphics.setFont(fonts.buttonFont)
        love.graphics.printf((i == 10 and 0 or i),printX,printY+tileSize,tileSize,"center")
        love.graphics.setFont(fonts.textFont)
        love.graphics.rectangle('line',printX-1,printY-1,tileSize+2,tileSize+2)
      end
    else
      setColor(255,255,255,255)
      local hover = self.cursorX == i or (mouseX > printX and mouseY > printY and mouseX < printX+tileSize and mouseY < printY+tileSize)
      if hover then
        setColor(150,150,150,255)
        love.graphics.rectangle('fill',printX,printY,tileSize,tileSize)
        setColor(255,255,255,255)
      end
      love.graphics.rectangle('line',printX-1,printY-1,tileSize+2,tileSize+2)
      love.graphics.printf((i == 10 and 0 or i),printX,printY+tileSize,tileSize,"center")
    end
    setColor(255,255,255,255)
    printX=printX+tileSize+6
  end
  if self.descBox then
    output:description_box(self.descBox.desc,self.descBox.x+20,self.descBox.y+fontSize)
    self.descBox = nil
  end
  self.closebutton = output:closebutton(startX+8,startY+8,nil,true)
  love.graphics.pop()
end

function hotkey:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
  end
end

function hotkey:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function hotkey:buttonpressed(key,scancode,isRepeat,controllerType)
  local hotkeyItem = self.hotkeyItem
  local origKey = key
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if key == "escape" then
    self:switchBack()
  elseif key == "east" then
    self.cursorX = self.cursorX + 1
    if self.cursorX > 10 then
      self.cursorX = 1
    end
  elseif key == "west" then
    self.cursorX = self.cursorX - 1
    if self.cursorX < 0 then
      self.cursorX = 10
    end
  elseif key == "south" then
    if self.cursorX == 0 then
      self.cursorX = 1
    end
  elseif key == "enter" and self.cursorX ~= 0 then
    return self:buttonpressed(self.cursorX)
  elseif tonumber(key) then
    local keynum = tonumber(key)
    if keynum == 0 then keynum = 10 end
    --Delete old item from hotkey:
    if player.hotkeys[keynum] then
      player.hotkeys[keynum].hotkeyItem.hotkey = nil
    end
    --Delete old hotkey for this item, if applicable
    for i=1,10 do
      if player.hotkeys[i] and player.hotkeys[i].hotkeyItem == hotkeyItem then
        player.hotkeys[i] = nil
      end
    end
    --Actually assign the key:
    player.hotkeys[keynum] = {type=hotkeyItem.baseType,hotkeyItem=hotkeyItem}
    hotkeyItem.hotkey = keynum
    self:switchBack()
  end
end

function hotkey:mousepressed(x,y,button)
  for i,button in ipairs(self.hotkeyButtons) do
    if x > button.minX and x < button.maxX and y > button.minY and y < button.maxY then
      return self:buttonpressed(i)
    end
  end
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) or (x < self.x or x > self.x+self.width or y < self.y or y > self.y+self.height) then
    self:switchBack()
  end
end