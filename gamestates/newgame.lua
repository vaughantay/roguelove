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
  self.cursorX = 1
end

function newgame:draw()
  love.graphics.print(self.afterClassIndex,14,36)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local mouseX,mouseY = love.mouse.getPosition()
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

  -- Draw the Text:
  setColor(255,255,255,255)
  love.graphics.setFont(fonts.graveFontSmall)
  local w = fonts.graveFontSmall:getWidth("Name: ")
  love.graphics.print("Name: ",nameBoxX-w,nameBoxY)
  --love.graphics.draw((self.cursorY == 1 and self.cursorX == 2 and images.uidicebuttonhover or images.uidicebutton),math.floor(width/2+w/2)+16,108)
  if self.cursorY == 1 then
    setColor(50,50,50,255)
    love.graphics.rectangle('fill',nameBoxX,nameBoxY,nameBoxWidth,24)
    setColor(255,255,255,255)
    love.graphics.printf(player.properName,nameBoxX,nameBoxY,nameBoxWidth,"center")
    if self.lineOn then
      local w = fonts.graveFontSmall:getWidth(player.properName)
      local lineX = nameBoxX+math.ceil(nameBoxWidth/2+w/2)
      love.graphics.line(lineX,nameBoxY+4,lineX,nameBoxY+21)
    end
  elseif mouseY > 32 and mouseY < 56 then
    setColor(33,33,33,255)
    love.graphics.rectangle('fill',nameBoxX,nameBoxY,nameBoxWidth,24)
    setColor(255,255,255,255)
    love.graphics.printf(player.properName,nameBoxX,nameBoxY,nameBoxWidth,"center")
  else
    love.graphics.printf(player.properName,nameBoxX,nameBoxY,nameBoxWidth,"center")
  end
  love.graphics.rectangle('line',nameBoxX,nameBoxY,nameBoxWidth,24)
  
  --Draw Pronouns:
  local w = fonts.graveFontSmall:getWidth("Pronouns: ")
  love.graphics.print("Pronouns: ",nameBoxX-w,pronounY)
  self.pronouns = {}
  if self.cursorY == 2 or (mouseY > pronounY and mouseY < pronounY+24) then
    local genderX = 1
    local printX = nameBoxX
    local pnouns = ucfirst(player:get_pronoun('n')) .. "/" .. ucfirst(player:get_pronoun('o')) .. "/" .. ucfirst(player:get_pronoun('p'))
    w = fonts.graveFontSmall:getWidth(pnouns)
    if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w) then
      setColor(50,50,50,255)
      love.graphics.rectangle("fill",printX,pronounY,w,24)
      setColor(255,255,255,255)
    end
    love.graphics.print(pnouns,printX,pronounY)
    self.pronouns[1] = {gender=player.gender,minX = printX,maxX = printX+w,minY=pronounY,maxY=pronounY+24}
    printX=printX+w+12
    if player.gender ~= "male" then
      genderX = genderX+1
      pnouns = "He"
      w = fonts.graveFontSmall:getWidth(pnouns)
      if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w+12) then
        setColor(50,50,50,255)
        love.graphics.rectangle("fill",printX,pronounY,w,24)
        setColor(255,255,255,255)
      end
      love.graphics.print(pnouns,printX,pronounY)
      self.pronouns[#self.pronouns+1] = {gender="male",minX = printX,maxX = printX+w+12,minY=pronounY,maxY=pronounY+24}
      printX = printX+w+12
    end
    if player.gender ~= "female" then
      genderX = genderX+1
      pnouns = "She"
      w = fonts.graveFontSmall:getWidth(pnouns)
      if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w+12) then
        setColor(50,50,50,255)
        love.graphics.rectangle("fill",printX,pronounY,w,24)
        setColor(255,255,255,255)
      end
      love.graphics.print(pnouns,printX,pronounY)
      self.pronouns[#self.pronouns+1] = {gender="female",minX = printX,maxX = printX+w+12,minY=pronounY,maxY=pronounY+24}
      printX = printX+w+12
    end
    if player.gender ~= "neuter" then
      genderX = genderX+1
      pnouns = "It"
      w = fonts.graveFontSmall:getWidth(pnouns)
      if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w+12) then
        setColor(50,50,50,255)
        love.graphics.rectangle("fill",printX,pronounY,w,24)
        setColor(255,255,255,255)
      end
      love.graphics.print(pnouns,printX,pronounY)
      self.pronouns[#self.pronouns+1] = {gender="neuter",minX = printX,maxX = printX+w+12,minY=pronounY,maxY=pronounY+24}
      printX = printX+w+12
    end
    if player.gender ~= "other" then 
      genderX = genderX+1
      pnouns = "They"
      w = fonts.graveFontSmall:getWidth(pnouns)
      if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w+12) then
        setColor(50,50,50,255)
        love.graphics.rectangle("fill",printX,pronounY,w,24)
        setColor(255,255,255,255)
      end
      love.graphics.print(pnouns,printX,pronounY)
      self.pronouns[#self.pronouns+1] = {gender="other",minX = printX,maxX = printX+printX+w+12,minY=pronounY,maxY=pronounY+24}
      printX = printX+w+12
    end
  else
    local pnouns = ucfirst(player:get_pronoun('n')) .. "/" .. ucfirst(player:get_pronoun('o')) .. "/" .. ucfirst(player:get_pronoun('p'))
    w = fonts.graveFontSmall:getWidth(pnouns)
    self.pronouns[1] = {gender=player.gender,minX = nameBoxX,maxX = nameBoxX+w,minY=pronounY,maxY=pronounY+24}
    love.graphics.print(pnouns,nameBoxX,pronounY)
  end
  
  --Classes:
  setColor(255,255,255,255)
  local fontSize = 24
  local classBoxX = nameBoxX
  local classBoxY = pronounY+32
  local classBoxW = nameBoxWidth
  local classBoxH = count(playerClasses)*fontSize
  local classDescH = 200
  local w = fonts.graveFontSmall:getWidth("Class: ")
  love.graphics.print("Class: ",classBoxX-w,math.ceil(classBoxY+classBoxH/2-24))
  local printY = classBoxY
  local index = 3
  local whichClass = nil
  self.classes = {}
  for id,class in pairs(playerClasses) do
    local moused = (mouseY >= printY and mouseY <= printY+fontSize and mouseX >= classBoxX and mouseX <= classBoxX+classBoxW)
    if self.class == id then
      setColor(100,100,100,255)
      love.graphics.rectangle('fill',classBoxX,printY,classBoxW,fontSize)
    elseif self.cursorY == index or moused then
      if moused or (mouseY < classBoxY or mouseY > classBoxY+classBoxH or mouseX < classBoxX or mouseX > classBoxX+classBoxW) then
        setColor(50,50,50,255)
        whichClass = id
      else
        setColor(33,33,33,255)
      end
      love.graphics.rectangle('fill',classBoxX,printY,classBoxW,fontSize)
    end
    setColor(255,255,255,255)
    love.graphics.print(class.name,classBoxX+2,printY)
    self.classes[#self.classes+1] = {classID=id,minX=classBoxX,maxX=classBoxX+classBoxW,minY=printY,maxY=printY+fontSize}
    printY = printY+fontSize
    index = index + 1
  end
  self.afterClassIndex = index
  whichClass = whichClass or self.class
  if whichClass then
    local class = playerClasses[whichClass]
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf(class.name .. "\n" .. class.description,classBoxX,classBoxY+classBoxH,classBoxW,"center")
    
    local desc = ""
    if class.factions and #class.factions > 0 then
      desc = desc .. "Faction Membership - "
      for i,fac in ipairs(class.factions) do
        if i ~= 1 then desc = desc .. ", " end
        desc = desc .. factions[fac].name
      end
      desc = desc .. "\n"
    end
    if class.spells and #class.spells > 0 then
      desc = desc .. "Abilities - "
      for i,spell in ipairs(class.spells) do
        if i ~= 1 then desc = desc .. ", " end
        desc = desc .. possibleSpells[spell].name
      end
      desc = desc .. "\n"
    end
    if (class.items and #class.items > 0) or (class.equipment and #class.equipment > 0) then
      desc = desc .. "Items - "
      local hasItems = false
      if (class.items and #class.items > 0) then
        for i,item in ipairs(class.items) do
          if i ~= 1 then desc = desc .. ", " end
          desc = desc .. ucfirst(possibleItems[item].name)
          hasItems = true
        end
      end
      if (class.equipment and #class.equipment > 0) then
        for i,item in ipairs(class.equipment) do
          if i ~= 1 or hasItems then desc = desc .. ", " end
          desc = desc .. ucfirst(possibleItems[item].name)
        end
      end
      desc = desc .. "\n"
    end
    if class.favor and count(class.favor) > 0 then
      desc = desc .. "Favor - "
      local i = 1
      for id,fav in pairs(class.favor) do
        if i ~= 1 then desc = desc .. ", "  end
        desc = desc .. factions[id].name .. ": " .. fav
        i = i + 1
      end
      desc = desc .. "\n"
    end
    if class.stat_modifiers and count(class.stat_modifiers) > 0  then
      desc = desc .. "Stat Modifiers - "
      local i = 1
      for stat,amt in pairs(class.stat_modifiers) do
        if i ~= 1 then desc = desc .. ", "  end
        desc = desc .. ucfirst(stat) .. (amt > 0 and " +" or " ") .. amt
        i = i + 1
      end
      desc = desc .. "\n"
    end
    if class.weaknesses and count(class.weaknesses) > 0 then
      desc = desc .. "Weaknesses - "
      local i = 1
      for stat,amt in pairs(class.weaknesses) do
        if i ~= 1 then desc = desc .. ", "  end
        desc = desc .. ucfirst(stat) .. ": " .. amt .. "%"
        i = i + 1
      end
      desc = desc .. "\n"
    end
    if class.resistances and count(class.resistances) > 0 then
      desc = desc .. "Resistances - "
      local i = 1
      for stat,amt in pairs(class.resistances) do
        if i ~= 1 then desc = desc .. ", "  end
        desc = desc .. ucfirst(stat) .. ": " .. amt .. "%"
        i = i + 1
      end
      desc = desc .. "\n"
    end
    
    local _, tlines = fonts.textFont:getWrap(class.description,classBoxW)
    local descYpad = #tlines+3*prefs['fontSize']
    love.graphics.printf(desc,classBoxX+2,classBoxY+classBoxH+descYpad,classBoxW,"left")
    love.graphics.setFont(fonts.graveFontSmall)
  end
  printY = classBoxY+classBoxH
  love.graphics.rectangle("line",classBoxX,classBoxY,classBoxW,classBoxH)
  love.graphics.rectangle("line",classBoxX,printY,classBoxW,classDescH)
  printY=printY+classDescH+24
  
  
  --Tutorial Checkbox:
  local padding = (prefs['noImages'] and 16 or 32)
  love.graphics.setFont(fonts.graveFontSmall)
  local textWidth = fonts.graveFontSmall:getWidth("Tutorial Messages?")
  if self.cursorY == self.afterClassIndex then
    setColor(100,100,100,255)
    love.graphics.rectangle('fill',nameBoxX,printY,nameBoxWidth,24)
    setColor(255,255,255,255)
  elseif (mouseY > printY and mouseY < printY+24 and mouseX > nameBoxX and mouseX < nameBoxX+nameBoxWidth) then
    setColor(50,50,50,255)
    love.graphics.rectangle('fill',nameBoxX,printY,nameBoxWidth,24)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((self.tutorial and "(Y)" or "(N)"),math.floor(width/2-textWidth/2-padding*2),printY)
  else
    love.graphics.draw((self.tutorial and images.uicheckboxchecked or images.uicheckbox),math.floor(width/2-textWidth/2-padding/2),math.floor(printY+padding/8))
  end
  love.graphics.print("Tutorial Messages?",math.floor(width/2-textWidth/2+padding/2),printY)
  self.tutorialBox = {minX=nameBoxX, maxX=nameBoxX+nameBoxWidth, minY=printY, maxY=printY+24}
  printY = printY+padding
  
  --Begin Button:
  if self.class then
    self.beginButton = output:button(math.floor(width/2-75),printY,150,false,(self.cursorY == self.afterClassIndex+1 and "hover" or nil))
    love.graphics.printf("BEGIN",math.floor(width/4),printY,width/2,"center")
  else
    love.graphics.printf("Select a Class to Begin",math.floor(width/4),printY,width/2,"center")
  end
  printY = printY+64
  
  --Seed info:
  local seedWidth = fonts.textFont:getWidth("Seed: 100000000000")
  local seedX = math.ceil(width/2-seedWidth/2)
  if self.cursorY == self.afterClassIndex+2 then
    setColor(50,50,50,255)
    love.graphics.rectangle('fill',seedX,printY,seedWidth,16)
    local w = fonts.textFont:getWidth("Seed: " .. (self.seed or ""))
    if self.lineOn then
      local lineX = seedX+math.ceil(seedWidth/2+w/2)
      setColor(255,255,255,255)
      love.graphics.line(lineX,printY+2,lineX,printY+14)
    end
    setColor(255,255,255,255)
  elseif mouseY >= printY and mouseY <=printY+16 and mouseX >= seedX and mouseX <= seedX+seedWidth then
    setColor(33,33,33,255)
    love.graphics.rectangle('fill',seedX,printY,seedWidth,16)
  end
  setColor(255,255,255,255)
  love.graphics.setFont(fonts.textFont)
  love.graphics.printf("Seed: " .. (self.seed or ""),seedX,printY,seedWidth,"center")
  self.seedBox = {minY=printY,maxY=printY+16,minX=seedX,maxX=seedX+seedWidth}
  love.graphics.rectangle('line',seedX,printY,seedWidth,16)
  printY = printY+fontSize

  --Copy/paste buttons:
  self.copyButton = output:button(math.floor(width/2-74),printY,64,false,((self.cursorY == self.afterClassIndex+3 and self.cursorX == 1) and "hover"),"Copy")
  self.pasteButton = output:button(math.ceil(width/2+seedWidth/2)-64,printY,64,false,((self.cursorY == self.afterClassIndex+3 and self.cursorX == 2) and "hover"),"Paste")
  --Cheats button:
  self.cheatsButton = output:button(math.ceil(width/2)-64,printY+42,136,false,(self.cursorY == self.afterClassIndex+4 and "hover"),"Game Modifiers")

  
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
      player.gender = self.pronouns[self.cursorX].gender
      self.cursorY = 3
    elseif self.cursorY >= 3 and self.cursorY < self.afterClassIndex then
      self.class = self.classes[self.cursorY-2].classID
      self.cursorY = self.afterClassIndex
    elseif self.cursorY == self.afterClassIndex then
      self.tutorial = not self.tutorial
    elseif self.cursorY == self.afterClassIndex+1 then --"begin" line
      self:startGame()
    elseif self.cursorY == self.afterClassIndex+2 then --seed line
      self.cursorY = self.afterClassIndex+1
    elseif self.cursorY == self.afterClassIndex+3 then --copy/paste buttons
      if self.cursorX == 1 then --copy
        love.system.setClipboardText((self.seed or ""))
      elseif self.cursorX == 2 then -- paste
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
    if self.cursorY == 2 then
      self.cursorX = 1
    end
    if not self.class and self.cursorY == self.afterClassIndex+1 then self.cursorY = self.afterClassIndex end
  elseif (key == "down") then
    self.cursorY = self.cursorY + 1
    if self.cursorY == 2 then
      self.cursorX = 1
    end
    if not self.class and self.cursorY == self.afterClassIndex+1 then self.cursorY = self.afterClassIndex+2 end
  elseif key == "left" then
    self.cursorX = math.max(1,self.cursorX - 1)
  elseif key == "right" then
    self.cursorX = self.cursorX + 1
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
    return
  end
  
  --Name Selection:
  if y > 32 and y<56 then
    self.cursorY = 1
  end
  
  --Pronoun Selection:
  if y >= self.pronouns[1].minY and y <= self.pronouns[1].maxY then
    for i = 1,4,1 do
      if x >= self.pronouns[i].minX and x <= self.pronouns[i].maxX then
        player.gender = self.pronouns[i].gender
      end
    end
  end --end gender if
  
  --Class Selection:
  if y >= self.classes[1].minY and y <= self.classes[#self.classes].maxY and x >= self.classes[1].minX and x <= self.classes[1].maxX then
    print('class select')
    for i = 1,#self.classes,1 do
      if y >= self.classes[i].minY and y <= self.classes[i].maxY then
        print('classY')
        self.class = self.classes[i].classID
      end
    end
  end --end class if
  
  --Tutorial Box:
  if y >= self.tutorialBox.minY and y <= self.tutorialBox.maxY and x >= self.tutorialBox.minX and x <= self.tutorialBox.maxX then
    self.tutorial = not self.tutorial
  end
  
  --Begin Button:
  if self.class and self.beginButton and y > self.beginButton.minY and y < self.beginButton.maxY and x > self.beginButton.minX and x < self.beginButton.maxX then
    self:startGame()
  end
  
  --Seedbox:
  if y >= self.seedBox.minY and y <= self.seedBox.maxY and x >= self.seedBox.minX and x <= self.seedBox.maxX then
    self.cursorY = self.afterClassIndex+2
  end
  
  --Copy Button:
  if y >= self.copyButton.minY and y <= self.copyButton.maxY and x >= self.copyButton.minX and x <= self.copyButton.maxX then
    love.system.setClipboardText((self.seed or ""))
  end
  
  --Paste Button:
  if y >= self.pasteButton.minY and y <= self.pasteButton.maxY and x >= self.pasteButton.minX and x <= self.pasteButton.maxX then
    self.seed = tonumber(love.system.getClipboardText())
  end
  
  --Cheats Button:
  if y >= self.cheatsButton.minY and y <= self.cheatsButton.maxY and x >= self.cheatsButton.minX and x <= self.cheatsButton.maxX then
    Gamestate.switch(cheats)
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
  if self.cursorY < 0 then self.cursorY = 0 elseif (self.cursorY > 10) then self.cursorY = 10 end
  if self.cursorX < 1 then
    self.cursorX = 1
  elseif self.cursorX > 4 and self.cursorY == 2 then
    self.cursorX = 4
  elseif self.cursorX > 2 and self.cursorY ~= 2 then
    self.cursorX = 2
  end
	local x,y = love.mouse.getPosition()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
	if x > math.floor(width/3) and x < math.floor(width/3)*2 and (y ~= output.mouseY or x ~= output.mouseX) then -- only do this if the mouse has moved, and if it's in range
		output.mouseX,output.mouseY = x,y
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

function newgame:startGame()
  new_game((tonumber(self.seed) > 0 and tonumber(self.seed) or 1),self.tutorial,self.cheats,self.class)
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
  if currGame.cheats.fullMap == true then currMap:reveal() end
end    