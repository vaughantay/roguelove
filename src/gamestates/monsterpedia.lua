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
        monsterpedia.list[creat.level] = (monsterpedia.list[creat.level] or {})
        if monsterpedia.list[creat.level] then
          monsterpedia.list[creat.level][#monsterpedia.list[creat.level]+1] = monster
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
  local lineSize = math.max(output:get_tile_size(),prefs['fontSize'],prefs['asciiSize'])
  local printY = lineSize*2
  for level, monsters in pairs (monsterpedia.list) do --loop through levels
    monsterpedia.positions[#monsterpedia.positions+1] = {id=-1,startY=printY,endY=printY+lineSize,level=level}
    printY=printY+lineSize
    for _, id in pairs (monsters) do --loop through monsters within levels
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
  local tileSize = output:get_tile_size()
	love.graphics.setFont(fonts.textFont)
  if (prefs['noImages'] ~= true) then
    --Borders for select:
    for x=32,388,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.u,x,0)
      love.graphics.draw(images.borders.borderImg,images.borders.d,x,height-32)
    end
    for y=32,height-36,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.l,0,y)
      love.graphics.draw(images.borders.borderImg,images.borders.r,400,y)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.ul,0,0)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,400,0)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,0,height-32)
    love.graphics.draw(images.borders.borderImg,images.borders.lr,400,height-32)
    --Borders for info panel:
    for x=452,width-36,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.u,x,0)
      love.graphics.draw(images.borders.borderImg,images.borders.d,x,height-32)
    end
    for y=32,height-36,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.l,432,y)
      love.graphics.draw(images.borders.borderImg,images.borders.r,width-32,y)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.ul,432,0)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,width-32,0)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,432,height-32)
    love.graphics.draw(images.borders.borderImg,images.borders.lr,width-32,height-32)
    --Draw inner coloring:
    setColor(44,44,44,225)
    love.graphics.rectangle("fill",18,18,396,height-36)
    love.graphics.rectangle("fill",450,18,width-468,height-36)
    setColor(255,255,255,255)
  else --no images
    setColor(20,20,20,225)
    love.graphics.rectangle("fill",18,18,396,height-36)
    love.graphics.rectangle("fill",450,18,width-468,height-36)
    setColor(255,255,255,255)
    love.graphics.rectangle("line",14,14,400,height-30)
    love.graphics.rectangle("line",450,14,width-465,height-30)
  end
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
		love.graphics.printf("Level " .. creat.level,450,start+fontSize,(width-460-scrollPad),"center")
    local types = ""
    for _,ctype in pairs((creat.types or {})) do
      if types ~= "" then types = types .. ", " .. ucfirst(ctype)
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
    if gamesettings.default_stats then
      text = text .. "\nStats:"
      for _,stat in ipairs(gamesettings.default_stats) do
        text = text .. "\n\t" .. ucfirst(stat) .. ": " .. (creat[stat]or 0)
      end
    end
    if creat.skills then
      text = text .. "\nSkills:"
      for skillID,val in pairs(creat.skills) do
        local skill = possibleSkills[skillID]
        if skill then
          text = text .. "\n\t" .. skill.name .. ": " .. val
        end
      end
    end
    if creat.armor then text = text .. "\nDamage Absorption: " .. creat.armor end
    text = text .. "\nSight Radius: " .. creat.perception
    if creat.ranged_attack then text = text .. "\nRanged Attack: " .. rangedAttacks[creat.ranged_attack].name end
    
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
    
    love.graphics.printf(text,455,statStart,(width-475-scrollPad),"left")
    _,tlines = fonts.textFont:getWrap(text,(width-475-scrollPad))
    local printY = statStart+(#tlines+1)*fontSize
    printY=math.max(350,printY+fontSize*2)
		love.graphics.printf("Special Abilities:",450,printY,(width-460-scrollPad),"center")
    printY=printY+fontSize
		local abilities = ""
		if (creat.spells) then
      local i = 1
      for id, ability in pairs(creat.spells) do
        if (i > 1) then abilities = abilities .. "\n" end
        abilities = abilities .. possibleSpells[ability].name .. (possibleSpells[ability].target_type == "passive" and " (Passive)" or "") .. " - " .. possibleSpells[ability].description
        i = i + 1
      end
      love.graphics.printf(abilities,455,printY,(width-475-scrollPad),"left")
      printY = printY+fontSize*i
		else
			abilities = "None"
      love.graphics.printf(abilities,450,printY,(width-460-scrollPad),"center")
		end
    _,tlines = fonts.textFont:getWrap(abilities,(width-475-scrollPad))
    printY = printY+(#tlines)*fontSize
    
    if creat.hit_conditions then
      printY=printY+fontSize
      love.graphics.printf("Hit Conditions:",450,printY,(width-460-scrollPad),"center")
      printY=printY+fontSize
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
      love.graphics.printf(context,450,printY,(width-460-scrollPad),"center")
      printY=printY+fontSize*2
		end
    
    local statText = ""
    if totalstats.exploded_creatures and totalstats.exploded_creatures[id] then
      statText = statText .. ucfirst(creat.name) .. " exploded: " .. totalstats.exploded_creatures[id] .. "\n"
    end
    if totalstats.creature_kills and totalstats.creature_kills[id] then
      statText = statText .. ucfirst(creat.name) .. "s killed: " .. totalstats.creature_kills[id] .. "\n"
    end
    if totalstats.creature_kills_by_ally and totalstats.creature_kills_by_ally[id] then
      statText = statText .. ucfirst(creat.name) .. "s killed by allies: " .. totalstats.creature_kills_by_ally[id] .. "\n"
    end
    if totalstats.turns_as_creature and totalstats.turns_as_creature[id] then
      statText = statText .. "Turns as " .. creat.name .. ": " .. totalstats.turns_as_creature[id] .. "\n"
    end
    if totalstats.kills_as_creature and totalstats.kills_as_creature[id] then
      statText = statText .. "Kills as " .. creat.name .. ": " .. totalstats.kills_as_creature[id] .. "\n"
    end
    if totalstats.deaths_as_creature and totalstats.deaths_as_creature[id] then
      statText = statText .. "Deaths as " .. creat.name .. ": " .. totalstats.deaths_as_creature[id] .. "\n"
    end
    if totalstats.ally_kills_as_creature and totalstats.ally_kills_as_creature[id] then
      statText = statText .. "Kills made by allies as " .. creat.name .. ": " .. totalstats.ally_kills_as_creature[id] .. "\n"
    end
    if totalstats.allied_creature_kills and totalstats.allied_creature_kills[id] then
      statText = statText .. "Kills made by allied " .. creat.name .. "s: " .. totalstats.allied_creature_kills[id] .. "\n"
    end
    if totalstats.creature_ally_deaths and totalstats.creature_ally_deaths[id] then
      statText = statText .. 'Allied ' .. creat.name .. " deaths: " .. totalstats.creature_ally_deaths[id] .. "\n"
    end
    if totalstats.ally_deaths_as_creature and totalstats.ally_deaths_as_creature[id] then
      statText = statText .. 'Ally deaths as ' .. creat.name .. ": " .. totalstats.ally_deaths_as_creature[id] .. "\n"
    end
    love.graphics.printf(statText,455,printY,(width-475-scrollPad),"left")
    _,tlines = fonts.textFont:getWrap(statText,(width-475-scrollPad))
    printY = printY+(#tlines+1)*fontSize
    self.rightYmax = printY+fontSize-love.graphics:getHeight()
    love.graphics.setStencilTest()
    love.graphics.pop()
	end
  self.closebutton = output:closebutton(24,24)
  love.graphics.pop()
end

function monsterpedia:buttonpressed(key)
  local lineSize = math.max(output:get_tile_size(),prefs['fontSize'],prefs['asciiSize'])
  key = input:parse_key(key)
  if (key == "north") then
    self.cursorY = self.cursorY - 1
    self.rightScroll = 0
    if monsterpedia.positions[self.cursorY].id == -1 then --if you're on a label
      self.cursorY = math.max(1,self.cursorY - 1) --just go to the next place
    end
    while self.positions[self.cursorY].startY-monsterpedia.scroll*lineSize < lineSize*2 and monsterpedia.scroll>0 do --if you select past the top of the screen and have scrolled down, scroll back up
      monsterpedia:scrollUp()
    end
    if self.cursorY < 1 then self.cursorY = 1 end --if, after all that, the cursor is offscreen, move it back down
  elseif (key == "south") then
    if monsterpedia.positions[self.cursorY+1] and monsterpedia.positions[self.cursorY+1].id then
      self.cursorY = self.cursorY + 1
      self.rightScroll = 0
    end
    if monsterpedia.positions[self.cursorY].id == -1 then --if you're on a label
      self.cursorY = math.min(self.cursorY + 1,#self.positions) --just go to the next place
    end
    while self.positions[self.cursorY].endY-monsterpedia.scroll*lineSize > love.graphics.getHeight()-32 do
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
  local tileSize = output:get_tile_size()
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