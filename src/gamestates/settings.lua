settings = {}

function settings:enter(previous)
  self.previous = previous
  self:make_controls()
  self.screen = "controls"
  self.yModPerc = 100
  self.blackScreenAlpha=0
  self.cursorX,self.cursorY=1,1
  self.scrollY = 0
  self.scrollMax = 0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=125})
  output:sound('stoneslideshort',2)
end

function settings:make_controls()
  local uiScale = prefs['uiScale']
  local width = love.graphics:getWidth()
  width = round(width/uiScale)
  local size=250
  local startX=math.floor(width/3)
  local keyStartX=math.floor(width/2)-size+15
  self.labels = {
    controls = {},
    graphics = {}
  }
  local startY = 100
  self.startY = startY
  local fontSize = prefs['fontSize']
  local increase = fontSize+6
  local controlIncrease = fontSize+4
  
  self.labels.controls[1] = {}
  local cwidth = fonts.buttonFont:getWidth('Controls')
  local gwidth = fonts.buttonFont:getWidth("Graphics/Sound")
  local twidth = round(cwidth+gwidth)/2
  self.labels.controls[1][1] = Setting('screen:controls','Controls',math.floor(width/2)-twidth,50,nil,false,nil,nil,nil,true)
  self.labels.controls[1][2] = Setting('screen:graphics','Graphics/Sound',(width/2),50,nil,false,nil,nil,nil,true)
  self.labels.controls[1][1].disabled = true
  local controlY = startY
  self.labels.controls[#self.labels.controls+1] = Setting('mouseMovesMap',"Mouse on Screen Edge Scrolls Map",startX,controlY,prefs['mouseMovesMap'],true,startX)
  controlY = controlY + increase
  if self.labels.controls[#self.labels.controls].checkbox then
    local scrollW = fonts.textFont:getWidth("Mouse Scroll Delay (ms): " .. prefs['mouseScrollTime']*1000)
    local plusW = math.ceil(scrollW/2)+16
    self.labels.controls[#self.labels.controls+1] = Setting(nil,"Mouse Scroll Delay (ms): " .. prefs['mouseScrollTime']*1000,startX,controlY,nil,true,startX)
    self.labels.controls[#self.labels.controls][1] = Setting('scrollSpeedDown',"-",width/2-plusW,controlY)
    self.labels.controls[#self.labels.controls][2] = Setting('scrollSpeedUp',"+",width/2+plusW,controlY)
    controlY = controlY+increase
  end
  self.labels.controls[#self.labels.controls+1] = Setting('captureMouse',"Lock Mouse to Game Screen",startX,controlY,prefs['captureMouse'],true,startX)
  local controlStartY=startY+increase*(#self.labels.controls)
  
  --Sort out the keybindings first:
  local sortedKB = {}
  local biggestCommand = "Northwest"
  for command,info in pairs(keybindings) do
    local category = info.category or "Miscellaneous"
    if not sortedKB[category] then sortedKB[category] = {} end
    sortedKB[category][command] = info
    if string.len(info.description) > string.len(biggestCommand) then
      biggestCommand = info.description
    end
  end
  self.keybindings = {}
  for _,category in ipairs(keybindings_order) do
    if sortedKB[category] then
      self.keybindings[#self.keybindings+1] = sortedKB[category]
    end
  end
  
  --Draw the keybinding settings:
  local biggestLeft = fonts.textFont:getWidth('Right Arrow')+8
  local biggestLeftLabel = fonts.textFont:getWidth(biggestCommand)+8
  local leftColumnX = math.floor(width/2 - ((biggestLeftLabel+biggestLeft*2)/2)-4)
  local leftW = biggestLeft*2+biggestLeftLabel
  local leftColumnLineX = leftColumnX+biggestLeftLabel
  local rightColumnLineX = leftColumnLineX+biggestLeft
  local totalW = biggestLeft*2+biggestLeftLabel
  local kb = #self.labels.controls+1
  local printY = controlStartY-2
  self.controlStartY=printY
  
  local controlCount = 0
  
  for _,kb_category in ipairs(self.keybindings) do
    printY=printY+controlIncrease
    controlCount = controlCount+1
    for command,info in pairs(kb_category) do
      self.labels.controls[kb] = {}
      --self.labels.controls[kb][1] = Setting('keybindings:' .. command,info.description,leftColumnX,printY,nil,nil,leftW)
      local firstKey, secondKey = input:get_keys(command)
      self.labels.controls[kb][1] = Setting('keybindings:' .. command.. ":1",(firstKey and firstKey or ""),leftColumnLineX,printY,nil,true,biggestLeft)
      self.labels.controls[kb][1].x,self.labels.controls[kb][1].width = leftColumnLineX,biggestLeft
      self.labels.controls[kb][1].description = info.description
      self.labels.controls[kb][2] = Setting('keybindings:' .. command .. ":2",(secondKey and secondKey or ""),rightColumnLineX,printY,nil,true,biggestLeft)
      self.labels.controls[kb][2].x,self.labels.controls[kb][2].width = rightColumnLineX,biggestLeft
      self.labels.controls[kb][2].description = info.description
      printY=printY+controlIncrease
      controlCount = controlCount+1
      kb=kb+1
    end
  end
  self.controlCount = controlCount
  self.labels.controls[kb] = Setting('defaultkeys',"Restore Default Keys",startX,printY+controlIncrease,nil,true,startX,nil,nil,true)
  local lastControl = self.labels.controls[#self.labels.controls]
  self.controlsMaxY = lastControl.maxY
  
  self.labels.graphics[1] = {}
  self.labels.graphics[#self.labels.graphics][1] = Setting('screen:controls','Controls',math.floor(width/2)-twidth,50,nil,false,nil,nil,nil,true)
  self.labels.graphics[#self.labels.graphics][2] = Setting('screen:graphics','Graphics/Sound',(width/2),50,nil,false,nil,nil,nil,true)
  self.labels.graphics[#self.labels.graphics][2].disabled = true
  local soundW = fonts.textFont:getWidth("Sound Volume: " .. prefs['soundVolume'] .. "%")
  local musicW = fonts.textFont:getWidth("Music Volume: " .. prefs['musicVolume'] .. "%")
  local uiScaleW = fonts.textFont:getWidth("UI Scaling: " .. prefs['uiScale']*100 .. "%")
  local fontSizeW = fonts.textFont:getWidth("Font Size: " .. prefs['fontSize'])
  local descFontSizeW = fonts.textFont:getWidth("Tooltip Font Size: " .. prefs['descFontSize'])
  local plusW = math.ceil(math.max(soundW,musicW,uiScaleW,fontSizeW,descFontSizeW)/2)+16
  self.labels.graphics[#self.labels.graphics+1] = {}
  self.labels.graphics[#self.labels.graphics][1] = Setting('soundDown',"-",width/2-plusW,startY)
  self.labels.graphics[#self.labels.graphics][2] = Setting('soundUp',"+",width/2+plusW,startY)
  self.labels.graphics[#self.labels.graphics+1] = {}
  self.labels.graphics[#self.labels.graphics][1] = Setting('musicDown',"-",width/2-plusW,startY+increase)
  self.labels.graphics[#self.labels.graphics][2] = Setting('musicUp',"+",width/2+plusW,startY+increase)
  self.labels.graphics[#self.labels.graphics+1] = {}
  self.labels.graphics[#self.labels.graphics][1] = Setting('uiScaleDown',"-",width/2-plusW,startY+increase*2)
  self.labels.graphics[#self.labels.graphics][2] = Setting('uiScaleUp',"+",width/2+plusW,startY+increase*2)
  self.labels.graphics[#self.labels.graphics+1] = {}
  self.labels.graphics[#self.labels.graphics][1] = Setting('fontSizeDown',"-",width/2-plusW,startY+increase*3)
  self.labels.graphics[#self.labels.graphics][2] = Setting('fontSizeUp',"+",width/2+plusW,startY+increase*3)
  self.labels.graphics[#self.labels.graphics+1] = {}
  self.labels.graphics[#self.labels.graphics][1] = Setting('descFontSizeDown',"-",width/2-plusW,startY+increase*4)
  self.labels.graphics[#self.labels.graphics][2] = Setting('descFontSizeUp',"+",width/2+plusW,startY+increase*4)
  self.labels.graphics[#self.labels.graphics+1] = Setting('fullscreen',"Fullscreen",startX,startY+increase*5,prefs['fullscreen'],true,startX)
  self.labels.graphics[#self.labels.graphics+1] = Setting('vsync',"Vsync",startX,startY+increase*6,prefs['vsync'],true,startX)
  self.labels.graphics[#self.labels.graphics+1] = Setting('minimap',"Mini-map",startX,startY+increase*7,prefs['minimap'],true,startX)
  self.labels.graphics[#self.labels.graphics+1] = Setting('healthbars',"Show Health Bars on Map",startX,startY+increase*8,prefs['healthbars'],true,startX)
  self.labels.graphics[#self.labels.graphics+1] = Setting('noSmoothCamera',"Disable Smooth Camera",startX,startY+increase*9,prefs['noSmoothCamera'],true,startX)
  self.labels.graphics[#self.labels.graphics+1] = Setting('noSmoothMovement',"Disable Smooth Movement",startX,startY+increase*10,prefs['noSmoothMovement'],true,startX)
  self.labels.graphics[#self.labels.graphics+1] = Setting('noImages',"ASCII Mode",startX,startY+increase*11,prefs['noImages'],true,startX)
  if prefs['noImages'] then
    local asciiW = math.ceil(fonts.textFont:getWidth("ASCII Font Size: " .. prefs['asciiSize'])/2)+16
    self.labels.graphics[#self.labels.graphics+1] = {}
    self.labels.graphics[#self.labels.graphics][1] = Setting('asciiSizeDown',"-",width/2-asciiW,startY+increase*12)
    self.labels.graphics[#self.labels.graphics][2] = Setting('asciiSizeUp',"+",width/2+asciiW,startY+increase*12)
  else
    self.labels.graphics[#self.labels.graphics+1] = Setting('creatureShadows',"Creature Shadows",startX,startY+increase*12,prefs['creatureShadows'],true,startX)
    self.labels.graphics[#self.labels.graphics+1] = Setting('creatureAnimations',"Creature Animations",startX,startY+increase*13,prefs['creatureAnimations'],true,startX)
  end
  local lastGraphic = self.labels.graphics[#self.labels.graphics]
  self.graphicsMaxY = (lastGraphic.maxY or lastGraphic[1].maxY)
end

function settings:draw()
  local uiScale = prefs['uiScale']
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  love.graphics.setFont(fonts.textFont)
  self.previous:draw()
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle("fill",0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  width,height = round(width/uiScale),round(height/uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  
  local padding = (prefs['noImages'] and 16 or 32)
  output:draw_window(1,1,math.floor(width-padding),math.floor(height-padding))
  
  --Draw the top buttons before creating stencil/scroll
  self.labels[self.screen][1][1]:draw()
  self.labels[self.screen][1][2]:draw()
  
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",1,self.startY,math.floor(width-padding),height-self.startY-2-math.floor(padding/2))
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
  --Draw the highlight around the active setting:
  local activeSetting = nil
  if self.replaceSetting then
    local setting = self.replaceSetting
    setColor(150,150,150,255)
    love.graphics.rectangle("fill",setting.x,setting.y-2,setting.width,setting.height+2)
    setColor(255,255,255,255)
  elseif self.labels[self.screen][self.cursorY] then
    local setting = self.labels[self.screen][self.cursorY]
    if setting[1] then
      setting = (setting[self.cursorX] or setting[1])
    end --end cursorX setting check
    if not setting.button then
      setColor(100,100,100,255)
      local split = explode(setting.id,":")
      if split[1] == 'keybindings' then
        love.graphics.rectangle("fill",setting.x,setting.y-2,setting.width,setting.height+2)
      else
        love.graphics.rectangle("fill",setting.x-8,setting.y-4,setting.width+16,setting.height+8)
      end
      setColor(255,255,255,255)
    end
    activeSetting = setting
  end --end active setting check
  --Draw settings:
  for id,setting in ipairs(self.labels[self.screen]) do
    if setting[1] then --an array holding more 
      for _,s in ipairs(setting) do
        if id ~= 1 then s:draw() end
        if s == activeSetting then
          s.selected = true
        else
          s.selected = nil
        end
      end --end nested for
      if setting.label then setting:draw() end
    else
      if id ~= 1 then setting:draw() end
      if setting == activeSetting then
        setting.selected = true
      else
        setting.selected = nil
      end
    end --end setting table if
  end --end setting for
  
  local size=250
  local startX=math.floor(width/2)-size+15
  local startY = 100
  local fontSize = prefs['fontSize']
  local increase = fontSize+6
  
  if self.screen == "controls" then
    local controlIncrease = fontSize+4
    local controlCount = self.controlCount
    
    local biggestCommand = "Northwest"
    for command,info in pairs(keybindings) do
      if string.len(info.description) > string.len(biggestCommand) then
        biggestCommand = info.description
      end
    end
    local biggestLeft = fonts.textFont:getWidth('Right Arrow')+8
    local biggestLeftLabel = fonts.textFont:getWidth(biggestCommand)+8
    local leftColumnX = math.floor(width/2 - ((biggestLeftLabel+biggestLeft*2)/2)-4)
    local leftW = biggestLeft*2+biggestLeftLabel
    local leftColumnLineX = leftColumnX+biggestLeftLabel
    local rightColumnLineX = leftColumnLineX+biggestLeft
    local totalW = biggestLeft*2+biggestLeftLabel
    
    love.graphics.setFont(fonts.textFont)
    if self.keyError then
      love.graphics.printf(self.keyError,leftColumnX,self.controlStartY-fontSize-4,totalW,'center')
    end
    
    --Draw the grid for keybindings, starting with the general outline rectangles and the vertical separators
    love.graphics.line(leftColumnLineX,self.controlStartY,leftColumnLineX,self.controlStartY+controlIncrease*controlCount)
    love.graphics.line(rightColumnLineX,self.controlStartY,rightColumnLineX,self.controlStartY+controlIncrease*controlCount)
    love.graphics.rectangle('line',leftColumnX,self.controlStartY,totalW,controlIncrease*controlCount)
    --Draw the lines for each key:
    for y = self.controlStartY+fontSize,self.controlStartY+controlIncrease*(controlCount-1),controlIncrease do
      love.graphics.line(leftColumnX,y+2,leftColumnX+totalW,y+2)
    end
    
    local printY = self.controlStartY
    for _,kb_category in ipairs(self.keybindings) do
      local category_printed = false
      for command,info in pairs(kb_category) do
        if not category_printed then
          love.graphics.rectangle("line",leftColumnX,printY,totalW,fontSize)
          setColor(50,50,50,255)
          love.graphics.rectangle("fill",leftColumnX,printY,totalW,fontSize)
          setColor(255,255,255,255)
          love.graphics.printf(info.category,leftColumnX,printY,totalW,"center")
          printY=printY+controlIncrease
          category_printed=true
        end
        love.graphics.printf(info.description,leftColumnX,printY,biggestLeftLabel,"center")
        printY=printY+controlIncrease
      end
    end
  elseif self.screen == "graphics" then
    love.graphics.printf("Sound Volume: " .. prefs['soundVolume'] .. "%",math.floor(width/4),startY,math.floor(width/4*2),"center")
    love.graphics.printf("Music Volume: " .. prefs['musicVolume'] .. "%",math.floor(width/4),startY+increase,math.floor(width/4*2),"center")
    love.graphics.printf("UI Scaling: " .. prefs['uiScale']*100 .. "%",math.floor(width/4),startY+increase*2,math.floor(width/4*2),"center")
    love.graphics.printf("Font Size: " .. prefs['fontSize'],math.floor(width/4),startY+increase*3,math.floor(width/4*2),"center")
    love.graphics.printf("Tooltip Font Size: " .. prefs['descFontSize'],math.floor(width/4),startY+increase*4,math.floor(width/4*2),"center")
    if prefs['noImages'] then love.graphics.printf("ASCII Font Size: " .. prefs['asciiSize'],math.floor(width/4),startY+increase*15,math.floor(width/4*2),"center") end
    --add special code here
  end
  love.graphics.setStencilTest()
  love.graphics.pop()
  --Scrollbars
  local maxY = (self.screen == "controls" and self.controlsMaxY or self.graphicsMaxY)
  if maxY*uiScale > height-startY then
    self.scrollMax = math.ceil((maxY-(startY+(height-startY))+padding))
    if self.scrollMax < 0 then --I don't know why this is sometimes the case but I'm too tired to figure it out, and this fixes the problem so...
      self.scrollMax = 0
    else
      local scrollAmt = self.scrollY/self.scrollMax
      self.scrollPositions = output:scrollbar(width-32,startY,math.floor((height-32)),scrollAmt,true)
    end
  else
    self.scrollMax = 0
  end
  self.scrollY = math.min(self.scrollY,self.scrollMax)
  
  self.closebutton = output:closebutton((prefs['noImages'] and 8 or 24),24,nil,true)
  love.graphics.pop()
end --end draw

function settings:buttonpressed(key,scancode,isRepeat,controllerType)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width,height = round(width/uiScale),round(height/uiScale)
  if (action == "setKeys") then
    local possiblePars,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
    if possibleParse ~= "escape" then
      for k, val in pairs(keybindings) do
        if val == key or val[1] == key or val[2] == key then
          self.keyError = "Key " .. key .. " already in use!"
          return
        end
       end -- end for loop
      keybindings[self.replaceKey].keyboard = (keybindings[self.replaceKey].keyboard or {})
      keybindings[self.replaceKey].keyboard[self.replaceWhich] = key
      self:make_controls() --refresh all the control labels
      self.replaceKey = nil
      self.replaceWhich = nil
      self.replaceSetting = nil
      self.keyError=nil
      action = "moving"
    elseif possibleParse == "escape" then
      self:make_controls() --refresh all the control labels
      self.replaceKey = nil
      self.replaceWhich = nil
      self.replaceSetting = nil
      self.keyError=nil
      action = "moving"
    end -- end check that makes sure it's not a reserved key
  else -- end setting keys
    key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
    if (key == "escape") then
      self:switchBack()
    elseif (key == "north") then
      if self.cursorY > 1 then
        self.cursorY = self.cursorY-1
        if (not self.labels[self.screen][self.cursorY-1]) or (self.labels[self.screen][self.cursorY-1].y or self.labels[self.screen][self.cursorY-1][1].y)-self.scrollY < self.startY then
          self:scrollUp()
        end
      end
    elseif (key == "south") then
      if self.labels[self.screen][self.cursorY+1] ~= nil then
        self.cursorY = self.cursorY+1
        if (not self.labels[self.screen][self.cursorY+1]) or (self.labels[self.screen][self.cursorY+1].maxY or self.labels[self.screen][self.cursorY+1][1].maxY)-self.scrollY > height then
          self:scrollDown()
        end
      end
    elseif (key == "west") then
      if self.cursorX > 1 then self.cursorX=self.cursorX-1 end
    elseif (key == "east") then
      self.cursorX = self.cursorX+1
    elseif (key == "enter") or key == "wait" then -- this is the big one
      local setting = nil
      if self.labels[self.screen][self.cursorY][self.cursorX] then
        setting = self.labels[self.screen][self.cursorY][self.cursorX]
      elseif self.labels[self.screen][self.cursorY] then
        setting = self.labels[self.screen][self.cursorY]
      end
      
      if setting and not setting.disabled then
        --if it's a checkbox, easy enough, just swap whatever the setting is
        if setting.checkbox ~= nil then 
          prefs[setting.id] = not prefs[setting.id]
          setting.checkbox = not setting.checkbox
          self:make_controls()
        end
        --Handle special cases:
        local split = explode(setting.id,":")
        if split[1] == 'keybindings' then --reset keys
          action = "setKeys"
          self.replaceSetting = setting
          self.replaceKey = split[2]
          self.replaceWhich = tonumber(split[3])
          self.keyError = "Choose a key for " .. setting.description .. ":"
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
          self.replaceWhich = nil
          self.replaceSetting = nil
          self.keyError=nil
          action = "moving"
        elseif setting.id == "fullscreen" then
          if prefs['fullscreen'] then
            love.window.setMode(prefs['width'],prefs['height'],{fullscreen=prefs['fullscreen'],resizable=true,minwidth=1280,minheight=720})
          else
            love.window.setMode((prefs['oldwidth'] or prefs['width']),(prefs['oldheight'] or prefs['height']),{fullscreen=prefs['fullscreen'],resizable=true,minwidth=1280,minheight=720})
          end
          self:make_controls() -- remake controls so it shows/hides the resolutions, as necessary
        elseif setting.id == "vsync" then
          love.window.setMode(prefs['width'],prefs['height'],{fullscreen=prefs['fullscreen'],vsync=prefs['vsync'],resizable=true,minwidth=1280,minheight=720})
        elseif split[1] == "resolution" then
          love.window.setMode(split[2],split[3],{fullscreen=prefs['fullscreen'],resizable=true,minwidth=1280,minheight=720})
          prefs['width'] = split[2]
          prefs['height'] = split[3]
          self:make_controls()
        elseif split[1] == "screen" then
          self.screen = split[2]
          self.scrollY = 0
          self.replaceKey = nil
          self.replaceWhich = nil
          self.replaceSetting = nil
          self.keyError=nil
          action = "moving"
        elseif setting.id == "scrollSpeedUp" then
          prefs['mouseScrollTime'] = prefs['mouseScrollTime'] + .01
          self:make_controls()
        elseif setting.id == "scrollSpeedDown" then
          prefs['mouseScrollTime'] = math.max(prefs['mouseScrollTime'] - .01,.01)
          self:make_controls()
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
          self:make_controls()
        elseif setting.id == "uiScaleDown" then
          prefs['uiScale'] = prefs['uiScale'] - .1
          self:make_controls()
        elseif setting.id == "asciiSizeUp" then
          prefs['asciiSize'] = prefs['asciiSize'] + 1
          fonts.mapFont = love.graphics.newFont("assets/fonts/VeraMono.ttf",prefs['asciiSize'])
        elseif setting.id == "asciiSizeDown" then
          prefs['asciiSize'] = prefs['asciiSize'] - 1
          if prefs['asciiSize'] < 8 then prefs['asciiSize'] = 8 end
          fonts.mapFont = love.graphics.newFont("assets/fonts/VeraMono.ttf",prefs['asciiSize'])
        elseif setting.id == "fontSizeUp" then
          prefs['fontSize'] = prefs['fontSize'] + 1
          fonts.textFont = love.graphics.newFont(prefs['fontSize'])
          self:make_controls()
        elseif setting.id == "fontSizeDown" then
          prefs['fontSize'] = prefs['fontSize'] - 1
          if prefs['fontSize'] < 12 then prefs['fontSize'] = 12 end
          fonts.textFont = love.graphics.newFont(prefs['fontSize'])
          self:make_controls()
        elseif setting.id == "descFontSizeUp" then
          prefs['descFontSize'] = prefs['descFontSize'] + 1
          fonts.descFont = love.graphics.newFont(prefs['descFontSize'])
        elseif setting.id == "descFontSizeDown" then
          prefs['descFontSize'] = prefs['descFontSize'] - 1
          if prefs['descFontSize'] < 8 then prefs['descFontSize'] = 8 end
          fonts.descFont = love.graphics.newFont(prefs['descFontSize'])
        end
      end
    end -- end key check
  end -- end if that checks if we're setting keys
end -- end function

function settings:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  local width = love.graphics.getWidth()
  width = round(width/uiScale)
  x,y = round(x/uiScale),round(y/uiScale)
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then 
    self:switchBack()
  elseif action == "setKeys" then
    self:make_controls() --refresh all the control labels
    self.replaceKey = nil
    self.replaceWhich = nil
    self.replaceSetting = nil
    action = "moving"
    self:buttonpressed(input:get_button_name('enter'))
  elseif x > width/4+16 and x < (width/4)*3 then
    self:buttonpressed(input:get_button_name('enter'))
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
  local uiScale = (prefs['uiScale'] or 1)
  x,y = round(x/uiScale), round(y/uiScale)
	if (y ~= output.mouseY or x ~= output.mouseX) then -- only do this if the mouse has moved
		output.mouseY = y
    output.mouseX = x
    for sy,setting in pairs(self.labels[self.screen]) do
      local stop = false
      local scrollY = (sy ~= 1 and self.scrollY or 0)
      if setting[1] then
        for sx,s in ipairs(setting) do
          if x > s.x-8 and x < s.x+s.width+8 and y+scrollY > s.y-4 and y+scrollY < s.y+s.height+4 then
            self.cursorX,self.cursorY = sx,sy
            stop = true
          end --end x setting check if
        end --end x setting for
      elseif setting and x > setting.x-8 and x < setting.x+setting.width+8 and y+scrollY > setting.y-4 and y+scrollY < setting.y+setting.height+4 then
        self.cursorY = sy
        stop = true
      end --end y setting check if
      if stop == true then break end
    end --end y setting for
	end
  --Set the cursor within bounds
  if self.cursorX < 1 then self.cursorX = 1 end
  if self.cursorY > #self.labels[self.screen] then self.cursorY = #self.labels[self.screen] end
  if self.labels[self.screen][self.cursorY][1] then
    if self.cursorX > #self.labels[self.screen][self.cursorY] then self.cursorX = #self.labels[self.screen][self.cursorY] end
  end
  --Scrollbars:
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local upArrow = self.scrollPositions.upArrow
    local downArrow = self.scrollPositions.downArrow
    local elevator = self.scrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:scrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:scrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then
        self:scrollUp()
      elseif y>elevator.endY then
        self:scrollDown()
      end
    end --end clicking on arrow
  end
  if self.scrollY > self.scrollMax then
    self.scrolLY = self.scrollMax
  end
end

function settings:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  self.replaceKey = nil
  self.replaceSetting = nil
  self.replaceWhich = nil
  self.keyError=nil
  action = "moving"
  Timer.after(0.2,function() self.switchNow=true end)
end

function settings:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end --end button type if
end

function settings:scrollUp()
  local height = love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  height = round(height/uiScale)
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize*2
    if self.scrollY < prefs.fontSize*2 then
      self.scrollY = 0
    end
    if self.labels[self.screen][self.cursorY] and (self.labels[self.screen][self.cursorY].y or self.labels[self.screen][self.cursorY][1].y)-self.scrollY > height then
      self.cursorY = self.cursorY-1
    end
  end
end

function settings:scrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize*2
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
    end
    if self.labels[self.screen][self.cursorY] and (self.labels[self.screen][self.cursorY].y or self.labels[self.screen][self.cursorY][1].y)-self.scrollY < self.startY then
      self.cursorY = self.cursorY+1
    end
  end
end