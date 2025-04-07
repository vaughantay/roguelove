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
  self.itemButtons = {}
  self.buttonCount = 0
  self.ignoreMouse = true
  
  self.yModPerc = 0
  if previous == game or previous == loadout or previous == multiselect  then
    self.yModPerc = 100
    tween(0.2,self,{yModPerc=0})
    output:sound('stoneslideshort',2)
  end
  self.previous = previous
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
  local fontSize = fonts.textFont:getHeight()
  local headerSize = fonts.headerFont:getHeight()
  local tileSize = output:get_tile_size()
  local lineSize = math.max(fontSize,tileSize)
  local padYtext = math.ceil((lineSize-fontSize)/2)
	
  self.screenMax = round(height/(fontSize+2)/2)
  local padding = self.padding
	love.graphics.setFont(fonts.textFont)
  local sidebarX = self.sidebarX
  local window1w = sidebarX-padding-padX
  local window2w = width-sidebarX-padX*2
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  
  love.graphics.setFont(fonts.headerFont)
  love.graphics.printf("Spells and Abilities",padding,padding,window1w,"center")
  love.graphics.setFont(fonts.textFont)
  local printY = padding+headerSize
  local printX = (prefs['noImages'] and 14 or 32)
  local spellPoints = (player.spellPoints or 0)
  local spellSlots = player:get_free_spell_slots()
  if spellPoints > 0 then
    love.graphics.printf(spellPoints .. " ability point" .. (spellPoints == 1 and " available" or "s available"),padding,printY,window1w,"center")
    printY = printY+fontSize
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
  local slotcount = 0
  if self.unmemorized and #self.unmemorized > 0 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Memorized Spells",x+padX,printY,window1w-x-padX,"center")
    love.graphics.setFont(fonts.textFont)
    printY=printY+headerSize
  end
	for i, spell in ipairs(playerSpells) do
    local moused = not self.ignoreMouse and (mouseX > printX and mouseX < window1w and mouseY+self.scrollY > printY and mouseY+self.scrollY < printY+lineSize+2)
    local spellID = spell.id
		spells[i] = spellID
    local name = spell.name
    local target_type = spell.target_type
    local active = spell.active
    local item = spell.from_item
    local upgrade = not item and (count(spell:get_possible_upgrades(true)) > 0)
    --Draw the highlight box:
    if (self.cursorY == i) then
      if self.cursorX == 2 then
        setColor(125,125,125,255)
      else
        setColor(100,100,100,255)
      end
      love.graphics.rectangle("fill",x+padX,printY,window1w-padX*2,lineSize+2)
      setColor(255,255,255,255)
    elseif moused then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",x+padX,printY,window1w-padX*2,lineSize+2)
      setColor(255,255,255,255)
      mousedSpell = i
    end
    local textColor = {r=255,g=255,b=255,a=255}
    if player.cooldowns[spell] or spell:requires(player) == false or (spell.charges and spell.charges < 1) then
      if moused or self.cursorY == i then
        textColor.r, textColor.g, textColor.b = (active and (upgrade and 12 or 0) or 25), 25, (upgrade and 0 or (active and 0 or 25))
      else
        textColor.r, textColor.g, textColor.b = (active and (upgrade and 50 or 0) or 100), 100, (upgrade and 0 or (active and 0 or 100))
      end
    else
      textColor.r, textColor.g, textColor.b = (active and (upgrade and 200 or 100) or 255), 255, (upgrade and 0 or (active and 100 or 255))
    end --end cooldowns if
    if not spell.freeSlot then
      slotcount = slotcount + 1
    end
    local num = (spell.freeSlot and "-) " or slotcount .. ") ")
    local thisPadX = fonts.textFont:getWidth(num)
    setColor(textColor.r,textColor.g,textColor.b,textColor.a)
    love.graphics.print(num,x+padX,printY+padYtext)
    if spell and images['spell' .. (spell.image_name or spell.id)] then
      if spell.color then
        setColor(spell.color.r,spell.color.g,spell.color.b,spell.color.a)
      end
      love.graphics.draw(images['spell' .. (spell.image_name or spell.id)],x+padX+thisPadX,printY)
      thisPadX = thisPadX + tileSize+2
    end
    setColor(textColor.r,textColor.g,textColor.b,textColor.a)
    local spellText = name .. (player.cooldowns[spell] and " (" .. player.cooldowns[spell] .. " turns to recharge)" or "") .. (target_type == "passive" and " (Passive)" or "") .. (active and " (Active)" or "") .. (upgrade and " (+)" or "")
		love.graphics.print(spellText,x+padX+thisPadX,printY+padYtext)
    setColor(255,255,255,255)
		line = line+1
    self.spellList[i] = {minY=printY,maxY=printY+lineSize+2,spell=spell}
    printY = printY+lineSize+2
	end
  if spellSlots and spellSlots > 0 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Free Slots",x+padX,printY,window1w-x-padX,"center")
    love.graphics.setFont(fonts.textFont)
    printY=printY+headerSize
    for i=1,spellSlots,1 do
      local slot = i+count(playerSpells)
      local moused = not self.ignoreMouse and (mouseX > printX and mouseX < window1w and mouseY+self.scrollY > printY and mouseY+self.scrollY < printY+lineSize+2)
      --Draw the highlight box:
      if (self.cursorY == slot) then
        setColor(100,100,100,255)
        love.graphics.rectangle("fill",x+padX,printY,window1w-padX*2,lineSize+2)
        setColor(255,255,255,255)
      elseif moused then
        setColor(100,100,100,125)
        love.graphics.rectangle("fill",x+padX,printY,window1w-padX*2,lineSize+2)
        setColor(255,255,255,255)
        mousedSpell = slot
      end
      slotcount = slotcount + 1
      local fullText = slotcount .. ") -"
      love.graphics.print(fullText,x+padX,printY+padYtext)
      setColor(255,255,255,255)
      line = line+1
      self.spellList[slot] = {minY=printY,maxY=printY+lineSize+2,spell=nil}
      printY = printY+lineSize+2
    end
  end
  if self.unmemorized and #self.unmemorized > 0 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Unmemorized Spells",x+padX,printY,window1w-x-padX,"center")
    love.graphics.setFont(fonts.textFont)
    printY=printY+headerSize
    for i, spell in pairs(self.unmemorized) do
      local index = #playerSpells+i+(spellSlots or 0)
      local moused = not self.ignoreMouse and (mouseX > printX and mouseX < window1w and mouseY+self.scrollY > printY and mouseY+self.scrollY < printY+lineSize+2)
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
        love.graphics.rectangle("fill",x+padX,printY,window1w-padX*2,lineSize+2)
        setColor(255,255,255,255)
      elseif moused then
        setColor(100,100,100,125)
        love.graphics.rectangle("fill",x+padX,printY,window1w-padX*2,lineSize+2)
        setColor(255,255,255,255)
        mousedSpell = index
      end
      setColor(255,255,(upgrade and 0 or 255),255)
      local fullText = name .. (target_type == "passive" and " (Passive)" or "") .. (upgrade and " (+)" or "")
      local thisPadX = 0
      if spell and images['spell' .. (spell.image_name or spell.id)] then
        if spell.color then
          setColor(spell.color.r,spell.color.g,spell.color.b,spell.color.a)
        end
        love.graphics.draw(images['spell' .. (spell.image_name or spell.id)],x+padX+thisPadX,printY)
        thisPadX = thisPadX + tileSize+2
        setColor(255,255,255,255)
      end
      love.graphics.print(fullText,x+padX+thisPadX,printY+padYtext)
      setColor(255,255,255,255)
      line = line+1
      self.spellList[index] = {minY=printY,maxY=printY+lineSize+2,spell=spell}
      printY = printY+lineSize+2
    end
  end
  bottom = printY
  
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  --Description Box:
  local spellEntry = (self.spellList[self.cursorY] or self.spellList[mousedSpell])
  if spellEntry ~= nil and spellEntry.spell then
    local spell = spellEntry.spell
    love.graphics.push()
    --Draw the actual spell info:
    local target_type = spell.target_type
    local spellText = spell:get_description()
    local printY = padding
    local printX = sidebarX+padX
    local hotkey = spell.hotkey
    local selected = (self.cursorX ~= 1)
    local memorized = player:has_spell(spell.id)
    local item = spell.from_item
    
    if item then
      spellText = spellText .. "\n\nGranted by " .. item:get_name(true) .. "."
    end
    
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
    if spell.level then
      love.graphics.printf("Level " .. spell.level,printX,printY,window2w,"center")
      printY=printY+fontSize+2
    end
    if spell.arcana then
      local arcText = ""
      for i,arc in ipairs(spell.arcana) do
        if i > 1 then
          arcText = arcText .. ", "
        end
        local arcInfo = arcana_list[arc]
        arcText = arcText .. ucfirst((arcInfo.name or arc))
      end
      love.graphics.printf(arcText,printX,printY,window2w,"center")
      printY=printY+fontSize+2
    end
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
      if player.cooldowns[spell] or spell:requires(player) == false or (spell.active and spell.no_manual_deactivate) or (spell.charges and spell.charges < 1) then
        setColor(100,100,100,255)
      end
      self.buttons.use = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == self.buttonCount and "hover" or nil),useText,true)
      self.buttons.use.buttonNum = self.buttonCount
      if player.cooldowns[spell] or spell:requires(player) == false or (spell.active and spell.no_manual_deactivate) or (spell.charges and spell.charges < 1)  then
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
      if memorized and not item and (spell.forgettable or (gamesettings.spells_forgettable_by_default and spell.forgettable ~= false)) then
        self.buttonCount = self.buttonCount + 1
        local forgetText = "Unmemorize"
        local buttonWidth = fonts.buttonFont:getWidth(forgetText)+25
        self.buttons.forget = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == self.buttonCount and "hover" or nil),forgetText,true)
        self.buttons.forget.buttonNum = self.buttonCount
        printY = printY+buttonHeight
      elseif not memorized and not item then
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
    self.descStartY=printY+2
    love.graphics.line(printX,self.descStartY,printX+window2w,self.descStartY)
    printY=printY+fontSize
    local scrollPad = (self.descScrollMax == 0 and 0 or output:get_tile_size())
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
      love.graphics.setFont(fonts.headerFont)
      love.graphics.printf("Settings:",printX,printY,window2w,"left")
      love.graphics.setFont(fonts.textFont)
      printY=printY+headerSize
      for settingID,info in pairs(settings) do
        self.buttonCount = self.buttonCount+1
        buttonY = buttonY+1
        local boxW = (prefs['noImages'] and fonts.textFont:getWidth("(Y)") or output:get_tile_size(true))
        local button = self.settingsButtons[buttonY]
        if self.sidebarCursorY == self.buttonCount or (not self.ignoreMouse and button and mouseX > button.minX and mouseX < button.maxX and mouseY > button.minY and mouseY < button.maxY) then
          setColor(100,100,100,255)
          love.graphics.rectangle('fill',printX-8,printY-8,boxW,settingH)
          setColor(255,255,255,255)
        end
        if prefs['noImages'] then
          love.graphics.print((info.enabled and "(Y)" or "(N)"),printX,printY)
        else
          setColor(0,255,255,255)
          love.graphics.draw((info.enabled and images.uicheckboxchecked or images.uicheckbox),printX,printY)
          setColor(255,255,255,255)
        end
        local setText = info.name .. (info.description and " (" .. info.description .. ")" or "")
        love.graphics.printf(setText,printX+boxW,printY,window2w-scrollPad,"left")
        local _, slines = fonts.textFont:getWrap(setText,window2w-scrollPad)
        local sHeight = #slines*settingH
        self.settingsButtons[buttonY] = {minX=printX-8,minY=printY-8,maxX=printX+32-8,maxY=printY+settingH-8}
        self.settingsButtons[buttonY].settingID = settingID
        printY = printY+sHeight
      end
    end
    
    --Print stats
    local statText = spell:get_info()
    
    love.graphics.printf(statText,printX,printY,window2w-scrollPad,"left")
    local _, slines = fonts.textFont:getWrap(statText,window2w-scrollPad)
    local sHeight = (statText == "" and 0 or #slines*fontSize)
    printY = printY+sHeight
    
    --Print upgrades
    local upgrade_stat = spell.upgrade_stat or "spellPoints"
    local upgrade_stat_name = (upgrade_stat == "spellPoints" and gamesettings.default_spell_upgrade_stat_name or false)
    if spell.possible_upgrades and not item and not player.oldBody then
      local upgrades = spell:get_possible_upgrades()
      if count(upgrades) > 0 then
        love.graphics.setFont(fonts.headerFont)
        love.graphics.printf("Upgrades:",printX,printY,window2w-scrollPad,"left")
        love.graphics.setFont(fonts.textFont)
        printY=printY+headerSize
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
        if not upgrade_stat_name then upgrade_stat_name = "Point" end
        if spell.free_upgrades > 0 then
          love.graphics.printf(spell.free_upgrades .. " Free Upgrade" .. (spell.free_upgrades > 1 and "s available" or " available"),printX,printY,window2w-scrollPad,"left")
          printY=printY+fontSize
        end
        if points_available > 0 then
          love.graphics.printf(points_available .. " " .. upgrade_stat_name .. (points_available > 1 and "s available" or " available"),printX,printY,window2w-scrollPad,"left")
          printY=printY+fontSize
        end
        if spell.spellPoints > 0 then
          love.graphics.printf(spell.spellPoints .. " " .. upgrade_stat_name .. (spell.spellPoints > 1 and "s" or "") .. " available for this ability",printX,printY,window2w-scrollPad,"left")
          printY=printY+fontSize
        end
        if self.locked then
          local explainText = "(You can upgrade your spells from the desk in your tower.)"
          local _,elines = fonts.textFont:getWrap(explainText,window2w-scrollPad)
          love.graphics.printf(explainText,printX,printY,window2w-scrollPad,"left")
          printY = printY+fontSize*#elines
        end
        local buttonY = 0
        local mod = self.buttonCount
        --Sort alphabetically:
        local sorted = {}
        for id,level in pairs(upgrades) do
          sorted[#sorted+1] = {id=id,level=level,name=(spell.possible_upgrades[id].name or id)}
        end
        sort_table(sorted,'name')
        for _,info in ipairs(sorted) do
          buttonY=buttonY+1
          self.buttonCount = self.buttonCount + 1
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
          if not self.ignoreMouse and self.upgradeButtons[buttonY] and mouseX > self.upgradeButtons[buttonY].minX and mouseX < self.upgradeButtons[buttonY].maxX and mouseY > self.upgradeButtons[buttonY].minY-self.descScrollY and mouseY < self.upgradeButtons[buttonY].maxY-self.descScrollY then
            mouseOver = true
          end
          if self.locked then
            setColor(100,100,100,255)
          end
          self.upgradeButtons[buttonY] = output:tinybutton(printX,printY+1,true,((mouseOver or self.sidebarCursorY==buttonY+mod) and "hover" or false),"+",true)
          self.upgradeButtons[buttonY].upgradeID = id
          if self.locked then
            self.upgradeButtons[buttonY].disabled = true
          end
          setColor(255,255,255,255)
          local buttonW = 34
          local details = spell.possible_upgrades[id]
          local level_details = spell.possible_upgrades[id][level]
          local cost = spell:get_upgrade_cost(id)
          local name = (level_details.name or details.name or ucfirst(id))
          name = string.gsub(name,'_',' ')
          local description = (level_details.description or details.description or nil)
          local i = 1
          local point_cost = cost.point_cost
          local statText = ""
          for stat,amt in pairs(level_details) do
            if type(amt) ~= "boolean" and type(amt) ~= "table" and stat ~= "point_cost" and stat ~= "item_cost" then
              local statName = (spell.stats and spell.stats[stat] and spell.stats[stat].name or ucfirst(stat))
              statName = string.gsub(statName,'_',' ')
              statText = statText .. "\n\t" .. statName .. (type(amt) == "number" and (amt < 0 and " " or " +") or ": ") .. amt .. (spell.stats and spell.stats[stat] and spell.stats[stat].is_percentage and "%" or "")
            elseif stat == "stat_cost" then
              for statID,cost in pairs(amt) do
                local name = (self.possessor and self.possessor.extra_stats[statID].name or ucfirst(statID))
                statText = statText .. "\n\t" .. name .. " Cost: " .. (cost > 0 and "+" or "" ) .. cost .. "\n"
              end
            elseif stat == "items_consumed" then
              for itemID,cost in pairs(amt) do
                local name = ucfirst(possibleItems[itemID].name)
                statText = statText .. "\n\t" .. name .. " Cost: " .. (cost > 0 and "+" or "" ) .. cost .. "\n"
              end
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
                costText = costText .. (firstCost == false and ", " or "") .. amount .. " " .. name .. " (have " .. has_amt .. ")"
                firstCost = false
              end --end item cost for
            end --end item cost if
          end
          local upText = name .. costText .. (description and "\n" .. description or "") .. (noText and "\n(" .. noText  .. ")" or "") .. statText
          love.graphics.printf(upText,printX+buttonW,printY,window2w-padding-scrollPad,"left")
          local _, dlines = fonts.textFont:getWrap(upText,window2w-padding-scrollPad)
          local dHeight = (#dlines+1)*fontSize
          printY = printY+dHeight
          self.upgradeButtons[buttonY].textMaxY = printY
        end --end upgrade for
      end --end count upgrades > 0
    end --end if upgrades
    
    --Print appliable items:
    local items = spell:get_appliable_items(player)
    if items and #items > 0 and not item and not player.oldBody then
      local buttonY = 0
      local mod = self.buttonCount
      love.graphics.setFont(fonts.headerFont)
      love.graphics.printf("Apply Items:",printX,printY,window2w-scrollPad,"left")
      love.graphics.setFont(fonts.textFont)
      printY=printY+headerSize
      if self.locked then
        local explainText = "(You can apply items to your spells at the desk in your tower.)"
        local _,elines = fonts.textFont:getWrap(explainText,window2w-scrollPad)
        love.graphics.printf(explainText,printX,printY,window2w-scrollPad,"left")
        printY = printY+fontSize*#elines
      end
      for _,item_details in ipairs(items) do
        local amount_required = item_details.amount_required or 1
        local item
        local name
        local has_amt = 0
        if item_details.item then
          item = item_details.item
          name = item:get_name(true,amount_required)
          has_amt = item.amount
        else
          local sortByVal = item_details.sortBy
          local has_item,_,has_amt2 = player:has_item(item_details.itemID,sortByVal)
          if has_item then
            item = has_item
            name = item:get_name(true,amount_required)
            has_amt = has_amt2
          else
            name = (amount_required > 1 and amount_required .. " " or "") .. (item_details.displayName or (amount_required > 1 and possibleItems[item_details.itemID].pluralName or possibleItems[item_details.itemID].name))
          end
        end
        
        local costText = name .. " (have " .. has_amt .. ")"
        local modX = 32
        buttonY=buttonY+1
        self.buttonCount = self.buttonCount + 1
        local mouseOver = false
        if self.itemButtons[buttonY] and mouseX > self.itemButtons[buttonY].minX and mouseX < self.itemButtons[buttonY].maxX and mouseY > self.itemButtons[buttonY].minY-self.descScrollY and mouseY < self.itemButtons[buttonY].maxY-self.descScrollY then
          mouseOver = true
        end
        if has_amt < amount_required or self.locked then
          setColor(100,100,100,255)
        end
        self.itemButtons[buttonY] = output:tinybutton(printX,printY+padYtext,true,((mouseOver or self.sidebarCursorY==buttonY+mod) and "hover" or false),"+",true)
        setColor(255,255,255,255)
        self.itemButtons[buttonY].item = item
        self.itemButtons[buttonY].textMaxY = printY
        if has_amt < amount_required or self.locked then
          self.itemButtons[buttonY].disabled = true
        end
        if item then
          output.display_entity(item,printX+modX,printY,true,true,1)
        else
          local itemDef = possibleItems[item_details.itemID]
          local image_name = "item" .. (item_details.image_name or itemDef.image_name or item_details.itemID)
          if not images[image_name] then
            if images["itemdefault"] then
              image_name = "itemdefault"
            else
              image_name = false
            end
          end
          local color = item_details.color or itemDef.color or {r=255,g=255,b=255,a=255}
          setColor(color.r,color.g,color.b,color.a)
          if image_name then
            love.graphics.draw(images[image_name],printX+modX,printY)
          else
            love.graphics.setFont((prefs['noImages'] and fonts.mapFont or fonts.mapFontWithImages))
            love.graphics.print(itemDef.symbol,printX+modX,printY)
            love.graphics.setFont(fonts.textFont)
          end
        end
        setColor(255,255,255,255)
        love.graphics.printf(costText,printX+modX+tileSize,printY+padYtext,window2w-scrollPad,"left")
        printY=printY+fontSize
        if item_details.bonuses then
          local bonusText
          for bonus,amt in pairs(item_details.bonuses) do
            local bonusName = spell.stats and spell.stats[bonus] and spell.stats[bonus].name or bonus
            if bonusName == upgrade_stat then bonusName = upgrade_stat_name end
            bonusName = ucfirst(bonusName)
            bonusName = string.gsub(bonusName,'_',' ')
            bonusText = (bonusText and bonusText .. "\n\t" or "\t") .. bonusName .. ": " .. (amt > 0 and "+" or "") .. amt
          end
          love.graphics.printf(bonusText,printX+modX+tileSize,printY+padYtext,window2w-scrollPad,"left")
          local _,blines = fonts.textFont:getWrap(bonusText,window2w-padding-scrollPad)
          printY=printY+(#blines-1)*fontSize+lineSize
        end
      end
    end
    
    love.graphics.setFont(oldFont)
    love.graphics.setStencilTest()
    love.graphics.pop()
    
    --Scrollbars
    if printY > height-padding then
      self.descScrollMax = math.ceil((printY-(self.descStartY+(love.graphics:getHeight()/uiScale-self.descStartY))+padding))
      local scrollAmt = self.descScrollY/self.descScrollMax
      self.descScrollPositions = output:scrollbar(sidebarX+window2w,self.descStartY,height-padY,scrollAmt,true)
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

function spellscreen:buttonpressed(key,scancode,isRepeat,controllerType)
  self.ignoreMouse = true
  local uiScale = prefs['uiScale']
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  width,height = round(width/uiScale),round(height/uiScale)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
	if (key == "escape") or key == "spell" then
    if self.cursorX == 1 then
      self:switchBack()
    else
      self.cursorX = 1
    end
	elseif (key == "enter") or key == "wait" then
    if self.cursorX == 1 and self.spellList[self.cursorY] and self.spellList[self.cursorY].spell then
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
          if self.sidebarCursorY == index+mod and not button.disabled then
            self:perform_upgrade(button.upgradeID)
            return
          end
        end
      end
      if self.itemButtons then
        for index,button in ipairs(self.itemButtons) do
          local mod = count(self.buttons)+(self.settingsButtons and #self.settingsButtons or 0)+(self.upgradeButtons and #self.upgradeButtons or 0)
          if self.sidebarCursorY == index+mod and not button.disabled then
            self:apply_item(button.item)
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
        self.buttons = {}
        self.upgradeButtons = {}
        self.settingsButtons = {}
        self.itemButtons = {}
      end
      if self.spellList[self.cursorY] and self.spellList[self.cursorY].minY-self.scrollY-prefs['fontSize'] < self.startY then
        self:scrollUp()
      end
    else --if a spell is selected
      self.sidebarCursorY = math.max(self.sidebarCursorY-1,1)
      local topButtonCount = count(self.buttons)
      local settingsButtons = (self.settingsButtons and #self.settingsButtons or 0)
      local upgradeButtons = (self.upgradeButtons and #self.upgradeButtons or 0)
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
      elseif self.itemButtons[self.sidebarCursorY-topButtonCount-settingsButtons-upgradeButtons] then
        while self.itemButtons[self.sidebarCursorY-topButtonCount-settingsButtons-upgradeButtons].minY-self.descScrollY < self.descStartY do
          self:descScrollUp()
        end
      end
    end
	elseif (key == "south") then
    if self.cursorX == 1 then
      if (self.spellList[self.cursorY+1] ~= nil) then
        self.cursorY = self.cursorY + 1
        self.descScrollY = 0
        self.buttons = {}
        self.upgradeButtons = {}
        self.settingsButtons = {}
        self.itemButtons = {}
      end
      if self.spellList[self.cursorY] and self.spellList[self.cursorY].maxY-self.scrollY+prefs['fontSize'] >= round(love.graphics.getHeight()/uiScale)-32 and self.scrollY < self.scrollMax then
        self:scrollDown()
      end
    else -- if a spell is selected
      local topButtonCount = count(self.buttons)
      local settingsButtons = (self.settingsButtons and #self.settingsButtons or 0)
      local upgradeButtons = (self.upgradeButtons and #self.upgradeButtons or 0)
      local itemButtons = (self.itemButtons and #self.itemButtons or 0)
      local max = upgradeButtons+settingsButtons+itemButtons+topButtonCount
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
      elseif self.itemButtons[self.sidebarCursorY-topButtonCount-settingsButtons-upgradeButtons] then
        while self.itemButtons[self.sidebarCursorY-topButtonCount-settingsButtons-upgradeButtons].textMaxY-self.descScrollY > height-self.padY do
          self:descScrollDown()
        end
      end
    end
  elseif (key == "east") then
    if self.cursorX == 1 and self.spellList[self.cursorY] and self.spellList[self.cursorY].spell then self:select_spell(self.cursorY) end
  elseif (key == "west") then
    self.cursorX = 1
  elseif tonumber(key) then
    local num = tonumber(key)
    if num == 0 then num = 10 end
    if self.spellList[num] then
      self:select_spell(num)
    end
	end
end

function spellscreen:mousemoved()
  self.ignoreMouse = false
end

function spellscreen:mousepressed(x,y,button)
  self.ignoreMouse = false
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale,y/uiScale
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then self:switchBack() end
  if x > self.x and x < self.sidebarX-(self.scrollPositions and self.padding or 0) then
    for index,coords in ipairs(self.spellList) do
      if coords.spell and y+self.scrollY > coords.minY and y+self.scrollY < coords.maxY then
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
        if not button.disabled and x > button.minX and x < button.maxX and y+self.descScrollY > button.minY and y+self.descScrollY < button.maxY then
          return self:perform_upgrade(button.upgradeID)
        end
      end
      for index,button in ipairs(self.itemButtons) do
        if not button.disabled and x > button.minX and x < button.maxX and y+self.descScrollY > button.minY and y+self.descScrollY < button.maxY then
          return self:apply_item(button.item)
        end
      end
    end --end if cursorX > 1
  end --end if x > sidebar X
end

function spellscreen:wheelmoved(x,y)
  self.ignoreMouse = false
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
    Gamestate.switch(self.previous or game)
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
  if player:has_spell(spell.id) and spell.target_type ~= "passive" and (not spell.charges or spell.charges > 0) and not (player.cooldowns[spell] or spell:requires(player) == false or (spell.active and spell.no_manual_deactivate)) then
    if(spell:target(target,player) ~= false) then
      advance_turn()
    end
    self:switchBack()
  end
end

function spellscreen:select_spell(spellIndex)
  local spell = self.spellList[spellIndex].spell
  if self.cursorY == spellIndex and self.cursorX == 2 then
    self:cast_spell(spellIndex)
  else
    self.cursorY = spellIndex
    self.cursorX = 2
    self.sidebarCursorY=1
    self.upgradeButtons = {}
    self.descScrollY = 0
  end
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

function spellscreen:apply_item(item)
  local spell = self.spellList[self.cursorY].spell
  if spell:apply_item(item) then
    self.itemButtons = {}
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