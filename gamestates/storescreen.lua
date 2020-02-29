storescreen = {}

function storescreen:enter(_,whichStore)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
  output:sound('stoneslideshort',2)
  self.cursorY = 1
  self.cursorX = 1
  self.store = stores[whichStore]
  self.screen="Buy"
  self.outText = nil
  self:refresh_lists()
  self.lineCountdown = 0.5
  self.totalCost = 0
end

function storescreen:refresh_lists()
  self.buying_list = {}
  self.selling_list = {}

  for _,item in pairs(self.store:get_inventory()) do
    self.selling_list[#self.selling_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),cost=item.store_cost,amount=item.amount,buyAmt=0,item=item}
  end
  for _,ilist in pairs(self.store:get_buy_list()) do
    local item = ilist.item
    self.buying_list[#self.buying_list+1] = {name=item:get_name(true,1),description=item:get_description(),info=item:get_info(),cost=ilist.cost,amount=item.amount,buyAmt=0,item=item}
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
  local fontSize = prefs['fontSize']+2
  local windowX = math.floor(width/4/uiScale)
  local windowWidth = math.floor(width/2/uiScale)
  local midX = math.floor(width/2)
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
  
  if not self.store.noBuy then
    printY=printY+fontSize
    local padX = 8
    local buybuttonW = fonts.textFont:getWidth("Buying")+padding
    local sellbuttonW = fonts.textFont:getWidth("Selling")+padding
    local startX = windowX+math.floor(windowWidth/2)
    if self.screen == "Buy" then setColor(150,150,150,255) end
    self.buyButton = output:button(startX-math.floor(buybuttonW/2)-padX,printY,buybuttonW+padX,false,((self.cursorX == 1 and self.cursorY == 1) and "hover" or nil),"Buying")
    if self.screen == "Buy" then setColor(255,255,255,255) end
    if self.screen == "Sell" then setColor(150,150,150,255) end
    self.sellButton = output:button(startX+math.floor(buybuttonW/2)+padX,printY,sellbuttonW,false,((self.cursorX == 2 and self.cursorY == 1) and "hover" or nil),"Selling")
    if self.screen == "Sell" then setColor(255,255,255,255) end
    printY = printY+padding
  end
  printY=printY+8
  love.graphics.line(printX,printY,printX+windowWidth,printY)
  printY=printY+8
  
  --Draw the screens:
  local mouseX,mouseY = love.mouse.getPosition()
  if self.screen == "Buy" then
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
    local costlineW = fonts.textFont:getWidth("Total cost: $99999. You have $999999.")
    love.graphics.print("Total cost: $" .. self.totalCost .. ". You have $" .. player.money .. ".",math.floor(midX-costlineW/2),printY+4)
    if self.totalCost > player.money then
      setColor(100,100,100,255)
    end
    self.actionButton = output:button(math.ceil(midX+costlineW/2)+32,printY-2,buybuttonW,false,(self.cursorY == 2 and "hover" or nil),"Buy")
    if self.totalCost > player.money then
      setColor(255,255,255,255)
    end
    printY = printY+32
    self.totalCost = 0
    for id,info in ipairs(self.selling_list) do
      local selected = self.cursorY == id+2
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
      love.graphics.print("$" .. info.cost,priceX,buyTextY)
      --Minus buttoN:
      --function output:button(x,y,width,small,special,text,useScaling)
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
      --Display description if necessary:
      if (selected and self.cursorX == 1) or (mouseX > nameX and mouseX < priceX and mouseY > info.minY and mouseY < info.maxY) then
        local text = info.item:get_name(true,1) .. "\n" .. info.item:get_description() .. "\n" .. info.item:get_info(true)
        self:description_box(text,nameX+yPad,buyTextY)
      end
      printY = printY+fontSize+16
      self.totalCost = self.totalCost + (info.buyAmt*info.cost)
    end
  elseif self.screen == "Sell" then
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
    local costlineW = fonts.textFont:getWidth("You will receive: $99999.")
    love.graphics.print("You will receive: $" .. self.totalCost .. ".",math.floor(midX-costlineW/2),printY+4)

    self.actionButton = output:button(math.ceil(midX+costlineW/2)+32,printY-2,sellbuttonW,false,(self.cursorY == 2 and "hover" or nil),"Sell")
    printY = printY+32
    self.totalCost = 0
    for id,info in ipairs(self.buying_list) do
      local selected = self.cursorY == id+2
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
      love.graphics.print("$" .. info.cost,priceX,sellTextY)
      --Minus buttoN:
      --function output:button(x,y,width,small,special,text,useScaling)
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
      self.totalCost = self.totalCost + (info.buyAmt*info.cost)
    end
  end

  self.closebutton = output:closebutton(windowX+24,24,nil,true)
  love.graphics.pop()
end

function storescreen:keypressed(key)
  if key == "escape" then
    self:switchBack()
  elseif (key == "return" or key == "kpenter") then
    if self.cursorY == 1 and not self.noBuy then --buttons
      if self.cursorX == 1 then
        self.screen = "Buy"
        self.cursorY = 2
      else
        self.screen = "Sell"
        self.cursorY = 2
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
      if self.cursorX == 1 then --item name
        self.cursorX = 2
      elseif self.cursorX == 2 and self.cursorY > 2 then --minus button
        list[id].buyAmt = math.max(list[id].buyAmt-1,0)
      elseif self.cursorX == 3 then --number entry
        self.cursorX = 5
      elseif self.cursorX == 4 then --plus button
        list[id].buyAmt = (list[id].amount ~= -1 and math.min(list[id].buyAmt+1,list[id].amount) or list[id].buyAmt+1)
      end
    end --end cursorY tests within return
  elseif key == "left" then
    if self.cursorY == 1 and not self.noBuy then --looping if on the nav buttons
      self.cursorX = 1
    else
      self.cursorX = math.max(1,self.cursorX-1)
    end
  elseif key == "right" then
    if self.cursorY == 1 and not self.noBuy then --looping if on the nav buttons
      self.cursorX = 2
    else
      self.cursorX = math.min(self.cursorX+1,4)
    end
  elseif key == "up" then
    if self.cursorY > 1 then
      self.cursorY = self.cursorY - 1
      self.cursorX = 1
    end --end cursorY check
  elseif key == "down" then
    local max = (self.screen == "Buy" and #self.selling_list+2 or #self.buying_list+2)
    if self.cursorY < max then
      self.cursorY = self.cursorY + 1
      self.cursorX = 1
    end
  elseif tonumber(key) and self.cursorX == 3 then
    local id = self.cursorY-2
    local list = (self.screen == "Buy" and self.selling_list or self.buying_list)
    if string.len(tostring(list[id].buyAmt or "")) < 3 then
      if list[id].buyAmt == 0 then
        list[id].buyAmt = tonumber(key)
      else
        local newAmt = (list[id].buyAmt or "").. key
        list[id].buyAmt = tonumber(newAmt)
      end
    end
  elseif (key == "backspace") and self.cursorX == 3 then
    local id = self.cursorY-2
    local list = (self.screen == "Buy" and self.selling_list or self.buying_list)
    local amt = tostring(list[id].buyAmt)
    local newAmt = tonumber(string.sub(amt,1,#amt-1))
    list[id].buyAmt = (newAmt or 0)
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
    self.cursorY = 2
  elseif self.sellButton and x > self.sellButton.minX and x < self.sellButton.maxX and y > self.sellButton.minY and y < self.sellButton.maxY then
    self.screen = "Sell"
    self.cursorY = 2
  elseif x > self.actionButton.minX and x < self.actionButton.maxX and y > self.actionButton.minY and y < self.actionButton.maxY then
    if self.screen == "Buy" then
      return self:player_buys()
    else
      return self:player_sells()
    end
  end
  local list = (self.screen == "Buy" and self.selling_list or self.buying_list)
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
end

function storescreen:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
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
  if self.cursorY == 1 and self.noBuy then
    self.cursorY = 2
  end
end

function storescreen:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function storescreen:description_box(text,x,y)
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

function storescreen:player_buys()
  if self.totalCost <= player.money then
    for id,info in ipairs(self.selling_list) do
      if info.buyAmt > 0 then
        self.store:creature_buys_item(info.item,info.buyAmt,player)
        info.buyAmt = 0
      end
    end
  end
  self:refresh_lists()
end

function storescreen:player_sells()
  for id,info in ipairs(self.buying_list) do
    if info.buyAmt > 0 then
      self.store:creature_sells_item(info.item,info.buyAmt,info.cost,player)
      info.buyAmt = 0
    end
  end
  self:refresh_lists()
end