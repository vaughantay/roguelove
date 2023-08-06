inventory = {}
--TODO: Scrolling for equipment
--TODO: Test for non-player inventory

function inventory:enter(previous,whichFilter,action,entity)
  if previous == game then
    self.cursorY = 0
    self.cursorX = 1
    self.scroll=0
    self.scrollMax=0
    self.yHold = 1
    self.xHold = 1
    self.text = nil
    self.filterScroll=0
    self.filterScrollMax=0
    self.filter = nil
    self.filterButtons = nil
    self.action = nil
    self.entity = entity or player
  end
  self.inventory_space = (self.entity.inventory_space and self.entity:get_stat('inventory_space') or false)
  self.free_space = self.entity:get_free_inventory_space()
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
  self.padding = (prefs['noImages'] and 16 or 32)
  self.padX,self.padY = padX,padY
  self.yModPerc = 0
  if previous == game then
    self.yModPerc = 100
    tween(0.2,self,{yModPerc=0})
    output:sound('stoneslideshort',2)
  end
  self.buttons = {}
  self.filter = (whichFilter and whichFilter) or self.filter
  self.sidebarX = round(width/2)+(prefs['noImages'] and 16 or 32)
  self:sort()
end

function inventory:sort()
  local tileSize = output:get_tile_size(true)
  local fontSize = prefs['fontSize']
  --First, sort by type:
  local sorted = {}
  for i,item in ipairs(self.entity.inventory) do
    if not self.entity:is_equipped(item) then
      local filter_info = self.filter
      if (filter_info == nil) or ((not filter_info.filter or item[filter_info.filter] == true) and (not filter_info.itemType or item.itemType == filter_info.itemType) and (not filter_info.subType or item.subType == filter_info.subType)) then
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
  local numberPad = fonts.textFont:getWidth("999)")
  local lineSize = math.max(fontSize,tileSize)
  for _,iType in ipairs(sorted) do
    for i,item in ipairs(iType) do
      if i == 1 then
        self.inventory[#self.inventory+1] = {item=false,y=itemPrintY,text=ucfirst(iType.text),header=true,maxY=itemPrintY+lineSize,height=lineSize,lineHeight=lineSize}
        itemPrintY = itemPrintY+lineSize
      end
      local name = item:get_name(true,nil,true)
      local _,nlines = fonts.textFont:getWrap(name,self.sidebarX-self.padding*2-numberPad-tileSize)
      local size = (self.inventory_space and math.max(item.size or 1,1) or 1)
      local lineHeight = math.max(tileSize,round(fontSize*(#nlines+0.5))+2)
      local height = lineHeight*size+(2*size)
      local maxY = itemPrintY+height
      self.inventory[#self.inventory+1] = {item=item,y=itemPrintY,text=name,maxY=maxY,height=height,lineHeight=lineHeight,nlines=#nlines}
      itemPrintY = maxY+2
    end --end 
  end --end item type sorting
  if self.filter == nil or self.filter.id == "all" then
    if self.free_space and self.free_space > 0 then
      self.inventory[#self.inventory+1] = {item=false,y=itemPrintY,text="Free Space (" .. self.free_space .. ")",header=true,maxY=itemPrintY+lineSize,height=lineSize,lineHeight=lineSize}
      itemPrintY = itemPrintY+lineSize
      for i=1,self.free_space,1 do
        local maxY = itemPrintY+lineSize
        self.inventory[#self.inventory+1] = {item=false,y=itemPrintY,text="-",empty=true,maxY=maxY,height=lineSize,lineHeight=lineSize}
        itemPrintY = maxY+2
      end
    end
  end
  
  local equipOrder = gamesettings.default_equipment_order
  self.equipment = {}
  local equipPrintY = (prefs['noImages'] and 16 or 32)
  local equipSlotWidth = 0
  for _,s in ipairs(equipOrder) do
    local slot = self.entity.equipment[s]
    equipSlotWidth = math.max(equipSlotWidth,fonts.textFont:getWidth((slot.name or ucfirst(s)) .. ":"))
    if slot then
      local usedSlots = 0
      for id,equip in ipairs(slot) do
        local slots = 1
        local equipSize = (equip.equipSize or 1)
        if equipSize > 0 then
          slots = equipSize
          usedSlots = usedSlots+equipSize
        end
        local maxY = equipPrintY+(lineSize*slots)
        self.equipment[#self.equipment+1] = {item=equip,y=equipPrintY,slotName=(slot.name or ucfirst(s)),slotID=s,maxY=maxY}
        equipPrintY = maxY
      end --end equip for
      if slot.slots > usedSlots then
        for i=(usedSlots+1),slot.slots,1 do
          local maxY = equipPrintY+lineSize
          self.equipment[#self.equipment+1] = {item=false,y=equipPrintY,slotName=(slot.name or ucfirst(s)),text="-",empty=true,slotID=s,maxY=maxY}
          equipPrintY=maxY
        end --end empty slot for
      end --end if empty slots
    end
  end --end equiporder for

  --Do extra slots that are not part of the standard equipment order:
  for slot,eq in pairs(self.entity.equipment) do
    if not in_table(slot,equipOrder) and slot ~= "list" then
      equipSlotWidth = math.max(equipSlotWidth,fonts.textFont:getWidth((self.entity.equipment[slot].name or ucfirst(slot)) .. ":"))
      for id,equip in ipairs(eq) do
        self.equipment[#self.equipment+1] = {item=equip,y=equipPrintY,slotName=(self.entity.equipment[slot].name or ucfirst(slot)),slotID=slot}
        equipPrintY=equipPrintY+lineSize
      end --end equip for
      for i=#slot,slot.slots,1 do
        self.equipment[#self.equipment+1] = {item=false,y=equipPrintY,slotName=(self.entity.equipment[slot].name or ucfirst(slot)),text="-",empty=true,slotID=slot}
        equipPrintY=equipPrintY+lineSize
      end
    end --end slot for
  end --end if not in_table slot,equiporder
  self.equipSlotWidth = equipSlotWidth
  self.inventory_space = (self.entity.inventory_space and self.entity:get_stat('inventory_space') or false)
  self.free_space = self.entity:get_free_inventory_space()
end --end inventory:sort()

function inventory:draw()
  local uiScale = (prefs['uiScale'] or 1)
  local fontSize = prefs['fontSize']
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
  local tileSize = output:get_tile_size(true)
	
  self.screenMax = round(height/(fontSize+2)/2)
  local padding = self.padding
	love.graphics.setFont(fonts.textFont)
  local sidebarX = self.sidebarX
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  local topText = "Inventory"
  if self.action == "use" then topText = "Select items to use"
  elseif self.action == "drop" then topText = "Select items to drop"
  elseif self.action == "throw" then topText = "Select items to throw"
  elseif self.action == "equip" then topText = "Select items to equip" end

  local spaceText = ""
  if self.inventory_space then
    spaceText = "\nUsed Space: " .. (self.inventory_space-self.free_space) .. " / " .. self.inventory_space
    if self.free_space < 0 then spaceText = spaceText .. " (Overloaded!)" end
  end
  topText = topText .. (self.entity == player and "\nYou have: " or "\n" .. self.entity:get_name() " has: ") .. get_money_name(self.entity.money) .. spaceText
  love.graphics.printf(topText,padding,round(padding*.75),sidebarX-padding*2,"center")
  local _,ttlines = fonts.textFont:getWrap(topText, sidebarX-padding*2)
    
  local printX = (prefs['noImages'] and 14 or 32)
  local printY = (#ttlines+3)*fontSize
  
  if self.text then
    love.graphics.printf(self.text,padding,printY,sidebarX-padding*2,"center")
    local _,olines = fonts.textFont:getWrap(self.text, sidebarX-padding*2)
    printY=printY+(#olines+1)*fontSize
  end
  printY=printY+8
  
  --Filter buttons:
  local boxpadding = (prefs['noImages'] and fontSize or 32)
  local maxFilterX = sidebarX-padding
  if not self.filterButtons then
    self.filterButtons = {}
    --All Items Option:
    local optionX = padding
    local optionW = fonts.textFont:getWidth("All Items")
    self.filterButtons[#self.filterButtons+1] = {filter=nil,label="All Items", id = "all", minX = optionX, maxX = optionX+boxpadding+optionW,minY=printY-4,maxY=printY+fontSize+10}
    --Calculate location of all filter buttons:
    for _,filter_info in pairs(gamesettings.inventory_filters) do
      local filter = filter_info.filter
      local itemType = filter_info.itemType
      local subType = filter_info.subType
      local label = ucfirst(filter_info.label or filter_info.itemType or filter_info.filter)
      local fid = (filter or "") .. (itemType or "") .. (subType or "")
      local previous = self.filterButtons[#self.filterButtons]
      optionX = previous.maxX+boxpadding
      optionW = fonts.textFont:getWidth(label)
      self.filterButtons[#self.filterButtons+1] = {filter=filter, itemType=itemType, subType = subType, label=label, id = fid, minX = optionX, maxX = optionX+boxpadding+optionW,minY=printY-4,maxY=printY+fontSize+10}
      if self.filter and ((not self.filter.id or self.filter.id == filter_info.id) and ((self.filter.filter == filter_info.filter) and (self.filter.itemType == filter_info.itemType) and (self.filter.subType == filter_info.subType))) then
        self:scrollToFilter(self.filterButtons[#self.filterButtons])
        self.cursorX = #self.filterButtons
        self.filter = self.filterButtons[#self.filterButtons]
      end
    end --end for
  end --end if filters haven't been made yet
  if not self.filter then self.filter = self.filterButtons[1] end
  --Draw the filter buttons:
  love.graphics.push()
  local function filterStencil()
    love.graphics.rectangle("fill",padding,printY-4,maxFilterX-padding,fontSize+10)
  end
  love.graphics.stencil(filterStencil,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(self.filterScroll,0)
  for id,filter in ipairs(self.filterButtons) do
    local minX,maxX = filter.minX,filter.maxX
    if (self.cursorY == 0 and self.cursorX == id) or (Gamestate.current() == inventory and mouseY < printY+fontSize+10 and mouseY > printY-4 and mouseX-self.filterScroll > minX-4 and mouseX-self.filterScroll < maxX and mouseX > padding and mouseX < maxFilterX) then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",minX-4,printY-4,maxX+10-minX,fontSize+10)
      setColor(255,255,255,255)
    end
    if prefs['noImages'] then
      love.graphics.print((self.filter and self.filter.id == filter.id and "(X)" or "( )"),minX,printY)
    else
      love.graphics.draw((self.filter and self.filter.id == filter.id and images.uicheckboxchecked or images.uicheckbox),minX,printY)
    end
    love.graphics.print(filter.label,minX+boxpadding,printY)
  end
  self.maxFilterScroll = maxFilterX-self.filterButtons[#self.filterButtons].maxX-6
  love.graphics.setStencilTest()
  love.graphics.pop()
  local w = fonts.textFont:getWidth('>')
  local leftArrowX = round(padding/2)-4
  if mouseX > leftArrowX and mouseX < leftArrowX+w and mouseY > printY and mouseY < printY+fontSize then
    setColor(100,100,100,125)
    love.graphics.rectangle('fill',leftArrowX,printY,w,fontSize+4)
    setColor(255,255,255,255)
  end
  if self.filterScroll == 0 then
    setColor(100,100,100,255)
  end
  love.graphics.print("<",leftArrowX,printY)
  if self.filterScroll == 0 then
    setColor(255,255,255,255)
  end
  local rightArrowX = round(sidebarX-padding+4)
  if mouseX > rightArrowX and mouseX < rightArrowX+w and mouseY > printY and mouseY < printY+fontSize then
    setColor(100,100,100,125)
    love.graphics.rectangle('fill',rightArrowX,printY,w,fontSize+4)
    setColor(255,255,255,255)
  end
  if self.filterScroll == self.maxFilterScroll then
    setColor(100,100,100,255)
  end
  love.graphics.print(">",rightArrowX,printY)
  if self.filterScroll == self.maxFilterScroll then
    setColor(255,255,255,255)
  end
  
  --Item list:
  fontSize = math.max(prefs['fontSize'],tileSize)
  love.graphics.line(padding,printY+fontSize,sidebarX-padding,printY+fontSize)
  printY = printY+fontSize+14
  self.itemStartY = printY
  love.graphics.push()
  local function stencilFunc()
    love.graphics.rectangle("fill",0,self.itemStartY,width,height-self.itemStartY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scroll)
  local slotCount = 0
	for i, line in ipairs(self.inventory) do
    local printY = self.itemStartY+line.y
    local slots = (line.item and math.max(1,(line.item.size or 1)) or 1)
    local itemHeight=line.height
    local lineHeight = line.lineHeight
    local numberText = ""
    local numberPad = 0
    if (line.item or line.empty) and not line.header and (self.filter == nil or self.filter.id == 'all') and self.inventory_space then
      if not line.item or not line.item.size or line.item.size > 0 then
        slotCount = slotCount + 1
        numberText = slotCount .. ") "
      else
        numberText = "-)"
      end
      numberPad = fonts.textFont:getWidth("999)")
    end
    --[[if line.item == self.selectedItem then
      setColor(100,100,100,255)
      love.graphics.rectangle("fill",printX-8,printY,sidebarX-printX-padding,fontSize+4)
      setColor(255,255,255,255)
    else]]
    if ((self.cursorY == i and self.cursorX == 1) or (Gamestate.current() == inventory and mouseX > printX and mouseX < sidebarX and mouseY+self.scroll > printY and mouseY+self.scroll < printY+itemHeight)) and not line.header then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",printX-8,printY,sidebarX-printX-padding+8,itemHeight)
      setColor(255,255,255,255)
    end
    if line.header == true then
     love.graphics.printf(line.text,printX,printY+5,sidebarX-padding,"center")
    else
      love.graphics.print(numberText,printX,printY)
      if line.item then output.display_entity(line.item,printX+numberPad,printY-2,true,true) end
      if line.empty then setColor(150,150,150,255) end
      love.graphics.printf(line.text,printX+tileSize+numberPad,printY,sidebarX-padding*2-numberPad-tileSize)
    end
    if slots > 1 and self.inventory_space then
      for i=2,slots,1 do
        slotCount = slotCount+1
        setColor(150,150,150,255)
        love.graphics.print(slotCount .. ") ",printX,printY+lineHeight*(i-1)+2)
        love.graphics.printf(line.text,printX+tileSize+numberPad,printY+lineHeight*(i-1)+2,sidebarX-padding*2-numberPad-tileSize)
      end
    end
    setColor(255,255,255,255)
    self.biggestY = printY+itemHeight
	end
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  if self.biggestY > height then
    self.scrollMax = self.biggestY-(height-padding*2)
    local scrollAmt = self.scroll/self.scrollMax
    self.scrollPositions = output:scrollbar(sidebarX-padX*2,self.itemStartY,math.floor(height)-(prefs['noImages'] and 24 or 16),scrollAmt,true)
  end
  
  --Draw equipment info:
  local equipCutoff=height-padding
  local equipPrintY = padding
  local equipPrintX = sidebarX+padX
  local doneEquips = {}
  local slotWidth = self.equipSlotWidth
  for i,equip in ipairs(self.equipment) do
    if not doneEquips[equip.slotName] then
      love.graphics.print(equip.slotName .. ":",equipPrintX,equip.y)
      doneEquips[equip.slotName] = true
    end
    local equipH = equip.maxY-equip.y
    --[[if equip.item == self.selectedItem then
      setColor(100,100,100,255)
      love.graphics.rectangle("fill",equipPrintX+slotWidth+3,equip.y,width-equipPrintX-padding,16)
      setColor(255,255,255,255)
    else]]
    if (self.cursorY == i and self.cursorX == 2) or (Gamestate.current() == inventory and mouseX > equipPrintX+3 and mouseX < width-padding and mouseY > equip.y and mouseY < equip.maxY) then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",equipPrintX+slotWidth,equip.y,width-equipPrintX-padding,equipH)
      setColor(255,255,255,255)
    end
    if equip.item then output.display_entity(equip.item,equipPrintX+slotWidth,equip.y-4,true,true) end
    if equip.empty then setColor(150,150,150,255) end
    love.graphics.print((equip.item and equip.item:get_name(true,nil,true) or equip.text or ""),equipPrintX+slotWidth+tileSize,equip.y+2)
    local slots = (equip.item and equip.item.equipSize and math.max(1,equip.item.equipSize) or 1)
    if slots > 1 then
      for i=2,slots,1 do
        setColor(150,150,150,255)
        love.graphics.print(equip.item:get_name(true,nil,true),equipPrintX+slotWidth+tileSize,equip.y+2+fontSize*(i-1))
      end
    end
    setColor(255,255,255,255)
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
      local equipped = self.entity:is_equipped(item)
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

function inventory:buttonpressed(key)
  local uiScale = prefs['uiScale']
  local letter = key
  key = input:parse_key(key)
  local padding = self.padding
	if (key == "escape") then
    self:switchBack()
	elseif (key == "enter") or key == "wait" then
    if self.cursorY == 0 then --sorting buttons
      if self.filterButtons[self.cursorX] then
        self.filter = self.filterButtons[self.cursorX]
        self:sort()
        if self.action and self.action ~= "drop" then self.action = nil end
      end
    else
      if self.cursorX == 1 then --selecting an item from the list
        if self.inventory[self.cursorY] and self.inventory[self.cursorY].item then
          --self.selectedItem = self.inventory[self.cursorY].item
          --self.xHold = self.cursorX
          --self.cursorX = 3
          if self.action == "drop" then
            return self:dropItem(self.inventory[self.cursorY].item)
          elseif self.action == "equip" then
            return self:equipItem(self.inventory[self.cursorY].item)
          elseif self.action == "use" then
            return self:useItem(self.inventory[self.cursorY].item)
          elseif self.action == "throw" then
            return self:throwItem(self.inventory[self.cursorY].item)
          else
            Gamestate.switch(examine_item,self.inventory[self.cursorY].item)
          end
        end --end item exists if
      elseif self.cursorX == 2 then --selecting an item from the equipped list
        if self.equipment[self.cursorY].item then
          Gamestate.switch(examine_item,self.equipment[self.cursorY].item)
          --[[self.selectedItem = self.equipment[self.cursorY].item
          self.xHold = self.cursorX
          self.cursorX = 3]]
        else --selecting an empty slot
          self.filter = {filter="equippable",itemType=self.equipment[self.cursorY].slotID,appliedFromEquipment=true} --Filter for items that fit in this slot
          self:sort()
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
			if self.inventory[self.cursorY-1] and not self.inventory[self.cursorY-1].header then
        self.cursorY = self.cursorY-1
      else
        for i = self.cursorY-1,1,-1 do
          if self.inventory[i] and not self.inventory[i].header then
            self.cursorY = i
            break
          elseif i == 1 then
            self.cursorY = 0
          end --end if item exists here if
        end --end equipment for
      end --end if item exists at next slot if
      while self.inventory[self.cursorY] and self.inventory[self.cursorY].y+self.itemStartY-self.scroll < self.itemStartY and self.scroll > 0 do
        self:scrollUp()
      end
    elseif self.cursorX == 2 and self.cursorY > 1 then
      if self.equipment[self.cursorY-1] and self.equipment[self.cursorY-1].item then
        self.cursorY = self.cursorY-1
      else
        for i = self.cursorY-1,1,-1 do
          if self.equipment[i] then
            self.cursorY = i
            break
          end --end if slot exists here if
        end --end equipment for
      end --end if item exists at next slot if
		end
	elseif (key == "south") and not self.selectedItem then
    if self.cursorY == 0 then
      self.cursorX = 1
    end
		if self.cursorX == 1 and (self.inventory[self.cursorY+1] ~= nil) then
			if not self.inventory[self.cursorY+1].header then
        self.cursorY = self.cursorY+1
      else
        for i = self.cursorY+1,#self.inventory,1 do
          if not self.inventory[i].header then
            self.cursorY = i
            break
          end --end if item exists here if
        end --end equipment for
      end --endif item exists and next slot if
      while self.inventory[self.cursorY].y+self.itemStartY+prefs['fontSize']-self.scroll >= round(love.graphics.getHeight()/uiScale)-32 and self.scroll < self.scrollMax do
        self:scrollDown()
      end
    elseif self.cursorX == 2 and self.cursorY < #self.equipment then
      if self.equipment[self.cursorY+1] then
        self.cursorY = self.cursorY+1
      end --end next slot exists if
		end --end which cursorX if
  elseif key == "west" then
    if self.cursorY == 0 then
      if self.cursorX > 1 then
        self.cursorX = self.cursorX-1
        self:scrollToFilter(self.filterButtons[self.cursorX])
      end
    elseif self.cursorX == 2 then
      self.cursorX = (self.yHold == 0 and #self.filterButtons or 1)
      self.cursorY,self.yHold = (self.yHold or 1),self.cursorY
    elseif self.cursorX > 3 then self.cursorX = self.cursorX-1 end
  elseif key == "east" then
    if self.cursorY == 0 and self.cursorX < #self.filterButtons then
      self.cursorX = self.cursorX+1
      self:scrollToFilter(self.filterButtons[self.cursorX])
    elseif self.cursorY == 0 or self.cursorX == 1 then
      self.cursorX = 2
      self.cursorY,self.yHold = self.yHold,self.cursorY
      if not self.equipment[self.cursorY] or not self.equipment[self.cursorY] then
        local done = false
        for i=1,#self.equipment,1 do
          if self.equipment[i] then
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
  elseif self. cursorX == 1 and self.inventory[self.cursorY] and self.inventory[self.cursorY].item then
    if key == "use" then
      self:useItem(self.inventory[self.cursorY].item)
    elseif key == "equip" then
      self:equipItem(self.inventory[self.cursorY].item)
    elseif key == "drop" then
      self:dropItem(self.inventory[self.cursorY].item)
    elseif key == "throw" then
      self:throwItem(self.inventory[self.cursorY].item)
  end
  
    
    --[[if self.action == "drop" then
            
          elseif self.action == "equip" then
            
          elseif self.action == "use" then
            
          elseif self.action == "throw" then
            
          end]]
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
  local padding = self.padding
  local maxFilterX = self.sidebarX-padding
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
    if x > padding/2-4 and x < padding then --left arrow
      local lastID = nil,nil
      for id,b in ipairs(self.filterButtons) do
        if b.minX+self.filterScroll <= padding then
          lastID = id
        else
          break
        end
      end -- end filterbutton for
      if lastID and lastID > 1 then
        self:scrollToFilter(self.filterButtons[lastID-1])
      end
    elseif x > self.sidebarX-padding+4 and x < self.sidebarX then -- right arrow
      for id,b in ipairs(self.filterButtons) do
        if b.maxX+self.filterScroll > maxFilterX then
          self:scrollToFilter(b)
          break
        end
      end --end filterbutton for
    end --end left/right arrow if
    for id,b in ipairs(self.filterButtons) do
      if x > b.minX+self.filterScroll and x < b.maxX+self.filterScroll and x > padding and x < self.sidebarX - padding then
        self.filter = b
        if self.cursorY == 0 then self.cursorX = id end
        self:scrollToFilter(b)
        self:sort()
        return
      end
    end --end filter for
  end --end filter y
  
  --Selecting an item by clicking on it:
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  width,height=round(width/uiScale),round(height/uiScale)
  local sidebarX = self.sidebarX
  local equipPrintX = sidebarX+self.padX
  local tileSize = output:get_tile_size(true)
  local fontSize = math.max(prefs['fontSize'],tileSize)
  
  if x > padding and x < sidebarX-(self.scrollPositions and padding or 0) then
    for i,item in ipairs(self.inventory) do
      if (item.item or item.empty) and not item.header and y+self.scroll > item.y+self.itemStartY and y+self.scroll < self.itemStartY+item.maxY then
        self.cursorY = i
        self.cursorX = 1
        if item.item then
          if self.action == "drop" then
            return self:dropItem(item.item)
          elseif self.action == "equip" then
            return self:equipItem(item.item)
          elseif self.action == "use" then
            return self:useItem(item.item)
          elseif self.action == "throw" then
            return self:throwItem(item.item)
          else
            Gamestate.switch(examine_item,item.item)
          end
          return
        end
      end
    end --end inventory for
  elseif x > equipPrintX and x < width-padding then
    for i,item in ipairs(self.equipment) do
      if y > item.y and y < item.maxY then
        self.cursorY = i
        self.cursorX = 2
        if item.item then
          Gamestate.switch(examine_item,item.item)
        else
          self.filter = {filter="equippable",itemType=item.slotID,appliedFromEquipment=true} --Filter for items that fit in this slot
          self:sort()
        end
        return
      end
    end --end inventory for
  end
end

function inventory:useItem(item)
  item = item or self.selectedItem
  if item then
    local canUse,text = self.entity:can_use_item(item,item.useVerb)
    if canUse then
      if item.target_type == "self" or not item.target_type then --if a self-targeting item, then just use it and be done
        local used,response = item:use(nil,self.entity)
        self.text=response
        if used ~= false then
          self:switchBack()
          if action ~= "targeting" then advance_turn() end
        end
      elseif (item.target_type == "creature" or item.target_type == "tile") and (not item.charges or item.charges > 0) then --if not self-use, target
        item:target(self.entity.target,self.entity)
        self:switchBack()
      end
    else --if canUse == false
      output:out(text)
      self.text=text
    end
  end
end

function inventory:equipItem(item)
  item = item or self.selectedItem
  if item then
    if self.entity:is_equipped(item) then
      local use,response = self.entity:unequip(item)
      self.text=response
    else
      local use,response = self.entity:equip(item)
      self.text=response
      if use ~= false then advance_turn() end
    end --end if it's equipped or not
    self:sort()
  end --end if item exists
end

function inventory:dropItem(item)
  item = item or self.selectedItem
  local drop,response = self.entity:drop_item(item)
  --self.selectedItem = nil
  if drop ~= false then
    self.cursorX=1
    self:sort()
    if self.cursorY > #self.inventory then
      self.cursorY = #self.inventory
    end
    self.text = "You drop " .. item:get_name() .. "."
    advance_turn()
    self:sort()
  end
end

function inventory:throwItem(item)
  item = item or self.selectedItem
  if item and item.throwable then
    item:target(self.entity.target,self.entity)
    self:switchBack()
  end
end

function inventory:reloadItem(item)
  item = item or self.selectedItem
  if item and item.charges and (not item.max_charges or item.max_charges > 0) then
    local recharge,text = item:reload(self.entity)
    self.text = text
    if recharge ~= false then
      advance_turn()
      self:sort()
    end
  end
end

function inventory:splitStack(item,amount)
  item = item or self.selectedItem
  if item and item.stacks and amount > 0 and amount < item.amount then
    local oldOwner = item.owner
    item.owner = nil --This is done because item.owner is the creature who owns the item, and Item:clone() does a deep copy of all tables, which means it will create a copy of the owner, which owns a copy of the item, which is owned by another copy of the owner which owns another copy of the item etc etc leading to a crash
    local newItem = item:clone()
    item.amount = item.amount - amount
    newItem.amount = amount
    item.owner,newItem.owner = oldOwner
    newItem.stacks = false
    self.entity:give_item(newItem)
    newItem.stacks = true
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
  self.scroll = math.min(self.scroll + prefs['fontSize'],self.scrollMax)
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

function inventory:scrollToFilter(filter)
  local padding = self.padding
  local maxFilterX = self.sidebarX-padding
  if filter.maxX+self.filterScroll > maxFilterX then
    self.filterScroll = maxFilterX-filter.maxX-6
  elseif filter.minX+self.filterScroll < padding then
    self.filterScroll = padding-filter.minX
  end
end

function inventory:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end