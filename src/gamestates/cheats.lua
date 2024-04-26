cheats = {}
local Setting = Class{}

function cheats:enter(previous)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
  output:sound('stoneslideshort',2)
  self:make_controls()
  self.cursorY=0
  self.scroll = 0
end

function cheats:make_controls()
  local uiScale = (prefs['uiScale'] or 1)
  local width = love.graphics:getWidth()
  local padding = (prefs['noImages'] and 16 or 32)
  local startX=math.floor(width/uiScale/4)+padding
  local fontSize = prefs['fontSize']
  local wrapL = math.ceil(width/uiScale/2)-padding-(self.scrollPositions and padding or 0)
  self.labels = {}
  local settingY = 145
  local yAdd = math.max(fontSize,25)
  
  self.labels[1] = Setting('text',"The game is meant to be played with permadeath, but this will change it so when you die, the map you're on will regenerate instead:",startX,settingY,nil,true,wrapL)
  settingY=settingY+math.max(yAdd,self.labels[1].height)
  self.labels[2] = Setting('regenMapOnDeath',"Regenerate map on death, instead of Game Over",startX,settingY,(newgame.cheats['regenMapOnDeath'] and true or false),false,wrapL)
  settingY=settingY+math.max(yAdd,self.labels[2].height)+yAdd
  
  self.labels[3] = Setting('text',"These will let you see more of the map. They're really more for testing than for use playing the game:",startX,settingY,nil,true,wrapL)
  settingY=settingY+math.max(yAdd,self.labels[3].height)
  self.labels[4] = Setting('fullMap',"Reveal entire map layout",startX,settingY,(newgame.cheats['fullMap'] and true or false),false,wrapL) 
  settingY=settingY+math.max(yAdd,self.labels[4].height)
  self.labels[5] = Setting('seeAll',"See everything, all the time",startX,settingY,(newgame.cheats['seeAll'] and true or false),false,wrapL)
  settingY=settingY+math.max(yAdd,self.labels[5].height)+yAdd
  
  self.maxY = settingY-math.ceil(love.graphics.getHeight()/uiScale-padding*2)
end

function cheats:draw()
  newgame:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle("fill",0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']
  local startX = math.ceil(width/uiScale/4)
  local startY = padding
  local wrapL = math.ceil(width/uiScale/2)-padding
  local endX=math.ceil(startX+width/uiScale/2)
  local endY = height/uiScale-padding*2
  output:draw_window(startX,padding,endX,endY)
  
  --Create a "stencil" that stops
  love.graphics.push()
  local function stencilFunc()
    love.graphics.rectangle("fill",startX,padding*2,math.ceil(startX+width/uiScale/2),height/uiScale-padding*4)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scroll)
  
  love.graphics.setFont(fonts.textFont)
  love.graphics.printf("Some of these change the game from its intended difficulty and length.",startX+padding,padding*2,wrapL,"center")

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
  love.graphics.setStencilTest()
  love.graphics.pop()

  if self.maxY > 0 and self.maxY < endY then
    local scrollAmt = self.scroll/self.maxY
    if scrollAmt > 1 then scrollAmt = 1 end
    local redo = false
    if not self.scrollPositions then redo = true end
    self.scrollPositions = output:scrollbar(endX-padding,startY+padding,endY,scrollAmt,true)
    if redo then self:make_controls() end
  end
  self.closebutton = output:closebutton(math.floor(width/uiScale/4+padding/2),math.floor(padding*1.5),nil,true)
  love.graphics.pop()
end

function cheats:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(newgame)
    Gamestate.update(dt)
  end
  local uiScale = (prefs['uiScale'] or 1)
  local x,y = love.mouse.getPosition()
	if (y ~= self.mouseY or x ~= self.mouseX) then -- only do this if the mouse has moved
		self.mouseY = y
    self.mouseX = x
    x,y = x/uiScale,y/uiScale
    for sy,setting in pairs(self.labels) do
      local stop = false
      if setting.id ~= "text" and x > setting.x-8 and x < setting.x+setting.width+8 and y > setting.y-4-self.scroll and y < setting.y+setting.height+4-self.scroll then
        self.cursorY = sy
        stop = true
      end --end y setting check if
      if stop == true then break end
      self.cursorY = 0 --if no setting was selected
    end --end y setting for
	end
