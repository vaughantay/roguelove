multipickup = {}

function multipickup:enter()
  self.cursorY = 0
  self.scrollY = 0
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
  self.itemLines = {}
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
  
  love.graphics.printf("Pick Up Items",x+padX,y+padY,boxW-16,"center")
  
  --Drawing the text:
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",x+padX,y+padY+fontSize,boxW-padX*2,boxH-padY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  --Draw the highloght box:
  if (self.items[self.cursorY] ~= nil) then
    local printY = y+padY+((self.cursorY+1)*fontSize)
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",x+padX,printY,boxW-8,fontSize+2)
    setColor(255,255,255,255)
	end
  
  --Draw the item list:
  local bottom = 0
	local items = {}
	for i, item in ipairs(self.items) do
		local letter = string.char(i+96)
    local name = item:get_name(true)
    local itemY = y+padY+((line-1)*fontSize)
		love.graphics.print(letter .. ") " .. name,x+padX,itemY)
		line = line+1
    self.itemLines[i] = {minY=itemY,maxY=itemY+fontSize+2}
    bottom = itemY+fontSize+2
	end
  bottom = bottom+fontSize
  
  love.graphics.setStencilTest()
  
  --Draw the description:
  if (self.items[self.cursorY] ~= nil) then
    local item = self.items[self.cursorY]
    local desc = item:get_description()
    local info = item:get_info(true)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(fonts.descFont)
    local descText = desc .. (info ~= "" and "\n\n" or info)
    local width, tlines = fonts.descFont:getWrap(descText,300)
    local height = #tlines*(prefs['descFontSize']+3)+math.ceil(fontSize/2)
    x,y = round((x+boxW)/2),self.itemLines[self.cursorY].minY+round(fontSize/2)
    if (y+20+height < love.graphics.getHeight()) then
      setColor(255,255,255,185)
      love.graphics.rectangle("line",x+22,y+20,302,height)
      setColor(0,0,0,185)
      love.graphics.rectangle("fill",x+23,y+21,301,height-1)
      setColor(255,255,255,255)
      love.graphics.printf(ucfirst(descText),x+24,y+22,300)
    else
      setColor(255,255,255,185)
      love.graphics.rectangle("line",x+22,y+20-height,302,height)
      setColor(0,0,0,185)
      love.graphics.rectangle("fill",x+23,y+21-height,301,height-1)
      setColor(255,255,255,255)
      love.graphics.printf(ucfirst(descText),x+24,y+22-height,300)
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

function multipickup:keypressed(key)
  key = input:parse_key(key)
	if (key == "escape") then
		self:switchBack()
	elseif (key == "enter") or key == "wait" then
		if self.items[self.cursorY] then
      self:pickup(self.items[self.cursorY])
    end
	elseif (key == "north") then
		if (self.items[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
      if self.itemLines[self.cursorY].minY-self.scrollY-prefs['fontSize'] < self.y+self.padY+prefs['fontSize'] then
        self:scrollUp()
      end
		end
	elseif (key == "south") then
		if (self.items[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
      if self.itemLines[self.cursorY].maxY-self.scrollY+prefs['fontSize'] > self.y+prefs['fontSize']+self.boxH then
        self:scrollDown()
      end
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
		if (self.items[self.cursorY] ~= nil) and (not self.scrollPositions or x/uiScale < self.x+self.boxW-self.padX) then
      self:pickup(self.items[self.cursorY])
		end
	end
end

function multipickup:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end --end button type if
end

function multipickup:scrollUp()
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
  end
end

function multipickup:scrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
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
		if (x > self.x and x < self.x+self.boxW-(not self.scrollPositions and 0 or self.padX) and y > self.y+prefs['fontSize']+self.padY and y < self.descY) then --if inside item box
      for i,coords in ipairs(self.itemLines) do
        if y > coords.minY-self.scrollY and y < coords.maxY-self.scrollY then
          self.cursorY = i
          break
        end
      end
		end
	end
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

function multipickup:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end