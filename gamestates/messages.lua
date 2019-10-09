messages = {}

function messages:enter()
  output.cursorY = 0
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
end

function messages:draw()
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  love.graphics.setFont(fonts.textFont)
  if (prefs['noImages'] ~= true) then
    --Borders for select:
    for x=32,math.floor(width/uiScale)-48,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.u,x,0)
      love.graphics.draw(images.borders.borderImg,images.borders.d,x,math.floor(height/uiScale)-32)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.u,math.floor(width/uiScale)-64,0)
    love.graphics.draw(images.borders.borderImg,images.borders.d,math.floor(width/uiScale)-64,math.floor(height/uiScale)-32)
    for y=32,math.floor(height/uiScale)-48,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.l,0,y)
      love.graphics.draw(images.borders.borderImg,images.borders.r,math.floor(width/uiScale)-32,y)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.l,0,math.floor(height/uiScale)-64)
    love.graphics.draw(images.borders.borderImg,images.borders.r,math.floor(width/uiScale)-32,math.floor(height/uiScale)-64)
    love.graphics.draw(images.borders.borderImg,images.borders.ul,0,0)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,math.floor(width/uiScale)-32,0)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,0,math.floor(height/uiScale)-32)
    love.graphics.draw(images.borders.borderImg,images.borders.lr,math.floor(width/uiScale)-32,math.floor(height/uiScale)-32)
    --Draw inner coloring:
    setColor(20,20,20,225)
    love.graphics.rectangle("fill",18,18,math.floor(width/uiScale)-32,math.floor(height/uiScale)-36)
    setColor(255,255,255,255)
  else --no images
    setColor(255,255,255,255)
    love.graphics.rectangle("line",6,6,math.floor(width/uiScale)-12,math.floor(height/uiScale)-12)
    setColor(0,0,0,225)
    love.graphics.rectangle("fill",7,7,math.floor(width/uiScale)-13,math.floor(height/uiScale)-13)
    setColor(255,255,255,255)
  end
	local cursor = math.floor(height/uiScale)-33
  local start = #output.text+output.cursorY
	for i = start, start-(math.floor(height/uiScale)/14*uiScale-2),-1 do
    if cursor < 14*uiScale then break end
		if (output.text[i] ~= nil) then
			love.graphics.print(ucfirst(output.text[i]),15,cursor)
			cursor = cursor - 14
		end
	end
  local maxLines = math.floor(((height-33)/14)/uiScale)
  if #output.text > maxLines then
    local maxScroll = #output.text-maxLines
    local scrollAmt = (maxScroll+output.cursorY)/maxScroll
    print(scrollAmt)
    messages.scrollPositions = output:scrollbar(math.floor(width/uiScale)-48,16,math.floor(height/uiScale)-(prefs['noImages'] and 24 or 16),scrollAmt,true)
  end
  self.closebutton = output:closebutton(24,24,nil,true)
  love.graphics.pop()
end

function messages:keypressed(key)
  if (key == "up" or key == keybindings.north) then
    messages:scrollUp()
  elseif (key == "down" or key == keybindings.south) then
    messages:scrollDown()
  else
    self:switchBack()
  end
end

function messages:scrollUp()
  local uiScale = (prefs['uiScale'] or 1)
  local maxLines = math.floor(((love.graphics:getHeight()-33)/14)/uiScale)
  if #output.text + output.cursorY > maxLines then
    output.cursorY = output.cursorY - 1
  end
end

function messages:scrollDown()
  if output.cursorY < 0 then output.cursorY = output.cursorY+1 end
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