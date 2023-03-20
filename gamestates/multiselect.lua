multiselect = {}

function multiselect:enter(previous,list,title,closeAfter,advanceAfter,description)
  if previous == multiselect then
    self.ignoreAfter = true
  end
  self.list = list
  self.title = title or "Select an Option"
  self.description = description
  self.closeAfter = closeAfter
  self.advanceAfter = advanceAfter
  self.cursorY = 0
  self.scrollY = 0
  self.scrollPositions=nil
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
  if self.description then
    local _,descLines = fonts.textFont:getWrap(self.description,boxW-padX)
    startY = startY+(#descLines*fontSize)
  end
  local tileSize = output:get_tile_size(true)
  local scrollMod = (self.scrollPositions and padX or 0)
  for i,item in ipairs(self.list) do
    local code = i+96
		local letter = (code > 32 and code <=122 and string.char(code) or nil)
    local letterText = letter and letter .. ") " or ""
    local letterW = fonts.textFont:getWidth(letterText)
    local imageW = (item.image and images[item.image] and tileSize or 0)
    local imageH = (item.image and images[item.image] and tileSize or 0)
    local _,textLines = fonts.textFont:getWrap((letter and letter .. ") " or "") .. item.text,boxW-padX-letterW-imageW-scrollMod)
    item.y = (i == 1 and startY or self.list[i-1].maxY)
    item.height = math.max(imageH,#textLines*fontSize)+2
    item.maxY = item.y+item.height
  end
end

function multiselect:select(item)
  if not item.disabled and item.selectFunction(unpack(item.selectArgs)) ~= false then
    if not self.ignoreAfter then
      if self.closeAfter then self:switchBack() end
      if self.advanceAfter then advance_turn() end
    end
    self.ignoreAfter = nil
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
  local x,y=self.x,self.y
  local fontSize = prefs.fontSize
	
  output:draw_window(x,y,x+boxW,y+boxH)
  
  love.graphics.setFont(fonts.textFont)
  local printY = y+padY
  love.graphics.printf(self.title,x+padX,printY,boxW-16,"center")
  printY=printY+fontSize
  if self.description then
    love.graphics.printf(self.description,x+padX,printY,boxW-16,"center")
    local _,descLines = fonts.textFont:getWrap(self.description,boxW-padX)
    printY = printY+(#descLines*fontSize)
  end
  
  love.graphics.push()
  local scrollMod = (self.scrollPositions and padX or 0)
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",x+padX,printY,boxW-padX-scrollMod,boxH-padY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  local tileSize = output:get_tile_size(true)
  --Draw the highlight box:
  if (self.list[self.cursorY] ~= nil) then
    local printY = self.list[self.cursorY].y
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",x+padX,printY,boxW-padX-scrollMod,self.list[self.cursorY].height)
    setColor(255,255,255,255)
	end
  
	for i, item in ipairs(self.list) do
    local code = i+96
		local letter = (code > 32 and code <=122 and string.char(code) or nil)
    local letterText = letter and letter .. ") " or ""
    local letterW = fonts.textFont:getWidth(letterText)
    love.graphics.print(letterText,x+padX,item.y+2)
    
    local imageW = 0
    if item.image and images[item.image] then
      if item.image_color or item.color then
        local color = item.image_color or item.color
        setColor(color.r,color.g,color.b,color.a)
      end
      love.graphics.draw(images[item.image],x+padX+letterW,item.y-2)
      imageW = tileSize
      setColor(255,255,255,255)
    end
		
    if item.text_color or item.color then
      local mod = (item.disabled and 2 or 1)
      local color = item.text_color or item.color
      setColor(round(color.r/mod),round(color.g/mod),round(color.b/mod),color.a)
    elseif item.disabled then
      setColor(150,150,150,255)
    end
    love.graphics.printf(item.text,x+padX+imageW+letterW+2,item.y+2,boxW-padX-imageW-letterW-scrollMod)
    setColor(255,255,255,255)
	end
  local bottom = self.list[#self.list].maxY+2
  
  love.graphics.setStencilTest()
  
  --Description:
  if self.list[self.cursorY] ~= nil and self.list[self.cursorY].description ~= nil then
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(fonts.descFont)
    local descText = self.list[self.cursorY].description
    local width, tlines = fonts.descFont:getWrap(descText,300)
    local height = #tlines*(prefs['descFontSize']+3)+math.ceil(prefs['fontSize']/2)
    x,y = round(x+boxW/2),self.list[self.cursorY].y+round(self.list[self.cursorY].height/2)
    output:description_box(ucfirst(descText),x,y)
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

function multiselect:keypressed(key)
  local typed = key
  key = input:parse_key(key)
	if (key == "escape") then
		self:switchBack()
	elseif (key == "enter") or key == "wait" then
		if self.list[self.cursorY] then
      self:select(self.list[self.cursorY])
    end
	elseif (key == "north") then
		if (self.list[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
      while self.list[self.cursorY].y-self.scrollY-prefs['fontSize'] < self.y+self.padY+prefs['fontSize'] and self.scrollY > 0 do
        self:scrollUp()
      end
		end
	elseif (key == "south") then
		if (self.list[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
      while self.list[self.cursorY].maxY-self.scrollY+prefs['fontSize'] > self.y+prefs['fontSize']+self.boxH and self.scrollY < self.scrollMax do
        self:scrollDown()
      end
		end
	elseif string.len(typed) == 1 then
		local id = string.byte(typed)-96
		if id >= 1 and id < 26 and self.list[id] ~= nil then
			self:select(self.list[id])
		end
	end
end

function multiselect:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
	if (x/uiScale > self.x and x/uiScale < self.x+self.boxW and y/uiScale > self.y and y/uiScale < self.y+self.boxH) then
    if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then self:switchBack() end
		if (self.list[self.cursorY] ~= nil and (not self.scrollPositions or x/uiScale < self.x+self.boxW-self.padX)) then
      self:select(self.list[self.cursorY])
		end
  else
    self:switchBack()
	end
end

function multiselect:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end --end button type if
end

function multiselect:scrollUp()
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
  end
end

function multiselect:scrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
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
		if (x > self.x and x < self.x+self.boxW-(not self.scrollPositions and 0 or self.padX) and y > self.y+prefs['fontSize']+self.padY and y < self.y+self.boxH) then --if inside item box
      local line = nil
      for i,coords in ipairs(self.list) do
        if y > coords.y-self.scrollY and y < coords.maxY-self.scrollY then
          line = i
          break
        end
      end --end coordinate for
			if (self.list[line] ~= nil) then
				self.cursorY=line
      else
        self.cursorY=0
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

function multiselect:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end