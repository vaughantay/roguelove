loadsaves = {}

function loadsaves:enter()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  self.saves = load_all_saves()
  self.scroll = 0
  self.cursorX = 1
  self.cursorY = 0
  self.deletewarning = false
  self.screenMax = round(height/(prefs['fontSize']+2)/2)
  self.currSave = nil
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
end

function loadsaves:draw()
  menu:draw()
  setColor(255,255,255,255)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  love.graphics.push()
  love.graphics.translate(0,height*(self.yModPerc/100))
  self.screenMax = round(height/(prefs['fontSize']+2)/2)
  local padding = (prefs['noImages'] and 16 or 32)
	love.graphics.setFont(fonts.textFont)
  local sidebarX = round(width/3)*2+padding
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  love.graphics.printf("Load a Saved Game:",padding,round(padding*.75),sidebarX-padding,"center")
  
  local line = 1
  local printX = (prefs['noImages'] and 14 or 32)
  local needsScroll = (count(self.saves) > self.screenMax)
  local mouseX,mouseY = love.mouse.getPosition()
  for _,save in ipairs(self.saves) do
    local printY = (line*2-self.scroll*2+4)*prefs['fontSize']
    if printY > padding*2 and printY < height-padding then
      local dateWidth = fonts.textFont:getWidth(os.date("%H:%M, %b %d, %Y",save.date))
      if line == self.cursorY then
        setColor(100,100,100,255)
        love.graphics.rectangle("fill",printX,printY,sidebarX-padding-(needsScroll and padding*2 or padding),2+prefs['fontSize'])
        setColor(255,255,255,255)
      elseif mouseX > padding and mouseX < sidebarX-(needsScroll and padding*2 or padding) and mouseY > printY and mouseY < printY+prefs['fontSize'] and self.deletewarning == false then
        setColor(100,100,100,125)
        love.graphics.rectangle("fill",printX,printY,sidebarX-padding-(needsScroll and padding*2 or padding),2+prefs['fontSize'])
        setColor(255,255,255,255)
      end
      love.graphics.printf(save.fileName,printX,printY,sidebarX-32-dateWidth-(needsScroll and padding or 0))
      love.graphics.printf(os.date("%H:%M, %b %d, %Y",save.date),sidebarX-32-dateWidth-(needsScroll and padding or 0),printY,dateWidth,"right")
    end
    line = line+1
  end
  
  if needsScroll then
    local maxScroll = #self.saves-self.screenMax
    local scrollAmt = self.scroll/(maxScroll+2)
    self.scrollPositions = output:scrollbar(round(sidebarX-padding*1.75),padding*2,height-padding,scrollAmt)
  end
  
  --Display selected save, if any
  if self.cursorY and self.saves[self.cursorY] then
    local endX = width-padding
    local printY = padding
    local padY = prefs['fontSize']+2
    
    
    if self.cursorY and self.saves[self.cursorY] then
      if not self.currSave or self.currSave.fileName ~= self.saves[self.cursorY].fileName then
        self.currSave = load_save_info(self.saves[self.cursorY].fileName)
      end
      local save = self.currSave
      if save then
        if save.screenshot then
          local ratio = (endX-sidebarX-padding)/save.screenshot:getWidth()
          local ssheight = save.screenshot:getHeight()*ratio
          love.graphics.draw(save.screenshot,sidebarX+padding,padding,0,ratio,ratio)
          love.graphics.rectangle("line",sidebarX+padding,padding,endX-sidebarX-padding,ssheight)
          printY=round(printY+ssheight+prefs['fontSize'])
        end
        love.graphics.printf(save.player.properName,sidebarX+padding,printY,endX-sidebarX-padding,"center")
        save.currGame.stats = save.currGame.stats or {}
        printY = printY+padY
        love.graphics.printf("Depth " .. 11-save.currMap.depth .. ": " .. save.currMap.name,sidebarX+padding,printY,endX-sidebarX-padding,"center")
        printY = printY+padY
        love.graphics.printf("Current Body: " .. ucfirst(save.player.name),sidebarX+padding,printY,endX-sidebarX-padding,"center")
        printY = printY+padY*2
        love.graphics.printf("Turns: " .. (save.currGame.stats.turns or 0),sidebarX+padding,printY,endX-sidebarX-padding,"center")
        printY = printY+padY
        love.graphics.printf("Kills: " .. (save.currGame.stats.kills or 0),sidebarX+padding,printY,endX-sidebarX-padding,"center")
        printY = printY+padY
        love.graphics.printf("Possessions: " .. (save.currGame.stats.total_possessions or 0),sidebarX+padding,printY,endX-sidebarX-padding,"center")
        printY = printY+padY
        love.graphics.printf("Explosions: " .. (save.currGame.stats.explosions or 0),sidebarX+padding,printY,endX-sidebarX-padding,"center")
        --check game ID and game version
        printY = printY+padY*3
        setColor(255,255,255,255)
        love.graphics.setFont(fonts.buttonFont)
        self.loadbutton = output:button(sidebarX+padding,printY,75,false,((self.cursorX == 2 and self.deletewarning == false) and "hover" or "image"))
        love.graphics.printf("Load",sidebarX+padding,printY+4,75,"center")
        self.deletebutton = output:button(round(endX-padding*(prefs['noImages'] and 5 or 2.5)),printY,75,false,((self.cursorX == 3 and self.deletewarning == false) and "hover" or "image"))
        love.graphics.printf("Delete",round(endX-padding*(prefs['noImages'] and 5 or 2.5)),printY+4,75,"center")
        love.graphics.setFont(fonts.textFont)
        if not save.gameDefinition or (save.gameDefinition.name ~= gamesettings.name) then
          printY = printY+padY*3
          setColor(255,0,0,255)
          love.graphics.printf("WARNING! This save file could be from a different game! This save is for game " .. (save.gameDefinition and save.gameDefinition.name or "Unknown") .. ", current game is " .. gamesettings.name .. ". If you load this save, it might not work correctly or may crash.",sidebarX+padding,printY,endX-sidebarX-padding,"center")
          printY = printY+padY*3
        elseif save.gameDefinition.version ~= gamesettings.version then
          printY = printY+padY*3
          setColor(255,0,0,255)
          love.graphics.printf("WARNING! This save file could be from a different version! This save is for version " .. (save.gameDefinition and save.gameDefinition.version or "Unknown") .. ", current game version " .. gamesettings.version .. ". If you load this save, it might not work correctly or may crash.",sidebarX+padding,printY,endX-sidebarX-padding,"center")
          printY = printY+padY*3
        end
      else --if save isn't found
        setColor(255,0,0,255)
          love.graphics.printf("WARNING! Save file not found or corrupted.",sidebarX+padding,printY,endX-sidebarX-padding,"center")
      end
    end
    setColor(255,255,255,255)
  end
  
  if self.deletewarning then
    local sizeX = 350
    local sizeY = 150
    local startX = round(love.graphics.getWidth()/2-sizeX/2)
    local startY = round(love.graphics.getHeight()/2-sizeY)
    output:draw_window(startX,startY,startX+sizeX,startY+sizeY)
    love.graphics.printf("Are you sure you want to delete " .. self.currSave.player.properName .. "?",startX+padding,startY+padding,sizeX-padding,"center")
    love.graphics.setFont(fonts.buttonFont)
    self.yesbutton = output:button(startX+padding,startY+sizeY-padding-(prefs['noImages'] and padding or 0),75,false,(self.cursorX == 1 and "hover" or "image"))
    love.graphics.printf("(Y)es",startX+padding,startY+sizeY-padding-(prefs['noImages'] and padding or 0),75,"center")
    self.nobutton = output:button(startX+sizeX-75,startY+sizeY-padding-(prefs['noImages'] and padding or 0),75,false,(self.cursorX == 2 and "hover" or "image"))
    love.graphics.printf("(N)o",startX+sizeX-75,startY+sizeY-padding-(prefs['noImages'] and padding or 0),75,"center")
    love.graphics.setFont(fonts.textFont)
  end
  self.closebutton = output:closebutton((prefs['noImages'] and 16 or 24),(prefs['noImages'] and 16 or 24))
  love.graphics.pop()
