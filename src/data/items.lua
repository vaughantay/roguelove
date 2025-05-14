possibleItems = {}

local healthPotionMinor = {
  name = "potion of minor healing",
  pluralName = "potions of minor healing",
	description = "A crimson liquid swirls in this flask.",
	symbol = "!",
	color = {r=255,g=0,b=0,a=255},
	category="usable",
	stacks = true,
  usable=true,
  useVerb="drink",
  consumed=true,
  tags={'liquid','healing'},
  crafting_ingredient_properties={healing=3},
  crafting_ingredient_types={'alchemy'},
  value=50,
  size=0
}
function healthPotionMinor:use(user)
	user = user or player
	local healPerc = tweak(20)
  local heal = math.max(5,math.ceil(user:get_max_hp()*(healPerc/100)))
	output:out(user.name .. " drinks a Potion of Minor Healing and regains " .. heal .. " HP!")
	user:updateHP(heal)
end
possibleItems['healthpotionminor'] = healthPotionMinor

local healthPotionModerate = {
  name = "potion of moderate healing",
  pluralName = "potions of moderate healing",
	description = "A crimson liquid swirls in this flask.",
	symbol = "!",
	color = {r=255,g=0,b=0,a=255},
	category="usable",
	stacks = true,
  usable=true,
  useVerb="drink",
  consumed=true,
  tags={'liquid','healing'},
  crafting_ingredient_properties={healing=5},
  crafting_ingredient_types={'alchemy'},
  value=5
}
function healthPotionModerate:use(user)
	user = user or player
	local healPerc = tweak(34)
  local heal = math.max(10,math.ceil(user:get_max_hp()*(healPerc/100)))
	output:out(user.name .. " drinks a Potion of Moderate Healing and regains " .. heal .. " HP!")
	user:updateHP(heal)
end
possibleItems['healthpotionmoderate'] = healthPotionModerate

local magicPotionMinor = {
  name = "potion of minor magic",
  pluralName = "potions of minor magic",
	description = "A azure liquid swirls in this flask.",
	symbol = "!",
	color = {r=0,g=0,b=255,a=255},
	category="usable",
	stacks = true,
  usable=true,
  useVerb="drink",
  consumed=true,
  tags={'liquid','magic'},
  value=5
}
function magicPotionMinor:use(user)
	user = user or player
	local healPerc = tweak(15)
  local heal = math.max(5,math.ceil(user:get_max_mp()*(healPerc/100)))
	output:out(user.name .. " drinks a Potion of Minor Magic and regains " .. heal .. " MP!")
  user.mp = math.min(user:get_max_mp(),user.mp+heal)
end
possibleItems['magicpotionminor'] = magicPotionMinor

local poison = {
  name = "poison bottle",
  pluralName = "poison bottles",
	description = "A sickly green liquid swirls in this flask.",
	symbol = "!",
	color = {r=0,g=255,b=0,a=255},
	category="throwable",
	stacks = true,
  usable=true,
  useVerb="drink",
  consumed=true,
  tags={'liquid','poison'},
  crafting_ingredient_properties={poison=2},
  crafting_ingredient_types={'alchemy'},
  value=5
}
function poison:use(user)
	user = user or player
	output:out(user.name .. " drinks poison and becomes poisoned!")
  user:give_condition('poisoned',tweak(25))
end
possibleItems['poison'] = poison

local herbs = {
  name = "medicinal herb",
  pluralName = "medicinal herbs",
	description = "A small herb with medicinal properties.",
	symbol = "!",
	color = {r=0,g=150,b=0,a=255},
	category="usable",
	stacks = true,
  usable=true,
  useVerb="eat",
  consumed=true,
  tags={'food','healing','nature','ingredient','alchemy'},
  crafting_ingredient_properties={healing=1},
  crafting_ingredient_types={'alchemy'},
  value=5
}
function herbs:use(user)
	user = user or player
	local heal = tweak(2)
	output:out(user.name .. " eats a medicinal herb and regains " .. heal .. " HP!")
	user:updateHP(heal)
end
possibleItems['herbs'] = herbs

local poisonshroom = {
  name = "poisonous mushroom",
  pluralName = "poisonous mushrooms",
	description = "A small mushroom, highly toxic.",
	symbol = "!",
	color = {r=150,g=0,b=0,a=255},
	category="usable",
	stacks = true,
  usable=true,
  useVerb="eat",
  consumed=true,
  tags={'food','nature','ingredient','alchemy','poison'},
  crafting_ingredient_properties={poison=1},
  crafting_ingredient_types={'alchemy'},
  value=5
}
function poisonshroom:use(user)
	user = user or player
	output:out(user.name .. " eats a poisonous mushroom and becomes poisoned!")
	user:give_condition('poisoned',tweak(5))
end
possibleItems['poisonshroom'] = poisonshroom

