monsterpedia = {}

function monsterpedia:enter(previous,selectMonster)
  self.previous = previous
  monsterpedia.list = {}
  monsterpedia.positions = {}
  monsterpedia.scroll = 0
  output.cursorY = 2
  totalstats.creature_possessions = totalstats.creature_possessions or {}
  
  for i=0,10,1 do
    monsterpedia.list[i] = {}
  end
  --for monster,_ in pairs(totalstats.creature_possessions) do
  for monster,m in pairs(possibleMonsters) do
    if totalstats.creature_possessions[monster] or (m.isBoss and totalstats.creatuer_kills and totalstats.creature_kills[monster]) or monster == "ghost" then
      local creat = possibleMonsters[monster]
      if creat then
        monsterpedia.list[creat.level] = (monsterpedia.list[creat.level] or {})
        if monsterpedia.list[creat.level] then
          monsterpedia.list[creat.level][#monsterpedia.list[creat.level]+1] = monster
        end
      end
    end
  end --end possessions for
  for i,v in pairs(monsterpedia.list) do --remove empty level labels
    if count(v) == 0 then
      monsterpedia.list[i] = nil
    end
  end
  
  --Store a second table of positions, for when the player is browsing
  for _, monsters in pairs (monsterpedia.list) do --loop through levels
    monsterpedia.positions[#monsterpedia.positions+1] = -1
    for _, id in pairs (monsters) do --loop through monsters within levels
      monsterpedia.positions[#monsterpedia.positions+1] = id
      if selectMonster == id then
        output.cursorY = #monsterpedia.positions
        local screenMax = math.floor(love.graphics:getHeight()/(output:get_tile_size()+2)) --if you scroll past the edge of the screen, scroll down
        while output.cursorY > screenMax-1 do
          monsterpedia:scrollDown()
        end
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
	local line = (prefs['noImages'] and 3 or 1)
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
	love.graphics.printf("Monsterpedia (Press escape to exit)",14,24,400,"center")
  
  for level, monsters in pairs(monsterpedia.list) do
    line = line + 1
    if (line-monsterpedia.scroll)*tileSize > height-32 then break end --don't display if you'll go off the screen
    if (line-1 > monsterpedia.scroll) and ((line-monsterpedia.scroll)*tileSize < height-64) then love.graphics.printf("Level " .. level,14,(line-monsterpedia.scroll)*tileSize-(prefs['noImages'] and -2 or 17),400,"center") end --only display if it hasn't been upscrolled
    for _,id in pairs(monsters) do
      local printY = (line-monsterpedia.scroll)*tileSize+16
      local creat = possibleMonsters[id]
      creat.image_frame = 1
      if creat then
        if printY+(prefs['noImages'] and 14 or 32) > height-30 then break end
        if creat.id == nil then creat.id = id end
        creat.baseType = 'creature'
        if printY > 32 then --only display if it hasn't been upscrolled
          if id == monsterpedia.positions[output.cursorY+monsterpedia.scroll] then --if it's the selected creature
            setColor(100,100,100,255)
            if prefs['noImages'] == true then love.graphics.rectangle("fill",15,printY,373,2+tileSize)
            else love.graphics.rectangle("fill",18,printY,364,2+tileSize) end
            setColor(255,255,255,255)
          end
          output.display_entity(creat,20,printY,"force")
          setColor(255,255,255,255)
          if prefs['noImages'] == true then
            love.graphics.print(ucfirst(creat.name),36,2+printY)
          else
            love.graphics.print(ucfirst(creat.name),56,printY+8)
          end
        end
        line = line+1
      end --end if creat if
    end --end monster for
	end --end levelgroup for
  local totalMonsters = count(monsterpedia.positions)
  local maxSeen = math.floor(love.graphics:getHeight()/(output:get_tile_size()+2))
  if totalMonsters > maxSeen then
    local maxScroll = totalMonsters-maxSeen
    local scrollAmt = monsterpedia.scroll/maxScroll
    if prefs['noImages'] then monsterpedia.scrollPositions = output:scrollbar(388,16,height-34,scrollAmt)
    else monsterpedia.scrollPositions = output:scrollbar(388,16,height-16,scrollAmt) end
  end
  
  -- Display the selected monster:
  local pos = monsterpedia.positions[output.cursorY+monsterpedia.scroll]
	if (pos ~= nil and pos ~= -1) then
    local id = monsterpedia.positions[output.cursorY+monsterpedia.scroll]
		local creat = possibleMonsters[id]
		setColor(255,255,255,255)
		love.graphics.printf(ucfirst(creat.name),450,24,(width-460),"center")
		love.graphics.printf("Level " .. creat.level,450,40,(width-460),"center")
    local types = ""
    for _,ctype in pairs((creat.types or {})) do
      if types ~= "" then types = types .. ", " .. ucfirst(ctype)
      else types = ucfirst(ctype) end
    end
    love.graphics.printf(types,450,56,(width-460),"center")
		love.graphics.printf(creat.description,455,75,(width-475),"left")
		love.graphics.print("Damage: " .. creat.strength .. " (" .. (creat.critical_damage and (creat.strength+creat.critical_damage) or math.ceil(creat.strength * 1.5)) .. " damage on critical hit, " .. (creat.critical_chance or 1) .. "% chance)",455,200)
		love.graphics.print("Max HP: " .. creat.max_hp,455,215)
		love.graphics.print("Sight Radius: " .. creat.perception,455,230)
		love.graphics.print("Melee Skill: " .. creat.melee .. " (" .. math.ceil(math.min(math.max(70 + (creat.melee - creat.level*5-5),25),95)) .. "% chance to hit average level " .. creat.level .. " creature)",455,245)
		love.graphics.print("Dodge Skill: " .. creat.dodging .. " (" .. math.ceil(math.min(math.max(70 + (5+creat.level*5 - creat.dodging),25),95)) .. "% chance to be hit by average level " .. creat.level .. " creature)",455,260)
    local printY = 275
    if creat.armor then love.graphics.print("Damage Absorption: " .. creat.armor,455,275) printY = printY+15 end
    if creat.weaknesses then
      local weakstring = "Weaknesses: "
      local first = true
      for dtype,amt in pairs(creat.weaknesses) do
        weakstring = weakstring .. (not first and ", " or "") .. ucfirst(dtype) .. " " .. amt .. "%"
        first = false
      end
      love.graphics.print(weakstring,455,printY)
      printY = printY+15
    end --end weaknesses
    if creat.resistances then
      local resiststring = "Resistances: "
      local first = true
      for dtype,amt in pairs(creat.resistances) do
        resiststring = resiststring .. (not first and ", " or "") .. ucfirst(dtype) .. " " .. amt .. "%"
        first = false
      end
      love.graphics.print(resiststring,455,printY)
      printY = printY+15
    end --end weaknesses
    if creat.ranged_attack then
      local rangedstring = "Ranged Attack: " .. rangedAttacks[creat.ranged_attack].name
      love.graphics.print(rangedstring,455,printY)
    end
      
	
		love.graphics.printf("Special Abilities:",450,350,(width-460),"center")
		local abilities = ""
    local sideBarY = 350
		if (creat.spells) then
      local i = 1
      for id, ability in pairs(creat.spells) do
        if (i > 1) then abilities = abilities .. "\n" end
        abilities = abilities .. possibleSpells[ability].name .. (possibleSpells[ability].target_type == "passive" and " (Passive)" or "") .. " - " .. possibleSpells[ability].description
        i = i + 1
      end
      sideBarY = sideBarY+15*i
      love.graphics.printf(abilities,455,365,(width-475),"left")
		else
			abilities = "None"
      love.graphics.printf(abilities,450,365,(width-460),"center")
		end
		
    
    if creat.hit_conditions or creat.crit_conditions then
      sideBarY=sideBarY+45
      love.graphics.printf("Hit Conditions:",450,sideBarY,(width-460),"center")
      local context = ""
      local i = 1
      if creat.hit_conditions then
        for _, condition in pairs(creat.hit_conditions) do
          if (i > 1) then context = context .. ", " end
          context = context .. conditions[condition.condition].name .. ": " .. condition.chance .. "% Chance"
          i = i + 1
        end
      end
      if creat.crit_conditions then
        for _, condition in pairs(creat.crit_conditions) do
          if (i > 1) then context = context .. ", " end
          context = context .. conditions[condition.condition].name .. ": " .. condition.chance .. "% Chance on Critical Hit"
          i = i + 1
        end
      end
      sideBarY=sideBarY+15
      love.graphics.printf(context,450,sideBarY,(width-460),"center")
		end
    
    sideBarY=sideBarY+45
    if totalstats.creature_possessions and totalstats.creature_possessions[id] then love.graphics.print(ucfirst(creat.name) .. " possessions: " .. totalstats.creature_possessions[id],455,sideBarY+15) end
    if totalstats.exploded_creatures and totalstats.exploded_creatures[id] then love.graphics.print(ucfirst(creat.name) .. " explosions: " .. totalstats.exploded_creatures[id],455,sideBarY+30) end
    if totalstats.creature_kills and totalstats.creature_kills[id] then love.graphics.print(ucfirst(creat.name) .. "s killed: " .. totalstats.creature_kills[id],455,sideBarY+45) end
    if totalstats.creature_kills_by_ally and totalstats.creature_kills_by_ally[id] then love.graphics.print(ucfirst(creat.name) .. "s killed by allies: " .. totalstats.creature_kills_by_ally[id],455,sideBarY+60) end
    if totalstats.turns_as_creature and totalstats.turns_as_creature[id] then love.graphics.print("Turns as " .. creat.name .. ": " .. totalstats.turns_as_creature[id],455,sideBarY+75) end
    if totalstats.kills_as_creature and totalstats.kills_as_creature[id] then love.graphics.print("Kills as " .. creat.name .. ": " .. totalstats.kills_as_creature[id],455,sideBarY+90) end
    if totalstats.deaths_as_creature and totalstats.deaths_as_creature[id] then love.graphics.print("Deaths as " .. creat.name .. ": " .. totalstats.deaths_as_creature[id],455,sideBarY+105) end
    if totalstats.ally_kills_as_creature and totalstats.ally_kills_as_creature[id] then love.graphics.print("Kills made by allies as " .. creat.name .. ": " .. totalstats.ally_kills_as_creature[id],455,sideBarY+120) end
    if totalstats.allied_creature_kills and totalstats.allied_creature_kills[id] then love.graphics.print("Kills made by allied " .. creat.name .. "s: " .. totalstats.allied_creature_kills[id],455,sideBarY+135) end
    if totalstats.creature_ally_deaths and totalstats.creature_ally_deaths[id] then love.graphics.print('Allied ' .. creat.name .. " deaths: " .. totalstats.creature_ally_deaths[id],455,sideBarY+150) end
    if totalstats.ally_deaths_as_creature and totalstats.ally_deaths_as_creature[id] then love.graphics.print('Ally deaths as ' .. creat.name .. ": " .. totalstats.ally_deaths_as_creature[id],455,sideBarY+165) end
	end
  self.closebutton = output:closebutton(24,24)
  love.graphics.pop()
end

function monsterpedia:keypressed(key)
  if (key == "up") then
    output.cursorY = output.cursorY - 1
    if monsterpedia.positions[output.cursorY+monsterpedia.scroll] == -1 then --if you're on a label
      output.cursorY = output.cursorY - 1 --just go to the next place
    end
    while output.cursorY < 1 and monsterpedia.scroll>0 do --if you select past the top of the screen and have scrolled down, scroll back up
      monsterpedia:scrollUp()
    end
    if output.cursorY < 1 then output.cursorY = 1 end --if, after all that, the cursor is offscreen, move it back down
  elseif (key == "down") then
    if monsterpedia.positions[output.cursorY+monsterpedia.scroll+1] then output.cursorY = output.cursorY + 1 end
    if monsterpedia.positions[output.cursorY+monsterpedia.scroll] == -1 then --if you're on a label
      output.cursorY = output.cursorY + 1 --just go to the next place
    end
    local screenMax = math.floor(love.graphics:getHeight()/(output:get_tile_size()+2)) --if you scroll past the edge of the screen, scroll down
    while output.cursorY > screenMax-1 do
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
  if x~=output.mouseX or y~=output.mouseY then
    output.mouseX = x
		output.mouseY = y
    local listY = 0
    if prefs['noImages'] ~= true then
      if x>32 and x<388 then
        listY = (y-16)/(tileSize)
      end --end x if
    else --end images if
      if (x < 435 and x > 14) then
        listY = (y-48)/14
      end
    end --end images if
    if listY ~= 0 then 
      output.cursorY=math.floor(listY)
      if monsterpedia.positions[monsterpedia.scroll+output.cursorY] == -1 then
        local _, dec = math.modf(listY)
        if dec < 0.5 then output.cursorY = output.cursorY-1
        else output.cursorY = output.cursorY+1 end
      end --end on label if
    end
  end
  --[[--Mouse movement is fuxxored right now
  local x,y = love.mouse.getPosition()
	if (x ~= mouseX or y ~= mouseY) then -- only do this if the mouse has moved
		mouseX = x
		mouseY = y
		if (x < 435 and x > 14) then
			local listY = math.floor(y/14)
			if (monsterpedia.positions[listY-1] ~= nil) then
				output.cursorY=listY-1
			end
		end
	end]]
  
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
  
  --Put the cursor back where it belongs:
  while (#monsterpedia.positions ~= 0 and output.cursorY+monsterpedia.scroll > #monsterpedia.positions) do --if you're scrolled too far, scroll up
    output.cursorY = output.cursorY-1
  end
  if output.cursorY == 1 and monsterpedia.scroll == 0 then output.cursorY = 2 end
  
  if output.cursorY < 1 then
    output.cursorY = output.cursorY+1
    if monsterpedia.positions[output.cursorY+monsterpedia.scroll] == -1 then --if you're on a label
      output.cursorY = output.cursorY + 1 --just go to the next place
    end
  end
  local screenMax = math.floor((love.graphics:getHeight())/(output:get_tile_size()+(prefs['noImages'] and 1 or 2)))
  if output.cursorY > screenMax-1 then
    output.cursorY = output.cursorY-1
    if monsterpedia.positions[output.cursorY+monsterpedia.scroll] == -1 then --if you're on a label
      output.cursorY = output.cursorY - 1 --just go to the next place
    end
  end
end

function monsterpedia:wheelmoved(x,y)
	if y > 0 then
    monsterpedia:scrollUp()
	elseif y < 0 then
    monsterpedia:scrollDown()
	end
end

function monsterpedia:scrollUp()
  if monsterpedia.scroll > 0 then
    monsterpedia.scroll = monsterpedia.scroll - 1
    output.cursorY = output.cursorY+1
  end
end

function monsterpedia:scrollDown()
  local screenMax = math.floor((love.graphics:getHeight())/(output:get_tile_size()+2))
  if #monsterpedia.positions ~= 0 and screenMax+monsterpedia.scroll-1 < #monsterpedia.positions then
    monsterpedia.scroll = monsterpedia.scroll + 1
    output.cursorY = output.cursorY-1
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