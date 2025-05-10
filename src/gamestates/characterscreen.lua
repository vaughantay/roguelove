characterscreen = {}

function characterscreen:enter(previous)
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.skillButtons = {}
  self.learnButtons = {}
  self.factionButtons = {}
  self.cursorY = 0
  self.cursorX = 1
  self.scrollY = 0
  self:refresh_spell_purchase_list()
  self.screen = "character"
  self.previous = previous
end

function characterscreen:draw()
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local spellPoints = (player.spellPoints or 0)
  local stat_increases = (gamesettings.leveling and player:get_stat_increases_for_level(player.level+1) or {})
  local skill_increases = (gamesettings.leveling and player:get_skill_increases_for_level(player.level+1) or {})
  local buttonY = 1
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = fonts.textFont:getHeight()
  local tileSize = output:get_tile_size()+2
  local headerSize = fonts.headerFont:getHeight()+2
  local printX = padding
  local printXbuttoned = printX+32
  local textW = math.floor(width/uiScale)-padding-(self.scrollPositions and padding*2 or 0)
  local padYtext = math.ceil((tileSize-fontSize)/2)
  local windowW = width-padding
  
  --Start drawing:
  output:draw_window(1,1,math.floor(width/uiScale-padding),math.floor(height/uiScale-padding))
  love.graphics.setFont(fonts.textFont)
  local printY = padding
  local buttonPad = fontSize
	love.graphics.printf(player.properName,padding,padding,math.floor(width/uiScale)-44,"center")
  printY = printY + fontSize
  local levelText = (gamesettings.leveling and "Level " .. player.level .. " " or "") .. ucfirst(player.name) .. ((gamesettings.xp and gamesettings.leveling) and " (" .. player.xp .. "/" .. player:get_level_up_cost() .. " XP to level up)" or "")
	love.graphics.printf(levelText,padding,printY,math.floor(width/uiScale)-44,"center")
  local _,tlines = fonts.textFont:getWrap(levelText,math.floor(width/uiScale)-44)
  printY = printY + #tlines*fontSize
  local ctypes = player:get_types()
  if count(ctypes) > 0 then
    local types = ""
    for _,ctype in ipairs(ctypes) do
      local typeName = (creatureTypes[ctype] and creatureTypes[ctype].name or ucfirst(ctype))
      if types ~= "" then types = types .. ", " .. typeName
      else types = typeName end
    end
    local _,tlines = fonts.textFont:getWrap(types,math.floor(width/uiScale)-44)
    love.graphics.printf(types,padding,printY,math.floor(width/uiScale)-44,"center")
    printY = printY + #tlines*fontSize
  end
  printY=printY+fontSize
  
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
    love.graphics.rectangle("fill",padding-4,screenStartY,width-padding,height-screenStartY-math.ceil(padding/2)-2)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  if self.screen == "character" then
    love.graphics.print("Max HP: " .. player.max_hp .. (stat_increases['max_hp'] and " (" .. (stat_increases['max_hp'] >= 1 and "+" or "") .. stat_increases['max_hp'] .. " next level)" or ""),printX,printY)
    if gamesettings.mp then
      printY = printY+fontSize
      love.graphics.print("Max MP: " .. player.max_mp .. (stat_increases['max_mp'] and " (" .. (stat_increases['max_mp'] >= 1 and "+" or "") .. stat_increases['max_mp'] .. " next level)" or ""),printX,printY)
    end
    printY = printY+fontSize
    love.graphics.print("Sight Radius: " .. player.perception,padding,printY)
    printY = printY+fontSize
    if player.stealth then
      love.graphics.print("Stealth Modifier: " .. player.stealth .. "%",padding,printY)
      printY = printY+fontSize
    end
    --Extra stats:
    if count(player.extra_stats) > 0 then
      printY = printY+fontSize
      for stat_id,stat in pairs(player.extra_stats) do
        love.graphics.print(stat.name .. ": " .. stat.value .. (stat.max and "/" .. stat.max or "") .. (stat.description and " - " .. stat.description or ""),printX,printY)
      end
    end
    printY = printY + fontSize
    
    if count(player.conditions) > 0 then
      love.graphics.setFont(fonts.headerFont)
      love.graphics.printf("Current Conditions:",printX,printY,windowW,"left")
      love.graphics.setFont(fonts.textFont)
      printY = printY+headerSize
      for condition, info in pairs(player.conditions) do
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
    local resistances = player:get_all_total_resistances()
    local armors = player:get_all_armor()
    love.graphics.setFont(fonts.headerFont)
    love.graphics.print("Damage Resistance and Armor:",padding,printY)
    love.graphics.setFont(fonts.textFont)
    printY = printY + fonts.headerFont:getHeight()
    for dtype,amt in pairs(resistances) do
      local thisPadX = 0
      if amt ~= 0 then
        local dtinfo = damage_types[dtype] or {}
        if dtinfo.color then
          setColor(dtinfo.color.r,dtinfo.color.g,dtinfo.color.b,dtinfo.color.a)
        end
        if images['damage_type' .. (dtinfo.image_name or dtype)] then
          love.graphics.draw(images['damage_type' .. (dtinfo.image_name or dtype)],padding,printY)
          thisPadX = tileSize
        end
        setColor(255,255,255,255)
        love.graphics.print(ucfirst(dtinfo.name or dtype) .. ": " .. (amt == 10000 and "Healed" or (amt == 1000 and "Immune") or amt .. "%") .. (armors[dtype] and armors[dtype] ~= 0 and ", " .. armors[dtype] or ""),padding+thisPadX,printY+padYtext)
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
          love.graphics.draw(images['damage_type' .. (dtinfo.image_name or dtype)],padding,printY)
          thisPadX = tileSize
        end
        setColor(255,255,255,255)
        love.graphics.print(ucfirst(dtinfo.name or dtype) .. ": " .. armors[dtype],padding+thisPadX,printY+padYtext)
        printY = printY + tileSize
      end
    end --end armors
    
    if player.hit_conditions then
      printY = printY+fontSize
      local context = ""
      local i = 1
      for _, condition in pairs(player.hit_conditions) do
        if (i > 1) then context = context .. "; " end
        context = context .. conditions[condition.condition].name .. ": "
        if condition.chance then context = context .. condition.chance .. "% Chance" .. (condition.crit_chance and ", " or "") end
        if condition.crit_chance then context = context .. condition.crit_chance .. "% Chance on a Critical Hit" end 
        i = i + 1
      end
      love.graphics.printf("Hit Conditions: " .. context,padding,printY,math.floor(width/uiScale)-padding,"left")
    end
    
    --Skills:
    local skill_lists = {}
    
    for skillID,value in pairs(player:get_skills()) do
      local skill = possibleSkills[skillID]
      if skill then
        local sType = skill.skill_type or "skill"
        if not skill_lists[sType] then
          skill_lists[sType] = {}
        end
        skill_lists[sType][#skill_lists[sType]+1] = {skillID=skillID,value=value,name=skill.name}
      end
    end
    
    for sType,_ in pairs(possibleSkillTypes) do
      if not skill_lists[sType] and count(player:get_purchasable_skills(sType)) > 0 then
        skill_lists[sType] = {}
      end
    end
    
    if count(skill_lists) > 0 then
      printY=printY+fontSize*2
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
      
      --Now go through the lists and display the actual skills
      for _,sType in pairs(ordered_list) do
        local list = skill_lists[sType]
        if list then
          sort_table(list,'name')
          local typeDef = possibleSkillTypes[sType]
          love.graphics.setFont(fonts.headerFont)
          love.graphics.printf((typeDef and typeDef.name .. ":" or ucfirst(sType) .. ":"),padding,printY,math.floor(width/uiScale)-padding,"left")
          printY=printY+headerSize
          love.graphics.setFont(fonts.textFont)
          local pointID = typeDef and typeDef.upgrade_stat or "upgrade_points_" .. sType
          local pointName = typeDef and typeDef.upgrade_stat_name or (ucfirst(sType) .. " Point")
          local pluralName = typeDef and typeDef.upgrade_stat_plural_name or pointName .. "s"
          local points = player[pointID] or 0
          if  count(list) > 0 then
            if points > 0 then
              love.graphics.printf(points .. " " .. (points == 1 and pointName or pluralName) .. " available.",padding,printY,math.floor(width/uiScale)-padding,"center")
              printY=printY+fontSize
            end
            if typeDef and typeDef.item_cost then
              for _,itemInfo in ipairs(typeDef.item_cost) do
                local itemID = itemInfo.item
                local itemDef = possibleItems[itemID]
                local item,_,amt = player:has_item(itemID)
                if itemID and itemDef and amt > 0 then
                  output.display_entity(item,printX,printY,true,true,1)
                  love.graphics.printf(amt .. " " .. (amt == 1 and itemDef.name or itemDef.pluralName or itemDef.name) .. " available.",printX+tileSize,printY+padYtext,math.floor(width/uiScale)-padding,"left")
                  printY=printY+tileSize
                end
              end
            end
          end
          local first = true
          for _,skillInfo in pairs(list) do
            if first then
              first = false
            else
              printY=printY+math.ceil(fontSize/2)
            end
            local skillID,skillLvl,skillBase = skillInfo.skillID, skillInfo.value, player.skills[skillInfo.skillID]
            local skill = possibleSkills[skillID]
            if skill and skillBase ~= false then
              local maxed = skill.max and (skillBase >= skill.max)
              --Create cost text:
              local costText = "" 
              local cost = player:get_skill_upgrade_cost(skillID)
              if not maxed and ((cost.point_post and cost.point_cost > 1) or cost.item_cost or (cost.upgrade_stat and cost.upgrade_stat ~= pointID)) then
                costText = costText .. " - Cost: "
                local firstCost = true
                if cost.point_cost and cost.point_cost > 0 then
                  costText = costText .. cost.point_cost .. " " .. (cost.point_cost == 1 and (cost.upgrade_stat_name or cost.upgrade_stat or pointName) or (cost.upgrade_stat_plural_name or cost.upgrade_stat or pluralName))
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
              local skillText = skill.name .. (skill.max == 1 and "" or ": " .. (skillLvl ~= skillBase and skillLvl .. " (" .. skillBase .. " base)" or skillLvl) .. (skill_increases[skillID] and " (" .. (skill_increases[skillID] >= 0 and "+" or "-") .. skill_increases[skillID] .. " next level)" or "")) .. costText .. (skill.description and "\n\t" .. skill.description or "")
              local bonuses = player:get_bonuses_from_skill(skillID)
              for bonus,amt in pairs(bonuses) do
                local isPercent = (string.find(bonus,"percent") or string.find(bonus,"chance"))
                skillText = skillText .. "\n\t\t* " .. ucfirstall(string.gsub(string.gsub(bonus, "_", " "), "percent", "")) .. (type(amt) == "number" and ": " .. (amt > 0 and "+" or "") .. amt .. (isPercent and "%" or "") or "")
              end
              local req, reqtext = player:can_upgrade_skill(skillID)
              love.graphics.printf(skillText .. (reqtext and " (" .. reqtext .. ")" or ""),(req and printXbuttoned or printX),printY,textW,"left")
              if req then
                local buttonMouse = false
                if self.skillButtons[buttonY] and mouseX > self.skillButtons[buttonY].minX and mouseX < self.skillButtons[buttonY].maxX and mouseY > self.skillButtons[buttonY].minY-self.scrollY and mouseY < self.skillButtons[buttonY].maxY-self.scrollY then
                  buttonMouse = true
                end
                self.skillButtons[buttonY] = output:tinybutton(printX,printY,true,((self.cursorY==buttonY or buttonMouse) and "hover" or false),"+",true)
                self.skillButtons[buttonY].skill = skillID
                buttonY = buttonY+1
              end
              local _, wrappedtext = fonts.textFont:getWrap(skillText,textW)
              printY=printY+#wrappedtext*fontSize
            end --end skill exists
          end --end skill for
          --List possible skills for purchase:
          local purchases = player:get_purchasable_skills(sType)
          if #purchases > 0 then
            sort_table(purchases,'name')
            love.graphics.setFont(fonts.headerFont)
            love.graphics.printf(("\n" .. "New " .. (typeDef and typeDef.name or ucfirst(sType))  .. " Available:"),padding,printY,math.floor(width/uiScale)-padding,"left")
            printY=printY+headerSize
            love.graphics.setFont(fonts.textFont)
            printY=printY+fontSize
            if typeDef and typeDef.item_cost then
              for _,itemInfo in ipairs((typeDef.learn_item_cost or typeDef.item_cost)) do
                local itemID = itemInfo.item
                local itemDef = possibleItems[itemID]
                local item,_,amt = player:has_item(itemID)
                if itemID and itemDef and amt > 0 then
                  output.display_entity(item,printX,printY,true,true,1)
                  love.graphics.printf(amt .. " " .. (amt == 1 and itemDef.name or itemDef.pluralName) .. " available.",printX+tileSize,printY+padYtext,math.floor(width/uiScale)-padding,"left")
                  printY=printY+tileSize
                end
              end
            end
            first = true
            for _,skillInfo in pairs(purchases) do
              if first then
                first = false
              else
                printY=printY+fontSize
              end
              local skillID = skillInfo.skill
              local skill = possibleSkills[skillID]
              if player.skills[skillID] ~= false then
                local costText = "" 
                local cost = player:get_skill_upgrade_cost(skillID)
                if ((cost.point_cost and cost.point_cost > 1) or cost.item_cost) then
                  costText = costText .. " - Cost: "
                  local firstCost = true
                  if cost.point_cost and cost.point_cost > 0 then
                    costText = costText .. cost.point_cost .. " " .. pointName
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
                local skillText = skill.name .. costText .. (skill.description and "\n\t" .. skill.description or "")
                local bonuses = player:get_bonuses_from_skill(skillID)
                for bonus,amt in pairs(bonuses) do
                  local isPercent = (string.find(bonus,"percent") or string.find(bonus,"chance"))
                  skillText = skillText .. "\n\t\t* " .. ucfirstall(string.gsub(string.gsub(bonus, "_", " "), "percent", "")) .. (type(amt) == "number" and ": " .. (amt > 0 and "+" or "") .. amt .. (isPercent and "%" or "") or "")
                end
                local buttonMouse = false
                if self.learnButtons[buttonY] and mouseX > self.learnButtons[buttonY].minX and mouseX < self.learnButtons[buttonY].maxX and mouseY > self.learnButtons[buttonY].minY-self.scrollY and mouseY < self.learnButtons[buttonY].maxY-self.scrollY then
                  buttonMouse = true
                end
                self.learnButtons[buttonY] = output:tinybutton(printX,printY,true,((self.cursorY==buttonY or buttonMouse) and "hover" or false),"+",true)
                self.learnButtons[buttonY].info = skillInfo
                buttonY = buttonY+1
                love.graphics.printf(skillText,printXbuttoned,printY,textW,"left")
                local _, wrappedtext = fonts.textFont:getWrap(skillText,textW)
                printY=printY+#wrappedtext*fontSize
              end --end if skillID ~= false
            end --end skill for
          end --end purchases if
          printY=printY+headerSize
        end --end list if
      end --end ordered_list for
    end --if skill lists exist
    
    --[[Purchasable spells:
    --TODO: Add "choose-between" abilities:
    if #self.spell_purchases > 0 then
      printY = printY + fontSize*2
      love.graphics.printf("Abilities Available to Learn:",padding,printY,math.floor(width/uiScale)-padding,"center")
      printY = printY+fontSize
      love.graphics.printf((player.spellPoints or 0) .. (gamesettings.default_spell_upgrade_stat_name or " Point") .. (player.spellPoints == 1 and " available" or "s available"),padding,printY,math.floor(width/uiScale)-padding,"center")
      printY = printY+fontSize*2
      for _,info in ipairs(self.spell_purchases) do
        local spell = possibleSpells[info.spell]
        local canLearn,noLearnText = player:can_learn_spell(info.spell)
        if not player:has_spell(info.spell,true,true) then
          local points = info.point_cost or 0
          local upgrade_stat = info.upgrade_stat or "spellPoints"
          local upgrade_stat_name = info.upgrade_stat_name or (upgrade_stat == "spellPoints" and gamesettings.default_spell_upgrade_stat_name or nil)
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
          local upgrade_stat_plural_name = info.upgrade_stat_plural_name or upgrade_stat_name .. "s"
          local player_has = player[upgrade_stat] or 0
          local costText = (points and points > 0 and points .. " " .. (points == 1 and upgrade_stat_name or upgrade_stat_plural_name) .. (upgrade_stat ~= "spellPoints" and " (have " .. player_has .. ")" or "") or nil)
          local text = spell.name .. (spell.target_type == "passive" and " (Passive)" or "") .. (costText and " - " .. costText or "") .. "\n" .. spell.description
          local buttonMouse = false
          if self.learnButtons[buttonY] and mouseX > self.learnButtons[buttonY].minX and mouseX < self.learnButtons[buttonY].maxX and mouseY > self.learnButtons[buttonY].minY-self.scrollY and mouseY < self.learnButtons[buttonY].maxY-self.scrollY then
            buttonMouse = true
          end
          if not canLearn or player_has < points then
            setColor(100,100,100,255)
          end
          self.learnButtons[buttonY] = output:button(padding,printY,60,false,((buttonMouse or self.cursorY == buttonY) and "hover" or false),"Learn",true)
          self.learnButtons[buttonY].info = info
          if not canLearn or player_has < points then
            setColor(255,255,255,255)
          end
          if noLearnText then
            text = text .. "\n" .. noLearnText
          elseif player_has < points then
            text = text .. "\nYou don't have enough " .. upgrade_stat_plural_name .. " to learn this ability."
          end
          love.graphics.printf(text,padding+65,printY,math.floor(width/uiScale)-padding-65-32,"left")
          local _, wrappedtext = fonts.textFont:getWrap(text, math.floor(width/uiScale)-padding-65-32)
          printY=printY+math.ceil(#wrappedtext*fontSize*1.25)
          buttonY = buttonY+1
        end --end player having spell
      end --end if 
    end --end if spell.purchases]]
    
    --[[printY = printY + fontSize
    love.graphics.print("Turns played this game: " .. (currGame.stats.turns or 0),padding,printY)
    printY = printY + fontSize
    love.graphics.print("Kills this game: " .. (currGame.stats.kills or 0),padding,printY)
    printY = printY + fontSize]]
    lastY = printY
  elseif self.screen == "factions" then
    self.factionButtons = {}
    local memberFacs = {}
    local factionNum = 0
    local infobuttonW = fonts.buttonFont:getWidth("Information")+padding
    local factionX = padding
    local factionXfirst = factionX+infobuttonW
    if count(player.factions) > 0 then
      love.graphics.printf("Member of: ",padding,printY,math.floor(width/uiScale)-padding,"center")
      printY = printY + fontSize
      for _,fid in ipairs(player.factions) do
        factionNum = factionNum + 1
        memberFacs[fid] = true
        local fButton = self.factionButtons[#self.factionButtons+1]
        local examineMouse = false
        if fButton and mouseX > fButton.minX and mouseX < fButton.maxX and mouseY > fButton.minY-self.scrollY and mouseY < fButton.maxY-self.scrollY then
          examineMouse = true
        end
        self.factionButtons[#self.factionButtons+1] = output:button(factionX,printY+4,infobuttonW,false,((examineMouse or self.cursorY == factionNum) and "hover" or false),"Information",true)
        self.factionButtons[#self.factionButtons].fid = fid
        local fac = currWorld.factions[fid]
        local imgPad = 0
        if images['faction' .. (fac.image_name or fid)] then
          imgPad = imgPad + output:get_tile_size()
          if fac.color then
            setColor(fac.color.r,fac.color.g,fac.color.b,fac.color.a)
          end
          love.graphics.draw(images['faction' .. (fac.image_name or fid)],factionXfirst,printY-padYtext)
          setColor(255,255,255,255)
        end
        local facText = fac.name .. " Reputation: " .. (player.reputation[fid] or 0) .. ", Favor: " .. (player.favor[fid] or 0) .. "\n" .. (fac.map_description or fac.description)
        love.graphics.printf(facText,factionXfirst+imgPad,printY,math.floor(width/uiScale)-padding-imgPad-factionXfirst)
        local _,tlines = fonts.textFont:getWrap(facText,math.floor(width/uiScale)-padding-factionXfirst-imgPad)
        printY = printY + math.max(tileSize,round((#tlines+0.5)*fontSize))
      end
      printY = printY + fontSize*2
    end
    love.graphics.printf("Known Factions: ",padding,printY,math.floor(width/uiScale)-padding,"center")
    printY = printY + fontSize
    
    local factions_known = {}
    for fid,fac in pairs(currWorld.factions) do
      if not memberFacs[fid] and not fac.hidden and fac.contacted then
        factions_known[#factions_known+1] = fac
      end
    end
    sort_table(factions_known,'name')
    for _,fac in ipairs(factions_known) do
      factionNum = factionNum+1
      local fid = fac.id
      local imgPad = 0
      local fButton = self.factionButtons[#self.factionButtons+1]
      local examineMouse = false
      if fButton and mouseX > fButton.minX and mouseX < fButton.maxX and mouseY > fButton.minY-self.scrollY and mouseY < fButton.maxY-self.scrollY then
        examineMouse = true
      end
      self.factionButtons[#self.factionButtons+1] = output:button(factionX,printY+4,infobuttonW,false,((examineMouse or self.cursorY == factionNum) and "hover" or false),"Information",true)
      self.factionButtons[#self.factionButtons].fid = fid
      if images['faction' .. (fac.image_name or fid)] then
        imgPad = imgPad + tileSize
        if fac.color then
          setColor(fac.color.r,fac.color.g,fac.color.b,fac.color.a)
        end
        love.graphics.draw(images['faction' .. (fac.image_name or fid)],factionXfirst,printY-padYtext)
        setColor(255,255,255,255)
      end
      local attitude = (fac:is_enemy(player) and "Hostile" or (fac:is_friend(player) and "Friendly" or "Neutral"))
      local facText = fac.name .. " - Reputation: " .. (player.reputation[fid] or 0) .. " (" .. attitude .. "), Favor: " .. (player.favor[fid] or 0) .. "\n" .. (fac.map_description or fac.description)
      love.graphics.printf(facText,factionXfirst+imgPad,printY,math.floor(width/uiScale)-padding-imgPad-factionXfirst)
      local _,tlines = fonts.textFont:getWrap(facText,math.floor(width/uiScale)-padding-imgPad-factionXfirst)
      printY = printY + math.max(tileSize,round((#tlines+0.5)*fontSize))
    end --end reputation for
    lastY = printY
  elseif self.screen == "missions" then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Active Missions: ",padding,printY,math.floor(width/uiScale)-padding*2,"center")
    love.graphics.setFont(fonts.textFont)
    printY = printY+headerSize
    if count(currGame.missionStatus) > 0 then
      for mid,minfo in pairs(currGame.missionStatus) do
        local source = get_mission_data(mid,'source')
        local mission = possibleMissions[mid]
        local statusText = (mission.get_status and mission:get_status(minfo.status)) or (mission.status_text and mission.status_text[minfo.status]) or nil
        local totalText = mission.name .. "\n" .. (source and "(Given by " .. (source.baseType == "creature" and source:get_name() or source.name) ..")\n" or "") .. (get_mission_data(mid,'description') or mission.description) .. (statusText and "\nStatus: " .. statusText or "")
        love.graphics.printf(totalText,padding,printY,math.floor(width/uiScale)-padding*2,"center")
        local _, wrappedtext = fonts.textFont:getWrap(totalText, math.floor(width/uiScale)-padding*2)
        printY=printY+(#wrappedtext+1)*fontSize
      end
    else
      love.graphics.printf("None",padding,printY,math.floor(width/uiScale)-padding*2,"center")
    end
    
    if count(currGame.finishedMissions) > 0 then
      printY = printY+headerSize
      love.graphics.setFont(fonts.headerFont)
      love.graphics.printf("Completed Missions: ",padding,printY,math.floor(width/uiScale)-padding*2,"center")
      love.graphics.setFont(fonts.textFont)
      printY = printY+headerSize
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
    self.scrollPositions = output:scrollbar(math.floor(width/uiScale-padding*2),screenStartY,math.floor((height-padding)/uiScale),scrollAmt,true)
  else
    self.scrollMax = 0
  end
  if self.scrollY > self.scrollMax then self.scrollY = self.scrollMax end
  self.closebutton = output:closebutton(24,24,nil,true)
  love.graphics.pop()
end

function characterscreen:buttonpressed(key,scancode,isRepeat,controllerType)
  local height = love.graphics.getHeight()
  local uiScale = prefs['uiScale'] or 1
  height = round(height/uiScale)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if key == "north" then
    if self.screen == "character" then
      local whichButton = self.learnButtons[self.cursorY-1] or self.skillButtons[self.cursorY-1] or nil
      if whichButton and whichButton.minY > self.screenStartY+self.scrollY then
        self.cursorY = self.cursorY-1
      elseif self.scrollY > 0 then
        self:scrollUp()
      else
        self.cursorY = 0
      end
    elseif self.screen == "factions" then
      local whichButton = self.factionButtons[self.cursorY-1]
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
    elseif self.screen == "factions" then
      local whichButton = self.factionButtons[self.cursorY+1]
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
    elseif self.screen == "character" then
      elseif self.skillButtons[self.cursorY] then
        self:use_skillButton(self.skillButtons[self.cursorY].skill)
      elseif self.learnButtons[self.cursorY] then
        self:use_learnButton(self.learnButtons[self.cursorY].info)
    elseif self.screen == "factions" then
      if self.factionButtons[self.cursorY] then
        Gamestate.switch(factionscreen,self.factionButtons[self.cursorY].fid,nil,true)
      end
    end
  elseif key == "east" then
    if self.cursorY == 0 then self.cursorX = math.min(self.cursorX+1,3) end
  elseif key == "west" then
    if self.cursorY == 0 then self.cursorX = math.max(self.cursorX-1,1) end
  elseif key == "escape" or key == "charScreen" then
    self:switchBack()
  end
end

function characterscreen:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale,y/uiScale
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    return self:switchBack()
  end
  for id,button in pairs(self.skillButtons) do
    if x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
      return self:use_skillButton(button.skill)
    end
  end
  for id,button in pairs(self.learnButtons) do
    if x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
      self:use_learnButton(button.info)
    end
  end
  for id,button in pairs(self.factionButtons) do
    if x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
      Gamestate.switch(factionscreen,button.fid,nil,true)
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

function characterscreen:use_skillButton(skillID)
  player:upgrade_skill(skillID)
  self.skillButtons = {}
end

function characterscreen:use_learnButton(info)
  if info.skill then
    if player:can_upgrade_skill(info.skill) then
      player:upgrade_skill(info.skill)
    end
  elseif info.spell then
    if (not info.point_cost or info.point_cost > 0 or player[info.upgrade_stat or "spellPoints"] >= info.point_cost) then
      player:learn_spell(info.spell)
      if info.point_cost and info.point_cost > 0 then
        player[info.upgrade_stat or "spellPoints"] = player[info.upgrade_stat or "spellPoints"] - info.point_cost
      end
    end
  end
end

function characterscreen:refresh_spell_purchase_list()
  self.spell_purchases = player:get_purchasable_spells()
end

function characterscreen:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous or game)
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