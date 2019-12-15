characterscreen = {}

function characterscreen:enter()
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.skillButtons = {}
  self.cursorY = 0
end

function characterscreen:draw()
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local skillPoints = (not player.skillPoints and 0 or player.skillPoints)
  local buttonY = 1
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']+2
  local printX = padding+(skillPoints > 0 and 32 or 0)
  output:draw_window(1,1,math.floor(width/uiScale-padding),math.floor(height/uiScale-padding))
  love.graphics.setFont(fonts.textFont)
  local printY = padding
	love.graphics.printf(player.properName,padding,padding,math.floor(width/uiScale)-44,"center")
  printY = printY + fontSize
	love.graphics.printf("Level " .. player.level .. " " .. player.name,padding,printY,math.floor(width/uiScale)-44,"center")
  printY = printY + 25
  if skillPoints > 0 then love.graphics.printf(skillPoints .. " skill points remaining",padding,printY,math.floor(width/uiScale)-44,"center") end
  printY = printY + 25
	love.graphics.print("Max HP: " .. player.max_hp,padding,printY)
  printY = printY + fontSize
	love.graphics.print("Sight Radius: " .. player.perception,padding,printY)
  printY = printY + fontSize
  love.graphics.print("Damage: " .. player.strength,printX,printY)
  if skillPoints > 0 then
    self.skillButtons[buttonY] = output:tinybutton(padding,printY,true,self.cursorY==buttonY,"+",true)
    self.skillButtons[buttonY].skill = "strength"
    buttonY = buttonY+1
  end
  printY = printY + fontSize
  love.graphics.print("Melee Skill: " .. player.melee .. " (" .. math.ceil(math.min(math.max(70 + (player.melee - player.level*5-5),25),95)) .. "% chance to hit average level " .. player.level .. " creature)",printX,printY)
  if skillPoints > 0 then
    self.skillButtons[buttonY] = output:tinybutton(padding,printY,true,self.cursorY==buttonY,"+",true)
    self.skillButtons[buttonY].skill = "melee"
    buttonY = buttonY+1
  end
  printY = printY + fontSize
  love.graphics.print("Dodge Skill: " .. player.dodging .. " (" .. math.ceil(math.min(math.max(70 + (5+player.level*5 - player.dodging),25),95)) .. "% chance to be hit by average level " .. player.level .. " creature)",printX,printY)
  if skillPoints > 0 then
    self.skillButtons[buttonY] = output:tinybutton(padding,printY,true,self.cursorY==buttonY,"+",true)
    self.skillButtons[buttonY].skill = "dodging"
    buttonY = buttonY+1
  end
  printY = printY + fontSize
  if player.armor then love.graphics.print("Damage Absorption: " .. player.armor,padding,printY) printY = printY+fontSize end
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
  
  if (player.ranged_attack) then
    printY = printY + 50
    local attack = rangedAttacks[player.ranged_attack]
    love.graphics.print("Ranged Attack: " .. attack:get_name(), padding,printY)
    printY = printY + fontSize
    love.graphics.printf(attack:get_description(),padding,printY,math.floor(width/uiScale)-padding)
  end
	
  printY = printY + 50
	love.graphics.printf("Special Abilities:",padding,printY,math.floor(width/uiScale)-padding,"center")
  printY=printY+fontSize*2
	local abilities = ""
	local i = 1
	for id, ability in pairs(player.spells) do
		if (i > 1) then abilities = abilities .. "\n" end
		abilities = abilities .. possibleSpells[ability].name .. (possibleSpells[ability].target_type == "passive" and " (Passive)" or "") .. " - " .. possibleSpells[ability].description
		i = i + 1
	end
	love.graphics.printf(abilities,padding,printY,math.floor(width/uiScale)-padding,"left")
  local _, wrappedtext = fonts.textFont:getWrap(abilities, math.floor(width/uiScale))
  printY=printY+#wrappedtext*fontSize
  
  if player.hit_conditions then
    printY = printY + 50
    love.graphics.printf("Hit Conditions:",padding,printY,math.floor(width/uiScale)-padding,"center")
    printY = printY+fontSize*2
    local context = ""
    local i = 1
    for _, condition in pairs(player.hit_conditions) do
      if (i > 1) then context = context .. ", " end
      context = context .. conditions[condition.condition].name .. ": " .. condition.chance .. "% Chance"
      i = i + 1
    end
    love.graphics.printf(context,padding,printY,math.floor(width/uiScale)-padding,"left")
  end
	
  printY = printY + 50
	love.graphics.print("Turns played this game: " .. (currGame.stats.turns or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print("Turns in current body: " .. (currGame.stats.turns_in_current_body or 1),padding,printY)
  printY = printY + fontSize
  love.graphics.print("Turns as " .. player.name  .. ", this game: " .. ((currGame.stats.turns_as_creature and currGame.stats.turns_as_creature[player.id]) or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print("Turns as " .. player.name  .. ", all games: " .. ((totalstats.turns_as_creature and totalstats.turns_as_creature[player.id]) or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print("Kills this game: " .. (currGame.stats.kills or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print("Kills in current body: " .. (currGame.stats.kills_in_current_body or 0),padding,printY)
  printY = printY + fontSize
  love.graphics.print("Kills as " .. player.name  .. ", this game: " .. ((currGame.stats.kills_as_creature and currGame.stats.kills_as_creature[player.id]) or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print("Kills as " .. player.name  .. ", all games: " .. ((totalstats.kills_as_creature and totalstats.kills_as_creature[player.id]) or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print("Total possessions, this game: " .. (currGame.stats.total_possessions or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print(ucfirst(player.name) .. " possessions, this game: " .. ((currGame.stats.creature_possessions and currGame.stats.creature_possessions[player.id]) or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print(ucfirst(player.name) .. " possessions, all games: " .. ((totalstats.creature_possessions and totalstats.creature_possessions[player.id]) or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print("Bodies exploded, this game: " .. (currGame.stats.explosions or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print(ucfirst(player.name) .. " explosions, this game: " .. ((currGame.stats.exploded_creatures and currGame.stats.exploded_creatures[player.id]) or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print(ucfirst(player.name) .. " explosions, all games: " .. ((totalstats.exploded_creatures and totalstats.exploded_creatures[player.id]) or 0),padding,printY)
  self.closebutton = output:closebutton(24,24,nil,true)
  love.graphics.pop()
end

function characterscreen:keypressed(key)
  if key == "up" then
    if self.cursorY > 1 then
      self.cursorY = self.cursorY - 1
    end
  elseif key == "down" then
    if self.cursorY < #self.skillButtons then
      self.cursorY = self.cursorY + 1
    end
  elseif key == "return" or key == "kpenter" then
    if self.skillButtons[self.cursorY] then
      self:use_skillbutton(self.skillButtons[self.cursorY].skill)
    end
  elseif key == "escape" then
    self:switchBack()
  end
end

function characterscreen:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then
    self:switchBack()
  end
  for id,button in ipairs(self.skillButtons) do
    if x > button.minX and x < button.maxX and y > button.minY and y < button.maxY then
      self:use_skillbutton(button.skill)
    end
  end
end

function characterscreen:use_skillbutton(skill)
  player.skillPoints = player.skillPoints - 1
  player[skill] = player[skill]+1
  if player.skillPoints < 1 then
    self.skillButtons = {}
  end
end

function characterscreen:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
end

function characterscreen:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end