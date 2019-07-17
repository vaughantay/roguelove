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
  love.graphics.push()
  love.graphics.translate(0,height*(self.yModPerc/100))
  love.graphics.setFont(fonts.textFont)
  if (prefs['noImages'] ~= true) then
    --Borders for select:
    for x=32,width-48,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.u,x,0)
      love.graphics.draw(images.borders.borderImg,images.borders.d,x,height-32)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.u,width-64,0)
    love.graphics.draw(images.borders.borderImg,images.borders.d,width-64,height-32)
    for y=32,height-48,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.l,0,y)
      love.graphics.draw(images.borders.borderImg,images.borders.r,width-32,y)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.l,0,height-64)
    love.graphics.draw(images.borders.borderImg,images.borders.r,width-32,height-64)
    love.graphics.draw(images.borders.borderImg,images.borders.ul,0,0)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,width-32,0)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,0,height-32)
    love.graphics.draw(images.borders.borderImg,images.borders.lr,width-32,height-32)
    --Draw inner coloring:
    setColor(20,20,20,225)
    love.graphics.rectangle("fill",18,18,width-32,height-36)
    setColor(255,255,255,255)
  else --no images
    setColor(255,255,255,255)
    love.graphics.rectangle("line",6,6,width-12,height-12)
    setColor(0,0,0,225)
    love.graphics.rectangle("fill",7,7,width-13,height-13)
    setColor(255,255,255,255)
  end
	local cursor = height-33
  local start = #output.text+output.cursorY
	for i = start, start-(height/14-2),-1 do
    if cursor < 14 then break end
		if (output.text[i] ~= nil) then
			love.graphics.print(ucfirst(output.text[i]),15,cursor)
			cursor = cursor - 14
		end
	end
  local maxLines = math.floor((height-33)/14)
  if #output.text > maxLines then
    local maxScroll = #output.text-maxLines
    local scrollAmt = (maxScroll+output.cursorY)/maxScroll
    messages.scrollPositions = output:scrollbar(width-48,16,height-(prefs['noImages'] and 24 or 16),scrollAmt)
  end
  self.closebutton = output:closebutton(24,24)
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
  local maxLines = math.floor((love.graphics:getHeight()-33)/14)
  if #output.text + output.cursorY > maxLines then
    output.cursorY = output.cursorY - 1
  end
end

function messages:scrollDown()
  if output.cursorY < 0 then output.cursorY = output.cursorY+1 end
end

function messages:mousepressed(x,y,button)
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
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