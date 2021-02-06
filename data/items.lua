possibleItems = {}

local healthPotionMinor = {
  name = "potion of minor healing",
  pluralName = "potions of minor healing",
	description = "A crimson liquid swirls in this flask.",
	symbol = "!",
	color = {r=255,g=0,b=0,a=255},
	itemType="usable",
	stacks = true,
  usable=true,
  useVerb="drink",
  consumed=true,
  tags={'liquid','healing'},
  value=5
}
function healthPotionMinor:use(user)
	user = user or player
	local heal = tweak(5)
	output:out(user.name .. " drinks a Potion of Minor Healing and regains " .. heal .. " HP!")
	user:updateHP(heal)
	user:delete_item(self)
end
possibleItems['healthpotionminor'] = healthPotionMinor

local blood = {
  name = "blood vial",
  pluralName = "blood vials",
	description = "A crimson liquid swirls in this flask.",
	symbol = "!",
	color = {r=200,g=0,b=0,a=255},
	itemType="usable",
	stacks = true,
  usable=true,
  useVerb="drink",
  consumed=true,
  tags={'liquid','blood'},
  value=5
}
function blood:use(user)
	user = user or player
  if user:has_spell('vampirism') then
    local dmg = tweak(10)
    output:out(user:get_name() .. " drinks some blood and regains " .. dmg .. " health!")
    user:update_hp(dmg)
    user:delete_item(self)
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
	itemType="usable",
	stacks = true,
  usable=true,
  useVerb="drink",
  consumed=true,
  tags={'liquid','unholy','fire','blood'},
  value=5
}
function demonblood:use(user)
	user = user or player
	local dmg = user:damage(5,nil,"fire")
	output:out(user.name .. " drinks demon blood and takes " .. dmg .. " fire damage!")
	user:delete_item(self)
end
possibleItems['demonblood'] = demonblood

