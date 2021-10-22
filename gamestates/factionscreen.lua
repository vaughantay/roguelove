factionscreen = {}

function factionscreen:enter(_,whichFac)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
  output:sound('stoneslideshort',2)
  self.cursorY = 0
  self.cursorX = 1
  self.scrollY = 0
  self.scrollMax = 0
  self.faction = currWorld.factions[whichFac]
  self.playerMember = player:is_faction_member(whichFac)
  self.screen="Info"
  self.subScreen="Buy"
  self.outText = nil
  self.totalCost = {favor=0,money=0}
  self.costMod = self.faction:get_cost_modifier(player)
  self:refresh_store_lists()
  self.lineCountdown = .5
end

function factionscreen:refresh_store_lists()
  self.buying_list = {}
  self.selling_list = {}

  for _,ilist in pairs(self.faction:get_inventory()) do
    local item = ilist.item
    self.selling_list[#self.selling_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),moneyCost=(ilist.moneyCost and ilist.moneyCost+round(ilist.moneyCost*(self.costMod/100)) or nil),favorCost=ilist.favorCost,membersOnly=ilist.membersOnly,amount=item.amount,buyAmt=0,item=item}
  end
  for _,ilist in pairs(self.faction:get_buy_list()) do
    local item = ilist.item
    self.buying_list[#self.buying_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),moneyCost=(ilist.moneyCost and ilist.moneyCost-round(ilist.moneyCost*(self.costMod/100)) or nil),favorCost=ilist.favorCost,amount=item.amount,buyAmt=0,item=item}
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
  local windowWidth = math.floor((width*.75)/uiScale)
  local midX = math.floor(width/2/uiScale)
  local windowX = math.floor(midX-windowWidth/2)
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
    end
    if reason then
      printY = printY+fontSize
      local _, wrappedtext = fonts.textFont:getWrap(reason, windowWidth)
      love.graphics.printf(reason,printX,printY,windowWidth,"center")
      printY=printY+(#wrappedtext)*fontSize
    end
    printY=printY+fontSize
  end
  
  if self.outText then
    printY=printY+fontSize
    local _, wrappedtext = fonts.textFont:getWrap(self.outText, windowWidth)
    love.graphics.printf(self.outText,printX,printY,windowWidth,"center")
    printY=printY+#wrappedtext*fontSize
  end
  
  if not faction.enter_threshold or ((player.favor[factionID] or 0) >= faction.enter_threshold) then
    printY=printY+fontSize
    local padX = 8
    local infobuttonW = fonts.buttonFont:getWidth("Information")+padding
    local shopbuttonW = fonts.buttonFont:getWidth("Items")+padding
    local spellbuttonW = fonts.buttonFont:getWidth("Abilities")+padding
    local servicebuttonW = fonts.buttonFont:getWidth("Services")+padding
    local missionbuttonW = fonts.buttonFont:getWidth("Missions")+padding
    local biggestButton = math.max(infobuttonW,shopbuttonW,servicebuttonW,spellbuttonW,missionbuttonW)
    infobuttonW,shopbuttonW,servicebuttonW,spellbuttonW,missionbuttonW = biggestButton,biggestButton,biggestButton,biggestButton,biggestButton
    local totalWidth = windowWidth
    local startX = windowX+math.floor(windowWidth/2-padding-2.5*biggestButton)+padding
    if self.screen == "Info" then setColor(150,150,150,255) end
    self.infoButton = output:button(startX,printY,infobuttonW+padX,false,((self.cursorX == 1 and self.cursorY == 2) and "hover" or nil),"Information",true)
    if self.screen == "Info" then setColor(255,255,255,255) end
    if self.screen == "Items" then setColor(150,150,150,255) end
    self.shopButton = output:button(startX+infobuttonW+padX*2,printY,shopbuttonW,false,((self.cursorX == 2 and self.cursorY == 2) and "hover" or nil),"Items",true)
    if self.screen == "Items" then setColor(255,255,255,255) end
    if self.screen == "Spells" then setColor(150,150,150,255) end
    self.spellsButton = output:button(startX+infobuttonW+shopbuttonW+padX*3,printY,spellbuttonW,false,((self.cursorX == 3 and self.cursorY == 2) and "hover" or nil),"Abilities",true)
    if self.screen == "Spells" then setColor(255,255,255,255) end
    if self.screen == "Services" then setColor(150,150,150,255) end
    self.serviceButton = output:button(startX+infobuttonW+shopbuttonW+spellbuttonW+padX*4,printY,servicebuttonW,false,((self.cursorX == 4 and self.cursorY == 2) and "hover" or nil),"Services",true)
    if self.screen == "Services" then setColor(255,255,255,255) end
    if self.screen == "Missions" then setColor(150,150,150,255) end
    self.missionButton = output:button(startX+infobuttonW+shopbuttonW+spellbuttonW+servicebuttonW+padX*5,printY,missionbuttonW,false,((self.cursorX == 5 and self.cursorY == 2) and "hover" or nil),"Missions",true)
    if self.screen == "Missions" then setColor(255,255,255,255) end
    printY = printY+padX
  else
    local _, wrappedtext = fonts.textFont:getWrap("You need more than " .. faction.enter_threshold .. " favor to do business with this faction.", windowWidth)
    love.graphics.printf("You need more than " .. faction.enter_threshold .. " favor to do business with this faction.",printX,printY,windowWidth,"center")
    printY=printY+(#wrappedtext)*fontSize-math.ceil(padding/2)
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
      local enemyText = "Hated Factions:\n"
      for i,fac in ipairs(faction.enemy_factions) do
        enemyText = enemyText .. (i > 1 and ", " or "") .. currWorld.factions[fac].name
      end
      love.graphics.printf(enemyText,printX,printY,maxW,"center")
      local _, wrappedtext = fonts.textFont:getWrap(enemyText, maxW)
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
    if faction.kill_favor_factions or faction.kill_favor_types then
      love.graphics.printf("Kill Favor:",printX,printY,maxW,"center")
      printY=printY+fontSize
      if faction.kill_favor_factions then
        local killtext = ""
        for fac,favor in pairs(faction.kill_favor_factions) do
          killtext = killtext .. (favor > 0 and "+" or "") .. favor .. ": members of " .. currWorld.factions[fac].name .. "\n"
        end
        love.graphics.printf(killtext,printX,printY,maxW,"left")
        local _, wrappedtext = fonts.textFont:getWrap(killtext, maxW)
        printY=printY+(#wrappedtext)*fontSize
      end --end kill_favor faction if
      if faction.kill_favor_types then
        local killtext = ""
        for typ,favor in pairs(faction.kill_favor_types) do
          killtext = killtext .. (favor > 0 and "+" or "") .. favor .. ": creatures of type " .. (creatureTypes[typ] and creatureTypes[typ].name or ucfirst(typ)) .. "\n"
        end
        love.graphics.printf(killtext,printX,printY,maxW,"left")
        local _, wrappedtext = fonts.textFont:getWrap(killtext, maxW)
        printY=printY+(#wrappedtext+1)*fontSize
      end --end kill_favor type if
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
    if not self.faction.noBuy then
      local padX = 8
      local buybuttonW = fonts.textFont:getWidth("Buying")+padding
      local sellbuttonW = fonts.textFont:getWidth("Selling")+padding
      local startX = windowX+math.floor(windowWidth/2)
      if self.subScreen == "Buy" then setColor(150,150,150,255) end
      self.buyButton = output:button(startX-math.floor(buybuttonW/2)-padX,printY,buybuttonW+padX,false,((self.cursorX == 1 and self.cursorY == 3) and "hover" or nil),"Buying",true)
      if self.subScreen == "Buy" then setColor(255,255,255,255) end
      if self.subScreen == "Sell" then setColor(150,150,150,255) end
      self.sellButton = output:button(startX+math.floor(buybuttonW/2)+padX,printY,sellbuttonW,false,((self.cursorX == 2 and self.cursorY == 3) and "hover" or nil),"Selling",true)
      if self.subScreen == "Sell" then setColor(255,255,255,255) end
      printY = printY+padding
      printY=printY+8
    end
    local mouseX,mouseY = love.mouse.getPosition()
    mouseX,mouseY = mouseX/uiScale,mouseY/uiScale
    if self.subScreen == "Buy" then
      local buybuttonW = fonts.textFont:getWidth("Buy")+padding
      local nameX = windowX+padding
      local costX = 0
      local amountX = 0
      local buyButtonX = windowX+windowWidth-buybuttonW
      local yPad = 8
      local buyBoxW = fonts.textFont:getWidth("1000")+8
      local buyBoxX = windowX+windowWidth-buyBoxW-padding*(self.scrollMax == 0 and 1 or 2)
      local priceX = buyBoxX-32-fonts.textFont:getWidth("$1000, 1000 Favor")
      local amtX = priceX-fonts.textFont:getWidth("x1000")
      local nameMaxLen = amtX-nameX
      local lastY = 0
      local descrItem = nil
      local costLine = "Favor Cost: " .. self.totalCost.favor .. ". Money Cost: $" .. self.totalCost.money .. " (You have $" .. player.money .. ") "
      local costlineW = fonts.textFont:getWidth(costLine)
      love.graphics.print(costLine,buyButtonX-costlineW,printY+4)
      if self.totalCost.money > player.money or self.totalCost.favor > favor then
        setColor(100,100,100,255)
      end
      self.storeActionButton = output:button(buyButtonX,printY-2,buybuttonW,false,(self.cursorY == 4 and "hover" or nil),"Buy",true)
      if self.totalCost.money > player.money or self.totalCost.favor > favor then
        setColor(255,255,255,255)
      end
      printY = printY+32
      local listStartY = printY
      self.listStartY = listStartY
      self.totalCost.money,self.totalCost.favor=0,0
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
        local nameLen,tlines = fonts.textFont:getWrap(info.name,nameMaxLen)
        info.maxX,info.maxY = info.minX+nameLen+yPad,info.minY+(#tlines*fontSize)+yPad*2
        if selected then
          setColor(50,50,50,255)
          love.graphics.rectangle('fill',info.minX,info.minY,windowWidth+yPad*2,(info.maxY-info.minY))
          setColor(255,255,255,255)
        end
        if selected and self.cursorX == 1 then
          setColor(100,100,100,255)
          love.graphics.rectangle('fill',nameX-yPad,info.minY,nameLen+yPad*2,info.maxY-info.minY)
          setColor(255,255,255,255)
        end
        love.graphics.printf(info.name,nameX,buyTextY,nameMaxLen)
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
          local minusMouse = false
          if info.minusButton and mouseX > info.minusButton.minX and mouseX < info.minusButton.maxX and mouseY > info.minusButton.minY-self.scrollY and mouseY < info.minusButton.maxY-self.scrollY then
            minusMouse = true
          end
          info.minusButton = output:tinybutton(buyBoxX-48,printY+8,nil,(minusMouse or (selected and self.cursorX == 2) and "hover" or false),"-")
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
          local plusMouse = false
          if info.plusButton and mouseX > info.plusButton.minX and mouseX < info.plusButton.maxX and mouseY > info.plusButton.minY-self.scrollY and mouseY < info.plusButton.maxY-self.scrollY then
            plusMouse = true
          end
          info.plusButton = output:tinybutton(buyBoxX+buyBoxW+16,printY+8,nil,(plusMouse or (selected and self.cursorX == 4) and "hover" or false),"+")
        else
          local moMax = buyBoxW+16+48+32
          local _,tl2 = fonts.textFont:getWrap("Members Only",moMax)
          love.graphics.printf("Members Only",buyBoxX-48,buyTextY,moMax,"center")
          if #tl2 > #tlines then tlines = tl2 end
        end
        --Display description if necessary:
        if (selected and self.cursorX == 1 and not descrItem) or (mouseX > nameX and mouseX < priceX and mouseY > info.minY-self.scrollY and mouseY < info.maxY-self.scrollY and not plusMouse and not minusMouse and not amountMouse) then
          descrItem = info
        end
        printY = printY+(#tlines*fontSize)+16
        lastY = printY
        self.totalCost.money = self.totalCost.money + (info.buyAmt*(info.moneyCost or 0))
        self.totalCost.favor = self.totalCost.favor + (info.buyAmt*(info.favorCost or 0))
      end
      love.graphics.setStencilTest()
      if descrItem and descrItem.maxY-self.scrollY > listStartY then
        local text = descrItem.item:get_name(true,1) .. "\n" .. descrItem.item:get_description() .. "\n" .. descrItem.item:get_info(true)
        local descX = nameX+round((amtX-nameX)/2)
        self:description_box(text,descX,descrItem.minY)
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
      local sellbuttonW = fonts.textFont:getWidth("Sell")+padding
      local nameX = windowX+padding
      local costX = 0
      local amountX = 0
      local sellButtonX = windowX+windowWidth-sellbuttonW
      local yPad = 8
      local sellBoxW = fonts.textFont:getWidth("1000")+8
      local sellBoxX = windowX+windowWidth-sellBoxW-padding*(self.scrollMax == 0 and 1 or 2)
      local priceX = sellBoxX-32-fonts.textFont:getWidth("$1000, 1000 Favor")
      local amtX = priceX-fonts.textFont:getWidth("x1000")
      local nameMaxLen = amtX-nameX
      local lastY = 0
      local descrItem = nil
      local costLine = "Favor Gain: " .. self.totalCost.favor .. ". Money Gain: " .. self.totalCost.money .. " "
      local costlineW = fonts.textFont:getWidth(costLine)
      love.graphics.print(costLine,sellButtonX-costlineW,printY+4)
      self.storeActionButton = output:button(sellButtonX,printY-2,sellbuttonW,false,(self.cursorY == 4 and "hover" or nil),"Sell",true)
      printY = printY+32
      local listStartY = printY
      self.listStartY = listStartY
      self.totalCost.money,self.totalCost.favor=0,0
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
        local selected = self.cursorY == id+4
        local sellTextY = printY+math.floor(padding/4)
        info.minX,info.minY = windowX+yPad,sellTextY-yPad
        local nameLen,tlines = fonts.textFont:getWrap(info.name,nameMaxLen)
        info.maxX,info.maxY = info.minX+nameLen+yPad,info.minY+(#tlines*fontSize)+yPad*2
        if selected then
          setColor(50,50,50,255)
          love.graphics.rectangle('fill',info.minX,info.minY,windowWidth+yPad,fontSize+yPad*2)
          setColor(255,255,255,255)
        end
        if selected and self.cursorX == 1 then
          setColor(100,100,100,255)
          love.graphics.rectangle('fill',nameX,sellTextY-yPad,nameLen,fontSize+yPad*2)
          setColor(255,255,255,255)
        end
        love.graphics.printf(info.name,nameX,sellTextY,nameMaxLen)
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
        local minusMouse = false
        if info.minusButton and mouseX > info.minusButton.minX and mouseX < info.minusButton.maxX and mouseY > info.minusButton.minY-self.scrollY and mouseY < info.minusButton.maxY-self.scrollY then
            minusMouse = true
          end
        info.minusButton = output:tinybutton(sellBoxX-48,printY+8,nil,(minusMouse or (selected and self.cursorX == 2) and "hover" or false),"-")
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
        info.plusButton = output:tinybutton(sellBoxX+sellBoxW+16,printY+8,nil,(plusMouse or (selected and self.cursorX == 4) and "hover" or false),"+")
        --Display description if necessary:
        if (selected and self.cursorX == 1 and not descrItem) or (mouseX > nameX and mouseX < priceX and mouseY > info.minY-self.scrollY and mouseY < info.maxY-self.scrollY and not plusMouse and not minusMouse and not amountMouse) then
          descrItem = info
        end
        printY = printY+(#tlines*fontSize)+16
        lastY = printY
        self.totalCost.money = self.totalCost.money + (info.buyAmt*(info.moneyCost or 0))
        self.totalCost.favor = self.totalCost.favor + (info.buyAmt*(info.favorCost or 0))
      end
      love.graphics.setStencilTest()
      if descrItem and descrItem.maxY-self.scrollY > listStartY then
        local text = descrItem.item:get_name(true,1) .. "\n" .. descrItem.item:get_description() .. "\n" .. descrItem.item:get_info(true)
        local descX = nameX+round((amtX-nameX)/2)
        self:description_box(text,descX,descrItem.minY)
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
    for i,spellDef in ipairs(faction.teaches_spells or {}) do
      if not player:has_spell(spellDef.spell) then
        spellCount = spellCount + 1
        local spell = possibleSpells[spellDef.spell]
        local costText = nil
        if spellDef.moneyCost then
          costText = " (Cost: $" .. spellDef.moneyCost+round(spellDef.moneyCost*(self.costMod/100))
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
        local canLearn = true
        local reasonText = nil
        
        if spellDef.membersOnly and not self.playerMember then
          reasonText = "This ability is only taught to members."
          canLearn = false
        elseif spellDef.favorCost and favor < spellDef.favorCost then
          reasonText = "You don't have enough favor to learn this ability."
          canLearn = false
        elseif spellDef.moneyCost and player.money < spellDef.moneyCost+round(spellDef.moneyCost*(self.costMod/100)) then
          reasonText = "You don't have enough money to learn this ability."
          canLearn = false
        else
          local ret,text = player:can_learn_spell(spellDef.spell)
          if ret == false then
            reasonText = (text or "You're unable to learn this ability.")
            canLearn = false
          end
        end
        if reasonText then
          spellText = spellText .. "\n" .. reasonText
        end
        local __, wrappedtext = fonts.textFont:getWrap(spellText, maxX)
        love.graphics.printf(spellText,printX,printY,maxX,"center")
        printY=printY+(#wrappedtext+1)*fontSize
        
        if canLearn then
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
        end
        printY=printY+fontSize
        lastY = printY
      end
    end
    if spellCount == 0 then
      love.graphics.printf("There are currently no spells available to learn.",windowX,printY,windowWidth,"center")
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
    local services = faction.offers_services or {}
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
      local service = possibleServices[servID]
      local costText = service:get_cost_text(player) or servData.costText or service.costText
      if costText == nil then
        local moneyText = (servData.moneyCost and "$" .. servData.moneyCost+round(servData.moneyCost*(self.costMod/100)) or nil)
        local favorText = (servData.favorCost and servData.favorCost.. " Favor" or nil)
        if moneyText then
          costText = moneyText .. (favorText and ", " .. favorText)
        else
          costText = favorText
        end
      end
      local serviceText = service.name .. (costText and " (Cost: " .. costText .. ")" or "") .. "\n" .. service.description
      local __, wrappedtext = fonts.textFont:getWrap(serviceText, windowWidth)
      love.graphics.printf(serviceText,printX,printY,maxX,"center")
      printY=math.ceil(printY+(#wrappedtext+0.5)*fontSize)
      
      local canDo,canDoText = nil,nil
      if servData.membersOnly and not self.playerMember then
        canDoText = "This service is only provided to members."
        canDo = false
      elseif servData.favorCost and favor < servData.favorCost then
        canDoText = "You don't have enough favor."
        canDo = false
      elseif servData.moneyCost and player.money < servData.moneyCost+round(servData.moneyCost*(self.costMod/100)) then
        canDoText = "You don't have enough money."
        canDo = false
      elseif not service.requires then
        canDo=true
      else
        canDo,canDoText = service:requires(player)
        if canDo == false then
          canDoText = "You're not eligible for this service" .. (canDoText and ": " .. canDoText or ".")
        end
      end
      if canDo == false then
        local __, wrappedtext = fonts.textFont:getWrap(canDoText, windowWidth)
        love.graphics.printf(canDoText,printX,printY,maxX,"center")
        printY=printY+(#wrappedtext+1)*fontSize
        self.serviceButtons[#self.serviceButtons+1] = false
      else
        local serviceW = fonts.buttonFont:getWidth("Select " .. service.name)+padding
        local buttonX = math.floor(midX-serviceW/2+padding/2)
        local buttonHi = false
        if mouseX > buttonX and mouseX < buttonX+serviceW and mouseY > printY-self.scrollY and mouseY < printY+32-self.scrollY then
          buttonHi = true
        end
        local button = output:button(buttonX,printY,serviceW,false,((buttonHi or self.cursorY == 2+#self.serviceButtons+1) and "hover" or false),"Select " .. service.name)
        self.serviceButtons[#self.serviceButtons+1] = button
        printY=printY+32
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
    local missions = (faction.offers_missions or {})
    local missionCount = 0
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
    for i, mData in ipairs(missions) do
      local missionID = mData.mission
      local active = currGame.missionStatus[missionID]
      if not currGame.finishedMissions[missionID] and possibleMissions[missionID] then
        missionCount = missionCount+1
        local mission = possibleMissions[missionID]
        local missionText = mission.name .. "\n" .. mission.description
        local __, wrappedtext = fonts.textFont:getWrap(missionText, windowWidth)
        love.graphics.printf(missionText,windowX,printY,windowWidth,"center")
        printY=math.ceil(printY+(#wrappedtext+0.5)*fontSize)
        if mData.membersOnly and not self.playerMember then
          local __, wrappedtext = fonts.textFont:getWrap("This mission is only offered to members.", windowWidth)
            love.graphics.printf("This mission is only offered to members.",windowX,printY,windowWidth,"center")
            printY=printY+(#wrappedtext+1)*fontSize
            self.missionButtons[#self.missionButtons+1] = false
        elseif active then
          local canFinish,canFinishText = nil,nil
          if mission.can_finish then
            canFinish,canFinishText = mission:can_finish(player)
          end
          if not canFinish then
            canFinishText = "You are currently on this mission" .. (canFinishText and ". " .. canFinishText or ".")
            local __, wrappedtext = fonts.textFont:getWrap(canFinishText, windowWidth)
            love.graphics.printf(canFinishText,windowX,printY,windowWidth,"center")
            printY=printY+(#wrappedtext+1)*fontSize
            self.missionButtons[#self.missionButtons+1] = false
          else
            local serviceW = fonts.textFont:getWidth("Finish")+padding
            local buttonX = math.floor(midX-serviceW/2)
            local buttonHi = false
            if mouseX > buttonX and mouseX < buttonX+serviceW and mouseY > printY-self.scrollY and mouseY < printY+32-self.scrollY then
              buttonHi = true
            end
            local button = output:button(buttonX,printY,serviceW,false,((buttonHi or self.cursorY == 2+i) and "hover" or false),"Finish",true)
            self.missionButtons[#self.missionButtons+1] = button
            printY=printY+32+fontSize
          end
        else --Not active mission
          local canDo,canDoText = (not mission.requires or mission:requires(player))
          if canDo == false then
            canDoText = "You're not eligible for this mission" .. (canDoText and ": " .. canDoText or ".")
            local __, wrappedtext = fonts.textFont:getWrap(canDoText, windowWidth)
            love.graphics.printf(canDoText,windowX,printY,windowWidth,"center")
            printY=printY+(#wrappedtext+1)*fontSize
            self.missionButtons[#self.missionButtons+1] = false
          else
            local serviceW = fonts.textFont:getWidth("Accept")+padding
            local buttonX = math.floor(midX-serviceW/2)
            local buttonHi = false
            if mouseX > buttonX and mouseX < buttonX+serviceW and mouseY > printY-self.scrollY and mouseY < printY+32-self.scrollY then
              buttonHi = true
            end
            local button = output:button(buttonX,printY,serviceW,false,((buttonHi or self.cursorY == 2+i) and "hover" or false),"Accept",true)
            self.missionButtons[#self.missionButtons+1] = button
            printY=printY+32+fontSize
          end
          lastY = printY
        end --end active mission or not if
      end
    end
    if missionCount == 0 then
      love.graphics.printf("There are currently no missions available.",windowX,printY,windowWidth,"center")
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

function factionscreen:keypressed(key)
  key = input:parse_key(key)
  if key == "escape" then
    self:switchBack()
  elseif (key == "return" or key == "wait") then
    if self.cursorY == 1 then --join button
      if self.faction:can_join(player) then
        self.faction:join(player)
        self.playerMember=true
      end
    elseif self.cursorY == 2 then --nav buttons
      if self.cursorX == 1 then self.screen = "Info" self.scrollY = 0
      elseif self.cursorX == 2 then self.screen = "Items" self.scrollY = 0
      elseif self.cursorX == 3 then self.screen = "Spells" self.scrollY = 0
      elseif self.cursorX == 4 then self.screen = "Services" self.scrollY = 0
      elseif self.cursorX == 5 then self.screen = "Missions" self.scrollY = 0 end
    else --activating something on the screen itself
      if self.screen == "Services" then
        if self.cursorY > 2 and self.serviceButtons[self.cursorY-2] then
          local serviceData = self.faction.offers_services[self.cursorY-2]
          local service = possibleServices[serviceData.service]
          local didIt, useText = service:activate(player)
          if useText then self.outText = useText end
          if serviceData.moneyCost then
            player.money = player.money - (serviceData.moneyCost+round(serviceData.moneyCost*(self.costMod/100)))
            self.outText = (self.outText .. "\n" or "") .. "You lose $" .. serviceData.moneyCost+round(serviceData.moneyCost*(self.costMod/100)) .. "."
          end
          if serviceData.favorCost then
            player.favor[self.faction.id] = player.favor[self.faction.id] - serviceData.favorCost
            self.outText = (self.outText .. "\n" or "") .. "You lose " .. serviceData.favorCost .. " Favor."
          end
        end
      elseif self.screen == "Missions" then
        if self.cursorY > 2 and self.missionButtons[self.cursorY-2] then
          local missionData = self.faction.offers_missions[self.cursorY-2]
          local missionID = missionData.mission
          if currGame.missionStatus[missionID] then
            local mission = possibleMissions[missionID]
            if mission.can_finish and mission:can_finish(player) then
              local useText = finish_mission(missionID)
              if type(useText) == "string" then self.outText = useText end
            end
          else
            local useText = start_mission(missionID,missionData.starting_status,self.faction,missionData.starting_data)
            if type(useText) == "string" then self.outText = useText end
          end
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
  elseif key == "west" then
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
  elseif key == "east" then
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
  elseif key == "north" then
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
      end
    end --end cursorY check
  elseif key == "south" then
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
        self.cursorY = id+2
        self.cursorX = 1
        local minus,plus,action,numberEntry = listItem.minusButton,listItem.plusButton,listItem.actionButton,listItem.numberEntry
        if x > minus.minX and x < minus.maxX and y > minus.minY-self.scrollY and y < minus.maxY-self.scrollY then
          listItem.buyAmt = math.max(listItem.buyAmt-1,0)
          self.cursorX = 2
        elseif x > plus.minX and x < plus.maxX and y > plus.minY-self.scrollY and y < plus.maxY-self.scrollY then
          listItem.buyAmt = (listItem.amount ~= -1 and math.min(listItem.buyAmt+1,listItem.amount) or listItem.buyAmt+1)
          self.cursorX = 4
        elseif x > numberEntry.minX and x < numberEntry.maxX and y > numberEntry.minY-self.scrollY and y < numberEntry.maxY-self.scrollY then
          self.cursorX = 3
        end
        break --no reason to continue looking at other list items if we've already seen one
      end --end x/y check
    end --end list for
  end --end if item screen
  
  --Services:
  if self.screen == "Services" and self.serviceButtons then
    for i,button in ipairs(self.serviceButtons) do
      if button and x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
        local serviceData = self.faction.offers_services[i]
        local service = possibleServices[serviceData.service]
        local didIt, useText = service:activate(player)
        if didIt and useText then self.outText = useText end
        if serviceData.moneyCost then
          player.money = player.money - (serviceData.moneyCost+round(serviceData.moneyCost*(self.costMod/100)))
          self.outText = (self.outText .. "\n" or "") .. "You lose $" .. serviceData.moneyCost+round(serviceData.moneyCost*(self.costMod/100)) .. "."
        end
        if serviceData.favorCost then
          player.favor[self.faction.id] = player.favor[self.faction.id] - serviceData.favorCost
          self.outText = (self.outText .. "\n" or "") .. "You lose " .. serviceData.favorCost .. " Favor."
        end
      end--end button coordinate if
    end--end button for
  elseif self.screen == "Spells" then
    for i,button in ipairs(self.spellButtons) do
      if button and x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
        local spellID = self.spellButtons[i].spellID
        local spell = possibleSpells[spellID]
        if self.faction:teach_spell(spellID,player) ~= false then
          self.outText = "You learn " .. spell.name .. "."
        end
      end --end button coordinate if
    end --end button for
  elseif self.screen == "Missions" then
    for i,button in ipairs(self.missionButtons) do
      if button and x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
        local missionData = self.faction.offers_missions[i]
        local missionID = missionData.mission
        if currGame.missionStatus[missionID] then
          local mission = possibleMissions[missionID]
          if mission.can_finish and mission:can_finish(player) then
            local useText = finish_mission(missionID)
            if type(useText) == "string" then self.outText = useText end
          end
        else
          local useText = start_mission(missionID,missionData.starting_status,self.faction,missionData.starting_data)
          if type(useText) == "string" then self.outText = useText end
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
  end
end --end mousepressed

function factionscreen:description_box(text,x,y,maxWidth)
  maxWidth = maxWidth or 300
  local oldFont = love.graphics.getFont()
  love.graphics.setFont(fonts.descFont)
  local width, tlines = fonts.descFont:getWrap(text,maxWidth)
  local height = #tlines*(prefs['descFontSize']+3)+prefs['descFontSize']
  x,y = round(x),round(y-height/2)
  while (y+height-self.scrollY > love.graphics.getHeight()) do
    y = y-prefs['descFontSize']
  end
    setColor(255,255,255,185)
    love.graphics.rectangle("line",x,y,302,height)
    setColor(0,0,0,185)
    love.graphics.rectangle("fill",x+1,y+1,301,height-1)
    setColor(255,255,255,255)
    love.graphics.printf(ucfirst(text),x+2,y+2,300)
  love.graphics.setFont(oldFont)
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