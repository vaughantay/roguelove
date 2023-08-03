achievements = {}

function achievements:check(flag)
  for id,a in pairs(achievementList) do
    if a.checkType == flag and a.check and not self:has_achievement(id) and not self:is_disqualified(id) then
      if a:check() == true then
        self:give_achievement(id)
      end --end if check
    end --end if checktype
  end --end for
end --end function

function achievements:has_achievement(achievement)
  if not totalstats.achievements then totalstats.achievements = {} end
  return totalstats.achievements[achievement]
end

function achievements:give_achievement(achievement)
  if not self:has_achievement(achievement) and not self:is_disqualified(achievement) and achievementList[achievement] then
    totalstats.achievements[achievement] = true
    print("Achievement Unlocked: " .. achievementList[achievement].name)
    output:out("Achievement Unlocked: " .. achievementList[achievement].name .. " - " .. achievementList[achievement].description)
    output:show_achievement_popup(achievement)
    if Steam then
      Steam.userStats.setAchievement(string.upper(achievement))
    end
  end
end

function achievements:disqualify(achievement)
  if not currGame.achievementDisqualifications then currGame.achievementDisqualifications = {} end
  currGame.achievementDisqualifications[achievement] = true
end

function achievements:is_disqualified(achievement)
  if currGame and currGame.achievementDisqualifications then
    return currGame.achievementDisqualifications[achievement]
  end
  return false
end


--Achievement popup:
AchievementPopup = Class{}

function AchievementPopup:init(achievement)
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

function AchievementPopup:draw()
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

function AchievementPopup:update(dt)
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