local blood = {
  name = "blood vial",
  pluralName = "blood vials",
	description = "A crimson liquid swirls in this flask.",
	symbol = "!",
	color = {r=200,g=0,b=0,a=255},
	category="usable",
	stacks = true,
  usable=true,
  useVerb="drink",
  consumed=true,
  tags={'liquid','blood','ingredient'},
  crafting_ingredient_properties={healing=2,blood=1},
  crafting_ingredient_types={'alchemy'},
  value=5
}
function blood:use(user)
	user = user or player
  if user:has_spell('vampirism') then
    local dmg = tweak(10)
    output:out(user:get_name() .. " drinks some blood and regains " .. dmg .. " health!")
    user:updateHP(dmg)
    if user.extra_stats.blood then
      user.extra_stats.blood.value = math.min(user.extra_stats.blood.value+dmg,user.extra_stats.blood.max)
    end
  else
    if user == player then output:out("You're not going to drink blood. That's disgusting.") end
    return false
  end
end
possibleItems['blood'] = blood

local demonblood = {
  name = "demon blood",
  pluralName = "demon bloods",
	description = "A crimson liquid swirls in this flask.",
	symbol = "!",
	color = {r=255,g=0,b=0,a=255},
	category="usable",
	stacks = true,
  usable=true,
  useVerb="drink",
  consumed=true,
  tags={'liquid','unholy','fire','blood','ingredient'},
  types={'unholy'},
  crafting_ingredient_properties={fire=1,unholy=1,demon=1},
  crafting_ingredient_types={'alchemy'},
  value=5
}
function demonblood:use(user)
	user = user or player
	local dmg = user:damage(5,nil,"fire")
	output:out(user.name .. " drinks demon blood and takes " .. dmg .. " fire damage!")
end
possibleItems['demonblood'] = demonblood

