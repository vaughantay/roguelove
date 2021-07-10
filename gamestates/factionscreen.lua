factionscreen = {}

function factionscreen:enter(_,whichFac)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
  output:sound('stoneslideshort',2)
  self.cursorY = 0
  self.cursorX = 1
  self.faction = currWorld.factions[whichFac]
  self.playerMember = player:is_faction_member(whichFac)
  self.screen="Info"
  self.subScreen="Buy"
  self.outText = nil
  self.totalCost = {favor=0,money=0}
  self:refresh_store_lists()
  self.lineCountdown = .5
end

function factionscreen:refresh_store_lists()
  self.buying_list = {}
  self.selling_list = {}

  for _,ilist in pairs(self.faction:get_inventory()) do
    local item = ilist.item
    self.selling_list[#self.selling_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),moneyCost=ilist.moneyCost,favorCost=ilist.favorCost,membersOnly=ilist.membersOnly,amount=item.amount,buyAmt=0,item=item}
  end
  for _,ilist in pairs(self.faction:get_buy_list()) do
    local item = ilist.item
    self.buying_list[#self.buying_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),moneyCost=ilist.moneyCost,favorCost=ilist.favorCost,amount=item.amount,buyAmt=0,item=item}
  end
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
  local _, wrappedtext = fonts.textFont:getWrap(relationship, windowWidth)
  printY=printY+(#wrappedtext)*fontSize
  
  if not self.playerMember then
    --Join text:
    local joinText = nil
    local canJoin,reason = faction:can_join(player)
    if canJoin then
      joinText = "You are eligible to join this faction."
      --TODO: Add join button
    else
      joinText = "You're not eligible to join this faction" .. (reason and " for the following reasons: " or ".")
    end
    love.graphics.printf(joinText,printX,printY,windowWidth,"center")
    local _, wrappedtext = fonts.textFont:getWrap(joinText, windowWidth)
    printY=printY+(#wrappedtext)*fontSize
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
  
  if not faction.enter_threshold or ((player.favor[factionID] or 0) >= faction.enter_threshold) then
    printY=printY+fontSize
    local padX = 8
    local infobuttonW = fonts.textFont:getWidth("Information")+padding
    local shopbuttonW = fonts.textFont:getWidth("Items")+padding
    local spellbuttonW = fonts.textFont:getWidth("Abilities")+padding
    local servicebuttonW = fonts.textFont:getWidth("Services")+padding
    local missionbuttonW = fonts.textFont:getWidth("Missions")+padding
    local totalWidth = windowWidth
    local startX = math.floor(midX-totalWidth/2)+padding
    if self.screen == "Info" then setColor(150,150,150,255) end
    self.infoButton = output:button(startX,printY,infobuttonW+padX,false,((self.cursorX == 1 and self.cursorY == 2) and "hover" or nil),"Information")
    if self.screen == "Info" then setColor(255,255,255,255) end
    if self.screen == "Items" then setColor(150,150,150,255) end
    self.shopButton = output:button(startX+infobuttonW+padX*2,printY,shopbuttonW,false,((self.cursorX == 2 and self.cursorY == 2) and "hover" or nil),"Items")
    if self.screen == "Items" then setColor(255,255,255,255) end
    if self.screen == "Spells" then setColor(150,150,150,255) end
    self.spellsButton = output:button(startX+infobuttonW+shopbuttonW+padX*3,printY,spellbuttonW,false,((self.cursorX == 3 and self.cursorY == 2) and "hover" or nil),"Abilities")
    if self.screen == "Spells" then setColor(255,255,255,255) end
    if self.screen == "Services" then setColor(150,150,150,255) end
    self.serviceButton = output:button(startX+infobuttonW+shopbuttonW+spellbuttonW+padX*4,printY,servicebuttonW,false,((self.cursorX == 4 and self.cursorY == 2) and "hover" or nil),"Services")
    if self.screen == "Services" then setColor(255,255,255,255) end
    if self.screen == "Missions" then setColor(150,150,150,255) end
    self.missionButton = output:button(startX+infobuttonW+shopbuttonW+spellbuttonW+servicebuttonW+padX*5,printY,missionbuttonW,false,((self.cursorX == 5 and self.cursorY == 2) and "hover" or nil),"Missions")
    if self.screen == "Missions" then setColor(255,255,255,255) end
    printY = printY+padX
  else
    local _, wrappedtext = fonts.textFont:getWrap("You need more than " .. faction.enter_threshold .. " favor to do business with this faction.", windowWidth)
    love.graphics.printf("You need more than " .. faction.enter_threshold .. " favor to do business with this faction.",printX,printY,windowWidth,"center")
    printY=printY+(#wrappedtext)*fontSize-math.ceil(padding/2)
  end
  printY=printY+padding
  love.graphics.line(printX,printY,printX+windowWidth,printY)
  printY=printY+8
  
  
  --Draw the screens:
  if self.screen == "Info" then
    love.graphics.printf(faction.description,printX,printY,windowWidth,"center")
    local _, wrappedtext = fonts.textFont:getWrap(faction.description, windowWidth)
    printY=printY+(#wrappedtext+1)*fontSize
    if faction.friendly_factions then
      local friendlyText = "Liked Factions:\n"
      for i,fac in ipairs(faction.friendly_factions) do
        friendlyText = friendlyText .. (i > 1 and ", " or "") .. currWorld.factions[fac].name
      end
      love.graphics.printf(friendlyText,printX,printY,windowWidth,"center")
      local _, wrappedtext = fonts.textFont:getWrap(friendlyText, windowWidth)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.enemy_factions then
      local enemyText = "Hated Factions:\n"
      for i,fac in ipairs(faction.enemy_factions) do
        enemyText = enemyText .. (i > 1 and ", " or "") .. currWorld.factions[fac].name
      end
      love.graphics.printf(enemyText,printX,printY,windowWidth,"center")
      local _, wrappedtext = fonts.textFont:getWrap(enemyText, windowWidth)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.friendly_types then
      local friendlyText = "Liked creature types:\n"
      for i,typ in ipairs(faction.friendly_types) do
        friendlyText = friendlyText .. (i > 1 and ", " or "") .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ))
      end
      love.graphics.printf(friendlyText,printX,printY,windowWidth,"center")
      local _, wrappedtext = fonts.textFont:getWrap(friendlyText, windowWidth)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.enemy_types then
      local enemyText = "Hated creature types:\n"
      for i,typ in ipairs(faction.enemy_types) do
        enemyText = enemyText .. (i > 1 and ", " or "") .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ))
      end
      love.graphics.printf(enemyText,printX,printY,windowWidth,"center")
      local _, wrappedtext = fonts.textFont:getWrap(enemyText, windowWidth)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.kill_favor_factions or faction.kill_favor_types then
      love.graphics.printf("Kill Favor:",printX,printY,windowWidth,"center")
      printY=printY+fontSize
      if faction.kill_favor_factions then
        local killtext = ""
        for fac,favor in pairs(faction.kill_favor_factions) do
          killtext = killtext .. (favor > 0 and "+" or "") .. favor .. ": members of " .. currWorld.factions[fac].name .. "\n"
        end
        love.graphics.printf(killtext,printX,printY,windowWidth,"left")
        local _, wrappedtext = fonts.textFont:getWrap(killtext, windowWidth)
        printY=printY+(#wrappedtext)*fontSize
      end --end kill_favor faction if
      if faction.kill_favor_types then
        local killtext = ""
        for typ,favor in pairs(faction.kill_favor_types) do
          killtext = killtext .. (favor > 0 and "+" or "") .. favor .. ": creatures of type " .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ)) .. "\n"
        end
        love.graphics.printf(killtext,printX,printY,windowWidth,"left")
        local _, wrappedtext = fonts.textFont:getWrap(killtext, windowWidth)
        printY=printY+(#wrappedtext+1)*fontSize
      end --end kill_favor type if
    end --end if kill favor anyhwere
    
  elseif self.screen == "Items" then
    if not self.faction.noBuy then
      local padX = 8
      local buybuttonW = fonts.textFont:getWidth("Buying")+padding
      local sellbuttonW = fonts.textFont:getWidth("Selling")+padding
      local startX = windowX+math.floor(windowWidth/2)
      if self.subScreen == "Buy" then setColor(150,150,150,255) end
      self.buyButton = output:button(startX-math.floor(buybuttonW/2)-padX,printY,buybuttonW+padX,false,((self.cursorX == 1 and self.cursorY == 3) and "hover" or nil),"Buying")
      if self.subScreen == "Buy" then setColor(255,255,255,255) end
      if self.subScreen == "Sell" then setColor(150,150,150,255) end
      self.sellButton = output:button(startX+math.floor(buybuttonW/2)+padX,printY,sellbuttonW,false,((self.cursorX == 2 and self.cursorY == 3) and "hover" or nil),"Selling")
      if self.subScreen == "Sell" then setColor(255,255,255,255) end
      printY = printY+padding
      printY=printY+8
    end
    local mouseX,mouseY = love.mouse.getPosition()
    if self.subScreen == "Buy" then
      local buybuttonW = fonts.textFont:getWidth("Buy")+padding
      local nameX = windowX+padding
      local costX = 0
      local amountX = 0
      local buyButtonX = 0
      local yPad = 8
      local buyBoxX = windowX+windowWidth-padding*2-8
      local buyBoxW = fonts.textFont:getWidth("1000")+8
      local amtX = nameX+225
      local priceX = nameX+300
      local costlineW = fonts.textFont:getWidth("Favor Cost: 9999. Money Cost: $9999 (You have $9999)")
      love.graphics.print("Favor Cost: " .. self.totalCost.favor .. ". Money Cost: $" .. self.totalCost.money .. " (You have $" .. player.money .. ")",math.floor(midX-costlineW/2),printY+4)
      if self.totalCost.money > player.money or self.totalCost.favor > favor then
        setColor(100,100,100,255)
      end
      self.storeActionButton = output:button(math.ceil(midX+costlineW/2)+32,printY-2,buybuttonW,false,(self.cursorY == 4 and "hover" or nil),"Buy")
      if self.totalCost.money > player.money or self.totalCost.favor > favor then
        setColor(255,255,255,255)
      end
      printY = printY+32
      self.totalCost.money,self.totalCost.favor=0,0
      for id,info in ipairs(self.selling_list) do
        local selected = self.cursorY == id+4
        local buyTextY = printY+math.floor(padding/4)
        info.minX,info.minY = windowX+yPad,buyTextY-yPad
        info.maxX,info.maxY = info.minX+windowWidth+yPad,info.minY+fontSize+yPad*2
        local nameLen = fonts.textFont:getWidth(tostring(info.name))
        if selected then
          setColor(25,25,25,255)
          love.graphics.rectangle('fill',info.minX,info.minY,windowWidth+yPad,fontSize+yPad*2)
          setColor(255,255,255,255)
        end
        if selected and self.cursorX == 1 then
          setColor(100,100,100,255)
          love.graphics.rectangle('fill',nameX,buyTextY-yPad,nameLen,fontSize+yPad*2)
          setColor(255,255,255,255)
        end
        love.graphics.print(info.name,nameX,buyTextY)
        love.graphics.print("x " .. (info.amount == -1 and "∞" or info.amount),amtX,buyTextY)
        local priceText = ""
        if info.moneyCost then
          priceText = priceText .. "$" .. info.moneyCost .. (info.favorCost and ", ")
        end
        if info.favorCost then
          priceText = priceText .. info.favorCost .. " Favor"
        end
        love.graphics.print(priceText,priceX,buyTextY)
        --Minus button:
        if self.playerMember or not info.membersOnly then
          info.minusButton = output:tinybutton(buyBoxX-fontSize*3,printY,nil,((selected and self.cursorX == 2) and "hover" or nil),"-")
          --Handle the item amount box:
          info.numberEntry = {minX=buyBoxX,minY=buyTextY-2,maxX=buyBoxX+buyBoxW,maxY=buyTextY-2+fontSize+4}
          if self.cursorX == 3 and selected or (mouseX > info.numberEntry.minX and mouseX < info.numberEntry.maxX and mouseY > info.numberEntry.minY and mouseY < info.numberEntry.maxY) then
            setColor(50,50,50,255)
            love.graphics.rectangle('fill',info.numberEntry.minX,info.numberEntry.minY,buyBoxW,fontSize+4)
            setColor(255,255,255,255)
            if self.lineOn and selected and self.cursorX == 3 then
              local w = fonts.textFont:getWidth(tostring(info.buyAmt))
              local lineX = buyBoxX+math.ceil(buyBoxW/2+w/2)
              love.graphics.line(lineX,buyTextY,lineX,buyTextY+fontSize)
            end
          end
          love.graphics.rectangle('line',info.numberEntry.minX,info.numberEntry.minY,buyBoxW,fontSize+4)
          love.graphics.printf(info.buyAmt,buyBoxX,buyTextY,buyBoxW,"center")
          --Plus Button:
          info.plusButton = output:tinybutton(buyBoxX+buyBoxW+fontSize,printY,nil,((selected and self.cursorX == 4) and "hover" or nil),"+")
        else
          love.graphics.print("Members Only",buyBoxX-fontSize*3,buyTextY)
        end
        --Display description if necessary:
        if (selected and self.cursorX == 1) or (mouseX > nameX and mouseX < priceX and mouseY > info.minY and mouseY < info.maxY) then
          local text = info.item:get_name(true,1) .. "\n" .. info.item:get_description() .. "\n" .. info.item:get_info(true)
          self:description_box(text,nameX+yPad,buyTextY)
        end
        printY = printY+fontSize+16
        self.totalCost.money = self.totalCost.money + (info.buyAmt*(info.moneyCost or 0))
        self.totalCost.favor = self.totalCost.favor + (info.buyAmt*(info.favorCost or 0))
      end
    elseif self.subScreen == "Sell" then
      local sellbuttonW = fonts.textFont:getWidth("Sell")+padding
      local nameX = windowX+padding
      local costX = 0
      local amountX = 0
      local sellButtonX = 0
      local yPad = 8
      local sellBoxX = windowX+windowWidth-padding*2-8
      local sellBoxW = fonts.textFont:getWidth("1000")+8
      local amtX = nameX+225
      local priceX = nameX+300
      local costlineW = fonts.textFont:getWidth("Favor Gain: 9999. Money Gain: $9999")
      love.graphics.print("Favor Gain: " .. self.totalCost.favor .. ". Money Gain: $" .. self.totalCost.money,math.floor(midX-costlineW/2),printY+4)
      self.storeActionButton = output:button(math.ceil(midX+costlineW/2)+32,printY-2,sellbuttonW,false,(self.cursorY == 4 and "hover" or nil),"Sell")
      printY = printY+32
      self.totalCost.money,self.totalCost.favor=0,0
      for id,info in ipairs(self.buying_list) do
        local selected = self.cursorY == id+4
        local sellTextY = printY+math.floor(padding/4)
        info.minX,info.minY = windowX+yPad,sellTextY-yPad
        info.maxX,info.maxY = info.minX+windowWidth+yPad,info.minY+fontSize+yPad*2
        local nameLen = fonts.textFont:getWidth(tostring(info.name))
        if selected then
          setColor(25,25,25,255)
          love.graphics.rectangle('fill',info.minX,info.minY,windowWidth+yPad,fontSize+yPad*2)
          setColor(255,255,255,255)
        end
        if selected and self.cursorX == 1 then
          setColor(100,100,100,255)
          love.graphics.rectangle('fill',nameX,sellTextY-yPad,nameLen,fontSize+yPad*2)
          setColor(255,255,255,255)
        end
        love.graphics.print(info.name,nameX,sellTextY)
        love.graphics.print("x " .. (info.amount == -1 and "∞" or info.amount),amtX,sellTextY)
        local priceText = ""
        if info.moneyCost then
          priceText = priceText .. "$" .. info.moneyCost .. (info.favorCost and ", ")
        end
        if info.favorCost then
          priceText = priceText .. info.favorCost .. " Favor"
        end
        love.graphics.print(priceText,priceX,sellTextY)
        --Minus button:
        info.minusButton = output:tinybutton(sellBoxX-fontSize*3,printY,nil,((selected and self.cursorX == 2) and "hover" or nil),"-")
        --Handle the item amount box:
        info.numberEntry = {minX=sellBoxX,minY=sellTextY-2,maxX=sellBoxX+sellBoxW,maxY=sellTextY-2+fontSize+4}
        if self.cursorX == 3 and selected or (mouseX > info.numberEntry.minX and mouseX < info.numberEntry.maxX and mouseY > info.numberEntry.minY and mouseY < info.numberEntry.maxY) then
          setColor(50,50,50,255)
          love.graphics.rectangle('fill',info.numberEntry.minX,info.numberEntry.minY,sellBoxW,fontSize+4)
          setColor(255,255,255,255)
          if self.lineOn and selected and self.cursorX == 3 then
            local w = fonts.textFont:getWidth(tostring(info.buyAmt))
            local lineX = sellBoxX+math.ceil(sellBoxW/2+w/2)
            love.graphics.line(lineX,sellTextY,lineX,sellTextY+fontSize)
          end
        end
        love.graphics.rectangle('line',info.numberEntry.minX,info.numberEntry.minY,sellBoxW,fontSize+4)
        love.graphics.printf(info.buyAmt,sellBoxX,sellTextY,sellBoxW,"center")
        --Plus Button:
        info.plusButton = output:tinybutton(sellBoxX+sellBoxW+fontSize,printY,nil,((selected and self.cursorX == 4) and "hover" or nil),"+")
        --Display description if necessary:
        if (selected and self.cursorX == 1) or (mouseX > nameX and mouseX < priceX and mouseY > info.minY and mouseY < info.maxY) then
          local text = info.item:get_name(true,1) .. "\n" .. info.item:get_description() .. "\n" .. info.item:get_info(true)
          self:description_box(text,nameX+yPad,sellTextY)
        end
        printY = printY+fontSize+16
        self.totalCost.money = self.totalCost.money + (info.buyAmt*(info.moneyCost or 0))
        self.totalCost.favor = self.totalCost.favor + (info.buyAmt*(info.favorCost or 0))
      end
    end --end buy/sell split
  elseif self.screen == "Spells" then
    self.spellButtons = {}
    local spellCount = 0
    for i,spellDef in ipairs(faction.teaches_spells or {}) do
      if not player:has_spell(spellDef.spell) then
        spellCount = spellCount + 1
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
          printY=printY+fontSize
        elseif spellDef.favorCost and favor < spellDef.favorCost then
          love.graphics.printf("You don't have enough favor to learn this ability.",windowX,printY,windowWidth,"center")
          printY=printY+fontSize
        elseif spellDef.moneyCost and player.money < spellDef.moneyCost then
          love.graphics.printf("You don't have enough money to learn this ability.",windowX,printY,windowWidth,"center")
          printY=printY+fontSize
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
    if spellCount == 0 then
      love.graphics.printf("There are currently no spells available to learn.",windowX,printY,windowWidth,"center")
    end
  elseif self.screen == "Services" then
    self.serviceButtons = {}
    local serviceCount = 0
    local services = faction.offers_services or {}
    for i,servID in ipairs(services) do
      serviceCount = serviceCount+1
      local service = possibleServices[servID]
      local costText = service:get_cost(player)
      local serviceText = service.name .. (costText and " (Cost: " .. costText .. ")" or "") .. "\n" .. service.description
      local __, wrappedtext = fonts.textFont:getWrap(serviceText, windowWidth)
      love.graphics.printf(serviceText,windowX,printY,windowWidth,"center")
      printY=printY+(#wrappedtext)*fontSize
      local canDo,canDoText = (not service.requires or service:requires(player))
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
    if serviceCount == 0 then
      love.graphics.printf("There are currently no services available.",windowX,printY,windowWidth,"center")
    end
  elseif self.screen == "Missions" then
    self.missionButtons = {}
    local missions = (faction.offers_missions or {})
    local missionCount = 0
    for i, missionID in ipairs(missions) do
      if not currGame.missionStatus[missionID] and not currGame.finishedMissions[missionID] then
        missionCount = missionCount+1
        local mission = possibleMissions[missionID]
        local missionText = mission.name .. "\n" .. mission.description
        local __, wrappedtext = fonts.textFont:getWrap(missionText, windowWidth)
        love.graphics.printf(missionText,windowX,printY,windowWidth,"center")
        printY=printY+(#wrappedtext)*fontSize
        local canDo,canDoText = (not mission.requires or mission:requires(player))
        if canDo == false then
          canDoText = "You're not eligible for this mission" .. (canDoText and ": " .. canDoText or ".")
          local __, wrappedtext = fonts.textFont:getWrap(canDoText, windowWidth)
          love.graphics.printf(canDoText,windowX,printY,windowWidth,"center")
          printY=printY+(#wrappedtext)*fontSize
          self.missionButtons[#self.missionButtons+1] = false
        else
          local serviceW = fonts.textFont:getWidth("Accept")+padding
          self.missionButtons[#self.missionButtons+1] = output:button(math.floor(midX-serviceW/2),printY,serviceW,false,(self.cursorY == 2+i and "hover" or nil),"Accept")
          printY=printY+32
        end
      end
    end
    if missionCount == 0 then
      love.graphics.printf("There are currently no missions available.",windowX,printY,windowWidth,"center")
    end
  end

  self.closebutton = output:closebutton(windowX+24,24,nil,true)
  love.graphics.pop()
end

function factionscreen:keypressed(key)
  if key == "escape" then
    self:switchBack()
  elseif (key == "return" or key == "kpenter") then
    if self.cursorY == 1 then --join button
      if self.faction:can_join(player) then
        self.faction:join(player)
        --TODO: Make this work
      end
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
      elseif self.screen == "Missions" then
        if self.cursorY > 2 and self.missionButtons[self.cursorY-2] then
          local missionID = self.faction.offers_missions[self.cursorY-2]
          local useText = start_mission(missionID)
          if type(useText) == "string" then self.outText = useText end
        end
      elseif self.screen == "Spells" then
        if self.cursorY > 2 and self.spellButtons[self.cursorY-2] then
          local spellID = self.spellButtons[self.cursorY-2].spellID
          local spell = possibleSpells[spellID]
          if self.faction:teach_spell(spellID,player) ~= false then
            self.outText = "You learn " .. spell.name .. "."
          end
        end
      elseif self.screen == "Items" then
        if self.cursorY == 3 and not self.noBuy then --buttons
          if self.cursorX == 1 then
            self.subScreen = "Buy"
            self.cursorY = 4
          else
            self.subScreen = "Sell"
            self.cursorY = 4
          end
        elseif self.cursorY == 4 then
          if self.subScreen == "Buy" then
            self:player_buys()
          else
            self:player_sells()
          end
        else --Buy buttons
          local id = self.cursorY-4
          local list = (self.subScreen == "Buy" and self.selling_list or self.buying_list)
          if self.cursorX == 1 then --item name
            self.cursorX = 2
          elseif self.cursorX == 2 and self.cursorY > 4 then --minus button
            list[id].buyAmt = math.max(list[id].buyAmt-1,0)
          elseif self.cursorX == 3 then --number entry
            self.cursorX = 5
          elseif self.cursorX == 4 then --plus button
            list[id].buyAmt = (list[id].amount ~= -1 and math.min(list[id].buyAmt+1,list[id].amount) or list[id].buyAmt+1)
          end
        end
      end --end which screen if
    end --end cursorY tests within return
  elseif key == "left" then
    self.cursorX = self.cursorX - 1
    if self.cursorY == 2 and self.cursorX < 1 then self.cursorX = 5 end --looping if on the nav buttons
    if self.cursorY < 2 then self.cursorY = 2 self.cursorX = 5 end --if above the nav buttons, move to them
    if self.screen == "Items" then
      if self.cursorY == 3 and not self.noBuy then --looping if on the nav buttons
        self.cursorX = 1
      else
        self.cursorX = math.max(1,self.cursorX)
      end
    end
  elseif key == "right" then
    self.cursorX = self.cursorX + 1
    if self.cursorY == 2 and self.cursorX > 5 then self.cursorX = 1 end --looping if on the nav buttons
    if self.cursorY < 2 then self.cursorY = 2 self.cursorX = 1 end --if above the nav buttons, move to them
    if self.screen == "Items" then
      if self.cursorY == 3 and not self.noBuy then
        self.cursorX = 2
      elseif self.cursorY > 4 then
        self.cursorX = math.min(self.cursorX,4)
      end
    end
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
    elseif self.screen == "Items" then
      if self.cursorY > 1 then
        self.cursorY = self.cursorY - 1
        self.cursorX = 1
      end
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
    elseif self.screen == "Missions" then
      for i=self.cursorY-1,#self.missionButtons,1 do
        if self.missionButtons[i] ~= false then
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
    elseif self.screen == "Items" then
      local max = (self.subScreen == "Buy" and #self.selling_list+4 or #self.buying_list+4)
      if self.cursorY < max then
        self.cursorY = self.cursorY + 1
        self.cursorX = 1
      end
    end --end cursorY check
  elseif self.screen == "Items" and tonumber(key) and self.cursorX == 3 then
    local id = self.cursorY-4
    local list = (self.subScreen == "Buy" and self.selling_list or self.buying_list)
    if string.len(tostring(list[id].buyAmt or "")) < 3 then
      if list[id].buyAmt == 0 then
        list[id].buyAmt = tonumber(key)
      else
        local newAmt = (list[id].buyAmt or "").. key
        list[id].buyAmt = tonumber(newAmt)
      end
    end
  elseif self.screen == "Items" and key == "backspace" and self.cursorX == 3 then
    local id = self.cursorY-4
    local list = (self.subScreen == "Buy" and self.selling_list or self.buying_list)
    local amt = tostring(list[id].buyAmt)
    local newAmt = tonumber(string.sub(amt,1,#amt-1))
    list[id].buyAmt = (newAmt or 0)
  end --end key if
end

function factionscreen:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y=x/uiScale,y/uiScale
  if (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    self:switchBack()
  end
  --Item screen:
  if self.screen == "Items" then
    if self.buyButton and x > self.buyButton.minX and x < self.buyButton.maxX and y > self.buyButton.minY and y < self.buyButton.maxY then
      self.subScreen = "Buy"
      self.cursorY = 4
    elseif self.sellButton and x > self.sellButton.minX and x < self.sellButton.maxX and y > self.sellButton.minY and y < self.sellButton.maxY then
      self.subScreen = "Sell"
      self.cursorY = 4
    elseif x > self.storeActionButton.minX and x < self.storeActionButton.maxX and y > self.storeActionButton.minY and y < self.storeActionButton.maxY then
      if self.subScreen == "Buy" then
        return self:player_buys()
      else
        return self:player_sells()
      end
    end
    local list = (self.subScreen == "Buy" and self.selling_list or self.buying_list)
    --Item List Buttons:
    for id,listItem in ipairs(list) do
      if listItem.minX and x > listItem.minX and x < listItem.maxX and y > listItem.minY and y < listItem.maxY then
        local minus,plus,action,numberEntry = listItem.minusButton,listItem.plusButton,listItem.actionButton,listItem.numberEntry
        if x > minus.minX and x < minus.maxX and y > minus.minY and y < minus.maxY then
          listItem.buyAmt = math.max(listItem.buyAmt-1,0)
        elseif x > plus.minX and x < plus.maxX and y > plus.minY and y < plus.maxY then
          listItem.buyAmt = (listItem.amount ~= -1 and math.min(listItem.buyAmt+1,listItem.amount) or listItem.buyAmt+1)
        elseif x > numberEntry.minX and x < numberEntry.maxX and y > numberEntry.minY and y < numberEntry.maxY then
          self.cursorX = 3
          self.cursorY = id+2
        end
        break --no reason to continue looking at other list items if we've already seen one
      end --end x/y check
    end --end list for
  end --end if item screen
  
  --Navbuttons:
  if self.infoButton and x > self.infoButton.minX and x < self.infoButton.maxX and y > self.infoButton.minY and y < self.infoButton.maxY then
    self.screen = "Info"
  elseif self.shopButton and x > self.shopButton.minX and x < self.shopButton.maxX and y > self.shopButton.minY and y < self.shopButton.maxY then
    self.screen = "Items"
  elseif self.spellsButton and x > self.spellsButton.minX and x < self.spellsButton.maxX and y > self.spellsButton.minY and y < self.spellsButton.maxY then
    self.screen = "Spells"
  elseif self.serviceButton and x > self.serviceButton.minX and x < self.serviceButton.maxX and y > self.serviceButton.minY and y < self.serviceButton.maxY then
    self.screen = "Services"
  elseif self.missionButton and x > self.missionButton.minX and x < self.missionButton.maxX and y > self.missionButton.minY and y < self.missionButton.maxY then
    self.screen = "Missions"
  end
end --end mousepressed

function factionscreen:description_box(text,x,y)
  local width, tlines = fonts.textFont:getWrap(text,300)
  local height = #tlines*(prefs['fontSize']+2)+5
  x,y = round(x),round(y)
  if (y+20+height < love.graphics.getHeight()) then
    setColor(255,255,255,185)
    love.graphics.rectangle("line",x+22,y+20,302,height)
    setColor(0,0,0,185)
    love.graphics.rectangle("fill",x+23,y+21,301,height-1)
    setColor(255,255,255,255)
    love.graphics.printf(ucfirst(text),x+24,y+22,300)
  else
    setColor(255,255,255,185)
    love.graphics.rectangle("line",x+22,y+20-height,302,height)
    setColor(0,0,0,185)
    love.graphics.rectangle("fill",x+23,y+21-height,301,height-1)
    setColor(255,255,255,255)
    love.graphics.printf(ucfirst(text),x+24,y+22-height,300)
  end
end

function factionscreen:player_buys()
  if self.totalCost.money <= player.money and self.totalCost.favor <= (player.favor[self.faction.id] or 0) then
    for id,info in ipairs(self.selling_list) do
      if info.buyAmt > 0 then
        self.faction:creature_buys_item(info.item,info.moneyCost,info.favorCost,info.buyAmt,player)
        info.buyAmt = 0
      end
    end
    self:refresh_store_lists()
  end
end

function factionscreen:player_sells()
  for id,info in ipairs(self.buying_list) do
    if info.buyAmt > 0 then
      self.faction:creature_sells_item(info.item,info.moneyCost,info.favorCost,info.buyAmt,player)
      info.buyAmt = 0
    end
    self:refresh_store_lists()
  end
end

function factionscreen:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
  if self.screen == "Items" then
    self.lineCountdown = self.lineCountdown-dt
    if self.lineCountdown <= 0 then
      self.lineCountdown = .5
      self.lineOn = not self.lineOn
    end
    local list = (self.subScreen == "Buy" and self.selling_list or self.buying_list)
    for id,v in ipairs(list) do
      if v.buyAmt > v.amount and (self.cursorX ~= 3 or self.cursorY ~= id+4) and v.amount ~= -1 then
        v.buyAmt = v.amount
      end
    end
    if self.cursorY == 3 and self.noBuy then
      self.cursorY = 4
    end
  end
end

function factionscreen:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end