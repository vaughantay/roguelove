menu = {whiteAlpha=0}

function menu:enter()
  output:play_playlist('menu')
  output.cursorY = 1
end

function menu:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  setColor(255,255,255,255)
	love.graphics.setFont(fonts.graveFontBig)
	love.graphics.printf("Roguelove Example Game",14,96,width-28,"center")
	love.graphics.setFont(fonts.graveFontSmall)
	love.graphics.setFont(fonts.graveFontBig)
  local spacing = 40
  if (output.cursorY >= 1 and output.cursorY <= 8) and Gamestate.current() == menu then
		setColor(100,100,100,255)
		love.graphics.rectangle("fill",width/2-256+80,(output.cursorY*spacing+127),512-161,45)
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
  love.graphics.printf("Version " .. gamesettings.version,16,height-42,width-14,"center")
  love.graphics.printf("Copyright 2019-2020 Weirdfellows LLC, http://weirdfellows.com",16,height-28,width-14,"center")
  local weirdwidth = fonts.textFont:getWidth("Copyright 2019-2020 Weirdfellows LLC, http://weirdfellows.com")
  local weirdtextwidth = fonts.textFont:getWidth("Copyright 2019-2020 Weirdfellows LLC, ")
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
	if key == "escape" then
      output:setCursor(0,0)
    --[[if player ~= nil and currMap ~= nil then
      Gamestate.switch(game)
    end]]
	elseif (key == "up") then
		output.cursorY = output.cursorY-1
    if output.cursorY < 1 then output.cursorY = 8 end
	elseif (key == "down") then
		output.cursorY = output.cursorY+1
    if output.cursorY > 8 then output.cursorY = 1 end
	elseif (key == "return") or key == "kpenter" then
		if (output.cursorY == 1) then
      initialize_player()
      initialize_world()
      Gamestate.switch(newgame)
      output.cursorY = 1
      newgame.cheats={}
    elseif (output.cursorY == 2) then
      Gamestate.switch(loadsaves)
		elseif (output.cursorY == 3) then
			Gamestate.switch(help)
		elseif (output.cursorY == 4) then
			Gamestate.switch(gamestats)
		elseif (output.cursorY == 5) then
			Gamestate.switch(monsterpedia)
    elseif (output.cursorY == 6) then
			Gamestate.switch(settings)
    elseif (output.cursorY == 7) then
			Gamestate.switch(credits)
		elseif (output.cursorY == 8) then
			love.event.quit()
		end
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
        output.cursorY = line
        done = true
        break
      end
    end --end line for
    if not done then output.cursorY = 0 end
	end
end

function menu:mousepressed(x,y,button)
  local startX = love.graphics.getWidth()/2-256+80
	if x > startX and x < startX+512-161 then
    menu:keypressed('return')
  end
  local weirdwidth = fonts.textFont:getWidth("Copyright 2019-2020 Weirdfellows LLC, http://weirdfellows.com")
  local weirdtextwidth = fonts.textFont:getWidth("Copyright 2019-2020 Weirdfellows LLC, ")
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
		output.cursorY = output.cursorY-1
    if output.cursorY < 1 then output.cursorY = 8 end
	elseif y < 0 then
		output.cursorY = output.cursorY+1
    if output.cursorY > 8 then output.cursorY = 1 end
  end
end