examine_creature = {}

function examine_creature:enter(previous,creature)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
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
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle("fill",0,0,width,height)
  setColor(255,255,255,255)
  local uiScale = (prefs['uiScale'] or 1)
  local buttonY = 1
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = fonts.textFont:getHeight()
  local headerSize = fonts.headerFont:getHeight()
  local tileSize = output:get_tile_size()
  local tabSize = fonts.textFont:getWidth("\t")
  local padYtext = math.ceil((tileSize-fontSize)/2)
  local scrollPad = (self.scrollPositions and tileSize or 0)
  local windowH = math.min(height,750)
  local windowW = math.min(width,850)
  local windowX = math.floor(width/uiScale/2-windowW/2)
  local windowY = math.floor(height/uiScale/2-windowH/2)
  local printX = windowX+padding
  local textW = windowW-scrollPad-padding
  output:draw_window(windowX,windowY,windowX+windowW,windowY+windowH)
  love.graphics.setFont(fonts.textFont)
  local printY = windowY+padding
  local topText = (creat.properName and creat.properName .. "\n" or "")
  if gamesettings.display_creature_levels and creat.level then
    topText = topText .. "Level " .. creat.level .. " "
  end
  topText = topText .. ucfirst(creat.name)
  local types = ""
  for _,ctype in ipairs(creat:get_types()) do
    local typeName = (creatureTypes[ctype] and creatureTypes[ctype].name or ucfirst(ctype))
    if types ~= "" then types = types .. ", " .. typeName
    else types = "\n" .. typeName end
  end
  topText = topText .. types
  topText = topText .. "\n" .. creat.description
  
  love.graphics.printf(topText,printX,printY,textW,"center")
  local _,tlines = fonts.textFont:getWrap(topText,textW)
  printY = printY + #tlines*fontSize
  local startY = printY
  self.startY = startY
  
  --Display the screens:
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",windowX,startY,windowW+padding,windowY+windowH-startY+math.ceil(padding/2)-2)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  local statStart = startY+fontSize
  local text = "HP: " .. creat.hp .. "/" .. creat:get_max_hp()
  if creat:get_max_mp() > 0 then text = text .. "\nMP: " .. creat.mp .. "/" .. creat:get_max_mp() end
  text = text .. "\nSight Radius: " .. creat:get_stat('perception')
  if creat.stealth then text = text .. "\nStealth Modifier: " .. creat:get_stat('stealth') .. "%" end
  --if creat.armor then text = text .. "\nDamage Absorbtion: " .. creat:get_stat('armor') .. "" end
  if creat.ranged_attack then text = text .. "\nRanged Attack: " .. rangedAttacks[creat.ranged_attack].name end
  --Extra stats:
  if creat.extra_stats then
    for stat_id,stat in pairs(creat.extra_stats) do
      text = text .. "\n" .. stat.name .. ": " .. stat.value .. (stat.max and "/" .. stat.max or "") .. (stat.description and " - " .. stat.description or "")
    end
  end
  love.graphics.printf(text,printX,statStart,textW,"left")
  local _,tlines = fonts.textFont:getWrap(text,textW)
  printY = statStart+(#tlines+1)*fontSize
  
  if count(creat.conditions) > 0 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Current Conditions:",printX,printY,windowW,"left")
    love.graphics.setFont(fonts.textFont)
    printY = printY+headerSize
    for condition, info in pairs(creat.conditions) do
      local turns = info.turns
      local conInfo = conditions[condition]
      if conInfo and conInfo.hidden ~= true then
        local name = conInfo.name .. (turns ~= -1 and " (" .. turns .. ")" or "") .. (conInfo.description and " - " .. conInfo.description or "")
        local color = conInfo.color
        if color then
          setColor(color.r,color.g,color.b,color.a)
        end
        if images['condition' .. (conInfo.image_name or condition)] then
          love.graphics.draw(images['condition' .. (conInfo.image_name or condition)],printX,printY)
        elseif images['conditiondefault'] then
          love.graphics.draw(images['conditiondefault'],printX,printY)
        else
          love.graphics.printf("!",printX,printY+padYtext,tileSize,"left")
        end
        if info.bonuses or conInfo.bonuses then
          local bonuses = {}
          if info.bonuses then
            for bonus,amt in pairs(info.bonuses) do
              bonuses[bonus] = amt
            end
          end
          if conInfo.bonuses then
            for bonus,amt in pairs(conInfo.bonuses) do
              if not bonuses[bonus] then
                bonuses[bonus] = amt
              end
            end
          end
          for bonus,amt in pairs(bonuses) do
            if bonus ~= 'xMod' and bonus ~= 'yMod' and bonus ~= 'scale' and bonus ~= 'angle' then
              local isPercent = (string.find(bonus,"percent") or string.find(bonus,"chance"))
              name = name .. "\n\t* " .. ucfirstall(string.gsub(string.gsub(bonus, "_", " "), "percent", "")) .. (type(amt) == "number" and ": " .. (amt > 0 and "+" or "") .. amt .. (isPercent and "%" or "") or "")
            end
          end
        end
        setColor(255,255,255,255)
        love.graphics.printf(name,printX+tileSize,printY+padYtext,textW-tileSize,"left")
        local _,nlines = fonts.textFont:getWrap(name,textW)
        printY = printY + math.max(#nlines*fontSize+padYtext,tileSize)
      end
    end
    printY=printY+headerSize
  end
  
  --Weaknesses/resistances
  local resistances = creat:get_all_total_resistances()
  local armors = creat:get_all_armor()
  if count(resistances) > 0 or count(armors) > 0 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.print("Damage Resistance and Armor:",printX,printY)
    love.graphics.setFont(fonts.textFont)
    printY = printY + fonts.headerFont:getHeight()
    if (resistances.all and resistances.all > 0) or (armors.all and armors.all > 0) then
      local resistance = resistances.all
      local armor = armors.all
      love.graphics.print("All: " .. (resistance and (resistance == 10000 and "Healed" or (resistance == 1000 and "Immune") or resistance .. "%") or "") .. (armor and (resistance and ", " or "") .. armor or ""),printX,printY+padYtext)
      armors.all = nil
      printY = printY + tileSize
    end
    for dtype,amt in pairs(resistances) do
      local thisPadX = 0
      if amt ~= 0 then
        local dtinfo = damage_types[dtype] or {}
        if dtinfo.color then
          setColor(dtinfo.color.r,dtinfo.color.g,dtinfo.color.b,dtinfo.color.a)
        end
        if images['damage_type' .. (dtinfo.image_name or dtype)] then
          love.graphics.draw(images['damage_type' .. (dtinfo.image_name or dtype)],printX,printY)
          thisPadX = tileSize
        end
        setColor(255,255,255,255)
        love.graphics.print(ucfirst(dtinfo.name or dtype) .. ": " .. (amt == 10000 and "Healed" or (amt == 1000 and "Immune") or amt .. "%") .. (armors[dtype] and armors[dtype] ~= 0 and ", " .. armors[dtype] or ""),printX+thisPadX,printY+padYtext)
        printY = printY + tileSize
        if armors[dtype] then armors[dtype] = nil end
      end
    end --end resistances
    for dtype,amt in pairs(armors) do
      local thisPadX = 0
      if amt ~= 0 then
        local dtinfo = damage_types[dtype] or {}
        if dtinfo.color then
          setColor(dtinfo.color.r,dtinfo.color.g,dtinfo.color.b,dtinfo.color.a)
        end
        if images['damage_type' .. (dtinfo.image_name or dtype)] then
          love.graphics.draw(images['damage_type' .. (dtinfo.image_name or dtype)],printX,printY)
          thisPadX = tileSize
        end
        setColor(255,255,255,255)
        love.graphics.print(ucfirst(dtinfo.name or dtype) .. ": " .. amt,printX+thisPadX,printY+padYtext)
        printY = printY + tileSize
      end
    end
    printY = printY + tileSize
  end
  

  if count(creat:get_hit_conditions()) > 0 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.print("Hit Conditions:",padding,printY)
    love.graphics.setFont(fonts.textFont)
    printY = printY + fonts.headerFont:getHeight()
    for _, condition in pairs(creat.hit_conditions) do
      local context = "\t" .. conditions[condition.condition].name .. ": "
      if condition.chance then context = context .. condition.chance .. "% Chance" .. (condition.crit_chance and ", " or "") end
      if condition.crit_chance then context = context .. condition.crit_chance .. "% Chance on a Critical Hit" end
      local _,clines = fonts.textFont:getWrap(context,textW-tabSize)
      love.graphics.printf(context,printX,printY,textW-tabSize,"left")
      printY = printY+#clines*fontSize
    end
    printY=printY+headerSize
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
  
  if count(ordered_list) > 0 then
    for _,sType in pairs(ordered_list) do
      local list = skill_lists[sType]
      if list then
        sort_table(list,'name')
        local typeDef = possibleSkillTypes[sType]
        love.graphics.setFont(fonts.headerFont)
        love.graphics.printf((typeDef and typeDef.name .. ":" or ucfirst(sType) .. ":"),printX,printY,textW,"left")
        printY = printY+headerSize
        love.graphics.setFont(fonts.textFont)
        for _,skillInfo in pairs(list) do
          local skillID,value = skillInfo.skillID, skillInfo.value
          local skill = possibleSkills[skillID]
          if value then
            local skillText = "\t" .. skill.name .. (skill.max ~= 1 and ": " .. value or "") .. " - " .. skill.description
            local bonuses = creat:get_bonuses_from_skill(skillID)
            for bonus,amt in pairs(bonuses) do
              local isPercent = (string.find(bonus,"percent") or string.find(bonus,"chance"))
              skillText = skillText .. "\n\t\t* " .. ucfirstall(string.gsub(string.gsub(bonus, "_", " "), "percent", "")) .. (type(amt) == "number" and ": " .. (amt > 0 and "+" or "") .. amt .. (isPercent and "%" or "") or "")
            end
            local _,slines = fonts.textFont:getWrap(skillText,textW-tabSize)
            love.graphics.printf(skillText,printX,printY,textW-tabSize,"left")
            printY=printY+#slines*fontSize
          end
        end --end for skillInfo
        printY=printY+headerSize
      end --end if list
    end --end ordered list for
  end

  local abilities = ""
  if count(creat.spells) > 0 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Abilities:",printX,printY,textW,"left")
    love.graphics.setFont(fonts.textFont)
    printY = printY+headerSize
    for id, ability in pairs(creat.spells) do
      --Draw image:
      if images['spell' .. (ability.image_name or ability.id)]  then
        if ability.color then
          setColor(ability.color.r,ability.color.g,ability.color.b,ability.color.a)
        end
        love.graphics.draw(images['spell' .. (ability.image_name or ability.id)],printX,printY)
        setColor(255,255,255,255)
      end
      local abilityText = ability.name .. (ability.target_type == "passive" and " (Passive)" or "") .. " - " .. ability.description
      local _,alines = fonts.textFont:getWrap(abilityText,textW-tileSize)
      love.graphics.printf(abilityText,printX+tileSize,printY+padYtext,textW-tileSize,"left")
      printY=printY+math.max(#alines*fontSize,tileSize)
    end
    printY=printY+headerSize
  end
  
  --Equipment:
  if not creat.noEquip and count(creat.equipment_list) > 0 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Equipment:",printX,printY,windowW,"left")
    love.graphics.setFont(fonts.textFont)
    printY = printY+headerSize
    local largestEquipLabelWidth = 0
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
      largestEquipLabelWidth = math.max(fonts.textFont:getWidth(slot.name or ucfirst(slotName)),largestEquipLabelWidth)
    end
    for i,eq in ipairs(self.equipment) do
      if #eq > 0 then
        love.graphics.printf(self.equipment_labels[i] .. ": ",printX,printY+padYtext,textW,"left")
        for id,equip in ipairs(eq) do
          local equipText = equip:get_name(true,nil,true)
          local _,elines = fonts.textFont:getWrap(equipText,textW-largestEquipLabelWidth-tileSize)
          output.display_entity(equip,printX+largestEquipLabelWidth,printY,true,true)
          love.graphics.printf(equipText,printX+largestEquipLabelWidth+tileSize,printY+padYtext,textW-largestEquipLabelWidth-tileSize,"left")
          printY=printY+math.max(#elines*fontSize,tileSize)
        end
      end --end slot for
    end --end if not in_table slot,equiporder
    printY = printY+headerSize
  end
  love.graphics.setStencilTest()
  love.graphics.pop()
  --Scrollbars
  if printY > (windowY+windowH-startY) then
    self.scrollMax = math.ceil((printY-(windowY+windowH)))
    local scrollAmt = self.scrollY/self.scrollMax
    self.scrollPositions = output:scrollbar(math.floor(windowW+windowX-padding),startY,math.floor((windowY+windowH-padding)/uiScale),scrollAmt,true)
  else
    self.scrollMax = 0
  end
  self.closebutton = output:closebutton(windowX+padding,windowY+padding,nil,true)
  love.graphics.pop()
end

function examine_creature:buttonpressed(key,scancode,isRepeat,controllerType)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
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
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
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