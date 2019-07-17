menu = {whiteAlpha=0}

function menu:enter()
  output:play_playlist('menu')
  output.cursorY = 1
  self.dirtSkyCanvas = nil
  --self:lightning()
  if not self.rain then
    local width = love.graphics.getWidth()
    self.rain = {}
    for i=1,25,1 do
      local r={x=random(1,width),y=random(1,500)}
      self.rain[r] = r
    end
  end
end

function menu:preDrawDirt()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  self.dirtSkyCanvas = love.graphics.newCanvas(width,height)
  love.graphics.setCanvas(self.dirtSkyCanvas)
  local dirt = ""
  for i=1,width,14 do
    dirt = dirt .. "# "
  end
  --Draw the dirt and sky:
  local actualDirt = ""
  for y=1,height,14 do
    if y >= 540 then
      setColor(153,103,73,255-(255*((y-540)/(height-540))))
      love.graphics.print(dirt,1,y)
    else
      if 255-(255*(y/540)) > 0 then
        setColor(0,181,255,255-(255*(y/540)))
        love.graphics.print(dirt,1,y)
      end
    end
  end
  love.graphics.setCanvas()
end

function menu:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  setColor(255,255,255,255)
  if prefs['noImages'] == true then
    love.graphics.setFont(fonts.mapFont)
    -- Calculate the dirt and sky:
    local dirttime = os.clock()
    love.graphics.setFont(fonts.mapFont)
    --Draw the dirt and sky:
    if not self.dirtSkyCanvas then
      self:preDrawDirt()
    end
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(self.dirtSkyCanvas)
    love.graphics.setBlendMode("alpha")
    
    -- Draw the tombstone:
    setColor(0,0,0,255)
    love.graphics.rectangle('fill',math.ceil(width/2-256),56,520,490)
    setColor(255,255,255,255)
    for y = 50,540,14 do
      if (y == 50) then
        for x = width/2-256,(width/2)+256,13 do
          love.graphics.print("#",x,y)
        end
      else
        love.graphics.print("#",width/2-256,y)
        love.graphics.print("#",width/2+256,y)
      end
    end
    --Draw the grass:
    local grass = ""
    for i=1,width,7 do
      if (i % 5 == 0) then grass = grass .. "\\"
      elseif (i % 7 == 0 or i == 3) then grass = grass .. "/"
      elseif (i % 11 == 0 or i == 2) then grass = grass .. "|"
      else grass = grass .. " " end
    end
    setColor(0,255,0)
    love.graphics.print(grass,1,538)
  else --graphical menu:
    setColor(255,255,255,255)
    for x = 0, width, 512 do
      love.graphics.draw(images['uimenuskydark'],x,0)
    end
    love.graphics.draw(images['uimenuskydark'],width-512,0)
          
    love.graphics.draw(images['uigravestonenew'],width/2-256,50)
    for x = 0, width/64, 1 do
      for y=572,height,32 do
        setColor(255,255,255,255-(255*((y-572)/(height-572))))
        love.graphics.draw(images['uimenudirt'],x*64,y)
      end
      setColor(255,255,255,255)
      love.graphics.draw(images['uimenudirtgrass'],x*64,550)
      if (x % 3 == 0 or x % 13 == 0) then love.graphics.draw(images['uimenugrass1'],x*64,490)
      elseif (x % 7 == 0 or x % 9 == 0) then love.graphics.draw(images['uimenugrass2'],x*64,490)
      elseif (x % 5 == 0 or x % 11 == 0) then love.graphics.draw(images['uimenugrass3'],x*64,490) end
    end
  end --end if images
  
	setColor(255,255,255,255)
	love.graphics.setFont(fonts.graveFontBig)
	love.graphics.printf("POSSESSION",14,96,width-28,"center")
	love.graphics.setFont(fonts.graveFontSmall)
	--love.graphics.printf("Escape from the Nether Regions",14,115,width-28,"center")
  --love.graphics.setFont(fonts.textFont)
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
  love.graphics.printf("Settings",14,printY,width-28,"center")
  printY = printY + spacing
  love.graphics.printf("Credits",14,printY,width-28,"center")
  printY = printY + spacing
  love.graphics.printf("Quit",14,printY,width-28,"center")
	setColor(255,255,255)
	love.graphics.setFont(fonts.textFont)
  love.graphics.printf("Version 1.0.3",16,height-42,width-14,"center")
  love.graphics.printf("Copyright 2019 Weirdfellows LLC, http://weirdfellows.com",16,height-28,width-14,"center")
  local weirdwidth = fonts.textFont:getWidth("Copyright 2019 Weirdfellows LLC, http://weirdfellows.com")
  local weirdtextwidth = fonts.textFont:getWidth("Copyright 2019 Weirdfellows LLC, ")
  local URLwidth = fonts.textFont:getWidth("http://weirdfellows.com")
  local startX = math.ceil((width+17)/2)-math.ceil(weirdwidth/2)+weirdtextwidth
  local mouseX,mouseY = love.mouse.getPosition()
  if mouseY >= height-28 and mouseY <= height-28+14 and mouseX >= startX and mouseX <= startX+URLwidth then
    love.graphics.line(startX,height-28+16,startX+URLwidth,height-28+16)
  end
  setColor(255,255,255,self.whiteAlpha)
  love.graphics.rectangle('fill',0,0,width,height)
  self:drawrain()
  setColor(255,255,255,255)
end

function menu:drawrain()
  setColor(200,200,255,150)
  for _,r in pairs(self.rain) do
    love.graphics.print("|",r.x,r.y)
  end
end

function menu:updaterain(dt)
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()
  if random(1,5) == 1 then
    local r = {x=random(1,width),y=0}
    self.rain[r] = r
  end
  for _,r in pairs(self.rain) do
    r.y = r.y+height*dt
    if r.y > 550 then
      self.rain[r] = nil
    end
  end
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
	elseif (key == "return") then
		if (output.cursorY == 1) then
      initialize_player()
      Gamestate.switch(newgame)
      output.cursorY = 1
      newgame.cheats={}
      newgame.rain=self.rain
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
  self:updaterain(dt)
end

function menu:mousepressed(x,y,button)
  local startX = love.graphics.getWidth()/2-256+80
	if x > startX and x < startX+512-161 then
    menu:keypressed('return')
  end
  local weirdwidth = fonts.textFont:getWidth("Copyright 2019 Weirdfellows LLC, http://weirdfellows.com")
  local weirdtextwidth = fonts.textFont:getWidth("Copyright 2019 Weirdfellows LLC, ")
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

function menu:lightning()
  self.whiteAlpha = random(125,255)
  tween(0.5,self,{whiteAlpha=0})
  output:sound('thunder2')
end