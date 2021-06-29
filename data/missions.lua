possibleMissions = {}

local killtownies = {
  name = "Kill Townies",
  description = "Kill 5 townspeople, you monster.",
}
function killtownies:start()
  output:out("Time to kill them, you monster.")
end
function killtownies:kills(killer,victim)
  if killer == player and victim.id == "townsperson" then
    local townies = update_mission_status('killtownies',1)
    output:out("You've killed " .. townies .. ", you monster.")
    if townies >= 5 then
      finish_mission('killtownies')
    end
  end
end
function killtownies:finish()
  output:out("You killed them, you monster.")
end
possibleMissions['killtownies'] = killtownies