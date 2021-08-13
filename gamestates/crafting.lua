crafting = {}

function crafting:enter()
  self.crafts = player:get_all_possible_recipes()
  self.makeAmt = 1
  self.cursorY = 0
  self.outText = nil
  self.outHeight = 0
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local boxW,boxH = 600,(#self.crafts+2)*prefs['fontSize']+250
  local padX,padY = 0,0
  local descY = 0
  local x,y=math.floor(width/2/uiScale-boxW/2),math.floor(height/2/uiScale-boxH/2)
  self.x,self.y,self.boxW,self.boxH=x,y,boxW,boxH
  if prefs['noImages'] == true then
    padX,padY=5,5
  else
    padX,padY=20,20
  end
  descY = y+padY+(#self.crafts+4)*prefs['fontSize']
  self.descY = descY
  self.padX,self.padY = padX,padY
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
end

function crafting:draw()
  local uiScale = (prefs['uiScale'] or 1)
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
	local line = 3
  local boxW,boxH = self.boxW,self.boxH
  local padX,padY = self.padX,self.padY
  local outHeight = self.outHeight
  local descY = self.descY
  local x,y=self.x,self.y
	
  output:draw_window(x,y,x+boxW,y+boxH)
  love.graphics.setFont(fonts.textFont)
  
  love.graphics.printf("Crafting",x+padX,y+padY,boxW-16,"center")
  if self.outText then
    local extra = prefs['fontSize']*2
    love.graphics.printf(self.outText,x+padX,y+padY+extra,boxW-16,"center")
  end
  love.graphics.line(x,descY,x+padX+boxW,descY)
  if (self.crafts[self.cursorY] ~= nil) then
    local printY = y+padY+((self.cursorY+1)*14)+outHeight
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",x+padX,printY,boxW-8,16)
    setColor(255,255,255,255)
	end
  
	local crafts = {}
	for i, craftID in pairs(self.crafts) do
    local recipe = possibleRecipes[craftID]
		local letter = string.char(i+96)
		crafts[i] = craftID
    local name = ""
    local count = 1
    for item,amount in pairs(recipe.results) do
      if count > 1 then name = name .. ", " end
      if amount > 1 then
        name = name .. amount .. " " .. ucfirst(possibleItems.pluralName or "x " .. possibleItems[item].name)
      else
        name = name .. ucfirst(possibleItems[item].name)
      end
      count = count + 1
    end
		love.graphics.print(letter .. ") " .. name,x+padX,y+padY+outHeight+((line-1)*14))
		line = line+1
	end
  if count(crafts) < 1 then
    love.graphics.printf("You can't craft anything right now.",x+padX,y+padY+outHeight+prefs['fontSize']*2,boxW-16,"center")
  end
  
  if (self.crafts[self.cursorY] ~= nil) then
    local recipe = possibleRecipes[self.crafts[self.cursorY]]
    local descY = descY+8
    for iid,amount in pairs(recipe.results) do
      local item = possibleItems[iid]
      local fullText = "Result: " .. ucfirst(item.name) .. " (" .. item.description .. ")"
      love.graphics.printf(fullText,x+padX,descY,boxW-16,"left")
      local _, dlines = fonts.descFont:getWrap(fullText,boxW-16)
      descY = descY+prefs['fontSize']*#dlines
    end
  end
  self.closebutton = output:closebutton(self.x+(prefs['noImages'] and 8 or 20),self.y+(prefs['noImages'] and 8 or 20),nil,true)
  love.graphics.pop()
end

function crafting:keypressed(key)
  key = input:parse_key(key)
	if (key == "escape") then
		self:switchBack()
	elseif (key == "return") or key == "wait" then
    if self.crafts[self.cursorY] ~= nil then
      self:doCraft(self.crafts[self.cursorY])
    end
	elseif (key == "north") then
		if (self.crafts[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
		end
	elseif (key == "south") then
		if (self.crafts[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
		end
	else
		local id = string.byte(key)-96
		if (self.crafts[id] ~= nil) then
			self:doCraft(self.crafts[id])
		end
	end
end

function crafting:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
	if (x/uiScale > self.x and x/uiScale < self.x+self.boxW and y/uiScale > self.y and y/uiScale < self.descY) then
    if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then self:switchBack() end
		if (self.crafts[self.cursorY] ~= nil) then
			self:doCraft(self.crafts[self.cursorY])
		end
  else
    self:switchBack()
	end
end

function crafting:wheelmoved(x,y)
  if y > 0 then
		if (self.cursorY and self.crafts[self.cursorY-1] ~= nil) then
			self.cursorY = self.cursorY - 1
		end
	elseif y < 0 then
    self.cursorY = self.cursorY or 0
		if (self.crafts[self.cursorY+1] ~= nil) then
			self.cursorY = self.cursorY + 1
		end
  end
end

function crafting:update(dt)
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
		if (x > self.x and x < self.x+self.boxW and y > self.y and y < self.descY) then --if inside the screen
      local mouseY = y-(self.y-self.padY)-self.outHeight
			local listY = math.floor(mouseY/14)
      local yMod = (prefs['noImages'] and 2 or 4)
			if (self.crafts[listY-yMod] ~= nil) then
				self.cursorY=listY-yMod
      else
        self.cursorY=nil
			end
		end
	end
end

function crafting:doCraft(craftID)
  local result,text = player:craft_recipe(craftID)
  self.outText = text
  local _, dlines = fonts.textFont:getWrap(text,self.boxW-16)
  self.outHeight = #dlines*prefs['fontSize']+(prefs['fontSize']*2)
  self.descY = self.descY+self.outHeight
  self.crafts = player:get_all_possible_recipes()
end

function crafting:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end