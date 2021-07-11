possibleMissions = {}

local killtownies = {
  name = "Kill Townies",
  description = "Kill 5 townspeople, you monster.",
}
function killtownies:start()
  output:out("Time to kill them, you monster.")
  return "Time to kill them, you monster."
end
function killtownies:kills(killer,victim)
  if killer == player and victim.id == "townsperson" then
    local townies = update_mission_status('killtownies',1)
    if townies <= 5 then
      output:out("You've killed " .. townies .. ", you monster.")
    end
  end
end
function killtownies:can_finish()
  local townies = get_mission_status('killtownies')
  if townies >= 5 then
    return true
  end
  return false,"Still gotta kill " .. 5-townies .. ", you monster."
end
function killtownies:finish()
  output:out("You killed them, you monster.")
  return "You killed them, you monster."
end
possibleMissions['killtownies'] = killtownies