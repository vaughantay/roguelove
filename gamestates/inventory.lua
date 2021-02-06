inventory = {}

function inventory:enter(previous,whichType)
  self.cursorY = 0
  self.cursorX = 1
  self.scroll=0
  self.biggestY=0
  self.selectedItem=nil
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local padX,padY = 0,0
  if prefs['noImages'] == true then
    padX,padY=5,5
  else
    padX,padY=20,20
  end
  self.padX,self.padY = padX,padY
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.buttons = {}
  self.yHold = 1
  self.xHold = 1
  self.filter = whichType
  self.text = ""
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
  local order = {'usable','throwable','weapon','offhand','armorhead','armortorso','armorhands','armorlegs','armorfeet','accessory','ammo','other'}
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
  local itemPrintY = fontSize*6
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
  
  local equipOrder = {'weapon','offhand','head','torso','hands','legs','feet','accessory','ammo'}
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
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padX,padY = self.padX,self.padY
  local x,y=self.x,self.y
  local mouseX,mouseY = love.mouse.getPosition()
  local fontSize = prefs['fontSize']
	
  self.screenMax = round(height/(fontSize+2)/2)
  local padding = (prefs['noImages'] and 16 or 32)
	love.graphics.setFont(fonts.textFont)
  local sidebarX = round(width/2)+padding
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  love.graphics.printf("Inventory\nYou have: $" .. player.money,padding,round(padding*.75),sidebarX-padding,"center")
  
  local printX = (prefs['noImages'] and 14 or 32)
  
  --Filter buttons:
  self.filterButtons = {}
  local boxpadding = (prefs['noImages'] and fontSize or 32)
  local filterY = fontSize*4
  local xAdd = math.floor((sidebarX-padding*2)/4)
  --All Items Option:
  local optionX = padding
  local optionW = fonts.textFont:getWidth("All Items")
  if (self.cursorY == 0 and self.cursorX == 1) or (mouseY < filterY+fontSize+10 and mouseY > filterY-4 and mouseX > optionX-4 and mouseX < optionX+boxpadding+optionW+10) then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",optionX-4,filterY-4,boxpadding+optionW+10,fontSize+10)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((not self.filter and "(X)" or "( )"),optionX,filterY)
  else
    love.graphics.draw((not self.filter and images.uicheckboxchecked or images.uicheckbox),optionX,filterY)
  end
  love.graphics.print("All Items",optionX+boxpadding,filterY)
  self.filterButtons[#self.filterButtons+1] = {filter=nil,minX = optionX, maxX = optionX+boxpadding+optionW,minY=filterY-4,maxY=filterY+fontSize+10}
  --Usable Items Option:
  optionX = padding+xAdd
  optionW = fonts.textFont:getWidth("Usable")
  if (self.cursorY == 0 and self.cursorX == 2) or (mouseY < filterY+fontSize+10 and mouseY > filterY-4 and mouseX > optionX-4 and mouseX < optionX+boxpadding+optionW+10) then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",optionX-4,filterY-4,boxpadding+optionW+10,fontSize+10)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((self.filter == "usable" and "(X)" or "( )"),optionX,filterY)
  else
    love.graphics.draw((self.filter == "usable" and images.uicheckboxchecked or images.uicheckbox),optionX,filterY)
  end
  love.graphics.print("Usable",optionX+boxpadding,filterY)
  self.filterButtons[#self.filterButtons+1] = {filter="usable",minX = optionX, maxX = optionX+boxpadding+optionW,minY=filterY-4,maxY=filterY+fontSize+10}
  --Throwable Items Option:
  optionX = padding+xAdd*2
  optionW = fonts.textFont:getWidth("Throwable")
  if (self.cursorY == 0 and self.cursorX == 3) or (mouseY < filterY+fontSize+10 and mouseY > filterY-4 and mouseX > optionX-4 and mouseX < optionX+boxpadding+optionW+10) then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",optionX-4,filterY-4,boxpadding+optionW+10,fontSize+10)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((self.filter == "throwable" and "(X)" or "( )"),optionX,filterY)
  else
    love.graphics.draw((self.filter == "throwable" and images.uicheckboxchecked or images.uicheckbox),optionX,filterY)
  end
  love.graphics.print("Throwable",optionX+boxpadding,filterY)
  self.filterButtons[#self.filterButtons+1] = {filter="throwable",minX = optionX, maxX = optionX+boxpadding+optionW,minY=filterY-4,maxY=filterY+fontSize+10}
  --Equippable Items Option:
  optionX = padding+xAdd*3
  optionW = fonts.textFont:getWidth("Equippable")
  if (self.cursorY == 0 and self.cursorX == 4) or (mouseY < filterY+fontSize+10 and mouseY > filterY-4 and mouseX > optionX-4 and mouseX < optionX+boxpadding+optionW+10) then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",optionX-4,filterY-4,boxpadding+optionW+10,fontSize+10)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((self.filter == "equippable" and "(X)" or "( )"),optionX,filterY)
  else
    love.graphics.draw((self.filter == "equippable" and images.uicheckboxchecked or images.uicheckbox),optionX,filterY)
  end
  love.graphics.print("Equipment",optionX+boxpadding,filterY)
  self.filterButtons[#self.filterButtons+1] = {filter="equippable",minX = optionX, maxX = optionX+boxpadding+optionW,minY=filterY-4,maxY=filterY+fontSize+10}
  love.graphics.line(padding,filterY+fontSize+14,sidebarX-padding,filterY+fontSize+14)

  love.graphics.push()
  local function stencilFunc()
    local startY = self.inventory[1] and self.inventory[1].y or 1
    love.graphics.rectangle("fill",0,startY,width,height-startY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scroll)
	for i, line in ipairs(self.inventory) do
    local printY = line.y
    if line.item == self.selectedItem then
      setColor(100,100,100,255)
      love.graphics.rectangle("fill",printX-8,printY,sidebarX-printX-padding,fontSize+4)
      setColor(255,255,255,255)
    elseif line.item and ((self.cursorY == i and self.cursorX == 1) or (mouseX > printX and mouseX < sidebarX and mouseY+self.scroll > printY and mouseY+self.scroll < printY+fontSize)) then
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
    local endY = self.biggestY-self.inventory[1].y
    local scrollAmt = self.scroll/endY
    self.scrollPositions = output:scrollbar(sidebarX-padX*2,self.inventory[1].y,math.floor(height/uiScale)-(prefs['noImages'] and 24 or 16),scrollAmt,true)
  end
  
  --Draw equipment info:
  local equipCutoff=250
  local equipPrintY = padding
  local equipPrintX = sidebarX+padX
  local doneEquips = {}
  for i,equip in ipairs(self.equipment) do
    local slotWidth = fonts.textFont:getWidth(equip.slotName .. ":")
    if not doneEquips[equip.slotName] then
      love.graphics.print(equip.slotName .. ":",equipPrintX,equip.y)
      doneEquips[equip.slotName] = true
    end
    if equip.item == self.selectedItem then
      setColor(100,100,100,255)
      love.graphics.rectangle("fill",equipPrintX+slotWidth+3,equip.y,width-equipPrintX-padding,16)
      setColor(255,255,255,255)
    elseif (self.cursorY == i and self.cursorX == 2) or (equip.item and mouseX > equipPrintX+3 and mouseX < width-padding and mouseY > equip.y and mouseY < equip.y+16) then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",equipPrintX+slotWidth+3,equip.y,width-equipPrintX-padding,16)
      setColor(255,255,255,255)
    end
    love.graphics.print((equip.item and equip.item:get_name(true) or ""),equipPrintX+slotWidth+3,equip.y)
  end
  
  love.graphics.line(sidebarX,equipCutoff,width,equipCutoff)
  
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
    if self.text then
      love.graphics.printf(self.text,sidebarX+padX,buttonY-30,width-sidebarX-padding,"center")
    end
    if item ~= self.selectedItem then setColor(100,100,100,255) end
    if item.usable==true then
      local useText = (item.useVerb and ucfirst(item.useVerb) or "Use") .. " (" .. keybindings.use .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      self.buttons.use = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and "hover" or nil),useText)
      self.buttons.xValues[buttonCursorX] = "use"
      --love.graphics.printf(useText,buttonX,buttonY,buttonWidth,"center")
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.throwable==true then
      local useText = "Throw (" .. keybindings.throw .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      self.buttons.throw = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and "hover" or nil),useText)
      self.buttons.xValues[buttonCursorX] = "throw"
      --love.graphics.printf(useText,buttonX,buttonY,buttonWidth,"center")
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true then
      local equipped = player:is_equipped(item)
      local useText = (equipped and "Unequip" or "Equip") .. " (" .. keybindings.equip .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      self.buttons.equip = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and "hover" or nil),useText)
      self.buttons.xValues[buttonCursorX] = "equip"
      --love.graphics.printf(useText,buttonX,buttonY,buttonWidth,"center")
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    local dropText = "Drop (" .. keybindings.drop .. ")"
    local buttonWidth = fonts.buttonFont:getWidth(dropText)+25
    self.buttons.drop = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and "hover" or nil),dropText)
    self.buttons.xValues[buttonCursorX] = "drop"
    self.maxButtonCursorX = buttonCursorX
    if item ~= self.selectedItem then setColor(255,255,255,255) end
  end
  self.closebutton = output:closebutton(14,14,nil,true)
  love.graphics.pop()
