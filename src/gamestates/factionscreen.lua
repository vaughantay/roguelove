factionscreen = {}

function factionscreen:enter(previous,whichFac,stash,infoOnly)
  if previous ~= examine_item then
    self.yModPerc = 100
    self.blackScreenAlpha=0
    tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
    output:sound('stoneslideshort',2)
    self.cursorY = 1
    self.cursorX = 1
    self.scrollY = 0
    self.scrollMax = 0
    self.infoOnly = infoOnly
    self.faction = currWorld.factions[whichFac]
    self.playerMember = player:is_faction_member(whichFac)
    self.screen="Info"
    self.subScreen=(self.faction.noSell and "Sell" or "Buy")
    self.outText = nil
    self.totalCost = {favor=0,money=0,reputation=0}
    self.costMod = self.faction:get_cost_modifier(player)
    self:refresh_store_lists()
    self.lineCountdown = .5
    self.navButtons = {}
    self.faction.contacted = true
    self.stash = stash
    self.previous = previous
    self.buyButton = nil
    self.sellButton = nil
    self.serviceButton = nil
    self.spellsButton = nil
    self.missionButton = nil
    self.favor_bar_value=0
  end
end

function factionscreen:refresh_store_lists()
  self.buying_list = {}
  self.selling_list = {}

  for _,ilist in pairs(self.faction:get_inventory()) do
    local item = ilist.item
    self.selling_list[#self.selling_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),moneyCost=(ilist.moneyCost and ilist.moneyCost+round(ilist.moneyCost*(self.costMod/100)) or nil),favorCost=ilist.favorCost,reputationCost=ilist.reputationCost,members_only=ilist.members_only,amount=item.amount,buyAmt=0,item=item,reputation_requirement=ilist.reputation_requirement}
  end
  if self.faction.buys_favor_for_money and (player.favor[self.faction.id] or 0) > 0 then
    self.buying_list[#self.buying_list+1] = {name="Favor",description="Exchange Favor owed from the " .. self.faction.name .. " for money.",amount=(player.favor[self.faction.id] or 0),moneyCost=self.faction.buys_favor_for_money,buyAmt=0,sellFavor=true}
  end
  for _,ilist in pairs(self.faction:get_buy_list()) do
    local item = ilist.item
    self.buying_list[#self.buying_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),moneyCost=(ilist.moneyCost and ilist.moneyCost-round(ilist.moneyCost*(self.costMod/100)) or nil),favorCost=ilist.favorCost,reputationCost=ilist.reputationCost,amount=item.amount,buyAmt=0,item=item}
  end
  if self.stash then
    for _,ilist in pairs(self.faction:get_buy_list(self.stash)) do
      local item = ilist.item
      self.buying_list[#self.buying_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),moneyCost=(ilist.moneyCost and ilist.moneyCost-round(ilist.moneyCost*(self.costMod/100)) or nil),favorCost=ilist.favorCost,reputationCost=ilist.reputationCost,amount=item.amount,buyAmt=0,item=item,stash=self.stash}
    end
  end
end

function factionscreen:draw()
  local factionID = self.faction.id
  local faction = self.faction
  game:draw()
  love.graphics.setFont(fonts.textFont)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local tileSize = output:get_tile_size()
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle('fill',0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = fonts.textFont:getHeight()
  local windowWidth = math.floor((width*.75)/uiScale)
  local midX = math.floor(width/2/uiScale)
  local windowX = math.floor(midX-windowWidth/2)
  output:draw_window(windowX,1,windowX+windowWidth,math.floor(height/uiScale-padding))
  local printX = windowX+fontSize
  --Basic header display:
  love.graphics.printf(faction.name,printX,padding,windowWidth,"center")
  local printY = padding+fontSize*2
  
  
  --Relationship text:
  local relationship = nil
  if self.playerMember then
    relationship = "Member"
  elseif faction:is_enemy(player) then
    relationship = "Enemy"
  elseif faction:is_friend(player) then
    relationship = "Friend"
  else
    relationship = "Neutral"
  end
  
  --Reputation Info:
  local reputation = (player.reputation[factionID] or 0)
  local favor = (player.favor[factionID] or 0)
  love.graphics.printf("Your Reputation: " .. reputation .. " (" .. relationship .. ")",printX,printY,windowWidth,"center")
  printY = printY+fontSize
  --[[love.graphics.printf(relationship,printX,printY,windowWidth,"center")
  local _, wrappedtext = fonts.textFont:getWrap(relationship, windowWidth)
  printY=printY+(#wrappedtext)*fontSize--]]
  love.graphics.printf("Your Favor: " .. favor,printX,printY,windowWidth,"center")
  printY = printY+fontSize
  if faction.reputation_per_favor_spent then
    local favor_spent = faction.favor_spent or 0
    local favor_required = faction.reputation_per_favor_spent-favor_spent
    local money_required
    if not faction.no_buy_money or not faction.no_sell_money then
      money_required = favor_required*(faction.money_per_favor or 1)
    end
    if faction.no_buy_favor or faction.no_sell_favor then
      favor_required = nil
    end
    local repText = "Earn or spend " .. (favor_required and favor_required .. " favor" or "") .. (money_required and (favor_required and " or " or "") .. get_money_name(money_required) or "") .. " here to gain +1 Reputation."
    love.graphics.printf(repText,printX,printY,windowWidth,"center")
    local _,rlines = fonts.textFont:getWrap(repText, windowWidth)
    printY = printY+fontSize*#rlines
    output:draw_tiny_bar(self.favor_bar_value,faction.reputation_per_favor_spent,midX-100,printY,200,round(tileSize/2),{r=255,g=255,b=255,a=255})
    printY = printY+tileSize
  end
  
  if not self.playerMember and not faction.never_join then
    --Join text:
    local joinText = nil
    local canJoin,reason = faction:can_join(player)
    if canJoin then
      joinText = "You are eligible to join this faction."
    else
      joinText = "You're not eligible to join this faction" .. (reason and " for the following reasons: " or ".")
    end
    love.graphics.printf(joinText,printX,printY,windowWidth,"center")
    local _, wrappedtext = fonts.textFont:getWrap(joinText, windowWidth)
    printY=printY+(#wrappedtext)*fontSize
    if canJoin then
      local joinButtonW = fonts.buttonFont:getWidth("Join")+padding
      local buttonX=math.floor(midX-joinButtonW/2)
      self.joinButton = output:button(buttonX,printY,joinButtonW+joinButtonW,false,(self.cursorY == 1 and "hover" or nil),"Join")
    else
      if self.cursorY == 1 then
        self.cursorY = 2
      end
    end
    if reason then
      printY = printY+fontSize
      local _, wrappedtext = fonts.textFont:getWrap(reason, windowWidth)
      love.graphics.printf(reason,printX,printY,windowWidth,"center")
      printY=printY+(#wrappedtext)*fontSize
    end
    printY=printY+fontSize
  elseif self.cursorY == 1 then --if a member, automatically jump down to the navigation row
    self.cursorY = 2
  end
  
  if self.outText then
    printY=printY+fontSize
    local _, wrappedtext = fonts.textFont:getWrap(self.outText, windowWidth)
    love.graphics.printf(self.outText,printX,printY,windowWidth,"center")
    printY=printY+#wrappedtext*fontSize
  end
  
  if not self.infoOnly then
    if not faction.enter_threshold or ((player.reputation[factionID] or 0) >= faction.enter_threshold) then
      printY=printY+fontSize
      local padX = 8
      local infobuttonW = fonts.buttonFont:getWidth("Information")+padding
      local shopbuttonW = fonts.buttonFont:getWidth("Items")+padding
      local spellbuttonW = fonts.buttonFont:getWidth("Skills/Abilities")+padding
      local servicebuttonW = fonts.buttonFont:getWidth("Services")+padding
      local missionbuttonW = fonts.buttonFont:getWidth("Missions")+padding
      local recruitbuttonW = fonts.buttonFont:getWidth("Recruit")+padding
      local biggestButton = math.max(infobuttonW,shopbuttonW,servicebuttonW,spellbuttonW,missionbuttonW,recruitbuttonW)
      infobuttonW,shopbuttonW,servicebuttonW,spellbuttonW,missionbuttonW,recruitbuttonW = biggestButton,biggestButton,biggestButton,biggestButton,biggestButton,biggestButton
      local totalWidth = windowWidth
      local startX = windowX+math.floor(windowWidth/2-padding-2.5*biggestButton)+padding
      local totalButtons = 1
      self.navButtons = {}
      if not self.faction.noBuy or not self.faction.noSell then
        totalButtons = totalButtons+1
      end
      if self.faction.offers_services and count(self.faction.offers_services) > 0 then
        totalButtons = totalButtons+1
      end
      if count(self.faction:get_teachable_spells(player)) > 0 or count(self.faction:get_teachable_skills(player)) > 0 then
        totalButtons = totalButtons+1
      end
      if count(self.faction:get_available_missions(player)) > 0 then
        totalButtons = totalButtons+1
      end
      if count(self.faction:get_recruitable_creatures(player)) > 0 then
        totalButtons = totalButtons+1
      end
      local buttonX = windowX+math.floor(windowWidth/2-padding-(totalButtons/2)*biggestButton)+padding
      if self.screen == "Info" then setColor(150,150,150,255) end
      self.infoButton = output:button(buttonX,printY,infobuttonW,false,((self.cursorX == #self.navButtons+1 and self.cursorY == 2) and "hover" or nil),"Information",true)
      self.navButtons[#self.navButtons+1] = self.infoButton
      self.infoButton.cursorX = #self.navButtons
      buttonX = buttonX + infobuttonW+padX
      if self.screen == "Info" then setColor(255,255,255,255) end
      if not self.faction.noBuy or not self.faction.noSell then
        if self.screen == "Items" then setColor(150,150,150,255) end
        self.shopButton = output:button(buttonX,printY,shopbuttonW,false,((self.cursorX == #self.navButtons+1 and self.cursorY == 2) and "hover" or nil),"Items",true)
        self.navButtons[#self.navButtons+1] = self.shopButton
        self.shopButton.cursorX = #self.navButtons
        buttonX = buttonX + shopbuttonW+padX
        if self.screen == "Items" then setColor(255,255,255,255) end
      end
      if count(self.faction:get_teachable_spells(player)) > 0 or count(self.faction:get_teachable_skills(player)) > 0 then
        if self.screen == "Spells" then setColor(150,150,150,255) end
        self.spellsButton = output:button(buttonX,printY,spellbuttonW,false,((self.cursorX == #self.navButtons+1 and self.cursorY == 2) and "hover" or nil),"Skills/Abilities",true)
        self.navButtons[#self.navButtons+1] = self.spellsButton
        self.spellsButton.cursorX = #self.navButtons
        buttonX=buttonX+spellbuttonW+padX
        if self.screen == "Spells" then setColor(255,255,255,255) end
      end
      if count(self.faction:get_available_services(player)) > 0 then
        if self.screen == "Services" then setColor(150,150,150,255) end
        self.serviceButton = output:button(buttonX,printY,servicebuttonW,false,((self.cursorX == #self.navButtons+1 and self.cursorY == 2) and "hover" or nil),"Services",true)
        self.navButtons[#self.navButtons+1] = self.serviceButton
        self.serviceButton.cursorX = #self.navButtons
        buttonX=buttonX+servicebuttonW+padX
        if self.screen == "Services" then setColor(255,255,255,255) end
      end
      if count(self.faction:get_available_missions(player)) > 0 then
        if self.screen == "Missions" then setColor(150,150,150,255) end
        self.missionButton = output:button(buttonX,printY,missionbuttonW,false,((self.cursorX == #self.navButtons+1 and self.cursorY == 2) and "hover" or nil),"Missions",true)
        self.navButtons[#self.navButtons+1] = self.missionButton
        self.missionButton.cursorX = #self.navButtons
        buttonX=buttonX+missionbuttonW+padX
        if self.screen == "Missions" then setColor(255,255,255,255) end
      end
      if count(self.faction:get_recruitable_creatures(player)) > 0 then
        if self.screen == "Recruit" then setColor(150,150,150,255) end
        self.recruitButton = output:button(buttonX,printY,recruitbuttonW,false,((self.cursorX == #self.navButtons+1 and self.cursorY == 2) and "hover" or nil),"Recruit",true)
        self.navButtons[#self.navButtons+1] = self.recruitButton
        self.recruitButton.cursorX = #self.navButtons
        buttonX=buttonX+recruitbuttonW+padX
        if self.screen == "Recruit" then setColor(255,255,255,255) end
      end
      printY = printY+padX
    else
      local _, wrappedtext = fonts.textFont:getWrap("You need a reputation higher than " .. faction.enter_threshold .. " to do business with this faction.", windowWidth)
      love.graphics.printf("You need reputation higher than " .. faction.enter_threshold .. " to do business with this faction.",printX,printY,windowWidth,"center")
      printY=printY+(#wrappedtext)*fontSize-math.ceil(padding/2)
    end
  end
  printY=printY+padding
  love.graphics.line(printX,printY,printX+windowWidth-padding,printY)
  printY=printY+8
  
  --Draw the screens:
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY=mouseX/uiScale,mouseY/uiScale
  local listStartY = printY
  if self.screen == "Info" then
    local maxW = windowWidth
    if self.scrollMax and self.scrollMax > 0 then
      maxW = windowWidth-padding
    end
    --Drawing the text:
    love.graphics.push()
    --Create a "stencil" that stops 
    local function stencilFunc()
      love.graphics.rectangle("fill",windowX,listStartY,windowWidth+padding,height-listStartY)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.scrollY)
    love.graphics.printf(faction.description,printX,printY,maxW,"center")
    local _, wrappedtext = fonts.textFont:getWrap(faction.description, maxW)
    printY=printY+(#wrappedtext+1)*fontSize
    if faction.friendly_factions then
      local friendlyText = "Liked Factions:\n"
      for i,fac in ipairs(faction.friendly_factions) do
        friendlyText = friendlyText .. (i > 1 and ", " or "") .. currWorld.factions[fac].name
      end
      love.graphics.printf(friendlyText,printX,printY,maxW,"center")
      local _, wrappedtext = fonts.textFont:getWrap(friendlyText, maxW)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.enemy_factions then
      local enemyText = "Hated Factions:\n(You will lose Reputation with " .. self.faction.name .. " if you gain Reputation with these factions)\n"
      for i,fac in ipairs(faction.enemy_factions) do
        enemyText = enemyText .. (i > 1 and ", " or "") .. currWorld.factions[fac].name
      end
      love.graphics.printf(enemyText,printX,printY,maxW,"center")
      local _, wrappedtext = fonts.textFont:getWrap(enemyText, maxW)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    local considered_enemy
    for _,fac in pairs(currWorld.factions) do
      if fac.enemy_factions and fac.contacted and in_table(self.faction.id,fac.enemy_factions) then
        considered_enemy = (considered_enemy and considered_enemy .. ", " or "") .. fac.name
      end
    end
    if considered_enemy then
      considered_enemy = "Hated by Factions:\n(If you gain Reputation with " .. self.faction.name ..", you will lose Reputation with these factions)\n" .. considered_enemy
      love.graphics.printf(considered_enemy,printX,printY,maxW,"center")
      local _, wrappedtext = fonts.textFont:getWrap(considered_enemy, maxW)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.friendly_types then
      local friendlyText = "Liked creature types:\n"
      for i,typ in ipairs(faction.friendly_types) do
        friendlyText = friendlyText .. (i > 1 and ", " or "") .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ))
      end
      love.graphics.printf(friendlyText,printX,printY,maxW,"center")
      local _, wrappedtext = fonts.textFont:getWrap(friendlyText, maxW)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.enemy_types then
      local enemyText = "Hated creature types:\n"
      for i,typ in ipairs(faction.enemy_types) do
        enemyText = enemyText .. (i > 1 and ", " or "") .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ))
      end
      love.graphics.printf(enemyText,printX,printY,maxW,"center")
      local _, wrappedtext = fonts.textFont:getWrap(enemyText, maxW)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.kill_reputation_factions or faction.kill_reputation_types then
      local killtext = ""
      love.graphics.printf("Kill Reputation:",printX,printY,maxW,"center")
      printY=printY+fontSize
      if faction.kill_reputation_factions then
        for fac,reputation in pairs(faction.kill_reputation_factions) do
          killtext = killtext .. (reputation > 0 and "+" or "") .. reputation .. ": " .. currWorld.factions[fac].name .. "\n"
        end
      end --end kill_reputation faction if
      if faction.kill_reputation_types then
        for typ,reputation in pairs(faction.kill_reputation_types) do
          killtext = killtext .. (reputation > 0 and "+" or "") .. reputation .. ": " .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ)) .. "\n"
        end
      end --end kill_reputation type if
      love.graphics.printf(killtext,printX,printY,maxW,"center")
      local _, wrappedtext = fonts.textFont:getWrap(killtext, maxW)
      printY=printY+(#wrappedtext+1)*fontSize
    end --end if kill reputation anyhwere
    if faction.incident_reputation then
      local reptext = ""
      love.graphics.printf("Action Reputation:",printX,printY,maxW,"center")
      printY=printY+fontSize
      for incidentID,reputation in pairs(faction.incident_reputation) do
        local name = ucfirst(possibleIncidents and possibleIncidents[incidentID] and possibleIncidents[incidentID].name or string.gsub(incidentID,"_"," "))
        reptext = reptext .. (reputation > 0 and "+" or "") .. reputation .. ": " .. name .. "\n" 
      end
      love.graphics.printf(reptext,printX,printY,maxW,"center")
      local _, wrappedtext = fonts.textFont:getWrap(reptext, maxW)
      printY=printY+(#wrappedtext+1)*fontSize
    end
    if faction.kill_favor_factions or faction.kill_favor_types then
      local killtext = ""
      love.graphics.printf("Kill Favor:",printX,printY,maxW,"center")
      printY=printY+fontSize
      if faction.kill_favor_factions then
        for fac,favor in pairs(faction.kill_favor_factions) do
          killtext = killtext .. (favor > 0 and "+" or "") .. favor .. ": members of " .. currWorld.factions[fac].name .. "\n"
        end
      end --end kill_favor faction if
      if faction.kill_favor_types then
        for typ,favor in pairs(faction.kill_favor_types) do
          killtext = killtext .. (favor > 0 and "+" or "") .. favor .. ": creatures of type " .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ)) .. "\n"
        end
      end --end kill_favor type if
      love.graphics.printf(killtext,printX,printY,maxW,"center")
      local _, wrappedtext = fonts.textFont:getWrap(killtext, maxW)
      printY=printY+(#wrappedtext+1)*fontSize
    end --end if kill favor anyhwere
    local lastY = printY
    love.graphics.setStencilTest()
    love.graphics.pop()
    if lastY*uiScale > height-padding then
      self.scrollMax = math.ceil((lastY-(listStartY+(height/uiScale-listStartY))+padding))
      local scrollAmt = self.scrollY/self.scrollMax
      self.scrollPositions = output:scrollbar(windowX+windowWidth,listStartY,math.floor((height-padding)/uiScale),scrollAmt,true)
    else
      self.scrollMax = 0
    end
  elseif self.screen == "Items" then
    if not self.faction.noBuy and not self.faction.noSell then
      local padX = 8
      local buybuttonW = fonts.textFont:getWidth("Buy")+padding
      local sellbuttonW = fonts.textFont:getWidth("Sell")+padding
      local startX = windowX+math.floor(windowWidth/2)
      if self.subScreen == "Buy" then setColor(150,150,150,255) end
      self.buyButton = output:button(startX-math.floor(buybuttonW/2)-padX,printY,buybuttonW+padX,false,((self.cursorX == 1 and self.cursorY == 3) and "hover" or nil),"Buy",true)
      if self.subScreen == "Buy" then setColor(255,255,255,255) end
      if self.subScreen == "Sell" then setColor(150,150,150,255) end
      self.sellButton = output:button(startX+math.floor(buybuttonW/2)+padX,printY,sellbuttonW,false,((self.cursorX == 2 and self.cursorY == 3) and "hover" or nil),"Sell",true)
      if self.subScreen == "Sell" then setColor(255,255,255,255) end
      printY = printY+padding
      printY=printY+8
    end
    local mouseX,mouseY = love.mouse.getPosition()
    mouseX,mouseY = mouseX/uiScale,mouseY/uiScale
    if self.subScreen == "Buy" then
      local exambuttonW = fonts.buttonFont:getWidth("Examine")+padding
      local exambuttonX = windowX+padding
      local imageX = exambuttonX+exambuttonW+3
      local nameX = imageX+tileSize+4
      local buybuttonW = fonts.buttonFont:getWidth("Buy")+padding
      local yPad = 8
      local buyBoxW = fonts.textFont:getWidth("1000")+8
      local buyBoxX = windowX+windowWidth-buyBoxW-padding*(self.scrollMax == 0 and 1 or 2)
      local buyButtonX = round((buyBoxX+buyBoxW/2)-buybuttonW/2)
      local priceW = fonts.textFont:getWidth(self:get_cost_text(1000) .. ", 1000 Favor, 1000 Reputation")
      local priceX = buyBoxX-32-16-priceW-8
      local nameMaxLen = priceX-nameX
      local lastY = 0
      local descrItem = nil
      local moneyText = (self.totalCost.money ~= 0 and self:get_cost_text(self.totalCost.money) .. " (have " .. player.money .. ")")
      if moneyText and (self.totalCost.favor ~= 0 or self.totalCost.reputation ~= 0) then
        moneyText = moneyText .. ", "
      end
      local favorText = (self.totalCost.favor ~= 0 and self.totalCost.favor .. " Favor (have " .. favor .. ") ")
      if favorText and self.totalCost.reputation ~= 0 then
        favorText = favorText .. ", "
      end
      local repText = (self.totalCost.reputation ~= 0 and self.totalCost.reputation .. " Reputation")
      local costLine = "Cost: " .. (moneyText or "") .. (favorText or "")  .. (repText or "") .. (not moneyText and not favorText and not repText and "Nothing" or "")
      local costlineW = fonts.textFont:getWidth(costLine)
      love.graphics.print(costLine,buyButtonX-costlineW-8,printY+4)
      if self.totalCost.money > player.money or self.totalCost.favor > favor or self.totalCost.reputation > reputation then
        setColor(100,100,100,255)
      end
      self.storeActionButton = output:button(buyButtonX,printY-2,buybuttonW,false,(self.cursorY == 4 and "hover" or nil),"Buy",true)
      if self.totalCost.money > player.money or self.totalCost.favor > favor or self.totalCost.reputation > reputation then
        setColor(255,255,255,255)
      end
      printY = printY+round(fontSize*1.5)
      local listStartY = printY
      self.listStartY = listStartY
      self.totalCost.money,self.totalCost.favor,self.totalCost.reputation=0,0,0
      --Drawing the text:
      love.graphics.push()
      --Create a "stencil" that stops 
      local function stencilFunc()
        love.graphics.rectangle("fill",windowX,listStartY,windowWidth+padding,height-listStartY)
      end
      love.graphics.stencil(stencilFunc,"replace",1)
      love.graphics.setStencilTest("greater",0)
      love.graphics.translate(0,-self.scrollY)
      for id,info in ipairs(self.selling_list) do
        local selected = self.cursorY == id+4
        local buyTextY = printY+math.floor(padding/4)
        info.minX,info.minY = windowX+yPad,buyTextY-yPad
        local name = (info.amount == -1 and "∞" or info.amount) .. " x " .. info.name
        local nameLen,tlines = fonts.textFont:getWrap(info.name,nameMaxLen)
        info.maxX,info.maxY = info.minX+nameLen+yPad,info.minY+(#tlines*fontSize)+yPad*2
        if selected then
          setColor(50,50,50,255)
          love.graphics.rectangle('fill',info.minX,info.minY,windowWidth+yPad*2,(info.maxY-info.minY))
          setColor(255,255,255,255)
        elseif mouseX > windowX and mouseX < windowX+windowWidth and mouseY > info.minY-self.scrollY and mouseY < info.maxY-self.scrollY then
          setColor(33,33,33,255)
          love.graphics.rectangle('fill',info.minX,info.minY,windowWidth+yPad*2,(info.maxY-info.minY))
          setColor(255,255,255,255)
        end
        --Examine Button:
        local examineMouse = false
        if info.examineButton and mouseX > info.examineButton.minX and mouseX < info.examineButton.maxX and mouseY > info.examineButton.minY-self.scrollY and mouseY < info.examineButton.maxY-self.scrollY then
          examineMouse = true
        end
        info.examineButton = output:button(exambuttonX,printY+4,exambuttonW,false,((examineMouse or (selected and self.cursorX == 1)) and "hover" or false),"Examine",true)
        --Icon:
        output.display_entity(info.item,imageX,buyTextY-8,true,true)
        --Name:
        love.graphics.printf(name,nameX,buyTextY,nameMaxLen)
        --Price:
        local priceText = ""
        if info.moneyCost and info.moneyCost ~= 0 then
          priceText = priceText .. get_money_name(info.moneyCost) .. (((info.favorCost and info.favorCost ~= 0) or (info.reputationCost and info.reputationCost ~= 0)) and ", " or "")
        end
        if info.favorCost and info.favorCost ~= 0 then
          priceText = priceText .. info.favorCost .. " Favor" .. (info.reputationCost and info.reputationCost ~= 0 and ", " or "")
        end
        if info.reputationCost and info.reputationCost ~= 0 then
          priceText = priceText .. info.reputationCost .. " Reputation"
        end
        love.graphics.printf(priceText,priceX,buyTextY,priceW,"right")
        local plusMouse = false
        local minusMouse = false
        local amountMouse = false
        local memberReq = self.playerMember or not info.members_only
        local repReq = not info.reputation_requirement or reputation >= info.reputation_requirement
        if memberReq and repReq then
          --Minus button:
          if info.minusButton and mouseX > info.minusButton.minX and mouseX < info.minusButton.maxX and mouseY > info.minusButton.minY-self.scrollY and mouseY < info.minusButton.maxY-self.scrollY then
            minusMouse = true
          end
          info.minusButton = output:tinybutton(buyBoxX-48,printY+4,nil,(minusMouse or (selected and self.cursorX == 2) and "hover" or false),"-")
          --Handle the item amount box:
          info.numberEntry = {minX=buyBoxX,minY=buyTextY-2,maxX=buyBoxX+buyBoxW,maxY=buyTextY-2+fontSize+4}
          local amountMouse = (mouseX > info.numberEntry.minX and mouseX < info.numberEntry.maxX and mouseY > info.numberEntry.minY-self.scrollY and mouseY < info.numberEntry.maxY-self.scrollY)
          if self.cursorX == 3 and selected or amountMouse then
            setColor(75,75,75,255)
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
          if info.plusButton and mouseX > info.plusButton.minX and mouseX < info.plusButton.maxX and mouseY > info.plusButton.minY-self.scrollY and mouseY < info.plusButton.maxY-self.scrollY then
            plusMouse = true
          end
          info.plusButton = output:tinybutton(buyBoxX+buyBoxW+16,printY+4,nil,(plusMouse or (selected and self.cursorX == 4) and "hover" or false),"+")
        elseif not memberReq then
          local moMax = buyBoxW+16+48+32
          local _,tl2 = fonts.textFont:getWrap("Members Only",moMax)
          love.graphics.printf("Members Only",buyBoxX-48,buyTextY,moMax,"center")
          if #tl2 > #tlines then tlines = tl2 end
         elseif not repReq then
          local moMax = buyBoxW+16+48+32
          local _,tl2 = fonts.textFont:getWrap("Requires " .. info.reputation_requirement .. " Reputation",moMax)
          love.graphics.printf("Requires " .. info.reputation_requirement .. " Reputation",buyBoxX-48,buyTextY,moMax,"center")
          if #tl2 > #tlines then tlines = tl2 end
        end
        --Display description if necessary:
        if plusMouse or minusMouse or amountMouse or (mouseY > listStartY and mouseY < info.maxY and mouseX >= priceX and mouseX <= windowX+windowWidth) then
          descrItem = nil
        elseif (selected and self.cursorX == 1 and not descrItem) or (mouseX > exambuttonX and mouseX <= windowX+windowWidth and mouseY > info.minY-self.scrollY and mouseY < info.maxY-self.scrollY) then
          descrItem = info
        end
        printY = printY+(#tlines*fontSize)+16
        lastY = printY
        self.totalCost.money = self.totalCost.money + (info.buyAmt*(info.moneyCost or 0))
        self.totalCost.favor = self.totalCost.favor + (info.buyAmt*(info.favorCost or 0))
        self.totalCost.reputation = self.totalCost.reputation + (info.buyAmt*(info.reputationCost or 0))
      end
      love.graphics.setStencilTest()
      if descrItem and descrItem.maxY-self.scrollY > listStartY then
        local text = descrItem.item:get_name(true,1) .. "\n" .. descrItem.item:get_description()
        local descX = nameX
        output:description_box(text,descX,descrItem.maxY,nil,self.scrollY)
      end
      love.graphics.pop()
      --Scrollbars
      if lastY*uiScale > height-padding then
        self.scrollMax = math.ceil((lastY-(listStartY+(height/uiScale-listStartY))+padding))
        local scrollAmt = self.scrollY/self.scrollMax
        self.scrollPositions = output:scrollbar(windowX+windowWidth,listStartY,math.floor((height-padding)/uiScale),scrollAmt,true)
      else
        self.scrollMax = 0
      end
    elseif self.subScreen == "Sell" then
      local exambuttonW = fonts.buttonFont:getWidth("Examine")+padding
      local exambuttonX = windowX+padding
      local imageX = exambuttonX+exambuttonW+3
      local nameX = imageX+output:get_tile_size()+4
      local sellbuttonW = fonts.textFont:getWidth("Sell")+padding
      local yPad = 8
      local sellBoxW = fonts.textFont:getWidth("1000")+8
      local sellBoxX = windowX+windowWidth-sellBoxW-padding*(self.scrollMax == 0 and 1 or 2)
      local sellButtonX = round((sellBoxX+sellBoxW/2)-sellbuttonW/2)
      local priceW = fonts.textFont:getWidth(self:get_cost_text(1000) .. " (Highest Known), 1000 Favor, 1000 Reputation")
      local priceX = sellBoxX-32-16-priceW-8
      local nameMaxLen = priceX-nameX
      local lastY = 0
      local descrItem = nil
      local moneyText = (self.totalCost.money ~= 0 and self:get_cost_text(self.totalCost.money))
      if moneyText and (self.totalCost.favor ~= 0 or self.totalCost.reputation ~= 0) then
        moneyText = moneyText .. ", "
      end
      local favorText = (self.totalCost.favor ~= 0 and self.totalCost.favor .. " Favor")
      if favorText and self.totalCost.reputation ~= 0 then
        favorText = favorText .. ", "
      end
      local repText = (self.totalCost.reputation ~= 0 and self.totalCost.reputation .. " Reputation")
      local costLine = "You will receive: " .. (moneyText or "") .. (favorText or "")  .. (repText or "") .. (not moneyText and not favorText and not repText and "Nothing" or "")
      local costlineW = fonts.textFont:getWidth(costLine)
      love.graphics.print(costLine,sellButtonX-costlineW-8,printY+4)
      self.storeActionButton = output:button(sellButtonX,printY-2,sellbuttonW,false,(self.cursorY == 4 and "hover" or nil),"Sell",true)
      printY = printY+32
      local listStartY = printY
      self.listStartY = listStartY
      self.totalCost.money,self.totalCost.favor,self.totalCost.reputation=0,0,0
      --Drawing the text:
      love.graphics.push()
      --Create a "stencil" that stops 
      local function stencilFunc()
        love.graphics.rectangle("fill",windowX,listStartY,windowWidth+padding,height-listStartY)
      end
      love.graphics.stencil(stencilFunc,"replace",1)
      love.graphics.setStencilTest("greater",0)
      love.graphics.translate(0,-self.scrollY)
      for id,info in ipairs(self.buying_list) do
        local name = (info.amount == -1 and "∞" or info.amount) .. " x " .. info.name
        local selected = self.cursorY == id+4
        local sellTextY = printY+math.floor(padding/4)
        info.minX,info.minY = windowX+yPad,sellTextY-yPad
        local nameLen,tlines = fonts.textFont:getWrap(name,nameMaxLen)
        info.maxX,info.maxY = info.minX+nameLen+yPad,info.minY+(#tlines*fontSize)+yPad*2
        if selected then
          setColor(50,50,50,255)
          love.graphics.rectangle('fill',info.minX,info.minY,windowWidth+yPad,fontSize+yPad*2)
          setColor(255,255,255,255)
        end
        if selected then
          setColor(50,50,50,255)
          love.graphics.rectangle('fill',info.minX,info.minY,windowWidth+yPad*2,(info.maxY-info.minY))
          setColor(255,255,255,255)
        elseif mouseX > windowX and mouseX < windowX+windowWidth and mouseY > info.minY-self.scrollY and mouseY < info.maxY-self.scrollY then
          setColor(33,33,33,255)
          love.graphics.rectangle('fill',info.minX,info.minY,windowWidth+yPad*2,(info.maxY-info.minY))
          setColor(255,255,255,255)
        end
        --Examine Button:
        local examineMouse = false
        if info.examineButton and mouseX > info.examineButton.minX and mouseX < info.examineButton.maxX and mouseY > info.examineButton.minY-self.scrollY and mouseY < info.examineButton.maxY-self.scrollY then
          examineMouse = true
        end
        info.examineButton = output:button(exambuttonX,printY+4,exambuttonW,false,((examineMouse or (selected and self.cursorX == 1)) and "hover" or false),"Examine",true)
        --Icon:
        if info.item then
          output.display_entity(info.item,imageX,sellTextY-8,true,true)
        end
        --Name:
        love.graphics.printf(name .. (info.stash and " (From " .. info.stash.name .. ")" or "").. (info.item and info.item.equipped and " (Equipped)" or ""),nameX,sellTextY,nameMaxLen)
        --Cost:
        local priceText = ""
        if info.moneyCost and info.moneyCost ~= 0 then
          priceText = priceText .. self:get_cost_text(info.moneyCost) .. (info.item and info.moneyCost >= info.item:get_highest_sell_cost() and " (Highest known)" or "") .. (((info.favorCost and info.favorCost ~= 0) or (info.reputationCost and info.reputationCost ~= 0)) and ", " or "")
        end
        if info.favorCost and info.favorCost ~= 0  then
          priceText = priceText .. info.favorCost .. " Favor" .. ((info.reputationCost and info.reputationCost ~= 0) and ", " or "")
        end
        if info.reputationCost and info.reputationCost ~= 0  then
          priceText = priceText .. info.reputationCost .. " Reputation"
        end
        love.graphics.printf(priceText,priceX,sellTextY,priceW,"right")
        --Minus button:
        local minusMouse = false
        if info.minusButton and mouseX > info.minusButton.minX and mouseX < info.minusButton.maxX and mouseY > info.minusButton.minY-self.scrollY and mouseY < info.minusButton.maxY-self.scrollY then
            minusMouse = true
          end
        info.minusButton = output:tinybutton(sellBoxX-48,printY+4,nil,(minusMouse or (selected and self.cursorX == 2) and "hover" or false),"-")
        --Handle the item amount box:
        info.numberEntry = {minX=sellBoxX,minY=sellTextY-2,maxX=sellBoxX+sellBoxW,maxY=sellTextY-2+fontSize+4}
        local amountMouse = (mouseX > info.numberEntry.minX and mouseX < info.numberEntry.maxX and mouseY > info.numberEntry.minY-self.scrollY and mouseY < info.numberEntry.maxY-self.scrollY)
        if self.cursorX == 3 and selected or amountMouse then
          setColor(75,75,75,255)
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
        local plusMouse = false
        if info.plusButton and mouseX > info.plusButton.minX and mouseX < info.plusButton.maxX and mouseY > info.plusButton.minY-self.scrollY and mouseY < info.plusButton.maxY-self.scrollY then
          plusMouse = true
        end
        info.plusButton = output:tinybutton(sellBoxX+sellBoxW+16,printY+4,nil,(plusMouse or (selected and self.cursorX == 4) and "hover" or false),"+")
        --Display description if necessary:
        if plusMouse or minusMouse or amountMouse or (mouseY > listStartY and mouseY < info.maxY and mouseX >= priceX and mouseX <= windowX+windowWidth) then
        descrItem = nil
      elseif (selected and self.cursorX == 1 and not descrItem) or (mouseX > exambuttonX and mouseX <= windowX+windowWidth and mouseY > info.minY-self.scrollY and mouseY < info.maxY-self.scrollY) then
        descrItem = info
      end
        printY = printY+(#tlines*fontSize)+16
        lastY = printY
        self.totalCost.money = self.totalCost.money + (info.buyAmt*(info.moneyCost or 0))
        self.totalCost.favor = self.totalCost.favor + (info.buyAmt*(info.favorCost or 0))
        self.totalCost.reputation = self.totalCost.reputation + (info.buyAmt*(info.reputationCost or 0))
      end
      love.graphics.setStencilTest()
      if descrItem and descrItem.maxY-self.scrollY > listStartY then
        local text = descrItem.name.. "\n" .. descrItem.description
        local descX = nameX
        output:description_box(text,descX,descrItem.maxY,nil,self.scrollY)
      end
      love.graphics.pop()
      --Scrollbars
      if lastY*uiScale > height-padding then
        self.scrollMax = math.ceil((lastY-(listStartY+(height/uiScale-listStartY))+padding))
        local scrollAmt = self.scrollY/self.scrollMax
        self.scrollPositions = output:scrollbar(windowX+windowWidth,listStartY,math.floor((height-padding)/uiScale),scrollAmt,true)
      else
        self.scrollMax = 0
      end
    end --end buy/sell split
  elseif self.screen == "Spells" then
    self.spellButtons = {}
    local spellCount = 0
    local lastY = 0
    local maxX = windowWidth-padding
    if self.maxScroll and self.maxScroll > 0 then
      maxX = windowWidth-padding
    end
    
    --Drawing the text:
    love.graphics.push()
    --Create a "stencil" that stops 
    local function stencilFunc()
      love.graphics.rectangle("fill",windowX,listStartY,windowWidth+padding,height-listStartY)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.scrollY)
    
    for i,skillDef in ipairs(faction:get_teachable_skills()) do
      spellCount = spellCount + 1
      local skill = possibleSkills[skillDef.skill]
      local costText = nil
      if skillDef.moneyCost and skillDef.moneyCost ~= 0 then
        costText = "\n(Cost: " .. get_money_name(skillDef.moneyCost)
      end
      if skillDef.favorCost and skillDef.favorCost ~= 0 then
        if costText == nil then
          costText = "\n(Cost: "
        else
          costText = costText .. ", "
        end
        costText = costText .. skillDef.favorCost .. " Favor"
      end
      if skillDef.reputationCost and skillDef.reputationCost ~= 0 then
        if costText == nil then
          costText = "\n(Cost: "
        else
          costText = costText .. ", "
        end
        costText = costText .. skillDef.reputationCost .. " Reputation"
      end
      if costText then costText = costText .. ")" end
      local spellText = skill.name .. (skillDef.level > 1 and " Level " .. skillDef.level or "") .. (costText  and costText or "") .. "\n" .. skill.description
      local __, wrappedtext = fonts.textFont:getWrap(spellText, windowWidth)
      love.graphics.printf(spellText,printX,printY,windowWidth,"center")
      printY=printY+#wrappedtext*fontSize+8
      
      local canLearn = skillDef.canLearn
      local reasonText = skillDef.reasonText or "You're unable to learn this skill."
      if not canLearn then
        setColor(150,150,150,255)
      end
      local spellW = fonts.buttonFont:getWidth("Learn " .. skill.name)+padding
      local buttonX = math.floor(midX-spellW/2)
      local buttonHi = false
      if mouseX > buttonX and mouseX < buttonX+spellW and mouseY > printY-self.scrollY and mouseY < printY+32-self.scrollY then
        buttonHi = true
      end
      local button = output:button(buttonX,printY,spellW,false,((buttonHi or self.cursorY == 1+#self.spellButtons+1) and "hover" or false),"Learn " .. skill.name,true)
      button.skillID = skillDef.skill
      self.spellButtons[#self.spellButtons+1] = button 
      printY=printY+32
      setColor(255,255,255,255)
      if not canLearn then
        local _,rlines = fonts.textFont:getWrap(reasonText,windowWidth)
        love.graphics.printf(reasonText,windowX,printY,windowWidth,"center")
        printY = printY+fontSize*#rlines
        button.disabled=true
      end
      printY=printY+fontSize
      lastY = printY
    end
    for i,spellDef in ipairs(faction:get_teachable_spells()) do
      local spell = possibleSpells[spellDef.spell]
      spellCount = spellCount + 1
      local costText = nil
      if spellDef.moneyCost and spellDef.moneyCost > 0 then
        costText = "\n(Cost: " .. get_money_name(spellDef.moneyCost)
      end
      if spellDef.favorCost and spellDef.favorCost > 0  then
        if costText == nil then
          costText = "\n(Cost: "
        else
          costText = costText .. ", "
        end
        costText = costText .. spellDef.favorCost .. " Favor"
      end
      if spellDef.reputationCost and spellDef.reputationCost > 0 then
        if costText == nil then
          costText = "\n(Cost: "
        else
          costText = costText .. ", "
        end
        costText = costText .. spellDef.reputationCost .. " Reputation"
      end
      if costText then costText = costText .. ")" end
      local spellText = spell.name .. (costText or "") .. "\n" .. spell.description
      local __, wrappedtext = fonts.textFont:getWrap(spellText, maxX)
      love.graphics.printf(spellText,printX,printY,maxX,"center")
      printY=printY+#wrappedtext*fontSize+8
      
      local canLearn = spellDef.canLearn
      local reasonText = spellDef.reasonText or "You're unable to learn this ability."
      if not canLearn then
        setColor(150,150,150,255)
      end
      local spellW = fonts.buttonFont:getWidth("Learn " .. spell.name)+padding
      local buttonX = math.floor(midX-spellW/2+padding/2)
      local buttonHi = false
      if mouseX > buttonX and mouseX < buttonX+spellW and mouseY > printY-self.scrollY and mouseY < printY+32-self.scrollY then
        buttonHi = true
      end
      local button = output:button(buttonX,printY,spellW,false,((buttonHi or self.cursorY == 2+#self.spellButtons+1) and "hover" or false),"Learn " .. spell.name)
      button.spellID = spellDef.spell
      self.spellButtons[#self.spellButtons+1] = button 
      printY=printY+32
      setColor(255,255,255,255)
      if not canLearn then
        local _,rlines = fonts.textFont:getWrap(reasonText,windowWidth)
        love.graphics.printf(reasonText,windowX,printY,windowWidth,"center")
        printY = printY+fontSize*#rlines
        button.disabled=true
      end
      printY=printY+fontSize
      lastY = printY
    end
    if spellCount == 0 then
      love.graphics.printf("There are currently no skills or abilities available to learn.",windowX,printY,windowWidth,"center")
    end
    love.graphics.setStencilTest()
    love.graphics.pop()
    --Scrollbars
    if lastY*uiScale > height-padding then
      self.scrollMax = math.ceil((lastY-(listStartY+(height/uiScale-listStartY))+padding))
      local scrollAmt = self.scrollY/self.scrollMax
      self.scrollPositions = output:scrollbar(windowX+windowWidth,listStartY,math.floor((height-padding)/uiScale),scrollAmt,true)
    else
      self.scrollMax = 0
    end
  elseif self.screen == "Services" then
    self.serviceButtons = {}
    local serviceCount = 0
    local services = faction:get_available_services(player)
    local lastY = 0
    local maxX = windowWidth-padding
    if self.maxScroll and self.maxScroll > 0 then
      maxX = windowWidth-padding
    end
    
    --Drawing the text:
    love.graphics.push()
    --Create a "stencil" that stops 
    local function stencilFunc()
      love.graphics.rectangle("fill",windowX,listStartY,windowWidth+padding,height-listStartY)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.scrollY)
    for i,servData in ipairs(services) do
      local servID = servData.service
      serviceCount = serviceCount+1
      love.graphics.setFont(fonts.headerFont)
      local serviceHeader = servData.name
      local __, wrappedtext = fonts.textFont:getWrap(serviceHeader, windowWidth)
      love.graphics.printf(serviceHeader,printX,printY,windowWidth,"center")
      printY=math.ceil(printY+(#wrappedtext*fonts.headerFont:getHeight()))
      love.graphics.setFont(fonts.textFont)
      local serviceText = servData.description
      local __, wrappedtext = fonts.textFont:getWrap(serviceText, windowWidth)
      love.graphics.printf(serviceText,printX,printY,maxX,"center")
      printY=math.ceil(printY+(#wrappedtext+1)*fontSize)
      
      local canDo,canDoText = not servData.disabled,servData.explainText
      if canDo == false then
        setColor(150,150,150,255)
      end
      local serviceW = fonts.buttonFont:getWidth("Select " .. servData.name)+padding
      local buttonX = math.floor(midX-serviceW/2+padding/2)
      local buttonHi = false
      if mouseX > buttonX and mouseX < buttonX+serviceW and mouseY > printY-self.scrollY and mouseY < printY+32-self.scrollY then
        buttonHi = true
      end
      local button = output:button(buttonX,printY,serviceW,false,((buttonHi or self.cursorY == 2+#self.serviceButtons+1) and "hover" or false),"Select " .. servData.name)
      self.serviceButtons[#self.serviceButtons+1] = button
      setColor(255,255,255,255)
      printY=printY+32
      if canDo == false and canDoText then
        local __, wrappedtext = fonts.textFont:getWrap(canDoText, windowWidth)
        love.graphics.printf(canDoText,printX,printY,maxX,"center")
        printY=printY+(#wrappedtext+1)*fontSize
        button.disabled=true
      end
      printY=printY+fontSize
      lastY = printY
    end
    if serviceCount == 0 then
      love.graphics.printf("There are currently no services available.",windowX,printY,windowWidth,"center")
    end
    love.graphics.setStencilTest()
    love.graphics.pop()
    --Scrollbars
    if lastY*uiScale > height-padding then
      self.scrollMax = math.ceil((lastY-(listStartY+(height/uiScale-listStartY))+padding))
      local scrollAmt = self.scrollY/self.scrollMax
      self.scrollPositions = output:scrollbar(windowX+windowWidth,listStartY,math.floor((height-padding)/uiScale),scrollAmt,true)
    else
      self.scrollMax = 0
    end
  elseif self.screen == "Missions" then
    self.missionButtons = {}
    local missions = faction:get_available_missions(player)
    local missionCount = count(missions)
    local lastY = 0
    
    --Drawing the text:
    love.graphics.push()
    --Create a "stencil" that stops 
    local function stencilFunc()
      love.graphics.rectangle("fill",windowX,listStartY,windowWidth+padding,height-listStartY)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.scrollY)
    if faction.mission_limit then
      love.graphics.printf("This faction only offers " .. faction.mission_limit .. " mission" .. (faction.mission_limit == 1 and "" or "s") .. " at a time. Missions refresh daily.",printX,printY,windowWidth,"center")
      printY = printY + fontSize*2
    end
    for i, mData in ipairs(missions) do
      local missionID = mData.missionID
      local mission = possibleMissions[missionID]
      love.graphics.setFont(fonts.headerFont)
      local missionHeader = mData.name
      local __, wrappedtext = fonts.textFont:getWrap(missionHeader, windowWidth)
      love.graphics.printf(missionHeader,printX,printY,windowWidth,"center")
      printY=math.ceil(printY+(#wrappedtext+0.5)*fonts.headerFont:getHeight())
      love.graphics.setFont(fonts.textFont)
      local missionText = mData.description
      local __, wrappedtext = fonts.textFont:getWrap(missionText, windowWidth)
      love.graphics.printf(missionText,printX,printY,windowWidth,"center")
      printY=math.ceil(printY+(#wrappedtext+1)*fontSize)
      
      local rewards = mData.rewards
      if rewards then
        love.graphics.printf("Reward:",printX,printY,windowWidth,"center")
        printY=printY+fontSize
        if rewards.money then
          local mText = get_money_name(rewards.money)
          love.graphics.printf(mText,printX,printY,windowWidth,"center")
          local __, wrappedtext = fonts.textFont:getWrap(mText, windowWidth)
          printY=printY+math.ceil(#wrappedtext*fontSize)
        end
        if rewards.reputation then
          local rText = (rewards.reputation < 0 and "" or "+") .. rewards.reputation .. " Reputation with " .. self.faction:get_name()
          love.graphics.printf(rText,printX,printY,windowWidth,"center")
          local __, wrappedtext = fonts.textFont:getWrap(rText, windowWidth)
          printY=printY+math.ceil(#wrappedtext*fontSize)
        end
        if rewards.favor then
          local fText = (rewards.favor < 0 and "" or "+") .. rewards.favor .. " Favor with " .. self.faction:get_name()
          love.graphics.printf(fText,printX,printY,windowWidth,"center")
          local __, wrappedtext = fonts.textFont:getWrap(fText, windowWidth)
          printY=printY+math.ceil(#wrappedtext*fontSize)
        end
        if rewards.items then
          for _,itemInfo in ipairs(rewards.items) do
            local iText = (itemInfo.amount and itemInfo.amount > 1 and itemInfo.amount .. " " or "") .. ucfirst(itemInfo.displayName or (itemInfo.amount > 1 and possibleItems[itemInfo.item].pluralName or "x " .. possibleItems[itemInfo.item].name))
            love.graphics.printf(iText,printX,printY,windowWidth,"center")
            local __, wrappedtext = fonts.textFont:getWrap(iText, windowWidth)
            printY=printY+math.ceil(#wrappedtext*fontSize)
          end
        end
        for _,text in ipairs(rewards) do
          love.graphics.printf(text,printX,printY,windowWidth,"center")
          local __, wrappedtext = fonts.textFont:getWrap(text, windowWidth)
          printY=printY+math.ceil(#wrappedtext*fontSize)
        end
      end
      
      if mData.active then
        local canFinish,canFinishText = not mData.disabled,mData.explainText
        if not canFinish then
          setColor(150,150,150,255)
        end
        local serviceW = fonts.buttonFont:getWidth("Finish")+padding
        local buttonX = math.floor(midX-serviceW/2)
        local buttonHi = false
        if mouseX > buttonX and mouseX < buttonX+serviceW and mouseY > printY-self.scrollY and mouseY < printY+32-self.scrollY then
          buttonHi = true
        end
        local button = output:button(buttonX,printY,serviceW,false,((buttonHi or self.cursorY == 2+i) and "hover" or false),"Finish",true)
        button.missionID = missionID
        self.missionButtons[#self.missionButtons+1] = button
        setColor(255,255,255,255)
        printY=printY+32
        if not canFinish then
          local __, wrappedtext = fonts.textFont:getWrap(canFinishText, windowWidth)
          love.graphics.printf(canFinishText,printX,printY,windowWidth,"center")
          printY=printY+(#wrappedtext+1)*fontSize
          button.disabled=true
        end
        printY=printY+fontSize
      else --Not active mission
        local canDo,canDoText = not mData.disabled,mData.explainText
        if canDo == false then
          setColor(150,150,150,255)
        end
        local serviceW = fonts.buttonFont:getWidth("Accept")+padding
        local buttonX = math.floor(midX-serviceW/2)
        local buttonHi = false
        if mouseX > buttonX and mouseX < buttonX+serviceW and mouseY > printY-self.scrollY and mouseY < printY+32-self.scrollY then
          buttonHi = true
        end
        local button = output:button(buttonX,printY,serviceW,false,((buttonHi or self.cursorY == 2+i) and "hover" or false),"Accept",true)
        button.missionID = missionID
        self.missionButtons[#self.missionButtons+1] = button
        printY=printY+32
        setColor(255,255,255,255)
        if not canDo then
          local __, wrappedtext = fonts.textFont:getWrap(canDoText, windowWidth)
          love.graphics.printf(canDoText,printX,printY,windowWidth,"center")
          printY=printY+(#wrappedtext+1)*fontSize
          button.disabled=true
        end
        printY=printY+fontSize
      end --end active mission or not if
      lastY = printY
    end
    if missionCount == 0 then
      love.graphics.printf("There are currently no missions available.",printX,printY,windowWidth,"center")
    end
    love.graphics.setStencilTest()
    love.graphics.pop()
    --Scrollbars
    if lastY*uiScale > height-padding then
      self.scrollMax = math.ceil((lastY-(listStartY+(height/uiScale-listStartY))+padding))
      local scrollAmt = self.scrollY/self.scrollMax
      self.scrollPositions = output:scrollbar(windowX+windowWidth,listStartY,math.floor((height-padding)/uiScale),scrollAmt,true)
    else
      self.scrollMax = 0
    end
  elseif self.screen == "Recruit" then
    self.recruitButtons = {}
    local recruitCount = 0
    local recruitments = faction:get_recruitable_creatures(player)
    local lastY = 0
    local maxX = windowWidth-padding
    if self.maxScroll and self.maxScroll > 0 then
      maxX = windowWidth-padding
    end
    
    --Drawing the text:
    love.graphics.push()
    --Create a "stencil" that stops 
    local function stencilFunc()
      love.graphics.rectangle("fill",windowX,listStartY,windowWidth+padding,height-listStartY)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.scrollY)
    for i,recruitData in ipairs(recruitments) do
      recruitCount = recruitCount+1
      local canDo,canDoText = not recruitData.disabled,recruitData.explainText
      if canDo == false then
        setColor(150,150,150,255)
      end
      local recruitW = fonts.buttonFont:getWidth("Recruit")+padding
      local buttonX = printX
      local buttonHi = false
      if mouseX > buttonX and mouseX < buttonX+recruitW and mouseY > printY-self.scrollY and mouseY < printY+32-self.scrollY then
        buttonHi = true
      end
      local button = output:button(buttonX,printY,recruitW,false,((buttonHi or self.cursorY == 2+#self.recruitButtons+1) and "hover" or false),"Recruit")
      self.recruitButtons[#self.recruitButtons+1] = button
      button.data = recruitData
      
      local creatW = 0
      for creat,amt in pairs(recruitData.creatures) do
        local c = possibleMonsters[creat]
        c.baseType = "creature"
        output.display_entity(c,printX+recruitW+creatW,printY,"force")
        creatW = creatW + tileSize+2
      end
      
      local header = recruitData.name .. (recruitData.amount and " (" .. recruitData.amount .. " Available)" or "")
      local __, wrappedtext = fonts.textFont:getWrap(header, windowWidth)
      love.graphics.printf(header,printX+recruitW+creatW,printY,windowWidth,"left")
      printY=math.ceil(printY+math.min(tileSize+2,(#wrappedtext*fontSize)))
      if recruitData.description then
        local description = recruitData.description
        local __, wrappedtext = fonts.textFont:getWrap(description, windowWidth)
        love.graphics.printf(description,printX,printY,maxX,"left")
        printY=math.ceil(printY+(#wrappedtext+1)*fontSize)
      end
      
      setColor(255,255,255,255)
      if canDo == false and canDoText then
        local __, wrappedtext = fonts.textFont:getWrap(canDoText, windowWidth)
        love.graphics.printf(canDoText,printX,printY,maxX,"left")
        printY=printY+(#wrappedtext+1)*fontSize
        button.disabled=true
      end
      printY=printY+fontSize
      lastY = printY
    end
    if recruitCount == 0 then
      love.graphics.printf("There's currently no one available to recruit.",windowX,printY,windowWidth,"center")
    end
    love.graphics.setStencilTest()
    love.graphics.pop()
    --Scrollbars
    if lastY*uiScale > height-padding then
      self.scrollMax = math.ceil((lastY-(listStartY+(height/uiScale-listStartY))+padding))
      local scrollAmt = self.scrollY/self.scrollMax
      self.scrollPositions = output:scrollbar(windowX+windowWidth,listStartY,math.floor((height-padding)/uiScale),scrollAmt,true)
    else
      self.scrollMax = 0
    end
  end

  self.closebutton = output:closebutton(windowX+24,24,nil,true)
  love.graphics.pop()
end

function factionscreen:buttonpressed(key,scancode,isRepeat,controllerType)
  local key_south = input:get_button_name("south")
  local key_east = input:get_button_name("east")

  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if key == "escape" then
    self:switchBack()
  elseif (key == "enter" or key == "wait") then
    if self.cursorY == 1 then --join button
      if self.faction:can_join(player) then
        self.faction:join(player)
        self.playerMember=true
      end
    elseif self.cursorY == 2 then --nav buttons
     local whichButton = self.navButtons[self.cursorX]
      if whichButton == self.infoButton then
        self.screen = "Info"
        self.scrollY = 0
      elseif whichButton == self.shopButton then
        self.screen = "Items"
        self.scrollY = 0
      elseif whichButton == self.serviceButton then
        self.screen = "Services"
        self.scrollY = 0
      elseif whichButton == self.spellsButton then
        self.screen = "Spells"
      elseif whichButton == self.missionButton then
        self.screen = "Missions"
        self.scrollY = 0
      elseif whichButton == self.recruitButton then
        self.screen = "Recruit"
        self.scrollY = 0
      end
    else --activating something on the screen itself
      if self.screen == "Services" then
        if self.cursorY > 2 and self.serviceButtons[self.cursorY-2] and not self.serviceButtons[self.cursorY-2].disabled then
          local serviceData = self.faction.offers_services[self.cursorY-2]
          local service = possibleServices[serviceData.service]
          local didIt, useText = service:activate(player)
          if useText then self.outText = useText end
          if didIt and serviceData.moneyCost then
            player:update_money(-(serviceData.moneyCost+round(serviceData.moneyCost*(self.costMod/100))))
            self.outText = (self.outText .. "\n" or "") .. "You lose " .. get_money_name(serviceData.moneyCost+round(serviceData.moneyCost*(self.costMod/100))) .. "."
          end
          if didIt and serviceData.favorCost then
            player.favor[self.faction.id] = player.favor[self.faction.id] - serviceData.favorCost
            self.outText = (self.outText .. "\n" or "") .. "You lose " .. serviceData.favorCost .. " Favor."
          end
        end
      elseif self.screen == "Missions" then
        if self.cursorY > 2 and self.missionButtons[self.cursorY-2] and not self.missionButtons[self.cursorY-2].disabled then
          local missionID = self.missionButtons[self.cursorY-2].missionID
          local missionData = {}
          for _,mInfo in pairs(self.faction:get_available_missions(player)) do
            if mInfo.mission == missionID then
              missionData = mInfo
              break
            end
          end
          if currGame.missionStatus[missionID] then
            local mission = possibleMissions[missionID]
            if mission.can_finish and mission:can_finish(player) then
              local ret,useText = finish_mission(missionID)
              if ret then 
                self.outText = "Mission Complete: " .. possibleMissions[missionID].name
              elseif useText then
                self.outText = useText
              end
            end
          else
            local ret,useText = start_mission(missionID,missionData.starting_status,self.faction,missionData.starting_data)
            if ret then
              self.outText = "Mission Started: " .. possibleMissions[missionID].name
            elseif useText then
              self.outText = useText
            end
          end
        end
      elseif self.screen == "Spells" then
        if self.cursorY > 2 and self.spellButtons[self.cursorY-2] and not self.spellButtons[self.cursorY-2].disabled then
          local spellID = self.spellButtons[self.cursorY-2].spellID
          local skillID = self.spellButtons[self.cursorY-2].skillID
          local spell = possibleSpells[spellID]
          local skill = possibleSkills[skillID]
          if spellID and spell then
            if self.faction:teach_spell(spellID,player) ~= false then
              self.outText = "You learn " .. spell.name .. "."
            end
          elseif skillID and skill then
            if self.faction:teach_skill(skillID,player)then
              self.outText = "You are trained in " .. skill.name .. "."
            end
          end
        end
      elseif self.screen == "Recruit" then
        if self.cursorY > 2 and self.recruitButtons[self.cursorY-2] and not self.recruitButtons[self.cursorY-2].disabled then
          self.faction:recruit(self.recruitButtons[self.cursorY-2].data,player)
          if self.recruitButtons[self.cursorY-2].data.recruitText then self.outText = self.recruitButtons[self.cursorY-2].data.recruitText end
        end
      elseif self.screen == "Items" then
        if self.cursorY == 3 and not (self.faction.noBuy or self.faction.noSell) then --buttons
          if self.cursorX == 1 then
            self.subScreen = "Buy"
            self.cursorY = 4
            self.scrollY = 0
          else
            self.subScreen = "Sell"
            self.cursorY = 4
            self.scrollY = 0
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
          if self.cursorX == 1 and self.cursorY > 4 then --examine
            Gamestate.switch(examine_item,list[id].item,nil,true)
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
  elseif key == "west" then
    self.cursorX = self.cursorX - 1
    if self.cursorY == 2 and self.cursorX < 1 then self.cursorX = #self.navButtons end --looping if on the nav buttons
    if self.cursorY < 2 then self.cursorY = 2 self.cursorX = #self.navButtons end --if above the nav buttons, move to them
    if self.screen == "Items" then
      if self.cursorY == 3 and not (self.faction.noBuy or self.faction.noSell) then --looping if on the nav buttons
        self.cursorX = 1
      else
        self.cursorX = math.max(1,self.cursorX)
      end
    end
  elseif key == "east" then
    self.cursorX = self.cursorX + 1
    if self.cursorY == 2 and self.cursorX > #self.navButtons then self.cursorX = 1 end --looping if on the nav buttons
    if self.cursorY < 2 then self.cursorY = 2 self.cursorX = 1 end --if above the nav buttons, move to them
    if self.screen == "Items" then
      if self.cursorY == 3 and not (self.faction.noBuy or self.faction.noSell) then
        self.cursorX = 2
      elseif self.cursorY > 4 then
        local list = (self.subScreen == "Buy" and self.selling_list or self.buying_list)
        if list[self.cursorY-4].members_only and not self.playerMember then
          self.cursorX = 1
        end
      end
    end
  elseif key == "north" then
    if self.screen == "Info" and self.scrollY ~= 0 then
      self:scrollUp()
    elseif self.cursorY < 3 then --Top bars only
      self.cursorY = math.max((self.faction:can_join(player) and 1 or 2),self.cursorY-1)
    elseif self.cursorY == 3 then
      self.cursorY = 2
      if self.screen == "Items" then
        self.cursorX = self.shopButton.cursorX
      elseif self.screen == "Info" then
        self.cursorX = self.infoButton.cursorX
      elseif self.screen == "Services" then
        self.cursorX = self.serviceButton.cursorX
      elseif self.screen == "Spells" then
        self.cursorX = self.spellsButton.cursorX
      elseif self.screen == "Missions" then
        self.cursorX = self.missionButton.cursorX
      elseif self.screen == "Recruit" then
        self.cursorX = self.recruitButton.cursorX
      end
    elseif self.screen == "Services" then
      for i=self.cursorY-1,3,-1 do
        if self.serviceButtons[i-2] ~= false then
          self.cursorY = i
          break
        end
        self.cursorY = 2
        self.cursorX = self.serviceButton.cursorX
      end --end cursorY for
    elseif self.screen == "Spells" then
      for i=self.cursorY-1,3,-1 do
        if self.spellButtons[i-2] ~= false then
          self.cursorY = i
          break
        end
        self.cursorY = 2
        self.cursorX = self.spellButton.cursorX
      end --end cursorY for
    elseif self.screen == "Missions" then
      for i=self.cursorY-1,3,-1 do
        if self.missionButtons[i-2] ~= false then
          self.cursorY = i
          break
        end
        self.cursorY = 2
        self.cursorX = self.missionButton.cursorX
      end --end cursorY for
    elseif self.screen == "Recruit" then
      for i=self.cursorY-1,3,-1 do
        if self.recruitButtons[i-2] ~= false then
          self.cursorY = i
          break
        end
        self.cursorY = 2
        self.cursorX = self.recruitButon.cursorX
      end --end cursorY for
    elseif self.screen == "Items" then
      if self.cursorY > 1 then
        self.cursorY = self.cursorY - 1
        if self.cursorY == 3 then
          if (self.faction.noBuy or self.faction.noSell) then
            self.cursorY = 2
          elseif self.subScreen == "Buy" then
            self.cursorX = 1
          else
            self.cursorX = 2
          end
        end
        if self.cursorY == 2 then
          self.cursorX = self.shopButton.cursorX
        end
      end
    end --end cursorY check
  elseif key == "south" then
    if self.cursorY < 2 then --Top bars only
      self.cursorY = self.cursorY + 1
      if self.cursorY == 1 and not self.faction:can_join(player) then
        self.cursorY = 2
      end
    elseif self.screen == "Info" then
      self:scrollDown()
    elseif self.screen == "Services" then
      if (self.cursorY == 2 and self.serviceButtons[1]) then
        self.cursorY = 3
      else
        for i=self.cursorY-1,#self.serviceButtons,1 do
          if self.serviceButtons[i] then
            self.cursorY = i+2
            break
          end
        end --end cursorY for
      end --end if 1
    elseif self.screen == "Missions" then
      if (self.cursorY == 2 and self.missionButtons[1]) then
        self.cursorY = 3
      else
        for i=self.cursorY-1,#self.missionButtons,1 do
          if self.missionButtons[i] then
            self.cursorY = i+2
            break
          end
        end --end cursorY for
      end --end if 1
    elseif self.screen == "Spells" then
      if (self.cursorY == 2 and self.spellButtons[1]) then
        self.cursorY = 3
      else
        for i=self.cursorY-1,#self.spellButtons,1 do
          if self.spellButtons[i] then
            self.cursorY = i+2
            break
          end
        end --end cursorY for
      end --end if 1
    elseif self.screen == "Recruit" then
      if (self.cursorY == 2 and self.recruitButtons[1]) then
        self.cursorY = 3
      else
        for i=self.cursorY-1,#self.recruitButtons,1 do
          if self.recruitButtons[i] then
            self.cursorY = i+2
            break
          end
        end --end cursorY for
      end --end if 1
    elseif self.screen == "Items" then
      if self.cursorY == 2 then
        self.cursorX = 1
        self.cursorY = 3
      else
        local max = (self.subScreen == "Buy" and #self.selling_list+4 or #self.buying_list+4)
        if self.cursorY < max then
          self.cursorY = self.cursorY + 1
          if self.cursorY == 4 then
            self.cursorX = 1
          end
        end
      end --end cursorY check
    end
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
  elseif key == "nextTarget" then
    if self.cursorY == 1 then
      self:buttonpressed(key_south)
    elseif self.cursorY == 2 then
      local buttonCount = #self.navButtons
      if self.cursorX == buttonCount then
        self:buttonpressed(key_south)
        if self.cursorY == 2 then --if going down didn't change anything, loop to beginning
          self.cursorX = 1
        end
      else
        self:buttonpressed(key_east)
      end
    elseif self.screen == "Items" then
      if self.cursorY == 3 then
        if self.cursorX == 1 then
          self:buttonpressed(key_east)
        else
          self:buttonpressed(key_south)
        end
      elseif self.cursorY == 4 then
        self:buttonpressed(key_south)
      else
        if self.cursorX == 4 then
          local whichList = (self.subScreen == "Buy" and self.selling_list or self.buying_list)
          local max = #whichList+4
          self.cursorX = 1
          if self.cursorY == max then
            self.cursorY = 4
          else
            self:buttonpressed(key_south)
          end
        else
          local list = (self.subScreen == "Buy" and self.selling_list or self.buying_list)
          if list[self.cursorY-4].members_only and not self.playerMember then
            self:buttonpressed(key_south)
          else
            self:buttonpressed(key_east)
          end
        end
      end
    else --services, missions, or spells
      local whichList = (self.screen == "Services" and self.serviceButtons or (self.screen == "Spells" and self.spellButtons or self.missionButtons))
      if self.cursorY-2 == #whichList then
        self.cursorY = 2
      end
      self:buttonpressed(key_south)
    end
  end --end key if
end

function factionscreen:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y=x/uiScale,y/uiScale
  if (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    self:switchBack()
  end
  
  --Join button:
  if self.joinButton and x > self.joinButton.minX and x < self.joinButton.maxX and y > self.joinButton.minY and y < self.joinButton.maxY then
    if self.faction:can_join(player) then
      self.faction:join(player)
      self.playerMember=true
    end
  end
  --Item screen:
  if self.screen == "Items" then
    if self.buyButton and x > self.buyButton.minX and x < self.buyButton.maxX and y > self.buyButton.minY and y < self.buyButton.maxY then
      self.subScreen = "Buy"
      self.cursorY = 4
      self.scrollY = 0
    elseif self.sellButton and x > self.sellButton.minX and x < self.sellButton.maxX and y > self.sellButton.minY and y < self.sellButton.maxY then
      self.subScreen = "Sell"
      self.cursorY = 4
      self.scrollY = 0
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
      if listItem.minY and y > listItem.minY-self.scrollY and y < listItem.maxY-self.scrollY then
        self.cursorY = id+4
        self.cursorX = 1
        local minus,plus,action,numberEntry,examine = listItem.minusButton,listItem.plusButton,listItem.actionButton,listItem.numberEntry,listItem.examineButton
        if x > minus.minX and x < minus.maxX and y > minus.minY-self.scrollY and y < minus.maxY-self.scrollY then
          listItem.buyAmt = math.max(listItem.buyAmt-1,0)
          self.cursorX = 2
        elseif x > plus.minX and x < plus.maxX and y > plus.minY-self.scrollY and y < plus.maxY-self.scrollY then
          listItem.buyAmt = (listItem.amount ~= -1 and math.min(listItem.buyAmt+1,listItem.amount) or listItem.buyAmt+1)
          self.cursorX = 4
        elseif x > numberEntry.minX and x < numberEntry.maxX and y > numberEntry.minY-self.scrollY and y < numberEntry.maxY-self.scrollY then
          self.cursorX = 3
        elseif x > examine.minX and x < examine.maxX and y > examine.minY-self.scrollY and y < examine.maxY-self.scrollY then
          Gamestate.switch(examine_item,listItem.item,nil,true)
        end
        break --no reason to continue looking at other list items if we've already seen one
      end --end x/y check
    end --end list for
  end --end if item screen
  
  --Services:
  if self.screen == "Services" and self.serviceButtons then
    for i,button in ipairs(self.serviceButtons) do
      if button and not button.disabled and x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
        local serviceData = self.faction.offers_services[i]
        local service = possibleServices[serviceData.service]
        local didIt, useText = service:activate(player)
        if didIt and useText then self.outText = useText end
        if didIt and serviceData.moneyCost then
          player:update_money(-(serviceData.moneyCost+round(serviceData.moneyCost*(self.costMod/100))))
          self.outText = (self.outText .. "\n" or "") .. "You lose " .. get_money_name(serviceData.moneyCost+round(serviceData.moneyCost*(self.costMod/100))) .. "."
        end
        if didIt and serviceData.favorCost then
          player.favor[self.faction.id] = player.favor[self.faction.id] - serviceData.favorCost
          self.outText = (self.outText and self.outText .. "\n" or "") .. "You lose " .. serviceData.favorCost .. " Favor."
        end
      end--end button coordinate if
    end--end button for
  elseif self.screen == "Recruit" and self.recruitButtons then
    for i,button in ipairs(self.recruitButtons) do
      if button and not button.disabled and x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
        self.faction:recruit(button.data,player)
        if button.data.recruitText then self.outText = button.data.recruitText end
      end--end button coordinate if
    end--end button for
  elseif self.screen == "Spells" then
    for i,button in ipairs(self.spellButtons) do
      if button and not button.disabled and x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
        local spellID = self.spellButtons[i].spellID
        local skillID = self.spellButtons[i].skillID
        local spell = possibleSpells[spellID]
        local skill = possibleSkills[skillID]
        if spellID and spell then
          if self.faction:teach_spell(spellID,player) ~= false then
            self.outText = "You learn " .. spell.name .. "."
          end
        elseif skillID and skill then
          if self.faction:teach_skill(skillID,player) then
            self.outText = "You are trained in " .. skill.name .. "."
          end
        end
      end --end button coordinate if
    end --end button for
  elseif self.screen == "Missions" then
    for i,button in ipairs(self.missionButtons) do
      if button and not button.disabled and x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
        local missionID = button.missionID
        local missionData = {}
        for _,mInfo in pairs(self.faction:get_available_missions(player)) do
          if mInfo.mission == missionID then
            missionData = mInfo
            break
          end
        end
        if currGame.missionStatus[missionID] then
          local mission = possibleMissions[missionID]
          if mission.can_finish and mission:can_finish(player) then
            local ret, useText = finish_mission(missionID)
            if ret then
              self.outText = "Mission Complete: " .. possibleMissions[missionID].name
            elseif useText then
              self.outText = useText
            end
          end
        else
          local ret, useText = start_mission(missionID,missionData.starting_status,self.faction,missionData.starting_data)
          if ret then
            self.outText = "Mission Started: " .. possibleMissions[missionID].name
          elseif useText then
            self.outText = useText
          end
        end --end active or not if
      end--end button coordinate if
    end--end button for
  end
  
  --Navbuttons:
  if self.infoButton and x > self.infoButton.minX and x < self.infoButton.maxX and y > self.infoButton.minY and y < self.infoButton.maxY then
    self.screen = "Info"
    self.scrollY = 0
  elseif self.shopButton and x > self.shopButton.minX and x < self.shopButton.maxX and y > self.shopButton.minY and y < self.shopButton.maxY then
    self.screen = "Items"
    self.scrollY = 0
  elseif self.spellsButton and x > self.spellsButton.minX and x < self.spellsButton.maxX and y > self.spellsButton.minY and y < self.spellsButton.maxY then
    self.screen = "Spells"
    self.scrollY = 0
  elseif self.serviceButton and x > self.serviceButton.minX and x < self.serviceButton.maxX and y > self.serviceButton.minY and y < self.serviceButton.maxY then
    self.screen = "Services"
    self.scrollY = 0
  elseif self.missionButton and x > self.missionButton.minX and x < self.missionButton.maxX and y > self.missionButton.minY and y < self.missionButton.maxY then
    self.screen = "Missions"
    self.scrollY = 0
  elseif self.recruitButton and x > self.recruitButton.minX and x < self.recruitButton.maxX and y > self.recruitButton.minY and y < self.recruitButton.maxY then
    self.screen = "Recruit"
    self.scrollY = 0
  end
end --end mousepressed

function factionscreen:player_buys()
  if self.totalCost.money <= player.money and self.totalCost.favor <= (player.favor[self.faction.id] or 0) and self.totalCost.reputation <= (player.reputation[self.faction.id] or 0) then
    for id,info in ipairs(self.selling_list) do
      if info.buyAmt > 0 then
        self.faction:creature_buys_item(info.item,info)
        info.buyAmt = 0
      end
    end
    self:refresh_store_lists()
  end
end

function factionscreen:player_sells()
  for id,info in ipairs(self.buying_list) do
    if info.buyAmt > 0 and info.item then
      self.faction:creature_sells_item(info.item,info)
      info.buyAmt = 0
    elseif info.buyAmt and info.sellFavor then
      player:update_favor(self.faction.id,-info.buyAmt,nil,nil,true)
      local moneyAmt = self.faction.buys_favor_for_money*info.buyAmt
      player:update_money(moneyAmt)
      info.buyAmt = 0
    end
    self:refresh_store_lists()
  end
end

function factionscreen:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    local switch = self.previous or game
    Gamestate.switch(switch)
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
    if self.cursorY == 3 and (self.faction.noBuy or self.faction.noSell) then
      self.cursorY = 4
    end
  end
  if self.faction.reputation_per_favor_spent and self.faction.favor_spent then
    if self.faction.favor_spent > self.favor_bar_value then
      self.favor_bar_value = math.min(self.favor_bar_value+20*dt,self.faction.favor_spent)
    elseif self.favor_bar_value == self.faction.reputation_per_favor_spent then
      self.favor_bar_value = 0
    elseif self.faction.favor_spent < self.favor_bar_value then
      self.favor_bar_value = math.min(self.favor_bar_value+20*dt,self.faction.reputation_per_favor_spent)
    end
  end
end

function factionscreen:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function factionscreen:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end --end button type if
end

function factionscreen:scrollUp()
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
  end
end

function factionscreen:scrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
    end
  end
end

function factionscreen:get_cost_text(amt)
  if self.currency_item then
    return amt .. (self.currency_item.pluralName and " " .. self.currency_item.pluralName or " x " .. self.currency_item.name)
  else
    return get_money_name(amt)
  end
end