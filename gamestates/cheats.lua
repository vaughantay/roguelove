cheats = {}
local Setting = Class{}

function cheats:enter(previous)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
  output:sound('stoneslideshort',2)
  self:make_controls()
  self.cursorY=0
end

function cheats:make_controls()
  local width = love.graphics:getWidth()
  local startX=math.floor(width/3)
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']
  self.labels = {}
  local _, tlines = fonts.textFont:getWrap("These cheats make the game a bit easier without changing too much:",math.ceil(width/2)-padding)
  local settingY = 145+(#tlines+1)*fontSize
  self.labels[1] = Setting('twoHitGhost',"Ghost dies in two hits instead of one",startX,settingY,(newgame.cheats['twoHitGhost'] and true or false),true,startX)
  self.labels[2] = Setting('easierPossession',"Easier possessions",startX,settingY+25,(newgame.cheats['easierPossession'] and true or false),true,startX)
  self.labels[3] = Setting('quickPossessionCooldown',"Half-length cooldowns for Possession",startX,settingY+50,(newgame.cheats['quickPossessionCooldown'] and true or false),true,startX)
  self.labels[4] = Setting('noPossessionCooldown',"No cooldowns for Possession",startX,settingY+75,(newgame.cheats['noPossessionCooldown'] and true or false),true,startX)
  local _, tlines = fonts.textFont:getWrap("The game is meant to be played with permadeath, but this will change it so when you die, the map you're on will regenerate instead:",math.ceil(width/2)-padding)
  local settingY = 345+(#tlines+1)*fontSize
  self.labels[5] = Setting('regenMapOnDeath',"Regenerate map on death, instead of Game Over",startX,settingY,(newgame.cheats['regenMapOnDeath'] and true or false),true,startX)
  local _, tlines = fonts.textFont:getWrap("You really should only use these if you're testing something:",math.ceil(width/2)-padding)
  local settingY = 500+(#tlines+1)*fontSize
  self.labels[6] = Setting('fullMap',"Reveal entire map layout",startX,settingY,(newgame.cheats['fullMap'] and true or false),true,startX) 
  self.labels[7] = Setting('seeAll',"See everything, all the time",startX,settingY+25,(newgame.cheats['seeAll'] and true or false),true,startX)
  local _, tlines = fonts.textFont:getWrap("The game originally launched with maps that were 75 x 75 tiles, but the maps seemed too big, so they were changed to 60 x 60. But the option's here if you prefered the larger size:",math.ceil(width/2)-padding)
  self.labels[8] = Setting('largeMaps',"Larger maps",startX,650+(#tlines+1)*fontSize,(newgame.cheats['largeMaps'] and true or false),true,startX)
end

function cheats:draw()
  newgame:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle("fill",0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']
  output:draw_window(math.ceil(width/4),padding,math.ceil(width/4+width/2),height-padding*2)
  
  love.graphics.setFont(fonts.textFont)
  love.graphics.printf("Some of these change the game from its intended difficulty and length.",math.ceil(width/4)+padding,padding*2,math.ceil(width/2)-padding,"center")
  love.graphics.printf("These cheats make the game a bit easier without changing too much:",math.ceil(width/4)+padding,145,math.ceil(width/2)-padding,"center")
  love.graphics.printf("The game is meant to be played with permadeath, but this will change it so when you die, the map you're on will regenerate instead:",math.ceil(width/4)+padding,345,math.ceil(width/2)-padding,"center")
  love.graphics.printf("You really should only use these if you're testing something:",math.ceil(width/4)+padding,500,math.ceil(width/2)-padding,"center")
  love.graphics.printf("The game originally launched with maps that were 75 x 75 tiles, but the maps seemed too big, so they were changed to 60 x 60. But the option's here if you prefered the larger size:",math.ceil(width/4)+padding,650,math.ceil(width/2)-padding,"center")

  --Draw a border around currently selected cheat:
  if self.labels[self.cursorY] then
    local setting = self.labels[self.cursorY]
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",setting.x-8,setting.y-4,setting.width+16,setting.height+8)
    setColor(255,255,255,255)
  end --end active setting check
  
  --Draw settings:
  for _,setting in pairs(self.labels) do
    if setting[1] then --an array holding more 
      for _,s in pairs(setting) do
        s:draw()
      end --end nested for
    else
      setting:draw()
    end --end setting table if
  end --end setting for
  self.closebutton = output:closebutton(width/4+padding,padding*2,self.cursorY == 0)
  love.graphics.pop()
end

function cheats:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(newgame)
    Gamestate.update(dt)
  end
  local x,y = love.mouse.getPosition()
	if (y ~= output.mouseY or x ~= output.mouseX) then -- only do this if the mouse has moved
		output.mouseY = y
    output.mouseX = x
    for sy,setting in pairs(self.labels) do
      local stop = false
      if x > setting.x-8 and x < setting.x+setting.width+8 and y > setting.y-4 and y < setting.y+setting.height+4 then
        self.cursorY = sy
        stop = true
      end --end y setting check if
      if stop == true then break end
      self.cursorY = 0 --if no setting was selected
    end --end y setting for
	end
end

function cheats:keypressed(key)
  if (key == "escape") then
    self:switchBack()
  elseif (key == "up") then
    if self.cursorY > 0 then self.cursorY = self.cursorY-1 end
  elseif (key == "down") then
    if self.cursorY < 7 then self.cursorY = self.cursorY+ 1 end
  elseif key == "return" or key == "kpenter" then
    local setting = nil
    if self.labels[self.cursorY] then
      setting = self.labels[self.cursorY]
    end
    if setting and not setting.disabled then
      --if it's a checkbox, easy enough, just swap whatever the setting is
      if setting.checkbox ~= nil then 
        setting.checkbox = not setting.checkbox
        newgame.cheats[setting.id] = setting.checkbox
        --Uncheck any cheats that contradict this one:
        if setting.id == "fullMap" and newgame.cheats["seeAll"] then newgame.cheats["seeAll"] = false self.labels[7].checkbox = false
        elseif setting.id == "seeAll" and newgame.cheats["fullMap"] then newgame.cheats["fullMap"] = false self.labels[6].checkbox = false
        elseif setting.id == "quickPossessionCooldown" and newgame.cheats["quickPossessionCooldown"] then newgame.cheats["noPossessionCooldown"] = false self.labels[4].checkbox = false
        elseif setting.id == "noPossessionCooldown" and newgame.cheats["noPossessionCooldown"] then newgame.cheats["quickPossessionCooldown"] = false self.labels[3].checkbox = false
        end
      end --end checkbox if
    end --end setting if
  end --end keycheck if
end

function cheats:mousepressed(x,y,button)
  local width = love.graphics.getWidth()
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) or x < math.ceil(width/4) or x > math.ceil(width/4+width/2) then 
    self:switchBack()
  else
    self:keypressed("return")
  end
end

function cheats:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end


function Setting:init(id,label,x,y,checkbox,center,width,xMod,font,image,highlightImage)
  xMod = xMod or 0
  self.id = id
  self.font = font or fonts.textFont
  self.label = label
  self.checkbox = checkbox
  self.image = image
  self.highlightImage = highlightImage
  self.y = math.floor(y)
  self.height = math.floor(self.image and images[self.image]:getHeight() or self.font:getHeight())
  local textWidth = self.font:getWidth(label)
  self.width = math.floor(textWidth + (checkbox ~= nil and 32 or 0))
  if center then
    self.x = math.floor((x+width/2)-textWidth/2 + xMod)
  else
    self.x = math.floor(x + xMod)
  end
end

function Setting:draw()
  if love.graphics.getFont ~= self.font then love.graphics.setFont(self.font) end
  if self.checkbox == nil then
    if self.disabled then setColor(150,150,150,255) end
    love.graphics.print(self.label,self.x,self.y)
    if self.disabled then setColor(255,255,255,255) end
    if self.image and not prefs['noImages'] then
      love.graphics.draw(self.image,self.x,self.y)
    end
  else
    if prefs['noImages'] then
      if self.disabled then setColor(150,150,150,255) end
      love.graphics.print((self.checkbox and "(Y)" or "(N)"),self.x,self.y)
      if self.disabled then setColor(255,255,255,255) end
    else
      love.graphics.draw((self.checkbox and images.uicheckboxchecked or images.uicheckbox),self.x,self.y)
    end
    if self.disabled then setColor(150,150,150,255) end
    love.graphics.print(self.label,self.x+32,self.y)
    if self.disabled then setColor(255,255,255,255) end
    if self.image and not prefs['noImages'] then
      love.graphics.draw(self.image,self.x+32,self.y)
    end
  end
end