end

function loadsaves:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(menu)
    Gamestate.update(dt)
    return
  end
  if self.cursorY < 0 then self.cursorY = 0
  elseif self.cursorY <= self.scroll then
    self:scrollUp()
  elseif self.cursorY > self.screenMax+self.scroll then
    self:scrollDown()
  end
  if self.cursorY > #self.saves then
    self.cursorY = #self.saves
  end
  if self.screenMax+self.scroll > #self.saves and self.needsScroll then
    self.scroll = #self.saves-self.screenMax
  end
  --Scrolling:
  if self.scrollPositions and (love.mouse.isDown(1)) then
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

function loadsaves:keypressed(key, isRepeat)
  if self.deletewarning == false then
    if key == "escape" then
      self:switchBack()
    elseif key == "up" then
      self.cursorY = self.cursorY-1
      self.cursorX = 1
    elseif key == "down" then
      if self.cursorY < #self.saves then
        self.cursorY = self.cursorY+1
        self.cursorX = 1
      end
    elseif key == "left" then
      self.cursorX = math.max(self.cursorX - 1,1)
    elseif key == "right" then
      self.cursorX = math.min (self.cursorX + 1,3)
    elseif key == "return" or key == "kpenter" then
      if self.cursorX == 1 then
        self.cursorX = 2
      elseif self.cursorX == 2 and self.cursorY ~= 0 and self.saves[self.cursorY] then
        load_game("saves/" .. self.saves[self.cursorY].fileName)
        Gamestate.switch(game)
        game:show_level_description()
      elseif self.cursorX == 3 then
        self.deletewarning = true
        self.cursorX = 2
      end
    end
  else
    if key == "escape" then
      self.deletewarning = false
      self.yesbutton,self.nobutton = nil,nil
      self.cursorX = 3
    elseif key == "left" then
      self.cursorX = 1
    elseif key == "right" then
      self.cursorX = 2
    elseif key == "y" then
      delete_save(self.saves[self.cursorY].fileName)
      local y,scroll = self.cursorY,self.scroll
      Gamestate.switch(loadsaves)
      loadsaves.cursorY,loadsaves.scroll = y,scroll
    elseif key == "n" then
      self.deletewarning = false
      self.yesbutton,self.nobutton = nil,nil
      self.cursorX = 3
    elseif key == "return" or key == "kpenter" then
      if self.cursorX == 1 then
        delete_save(self.saves[self.cursorY].fileName)
        local y,scroll = self.cursorY,self.scroll
        Gamestate.switch(loadsaves)
        loadsaves.cursorY,loadsaves.scroll = y,scroll
      else
        self.deletewarning = false
        self.yesbutton,self.nobutton = nil,nil
        self.cursorX = 3
      end
    end
  end
