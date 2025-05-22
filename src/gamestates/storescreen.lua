storescreen = {}

function storescreen:enter(previous,whichStore,stash)
  if previous ~= examine_item then
    self.yModPerc = 100
    self.blackScreenAlpha=0
    tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
    output:sound('stoneslideshort',2)
    self.cursorY = 1
    self.cursorX = 1
    self.store = whichStore
    self.screen=nil
    self.outText = nil
    self.lineCountdown = 0.5
    self.totalCost = 0
    self.scrollY=0
    self.scrollMax=1000
    self.currency_item = self.store.currency_item and possibleItems[self.store.currency_item]
    self.costMod = 0
    self.stash = stash
    self.previous = previous
    if self.store.faction then
      self.faction = currWorld.factions[self.store.faction]
      self.playerMember = player:is_faction_member(self.store.faction)
      self.costMod = self.faction:get_cost_modifier(player)
      self.faction.contacted = true
    end
    self.store.contacted = true
    self:refresh_lists()
    self.buyButton = nil
    self.sellButton = nil
    self.serviceButton = nil
    self.spellsButton = nil
    self.missionButton = nil
  end
end

function storescreen:refresh_lists()
  self.buying_list = {}
  self.selling_list = {}

  for _,ilist in pairs(self.store:get_inventory()) do
    local item = ilist.item
    self.selling_list[#self.selling_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),cost=(ilist.cost and ilist.cost+round(ilist.cost*(self.costMod/100)) or 0),amount=(ilist.amount or item.amount or 1),buyAmt=0,item=item}
  end
  for _,ilist in pairs(self.store:get_buy_list()) do
    local item = ilist.item
    self.buying_list[#self.buying_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),cost=(ilist.cost and ilist.cost-round(ilist.cost*(self.costMod/100)) or 0),amount=(ilist.amount or item.amount or 1),buyAmt=0,item=item}
  end
  --Add items from stash:
  if self.stash then
    for _,ilist in pairs(self.store:get_buy_list(self.stash)) do
      local item = ilist.item
      self.buying_list[#self.buying_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),cost=(ilist.cost and ilist.cost-round(ilist.cost*(self.costMod/100)) or 0),amount=(ilist.amount or item.amount or 1),buyAmt=0,item=item,stash=self.stash}
    end
  end
end

function storescreen:draw()
  local storeID = self.store.id
  local store = self.store
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
  local fontSize = fonts.textFont:getHeight()
  local windowWidth = math.floor((width*.75)/uiScale)
  local midX = math.floor(width/2/uiScale)
  local windowX = math.floor(midX-windowWidth/2)
  output:draw_window(windowX,1,windowX+windowWidth,math.floor(height/uiScale-padding))
  local printX = windowX+fontSize
  --Basic header display:
  love.graphics.printf(store.name,printX,padding,windowWidth,"center")
  local printY = padding+fontSize*2
  local _, desclen = fonts.textFont:getWrap(store.description, windowWidth)
  love.graphics.printf(store.description,printX,printY,windowWidth,"center")
  printY=printY+#desclen*fontSize
  
  if self.outText then
    printY=printY+fontSize*2
    local _, wrappedtext = fonts.textFont:getWrap(self.outText, windowWidth)
    love.graphics.printf(self.outText,printX,printY,windowWidth,"center")
    printY=printY+#wrappedtext*fontSize
  end
  
  local canEnter = true
  local reasonText = nil
  
  if self.faction then
    if self.faction.enter_threshold and (player.reputation[self.faction.id] or 0) < self.faction.enter_threshold then
      canEnter = false
      reasonText = "Your reputation with " .. self.faction.name .. " is too low to enter this store."
    end
  end
  if canEnter and possibleStores[storeID].enter_requires then
    local canDo,reqText = possibleStores[storeID].enter_requires(store,player)
    if canDo == false then canEnter = false end
    if reqText then reasonText = reqText end
  end
  
  if canEnter and (not (self.store.noBuy and self.store.noSell) or count(self.store.offers_services) > 0 or count((self.store:get_teachable_spells())) > 0 or count((self.store:get_teachable_skills())) > 0) then
    printY=printY+fontSize
    local padX = 8
    local buybuttonW = fonts.buttonFont:getWidth("Buy")+padding
    local sellbuttonW = fonts.buttonFont:getWidth("Sell")+padding
    local servicebuttonW = fonts.buttonFont:getWidth("Services")+padding
    local spellbuttonW = fonts.buttonFont:getWidth("Skills/Abilities")+padding
    local missionbuttonW = fonts.buttonFont:getWidth("Missions")+padding
    local biggestButton = math.max(buybuttonW,sellbuttonW,servicebuttonW,spellbuttonW)
    buybuttonW,sellbuttonW,servicebuttonW,spellbuttonW= biggestButton,biggestButton,biggestButton,biggestButton
    local totalButtons = 2-(self.store.noBuy and 1 or 0)-(self.store.noSell and 1 or 0)
    self.navButtons = {}
    if self.store.offers_services and count(self.store.offers_services) > 0 then
      totalButtons = totalButtons+1
    end
    if count(self.store:get_teachable_spells(player)) > 0 or count(self.store:get_teachable_skills(player)) > 0 then
      totalButtons = totalButtons+1
    end
    if count(self.store:get_available_missions()) > 0 then
      totalButtons = totalButtons+1
    end
    local buttonX = windowX+math.floor(windowWidth/2-padding-(totalButtons/2)*biggestButton)+padding
    if not self.store.noSell then
      if not self.screen then self.screen = "Buy" end
      if self.screen == "Buy" then setColor(150,150,150,255) end
      self.buyButton = output:button(buttonX-padX,printY,buybuttonW+padX,false,((self.cursorX == 1 and self.cursorY == 1) and "hover" or nil),"Buy",true)
      self.navButtons[#self.navButtons+1] = self.buyButton
      self.buyButton.cursorX = #self.navButtons
      buttonX=buttonX+buybuttonW+padX
      if self.screen == "Buy" then setColor(255,255,255,255) end
    end
    if not self.store.noBuy then
      if not self.screen then self.screen = "Sell" end
      if self.screen == "Sell" then setColor(150,150,150,255) end
      self.sellButton = output:button(buttonX,printY,sellbuttonW,false,((self.cursorX == 2 and self.cursorY == 1) and "hover" or nil),"Sell",true)
      self.navButtons[#self.navButtons+1] = self.sellButton
      self.sellButton.cursorX = #self.navButtons
      buttonX=buttonX+sellbuttonW+padX
      if self.screen == "Sell" then setColor(255,255,255,255) end
    end
    if count(self.store.offers_services) > 0 then
      if not self.screen then self.screen = "Services" end
      if self.screen == "Services" then setColor(150,150,150,255) end
      self.serviceButton = output:button(buttonX,printY,servicebuttonW,false,((self.cursorX == #self.navButtons+1 and self.cursorY == 1) and "hover" or nil),"Services",true)
      self.navButtons[#self.navButtons+1] = self.serviceButton
      self.serviceButton.cursorX = #self.navButtons
      buttonX=buttonX+servicebuttonW+padX
      if self.screen == "Services" then setColor(255,255,255,255) end
    end
    if count(self.store:get_teachable_spells(player)) > 0 or count(self.store:get_teachable_skills(player)) > 0 then
      if not self.screen then self.screen = "Spells" end
      if self.screen == "Spells" then setColor(150,150,150,255) end
      self.spellsButton = output:button(buttonX,printY,spellbuttonW,false,((self.cursorX == #self.navButtons+1 and self.cursorY == 1) and "hover" or nil),"Skills/Abilities",true)
      self.navButtons[#self.navButtons+1] = self.spellsButton
      self.spellsButton.cursorX = #self.navButtons
      buttonX=buttonX+spellbuttonW+padX
      if self.screen == "Spells" then setColor(255,255,255,255) end
    end
    if count(self.store:get_available_missions()) > 0 then
      if not self.screen then self.screen = "Missions" end
      if self.screen == "Missions" then setColor(150,150,150,255) end
      self.missionButton = output:button(buttonX,printY,missionbuttonW,false,((self.cursorX == #self.navButtons+1 and self.cursorY == 1) and "hover" or nil),"Missions",true)
      self.navButtons[#self.navButtons+1] = self.missionButton
      self.missionButton.cursorX = #self.navButtons
      buttonX=buttonX+missionbuttonW+padX
      if self.screen == "Missions" then setColor(255,255,255,255) end
    end
    printY = printY+padding
  end
    printY=printY+8
    love.graphics.line(printX,printY,printX+windowWidth-padding,printY)
    printY=printY+8
  
  --Draw the screens:
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY=mouseX/uiScale,mouseY/uiScale
  if not canEnter then
    if not reasonText then reasonText = "You're currently unable to buy or sell at this store." end
    love.graphics.printf(reasonText,windowX+padding,printY,windowWidth-(padding*2),"center")
  elseif self.screen == "Buy" then
    local buybuttonW = fonts.buttonFont:getWidth("Buy")+padding
    local exambuttonW = fonts.buttonFont:getWidth("Examine")+padding
    local exambuttonX = windowX+padding
    local imageX = exambuttonX+exambuttonW+3
    local nameX = imageX+output:get_tile_size()+4
    local yPad = 8
    local buyBoxW = fonts.textFont:getWidth("1000")+8
    local buyBoxX = windowX+windowWidth-buyBoxW-padding*(self.scrollMax == 0 and 1 or 2)
    local buyButtonX = round((buyBoxX+buyBoxW/2)-buybuttonW/2)
    local priceW = fonts.textFont:getWidth(self:get_cost_text(1000))
    local priceX = buyBoxX-32-16-priceW-8
    local nameMaxLen = priceX-nameX
    local canBuy = false
    local costlineW = 0
    local lastY = 0
    local descrItem = nil
    if self.currency_item then
      local playerItem = player:has_item(self.store.currency_item)
      local playerAmt = playerItem and playerItem.amount or 0
      local costText = "You have " .. self:get_cost_text(playerAmt) .. ". " .. "Cost: "
      costlineW = fonts.textFont:getWidth(costText)
      costText = costText .. self:get_cost_text(self.totalCost) .. ". "
      love.graphics.print(costText,priceX-costlineW,printY+4)
      canBuy = (self.totalCost <= playerAmt)
    else
      local costText = "You have " .. self:get_cost_text(player.money) .. ". " .. "Cost: " 
      costlineW = fonts.textFont:getWidth(costText)
      costText = costText .. self:get_cost_text(self.totalCost) .. ". "
      love.graphics.print(costText,priceX-costlineW,printY+4)
      canBuy = (self.totalCost <= player.money)
    end
    
    if not canBuy then
      setColor(100,100,100,255)
    end
    self.actionButton = output:button(buyButtonX,printY-2,buybuttonW,false,(self.cursorY == 2 and "hover" or nil),"Buy",true)
    if not canBuy then
      setColor(255,255,255,255)
    end
    printY = printY+round(fontSize*1.5)
    local listStartY = printY
    self.listStartY = listStartY
    self.totalCost = 0
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
      local selected = self.cursorY == id+2
      local buyTextY = printY+math.floor(padding/4)
      info.minX,info.minY = windowX+yPad,buyTextY-yPad
      local name = (info.amount == -1 and "∞" or info.amount) .. " x " .. info.name
      local nameLen,tlines = fonts.textFont:getWrap(name,nameMaxLen)
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
      --Cost:
      love.graphics.printf(self:get_cost_text(info.cost),priceX,buyTextY,priceW,"right")
      --Minus button:
      local minusMouse = false
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
      local plusMouse = false
      if info.plusButton and mouseX > info.plusButton.minX and mouseX < info.plusButton.maxX and mouseY > info.plusButton.minY-self.scrollY and mouseY < info.plusButton.maxY-self.scrollY then
        plusMouse = true
      end
      info.plusButton = output:tinybutton(buyBoxX+buyBoxW+16,printY+4,nil,(plusMouse or (selected and self.cursorX == 4) and "hover" or false),"+")
      --Display description if necessary:
      if plusMouse or minusMouse or amountMouse or (mouseY > listStartY and mouseY < info.maxY and mouseX >= priceX and mouseX <= windowX+windowWidth) then
        descrItem = nil
      elseif (selected and self.cursorX == 1 and not descrItem) or (mouseX > exambuttonX and mouseX <= windowX+windowWidth and mouseY > info.minY-self.scrollY and mouseY < info.maxY-self.scrollY) then
        descrItem = info
      end
      printY = printY+(#tlines*fontSize)+16
      self.totalCost = self.totalCost + (info.buyAmt*info.cost)
      lastY = info.maxY
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
  elseif self.screen == "Sell" then
    local sellbuttonW = fonts.buttonFont:getWidth("Sell")+padding
    local exambuttonW = fonts.buttonFont:getWidth("Examine")+padding
    local exambuttonX = windowX+padding
    local imageX = exambuttonX+exambuttonW+3
    local nameX = imageX+output:get_tile_size()+4
    local yPad = 8
    local sellBoxW = fonts.textFont:getWidth("1000")+8
    local sellBoxX = windowX+windowWidth-sellBoxW-padding*(self.scrollMax == 0 and 1 or 2)
    local sellButtonX = round((sellBoxX+sellBoxW/2)-sellbuttonW/2)
    local priceW = fonts.textFont:getWidth(self:get_cost_text(1000) .. " (Highest known)")
    local priceX = sellBoxX-32-16-priceW-8
    local nameMaxLen = priceX-nameX
    local costlineW = 0
    local lastY = 0
    local descrItem = nil
    
    local costText = "You will receive: "
    costlineW = fonts.textFont:getWidth(costText)
    costText = costText .. self:get_cost_text(self.totalCost) .. ". "
    love.graphics.print(costText,priceX-costlineW,printY+4)

    self.actionButton = output:button(sellButtonX,printY-2,sellbuttonW,false,(self.cursorY == 2 and "hover" or nil),"Sell",true)
    printY = printY+32
    local listStartY = printY
    self.listStartY = listStartY
    self.totalCost = 0
    
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
      local selected = self.cursorY == id+2
      local sellTextY = printY+math.floor(padding/4)
      info.minX,info.minY = windowX+yPad,sellTextY-yPad
      local nameLen,tlines = fonts.textFont:getWrap(info.name,nameMaxLen)
      info.maxX,info.maxY = info.minX+nameLen+yPad,info.minY+(#tlines*fontSize)+yPad*2
      if selected then
        setColor(50,50,50,255)
        love.graphics.rectangle('fill',info.minX,info.minY,windowWidth+yPad,fontSize+yPad*2)
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
      output.display_entity(info.item,imageX,sellTextY-8,true,true)
      --Name:
      love.graphics.printf(name .. (info.stash and " (From " .. info.stash.name .. ")" or "") .. (info.item.equipped and " (Equipped)" or ""),nameX,sellTextY,nameMaxLen)
      --Cost:
      love.graphics.printf(self:get_cost_text(info.cost) .. (info.cost >= info.item:get_highest_sell_cost() and " (Highest known)" or ""),priceX,sellTextY,priceW,"right")
      --Minus button:
      local minusMouse = false
      if info.minusButton and mouseX > info.minusButton.minX and mouseX < info.minusButton.maxX and mouseY > info.minusButton.minY-self.scrollY and mouseY < info.minusButton.maxY-self.scrollY then
        minusMouse = true
      end
      info.minusButton = output:tinybutton(sellBoxX-48,printY+4,nil,(minusMouse or (selected and self.cursorX == 2) and "hover" or false),"-",true)
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
      info.plusButton = output:tinybutton(sellBoxX+sellBoxW+16,printY+4,nil,(plusMouse or (selected and self.cursorX == 4) and "hover" or false),"+",true)
      --Display description if necessary
      if plusMouse or minusMouse or amountMouse or (mouseY > listStartY and mouseY < info.maxY and mouseX >= priceX and mouseX <= windowX+windowWidth) then
        descrItem = nil
      elseif (selected and self.cursorX == 1 and not descrItem) or (mouseX > exambuttonX and mouseX <= windowX+windowWidth and mouseY > info.minY-self.scrollY and mouseY < info.maxY-self.scrollY) then
        descrItem = info
      end
      printY = printY+(#tlines*fontSize)+16
      self.totalCost = self.totalCost + (info.buyAmt*info.cost)
      lastY = info.maxY
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
  elseif self.screen == "Services" then
    self.serviceButtons = {}
    local serviceCount = 0
    local services = self.store:get_available_services(player)
    local lastY = 0
    local listStartY = printY
    
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
      love.graphics.printf(serviceText,windowX,printY,windowWidth,"center")
      printY=printY+(#wrappedtext+1)*fontSize
      
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
      local button = output:button(buttonX,printY,serviceW,false,((buttonHi or self.cursorY == 1+i) and "hover" or false),"Select " .. servData.name,true)
      self.serviceButtons[#self.serviceButtons+1] = button
      setColor(255,255,255,255)
      printY=printY+32
      if canDo == false and canDoText then
        local __, wrappedtext = fonts.textFont:getWrap(canDoText, windowWidth)
        love.graphics.printf(canDoText,windowX,printY,windowWidth,"center")
        printY=printY+(#wrappedtext+1)*fontSize
        button.disabled = true
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
  elseif self.screen == "Spells" then
    self.spellButtons = {}
    local spellCount = 0
    local lastY = 0
    local listStartY = printY
    
    --Drawing the text:
    love.graphics.push()
    --Create a "stencil" that stops 
    local function stencilFunc()
      love.graphics.rectangle("fill",windowX,listStartY,windowWidth+padding,height-listStartY)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.scrollY)
    
    for i,skillDef in ipairs(self.store:get_teachable_skills()) do
      spellCount = spellCount + 1
      local skill = possibleSkills[skillDef.skill]
      local costText = nil
      if skillDef.cost and skillDef.cost > 0 then
        costText = "\n(Cost: " .. self:get_cost_text(skillDef.cost) .. ")"
      end
      local spellText = skill.name .. (skillDef.level > 1 and " Level " .. skillDef.level or "") .. (costText or "") .. "\n" .. skill.description
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
    for i,spellDef in ipairs(self.store:get_teachable_spells(player) or {}) do
      spellCount = spellCount + 1
      local spell = possibleSpells[spellDef.spell]
      local costText = nil
      if spellDef.cost then
        costText = "\n(Cost: " .. self:get_cost_text(spellDef.cost) .. ")"
      end
      local spellText = spell.name .. (costText or "") .. "\n" .. spell.description
      local __, wrappedtext = fonts.textFont:getWrap(spellText, windowWidth)
      love.graphics.printf(spellText,windowX,printY,windowWidth,"center")
      printY=printY+#wrappedtext*fontSize+8
      
      local canLearn = spellDef.canLearn
      local reasonText = spellDef.reasonText or "You're unable to learn this ability."
      if not canLearn then
        setColor(150,150,150,255)
      end
      local spellW = fonts.buttonFont:getWidth("Learn " .. spell.name)+padding
      local buttonX = math.floor(midX-spellW/2)
      local buttonHi = false
      if mouseX > buttonX and mouseX < buttonX+spellW and mouseY > printY-self.scrollY and mouseY < printY+32-self.scrollY then
        buttonHi = true
      end
      local button = output:button(buttonX,printY,spellW,false,((buttonHi or self.cursorY == 1+#self.spellButtons+1) and "hover" or false),"Learn " .. spell.name,true)
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
  elseif self.screen == "Missions" then
    self.missionButtons = {}
    local missions = self.store:get_available_missions()
    local missionCount = count(missions)
    local lastY = 0
    local listStartY = printY
    
    --Drawing the text:
    love.graphics.push()
    --Create a "stencil" that stops 
    local function stencilFunc()
      love.graphics.rectangle("fill",windowX,listStartY,windowWidth+padding,height-listStartY)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.scrollY)
    if store.mission_limit then
      love.graphics.printf("This store only offers " .. store.mission_limit .. " mission" .. (store.mission_limit == 1 and "" or "s") .. " at a time. Missions refresh daily.",printX,printY,windowWidth,"center")
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
      love.graphics.printf(missionText,windowX,printY,windowWidth,"center")
      printY=math.ceil(printY+(#wrappedtext+1)*fontSize)
      
      local rewards = mData.rewards
      if rewards then
        love.graphics.printf("Reward:",printX,printY,windowWidth,"center")
        printY=printY+fontSize
        if rewards.money then
          local mText = get_money_name(rewards.money)
          love.graphics.printf(mText,printX,printY,windowWidth,"center")
          local __, wrappedtext = fonts.textFont:getWrap(mText, windowWidth)
          printY=math.ceil(printY+(#wrappedtext)*fontSize)
        end
        if rewards.reputation and self.faction then
          local rText = (rewards.reputation < 0 and "" or "+") .. rewards.reputation .. " Reputation with " .. self.faction:get_name()
          love.graphics.printf(rText,printX,printY,windowWidth,"center")
          local __, wrappedtext = fonts.textFont:getWrap(rText, windowWidth)
          printY=math.ceil(printY+(#wrappedtext)*fontSize)
        end
        if rewards.favor and self.faction then
          local fText = (rewards.favor < 0 and "" or "+") .. rewards.favor .. " Favor with " .. self.faction:get_name()
          love.graphics.printf(fText,printX,printY,windowWidth,"center")
          local __, wrappedtext = fonts.textFont:getWrap(fText, windowWidth)
          printY=math.ceil(printY+(#wrappedtext)*fontSize)
        end
        if rewards.items then
          for _,itemInfo in ipairs(rewards.items) do
            local iText = (itemInfo.amount and itemInfo.amount > 1 and itemInfo.amount .. " " or "") .. ucfirst(itemInfo.displayName or (itemInfo.amount > 1 and possibleItems[itemInfo.item].pluralName or "x " .. possibleItems[itemInfo.item].name))
            love.graphics.printf(iText,printX,printY,windowWidth,"center")
            local __, wrappedtext = fonts.textFont:getWrap(iText, windowWidth)
            printY=math.ceil(printY+(#wrappedtext)*fontSize)
          end
        end
        for _,text in ipairs(rewards) do
          love.graphics.printf(text,printX,printY,windowWidth,"center")
          local __, wrappedtext = fonts.textFont:getWrap(text, windowWidth)
          printY=math.ceil(printY+(#wrappedtext)*fontSize)
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
        local button = output:button(buttonX,printY,serviceW,false,((buttonHi or self.cursorY == 1+i) and "hover" or false),"Finish",true)
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
        printY = printY+fontSize
        lastY = printY
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
        local button = output:button(buttonX,printY,serviceW,false,((buttonHi or self.cursorY == 1+i) and "hover" or false),"Accept",true)
        button.missionID = missionID
        self.missionButtons[#self.missionButtons+1] = button
        setColor(255,255,255,255)
        printY=printY+32
        if canDo == false then
          local __, wrappedtext = fonts.textFont:getWrap(canDoText, windowWidth)
          love.graphics.printf(canDoText,printX,printY,windowWidth,"center")
          printY=printY+(#wrappedtext+1)*fontSize
          button.disabled = true
        end
        printY=printY+fontSize
        lastY = printY
      end --end active mission or not if
    end
    if missionCount == 0 then
      love.graphics.printf("There are currently no missions available. Missions refresh every day, so there may be more tomorrow.",printX,printY,windowWidth,"center")
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

function storescreen:buttonpressed(key,scancode,isRepeat,controllerType)
  local key_south = input:get_button_name("south")
  local key_east = input:get_button_name("east")

  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local typed = key
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if key == "escape" then
    self:switchBack()
  elseif (key == "enter" or key == "wait") then
    if self.cursorY == 1 then --buttons
      local whichButton = self.navButtons[self.cursorX]
      if whichButton == self.buyButton then
        self.screen = "Buy"
        self.scrollY = 0
      elseif whichButton == self.sellButton then
        self.screen = "Sell"
        self.scrollY = 0
      elseif whichButton == self.serviceButton then
        self.screen = "Services"
        self.scrollY = 0
      elseif whichButton == self.spellsButton then
        self.screen = "Spells"
      elseif whichButton == self.missionButton then
        self.screen = "Missions"
        self.scrollY = 0
      end
    elseif self.screen == "Services" then
      if self.cursorY > 1 and self.serviceButtons[self.cursorY-1] and not self.serviceButtons[self.cursorY-1].disabled then
        local serviceData = self.store.offers_services[self.cursorY-1]
        local service = possibleServices[serviceData.service]
        local didIt, useText = service:activate(player)
        if useText then self.outText = useText end
        if didIt and serviceData.cost then
          if self.currency_item then
            local creatureItem = player:has_item(self.store.currency_item)
            player:delete_item(creatureItem,serviceData.cost)
          else
            player:update_money(-(serviceData.cost+round(serviceData.cost*(self.costMod/100))))
            self.outText = (self.outText and self.outText .. "\n" or "") .. "You lose " .. get_money_name(serviceData.cost+round(serviceData.cost*(self.costMod/100))) .. "."
          end
        end
      end
    elseif self.screen == "Spells" then
      if self.cursorY > 1 and self.spellButtons[self.cursorY-1] and not self.spellButtons[self.cursorY-1].disabled then
        local spellID = self.spellButtons[self.cursorY-1].spellID
        local skillID = self.spellButtons[self.cursorY-1].skillID
        local spell = possibleSpells[spellID]
        local skill = possibleSkills[skillID]
        if spellID and spell then
          if self.store:teach_spell(spellID,player) ~= false then
            self.outText = "You learn " .. spell.name .. "."
          end
        elseif skillID and skill then
          if self.store:teach_skill(skillID,player) then
            self.outText = "You are trained in " .. skill.name .. "."
          end
        end
      end
    elseif self.screen == "Missions" then
      if self.cursorY > 1 and self.missionButtons[self.cursorY-1] and not self.missionButtons[self.cursorY-1].disabled then
        local missionID = self.missionButtons[self.cursorY-1].missionID
        local missionData = {}
        for _,mInfo in pairs(self.store:get_available_missions()) do
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
          local ret,useText = start_mission(missionID,missionData.starting_status,self.store,missionData.starting_data)
          if ret then 
            self.outText = "Mission Started: " .. possibleMissions[missionID].name
          elseif useText then
            self.outText = useText
          end
        end
      end
    elseif self.cursorY == 2 then
      if self.screen == "Buy" then
        self:player_buys()
      else
        self:player_sells()
      end
    else --Buy buttons
      local id = self.cursorY-2
      local list = (self.screen == "Buy" and self.selling_list or self.buying_list)
      if self.cursorX == 1 and self.cursorY > 2 then
        Gamestate.switch(examine_item,list[id].item,nil,true)
      elseif self.cursorX == 2 and self.cursorY > 2 then --minus button
        list[id].buyAmt = math.max(list[id].buyAmt-1,0)
      elseif self.cursorX == 4 and self.cursorY > 2 then --plus button
        list[id].buyAmt = (list[id].amount ~= -1 and math.min(list[id].buyAmt+1,list[id].amount) or list[id].buyAmt+1)
      end
    end --end cursorY tests within return
  elseif key == "west" then
    local buttonCount = #self.navButtons
    if self.cursorY == 1 then --looping if on the nav buttons
      self.cursorX = self.cursorX-1
      if self.cursorX < 1 then self.cursorX = buttonCount end
    else
      self.cursorX = math.max(1,self.cursorX-1)
    end
  elseif key == "east" then
    local buttonCount = #self.navButtons
    if self.cursorY == 1 then --looping if on the nav buttons
      self.cursorX = self.cursorX+1
      if self.cursorX > buttonCount then self.cursorX = 1 end
    else
      self.cursorX = math.min(self.cursorX+1,4)
    end
  elseif key == "north" then
    if self.cursorY > 1 then
      self.cursorY = self.cursorY - 1
      if self.cursorY == 1 then
        if self.screen == "Buy" then
          self.cursorX = self.buyButton.cursorX
        elseif self.screen == "Sell" then
          self.cursorX = self.sellButton.cursorX
        elseif self.screen == "Services" then
          self.cursorX = self.serviceButton.cursorX
        elseif self.screen == "Spells" then
          self.cursorX = self.spellsButton.cursorX
        elseif self.screen == "Missions" then
          self.cursorX = self.missionButton.cursorX
        end
      elseif self.screen == "Buy" or self.screen == "Sell" then
        local whichList = (self.screen == "Buy" and self.selling_list or self.buying_list)
        if whichList[self.cursorY-2] then
          if whichList[self.cursorY-2].minY-self.scrollY < (self.listStartY or 0) and self.scrollY > 0 then
            while whichList[self.cursorY-2].minY-self.scrollY < (self.listStartY or 0) and self.scrollY > 0 do
              self:scrollUp()
            end
          elseif whichList[self.cursorY-2].maxY*uiScale-self.scrollY > height/uiScale and self.scrollY < self.scrollMax then
            while whichList[self.cursorY-2].maxY-self.scrollY > height/uiScale and self.scrollY < self.scrollMax do
              self:scrollDown()
            end
          end
        end
      end
    end --end cursorY check
  elseif key == "south" then
    if self.screen == "Services" then
      if (self.cursorY == 1 and self.serviceButtons[1]) then
        self.cursorY = 2
      else
        for i=self.cursorY,#self.serviceButtons,1 do
          if self.serviceButtons[i] then
            self.cursorY = i+1
            break
          end
        end --end cursorY for
      end --end if 1
    elseif self.screen == "Missions" then
      if (self.cursorY == 1 and self.missionButtons[1]) then
        self.cursorY = 2
      else
        for i=self.cursorY,#self.missionButtons,1 do
          if self.missionButtons[i] then
            self.cursorY = i+1
            break
          end
        end --end cursorY for
      end --end if 1
    elseif self.screen == "Spells" then
      if (self.cursorY == 1 and self.spellButtons[1]) then
        self.cursorY = 2
      else
        for i=self.cursorY-1,#self.spellButtons,1 do
          if self.spellButtons[i] or (self.cursorY == 1 and self.spellButtons[1]) then
            self.cursorY = i+1
            break
          end
        end --end cursorY for
      end --end if 1
    else --buy or sell screen
      local whichList = (self.screen == "Buy" and self.selling_list or self.buying_list)
      local max = #whichList+2
      if self.cursorY < max then
        self.cursorY = self.cursorY + 1
        if self.cursorY == 2 then
          self.cursorX = 1
        end
        if whichList[self.cursorY-2] then
          if whichList[self.cursorY-2].minY-self.scrollY < (self.listStartY or 0) and self.scrollY > 0 then
            while whichList[self.cursorY-2].minY-self.scrollY < (self.listStartY or 0) and self.scrollY > 0 do
              self:scrollUp()
            end
          elseif whichList[self.cursorY-2].maxY*uiScale-self.scrollY > height/uiScale and self.scrollY < self.scrollMax then
            while whichList[self.cursorY-2].maxY-self.scrollY > height/uiScale and self.scrollY < self.scrollMax do
              self:scrollDown()
            end
          end
        end
      end
    end
  elseif tonumber(typed) and self.cursorX == 3 then
    local id = self.cursorY-2
    local list = (self.screen == "Buy" and self.selling_list or self.buying_list)
    if string.len(tostring(list[id].buyAmt or "")) < 3 then
      if list[id].buyAmt == 0 then
        list[id].buyAmt = tonumber(typed)
      else
        local newAmt = (list[id].buyAmt or "").. typed
        list[id].buyAmt = tonumber(newAmt)
      end
    end
  elseif (typed == "backspace") and self.cursorX == 3 then
    local id = self.cursorY-2
    local list = (self.screen == "Buy" and self.selling_list or self.buying_list)
    local amt = tostring(list[id].buyAmt)
    local newAmt = tonumber(string.sub(amt,1,#amt-1))
    list[id].buyAmt = (newAmt or 0)
  elseif key == "nextTarget" then
    if self.cursorY == 1 then
      local buttonCount = #self.navButtons
      if self.cursorX == buttonCount then
        self:buttonpressed(key_south)
        if self.cursorY == 2 then --if going down didn't change anything, loop to beginning
          self.cursorX = 1
        end
      else
        self:buttonpressed(key_east)
      end
    elseif self.screen == "Buy" or self.screen == "Sell" then
      if self.cursorY == 2 then
        self:buttonpressed(key_south)
      else
        if self.cursorX == 4 then
          local whichList = (self.screen == "Buy" and self.selling_list or self.buying_list)
          local max = #whichList+2
          self.cursorX = 1
          if self.cursorY == max then
            self.cursorY = 2
          else
            self:buttonpressed(key_south)
          end
        else
          self:buttonpressed(key_east)
        end
      end
    else --services, missions, or spells
      local whichList = (self.screen == "Services" and self.serviceButtons or self.spellButtons)
      if self.cursorY-1 == #whichList then
        self.cursorY = 1
      end
      self:buttonpressed(key_south)
    end
  end --end key if
end

function storescreen:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y=x/uiScale,y/uiScale
  if (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    self:switchBack()
  end
  --Buy/Sell Buttons:
  if self.buyButton and x > self.buyButton.minX and x < self.buyButton.maxX and y > self.buyButton.minY and y < self.buyButton.maxY then
      self.screen = "Buy"
      self.cursorX = self.buyButton.cursorX
      self.cursorY = 1
      self.scrollY = 0
    elseif self.sellButton and x > self.sellButton.minX and x < self.sellButton.maxX and y > self.sellButton.minY and y < self.sellButton.maxY then
      self.screen = "Sell"
      self.cursorX = self.sellButton.cursorX
      self.cursorY = 1
      self.scrollY = 0
    elseif self.serviceButton and x > self.serviceButton.minX and x < self.serviceButton.maxX and y > self.serviceButton.minY and y < self.serviceButton.maxY then
      self.screen = "Services"
      self.cursorX = self.serviceButton.cursorX
      self.cursorY = 1
      self.scrollY = 0
    elseif self.spellsButton and x > self.spellsButton.minX and x < self.spellsButton.maxX and y > self.spellsButton.minY and y < self.spellsButton.maxY then
      self.screen = "Spells"
      self.cursorX = self.spellsButton.cursorX
      self.cursorY = 1
      self.scrollY = 0
    elseif self.missionButton and x > self.missionButton.minX and x < self.missionButton.maxX and y > self.missionButton.minY and y < self.missionButton.maxY then
      self.screen = "Missions"
      self.cursorX = self.missionButton.cursorX
      self.cursorY = 1
      self.scrollY = 0
  elseif self.screen == "Services" and self.serviceButtons then --Services:
    for i,button in ipairs(self.serviceButtons) do
      if button and not button.disabled and x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
        local serviceData = self.store.offers_services[i]
        local service = possibleServices[serviceData.service]
        local didIt, useText = service:activate(player)
        if useText then self.outText = useText end
        if didIt then
          if serviceData.cost then
            if self.currency_item then
              local creatureItem = player:has_item(self.store.currency_item)
              player:delete_item(creatureItem,serviceData.cost)
            else
              player:update_money(-(serviceData.cost+round(serviceData.cost*(self.costMod/100))))
              self.outText = (self.outText and self.outText .. "\n" or "") .. "You lose " .. get_money_name(serviceData.cost+round(serviceData.cost*(self.costMod/100))) .. "."
            end
          end
        end
      end--end button coordinate if
    end--end button for
  elseif self.screen == "Spells" and self.spellButtons then
    for i,button in ipairs(self.spellButtons) do
      if button and not button.disabled and x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
        local spellID = self.spellButtons[i].spellID
        local skillID = self.spellButtons[i].skillID
        local spell = possibleSpells[spellID]
        local skill = possibleSkills[skillID]
        if spellID and spell then
          if self.store:teach_spell(spellID,player) ~= false then
            self.outText = "You learn " .. spell.name .. "."
          end
        elseif skillID and skill then
          if self.store:teach_skill(skillID,player) then
            self.outText = "You are trained in " .. skill.name .. "."
          end
        end
      end --end button coordinate if
    end --end button for
  elseif self.screen == "Missions" and self.missionButtons then --Services:
    for i,button in ipairs(self.missionButtons) do
      if button and not button.disabled and x > button.minX and x < button.maxX and y > button.minY-self.scrollY and y < button.maxY-self.scrollY then
        local missionID = button.missionID
        local missionData = {}
        for _,mInfo in pairs(self.store:get_available_missions()) do
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
          local ret, useText = start_mission(missionID,missionData.starting_status,self.store,missionData.starting_data)
          if ret then 
            self.outText = "Mission Started: " .. possibleMissions[missionID].name
          elseif useText then
            self.outText = useText
          end
        end --end active or not if
      end--end button coordinate if
    end--end button for
  else --Buying/selling screen:
    if self.actionButton and x > self.actionButton.minX and x < self.actionButton.maxX and y > self.actionButton.minY and y < self.actionButton.maxY then
      if self.screen == "Buy" then
        return self:player_buys()
      else
        return self:player_sells()
      end
    end
  end
  local list = (self.screen == "Buy" and self.selling_list or self.buying_list)
  --Item List Buttons:
  for id,listItem in ipairs(list) do
    if listItem.minY and y > listItem.minY-self.scrollY and y < listItem.maxY-self.scrollY then
      self.cursorY = id+2
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
end

function storescreen:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    local switch = self.previous or game
    Gamestate.switch(switch)
    Gamestate.update(dt)
    return
  end
  self.lineCountdown = self.lineCountdown-dt
  if self.lineCountdown <= 0 then
    self.lineCountdown = .5
    self.lineOn = not self.lineOn
  end
  local list = (self.screen == "Buy" and self.selling_list or self.buying_list)
  for id,v in ipairs(list) do
    if v.buyAmt > v.amount and (self.cursorX ~= 3 or self.cursorY ~= id+2) and v.amount ~= -1 then
      v.buyAmt = v.amount
    end
  end
  if self.cursorY == 1 and self.store.noBuy and count(self.store.offers_services) == 0 then
    self.cursorY = 2
  end
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local uiScale = (prefs['uiScale'] or 1)
    local x,y = love.mouse.getPosition()
    x,y = x/uiScale,y/uiScale
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

function storescreen:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function storescreen:player_buys()
  if self.totalCost <= player.money then
    for id,info in ipairs(self.selling_list) do
      if info.buyAmt > 0 then
        self.store:creature_buys_item(info.item,info)
        info.buyAmt = 0
      end
    end
    self:refresh_lists()
  end
end

function storescreen:player_sells()
  for id,info in ipairs(self.buying_list) do
    if info.buyAmt > 0 then
      self.store:creature_sells_item(info.item,info)
      info.buyAmt = 0
    end
    self:refresh_lists()
  end
end

function storescreen:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end --end button type if
end

function storescreen:scrollUp()
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
  end
end

function storescreen:scrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
    end
  end
end

function storescreen:get_cost_text(amt)
  if self.currency_item then
    return amt .. (self.currency_item.pluralName and " " .. self.currency_item.pluralName or " x " .. self.currency_item.name)
  else
    return get_money_name(amt)
  end
end