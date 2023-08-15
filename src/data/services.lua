possibleServices = {}
 
local healing = Service({
  name = "Healing",
  description = "Heal all your damage.",
})
function healing:get_cost_text()
  local amt = (player:get_max_hp() - player.hp)
  return get_money_name(1) .. " per HP" .. (amt > 0 and ", " .. amt .. " Total" or "")
end
function healing:requires()
  local hp, mhp = player.hp,player:get_max_hp()
  if hp == mhp then
    return false,"You're at full health."
  end
end
function healing:use(user)
  local amt = math.min((user:get_max_hp() - user.hp),user.money)
  user.money = user.money-amt
  user:updateHP(amt)
  return true,"You regain " .. amt .. " HP.\nYou pay " .. get_money_name(amt) .. "."
end
possibleServices['healing'] = healing

local healing_church = Service({
  name = "Healing",
  description = "Heal all your damage.",
})
function healing_church:get_cost_text()
  local amt = (player:get_max_hp() - player.hp)
  return "1 favor per HP" .. (amt > 0 and ", " .. amt .. " Total" or "")
end
function healing_church:requires()
  local hp, mhp = player.hp,player:get_max_hp()
  if hp == mhp then
    return false,"You're at full health."
  end
  if (player.favor.lightchurch or 0) < mhp-hp then
    return false,"You don't have enough favor."
  end
end
function healing_church:use(user)
  local amt = (user:get_max_hp() - user.hp)
  user.hp = user:get_max_hp()
  user.favor.lightchurch = user.favor.lightchurch - amt
  return true,"You regain " .. amt .. " HP.\nYou lose " .. amt .. " favor with the Church of Sweetness and Light."
end
possibleServices['healing_church'] = healing_church

local blessing = Service({
  name = "Blessing",
  description = "Receive a blessing.",
})
function blessing:use(user)
  user:give_condition('blessed',5)
  return true,"You feel #blessed."
end
possibleServices['blessing'] = blessing

local exorcism = Service({
  name = "Exorcism",
  description = "Receive an exorcism.",
})
function exorcism:use(user)
  return true,"There are no more demons in you."
end
possibleServices['exorcism'] = exorcism