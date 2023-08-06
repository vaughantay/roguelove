examine_item = {}
--TODO: Add scrolling for long descriptions

function examine_item:enter(previous,item)
  if previous ~= hotkey and previous ~= splitstack and previous ~= nameitem then
    local width, height = love.graphics:getWidth(),love.graphics:getHeight()
    local uiScale = (prefs['uiScale'] or 1)
    width,height = round(width/uiScale),round(height/uiScale)
    self.previous=previous
    self.item=item
    self.has_item = player:has_specific_item(self.item)
    self.cursorX,self.cursorY=1,1
    self.scroll=0
    self.scrollMax=0
    self.width = round(width/2)
    self.x = round(width/2-self.width/2)
    self.height = self:calculate_height()
    self.y = round(height/2-self.height/2)
    self.yModPerc = 100
    tween(0.2,self,{yModPerc=0})
    output:sound('stoneslideshort',2)
    self.buttons = {}
  end
end

function examine_item:draw()
  self.previous:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width,height = round(width/uiScale),round(height/uiScale)
  local fontSize = prefs['fontSize']
  local padding = 16
  
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  
  output:draw_window(self.x,self.y,self.x+self.width,self.y+self.height)
  
  local item = self.item
  local name = item:get_name(true)
  local level = item.level
  local desc = item:get_description()
  local info = item:get_info(true)
  local textW = (self.scrollMax > 0 and self.width-32 or self.width)
  local _, nlines = fonts.textFont:getWrap(name,self.width)
  local nameH = #nlines*(fontSize+1)
  local _, dlines = fonts.textFont:getWrap(desc,textW)
  local descH = #dlines*(fontSize+2)
  local _, ilines = fonts.textFont:getWrap(info,textW)
  local infoH = #ilines*fontSize+fontSize*(#ilines > 0 and 2 or 0)
  local printY = self.y+padding
  love.graphics.printf(name,self.x+padding,printY,self.width,"center")
  printY=printY+nameH
  if level and gamesettings.display_item_levels then
    local ltext = "Level " .. level
    local _, llines = fonts.textFont:getWrap(ltext,textW)
    local levelH = #llines*(fontSize+1)
    love.graphics.printf("Level " .. level,self.x+padding,printY,self.width,"center")
    printY=printY+levelH
  end
  
  self.buttons = {}
  
  if self.has_item then
    local buttonStartX = self.x+padding
    local buttonX = buttonStartX
    local buttonMaxX = self.x+self.width
    local buttonY = printY+padding
    local buttonCursorX = 1
    local buttonCursorY = 1
    self.buttons.values = {}
    self.buttons.values[buttonCursorY]={}
    
    if item.usable==true then
      local useText = (item.useVerb and ucfirst(item.useVerb) or "Use") .. " (" .. input:get_button_name("use") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      if not player:can_use_item(item) then
        setColor(175,175,175,255)
      end
      self.buttons.use = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      if not player:can_use_item(item) then
        setColor(255,255,255,255)
      end
      self.buttons.values[buttonCursorY][buttonCursorX] = "use"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.throwable==true then
      local useText = "Throw (" .. input:get_button_name("throw") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.throw = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "throw"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true then
      local equipped = player:is_equipped(item)
      local useText = (equipped and "Unequip" or "Equip") .. " (" .. input:get_button_name("equip") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.equip = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "equip"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.charges and (item.max_charges and item.max_charges > 0) then
      local useText = "Reload/Recharge" .. " (" .. input:get_button_name("recharge") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      if item.charges >= item.max_charges then
        setColor(175,175,175,255)
      end
      self.buttons.reload = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      if item.charges >= item.max_charges then
        setColor(255,255,255,255)
      end
      self.buttons.values[buttonCursorY][buttonCursorX] = "reload"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true and not item.stacks then
      local useText = (item.properName and "Rename" or "Name")
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.name = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "name"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.stacks==true and item.amount and item.amount > 1 then
      local useText = "Split Stack"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.split = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "split"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable == true or item.usable == true or item.throwable == true then
      local hotkey = item.hotkey
      local hotkeyText = (hotkey and "Change Hotkey" or "Assign Hotkey")
      local buttonWidth = fonts.buttonFont:getWidth(hotkeyText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.hotkey = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),hotkeyText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "hotkey"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    local dropText = "Drop (" .. input:get_button_name("drop") .. ")"
    local buttonWidth = fonts.buttonFont:getWidth(dropText)+25
    if buttonX+buttonWidth >= buttonMaxX then
      buttonCursorX=1
      buttonCursorY=buttonCursorY+1
      self.buttons.values[buttonCursorY] = {}
      buttonX = buttonStartX
      buttonY = buttonY+40
    end
    if not item.undroppable then
      self.buttons.drop = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),dropText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "drop"
      printY=buttonY+40
      love.graphics.line(self.x+padding,printY,self.x+padding+self.width,printY)
      printY=printY+padding
    end
  end --end if has_item
  love.graphics.printf(desc,self.x+padding,printY,self.width,"center")
  printY=printY+descH
  love.graphics.printf(info,self.x+padding,printY,self.width,"center")
  printY=printY+infoH
  if printY > self.height then
    --TODO: add scrolling
  end
  self.closebutton = output:closebutton(self.x+round(padding/2),self.y+round(padding/2),nil,true)
  love.graphics.pop()
