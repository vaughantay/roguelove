pronoun_entry = {}

function pronoun_entry:enter()
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=75})
  output:sound('stoneslideshort',2)
  self.cursorY = 1
  self.lineOn = true
  self.lineCountdown=.5
  self.pronouns = newgame.player.pronouns and {n=newgame.player.pronouns.n,o=newgame.player.pronouns.o,p=newgame.player.pronouns.p} or {n="he",o="them",p="her"}
  self.boxes={n={startX=0,startY=0,endX=0,endY=0},o={startX=0,startY=0,endX=0,endY=0},p={startX=0,startY=0,endX=0,endY=0}}
  self.height=250
end

function pronoun_entry:draw()
  newgame:draw()
  love.graphics.setFont(fonts.textFont)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local midY = math.floor(height/2/uiScale)
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle("fill",0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']
  local startX = math.ceil(width/uiScale/4)
  local startY = padding*2
  local wrapL = math.ceil(width/uiScale/2)-padding
  local endX=math.ceil(startX+width/uiScale/2)
  local endY = startY+self.height
  output:draw_window(startX,startY,endX,endY)
  local printY = startY + padding
  local printX = startX + padding
  local x,y = love.mouse.getPosition()
  x,y = x/uiScale, y/uiScale
  love.graphics.printf("Subject (eg he/she/they):",printX,printY,wrapL)
  local _,tlines = fonts.textFont:getWrap("Subject (eg he/she/they):",wrapL)
  printY = printY + round(fontSize*#tlines*1.25)
  if self.cursorY == 1 then
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",printX,printY,wrapL,fontSize+1)
    setColor(255,255,255,255)
    if self.lineOn then
      local w = fonts.textFont:getWidth(self.pronouns.n)
      local lineX = printX+w+2
      love.graphics.line(lineX,printY+3,lineX,printY+fontSize-2)
    end
  elseif x > self.boxes.n.startX and x < self.boxes.n.endX and y > self.boxes.n.startY and y < self.boxes.n.endY then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",printX,printY,wrapL,fontSize+1)
    setColor(255,255,255,255)
  end
  love.graphics.print(self.pronouns.n,printX,printY)
  love.graphics.rectangle("line",printX,printY,wrapL,fontSize+1)
  self.boxes.n = {startX=printX,startY=printY,endX=printX+wrapL,endY=printY+fontSize+1}
  printY = printY+round(fontSize*1.5)
  love.graphics.printf("Object (eg him/her/them):",printX,printY,wrapL)
  _,tlines = fonts.textFont:getWrap("Object (eg him/her/them):",wrapL)
  printY = printY + round(fontSize*#tlines*1.25)
  if self.cursorY == 2 then
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",printX,printY,wrapL,fontSize+1)
    setColor(255,255,255,255)
    if self.lineOn then
      local w = fonts.textFont:getWidth(self.pronouns.o)
      local lineX = printX+w+2
      love.graphics.line(lineX,printY+3,lineX,printY+fontSize-2)
    end
  elseif x > self.boxes.o.startX and x < self.boxes.o.endX and y > self.boxes.o.startY and y < self.boxes.o.endY then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",printX,printY,wrapL,fontSize+1)
    setColor(255,255,255,255)
  end
  love.graphics.print(self.pronouns.o,printX,printY)
  love.graphics.rectangle("line",printX,printY,wrapL,fontSize+1)
  self.boxes.o = {startX=printX,startY=printY,endX=printX+wrapL,endY=printY+fontSize+1}
  printY = printY+round(fontSize*1.5)
  love.graphics.printf("Possessive (eg his/her/their):",printX,printY,wrapL)
  _,tlines = fonts.textFont:getWrap("Possessive (eg his/her/their):",wrapL)
  printY = printY + round(fontSize*#tlines*1.25)
  if self.cursorY == 3 then
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",printX,printY,wrapL,fontSize+1)
    setColor(255,255,255,255)
    if self.lineOn then
      local w = fonts.textFont:getWidth(self.pronouns.p)
      local lineX = printX+w+2
      love.graphics.line(lineX,printY+3,lineX,printY+fontSize-2)
    end
  elseif x > self.boxes.p.startX and x < self.boxes.p.endX and y > self.boxes.p.startY and y < self.boxes.p.endY then
    setColor(100,100,100,125)
    love.graphics.rectangle("fill",printX,printY,wrapL,fontSize+1)
    setColor(255,255,255,255)
  end
  love.graphics.print(self.pronouns.p,printX,printY)
  love.graphics.rectangle("line",printX,printY,wrapL,fontSize+1)
  self.boxes.p = {startX=printX,startY=printY,endX=printX+wrapL,endY=printY+fontSize+1}
  printY = printY+round(fontSize*1.5)
  self.height=printY-startY
  self.closebutton = output:closebutton(startX+8,startY+8,nil,true)
  love.graphics.pop()
end

function pronoun_entry:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(newgame)
    Gamestate.update(dt)
  end
  local uiScale = (prefs['uiScale'] or 1)
  local x,y = love.mouse.getPosition()
	if (y ~= self.mouseY or x ~= self.mouseX) then -- only do this if the mouse has moved
		self.mouseY = y
    self.mouseX = x
    x,y = x/uiScale,y/uiScale
  end
  self.lineCountdown = self.lineCountdown-dt
  if self.lineCountdown <= 0 then
    self.lineCountdown = .5
    self.lineOn = not self.lineOn
  end
end

function pronoun_entry:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
  newgame.player.pronouns = self.pronouns
end

function pronoun_entry:buttonpressed(key,scancode,isRepeat,controllerType)
  local origKey = key
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if (origKey == "escape") then
    self:switchBack()
  elseif key == "south" or origKey == "tab" or key == "nextTarget" then
    self.cursorY = self.cursorY+1
    if self.cursorY > 3 then self.cursorY = 1 end
  elseif key == "north" then
    self.cursorY = self.cursorY-1
    if self.cursorY < 1 then self.cursorY = 3 end
  elseif key == "enter" then
    self.cursorY = self.cursorY + 1
    if self.cursorY > 3 then
      self:switchBack()
    end
  elseif origKey == "backspace" then
    if self.cursorY == 1 then
      self.pronouns.n = string.sub(self.pronouns.n,1,#self.pronouns.n-1)
    elseif self.cursorY == 2 then
      self.pronouns.o = string.sub(self.pronouns.o,1,#self.pronouns.o-1)
    elseif self.cursorY == 3 then
      self.pronouns.p = string.sub(self.pronouns.p,1,#self.pronouns.p-1)
    end
  end
end

function pronoun_entry:textinput(text)
  if self.cursorY == 1 then
    self.pronouns.n = self.pronouns.n .. text
  elseif self.cursorY == 2 then
    self.pronouns.o = self.pronouns.o .. text
  elseif self.cursorY == 3 then
    self.pronouns.p = self.pronouns.p .. text
  end
end

function pronoun_entry:mousepressed(x,y,button)
  local width = love.graphics.getWidth()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale,y/uiScale
  if x > self.boxes.n.startX and x < self.boxes.n.endX and y > self.boxes.n.startY and y < self.boxes.n.endY then
    self.cursorY = 1
  elseif x > self.boxes.o.startX and x < self.boxes.o.endX and y > self.boxes.o.startY and y < self.boxes.o.endY then
    self.cursorY = 2
  elseif x > self.boxes.p.startX and x < self.boxes.p.endX and y > self.boxes.p.startY and y < self.boxes.p.endY then
    self.cursorY = 3
  elseif button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) or x < math.ceil(width/4) or x > math.ceil(width/4+width/2) then 
    self:switchBack()
  end
end