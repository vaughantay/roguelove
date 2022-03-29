inventory = {}
--TODO: make it scroll when moving up/down list

function inventory:enter(previous,whichType,action)
  if previous == game then
    self.cursorY = 0
    self.cursorX = 1
    self.scroll=0
    self.yHold = 1
    self.xHold = 1
    self.text = nil
  end
  self.biggestY=0
  self.action=action or self.action
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width,height = round(width/uiScale),round(height/uiScale)
  local padX,padY = 0,0
  if prefs['noImages'] == true then
    padX,padY=5,5
  else
    padX,padY=20,20
  end
  self.padX,self.padY = padX,padY
  self.yModPerc = 0
  if previous == game then
    self.yModPerc = 100
    tween(0.2,self,{yModPerc=0})
  end
  output:sound('stoneslideshort',2)
  self.buttons = {}
  self.filter = whichType or self.filter
  self.sidebarX = round(width/2)+(prefs['noImages'] and 16 or 32)
  self:sort()
end

function inventory:sort()
  --Item types: Usable, Throwable, Equipment, Other
  local fontSize = prefs['fontSize']
  --First, sort by type:
  local sorted = {}
  for i,item in ipairs(player.inventory) do
    if not player:is_equipped(item) then
      if (self.filter == nil) or (item[self.filter] == true) then
        local iType = item.itemType or "other"
        local subType = item.subType or ""
        if not sorted[iType .. subType] then
          sorted[iType .. subType] = {text=iType .. (subType ~= "" and " (" .. ucfirst(subType) .. ")" or "")}
        end
        sorted[iType .. subType][#sorted[iType .. subType]+1] = item
      end --end filter if
    end --end equiiped if
  end --end inventory for
  
  --Put them in the order you'd like to see them:
  local order = gamesettings.default_inventory_order
  for _,iType in ipairs(order) do
    if sorted[iType] then
      sorted[#sorted+1] = sorted[iType]
      sorted[iType] = nil
    end
  end --end itype for
  for i,iType in pairs(sorted) do
    if type(i) ~= "number" then
      sorted[#sorted+1] = sorted[i]
      sorted[i] = nil
    end --end if number
  end --end itype for

  --Then, sort for the page:
  self.inventory = {}
  local itemPrintY = 0
  for _,iType in ipairs(sorted) do
    for i,item in ipairs(iType) do
      if i == 1 then
        self.inventory[#self.inventory+1] = {item=false,y=itemPrintY,text=ucfirst(iType.text)}
        itemPrintY = itemPrintY+fontSize
      end
      self.inventory[#self.inventory+1] = {item=item,y=itemPrintY,text=item:get_name(true)}
      itemPrintY = itemPrintY+fontSize+2
    end --end 
  end --end item type sorting
  
  local equipOrder = gamesettings.default_equipment_order
  self.equipment = {}
  local equipPrintY = (prefs['noImages'] and 16 or 32)
  for _,s in ipairs(equipOrder) do
    local slot = player.equipment[s]
    if slot then
      if #slot == 0 then
        self.equipment[#self.equipment+1] = {item=false,y=equipPrintY,slotName=(slot.name or ucfirst(s))}
        equipPrintY=equipPrintY+fontSize
      else
        for id,equip in ipairs(slot) do
          self.equipment[#self.equipment+1] = {item=equip,y=equipPrintY,slotName=(slot.name or ucfirst(s))}
          equipPrintY=equipPrintY+fontSize
        end --end equip for
      end
    end
  end --end equiporder for

  for slot,eq in pairs(player.equipment) do
    if not in_table(slot,equipOrder) then
      if #eq == 0 then
        self.equipment[#self.equipment+1] = {item=false,y=equipPrintY,slotName=(slot.name or ucfirst(slot))}
        equipPrintY=equipPrintY+fontSize
      else
        for id,equip in ipairs(eq) do
          self.equipment[#self.equipment+1] = {item=equip,y=equipPrintY,slotName=(slot.name or ucfirst(slot))}
          equipPrintY=equipPrintY+fontSize
        end --end equip for
      end --end if count > 0
    end --end slot for
  end --end if not in_table slot,equiporder
end --end inventory:sort()

function inventory:draw()
  local uiScale = (prefs['uiScale'] or 1)
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  width,height = round(width/uiScale),round(height/uiScale)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padX,padY = self.padX,self.padY
  local x,y=self.x,self.y
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  local fontSize = prefs['fontSize']
	
  self.screenMax = round(height/(fontSize+2)/2)
  local padding = (prefs['noImages'] and 16 or 32)
	love.graphics.setFont(fonts.textFont)
  local sidebarX = self.sidebarX
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  local topText = "Inventory"
  if self.action == "use" then topText = "Select items to use"
  elseif self.action == "drop" then topText = "Select items to drop"
  elseif self.action == "throw" then topText = "Select items to throw"
  elseif self.action == "equip" then topText = "Select items to equip" end
  love.graphics.printf(topText .. "\nYou have: $" .. player.money,padding,round(padding*.75),sidebarX-padding*2,"center")
  
  local printX = (prefs['noImages'] and 14 or 32)
  local printY = fontSize*4
  
  if self.text then
    love.graphics.printf(self.text,padding,printY,sidebarX-padding*2,"center")
    local _,olines = fonts.textFont:getWrap(self.text, sidebarX-padding*2)
    printY=printY+(#olines+1)*fontSize
  end
  
  --Filter buttons:
  self.filterButtons = {}
  local boxpadding = (prefs['noImages'] and fontSize or 32)
  local xAdd = math.floor((sidebarX-padding*2)/4)
  --All Items Option:
  local optionX = padding
  local optionW = fonts.textFont:getWidth("All Items")
  if (self.cursorY == 0 and self.cursorX == 1) or (mouseY < printY+fontSize+10 and mouseY > printY-4 and mouseX > optionX-4 and mouseX < optionX+boxpadding+optionW+10) then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",optionX-4,printY-4,boxpadding+optionW+10,fontSize+10)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((not self.filter and "(X)" or "( )"),optionX,printY)
  else
    love.graphics.draw((not self.filter and images.uicheckboxchecked or images.uicheckbox),optionX,printY)
  end
  love.graphics.print("All Items",optionX+boxpadding,printY)
  self.filterButtons[#self.filterButtons+1] = {filter=nil,minX = optionX, maxX = optionX+boxpadding+optionW,minY=printY-4,maxY=printY+fontSize+10}
  --Usable Items Option:
  optionX = padding+xAdd
  optionW = fonts.textFont:getWidth("Usable")
  if (self.cursorY == 0 and self.cursorX == 2) or (mouseY < printY+fontSize+10 and mouseY > printY-4 and mouseX > optionX-4 and mouseX < optionX+boxpadding+optionW+10) then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",optionX-4,printY-4,boxpadding+optionW+10,fontSize+10)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((self.filter == "usable" and "(X)" or "( )"),optionX,printY)
  else
    love.graphics.draw((self.filter == "usable" and images.uicheckboxchecked or images.uicheckbox),optionX,printY)
  end
  love.graphics.print("Usable",optionX+boxpadding,printY)
  self.filterButtons[#self.filterButtons+1] = {filter="usable",minX = optionX, maxX = optionX+boxpadding+optionW,minY=printY-4,maxY=printY+fontSize+10}
  --Throwable Items Option:
  optionX = padding+xAdd*2
  optionW = fonts.textFont:getWidth("Throwable")
  if (self.cursorY == 0 and self.cursorX == 3) or (mouseY < printY+fontSize+10 and mouseY > printY-4 and mouseX > optionX-4 and mouseX < optionX+boxpadding+optionW+10) then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",optionX-4,printY-4,boxpadding+optionW+10,fontSize+10)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((self.filter == "throwable" and "(X)" or "( )"),optionX,printY)
  else
    love.graphics.draw((self.filter == "throwable" and images.uicheckboxchecked or images.uicheckbox),optionX,printY)
  end
  love.graphics.print("Throwable",optionX+boxpadding,printY)
  self.filterButtons[#self.filterButtons+1] = {filter="throwable",minX = optionX, maxX = optionX+boxpadding+optionW,minY=printY-4,maxY=printY+fontSize+10}
  --Equippable Items Option:
  optionX = padding+xAdd*3
  optionW = fonts.textFont:getWidth("Equippable")
  if (self.cursorY == 0 and self.cursorX == 4) or (mouseY < printY+fontSize+10 and mouseY > printY-4 and mouseX > optionX-4 and mouseX < optionX+boxpadding+optionW+10) then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",optionX-4,printY-4,boxpadding+optionW+10,fontSize+10)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((self.filter == "equippable" and "(X)" or "( )"),optionX,printY)
  else
    love.graphics.draw((self.filter == "equippable" and images.uicheckboxchecked or images.uicheckbox),optionX,printY)
  end
  love.graphics.print("Equipment",optionX+boxpadding,printY)
  self.filterButtons[#self.filterButtons+1] = {filter="equippable",minX = optionX, maxX = optionX+boxpadding+optionW,minY=printY-4,maxY=printY+fontSize+10}
  love.graphics.line(padding,printY+fontSize+14,sidebarX-padding,printY+fontSize+14)
  printY = printY+fontSize*2+14
  self.itemStartY = printY

  love.graphics.push()
  local function stencilFunc()
    love.graphics.rectangle("fill",0,self.itemStartY,width,height-self.itemStartY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scroll)
	for i, line in ipairs(self.inventory) do
    local printY = printY+line.y
    --[[if line.item == self.selectedItem then
      setColor(100,100,100,255)
      love.graphics.rectangle("fill",printX-8,printY,sidebarX-printX-padding,fontSize+4)
      setColor(255,255,255,255)
    else]]
    if line.item and ((self.cursorY == i and self.cursorX == 1) or (mouseX > printX and mouseX < sidebarX and mouseY+self.scroll > printY and mouseY+self.scroll < printY+fontSize)) then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",printX-8,printY,sidebarX-printX-padding,fontSize+4)
      setColor(255,255,255,255)
    end
    if line.item == false then
     love.graphics.printf(line.text,printX,printY,sidebarX-padding,"center")
    else
      love.graphics.print(line.text,printX,printY)
    end
    self.biggestY = printY
	end
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  if self.biggestY > height then
    local endY = self.biggestY-self.itemStartY
    local scrollAmt = self.scroll/endY
    self.scrollPositions = output:scrollbar(sidebarX-padX*2,self.itemStartY,math.floor(height)-(prefs['noImages'] and 24 or 16),scrollAmt,true)
  end
  
  --Draw equipment info:
  local equipCutoff=height-padding
  local equipPrintY = padding
  local equipPrintX = sidebarX+padX
  local doneEquips = {}
  for i,equip in ipairs(self.equipment) do
    local slotWidth = fonts.textFont:getWidth(equip.slotName .. ":")
    if not doneEquips[equip.slotName] then
      love.graphics.print(equip.slotName .. ":",equipPrintX,equip.y)
      doneEquips[equip.slotName] = true
    end
    --[[if equip.item == self.selectedItem then
      setColor(100,100,100,255)
      love.graphics.rectangle("fill",equipPrintX+slotWidth+3,equip.y,width-equipPrintX-padding,16)
      setColor(255,255,255,255)
    else]]
    if (self.cursorY == i and self.cursorX == 2) or (equip.item and mouseX > equipPrintX+3 and mouseX < width-padding and mouseY > equip.y and mouseY < equip.y+16) then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",equipPrintX+slotWidth+3,equip.y,width-equipPrintX-padding,16)
      setColor(255,255,255,255)
    end
    love.graphics.print((equip.item and equip.item:get_name(true) or ""),equipPrintX+slotWidth+3,equip.y)
  end
  
  --[[love.graphics.line(sidebarX,equipCutoff,width,equipCutoff)
  
  --Draw highlighted item:
  local item = self.selectedItem or nil
  if item == nil then
    if self.cursorX == 1 then
      item = self.inventory[self.cursorY] and self.inventory[self.cursorY].item
    elseif self.cursorX == 2 then
      item = self.equipment[self.cursorY] and self.equipment[self.cursorY].item
    end
  end
  if item then
    local desc = item:get_description(true)
    local info = item:get_info(true)
    local _, dlines = fonts.descFont:getWrap(desc,width-sidebarX-padding)
    local descH = #dlines*fontSize+fontSize
    local _, ilines = fonts.descFont:getWrap(info,width-sidebarX-padding)
    local infoH = #ilines*fontSize+fontSize*(#ilines > 0 and 2 or 0)
    love.graphics.printf(desc,sidebarX+padX,equipCutoff+8,width-sidebarX-padding,"center")
    love.graphics.printf(info,sidebarX+padX,equipCutoff+8+descH,width-sidebarX-padding,"center")
    
    self.buttons = {}
    self.buttons.xValues = {}
    self.maxButtonCursorX = nil
    
    local buttonX = sidebarX+padding
    local buttonY = equipCutoff+8+descH+infoH
    local buttonCursorX = 3
    if item ~= self.selectedItem then setColor(100,100,100,255) end
    if item.usable==true then
      local useText = (item.useVerb and ucfirst(item.useVerb) or "Use") .. " (" .. keybindings.use[1] .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      self.buttons.use = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and "hover" or nil),useText)
      self.buttons.xValues[buttonCursorX] = "use"
      --love.graphics.printf(useText,buttonX,buttonY,buttonWidth,"center")
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.throwable==true then
      local useText = "Throw (" .. keybindings.throw[1] .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      self.buttons.throw = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and "hover" or nil),useText)
      self.buttons.xValues[buttonCursorX] = "throw"
      --love.graphics.printf(useText,buttonX,buttonY,buttonWidth,"center")
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true then
      local equipped = player:is_equipped(item)
      local useText = (equipped and "Unequip" or "Equip") .. " (" .. keybindings.equip[1] .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      self.buttons.equip = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and "hover" or nil),useText)
      self.buttons.xValues[buttonCursorX] = "equip"
      --love.graphics.printf(useText,buttonX,buttonY,buttonWidth,"center")
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable == true or item.usable == true or item.throwable == true then
      local hotkey = item.hotkey
      local hotkeyText = (hotkey and "Change Hotkey" or "Assign Hotkey")
      local buttonWidth = fonts.buttonFont:getWidth(hotkeyText)+25
      self.buttons.hotkey = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and "hover" or nil),hotkeyText)
      self.buttons.xValues[buttonCursorX] = "hotkey"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    local dropText = "Drop (" .. keybindings.drop[1] .. ")"
    local buttonWidth = fonts.buttonFont:getWidth(dropText)+25
    self.buttons.drop = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and "hover" or nil),dropText)
    self.buttons.xValues[buttonCursorX] = "drop"
    self.maxButtonCursorX = buttonCursorX
    if item ~= self.selectedItem then setColor(255,255,255,255) end
  end--]]
  self.closebutton = output:closebutton(14,14,nil,true)
  love.graphics.pop()
end

function inventory:keypressed(key)
  local letter = key
  key = input:parse_key(key)
	if (key == "escape") then
    --[[if self.selectedItem then
      self.selectedItem = nil
      self.cursorX = self.xHold
    else --]]
      self:switchBack()
    --end
	elseif (key == "enter") or key == "wait" then
    if self.cursorY == 0 then --sorting buttons
      if self.filterButtons[self.cursorX] then
        self.filter = self.filterButtons[self.cursorX].filter
        self:sort()
        if self.action and self.action ~= "drop" then self.action = nil end
      end
    else
      if self.cursorX == 1 then --selecting an item from the list
        if self.inventory[self.cursorY] and self.inventory[self.cursorY].item then
          --self.selectedItem = self.inventory[self.cursorY].item
          Gamestate.switch(examine_item,self.inventory[self.cursorY].item)
          --self.xHold = self.cursorX
          --self.cursorX = 3
          if self.action == "drop" then
            self:dropItem(self.inventory[self.cursorY].item)
          elseif self.action == "equip" then
            self:equipItem(self.inventory[self.cursorY].item)
          elseif self.action == "use" then
            self:useItem(self.inventory[self.cursorY].item)
          elseif self.action == "throw" then
            self:throwItem(self.inventory[self.cursorY].item)
          end
        end --end item exists if
      elseif self.cursorX == 2 then --selecting an item from the equipped list
        if self.equipment[self.cursorY].item then
          Gamestate.switch(examine_item,self.equipment[self.cursorY].item)
          --[[self.selectedItem = self.equipment[self.cursorY].item
          self.xHold = self.cursorX
          self.cursorX = 3]]
        end
      --[[else --buttons for manipulating items
        if self.buttons.xValues[self.cursorX] == "use" then
          self:useItem()
         elseif self.buttons.xValues[self.cursorX] == "equip" then
          self:equipItem()
        elseif self.buttons.xValues[self.cursorX] == "drop" then
          self:dropItem()
        elseif self.buttons.xValues[self.cursorX] == "throw" then
          self:throwItem()
        elseif self.buttons.xValues[self.cursorX] == "hotkey" then
          if self.selectedItem then Gamestate.switch(hotkey,self.selectedItem) end
        end --]]
      end --end cursorX == 1 if
    end --end cursorY == 0 if
	elseif (key == "north") and not self.selectedItem then
    if self.cursorY == 1 then
      self.cursorX = 1
      self.cursorY = 0
		elseif self.cursorX == 1 and self.cursorY > 1 then
			if self.inventory[self.cursorY-1] and self.inventory[self.cursorY-1].item then
        self.cursorY = self.cursorY-1
      else
        for i = self.cursorY-1,1,-1 do
          if self.inventory[i] and self.inventory[i].item then
            self.cursorY = i
            break
          elseif i == 1 then
            self.cursorY = 0
          end --end if item exists here if
        end --end equipment for
      end --end if item exists at next slot if
    elseif self.cursorX == 2 and self.cursorY > 1 then
      if self.equipment[self.cursorY-1] and self.equipment[self.cursorY-1].item then
        self.cursorY = self.cursorY-1
      else
        for i = self.cursorY-1,1,-1 do
          if self.equipment[i] and self.equipment[i].item then
            self.cursorY = i
            break
          end --end if item exists here if
        end --end equipment for
      end --end if item exists at next slot if
		end
	elseif (key == "south") and not self.selectedItem then
    if self.cursorY == 0 then
      self.cursorX = 1
    end
		if self.cursorX == 1 and (self.inventory[self.cursorY+1] ~= nil) then
			if self.inventory[self.cursorY+1].item then
        self.cursorY = self.cursorY+1
      else
        for i = self.cursorY+1,#self.inventory,1 do
          if self.inventory[i].item then
            self.cursorY = i
            break
          end --end if item exists here if
        end --end equipment for
      end --endif item exists and next slot if
    elseif self.cursorX == 2 and self.cursorY < #self.equipment then
      if self.equipment[self.cursorY+1].item then
        self.cursorY = self.cursorY+1
      else
        for i = self.cursorY+1,#self.equipment,1 do
          if self.equipment[i].item then
            self.cursorY = i
            break
          end --end if item exists here if
        end --end equipment for
      end --end if item exists at next slot if
		end --end which cursorX if
  elseif key == "west" then
    if self.cursorY == 0 then
      if self.cursorX > 1 then
        self.cursorX = self.cursorX-1
      end
    elseif self.cursorX == 2 then
      self.cursorX = (self.yHold == 0 and #self.filterButtons or 1)
      self.cursorY,self.yHold = (self.yHold or 1),self.cursorY
    elseif self.cursorX > 3 then self.cursorX = self.cursorX-1 end
  elseif key == "east" then
    if self.cursorY == 0 and self.cursorX < #self.filterButtons then
      self.cursorX = self.cursorX+1
    elseif self.cursorY == 0 or self.cursorX == 1 then
      self.cursorX = 2
      self.cursorY,self.yHold = self.yHold,self.cursorY
      if not self.equipment[self.cursorY] or not self.equipment[self.cursorY].item then
        local done = false
        for i=1,#self.equipment,1 do
          if self.equipment[i].item then
            self.cursorY = i
            done = true
            break
          end --end if item exists here if
        end --end equipment loopthrough for
        if done == false then
          self.cursorX = 1 
          self.cursorY,self.yHold = self.yHold,self.cursorY
        end
      end --end if not equipment at the right slot if
    elseif self.cursorX >= 3 and self.cursorX < self.maxButtonCursorX then
      self.cursorX = self.cursorX + 1
    end --end which cursorX if
  --[[elseif self.selectedItem then --only look at item buttons if you've selected an item
    if key == "use" then
      self:useItem()
    elseif key == "equip" then
      self:equipItem()
    elseif key == "drop" then
      self:dropItem()
    elseif key == "throw" then
      self:throwItem()
    end --]]
	end
end

function inventory:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y = round(x/uiScale),round(y/uiScale)
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    self:switchBack()
  end
  --[[Item use buttons:
  if self.buttons.use and x > self.buttons.use.minX and x < self.buttons.use.maxX and y > self.buttons.use.minY and y < self.buttons.use.maxY then
    return self:useItem()
  elseif self.buttons.equip and self.selectedItem and x > self.buttons.equip.minX and x < self.buttons.equip.maxX and y > self.buttons.equip.minY and y < self.buttons.equip.maxY then
    return self:equipItem()
  elseif self.buttons.drop and self.selectedItem and x > self.buttons.drop.minX and x < self.buttons.drop.maxX and y > self.buttons.drop.minY and y < self.buttons.drop.maxY then
    return self:dropItem()
  elseif self.buttons.throw and self.selectedItem and x > self.buttons.throw.minX and x < self.buttons.throw.maxX and y > self.buttons.throw.minY and y < self.buttons.throw.maxY then
    return self:throwItem()
  elseif self.buttons.hotkey and self.selectedItem and x > self.buttons.hotkey.minX and x < self.buttons.hotkey.maxX and y > self.buttons.hotkey.minY and y < self.buttons.hotkey.maxY then
    if self.selectedItem then Gamestate.switch(hotkey,self.selectedItem) end
  end --]]
  
  --Filter buttons:
  if self.filterButtons[1] and y > self.filterButtons[1].minY and y < self.filterButtons[1].maxY then
    for _,b in ipairs(self.filterButtons) do
      if x > b.minX and x < b.maxX then
        self.filter = b.filter
        self:sort()
        return
      end
    end --end filter for
  end --end filter y
  
  --Selecting an item by clicking on it:
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  width,height=round(width/uiScale),round(height/uiScale)
  local padding = (prefs['noImages'] and 16 or 32)
  local sidebarX = self.sidebarX
  local equipPrintX = sidebarX+self.padX
  local fontSize = prefs['fontSize']
  
  if x > padding and x < sidebarX then
    for i,item in ipairs(self.inventory) do
      if item.item and y+self.scroll > item.y+self.itemStartY and y+self.scroll < item.y+self.itemStartY+fontSize then
        Gamestate.switch(examine_item,item.item)
        return
      end
    end --end inventory for
  elseif x > equipPrintX and x < width-padding then
    for i,item in ipairs(self.equipment) do
      if item.item and y > item.y and y < item.y+fontSize then
        Gamestate.switch(examine_item,item.item)
        return
      end
    end --end inventory for
  end
end

function inventory:useItem(item)
  item = item or self.selectedItem
  if item then
    local use,response = item:use(nil,player)
    if use ~= false then
      self:switchBack()
      if action ~= "targeting" then advance_turn() end
    elseif (item.target_type == "creature" or item.target_type == "tile") and (not item.charges or item.charges > 0) then
      item:target()
      self:switchBack()
    else
      self.text=response
    end
  end
end

function inventory:equipItem(item)
  item = item or self.selectedItem
  if item then
    if player:is_equipped(item) then
      local use,response = player:unequip(item)
      self.text=response
    else
      local use,response = player:equip(item)
      self.text=response
      if use ~= false then advance_turn() end
    end --end if it's equipped or not
    self:sort()
  end --end if item exists
end

function inventory:dropItem(item)
  item = item or self.selectedItem
  player:drop_item(item)
  --self.selectedItem = nil
  self.cursorX=1
  self:sort()
  if self.cursorY > #self.inventory then
    self.cursorY = #self.inventory
  end
  advance_turn()
end

function inventory:throwItem(item)
  item = item or self.selectedItem
  if item and item.throwable then
    action="targeting"
    actionResult=rangedAttacks[self.selectedItem.ranged_attack]
    actionItem=item
    self:switchBack()
  end
end

function inventory:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end
end

function inventory:scrollUp()
  self.scroll = math.max(self.scroll - prefs['fontSize'],0)
end

function inventory:scrollDown()
  self.scroll = self.scroll or 0
  self.scroll = math.min(self.scroll + prefs['fontSize'],(self.biggestY-self.itemStartY))
end

function inventory:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
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

function inventory:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end