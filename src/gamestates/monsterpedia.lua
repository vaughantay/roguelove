monsterpedia = {}

function monsterpedia:enter(previous,selectMonster)
  self.previous = previous
  monsterpedia.list = {}
  monsterpedia.positions = {}
  monsterpedia.scroll = 0
  self.rightScroll=0
  self.rightYmax=0
  self.cursorY = 2
  self.maxSeen=0
  totalstats.creature_kills = totalstats.creature_kills or {}
  
  for i=0,10,1 do
    monsterpedia.list[i] = {}
  end
  for monster,m in pairs(possibleMonsters) do
    if totalstats.creature_kills[monster] then
      local creat = possibleMonsters[monster]
      if creat then
        monsterpedia.list[creat.level or 1] = (monsterpedia.list[creat.level or 1] or {})
        if monsterpedia.list[creat.level or 1] then
          monsterpedia.list[creat.level or 1][#monsterpedia.list[creat.level or 1]+1] = {id=monster,name=creat.name}
        end
      end
    end
  end --end monsters for
  for i,v in pairs(monsterpedia.list) do --remove empty level labels
    if count(v) == 0 then
      monsterpedia.list[i] = nil
    end
  end
  
  --Store a second table of positions, for when the player is browsing
  local lineSize = math.max(output:get_tile_size(true),prefs['fontSize'],prefs['asciiSize'])
  local printY = lineSize*2
  for level, monsters in pairs (monsterpedia.list) do --loop through levels
    monsterpedia.positions[#monsterpedia.positions+1] = {id=-1,startY=printY,endY=printY+lineSize,level=level}
    printY=printY+lineSize
    sort_table(monsters,'name')
    for _, info in pairs(monsters) do --loop through monsters within levels
      local id = info.id
      local _, tlines = fonts.textFont:getWrap(possibleMonsters[id].name,322)
      monsterpedia.positions[#monsterpedia.positions+1] = {id=id,startY=printY,endY=printY+#tlines*lineSize}
      printY=printY+#tlines*lineSize
      if selectMonster == id then
        self.cursorY = #monsterpedia.positions
        self.forceScroll = true
      end
    end --end monster level list pair for
  end --end monsterpedia.list for
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
end

function monsterpedia:leave()
  output:setCursor(0,0)
end

function monsterpedia:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  self.previous:draw()
  love.graphics.push()
  love.graphics.translate(0,height*(self.yModPerc/100))
  --Draw the actual Monsterpedia:
  local tileSize = output:get_tile_size(true)
	love.graphics.setFont(fonts.textFont)
  output:draw_window(0,0,400,height-32)
  output:draw_window(432,0,width-32,height-32)
	love.graphics.printf("Monsterpedia",14,24,400,"center")
  
  local lineSize = math.max(tileSize,prefs['fontSize'],prefs['asciiSize'])
  local seenCount = 0
  for pid, monster in pairs(monsterpedia.positions) do
    local printY = monster.startY-monsterpedia.scroll*lineSize
    if printY+lineSize < height-32 and printY > 32 then --don't display if you'll go off the screen
      if monster.id == -1 then
        love.graphics.printf("Level " .. monster.level,14,printY,400,"center") --only display if it hasn't been upscrolled
      else
        seenCount = seenCount+1
        local id = monster.id
        local creat = possibleMonsters[id]
        creat.image_frame = 1
        if creat then
          if printY+lineSize > height-30 then break end
          if creat.id == nil then creat.id = id end
          creat.baseType = 'creature'
          if id == monsterpedia.positions[self.cursorY].id then --if it's the selected creature
            local rectPad = math.ceil(tileSize/3)
            setColor(100,100,100,255)
            if prefs['noImages'] == true then love.graphics.rectangle("fill",15,printY+rectPad,373,monster.endY-monster.startY)
            else love.graphics.rectangle("fill",18,printY+rectPad,364,monster.endY-monster.startY) end
            setColor(255,255,255,255)
          end
          output.display_entity(creat,20,printY+10,"force")
          setColor(255,255,255,255)
          if prefs['noImages'] == true then
            love.graphics.printf(ucfirst(creat.name),36,2+printY,322,"left")
          else
            love.graphics.printf(ucfirst(creat.name),56,printY+8,322,"left")
          end
        end --end if creat if
      end --end if -1
    end --end printing on screen if
	end --end levelgroup for
  local totalMonsters = count(monsterpedia.positions)
  self.maxSeen = seenCount
  if totalMonsters > self.maxSeen then
    self.maxScroll = totalMonsters-math.ceil(self.maxSeen/2)
    local scrollAmt = monsterpedia.scroll/self.maxScroll
    if prefs['noImages'] then monsterpedia.scrollPositions = output:scrollbar(388,16,height-34,scrollAmt)
    else monsterpedia.scrollPositions = output:scrollbar(388,16,height-16,scrollAmt) end
  end
  
  -- Display the selected monster:
  love.graphics.push()
  --Right side scrollbar:
  if self.rightYmax > 0 then
    local scrollAmt = self.rightScroll/self.rightYmax
    if scrollAmt > 1 then scrollAmt = 1 end
    self.rightScrollPositions = output:scrollbar(math.floor(width)-48,16,math.floor(height)-(prefs['noImages'] and 24 or 16),scrollAmt,true)
  end
  --Create a "stencil" that stops
  local function stencilFunc()
    love.graphics.rectangle("fill",416,16,width-432,height-32)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.rightScroll)
  local pos = monsterpedia.positions[self.cursorY] and monsterpedia.positions[self.cursorY].id
	if (pos ~= nil and pos ~= -1) then
    local scrollPad = (self.rightScrollPositions and 24 or 0)
    local id = pos
		local creat = possibleMonsters[id]
    local fontSize = prefs['fontSize']
    local start = 24
		setColor(255,255,255,255)
		love.graphics.printf(ucfirst(creat.name),450,start,(width-460-scrollPad),"center")
		if creat.level then love.graphics.printf("Level " .. creat.level,450,start+fontSize,(width-460-scrollPad),"center") end
    local types = ""
    for _,ctype in pairs((creat.types or {})) do
      if types ~= "" then types = types .. ", " .. (creatureTypes[ctype] and creatureTypes[ctype].name or ucfirst(ctype))
      else types = ucfirst(ctype) end
    end
    love.graphics.printf(types,450,start+fontSize*2,(width-460-scrollPad),"center")
    local _,tlines = fonts.textFont:getWrap(types,(width-460-scrollPad))
    start = start + #tlines*fontSize
		love.graphics.printf(creat.description,455,start+fontSize*2,(width-475-scrollPad),"left")
    _,tlines = fonts.textFont:getWrap(creat.description,(width-475-scrollPad))
    local statStart = (start+fontSize*2)+((#tlines+2)*fontSize)
    local text = "Max HP: " .. creat.max_hp
    if creat.max_mp then text = text .. "\nMax MP: " .. creat.max_mp end
    text = text .. "\nSight Radius: " .. creat.perception
    if creat.stealth then text = text .. "\nStealth Modifier: " .. creat.stealth .. "%" end
    if creat.ranged_attack and rangedAttacks[creat.ranged_attack] then text = text .. "\nRanged Attack: " .. rangedAttacks[creat.ranged_attack].name end
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
    if gamesettings.default_skills or creat.skills then
      local skillVals = {}
      for _,skillID in ipairs(gamesettings.default_skills or {}) do
        skillVals[skillID] = 0
      end
      for skillID, value in pairs(creat.skills or {}) do
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
    end --end skill if
    
		local abilities = ""
		if (creat.spells) then
      local i = 1
      for id, ability in pairs(creat.spells) do
        abilities = abilities .. "\n\t" .. possibleSpells[ability].name .. (possibleSpells[ability].target_type == "passive" and " (Passive)" or "") .. " - " .. possibleSpells[ability].description
        i = i + 1
      end
      text = text .. "\nSpecial Abilities:" .. abilities .. "\n"
		end
    
    if totalstats.exploded_creatures and totalstats.exploded_creatures[id] then
      text = text .. "\n" .. ucfirst(creat.name) .. " exploded: " .. totalstats.exploded_creatures[id]
    end
    if totalstats.creature_kills and totalstats.creature_kills[id] then
      text = text .. "\n" .. ucfirst(creat.name) .. "s killed: " .. totalstats.creature_kills[id]
    end
    if totalstats.creature_kills_by_ally and totalstats.creature_kills_by_ally[id] then
      text = text .. "\n" .. ucfirst(creat.name) .. "s killed by allies: " .. totalstats.creature_kills_by_ally[id]
    end
    if totalstats.turns_as_creature and totalstats.turns_as_creature[id] then
      text = text .. "\nTurns as " .. creat.name .. ": " .. totalstats.turns_as_creature[id]
    end
    if totalstats.kills_as_creature and totalstats.kills_as_creature[id] then
      text = text .. "\nKills as " .. creat.name .. ": " .. totalstats.kills_as_creature[id]
    end
    if totalstats.deaths_as_creature and totalstats.deaths_as_creature[id] then
      text = text .. "\nDeaths as " .. creat.name .. ": " .. totalstats.deaths_as_creature[id]
    end
    if totalstats.ally_kills_as_creature and totalstats.ally_kills_as_creature[id] then
      text = text .. "\nKills made by allies as " .. creat.name .. ": " .. totalstats.ally_kills_as_creature[id]
    end
    if totalstats.allied_creature_kills and totalstats.allied_creature_kills[id] then
      text = text .. "\nKills made by allied " .. creat.name .. "s: " .. totalstats.allied_creature_kills[id]
    end
    if totalstats.creature_ally_deaths and totalstats.creature_ally_deaths[id] then
      text = text .. '\nAllied ' .. creat.name .. " deaths: " .. totalstats.creature_ally_deaths[id]
    end
    if totalstats.ally_deaths_as_creature and totalstats.ally_deaths_as_creature[id] then
      text = text .. '\nAlly deaths as ' .. creat.name .. ": " .. totalstats.ally_deaths_as_creature[id]
    end
    love.graphics.printf(text,455,statStart,(width-475-scrollPad),"left")
    local _,tlines = fonts.textFont:getWrap(text,(width-475-scrollPad))
    local printY = statStart+(#tlines+1)*fontSize
    self.rightYmax = printY+fontSize-love.graphics:getHeight()
	end
  love.graphics.setStencilTest()
  love.graphics.pop()
  self.closebutton = output:closebutton(24,24)
  love.graphics.pop()
end

function monsterpedia:buttonpressed(key,scancode,isRepeat,controllerType)
  local lineSize = math.max(output:get_tile_size(true),prefs['fontSize'],prefs['asciiSize'])
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if (key == "north") then
    self.cursorY = self.cursorY - 1
    self.rightScroll = 0
    if self.positions[self.cursorY] and monsterpedia.positions[self.cursorY].id == -1 then --if you're on a label
      self.cursorY = math.max(1,self.cursorY - 1) --just go to the next place
    end
    while self.positions[self.cursorY] and self.positions[self.cursorY].startY-monsterpedia.scroll*lineSize < lineSize*2 and monsterpedia.scroll>0 do --if you select past the top of the screen and have scrolled down, scroll back up
      monsterpedia:scrollUp()
    end
    if self.cursorY < 1 then self.cursorY = 1 end --if, after all that, the cursor is offscreen, move it back down
  elseif (key == "south") then
    if monsterpedia.positions[self.cursorY+1] and monsterpedia.positions[self.cursorY+1].id then
      self.cursorY = self.cursorY + 1
      self.rightScroll = 0
    end
    if self.positions[self.cursorY] and self.positions[self.cursorY].id == -1 then --if you're on a label
      self.cursorY = math.min(self.cursorY + 1,#self.positions) --just go to the next place
    end
    while self.positions[self.cursorY] and self.positions[self.cursorY].endY-monsterpedia.scroll*lineSize > love.graphics.getHeight()-32 do
      monsterpedia:scrollDown()
    end
  elseif (key == "escape") then
    self:switchBack()
    return
  end
end

function monsterpedia:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
    return
  end
  local x,y = love.mouse.getPosition()
  local tileSize = output:get_tile_size(true)
  local lineSize = math.max(tileSize,prefs['fontSize'],prefs['asciiSize'])
  if x~=output.mouseX or y~=output.mouseY then
    output.mouseX = x
		output.mouseY = y
    y = y+monsterpedia.scroll*lineSize
    local listY = 0
    if (prefs['noImages'] ~= true and x>32 and x<388) or (prefs['noImages'] and x < 435 and x > 14) then
      for id,pos in ipairs(monsterpedia.positions) do
        if y > pos.startY and y < pos.endY then
          listY = id
        end
      end
    end --end images if
    if listY ~= 0 then
      if math.floor(listY) ~= self.cursorY and monsterpedia.positions[listY].id ~= -1 then
        self.rightScroll = 0
        self.cursorY=math.floor(listY)
      end
    end
  end
  
  --Handle scrolling:
  if (love.mouse.isDown(1) and monsterpedia.scrollPositions) then
    local upArrow = monsterpedia.scrollPositions.upArrow
    local downArrow = monsterpedia.scrollPositions.downArrow
    local elevator = monsterpedia.scrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      monsterpedia:scrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      monsterpedia:scrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then monsterpedia:scrollUp()
      elseif y>elevator.endY then monsterpedia:scrollDown() end
    end --end clicking on arrow
  end
  if (love.mouse.isDown(1) and monsterpedia.rightScrollPositions) then
    local upArrow = monsterpedia.rightScrollPositions.upArrow
    local downArrow = monsterpedia.rightScrollPositions.downArrow
    local elevator = monsterpedia.rightScrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      monsterpedia:scrollUp(true)
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      monsterpedia:scrollDown(true)
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then monsterpedia:scrollUp(true)
      elseif y>elevator.endY then monsterpedia:scrollDown(true) end
    end --end clicking on arrow
  end
  
  --Put the cursor back where it belongs:
  if #monsterpedia.positions ~= 0 then
    while self.cursorY > #monsterpedia.positions do --if you're scrolled too far, scroll up
      self.cursorY = self.cursorY-1
    end
    if self.cursorY == 1 and monsterpedia.scroll == 0 then self.cursorY = 2 end
    
    if self.cursorY < 1 then
      self.cursorY = self.cursorY+1
      if monsterpedia.positions[self.cursorY].id == -1 then --if you're on a label
        self.cursorY = self.cursorY + 1 --just go to the next place
      end
    end
    if monsterpedia.positions[self.cursorY].endY-monsterpedia.scroll*lineSize > love.graphics.getHeight()-32 then
      if self.forceScroll then
        if self.maxScroll then --just skip it the first frame while max scroll hasn't been created yet
          while monsterpedia.positions[self.cursorY].endY-monsterpedia.scroll*lineSize > love.graphics.getHeight()-32 do
            self:scrollDown()
          end
          self.forceScroll = nil
        end
      else
        self.cursorY = self.cursorY-1
        if monsterpedia.positions[self.cursorY].id == -1 then --if you're on a label
          self.cursorY = self.cursorY - 1 --just go to the next place
        end
      end
    elseif monsterpedia.positions[self.cursorY].startY-monsterpedia.scroll*lineSize < lineSize*2 then
      self.cursorY = self.cursorY+1
      if monsterpedia.positions[self.cursorY].id == -1 then --if you're on a label
        self.cursorY = self.cursorY + 1 --just go to the next place
      end
    end
  end
end

function monsterpedia:wheelmoved(x,y)
  local right = false
  local mouseX = love.mouse.getX()
  if mouseX > 432 then right = true end
	if y > 0 then
    monsterpedia:scrollUp(right)
	elseif y < 0 then
    monsterpedia:scrollDown(right)
	end
end

function monsterpedia:scrollUp(right)
  if not right and monsterpedia.scroll > 0 then
    monsterpedia.scroll = monsterpedia.scroll - 1
  elseif right and self.rightScroll > 0 then
    monsterpedia.rightScroll = monsterpedia.rightScroll - prefs['fontSize']
  end
end

function monsterpedia:scrollDown(right)
  if not right and #monsterpedia.positions ~= 0 and monsterpedia.scroll < self.maxScroll  then
    monsterpedia.scroll = monsterpedia.scroll + 1
  elseif right and self.rightScroll < self.rightYmax then
    monsterpedia.rightScroll = monsterpedia.rightScroll + prefs['fontSize']
  end
end

function monsterpedia:mousepressed(x,y,button)
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then self:switchBack() end
end

function monsterpedia:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end