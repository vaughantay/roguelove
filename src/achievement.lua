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
    output:show_achievement_notification(achievement)
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