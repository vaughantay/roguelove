multipickup = {}

function multipickup:enter()
  self.cursorY = 0
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local boxW,boxH = 450,300
  local padX,padY = 0,0
  local descY = 0
  local fontSize = prefs['fontSize']
  local x,y=math.floor(width/2/uiScale-boxW/2),math.floor(height/2/uiScale-boxH/2)
  self.x,self.y,self.boxW,self.boxH=x,y,boxW,boxH
  if prefs['noImages'] == true then
    padX,padY=5,5
  else
    padX,padY=20,20
  end
  self:refresh_items()
  descY = y+padY+(count(self.items)+2)*(fontSize+2)
  self.descY = descY
  self.padX,self.padY = padX,padY
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
end

function multipickup:refresh_items()
  self.items = currMap:get_tile_items(player.x,player.y,true)
  if count(self.items) == 0 then
    self:switchBack()
  end
end

function multipickup:pickup(item)
  if player:pickup(item) ~= false then
    advance_turn()
    self:refresh_items()
    if self.cursorY > #self.items then self.cursorY = #self.items end
  end
end

function multipickup:draw()
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
  local fontSize = prefs['fontSize']
	
  love.graphics.line(x,descY,x+padX+boxW,descY)
  output:draw_window(x,y,x+boxW,y+boxH)
  
  love.graphics.setFont(fonts.textFont)
  
  if (self.items[self.cursorY] ~= nil) then
    local printY = y+padY+((self.cursorY+1)*fontSize)
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",x+padX,printY,boxW-8,fontSize+2)
    setColor(255,255,255,255)
	end
  
  love.graphics.printf("Pick Up Items",x+padX,y+padY,boxW-16,"center")
	local items = {}
	for i, item in ipairs(self.items) do
		local letter = string.char(i+96)
    local name = item:get_name(true)
		love.graphics.print(letter .. ") " .. name,x+padX,y+padY+((line-1)*fontSize))
		line = line+1
	end
  
  if (self.items[self.cursorY] ~= nil) then
    local fontSize = prefs['fontSize']
    local item = self.items[self.cursorY]
    local desc = item:get_description()
    local info = item:get_info(true)
    local _, dlines = fonts.descFont:getWrap(desc,x+padX)
    local descH = #dlines*fontSize+fontSize
    local _, ilines = fonts.descFont:getWrap(info,x+padX)
    local infoH = #ilines*fontSize+fontSize*(#ilines > 0 and 2 or 0)
    love.graphics.printf(desc,x+padX,descY+8,boxW-16,"left")
    love.graphics.printf(info,x+padX,descY+descH+8,boxW-16,"left")
  end
  self.closebutton = output:closebutton(self.x+(prefs['noImages'] and 8 or 20),self.y+(prefs['noImages'] and 8 or 20),nil,true)
  love.graphics.pop()
end

function multipickup:keypressed(key)
	if (key == "escape") then
		self:switchBack()
	elseif (key == "return") or key == "kpenter" then
		if self.items[self.cursorY] then
      self:pickup(self.items[self.cursorY])
    end
	elseif (key == "up") then
		if (self.items[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
		end
	elseif (key == "down") then
		if (self.items[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
		end
	else
		local id = string.byte(key)-96
		if (self.items[id] ~= nil) then
			self:pickup(self.items[id])
		end
	end
end

function multipickup:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
	if (x/uiScale > self.x and x/uiScale < self.x+self.boxW and y/uiScale > self.y and y/uiScale < self.descY) then
    if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then self:switchBack() end
		if (self.items[self.cursorY] ~= nil) then
      self:pickup(self.items[self.cursorY])
		end
	end
end

function multipickup:wheelmoved(x,y)
  if y > 0 then
		if (self.cursorY and self.items[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
		end
	elseif y < 0 then
    self.cursorY = self.cursorY or 0
		if (self.items[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
		end
  end
end

function multipickup:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  local fontSize = prefs['fontSize']
  x,y = x/uiScale, y/uiScale
	if (x ~= output.mouseX or y ~= output.mouseY) then -- only do this if the mouse has moved
    output.mouseX,output.mouseY = x,y
		if (x > self.x and x < self.x+self.boxW and y > self.y and y < self.descY) then --if inside item box
      local mouseY = y-(self.y-self.padY)-(prefs['noImages'] and 2 or 4)*prefs['fontSize']
			local listY = math.floor(mouseY/(fontSize))
			if (self.items[listY] ~= nil) then
				self.cursorY=listY
      else
        self.cursorY=nil
			end
		end
	end
end

function multipickup:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end