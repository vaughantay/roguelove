newgame = {whiteAlpha=0,cheats = {}}

function newgame:enter(previous)
  self.lineCountdown = 0.5
  self.lineOn = true
  if not self.seed or previous == menu then self.seed = random(999999,2147483647) end
  if previous == menu then
    self:lightning()
  end
  self.blackAmt=nil
  if not totalstats or not totalstats.games or totalstats.games == 0 then
    self.tutorial = true
  end
  self.dirtSkyCanvas = nil
end

function newgame:preDrawDirt()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  self.dirtSkyCanvas = love.graphics.newCanvas(width,height)
  love.graphics.setCanvas(self.dirtSkyCanvas)
  local dirt = ""
  for i=1,width,14 do
    dirt = dirt .. "# "
  end
  --Draw the dirt and sky:
  local actualDirt = ""
  for y=1,height,14 do
    if y >= 540 then
      setColor(153,103,73,255-(255*((y-540)/(height-540))))
      love.graphics.print(dirt,1,y)
    else
      if 255-(255*(y/540)) > 0 then
        setColor(0,181,255,255-(255*(y/540)))
        love.graphics.print(dirt,1,y)
      end
    end
  end
  love.graphics.setCanvas()
end

function newgame:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  if output.cursorY < 0 then output.cursorY = 0 elseif (output.cursorY > 9) then output.cursorY = 9 end
  if output.cursorX < 1 then output.cursorX = 1 elseif output.cursorX > 2 then output.cursorX = 2 end
  love.graphics.setFont(fonts.mapFont)
  love.graphics.push()
  love.graphics.translate(0,math.floor(-((self.blackAmt and self.blackAmt/255 or 0/255))*height/2))

  if prefs['noImages'] == true then
    -- Calculate the dirt and sky:
    local dirttime = os.clock()
    love.graphics.setFont(fonts.mapFont)
    local grass = ""
    for i=1,width,7 do
      if (i % 5 == 0) then grass = grass .. "\\"
      elseif (i % 7 == 0 or i == 3) then grass = grass .. "/"
      elseif (i % 11 == 0 or i == 2) then grass = grass .. "|"
      else grass = grass .. " " end
    end
    --Draw the dirt and sky:
    if not self.dirtSkyCanvas then
      self:preDrawDirt()
    end
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(self.dirtSkyCanvas)
    love.graphics.setBlendMode("alpha")
    
    -- Draw the tombstone:
    setColor(0,0,0,255)
    love.graphics.rectangle('fill',math.ceil(width/2-256),56,520,490)
    setColor(255,255,255,255)
    for y = 50,540,14 do
      if (y == 50) then
        for x = width/2-256,(width/2)+256,13 do
          love.graphics.print("#",x,y)
        end
      else
        love.graphics.print("#",width/2-256,y)
        love.graphics.print("#",width/2+256,y)
      end
    end
    -- Draw the grass:
    setColor(0,255,0)
    love.graphics.print(grass,1,538)
    setColor(255,255,255,255)
  else --graphical menu:
    setColor(255,255,255,255)
    for x = 0, width, 512 do
      love.graphics.draw(images['uimenuskydark'],x,0)
    end
    love.graphics.draw(images['uimenuskydark'],width-512,0)
          
    love.graphics.draw(images['uigravestone'],width/2-256,50)
    for x = 0, width/64, 1 do
      for y=572,height,32 do
        setColor(255,255,255,255-(255*((y-572)/(height-572))))
        love.graphics.draw(images['uimenudirt'],x*64,y)
      end
      setColor(255,255,255,255)
      love.graphics.draw(images['uimenudirtgrass'],x*64,550)
      if (x % 3 == 0 or x % 13 == 0) then love.graphics.draw(images['uimenugrass1'],x*64,490)
      elseif (x % 7 == 0 or x % 9 == 0) then love.graphics.draw(images['uimenugrass2'],x*64,490)
      elseif (x % 5 == 0 or x % 11 == 0) then love.graphics.draw(images['uimenugrass3'],x*64,490) end
    end
  end --end noimages if

  -- Define some coordinates:
  local nameBoxX=math.floor(width/2)-256+48-(prefs['noImages'] and 32 or 0)
  local nameBoxWidth = 512-128+(prefs['noImages'] and 96 or 0)
  local selectBoxX = math.floor(width/3)+85
  local selectBoxWidth = math.floor(width/3)-170
  -- Draw the cursor:
  local seedWidth = fonts.textFont:getWidth("Seed: 100000000000")
  setColor(100,100,100,255)
  if (output.cursorY == 1) then
    love.graphics.rectangle('fill',nameBoxX,144,nameBoxWidth,24)
  elseif (output.cursorY >= 2 and output.cursorY <= 4) then
    love.graphics.rectangle('fill',nameBoxX,175,nameBoxWidth,96)
  elseif output.cursorY == 5 then
    love.graphics.rectangle('fill',nameBoxX,354,nameBoxWidth,24)
  elseif output.cursorY == 6 then
    --love.graphics.rectangle('fill',width/2-74,401,149,39)
  elseif output.cursorY == 7 then
    love.graphics.rectangle('fill',math.ceil(width/2-seedWidth/2),572,seedWidth,16)
  elseif output.cursorY == 8 then
    -- do nothing, it's handled by buttons later on
  end
  
  if output.cursorY ~= 7 then
    setColor(50,50,50,255)
    love.graphics.rectangle('fill',math.ceil(width/2-seedWidth/2),572,seedWidth,16)
  end
  -- Draw the Text:
  setColor(255,255,255,255)
  love.graphics.setFont(fonts.graveFontBig)
  local w = fonts.graveFontBig:getWidth("Here Lies")
  love.graphics.printf("Here Lies",math.floor(width/3),100,math.floor(width/3),"center")
  --love.graphics.draw((output.cursorY == 1 and output.cursorX == 2 and images.uidicebuttonhover or images.uidicebutton),math.floor(width/2+w/2)+16,108)
  love.graphics.printf("??/??/???? - " .. os.date("%x"),math.floor(width/3),275,math.floor(width/3),"center")
  love.graphics.setFont(fonts.graveFontSmall)
  if output.cursorY == 1 then
    setColor(255,255,255,255)
    --love.graphics.print(player.properName,nameBoxX+3,140)
    love.graphics.printf(player.properName,math.floor(width/3),142,math.floor(width/3),"center")
    if self.lineOn then
      local w = fonts.graveFontSmall:getWidth(player.properName)
      local lineX = math.floor(width/3+width/6+w/2)
      love.graphics.line(lineX,148,lineX,165)
    end
  else
    love.graphics.printf(player.properName,math.floor(width/3),142,math.floor(width/3),"center")
  end
  love.graphics.setFont(fonts.graveFontSmall)
  --output:button(math.floor(width/2-75),450,150,false,(output.cursorY == 6 and "hover" or nil))
  local buttonWidth = fonts.graveFontSmall:getWidth("A Good Woman")+64
  local buttonX = math.floor(width/2-buttonWidth/2)
  if output.cursorY >= 2 and output.cursorY <= 4 then --only show other options of gender is highlighted
    output:button(buttonX,200,buttonWidth,false,(output.cursorY == 3 and "hover" or nil))
    output:button(buttonX,235,buttonWidth,false,(output.cursorY == 4 and "hover" or nil))
  end
  if (player.gender == "male") then
    love.graphics.printf("A Great Man",math.floor(width/3),175,math.floor(width/3),"center")
    if output.cursorY >= 2 and output.cursorY <= 4 then --only show other options of gender is highlighted
      setColor(225,225,225,255)
      love.graphics.printf("A Great Woman",buttonX,200,buttonWidth,"center")
      love.graphics.printf("A Great Person",buttonX,235,buttonWidth,"center")
    end
  elseif (player.gender == "female") then
    love.graphics.printf("A Great Woman",math.floor(width/3),175,math.floor(width/3),"center")
    if output.cursorY >= 2 and output.cursorY <= 4 then --only show other options of gender is highlighted
      setColor(225,225,225,255)
      love.graphics.printf("A Great Man",buttonX,200,buttonWidth,"center")
      love.graphics.printf("A Great Person",buttonX,235,buttonWidth,"center")
    end
  else
    love.graphics.printf("A Great Person",math.floor(width/3),175,math.floor(width/3),"center")
    if output.cursorY >= 2 and output.cursorY <= 4 then --only show other options of gender is highlighted
      setColor(225,225,225,255)
      love.graphics.printf("A Great Man",buttonX,200,buttonWidth,"center")
      love.graphics.printf("A Great Woman",buttonX,235,buttonWidth,"center")
    end
  end
  setColor(255,255,255,255)
  love.graphics.setFont(fonts.graveFontBig)
  love.graphics.printf("Gone, but not forgotten...",width/4,305,width/2,"center")
  
  --Tutorial Checkbox:
  local padding = (prefs['noImages'] and 16 or 32)
  love.graphics.setFont(fonts.graveFontSmall)
  local textWidth = fonts.graveFontSmall:getWidth("Tutorial Messages?")
  if prefs['noImages'] then
    love.graphics.print((self.tutorial and "(Y)" or "(N)"),math.floor(width/2-textWidth/2-padding*2),350)
  else
    love.graphics.draw((self.tutorial and images.uicheckboxchecked or images.uicheckbox),math.floor(width/2-textWidth/2-padding/2),math.floor(350+padding/4))
  end
  love.graphics.print("Tutorial Messages?",math.floor(width/2-textWidth/2+padding/2),350)
  --love.graphics.setFont(fonts.graveFontSmall)
  
  --setColor(50,50,50,255)
  --love.graphics.rectangle('line',width/2-75,400,150,41)
  setColor(255,255,255,255)
  output:button(math.floor(width/2-75),450,150,false,(output.cursorY == 6 and "hover" or nil))
  love.graphics.printf("BEGIN",math.floor(width/4),450,width/2,"center")
  love.graphics.setFont(fonts.textFont)
  love.graphics.printf("Seed: " .. (self.seed or ""),math.floor(width/4),572,width/2,"center")
  --[[setColor(50,50,50,255)
  love.graphics.rectangle('line',width/2-70,600,50,26)
  love.graphics.rectangle('line',width/2+25,600,50,26)
  setColor(255,255,255,255)]]
  --love.graphics.rectangle('fill',width/2-69,601,48,24)
 -- love.graphics.rectangle('fill',width/2+26,601,48,24)
  --Copy/paste buttons:
  output:button(math.floor(width/2-74),600,64,false,((output.cursorY == 8 and output.cursorX == 1) and "hover"))
  output:button(math.ceil(width/2+seedWidth/2)-64,600,64,false,((output.cursorY == 8 and output.cursorX == 2) and "hover"))
  love.graphics.print("Copy",math.floor(width/2-60),605)
  love.graphics.print("Paste",math.floor(width/2+24),605)
  if output.cursorY == 7 then
    local w = fonts.textFont:getWidth("Seed: " .. (self.seed or ""))
    if self.lineOn then
      love.graphics.line(width/2+w/2,574,width/2+w/2,586)
    end
  end
  --Cheats button:
  output:button(math.ceil(width/2)-32,641,68,false,(output.cursorY == 9 and "hover"))
  love.graphics.print("Cheats",math.floor(width/2)-24,646)
  
  --close button:
  self.closebutton = output:closebutton((prefs['noImages'] and width/2-256+16 or width/2-256+40),(prefs['noImages'] and 50+24 or 50+56))
  
  love.graphics.pop()
  --White and black for flashes and fadeouts
  setColor(255,255,255,self.whiteAlpha)
  love.graphics.rectangle('fill',0,0,width,height)
  self:drawrain()
  if self.blackAmt then
    setColor(0,0,0,self.blackAmt)
    love.graphics.rectangle('fill',0,0,width,height)
  end
  setColor(255,255,255,255)
