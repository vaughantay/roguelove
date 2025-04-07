menu = {whiteAlpha=0}

function menu:enter()
  output:play_playlist('menu')
  self.cursorY = 1
  self.winY = 0
end

function menu:draw()
  local uiScale = (prefs['uiScale'] or 1)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  local width, height = round(love.graphics:getWidth()/uiScale),round(love.graphics:getHeight()/uiScale)
  local midX,midY = round(width/2),round(height/2)
  local spacing = fonts.menuFont:getHeight()
  setColor(255,255,255,255)
  local winW = 400
  local winH = spacing*8
  local printX = round(midX-winW/2)
  local printY = 32
	love.graphics.setFont(fonts.titleFont)
	love.graphics.printf(gamesettings.name,printX+16,32,winW,"center")
  printY = printY+96
  local winY = printY
  self.winY = winY
  output:draw_window(printX,winY,printX+winW,winY+winH)
  printY=printY+16
  if (self.cursorY >= 1 and self.cursorY <= 8) and Gamestate.current() == menu then
		setColor(100,100,100,255)
		love.graphics.rectangle("fill",printX+16,(self.cursorY-1)*spacing+winY+16,winW,spacing)
    setColor(255,255,255,255)
	end
  love.graphics.setFont(fonts.menuFont)
  love.graphics.printf("Start a New Game",printX+16,printY,winW,"center")
  printY = printY + spacing
	love.graphics.printf("Load a Saved Game",printX+16,printY,winW,"center")
  printY = printY + spacing
	love.graphics.printf("How to Play",printX+16,printY,winW,"center")
  printY = printY + spacing
  setColor(50,50,50,255)
	love.graphics.printf("Stats and Records",printX+16,printY,winW,"center")
  printY = printY + spacing
  setColor(255,255,255,255)
	love.graphics.printf("Monsterpedia",printX+16,printY,winW,"center")
  printY = printY + spacing
  love.graphics.printf("Settings & Controls",printX+16,printY,winW,"center")
  printY = printY + spacing
  love.graphics.printf("Credits",printX+16,printY,winW,"center")
  printY = printY + spacing
  love.graphics.printf("Quit",printX+16,printY,winW,"center")
	love.graphics.setFont(fonts.textFont)
  if gamesettings.version_text then
    love.graphics.printf(gamesettings.version_text,16,height-prefs['fontSize']*4,width-14,"center")
  end
  if gamesettings.copyright_text then
    love.graphics.printf(gamesettings.copyright_text,16,height-prefs['fontSize']*3,width-14,"center")
  end
  if gamesettings.url then
    love.graphics.printf(gamesettings.url,16,height-prefs['fontSize']*2,width-14,"center")
    local URLwidth = fonts.textFont:getWidth(gamesettings.url)
    local startX = math.ceil(width/2-URLwidth/2)+8
    local mouseX,mouseY = love.mouse.getPosition()
    mouseX,mouseY = mouseX/uiScale,mouseY/uiScale
    if Gamestate.current() == menu and mouseY >= height-prefs['fontSize']*2 and mouseY <= height-prefs['fontSize'] and mouseX >= startX and mouseX <= startX+URLwidth then
      love.graphics.line(startX,height-prefs['fontSize'],startX+URLwidth,height-prefs['fontSize'])
    end
  end
  setColor(255,255,255,self.whiteAlpha)
  love.graphics.rectangle('fill',0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.pop()
end

function menu:buttonpressed(key,scancode,isRepeat,controllerType)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
	if key == "escape" then
    self.cursorY = 0
	elseif key == "north" then
		self.cursorY = self.cursorY-1
    if self.cursorY < 1 then self.cursorY = 8 end
	elseif key == "south" then
		self.cursorY = self.cursorY+1
    if self.cursorY > 8 then self.cursorY = 1 end
	elseif key == "enter" or key == "wait" then
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

function menu:update(dt)
  local uiScale = (prefs['uiScale'] or 1)
	local x,y = love.mouse.getPosition()
  x,y = x/uiScale, y/uiScale
  local width = love.graphics.getWidth()
  local startX = round(width/uiScale/2)-256+80
  local spacing = fonts.menuFont:getHeight()
	if y ~= output.mouseY and x > startX and x < startX+512-161 then -- only do this if the mouse has moved
    output.mouseY = y
    local done = false
    for line=1,8,1 do
      if y > (line-1)*spacing+self.winY+16 and y < (line)*spacing+self.winY+16 then
        self.cursorY = line
        done = true
        break
      end
    end --end line for
    if not done then self.cursorY = 0 end
	end
end

function menu:mousepressed(x,y,button)
  local uiScale = prefs['uiScale'] or 1
  local startX = round(love.graphics.getWidth()/uiScale/2-256+80)
  x,y = x/uiScale,y/uiScale
	if x > startX and x < startX+512-161 then
    menu:buttonpressed(input:get_button_name('enter'))
  end
  if gamesettings.url then
    local URLwidth = fonts.textFont:getWidth(gamesettings.url)
    local width,height = round(love.graphics.getWidth()/uiScale),round(love.graphics.getHeight()/uiScale)
    local startX = math.ceil(width/2-URLwidth/2)+8
    if y >= height-prefs['fontSize']*2 and y <= height-prefs['fontSize'] and x >= startX and x <= startX+URLwidth then
      love.system.openURL(gamesettings.url)
    end
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