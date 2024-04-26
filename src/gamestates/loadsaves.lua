loadsaves = {}

function loadsaves:enter()
  self.saves = load_all_saves()
  self.scroll = 0
  self.cursorX = 1
  self.cursorY = 0
  self.deletewarning = false
  self.maxScroll=0
  self.currSave = nil
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self:create_coordinates()
end

function loadsaves:create_coordinates()
  --Create y-coordinates for all saves:
  local uiScale = (prefs['uiScale'] or 1)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  width,height = round(width/uiScale),round(height/uiScale)
  local padding = (prefs['noImages'] and 16 or 32)
  local sidebarX = round(width/3)*2+padding
  self.saveCoordinates = {}
  for i,save in ipairs(self.saves) do
    local dateWidth = fonts.textFont:getWidth(os.date("%H:%M, %b %d, %Y",save.date))
    local _,textLines = fonts.textFont:getWrap(save.fileName,sidebarX-32-dateWidth-padding*2)
    local saveHeight = #textLines*prefs['fontSize']+(4*#textLines)
    local saveY = (i == 1 and padding*2 or self.saveCoordinates[i-1].maxY+math.ceil(prefs['fontSize']*.5))
    self.saveCoordinates[i] = {y=saveY,height=saveHeight,maxY=saveY+saveHeight}
  end
end