end

function inventory:keypressed(key)
	if (key == "escape") then
    if self.selectedItem then
      self.selectedItem = nil
      self.cursorX = self.xHold
    else
      self:switchBack()
    end
	elseif (key == "return") or key == "kpenter" then
    if self.cursorY == 0 then --sorting buttons
      if self.filterButtons[self.cursorX] then
        self.filter = self.filterButtons[self.cursorX].filter
        self:sort()
      end
    else
      if self.cursorX == 1 then --selecting an item from the list
        if self.inventory[self.cursorY] and self.inventory[self.cursorY].item then
          self.selectedItem = self.inventory[self.cursorY].item
          self.xHold = self.cursorX
          self.cursorX = 3
        end --end item exists if
      elseif self.cursorX == 2 then --selecting an item from the equipped list
        if self.equipment[self.cursorY].item then
          self.selectedItem = self.equipment[self.cursorY].item
          self.xHold = self.cursorX
          self.cursorX = 3
        end
      else --buttons for manipulating items
        if self.buttons.xValues[self.cursorX] == "use" then
          self:useItem()
         elseif self.buttons.xValues[self.cursorX] == "equip" then
          self:equipItem()
        elseif self.buttons.xValues[self.cursorX] == "drop" then
          self:dropItem()
        elseif self.buttons.xValues[self.cursorX] == "throw" then
          self:throwItem()
        end
      end --end cursorX == 1 if
    end --end cursorY == 0 if
	elseif (key == "up") and not self.selectedItem then
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
	elseif (key == "down") and not self.selectedItem then
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
  elseif key == "left" then
    if self.cursorY == 0 then
      if self.cursorX > 1 then
        self.cursorX = self.cursorX-1
      end
    elseif self.cursorX == 2 then
      self.cursorX = 1
      self.cursorY,self.yHold = (self.yHold or 1),self.cursorY
    elseif self.cursorX > 3 then self.cursorX = self.cursorX-1 end
  elseif key == "right" then
    if self.cursorY == 0 then
      if self.cursorX < #self.filterButtons then
        self.cursorX = self.cursorX+1
      end
    elseif self.cursorX == 1 then
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
  elseif self.selectedItem then --only look at item buttons if you've selected an item
    if key == keybindings.use then
      self:useItem()
    elseif key == keybindings.equip then
      self:equipItem()
    elseif key == keybindings.drop then
      self:dropItem()
    elseif key == keybindings.throw then
      self:throwItem()
    end
	else
		local id = string.byte(key)-96
		if (player.inventory[id] ~= nil) then
      self.selectedItem = player.inventory[id]
      self.cursorY = id
		end
	end
