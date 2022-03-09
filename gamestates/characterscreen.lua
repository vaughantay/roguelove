characterscreen = {}

function characterscreen:enter()
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.skillButtons = {}
  self.learnButtons = {}
  self.cursorY = 0
  self.cursorX = 1
  self.scrollY = 0
  self:refresh_spell_purchase_list()
  self.screen = "character"
end

function characterscreen:draw()
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local skillPoints = (not player.skillPoints and 0 or player.skillPoints)
  local buttonY = 1
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']+2
  local printX = padding+(skillPoints > 0 and 32 or 0)
  output:draw_window(1,1,math.floor(width/uiScale-padding),math.floor(height/uiScale-padding))
  love.graphics.setFont(fonts.textFont)
  local printY = padding
  local buttonPad = fontSize
	love.graphics.printf(player.properName,padding,padding,math.floor(width/uiScale)-44,"center")
  printY = printY + fontSize
  local levelText = "Level " .. player.level .. " " .. player.name .. " (" .. player.xp .. "/" .. player:get_level_up_cost() .. " XP to level up)"
	love.graphics.printf(levelText,padding,printY,math.floor(width/uiScale)-44,"center")
  local _,tlines = fonts.textFont:getWrap(levelText,math.floor(width/uiScale)-44)
  printY = printY + #tlines*fontSize
  --Buttons:
  local padX = 16
  local midX = round(width/2/uiScale)
  local buttonW = math.max(fonts.buttonFont:getWidth("Character")+padding,fonts.buttonFont:getWidth("Factions")+padding,fonts.buttonFont:getWidth("Missions")+padding)
  if self.screen == "character" then setColor(150,150,150,255) end
  self.charButton = output:button(midX-buttonW-math.floor(buttonW/2)-padX,printY,buttonW+padX,false,((self.cursorX == 1 and self.cursorY == 0) and "hover" or nil),"Character",true)
  if self.screen == "character" then setColor(255,255,255,255) end
  if self.screen == "factions" then setColor(150,150,150,255) end
  self.factionButton = output:button(midX-math.floor(buttonW/2),printY,buttonW+padX,false,((self.cursorX == 2 and self.cursorY == 0) and "hover" or nil),"Factions",true)
  if self.screen == "factions" then setColor(255,255,255,255) end
  if self.screen == "missions" then setColor(150,150,150,255) end
  self.missionButton = output:button(midX+math.floor(buttonW/2)+padX,printY,buttonW+padX,false,((self.cursorX == 3 and self.cursorY == 0) and "hover" or nil),"Missions",true)
  if self.screen == "missions" then setColor(255,255,255,255) end
  printY=printY+32
  local screenStartY = printY
  self.screenStartY = screenStartY
  local lastY = 0
  
  --Display the screens:
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",padding,screenStartY,width-padding,height-screenStartY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  if self.screen == "character" then
    if skillPoints > 0 then love.graphics.printf(skillPoints .. " skill points remaining",padding,printY,math.floor(width/uiScale)-44,"center") end
    printY = printY + fontSize
    love.graphics.print("Max HP: " .. player.max_hp,printX,printY)
    if skillPoints > 0 then
      self.skillButtons[buttonY] = output:tinybutton(printX-32,printY,true,self.cursorY==buttonY,"+",true)
      self.skillButtons[buttonY].skill = "max_hp"
      buttonY = buttonY+1
    end
    printY = printY + fontSize
    love.graphics.print("Max MP: " .. player.max_mp,printX,printY)
    if skillPoints > 0 then
      self.skillButtons[buttonY] = output:tinybutton(printX-32,printY,true,self.cursorY==buttonY,"+",true)
      self.skillButtons[buttonY].skill = "max_mp"
      buttonY = buttonY+1
    end
    printY = printY + fontSize
    love.graphics.print("Strength: " .. player.strength,printX,printY)
    if skillPoints > 0 then
      self.skillButtons[buttonY] = output:tinybutton(printX-32,printY,true,self.cursorY==buttonY,"+",true)
      self.skillButtons[buttonY].skill = "strength"
      buttonY = buttonY+1
    end
    printY = printY + fontSize
    love.graphics.print("Melee Skill: " .. player.melee,printX,printY)
    if skillPoints > 0 then
      self.skillButtons[buttonY] = output:tinybutton(printX-32,printY,true,self.cursorY==buttonY,"+",true)
      self.skillButtons[buttonY].skill = "melee"
      buttonY = buttonY+1
    end
    printY = printY + fontSize
    love.graphics.print("Ranged Skill: " .. player.ranged,printX,printY)
    if skillPoints > 0 then
      self.skillButtons[buttonY] = output:tinybutton(printX-32,printY,true,self.cursorY==buttonY,"+",true)
      self.skillButtons[buttonY].skill = "ranged"
      buttonY = buttonY+1
    end
    printY = printY + fontSize
    love.graphics.print("Magic Skill: " .. player.magic,printX,printY)
    if skillPoints > 0 then
      self.skillButtons[buttonY] = output:tinybutton(printX-32,printY,true,self.cursorY==buttonY,"+",true)
      self.skillButtons[buttonY].skill = "magic"
      buttonY = buttonY+1
    end
    printY = printY + fontSize
    love.graphics.print("Dodge Skill: " .. player.dodging,printX,printY)
    if skillPoints > 0 then
      self.skillButtons[buttonY] = output:tinybutton(printX-32,printY,true,self.cursorY==buttonY,"+",true)
      self.skillButtons[buttonY].skill = "dodging"
      buttonY = buttonY+1
    end
    printY = printY + fontSize
    if player.extra_stats then
      for stat_id,stat in pairs(player.extra_stats) do
        if stat.can_increase_with_points and skillPoints > 0 then
          self.skillButtons[buttonY] = output:tinybutton(printX-32,printY,true,self.cursorY==buttonY,"+",true)
          self.skillButtons[buttonY].skill = stat_id
          buttonY = buttonY+1
        end
        love.graphics.print("Max " .. stat.name .. ": " .. stat.max,printX,printY)
        printY=printY+fontSize
      end
    end
    if player.armor then
      love.graphics.print("Damage Absorption: " .. player.armor,padding,printY)
      printY = printY+fontSize
    end
  
    if player.weaknesses then
      local weakstring = "Weaknesses: "
      local first = true
      for dtype,_ in pairs(player.weaknesses) do
        weakstring = weakstring .. (not first and ", " or "") .. ucfirst(dtype)
        first = false
      end
      love.graphics.print(weakstring,padding,printY)
      printY = printY+fontSize
    end --end weaknesses
    if player.resistances then
      local resiststring = "Resistances: "
      local first = true
      for dtype,_ in pairs(player.resistances) do
        resiststring = resiststring .. (not first and ", " or "") .. ucfirst(dtype)
        first = false
      end
      love.graphics.print(resiststring,padding,printY)
      printY = printY + fontSize
    end --end resistances
    
    printY = printY + 50
    love.graphics.printf("Special Abilities:",padding,printY,math.floor(width/uiScale)-padding,"center")
    printY=printY+fontSize*2
    local abilities = ""
    local i = 1
    for id, ability in pairs(player:get_spells(true)) do
      if (i > 1) then abilities = abilities .. "\n" end
      abilities = abilities .. possibleSpells[ability].name .. (possibleSpells[ability].target_type == "passive" and " (Passive)" or "") .. " - " .. possibleSpells[ability].description
      i = i + 1
    end
    love.graphics.printf(abilities,padding,printY,math.floor(width/uiScale)-padding,"left")
    local _, wrappedtext = fonts.textFont:getWrap(abilities, math.floor(width/uiScale))
    printY=printY+#wrappedtext*fontSize
    
    --TODO: Add "choose-between" abilities:
    if #self.spell_purchases > 0 then
      printY = printY + 50
      love.graphics.printf("Abilities Available to Learn:",padding,printY,math.floor(width/uiScale)-padding,"center")
      printY = printY+fontSize*2
      for _,info in ipairs(self.spell_purchases) do
        local spell = possibleSpells[info.spell]
        local canLearn,noLearnText = player:can_learn_spell(info.spell)
        if not player:has_spell(info.spell) then
          local text = spell.name .. (spell.target_type == "passive" and " (Passive)" or "") .. " - " .. spell.description .. " (" .. info.cost .. " Skill Points)"
          local buttonMouse = false
          if self.learnButtons[buttonY] and mouseX > self.learnButtons[buttonY].minX and mouseX < self.learnButtons[buttonY].maxX and mouseY > self.learnButtons[buttonY].minY-self.scrollY and mouseY < self.learnButtons[buttonY].maxY-self.scrollY then
            buttonMouse = true
          end
          if not canLearn or skillPoints < info.cost then
            setColor(100,100,100,255)
          end
          self.learnButtons[buttonY] = output:button(padding,printY,60,true,((buttonMouse or self.cursorY == buttonY) and "hover" or false),"Learn",true)
          self.learnButtons[buttonY].info = info
          if not canLearn or skillPoints < info.cost then
            setColor(255,255,255,255)
          end
          if noLearnText then
            text = text .. "\n" .. noLearnText
          elseif skillPoints < info.cost then
            text = text .. "\nYou don't have enough skill points to learn this ability."
          end
          love.graphics.printf(text,padding+65,printY,math.floor(width/uiScale)-padding-65-32,"left")
          local _, wrappedtext = fonts.textFont:getWrap(text, math.floor(width/uiScale)-padding-65-32)
          printY=printY+math.ceil(#wrappedtext*fontSize*1.25)
          buttonY = buttonY+1
        end --end player having spell
      end --end if 
    end --end if spell.purchases
    
    if player.hit_conditions then
      printY = printY + 50
      love.graphics.printf("Hit Conditions:",padding,printY,math.floor(width/uiScale)-padding,"center")
      printY = printY+fontSize*2
      local context = ""
      local i = 1
      for _, condition in pairs(player.hit_conditions) do
        if (i > 1) then context = context .. "; " end
        context = context .. conditions[condition.condition].name .. ": "
        if condition.chance then context = context .. condition.chance .. "% Chance" .. (condition.crit_chance and ", " or "") end
        if condition.crit_chance then context = context .. condition.crit_chance .. "% Chance on a Critical Hit" end 
        i = i + 1
      end
      love.graphics.printf(context,padding,printY,math.floor(width/uiScale)-padding,"left")
    end
    
    printY = printY + 50
    love.graphics.print("Turns played this game: " .. (currGame.stats.turns or 0),padding,printY)
    printY = printY + fontSize
    love.graphics.print("Kills this game: " .. (currGame.stats.kills or 0),padding,printY)
    printY = printY + fontSize
    lastY = printY
  elseif self.screen == "factions" then
    local memberFacs = {}
    if count(player.factions) > 0 then
      love.graphics.printf("Member of: ",padding,printY,math.floor(width/uiScale)-padding,"center")
      printY = printY + fontSize
      for _,fid in ipairs(player.factions) do
        memberFacs[fid] = true
        local fac = currWorld.factions[fid]
        local facText = fac.name .. ": " .. (player.favor[fid] or 0) .. " Favor"
        love.graphics.print(facText,padding,printY)
        local _,tlines = fonts.textFont:getWrap(facText,math.floor(width/uiScale)-padding*2)
        printY = printY + round((#tlines+0.5)*fontSize)
      end
      printY = printY + fontSize*2
    end
    love.graphics.printf("Faction Favor: ",padding,printY,math.floor(width/uiScale)-padding,"center")
    printY = printY + fontSize
    for fid,favor in pairs(player.favor) do
      local fac = currWorld.factions[fid]
      if not memberFacs[fid] and not fac.hidden then
        local attitude = (fac:is_enemy(player) and "Hostile" or (fac:is_friend(player) and "Friendly" or "Neutral"))
        local facText = fac.name .. ": " .. (player.favor[fid] or 0) .. " Favor (" .. attitude .. ")"
        love.graphics.printf(facText,padding,printY,math.floor(width/uiScale)-padding*2)
        local _,tlines = fonts.textFont:getWrap(facText,math.floor(width/uiScale)-padding*2)
        printY = printY + round((#tlines+0.5)*fontSize)
      end
    end --end favor for
    lastY = printY
  elseif self.screen == "missions" then
    love.graphics.printf("Active Missions: ",padding,printY,math.floor(width/uiScale)-padding*2,"center")
    printY = printY+fontSize*2
    if count(currGame.missionStatus) > 0 then
      for mid,status in pairs(currGame.missionStatus) do
        local source = get_mission_data(mid,'source')
        local mission = possibleMissions[mid]
        local statusText = (mission.get_status and mission:get_status(get_status)) or (mission.status_text and mission.status_text[status]) or nil
        local totalText = mission.name .. "\n" .. (source and "(Given by " .. (source.baseType == "creature" and source:get_name() or source.name) ..")\n" or "") .. (get_mission_data(mid,'description') or mission.description) .. (statusText and "\nStatus: " .. statusText or "")
        love.graphics.printf(totalText,padding,printY,math.floor(width/uiScale)-padding*2,"center")
        local _, wrappedtext = fonts.textFont:getWrap(totalText, math.floor(width/uiScale)-padding*2)
        printY=printY+(#wrappedtext+1)*fontSize
      end
    else
      love.graphics.printf("None",padding,printY,math.floor(width/uiScale)-padding*2,"center")
    end
    
    if count(currGame.finishedMissions) > 0 then
      printY = printY+fontSize
      love.graphics.printf("Completed Missions: ",padding,printY,math.floor(width/uiScale)-padding*2,"center")
      printY = printY+fontSize*2
      for mid,status in pairs(currGame.finishedMissions) do
        local mission = possibleMissions[mid]
        local totalText = mission.name .. "\n" .. (mission.finished_description or mission.description)
        love.graphics.printf(totalText,padding,printY,math.floor(width/uiScale)-padding*2,"center")
        local _, wrappedtext = fonts.textFont:getWrap(totalText, math.floor(width/uiScale)-padding*2)
        printY=printY+(#wrappedtext+1)*fontSize
      end
    end
    lastY = printY
  end --end which screen if
  love.graphics.setStencilTest()
  love.graphics.pop()
  --Scrollbars
  if lastY*uiScale > height-padding then
    self.scrollMax = math.ceil((lastY-(screenStartY+(height/uiScale-screenStartY))+padding))
    local scrollAmt = self.scrollY/self.scrollMax
    self.scrollPositions = output:scrollbar(math.floor(width/uiScale-padding),screenStartY,math.floor((height-padding)/uiScale),scrollAmt,true)
  else
    self.scrollMax = 0
  end
  self.closebutton = output:closebutton(24,24,nil,true)
  love.graphics.pop()
end

function characterscreen:keypressed(key)
  local height = love.graphics.getHeight()
  local uiScale = prefs['uiScale'] or 1
  height = round(height/uiScale)
  key = input:parse_key(key)
  if key == "north" then
    if self.screen == "character" then
      local whichButton = self.learnButtons[self.cursorY-1] or (self.cursorY-1 <= #self.skillButtons and self.skillButtons[self.cursorY-1]) or nil
      if whichButton and whichButton.minY > self.screenStartY+self.scrollY then
        self.cursorY = self.cursorY-1
      elseif self.scrollY > 0 then
        self:scrollUp()
      else
        self.cursorY = 0
      end
    else
      self:scrollUp()
    end
  elseif key == "south" then
    if self.screen == "character" then
      local whichButton = self.skillButtons[self.cursorY+1] or (self.cursorY+1 > #self.skillButtons and self.learnButtons[self.cursorY+1]) or nil
      if whichButton and whichButton.maxY < height+self.scrollY then
        self.cursorY = self.cursorY+1
      else
        self:scrollDown()
      end
    else
      self:scrollDown()
    end
  elseif key == "enter" or key == "wait" then
    if self.cursorY == 0 then
      if self.cursorX == 1 then
        self.screen = "character"
        self.scrollY=0
      elseif self.cursorX == 2 then
        self.screen = "factions"
        self.scrollY=0
      elseif self.cursorX == 3 then
        self.screen = "missions"
        self.scrollY=0
      end
    elseif self.skillButtons[self.cursorY] then
      self:use_skillButton(self.skillButtons[self.cursorY].skill)
    elseif self.learnButtons[self.cursorY] then
      self:use_learnButton(self.learnButtons[self.cursorY].info)
    end
  elseif key == "east" then
    if self.cursorY == 0 then self.cursorX = math.min(self.cursorX+1,3) end
  elseif key == "west" then
    if self.cursorY == 0 then self.cursorX = math.max(self.cursorX-1,1) end
  elseif key == "escape" then
    self:switchBack()
  end
end

function characterscreen:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale,y/uiScale
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    return self:switchBack()
  end
  for id,button in ipairs(self.skillButtons) do
    if x > button.minX and x < button.maxX and y > button.minY and y < button.maxY then
      return self:use_skillButton(button.skill)
    end
  end
  for id,button in ipairs(self.learnButtons) do
    if x > button.minX and x < button.maxX and y > button.minY and y < button.maxY then
      self:use_learnButton(button.info)
    end
  end
  if x > self.charButton.minX and x < self.charButton.maxX and y > self.charButton.minY and y < self.charButton.maxY then
    self.screen = "character"
    self.cursorX,self.cursorY=1,0
    self.scrollY=0
  elseif x > self.factionButton.minX and x < self.factionButton.maxX and y > self.factionButton.minY and y < self.factionButton.maxY then
    self.screen = "factions"
    self.cursorX,self.cursorY=2,0
    self.scrollY=0
  elseif x > self.missionButton.minX and x < self.missionButton.maxX and y > self.missionButton.minY and y < self.missionButton.maxY then
    self.screen = "missions"
    self.cursorX,self.cursorY=3,0
    self.scrollY=0
  end
end

function characterscreen:use_skillButton(skill)
  player.skillPoints = player.skillPoints - 1
  if skill == "max_hp" or skill == "max_mp" then
    player[skill] = player[skill]+2
  elseif player[skill] then
    player[skill] = player[skill]+1
    if skill == "magic" and player.max_mp == 0 then --If putting points into magic, get some free MP. Presumably this would only be happening if the player is putting their first skill point into magic
      player.max_mp = 10
    end
  elseif player.extra_stats[skill] then
    local eskill = player.extra_stats[skill]
    eskill.max = eskill.max+(eskill.increase_per_point or 1)
  end
  if player.skillPoints < 1 then
    self.skillButtons = {}
  end
end

function characterscreen:use_learnButton(info)
  if player.skillPoints and player.skillPoints >= info.cost then
    player:learn_spell(info.spell)
    player.skillPoints = player.skillPoints - info.cost
  end
end

function characterscreen:refresh_spell_purchase_list()
  self.spell_purchases = {}
  if playerClasses[player.class].spell_purchases then
    for _,info in ipairs(playerClasses[player.class].spell_purchases) do
      if not info.level or info.level <= player.level then
        self.spell_purchases[#self.spell_purchases+1] = info
      end --end level check if
    end --end spell purchase list for
  end --end if player class has spell purchases
  if possibleMonsters[player.id].spell_purchases then
    for _,info in ipairs(possibleMonsters[player.id].spell_purchases) do
      if not info.level or info.level <= player.level then
        self.spell_purchases[#self.spell_purchases+1] = info
      end --end level check if
    end --end spell purchase list for
  end --end if player definition has spell purchases
end

function characterscreen:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local uiScale = (prefs['uiScale'] or 1)
    local x,y = love.mouse.getPosition()
    x,y = x/uiScale,y/uiScale
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
end

function characterscreen:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function characterscreen:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end --end button type if
end

function characterscreen:scrollUp()
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
  end
end

function characterscreen:scrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
    end
  end
end