function loadsaves:draw()
  menu:draw()
  setColor(255,255,255,255)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width,height = round(width/uiScale),round(height/uiScale)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
	love.graphics.setFont(fonts.textFont)
  local sidebarX = round(width/3)*2+padding
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  love.graphics.printf("Load a Saved Game:",padding,round(padding*.75),sidebarX-padding,"center")
  
  local printX = (prefs['noImages'] and 14 or 32)
  local maxY = 0
  
  --Draw the actual saves:
  love.graphics.push()
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  mouseY=mouseY+self.scroll
  local function stencilFunc()
    local startY = padding*2
    love.graphics.rectangle("fill",0,startY,width,height-startY-padding)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scroll)
  for i,save in ipairs(self.saves) do
    local printY = self.saveCoordinates[i].y
    local saveHeight = self.saveCoordinates[i].height
    local saveMaxY = self.saveCoordinates[i].maxY
      local dateWidth = fonts.textFont:getWidth(os.date("%H:%M, %b %d, %Y",save.date))
      local _,textLines = fonts.textFont:getWrap(save.fileName,sidebarX-32-dateWidth-(needsScroll and padding or 0))
      if i == self.cursorY then
        setColor(100,100,100,255)
        love.graphics.rectangle("fill",printX,printY,sidebarX-padding-padding*2,saveHeight)
        setColor(255,255,255,255)
      elseif mouseX > padding and mouseX < sidebarX-padding*2 and mouseY > printY and mouseY < saveMaxY and self.deletewarning == false then
        setColor(100,100,100,125)
        love.graphics.rectangle("fill",printX,printY,sidebarX-padding-padding*2,saveHeight)
        setColor(255,255,255,255)
      end
      love.graphics.printf(save.fileName,printX,printY,sidebarX-32-dateWidth-padding*2)
      love.graphics.printf(os.date("%H:%M, %b %d, %Y",save.date),sidebarX-32-dateWidth-padding,printY,dateWidth,"right")
    maxY = self.saveCoordinates[i].y+self.saveCoordinates[i].height
  end
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  if maxY > height-padding then
    self.maxScroll = maxY-(height-padding)
    local scrollAmt = self.scroll/self.maxScroll
    self.scrollPositions = output:scrollbar(round(sidebarX-padding*1.75),padding*2,height-padding,scrollAmt,true)
  end
  
  --Display selected save, if any
  if self.cursorY and self.saves[self.cursorY] then
    local endX = width-padding
    local printY = padding
    local padY = prefs['fontSize']+2
    
    if self.cursorY and self.saves[self.cursorY] then
      if not self.currSave or self.currSave.fileName ~= self.saves[self.cursorY].fileName then
        local status,s = pcall(load_save_info,self.saves[self.cursorY].fileName)
        self.currSave = s
      end
      local save = self.currSave
      if save and save.player then
        love.graphics.setFont(fonts.buttonFont)
        self.loadbutton = output:button(sidebarX+padding,printY,75,false,((self.cursorX == 2 and self.deletewarning == false) and "hover" or nil),nil,true)
        love.graphics.printf("Load",sidebarX+padding,printY+4,75,"center")
        self.deletebutton = output:button(round(endX-padding*(prefs['noImages'] and 5 or 2.5)),printY,75,false,((self.cursorX == 3 and self.deletewarning == false) and "hover" or nil),nil,true)
        love.graphics.printf("Delete",round(endX-padding*(prefs['noImages'] and 5 or 2.5)),printY+4,75,"center")
        love.graphics.setFont(fonts.textFont)
        printY = printY+38
        if save.screenshot then
          local ratio = (endX-sidebarX-padding)/save.screenshot:getWidth()
          local ssheight = save.screenshot:getHeight()*ratio
          love.graphics.draw(save.screenshot,sidebarX+padding,printY,0,ratio,ratio)
          love.graphics.rectangle("line",sidebarX+padding,printY,endX-sidebarX-padding,ssheight)
          printY=round(printY+ssheight+prefs['fontSize'])
        end
        local _,nameLines = fonts.textFont:getWrap(save.player.properName .. "\n" .. ucfirst(save.player.name),endX-sidebarX-padding)
        love.graphics.printf(save.player.properName .. "\n" .. ucfirst(save.player.name),sidebarX+padding,printY,endX-sidebarX-padding,"center")
        save.currGame.stats = save.currGame.stats or {}
        printY = printY+padY*#nameLines
        local mapName = (save.currMap.fullName or "Depth " .. save.currMap.depth .. (save.currMap.name and ": " .. save.currMap.name or ""))
        local _,depthLines = fonts.textFont:getWrap(mapName,endX-sidebarX-padding)
        love.graphics.printf(mapName,sidebarX+padding,printY,endX-sidebarX-padding,"center")
        printY = printY+padY*#depthLines
        love.graphics.printf("Turns: " .. (save.currGame.stats.turns or 0),sidebarX+padding,printY,endX-sidebarX-padding,"center")
        --check game ID and game version
        setColor(255,255,255,255)
        if not save.gamesettings or (save.gamesettings.name ~= gamesettings.name) then
          printY = printY+padY*3
          setColor(255,0,0,255)
          love.graphics.printf("WARNING! This save file could be from a different game! This save is for game " .. (save.gamesettings and save.gamesettings.name or "Unknown") .. ", current game is " .. gamesettings.name .. ". If you load this save, it might not work correctly or may crash.",sidebarX+padding,printY,endX-sidebarX-padding,"center")
          printY = printY+padY*3
        elseif save.gamesettings.version ~= gamesettings.version then
          printY = printY+padY*3
          setColor(255,0,0,255)
          love.graphics.printf("WARNING! This save file could be from a different version! This save is for version " .. (save.gamesettings and save.gamesettings.version_text or "Unknown") .. ", current game version " .. gamesettings.version_text .. ". If you load this save, it might not work correctly or may crash.",sidebarX+padding,printY,endX-sidebarX-padding,"center")
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
    local startX = round(width/2-sizeX/2)
    local startY = round(height/2-sizeY)
    output:draw_window(startX,startY,startX+sizeX,startY+sizeY)
    love.graphics.printf("Are you sure you want to delete " .. self.currSave.player.properName .. "?",startX+padding,startY+padding,sizeX-padding,"center")
    love.graphics.setFont(fonts.buttonFont)
    self.yesbutton = output:button(startX+padding,startY+sizeY-padding-(prefs['noImages'] and padding or 0),75,false,(self.cursorX == 1 and "hover" or nil),nil,true)
    love.graphics.printf("(Y)es",startX+padding,startY+sizeY-padding-(prefs['noImages'] and padding or 0),75,"center")
    self.nobutton = output:button(startX+sizeX-75,startY+sizeY-padding-(prefs['noImages'] and padding or 0),75,false,(self.cursorX == 2 and "hover" or nil),nil,true)
    love.graphics.printf("(N)o",startX+sizeX-75,startY+sizeY-padding-(prefs['noImages'] and padding or 0),75,"center")
    love.graphics.setFont(fonts.textFont)
  end
  self.closebutton = output:closebutton((prefs['noImages'] and 16 or 24),(prefs['noImages'] and 16 or 24),nil,true)
  love.graphics.pop()
end

function loadsaves:update(dt)
  local padding = (prefs['noImages'] and 16 or 32)
  local uiScale = prefs['uiScale'] or 1
  local height = love.graphics.getHeight()
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(menu)
    Gamestate.update(dt)
    return
  end
  if self.cursorY < 0 then
    self.cursorY = 0
  elseif self.saveCoordinates[self.cursorY] and self.saveCoordinates[self.cursorY].y-self.scroll <= padding*3 then
    self:scrollUp()
  elseif self.saveCoordinates[self.cursorY] and self.saveCoordinates[self.cursorY].maxY-self.scroll > height/uiScale-padding then
    self:scrollDown()
  end
  if self.cursorY > #self.saves then
    self.cursorY = #self.saves
  end
  if self.maxScroll+self.scroll > #self.saves and self.needsScroll then
    self.scroll = #self.saves-self.maxScroll
  end
  --Scrolling:
  if self.scrollPositions and (love.mouse.isDown(1)) then
    local x,y = love.mouse.getPosition()
    x,y = round(x/uiScale),round(y/uiScale)
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

