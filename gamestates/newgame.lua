newgame = {whiteAlpha=0,cheats = {}}

function newgame:enter(previous)
  self.lineCountdown = 0.5
  self.lineOn = true
  if not self.seed or previous == menu then self.seed = random(999999,2147483647) end
  self.blackAmt=nil
  if not totalstats or not totalstats.games or totalstats.games == 0 then
    self.tutorial = true
  end
  self.class = nil
  self.afterClassIndex = 3
  self.classes = {}
  self.cursorY = 1
end

function newgame:draw()
  love.graphics.print(self.afterClassIndex,14,36)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  if self.cursorY < 0 then self.cursorY = 0 elseif (self.cursorY > 10) then self.cursorY = 10 end
  if output.cursorX < 1 then output.cursorX = 1 elseif output.cursorX > 2 then output.cursorX = 2 end
  love.graphics.setFont(fonts.mapFont)
  love.graphics.push()
  love.graphics.translate(0,math.floor(-((self.blackAmt and self.blackAmt/255 or 0/255))*height/2))

  -- Define some coordinates:
  local nameBoxX=math.floor(width/2)-256+48-(prefs['noImages'] and 32 or 0)
  local nameBoxY = 32
  local nameBoxWidth = 512-128+(prefs['noImages'] and 96 or 0)
  local selectBoxX = math.floor(width/3)+85
  local selectBoxWidth = math.floor(width/3)-170
  local pronounY = nameBoxY+32
  -- Draw the cursor:
  local seedWidth = fonts.textFont:getWidth("Seed: 100000000000")
  setColor(100,100,100,255)

  if self.cursorY ~= 8 then
    setColor(50,50,50,255)
    love.graphics.rectangle('fill',math.ceil(width/2-seedWidth/2),572,seedWidth,16)
  end
  -- Draw the Text:
  setColor(255,255,255,255)
  love.graphics.setFont(fonts.graveFontSmall)
  local w = fonts.graveFontSmall:getWidth("Name: ")
  love.graphics.print("Name: ",nameBoxX-w,nameBoxY)
  love.graphics.rectangle('line',nameBoxX,nameBoxY,nameBoxWidth,24)
  --love.graphics.draw((self.cursorY == 1 and output.cursorX == 2 and images.uidicebuttonhover or images.uidicebutton),math.floor(width/2+w/2)+16,108)
  if self.cursorY == 1 then
    setColor(100,100,100,255)
    love.graphics.rectangle('fill',nameBoxX,nameBoxY,nameBoxWidth,24)
    setColor(255,255,255,255)
    love.graphics.printf(player.properName,nameBoxX,nameBoxY,nameBoxWidth,"center")
    if self.lineOn then
      local w = fonts.graveFontSmall:getWidth(player.properName)
      local lineX = nameBoxX+math.ceil(nameBoxWidth/2+w/2)
      love.graphics.line(lineX,nameBoxY+4,lineX,nameBoxY+21)
    end
  else
    love.graphics.printf(player.properName,nameBoxX,nameBoxY,nameBoxWidth,"center")
  end
  local w = fonts.graveFontSmall:getWidth("Pronouns: ")
  love.graphics.print("Pronouns: ",nameBoxX-w,pronounY)
  local pnouns = ucfirst(player:get_pronoun('n')) .. "/" .. ucfirst(player:get_pronoun('o')) .. "/" .. ucfirst(player:get_pronoun('p'))
  w = fonts.graveFontSmall:getWidth(pnouns)
  love.graphics.print(pnouns,nameBoxX,pronounY)
  if self.cursorY == 2 then
    --handle choosing pronouns
  end

  --[[local buttonWidth = fonts.graveFontSmall:getWidth("They Will be Missed")+64
  local buttonX = math.floor(width/2-buttonWidth/2)
  if self.cursorY >= 2 and self.cursorY <= 5 then --only show other options of gender is highlighted
    output:button(buttonX,200,buttonWidth,false,(self.cursorY == 3 and "hover" or nil))
    output:button(buttonX,235,buttonWidth,false,(self.cursorY == 4 and "hover" or nil))
    output:button(buttonX,270,buttonWidth,false,(self.cursorY == 5 and "hover" or nil))
  end
  if (player.gender == "male") then
    love.graphics.printf("He Will be Missed",math.floor(width/3),175,math.floor(width/3),"center")
    if self.cursorY >= 2 and self.cursorY <= 5 then --only show other options of gender is highlighted
      setColor(225,225,225,255)
      love.graphics.printf("She Will be Missed",buttonX,200,buttonWidth,"center")
      love.graphics.printf("They Will be Missed",buttonX,235,buttonWidth,"center")
      love.graphics.printf("It Will be Missed",buttonX,270,buttonWidth,"center")
    end
  elseif (player.gender == "female") then
    love.graphics.printf("She Will be Missed",math.floor(width/3),175,math.floor(width/3),"center")
    if self.cursorY >= 2 and self.cursorY <= 5 then --only show other options of gender is highlighted
      setColor(225,225,225,255)
      love.graphics.printf("He Will be Missed",buttonX,200,buttonWidth,"center")
      love.graphics.printf("They Will be Missed",buttonX,235,buttonWidth,"center")
      love.graphics.printf("It Will be Missed",buttonX,270,buttonWidth,"center")
    end
  elseif player.gender== "unspecified" then 
    love.graphics.printf("They Will be Missed",math.floor(width/3),175,math.floor(width/3),"center")
    if self.cursorY >= 2 and self.cursorY <= 5 then --only show other options of gender is highlighted
      setColor(225,225,225,255)
      love.graphics.printf("He Will be Missed",buttonX,200,buttonWidth,"center")
      love.graphics.printf("She Will be Missed",buttonX,235,buttonWidth,"center")
      love.graphics.printf("It Will be Missed",buttonX,270,buttonWidth,"center")
    end
  elseif player.gender== "neuter" then 
    love.graphics.printf("It Will be Missed",math.floor(width/3),175,math.floor(width/3),"center")
    if self.cursorY >= 2 and self.cursorY <= 5 then --only show other options of gender is highlighted
      setColor(225,225,225,255)
      love.graphics.printf("He Will be Missed",buttonX,200,buttonWidth,"center")
      love.graphics.printf("She Will be Missed",buttonX,235,buttonWidth,"center")
      love.graphics.printf("They Will be Missed",buttonX,270,buttonWidth,"center")
    end
  end]]
  
  --Classes:
  setColor(255,255,255,255)
  local fontSize = 24
  local classBoxX = nameBoxX
  local classBoxY = pronounY+32
  local classBoxSep = 150
  local classBoxW = nameBoxWidth
  local classBoxH = math.max(count(playerClasses)*fontSize,150)
  local w = fonts.graveFontSmall:getWidth("Class: ")
  love.graphics.print("Class: ",classBoxX-w,math.ceil(classBoxY+classBoxH/2-24))
  local printY = classBoxY
  local index = 3
  local whichClass = nil
  self.classes = {}
  for id,class in pairs(playerClasses) do
    if self.class == id then
      setColor(100,100,100,255)
      love.graphics.rectangle('fill',classBoxX,printY,classBoxH,fontSize)
    elseif self.cursorY == index then
      setColor(100,100,100,125)
      love.graphics.rectangle('fill',classBoxX,printY,classBoxH,fontSize)
      whichClass = id
    end
    setColor(255,255,255,255)
    love.graphics.print(class.name,classBoxX,printY)
    self.classes[#self.classes+1] = {classID=id,minY=printY,maxY=printY+fontSize}
    printY = printY+fontSize
    index = index + 1
  end
  whichClass = whichClass or self.class
  if whichClass then
    love.graphics.setFont(fonts.textFont)
    local desc = playerClasses[whichClass].description
    love.graphics.printf(desc,classBoxX+classBoxSep,classBoxY+2,(classBoxW-classBoxSep),"center")
    love.graphics.setFont(fonts.graveFontSmall)
  end
  printY = classBoxY+classBoxH+24
  love.graphics.line(classBoxX+classBoxSep,classBoxY,classBoxX+classBoxSep,classBoxY+classBoxH)
  love.graphics.rectangle("line",classBoxX,classBoxY,classBoxW,classBoxH)
  self.afterClassIndex = index
  
  
  --Tutorial Checkbox:
  local padding = (prefs['noImages'] and 16 or 32)
  love.graphics.setFont(fonts.graveFontSmall)
  local textWidth = fonts.graveFontSmall:getWidth("Tutorial Messages?")
  if self.cursorY == self.afterClassIndex then
    setColor(100,100,100,255)
    love.graphics.rectangle('fill',nameBoxX,printY,nameBoxWidth,24)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((self.tutorial and "(Y)" or "(N)"),math.floor(width/2-textWidth/2-padding*2),printY)
  else
    love.graphics.draw((self.tutorial and images.uicheckboxchecked or images.uicheckbox),math.floor(width/2-textWidth/2-padding/2),math.floor(printY+padding/4))
  end
  love.graphics.print("Tutorial Messages?",math.floor(width/2-textWidth/2+padding/2),printY)

--Begin Button:
  output:button(math.floor(width/2-75),450,150,false,(self.cursorY == self.afterClassIndex+1 and "hover" or nil))
  love.graphics.printf("BEGIN",math.floor(width/4),450,width/2,"center")
  --Seed info:
  if self.cursorY == self.afterClassIndex+2 then
    setColor(100,100,100,255)
    love.graphics.rectangle('fill',math.ceil(width/2-seedWidth/2),572,seedWidth,16)
    local w = fonts.textFont:getWidth("Seed: " .. (self.seed or ""))
    if self.lineOn then
      love.graphics.line(width/2+w/2,574,width/2+w/2,586)
    end
    setColor(255,255,255,255)
  end
  love.graphics.setFont(fonts.textFont)
  love.graphics.printf("Seed: " .. (self.seed or ""),math.floor(width/4),572,width/2,"center")

  --Copy/paste buttons:
  output:button(math.floor(width/2-74),600,64,false,((self.cursorY == self.afterClassIndex+3 and output.cursorX == 1) and "hover"))
  output:button(math.ceil(width/2+seedWidth/2)-64,600,64,false,((self.cursorY == self.afterClassIndex+3 and output.cursorX == 2) and "hover"))
  love.graphics.print("Copy",math.floor(width/2-60),605)
  love.graphics.print("Paste",math.floor(width/2+24),605)
  --Cheats button:
  output:button(math.ceil(width/2)-64,641,136,false,(self.afterClassIndex+4 and "hover"),"Game Modifiers")

  
  --close button:
  self.closebutton = output:closebutton(14,14)
  
  love.graphics.pop()
  --White and black for flashes and fadeouts
  setColor(255,255,255,self.whiteAlpha)
  love.graphics.rectangle('fill',0,0,width,height)
  if self.blackAmt then
    setColor(0,0,0,self.blackAmt)
    love.graphics.rectangle('fill',0,0,width,height)
  end
  setColor(255,255,255,255)
end

function newgame:keypressed(key)
  if self.blackAmt then return false end
  if (key == "return") or key == "kpenter" then
    if self.cursorY == 0 then -- not selecting anyting
      self.cursorY = self.afterClassIndex+1 --select button
    elseif (self.cursorY == 1) then -- name entry
      self.cursorY = 2
    elseif (self.cursorY == 2) then --gender line
    
    elseif self.cursorY >= 3 and self.cursorY < self.afterClassIndex then
      self.class = self.classes[self.cursorY-2].classID
      self.cursorY = self.afterClassIndex+1
    elseif self.cursorY == self.afterClassIndex then
      self.tutorial = not self.tutorial
    elseif self.cursorY == self.afterClassIndex+1 then --"begin" line
      new_game((tonumber(self.seed) > 0 and tonumber(self.seed) or 1),self.tutorial,self.cheats,self.class)
      output:sound('possession')
      self.cursorY=0
      self.blackAmt = 0
      tween(1,self,{blackAmt=255})
      Timer.after(1.5,function()
          output:play_playlist('silence')
          Gamestate.switch(game)
          tween(1,game,{blackAmt=0})
          Timer.after(1,function () game.blackAmt=nil end)
      end)
      game.blackAmt=255
      output:setCursor(0,0)
      currGame.cheats = self.cheats
      if currGame.cheats.twoHitGhost then
        player.hp,player.max_hp = 2,2
      end
      if currGame.cheats.fullMap == true then currMap:reveal() end
      --game:show_level_description()
    elseif self.cursorY == self.afterClassIndex+2 then --seed line
      self.cursorY = self.afterClassIndex+1
    elseif self.cursorY == self.afterClassIndex+3 then --copy/paste buttons
      if output.cursorX == 1 then --copy
        love.system.setClipboardText((self.seed or ""))
      elseif output.cursorX == 2 then -- paste
        self.seed = tonumber(love.system.getClipboardText())
      end
    elseif self.cursorY == self.afterClassIndex+4 then --cheats button
      Gamestate.switch(cheats)
    end -- end cursor check
  elseif (key == "tab") then
    if self.cursorY == 1 then self.cursorY = 2
    else self.cursorY = self.afterClassIndex+1 end
  elseif (key == "backspace") then
    if self.cursorY == 1 then
      player.properName = string.sub(player.properName,1,#player.properName-1)
    elseif self.cursorY == self.afterClassIndex+2 then
      local seed = tostring(self.seed)
      local newSeed = tonumber(string.sub(seed,1,#seed-1))
      self.seed = newSeed
    end
  elseif (key == "up") then
    self.cursorY = self.cursorY - 1
  elseif (key == "down") then
    self.cursorY = self.cursorY + 1
  elseif key == "left" then
    output.cursorX = output.cursorX - 1
  elseif key == "right" then
    output.cursorX = output.cursorX + 1
  elseif tonumber(key) and self.cursorY == self.afterClassIndex+2 then
    local newSeed = tonumber((self.seed or "").. key)
    if newSeed < math.pow(2,32) then
      self.seed = newSeed
    end --end seed bounds check
  elseif key == "escape" then
    Gamestate.switch(menu)
  end --end key if
end

function newgame:mousepressed(x,y,button)
  if self.blackAmt then return false end
  if button == 2 then
    Gamestate.switch(menu)
    return
  end
  local width = love.graphics.getWidth()
  local nameBoxX=math.floor(width/2)-256+48-(prefs['noImages'] and 32 or 0)
  local nameBoxWidth = 512-128+(prefs['noImages'] and 96 or 0)
  if x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY then
    Gamestate.switch(menu)
  elseif self.cursorY ~= 1 and self.cursorY ~= self.afterClassIndex+2 and x > nameBoxX and x < nameBoxX+nameBoxWidth then
    output.mouseX,output.mouseY=1,1
    return self:keypressed("return")
  end
end

function newgame:wheelmoved(x,y)
  if self.blackAmt then return false end
  if y > 0 then
		self.cursorY = self.cursorY-1
	elseif y < 0 then
		self.cursorY = self.cursorY+1
  end
end

function newgame:update(dt)
	local x,y = love.mouse.getPosition()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
	if x > math.floor(width/3) and x < math.floor(width/3)*2 and (y ~= output.mouseY or x ~= output.mouseX) then -- only do this if the mouse has moved, and if it's in range
		output.mouseX,output.mouseY = x,y
    --[[Redo all this cursorY shit:
		if (y < 170) then self.cursorY = 1
    elseif (y > 175 and y < 295) then
      self.cursorY = 2
      if x > width/5*2 and x < width/5*3 then
        if (y >= 200 and y < 225) then self.cursorY = 3
        elseif (y >= 235 and y < 260) then self.cursorY = 4
        elseif (y >= 270 and y < 295) then self.cursorY = 5 end
      end
    elseif (y >= 375 and y < 415) then self.cursorY = 6
    elseif (y >= 450 and y < 490) then self.cursorY = 7
    elseif (y >=572 and y < 586) then self.cursorY = 8
    elseif (y >=600 and y < 632) and (x >= width/2-70 and x <= width/2-20) then self.cursorY,output.cursorX = 9,1
    elseif (y >=600 and y < 632) and (x >= width/2+25 and x <= width/2+75) then self.cursorY,output.cursorX = 9,2
    elseif (y >=641 and y < 673) then self.cursorY = 10
    else self.cursorY = 0
    end]]
	end
  self.lineCountdown = self.lineCountdown-dt
  if self.lineCountdown <= 0 then
    self.lineCountdown = .5
    self.lineOn = not self.lineOn
  end
  if player.properName == "" and self.cursorY ~= 1 then
    player.properName = namegen:generate_human_name(player)
  end
end

function newgame:textinput(text)
  if self.cursorY == 1 then
    player.properName = player.properName .. text
  end
end