end

function examine_item:calculate_height()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width,height = round(width/uiScale),round(height/uiScale)
  local fontSize = prefs['fontSize']
  local padding = 16
  
  local item = self.item
  local name = item:get_name(true)
  local level = item.level
  local desc = item:get_description()
  local info = item:get_info(true)
  local textW = (self.scrollMax > 0 and self.width-32 or self.width)
  local _, nlines = fonts.textFont:getWrap(name,self.width)
  local nameH = #nlines*(fontSize+1)
  local _, dlines = fonts.textFont:getWrap(desc,textW)
  local descH = #dlines*(fontSize+2)
  local _, ilines = fonts.textFont:getWrap(info,textW)
  local infoH = #ilines*fontSize+fontSize*(#ilines > 0 and 2 or 0)
  local printY = padding
  printY=printY+nameH
  if level and gamesettings.display_item_levels then
    local ltext = "Level " .. level
    local _, llines = fonts.textFont:getWrap(ltext,textW)
    local levelH = #llines*(fontSize+1)
    printY=printY+levelH
  end
  
  if self.has_item then
    local buttonStartX = self.x+padding
    local buttonX = buttonStartX
    local buttonMaxX = self.x+self.width
    local buttonY = printY+padding
    local buttonCursorX = 1
    local buttonCursorY = 1
    
    if item.usable==true then
      local useText = (item.useVerb and ucfirst(item.useVerb) or "Use") .. " (" .. input:get_button_name("use") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.throwable==true then
      local useText = "Throw (" .. input:get_button_name("throw") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true then
      local equipped = player:is_equipped(item)
      local useText = (equipped and "Unequip" or "Equip") .. " (" .. input:get_button_name("equip") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.charges and (not item.max_charges or item.max_charges > 0) then
      local useText = "Reload" .. " (" .. input:get_button_name("recharge") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true and not item.stacks then
      local useText = (item.properName and "Rename" or "Name")
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.stacks==true and item.amount and item.amount > 1 then
      local useText = "Split Stack"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable == true or item.usable == true or item.throwable == true then
      local hotkey = item.hotkey
      local hotkeyText = (hotkey and "Change Hotkey" or "Assign Hotkey")
      local buttonWidth = fonts.buttonFont:getWidth(hotkeyText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    local dropText = "Drop (" .. input:get_button_name("drop") .. ")"
    local buttonWidth = fonts.buttonFont:getWidth(dropText)+25
    if buttonX+buttonWidth >= buttonMaxX then
      buttonCursorX=1
      buttonCursorY=buttonCursorY+1
      buttonX = buttonStartX
      buttonY = buttonY+40
    end
    printY=buttonY+40
    love.graphics.line(self.x+padding,printY,self.x+padding+self.width,printY)
    printY=printY+padding
  end --end if has_item
  printY=printY+descH
  printY=printY+infoH
  printY=printY+padding
  return math.min(height,printY)
end

function examine_item:buttonpressed(key)
  local letter = key
  key = input:parse_key(key)
	if (key == "escape") then
    self:switchBack()
	elseif self.has_item and ((key == "enter") or key == "wait") then
    if self.buttons.values[self.cursorY][self.cursorX] == "use" then
      self:switchBack()
      inventory:useItem(self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "equip" then
      self:switchBack()
      inventory:equipItem(self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "drop" then
      self:switchBack()
      inventory:dropItem(self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "throw" then
      self:switchBack()
      inventory:throwItem(self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "hotkey" then
      Gamestate.switch(hotkey,self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "split" then
      Gamestate.switch(splitstack,self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "name" then
      Gamestate.switch(nameitem,self.item)
    end
	elseif (key == "north") then
    self.cursorY = math.max(self.cursorY-1,1)
	elseif (key == "south") then
    self.cursorY = math.min(self.cursorY+1,#self.buttons.values)
  elseif key == "west" then
    self.cursorX = self.cursorX - 1
    if self.cursorX < 1 then
      if self.cursorY > 1 then
        self.cursorY = math.max(self.cursorY-1,1)
        self.cursorX = #self.buttons.values[self.cursorY]
      else
        self.cursorX = 1
      end
    end
  elseif key == "east" then
    self.cursorX = self.cursorX + 1
    if self.cursorX > #self.buttons.values[self.cursorY] then
      if self.cursorY < #self.buttons.values then
      self.cursorY = math.min(self.cursorY+1,#self.buttons.values)
      self.cursorX = 1
      else
        self.cursorX = #self.buttons.values[self.cursorY]
      end
    end
  elseif key == "use" and self.has_item then
    self:switchBack()
    inventory:useItem(self.item)
  elseif key == "equip" and self.has_item then
    self:switchBack()
    inventory:equipItem(self.item)
  elseif key == "drop" and self.has_item then
    self:switchBack()
    inventory:dropItem(self.item)
  elseif key == "recharge" and self.has_item then
    self:switchBack()
    inventory:reloadItem(self.item)
  elseif key == "throw" and self.has_item then
    self:switchBack()
    inventory:throwItem(self.item)
  end
end

function examine_item:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end
end

function examine_item:scrollUp()
  self.scroll = math.max(self.scroll - prefs['fontSize'],0)
end

function examine_item:scrollDown()
  self.scroll = self.scroll or 0
  self.scroll = math.min(self.scroll + prefs['fontSize'],self.scrollMax)
end

function examine_item:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
    return
  end
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale, y/uiScale
	if (x ~= output.mouseX or y ~= output.mouseY) then -- only do this if the mouse has moved
    output.mouseX,output.mouseY = x,y
	end
  --Scrollbars:
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local upArrow = self.scrollPositions.upArrow
    local downArrow = self.scrollPositions.downArrow
    local elevator = self.scrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:scrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:scrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then
        self:scrollUp()
      elseif y>elevator.endY then
        self:scrollDown()
      end
    end --end clicking on arrow
  end
end

function examine_item:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  local padding = prefs['noImages'] and 16 or 32
  x,y = round(x/uiScale),round(y/uiScale)
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) or (x < self.x or x > self.x+self.width or y < self.y or y > self.y+self.height+padding) then
    self:switchBack()
  end
  --Item use buttons:
  if self.buttons.use and x > self.buttons.use.minX and x < self.buttons.use.maxX and y > self.buttons.use.minY and y < self.buttons.use.maxY then
    self:switchBack()
    inventory:useItem(self.item)
  elseif self.buttons.equip and x > self.buttons.equip.minX and x < self.buttons.equip.maxX and y > self.buttons.equip.minY and y < self.buttons.equip.maxY then
    self:switchBack()
    inventory:equipItem(self.item)
  elseif self.buttons.drop and x > self.buttons.drop.minX and x < self.buttons.drop.maxX and y > self.buttons.drop.minY and y < self.buttons.drop.maxY then
    self:switchBack()
    inventory:dropItem(self.item)
  elseif self.buttons.throw and x > self.buttons.throw.minX and x < self.buttons.throw.maxX and y > self.buttons.throw.minY and y < self.buttons.throw.maxY then
    self:switchBack()
    inventory:throwItem(self.item)
  elseif self.buttons.hotkey and x > self.buttons.hotkey.minX and x < self.buttons.hotkey.maxX and y > self.buttons.hotkey.minY and y < self.buttons.hotkey.maxY then
    Gamestate.switch(hotkey,self.item)
  elseif self.buttons.split and x > self.buttons.split.minX and x < self.buttons.split.maxX and y > self.buttons.split.minY and y < self.buttons.split.maxY then
    Gamestate.switch(splitstack,self.item)
  elseif self.buttons.name and x > self.buttons.name.minX and x < self.buttons.name.maxX and y > self.buttons.name.minY and y < self.buttons.name.maxY then
    Gamestate.switch(nameitem,self.item)
  elseif self.buttons.reload and x > self.buttons.reload.minX and x < self.buttons.reload.maxX and y > self.buttons.reload.minY and y < self.buttons.reload.maxY then
    self:switchBack()
    inventory:reloadItem(self.item)
  end
end

function examine_item:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end