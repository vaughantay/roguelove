help = {}

function help:enter(previous)
  self.previous = previous
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.scroll=0
  self.finalY=0
end

function help:draw()
  self.previous:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width,height = round(width/uiScale),round(height/uiScale)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']
  output:draw_window(1,1,width-padding,height-padding)
  love.graphics.setFont(fonts.textFont)
	love.graphics.printf("How to Play",padding,padding,width-padding,"center")
  local printY = padding+fontSize*2
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",padding,printY,width-padding,height-padding-printY)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scroll)
  local helpText = [[Insert text here]]
	love.graphics.printf(helpText,padding,printY,width-padding*3)
  love.graphics.setStencilTest()
  love.graphics.pop() --scrolling pop

  --Scrollbar:
  local _,tlines = fonts.textFont:getWrap(helpText,width-padding*3)
  local finalY = printY+#tlines*prefs['fontSize']
  if finalY > height-padding then
    self.finalY = finalY-math.floor(height/2)
    local scrollAmt = self.scroll/self.finalY
    self.scrollPositions = output:scrollbar(width-padding*2,padding,height-padding,scrollAmt,true)
  end

  self.closebutton = output:closebutton(24,24,nil,true)
  love.graphics.pop() -- window moving up screen pop
end

function help:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
  end
  
  local uiScale = prefs['uiScale'] or 1
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local x,y = love.mouse.getPosition()
    x,y = round(x/uiScale),round(y/uiScale)
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

function help:buttonpressed(key)
  key = input:parse_key(key)
  if key == "escape" or key == "enter" or key == "wait" then
    self:switchBack()
  elseif key == "south" then
    self:scrollDown()
  elseif key == "north" then
    self:scrollUp()
  end
end

function help:mousepressed(x,y,button)
  local uiScale = prefs['uiScale'] or 1
  x,y = round(x/uiScale),round(y/uiScale)
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then self:switchBack() end
end

function help:wheelmoved(x,y)
	if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end --end button type if
end --end mousepressed if

function help:scrollUp()
  if self.scroll > 0 then
    self.scroll = math.max(self.scroll - prefs.fontSize,0)
  end
end

function help:scrollDown()
  if self.scroll+prefs.fontSize < self.finalY then self.scroll = self.scroll+prefs.fontSize end
end

function help:switchBack()
  tween(0.2,self,{yModPerc=100})
  Timer.after(0.2,function() self.switchNow=true end)
  output:sound('stoneslideshortbackwards',2)
end