end

function newgame:drawrain()
  setColor(200,200,255,150)
  for _,r in pairs(self.rain) do
    love.graphics.print("|",r.x,r.y)
  end
end

function newgame:updaterain(dt)
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()
  if random(1,10) == 1 then
    local r = {x=random(1,width),y=0}
    self.rain[r] = r
  end
  for _,r in pairs(self.rain) do
    r.y = r.y+height*dt
    if r.y > 550 then
      self.rain[r] = nil
    end
  end
end

function newgame:keypressed(key)
  if self.blackAmt then return false end
  if (key == "return") then
    if output.cursorY == 0 then -- not selecting anyting
      output.cursorY = 6 --select button
    elseif (output.cursorY == 1) then -- name entry
      output.cursorY = 2
    elseif (output.cursorY == 2) then --first gender line
      output.cursorY = 6
    elseif (output.cursorY == 3) then --second gender line
      if player.gender == "male" then player.gender = "female"
      elseif player.gender == "female" then player.gender = "male"
      else player.gender = "male" end
      output.cursorY = 6
    elseif (output.cursorY == 4) then --third gender line
      if player.gender == "male" then player.gender = "unspecified"
      elseif player.gender == "female" then player.gender = "unspecified"
      else player.gender = "female" end
      output.cursorY = 6
    elseif output.cursorY == 5 then
      self.tutorial = not self.tutorial
    elseif output.cursorY == 6 then --"begin" line
      new_game((tonumber(self.seed) > 0 and tonumber(self.seed) or 1),self.tutorial)
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
    elseif output.cursorY == 7 then --seed line
      output.cursorY = 6
    elseif output.cursorY == 8 then --copy/paste buttons
      if output.cursorX == 1 then --copy
        love.system.setClipboardText((self.seed or ""))
      elseif output.cursorX == 2 then -- paste
        self.seed = tonumber(love.system.getClipboardText())
      end
    elseif output.cursorY == 9 then --cheats button
      Gamestate.switch(cheats)
    end -- end cursor check
  elseif (key == "tab") then
    if output.cursorY == 1 then output.cursorY = 2
    else output.cursorY = 6 end
  elseif (key == "backspace") then
    if output.cursorY == 1 then
      player.properName = string.sub(player.properName,1,#player.properName-1)
    elseif output.cursorY == 7 then
      local seed = tostring(self.seed)
      local newSeed = tonumber(string.sub(seed,1,#seed-1))
      self.seed = newSeed
    end
  elseif (key == "up") then
    output.cursorY = output.cursorY - 1
  elseif (key == "down") then
    output.cursorY = output.cursorY + 1
  elseif key == "left" then
    output.cursorX = output.cursorX - 1
  elseif key == "right" then
    output.cursorX = output.cursorX + 1
  elseif tonumber(key) and output.cursorY == 7 then
    local newSeed = tonumber((self.seed or "").. key)
    if newSeed < math.pow(2,32) then
      self.seed = newSeed
    end --end seed bounds check
  elseif key == "escape" then
    Gamestate.switch(menu)
    menu:lightning()
    menu.rain = self.rain
  end --end key if
end

function newgame:mousepressed(x,y,button)
  if self.blackAmt then return false end
  if button == 2 then
    Gamestate.switch(menu)
    menu:lightning()
    return
  end
  local width = love.graphics.getWidth()
  local nameBoxX=math.floor(width/2)-256+48-(prefs['noImages'] and 32 or 0)
  local nameBoxWidth = 512-128+(prefs['noImages'] and 96 or 0)
  if x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY then
    Gamestate.switch(menu)
    menu:lightning()
  elseif output.cursorY ~= 1 and x > nameBoxX and x < nameBoxX+nameBoxWidth then
    output.mouseX,output.mouseY=1,1
    return self:keypressed("return")
  end
end

function newgame:wheelmoved(x,y)
  if self.blackAmt then return false end
  if y > 0 then
		output.cursorY = output.cursorY-1
	elseif y < 0 then
		output.cursorY = output.cursorY+1
  end
end

function newgame:update(dt)
	local x,y = love.mouse.getPosition()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
	if x > math.floor(width/3) and x < math.floor(width/3)*2 and (y ~= output.mouseY or x ~= output.mouseX) then -- only do this if the mouse has moved, and if it's in range
		output.mouseX,output.mouseY = x,y
		if (y < 170) then output.cursorY = 1
    elseif (y > 175 and y < 275) then
      output.cursorY = 2
      if x > width/5*2 and x < width/5*3 then
        if (y >= 200 and y < 225) then output.cursorY = 3
        elseif (y >= 235 and y < 260) then output.cursorY = 4 end
      end
    elseif (y >= 345 and y < 375) then output.cursorY = 5
    elseif (y >= 450 and y < 490) then output.cursorY = 6
    elseif (y >=572 and y < 586) then output.cursorY = 7
    elseif (y >=600 and y < 632) and (x >= width/2-70 and x <= width/2-20) then output.cursorY,output.cursorX = 8,1
    elseif (y >=600 and y < 632) and (x >= width/2+25 and x <= width/2+75) then output.cursorY,output.cursorX = 8,2
    elseif (y >=641 and y < 673) then output.cursorY = 9
    else output.cursorY = 0
    end
	end
  self.lineCountdown = self.lineCountdown-dt
  if self.lineCountdown <= 0 then
    self.lineCountdown = .5
    self.lineOn = not self.lineOn
  end
  if player.properName == "" and output.cursorY ~= 1 then
    player.properName = namegen:generate_human_name(player)
  end
  self:updaterain(dt)
end

function newgame:textinput(text)
  if output.cursorY == 1 then
    player.properName = player.properName .. text
  end
end

function newgame:lightning()
  self.whiteAlpha = random(125,255)
  tween(0.5,self,{whiteAlpha=0})
  output:sound('thunder1')
end