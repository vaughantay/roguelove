spellscreen = {}

function spellscreen:enter()
  self.cursorY = 0
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local boxW,boxH = 450,300
  local padX,padY = 0,0
  local descY = 0
  local x,y=math.floor(width/2/uiScale-boxW/2),math.floor(height/2/uiScale-boxH/2)
  self.x,self.y,self.boxW,self.boxH=x,y,boxW,boxH
  if prefs['noImages'] == true then
    padX,padY=5,5
  else
    padX,padY=20,20
  end
  descY = y+padY+(count(player.spells)+2)*16
  self.descY = descY
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
  local descY = self.descY
  local x,y=self.x,self.y
	
  if prefs['noImages'] == true then
    setColor(20,20,20,200)
    love.graphics.rectangle("fill",x,y,boxW,boxH)
    setColor(150,150,150,255)
    love.graphics.line(x,descY,x+padX+boxW,descY)
    setColor(255,255,255,255)
    love.graphics.rectangle("line",x,y,boxW,boxH)
  else
    setColor(20,20,20,200)
    love.graphics.rectangle("fill",x+16,y+16,boxW,boxH)
    setColor(150,150,150,255)
    love.graphics.line(x,descY,x+padX+boxW,descY)
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
  
  if (player.spells[self.cursorY] ~= nil) then
    local printY = y+padY+((self.cursorY+1)*14)
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",x+padX,printY,boxW-8,16)
    setColor(255,255,255,255)
	end
  
  love.graphics.printf("Spells and Abilities",x+padX,y+padY,boxW-16,"center")
	local spells = {}
	for i, spellID in pairs(player.spells) do
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
		love.graphics.print(letter .. ") " .. name .. (player.cooldowns[name] and " (" .. player.cooldowns[name] .. " turns to recharge)" or "") .. (target_type == "passive" and " (Passive)" or ""),x+padX,y+padY+((line-1)*14))
    if player.cooldowns[name] or possibleSpells[spellID]:requires(player) == false then
      setColor(255,255,255,255)
    end
		line = line+1
	end
  
  if (player.spells[self.cursorY] ~= nil) then
    local spell = possibleSpells[player.spells[self.cursorY]]
    local target_type = spell.target_type
    local targetText = ""
    
    if target_type == "self" then
      targetText = "This ability does not require a target."
    elseif target_type == "creature" then
      targetText = "This ability can be used on creatures."
    elseif target_type == "square" then
      targetText = "This ability can be used on any square in range."
    elseif target_type == "passive" then
      targetText = "This ability is passive and is used automatically when needed."
    end
    
    love.graphics.print(targetText,x+padX,descY+8)
    love.graphics.printf(spell:get_description(),x+padX,descY+32,boxW-16,"left")
  end
  self.closebutton = output:closebutton(self.x+(prefs['noImages'] and 8 or 20),self.y+(prefs['noImages'] and 8 or 20),nil,true)
  love.graphics.pop()
end

function spellscreen:keypressed(key)
	if (key == "escape") then
		self:switchBack()
	elseif (key == "return") or key == "kpenter" then
		if (possibleSpells[player.spells[self.cursorY]] and possibleSpells[player.spells[self.cursorY]]:target(target,player) ~= false) then
			advance_turn()
		end
		self:switchBack()
	elseif (key == "up") then
		if (player.spells[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
		end
	elseif (key == "down") then
		if (player.spells[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
		end
	else
		local id = string.byte(key)-96
		if (player.spells[id] ~= nil) then
			if(possibleSpells[player.spells[id]]:target(target,player) ~= false) then
				advance_turn()
			end
			self:switchBack()
		end
	end
end

function spellscreen:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
	if (x/uiScale > self.x and x/uiScale < self.x+self.boxW and y/uiScale > self.y and y/uiScale < self.descY) then
    if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then self:switchBack() end
		if (player.spells[self.cursorY] ~= nil) then
			if(possibleSpells[player.spells[self.cursorY]]:target(target,player) ~= false) then
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
		if (self.cursorY and player.spells[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
		end
	elseif y < 0 then
    self.cursorY = self.cursorY or 0
		if (player.spells[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
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
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale, y/uiScale
	if (x ~= output.mouseX or y ~= output.mouseY) then -- only do this if the mouse has moved
    output.mouseX,output.mouseY = x,y
		if (x > self.x and x < self.x+self.boxW and y > self.y and y < self.descY) then --if inside spell box
      local mouseY = y-(self.y-self.padY)
			local listY = math.floor(mouseY/14)
      local yMod = (prefs['noImages'] and 2 or 4)
			if (player.spells[listY-yMod] ~= nil) then
				self.cursorY=listY-yMod
      else
        self.cursorY=nil
			end
		end
	end
end

function spellscreen:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end