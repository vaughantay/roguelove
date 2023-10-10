spellscreen = {}

function spellscreen:enter(previous,locked)
  if locked == nil then
    locked = gamesettings.spells_locked_by_default
  end
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
  self.locked = locked
  self.unmemorized = player:get_unmemorized_spells()
  self.buttons = {}
  self.upgradeButtons = {}
  self.settingsButtons = {}
  self.buttonCount = 0
  
  self.yModPerc = 0
  if previous == game then
    self.yModPerc = 100
    tween(0.2,self,{yModPerc=0})
    output:sound('stoneslideshort',2)
  end
  self.spellList = {}
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
  if self.unmemorized and #self.unmemorized > 0 then
    love.graphics.printf("Memorized Spells",x+padX,printY,window1w-x-padX,"center")
    printY=printY+round(fontSize*1.5)
  end
	for i, spell in pairs(playerSpells) do
    local moused = (mouseX > printX and mouseX < window1w and mouseY+self.scrollY > printY and mouseY+self.scrollY < printY+fontSize+2)
    local spellID = spell.id
		spells[i] = spellID
    local name = spell.name
    local target_type = spell.target_type
    local active = spell.active
    local upgrade = ((spellPoints > 0 or spell.spellPoints > 0) and (count(spell:get_possible_upgrades()) > 0))
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
    self.spellList[i] = {minY=printY,maxY=printY+fontSize+2,spell=spell}
    printY = printY+fontSize+2
	end
  if self.unmemorized and #self.unmemorized > 0 then
    love.graphics.printf("Unmemorized Spells",x+padX,printY,window1w-x-padX,"center")
    printY=printY+round(fontSize*1.5)
    for i, spell in pairs(self.unmemorized) do
      local index = #playerSpells+i
      local moused = (mouseX > printX and mouseX < window1w and mouseY+self.scrollY > printY and mouseY+self.scrollY < printY+fontSize+2)
      local spellID = spell.id
      spells[index] = spellID
      local name = spell.name
      local target_type = spell.target_type
      local upgrade = (spellPoints > 0 and (count(spell:get_possible_upgrades()) > 0))
      --Draw the highlight box:
      if (self.cursorY == index) then
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
        mousedSpell = index
      end
      setColor(255,255,(upgrade and 0 or 255),255)
      local fullText = (spell.hotkey and spell.hotkey .. ") " or "") .. name .. (target_type == "passive" and " (Passive)" or "") .. (active and " (Active)" or "") .. (upgrade and " (+)" or "")
      love.graphics.print(fullText,x+padX,printY)
      setColor(255,255,255,255)
      line = line+1
      self.spellList[index] = {minY=printY,maxY=printY+fontSize+2,spell=spell}
      printY = printY+fontSize+2
    end
  end
  bottom = printY
  
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  --Description Box:
  local spellEntry = (self.spellList[self.cursorY] or self.spellList[mousedSpell])
  self.buttons = {}
  self.upgradebuttons = {}
  if spellEntry ~= nil then
    local spell = spellEntry.spell
    love.graphics.push()
    --Draw the actual spell info:
    local target_type = spell.target_type
    local spellText = spell:get_description()
    local printY = padding
    local printX = sidebarX+padX
    local hotkey = spell.hotkey
    local selected = (self.cursorX ~= 1)
    local memorized = player:has_spell(spell.id,true)
    
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
    self.buttonCount = 0
    if not selected then
      setColor(175,175,175,255)
    end

    if memorized and spell.target_type ~= "passive" then
      self.buttonCount = self.buttonCount + 1
      local useText = ((spell.active and not spell.no_manual_deactivate) and "Stop" or "Use")
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if player.cooldowns[spell.name] or spell:requires(player) == false or (spell.active and spell.no_manual_deactivate) then
        setColor(100,100,100,255)
      end
      self.buttons.use = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == self.buttonCount and "hover" or nil),useText,true)
      self.buttons.use.buttonNum = self.buttonCount
      if player.cooldowns[spell.name] or spell:requires(player) == false or (spell.active and spell.no_manual_deactivate) then
        if selected then setColor(255,255,255,255)
        else setColor(175,175,175,255) end
      end
      printY = printY+buttonHeight
      self.buttonCount = self.buttonCount + 1
      local hotkeyText = (hotkey and "Change Hotkey" or "Assign Hotkey")
      buttonWidth = fonts.buttonFont:getWidth(hotkeyText)+25
      self.buttons.hotkey = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == self.buttonCount and "hover" or nil),hotkeyText,true)
      self.buttons.hotkey.buttonNum = self.buttonCount
      printY = printY+buttonHeight
    end
    
    if not self.locked then
      if memorized and (spell.forgettable or (gamesettings.spells_forgettable_by_default and spell.forgettable ~= false)) then
        self.buttonCount = self.buttonCount + 1
        local forgetText = "Forget"
        local buttonWidth = fonts.buttonFont:getWidth(forgetText)+25
        self.buttons.forget = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == self.buttonCount and "hover" or nil),forgetText,true)
        self.buttons.forget.buttonNum = self.buttonCount
        printY = printY+buttonHeight
      elseif not memorized then
        self.buttonCount = self.buttonCount + 1
        local memText = "Memorize"
        local buttonWidth = fonts.buttonFont:getWidth(memText)+25
        if not spell.freeSlot and (spellSlots and spellSlots < 1) then
          setColor(100,100,100,255)
        end
        self.buttons.memorize = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == self.buttonCount and "hover" or nil),memText,true)
        self.buttons.memorize.buttonNum = self.buttonCount
        if not spell.freeSlot and (spellSlots and spellSlots < 1) then
          setColor(255,255,255,255)
        end
        printY = printY+buttonHeight
      end
    end
    
    if not selected then
      setColor(255,255,255,255)
    end
    
    self.descStartY=printY
    printY=printY+fontSize
    --Stencil and scroll:
    local function stencilFunc()
      love.graphics.rectangle("fill",printX-8,self.descStartY,window2w+8,height-padY-self.descStartY)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.descScrollY)
    
    --Settings
    local settingH = output:get_tile_size(true)
    local settings = spell:get_all_settings()
    --sort_table(settings,'name')
    if count(settings) > 0 then
      local buttonY=0
      love.graphics.printf("Settings:",printX,printY,window2w,"left")
      printY=printY+settingH
      for settingID,info in pairs(settings) do
        self.buttonCount = self.buttonCount+1
        buttonY = buttonY+1
        local boxW = (prefs['noImages'] and fonts.textFont:getWidth("(Y)") or output:get_tile_size(true))
        local button = self.settingsButtons[buttonY]
        if self.sidebarCursorY == self.buttonCount or (button and mouseX > button.minX and mouseX < button.maxX and mouseY > button.minY and mouseY < button.maxY) then
          setColor(100,100,100,255)
          love.graphics.rectangle('fill',printX-8,printY-8,boxW,settingH)
          setColor(255,255,255,255)
        end
        if prefs['noImages'] then
          love.graphics.print((info.enabled and "(Y)" or "(N)"),printX,printY)
        else
          love.graphics.draw((info.enabled and images.uicheckboxchecked or images.uicheckbox),printX,printY)
        end
        local setText = info.name .. (info.description and " (" .. info.description .. ")" or "")
        love.graphics.printf(setText,printX+boxW,printY,window2w,"left")
        local _, slines = fonts.textFont:getWrap(setText,window2w)
        local sHeight = #slines*settingH
        self.settingsButtons[buttonY] = {minX=printX-8,minY=printY-8,maxX=printX+32-8,maxY=printY+settingH-8}
        self.settingsButtons[buttonY].settingID = settingID
        printY = printY+sHeight
      end
    end
    
    --Print stats
    local statText = spell:get_info()
    
    love.graphics.printf(statText,printX,printY,window2w,"left")
    local _, slines = fonts.textFont:getWrap(statText,window2w)
    local sHeight = (#slines+1)*fontSize
    printY = printY+sHeight
    
    --Print upgrades
    if spell.possible_upgrades then
      local upgrades = spell:get_possible_upgrades()
      if count(upgrades) > 0 then
        love.graphics.printf("Upgrades:",printX,printY,window2w,"left")
        local upgrade_stat = spell.upgrade_stat or "spellPoints"
        local upgrade_stat_name = (upgrade_stat == "spellPoints" and "Ability Point" or false)
        local points_available = player[upgrade_stat] or 0
        if not upgrade_stat_name then
          for _,stInfo in pairs(possibleSkillTypes) do
            if stInfo.upgrade_stat == upgrade_stat then
              upgrade_stat_name = stInfo.upgrade_stat_name
              break
            end
          end
          if not upgrade_stat_name then upgrade_stat_name = upgrade_stat end
        end
        if spell.free_upgrades > 0 then
          printY=printY+fontSize
          love.graphics.printf(spell.free_upgrades .. " Free Upgrade" .. (spell.free_upgrades > 1 and "s available" or " available"),printX,printY,window2w,"left")
        end
        printY=printY+fontSize
        love.graphics.printf(points_available .. " " .. upgrade_stat_name .. (points_available > 1 and "s available" or " available"),printX,printY,window2w,"left")
        if spell.spellPoints > 0 then
          printY=printY+fontSize
          love.graphics.printf(spell.spellPoints .. " " .. upgrade_stat_name .. (spell.spellPoints > 1 and "s" or "") .. " available specifically for this ability",printX,printY,window2w,"left")
        end
        printY=printY+fontSize+5
        local buttonY = 1
        local mod = self.buttonCount
        local upDesc,upY = nil,nil
        --Sort alphabetically:
        local sorted = {}
        for id,level in pairs(upgrades) do
          sorted[#sorted+1] = {id=id,level=level,name=(spell.possible_upgrades[id].name or id)}
        end
        sort_table(sorted,'name')
        for _,info in ipairs(sorted) do
          local id = info.id
          local level = upgrades[id]
          if self.sidebarCursorY==buttonY+mod and printY-self.descScrollY < self.descStartY then
            self:descScrollUp()
          end
          local canUpgrade,noText = spell:can_upgrade(id)
          if not canUpgrade then
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
          local cost = spell:get_upgrade_cost(id)
          local name = (level_details.name or details.name or ucfirst(id))
          local description = (level_details.description or details.description or nil)
          local i = 1
          local point_cost = cost.point_cost
          local statText = ""
          for stat,amt in pairs(level_details) do
            if type(amt) ~= "boolean" and type(amt) ~= "table" and stat ~= "point_cost" and stat ~= "item_cost" then
              local statName = (spell.stats and spell.stats[stat] and spell.stats[stat].name or ucfirst(stat))
              statName = string.gsub(statName,'_',' ')
              statText = statText .. "\n\t" .. statName .. (type(amt) == "number" and (amt < 0 and " " or " +") or ": ") .. amt .. (spell.stats and spell.stats[stat] and spell.stats[stat].is_percentage and "%" or "")
            end
          end --end stat for
          local costText = ""
          if point_cost > 0 or cost.item_cost then
            costText = " - Cost: "
            local firstCost = true
            if point_cost > 0 then
              costText = costText .. point_cost .. " " .. upgrade_stat_name .. (point_cost > 1 and "s" or "")
              firstCost = false
            end
            if cost.item_cost then
              for _,item_details in pairs(cost.item_cost) do
                local amount = item_details.amount or 1
                local sortByVal = item_details.sortBy
                local _,_,has_amt = player:has_item(item_details.item,sortByVal)
                local name = item_details.displayName or (amount > 1 and possibleItems[item_details.item].pluralName or possibleItems[item_details.item].name)
                costText = costText .. (firstCost == false and ", " or "") .. amount .. " " .. name .. " (You have " .. has_amt .. ")"
                firstCost = false
              end --end item cost for
            end --end item cost if
          end
          local upText = name .. costText .. (description and "\n" .. description or "") .. (noText and "\n(" .. noText  .. ")" or "") .. statText
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

function spellscreen:buttonpressed(key)
  local uiScale = prefs['uiScale']
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  width,height = round(width/uiScale),round(height/uiScale)
  key = input:parse_key(key)
	if (key == "escape") then
    if self.cursorX == 1 then
      self:switchBack()
    else
      self.cursorX = 1
    end
	elseif (key == "enter") or key == "wait" then
    if self.cursorX == 1 and self.spellList[self.cursorY] then
      self:select_spell(self.cursorY)
    elseif self.cursorX == 2 then
      local spell = self.spellList[self.cursorY].spell
      --sidebarCursorY
      if self.buttons.memorize and self.sidebarCursorY == self.buttons.memorize.buttonNum then
        return self:memorize_spell(self.cursorY)
      elseif self.buttons.forget and self.sidebarCursorY == self.buttons.forget.buttonNum then
        return self:unmemorize_spell(self.cursorY)
      elseif self.buttons.use and self.sidebarCursorY == self.buttons.use.buttonNum then
        return self:cast_spell(self.cursorY)
      elseif self.buttons.hotkey and self.sidebarCursorY == self.buttons.hotkey.buttonNum then
        return Gamestate.switch(hotkey,spell)
      end
      if self.settingsButtons then
        for index,button in ipairs(self.settingsButtons) do
          local mod = count(self.buttons)
          if self.sidebarCursorY == index+mod then
            self:toggle_setting(button.settingID)
            return
          end
        end
      end
      if self.upgradeButtons then
        for index,button in ipairs(self.upgradeButtons) do
          local mod = count(self.buttons)+(self.settingsButtons and #self.settingsButtons or 0)
          if self.sidebarCursorY == index+mod then
            self:perform_upgrade(button.upgradeID)
            return
          end
        end
      end
    end
	elseif (key == "north") then
    if self.cursorX == 1 then
      if (self.spellList[self.cursorY-1] ~= nil) then
        self.cursorY = self.cursorY - 1
        self.descScrollY = 0
        self.upgradeButtons = {}
      end
      if self.spellList[self.cursorY] and self.spellList[self.cursorY].minY-self.scrollY-prefs['fontSize'] < self.startY then
        self:scrollUp()
      end
    else --if a spell is selected
      self.sidebarCursorY = math.max(self.sidebarCursorY-1,1)
      local topButtonCount = count(self.buttons)
      local settingsButtons = (self.settingsButtons and #self.settingsButtons or 0)
      if self.sidebarCursorY <= topButtonCount then
        self.descScrollY = 0
      elseif self.settingsButtons[self.sidebarCursorY-topButtonCount] then
        while self.settingsButtons[self.sidebarCursorY-topButtonCount].minY-self.descScrollY < self.descStartY do
          self:descScrollUp()
        end
      elseif self.upgradeButtons[self.sidebarCursorY-topButtonCount-settingsButtons] then
        while self.upgradeButtons[self.sidebarCursorY-topButtonCount-settingsButtons].minY-self.descScrollY < self.descStartY do
          self:descScrollUp()
        end
      end
    end
	elseif (key == "south") then
    if self.cursorX == 1 then
      if (self.spellList[self.cursorY+1] ~= nil) then
        self.cursorY = self.cursorY + 1
        self.descScrollY = 0
        self.upgradeButtons = {}
      end
      if self.spellList[self.cursorY].maxY-self.scrollY+prefs['fontSize'] >= round(love.graphics.getHeight()/uiScale)-32 and self.scrollY < self.scrollMax then
        self:scrollDown()
      end
    else -- if a spell is selected
      local topButtonCount = count(self.buttons)
      local settingsButtons = (self.settingsButtons and #self.settingsButtons or 0)
      local upgradeButtons = (self.upgradeButtons and #self.upgradeButtons or 0)
      local max = upgradeButtons+settingsButtons+topButtonCount
      if self.sidebarCursorY < max then
        self.sidebarCursorY = self.sidebarCursorY+1
      end
      if self.settingsButtons[self.sidebarCursorY-topButtonCount] then
        while self.settingsButtons[self.sidebarCursorY-topButtonCount].maxY-self.descScrollY > height-self.padY do
          self:descScrollDown()
        end
      elseif self.upgradeButtons[self.sidebarCursorY-topButtonCount-settingsButtons] then
        while self.upgradeButtons[self.sidebarCursorY-topButtonCount-settingsButtons].textMaxY-self.descScrollY > height-self.padY do
          self:descScrollDown()
        end
      end
    end
  elseif (key == "east") then
    if self.spellList[self.cursorY] then self:select_spell(self.cursorY) end
  elseif (key == "west") then
    self.cursorX = 1
	end
end

function spellscreen:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale,y/uiScale
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then self:switchBack() end
  if x > self.x and x < self.sidebarX-(self.scrollPositions and self.padding or 0) then
    self.cursorX = 1 --if a spell is selected, unselect it
    for index,coords in ipairs(self.spellList) do
      if y+self.scrollY > coords.minY and y+self.scrollY < coords.maxY then
        self:select_spell(index)
      end
    end
  end
  if x > self.sidebarX then
    if self.spellList[self.cursorY] then
      self.cursorX = 2
    end
    if self.cursorX > 1 then --if a spell is selected
      if self.buttons.memorize and x > self.buttons.memorize.minX and x < self.buttons.memorize.maxX and y > self.buttons.memorize.minY and y < self.buttons.memorize.maxY then
        return self:memorize_spell(self.cursorY)
      elseif self.buttons.forget and x > self.buttons.forget.minX and x < self.buttons.forget.maxX and y > self.buttons.forget.minY and y < self.buttons.forget.maxY then
        return self:unmemorize_spell(self.cursorY)
      elseif self.buttons.use and x > self.buttons.use.minX and x < self.buttons.use.maxX and y > self.buttons.use.minY and y < self.buttons.use.maxY then
        return self:cast_spell(self.cursorY)
      elseif self.buttons.hotkey and x > self.buttons.hotkey.minX and x < self.buttons.hotkey.maxX and y > self.buttons.hotkey.minY and y < self.buttons.hotkey.maxY then
        return Gamestate.switch(hotkey,self.spellList[self.cursorY].spell)
      end
      for index,button in ipairs(self.settingsButtons) do
        if x > button.minX and x < button.maxX and y+self.descScrollY > button.minY and y+self.descScrollY < button.maxY then
          return self:toggle_setting(button.settingID)
        end
      end
      for index,button in ipairs(self.upgradeButtons) do
        if x > button.minX and x < button.maxX and y+self.descScrollY > button.minY and y+self.descScrollY < button.maxY then
          return self:perform_upgrade(button.upgradeID)
        end
      end
    end --end if cursorX > 1
  end --end if x > sidebar X
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
  local spell = self.spellList[spellIndex].spell
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
  local spell = self.spellList[self.cursorY].spell
  if not spell or not spell.possible_upgrades or not spell.possible_upgrades[upgradeID] then
    return false
  end
  if spell:apply_upgrade(upgradeID) then
    self.upgradeButtons = {}
    return true
  end
end

function spellscreen:unmemorize_spell(spellIndex)
  local spell = self.spellList[spellIndex].spell
  player:unmemorize_spell(spell)
  self.playerSpells = player:get_spells()
  self.unmemorized = player:get_unmemorized_spells()
  self.spellList = {}
  self.cursorX = 1
end

function spellscreen:memorize_spell(spellIndex)
  local spell = self.spellList[spellIndex].spell
  if spell then
    player:memorize_spell(spell)
    self.playerSpells = player:get_spells()
    self.unmemorized = player:get_unmemorized_spells()
    self.spellList = {}
    self.cursorX = 1
  end
end

function spellscreen:toggle_setting(settingID)
  local spell = self.spellList[self.cursorY].spell
  if not spell or not spell:setting_available(settingID) then
    return false
  end
  if spell:toggle_setting(settingID) then
    return true
  end
end