settings = {}
local Setting = Class{}

function settings:enter(previous)
  self.previous = previous
  output:setCursor(1,1)
  self:make_controls()
  self.screen = "controls"
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
  output:sound('stoneslideshort',2)
end

function settings:leave()
  output:setCursor(0,0)
end

function settings:make_controls()
  local width = love.graphics:getWidth()
  local size=250
  local startX=math.floor(width/3)
  local keyStartX=math.floor(width/2)-size+15
  self.labels = {
    controls = {},
    graphics = {}
  }
  --[[local size=250
    local startX=math.floor(width/2)-size+15
    love.graphics.rectangle('line',startX,330,size,135)
    love.graphics.line(startX+75,330,startX+75,465)
    love.graphics.rectangle('line',startX+255,330,size,150)
    love.graphics.line(startX+350,330,startX+350,480)
    for y = 345,450,15 do
      love.graphics.line(startX,y,startX+size,y)
      love.graphics.line(startX+255,y,startX+255+size,y)
    end
    love.graphics.line(startX+255,465,startX+255+size,465)]]
  self.labels.controls[1] = {}
  self.labels.controls[1][1] = Setting('screen:controls','Controls',math.floor(width/4)+32,50,nil,false,nil,nil,fonts.menuFont,true)
  local gwidth = fonts.menuFont:getWidth('Graphics/Sound')
  self.labels.controls[1][2] = Setting('screen:graphics','Graphics/Sound',(width/4*3)-gwidth,50,nil,false,nil,nil,fonts.menuFont,true)
  self.labels.controls[1][1].disabled = true
  self.labels.controls[2] = Setting('mouseMovesMap',"Mouse Cursor Moves Map",startX,100,prefs['mouseMovesMap'],true,startX)
  self.labels.controls[3] = Setting('spellShortcuts',"Use 1-9 as Spell Shortcuts",startX,125,prefs['spellShortcuts'],true,startX)
  self.labels.controls[4] = Setting('arrowKeys',"Use Arrow Keys to Move",startX,150,prefs['arrowKeys'],true,startX)
  self.labels.controls[5] = {Setting('keybindings:northwest',"Northwest",keyStartX,330,nil,nil,250)}
  self.labels.controls[6] = {Setting('keybindings:north','North',keyStartX,345,nil,nil,250)}
  self.labels.controls[7] = {Setting('keybindings:northeast','Northeast',keyStartX,360,nil,nil,250)}
  self.labels.controls[8] = {Setting('keybindings:east','East',keyStartX,375,nil,nil,250)}
  self.labels.controls[9] = {Setting('keybindings:southeast','Southeast',keyStartX,390,nil,nil,250)}
  self.labels.controls[10] = {Setting('keybindings:south','South',keyStartX,405,nil,nil,250)}
  self.labels.controls[11] = {Setting('keybindings:southwest','Southwest',keyStartX,420,nil,nil,250)}
  self.labels.controls[12] = {Setting('keybindings:west','West',keyStartX,435,nil,nil,250)}
  self.labels.controls[13] = {Setting('keybindings:wait','Wait',keyStartX,450,nil,nil,250)}
  self.labels.controls[5][2] = Setting('keybindings:spell','See Abilities',keyStartX+255,330,nil,nil,250)
  self.labels.controls[6][2] = Setting('keybindings:charScreen','Game Stats',keyStartX+255,345,nil,nil,250)
  self.labels.controls[7][2] = Setting('keybindings:examine','Examine',keyStartX+255,360,nil,nil,250)
  self.labels.controls[8][2] = Setting('keybindings:messages','View Messages',keyStartX+255,375,nil,nil,250)
  self.labels.controls[9][2] = Setting('keybindings:stairsUp','Use Stairs',keyStartX+255,390,nil,nil,250)
  self.labels.controls[10][2] = Setting('keybindings:ranged','Ranged Attack',keyStartX+255,405,nil,nil,250)
  self.labels.controls[11][2] = Setting('keybindings:recharge','Reload',keyStartX+255,420,nil,nil,250)
  self.labels.controls[12][2] = Setting('keybindings:possess','Possession',keyStartX+255,435,nil,nil,250)
  self.labels.controls[13][2] = Setting('keybindings:heal','Heal Body',keyStartX+255,450,nil,nil,250)
  self.labels.controls[14] = Setting('keybindings:nextTarget','Switch Target',keyStartX+255,465,nil,nil,250)
  self.labels.controls[15] = Setting('keybindings:zoomIn','Zoom In',keyStartX+255,480,nil,nil,250)
  self.labels.controls[16] = Setting('keybindings:zoomOut','Zoom Out',keyStartX+255,495,nil,nil,250)
  self.labels.controls[17] = Setting('defaultkeys',"Restore Default Keys",startX,530,nil,true,startX,nil,fonts.menuFont,true)
  self.labels.graphics[1] = {}
  self.labels.graphics[1][1] = Setting('screen:controls','Controls',math.floor(width/4)+32,50,nil,false,nil,nil,fonts.menuFont,true)
  local gwidth = fonts.menuFont:getWidth('Graphics/Sound')
  self.labels.graphics[1][2] = Setting('screen:graphics','Graphics/Sound',(width/4*3)-gwidth,50,nil,false,nil,nil,fonts.menuFont,true)
  self.labels.graphics[1][2].disabled = true
  self.labels.graphics[2] = {}
  self.labels.graphics[2][1] = Setting('soundDown',"-",width/2-100,100)
  self.labels.graphics[2][2] = Setting('soundUp',"+",width/2+100,100)
  self.labels.graphics[3] = {}
  self.labels.graphics[3][1] = Setting('musicDown',"-",width/2-100,125)
  self.labels.graphics[3][2] = Setting('musicUp',"+",width/2+100,125)
  self.labels.graphics[4] = {}
  self.labels.graphics[4][1] = Setting('uiScaleDown',"-",width/2-100,150)
  self.labels.graphics[4][2] = Setting('uiScaleUp',"+",width/2+100,150)
  self.labels.graphics[5] = Setting('noImages',"ASCII Mode",startX,175,prefs['noImages'],true,startX)
  self.labels.graphics[6] = Setting('minimap',"Mini-map",startX,200,prefs['minimap'],true,startX)
  if prefs['noImages'] then
    self.labels.graphics[7] = {}
    self.labels.graphics[7][1] = Setting('asciiSizeDown',"-",width/2-100,225)
    self.labels.graphics[7][2] = Setting('asciiSizeUp',"+",width/2+100,225)
  else
    self.labels.graphics[7] = Setting('creatureShadows',"Creature Shadows",startX,225,prefs['creatureShadows'],true,startX)
    self.labels.graphics[8] = Setting('creatureAnimations',"Creature Animations",startX,250,prefs['creatureAnimations'],true,startX)
  end
  local nextSetting = 9
  local prefY = 275
  if prefs['noImages'] then nextSetting=8 prefY = 250 end
  self.labels.graphics[nextSetting] = Setting('noSmoothCamera',"No Smooth Camera",startX,prefY,prefs['noSmoothCamera'],true,startX)
  self.labels.graphics[nextSetting+1] = Setting('noSmoothMovement',"No Smooth Movement",startX,prefY+25,prefs['noSmoothMovement'],true,startX)
  self.labels.graphics[nextSetting+2] = Setting('statsOnSidebar',"Show Creature Attributes on Sidebar",startX,prefY+50,prefs['statsOnSidebar'],true,startX)
  self.labels.graphics[nextSetting+3] = Setting('plainFonts',"Plain Fonts on Sidebar",startX,prefY+75,prefs['plainFonts'],true,startX)
  self.labels.graphics[nextSetting+4] = Setting('fullscreen',"Fullscreen",startX,prefY+125,prefs['fullscreen'],true,startX)
  self.labels.graphics[nextSetting+5] = Setting('vsync',"Vsync",startX,prefY+150,prefs['vsync'],true,startX)