end

function inventory:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then
    self:switchBack()
  end
  --Item use buttons:
  if self.buttons.use and x/uiScale > self.buttons.use.minX and x/uiScale < self.buttons.use.maxX and y/uiScale > self.buttons.use.minY and y/uiScale < self.buttons.use.maxY then
    return self:useItem()
  elseif self.buttons.equip and self.selectedItem and x/uiScale > self.buttons.equip.minX and x/uiScale < self.buttons.equip.maxX and y/uiScale > self.buttons.equip.minY and y/uiScale < self.buttons.equip.maxY then
    return self:equipItem()
  elseif self.buttons.drop and self.selectedItem and x/uiScale > self.buttons.drop.minX and x/uiScale < self.buttons.drop.maxX and y/uiScale > self.buttons.drop.minY and y/uiScale < self.buttons.drop.maxY then
    return self:dropItem()
  elseif self.buttons.throw and self.selectedItem and x/uiScale > self.buttons.throw.minX and x/uiScale < self.buttons.throw.maxX and y/uiScale > self.buttons.throw.minY and y/uiScale < self.buttons.throw.maxY then
    return self:throwItem()
  end
  
  --Filter buttons:
  if self.filterButtons[1] and y/uiScale > self.filterButtons[1].minY and y/uiScale < self.filterButtons[1].maxY then
    for _,b in ipairs(self.filterButtons) do
      if x/uiScale > b.minX and x/uiScale < b.maxX then
        self.filter = b.filter
        self:sort()
        return
      end
    end --end filter for
  end --end filter y
  
  --Selecting an item by clicking on it:
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local padding = (prefs['noImages'] and 16 or 32)
  local sidebarX = round(width/2)+padding
  local equipPrintX = sidebarX+self.padX
  local fontSize = prefs['fontSize']
  
  if x > padding and x < sidebarX then
    for i,item in ipairs(self.inventory) do
      if item.item and y+self.scroll > item.y and y+self.scroll < item.y+fontSize then
        self.selectedItem = item.item
        self.xHold = 1
        self.cursorX = 3
        self.cursorY = i
        return
      end
    end --end inventory for
  elseif x > equipPrintX and x < width-padding then
    for i,item in ipairs(self.equipment) do
      if item.item and y > item.y and y < item.y+fontSize then
        self.selectedItem = item.item
        self.xHold = 2
        self.cursorX = 3
        self.cursorY = i
        return
      end
    end --end inventory for
  end
end

function inventory:useItem()
  local item = self.selectedItem
  if item then
    local use,response = item:use(nil,player)
    if use ~= false then
      self:switchBack()
      if action ~= "targeting" then advance_turn() end
    elseif (item.target_type == "creature" or item.target_type == "square") and (not item.charges or item.charges > 0) then
      item:target()
      self:switchBack()
    else
      self.text=response
    end
  end
end

function inventory:equipItem()
  local item = self.selectedItem
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

function inventory:dropItem()
  player:drop_item(self.selectedItem)
  self.selectedItem = nil
  self:sort()
  advance_turn()
end

function inventory:throwItem()
  if self.selectedItem and self.selectedItem.throwable then
    action="targeting"
    actionResult=rangedAttacks[self.selectedItem.ranged_attack]
    actionItem=self.selectedItem
    self:switchBack()
  end
end

function inventory:wheelmoved(x,y)
  if y > 0 then
    self.scroll = math.max(self.scroll - prefs['fontSize'],0)
	elseif y < 0 then
    self.scroll = self.scroll or 0
    self.scroll = math.min(self.scroll + prefs['fontSize'],(self.biggestY-self.inventory[1].y))
  end
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
end

function inventory:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end