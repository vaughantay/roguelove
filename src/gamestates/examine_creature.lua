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
  local statStart = startY+fontSize
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
      text = text .. "\n\n" .. (typeDef and typeDef.name .. ":" or ucfirst(sType) .. ":")
      for _,skillInfo in pairs(list) do
        local skillID,value = skillInfo.skillID, skillInfo.value
        local skill = possibleSkills[skillID]
        if value then
          text = text .. "\n\t" .. skill.name .. (skill.max ~= 1 and ": " .. value or "") .. " - " .. skill.description
        end
      end --end for skillInfo
    end --end if list
  end --end ordered list for

  local abilities = ""
  if count(creat.spells) > 0 then
    local i = 1
    for id, ability in pairs(creat.spells) do
      abilities = abilities .. "\n\t" .. ability.name .. (ability.target_type == "passive" and " (Passive)" or "") .. " - " .. ability.description
      i = i + 1
    end
    text = text .. "\n\nSpecial Abilities:" .. abilities
  end
  
  --Equipment:
  if not creat.noEquip then
    local equipOrder = gamesettings.default_equipment_order
    self.equipment = {}
    self.equipment_labels = {}
    for _,s in ipairs(equipOrder) do
      local slot = creat.equipment[s]
      if slot then
        self.equipment[#self.equipment+1] = slot
        self.equipment_labels[#self.equipment_labels+1] = slot.name or ucfirst(s)
      end
    end
    for slotName,slot in pairs(creat.equipment) do
      if not in_table(slotName,equipOrder) then
        self.equipment[#self.equipment+1] = slot
        self.equipment_labels[#self.equipment_labels+1] = slot.name or ucfirst(slotName)
      end
    end
    local equipment = ""
    for i,eq in ipairs(self.equipment) do
      if #eq > 0 then
        equipment = equipment .. "\n\t" .. self.equipment_labels[i] .. ": "
        for id,equip in ipairs(eq) do
          if id ~= 1 then equipment = equipment .. ", " end
          equipment = equipment .. equip:get_name(true,nil,true)
        end
      end --end slot for
    end --end if not in_table slot,equiporder
    text = text .. (equipment ~= "" and "\n\nEquipment:" .. equipment or "")
  end
  
  love.graphics.printf(text,printX,statStart,round((width-scrollPad-printX-padding)/uiScale),"left")
  local _,tlines = fonts.textFont:getWrap(text,(width-scrollPad))
  printY = statStart+(#tlines+2)*fontSize
  love.graphics.setStencilTest()
  love.graphics.pop()
  --Scrollbars
  if printY > (height/uiScale-startY) then
    self.scrollMax = math.ceil((printY-(height/uiScale)+padding))
    local scrollAmt = self.scrollY/self.scrollMax
    self.scrollPositions = output:scrollbar(math.floor(width/uiScale-padding),padding,math.floor((height-padding)/uiScale),scrollAmt,true)
  else
    self.scrollMax = 0
  end
  self.closebutton = output:closebutton(24,24,nil,true)
  love.graphics.pop()
end

function examine_creature:buttonpressed(key)
  key = input:parse_key(key)
  if key == "north" then
    self:scrollUp()
  elseif key == "south" then
    self:scrollDown()
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