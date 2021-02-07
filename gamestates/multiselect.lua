multiselect = {}

function multiselect:enter(origin,list,title,closeAfter,advanceAfter)
  self.list = list
  self.title = title or "Select an Option"
  self.closeAfter = closeAfter
  self.advanceAfter = advanceAfter
  self.cursorY = 0
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local boxW,boxH = 450,300
  local padX,padY = 0,0
  local descY = 0
  local x,y=math.floor(width/2/uiScale-boxW/2),math.floor(height/2/uiScale-boxH/2)
  local fontSize = prefs['fontSize']
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
  local _,titleLines = fonts.textFont:getWrap(self.title,boxW-padX)
  local startY = y+(#titleLines+2)*fontSize
  for i,item in ipairs(self.list) do
    local code = i+96
		local letter = string.char(code)
    local _,textLines = fonts.textFont:getWrap((code <=122 and letter .. ") " or "") .. item.text,boxW-padX)
    item.y = (i == 1 and startY or self.list[i-1].maxY)
    item.height = #textLines*fontSize
    item.maxY = item.y+item.height
  end
  self.descY = self.list[#self.list].maxY+math.ceil(prefs['fontSize']*.5)
end

function multiselect:select(item)
  if item.selectFunction(unpack(item.selectArgs)) ~= false then
    if self.closeAfter then self:switchBack() end
    if self.advanceAfter then advance_turn() end
  end
end

function multiselect:draw()
  local uiScale = (prefs['uiScale'] or 1)
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local boxW,boxH = self.boxW,self.boxH
  local padX,padY = self.padX,self.padY
  local descY = self.descY
  local x,y=self.x,self.y
	
  love.graphics.line(x,descY,x+padX+boxW,descY)
  output:draw_window(x,y,x+boxW,y+boxH)
  
  love.graphics.setFont(fonts.textFont)
  love.graphics.printf(self.title,x+padX,y+padY,boxW-16,"center")
  
  if (self.list[self.cursorY] ~= nil) then
    local printY = self.list[self.cursorY].y
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",x+padX,printY,boxW-8,self.list[self.cursorY].height)
    setColor(255,255,255,255)
	end
  
	for i, item in ipairs(self.list) do
    local code = i+96
		local letter = string.char(code)
		love.graphics.printf((code <=122 and letter .. ") " or "") .. item.text,x+padX,item.y,boxW-padX)
	end
  
  if (self.list[self.cursorY] ~= nil) then
    love.graphics.printf(self.list[self.cursorY].description,x+padX,descY+4,boxW-16,"left")
  end
  
  self.closebutton = output:closebutton(self.x+(prefs['noImages'] and 8 or 20),self.y+(prefs['noImages'] and 8 or 20),nil,true)
  love.graphics.pop()
end

function multiselect:keypressed(key)
	if (key == "escape") then
		self:switchBack()
	elseif (key == "return") or key == "kpenter" then
		if self.list[self.cursorY] then
      self:select(self.list[self.cursorY])
    end
	elseif (key == "up") then
		if (self.list[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
		end
	elseif (key == "down") then
		if (self.list[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
		end
	else
		local id = string.byte(key)-96
		if (self.list[id] ~= nil) then
			self:select(self.list[id])
		end
	end
end

function multiselect:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
	if (x/uiScale > self.x and x/uiScale < self.x+self.boxW and y/uiScale > self.y and y/uiScale < self.descY) then
    if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then self:switchBack() end
		if (self.list[self.cursorY] ~= nil) then
      self:select(self.list[self.cursorY])
		end
	end
end

function multiselect:wheelmoved(x,y)
  if y > 0 then
		if (self.cursorY and self.list[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
		end
	elseif y < 0 then
    self.cursorY = self.cursorY or 0
		if (self.list[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
		end
  end
end

function multiselect:update(dt)
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
		if (x > self.x and x < self.x+self.boxW and y > self.y and y < self.descY) then --if inside item box
      local line = nil
      for i,coords in ipairs(self.list) do
        if output.mouseY > coords.y and output.mouseY < coords.maxY then
          line = i
          break
        end
      end --end coordinate for
			if (self.list[line] ~= nil) then
				self.cursorY=line
      else
        self.cursorY=nil
			end
		end
	end
end

function multiselect:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end