end

function settings:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  love.graphics.setFont(fonts.textFont)
  self.previous:draw()
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle("fill",0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.translate(0,height*(self.yModPerc/100))
  
  if (prefs['noImages'] ~= true) then
    --Draw inner coloring:
    setColor(20,20,20,225)
    love.graphics.rectangle("fill",width/4,18,width/2+16,height-36)
    setColor(255,255,255,255)
    --Borders for select:
    for x=width/4+16,(width/4)*3,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.u,x,0)
      love.graphics.draw(images.borders.borderImg,images.borders.d,x,height-32)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.u,(width/4)*3-16,0)
    love.graphics.draw(images.borders.borderImg,images.borders.d,(width/4)*3-16,height-32)
    for y=32,height-48,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.l,width/4,y)
      love.graphics.draw(images.borders.borderImg,images.borders.r,(width/4)*3,y)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.l,width/4,height-64)
    love.graphics.draw(images.borders.borderImg,images.borders.r,(width/4)*3,height-64)
    love.graphics.draw(images.borders.borderImg,images.borders.ul,width/4,0)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,(width/4)*3,0)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,width/4,height-32)
    love.graphics.draw(images.borders.borderImg,images.borders.lr,(width/4)*3,height-32)
  else --no images
    --Draw inner coloring:
    setColor(20,20,20,225)
    love.graphics.rectangle("fill",width/4,18,width/2+16,height-32)
    setColor(255,255,255,255)
    love.graphics.rectangle("line",width/4,18,width/2+16,height-32)
  end
  
  --Draw the highlight around the active setting:
  local activeSetting = nil
  if self.replaceSetting then
    local setting = self.replaceSetting
    setColor(150,150,150,255)
    love.graphics.rectangle("fill",setting.x,setting.y,250,setting.height)
    setColor(255,255,255,255)
  elseif self.labels[self.screen][output.cursorY] then
    local setting = self.labels[self.screen][output.cursorY]
    if setting[1] then
      setting = (setting[output.cursorX] or setting[1])
    end --end cursorX setting check
    if not setting.button then
      setColor(100,100,100,255)
      local split = explode(setting.id,":")
      if split[1] == 'keybindings' then
        love.graphics.rectangle("fill",setting.x,setting.y,250,setting.height)
      else
        love.graphics.rectangle("fill",setting.x-8,setting.y-4,setting.width+16,setting.height+8)
      end
      setColor(255,255,255,255)
    end
    activeSetting = setting
  end --end active setting check
  --Draw settings:
  for _,setting in pairs(self.labels[self.screen]) do
    if setting[1] then --an array holding more 
      for _,s in pairs(setting) do
        s:draw()
        if s == activeSetting then
          s.selected = true
        else
          s.selected = nil
        end
      end --end nested for
    else
      setting:draw()
      if setting == activeSetting then
        setting.selected = true
      else
          setting.selected = nil
      end
    end --end setting table if
  end --end setting for
    
  if self.screen == "controls" then
    local size=250
    local startX=math.floor(width/2)-size+15
    
    love.graphics.setFont(fonts.textFont)
    if self.keyError then
      love.graphics.printf(self.keyError,math.floor(width/4),300,math.floor(width/2)+32,'center')
    end
    
    --Draw the grid for keybindings, starting with the general outline rectangles and the vertical separators
    love.graphics.line(startX+75,330,startX+75,465)
    love.graphics.line(startX+365,330,startX+365,510)
    love.graphics.rectangle('line',startX,330,size,135)
    love.graphics.rectangle('line',startX+255,330,size,180)
    --Draw the lines for each key:
    for y = 345,510,15 do
      if y <= 450 then love.graphics.line(startX,y,startX+size,y) end
      love.graphics.line(startX+255,y,startX+255+size,y)
    end
    --Draw an extra line on the right since there's an extra setting:
    love.graphics.line(startX+255,465,startX+255+size,465)
    
    --Print the keys used for each command:
    love.graphics.printf(keybindings['northwest'],startX+75,330,size-75,"center")
    love.graphics.printf((not prefs['arrowKeys'] and '' or 'Up Arrow or ') .. keybindings['north'],startX+75,345,size-75,"center")
    love.graphics.printf(keybindings['northeast'],startX+75,360,size-75,"center")
    love.graphics.printf((not prefs['arrowKeys'] and '' or 'Right Arrow or ') .. keybindings['east'],startX+75,375,size-75,"center")
    love.graphics.printf(keybindings['southeast'],startX+75,390,size-75,"center")
    love.graphics.printf((not prefs['arrowKeys'] and '' or 'Down Arrow or ') .. keybindings['south'],startX+75,405,size-75,"center")
    love.graphics.printf(keybindings['southwest'],startX+75,420,size-75,"center")
    love.graphics.printf((not prefs['arrowKeys'] and '' or 'Left Arrow or ') .. keybindings['west'],startX+75,435,size-75,"center")
    love.graphics.printf((not prefs['arrowKeys'] and '' or 'Space Bar or ') .. keybindings['wait'],startX+75,450,size-75,"center")
    
    
    love.graphics.printf(keybindings['spell'],startX+365,330,size-115,"center")
    love.graphics.printf(keybindings['charScreen'],startX+365,345,size-115,"center")
    love.graphics.printf(keybindings['examine'],startX+365,360,size-115,"center")
    love.graphics.printf(keybindings['messages'],startX+365,375,size-115,"center")
    love.graphics.printf(keybindings['stairsUp'],startX+365,390,size-115,"center")
    love.graphics.printf(keybindings['ranged'],startX+365,405,size-115,"center")
    love.graphics.printf(keybindings['recharge'],startX+365,420,size-115,"center")
    love.graphics.printf(keybindings['possess'],startX+365,435,size-115,"center")
    love.graphics.printf(keybindings['heal'],startX+365,450,size-115,"center")
    love.graphics.printf(keybindings['nextTarget'],startX+365,465,size-115,"center")
    love.graphics.printf(keybindings['zoomIn'],startX+365,480,size-115,"center")
    love.graphics.printf(keybindings['zoomOut'],startX+365,495,size-115,"center")
  elseif self.screen == "graphics" then
    love.graphics.printf("Sound Volume: " .. prefs['soundVolume'] .. "%",math.floor(width/4),100,math.floor(width/4*2),"center")
    love.graphics.printf("Music Volume: " .. prefs['musicVolume'] .. "%",math.floor(width/4),125,math.floor(width/4*2),"center")
    love.graphics.printf("UI Scaling: " .. prefs['uiScale']*100 .. "%",math.floor(width/4),150,math.floor(width/4*2),"center")
    if prefs['noImages'] then love.graphics.printf("ASCII Font Size: " .. prefs['asciiSize'],math.floor(width/4),200,math.floor(width/4*2),"center") end
    --add special code here
  end
  self.closebutton = output:closebutton(width/4+(prefs['noImages'] and 8 or 24),24)
  love.graphics.pop()
