multipickup = {}

function multipickup:enter(previous,itemX,itemY,adjacentItems)
  self.adjacentItems = (adjacentItems == nil and gamesettings.can_pickup_adjacent_items or adjacentItems)
  self.itemX = itemX or player.x
  self.itemY = itemY or player.y
  self.cursorY = 0
  self.scrollY = 0
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local boxW,boxH = math.min(550,width),math.min(750,height)
  local padX,padY = 0,0
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
  self.padX,self.padY = padX,padY
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.startY = 0
  self.scrollPositions=nil
end

function multipickup:refresh_items()
  self.scrollPositions=nil
  self.itemLines = {}
  self.items = currMap:get_tile_items(self.itemX,self.itemY,self.adjacentItems)
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
  local boxW,boxH = self.boxW,self.boxH
  local padX,padY = self.padX,self.padY
  local x,y=self.x,self.y
  local fontSize = prefs['fontSize']
	
  output:draw_window(x,y,x+boxW,y+boxH)
  
  love.graphics.setFont(fonts.textFont)
  
  love.graphics.printf("Pick Up Items",x+padX,y+padY,boxW-16,"center")
  
  local printY = y+padY+fontSize
  
  if player.inventory_space then
    local totalspace = player:get_stat('inventory_space')
    local usedspace = player:get_used_inventory_space()
    love.graphics.printf("Used Inventory Space: " .. usedspace .. "/" .. totalspace,x+padX,printY,boxW-16,"center")
    printY = printY+fontSize+5
  end
  
  local startY = printY
  self.startY = startY
  
  --Drawing the text:
  love.graphics.push()
  local scrollMod = (self.scrollPositions and padX or 0)
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",x+padX,startY,boxW-padX-scrollMod,boxH-(startY-y)+padY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  local tileSize = output:get_tile_size(true)
  --Draw the highlight box:
  if self.itemLines[self.cursorY] and self.itemLines[self.cursorY].minY and self.itemLines[self.cursorY].maxY then
    local highlightY = self.itemLines[self.cursorY].minY
    local highlightH = self.itemLines[self.cursorY].maxY - self.itemLines[self.cursorY].minY
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",x+padX,highlightY,boxW-padX-scrollMod,highlightH)
    setColor(255,255,255,255)
	end
  
  --Draw the item list:
  local bottom = 0
	local items = {}
	for i, item in ipairs(self.items) do
		local code = i+96
    local letter = (code > 32 and code <=122 and string.char(code) or nil)
    local name = item:get_name(true)
    
    --Add extra text if needed:
    local extra = nil
    local direction = ""
    if (item.y or item.possessor.y) < player.y then direction = direction .. "north"
    elseif (item.y or item.possessor.y) > player.y then direction = direction .. "south" end
    if (item.x or item.possessor.x) < player.x then direction = direction .. "west"
    elseif (item.x or item.possessor.x) > player.x then direction = direction .. "east" end
    if item.possessor then extra = " (In " .. item.possessor.name .. (direction ~= "" and ", " .. direction or "") .. ")" end
    if extra == nil and direction ~= "" then extra = " (" .. ucfirst(direction) .. ")" end
    
    --Display line:
    local letterW = fonts.textFont:getWidth((letter and letter .. ") " or ""))
    local nameX = x+padX+letterW+tileSize
    local nameText = name .. (extra or "")
    local nameW = boxW-letterW-tileSize-padX-scrollMod
    local _,nlines = fonts.textFont:getWrap(nameText,nameW)
    local nameHeight = math.max((#nlines)*fontSize,tileSize)
    self.itemLines[i] = {minY=printY,maxY=printY+nameHeight+2}
    
    love.graphics.print((letter and letter .. ") " or ""),x+padX,printY+2)
    output.display_entity(item,x+padX+letterW,printY-2,true,true)
    love.graphics.printf(nameText,nameX,printY+2,nameW,"left")
    
    printY = printY+nameHeight+2
	end
  bottom = printY
  
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  --Scrollbars
  if bottom > self.y+self.boxH then
    self.scrollMax = bottom-(self.y+self.boxH)
    local scrollAmt = self.scrollY/self.scrollMax
    self.scrollPositions = output:scrollbar(self.x+self.boxW-padX,self.y+padY,self.y+self.boxH,scrollAmt,true)
  end
  self.closebutton = output:closebutton(self.x+(prefs['noImages'] and 8 or 20),self.y+(prefs['noImages'] and 8 or 20),nil,true)
  
  --Draw the description:
  if (self.items[self.cursorY] ~= nil) then
    local item = self.items[self.cursorY]
    local desc = item:get_description()
    local info = item:get_info(true)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(fonts.descFont)
    local descText = desc .. (info ~= "" and info or "")
    x,y = round((x+boxW/2)),self.itemLines[self.cursorY].minY+round((self.itemLines[self.cursorY].maxY-self.itemLines[self.cursorY].minY))/2
    y = y-self.scrollY
    output:description_box(ucfirst(descText),x,y)
    love.graphics.setFont(oldFont)
  end
  
  if bottom < self.y+self.boxH then
    self.boxH = bottom-self.y
    self.y = math.floor(height/uiScale/2-self.boxH/2)
  end
  
  love.graphics.pop()
end

function multipickup:buttonpressed(key,scancode,isRepeat,controllerType)
  local typed = key
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
	if (key == "escape") then
		self:switchBack()
	elseif (key == "enter") or key == "wait" then
		if self.items[self.cursorY] then
      self:pickup(self.items[self.cursorY])
    end
	elseif (key == "north") then
		if (self.items[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
      while self.itemLines[self.cursorY].minY-self.scrollY-prefs['fontSize'] < self.startY+prefs['fontSize'] and self.scrollY > 0 do
        self:scrollUp()
      end
		end
	elseif (key == "south") then
		if (self.items[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
      while self.itemLines[self.cursorY].maxY-self.scrollY+prefs['fontSize'] > self.y+prefs['fontSize']+self.boxH and self.scrollY < self.scrollMax do
        self:scrollDown()
      end
		end
	elseif string.len(typed) == 1 then
		local id = string.byte(typed)-96
    print(id)
		if id >= 1 and id <=26 and self.items[id] ~= nil then
			self:pickup(self.items[id])
		end
	end
end

function multipickup:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
	if (x/uiScale > self.x and x/uiScale < self.x+self.boxW and y/uiScale > self.y and y/uiScale < self.y+self.boxH) then
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
  game:update(dt)
  if player.hp ~= game.hp or player.hp < 1 then
    self:switchBack()
  end
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  local fontSize = prefs['fontSize']
  x,y = x/uiScale, y/uiScale
	if (x ~= self.mouseX or y ~= self.mouseY) then -- only do this if the mouse has moved
    self.mouseX,self.mouseY = x,y
		if (x > self.x and x < self.x+self.boxW-(not self.scrollPositions and 0 or self.padX) and y > self.y+fontSize+self.padY and y < self.y+self.boxH) then --if inside item box
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