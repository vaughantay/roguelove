inventory = {}
--TODO: Test for non-player inventory
--TODO: Pickup from containers from right-click menu

function inventory:enter(previous,whichFilter,action,entity,container)
  if previous == game or previous == multiselect or previous == loadout then
    self.cursorY = 0
    self.cursorX = 1
    self.scroll=0
    self.scrollMax=0
    self.sideScroll = 0
    self.sideScrollMax = 0
    self.yHold = 1
    self.xHold = 1
    self.text = nil
    self.filterScroll=0
    self.filterScrollMax=0
    self.filter = nil
    self.filterButtons = nil
    self.action = nil
    self.entity = entity or player
    self.container = container
    self.itemStartY = 0
    self.ignoreMouse = true
  end
  self.inventory_space = (self.entity.inventory_space and self.entity:get_stat('inventory_space') or false)
  self.free_space = self.entity:get_free_inventory_space()
  self.biggestY=0
  self.biggestSideY = 0
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
  if previous == game or previous == loadout then
    self.yModPerc = 100
    tween(0.2,self,{yModPerc=0})
    output:sound('stoneslideshort',2)
  end
  self.buttons = {}
  self.filter = (whichFilter and whichFilter) or self.filter
  self.sidebarX = round(width/2)+(prefs['noImages'] and 16 or 32)
  self.sidebarW = width-self.sidebarX
  self.previous = previous
  self:sort()
end

