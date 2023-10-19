examine_creature = {}

function examine_creature:enter(previous,creature)
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.cursorY = 0
  self.cursorX = 1
  self.scrollY = 0
  self.creature = creature
end

function examine_creature:draw()
  game:draw()
  local creat = self.creature
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local buttonY = 1
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']+2
  local printX = padding
  local printXbuttoned = printX+32
  output:draw_window(1,1,math.floor(width/uiScale-padding),math.floor(height/uiScale-padding))
  love.graphics.setFont(fonts.textFont)
  local printY = padding
  local buttonPad = fontSize
  local topText = (creat.properName and creat.properName .. "\n" or "")
  if gamesettings.leveling then topText = topText .. "Level " .. creat.level .. " " end
  topText = topText .. creat.name
  local types = ""
  for _,ctype in pairs((creat.types or {})) do
    if types ~= "" then types = types .. ", " .. (creatureTypes[ctype] and creatureTypes[ctype].name or ucfirst(ctype))
    else types = "\n" .. ucfirst(ctype) end
  end
  topText = topText .. types
  topText = topText .. "\n" .. creat.description
  
  love.graphics.printf(topText,printX,padding,math.floor(width/uiScale)-44,"center")
  local _,tlines = fonts.textFont:getWrap(topText,math.floor(width/uiScale)-44)
  printY = printY + #tlines*fontSize
  local startY = printY
  self.startY = startY
  local lastY = 0
  local scrollPad = (self.scrollPositions and 24 or 0)
  
  --Display the screens:
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",padding-4,startY,width-padding,height-startY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  local statStart = startY
  local text = "HP: " .. creat.hp .. "/" .. creat:get_max_hp()
  if creat.max_mp then text = text .. "\nMP: " .. creat.mp .. "/" .. creat:get_max_mp() end
  text = text .. "\nSight Radius: " .. creat:get_stat('perception')
  if creat.stealth then text = text .. "\nStealth Modifier: " .. creat:get_stat('stealth') .. "%" end
  if creat.armor then text = text .. "\nDamage Absorbtion: " .. creat:get_stat('armor') .. "" end
  if creat.ranged_attack then text = text .. "\nRanged Attack: " .. rangedAttacks[creat.ranged_attack].name end
  --Extra stats:
  if creat.extra_stats then
    for stat_id,stat in pairs(creat.extra_stats) do
      text = text .. "\n" .. stat.name .. ": " .. stat.value .. (stat.max and "/" .. stat.max or "") .. (stat.description and " - " .. stat.description or "")
    end
  end
  --Weaknesses and resistances
  if creat.weaknesses then
    local weakstring = "\nWeaknesses: "
    local first = true
    for dtype,amt in pairs(creat.weaknesses) do
      weakstring = weakstring .. (not first and ", " or "") .. ucfirst(dtype) .. " " .. amt .. "%"
      first = false
    end
    text = text .. weakstring
  end --end weaknesses
  if creat.resistances then
    local resiststring = "\nResistances: "
    local first = true
    for dtype,amt in pairs(creat.resistances) do
      resiststring = resiststring .. (not first and ", " or "") .. ucfirst(dtype) .. " " .. amt .. "%"
      first = false
    end
    text = text .. resiststring
  end --end weaknesses

  if creat.hit_conditions then
    local context = ""
    local i = 1
    if creat.hit_conditions then
      for _, condition in pairs(creat.hit_conditions) do
        if (i > 1) then context = context .. "; " end
        context = context .. conditions[condition.condition].name .. ": "
        if condition.chance then context = context .. condition.chance .. "% Chance" .. (condition.crit_chance and ", " or "") end
        if condition.crit_chance then context = context .. condition.crit_chance .. "% Chance on a Critical Hit" end
        i = i + 1
      end
    end
    text = text .. "\nHit Conditions: " .. context
  end

  text = text .. "\n"

  --Skills:
  local skillVals = {}
  for skillID, value in pairs(creat:get_skills()) do
    if value == false then
      skillVals[skillID] = false
    elseif skillVals[skillID] ~= false then
      skillVals[skillID] = (skillVals[skillID] or 0) + value
    end
  end
  
  local skill_lists = {}
  for skillID,value in pairs(skillVals) do
    local skill = possibleSkills[skillID]
    if skill then
      local sType = skill.skill_type or "skill"
      if not skill_lists[sType] then
        skill_lists[sType] = {}
      end
      skill_lists[sType][#skill_lists[sType]+1] = {skillID=skillID,value=value,name=skill.name}
    end
  end
  
  local ordered_list = {}
  if gamesettings.skill_type_order then
    for i,skillType in pairs(gamesettings.skill_type_order) do
      ordered_list[#ordered_list+1] = skillType
    end
  end
  local unordered = {} --sort unordered skill lists alphabetically so at least there's consistency
  for skillType,_ in pairs(skill_lists) do
    if not in_table(skillType,ordered_list) then
      unordered[#unordered+1] = skillType
    end
  end
  sort_table(unordered) --sort alphabetically
  for _,skillType in ipairs(unordered) do
    ordered_list[#ordered_list+1] = skillType
  end
  
  for _,sType in pairs(ordered_list) do
    local list = skill_lists[sType]
    if list then
      sort_table(list,'name')
      local typeDef = possibleSkillTypes[sType]
      text = text .. "\n" .. (typeDef and typeDef.name .. ":" or ucfirst(sType) .. ":")
      for _,skillInfo in pairs(list) do
        local skillID,value = skillInfo.skillID, skillInfo.value
        local skill = possibleSkills[skillID]
        if value then
          text = text .. "\n\t" .. skill.name .. (skill.max ~= 1 and ": " .. value or "") .. " - " .. skill.description
        end
      end --end for skillInfo
    end --end if list
    text = text .. "\n"
  end --end ordered list for

  local abilities = ""
  if count(creat.spells) > 0 then
    local i = 1
    for id, ability in pairs(creat.spells) do
      abilities = abilities .. "\n\t" .. possibleSpells[ability].name .. (possibleSpells[ability].target_type == "passive" and " (Passive)" or "") .. " - " .. possibleSpells[ability].description
      i = i + 1
    end
    text = text .. "\nSpecial Abilities:" .. abilities .. "\n"
  end
  
  --Equipment:
  local equipment = ""
  for slot,eq in pairs(creat.equipment) do
    equipment = equipment .. "\n\t" .. (creat.equipment[slot].name or ucfirst(slot)) .. ": "
    for id,equip in ipairs(eq) do
      if id ~= 1 then equipment = equipment .. ", " end
      equipment = equipment .. equip:get_name(true,nil,true)
    end --end slot for
  end --end if not in_table slot,equiporder
  text = text .. (equipment ~= "" and "Equipment:" .. equipment or "")
  
  love.graphics.printf(text,printX,statStart,(width-scrollPad),"left")
  local _,tlines = fonts.textFont:getWrap(text,(width-scrollPad))
  local printY = statStart+(#tlines+1)*fontSize
  self.rightYmax = printY+fontSize-love.graphics:getHeight()
  love.graphics.setStencilTest()
  love.graphics.pop()
  --Scrollbars
  if lastY*uiScale > height-padding then
    self.scrollMax = math.ceil((lastY-(startY+(height/uiScale-startY))+padding))
    local scrollAmt = self.scrollY/self.scrollMax
    self.scrollPositions = output:scrollbar(math.floor(width/uiScale-padding),screenStartY,math.floor((height-padding)/uiScale),scrollAmt,true)
  else
    self.scrollMax = 0
  end
  self.closebutton = output:closebutton(24,24,nil,true)
  love.graphics.pop()
end

function examine_creature:buttonpressed(key)
  local height = love.graphics.getHeight()
  local uiScale = prefs['uiScale'] or 1
  height = round(height/uiScale)
  key = input:parse_key(key)
  if key == "north" then
    if self.screen == "character" then
      local whichButton = self.learnButtons[self.cursorY-1] or self.skillButtons[self.cursorY-1] or self.statButtons[self.cursorY-1] or nil
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
      local whichButton = self.statButtons[self.cursorY+1] or (self.cursorY+1 > #self.statButtons and self.skillButtons[self.cursorY+1] or (self.cursorY+1 > #self.skillButtons and self.learnButtons[self.cursorY+1])) or nil
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
    elseif self.statButtons[self.cursorY] then
      self:use_statButton(self.statButtons[self.cursorY].stat)
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

function examine_creature:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale,y/uiScale
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    return self:switchBack()
  end
  for id,button in ipairs(self.statButtons) do
    if x > button.minX and x < button.maxX and y > button.minY and y < button.maxY then
      return self:use_statButton(button.stat)
    end
  end
  for id,button in pairs(self.skillButtons) do
    if x > button.minX and x < button.maxX and y > button.minY and y < button.maxY then
      return self:use_skillButton(button.skill)
    end
  end
  for id,button in pairs(self.learnButtons) do
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

function examine_creature:update(dt)
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

function examine_creature:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function examine_creature:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end --end button type if
end

function examine_creature:scrollUp()
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
  end
end

function examine_creature:scrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
    end
  end
end