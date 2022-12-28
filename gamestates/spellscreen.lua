spellscreen = {}

function spellscreen:enter()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  
  --Set initial coordinates and such:
  local padX,padY = 0,0
  if prefs['noImages'] == true then
    padX,padY=5,5
  else
    padX,padY=20,20
  end
  width,height = round(width/uiScale),round(height/uiScale)
  self.sidebarX = round(width/2)+(prefs['noImages'] and 16 or 32)
  self.padding = (prefs['noImages'] and 16 or 32)
  self.x,self.y=1,1
  self.padX,self.padY = padX,padY
  self.cursorY = 0
  self.cursorX = 1
  self.sidebarCursorY = 1
  self.yModPerc = 100
  self.scrollY = 0
  self.descScrollY = 0
  self.scrollMax = 0
  self.descScrollMax = 0
  self.startY=0
  self.playerSpells = player:get_spells()
  self.buttons = {}
  self.upgradebuttons = {}
  
  self.yModPerc = 0
  if previous == game then
    self.yModPerc = 100
    tween(0.2,self,{yModPerc=0})
    output:sound('stoneslideshort',2)
  end
  self.spellLines = {}
end

function spellscreen:draw()
  local uiScale = (prefs['uiScale'] or 1)
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  width,height = round(width/uiScale),round(height/uiScale)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padX,padY = self.padX,self.padY
  local x,y=self.x,self.y
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  local fontSize = prefs['fontSize']
	
  self.screenMax = round(height/(fontSize+2)/2)
  local padding = self.padding
	love.graphics.setFont(fonts.textFont)
  local sidebarX = self.sidebarX
  local window1w = sidebarX-padding-padX
  local window2w = width-sidebarX-padX-padding
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  
  local printY = fontSize*4
  local printX = (prefs['noImages'] and 14 or 32)
  
  love.graphics.printf("Spells and Abilities",padding,padding,window1w,"center")
  local spellPoints = (not player.spellPoints and 0 or player.spellPoints)
  if spellPoints > 0 then
    love.graphics.printf("You have " .. spellPoints .. " points to spend.",padding,padding+fontSize,window1w,"center")
    printY = printY+fontSize
  end
  self.startY = printY
  
  --Display filter buttons:
  local maxFilterX = sidebarX-padding
  
  --Drawing the text:
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",padX,printY-4,maxFilterX-padX*2,height-padding-printY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  local playerSpells = self.playerSpells
  --Display the spells:
  local bottom = 0
	local spells = {}
  local line=1
  local mousedSpell = nil
	for i, spell in pairs(playerSpells) do
    local moused = (mouseX > printX and mouseX < window1w and mouseY+self.scrollY > printY and mouseY+self.scrollY < printY+fontSize+2)
    local spellID = spell.id
		spells[i] = spellID
    local name = spell.name
    local target_type = spell.target_type
    local upgrade = (spellPoints > 0 and (count(spell:get_possible_upgrades()) > 0))
    --Draw the highlight box:
    if (self.cursorY == i) then
      if self.cursorX == 2 then
        setColor(125,125,125,255)
      else
        setColor(100,100,100,255)
      end
      love.graphics.rectangle("fill",x+padX,printY,window1w-padX*2,fontSize+2)
      setColor(255,255,255,255)
    elseif moused then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",x+padX,printY,window1w-padX*2,fontSize+2)
      setColor(255,255,255,255)
      mousedSpell = i
    end
    if player.cooldowns[name] or spell:requires(player) == false then
      if moused or self.cursorY == i then
        setColor(25,25,(upgrade and 0 or 25),255)
      else
        setColor(100,100,(upgrade and 0 or 100),255)
      end
    else
      setColor(255,255,(upgrade and 0 or 255),255)
    end --end cooldowns if
		love.graphics.print((spell.hotkey and spell.hotkey .. ") " or "") .. name .. (player.cooldowns[name] and " (" .. player.cooldowns[name] .. " turns to recharge)" or "") .. (target_type == "passive" and " (Passive)" or "") .. (upgrade and " (+)" or ""),x+padX,printY)
    if player.cooldowns[name] or spell:requires(player) == false then
      setColor(255,255,255,255)
    end
		line = line+1
    self.spellLines[i] = {minY=printY,maxY=printY+fontSize+2}
    printY = printY+fontSize+2
	end
  bottom = printY
  
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  --Description Box:
  local spell = playerSpells[self.cursorY] or playerSpells[mousedSpell]
  if spell ~= nil then
    love.graphics.push()
    local target_type = spell.target_type
    local spellText = spell:get_description()
    local printY = padding
    local printX = sidebarX+padX
    local hotkey = spell.hotkey
    local selected = (self.cursorX ~= 1)
    
    if target_type == "passive" then
      spellText = spellText .. "\n\nThis ability is passive and is used automatically when needed."
    end
    
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(fonts.textFont)
    local width, tlines = fonts.textFont:getWrap(spellText,window2w)
    local height = (#tlines+1)*fontSize
    love.graphics.printf(spell.name,printX,printY,window2w,"center")
    printY=printY+fontSize+2
    love.graphics.printf(spellText,printX,printY,window2w,"left")
    printY=printY+height
    
    --Buttons:
    if spell.target_type ~= "passive" then
      if not selected then
        setColor(175,175,175,255)
      end
      local buttonHeight = 32
      local useText = "Use"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if player.cooldowns[spell.name] or spell:requires(player) == false then
        setColor(100,100,100,255)
      end
      self.buttons.use = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == 1 and "hover" or nil),useText,true)
      if player.cooldowns[spell.name] or spell:requires(player) == false then
        if selected then setColor(255,255,255,255)
        else setColor(175,175,175,255) end
      end
      printY = printY+buttonHeight
      local hotkeyText = (hotkey and "Change Hotkey" or "Assign Hotkey")
      local buttonWidth = fonts.buttonFont:getWidth(hotkeyText)+25
      self.buttons.hotkey = output:button(printX,printY,buttonWidth,false,(self.cursorX == 2 and self.sidebarCursorY == 2 and "hover" or nil),hotkeyText,true)
      printY = printY+buttonHeight
      if not selected then
        setColor(255,255,255,255)
      end
    end
    
    --Print stats
    local statText = ""
    if spell.charges then
      statText = statText .. "\nCharges: " .. spell.charges .. (spell.max_charges and "/" .. spell.max_charges or "")
    end
    if spell.cost then
      statText = statText .. "\nMP Cost: " .. spell.cost
    end
    if spell.cooldown then
      statText = statText .. "\nCooldown: " .. spell.cooldown .. " Turns"
    end
    if spell.min_range then
      statText = statText .. "\nMin Range: " .. spell.range
    end
    if spell.range then
      statText = statText .. "\nMax Range: " .. spell.range
    end
    if spell.stats then
      local stats = {}
      for stat,info in pairs(spell.stats) do
        info.id = stat
        local display_order = info.display_order
        if display_order then
          table.insert(stats,display_order,info)
        else
          table.insert(stats,info)
        end
      end
      for i,stat in pairs(stats) do
        print(i,stat.name,stat.value)
        if stat.value ~= false and (stat.value ~= 0 or stat.hide_when_zero ~= true) and stat.hide ~= true then
          statText = statText .. "\n" .. stat.name .. (type(stat.value) ~= "boolean" and ": " .. stat.value or "") .. (stat.description and " (" .. stat.description .. ")" or "")
        end
      end
    end
    love.graphics.printf(statText,printX,printY,window2w,"left")
    local _, slines = fonts.textFont:getWrap(statText,window2w)
    local sHeight = (#slines+2)*fontSize
    printY = printY+sHeight
    
    --Print upgrades --TODO: Show stat changes of upgrade when hovered
    if spell.possible_upgrades then
      local upgrades = spell:get_possible_upgrades()
      if count(upgrades) > 0 then
        self.upgradebuttons = {}
        love.graphics.printf("Upgrades:",printX,printY,window2w,"left")
        printY=printY+fontSize
        local buttonY = 1
        local mod = (spell.target_type == "passive" and 0 or 2)
        for id,level in pairs(upgrades) do
          if spellPoints < 1 then
            setColor(100,100,100,255)
          elseif not selected then
            setColor(175,175,175,255)
          end
          self.upgradebuttons[buttonY] = output:tinybutton(printX,printY+2,true,self.sidebarCursorY==buttonY+mod,"+",true)
          self.upgradebuttons[buttonY].upgradeID = id
          setColor(255,255,255,255)
          local buttonW = 34
          local details = spell.possible_upgrades[id]
          local upText = (details.name or ucfirst(id)) .. (details.description and " (" .. details.description .. ")" or "")
          love.graphics.printf(upText,printX+buttonW,printY,window2w,"left")
          local _, dlines = fonts.textFont:getWrap(upText,window2w)
          local dHeight = #dlines*fontSize
          printY = printY+dHeight
          buttonY=buttonY+1
        end
      end
    end
    
    --TODO: Print scrollbars
    
    love.graphics.setFont(oldFont)
    love.graphics.pop()
  end
  
  --Scrollbars
  if bottom > height-padding then
    self.scrollMax = math.ceil((bottom-(self.startY+(love.graphics:getHeight()/uiScale-self.startY))+padding*2))
    local scrollAmt = self.scrollY/self.scrollMax
    self.scrollPositions = output:scrollbar(window1w,self.y+padY,height-padY,scrollAmt,true)
  end
  
  self.closebutton = output:closebutton(self.x+(prefs['noImages'] and 8 or 20),self.y+(prefs['noImages'] and 8 or 20),nil,true)
  love.graphics.pop()
end

function spellscreen:keypressed(key)
  local uiScale = prefs['uiScale']
  key = input:parse_key(key)
  local playerSpells = player:get_spells()
	if (key == "escape") then
    if self.cursorX == 1 then
      self:switchBack()
    else
      self.cursorX = 1
    end
	elseif (key == "enter") or key == "wait" then
    if self.cursorX == 1 and playerSpells[self.cursorY] then
      self:select_spell(self.cursorY)
    elseif self.cursorX == 2 then
      local spell = playerSpells[self.cursorY]
      local passive = (spell.target_type == "passive")
      if not passive then
        if self.sidebarCursorY == 1 then
          return self:cast_spell(self.cursorY)
        elseif self.sidebarCursorY == 2 then
          return Gamestate.switch(hotkey,playerSpells[self.cursorY])
        end
      end
      if self.upgradebuttons then
        for index,button in ipairs(self.upgradebuttons) do
          local mod = (passive and 0 or 2)
          if self.sidebarCursorY == index+mod then
            self:perform_upgrade(button.upgradeID)
            return
          end
        end
      end
    end
	elseif (key == "north") then
    if self.cursorX == 1 then
      if (playerSpells[self.cursorY-1] ~= nil) then
        self.cursorY = self.cursorY - 1
      end
      if self.spellLines[self.cursorY] and self.spellLines[self.cursorY].minY-self.scrollY-prefs['fontSize'] < self.startY then
        self:scrollUp()
      end
    else --if a spell is selected
      self.sidebarCursorY = math.max(self.sidebarCursorY-1,1)
    end
	elseif (key == "south") then
    if self.cursorX == 1 then
      if (playerSpells[self.cursorY+1] ~= nil) then
        self.cursorY = self.cursorY + 1
      end
      if self.spellLines[self.cursorY].maxY-self.scrollY+prefs['fontSize'] >= round(love.graphics.getHeight()/uiScale)-32 and self.scrollY < self.scrollMax then
        self:scrollDown()
      end
    else -- if a spell is selected
      local spell = playerSpells[self.cursorY]
      local max = (self.upgradebuttons and #self.upgradebuttons or 0)+(spell.target_type == "passive" and 0 or 2)
      if self.sidebarCursorY < max then
        self.sidebarCursorY = self.sidebarCursorY+1
      end
    end
  elseif (key == "east") then
    if playerSpells[self.cursorY] then self:select_spell(self.cursorY) end
  elseif (key == "west") then
    self.cursorX = 1
	end
end

function spellscreen:mousepressed(x,y,button)
  local playerSpells = player:get_spells()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale,y/uiScale
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then self:switchBack() end
  if x > self.x and x < self.sidebarX-(self.scrollPositions and self.padding or 0) then
    for index,coords in ipairs(self.spellLines) do
      if y+self.scrollY > coords.minY and y+self.scrollY < coords.maxY then
        self:select_spell(index)
      end
    end
  end
  if self.cursorX > 1 and x > self.sidebarX then --if a spell is selected
    if self.buttons.use and x > self.buttons.use.minX and x < self.buttons.use.maxX and y > self.buttons.use.minY and y < self.buttons.use.maxY then
      return self:cast_spell(self.cursorY)
    elseif self.buttons.hotkey and x > self.buttons.hotkey.minX and x < self.buttons.hotkey.maxX and y > self.buttons.hotkey.minY and y < self.buttons.hotkey.maxY then
      return Gamestate.switch(hotkey,playerSpells[self.cursorY])
    end
    for index,button in ipairs(self.upgradebuttons) do
      if x > button.minX and x < button.maxX and y > button.minY and y < button.maxY then
        self:perform_upgrade(button.upgradeID)
      end
    end
  end
end

function spellscreen:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end --end button type if
end

function spellscreen:scrollUp()
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
  end
end

function spellscreen:scrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
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
  local playerSpells = player:get_spells()
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale, y/uiScale
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

function spellscreen:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function spellscreen:cast_spell(spellIndex)
  local playerSpells = player:get_spells()
  local spell = playerSpells[spellIndex] or playerSpells[self.cursorY]
  if(spell:target(target,player) ~= false) then
    advance_turn()
  end
  self:switchBack()
end

function spellscreen:select_spell(spellIndex)
  self.cursorY = spellIndex
  self.cursorX = 2
  self.sidebarCursorY=1
end

function spellscreen:perform_upgrade(upgradeID)
  local spell = self.playerSpells[self.cursorY]
  if not spell or not spell.possible_upgrades or not spell.possible_upgrades[upgradeID] then
    return false
  end
  if spell:apply_upgrade(upgradeID) then
    player.spellPoints = player.spellPoints-1
  end
end