modloader = {}

function modloader:enter()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  self.mods = load_all_mod_info()
  self.allSelected = true
  for _,mod in pairs(self.mods) do
    if prefs['lastMods'][mod.id] then
      mod.selected = true
    else
      self.allSelected = false
    end
  end
  local padding = (prefs['noImages'] and 16 or 32)
  self.scroll = 0
  self.cursorX = 2
  self.cursorY = 0
  self.screenMax = round(((height-padding)*2+5)/padding/2)
  if count(self.mods) == 0 then
    Gamestate.switch(menu)
  end
end

function modloader:draw()
  setColor(255,255,255,255)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local padding = 32
  self.screenMax = round(((height-padding)*2+5)/padding/2)
	love.graphics.setFont(fonts.textFont)
  local sidebarX = round(width/3)*2+padding
  local printX = (prefs['noImages'] and 14 or 32)
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  
  love.graphics.printf("Weirdfellows LLC is not responsible for the content, stability, or actions of any mods.",padding,round(padding*.75),sidebarX-padding*2,"center")
  love.graphics.printf("Select Mods to Load:",padding,round(padding*.75)+prefs['fontSize'],sidebarX-padding*2,"center")
  --Draw buttons:
  local midX = math.floor((sidebarX-padding*2)/2)
  local printY = prefs['fontSize']*4
  local loadModButtonW = fonts.textFont:getWidth("Start With Selected Mods")+padding
  local noModButtonW = fonts.textFont:getWidth("Start Without Mods")+padding
  local selectAllButtonW = fonts.textFont:getWidth("Select All Mods")+padding
  self.selectAllButton = output:button(midX-selectAllButtonW-loadModButtonW/2-padding,printY,selectAllButtonW,false,((self.cursorX == 1 and self.cursorY == 0) and "hover" or nil),(self.allSelected and "Deselect All Mods" or "Select All Mods"))
  --love.graphics.print((self.allSelected and "Deselect All Mods" or "Select All Mods"),math.floor(midX-selectAllButtonW-loadModButtonW/2),printY+math.floor(padding/2))
  self.loadModsButton = output:button(math.floor(midX-loadModButtonW/2),printY,loadModButtonW,false,((self.cursorX == 2 and self.cursorY == 0) and "hover" or nil),"Start With Selected Mods")
  --love.graphics.print("Start With Selected Mods",math.floor(midX-loadModButtonW/2),printY+math.floor(padding/2))
  self.startNoModsButton = output:button(math.floor(midX+loadModButtonW/2+padding),printY,loadModButtonW,false,((self.cursorX == 3 and self.cursorY == 0) and "hover" or nil),"Start Without Mods")
  --love.graphics.print("Start Without Mods",math.floor(midX+loadModButtonW/2),printY+math.floor(padding/2))
  love.graphics.line(printX,printY+padding,sidebarX-padding,printY+padding+8)
  
  local line = 1
  local needsScroll = (count(self.mods) > self.screenMax)
  local mouseX,mouseY = love.mouse.getPosition()
  local top = printY+padding
  for _,mod in pairs(self.mods) do
    mod.highlighted = false
    local printY = (line*2-self.scroll*2+5)*prefs['fontSize']
    if printY > top and printY < height-padding then
      if mouseX > padding and mouseX < sidebarX-(needsScroll and padding*2 or padding) and mouseY > printY and mouseY < printY+prefs['fontSize'] then
        mod.highlighted = true
      end
      if line == self.cursorY then
        setColor(100,100,100,255)
        love.graphics.rectangle("fill",printX,printY,sidebarX-padding-(needsScroll and padding*2 or padding),2+prefs['fontSize'])
        setColor(255,255,255,255)
      elseif mod.highlighted then
        setColor(100,100,100,125)
        love.graphics.rectangle("fill",printX,printY,sidebarX-padding-(needsScroll and padding*2 or padding),2+prefs['fontSize'])
        setColor(255,255,255,255)
        mod.highlighted = true
      end
      if prefs['noImages'] then
        love.graphics.print((mod.selected and "(Y)" or "(N)"),printX,printY)
      else
        love.graphics.draw((mod.selected and images.uicheckboxchecked or images.uicheckbox),printX,printY)
      end
      love.graphics.printf(mod.name,printX+padding,printY,sidebarX-32-(needsScroll and padding or 0))
    end
    line = line+1
  end
  
  if needsScroll then
    local maxScroll = #self.mods-self.screenMax
    local scrollAmt = self.scroll/maxScroll
    self.scrollPositions = output:scrollbar(round(sidebarX-padding*1.75),padding*2,height-padding,scrollAmt)
  end
  
  --Display selected mod, if any
  if self.cursorY and self.mods[self.cursorY] then
    local endX = width-padding
    local printY = padding
    local padY = prefs['fontSize']+2
    
    local mod = self.mods[self.cursorY]
    if mod then
      love.graphics.printf(mod.name,sidebarX+padding,printY,endX-sidebarX-padding,"center")
      printY = printY+padY
      if mod.author then
        love.graphics.printf("By " .. mod.author,sidebarX+padding,printY,endX-sidebarX-padding,"center")
        printY = printY+padY
      end
      if mod.modVersion then
        love.graphics.printf("Version " .. mod.modVersion,sidebarX+padding,printY,endX-sidebarX-padding,"center")
        printY = printY+padY
      end
      local image = mod.image
      if image == nil then
        if love.filesystem.getInfo("mods/" .. mod.id .. "/images/banner.png") then
          mod.image = love.graphics.newImage("mods/" .. mod.id .. "/images/banner.png")
          image = mod.image
        else
          image = nil
        end
      end
      if image then
        --print mod image
        local ratio = (endX-sidebarX-padding)/image:getWidth()
        local ssheight = image:getHeight()*ratio
        love.graphics.draw(image,sidebarX+padding,printY,0,ratio,ratio)
        love.graphics.rectangle("line",sidebarX+padding,printY,endX-sidebarX-padding,ssheight)
        printY=round(printY+ssheight+prefs['fontSize'])
      end
      love.graphics.printf(mod.description,sidebarX+padding,printY,endX-sidebarX-padding,"center")
      local width, tlines = fonts.textFont:getWrap(mod.description,endX-sidebarX-padding)
      printY = printY+(#tlines+1)*prefs['fontSize']
      if mod.graphicsOnly then
        love.graphics.print("Graphics/sound changes only.",sidebarX+padding,printY)
        printY = printY + padY
      end
      if mod.gameVersion then
        love.graphics.print("For Possession version " .. mod.gameVersion,sidebarX+padding,printY)
        printY = printY + padY
        if mod.gameVersion ~= gamesettings.version then
          setColor(255,0,0,255)
          love.graphics.print("Warning! Not for current version.\nMay have issues.",sidebarX+padding,printY)
          setColor(255,255,255,255)
          printY = printY + padY*2
        end
      end
      if mod.requirements then
        love.graphics.printf("Required Mods: " .. mod.requirements,sidebarX+padding,printY,endX-sidebarX-padding,"center")
      local width, tlines = fonts.textFont:getWrap(mod.requirements,endX-sidebarX-padding)
      printY = printY+(#tlines+1)*prefs['fontSize']
      end
      if mod.incompatibilities then
        love.graphics.printf("Known Incompatibilities: " .. mod.incompatibilities,sidebarX+padding,printY,endX-sidebarX-padding,"center")
        local width, tlines = fonts.textFont:getWrap(mod.incompatibilities,endX-sidebarX-padding)
        printY = printY+(#tlines+1)*prefs['fontSize']
      end
    end
  end
  setColor(255,255,255,255)
end

function modloader:update(dt)
  if self.cursorY <= self.scroll and self.cursorY ~= 0 then
    self:scrollUp()
  elseif self.cursorY > self.screenMax+self.scroll then
    self:scrollDown()
  end
end

function modloader:keypressed(key, isRepeat)
  if key == "escape" then
    --go to "no mods" button
  elseif key == "up" then
    if self.cursorY > 0 then
      self.cursorY = self.cursorY-1
      self.cursorX = 2
      
    end
  elseif key == "down" then
    if self.cursorY < #self.mods then
      self.cursorY = self.cursorY+1
      self.cursorX = 1
    end
  elseif key == "left" then
    self.cursorX = math.max(self.cursorX - 1,1)
  elseif key == "right" then
    self.cursorX = math.min (self.cursorX + 1,3)
  elseif key == "return" then
    if self.cursorY == 0 then
      if self.cursorX == 1 then --select all
        local which = true
        if self.allSelected then
          which = false
          self.allSelected = false
        else
          self.allSelected = true
        end
        for _,mod in pairs(self.mods) do
          mod.selected = which
        end
      elseif self.cursorX == 2 then --load mods
        self:start_with_mods()
      elseif self.cursorX == 3 then --start without mods
        self:start_no_mods()
      end
    else
      self.mods[self.cursorY].selected = not self.mods[self.cursorY].selected
    end
  end
end

function modloader:mousepressed(x,y,button)
  if x>self.selectAllButton.minX and x<self.selectAllButton.maxX and y>self.selectAllButton.minY and y<self.selectAllButton.maxY then
    self:selectAll()
  elseif x>self.loadModsButton.minX and x<self.loadModsButton.maxX and y>self.loadModsButton.minY and y<self.loadModsButton.maxY then
    self:start_with_mods()
  elseif x>self.startNoModsButton.minX and x<self.startNoModsButton.maxX and y>self.startNoModsButton.minY and y<self.startNoModsButton.maxY then
    self:start_no_mods()
  else
    for i,mod in pairs(self.mods) do
      if mod.highlighted then
        mod.selected = not mod.selected
        self.cursorY = i
      end
    end --end mod for
  end --end which button if
end

function modloader:start_with_mods()
  local modsLoaded = {}
  for _,mod in pairs(self.mods) do
    if mod.selected then
      load_mod(mod.id,mod.graphicsOnly)
      modsLoaded[mod.id] = mod.id
    end
  end
  prefs['lastMods'] = modsLoaded
  Gamestate.switch(menu)
end

function modloader:selectAll()
  for _,mod in pairs(self.mods) do
    if self.allSelected == true then
      mod.selected = false
      self.allSelected = false
    else
      mod.selected = true
      self.allSelected = true
    end
  end
end

function modloader:start_no_mods()
  Gamestate.switch(menu)
end

function modloader:wheelmoved(x,y)
	if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
	end
end

function modloader:scrollUp()
  if self.scroll > 0 then
    self.scroll = self.scroll - 1
    if self.cursorY > self.screenMax+self.scroll then
      self.cursorY=self.cursorY-1
      self.cursorX = 1
    end
  end
end

function modloader:scrollDown()
  if self.screenMax+self.scroll < count(self.mods) then
    self.scroll = self.scroll + 1
    if self.cursorY <= self.scroll and self.cursorY ~= 0 then
      self.cursorY = self.cursorY+1
      self.cursorX = 1
    end
  end
end