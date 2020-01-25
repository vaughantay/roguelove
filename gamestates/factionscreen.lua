factionscreen = {}

function factionscreen:enter(_,whichFac)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
  output:sound('stoneslideshort',2)
  self.cursorY = 0
  self.cursorX = 1
  self.faction = factions[whichFac]
  self.playerMember = player:is_faction_member(whichFac)
  self.screen="Info"
  self.outText = nil
end

function factionscreen:draw()
  local factionID = self.faction.id
  local faction = self.faction
  game:draw()
  love.graphics.setFont(fonts.textFont)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle('fill',0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']+2
  local windowX = math.floor(width/4/uiScale)
  local windowWidth = math.floor(width/2/uiScale)
  local midX = math.floor(width/2)
  output:draw_window(windowX,1,windowX+windowWidth,math.floor(height/uiScale-padding))
  local printX = windowX+fontSize
  --Basic header display:
  love.graphics.printf(faction.name,printX,padding,windowWidth,"center")
  local printY = padding+fontSize*2
  local favor = (player.favor[factionID] or 0)
  love.graphics.printf("Your Favor: " .. favor,printX,printY,windowWidth,"center")
  printY = printY+fontSize
  --Relationship text:
  local relationship = nil
  if self.playerMember then
    relationship = "You are a member of this faction."
  elseif faction:is_enemy(player) then
    relationship = "This faction sees you as an enemy."
  elseif faction:is_friend(player) then
    relationship = "This faction sees you as a friend."
  else
    relationship = "This faction is neutral towards you."
  end
  love.graphics.printf(relationship,printX,printY,windowWidth,"center")
  
  if not self.playerMember then
    --Join text:
    local joinText = nil
    local canJoin,reason = faction:can_join(player)
    if canJoin then
      joinText = "You are eligible to join this faction."
    else
      joinText = "You're not eligible to join this faction" .. (reason and " for the following reasons: " or ".")
    end
    printY=printY+fontSize
    love.graphics.printf(joinText,printX,windowWidth,width,"center")
    if reason then
      printY = printY+fontSize
      local _, wrappedtext = fonts.textFont:getWrap(reason, windowWidth)
      love.graphics.printf(reason,printX,printY,windowWidth,"center")
      printY=printY+(#wrappedtext)*fontSize
    end
    printY=printY+fontSize
  end
  
  if self.outText then
    printY=printY+fontSize*2
    local _, wrappedtext = fonts.textFont:getWrap(self.outText, windowWidth)
    love.graphics.printf(self.outText,printX,printY,windowWidth,"center")
    printY=printY+#wrappedtext*fontSize
  end
  
  if not faction.enterThreshold or ((player.favor[factionID] or 0) >= faction.enterThreshold) then
    printY=printY+fontSize
    local padX = 8
    local infobuttonW = fonts.textFont:getWidth("Information")+padding
    local shopbuttonW = fonts.textFont:getWidth("Items")+padding
    local spellbuttonW = fonts.textFont:getWidth("Abilities")+padding
    local servicebuttonW = fonts.textFont:getWidth("Services")+padding
    local missionbuttonW = fonts.textFont:getWidth("Missions")+padding
    local totalWidth = windowWidth
    local startX = math.floor(midX-totalWidth/2)+padding
    self.infoButton = output:button(startX,printY,infobuttonW+padX,false,((self.cursorX == 1 and self.cursorY == 2) and "hover" or nil),"Information")
    self.shopButton = output:button(startX+infobuttonW+padX*2,printY,shopbuttonW,false,((self.cursorX == 2 and self.cursorY == 2) and "hover" or nil),"Items")
    self.spellsButton = output:button(startX+infobuttonW+shopbuttonW+padX*3,printY,spellbuttonW,false,((self.cursorX == 3 and self.cursorY == 2) and "hover" or nil),"Abilities")
    self.serviceButton = output:button(startX+infobuttonW+shopbuttonW+spellbuttonW+padX*4,printY,servicebuttonW,false,((self.cursorX == 4 and self.cursorY == 2) and "hover" or nil),"Services")
    self.missionButton = output:button(startX+infobuttonW+shopbuttonW+spellbuttonW+servicebuttonW+padX*5,printY,missionbuttonW,false,((self.cursorX == 5 and self.cursorY == 2) and "hover" or nil),"Missions")
    printY = printY+padX
  else
    love.graphics.printf("You need at least " .. faction.enterThreshold .. " favor to do business with this faction.",printX,printY,windowWidth,"center")
  end
  printY=printY+padding
  love.graphics.line(printX,printY,printX+windowWidth,printY)
  printY=printY+8
  
  
  --Draw the screens:
  if self.screen == "Info" then
    love.graphics.printf(faction.description,printX,printY,windowWidth,"center")
    local _, wrappedtext = fonts.textFont:getWrap(faction.description, windowWidth)
    printY=printY+(#wrappedtext+1)*fontSize
    if faction.friendlyFactions then
      local friendlyText = "Liked Factions:\n"
      for i,fac in ipairs(faction.friendlyFactions) do
        friendlyText = friendlyText .. (i > 1 and ", " or "") .. factions[fac].name
      end
      love.graphics.printf(friendlyText,printX,printY,windowWidth,"center")
      local _, wrappedtext = fonts.textFont:getWrap(friendlyText, windowWidth)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.enemyFactions then
      local enemyText = "Hated Factions:\n"
      for i,fac in ipairs(faction.enemyFactions) do
        enemyText = enemyText .. (i > 1 and ", " or "") .. factions[fac].name
      end
      love.graphics.printf(enemyText,printX,printY,windowWidth,"center")
      local _, wrappedtext = fonts.textFont:getWrap(enemyText, windowWidth)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.friendlyTypes then
      local friendlyText = "Liked creature types:\n"
      for i,typ in ipairs(faction.friendlyTypes) do
        friendlyText = friendlyText .. (i > 1 and ", " or "") .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ))
      end
      love.graphics.printf(friendlyText,printX,printY,windowWidth,"center")
      local _, wrappedtext = fonts.textFont:getWrap(friendlyText, windowWidth)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.enemyTypes then
      local enemyText = "Hated creature types:\n"
      for i,typ in ipairs(faction.enemyTypes) do
        enemyText = enemyText .. (i > 1 and ", " or "") .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ))
      end
      love.graphics.printf(enemyText,printX,printY,windowWidth,"center")
      local _, wrappedtext = fonts.textFont:getWrap(enemyText, windowWidth)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.killFavor_factions or faction.killFavor_types then
      love.graphics.printf("Kill Favor:",printX,printY,windowWidth,"center")
      printY=printY+fontSize
      if faction.killFavor_factions then
        local killtext = ""
        for fac,favor in pairs(faction.killFavor_factions) do
          killtext = killtext .. (favor > 0 and "+" or "") .. favor .. ": members of " .. factions[fac].name .. "\n"
        end
        love.graphics.printf(killtext,printX,printY,windowWidth,"left")
        local _, wrappedtext = fonts.textFont:getWrap(killtext, windowWidth)
        printY=printY+(#wrappedtext)*fontSize
      end --end killfavor faction if
      if faction.killFavor_types then
        local killtext = ""
        for typ,favor in pairs(faction.killFavor_types) do
          killtext = killtext .. (favor > 0 and "+" or "") .. favor .. ": creatures of type " .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ)) .. "\n"
        end
        love.graphics.printf(killtext,printX,printY,windowWidth,"left")
        local _, wrappedtext = fonts.textFont:getWrap(killtext, windowWidth)
        printY=printY+(#wrappedtext+1)*fontSize
      end --end killfavor type if
    end --end if kill favor anyhwere
    
  elseif self.screen == "Items" then
  elseif self.screen == "Spells" then
    self.spellButtons = {}
    for i,spellDef in ipairs(faction.teaches_spells or {}) do
      if not player:has_spell(spellDef.spell) then
        local spell = possibleSpells[spellDef.spell]
        local costText = nil
        if spellDef.moneyCost then
          costText = " (Cost: $" .. spellDef.moneyCost
        end
        if spellDef.favorCost then
          if costText == nil then
            costText = " (Cost: "
          else
            costText = costText .. ", "
          end
          costText = costText .. spellDef.favorCost .. " Favor"
        end
        if costText then costText = costText .. ")" end
        local spellText = spell.name .. (costText or "") .. "\n" .. spell.description
        local __, wrappedtext = fonts.textFont:getWrap(spellText, windowWidth)
        love.graphics.printf(spellText,windowX,printY,windowWidth,"center")
        printY=printY+(#wrappedtext)*fontSize
        if spellDef.membersOnly and not self.playerMember then
          love.graphics.printf("This ability is only taught to members.",windowX,printY,windowWidth,"center")
        elseif spellDef.favorCost and player.favor[faction.id] < spellDef.favorCost then
          love.graphics.printf("You don't have enough favor to learn this ability.",windowX,printY,windowWidth,"center")
        elseif spellDef.moneyCost and player.money < spellDef.moneyCost then
          love.graphics.printf("You don't have enough money to learn this ability.",windowX,printY,windowWidth,"center")
        else
          local spellW = fonts.textFont:getWidth("Learn " .. spell.name)+padding
          local button = output:button(math.floor(midX-spellW/2),printY,spellW,false,(self.cursorY == 2+#self.spellButtons+1 and "hover" or nil),"Learn " .. spell.name)
          button.spellID = spellDef.spell
          self.spellButtons[#self.spellButtons+1] = button 
          printY=printY+32
        end
        printY=printY+fontSize
      end
    end
  elseif self.screen == "Services" then
    self.serviceButtons = {}
    for i,servID in ipairs(faction.offers_services or {}) do
      local service = possibleServices[servID]
      local costText = service:get_cost(player)
      local serviceText = service.name .. (costText and " (Cost: " .. costText .. ")" or "") .. "\n" .. service.description
      local __, wrappedtext = fonts.textFont:getWrap(serviceText, windowWidth)
      love.graphics.printf(serviceText,windowX,printY,windowWidth,"center")
      printY=printY+(#wrappedtext)*fontSize
      local canDo,canDoText = service:requires(player)
      if canDo == false then
        canDoText = "You're not eligible for this service" .. (canDoText and ": " .. canDoText or ".")
        local __, wrappedtext = fonts.textFont:getWrap(canDoText, windowWidth)
        love.graphics.printf(canDoText,windowX,printY,windowWidth,"center")
        printY=printY+(#wrappedtext)*fontSize
        self.serviceButtons[#self.serviceButtons+1] = false
      else
        local serviceW = fonts.textFont:getWidth("Select " .. service.name)+padding
        self.serviceButtons[#self.serviceButtons+1] = output:button(math.floor(midX-serviceW/2),printY,serviceW,false,(self.cursorY == 2+i and "hover" or nil),"Select " .. service.name)
        printY=printY+32
      end
      printY=printY+fontSize
    end
  elseif self.screen == "Missions" then
end

  self.closebutton = output:closebutton(windowX+24,24,nil,true)
  love.graphics.pop()
end

function factionscreen:keypressed(key)
  if key == "escape" then
    self:switchBack()
  elseif (key == "return" or key == "kpenter") then
    if self.cursorY == 1 then --join button
      
    elseif self.cursorY == 2 then --nav buttons
      if self.cursorX == 1 then self.screen = "Info"
      elseif self.cursorX == 2 then self.screen = "Items"
      elseif self.cursorX == 3 then self.screen = "Spells"
      elseif self.cursorX == 4 then self.screen = "Services"
      elseif self.cursorX == 5 then self.screen = "Missions" end
    else --activating something on the screen itself
      if self.screen == "Services" then
        if self.cursorY > 2 and self.serviceButtons[self.cursorY-2] then
          local service = possibleServices[self.faction.offers_services[self.cursorY-2]]
          local didIt, useText = service:activate(player)
          if useText then self.outText = useText end
        end
      elseif self.screen == "Spells" then
        if self.cursorY > 2 and self.spellButtons[self.cursorY-2] then
          local spellID = self.spellButtons[self.cursorY-2].spellID
          local spell = possibleSpells[spellID]
          if self.faction:teach_spell(spellID,player) ~= false then
            self.outText = "You learn " .. spell.name .. "."
          end
        end
      end --end which screen if
    end --end cursorY tests within return
  elseif key == "left" then
    self.cursorX = self.cursorX - 1
    if self.cursorY == 2 and self.cursorX < 1 then self.cursorX = 5 end --looping if on the nav buttons
    if self.cursorY < 2 then self.cursorY = 2 self.cursorX = 5 end --if above the nav buttons, move to them
  elseif key == "right" then
    self.cursorX = self.cursorX + 1
    if self.cursorY == 2 and self.cursorX > 5 then self.cursorX = 1 end --looping if on the nav buttons
    if self.cursorY < 2 then self.cursorY = 2 self.cursorX = 1 end --if above the nav buttons, move to them
  elseif key == "up" then
    if self.cursorY < 3 then --Top bars only
      self.cursorY = math.max((self.faction:can_join(player) and 1 or 2),self.cursorY-1)
    elseif self.screen == "Services" then
      for i=self.cursorY-1,3,1 do
        if self.serviceButtons[i-2] ~= false then
          self.cursorY = i
          break
        end
        self.cursorY = 2
      end --end cursorY for
    elseif self.screen == "Spells" then
      for i=self.cursorY-1,3,1 do
        if self.spellButtons[i-2] ~= false then
          self.cursorY = i
          break
        end
        self.cursorY = 2
      end --end cursorY for
    end --end cursorY check
  elseif key == "down" then
    if self.cursorY < 2 then --Top bars only
      self.cursorY = self.cursorY + 1
      if self.cursorY == 1 and not self.faction:can_join(player) then
        self.cursorY = 2
      end
    elseif self.screen == "Services" then
      for i=self.cursorY-1,#self.serviceButtons,1 do
        if self.serviceButtons[i] ~= false then
          self.cursorY = i+2
          break
        end
      end
    elseif self.screen == "Spells" then
      for i=self.cursorY-1,#self.spellButtons,1 do
        if self.spellButtons[i] ~= false then
          self.cursorY = i+2
          break
        end
      end --end cursorY for
    end --end cursorY check
  end --end key if
end

function factionscreen:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y=x/uiScale,y/uiScale
  if (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    self:switchBack()
  end
  --Navbuttons:
  if x > self.infoButton.minX and x < self.infoButton.maxX and y > self.infoButton.minY and y < self.infoButton.maxY then
    self.screen = "Info"
  elseif x > self.shopButton.minX and x < self.shopButton.maxX and y > self.shopButton.minY and y < self.shopButton.maxY then
    self.screen = "Items"
  elseif x > self.spellsButton.minX and x < self.spellsButton.maxX and y > self.spellsButton.minY and y < self.spellsButton.maxY then
    self.screen = "Spells"
  elseif x > self.serviceButton.minX and x < self.serviceButton.maxX and y > self.serviceButton.minY and y < self.serviceButton.maxY then
    self.screen = "Services"
  elseif x > self.missionButton.minX and x < self.missionButton.maxX and y > self.missionButton.minY and y < self.missionButton.maxY then
    self.screen = "Missions"
  end
end

function factionscreen:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
end

function factionscreen:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end