end --end draw

function settings:keypressed(key)
  if (action == "setKeys") then
    if key ~= "escape" then
      for k, val in pairs(keybindings) do
        if val == key or (key == "return" or key == "kpenter") or ((key == "up" or key == "down" or key == "left" or key == "right" or key == "space") and prefs['arrowKeys']) or (prefs['spellShortcuts'] and tonumber(key) ~= nil) then
          self.keyError = "Key " .. key .. " already in use!"
          return
        end
       end -- end for loop
        keybindings[self.replaceKey] = key
        self:make_controls() --refresh all the control labels
        self.replaceKey = nil
        self.replaceSetting = nil
        self.keyError=nil
        action = "moving"
      elseif key == "escape" then
        self:make_controls() --refresh all the control labels
        self.replaceKey = nil
        self.replaceSetting = nil
        self.keyError=nil
        action = "moving"
    end -- end check that makes sure it's not a reserved key
  else -- end setting keys
    if (key == "escape") then
      self:switchBack()
    elseif (key == "up") then
      if output.cursorY > 1 then output:moveCursor(0,-1) end
    elseif (key == "down") then
      output:moveCursor(0,1)
    elseif (key == "left") then
      if output.cursorX > 1 then output:moveCursor(-1,0) end
    elseif (key == "right") then
      output:moveCursor(1,0)
    elseif (key == "return") or key == "kpenter" then -- this is the big one
      local setting = nil
      if self.labels[self.screen][output.cursorY][output.cursorX] then
        setting = self.labels[self.screen][output.cursorY][output.cursorX]
      elseif self.labels[self.screen][output.cursorY] then
        setting = self.labels[self.screen][output.cursorY]
      end
      
      if setting and not setting.disabled then
        --if it's a checkbox, easy enough, just swap whatever the setting is
        if setting.checkbox ~= nil then 
          prefs[setting.id] = not prefs[setting.id]
          setting.checkbox = not setting.checkbox
        end
        --Handle special cases:
        local split = explode(setting.id,":")
        if split[1] == 'keybindings' then --reset keys
          action = "setKeys"
          self.replaceSetting = setting
          self.replaceKey = split[2]
          self.keyError = "Choose a key for " .. setting.label .. ":"
        elseif setting.id == "noImages" then
          self:make_controls() -- swap shadows/font size
          if prefs['noImages'] then
            images = {}
            love.mouse.setCursor()
          else
            output:load_all_images()
            output:load_ui()
          end
        elseif setting.id == "arrowKeys" then
          self:make_controls() --refresh all the control labels, because this will change some of the keybindings too
        elseif setting.id == "defaultkeys" then
          package.loaded['keybindings'] = nil
          require "keybindings"
          self:make_controls() --redraw all settings to show default keys
          self.replaceKey = nil
          self.replaceSetting = nil
          self.keyError=nil
          action = "moving"
        elseif setting.id == "fullscreen" then
          if prefs['fullscreen'] then
            love.window.setMode(prefs['width'],prefs['height'],{fullscreen=prefs['fullscreen'],resizable=true,minwidth=1024,minheight=768})
          else
            love.window.setMode((prefs['oldwidth'] or prefs['width']),(prefs['oldheight'] or prefs['height']),{fullscreen=prefs['fullscreen'],resizable=true,minwidth=1024,minheight=768})
          end
          self:make_controls() -- remake controls so it shows/hides the resolutions, as necessary
        elseif setting.id == "vsync" then
          love.window.setMode(prefs['width'],prefs['height'],{fullscreen=prefs['fullscreen'],vsync=prefs['vsync'],resizable=true,minwidth=1024,minheight=768})
        elseif split[1] == "resolution" then
          love.window.setMode(split[2],split[3],{fullscreen=prefs['fullscreen'],resizable=true,minwidth=1024,minheight=768})
          prefs['width'] = split[2]
          prefs['height'] = split[3]
          self:make_controls()
        elseif split[1] == "screen" then
          self.screen = split[2]
          self.replaceKey = nil
          self.replaceSetting = nil
          self.keyError=nil
          action = "moving"
        elseif setting.id == "soundDown" then
          prefs['soundVolume'] = prefs['soundVolume'] - 10
          if prefs['soundVolume'] < 0 then prefs['soundVolume'] = 0 end
          soundTags.sfx.volume = prefs['soundVolume']/100
        elseif setting.id == "soundUp" then
          prefs['soundVolume'] = prefs['soundVolume'] + 10
          if prefs['soundVolume'] > 100 then prefs['soundVolume'] = 100 end
          soundTags.sfx.volume = prefs['soundVolume']/100
        elseif setting.id == "musicDown" then
          prefs['musicVolume'] = prefs['musicVolume'] - 10
          if prefs['musicVolume'] < 0 then prefs['musicVolume'] = 0 end
          soundTags.music.volume = prefs['musicVolume']/100
        elseif setting.id == "musicUp" then
          prefs['musicVolume'] = prefs['musicVolume'] + 10
          if prefs['musicVolume'] > 100 then prefs['musicVolume'] = 100 end
          soundTags.music.volume = prefs['musicVolume']/100
        elseif setting.id == "uiScaleUp" then
          prefs['uiScale'] = prefs['uiScale'] + .1
        elseif setting.id == "uiScaleDown" then
          prefs['uiScale'] = prefs['uiScale'] - .1
        elseif setting.id == "asciiSizeUp" then
          prefs['asciiSize'] = prefs['asciiSize'] + 1
          fonts.mapFont = love.graphics.newFont("VeraMono.ttf",prefs['asciiSize'])
        elseif setting.id == "asciiSizeDown" then
          prefs['asciiSize'] = prefs['asciiSize'] - 1
          if prefs['asciiSize'] < 8 then prefs['asciiSize'] = 8 end
          fonts.mapFont = love.graphics.newFont("VeraMono.ttf",prefs['asciiSize'])
        end
      end
    end -- end key check
  end -- end if that checks if we're setting keys
