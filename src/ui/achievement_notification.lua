--Achievement popup:
AchievementNotification = Class{}

function AchievementNotification:init(achievement)
  self.achievement=achievement
  self.a = 1
  self.appearing = true
  local text = "Achievement Unlocked:\n" .. achievementList[self.achievement].name
  local width = 256
  local _, tlines = fonts.textFont:getWrap(text,width)
  local imgX,imgY = math.floor(width/2)-16,48+#tlines*14
  self.height = imgY+64
  self.yMod = -self.height-32
end

function AchievementNotification:draw()
  local img = (images['achievement' .. self.achievement] and images['achievement' .. self.achievement] or images['achievementunknown'])
  local text = "Achievement Unlocked:\n" .. achievementList[self.achievement].name
  local width = 256
  local _, tlines = fonts.textFont:getWrap(text,width)
  local imgX,imgY = math.floor(width/2)-16,48+#tlines*14
  local height = imgY+64

  love.graphics.setFont(fonts.textFont)
  if prefs['noImages'] then
    output:draw_window(0,16+self.yMod,width,height+self.yMod-64,self.a)
    love.graphics.printf(text,0,34+self.yMod,width+32,"center")
  else
    output:draw_window(0,16+self.yMod,width,height+self.yMod,self.a)
    love.graphics.printf(text,0,34+self.yMod,width+32,"center")
    love.graphics.rectangle("line",imgX,imgY+self.yMod,64,64)
    love.graphics.draw(img,imgX,imgY+self.yMod)
  end
end

function AchievementNotification:update(dt)
  if self.appearing == true then
    self.yMod = math.floor(self.yMod+dt*5*(self.height-32))
  elseif self.waiting > 0 then
    self.waiting = self.waiting-dt
  else
    self.yMod = math.floor(self.yMod-dt*5*(self.height-32))
  end
  
  if self.yMod < -self.height and self.yMod ~= 1000 then
    self.done = true
  elseif self.yMod >= 0 then
    if self.waiting == nil then self.waiting = 1.5 end
    self.appearing = false
  end
end