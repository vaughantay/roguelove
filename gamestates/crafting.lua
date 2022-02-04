crafting = {}

function crafting:enter()
  self.hideUncraftable = self.hideUncraftable or false
  self:refresh_craft_list()
  self.craft_coordinates = {toggle={minX=0,maxX=0,minY=0,maxY=0}}
  self.makeAmt = 1
  self.cursorX = 1
  self.cursorY = 0
  self.outText = nil
  self.yModPerc = 100
  self.scrollY = 0
  self.descScrollY = 0
  self.scrollMax = 0
  self.descScrollMax = 0
  self.sidebarX = 0
  self.startY = 0
  
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
end

function crafting:refresh_craft_list()
  local craft_list = player:get_all_possible_recipes(self.hideUncraftable)
  local crafts = {}
  for _,craftID in ipairs(craft_list) do
    local craftData = {id=craftID,craftable=true,ingredients={}}
    local recipe = possibleRecipes[craftID]
    --First look at igredients:
    for iid,amount in pairs(recipe.ingredients) do
      local item = possibleItems[iid]
      local _,_,player_amount = player:has_item(iid)
      local ing = {id=iid,amount=amount,player_amount=player_amount,enough=(player_amount>=amount)}
      craftData.ingredients[ing.id] = ing
      if player_amount < amount then craftData.craftable = false end
    end
    --Class check:
    if recipe.requires_class then
      craftData.requires_class = playerClasses[recipe.requires_class]
      craftData.is_class = (player.class == recipe.requires_class)
      if not craftData.is_class then craftData.craftable=false end
    end
    --Spell check:
    if recipe.requires_spells then
      craftData.requires_spells = {}
      for _,spell in ipairs(recipe.requires_spells) do
        local has_spell = player:has_spell(spell)
        craftData.requires_spells[#craftData.requires_spells+1] = {spellID=spell,spell_name=possibleSpells[spell].name,has_spell=has_spell}
        if not has_spell then craftData.craftable = false end
      end
    end
    --Specific Tool Check:
    if recipe.specific_tools then
      craftData.specific_tools = {}
      for _,tool in ipairs(recipe.specific_tools) do
        local has_item = player:has_item(tool)
        craftData.specific_tools[#craftData.specific_tools+1] = {toolID=tool,has_item=has_item}
        if not has_item then craftData.craftable=false end
      end
    end --end specific tool for

    --Tool Tag Check:
    if recipe.tool_tags then
      craftData.tool_tags = {}
      for _,tag in ipairs(recipe.tool_tags) do
        craftData.tool_tags[tag] = false
        for _,item in pairs(player.inventory) do
          if item:has_tag(tag) then
            craftData.tool_tags[tag] = item
            break
          end --end if has_tag
        end -- end inventory for
        if not craftData.tool_tags[tag] then
          craftData.craftable=false
        end
      end --end tag for
    end --end tool tag for
    
    --Level Requirement Check:
    if recipe.required_level then
      craftData.required_level = recipe.required_level
      craftData.is_level = (player.level >= recipe.required_level)
      if not craftData.is_level then craftData.craftable = false end
    end
    
    if recipe.stat_requirements then
      craftData.stat_requirements = {}
      for stat,requirement in pairs(recipe.stat_requirements) do
        local player_stat = (player:get_stat(stat,true) or player:get_bonus_stat(stat,true)) or 0
        local meets_requirement = (player_stat >= requirement)
        craftData.stat_requirements[stat] = {requirement=requirement,player_stat=player_stat,meets_requirement=meets_requirement}
        if not meets_requirement  then
          craftData.craftable = false
        end
      end
    end
    
    if recipe.requires then
      local canCraft,result = recipe:requires(player)
      if canCraft == false then craftData.craftable = false end
      craftData.meets_requires_code = not (canCraft == false)
      if result and type(result) == "string" then 
        craftData.requires_text = result
      elseif recipe.requires_text then
        craftData.requires_text = recipe.requires_text
      elseif canCraft == false then
        craftData.requires_text = "You do not meet the other requirements needed to craft this."
      end
    end
    
    if not self.hideUncraftable or craftData.craftable then crafts[#crafts+1] = craftData end
  end --end craft list for
  self.crafts = crafts
end

function crafting:draw()
  local uiScale = (prefs['uiScale'] or 1)
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
	local padX,padY = (prefs['noImages'] and 5 or 20),(prefs['noImages'] and 5 or 20)
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  local fontSize = prefs['fontSize']
  local outHeight = 0
	
  self.screenMax = round((height/(fontSize+2)/2)/uiScale)
  local padding = (prefs['noImages'] and 16 or 32)
	love.graphics.setFont(fonts.textFont)
  local sidebarX = round(width/2/uiScale)+padding
  local window1w = sidebarX-padding-padX
  local window2w = round(width/uiScale)-sidebarX-padX-padding
  self.sidebarX = sidebarX
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  
  love.graphics.printf("Crafting",padX,padY,window1w,"center")
  --Display output text:
  local printY=padY+prefs['fontSize']*2
  if self.outText then
    local _,olines = fonts.textFont:getWrap(self.outText, window1w)
    outHeight = (#olines+2)*prefs['fontSize']
    love.graphics.printf(self.outText,padX,printY,window1w,"center")
    printY=printY+outHeight
  end
  
  --Display box to filter out uncraftables
  local midX = round(window1w/2)
  local textW = fonts.textFont:getWidth("Show Only Craftable Recipes")
  local boxX = round(midX-textW/2)
  if self.cursorY == 0 then
    setColor(100,100,100,255)
    love.graphics.rectangle('fill',boxX-padX,printY-8,textW+32+padX*2,prefs['fontSize']+8)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((self.hideUncraftable and "(X)" or "( )"),boxX,printY)
  else
    love.graphics.draw((self.hideUncraftable and images.uicheckboxchecked or images.uicheckbox),boxX,printY)
  end
  self.craft_coordinates['toggle'] = {minX=boxX-padX,minY=printY-8,maxX=boxX+textW+32+padX*2,maxY=printY+prefs['fontSize']}
  love.graphics.print("Show Only Craftable Recipes",boxX+32,printY-8)
  printY=printY+prefs['fontSize']*2
  
  local startY = printY
  self.startY = startY
  
  --List crafts:
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",padX,startY,window1w,height-printY-8)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
	for i,craftInfo in ipairs(self.crafts) do
    local craftID = craftInfo.id
    local name = ""
    local count = 1
    local recipe = possibleRecipes[craftID]
    for item,amount in pairs(recipe.results) do
      if count > 1 then name = name .. ", " end
      if amount > 1 then
        name = name .. amount .. " " .. ucfirst(possibleItems.pluralName or "x " .. ucfirst(possibleItems[item].name))
      else
        name = name .. ucfirst(possibleItems[item].name)
      end
      count = count + 1
    end
    local _, nameLines = fonts.textFont:getWrap(name, window1w)
    if self.cursorY == i then
      if self.cursorX == 1 then setColor(150,150,150,255)
      else setColor(75,75,75,255) end
      love.graphics.rectangle("fill",padX,printY,window1w-padX,#nameLines*fontSize+2)
      setColor(255,255,255,255)
    end
    self.craft_coordinates[i] = {minX=padX,minY=printY,maxX=window1w-padX,maxY=printY+#nameLines*fontSize}
    if not craftInfo.craftable then
      setColor(200,0,0,255)
    end
		love.graphics.printf(name,padX,printY,window1w)
    if not craftInfo.craftable then
      setColor(255,255,255,255)
    end
		printY=printY+#nameLines*fontSize
	end
  if count(self.crafts) < 1 then
    love.graphics.printf("You can't craft anything right now.",padX,printY,window1w,"center")
  end
  love.graphics.setStencilTest()
  love.graphics.pop()
  --Scrollbars
  if printY*uiScale > height-startY then
    self.scrollMax = math.ceil((printY-(startY+(height/uiScale-startY))+padding))
    local scrollAmt = self.scrollY/self.scrollMax
    if self.cursorX == 2 then
      setColor(150,150,150,255)
      love.graphics.rectangle('fill',window1w,startY,32,math.floor((height-padding)/uiScale)-startY)
      setColor(255,255,255,255)
    end
    self.scrollPositions = output:scrollbar(window1w,startY,math.floor((height-padding)/uiScale),scrollAmt,true)
  else
    self.scrollMax = 0
  end
  self.scrollY = math.min(self.scrollY,self.scrollMax)
  
  --Print info on selected craft:
  if (self.crafts[self.cursorY] ~= nil) then
    love.graphics.push()
    --Create a "stencil" that stops 
    local function stencilFunc()
      love.graphics.rectangle("fill",sidebarX+padX,padY,window2w,height-padY-8)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.descScrollY)
    local craftInfo = self.crafts[self.cursorY]
    local recipe = possibleRecipes[craftInfo.id]
    local descY = padding
    --List Results:
    local resultCount = count(recipe.results)
    local resultText = (resultCount > 1 and "Results:" or "Result: ")
    for iid,amount in pairs(recipe.results) do
      local item = possibleItems[iid]
      resultText = resultText .. (resultCount > 1 and "\n\t*" or "") .. (amount > 1 and item.pluralName and amount .. " " .. ucfirst(item.pluralName) or ucfirst(item.name) .. (amount > 1 and " x " .. amount or "")) .. " (" .. item.description .. ")"
    end
    love.graphics.printf(resultText,sidebarX+padX,descY,window2w,"left")
    local _, dlines = fonts.textFont:getWrap(resultText,window2w)
    descY = descY+prefs['fontSize']*(#dlines+2)
    --List Ingredients:
    love.graphics.printf("Ingredients:",sidebarX+padX,descY,window2w,"left")
    descY=descY+prefs['fontSize']
    for iid,ingInfo in pairs(craftInfo.ingredients) do
      local item = possibleItems[iid]
      local player_amount = ingInfo.player_amount or 0
      local amount = ingInfo.amount
      local ingText = "\t*" .. (amount > 1 and item.pluralName and amount .. " " .. ucfirst(item.pluralName) or ucfirst(item.name) .. (amount > 1 and " x " .. amount or "")) .. " (You have " .. player_amount .. ")"
      if not ingInfo.enough then
        setColor(200,0,0,255)
      end
      love.graphics.printf(ingText,sidebarX+padX,descY,window2w,"left")
      if not ingInfo.enough then
        setColor(255,255,255,255)
      end
      local _, dlines = fonts.textFont:getWrap(ingText,window2w)
      descY = descY+prefs['fontSize']*#dlines
    end
    descY=descY+prefs['fontSize']
    
    if craftInfo.specific_tools then
      local toolCount = count(craftInfo.specific_tools)
      love.graphics.printf("Requires Tool" .. (toolCount > 1 and "s:" or ":"),sidebarX+padX,descY,window2w,"left")
      descY=descY+prefs['fontSize']
      for _,toolInfo in ipairs(craftInfo.specific_tools) do
        local item = possibleItems[toolInfo.toolID]
        if not toolInfo.has_item then
          setColor(200,0,0,255)
        end
        local toolText = "\t*" .. ucfirst(item.name)
        love.graphics.printf(toolText,sidebarX+padX,descY,window2w,"left")
        if not toolInfo.has_item then
          setColor(255,255,255,255)
        end
        local _, dlines = fonts.textFont:getWrap(toolText,window2w)
        descY = descY+prefs['fontSize']*#dlines
      end
      descY=descY+prefs['fontSize']
    end
    
    if craftInfo.tool_tags then
      local toolCount = count(craftInfo.tool_tags)
      love.graphics.printf("Requires tool" .. (toolCount > 1 and "s" or "") .. " with tag" .. (toolCount > 1 and "s:" or ":"),sidebarX+padX,descY,window2w,"left")
      descY = descY + prefs['fontSize']
      for tag,item in pairs(craftInfo.tool_tags) do
        local toolText = "\t*" .. ucfirst(tag) .. (item and " (" .. ucfirst(item.name) .. ")" or "")
        if not item then
          setColor(200,0,0,255)
        end
        love.graphics.printf(toolText,sidebarX+padX,descY,window2w,"left")
        local _, dlines = fonts.textFont:getWrap(toolText,window2w)
        descY = descY+prefs['fontSize']*#dlines
        if not item then
          setColor(255,255,255,255)
        end
      end
      descY=descY+prefs['fontSize']
    end
    
    if craftInfo.requires_spells then
      local spellCount = #craftInfo.requires_spells
      love.graphics.printf("Requires spell" .. (spellCount > 1 and "s:" or ":"),sidebarX+padX,descY,window2w,"left")
      descY = descY+prefs['fontSize']
      for _,spellData in ipairs(craftInfo.requires_spells) do
        local spellText = "\t*" .. ucfirst(spellData.spell_name)
        if not spellData.has_spell then
          setColor(200,0,0,255)
        end
        love.graphics.printf(spellText,sidebarX+padX,descY,window2w,"left")
        local _, dlines = fonts.textFont:getWrap(spellText,window2w)
        descY = descY+prefs['fontSize']*#dlines
        if not spellData.has_spell then
          setColor(255,255,255,255)
        end
      end
      descY = descY+prefs['fontSize']
    end
    
    if craftInfo.requires_class then
      local classText = "Only Craftable by: " .. craftInfo.requires_class.name
      if not craftInfo.is_class then
        setColor(200,0,0,255)
      end
      love.graphics.printf(classText,sidebarX+padX,descY,window2w,"left")
      if not craftInfo.is_class then
        setColor(255,255,255,255)
      end
      local _, dlines = fonts.textFont:getWrap(classText,window2w)
      descY = descY+prefs['fontSize']*(#dlines+1)
    end
    
    if craftInfo.requires_level then
      local levelText = "Must be level " .. craftInfo.requires_level
      if not craftInfo.is_level then
        setColor(200,0,0,255)
      end
      love.graphics.printf(levelText,sidebarX+padX,descY,window2w,"left")
      if not craftInfo.is_level then
        setColor(255,255,255,255)
      end
      local _, dlines = fonts.textFont:getWrap(levelText,window2w)
      descY = descY+prefs['fontSize']*(#dlines+1)
    end
    
    if craftInfo.stat_requirements then
      love.graphics.printf("Stat Requirements:",sidebarX+padX,descY,window2w,"left")
      descY = descY+prefs['fontSize']
      for stat,info in pairs(craftInfo.stat_requirements) do
        local statText = "\t*" .. ucfirst(stat) .. ": " .. info.requirement .. " (You have " .. info.player_stat .. ")"
        if not info.meets_requirement then
          setColor(200,0,0,255)
        end
        love.graphics.printf(statText,sidebarX+padX,descY,window2w,"left")
        local _, dlines = fonts.textFont:getWrap(statText,window2w)
        descY = descY+prefs['fontSize']*#dlines
        if not info.meets_requirement then
          setColor(255,255,255,255)
        end
      end
      descY = descY+prefs['fontSize']
    end
    
    if craftInfo.requires_text then
      if not craftInfo.meets_requires_code then
        setColor(200,0,0,255)
      end
      love.graphics.printf(craftInfo.requires_text,sidebarX+padX,descY,window2w,"left")
      if not craftInfo.meets_requires_code then
        setColor(255,255,255,255)
      end
      local _, dlines = fonts.textFont:getWrap(craftInfo.requires_text,window2w)
      descY = descY+prefs['fontSize']*(#dlines+1)
    end
    love.graphics.setStencilTest()
    love.graphics.pop()
    --Scrollbars
    if descY*uiScale > height-padY then
      self.descScrollMax = math.ceil((descY-(padY+(height/uiScale-padY))+padding))
      local scrollAmt = self.descScrollY/self.descScrollMax
      if self.cursorX == 3 then
        setColor(150,150,150,255)
        love.graphics.rectangle('fill',sidebarX+window2w,padY,32,math.floor((height-padding)/uiScale)-padY)
        setColor(255,255,255,255)
      end
      self.descScrollPositions = output:scrollbar(sidebarX+window2w,padY,math.floor((height-padding)/uiScale),scrollAmt,true)
    else
      self.descScrollMax = 0
    end
    self.descScrollY = math.min(self.descScrollY,self.descScrollMax)
  end --end showing selected craft
  self.closebutton = output:closebutton(padding,padding,nil,true)
  love.graphics.pop()
end

function crafting:keypressed(key)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width,height = round(width/uiScale),round(height/uiScale)
  key = input:parse_key(key)
	if (key == "escape") then
		self:switchBack()
	elseif (key == "return") or key == "wait" then
    if self.cursorX == 1 then
      if self.cursorY == 0 then
        self.hideUncraftable = not self.hideUncraftable
        self:refresh_craft_list()
      end
      if self.crafts[self.cursorY] ~= nil then
        self:doCraft(self.cursorY)
      end
    else
      self.cursorX = 1
    end
  elseif key == "east" then
    if self.cursorX == 1 and self.cursorY ~= 0 then
      if self.scrollMax > 0 then
        self.cursorX = 2
      elseif self.descScrollMax > 0 then
        self.cursorX = 3
      end
    elseif self.cursorX == 2 and self.descScrollMax > 0 then
      self.cursorX = 3
    end
  elseif key == "west" then
    if self.cursorX == 2 then
      self.cursorX = 1
    elseif self.cursorX == 3 then
      if self.scrollMax > 0 then self.cursorX = 2
      else self.cursorX = 1 end
    end
	elseif (key == "north") then
    if self.cursorX == 1 then
      if (self.cursorY > 0) then
        self.cursorY = self.cursorY - 1
        if not self.craft_coordinates[self.cursorY-1] or self.craft_coordinates[self.cursorY-1].minY-self.scrollY < self.startY then
          self:listScrollUp()
        end
      end
    elseif self.cursorX == 2 then
      self:listScrollUp()
    elseif self.cursorX == 3 then
      self:descScrollUp()
    end
	elseif (key == "south") then
    if self.cursorX == 1 then
      if (self.crafts[self.cursorY+1] ~= nil) then
        self.cursorY = self.cursorY + 1
        if not self.craft_coordinates[self.cursorY+1] or self.craft_coordinates[self.cursorY+1].maxY-self.scrollY > height then
          self:listScrollDown()
        end
      end
    elseif self.cursorX == 2 then
      self:listScrollDown()
    elseif self.cursorX == 3 then
      self:descScrollDown()
    end
	end
end

function crafting:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then self:switchBack() end
  local scrolled = self:update(0,true)
  
  if not scrolled then
    if (self.crafts[self.cursorY] ~= nil) then
      self:doCraft(self.cursorY)
    elseif self.cursorY == 0 then
      self.hideUncraftable = not self.hideUncraftable
      self:refresh_craft_list()
    end
  end
end

function crafting:update(dt,forceMouse)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = round(x/uiScale), round(y/uiScale)
	if (forceMouse or x ~= self.mouseX or y ~= self.mouseY) then -- only do this if the mouse has moved
    self.mouseX,self.mouseY = x,y
    for id,coords in ipairs(self.craft_coordinates) do
      if x > coords.minX and x < coords.maxX and y+self.scrollY > coords.minY and y+self.scrollY < coords.maxY then
        self.cursorY = id
      end
    end
    local toggle = self.craft_coordinates['toggle']
    if x > toggle.minX and x < toggle.maxX and y > toggle.minY and y < toggle.maxY then
      self.cursorY = 0
    end
	end
  --Scrollbars:
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local upArrow = self.scrollPositions.upArrow
    local downArrow = self.scrollPositions.downArrow
    local elevator = self.scrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:listScrollUp()
      return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:listScrollDown()
      return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then
        self:listScrollUp()
        return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
      elseif y>elevator.endY then
        self:listScrollDown()
        return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
      end
    end --end clicking on arrow
  end
  if (love.mouse.isDown(1)) and self.descScrollPositions then
    local upArrow = self.descScrollPositions.upArrow
    local downArrow = self.descScrollPositions.downArrow
    local elevator = self.descScrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:descScrollUp()
      return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:descScrollDown()
      return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then
        self:descScrollUp()
        return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
      elseif y>elevator.endY then
        self:descScrollDown()
        return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
      end
    end --end clicking on arrow
  end
end

function crafting:doCraft(craftIndex)
  local craftID = self.crafts[craftIndex].id
  if self.crafts[craftIndex].craftable then
    local result,text = player:craft_recipe(craftID)
    if result == true and not text then
      text = possibleCrafts[craftID].result_text
    end
    self.outText = text
    self:refresh_craft_list()
  else
    self.outText = "You can't craft that right now."
  end
end

function crafting:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function crafting:wheelmoved(x,y)
  if y > 0 then
    if self.mouseX < self.sidebarX then self:listScrollUp() else self:descScrollUp() end
	elseif y < 0 then
    if self.mouseX < self.sidebarX then self:listScrollDown() else self:descScrollDown() end
  end --end button type if
end

function crafting:listScrollUp()
  local height = love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  height = round(height/uiScale)
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
    if self.craft_coordinates[self.cursorY] and self.craft_coordinates[self.cursorY].maxY-self.scrollY > height then
      self.cursorY = self.cursorY-1
    end
  end
end

function crafting:listScrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
    end
    if self.craft_coordinates[self.cursorY] and self.craft_coordinates[self.cursorY].minY-self.scrollY < self.startY then
      self.cursorY = self.cursorY+1
    end
  end
end

function crafting:descScrollUp()
  if self.descScrollY > 0 then
    self.descScrollY = self.descScrollY - prefs.fontSize
    if self.descScrollY < prefs.fontSize then
      self.descScrollY = 0
    end
  end
end

function crafting:descScrollDown()
  if self.descScrollMax and self.descScrollY < self.descScrollMax then
    self.descScrollY = self.descScrollY+prefs.fontSize
    if self.descScrollMax-self.descScrollY < prefs.fontSize then
      self.descScrollY = self.descScrollMax
    end
  end
end