spellscreen = {}

function spellscreen:enter()
  self.cursorY = 0
  self.scrollY = 0
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local boxW,boxH = 450,300
  local padX,padY = 0,0
  local x,y=math.floor(width/2/uiScale-boxW/2),math.floor(height/2/uiScale-boxH/2)
  self.spellLines = {}
  self.x,self.y,self.boxW,self.boxH=x,y,boxW,boxH
  if prefs['noImages'] == true then
    padX,padY=5,5
  else
    padX,padY=20,20
  end
  self.padX,self.padY = padX,padY
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
end

function spellscreen:draw()
  local uiScale = (prefs['uiScale'] or 1)
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
	local line = 3
  local boxW,boxH = self.boxW,self.boxH
  local padX,padY = self.padX,self.padY
  local x,y=self.x,self.y
  
  if prefs['noImages'] == true then
    setColor(20,20,20,200)
    love.graphics.rectangle("fill",x,y,boxW,boxH)
    setColor(150,150,150,255)
    setColor(255,255,255,255)
    love.graphics.rectangle("line",x,y,boxW,boxH)
  else
    setColor(20,20,20,200)
    love.graphics.rectangle("fill",x+16,y+16,boxW,boxH)
    setColor(150,150,150,255)
    setColor(255,255,255,255)
    love.graphics.draw(images.borders.borderImg,images.borders.ul,x,y)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,x+boxW,y)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,x,y+boxH)
    love.graphics.draw(images.borders.borderImg,images.borders.lr,x+boxW,y+boxH)
    for x=x+16,x+boxW-16,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.u,x,y)
      love.graphics.draw(images.borders.borderImg,images.borders.d,x,y+boxH)
    end
    for y=y+16,y+boxH-16,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.l,x,y)
      love.graphics.draw(images.borders.borderImg,images.borders.r,x+boxW,y)
    end
  end
  
  love.graphics.setFont(fonts.textFont)
  local fontSize = prefs['fontSize']
  
  love.graphics.printf("Spells and Abilities",x+padX,y+padY,boxW-16,"center")
  
  --Drawing the text:
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",x+padX,y+padY+fontSize,boxW-padX*2,boxH-padY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  local playerSpells = player:get_spells()
  --Draw the highlight box:
  if (playerSpells[self.cursorY] ~= nil) then
    local printY = y+padY+((self.cursorY+1)*fontSize)
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",x+padX,printY,boxW-8,fontSize+2)
    setColor(255,255,255,255)
	end
  --Display the spells:
  local bottom = 0
	local spells = {}
	for i, spellID in pairs(playerSpells) do
		local letter = string.char(i+96)
		spells[i] = spellID
    local name = possibleSpells[spellID].name
    local target_type = possibleSpells[spellID].target_type
    if player.cooldowns[name] or possibleSpells[spellID]:requires(player) == false then
      if self.cursorY == i then
        setColor(0,0,0,255)
      else
        setColor(100,100,100,255)
      end --end color if
    end --end cooldowns if
    local printY = y+padY+((line-1)*fontSize)
		love.graphics.print(letter .. ") " .. name .. (player.cooldowns[name] and " (" .. player.cooldowns[name] .. " turns to recharge)" or "") .. (target_type == "passive" and " (Passive)" or ""),x+padX,printY)
    if player.cooldowns[name] or possibleSpells[spellID]:requires(player) == false then
      setColor(255,255,255,255)
    end
		line = line+1
    self.spellLines[i] = {minY=printY,maxY=printY+fontSize+2}
    bottom = printY+fontSize+2
	end
  bottom = bottom+fontSize
  
  love.graphics.setStencilTest()
  
  --Description Box:
  if (playerSpells[self.cursorY] ~= nil) then
    local spell = possibleSpells[playerSpells[self.cursorY]]
    local target_type = spell.target_type
    local spellText = spell:get_description()
    
    if target_type == "self" then
      spellText = spellText .."\nThis ability does not require a target."
    elseif target_type == "creature" then
      spellText = spellText .. "\nThis ability can be used on creatures."
    elseif target_type == "tile" then
      spellText = spellText .. "\nThis ability can be used on any tile in range."
    elseif target_type == "passive" then
      spellText = spellText .. "\nThis ability is passive and is used automatically when needed."
    end
    
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(fonts.descFont)
    local width, tlines = fonts.descFont:getWrap(spellText,300)
    local height = #tlines*(prefs['descFontSize']+3)+math.ceil(prefs['fontSize']/2)
    x,y = round((x+boxW)/2),self.spellLines[self.cursorY].minY+round((self.spellLines[self.cursorY].maxY-self.spellLines[self.cursorY].minY)/2)
    if (y+20+height < love.graphics.getHeight()) then
      setColor(255,255,255,185)
      love.graphics.rectangle("line",x+22,y+20,302,height)
      setColor(0,0,0,185)
      love.graphics.rectangle("fill",x+23,y+21,301,height-1)
      setColor(255,255,255,255)
      love.graphics.printf(ucfirst(spellText),x+24,y+22,300)
    else
      setColor(255,255,255,185)
      love.graphics.rectangle("line",x+22,y+20-height,302,height)
      setColor(0,0,0,185)
      love.graphics.rectangle("fill",x+23,y+21-height,301,height-1)
      setColor(255,255,255,255)
      love.graphics.printf(ucfirst(spellText),x+24,y+22-height,300)
    end
    love.graphics.setFont(oldFont)
  end
  love.graphics.pop()
  
  --Scrollbars
  if bottom > self.y+self.boxH then
    self.scrollMax = bottom-(self.y+self.boxH)
    local scrollAmt = self.scrollY/self.scrollMax
    self.scrollPositions = output:scrollbar(self.x+self.boxW-padX,self.y+padY,self.y+self.boxH,scrollAmt,true)
  end
  
  self.closebutton = output:closebutton(self.x+(prefs['noImages'] and 8 or 20),self.y+(prefs['noImages'] and 8 or 20),nil,true)
  love.graphics.pop()
