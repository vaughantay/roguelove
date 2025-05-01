possibleMissions = {}

local killtownies = {
  name = "Kill Townies",
  description = "Those weaklings in town have forgotten that life is nasty, brutish, and short. Remind them that safety is an illusion by killing 5 townspeople.",
  finished_description = "The weaklings have been reminded what fear is.",
  finish_text = "The townspeople have been reminded what fear is."
}
function killtownies:start()
  local godname = currWorld.factions['barbariangod'].name
  return true,godname .. " roars in approval."
end
function killtownies:kills(killer,victim)
  if killer == player and victim.id == "townsperson" then
    local townies = update_mission_status('killtownies',1)
    if townies < 5 then
      output:out("You've killed " .. townies .. " townspeople. " .. 5-townies .. " to go.")
    elseif townies == 5 then
      output:out("You've killed 5 townspeople. Return to the altar.")
    end
  end
end
function killtownies:get_status(status)
  if not status then status = get_mission_status('killtownies') end
  if status < 5 then
    return "You still need to kill " .. 5-status .. " townspeople."
  else
    return "The townspeople have been reminded what fear is. Return to the altar."
  end
end
function killtownies:can_finish()
  local townies = get_mission_status('killtownies')
  if townies >= 5 then
    return true
  end
  return false,"You still need to kill " .. 5-townies .. " townspeople."
end
function killtownies:finish()
  player.reputation.barbariangod = player.reputation.barbariangod or 0 + 100
end
possibleMissions['killtownies'] = killtownies

local killdemons = {
  name = "Kill Demons",
  description = "Prove you have what it takes to be a demonslayer. Kill 5 demons.",
  finished_description = "You have proven your worth as a demonslayer, but many unholy beasts still infest this world.",
  finish_text = "You have done a holy service to the world.",
  start_text = "You pledge to kill 5 demons.",
  hide_when_disabled=true
}
function killdemons:kills(killer,victim)
  if killer == player and victim:is_type('demon') then
    local demons = update_mission_status('killdemons',1)
    if demons < 5 then
      output:out("You've killed " .. demons .. " demons. " .. 5-demons .. " to go.")
    elseif demons == 5 then
      output:out("You've killed 5 demons. Return to " .. currWorld.factions.lightchurch.name .. ".")
    end
  end
end
function killdemons:get_status(status)
  if not status then status = get_mission_status('killdemons') end
  if status < 5 then
    return "You still need to kill " .. 5-status .. " demons."
  else
    return "You have slain 5 unholy demons. Return to " .. currWorld.factions.lightchurch.name .. "."
  end
end
function killdemons:can_finish()
  local demons = get_mission_status('killdemons')
  if demons >= 5 then
    return true
  end
  return false,"You still need to kill " .. 5-demons .. " demons."
end
function killdemons:finish()
  player.reputation.lightchurch = (player.reputation.lightchurch or 0) + 100
end
possibleMissions['killdemons'] = killdemons

local killundead = {
  name = "Kill Undead",
  description = "Prove you have what it takes to be an undead slayer. Kill 5 undead.",
  finished_description = "You have proven your worth as an undead slayer, but many unholy beasts still infest this world.",
  finish_text = "You have done a holy service to the world.",
  start_text = "You pledge to kill 5 undead.",
  hide_when_disabled=true
}
function killundead:kills(killer,victim)
  if killer == player and victim:is_type('undead') then
    local demons = update_mission_status('killundead',1)
    if demons < 5 then
      output:out("You've killed " .. demons .. " undead. " .. 5-demons .. " to go.")
    elseif demons == 5 then
      output:out("You've killed 5 undead. Return to " .. currWorld.factions.lightchurch.name .. ".")
    end
  end
end
function killundead:get_status(status)
  if not status then status = get_mission_status('killundead') end
  if status < 5 then
    return "You still need to kill " .. 5-status .. " undead."
  else
    return "You have slain 5 unholy undead. Return to " .. currWorld.factions.lightchurch.name .. "."
  end
end
function killundead:can_finish()
  local demons = get_mission_status('killundead')
  if demons >= 5 then
    return true
  end
  return false,"You still need to kill " .. 5-demons .. " undead."
end
function killundead:finish()
  player.reputation.lightchurch = (player.reputation.lightchurch or 0) + 100
end
possibleMissions['killundead'] = killundead

local ascend = {
  name = "Ascend as a Hero",
  description = "Prove yourself a true hero by making your way to the Hall of Heroes at the bottom of the dungeon and ascending to Valhalla.",
  status_text = {[0] = "Unlock the first Valhalla Gate with a Hero's Key.", [1] = "Unlock the second Valhalla Gate with a Hero's Key.",[2] = "Ascend to Valhalla as a True Hero."}
}
possibleMissions['ascend'] = ascend

local findtreasure = {
  name = "Treasure Hunting",
  description = "Seek out a hidden treasure.",
  repeatable = true,
  repeat_limit=2,
  rewards={money=100,reputation=100,favor=100,items={{item="scroll", passed_info={'holy'}, displayName = "Random Holy Scrolls",amount=3},{item="dagger",amount=2}},"The favor of the goddess","Bonus goodies"},
}
function findtreasure:start()
  local treasure = Item('treasure')
  treasure.properName = namegen:generate_weapon_name()
  set_mission_data('findtreasure','item',treasure)
  local text = "You seek " .. treasure:get_name() .. "."
  set_mission_data('findtreasure','description',text)
  return text
end
function findtreasure:get_status()
  local treasure = get_mission_data('findtreasure','item')
  local source = get_mission_data('findtreasure','source')
  if not player:has_specific_item(treasure) then
    return nil
  else
    return "You've acquired " .. treasure:get_name() .. ". Return it to " .. (source.baseType == "creature" and source:get_name() or source.name) .. "."
  end
end
function findtreasure:enter_map()
  local treasure = get_mission_data('findtreasure','item')
  if not treasure.placed then
    currMap:add_item(treasure,player.x,player.y)
    treasure.placed=true
  end
end
function findtreasure:can_finish()
  local treasure = get_mission_data('findtreasure','item')
  if player:has_specific_item(treasure) then
    return true
  else
    return false
  end
end
function findtreasure:finish()
  local treasure = get_mission_data('findtreasure','item')
  treasure:delete()
  --local reputation = nil
  --local source = get_mission_data('findtreasure','source')
  --if source and source.baseType == "faction" then
    --reputation = 100
    --player.reputation[source.id] = (player.reputation[source.id] or 0)+reputation
  --end
  return true,"You turn in " .. treasure:get_name() .. "."
end
possibleMissions['findtreasure'] = findtreasure