end

function loadsaves:wheelmoved(x,y)
	if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
	end
end

function loadsaves:scrollUp()
  if self.scroll > 0 and self.deletewarning == false then
    self.scroll = self.scroll - 1
    if self.cursorY > self.screenMax+self.scroll then
      self.cursorY=self.cursorY-1
      self.cursorX = 1
    end
  end
end

function loadsaves:scrollDown()
  if self.screenMax+self.scroll < count(self.saves) and self.deletewarning == false then
    self.scroll = self.scroll + 1
    if self.cursorY <= self.scroll then
      self.cursorY = self.cursorY+1
      self.cursorX = 1
    end
  end
end
  
function loadsaves:mousepressed(x,y,button)
  if self.deletewarning == false then
    if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then 
      self:switchBack()
    end
    if self.loadbutton and x>self.loadbutton.minX and x<self.loadbutton.maxX and y>self.loadbutton.minY and y<self.loadbutton.maxY then
      output:play_playlist('silence')
      load_game("saves/" .. self.saves[self.cursorY].fileName)
      Gamestate.switch(game)
      game:show_level_description()
    elseif self.deletebutton and x>self.deletebutton.minX and x<self.deletebutton.maxX and y>self.deletebutton.minY and y<self.deletebutton.maxY then
      self.deletewarning = true
      self.cursorX = 2
    else
      local line = round(((y/prefs['fontSize'])-4)/2+self.scroll)
      local padding = (prefs['noImages'] and 16 or 32)
      local sidebarX = round(love.graphics.getWidth()/3)*2+padding
      local needsScroll = (count(self.saves) > self.screenMax)
      if x > padding and x < sidebarX-(needsScroll and padding*2 or padding) then
        if self.cursorY == line then
          output:play_playlist('silence')
          load_game("saves/" .. self.saves[self.cursorY].fileName)
          Gamestate.switch(game)
          game:show_level_description()
        else
          self.cursorY = line
        end
      end
    end
  else
    if x>self.yesbutton.minX and x<self.yesbutton.maxX and y>self.yesbutton.minY and y<self.yesbutton.maxY then
      delete_save(self.saves[self.cursorY].fileName)
      local y,scroll = self.cursorY,self.scroll
      Gamestate.switch(loadsaves)
      loadsaves.cursorY,loadsaves.scroll = y,scroll
    elseif x>self.nobutton.minX and x<self.nobutton.maxX and y>self.nobutton.minY and y<self.nobutton.maxY then
      self.deletewarning = false
      self.cursor = 3
      self.yesbutton,self.nobutton = nil,nil
    end
  end
end -- end mousepressed function

function loadsaves:mousemoved(x,y,dx,dy)
  if self.deletewarning == true then
    if x>self.yesbutton.minX and x<self.yesbutton.maxX and y>self.yesbutton.minY and y<self.yesbutton.maxY then
      self.cursorX = 1
    elseif x>self.nobutton.minX and x<self.nobutton.maxX and y>self.nobutton.minY and y<self.nobutton.maxY then
      self.cursorX = 2
    end
  else
    if self.loadbutton and x>self.loadbutton.minX and x<self.loadbutton.maxX and y>self.loadbutton.minY and y<self.loadbutton.maxY then
      self.cursorX = 2
    elseif self.deletebutton and x>self.deletebutton.minX and x<self.deletebutton.maxX and y>self.deletebutton.minY and y<self.deletebutton.maxY then
      self.cursorX = 3
    end
  end
end --end mousemoved function

function loadsaves:switchBack()
  tween(0.2,self,{yModPerc=100})
  Timer.after(0.2,function() self.switchNow=true end)
  output:sound('stoneslideshortbackwards',2)
end