end -- end function

function settings:mousepressed(x,y,button)
  local width = love.graphics.getWidth()
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then 
    self:switchBack()
  elseif action == "setKeys" then
    self:make_controls() --refresh all the control labels
    self.replaceKey = nil
    self.replaceSetting = nil
    action = "moving"
    self:keypressed("return")
  elseif x > width/4+16 and x < (width/4)*3 then
    self:keypressed("return")
  else
    self:switchBack()
  end
end

function settings:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
    return
  end
  --Mouse highlighting setting code:
	local x,y = love.mouse.getPosition()
	if (y ~= output.mouseY or x ~= output.mouseX) then -- only do this if the mouse has moved
		output.mouseY = y
    output.mouseX = x
    for sy,setting in pairs(self.labels[self.screen]) do
      local stop = false
      if setting[1] then
        for sx,s in pairs(setting) do
          if x > s.x-8 and x < s.x+s.width+8 and y > s.y-4 and y < s.y+s.height+4 then
            output.cursorX,output.cursorY = sx,sy
            stop = true
          end --end x setting check if
        end --end x setting for
      elseif x > setting.x-8 and x < setting.x+setting.width+8 and y > setting.y-4 and y < setting.y+setting.height+4 then
        output.cursorY = sy
        stop = true
      end --end y setting check if
      if stop == true then break end
    end --end y setting for
	end
  --Set the 
  if output.cursorX < 1 then output.cursorX = 1 end
  if output.cursorY > #self.labels[self.screen] then output.cursorY = #self.labels[self.screen] end
  if self.labels[self.screen][output.cursorY][1] then
    if output.cursorX > #self.labels[self.screen][output.cursorY] then output.cursorX = #self.labels[self.screen][output.cursorY] end
  end
