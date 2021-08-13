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
  local startY = 100
  local fontSize = prefs['fontSize']
  local increase = fontSize+6
  local controlIncrease = fontSize+2
  local controlStartY=startY+increase*5
  self.labels.controls[1] = {}
  self.labels.controls[1][1] = Setting('screen:controls','Controls',math.floor(width/4)+32,50,nil,false,nil,nil,fonts.menuFont,true)
  local gwidth = fonts.menuFont:getWidth('Graphics/Sound')
  self.labels.controls[1][2] = Setting('screen:graphics','Graphics/Sound',(width/4*3)-gwidth,50,nil,false,nil,nil,fonts.menuFont,true)
  self.labels.controls[1][1].disabled = true
  self.labels.controls[2] = Setting('mouseMovesMap',"Mouse on Screen Edge Scrolls Map",startX,startY,prefs['mouseMovesMap'],true,startX)
  self.labels.controls[3] = Setting('spellShortcuts',"Use 1-9 as Spell Shortcuts",startX,startY+increase,prefs['spellShortcuts'],true,startX)
  self.labels.controls[4] = Setting('arrowKeys',"Use Arrow Keys to Move",startX,startY+increase*2,prefs['arrowKeys'],true,startX)
  self.labels.controls[5] = Setting('autoLevel',"Auto-assign Stat Increases on Kill",startX,startY+increase*3,prefs['autoLevel'],true,startX)
  local biggestLeft = fonts.textFont:getWidth('Right Arrow or ' .. keybindings['east'])+8
  local biggestLeftLabel = fonts.textFont:getWidth('Northwest')+8
  local leftColumnX = math.floor(width/2)-(biggestLeftLabel+biggestLeft)-4
  local leftW = biggestLeft+biggestLeftLabel
  self.labels.controls[6] = {Setting('keybindings:northwest',"Northwest",leftColumnX,controlStartY-2,nil,nil,leftW)}
  self.labels.controls[7] = {Setting('keybindings:north','North',leftColumnX,controlStartY+controlIncrease-2,nil,nil,leftW)}
  self.labels.controls[8] = {Setting('keybindings:northeast','Northeast',leftColumnX,controlStartY+controlIncrease*2-2,nil,nil,leftW)}
  self.labels.controls[9] = {Setting('keybindings:east','East',leftColumnX,controlStartY+controlIncrease*3-2,nil,nil,leftW)}
  self.labels.controls[10] = {Setting('keybindings:southeast','Southeast',leftColumnX,controlStartY+controlIncrease*4-2,nil,nil,leftW)}
  self.labels.controls[11] = {Setting('keybindings:south','South',leftColumnX,controlStartY+controlIncrease*5-2,nil,nil,leftW)}
  self.labels.controls[12] = {Setting('keybindings:southwest','Southwest',leftColumnX,controlStartY+controlIncrease*6-2,nil,nil,leftW)}
  self.labels.controls[13] = {Setting('keybindings:west','West',leftColumnX,controlStartY+controlIncrease*7-2,nil,nil,leftW)}
  self.labels.controls[14] = {Setting('keybindings:wait','Wait',leftColumnX,controlStartY+controlIncrease*8-2,nil,nil,leftW)}
  local rightColumnX = math.floor(width/2)+4
  local biggestRight = fonts.textFont:getWidth('Space Bar')+4
  local biggestRightLabel = fonts.textFont:getWidth('Message History')+4
  local rightColumnLineX = math.floor(width/2)+biggestRightLabel
  local rightW = biggestRight+biggestRightLabel
  self.labels.controls[6][2] = Setting('keybindings:spell','See Abilities',rightColumnX,controlStartY-2,nil,nil,rightW)
  self.labels.controls[7][2] = Setting('keybindings:charScreen','Game Stats',rightColumnX,controlStartY+controlIncrease-2,nil,nil,rightW)
  self.labels.controls[8][2] = Setting('keybindings:examine','Examine',rightColumnX,controlStartY+controlIncrease*2-2,nil,nil,rightW)
  self.labels.controls[9][2] = Setting('keybindings:messages','Message History',rightColumnX,controlStartY+controlIncrease*3-2,nil,nil,rightW)
  self.labels.controls[10][2] = Setting('keybindings:stairsUp','Use Stairs',rightColumnX,controlStartY+controlIncrease*4-2,nil,nil,rightW)
  self.labels.controls[11][2] = Setting('keybindings:ranged','Ranged Attack',rightColumnX,controlStartY+controlIncrease*5-2,nil,nil,rightW)
  self.labels.controls[12][2] = Setting('keybindings:recharge','Reload',rightColumnX,controlStartY+controlIncrease*6-2,nil,nil,rightW)
  self.labels.controls[13][2] = Setting('keybindings:possess','Possession',rightColumnX,controlStartY+controlIncrease*7-2,nil,nil,rightW)
  self.labels.controls[14][2] = Setting('keybindings:heal','Heal Body',rightColumnX,controlStartY+controlIncrease*8-2,nil,nil,rightW)
  self.labels.controls[15] = Setting('keybindings:nextTarget','Switch Target',rightColumnX,controlStartY+controlIncrease*9-2,nil,nil,rightW)
  self.labels.controls[16] = Setting('keybindings:zoomIn','Zoom In',rightColumnX,controlStartY+controlIncrease*10-2,nil,nil,rightW)
  self.labels.controls[17] = Setting('keybindings:zoomOut','Zoom Out',rightColumnX,controlStartY+controlIncrease*11-2,nil,nil,rightW)
  self.labels.controls[18] = Setting('defaultkeys',"Restore Default Keys",startX,controlStartY+controlIncrease*13-2,nil,true,startX,nil,fonts.menuFont,true)
  self.labels.graphics[1] = {}
  self.labels.graphics[1][1] = Setting('screen:controls','Controls',math.floor(width/4)+32,50,nil,false,nil,nil,fonts.menuFont,true)
  local gwidth = fonts.menuFont:getWidth('Graphics/Sound')
  self.labels.graphics[1][2] = Setting('screen:graphics','Graphics/Sound',(width/4*3)-gwidth,50,nil,false,nil,nil,fonts.menuFont,true)
  self.labels.graphics[1][2].disabled = true
  self.labels.graphics[2] = {}
  local soundW = fonts.textFont:getWidth("Sound Volume: " .. prefs['soundVolume'] .. "%")
  local musicW = fonts.textFont:getWidth("Music Volume: " .. prefs['musicVolume'] .. "%")
  local uiScaleW = fonts.textFont:getWidth("UI Scaling: " .. prefs['uiScale']*100 .. "%")
  local fontSizeW = fonts.textFont:getWidth("Font Size: " .. prefs['fontSize'])
  local descFontSizeW = fonts.textFont:getWidth("Tooltip Font Size: " .. prefs['descFontSize'])
  local plusW = math.ceil(math.max(soundW,musicW,uiScaleW,fontSizeW,descFontSizeW)/2)+16
  self.labels.graphics[2][1] = Setting('soundDown',"-",width/2-plusW,startY)
  self.labels.graphics[2][2] = Setting('soundUp',"+",width/2+plusW,startY)
  self.labels.graphics[3] = {}
  self.labels.graphics[3][1] = Setting('musicDown',"-",width/2-plusW,startY+increase)
  self.labels.graphics[3][2] = Setting('musicUp',"+",width/2+plusW,startY+increase)
  self.labels.graphics[4] = {}
  self.labels.graphics[4][1] = Setting('uiScaleDown',"-",width/2-plusW,startY+increase*2)
  self.labels.graphics[4][2] = Setting('uiScaleUp',"+",width/2+plusW,startY+increase*2)
  self.labels.graphics[5] = {}
  self.labels.graphics[5][1] = Setting('fontSizeDown',"-",width/2-plusW,startY+increase*3)
  self.labels.graphics[5][2] = Setting('fontSizeUp',"+",width/2+plusW,startY+increase*3)
  self.labels.graphics[6] = {}
  self.labels.graphics[6][1] = Setting('descFontSizeDown',"-",width/2-plusW,startY+increase*4)
  self.labels.graphics[6][2] = Setting('descFontSizeUp',"+",width/2+plusW,startY+increase*4)
  self.labels.graphics[7] = Setting('minimap',"Mini-map",startX,startY+increase*5,prefs['minimap'],true,startX)
  self.labels.graphics[8] = Setting('noSmoothCamera',"No Smooth Camera",startX,startY+increase*6,prefs['noSmoothCamera'],true,startX)
  self.labels.graphics[9] = Setting('noSmoothMovement',"No Smooth Movement",startX,startY+increase*7,prefs['noSmoothMovement'],true,startX)
  self.labels.graphics[10] = Setting('statsOnSidebar',"Show Creature Attributes on Sidebar",startX,startY+increase*8,prefs['statsOnSidebar'],true,startX)
  self.labels.graphics[11] = Setting('plainFonts',"Plain Fonts on Sidebar",startX,startY+increase*9,prefs['plainFonts'],true,startX)
  self.labels.graphics[12] = Setting('bigButtons',"Larger Buttons on Sidebar",startX,startY+increase*10,prefs['bigButtons'],true,startX)
  self.labels.graphics[13] = Setting('fullscreen',"Fullscreen",startX,startY+increase*11,prefs['fullscreen'],true,startX)
  self.labels.graphics[14] = Setting('vsync',"Vsync",startX,startY+increase*12,prefs['vsync'],true,startX)
  self.labels.graphics[15] = Setting('noImages',"ASCII Mode",startX,startY+increase*13,prefs['noImages'],true,startX)
  if prefs['noImages'] then
    local asciiW = math.ceil(fonts.textFont:getWidth("ASCII Font Size: " .. prefs['asciiSize'])/2)+16
    self.labels.graphics[16] = {}
    self.labels.graphics[16][1] = Setting('asciiSizeDown',"-",width/2-asciiW,startY+increase*14)
    self.labels.graphics[16][2] = Setting('asciiSizeUp',"+",width/2+asciiW,startY+increase*14)
  else
    self.labels.graphics[16] = Setting('creatureShadows',"Creature Shadows",startX,startY+increase*14,prefs['creatureShadows'],true,startX)
    self.labels.graphics[17] = Setting('creatureAnimations',"Creature Animations",startX,startY+increase*15,prefs['creatureAnimations'],true,startX)
  end
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
  
  local padding = (prefs['noImages'] and 16 or 32)
  output:draw_window(1,1,math.floor(width-padding),math.floor(height-padding))
  
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
        love.graphics.rectangle("fill",setting.x,setting.y,setting.width,setting.height)
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
  
  local size=250
  local startX=math.floor(width/2)-size+15
  local startY = 100
  local fontSize = prefs['fontSize']
  local increase = fontSize+6
  
  if self.screen == "controls" then
    local controlIncrease = fontSize+2
    local controlStartY=startY+increase*5
    local leftControls = 9
    local rightControls = 12
    
    love.graphics.setFont(fonts.textFont)
    if self.keyError then
      love.graphics.printf(self.keyError,math.floor(width/4),300,math.floor(width/2)+32,'center')
    end
    
    local biggestLeft = fonts.textFont:getWidth('Right Arrow or ' .. keybindings['east'])+8
    local biggestLeftLabel = fonts.textFont:getWidth('Northwest')+8
    local leftColumnX = math.floor(width/2)-(biggestLeftLabel+biggestLeft)-4
    local leftColumnLineX = leftColumnX+biggestLeftLabel
    local rightColumnX = math.floor(width/2)+4
    local biggestRight = fonts.textFont:getWidth('Space Bar')+4
    local biggestRightLabel = fonts.textFont:getWidth('Message History')+4
    local rightColumnLineX = math.floor(width/2)+biggestRightLabel
    --Draw the grid for keybindings, starting with the general outline rectangles and the vertical separators
    love.graphics.line(leftColumnLineX,controlStartY,leftColumnLineX,controlStartY+controlIncrease*leftControls)
    love.graphics.line(rightColumnLineX,controlStartY,rightColumnLineX,controlStartY+controlIncrease*rightControls)
    love.graphics.rectangle('line',leftColumnX,controlStartY,biggestLeft+biggestLeftLabel,controlIncrease*leftControls)
    love.graphics.rectangle('line',rightColumnX,controlStartY,biggestRight+biggestRightLabel,controlIncrease*rightControls)
    --Draw the lines for each key:
    for y = controlStartY+fontSize,controlStartY+controlIncrease*(rightControls-1),controlIncrease do
      if y <= controlStartY+controlIncrease*(leftControls-1) then love.graphics.line(leftColumnX,y,leftColumnX+biggestLeft+biggestLeftLabel,y) end
      love.graphics.line(rightColumnX,y,rightColumnX+biggestRight+biggestRightLabel,y)
    end
    --Draw an extra line on the right since there's an extra setting:
    
    --Print the keys used for each command:
    love.graphics.printf(keybindings['northwest'],leftColumnLineX,controlStartY-2,biggestLeft,"center")
    love.graphics.printf((not prefs['arrowKeys'] and '' or 'Up Arrow or ') .. keybindings['north'],leftColumnLineX,controlStartY+controlIncrease-2,biggestLeft,"center")
    love.graphics.printf(keybindings['northeast'],leftColumnLineX,controlStartY+controlIncrease*2,biggestLeft,"center")
    love.graphics.printf((not prefs['arrowKeys'] and '' or 'Right Arrow or ') .. keybindings['east'],leftColumnLineX,controlStartY+controlIncrease*3-2,biggestLeft,"center")
    love.graphics.printf(keybindings['southeast'],leftColumnLineX,controlStartY+controlIncrease*4-2,biggestLeft,"center")
    love.graphics.printf((not prefs['arrowKeys'] and '' or 'Down Arrow or ') .. keybindings['south'],leftColumnLineX,controlStartY+controlIncrease*5-2,biggestLeft,"center")
    love.graphics.printf(keybindings['southwest'],leftColumnLineX,controlStartY+controlIncrease*6-2,biggestLeft,"center")
    love.graphics.printf((not prefs['arrowKeys'] and '' or 'Left Arrow or ') .. keybindings['west'],leftColumnLineX,controlStartY+controlIncrease*7-2,biggestLeft,"center")
    love.graphics.printf((not prefs['arrowKeys'] and '' or 'Space Bar or ') .. keybindings['wait'],leftColumnLineX,controlStartY+controlIncrease*8-2,biggestLeft,"center")
    
    
    love.graphics.printf(keybindings['spell'],rightColumnLineX,controlStartY-2,biggestRight,"center")
    love.graphics.printf(keybindings['charScreen'],rightColumnLineX,controlStartY+controlIncrease-2,biggestRight,"center")
    love.graphics.printf(keybindings['examine'],rightColumnLineX,controlStartY+controlIncrease*2-2,biggestRight,"center")
    love.graphics.printf(keybindings['messages'],rightColumnLineX,controlStartY+controlIncrease*3-2,biggestRight,"center")
    love.graphics.printf(keybindings['stairsUp'],rightColumnLineX,controlStartY+controlIncrease*4-2,biggestRight,"center")
    love.graphics.printf(keybindings['ranged'],rightColumnLineX,controlStartY+controlIncrease*5-2,biggestRight,"center")
    love.graphics.printf(keybindings['recharge'],rightColumnLineX,controlStartY+controlIncrease*6-2,biggestRight,"center")
    --love.graphics.printf(keybindings['possess'],rightColumnLineX,controlStartY+controlIncrease*7-2,biggestRight,"center")
    --love.graphics.printf(keybindings['heal'],rightColumnLineX,controlStartY+controlIncrease*8-2,biggestRight,"center")
    love.graphics.printf(keybindings['nextTarget'],rightColumnLineX,controlStartY+controlIncrease*9-2,biggestRight,"center")
    love.graphics.printf(keybindings['zoomIn'],rightColumnLineX,controlStartY+controlIncrease*10-2,biggestRight,"center")
    love.graphics.printf(keybindings['zoomOut'],rightColumnLineX,controlStartY+controlIncrease*11-2,biggestRight,"center")
  elseif self.screen == "graphics" then
    love.graphics.printf("Sound Volume: " .. prefs['soundVolume'] .. "%",math.floor(width/4),startY,math.floor(width/4*2),"center")
    love.graphics.printf("Music Volume: " .. prefs['musicVolume'] .. "%",math.floor(width/4),startY+increase,math.floor(width/4*2),"center")
    love.graphics.printf("UI Scaling: " .. prefs['uiScale']*100 .. "%",math.floor(width/4),startY+increase*2,math.floor(width/4*2),"center")
    love.graphics.printf("Font Size: " .. prefs['fontSize'],math.floor(width/4),startY+increase*3,math.floor(width/4*2),"center")
    love.graphics.printf("Tooltip Font Size: " .. prefs['descFontSize'],math.floor(width/4),startY+increase*4,math.floor(width/4*2),"center")
    if prefs['noImages'] then love.graphics.printf("ASCII Font Size: " .. prefs['asciiSize'],math.floor(width/4),startY+increase*14,math.floor(width/4*2),"center") end
    --add special code here
  end
  self.closebutton = output:closebutton((prefs['noImages'] and 8 or 24),24)
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
    key = input:parse_key(key)
    if (key == "escape") then
      self:switchBack()
    elseif (key == "north") then
      if output.cursorY > 1 then output:moveCursor(0,-1) end
    elseif (key == "south") then
      output:moveCursor(0,1)
    elseif (key == "west") then
      if output.cursorX > 1 then output:moveCursor(-1,0) end
    elseif (key == "east") then
      output:moveCursor(1,0)
    elseif (key == "return") or key == "wait" then -- this is the big one
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