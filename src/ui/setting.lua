Setting = Class{}

function Setting:init(id,label,x,y,checkbox,center,width,xMod,font,button)
  xMod = xMod or 0
  self.id = id
  self.font = font or (button and fonts.buttonFont or fonts.textFont)
  self.label = label
  self.checkbox = checkbox
  self.button = button
  self.center = center
  self.y = math.floor(y)
  self.height = math.floor(self.image and images[self.image]:getHeight() or self.font:getHeight())
  self.maxY = self.y+self.height
  local textWidth = self.font:getWidth(label)
  if center or not width and not button then
    self.width = math.floor(textWidth + (checkbox ~= nil and 32 or 0))
  elseif button then
    local b = output:button(1,1,nil,(self.button == "small" and "small" or nil),(self.selected and "hover" or nil),self.label,true)
    self.width = b.maxX-b.minX
  else
    self.width=width
  end
  local lWidth,tlines = self.font:getWrap(label,self.width)
  self.height = math.max(#tlines*self.font:getHeight(),self.height)
  if center then
    self.x = math.floor((x+width/2)-textWidth/2 + xMod)
  else
    self.x = math.floor(x + xMod)
  end
end

function Setting:draw(selected)
  if love.graphics.getFont ~= self.font then love.graphics.setFont(self.font) end
  if self.checkbox == nil then
    if self.disabled then setColor(150,150,150,255) end
    if self.button then
      local b = output:button(self.x,self.y,nil,(self.button == "small" and "small" or nil),(selected and "hover" or nil),self.label,true)
      self.width = b.maxX-b.minX
    else
      if self.center then
        love.graphics.printf(self.label,self.x,self.y,self.width,"center")
      else
        love.graphics.printf(self.label,self.x,self.y,self.width)
      end
    end
    if self.disabled then setColor(255,255,255,255) end
  else
    if prefs['noImages'] then
      if self.disabled then setColor(150,150,150,255) end
      love.graphics.print((self.checkbox and "(Y)" or "(N)"),self.x,self.y)
      if self.disabled then setColor(255,255,255,255) end
    else
      setColor(255,255,255,255)
      love.graphics.draw((self.checkbox and images.uicheckboxchecked or images.uicheckbox),self.x,self.y)
      setColor(255,255,255,255)
    end
    if self.disabled then setColor(150,150,150,255) end
    if self.button then
      local b = output:button(self.x,self.y,nil,(self.button == "small" and "small" or nil),(self.selected and "hover" or nil),self.label,true)
      self.width = b.maxX-b.minX
    else
      love.graphics.print(self.label,self.x+32,self.y)
    end
    if self.disabled then setColor(255,255,255,255) end
  end
end