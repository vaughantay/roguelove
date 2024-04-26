splitstack = {}

function splitstack:enter(previous,splitItem)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=75})
  output:sound('stoneslideshort',2)
  self.previous = previous
  self.splitItem = splitItem
  self.stackAmt=0
  self.cursorX = 2
  self.cursorY = 1
  self.lineCountdown= .5
end

function splitstack:draw()
  self.previous:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY=mouseX/uiScale,mouseY/uiScale
  local midY = math.floor(height/2/uiScale)
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle("fill",0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']
  local splitItem = self.splitItem
  local name = (splitItem.baseType == "item" and splitItem:get_name(true) or self.splitItem.name)
  local hktext = "Split off new stack from " .. name .. ":"
  local wrapL = math.ceil(width/uiScale/2)-padding
  local _,tlines = fonts.textFont:getWrap(hktext,wrapL)
  --Window size stuff
  local startX = math.ceil(width/uiScale/4)
  local endX=math.ceil(startX+width/uiScale/2)
  local midX = round((startX+endX)/2)
  local windowHeight = round(fontSize*#tlines*5)+padding
  local startY = round(midY-windowHeight/2)
  local endY = startY+windowHeight
  self.x = startX
  self.width = endX-startX
  self.y = startY
  self.height = endY-startY
  output:draw_window(startX,startY,endX,endY)
  local printY = startY + padding
  local printX = startX + padding
  love.graphics.printf(hktext,printX,printY,wrapL,"center")
  local numberBoxW = fonts.textFont:getWidth("1000")+8
  local numberBoxX = round(midX-numberBoxW/2)
  local numberBoxY = round(printY+(fontSize*#tlines*1.5))
  
  --Minus button:
  local minusMouse = false
  if self.minusButton and mouseX > self.minusButton.minX and mouseX < self.minusButton.maxX and mouseY > self.minusButton.minY and mouseY < self.minusButton.maxY then
    minusMouse = true
  end
  if self.stackAmt < 1 then
    setColor(100,100,100,255)
  end
  self.minusButton = output:tinybutton(numberBoxX-48,numberBoxY-4,nil,((minusMouse or (self.cursorY == 1 and self.cursorX == 1)) and "hover" or false),"-")
  if self.stackAmt < 1 then
    setColor(255,255,255,255)
  end
  --Handle the item amount box:
  self.numberEntry = {minX=numberBoxX,minY=numberBoxY-2,maxX=numberBoxX+numberBoxW,maxY=numberBoxY-2+fontSize+4}
  local amountMouse = (mouseX > self.numberEntry.minX and mouseX < self.numberEntry.maxX and mouseY > self.numberEntry.minY and mouseY < self.numberEntry.maxY)
  if (self.cursorY == 1 and self.cursorX == 2) or amountMouse then
    setColor(75,75,75,255)
    love.graphics.rectangle('fill',self.numberEntry.minX,self.numberEntry.minY,numberBoxW,fontSize+4)
    setColor(255,255,255,255)
    if self.lineOn and self.cursorX == 2 then
      local w = fonts.textFont:getWidth(tostring(self.stackAmt))
      local lineX = numberBoxX+math.ceil(numberBoxW/2+w/2)
      love.graphics.line(lineX,numberBoxY,lineX,numberBoxY+fontSize)
    end
  end
  love.graphics.rectangle('line',self.numberEntry.minX,self.numberEntry.minY,numberBoxW,fontSize+4)
  love.graphics.printf(self.stackAmt,numberBoxX,numberBoxY,numberBoxW,"center")
  --Plus Button:
  local plusMouse = false
  if self.plusButton and mouseX > self.plusButton.minX and mouseX < self.plusButton.maxX and mouseY > self.plusButton.minY and mouseY < self.plusButton.maxY then
    plusMouse = true
  end
  if self.stackAmt == self.splitItem.amount-1 then
    setColor(100,100,100,255)
  end
  self.plusButton = output:tinybutton(numberBoxX+numberBoxW+16,numberBoxY-4,nil,((plusMouse or (self.cursorY == 1 and self.cursorX == 3)) and "hover" or false),"+")
  if self.stackAmt == self.splitItem.amount-1 then
    setColor(255,255,255,255)
  end
  
  --Split button:
  local w = fonts.buttonFont:getWidth("Split Stack")+25
  if self.stackAmt < 1 then
    setColor(100,100,100,255)
  end
  self.splitButton = output:button(round(midX-w/2),numberBoxY+fontSize*2,w,nil,(self.cursorY == 2 and "hover" or nil),"Split Stack",true)
  if self.stackAmt < 1 then
    setColor(255,255,255,255)
  end
  self.closebutton = output:closebutton(startX+8,startY+8,nil,true)
  love.graphics.pop()
end

function splitstack:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
  end
  if not self.stackAmt or self.stackAmt < 0 then self.stackAmt = 0 end
  if self.stackAmt > self.splitItem.amount-1 then self.stackAmt = self.splitItem.amount-1 end
  self.lineCountdown = self.lineCountdown-dt
  if self.lineCountdown <= 0 then
    self.lineCountdown = .5
    self.lineOn = not self.lineOn
  end
end

function splitstack:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function splitstack:buttonpressed(key,scancode,isRepeat,controllerType)
  --First, look at number keys and backspace, to manipulate the number amount directly
  local stackAmt = tostring(self.stackAmt)
  if tonumber(key) then
    self.cursorX,self.cursorY = 2,1
    if not stackAmt or stackAmt == 0 or stackAmt == "0" then
      self.stackAmt = tonumber(key)
      return
    else
      local newAmt = tonumber(stackAmt .. key)
      self.stackAmt = newAmt
      return
    end
  elseif key == "backspace" then
    local newAmt = tonumber(string.sub(stackAmt,1,#stackAmt-1))
    self.stackAmt = (newAmt or 0)
    return
  end
  --Parse keys to look at commands:
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if key == "escape" then
    self:switchBack()
  elseif key == "east" then
    self.cursorX = math.min(3,self.cursorX+1)
  elseif key == "west" then
    self.cursorX = math.max(1,self.cursorX-1)
  elseif key == "south" then
    self.cursorY = 2
  elseif key == "north" then
    self.cursorY = 1
  elseif key == "enter" or key == "wait" then
    if self.cursorY == 1 then --selection buttons
      if self.cursorX == 1 then self.stackAmt = self.stackAmt-1
      elseif self.cursorX == 2 then self.cursorY = 2
      elseif self.cursorX == 3 then self.stackAmt = self.stackAmt+1 end
    elseif self.cursorY == 2 and self.stackAmt > 0 then
      self:switchBack()
      inventory:splitStack(self.splitItem,self.stackAmt)
      inventory:sort()
    end
  end
end

function splitstack:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  local padding = prefs['noImages'] and 16 or 32
  x,y = round(x/uiScale),round(y/uiScale)
  if (x > self.minusButton.minX and x < self.minusButton.maxX and y > self.minusButton.minY and y < self.minusButton.maxY) then
    self.stackAmt = self.stackAmt - 1
  elseif (x > self.plusButton.minX and x < self.plusButton.maxX and y > self.plusButton.minY and y < self.plusButton.maxY) then
    self.stackAmt = self.stackAmt + 1
  elseif (x > self.numberEntry.minX and x < self.numberEntry.maxX and y > self.numberEntry.minY and y < self.numberEntry.maxY) then
    self.cursorX,self.cursorY = 2,1
  elseif self.stackAmt > 0 and (x > self.splitButton.minX and x < self.splitButton.maxX and y > self.splitButton.minY and y < self.splitButton.maxY) then
    self:switchBack()
    inventory:splitStack(self.splitItem,self.stackAmt)
    inventory:sort()
  end
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) or (x < self.x or x > self.x+self.width or y < self.y or y > self.y+self.height+padding) then
    self:switchBack()
  end
end