end

function settings:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  self.replaceKey = nil
  self.replaceSetting = nil
  self.keyError=nil
  action = "moving"
  Timer.after(0.2,function() self.switchNow=true end)
end

function Setting:init(id,label,x,y,checkbox,center,width,xMod,font,button)
  xMod = xMod or 0
  self.id = id
  self.font = font or fonts.textFont
  self.label = label
  self.checkbox = checkbox
  self.button = button
  self.y = math.floor(y)
  self.height = math.floor(self.image and images[self.image]:getHeight() or self.font:getHeight())
  local textWidth = self.font:getWidth(label)
  if center or not width then
    self.width = math.floor(textWidth + (checkbox ~= nil and 32 or 0))
  else
    self.width=width
  end
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
    if self.button then
      output:button(self.x,self.y,self.width,(self.button == "small" and "small" or nil),(self.selected and "hover" or nil),self.label)
    else
      love.graphics.print(self.label,self.x,self.y)
    end
    if self.disabled then setColor(255,255,255,255) end
  else
    if prefs['noImages'] then
      if self.disabled then setColor(150,150,150,255) end
      love.graphics.print((self.checkbox and "(Y)" or "(N)"),self.x,self.y)
      if self.disabled then setColor(255,255,255,255) end
    else
      love.graphics.draw((self.checkbox and images.uicheckboxchecked or images.uicheckbox),self.x,self.y)
    end
    if self.disabled then setColor(150,150,150,255) end
    if self.button then
      output:button(self.x,self.y,self.width,(self.button == "small" and "small" or nil),(self.selected and "hover" or nil),self.label)
    else
      love.graphics.print(self.label,self.x+32,self.y)
    end
    if self.disabled then setColor(255,255,255,255) end
  end
end