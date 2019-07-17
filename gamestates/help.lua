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
	love.graphics.printf([[You are a ghost escaped from the Nether Regions, trying to make it back to the surface.
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
escape - Exit current mode and return to game screen. If on game screen, return to main menu.]],padding,printY,width-padding*2)

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