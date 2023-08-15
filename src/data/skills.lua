possibleSkills = {}
possibleSkillTypes = {}

  
possibleSkillTypes['attribute']={name="Attributes",upgrade_stat="upgrade_points_attribute",upgrade_stat_name="Attribute Points"}
possibleSkillTypes['skill']={name="Skills",upgrade_stat="upgrade_points_skill",upgrade_stat_name="Skill Points"}

--Attributes:
local strength = {
  name = "Strength",
  description = "Increases the damage you do in melee, and the amount you can carry.",
  skill_type="attribute",
  stats_per_x_levels={[10]={inventory_space=1}}
}
possibleSkills['strength'] = strength

local agility = {
  name = "Agility",
  description = "Increases dodge chance by 5% for every point.",
  skill_type="attribute",
}
possibleSkills['agility'] = agility

local toughness = {
  name = "Toughness",
  description = "Increases max HP by 1 per toughness per level.",
  skill_type="attribute"
}
function toughness:update(possessor,val)
  local amt = val * possessor.level
  possessor.max_hp = possessor.max_hp + amt
  possessor.hp = possessor.hp + amt
end
function toughness:level_up(possessor)
  local amt = possessor:get_skill('toughness',true)
  possessor.max_hp = possessor.max_hp + amt
  possessor.hp = possessor.hp + amt
end
possibleSkills['toughness'] = toughness

--[[
local skill = {
  name = "Name",
  description = "Desc",
  skill_type = "attribute", --If blank, defaults to "skill"
  max=10, --the maximum possible level attainable in this skill
  learns_spells={{spell="smite",level=2}}, --Spells that will be automatically granted when reaching a certain level of the skill
  spell_purchases={{spell='teleportother',level=4}}, --Spells that will be available to purchase when reaching a certain level of the skill
  spell_choices={},
  stats_per_level={spellPoints=1,max_mp=5},
  stats_per_x_levels={[5]={spell_slots=1}},
  stats_at_level={[1]={spell_slots=1,max_mp=10}},
  bonuses={max_hp=1000}, --bonuses applied from having this skill
  bonuses_per_level={strength=10},
  bonuses_at_level={[2]={agility=100}},
  bonuses_per_x_levels={[3]={toughness=10}},
  upgrade_stat=statID --Defaults to the upgrade_stat of the skill's type, or to upgrade_points_[skill_type] if the skill's type's upgrade_stat is undefined
}
possibleSkills['stat'] = stat
]]

--Skills:
local melee = {
  name = "Melee Combat",
  description = "Proficiency in melee combat.",
  skill_type="skill",
}
possibleSkills['melee'] = melee

local ranged = {
  name = "Ranged Combat",
  description = "Proficiency with ranged and thrown weaponry.",
  skill_type="skill",
}
possibleSkills['ranged'] = ranged

local magic = {
  name = "Magic",
  description = "Power over the mystic realm.",
  skill_type="skill",
  stats_per_level={spellPoints=1,max_mp=5},
  stats_per_x_levels={[5]={spell_slots=1}},
  stats_at_level={[1]={spell_slots=1,max_mp=10}},
  learns_spells={{spell='blast',level=1}}
}
possibleSkills['magic'] = magic

local demonology = {
  name = "Demonology",
  description = "The study of demons and the powers of hell.",
  skill_type="skill"
}
possibleSkills['demonology'] = demonology

local divinity = {
  name = "Divinity",
  description = "The study of angels, gods, and the powers of heaven.",
  skill_type="skill",
  stats_per_level={spellPoints=1,max_mp=5},
  stats_per_x_levels={[5]={spell_slots=1}},
  stats_at_level={[1]={spell_slots=1,max_mp=10}},
  learns_spells={{spell='smite',level=1}}
}
possibleSkills['divinity'] = divinity

local alchemy = {
  name = "Alchemy",
  description = "The knowledge required to be able mix things together and have them only blow up when you want them to.",
  skill_type="skill"
}
possibleSkills['alchemy'] = alchemy

--Vampiric skills

local bloodpotency = {
  name = "Blood Potency",
  description="The power of your vampiric blood. Increasing this will increase the strength of some of your vampiric powers, and give you points to spend on increasing other vampiric attributes.",
  skill_type="attribute",
  stats_per_level={upgrade_points_vampirism=3}
}
possibleSkills['bloodpotency'] = bloodpotency

local bloodpool = {
  name = "Blood Pool",
  description = "The amount of blood you can hold. Every point increases the amount you can hold by 10.",
  skill_type="vampirism",
  increase_per_point=10
}
function bloodpool:update(posssesor,val)
  if posssesor.extra_stats.blood then
    posssesor.extra_stats.blood.max = posssesor.extra_stats.blood.max + val
  else
    posssesor.extra_stats.blood = {name="Blood",description="The amount of blood in your body. Used to power vampiric abilities.",value=round(val/2),max=val,bar_color={r=155,g=0,b=0,a=255}}
  end
end
possibleSkills['bloodpool'] = bloodpool