messages = {}

function messages:enter()
  self.cursorY = 0
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.smallestY=0
end

function messages:draw()
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width, height = round(width/uiScale), round(height/uiScale)
  local tileSize = output:get_tile_size()
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  love.graphics.setFont(fonts.textFont)
  local startX,startY,windowW,windowH = 1,1,math.min(550,width-tileSize),height-tileSize
  startX = round(width/2-windowW/2-tileSize/2)
  output:draw_window(startX,startY,startX+windowW,startY+windowH)
  local fontSize = prefs['fontSize']
	local cursor = height-fontSize
  local textWidth = windowW-tileSize*2
  local printX = startX+tileSize
  
  --Drawing the text:
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",round(startX+tileSize/2),round(startY+tileSize/2),windowW,windowH)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.cursorY)
	for i = #output.text,1,-1 do
    local _, tlines = fonts.textFont:getWrap(ucfirst(output.text[i]),textWidth)
    cursor = cursor - math.floor(#tlines*(fontSize*1.25))
    love.graphics.printf(ucfirst(output.text[i]),printX,cursor,textWidth,"left")
	end
  love.graphics.setStencilTest()
  love.graphics.pop()
  
  self.smallestY = cursor-math.floor(fontSize/2)
  if self.smallestY < 1 then
    local scrollAmt = (self.smallestY-self.cursorY)/self.smallestY
    self.scrollPositions = output:scrollbar(startX+windowW-tileSize,tileSize,height-tileSize,scrollAmt,true)
  end
  self.closebutton = output:closebutton(startX+18,startY+18,nil,true)
  love.graphics.pop()
end

function messages:buttonpressed(key,scancode,isRepeat,controllerType)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if (key == "north") then
    messages:scrollUp()
  elseif (key == "south") then
    messages:scrollDown()
  else
    self:switchBack()
  end
end

function messages:scrollUp()
  if self.cursorY > self.smallestY then
    self.cursorY = math.max(self.cursorY - prefs.fontSize,self.smallestY)
  end
end

function messages:scrollDown()
  if self.cursorY < 0 then self.cursorY = math.min(self.cursorY+prefs.fontSize,0) end
end

function messages:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) then
    self:switchBack()
  end
end

function messages:wheelmoved(x,y)
	if y > 0 then
    messages:scrollUp()
	elseif y < 0 then
    messages:scrollDown()
  end --end button type if
end --end mousepressed if

function messages:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
  if (love.mouse.isDown(1)) and messages.scrollPositions then
    local x,y = love.mouse.getPosition()
    local upArrow = messages.scrollPositions.upArrow
    local downArrow = messages.scrollPositions.downArrow
    local elevator = messages.scrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      messages:scrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      messages:scrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then messages:scrollUp()
      elseif y>elevator.endY then messages:scrollDown() end
    end --end clicking on arrow
  end
end

function messages:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end