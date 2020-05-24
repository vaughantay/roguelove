enchantments = {}

local vampiric = {
  name = "Vampiric",
  prefix = "vampiric",
  description = "Drains health from your enemies and gives it to you.",
  tags={"unholy"},
  item_type="weapon"
}
function vampiric:damages(item,possessor,target,damage)
  if (random(1,2) == 1 and not target:is_type('bloodless')) or target:has_condition('bleeding') then
    local hp = tweak(math.ceil(damage*(random(2,6)/10)))
    if player:can_see_tile(possessor.x,possessor.y) and hp > 0 then
      output:out(item:get_name() .. " drains some blood from " .. target:get_name() .. ", restoring " .. hp .. " HP to " .. possessor:get_name() .. "!")
      local blood = currMap:add_effect(Effect('animation','bloodmagicdamage',5,target,{r=255,g=255,b=255}),target.x,target.y)
      if possessor == player or target == player then output:sound('vampirism') end
    end
    possessor:updateHP(hp)
  end
end
enchantments['vampiric'] = vampiric
  
local poisoned = {
  name = "Poisoned",
  prefix = "poisoned",
  removal_type="hit",
  description = "Poisons the target on a successful hit.",
  hit_conditions={{condition='poisoned',chance=25,minTurns=2,maxTurns=4}},
  crit_conditions={{condition="poisoned",turns=5,chance=100}},
  item_type="weapon"
}
enchantments['poisoned'] = poisoned

local accurate = {
  name = "Accurate",
  suffix = "of Accuracy",
  bonuses={hit_chance=10,critical_chance=1},
  description = "Has a higher chance of hitting the target.",
  value_increase=0.5,
  item_type="weapon"
}

local blessed = {
  name = "Blessed",
  prefix = "blessed",
  description = "Does extra holy damage to demons and the undead.",
  extra_damage = {},
  removal_type="kill",
  tags={"holy"},
  item_type="weapon"
}

local sharpened = {
  name = "Sharpened",
  prefix = "sharpened",
  description = "Wickedly sharp and ready to draw blood.",
  removal_type="hit",
  item_type="weapon",
  hit_conditions={{condition="bleeding",minTurns=2,maxTurns=5,chance=100}},
  crit_conditions={{condition="bleeding",turns=5,chance=100}}
}