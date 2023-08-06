hotkey = {}

function hotkey:enter(previous,hotkeyItem)
  self.yModPerc = 100
  self.blackScreenAlpha=0
  tween(0.2,self,{yModPerc=0,blackScreenAlpha=75})
  output:sound('stoneslideshort',2)
  self.previous = previous
  self.hotkeyItem = hotkeyItem
end

function hotkey:draw()
  self.previous:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local midY = math.floor(height/2/uiScale)
  setColor(0,0,0,self.blackScreenAlpha)
  love.graphics.rectangle("fill",0,0,width,height)
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  
  local padding = (prefs['noImages'] and 16 or 32)
  local fontSize = prefs['fontSize']
  local hotkeyItem = self.hotkeyItem
  local name = (hotkeyItem.baseType == "item" and hotkeyItem:get_name(true) or self.hotkeyItem.name)
  local hktext = "Press a number key to use as hotkey for " .. name .. "."
  local wrapL = math.ceil(width/uiScale/2)-padding
  local _,tlines = fonts.textFont:getWrap(hktext,wrapL)
  --Window size stuff
  local startX = math.ceil(width/uiScale/4)
  local endX=math.ceil(startX+width/uiScale/2)
  local windowHeight = round(fontSize*#tlines*1.25)+padding
  local startY = round(midY-windowHeight/2)
  local endY = startY+windowHeight
  output:draw_window(startX,startY,endX,endY)
  local printY = startY + padding
  local printX = startX + padding
  love.graphics.printf(hktext,printX,printY,wrapL,"center")
  
  self.closebutton = output:closebutton(startX+8,startY+8,nil,true)
  love.graphics.pop()
end

function hotkey:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
  end
end

function hotkey:switchBack()
  tween(0.2,self,{yModPerc=100,blackScreenAlpha=0})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function hotkey:buttonpressed(key)
  local hotkeyItem = self.hotkeyItem
  local origKey = key
  key = input:parse_key(key)
  if (origKey == "escape") or key == "enter" then
    self:switchBack()
  elseif tonumber(key) then
    local keynum = tonumber(key)
    --Delete old item from hotkey:
    if player.hotkeys[keynum] then
      player.hotkeys[keynum].hotkeyItem.hotkey = nil
    end
    --Delete old hotkey for this item, if applicable
    for i=1,10 do
      if player.hotkeys[i] and player.hotkeys[i].hotkeyItem == hotkeyItem then
        player.hotkeys[i] = nil
      end
    end
    --Actually assign the key:
    player.hotkeys[keynum] = {type=hotkeyItem.baseType,hotkeyItem=hotkeyItem}
    hotkeyItem.hotkey = keynum
    self:switchBack()
  end
end

function hotkey:mousepressed(x,y,button)
  self:switchBack()
end