local scroll = {
	name = "scroll",
  pluralName = "scrolls",
	symbol = "?",
	description = "A faded parchment, bearing arcane writing.",
	color={r=255,g=255,b=255,a=255},
	category="usable",
	stacks = true,
  acceptTags=true, --If true, this item will have the map's passedTags passed to its new() function
	spell = nil,
  sortBy = "spell",
  usable=true,
  useVerb="read",
  types={'magic'},
  tags={'paper','magic'},
  value=10,
  requires_identification=true,
  unidentified_name="unknown scroll",
  unidentified_names="unknown scrolls",
  unidentified_description = "A faded parchment, bearing arcane writing.",
  identify_all_of_type=true
}
function scroll:new(spell)
  if type(spell) == "string" and possibleSpells[spell] and possibleSpells[spell].target_type ~= "passive" then --spell provided
    self.spell = spell
  else --invalid or no spell provided
    local tags = nil
    local possibles = {}
    local allPossibles = {}
    if type(spell) == "table" and count(spell) > 0 then
      tags = spell
    end
    for id,spell in pairs(possibleSpells) do
      if spell.target_type ~= "passive" then
        allPossibles[#allPossibles+1] = id --keep track of all possible spells, in case when we look at the tags it comes back with nothing
        local acceptable = false
        if tags then
          if spell.tags then
            for _,tag in pairs(tags) do
              if Spell.has_tag(spell,tag) then
                acceptable = true
                break --break the tag for
              end --end if in_table
            end --end tag for
          end --end if spell has tags
        else --If no tags are provided, then any spell is acceptable
          acceptable = true
        end --end if tags or not if
        if acceptable == true then possibles[#possibles+1] = id end
      end --end if not passive
    end --end spell for
    if #possibles == 0 then possibles = allPossibles end
    spell = get_random_element(possibles)
    self.spell = spell
    self.target_type = possibleSpells[spell].target_type
  end --end spell provided or not if
  
	self.name = "scroll of " .. possibleSpells[spell].name
  self.pluralName = "scrolls of " .. possibleSpells[spell].name
  self.description = possibleSpells[spell].description
  if possibleSpells[spell].tags then self:add_tags(possibleSpells[spell].tags) end
  if player and player:has_spell(self.spell) then
    self:identify()
    return
  end
  if not self:is_identified() then
    local writing = currGame.unidentified_item_info['scroll' .. self.spell] or namegen:generate_phoneme_name()
    if not currGame.unidentified_item_info['scroll' .. self.spell] then currGame.unidentified_item_info['scroll' .. self.spell] = writing end
    self.unidentified_name = "scroll marked \"" .. writing .. "\""
    self.unidentified_plural_name = "scrolls marked \"" .. writing  .. "\""
  end
end
function scroll:target(target,user)
  action="targeting"
  actionResult=self
  actionItem=self
  actionIgnoreCooldown = true
  actionignoreCost = true
  game.targets = {}
end
function scroll:use(target,user)
  if possibleSpells[self.spell].target_type == "self" then
    target = user
    local spResult = Spell(self.spell):use(target,user,true,true)
    if spResult ~= false then
      self:identify()
      user:delete_item(self)
    else
      return false
    end
  elseif action == "targeting" then
    local spResult = Spell(self.spell):use(target,user,true,true)
     if spResult ~= false then
       self:identify()
      user:delete_item(self)
    else
      return false
      end
  else
    action="targeting"
    actionResult=self
    actionItem=self
    actionIgnoreCooldown = true
    actionignoreCost = true
    game.targets = {}
  end
end
possibleItems['scroll'] = scroll

local spellBook = {
	name = "spellbook",
	symbol= "◊",
	color={r=255,g=255,b=255,a=255},
	description="A heavy tome, filled with mystical knowledge.",
	spells={},
	category="usable",
  usable=true,
  useVerb="study",
  types={'book','magic'},
  tags={'paper','magic'},
  acceptTags=true,
  value=100,
  requires_identification=true,
  proper_name_when_unidentified=true
}
function spellBook:new(tags,spells,spellCount)
	require "data.spells"
  spellCount = spellCount or 5
	self.color = {r=math.random(33,255),g=math.random(33,255),b=math.random(33,255),a=255}
	self.properName = namegen:generate_book_name()
  if spells then
    self.spells = spells
  else
    local s = {}
    local possibles = {}
    local allPossibles = {}
    for id,spell in pairs(possibleSpells) do
      if not spell.unlearnable and spell.tags and (in_table('magic',spell.tags)) then
        allPossibles[#allPossibles+1] = id --keep track of all possible spells, in case when we look at the tags it comes back with nothing
        local acceptable = false
        if tags then
          for _,tag in pairs(tags) do
            if Spell.has_tag(spell,tag) then
              acceptable = true
              break --break the tag for
            end --end if in_table
          end --end tag for
        else --If no tags are provided, then any spell is acceptable
          acceptable = true
        end --end if tags or not if
        if acceptable == true then possibles[#possibles+1] = id end
      end --end if not passive
    end --end spell for
    if #possibles == 0 then possibles = allPossibles end
    local possCount = #possibles
    for i=1,math.min(spellCount,possCount),1 do
      local k = get_random_key(possibles)
      s[i] = possibles[k]
      if possibleSpells[possibles[k]].tags then
        self:add_tags(possibleSpells[possibles[k]].tags)
      end
      table.remove(possibles,k)
    end
    self.spells = s
  end --end preset spells or not if
  local text = "This book contains the following spells: "
  for id, spellid in ipairs(self.spells) do
		text = text .. "\n" .. id .. ") " .. possibleSpells[spellid].name
	end
  self.info = text
end
function spellBook:use()
  local turn = false
  if not self:is_identified() then
    output:out("You study the book, and discover which spells it contains.")
    self:identify()
    turn = true
  end
  local list = {}
  for _, spellid in ipairs(self.spells) do
    local alreadyLearned = player:has_spell(spellid)
    local canLearn,canText = player:can_learn_spell(spellid)
    list[#list+1] = {text="Learn " .. possibleSpells[spellid].name,description=possibleSpells[spellid].description .. (alreadyLearned and "\nYou already know this spell." or "") .. (canText and "\n" .. canText or ""),selectFunction=player.learn_spell,selectArgs={player,spellid},disabled=(alreadyLearned or not canLearn)}
  end
  Gamestate.switch(multiselect,list,"Learn a Spell from " .. self.properName,true,true)
  return turn
end
possibleItems['spellbook'] = spellBook

local weaponPoison = {
	name = "weapon poison",
	symbol= "!",
	color={r=0,g=255,b=0,a=255},
	description="A bottle filled with a toxic oil you can apply to a weapon.",
	spells={},
	category="usable",
  usable=true,
  useVerb="apply",
  stacks=true,
  tags={'liquid'},
  value=100
}
function weaponPoison:use()
  local list = {}
  for i,item in ipairs(player.inventory) do
    if item:qualifies_for_enchantment('poisoned') or item:qualifies_for_enchantment('poisoned_projectile') then
      local afterFunc = function()
        output:out(player:get_name() .. " applies poison to " .. item:get_name() .. ".")
        if item:is_type("weapon") then
          item:apply_enchantment('poisoned',tweak(5))
        elseif item:is_type("ammo") or item:is_type("throwable") then
          output:out(player:get_name() .. " applies poison to " .. item:get_name() .. ".")
          item:apply_enchantment('poisoned_projectile',2)
        end
        player:delete_item(self)
        advance_turn()
      end
      list[#list+1] = {text=item:get_name(true),description=item:get_description(),selectFunction=afterFunc,selectArgs={}}
    end
  end
  if #list > 0 then
    Gamestate.switch(multiselect,list,"Poison a Weapon",true,true)
    return false
  else
    output:out("You can't apply poison to any of your weapons.")
    return false,"You can't apply poison to any of your weapons."
  end
end
possibleItems['weaponpoison'] = weaponPoison

local weaponFireOil = {
	name = "fiery weapon oil",
	symbol= "!",
	color={r=255,g=0,b=0,a=255},
	description="A bottle filled with a magically hot oil you can apply to a weapon.",
	spells={},
	category="usable",
  usable=true,
  useVerb="apply",
  stacks=true,
  tags={'liquid'},
  value=100
}
function weaponFireOil:use()
  local list = {}
  for i,item in ipairs(player.inventory) do
    if item:qualifies_for_enchantment('firewapon') then
      local afterFunc = function()
        output:out(player:get_name() .. " applies fire oil to " .. item:get_name() .. ".")
        item:apply_enchantment('fieryweapon',tweak(5))
        player:delete_item(self)
        advance_turn()
      end
      list[#list+1] = {text=item:get_name(true),description=item:get_description(),selectFunction=afterFunc,selectArgs={}}
    end
  end
  if #list > 0 then
    Gamestate.switch(multiselect,list,"Apply Fire Oil",true,true)
    return false
  else
    output:out("You can't apply this oil to any of your weapons.")
    return false,"You can't apply this oil to any of your weapons."
  end
end
possibleItems['weaponfireoil'] = weaponFireOil

local greatsword = {
  name="greatsword",
	description="A really big sword.",
	symbol="†",
	category="weapon",
  subcategory="melee",
  equippable=true,
  equipSlot="wielded",
  equipSize=2,
	color={r=255,g=255,b=255,a=255},
	melee_attack=true,
  damage = 3,
	accuracy = 10,
	critical_chance = 5,
	level = 1,
  max_level=5,
  types={'weapon','sword','sharp','metal'},
  tags={'large','sharp','sword'},
  stats_per_level={damage=2,value=5},
  enchantable=true,
  enchantment_slots={elemental=1,sharpness=1},
  value=50
}
possibleItems['greatsword'] = greatsword

local club = {
  name="club",
	description="A really big stick.",
	symbol="†",
	category="weapon",
  subcategory="melee",
  equippable=true,
  equipSlot="wielded",
  equipSize=2,
	color={r=255,g=255,b=255,a=255},
  melee_attack=true,
	damage = 3,
	accuracy = 10,
	level = 1,
  max_level=5,
  types={'weapon','wood'},
  tags={'large','wood'},
  value=5,
  stats_per_level={damage=2,value=1}
}
possibleItems['club'] = club

local reallybigclub = {
  name="really big club",
	description="A really really big stick.",
	symbol="†",
	category="weapon",
  subcategory="melee",
  equippable=true,
  equipSlot="wielded",
  equipSize=2,
	color={r=255,g=255,b=255,a=255},
  melee_attack=true,
	damage = 10,
	accuracy = -10,
	critical_chance = 10,
	level = 1,
  types={'weapon','wood'},
  tags={'large','wood'},
  value=50,
  neverSpawn=true
}
possibleItems['reallybigclub'] = reallybigclub

local dagger = {
  name="dagger",
	description="A short-bladed dagger, wickedly sharp.",
	symbol="†",
	category="weapon",
  subcategory="melee",
  equippable=true,
  throwable=true,
  preserve_on_throw=true,
  equipSlot="wielded",
	color={r=200,g=200,b=200,a=255},
  melee_attack=true,
	damage = 3,
	accuracy = 10,
	critical_chance = 5,
	level = 1,
  max_level=5,
  types={'weapon','sharp'},
  tags={'sharp'},
  value=5,
  ranged_attack="dagger",
  stats_per_level={damage=1,value=1,accuracy=1,critical_chance=.5}
}
possibleItems['dagger'] = dagger

local sword = {
  name="sword",
	description="A sword.",
	symbol="†",
	category="weapon",
  subcategory="melee",
  equippable=true,
  equipSlot="wielded",
	color={r=200,g=200,b=200,a=255},
  melee_attack=true,
	damage = 5,
	level = 1,
  max_level=5,
  types={'weapon','sword','sharp'},
  tags={'sharp'},
  value=5,
  stats_per_level={damage=1,value=1,accuracy=1},
  enchantable=true,
  enchantment_slots={elemental=1,sharpness=1}
}
possibleItems['sword'] = sword

local selfharmdagger = {
  name="dual-bladed dagger",
	description="A short-bladed dagger, wickedly sharp. Unfortunately, its hilt is also a blade.",
  into = "Also deals damage to the attacker.",
	symbol="†",
	category="weapon",
  subcategory="melee",
  equippable=true,
  throwable=true,
  equipSlot="wielded",
	color={r=200,g=200,b=200,a=255},
  melee_attack=true,
	damage = 3,
	accuracy = 10,
	critical_chance = 5,
	level = 1,
  types={'weapon','sharp'},
  tags={'sharp'},
  value=1
}
function selfharmdagger:attacked_with(target,wielder)
  local dmg = wielder:damage(5)
  output:out(wielder:get_name() .. " cuts themselves on " .. self:get_name() .. ", taking " .. dmg .. " damage.")
  return true
end
possibleItems['selfharmdagger'] = selfharmdagger

local cattleprod = {
  name="cattle prod",
	description="A cattle prod. Deals no damage, but stuns.",
	symbol="†",
	category="weapon",
  subcategory="melee",
  melee_attack=true,
  equippable=true,
  equipSlot="wielded",
	color={r=200,g=200,b=200,a=255},
	damage = 3,
	accuracy = 10,
	level = 1,
  types={'weapon','nonlethal','electric'},
  tags={'nonlethal','electric'},
  value=10,
  noEnchantments=true
}
function cattleprod:attack_hits(target,wielder,damage)
  if player:can_sense_creature(target) then output:out(wielder:get_name() .. " gives " .. target:get_name() .. " a nasty shock with a cattle prod!") end
  target:give_condition('stunned',random(1,3),wielder)
  return 0
end
possibleItems['cattleprod'] = cattleprod

local buckler = {
  name="buckler",
	description="A small shield.",
	symbol="o",
	category="offhand",
  equippable=true,
  equipSlot="wielded",
	color={r=200,g=200,b=200,a=255},
  types={'shield','wood','armor'},
  tags={'wood'},
  value=5
}
possibleItems['buckler'] = buckler

local dart = {
  name = "dart",
  pluralName = "darts",
  description = "A small, sharp dart.",
  symbol="/",
	category="throwable",
  throwable=true,
  target_type="creature",
	color={r=200,g=200,b=200,a=255},
  ranged_damage_stats={strength=1},
	ranged_attack="dart",
  stacks=true,
  max_stack=10,
  level = 1,
  max_level = 5,
  value=1,
  types={'throwable','sharp'},
  tags={'sharp'}
}
possibleItems['dart'] = dart

local bomb = {
  name = "bomb",
  pluralName = "bombs",
  description = "A small bomb.",
  symbol="*",
	category="throwable",
  projectile_name="bomb",
  throwable=true,
	color={r=100,g=100,b=100,a=255},
	ranged_attack="genericthrow",
  stacks=true,
  value=10,
  types={'throwable'},
  tags={'explosive'}
}
possibleItems['bomb'] = bomb

local molotov = {
  name = "molotov cocktail",
  pluralName = "molotov cocktails",
  description = "A bottle of explosive liquid.",
  symbol="*",
	category="throwable",
  projectile_name="molotov",
  throwable=true,
	color={r=100,g=100,b=100,a=255},
	ranged_attack="genericthrow",
  stacks=true,
  value=10,
  types={'throwable','fire'},
  tags={'explosive','fire'}
}
possibleItems['molotov'] = molotov

local soul = {
  name = "soul",
  pluralName = "souls",
  description = "A bottle containing a wispy, glowing soul. Delicious to demons, but incredibly problematic from an ethical standpoint for you to just be carrying around.",
  symbol="!",
	category="throwable",
  usable=true,
  useVerb="consume",
  throwable=true,
	color={r=200,g=255,b=255,a=125},
	ranged_attack="genericthrow",
  projectile_name="soul",
  stacks=true,
  value=1,
  types={'throwable','holy','soul'},
  tags={'holy','unholy','magic','soul'},
  noEnchantments=true,
  neverStore=true
}
function soul:use(user)
  if user:is_type('demon') then
    output:out(user.name .. " consumes a soul and regains all their HP and MP!")
    user:updateHP(user:get_max_hp())
    user:delete_item(self)
  else
    if user == player then output:out("You're not a demon. You can't consume souls.") end
    return false
  end
end
possibleItems['soul'] = soul

local holywater = {
  name = "holy water",
  pluralName = "vials of holy water",
  description = "A small vial filled with a slightly glowing liquid.",
  symbol="!",
	category="throwable",
  usable=true,
  throwable=true,
	color={r=0,g=200,b=200,a=255},
	ranged_attack="genericthrow",
  projectile_name="holywater",
  stacks=true,
  types={'throwable','holy','liquid'},
  tags={'liquid','holy'},
  noEnchantments=true,
  useVerb="Apply",
  value=5
}
function holywater:use()
  local list = {}
  for i,item in ipairs(player.inventory) do
    if item:qualifies_for_enchantment('blessed') then
      local afterFunc = function()
        output:out(player:get_name() .. " applies holy water to " .. item:get_name() .. ".")
        item:apply_enchantment('blessed',tweak(5))
        player:delete_item(self)
        advance_turn()
      end
      list[#list+1] = {text=item:get_name(true),description=item:get_description(),selectFunction=afterFunc,selectArgs={}}
    end
  end
  if #list > 0 then
    Gamestate.switch(multiselect,list,"Bless a Weapon",true,true)
    return false
  else
    output:out("You can't apply holy water to any of your weapons.")
    return false,"You can't apply holy water to any of your weapons."
  end
end
possibleItems['holywater'] = holywater

local unholywater = {
  name = "unholy water",
  pluralName = "vials of unholy water",
  description = "A small vial filled with a liquid that seems to absorb all light around it.",
  symbol="!",
	category="throwable",
  throwable=true,
	color={r=100,g=0,b=100,a=255},
	ranged_attack="genericthrow",
  projectile_name="unholywater",
  stacks=true,
  types={'throwable','unholy','liquid'},
  tags={'liquid','unholy'},
  value=5,
  noEnchantments=true
}
possibleItems['unholywater'] = unholywater

local painwand = {
  name = "Wand of Horrific Pain",
  description = "A horrible device that causes damage to a target.",
  symbol = "/",
  category = "usable",
  usable=true,
  color={r=255,g=0,b=255,a=255},
  charges=5,
  cooldown=10,
  target_type = "creature",
  types={'magic','wand','wood'},
  tags={'magic','wood'},
  value=50
}
function painwand:use(target,user)
  if self.charges < 1 then
    if user == player then output:out("The wand is out of charges.") end
    return false,"The wand is out of charges."
  end
  if target then
    local dmg = target:damage(5)
    if player:can_sense_creature(target) then output:out(user:get_name() .. " blasts " .. target:get_name() .. " with a wand, dealing " .. dmg .. " damage.") end
    self.charges = self.charges-1
    self.value = math.max(self.charges*5,1)
    return true
  else
    return false
  end
end
possibleItems['painwand'] = painwand

local firewand = {
  name = "Wand of Fireballs",
  description = "A wand that shoots fireballs.",
  symbol = "/",
  category="weapon",
  subcategory="ranged",
  equippable=true,
  equipSlot="wielded",
  ranged_attack='smallfireball',
  color={r=255,g=0,b=255,a=255},
  cooldown=10,
  target_type = "creature",
  types={'magic','wand','wood','fire','weapon','ranged weapon'},
  tags={'magic','wood','fire'},
  value=50
}
possibleItems['firewand'] = firewand

local breastplate = {
  name="iron breastplate",
	description="An iron breastplate.",
	symbol="]",
	category="armor",
  subcategory="torso",
  equippable=true,
  equipSlot="torso",
  equipText = "You put on the iron breastplate. It's heavy.",
  unequipText = "You take off the iron breastplate and breathe easier.",
	color={r=150,g=150,b=150,a=255},
  types={'armor','metal'},
  tags={'iron'},
  value=25,
  level=1,
  armor={all=5},
  bonuses={dodge_chance=-15},
  bonuses_per_level={dodge_chance=1},
  equip = function(self,equipper)
    return true,"Heavy!"
  end
}
possibleItems['breastplate'] = breastplate

local helmet = {
  name="iron helmet",
	description="An iron helmet.",
	symbol="]",
	category="armor",
  subcategory="head",
  equippable=true,
  equipSlot="head",
  equipText = "You put on the iron helmet. It makes your neck hurt.",
  unequipText = "You take off the iron helmet.",
	color={r=150,g=150,b=150,a=255},
  types={'armor','metal'},
  tags={'iron'},
  value=25
}
possibleItems['helmet'] = helmet

local gungauntlets = {
  name="gun gauntlets",
	description="An pair of gauntlets with gun barrels installed.",
	symbol="]",
	category="armor",
  subcategory="hands",
  equippable=true,
  equipSlot="hands",
	color={r=150,g=150,b=150,a=255},
  types={'armor','metal','weapon','ranged weapon'},
  tags={'iron','weapon','armor'},
  value=25,
  level=1,
  ranged_attack="revolver",
}
possibleItems['gungauntlets'] = gungauntlets

local loincloth = {
  name="loincloth",
	description="A loincloth.",
	symbol="]",
	category="armor",
  subcategory="legs",
  equippable=true,
  equipSlot="legs",
	color={r=150,g=150,b=150,a=255},
  types={'armor','clothing','cloth'},
  tags={'cloth'},
  bonuses={agility=1},
  value=25
}
possibleItems['loincloth'] = loincloth

local sexyring = {
  name="ring of +1000 sexiness",
	description="A ring that makes you incredibly hot.",
	symbol="o",
	category="accessory",
  equippable=true,
  equipSlot="accessory",
  types={'magic','ring','accessory'},
  tags={'magic'},
  damaged = function(self,possessor,attacker)
    possessor:give_condition('fireaura',random(5,10),attacker)
    conditions['fireaura']:advance(possessor)
	end,
	color={r=255,g=0,b=255,a=255},
  value=5
}
possibleItems['sexyring'] = sexyring

local uglyring = {
  name="ring of +1000 armor",
	description="A ring that makes you incredibly hard to hurt.",
	symbol="o",
	category="accessory",
  equippable=true,
  equipSlot="accessory",
  bonuses={armor=1000},
	color={r=0,g=255,b=255,a=255},
  types={'magic','ring','accessory'},
  tags={'magic'},
  drop_chance=25,
  value=5
}
possibleItems['uglyring'] = uglyring

local strengthring = {
  name="ring of +1000 strength",
	description="A ring that makes you incredibly strong.",
	symbol="o",
	category="accessory",
  equippable=true,
  equipSlot="accessory",
  bonuses={damage=1000},
	color={r=255,g=0,b=0,a=255},
  types={'magic','ring','accessory'},
  tags={'magic'},
  value=5
}
possibleItems['strengthring'] = strengthring

local sadring = {
  name="ring of +1000 sadness",
	description="A ring that makes you incredibly sad, which for some reason gives you psychic powers.",
	symbol="o",
	category="accessory",
  equippable=true,
  equipSlot="accessory",
  spells_granted={'blast'},
	color={r=0,g=0,b=255,a=255},
  types={'magic','ring','accessory'},
  tags={'magic'},
  value=5
}
possibleItems['sadring'] = sadring

local crossbow = {
  name = "crossbow",
  description="",
  symbol="]",
  category="weapon",
  subcategory="ranged",
  equippable=true,
  equipSlot="wielded",
  equipSize=2,
  max_charges=1,
  level=1,
  ranged_attack="crossbow",
  ranged_accuracy=5,
  charge_name="bolts",
  usesAmmo="bolt",
  color={r=150,g=150,b=150,a=255},
  types={'weapon','ranged weapon','wood'},
  tags={'wooden','ranged'},
  stats_per_level={ranged_accuracy=1,ranged_damage=1},
  value=10
}
possibleItems['crossbow'] = crossbow

local revolver = {
  name = "revolver",
  description="A trusty six shooter.",
  symbol="]",
  category="weapon",
  subcategory="ranged",
  equippable=true,
  equipSlot="wielded",
  charge_name="shots",
  max_charges=6,
  ranged_attack="revolver",
  usesAmmo="bullet",
  color={r=98,g=73,b=22,a=255},
  types={'weapon','ranged weapon','metal'},
  tags={'ranged'},
  value=10
}
possibleItems['revolver'] = revolver

local bow = {
  name = "bow",
  description="",
  symbol="]",
  category="weapon",
  subcategory="ranged",
  equippable=true,
  equipSlot="wielded",
  equipSize=2,
  level=1,
  ranged_attack="bow",
  ranged_accuracy=5,
  usesAmmo="arrow",
  color={r=150,g=150,b=150,a=255},
  types={'weapon','ranged weapon','wood'},
  tags={'wooden','ranged'},
  stats_per_level={ranged_accuracy=1,ranged_damage=1},
  value=10
}
possibleItems['bow'] = bow

local arrow = {
  name = "arrow",
  pluralName = "arrows",
  description = "A simple arrow.",
  symbol = ")",
  category="ammo",
  equippable=true,
  equipSlot="ammo",
  ammoType = "arrow",
  stacks=true,
  color={r=150,g=150,b=150,a=255},
  value=1,
  types={'sharp','ammo','arrow','wood'},
  tags={'sharp'}
}
function arrow:new()
  self.amount = tweak(10)
end
possibleItems['arrow'] = arrow

local bolt = {
  name = "crossbow bolt",
  pluralName = "crossbow bolts",
  description = "A simple crossbow bolt.",
  symbol = ")",
  category="ammo",
  equippable=true,
  equipSlot="ammo",
  ammoType = "bolt",
  stacks=true,
  color={r=150,g=150,b=150,a=255},
  value=1,
  tags={'sharp'}
}
function bolt:new()
  self.amount = tweak(10)
end
possibleItems['bolt'] = bolt

local firebolt = {
  name = "fire bolt",
  pluralName = "fiery bolts",
  description = "A crossbow bolt on fire.",
  symbol = ")",
  category="ammo",
  equippable=true,
  equipSlot="ammo",
  ammoType = "bolt",
  damage_type="fire",
  projectile_name="smallfireball",
  stacks=true,
  color={r=255,g=150,b=150,a=255},
  tags={'fire'},
  value=1
}
function firebolt:new()
  self.amount = tweak(10)
end
possibleItems['firebolt'] = firebolt

local explosivebolt = {
  name = "explosive bolt",
  pluralName = "explosive bolts",
  description = "An explosive crossbow bolt.",
  symbol = ")",
  category="ammo",
  equippable=true,
  equipSlot="ammo",
  ammoType = "bolt",
  projectile_name="bomb",
  stacks=true,
  color={r=255,g=255,b=150,a=255},
  value=1,
  noEnchantments=true
}
function explosivebolt:new()
  self.amount = tweak(10)
end
possibleItems['explosivebolt'] = explosivebolt

local bullet = {
  name = "bullet",
  pluralName = "bullets",
  description = "A simple bullet.",
  symbol = ")",
  category="ammo",
  equippable=true,
  equipSlot="ammo",
  ammoType = "bullet",
  tags={"sharp"},
  stacks=true,
  color={r=33,g=33,b=33,a=33},
  value=1
}
function bullet:new()
  self.amount = tweak(10)
end
possibleItems['bullet'] = bullet

local firebullet = {
  name = "fire bullet",
  pluralName = "fiery bullets",
  description = "A bullet on fire.",
  symbol = ")",
  category="ammo",
  equippable=true,
  equipSlot="ammo",
  ammoType = "bullet",
  damage_type="fire",
  projectile_name="smallfireball",
  stacks=true,
  color={r=255,g=150,b=150,a=255},
  tags={'fire'},
  value=1
}
function firebullet:new()
  self.amount = tweak(10)
end
possibleItems['firebullet'] = firebullet

local explosivebullet = {
  name = "explosive bullet",
  pluralName = "explosive bullets",
  description = "An explosive bullet.",
  symbol = ")",
  category="ammo",
  equippable=true,
  equipSlot="ammo",
  ammoType = "bullet",
  projectile_name="bomb",
  stacks=true,
  color={r=255,g=255,b=150,a=255},
  value=1,
  noEnchantments=true
}
function explosivebullet:new()
  self.amount = tweak(10)
end
possibleItems['explosivebullet'] = explosivebullet


local alcahest = {
  name = "alcahest vial",
  pluralName = "alcahest vials",
  description = "A universal alchemical ingredient.",
  symbol = "!",
  category="other",
  stacks=true,
  color={r=255,g=255,b=255,a=255},
  tags={'alchemy','ingredient'},
  value=5,
  }
possibleItems['alcahest'] = alcahest

local weaponoil = {
  name = "weapon oil",
  pluralName = "jar of weapon oil",
  description = "Oil used to apply an effect to a weapon. Useless without something else mixed in",
  symbol = "!",
  category="other",
  stacks=true,
  color={r=100,g=100,b=100,a=255},
  tags={'ingredient'},
  value=20
  }
possibleItems['weaponoil'] = weaponoil

local insectwing = {
  name = "insect wing",
  pluralName = "insect wings",
  description = "The wing of a giant insect.",
  symbol = "%",
  category="other",
  color={r=255,g=255,b=255,a=255},
  tags={'insect','bodypart','ingredient'},
  value=1,
  stacks=true,
  neverSpawn=true,
  remove_on_cleanup=true
  }
possibleItems['insectwing'] = insectwing

local dragonflyheart = {
  name = "dragon fly heart",
  pluralName = "dragon fly hearts",
  description = "The heart of a dragon fly. It's warm.",
  symbol = "%",
  category="other",
  color={r=255,g=0,b=0,a=255},
  tags={'insect','bodypart','fire','ingredient'},
  crafting_ingredient_properties={fire=1},
  crafting_ingredient_types={'alchemy'},
  value=1,
  stacks=true,
  neverSpawn=true,
  remove_on_cleanup=true
  }
possibleItems['dragonflyheart'] = dragonflyheart

local spores = {
  name = "handful of mushroom spores",
  pluralName = "handfuls of mushroom spores",
  description = "A small pile of mushroom spores.",
  symbol = "%",
  category="other",
  color={r=150,g=150,b=150,a=255},
  tags={'fungus','nature','ingredient'},
  value=1,
  stacks=true,
  neverSpawn=true,
  remove_on_cleanup=true
  }
possibleItems['spores'] = spores

local mushroomcap = {
  name="mushroom cap",
	description="The top of a mushroom. Large enough to be worn on your own head.",
	symbol="]",
	category="armor",
  subcategory="head",
  equippable=true,
  equipSlot="head",
	color={r=255,g=0,b=0,a=0},
  tags={'bodypart','nature','ingredient'},
  value=1,
  neverSpawn=true,
  remove_on_cleanup=true
}
possibleItems['mushroomcap'] = mushroomcap

local bone = {
  name = "bone",
  pluralName = "bones",
  description = "A bone from some dead creature.",
  symbol = "%",
  category="throwable",
  color={r=255,g=255,b=255,a=255},
  tags={'death','bodypart','ingredient','necromancy'},
  ranged_accuracy=-15,
  value=1,
  stacks=true,
  neverSpawn=true,
  remove_on_cleanup=true
  }
possibleItems['bone'] = bone

local humanskull = {
  name = "skull",
  pluralName = "skulls",
  description = "A human skull.",
  symbol = "%",
  category="throwable",
  color={r=255,g=255,b=255,a=255},
  tags={'death','bodypart','ingredient','necromancy'},
  value=1,
  stacks=true,
  projectile_name="skull",
  throwable=true,
	color={r=255,g=255,b=255,a=255},
	ranged_attack="genericthrow",
  neverSpawn=true,
  remove_on_cleanup=true
  }
possibleItems['humanskull'] = humanskull

local bloodextractor = {
  name = "blood extractor",
  description = "A device with a series of syringes and tubes, for extracting vials of blood.",
  symbol = "&",
  category="usable",
  usable=true,
  useVerb="Extract Blood",
  color={r=100,g=100,b=100,a=255},
  value=50
}
function bloodextractor:use(corpse,user)
  if not corpse then
    local corpses = {}
    for _,feat in pairs(currMap:get_tile_features(user.x,user.y)) do
      if feat.id == "corpse" and not feat.bloodless and feat.creature and not feat.creature:is_type('bloodless') then
        corpses[#corpses+1] = corpse
      end
    end
    if #corpses == 1 then
      corpse = corpses[1]
    elseif #corpses > 1 then
      --add a list
    end
  end
  if corpse then
    corpse.bloodless = true
    user:give_item(Item('blood'))
    if user == player or player:can_sense_creature(user) then output:out(user:get_name() .. " extracts some blood from the corpse of " .. corpse.creature:get_name() ..  ".") end
  else
    output:out("There are no corpses here with blood in them.")
    return false,"There are no corpses here with blood in them."
  end
end
possibleItems['bloodextractor'] = bloodextractor

local stew = {
  name = "stew",
  description="Delicious stew.",
  symbol="%"
}
possibleItems['stew'] = stew

local tomato = {
  name = "tomator",
  description="Delicious stew.",
  symbol="%",
  color={r=255,g=0,b=0},
  crafting_ingredient_properties={vegetable=1},
  crafting_given_bonuses={hp=1}
}
possibleItems['tomato'] = tomato

local pepper = {
  name = "hot pepper",
  description="A spicy chili pepper.",
  symbol="%",
  color={r=255,g=0,b=0},
  crafting_ingredient_properties={vegetable=1},
  crafting_given_bonuses={fire_armor=1}
}
possibleItems['pepper'] = pepper

local chicken = {
  name = "chicken",
  description="Raw chicken.",
  symbol="%",
  color={r=255,g=0,b=0},
  crafting_given_bonuses={hp=10},
  crafting_ingredient_properties={protein=2},
}
possibleItems['chicken'] = chicken

local heroskey = {
  name = "Hero's Key",
  pluralName = "Hero's Keys",
  description = "A key that unlocks the gates to valhalla.",
  symbol="\\",
  color={r=255,g=255,b=0,a=255},
  category="other"
}
possibleItems['heroskey'] = heroskey

local treasure = {
  name = "Treasure",
  description = "A priceless treasure.",
  symbol="!",
  color={r=255,g=255,b=0,a=255},
  category="other"
}
possibleItems['treasure'] = treasure

--Standard items used within the engine

local money = {
  name = "money",
  description = "A pile of money.",
  symbol = "$",
  category="other",
  color={r=255,g=255,b=0,a=255},
  value=1
}
function money:new(amount)
  if type(amount) ~= "number" then
    amount = random(10,50)
  end
  self.value = amount
  self.name = get_money_name(amount)
end
function money:pickup(possessor)
  possessor.money = possessor.money + self.value
  self:delete()
  return false
end
possibleItems['money'] = money