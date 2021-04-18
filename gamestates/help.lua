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
  love.graphics.push()
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
  local helpText = [[You are a ghost escaped from the Nether Regions, trying to make it back to the surface.
Your goal on each level is to reach the stairs up and climb up to the next level.

Because you are a spirit, your physical form is weak, and a single hit will send you back to the Nether Regions.
Luckily for you, you have the ability to take over the bodies of other monsters. Press "]] .. keybindings['possess'].. [[" and select a nearby monster by clicking, or moving the cursor to the creature and pressing enter.

If successful, you will take over that monster's body, and gain access to their physical form and abilities. Use the "]] .. keybindings['charScreen'].. [[" key to pull up information about your current body and "]] .. keybindings['spell'].. [[" to see its abilities.

If unsuccessful at a possession, the target of your possession will be stunned, so it can't hurt you. Additionally, every time you fail to possess a creature, you weaken its will and make it easier to possess. Be careful, though! Even though your target is stunned, other nearby creatures can still attack.


If you die while inhabiting the body of a monster, you will be become a ghost again, and should possess another body immediately.

Don't get too attached to any one body, feel free to possession-hop from creature to creature. But be warned: when you first possess a creature, it takes a few turns to get used to the new body, which means that you won't be able to fight as effectively, and you won't be able to possess again for a short time. Every time you possess a new body, the time to get used to your new body will increase!


Commands:
Mouse - Move the mouse cursor over something to see what it is. Click on an empty square to move there. Click on a monster to target it, and attack if if you're next to it. Right click to bring up a menu of possible actions.]] .. (prefs['arrowKeys'] and "\nArrow Keys - Move. Move into a monster to attack it.\nSpace bar - Wait a turn\n" or "") .. [[
]] .. keybindings['possess'].. [[ - Select a target for possession
]] .. keybindings['heal'].. [[ - Heal (if possessing a body)
]] .. keybindings['ranged'].. [[ - Ranged attack (if your current body has one)
]] .. keybindings['recharge'].. [[ - Recharge/reload ranged attack (if your current body can)
]] .. keybindings['charScreen'].. [[ - View attributes of current body
]] .. keybindings['spell'].. [[ - View abilities of current body
]] .. keybindings['examine'].. [[ - switch to targeting mode
]] .. keybindings['stairsUp'].. [[ - Go up stairs
]] .. keybindings['messages'].. [[ - View old messages
]] .. keybindings['nextTarget'].. [[ - Switch between targets
escape - Exit current mode and return to game screen. If on game screen, return to main menu.]]
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
  
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local x,y = love.mouse.getPosition()
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

function help:keypressed(key)
  if key == "escape" or key == "return" or key == "kpenter" then
    self:switchBack()
  elseif key == "down" then
    self:scrollDown()
  elseif key == "up" then
    self:scrollUp()
  end
end

function help:mousepressed(x,y,button)
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