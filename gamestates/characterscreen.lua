characterscreen = {}

function characterscreen:enter()
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.skillButtons = {}
  self.learnButtons = {}
  self.cursorY = 0
  self:refresh_spell_purchase_list()
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
	love.graphics.printf("Level " .. player.level .. " " .. player.name .. " (" .. player.xp .. "/" .. player:get_level_up_cost() .. " XP to level up)",padding,printY,math.floor(width/uiScale)-44,"center")
  printY = printY + 25
  if skillPoints > 0 then love.graphics.printf(skillPoints .. " skill points remaining",padding,printY,math.floor(width/uiScale)-44,"center") end
  printY = printY + 25
	love.graphics.print("Max HP: " .. player.max_hp,padding,printY)
  if skillPoints > 0 then
    self.skillButtons[buttonY] = output:tinybutton(padding,printY,true,self.cursorY==buttonY,"+",true)
    self.skillButtons[buttonY].skill = "max_hp"
    buttonY = buttonY+1
  end
  printY = printY + fontSize
  love.graphics.print("Max MP: " .. player.max_mp,padding,printY)
  if skillPoints > 0 then
    self.skillButtons[buttonY] = output:tinybutton(padding,printY,true,self.cursorY==buttonY,"+",true)
    self.skillButtons[buttonY].skill = "max_mp"
    buttonY = buttonY+1
  end
  printY = printY + fontSize
  love.graphics.print("Strength: " .. player.strength,printX,printY)
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
  love.graphics.print("Ranged Skill: " .. player.ranged .. " (" .. math.ceil(math.min(math.max(70 + (player.melee - player.level*5-5),25),95)) .. "% chance to hit average level " .. player.level .. " creature)",printX,printY)
  if skillPoints > 0 then
    self.skillButtons[buttonY] = output:tinybutton(padding,printY,true,self.cursorY==buttonY,"+",true)
    self.skillButtons[buttonY].skill = "ranged"
    buttonY = buttonY+1
  end
  printY = printY + fontSize
  love.graphics.print("Magic Skill: " .. player.magic,printX,printY)
  if skillPoints > 0 then
    self.skillButtons[buttonY] = output:tinybutton(padding,printY,true,self.cursorY==buttonY,"+",true)
    self.skillButtons[buttonY].skill = "magic"
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
  
  --TODO: Add "choose-between" abilities:
  if #self.spell_purchases > 0 then
    printY = printY + 50
    love.graphics.printf("Abilities Available to Learn:",padding,printY,math.floor(width/uiScale)-padding,"center")
    printY = printY+fontSize*2
    for _,info in ipairs(self.spell_purchases) do
      if not player:has_spell(info.spell) then
        local spell = possibleSpells[info.spell]
        self.learnButtons[buttonY] = output:button(padding,printY,60,true,(self.cursorY == buttonY and "hover" or false),"Learn",true)
        self.learnButtons[buttonY].info = info
        local text = spell.name .. (spell.target_type == "passive" and " (Passive)" or "") .. " - " .. spell.description .. " (" .. info.cost .. " Skill Points)"
        love.graphics.printf(text,padding+65,printY,math.floor(width/uiScale)-padding,"left")
        local _, wrappedtext = fonts.textFont:getWrap(text, math.floor(width/uiScale))
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
      if (i > 1) then context = context .. ", " end
      context = context .. conditions[condition.condition].name .. ": " .. condition.chance .. "% Chance"
      i = i + 1
    end
    love.graphics.printf(context,padding,printY,math.floor(width/uiScale)-padding,"left")
  end
	
  printY = printY + 50
	love.graphics.print("Turns played this game: " .. (currGame.stats.turns or 0),padding,printY)
  printY = printY + fontSize
	love.graphics.print("Kills this game: " .. (currGame.stats.kills or 0),padding,printY)
  printY = printY + fontSize
  self.closebutton = output:closebutton(24,24,nil,true)
  love.graphics.pop()
end

function characterscreen:keypressed(key)
  if key == "up" then
    if self.cursorY > 1 then
      self.cursorY = self.cursorY - 1
    end
  elseif key == "down" then
    if self.cursorY < #self.skillButtons+count(self.learnButtons) then
      self.cursorY = self.cursorY + 1
    end
  elseif key == "return" or key == "kpenter" then
    if self.skillButtons[self.cursorY] then
      self:use_skillButton(self.skillButtons[self.cursorY].skill)
    elseif self.learnButtons[self.cursorY] then
      self:use_learnButton(self.learnButtons[self.cursorY].info)
    end
  elseif key == "escape" then
    self:switchBack()
  end
end

function characterscreen:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then
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
end

function characterscreen:use_skillButton(skill)
  player.skillPoints = player.skillPoints - 1
  if skill == "max_hp" or skill == "max_mp" then
    player[skill] = player[skill]+2
  else
    player[skill] = player[skill]+1
    if skill == "magic" and player.max_mp == 0 then --If putting points into magic, get some free MP. Presumably this would only be happening if the player is putting their first skill point into magic
      player.max_mp = 10
    end
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