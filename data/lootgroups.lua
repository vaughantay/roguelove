lootGroups = {}

local fireweapons = {
  itemTypes = {'weapon'},
  enchantmentTags = {'fire'},
  tags = {'fire','weapon'},
  artifact_chance=10,
  rarity=20
}
lootGroups['fireweapons'] = fireweapons

local healing = {
  items = {{item="healthpotionminor"},{item="healthpotionmoderate",chance=75},{item="herb",chance=25}},
  tags = {'healing'}
}
lootGroups['healing'] = healing

--[[
Template for items:
{item=itemID,rarity=0,passed_info=whatever,pass_tags=true,amount=1,min_amt=1,max_amt=1,enchantment=enchID,enchantment_turns=5,enchantment_chance=0,artifact_chance=0,level=1,min_level=1,max_level=1}
]]

--[[Template:
local fireWeapons = {
  items = {},
  itemTypes = {},
  itemTags = {},
  enchantments = {},
  enchantmentTags = {},
  tags = {},
  rarity=0,
  noStores=true,
  artifact_chance=1
}
]]