enchantments = {}

local vampiric = {
  name = "Vampiric",
  prefix = "vampiric",
  description = "Drains health from your enemies and gives it to you.",
  tags={"unholy"},
  requires_tags={"sharp"},
  forbiddenTags={'holy'},
  item_type="weapon",
  requires_types={"melee"}
}
function vampiric:after_damage(item,possessor,target,damage)
  if (random(1,2) == 1 and not target:is_type('bloodless')) or target:has_condition('bleeding') then
    local hp = tweak(math.ceil(damage*(random(2,6)/10)))
    if player:can_see_tile(possessor.x,possessor.y) and hp > 0 then
      output:out(item:get_name() .. " drains some blood from " .. target:get_name() .. ", restoring " .. hp .. " HP to " .. possessor:get_name() .. "!")
      local blood = currMap:add_effect(Effect('animation',{image_name='bloodmagicdamage',image_max=5,target=target,color={r=255,g=255,b=255}}),target.x,target.y)
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
  hit_conditions={{condition='poisoned',chance=25,minTurns=2,maxTurns=4,crit_chance=100,crit_turns=5}},
  item_type="weapon",
  requires_tags={"sharp"},
  neverPermanent=true, --This enchantment will never be picked to be a permanent part of an artifact
  apply_to_projectile="poisoned_projectile" --If this enchantment is applied to a ranged weapon, either set this to TRUE to copy this enchantment to the projectile, or set it to the ID of another enchantment to apply that enchantment instead
}
enchantments['poisoned'] = poisoned

local poisonedProjectile = {
  name = "Poisoned",
  prefix = "poisoned",
  removal_type="hit",
  description = "Poisons the target on a successful hit.",
  hit_conditions={{condition='poisoned',chance=100,minTurns=2,maxTurns=4}},
  item_types={"throwable","ammo"},
  requires_tags={"sharp"}
}
enchantments['poisoned_projectile'] = poisonedProjectile

local fireweapon = {
  name = "Enflamed",
  prefix = "enflamed",
  description = "Does extra fire damage.",
  extra_damage = {damage_type="fire",damage_percent=50,safe_creature_types={"fireImmune"}},
  removal_type="hit",
  tags={"fire","magic"},
  forbiddenTags={'ice'},
  item_types={"weapon","ammo","throwable"},
  apply_to_projectile=true,
  enchantment_type="elemental"
}
enchantments['fireweapon'] = fireweapon

local iceweapon = {
  name = "Frozen",
  prefix = "frozen",
  description = "Does extra ice damage.",
  extra_damage = {damage_type="ice",damage_percent=50},
  removal_type="hit",
  tags={"ice","magic"},
  forbiddenTags={'fire'},
  item_types={"weapon","ammo","throwable"},
  apply_to_projectile=true,
  enchantment_type="elemental"
}
enchantments['iceweapon'] = iceweapon

local accurate = {
  name = "Accurate",
  suffix = "of Accuracy",
  bonuses={hit_chance=10,critical_chance=5},
  description = "Has a higher chance of hitting the target.",
  value_increase=0.5,
  item_type="weapon"
}
enchantments['accurate'] = accurate

local blessed = {
  name = "Blessed",
  prefix = "blessed",
  description = "Does extra holy damage to unholy creatures.",
  extra_damage = {damage_type="holy",damage_percent=50,armor_piercing=true,only_creature_types={"demon","undead","abomination","unholy"}},
  removal_type="kill",
  tags={"holy"},
  forbiddenTags={'unholy'},
  item_types={"weapon","ammo","throwable"},
  enchantment_type="elemental",
  spells_granted={'smite'}
}
enchantments['blessed'] = blessed

local sharpened = {
  name = "Sharpened",
  prefix = "sharpened",
  description = "Wickedly sharp and ready to draw blood.",
  removal_type="hit",
  item_type="weapon",
  requires_types={"melee","sharp"},
  forbiddenEnchantments={'dulled'},
  hit_conditions={{condition="bleeding",minTurns=2,maxTurns=5,chance=100,crit_turns=5}},
  enchantment_type="sharpness"
}
enchantments['sharpened'] = sharpened

local dulled = {
  name = "Dull",
  prefix = "dull",
  description = "The edge of this weapon is dulled, dealing less damage.",
  item_type="weapon",
  requires_types={"melee","sharp"},
  removes_item_types={"sharp"},
  forbiddenEnchantments={'sharpened'},
  bonuses={damage=-5},
  enchantment_type="sharpness"
}
enchantments['dulled'] = dulled

local damaging = {
  name = "Damaging",
  prefix = "Damaging",
  bonuses={damage=5},
  description = "Does more damage to the target.",
  item_types={"weapon","ammo","throwable"}
}
enchantments['damaging'] = damaging

local armorInvincible = {
  name = "Invicibility",
  suffix = "of Invincibility",
  bonuses = {all_armor=1000},
  description = "Makes you immune to damage.",
  item_type="armor",
  removal_type="damaged",
  damaged = function(item,possessor,attacker)
    possessor:give_condition('fireaura',random(5,10),attacker)
    conditions['fireaura']:advance(possessor)
	end,
}
enchantments['armor_invincible'] = armorInvincible

local armorDamaging = {
  name = "Killing",
  suffix = "of Killing",
  bonuses = {critical_chance=1000},
  description = "Makes you very deadly.",
  item_type="armor"
}
enchantments['armor_damaging'] = armorDamaging

local artifact = {
  name = "Artifact",
  hidden=true, --Enchantment will not show up in the item's description
  value_increase=1,
  item_types={"weapon","ammo","throwable","armor"},
  specialOnly=true, --Enchantment will only be applied manually
  tags={"valuable"},
}
enchantments['artifact'] = artifact