end

function cheats:buttonpressed(key,scancode,isRepeat,controllerType)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if (key == "escape") then
    self:switchBack()
  elseif (key == "north") then
    if self.cursorY > 2 then
      self.cursorY = self.cursorY-1
      if self.labels[self.cursorY].id == "text" then
        self.cursorY = self.cursorY-1
      end
    end
  elseif (key == "south") then
    if self.cursorY < #self.labels then
      self.cursorY = self.cursorY+ 1
      if self.labels[self.cursorY].id == "text" then
        self.cursorY = self.cursorY+1
      end
    end
  elseif key == "enter" or key == "wait" then
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
        if setting.id == "fullMap" and newgame.cheats["seeAll"] then newgame.cheats["seeAll"] = false self.labels[5].checkbox = false
        elseif setting.id == "seeAll" and newgame.cheats["fullMap"] then newgame.cheats["fullMap"] = false self.labels[4].checkbox = false
        end
      end --end checkbox if
    end --end setting if
  end --end keycheck if
end

function cheats:mousepressed(x,y,button)
  local width = love.graphics.getWidth()
  local uiScale = (prefs['uiScale'] or 1)
  if button == 2 or (x/uiScale > self.closebutton.minX and x/uiScale < self.closebutton.maxX and y/uiScale > self.closebutton.minY and y/uiScale < self.closebutton.maxY) or x < math.ceil(width/4) or x > math.ceil(width/4+width/2) then 
    self:switchBack()
  else
    self:buttonpressed(input:get_button_name('enter'))
  end
end

function cheats:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function cheats:wheelmoved(x,y)
	if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end
end

function cheats:scrollUp()
  if self.scroll > 0 then
    self.scroll = self.scroll - prefs.fontSize
  end
end

function cheats:scrollDown()
  if self.scroll < self.maxY then self.scroll = math.min(self.scroll+prefs.fontSize,self.maxY) end
end

function Setting:init(id,label,x,y,checkbox,center,width,xMod,font,image,highlightImage)
  xMod = xMod or 0
  self.id = id
  self.font = font or fonts.textFont
  self.label = label
  self.checkbox = checkbox
  self.image = image
  self.highlightImage = highlightImage
  self.center = center
  self.y = math.floor(y)
  self.height = math.floor(self.image and images[self.image]:getHeight() or self.font:getHeight())
  local textWidth = self.font:getWidth(label)
  local lWidth,tlines = self.font:getWrap(label,width-(checkbox ~= nil and 64 or 0))
  self.width = width or math.floor(textWidth + (checkbox ~= nil and 32 or 0))
  self.height = math.max(#tlines*self.font:getHeight(),self.height)
  self.x = math.floor(x + xMod)
  self.checkBoxX = (center and round((self.x+self.width/2)-lWidth/2) or self.x)
end

function Setting:draw()
  if love.graphics.getFont ~= self.font then love.graphics.setFont(self.font) end
  if self.checkbox == nil then
    if self.disabled then setColor(150,150,150,255) end
    love.graphics.printf(self.label,self.x,self.y,self.width,(self.center and "center" or "left"))
    if self.disabled then setColor(255,255,255,255) end
    if self.image and not prefs['noImages'] then
      love.graphics.draw(self.image,self.x,self.y)
    end
  else
    if prefs['noImages'] then
      if self.disabled then setColor(150,150,150,255) end
      love.graphics.print((self.checkbox and "(Y)" or "(N)"),self.checkBoxX,self.y)
      if self.disabled then setColor(255,255,255,255) end
    else
      love.graphics.draw((self.checkbox and images.uicheckboxchecked or images.uicheckbox),self.checkBoxX,self.y)
    end
    if self.disabled then setColor(150,150,150,255) end
    love.graphics.printf(self.label,self.x+32,self.y,self.width-32,(self.center and "center" or "left"))
    if self.disabled then setColor(255,255,255,255) end
    if self.image and not prefs['noImages'] then
      love.graphics.draw(self.image,self.x+32,self.y)
    end
  end
end