function loadsaves:buttonpressed(key,scancode,isRepeat,controllerType)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if self.deletewarning == false then
    if key == "escape" then
      self:switchBack()
    elseif key == "north" then
      self.cursorY = self.cursorY-1
      self.cursorX = 1
    elseif key == "south" then
      if self.cursorY < #self.saves then
        self.cursorY = self.cursorY+1
        self.cursorX = 1
      end
    elseif key == "west" then
      self.cursorX = math.max(self.cursorX - 1,1)
    elseif key == "east" and self.currSave then
      self.cursorX = math.min (self.cursorX + 1,3)
    elseif key == "enter" or key == "wait" then
      if self.cursorX == 1 and self.saves[self.cursorY] and self.currSave then
        self.cursorX = 2
      elseif self.cursorX == 2 and self.cursorY ~= 0 and self.saves[self.cursorY] and self.currSave then
        --TODO: add a check to make sure loading this save won't crash?
        load_game("saves/" .. self.saves[self.cursorY].fileName)
        Gamestate.switch(game)
        game:show_map_description()
      elseif self.cursorX == 3 and self.currSave then
        self.deletewarning = true
        self.cursorX = 2
      end
    end
  else
    if key == "escape" then
      self.deletewarning = false
      self.yesbutton,self.nobutton = nil,nil
      self.cursorX = 3
    elseif key == "west" then
      self.cursorX = 1
    elseif key == "east" then
      self.cursorX = 2
    elseif key == "yes" then
      delete_save(self.saves[self.cursorY].fileName)
      local y,scroll = self.cursorY,self.scroll
      Gamestate.switch(loadsaves)
      loadsaves.cursorY,loadsaves.scroll = y,scroll
    elseif key == "nes" then
      self.deletewarning = false
      self.yesbutton,self.nobutton = nil,nil
      self.cursorX = 3
    elseif key == "enter" or key == "wait" then
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
  local padding = (prefs['noImages'] and 16 or 32)
  local height = love.graphics.getHeight()
  if self.scroll > 0 and self.deletewarning == false then
    self.scroll = self.scroll - prefs['fontSize']
    if self.saveCoordinates[self.cursorY] and self.saveCoordinates[self.cursorY].maxY-self.scroll > height-padding then
      self.cursorY=self.cursorY-1
      self.cursorX = 1
    end
  end
end

function loadsaves:scrollDown()
  local padding = (prefs['noImages'] and 16 or 32)
  if self.scroll < self.maxScroll and self.deletewarning == false then
    self.scroll = self.scroll + prefs['fontSize']
    if self.saveCoordinates[self.cursorY] and self.saveCoordinates[self.cursorY].y-self.scroll <= padding*3 then
      self.cursorY = self.cursorY+1
      self.cursorX = 1
    end
  end
end
  
function loadsaves:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y = round(x/uiScale),round(y/uiScale)
  if self.deletewarning == false then
    if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then 
      self:switchBack()
    end
    if self.loadbutton and x>self.loadbutton.minX and x<self.loadbutton.maxX and y>self.loadbutton.minY and y<self.loadbutton.maxY then
      output:play_playlist('silence')
      load_game("saves/" .. self.saves[self.cursorY].fileName)
      Gamestate.switch(game)
      game:show_map_description()
    elseif self.deletebutton and x>self.deletebutton.minX and x<self.deletebutton.maxX and y>self.deletebutton.minY and y<self.deletebutton.maxY then
      self.deletewarning = true
      self.cursorX = 2
    else
      local padding = (prefs['noImages'] and 16 or 32)
      local sidebarX = round(love.graphics.getWidth()/3)*2+padding
      if x > padding and x < sidebarX-padding*2 then
        local line = nil
        local mouseY = y+self.scroll
        for i,coords in ipairs(self.saveCoordinates) do
          if mouseY > coords.y and mouseY < coords.maxY then
            line = i
            break
          end
        end --end coordinate for
        if line and self.cursorY == line and self.cursorY >= 1 then
          output:play_playlist('silence')
          if load_game("saves/" .. self.saves[self.cursorY].fileName) then
            Gamestate.switch(game)
            game:show_map_description()
          end
        elseif line then
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