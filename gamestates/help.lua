help = {}

function help:enter(previous)
  self.previous = previous
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
end

function help:draw()
  self.previous:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  love.graphics.push()
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']
  output:draw_window(1,1,width-padding,height-padding)
  love.graphics.setFont(fonts.textFont)
	love.graphics.printf("How to Play",padding,padding,width-padding,"center")
  local printY = padding+fontSize*2
	love.graphics.printf([[Your help text here]],padding,printY,width-padding*2)

love.graphics.printf("Press any key or click to return to game.",padding,height-padding-(prefs['noImages'] and padding or 0),width-padding-fontSize,"center")
love.graphics.pop()
end

function help:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
  end
end

function help:keypressed()
  self:switchBack()
end

function help:mousepressed()
  self:switchBack()
end

function help:switchBack()
  tween(0.2,self,{yModPerc=100})
  Timer.after(0.2,function() self.switchNow=true end)
  output:sound('stoneslideshortbackwards',2)
end