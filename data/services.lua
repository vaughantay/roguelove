possibleServices = {}
 
local healing = Service({
  name = "Healing",
  description = "Heal all your damage.",
  cost = "$100",
})
function healing:get_cost()
  local amt = (player:get_mhp() - player.hp)
  return "$1 per HP" .. (amt > 0 and ", " .. amt .. " Total" or "")
end
function healing:requires()
  local hp, mhp = player.hp,player:get_mhp()
  if hp == mhp then
    return false,"You're at full health."
  end
end
function healing:use(user)
  local amt = math.min((user:get_mhp() - user.hp),user.money)
  user.money = user.money-amt
  user:updateHP(amt)
  return true,"You regain " .. amt .. " HP.\nYou pay $" .. amt .. "."
end
possibleServices['healing'] = healing

local healing_church = Service({
  name = "Healing",
  description = "Heal all your damage.",
  cost = "10 Favor",
})
function healing_church:get_cost()
  local amt = (player:get_mhp() - player.hp)
  return "1 favor per HP" .. (amt > 0 and ", " .. amt .. " Total" or "")
end
function healing_church:requires()
  local hp, mhp = player.hp,player:get_mhp()
  if hp == mhp then
    return false,"You're at full health."
  end
  if (player.favor.lightchurch or 0) < mhp-hp then
    return false,"You don't have enough favor."
  end
end
function healing_church:use(user)
  local amt = (user:get_mhp() - user.hp)
  user.hp = user:get_mhp()
  user.favor.lightchurch = user.favor.lightchurch - amt
  return true,"You regain " .. amt .. " HP.\nYou lose " .. amt .. " favor with the Church of Sweetness and Light."
end
possibleServices['healing_church'] = healing_church

local blessing = Service({
  name = "Blessing",
  description = "Receive a blessing.",
  cost = "10 Favor",
})
function blessing:requires()
  if not player:is_faction_member('lightchurch') then
    return false,"This service is only available to Church members."
  else
    return true
  end
end
function blessing:use(user)
  user:give_condition('blessed',5)
  return true,"You feel #blessed."
end
possibleServices['blessing'] = blessing