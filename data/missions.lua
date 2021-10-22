possibleMissions = {}

local killtownies = {
  name = "Kill Townies",
  description = "Those weaklings in town have forgotten that life is nasty, brutish, and short. Remind them that safety is an illusion by killing 5 townspeople.",
  finished_description = "The weaklings have been reminded what fear is."
}
function killtownies:start()
  local godname = currWorld.factions['barbariangod'].name
  output:out(godname .. " roars in approval.")
  return godname .. " roars in approval."
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
  output:out("The townspeople have been reminded what fear is.")
  player.favor.barbariangod = player.favor.barbariangod + 100
  return "The townspeople have been reminded what fear is."
end
possibleMissions['killtownies'] = killtownies

local killdemons = {
  name = "Kill Demons",
  description = "Prove you have what it takes to be a demonslayer. Kill 5 demons.",
  finished_description = "You have proven your worth as a demonslayer, but many unholy beasts still infest this world.",
}
function killdemons:start()
  return "You pledge to kill 5 demons."
end
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
  output:out("You have done a holy service to the world.")
  player.favor.lightchurch = player.favor.lightchurch + 100
  return "You have done a holy service to the world."
end
possibleMissions['killdemons'] = killdemons

local ascend = {
  name = "Ascend as a Hero",
  description = "Prove yourself a true hero by making your way to the Hall of Heroes at the bottom of the dungeon and ascending to Valhalla.",
  status_text = {[0] = "Unlock the first Valhalla Gate with a Hero's Key.", [1] = "Unlock the second Valhalla Gate with a Hero's Key.",[2] = "Ascend to Valhalla as a True Hero."}
}
possibleMissions['ascend'] = ascend

local findtreasure = {
  name = "Treasure Hunting",
  description = "Seek out a hidden treasure.",
  repeating = true
}
function findtreasure:start()
  local treasure = Item('treasure')
  treasure.properName = namegen:generate_weapon_name()
  set_mission_data('findtreasure','item',treasure)
  return "You seek " .. treasure:get_name() .. "."
end
function findtreasure:get_status()
  local treasure = get_mission_data('findtreasure','item')
  local source = get_mission_data('findtreasure','source')
  if not player:has_specific_item(treasure) then
    return "You seek " .. treasure:get_name() .. "."
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
    return false,"You seek " .. treasure:get_name() .. "."
  end
end
function findtreasure:finish()
  local treasure = get_mission_data('findtreasure','item')
  treasure:delete()
  local favor = nil
  local source = get_mission_data('findtreasure','source')
  if source and source.baseType == "faction" then
    favor = 100
    player.favor[source.id] = player.favor[source.id]+favor
  end
  return "You turn in " .. treasure:get_name() .. (favor and " for " .. favor .. " favor." or ".")
end
possibleMissions['findtreasure'] = findtreasure