end

function spellscreen:keypressed(key)
  local letter = key
  key = input:parse_key(key)
  local playerSpells = player:get_spells()
	if (key == "escape") then
		self:switchBack()
	elseif (key == "enter") or key == "wait" then
		if (possibleSpells[playerSpells[self.cursorY]] and possibleSpells[playerSpells[self.cursorY]]:target(target,player) ~= false) then
			advance_turn()
		end
		self:switchBack()
	elseif (key == "north") then
		if (playerSpells[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
		end
    if self.spellLines[self.cursorY].minY-self.scrollY-prefs['fontSize'] < self.y+self.padY+prefs['fontSize'] then
      self:scrollUp()
    end
	elseif (key == "south") then
		if (playerSpells[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
		end
    if self.spellLines[self.cursorY].maxY-self.scrollY+prefs['fontSize'] > self.y+prefs['fontSize']+self.boxH then
      self:scrollDown()
    end
	else
		local id = string.byte(letter)-96
		if (playerSpells[id] ~= nil) then
			if(possibleSpells[playerSpells[id]]:target(target,player) ~= false) then
				advance_turn()
			end
			self:switchBack()
		end
	end
end

function spellscreen:mousepressed(x,y,button)
  local playerSpells = player:get_spells()
  local uiScale = (prefs['uiScale'] or 1)
	if (x/uiScale > self.x and x/uiScale < self.x+self.boxW and y/uiScale > self.y and y/uiScale < self.y+self.boxH) then
    if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then self:switchBack() end
		if (playerSpells[self.cursorY] ~= nil and (not self.scrollPositions or x/uiScale < self.x+self.boxW-self.padX)) then
			if(possibleSpells[playerSpells[self.cursorY]]:target(target,player) ~= false) then
				advance_turn()
			end
			self:switchBack()
		end
  else
    self:switchBack()
	end
end

function spellscreen:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end --end button type if
end

function spellscreen:scrollUp()
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
  end
end

function spellscreen:scrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
    end
  end
end

function spellscreen:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
  local playerSpells = player:get_spells()
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale, y/uiScale
	if (x ~= output.mouseX or y ~= output.mouseY) then -- only do this if the mouse has moved
    output.mouseX,output.mouseY = x,y
		if (x > self.x and x < self.x+self.boxW-(not self.scrollPositions and 0 or self.padX) and y > self.y+prefs['fontSize']+self.padY and y < self.y+self.boxH) then --if inside spell box
      for i,coords in ipairs(self.spellLines) do
        if y > coords.minY-self.scrollY and y < coords.maxY-self.scrollY then
          self.cursorY = i
          break
        end
      end
		end
	end --end if mouse has moved if
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local x,y = love.mouse.getPosition()
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

function spellscreen:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end