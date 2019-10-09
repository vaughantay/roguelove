pausemenu = {}

function pausemenu:enter(previous)
  if previous == game then
    self.cursorY=1
    love.graphics.captureScreenshot( function(img) pausemenu.screenshot = img end )
    self.yModPerc = 100
    self.blackScreenAlpha=0
    tween(0.2,self,{yModPerc=0,blackScreenAlpha=75})
    output:sound('stoneslideshort',2)
  end
end

function pausemenu:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  game:draw()
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle('fill',0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local startX=math.floor((width/2)/uiScale-100)
  local startY=math.floor((height/2)/uiScale-140)
  --[[if prefs['noImages'] ~= true then
    for x=startX+16,startX+166,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.u,x,startY-16)
      love.graphics.draw(images.borders.borderImg,images.borders.d,x,startY+240)
    end
    for y=startY+16,startY+224,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.l,startX,y)
      love.graphics.draw(images.borders.borderImg,images.borders.r,startX+182,y)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.u,startX+150,startY-16)
    love.graphics.draw(images.borders.borderImg,images.borders.d,startX+150,startY+240)
    love.graphics.draw(images.borders.borderImg,images.borders.ul,startX,startY-16)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,startX+182,startY-16)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,startX,startY+240)
    love.graphics.draw(images.borders.borderImg,images.borders.lr,startX+182,startY+240)
  else
    love.graphics.rectangle("line",self.x,self.y,200,112) -- warning outline
  end]]
  output:draw_window(startX,startY,startX+166+(prefs['noImages'] and 16 or 0),startY+244+(prefs['noImages'] and 16 or 0))
  love.graphics.setFont(fonts.graveFontSmall)
  self.buttons = {}
  local buttonY,buttonAdd = startY+26,48
  self.buttons[#self.buttons+1] = output:button(startX+25,buttonY,150,nil,(self.cursorY == 1 and "hover" or "image"))
  love.graphics.printf("Resume",startX+25,buttonY,150,"center")
  --("Resume")
  buttonY=buttonY+buttonAdd
  self.buttons[#self.buttons+1] = output:button(startX+25,buttonY,150,nil,(self.cursorY == 2 and "hover" or "image"))
  love.graphics.printf("Help",startX+25,buttonY,150,"center")
  --output:button("How to Play")
  buttonY=buttonY+buttonAdd
  self.buttons[#self.buttons+1] = output:button(startX+25,buttonY,150,nil,(self.cursorY == 3 and "hover" or "image"))
  love.graphics.printf("Monsterpedia",startX+25,buttonY,150,"center")
  --output:button("Monsterpedia")
  buttonY=buttonY+buttonAdd
  self.buttons[#self.buttons+1] = output:button(startX+25,buttonY,150,nil,(self.cursorY == 4 and "hover" or "image"))
  love.graphics.printf("Settings",startX+25,buttonY,150,"center")
  --output:button("Settings")
  buttonY=buttonY+buttonAdd
  self.buttons[#self.buttons+1] = output:button(startX+25,buttonY,150,nil,(self.cursorY == 5 and "hover" or "image"))
  love.graphics.printf("Save and Exit",startX+25,buttonY,150,"center")
  --output:button("Exit to Menu")
  love.graphics:pop()
end

function pausemenu:keypressed(key,isRepeat)
  if key == "escape" then
    self:switchBack()
  elseif key == "up" then
    self.cursorY = (self.cursorY == 1 and 5 or self.cursorY-1)
  elseif key == "down" then
    self.cursorY = (self.cursorY == 5 and 1 or self.cursorY+1)
  elseif key == "return" or key == "kpenter" then
    self:mousepressed(1,1,1)
  end --end key if
end

function pausemenu:update(dt)
    if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
  local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
	if (x ~= output.mouseX or y ~= output.mouseY) then -- only do this if the mouse has moved
		output.mouseX,output.mouseY = x,y
    self.cursorY = 0
    if self.buttons then
      for bid,button in pairs(self.buttons) do
        if x/uiScale > button.minX and x/uiScale < button.maxX and y/uiScale > button.minY and y/uiScale < button.maxY then
          self.cursorY = bid
        end
      end --end button for
    end --end if buttons
	end --end if mouse moved
end

function pausemenu:mousepressed(x,y,button)
  if button == 2 then
    self:switchBack()
  end
  if self.cursorY == 1 then
    self:switchBack()
  elseif self.cursorY == 2 then
    Gamestate.switch(help)
  elseif self.cursorY == 3 then
    output:setCursor(0,0)
    Gamestate.switch(monsterpedia)
  elseif self.cursorY == 4 then
    output:setCursor(0,0)
    Gamestate.switch(settings)
  elseif self.cursorY == 5 then
    save_game(self.screenshot)
    Gamestate.switch(menu)
  end
end

function pausemenu:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  Timer.after(0.2,function() self.switchNow=true end)
  output:sound('stoneslideshortbackwards',2)
end