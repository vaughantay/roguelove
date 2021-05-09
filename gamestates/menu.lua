menu = {whiteAlpha=0}

function menu:enter()
  output:play_playlist('menu')
  self.cursorY = 1
end

function menu:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  setColor(255,255,255,255)
	love.graphics.setFont(fonts.graveFontBig)
	love.graphics.printf("Roguelove Example Game",14,96,width-28,"center")
	love.graphics.setFont(fonts.graveFontSmall)
	love.graphics.setFont(fonts.graveFontBig)
  local spacing = 40
  if (self.cursorY >= 1 and self.cursorY <= 8) and Gamestate.current() == menu then
		setColor(100,100,100,255)
		love.graphics.rectangle("fill",width/2-256+80,(self.cursorY*spacing+127),512-161,45)
	end
  setColor(255,255,255)
  --output:largebutton(math.floor(width/2-256+80),200,512-161)
  local printY = 170
  love.graphics.printf("Start a New Game",14,printY,width-28,"center")
  printY = printY + spacing
	love.graphics.printf("Load a Saved Game",14,printY,width-28,"center")
  printY = printY + spacing
	love.graphics.printf("How to Play",14,printY,width-28,"center")
  printY = printY + spacing
	love.graphics.printf("Stats and Records",14,printY,width-28,"center")
  printY = printY + spacing
	love.graphics.printf("Monsterpedia",14,printY,width-28,"center")
  printY = printY + spacing
  love.graphics.printf("Settings & Controls",14,printY,width-28,"center")
  printY = printY + spacing
  love.graphics.printf("Credits",14,printY,width-28,"center")
  printY = printY + spacing
  love.graphics.printf("Quit",14,printY,width-28,"center")
	setColor(255,255,255)
	love.graphics.setFont(fonts.textFont)
  love.graphics.printf("Version " .. gamesettings.version,16,height-prefs['fontSize']*3,width-14,"center")
  love.graphics.printf("Copyright 2019-2021 Weirdfellows LLC, http://weirdfellows.com",16,height-prefs['fontSize']*2,width-14,"center")
  local weirdwidth = fonts.textFont:getWidth("Copyright 2019-2021 Weirdfellows LLC, http://weirdfellows.com")
  local weirdtextwidth = fonts.textFont:getWidth("Copyright 2019-2021 Weirdfellows LLC, ")
  local URLwidth = fonts.textFont:getWidth("http://weirdfellows.com")
  local startX = math.ceil((width+17)/2)-math.ceil(weirdwidth/2)+weirdtextwidth
  local mouseX,mouseY = love.mouse.getPosition()
  if mouseY >= height-28 and mouseY <= height-28+14 and mouseX >= startX and mouseX <= startX+URLwidth then
    love.graphics.line(startX,height-28+16,startX+URLwidth,height-28+16)
  end
  setColor(255,255,255,self.whiteAlpha)
  love.graphics.rectangle('fill',0,0,width,height)
  setColor(255,255,255,255)
end

function menu:keypressed(key)
  key = input:parse_key(key)
	if key == "escape" then
    self.cursorY = 0
	elseif key == "north" then
		self.cursorY = self.cursorY-1
    if self.cursorY < 1 then self.cursorY = 8 end
	elseif key == "south" then
		self.cursorY = self.cursorY+1
    if self.cursorY > 8 then self.cursorY = 1 end
	elseif key == "return" or key == "wait" then
		if (self.cursorY == 1) then
      Gamestate.switch(newgame)
      self.cursorY = 1
      newgame.cheats={}
    elseif (self.cursorY == 2) then
      Gamestate.switch(loadsaves)
		elseif (self.cursorY == 3) then
			Gamestate.switch(help)
		elseif (self.cursorY == 4) then
			Gamestate.switch(gamestats)
		elseif (self.cursorY == 5) then
			Gamestate.switch(monsterpedia)
    elseif (self.cursorY == 6) then
			Gamestate.switch(settings)
    elseif (self.cursorY == 7) then
			Gamestate.switch(credits)
		elseif (self.cursorY == 8) then
			love.event.quit()
		end
	end
end

function menu:gamepadaxis(joystick,axis,value)
  local command = input:parse_gamepadaxis(joystick,axis,value)
  if math.abs(value) > 0.5 then
    print(axis,value)
  end
end

function menu:gamepadpressed(joystick,button)
  local command = input:parse_gamepadbutton(joystick,button)
  if command == "select" then
    self:keypressed("return")
  end
end

function menu:update(dt)
	local x,y = love.mouse.getPosition()
  local width = love.graphics.getWidth()
  local startX = width/2-256+80
	if y ~= output.mouseY and x > startX and x < startX+512-161 then -- only do this if the mouse has moved
    output.mouseY = y
    local done = false
    for line=1,8,1 do
      if y > (line*40+127) and y < (line*40+172) then
        self.cursorY = line
        done = true
        break
      end
    end --end line for
    if not done then self.cursorY = 0 end
	end
end

function menu:mousepressed(x,y,button)
  local startX = love.graphics.getWidth()/2-256+80
	if x > startX and x < startX+512-161 then
    menu:keypressed('return')
  end
  local weirdwidth = fonts.textFont:getWidth("Copyright 2019-2021 Weirdfellows LLC, http://weirdfellows.com")
  local weirdtextwidth = fonts.textFont:getWidth("Copyright 2019-2021 Weirdfellows LLC, ")
  local URLwidth = fonts.textFont:getWidth("http://weirdfellows.com")
  local startX = math.ceil((love.graphics.getWidth()+17)/2)-math.ceil(weirdwidth/2)+weirdtextwidth
  local mouseX,mouseY = love.mouse.getPosition()
  local height = love.graphics.getHeight()
  if mouseY >= height-28 and mouseY <= height-28+14 and mouseX >= startX and mouseX <= startX+URLwidth then
    love.system.openURL("http://weirdfellows.com")
  end
end

function menu:wheelmoved(x,y)
	if y > 0 then
		self.cursorY = self.cursorY-1
    if self.cursorY < 1 then self.cursorY = 8 end
	elseif y < 0 then
		self.cursorY = self.cursorY+1
    if self.cursorY > 8 then self.cursorY = 1 end
  end
end