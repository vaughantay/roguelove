--Notification popup:
Notification = Class{}

function Notification:init(text,image)
  self.appearing = true
  self.text = text
  self.image = images[image] and image or nil
  local width = 256
  local _, tlines = fonts.textFont:getWrap(text,width)
  local imgX,imgY = math.floor(width/2)-16,48+#tlines*14
  self.height = imgY+64
  self.yMod = -self.height-32
end

function Notification:draw()
  local img = self.image and images[self.image] or nil
  local text = self.text
  local width = 256
  local fontSize = fonts.textFont:getHeight()
  local _, tlines = fonts.textFont:getWrap(text,width)
  local imgX,imgY = (not img and 0 or math.floor(img:getWidth()/2)-16),48+#tlines*fontSize
  local height = imgY+(img and img:getHeight() or 0)

  love.graphics.setFont(fonts.textFont)
  if prefs['noImages'] then
    output:draw_window(0,16+self.yMod,width,height+self.yMod-64)
    love.graphics.printf(text,0,34+self.yMod,width+32,"center")
  else
    output:draw_window(0,16+self.yMod,width,height+self.yMod)
    love.graphics.printf(text,0,34+self.yMod,width+32,"center")
    if self.image then love.graphics.draw(self.image,imgX,imgY+self.yMod) end
  end
end

function Notification:update(dt)
  if self.appearing == true then
    self.yMod = math.floor(self.yMod+dt*5*(self.height-32))
  elseif self.waiting > 0 then
    self.waiting = self.waiting-dt
  else
    self.yMod = math.floor(self.yMod-dt*5*(self.height-32))
  end
  
  if self.yMod < -self.height and self.yMod ~= 1000 and not self.appearing then
    self.done = true
  elseif self.yMod >= 0 then
    if self.waiting == nil then self.waiting = 1.5 end
    self.appearing = false
  end
end