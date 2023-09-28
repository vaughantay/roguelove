characterscreen = {}

function characterscreen:enter()
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.statButtons = {}
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
  local fontSize = prefs['fontSize']+2
  local printX = padding
  local printXbuttoned = printX+32
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
    love.graphics.rectangle("fill",padding-4,screenStartY,width-padding,height-screenStartY)
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
    if player.armor then
      printY = printY+fontSize
      love.graphics.print("Damage Absorption: " .. player.armor,padding,printY)
    end
    if player.stealth then
      printY = printY+fontSize
      love.graphics.print("Stealth Modifier: " .. player.stealth .. "%",padding,printY)
    end
    --Extra stats:
    if count(player.extra_stats) > 0 then
      printY = printY+fontSize
      for stat_id,stat in pairs(player.extra_stats) do
        love.graphics.print(stat.name .. ": " .. stat.value .. (stat.max and "/" .. stat.max or "") .. (stat.description and " - " .. stat.description or ""),printX,printY)
      end
    end
    --Weaknesses/resistances
    if player.weaknesses then
      printY = printY + fontSize
      local weakstring = "Weaknesses: "
      local first = true
      for dtype,amt in pairs(player.weaknesses) do
        weakstring = weakstring .. (not first and ", " or "") .. ucfirst(dtype) .. " " .. amt .. "%"
        first = false
      end
      love.graphics.print(weakstring,padding,printY)
    end --end weaknesses
    if player.resistances then
      printY = printY+fontSize
      local resiststring = "Resistances: "
      local first = true
      for dtype,amt in pairs(player.resistances) do
        resiststring = resiststring .. (not first and ", " or "") .. ucfirst(dtype) .. " " .. amt .. "%"
        first = false
      end
      love.graphics.print(resiststring,padding,printY)
    end --end resistances
    
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
          love.graphics.printf((typeDef and typeDef.name .. ":" or ucfirst(sType) .. ":"),padding,printY,math.floor(width/uiScale)-padding,"center")
          printY=printY+fontSize
          local pointID = typeDef and typeDef.upgrade_stat or "upgrade_points_" .. sType
          local pointName = typeDef and typeDef.upgrade_stat_name or (ucfirst(sType) .. " Points")
          local points = player[pointID] or 0
          if points > 0 then
            love.graphics.printf("You have " .. points .. " " .. pointName .. " available.",padding,printY,math.floor(width/uiScale)-padding,"center")
            printY=printY+fontSize
          end
          for _,skillInfo in pairs(list) do
            local skillID,skillLvl,skillBase = skillInfo.skillID, skillInfo.value, player.skills[skillInfo.skillID]
            local skill = possibleSkills[skillID]
            if skill and skillBase ~= false then
              local maxed = skill.max and (skillBase >= skill.max)
              --Create cost text:
              local costText = "" 
              local cost = player:get_skill_upgrade_cost(skillID)
              if not maxed and (cost.point_cost > 1 or cost.item_cost or (cost.upgrade_stat and cost.upgrade_stat ~= pointID)) then
                costText = costText .. " - Cost: "
                local firstCost = true
                if cost.point_cost and cost.point_cost > 0 then
                  costText = costText .. cost.point_cost .. " " .. (cost.upgrade_stat_name or cost.upgrade_stat or pointName)
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
              local skillText = skill.name .. (skill.max == 1 and "" or ": " .. (skillLvl ~= skillBase and skillLvl .. " (" .. skillBase .. " base)" or skillLvl) .. (skill_increases[skillID] and " (" .. (skill_increases[skillID] >= 0 and "+" or "-") .. skill_increases[skillID] .. " next level)" or "")) .. costText .. (skill.description and "\n\t" .. skill.description or "")
              local req, reqtext = player:can_upgrade_skill(skillID)
              love.graphics.printf(skillText .. (reqtext and " (" .. reqtext .. ")" or ""),(req and printXbuttoned or printX),printY,width-padding,"left")
              if req then
                self.skillButtons[buttonY] = output:tinybutton(printX,printY,true,(self.cursorY==buttonY or nil),"+",true)
                self.skillButtons[buttonY].skill = skillID
                buttonY = buttonY+1
              end
              local _, wrappedtext = fonts.textFont:getWrap(skillText, math.floor(width/uiScale))
              printY=printY+#wrappedtext*fontSize
            end --end skill exists
          end --end skill for
          --List possible skills for purchase:
          local purchases = player:get_purchasable_skills(sType)
          if #purchases > 0 then
            sort_table(purchases,'name')
            love.graphics.printf(("\nAvailable to Learn:"),padding,printY,math.floor(width/uiScale)-padding,"center")
            printY=printY+(fontSize*2)
            for _,skillInfo in pairs(purchases) do
              local skillID = skillInfo.skill
              local skill = possibleSkills[skillID]
              if player.skills[skillID] ~= false then
                local costText = "" 
                local cost = player:get_skill_upgrade_cost(skillID)
                if not maxed and (cost.point_cost > 1 or cost.item_cost) then
                  costText = costText .. " - Cost: "
                  local firstCost = true
                  if cost.point_cost and cost.point_cost > 0 then
                    costText = costText .. cost.point_cost .. " " .. pointName
                    firstCost = false
                  end
                  if cost.item_cost then
                    for _,item_details in ipairs(cost.item_cost) do
                      local amount = item_details.amount or 1
                      local sortByVal = item_details.sortBy
                      local _,_,has_amt = player:has_item(item_details.item,sortByVal)
                      local name = item_details.displayName or (amount > 1 and possibleItems[item_details.item].pluralName or possibleItems[item_details.item].name)
                      costText = costText .. (firstCost == false and ", " or "") .. amount .. " " .. name .. " (You have " .. has_amt .. ")"
                      firstCost = false
                    end --end item cost for
                  end --end item cost if
                end
                local skillText = skill.name .. costText .. (skill.description and "\n\t" .. skill.description or "")
                self.learnButtons[buttonY] = output:tinybutton(printX,printY,true,(self.cursorY==buttonY or nil),"+",true)
                self.learnButtons[buttonY].info = skillInfo
                buttonY = buttonY+1
                love.graphics.printf(skillText,printXbuttoned,printY,width-padding,"left")
                local _, wrappedtext = fonts.textFont:getWrap(skillText, math.floor(width/uiScale))
                printY=printY+#wrappedtext*fontSize
              end --end if skillID ~= false
            end --end skill for
          end --end purchases if
        end --end list if
        printY=printY+fontSize
      end --end ordered_list for
    end --if skill lists exist
    
    --Purchasable spells:
    --TODO: Add "choose-between" abilities:
    if #self.spell_purchases > 0 then
      printY = printY + fontSize*2
      love.graphics.printf("Abilities Available to Learn:",padding,printY,math.floor(width/uiScale)-padding,"center")
      printY = printY+fontSize
      love.graphics.printf((player.spellPoints or 0) .. " Ability Points Available",padding,printY,math.floor(width/uiScale)-padding,"center")
      printY = printY+fontSize*2
      for _,info in ipairs(self.spell_purchases) do
        local spell = possibleSpells[info.spell]
        local canLearn,noLearnText = player:can_learn_spell(info.spell)
        if not player:has_spell(info.spell,true,true) then
          local spCost = (info.spell_point_cost and info.spell_point_cost .. " Ability Points" or "")
          local costText = spCost
          local text = spell.name .. (spell.target_type == "passive" and " (Passive)" or "") .. " - " .. spell.description .. costText
          local buttonMouse = false
          if self.learnButtons[buttonY] and mouseX > self.learnButtons[buttonY].minX and mouseX < self.learnButtons[buttonY].maxX and mouseY > self.learnButtons[buttonY].minY-self.scrollY and mouseY < self.learnButtons[buttonY].maxY-self.scrollY then
            buttonMouse = true
          end
          if not canLearn or spellPoints < (info.spell_point_cost or 0) then
            setColor(100,100,100,255)
          end
          self.learnButtons[buttonY] = output:button(padding,printY,60,false,((buttonMouse or self.cursorY == buttonY) and "hover" or false),"Learn",true)
          self.learnButtons[buttonY].info = info
          if not canLearn or spellPoints < (info.spell_point_cost or 0) then
            setColor(255,255,255,255)
          end
          if noLearnText then
            text = text .. "\n" .. noLearnText
          elseif spellPoints < (info.spell_point_cost or 0) then
            text = text .. "\nYou don't have enough ability points to learn this ability."
          end
          love.graphics.printf(text,padding+65,printY,math.floor(width/uiScale)-padding-65-32,"left")
          local _, wrappedtext = fonts.textFont:getWrap(text, math.floor(width/uiScale)-padding-65-32)
          printY=printY+math.ceil(#wrappedtext*fontSize*1.25)
          buttonY = buttonY+1
        end --end player having spell
      end --end if 
    end --end if spell.purchases
    
    printY = printY + fontSize*2
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

function characterscreen:buttonpressed(key)
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

function characterscreen:mousepressed(x,y,button)
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

function characterscreen:use_statButton(stat)
  player.upgrade_points_attribute = player.upgrade_points_attribute - 1
  if player[stat] then
    player[stat] = player[stat]+1
  elseif player.extra_stats[stat] then
    local estat = player.extra_stats[stat]
    if estat.max then
      estat.max = estat.max+(estat.increase_per_point or 1)
    else
      estat.value = estat.value+(estat.increase_per_point or 1)
    end
  end
  if player.upgrade_points_attribute < 1 then
    self.statButtons = {}
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
    if (not info.spell_point_cost or (player.spellPoints and player.spellPoints >= info.spell_point_cost)) and (not info.stat_point_cost or (player.upgrade_points_attribute and player.upgrade_points_attribute >= info.stat_point_cost)) then
      player:learn_spell(info.spell)
      if info.spell_point_cost then player.spellPoints = player.spellPoints - info.spell_point_cost end
    end
  end
end

function characterscreen:refresh_spell_purchase_list()
  self.spell_purchases = player:get_purchasable_spells()
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