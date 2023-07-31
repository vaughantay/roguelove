spellscreen = {}

function spellscreen:enter()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  
  --Set initial coordinates and such:
  local padX,padY = 0,0
  if prefs['noImages'] == true then
    padX,padY=5,5
  else
    padX,padY=20,20
  end
  width,height = round(width/uiScale),round(height/uiScale)
  self.sidebarX = round(width/2)+(prefs['noImages'] and 16 or 32)
  self.padding = (prefs['noImages'] and 16 or 32)
  self.x,self.y=1,1
  self.padX,self.padY = padX,padY
  self.cursorY = 0
  self.cursorX = 1
  self.sidebarCursorY = 1
  self.yModPerc = 100
  self.scrollY = 0
  self.descScrollY = 0
  self.scrollMax = 0
  self.descScrollMax = 0
  self.startY=0
  self.descStartY=0
  self.playerSpells = player:get_spells()
  self.buttons = {}
  self.upgradeButtons = {}
  
  self.yModPerc = 0
  if previous == game then
    self.yModPerc = 100
    tween(0.2,self,{yModPerc=0})
    output:sound('stoneslideshort',2)
  end
  self.spellLines = {}
end

function spellscreen:draw()
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
  local padding = self.padding
	love.graphics.setFont(fonts.textFont)
  local sidebarX = self.sidebarX
  local window1w = sidebarX-padding-padX
  local window2w = width-sidebarX-padX*2
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  
  love.graphics.printf("Spells and Abilities",padding,padding,window1w,"center")
  local printY = padding+round(fontSize*1.5)
  local printX = (prefs['noImages'] and 14 or 32)
  local spellPoints = (player.spellPoints or 0)
  local spellSlots = player:get_free_spell_slots()
  if spellPoints > 0 then
    love.graphics.printf(spellPoints .. " ability point" .. (spellPoints == 1 and " available" or "s available"),padding,printY,window1w,"center")
    printY = printY+fontSize
  end
  if spellSlots and spellSlots > 0 then
    love.graphics.printf(spellSlots .. " open spell slot" .. (spellSlots == 1 and "" or "s"),padding,printY,window1w,"center")
    printY = printY+round(fontSize*1.5)
  end
  self.startY = printY
  
  --Display filter buttons:
  local maxFilterX = sidebarX-padding
  
  --Drawing the text:
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",padX,printY-4,maxFilterX-padX*2,height-padding-printY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  local playerSpells = self.playerSpells
  --Display the spells:
  local bottom = 0
	local spells = {}
  local line=1
  local mousedSpell = nil
	for i, spell in pairs(playerSpells) do
    local moused = (mouseX > printX and mouseX < window1w and mouseY+self.scrollY > printY and mouseY+self.scrollY < printY+fontSize+2)
    local spellID = spell.id
		spells[i] = spellID
    local name = spell.name
    local target_type = spell.target_type
    local active = spell.active
    local upgrade = (spellPoints > 0 and (count(spell:get_possible_upgrades()) > 0))
    --Draw the highlight box:
    if (self.cursorY == i) then
      if self.cursorX == 2 then
        setColor(125,125,125,255)
      else
        setColor(100,100,100,255)
      end
      love.graphics.rectangle("fill",x+padX,printY,window1w-padX*2,fontSize+2)
      setColor(255,255,255,255)
    elseif moused then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",x+padX,printY,window1w-padX*2,fontSize+2)
      setColor(255,255,255,255)
      mousedSpell = i
    end
    if player.cooldowns[name] or spell:requires(player) == false then
      if moused or self.cursorY == i then
        setColor((active and (upgrade and 12 or 0) or 25),25,(upgrade and 0 or (active and 0 or 25)),255)
      else
        setColor((active and (upgrade and 50 or 0) or 100),100,(upgrade and 0 or (active and 0 or 100)),255)
      end
    else
      setColor((active and (upgrade and 200 or 100) or 255),255,(upgrade and 0 or (active and 100 or 255)),255)
    end --end cooldowns if
    local fullText = (spell.hotkey and spell.hotkey .. ") " or "") .. name .. (player.cooldowns[name] and " (" .. player.cooldowns[name] .. " turns to recharge)" or "") .. (target_type == "passive" and " (Passive)" or "") .. (active and " (Active)" or "") .. (upgrade and " (+)" or "")
		love.graphics.print(fullText,x+padX,printY)
    setColor(255,255,255,255)
		line = line+1
    self.spellLines[i] = {minY=printY,maxY=printY+fontSize+2}
    printY = printY+fontSize+2
	end
  bottom = printY
  
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  --Description Box:
  local spell = playerSpells[self.cursorY] or playerSpells[mousedSpell]
  if spell ~= nil then
    love.graphics.push()
    --Draw the actual spell info:
    local target_type = spell.target_type
    local spellText = spell:get_description()
    local printY = padding
    local printX = sidebarX+padX
    local hotkey = spell.hotkey
    local selected = (self.cursorX ~= 1)
    
    if target_type == "passive" then
      spellText = spellText .. "\n\nThis ability is passive and is used automatically when needed."
    end
    if spell.toggled then
      if not spell.no_manual_deactivate then
        spellText = spellText .. "\n\nThis ability can be toggled on and off at will and has an effect over time while activated."
      else
        spellText = spellText .. "\n\nThis ability can be toggled on and has an effect over time while activated."
      end
      local move = spell.deactivate_on_move or spell.deactivate_on_all_actions
      local attack = spell.deactivate_on_attack or spell.deactivate_on_all_actions
      local ranged = spell.deactivate_on_ranged_attack or spell.deactivate_on_all_actions
      local item = spell.deactivate_on_item or spell.deactivate_on_all_actions
      local cast = spell.deactivate_on_cast or spell.deactivate_on_all_actions
      if move or attack or ranged or item or cast then
        spellText = spellText .. "\nThis ability is deactivated when you"
        if move then
          spellText = spellText .. " move"
        end
        if attack then
          spellText = spellText .. (move and "," .. (not cast and not ranged and not item and " or" or "") or "") .. " attack"
        end
        if ranged then
          spellText = spellText .. ((move or attack) and "," .. (not cast and not item and " or" or "") or "") .. " use a ranged attack"
        end
        if item then
          spellText = spellText .. ((move or ranged or attack) and "," .. (not cast and " or" or "") or "") .. " use an item"
        end
        if cast then
          spellText = spellText .. ((move or ranged or item or attack) and ", or" or "") .. " cast another spell"
        end
        spellText = spellText .. "."
      end
    end
    
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(fonts.textFont)
    local width, tlines = fonts.textFont:getWrap(spellText,window2w)
    local sheight = (#tlines+1)*fontSize
    love.graphics.printf(spell.name,printX,printY,window2w,"center")
    printY=printY+fontSize+2
    love.graphics.printf(spellText,printX,printY,window2w,"left")
    printY=printY+sheight
    
    --Buttons:
    local buttonHeight = 32
    local buttonCount = 0
    if not selected then
      setColor(175,175,175,255)
    end
    if spell.target_type ~= "passive" then
      buttonCount = buttonCount + 1
      local useText = ((spell.active and not spell.no_manual_deactivate) and "Stop" or "Use")
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if player.cooldowns[spell.name] or spell:requires(player) == false or (spell.active and spell.no_manual_deactivate) then
        setColor(100,100,100,255)
      end
      self.buttons.use = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == buttonCount and "hover" or nil),useText,true)
      self.buttons.use.buttonNum = buttonCount
      if player.cooldowns[spell.name] or spell:requires(player) == false or (spell.active and spell.no_manual_deactivate) then
        if selected then setColor(255,255,255,255)
        else setColor(175,175,175,255) end
      end
      printY = printY+buttonHeight
      buttonCount = buttonCount + 1
      local hotkeyText = (hotkey and "Change Hotkey" or "Assign Hotkey")
      buttonWidth = fonts.buttonFont:getWidth(hotkeyText)+25
      self.buttons.hotkey = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == buttonCount and "hover" or nil),hotkeyText,true)
      self.buttons.hotkey.buttonNum = buttonCount
      printY = printY+buttonHeight
    end
    if spell.forgettable or (gamesettings.spells_forgettable_by_default and spell.forgettable ~= false) then
      buttonCount = buttonCount + 1
      local forgetText = "Forget"
      local buttonWidth = fonts.buttonFont:getWidth(forgetText)+25
      self.buttons.forget = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == buttonCount and "hover" or nil),forgetText,true)
      self.buttons.forget.buttonNum = buttonCount
      printY = printY+buttonHeight
    end
    if not selected then
      setColor(255,255,255,255)
    end
    
    self.descStartY=printY
    --Stencil and scroll:
    local function stencilFunc()
      love.graphics.rectangle("fill",printX,self.descStartY,window2w,height-padY-self.descStartY)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.descScrollY)
    
    --Print stats
    local statText = ""
    if spell.charges then
      statText = statText .. "\nCharges: " .. spell.charges .. (spell.max_charges and "/" .. spell.max_charges or "")
    end
    if spell.cost then
      statText = statText .. "\nMP Cost: " .. spell.cost
    end
    if spell.cost_per_turn then
      statText = statText .. "\nMP Cost per Turn: " .. spell.cost_per_turn
    end
    if spell.max_active_turns then
      statText = statText .. "\nMax Active Turns: " .. spell.max_active_turns
    end
    if spell.cooldown then
      statText = statText .. "\nCooldown: " .. spell.cooldown .. " Turns"
    end
    if spell.min_range then
      statText = statText .. "\nMin Range: " .. spell.range
    end
    if spell.range then
      statText = statText .. "\nMax Range: " .. spell.range
    end
    if spell.deactivate_on_damage_chance then
      statText = statText .. "\nChance of Deactivation when Damaged: " .. spell.deactivate_on_damage_chance .. "%"
    end
    if spell.stats then
      local tempstats = {}
      local stats = {}
      local lastorder = 0
      for stat,info in pairs(spell.stats) do
        info.id = stat
        local display_order = info.display_order
        if display_order then
          lastorder = math.max(lastorder,display_order)
          table.insert(tempstats,display_order,info)
        else
          table.insert(tempstats,info)
          lastorder = math.max(lastorder,#tempstats)
        end
      end
      for i=1,lastorder,1 do
        if tempstats[i] then
          stats[#stats+1] = tempstats[i]
        end
      end
      for i,stat in pairs(stats) do
        local value = spell:get_stat(stat.id)
        if value ~= false and stat.hide ~= true and (value ~= 0 or stat.hide_when_zero ~= true) then
          statText = statText .. "\n" .. stat.name .. (type(value) ~= "boolean" and ": " .. value .. (stat.is_percentage and "%" or "") or "") .. (stat.description and " (" .. stat.description .. ")" or "")
        end
      end
    end
    love.graphics.printf(statText,printX,printY,window2w,"left")
    local _, slines = fonts.textFont:getWrap(statText,window2w)
    local sHeight = (#slines+2)*fontSize
    printY = printY+sHeight
    
    --Print upgrades
    if spell.possible_upgrades then
      local upgrades = spell:get_possible_upgrades()
      if count(upgrades) > 0 then
        love.graphics.printf("Upgrades:",printX,printY,window2w,"left")
        printY=printY+fontSize+5
        local buttonY = 1
        local mod = buttonCount
        local upDesc,upY = nil,nil
        for id,level in pairs(upgrades) do
          if self.sidebarCursorY==buttonY+mod and printY-self.descScrollY < self.descStartY then
            self:descScrollUp()
          end
          if not spell:can_upgrade(id,level) then
            setColor(100,100,100,255)
          elseif not selected then
            setColor(175,175,175,255)
          end
          local mouseOver = false
          if self.upgradeButtons[buttonY] and mouseX > self.upgradeButtons[buttonY].minX and mouseX < self.upgradeButtons[buttonY].maxX and mouseY > self.upgradeButtons[buttonY].minY-self.descScrollY and mouseY < self.upgradeButtons[buttonY].maxY-self.descScrollY then
            mouseOver = true
          end
          self.upgradeButtons[buttonY] = output:tinybutton(printX,printY+1,true,((mouseOver or self.sidebarCursorY==buttonY+mod) and "hover" or false),"+",true)
          self.upgradeButtons[buttonY].upgradeID = id
          setColor(255,255,255,255)
          local buttonW = 34
          local details = spell.possible_upgrades[id]
          local level_details = spell.possible_upgrades[id][level]
          local name = (level_details.name or details.name or ucfirst(id))
          local description = (level_details.description or details.description or nil)
          local i = 1
          local point_cost = level_details.point_cost or 1
          local statText = ""
          for stat,amt in pairs(level_details) do
            if type(amt) ~= "boolean" and type(amt) ~= "table" and stat ~= "point_cost" then
              local statName = (spell.stats and spell.stats[stat] and spell.stats[stat].name or ucfirst(stat))
              statName = string.gsub(statName,'_',' ')
              statText = statText .. "\n\t" .. statName .. (type(amt) == "number" and (amt < 0 and " " or " +") or ": ") .. amt .. (spell.stats and spell.stats[stat] and spell.stats[stat].is_percentage and "%" or "")
            end
          end --end stat for
          local costText = ""
          if point_cost > 0 or level_details.item_cost then
            costText = " - Cost: "
            local firstCost = true
            if point_cost > 0 then
              costText = costText .. point_cost .. " ability point" .. (point_cost > 1 and "s" or "")
              firstCost = false
            end
            if level_details.item_cost then
              for _,item_details in ipairs(level_details.item_cost) do
                local amount = item_details.amount or 1
                local sortByVal = item_details.sortBy
                local _,_,has_amt = player:has_item(item_details.item,sortByVal)
                local name = item_details.displayName or (amount > 1 and possibleItems[item_details.item].pluralName or possibleItems[item_details.item].name)
                costText = costText .. (firstCost == false and ", " or "") .. amount .. " " .. name .. " (You have " .. has_amt .. ")"
                firstCost = false
              end --end item cost for
            end --end item cost if
          end
          local upText = name .. costText .. (description and "\n" .. description or "") .. statText
          love.graphics.printf(upText,printX+buttonW,printY,window2w-padding,"left")
          local _, dlines = fonts.textFont:getWrap(upText,window2w-padding)
          local dHeight = (#dlines+1)*fontSize
          printY = printY+dHeight
          self.upgradeButtons[buttonY].textMaxY = printY
          buttonY=buttonY+1
        end --end upgrade for
      end --end count upgrades > 0
    end --end if upgrades
    
    love.graphics.setFont(oldFont)
    love.graphics.setStencilTest()
    love.graphics.pop()
    
    --Scrollbars
    if printY > height-padding then
      self.descScrollMax = math.ceil((printY-(self.descStartY+(love.graphics:getHeight()/uiScale-self.descStartY))+padding))
      local scrollAmt = self.descScrollY/self.descScrollMax
      self.descScrollPositions = output:scrollbar(sidebarX+window2w,self.y+padY,height-padY,scrollAmt,true)
    end
  end
  
  --Scrollbars
  if bottom > height-padding then
    self.scrollMax = math.ceil((bottom-(self.startY+(love.graphics:getHeight()/uiScale-self.startY))+padding*2))
    local scrollAmt = self.scrollY/self.scrollMax
    self.scrollPositions = output:scrollbar(window1w,self.y+padY,height-padY,scrollAmt,true)
  end
  
  self.closebutton = output:closebutton(self.x+(prefs['noImages'] and 8 or 20),self.y+(prefs['noImages'] and 8 or 20),nil,true)
  love.graphics.pop()
end

function spellscreen:keypressed(key)
  local uiScale = prefs['uiScale']
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  width,height = round(width/uiScale),round(height/uiScale)
  key = input:parse_key(key)
  local playerSpells = player:get_spells()
	if (key == "escape") then
    if self.cursorX == 1 then
      self:switchBack()
    else
      self.cursorX = 1
    end
	elseif (key == "enter") or key == "wait" then
    if self.cursorX == 1 and playerSpells[self.cursorY] then
      self:select_spell(self.cursorY)
    elseif self.cursorX == 2 then
      local spell = playerSpells[self.cursorY]
      local passive = (spell.target_type == "passive")
      local forgettable = spell.forgettable or (gamesettings.spells_forgettable_by_default and spell.forgettable ~= false)
      if not passive then
        if self.sidebarCursorY == 1 then
          return self:cast_spell(self.cursorY)
        elseif self.sidebarCursorY == 2 then
          return Gamestate.switch(hotkey,playerSpells[self.cursorY])
        elseif self.sidebarCursorY == 3 then
          return self:forget_spell(self.cursorY)
        end
      elseif forgettable and self.sidebarCursorY == 1 then
        return self:forget_spell(self.cursorY)
      end
      if self.upgradeButtons then
        for index,button in ipairs(self.upgradeButtons) do
          local mod = (passive and 0 or 2)
          if self.sidebarCursorY == index+mod then
            self:perform_upgrade(button.upgradeID)
            return
          end
        end
      end
    end
	elseif (key == "north") then
    if self.cursorX == 1 then
      if (playerSpells[self.cursorY-1] ~= nil) then
        self.cursorY = self.cursorY - 1
        self.descScrollY = 0
        self.upgradeButtons = {}
      end
      if self.spellLines[self.cursorY] and self.spellLines[self.cursorY].minY-self.scrollY-prefs['fontSize'] < self.startY then
        self:scrollUp()
      end
    else --if a spell is selected
      local spell = playerSpells[self.cursorY]
      self.sidebarCursorY = math.max(self.sidebarCursorY-1,1)
      local topButtonCount = (spell.target_type == "passive" and 0 or 2)+((spell.forgettable or (gamesettings.spells_forgettable_by_default and spell.forgettable ~= false)) and 1 or 0)
      if self.sidebarCursorY <= topButtonCount then
        self.descScrollY = 0
      elseif self.upgradeButtons[self.sidebarCursorY-topButtonCount] then
        while self.upgradeButtons[self.sidebarCursorY-topButtonCount].minY-self.descScrollY < self.descStartY do
          self:descScrollUp()
        end
      end
    end
	elseif (key == "south") then
    if self.cursorX == 1 then
      if (playerSpells[self.cursorY+1] ~= nil) then
        self.cursorY = self.cursorY + 1
        self.descScrollY = 0
        self.upgradeButtons = {}
      end
      if self.spellLines[self.cursorY].maxY-self.scrollY+prefs['fontSize'] >= round(love.graphics.getHeight()/uiScale)-32 and self.scrollY < self.scrollMax then
        self:scrollDown()
      end
    else -- if a spell is selected
      local spell = playerSpells[self.cursorY]
      local topButtonCount = (spell.target_type == "passive" and 0 or 2)+((spell.forgettable or (gamesettings.spells_forgettable_by_default and spell.forgettable ~= false)) and 1 or 0)
      local max = (self.upgradeButtons and #self.upgradeButtons or 0)+topButtonCount
      if self.sidebarCursorY < max then
        self.sidebarCursorY = self.sidebarCursorY+1
      end
      if self.upgradeButtons[self.sidebarCursorY-topButtonCount] then
        while self.upgradeButtons[self.sidebarCursorY-topButtonCount].textMaxY-self.descScrollY > height-self.padY do
          self:descScrollDown()
        end
      end
    end
  elseif (key == "east") then
    if playerSpells[self.cursorY] then self:select_spell(self.cursorY) end
  elseif (key == "west") then
    self.cursorX = 1
	end
end

function spellscreen:mousepressed(x,y,button)
  local playerSpells = player:get_spells()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale,y/uiScale
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then self:switchBack() end
  if x > self.x and x < self.sidebarX-(self.scrollPositions and self.padding or 0) then
    for index,coords in ipairs(self.spellLines) do
      if y+self.scrollY > coords.minY and y+self.scrollY < coords.maxY then
        self:select_spell(index)
      end
    end
  end
  if self.cursorX > 1 and x > self.sidebarX then --if a spell is selected
    if self.buttons.use and x > self.buttons.use.minX and x < self.buttons.use.maxX and y > self.buttons.use.minY and y < self.buttons.use.maxY then
      return self:cast_spell(self.cursorY)
    elseif self.buttons.hotkey and x > self.buttons.hotkey.minX and x < self.buttons.hotkey.maxX and y > self.buttons.hotkey.minY and y < self.buttons.hotkey.maxY then
      return Gamestate.switch(hotkey,playerSpells[self.cursorY])
      elseif self.buttons.forget and x > self.buttons.forget.minX and x < self.buttons.forget.maxX and y > self.buttons.forget.minY and y < self.buttons.forget.maxY then
      return self:forget_spell(self.cursorY)
    end
    for index,button in ipairs(self.upgradeButtons) do
      if x > button.minX and x < button.maxX and y+self.descScrollY > button.minY and y+self.descScrollY < button.maxY then
        self:perform_upgrade(button.upgradeID)
      end
    end
  end
end

function spellscreen:wheelmoved(x,y)
  local uiScale = prefs['uiScale']
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  if y > 0 then
    if mouseX < self.sidebarX then
      self:scrollUp()
    else
      self:descScrollUp()
    end
	elseif y < 0 then
    if mouseX < self.sidebarX then
      self:scrollDown()
    else
      self:descScrollDown()
    end
  end --end button type if
end

function spellscreen:scrollUp()
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
  end
end

function spellscreen:scrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
    end
  end
end

function spellscreen:descScrollUp()
  if self.descScrollY > 0 then
    self.descScrollY = self.descScrollY - prefs.fontSize
    if self.descScrollY < prefs.fontSize then
      self.descScrollY = 0
    end
  end
end

function spellscreen:descScrollDown()
  if self.descScrollMax and self.descScrollY < self.descScrollMax then
    self.descScrollY = self.descScrollY+prefs.fontSize
    if self.descScrollMax-self.descScrollY < prefs.fontSize then
      self.descScrollY = self.descScrollMax
    end
  end
end

function spellscreen:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
  local playerSpells = player:get_spells()
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale, y/uiScale
  if (love.mouse.isDown(1)) then
    if self.scrollPositions then
      local upArrow = self.scrollPositions.upArrow
      local downArrow = self.scrollPositions.downArrow
      local elevator = self.scrollPositions.elevator
      if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
        self:scrollUp()
      elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
        self:scrollDown()
      elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
        if y<elevator.startY then self:scrollUp()
        elseif y>elevator.endY then self:scrollDown() end
      end --end clicking on arrow
    end
    if self.descScrollPositions then
      local upArrow = self.descScrollPositions.upArrow
      local downArrow = self.descScrollPositions.downArrow
      local elevator = self.descScrollPositions.elevator
      if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
        self:descScrollUp()
      elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
        self:descScrollDown()
      elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
        if y<elevator.startY then self:descScrollUp()
        elseif y>elevator.endY then self:descScrollDown() end
      end --end clicking on arrow
    end
  end
end

function spellscreen:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function spellscreen:cast_spell(spellIndex)
  local playerSpells = player:get_spells()
  local spell = playerSpells[spellIndex] or playerSpells[self.cursorY]
  if(spell:target(target,player) ~= false) then
    advance_turn()
  end
  self:switchBack()
end

function spellscreen:select_spell(spellIndex)
  self.cursorY = spellIndex
  self.cursorX = 2
  self.sidebarCursorY=1
  self.upgradeButtons = {}
  self.descScrollY = 0
end

function spellscreen:perform_upgrade(upgradeID)
  local spell = self.playerSpells[self.cursorY]
  if not spell or not spell.possible_upgrades or not spell.possible_upgrades[upgradeID] then
    return false
  end
  if spell:apply_upgrade(upgradeID) then
    self.upgradeButtons = {}
    return true
  end
end

function spellscreen:forget_spell(spellIndex)
  local playerSpells = player:get_spells()
  local spell = playerSpells[spellIndex] or playerSpells[self.cursorY]
  player:forget_spell(spell.id)
  self.playerSpells = player:get_spells()
  self.cursorX = 1
end