nameitem = {}

function nameitem:enter(previous,nameItem)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=75})
  output:sound('stoneslideshort',2)
  self.previous = previous
  self.nameItem = nameItem
  self.lineCountdown= .5
  self.name = nameItem.properName or ""
  self.cursorY = 1
end

function nameitem:draw()
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
  local nameItem = self.nameItem
  local properName = nameItem.properName
  local name = nameItem.name
  local hktext = (properName and "Rename " .. properName .. ":" or "Name your " .. name .. ":")
  local wrapL = math.ceil(width/uiScale/2)-padding
  local _,tlines = fonts.textFont:getWrap(hktext,wrapL)
  local _,nameLines = fonts.textFont:getWrap(self.name,wrapL-padding)
  --Window size stuff
  local startX = math.ceil(width/uiScale/4)
  local endX=math.ceil(startX+width/uiScale/2)
  local midX = round((startX+endX)/2)
  local windowHeight = fontSize*(#tlines+math.max(#nameLines,1)+3)+padding
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
  local nameBoxW = self.width-padding*2
  local nameBoxX = self.x+padding
  local nameBoxY = round(printY+fontSize*(#tlines+1))
  local nameBoxH = fontSize*math.max(#nameLines,1)+6
  
  --Name box:
  self.nameBox = {minX=nameBoxX,minY=nameBoxY-2,maxX=nameBoxX+nameBoxW,maxY=nameBoxY+nameBoxH}
  if self.cursorY == 1 or (mouseX > self.nameBox.minX and mouseX < self.nameBox.maxX and mouseY > self.nameBox.minY and mouseY < self.nameBox.maxY) then
    setColor(75,75,75,255)
    love.graphics.rectangle('fill',self.nameBox.minX,self.nameBox.minY,nameBoxW,nameBoxH)
    setColor(255,255,255,255)
    if self.lineOn and self.cursorY == 1 then
      local w = fonts.textFont:getWidth(nameLines[#nameLines] or " ")
      local lineX = nameBoxX+w
      love.graphics.line(lineX,self.nameBox.maxY-fontSize-5,lineX,self.nameBox.maxY-5)
    end
  end
  love.graphics.rectangle('line',self.nameBox.minX,self.nameBox.minY,nameBoxW,nameBoxH)
  love.graphics.printf(self.name,nameBoxX,nameBoxY,nameBoxW)
  
  --Rename button:
  local buttonText = (self.name == "" and "Remove Name" or "Bestow Name")
  local w = fonts.buttonFont:getWidth(buttonText)+25
  self.nameButton = output:button(round(midX-w/2),nameBoxY+nameBoxH+fontSize,w,nil,(self.cursorY == 2 and "hover" or nil),buttonText,true)
  
  self.closebutton = output:closebutton(startX+8,startY+8,nil,true)
  love.graphics.pop()
end

function nameitem:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
  end
  self.lineCountdown = self.lineCountdown-dt
  if self.lineCountdown <= 0 then
    self.lineCountdown = .5
    self.lineOn = not self.lineOn
  end
end

function nameitem:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function nameitem:textinput(text)
  if self.cursorY == 1 then
    self.name = self.name .. text
  end
end

function nameitem:buttonpressed(key,scancode,isRepeat,controllerType)
  --Text entry
  if key == "backspace" and self.cursorY == 1 then
    self.name = string.sub(self.name,1,#self.name-1)
    return
  end
  --Parse keys to look at commands:
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if key == "escape" then
    self:switchBack()
  elseif key == "south" then
    self.cursorY = 2
  elseif key == "north" then
    self.cursorY = 1
  elseif key == "enter" then
    if self.cursorY == 1 then --selection buttons
      self.cursorY = 2
    elseif self.cursorY == 2 then
      if self.name == "" then
        self.nameItem.properName = nil
      else
        self.nameItem.properName = self.name
      end
      self:switchBack()
    end
  end
end

function nameitem:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  local padding = prefs['noImages'] and 16 or 32
  x,y = round(x/uiScale),round(y/uiScale)
  if (x > self.nameBox.minX and x < self.nameBox.maxX and y > self.nameBox.minY and y < self.nameBox.maxY) then
    self.cursorY = 1
  elseif (x > self.nameButton.minX and x < self.nameButton.maxX and y > self.nameButton.minY and y < self.nameButton.maxY) then
    if self.name == "" then
      self.nameItem.properName = nil
    else
      self.nameItem.properName = self.name
    end
    self:switchBack()
  end
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) or (x < self.x or x > self.x+self.width or y < self.y or y > self.y+self.height+padding) then
    self:switchBack()
  end
end