function inventory:sort()
  local tileSize = output:get_tile_size(true)
  local fontSize = fonts.textFont:getHeight()
  --First, sort by type:
  local sorted = {}
  for i,item in ipairs(self.entity.inventory) do
    if not self.entity:is_equipped(item) or (self.filter and self.filter.id and self.filter.id ~= "all") then
      local filter_info = self.filter
      if (filter_info == nil) or ((not filter_info.filter or item[filter_info.filter]) and (not filter_info.category or item.category == filter_info.category) and (not filter_info.equipSlot or filter_info.equipSlot == item.equipSlot) and (not filter_info.subcategory or item.subcategory == filter_info.subcategory)) then
        local matches = true
        if filter_info and filter_info.types then
          matches = false
          for _,itype in ipairs(filter_info.types) do
            if item:is_type(itype) then
              matches = true
              break
            end
          end
        end
        if matches then
          local iType = item.category or "other"
          local subcategory = item.subcategory or ""
          if not sorted[iType .. subcategory] then
            sorted[iType .. subcategory] = {text=iType .. (subcategory ~= "" and " (" .. ucfirst(subcategory) .. ")" or "")}
          end
          sorted[iType .. subcategory][#sorted[iType .. subcategory]+1] = item
        end
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
    local allItems = {}
    local freeSlotItems = {}
    for _,item in ipairs(iType) do
      if item.size == 0 then
        freeSlotItems[#freeSlotItems+1] = item
      else
        allItems[#allItems+1] = item
      end
    end
    for _,item in ipairs(freeSlotItems) do
      allItems[#allItems+1] = item
    end
    for i,item in ipairs(allItems) do
      if i == 1 then
        self.inventory[#self.inventory+1] = {item=false,y=itemPrintY,text=ucfirst(iType.text),header=true,maxY=itemPrintY+lineSize,height=lineSize,lineHeight=lineSize}
        itemPrintY = itemPrintY+lineSize
      end
      local name = item:get_name(true,nil,true)
      local _,nlines = fonts.textFont:getWrap(name,self.sidebarX-self.padding*2-numberPad-tileSize)
      local size = (self.inventory_space and math.max(item.size or 1,1) or 1)
      if item.equipped then size = 1 end
      local lineHeight = math.max(tileSize,round(fontSize*(#nlines+0.5))+2)
      local height = lineHeight*size+(2*size)
      local maxY = itemPrintY+height
      self.inventory[#self.inventory+1] = {item=item,y=itemPrintY,text=name .. (item.equipped and " (Equipped)" or ""),maxY=maxY,height=height,lineHeight=lineHeight,nlines=#nlines}
      itemPrintY = maxY
    end --end 
  end --end item type sorting
  if self.filter == nil or self.filter.id == "all" then
    if self.free_space and self.free_space > 0 then
      self.inventory[#self.inventory+1] = {item=false,y=itemPrintY,text="Free Space (" .. self.free_space .. ")",header=true,maxY=itemPrintY+lineSize,height=lineSize,lineHeight=lineSize}
      itemPrintY = itemPrintY+lineSize
      for i=1,self.free_space,1 do
        local maxY = itemPrintY+lineSize
        self.inventory[#self.inventory+1] = {item=false,y=itemPrintY,text="-",empty=true,maxY=maxY,height=lineSize,lineHeight=lineSize}
        itemPrintY = maxY
      end
    end
  end
  if self.container and self.container.inventory then
    local containerInv = self.container:get_inventory()
    self.inventory[#self.inventory+1] = {item=false,y=itemPrintY,text=self.container:get_name(true),header=true,maxY=itemPrintY+lineSize,height=lineSize,lineHeight=lineSize}
      itemPrintY = itemPrintY+lineSize
    for i,item in ipairs(containerInv) do
      local name = item:get_name(true,nil,true)
      local _,nlines = fonts.textFont:getWrap(name,self.sidebarX-self.padding*2-numberPad-tileSize)
      local size = (self.inventory_space and math.max(item.size or 1,1) or 1)
      local lineHeight = math.max(tileSize,round(fontSize*(#nlines+0.5))+2)
      local height = lineHeight*size+(2*size)
      local maxY = itemPrintY+height
      self.inventory[#self.inventory+1] = {item=item,y=itemPrintY,text=name,maxY=maxY,height=height,lineHeight=lineHeight,nlines=#nlines}
      itemPrintY = maxY
    end
  end
  
  local equipOrder = gamesettings.default_equipment_order
  self.equipment = {}
  local equipPrintY = (prefs['noImages'] and 16 or 32)
  local impressions = player:get_all_impressions()
  if count(impressions) > 0 then
    local impText = "Impressions from equipment: "
    local i = 1
    for _,imp in pairs(impressions) do
      impText = impText .. ucfirst(imp) .. (i < count(impressions) and ", " or "")
      i = i+1
    end
    local _,ilines = fonts.textFont:getWrap(impText,self.sidebarW)
    equipPrintY = equipPrintY + #ilines*fontSize
  end
  local equipSlotWidth = 0
  for _,s in ipairs(equipOrder) do
    local slot = self.entity.equipment[s]
    if slot then
      equipSlotWidth = math.max(equipSlotWidth,fonts.textFont:getWidth((slot.name or ucfirst(s)) .. ":"))
      local usedSlots = 0
      for id,equip in ipairs(slot) do
        local slots = 1
        local equipSize = (equip.equipSize or 1)
        if equipSize > 0 then
          slots = equipSize
          usedSlots = usedSlots+equipSize
        end
        local maxY = equipPrintY+(lineSize*slots)
        self.equipment[#self.equipment+1] = {item=equip,y=equipPrintY,slotName=(slot.name or ucfirst(s)),slotID=s,maxY=maxY,height=lineSize,lineHeight=lineSize}
        equipPrintY = maxY
      end --end equip for
      if slot.slots > usedSlots then
        for i=(usedSlots+1),slot.slots,1 do
          local maxY = equipPrintY+lineSize
          self.equipment[#self.equipment+1] = {item=false,y=equipPrintY,slotName=(slot.name or ucfirst(s)),text="-",empty=true,slotID=s,maxY=maxY,height=lineSize,lineHeight=lineSize}
          equipPrintY=maxY
        end --end empty slot for
      end --end if empty slots
    end
  end --end equiporder for

  --Do extra slots that are not part of the standard equipment order:
  for slot,eq in pairs(self.entity.equipment) do
    if not in_table(slot,equipOrder) then
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
  local fontSize = fonts.textFont:getHeight()
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
  local numberPad = fonts.textFont:getWidth("999)")
  local topText = "Inventory"
  if self.action == "use" then topText = "Select items to use"
  elseif self.action == "drop" then topText = "Select items to " .. (self.container and "place in " .. self.container:get_name(true) or "drop")
  elseif self.action == "throw" then topText = "Select items to throw"
  elseif self.action == "equip" then topText = "Select items to equip" end

  local spaceText = ""
  if self.inventory_space then
    spaceText = "\nUsed Space: " .. (self.inventory_space-self.free_space) .. " / " .. self.inventory_space
    if self.free_space < 0 then spaceText = spaceText .. " (Overloaded!)" end
  end
  topText = topText .. (self.entity == player and "\nYou have: " or "\n" .. self.entity:get_name() .. " has: ") .. get_money_name(self.entity.money) .. spaceText
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
      local category = filter_info.category
      local subcategory = filter_info.subcategory
      local label = ucfirst(filter_info.label or filter_info.category or filter_info.filter)
      local types = filter_info.types
      local fid = filter_info.id or label or ((filter or "") .. (category or "") .. (subcategory or ""))
      local previous = self.filterButtons[#self.filterButtons]
      optionX = previous.maxX+boxpadding
      optionW = fonts.textFont:getWidth(label)
      self.filterButtons[#self.filterButtons+1] = {filter=filter, category=category, subcategory = subcategory, types=types, label=label, id = fid, minX = optionX, maxX = optionX+boxpadding+optionW,minY=printY-4,maxY=printY+fontSize+10}
      if self.filter and ((not self.filter.id or self.filter.id == filter_info.id) and ((self.filter.filter == filter_info.filter) and (self.filter.category == filter_info.category) and (self.filter.subcategory == filter_info.subcategory) and self.filter.types == filter_info.types)) then
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
    if (self.cursorY == 0 and self.cursorX == id) or (Gamestate.current() == inventory and not self.inventoryMenu and mouseY < printY+fontSize+10 and mouseY > printY-4 and mouseX-self.filterScroll > minX-4 and mouseX-self.filterScroll < maxX and mouseX > padding and mouseX < maxFilterX) then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",minX-4,printY-4,maxX+10-minX,fontSize+10)
      setColor(255,255,255,255)
    end
    if prefs['noImages'] then
      love.graphics.print((self.filter and self.filter.id == filter.id and "(X)" or "( )"),minX,printY)
    else
      setColor(0,255,255,255)
      love.graphics.draw((self.filter and self.filter.id == filter.id and images.uicheckboxchecked or images.uicheckbox),minX,printY)
      setColor(255,255,255,255)
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
  
  local mouseSelected = self:get_mouse_selected_item()
  --Item list:
  fontSize = math.max(prefs['fontSize'],tileSize)
  love.graphics.line(padding,printY+fontSize,sidebarX-padding,printY+fontSize)
  printY = printY+fontSize+14
  self.itemStartY = printY
  love.graphics.push()
  local function stencilFunc()
    love.graphics.rectangle("fill",0,self.itemStartY,width,height-self.itemStartY-18)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scroll)
  local slotCount = 0
  local selectedLine
	for i, line in ipairs(self.inventory) do
    local printY = self.itemStartY+line.y
    local slots = (line.item and math.max(1,(line.item.size or 1)) or 1)
    local itemHeight=line.height
    local lineHeight = line.lineHeight
    local numberText = ""
    if (line.item or line.empty) and not line.header and (self.filter == nil or self.filter.id == 'all') and self.inventory_space then
      if (not line.item or not line.item.size or line.item.size > 0) and (not line.item or not line.item.equipped) then
        slotCount = slotCount + 1
        numberText = slotCount .. ") "
      else
        numberText = "-)"
      end
    end
    --[[if line.item == self.selectedItem then
      setColor(100,100,100,255)
      love.graphics.rectangle("fill",printX-8,printY,sidebarX-printX-padding,fontSize+4)
      setColor(255,255,255,255)
    else]]
    local moused = not self.ignoreMouse and (Gamestate.current() == inventory and not self.inventoryMenu and mouseX > printX and mouseX < sidebarX and mouseY+self.scroll >= printY and mouseY+self.scroll < printY+itemHeight and not (self.filterButtons[1] and mouseY > self.filterButtons[1].minY and mouseY < self.filterButtons[1].maxY))
    local selected = ((self.cursorY == i and self.cursorX == 1) or moused) and not line.header
    if selected then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",printX-8,printY,sidebarX-printX-padding+8,itemHeight)
      setColor(255,255,255,255)
      if (not selectedLine or moused) and line.item then
        selectedLine = line
      end
    end
    if line.header == true then
     love.graphics.printf(line.text,printX,printY+5,sidebarX-padding,"center")
    else
      love.graphics.print(numberText,printX,printY)
      if line.item then output.display_entity(line.item,printX+numberPad,printY-2,true,true) end
      if line.empty then setColor(200,200,200,255) end
      love.graphics.printf(line.text,printX+tileSize+numberPad,printY,sidebarX-padding*2-numberPad-tileSize)
    end
    if slots > 1 and self.inventory_space then
      for i=2,slots,1 do
        slotCount = slotCount+1
        setColor(200,200,200,255)
        if (self.filter == nil or self.filter.id == 'all') then love.graphics.print(slotCount .. ") ",printX,printY+lineHeight*(i-1)+2) end
        love.graphics.printf(line.text,printX+tileSize+numberPad,printY+lineHeight*(i-1)+2,sidebarX-padding*2-numberPad-tileSize)
      end
    end
    setColor(255,255,255,255)
    self.biggestY = printY+itemHeight
	end
  if selectedLine and selectedLine.item and not self.inventoryMenu and (mouseSelected == selectedLine.item or (not mouseSelected and self.cursorX == 1)) then
    local desc = selectedLine.text .. "\n" .. selectedLine.item:get_description()
    local boxX = printX+tileSize+numberPad
    local boxY = self.itemStartY+selectedLine.y+selectedLine.lineHeight
    output:description_box(desc,boxX,boxY,nil,self.scroll)
  end
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  if self.biggestY > height then
    self.scrollMax = self.biggestY-(height-padding*2)
    local scrollAmt = self.scroll/self.scrollMax
    self.scrollPositions = output:scrollbar(sidebarX-padX*2,self.itemStartY,math.floor(height)-(prefs['noImages'] and 24 or 16),scrollAmt,true)
  end
  
  --Draw equipment info:
  selectedLine = nil
  local equipCutoff=height-padding
  local equipPrintY = padding
  local equipPrintX = sidebarX+padX
  love.graphics.push()
  local function equipStencilFunc()
    love.graphics.rectangle("fill",equipPrintX,equipPrintY,width-equipPrintX,equipCutoff-equipPrintY)
  end
  love.graphics.stencil(equipStencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.sideScroll)
  local impressions = player:get_all_impressions()
  if count(impressions) > 0 then
    local impText = "Impressions from equipment: "
    local i = 1
    for _,imp in pairs(impressions) do
      impText = impText .. ucfirst(imp) .. (i < count(impressions) and ", " or "")
      i = i+1
    end
    love.graphics.printf(impText,equipPrintX,equipPrintY,self.sidebarW,'center')
    local _,ilines = fonts.textFont:getWrap(impText,self.sidebarW)
    equipPrintY = equipPrintY + #ilines*fontSize
  end
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

    local moused = not self.ignoreMouse and (Gamestate.current() == inventory and not self.inventoryMenu and mouseX > equipPrintX+3 and mouseX < width-padding and mouseY+self.sideScroll >= equip.y and mouseY+self.sideScroll < equip.maxY)
    local selected = ((self.cursorY == i and self.cursorX == 2) or moused)
    if selected then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",equipPrintX+slotWidth,equip.y,width-equipPrintX-padding,equipH)
      setColor(255,255,255,255)
      if (not selectedLine or moused) and equip.item then
        selectedLine = equip
      end
    end
    if equip.item then output.display_entity(equip.item,equipPrintX+slotWidth,equip.y-4,true,true) end
    if equip.empty then setColor(200,200,200,255) end
    love.graphics.print((equip.item and equip.item:get_name(true,nil,true) or equip.text or ""),equipPrintX+slotWidth+tileSize,equip.y+2)
    local slots = (equip.item and equip.item.equipSize and math.max(1,equip.item.equipSize) or 1)
    if slots > 1 then
      for i=2,slots,1 do
        setColor(200,200,200,255)
        love.graphics.print(equip.item:get_name(true,nil,true),equipPrintX+slotWidth+tileSize,equip.y+2+fontSize*(i-1))
      end
    end
    setColor(255,255,255,255)
    self.biggestSideY = equip.y+equipH
  end
  if selectedLine and selectedLine.item and not self.inventoryMenu and (mouseSelected == selectedLine.item or (not mouseSelected and self.cursorX == 2)) then
    local desc = (selectedLine.text or selectedLine.item:get_name(true,nil,true)) .. "\n" .. selectedLine.item:get_description()
    local boxX = equipPrintX+tileSize+slotWidth
    local boxY = selectedLine.y+selectedLine.lineHeight
    output:description_box(desc,boxX,boxY)
  end
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  if self.biggestSideY > height then
    self.sideScrollMax = self.biggestSideY-(height-padding*2)
    local scrollAmt = self.sideScroll/self.sideScrollMax
    self.sideScrollPositions = output:scrollbar(width-padding,equipPrintY,math.floor(height)-(prefs['noImages'] and 24 or 16),scrollAmt,true)
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
  if self.inventoryMenu then
    self.inventoryMenu:draw()
  end
  self.closebutton = output:closebutton(14,14,nil,true)
  love.graphics.pop()
end

function inventory:buttonpressed(key,scancode,isRepeat,controllerType)
  self.ignoreMouse = true
  local uiScale = prefs['uiScale']
  local letter = key
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  local padding = self.padding
	if (key == "escape") or key == "inventory" then
    if self.inventoryMenu then
      self.inventoryMenu = nil
    else
      self:switchBack()
    end
	elseif (key == "enter") or key == "wait" then
    if self.inventoryMenu then
      if self.inventoryMenu.selectedItem then
        self.inventoryMenu:click()
      end
    else
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
              Gamestate.switch(examine_item,self.inventory[self.cursorY].item,self.container)
            end
          end --end item exists if
        elseif self.cursorX == 2 then --selecting an item from the equipped list
          if self.equipment[self.cursorY].item then
            Gamestate.switch(examine_item,self.equipment[self.cursorY].item,self.container)
            --[[self.selectedItem = self.equipment[self.cursorY].item
            self.xHold = self.cursorX
            self.cursorX = 3]]
          else --selecting an empty slot
            self.filter = {filter="equippable",equipSlot=self.equipment[self.cursorY].slotID,appliedFromEquipment=true} --Filter for items that fit in this slot
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
    end
	elseif (key == "north") then
    if self.inventoryMenu then
      self.inventoryMenu:scrollUp()
    else
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
        while self.equipment[self.cursorY] and self.equipment[self.cursorY].y-self.sideScroll < padding and self.sideScroll > 0 do
          self:sideScrollUp()
        end
      end
    end
	elseif (key == "south") then
    if self.inventoryMenu then
      self.inventoryMenu:scrollDown()
    else
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
        while self.equipment[self.cursorY].y+prefs['fontSize']-self.sideScroll >= round(love.graphics.getHeight()/uiScale)-32 and self.sideScroll < self.sideScrollMax do
          self:sideScrollDown()
        end
      end --end which cursorX if
    end
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
    elseif key == "ranged" then
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

function inventory:mousemoved()
  self.ignoreMouse = false
end

function inventory:mousepressed(x,y,button)
  self.ignoreMouse = false
  local uiScale = (prefs['uiScale'] or 1)
  local padding = self.padding
  local maxFilterX = self.sidebarX-padding
  x,y = round(x/uiScale),round(y/uiScale)
  if (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    self:switchBack()
  end
  if self.inventoryMenu then
    if x >= self.inventoryMenu.x and x <= self.inventoryMenu.maxX and y >= self.inventoryMenu.y and y <= self.inventoryMenu.maxY then
      self.inventoryMenu:click(x,y)
      return
    else --if you click outside the menu, close it
      self.inventoryMenu = nil
      return
    end
  end
  
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
  
  if x > padding and x < sidebarX-(self.scrollPositions and padding or 0) and not (self.filterButtons[1] and y > self.filterButtons[1].minY and y < self.filterButtons[1].maxY) then
    for i,item in ipairs(self.inventory) do
      if (item.item or item.empty) and not item.header and y+self.scroll > item.y+self.itemStartY and y+self.scroll < self.itemStartY+item.maxY then
        self.cursorY = i
        self.cursorX = 1
        if item.item then
          if button == 1 then
            if self.action == "drop" then
              return self:dropItem(item.item)
            elseif self.action == "equip" then
              return self:equipItem(item.item)
            elseif self.action == "use" then
              return self:useItem(item.item)
            elseif self.action == "throw" then
              return self:throwItem(item.item)
            else
              Gamestate.switch(examine_item,item.item,self.container)
            end
            return
          elseif button == 2 then
            self.inventoryMenu = InventoryMenu(x,y,item.item)
            return
          end
        end
      end
    end --end inventory for
  elseif x > equipPrintX and x < width-padding then
    for i,item in ipairs(self.equipment) do
      if y+self.sideScroll > item.y and y+self.sideScroll < item.maxY then
        self.cursorY = i
        self.cursorX = 2
        if item.item then
          if button == 1 then
            Gamestate.switch(examine_item,item.item,self.container)
          elseif button == 2 then
            self.inventoryMenu = InventoryMenu(x,y,item.item)
            return
          end
        else
          self.filter = {filter="equippable",equipSlot=item.slotID,appliedFromEquipment=true} --Filter for items that fit in this slot
          self:sort()
        end
        return
      end
    end --end inventory for
  end
end

function inventory:get_mouse_selected_item()
  if self.ignoreMouse then return end
  local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  local padding = self.padding
  local maxFilterX = self.sidebarX-padding
  x,y = round(x/uiScale),round(y/uiScale)
  --Selecting an item by clicking on it:
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  width,height=round(width/uiScale),round(height/uiScale)
  local sidebarX = self.sidebarX
  local equipPrintX = sidebarX+self.padX
  local tileSize = output:get_tile_size(true)
  local fontSize = math.max(prefs['fontSize'],tileSize)
  
  if x > padding and x < sidebarX-(self.scrollPositions and padding or 0) then
    for i,item in ipairs(self.inventory) do
      if (item.item or item.empty) and not item.header and y+self.scroll >= item.y+self.itemStartY and y+self.scroll < self.itemStartY+item.maxY then
        return item.item or true
      end
    end --end inventory for
  elseif x > equipPrintX and x < width-padding then
    for i,item in ipairs(self.equipment) do
      if y+self.sideScroll >= item.y and y+self.sideScroll < item.maxY then
        return item.item or true
      end
    end
  end
end

function inventory:useItem(item)
  local textID = #output.text
  if item then
    if not self.entity then self.entity = player end
    local canUse,text = self.entity:can_use_item(item,item.useVerb)
    if canUse then
      if item.target_type == "self" or not item.target_type then --if a self-targeting item, then just use it and be done
        local used,response = item:use(nil,self.entity)
        self.text=response
        if used ~= false then
          self:switchBack()
          if action ~= "targeting" then advance_turn() end
        else
          if #output.text > textID then
            self.text = output.text[#output.text]
          end
        end
      elseif (item.target_type == "creature" or item.target_type == "tile") and (not item.charges or item.charges > 0) then --if not self-use, target
        item:target(self.entity.target,self.entity)
        self:switchBack()
      end
    else --if canUse == false
      if text then
        output:out(text)
        self.text=text
      elseif #output.text > textID then
        self.text = output.text[#output.text]
      end
    end
  end
end

function inventory:equipItem(item)
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
  local drop,response = self.entity:drop_item(item)
  if drop ~= false then
    self.cursorX=1
    self:sort()
    if self.cursorY > #self.inventory then
      self.cursorY = #self.inventory
    end
    if self.container then
      currMap.contents[item.x][item.y][item] = nil
      self.container:give_item(item)
    end
    self.text = (self.container and "You put " .. item:get_name() .. " in " .. self.container:get_name(true) ..  "." or "You drop " .. item:get_name() .. "." )
    --advance_turn() --Uncomment this if you want dropping to require a turn
    self:sort()
  end
end

function inventory:throwItem(item)
  if item and item.throwable then
    item:target(self.entity.target,self.entity)
    self:switchBack()
  end
end

function inventory:reloadItem(item)
  if item and item.charges and (item.max_charges and item.max_charges > 0) then
    local ammo_list = item:get_possible_ammo(self.entity)
    if item.charges == 0 and #ammo_list > 1 then
      local ammo_selection = {}
      for _, ammo in ipairs(ammo_list) do
        ammo_selection[#ammo_selection+1] = {text=ammo:get_name(true),description=ammo:get_description(),selectFunction=Item.reload,selectArgs={item,self.entity,ammo}}
      end
      Gamestate.switch(multiselect,ammo_selection,"Reload " .. item:get_name(true),true,true)
    else
      local recharge,text = item:reload(self.entity)
      self.text = text
      if recharge ~= false then
        advance_turn()
        self:sort()
      end
    end
  end
end

function inventory:splitStack(item,amount)
  if item and item.stacks and amount > 0 and amount < item.amount then
    item:splitStack(amount)
  end
end

function inventory:wheelmoved(x,y)
  self.ignoreMouse = false
  local mouseX,mouseY = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  mouseX,mouseY = mouseX/uiScale, mouseY/uiScale
  if self.inventoryMenu then
    if y > 0 then
      self.inventoryMenu:scrollUp()
    elseif y < 0 then
      self.inventoryMenu:scrollDown()
    end
  else
    if y > 0 then
      if mouseX < self.sidebarX then
        self:scrollUp()
      else
        self:sideScrollUp()
      end
    elseif y < 0 then
      if mouseX < self.sidebarX then
        self:scrollDown()
      else
        self:sideScrollDown()
      end
    end
  end
end

function inventory:scrollUp()
  self.scroll = math.max(self.scroll - prefs['fontSize'],0)
end

function inventory:scrollDown()
  self.scroll = self.scroll or 0
  self.scroll = math.min(self.scroll + prefs['fontSize'],self.scrollMax)
end

function inventory:sideScrollUp()
  self.sideScroll = math.max(self.sideScroll - prefs['fontSize'],0)
end

function inventory:sideScrollDown()
  self.sideScroll = self.sideScroll or 0
  self.sideScroll = math.min(self.sideScroll + prefs['fontSize'],self.sideScrollMax)
end

function inventory:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch((self.previous == loadout and loadout or game))
    Gamestate.update(dt)
    return
  end
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale, y/uiScale
	if (x ~= output.mouseX or y ~= output.mouseY) then -- only do this if the mouse has moved
    output.mouseX,output.mouseY = x,y
	end
  --Inventory menu:
  if self.inventoryMenu and x >= self.inventoryMenu.x and x <= self.inventoryMenu.maxX and y >= self.inventoryMenu.y and y <= self.inventoryMenu.maxY then
    self.inventoryMenu:mouseSelect(x,y)
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
  if (love.mouse.isDown(1)) and self.sideScrollPositions then
    local upArrow = self.sideScrollPositions.upArrow
    local downArrow = self.sideScrollPositions.downArrow
    local elevator = self.sideScrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:sideScrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:sideScrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then
        self:sideScrollUp()
      elseif y>elevator.endY then
        self:sideScrollDown()
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

InventoryMenu = Class{}

function InventoryMenu:init(printX,printY,item)
  if not item then return nil end
  self.x,self.y=(printX and printX or self.x)+22,(printY and printY or self.y)+20
  self.width = math.max(300,fonts.descFont:getWidth(self.creature and self.creature:get_name(true) or ""))
  self.maxX=self.x+self.width
  self.item = item
  local fontPadding = prefs['descFontSize']+2
  -- Make the box:
  self.entries = {}
  local spellY = self.y+fontPadding
  
  self.entries[#self.entries+1] = {name="Examine",y=spellY,action="examine"}
  spellY = spellY+fontPadding
  if (inventory.container == item.possessor) then -- drop
    self.entries[#self.entries+1] = {name="Take",y=spellY,action="take"}
    spellY = spellY+fontPadding
  end
  if item.usable==true then
    self.entries[#self.entries+1] = {name=item.useVerb and ucfirst(item.useVerb) or "Use",y=spellY,action="use"}
    spellY = spellY+fontPadding
  end
  if item.throwable==true then
    self.entries[#self.entries+1] = {name="Throw",y=spellY,action="throw"}
    spellY = spellY+fontPadding
  end
  if item.equippable==true then
    local equipped = player:is_equipped(item)
    self.entries[#self.entries+1] = {name=(equipped and "Unequip" or "Equip"),y=spellY,action="equip"}
    spellY = spellY+fontPadding
  end
  if item.charges and (item.max_charges and item.max_charges > 0) then -- recharge
    self.entries[#self.entries+1] = {name="Reload/Recharge",y=spellY,action="reload"}
    spellY = spellY+fontPadding
  end
  if item.equippable==true and not item.stacks then --rename
    self.entries[#self.entries+1] = {name="Rename",y=spellY,action="rename"}
    spellY = spellY+fontPadding
  end
  if item.stacks==true and item.amount and item.amount > 1 then --split stack
    self.entries[#self.entries+1] = {name="Split Stack",y=spellY,action="splitstack"}
    spellY = spellY+fontPadding
  end
  if item.equippable == true or item.usable == true or item.throwable == true then --hotkey
    local hotkey = item.hotkey
    self.entries[#self.entries+1] = {name=(hotkey and "Change Hotkey" or "Assign Hotkey"),y=spellY,action="hotkey"}
    spellY = spellY+fontPadding
  end
  if not item.undroppable and (not inventory.container or inventory.container ~= item.possessor) then -- drop
    local dropText =  (inventory.container and "Place in " .. inventory.container:get_name(true) or "Drop")
    self.entries[#self.entries+1] = {name=dropText,y=spellY,action="drop"}
    spellY = spellY+fontPadding
  end
  self.maxY = spellY
  self.height = spellY-self.y
end

function InventoryMenu:mouseSelect(mouseX,mouseY)
  local fontPadding = prefs['descFontSize']
  if mouseX>=self.x and mouseX<=self.maxX and mouseY>=self.y and mouseY<=self.maxY then
    for iid,item in ipairs(self.entries) do
      if mouseY>item.y-1 and mouseY<item.y+fontPadding then
        self.selectedItem = iid
        break
      end
    end
  end
end

function InventoryMenu:draw()
  love.graphics.setFont(fonts.descFont)
  local fontPadding = prefs['descFontSize']+2
  setColor(0,0,0,185)
  love.graphics.rectangle("fill",self.x,self.y,self.width+1,self.height-1)
  setColor(255,255,255,255)
  love.graphics.rectangle("line",self.x,self.y,self.width+2,self.height)
  
  if self.selectedItem then
    setColor(100,100,100,185)
    love.graphics.rectangle("fill",self.x,self.entries[self.selectedItem].y,self.width+1,fontPadding)
    setColor(255,255,255,255)
  end
  if self.item then
    love.graphics.print(self.item:get_name(true),self.x,self.y)
    love.graphics.line(self.x,self.y+fontPadding,self.x+self.width+1,self.y+fontPadding)
  end
  for _,item in ipairs(self.entries) do
    love.graphics.print(item.name,self.x,item.y)
  end
  love.graphics.setFont(fonts.textFont)
end

function InventoryMenu:click(x,y)
  local fontPadding = prefs['descFontSize']
  local useItem = nil
  if self.selectedItem then
    useItem = self.entries[self.selectedItem]
  else  
    for _,item in ipairs(self.entries) do
      if y>item.y-1 and y<item.y+fontPadding then
        useItem = item
        break
      end
    end
  end
  if useItem then
    if useItem.action == "use" then
      inventory:useItem(self.item)
    elseif useItem.action == "examine" then
      Gamestate.switch(examine_item,self.item)
    elseif useItem.action == "take" then
      player:pickup(self.item)
      advance_turn()
      inventory:sort()
      inventory.text = (inventory.container and "You take " .. self.item:get_name() .. " from " .. inventory.container:get_name(true) ..  "." or "You take " .. self.item:get_name() .. "." )
    elseif useItem.action == "throw" then
      inventory:throwItem(self.item)
    elseif useItem.action == "equip" then
      if inventory.container then
        player:pickup(self.item)
      end
      inventory:equipItem(self.item)
    elseif useItem.action == "reload" then
      inventory:reloadItem(self.item)
    elseif useItem.action == "rename" then
      Gamestate.switch(nameitem,self.item)
    elseif useItem.action == "splitstack" then
      Gamestate.switch(splitstack,self.item)
    elseif useItem.action == "hotkey" then
      Gamestate.switch(hotkey,self.item)
    elseif useItem.action == "drop" then
      inventory:dropItem(self.item)
    elseif useItem.action == "pickup" then
      player:pickup(self.item)
    end
    inventory.inventoryMenu = nil
  end
end

function InventoryMenu:scrollUp()
  if self.selectedItem then
    self.selectedItem = self.selectedItem - 1
    if self.selectedItem < 1 then self.selectedItem = nil end
  end
end

function InventoryMenu:scrollDown()
  if self.selectedItem then
    self.selectedItem = self.selectedItem + 1
    if self.selectedItem > #self.entries then self.selectedItem = #self.entries end
  else --if there's no selected item, set it to the first one
    self.selectedItem = 1
  end
end