local scroll = {
	name = "scroll",
  pluralName = "scrolls",
	symbol = "?",
	description = "A faded parchment, bearing arcane writing.",
	color={r=255,g=255,b=255,a=255},
	itemType="usable",
	stacks = true,
	spell = nil,
  sortBy = "spell",
  usable=true,
  useVerb="read",
  consumed=true,
  tags={'paper','magic'},
  value=10
}
function scroll:new(spell,tags)
  if spell and type(spell) == "string" and possibleSpells[spell] and possibleSpells[spell].target_type ~= "passive" then --spell provided
    self.spell = spell
  else --invalid or no spell provided
    local possibles = {}
    for id,spell in pairs(possibleSpells) do
      if possibleSpells.target_type ~= "passive" then
        possibles[#possibles+1] = id
      end
    end --end spell for
    self.spell = get_random_element(possibles)
  end --end spell provided or not if
  
	self.name = "scroll of " .. possibleSpells[self.spell].name
  self.pluralName = "scrolls of " .. possibleSpells[self.spell].name
end
function scroll:use(target,user)
  if possibleSpells[self.spell].target_type == "self" then
    target = user
    possibleSpells[self.spell]:use(target,user,true)
    user:delete_item(self)
  else
    action="targeting"
    actionResult=possibleSpells[self.spell]
    actionItem=self
    actionIgnoreCooldown = true
  end
end
possibleItems['scroll'] = scroll

local spellBook = {
	name = "spellbook",
	symbol= "◊",
	color={r=255,g=255,b=255,a=255},
	description="A heavy tome, filled with mystical knowledge.",
	spells={},
	itemType="usable",
  usable=true,
  useVerb="study",
  tags={'paper','magic'},
  value=100
}
function spellBook:new()
	require "data.spells"
	self.color = {r=math.random(33,255),g=math.random(33,255),b=math.random(33,255),a=255}
	self.properName = namegen:generate_book_name()
	local s = {}
	for i=1,5,1 do
		s[i] = get_random_key(possibleSpells)
	end
	self.spells = s
  local text = "This book contains the following spells: "
  for id, spellid in ipairs(s) do
		text = text .. "\n" .. id .. ") " .. possibleSpells[spellid].name
	end
  self.info = text
end
function spellBook:use()
  local list = {}
  for _, spellid in ipairs(self.spells) do
    if not player:has_spell(spellid) then
      list[#list+1] = {text="Learn " .. possibleSpells[spellid].name,description=possibleSpells[spellid].description,selectFunction=player.learn_spell,selectArgs={player,spellid}}
    end
  end
  if #list > 0 then
    Gamestate.switch(multiselect,list,"Learn a Spell from " .. self.properName,true,true)
    return false
  else
    output:out("You already know all the spells in this book.")
    return false,"You already know all the spells in this book."
  end
end
possibleItems['spellbook'] = spellBook

local weaponPoison = {
	name = "weapon poison",
	symbol= "!",
	color={r=0,g=255,b=0,a=255},
	description="A bottle filled with a toxic substance.",
	spells={},
	itemType="usable",
  usable=true,
  useVerb="apply",
  tags={'liquid'},
  value=100
}
function weaponPoison:use()
  local list = {}
  for i,item in ipairs(player.inventory) do
    if item:qualifies_for_enchantment('poisoned') or item:qualifies_for_enchantment('poisoned_projectile') then
      local afterFunc = function()
        output:out(player:get_name() .. " applies poison to " .. item:get_name() .. ".")
        if item.itemType == "weapon" then
          item:apply_enchantment('poisoned',tweak(5))
        elseif item.itemType == "ammo" or item.itemType == "throwable" then
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

local greatsword = {
  name="greatsword",
	description="A really big sword.",
	symbol="†",
	itemType="weapon",
  subType="melee",
  equippable=true,
  equipSlot="weapon",
  hands=2,
	color={r=255,g=255,b=255,a=255},
	damage = 3,
	accuracy = 10,
	critical_chance = 5,
	level = 1,
	strmod=5,
  tags={'large','sharp','sword'},
  value=50
}
possibleItems['greatsword'] = greatsword

local dagger = {
  name="dagger",
	description="A short-bladed dagger, wickedly sharp.",
	symbol="†",
	itemType="weapon",
  subType="melee",
  equippable=true,
  throwable=true,
  preserve_on_throw=true,
  equipSlot="weapon",
  hands=1,
	color={r=200,g=200,b=200,a=255},
	damage = 3,
	accuracy = 10,
	critical_chance = 5,
	level = 1,
	strmod=5,
  tags={'sharp'},
  value=5,
  ranged_attack="dagger"
}
possibleItems['dagger'] = dagger

local selfharmdagger = {
  name="dual-bladed dagger",
	description="A short-bladed dagger, wickedly sharp. Unfortunately, its hilt is also a blade.",
  into = "Also deals damage to the attacker.",
	symbol="†",
	itemType="weapon",
  subType="melee",
  equippable=true,
  throwable=true,
  equipSlot="weapon",
  hands=1,
	color={r=200,g=200,b=200,a=255},
	damage = 3,
	accuracy = 10,
	critical_chance = 5,
	level = 1,
	strmod=5,
  tags={'sharp'},
  value=1
}
function selfharmdagger:attacked_with(target,wielder)
  local dmg = wielder:damage(5)
  output:out(wielder:get_name() .. " cuts themselves on " .. self:get_name() .. ", taking " .. dmg .. " damage.")
  return true
end
possibleItems['selfharmdagger'] = selfharmdagger

local firedagger = {
  name="fire dagger",
	description="A short-bladed dagger, wickedly sharp, and on fire.",
	symbol="†",
	itemType="weapon",
  subType="melee",
  equippable=true,
  throwable=true,
  equipSlot="weapon",
  hands=1,
	color={r=255,g=200,b=200,a=255},
	damage = 3,
	accuracy = 10,
	critical_chance = 5,
	level = 1,
  damage_type="fire",
  tags={'sharp','fire','hot'},
  value=10
}
function firedagger:after_damage(target,attacker)
  target:give_condition('onfire',10)
end
possibleItems['firedagger'] = firedagger

local holydagger = {
  name="holy dagger",
	description="A short-bladed dagger, wickedly sharp, and blessed with righteousness.",
	symbol="†",
	itemType="weapon",
  subType="melee",
  equippable=true,
  throwable=true,
  equipSlot="weapon",
  hands=1,
	color={r=255,g=255,b=200,a=255},
	damage = 3,
	accuracy = 10,
	critical_chance = 5,
	level = 1,
  damage_type="holy",
  tags={'sharp','holy'},
  value=10
}
possibleItems['holydagger'] = holydagger

local cattleprod = {
  name="cattle prod",
	description="A cattle prod. Deals no damage, but stuns.",
	symbol="†",
	itemType="weapon",
  subType="melee",
  equippable=true,
  equipSlot="weapon",
  hands=1,
	color={r=200,g=200,b=200,a=255},
	damage = 3,
	accuracy = 10,
	level = 1,
  tags={'nonlethal','electric'},
  value=10
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
	itemType="offhand",
  equippable=true,
  equipSlot="offhand",
  hands=1,
	color={r=200,g=200,b=200,a=255},
  tags={'wood'},
  value=5
}
possibleItems['buckler'] = buckler

local dart = {
  name = "dart",
  pluralName = "darts",
  description = "A small, sharp dart.",
  symbol="/",
	itemType="throwable",
  throwable=true,
	color={r=200,g=200,b=200,a=255},
	ranged_attack="dart",
  stacks=true,
  value=1,
  tags={'sharp'}
}
function dart:new()
  self.amount = tweak(100)
end
possibleItems['dart'] = dart

local soul = {
  name = "soul",
  pluralName = "souls",
  description = "A bottle containing a wispy, glowing soul. Delicious to demons, but incredibly problematic from an ethical standpoint for you to just be carrying around.",
  symbol="!",
	itemType="throwable",
  usable=true,
  useVerb="consume",
  throwable=true,
	color={r=200,g=255,b=255,a=125},
	ranged_attack="genericthrow",
  projectile_name="soul",
  stacks=true,
  value=1,
  tags={'holy','unholy','magic','soul'},
  noEnchantments=true
}
function soul:use(user)
  if user:is_type('demon') then
    output:out(user.name .. " consumes a soul and regains all their HP and MP!")
    user:updateHP(user:get_mhp())
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
	itemType="throwable",
  usable=true,
  throwable=true,
	color={r=0,g=200,b=200,a=255},
	ranged_attack="genericthrow",
  projectile_name="holywater",
  stacks=true,
  tags={'liquid','holy'},
  noEnchantments=true,
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
	itemType="throwable",
  throwable=true,
	color={r=100,g=0,b=100,a=255},
	ranged_attack="genericthrow",
  projectile_name="unholywater",
  stacks=true,
  tags={'liquid','unholy'},
  value=5,
  noEnchantments=true
}
possibleItems['unholywater'] = unholywater

local painwand = {
  name = "Wand of Horrific Pain",
  description = "A horrible device that causes damage to a target.",
  symbol = "/",
  itemType = "usable",
  usable=true,
  color={r=255,g=0,b=255,a=255},
  charges=5,
  target_type = "creature",
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
    self.value = math.max(self.charges*10,1)
    return true
  else
    return false
  end
end
possibleItems['painwand'] = painwand

local breastplate = {
  name="iron breasplate",
	description="An iron breastplate.",
	symbol="]",
	itemType="armor",
  subType="torso",
  equippable=true,
  equipSlot="torso",
  equipText = "You put on the iron breastplate. It's heavy.",
  unequipText = "You take off the iron breastplate and breathe easier.",
	color={r=150,g=150,b=150,a=255},
  tags={'iron'},
  value=25,
  equip = function(self,equipper)
    equipper.max_hp = 1000
    return true,"Woof!"
  end
}
possibleItems['breastplate'] = breastplate

local helmet = {
  name="iron helmet",
	description="An iron helmet.",
	symbol="]",
	itemType="armor",
  subType="head",
  equippable=true,
  equipSlot="head",
  equipText = "You put on the iron helmet. It makes your neck hurt.",
  unequipText = "You take off the iron helmet.",
	color={r=150,g=150,b=150,a=255},
  tags={'iron'},
  value=25
}
possibleItems['helmet'] = helmet

local sexyring = {
  name="ring of +1000 sexiness",
	description="A ring that makes you incredibly hot.",
	symbol="o",
	itemType="accessory",
  equippable=true,
  equipSlot="accessory",
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
	itemType="accessory",
  equippable=true,
  equipSlot="accessory",
  bonuses={armor=1000},
	color={r=0,g=255,b=255,a=255},
  tags={'magic'},
  value=5
}
possibleItems['uglyring'] = uglyring

local strengthring = {
  name="ring of +1000 strength",
	description="A ring that makes you incredibly strong.",
	symbol="o",
	itemType="accessory",
  equippable=true,
  equipSlot="accessory",
  bonuses={damage=1000},
	color={r=255,g=0,b=0,a=255},
  tags={'magic'},
  value=5
}
possibleItems['strengthring'] = strengthring

local sadring = {
  name="ring of +1000 sadness",
	description="A ring that makes you incredibly sad, which for some reason gives you psychic powers.",
	symbol="o",
	itemType="accessory",
  equippable=true,
  equipSlot="accessory",
  spells_granted={'blast'},
	color={r=0,g=0,b=255,a=255},
  tags={'magic'},
  value=5
}
possibleItems['sadring'] = sadring

local crossbow = {
  name = "crossbow",
  description="",
  symbol="]",
  itemType="weapon",
  subType="ranged",
  equippable=true,
  equipSlot="weapon",
  hands=1,
  charges = 0,
  max_charges=1,
  ranged_attack="crossbow",
  ranged_accuracy=5,
  usesAmmo="bolt",
  color={r=150,g=150,b=150,a=255},
  tags={'wooden','ranged'},
  value=10
}
possibleItems['crossbow'] = crossbow

local revolver = {
  name = "revolver",
  description="A trusty six shooter.",
  symbol="]",
  itemType="weapon",
  subType="ranged",
  equippable=true,
  equipSlot="weapon",
  hands=1,
  charges = 0,
  charge_name="shots",
  max_charges=6,
  ranged_attack="revolver",
  usesAmmo="bullet",
  color={r=98,g=73,b=22,a=255},
  tags={'ranged'},
  value=10
}
possibleItems['revolver'] = revolver

local bolt = {
  name = "crossbow bolt",
  pluralName = "crossbow bolts",
  description = "A simple crossbow bolt.",
  symbol = ")",
  itemType="ammo",
  equippable=true,
  equipSlot="ammo",
  ammoType = "bolt",
  stacks=true,
  color={r=150,g=150,b=150,a=255},
  value=1,
  tags={'sharp'}
}
function bolt:new()
  self.amount = tweak(100)
end
possibleItems['bolt'] = bolt

local bullet = {
  name = "bullet",
  pluralName = "bullets",
  description = "A simple bullet.",
  symbol = ")",
  itemType="ammo",
  equippable=true,
  equipSlot="ammo",
  ammoType = "bullet",
  tags={"sharp"},
  stacks=true,
  color={r=33,g=33,b=33,a=33},
  value=1
}
function bullet:new()
  self.amount = tweak(100)
end
possibleItems['bullet'] = bullet

local firebolt = {
  name = "fire bolt",
  pluralName = "fiery bolts",
  description = "A crossbow bolt on fire.",
  symbol = ")",
  itemType="ammo",
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
function firebolt:new()
  self.amount = tweak(100)
end
possibleItems['firebolt'] = firebolt

local explosivebolt = {
  name = "explosive bolt",
  pluralName = "explosive bolts",
  description = "An explosive crossbow bolt.",
  symbol = ")",
  itemType="ammo",
  equippable=true,
  equipSlot="ammo",
  ammoType = "bullet",
  projectile_name="bomb",
  stacks=true,
  color={r=255,g=255,b=150,a=255},
  value=1,
  noEnchantments=true
}
function explosivebolt:new()
  self.amount = tweak(100)
end
possibleItems['explosivebolt'] = explosivebolt

local bloodextractor = {
  name = "blood extractor",
  description = "A device with a series of syringes and tubes, for extracting vials of blood.",
  symbol = "&",
  itemType="usable",
  usable=true,
  useText="Extract Blood",
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