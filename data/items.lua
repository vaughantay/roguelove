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
  consumed=true
}
function healthPotionMinor:use(user)
	user = user or player
	local heal = tweak(5)
	output:out(user.name .. " drinks a Potion of Minor Healing and regains " .. heal .. " HP!")
	user:updateHP(heal)
	user:delete_item(self)
end
possibleItems['healthpotionminor'] = healthPotionMinor

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
  consumed=true
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
  consumed=true
}
function scroll:new()
	self.spell = get_random_key(possibleSpells)
  while possibleSpells[self.spell].target_type == "passive" do
    self.spell = get_random_key(possibleSpells)
  end
	self.name = "scroll of " .. possibleSpells[self.spell].name
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
  useVerb="study"
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
	output:out("You look at the spells in the book.")
	for id, spellid in ipairs(self.spells) do
		output:out(id .. ") " .. possibleSpells[spellid].name)
	end
end
possibleItems['spellbook'] = spellBook

local greatsword = {
  name="greatsword",
	description="A really big sword.",
	symbol="†",
	itemType="weapon",
  equippable=true,
  equipSlot="weapon",
  hands=2,
	color={r=255,g=255,b=255,a=255},
	damage = 3,
	accuracy = 10,
	critical = 5,
	level = 1,
	strmod=5
}
possibleItems['greatsword'] = greatsword

local dagger = {
  name="dagger",
	description="A short-bladed dagger, wickedly sharp.",
	symbol="†",
	itemType="weapon",
  equippable=true,
  throwable=true,
  equipSlot="weapon",
  hands=1,
	color={r=200,g=200,b=200,a=255},
	damage = 3,
	accuracy = 10,
	critical = 5,
	level = 1,
	strmod=5
}
possibleItems['dagger'] = dagger

local selfharmdagger = {
  name="dual-bladed dagger",
	description="A short-bladed dagger, wickedly sharp. Unfortunately, its hilt is also a blade.",
  into = "Also deals damage to the attacker.",
	symbol="†",
	itemType="weapon",
  equippable=true,
  throwable=true,
  equipSlot="weapon",
  hands=1,
	color={r=200,g=200,b=200,a=255},
	damage = 3,
	accuracy = 10,
	critical = 5,
	level = 1,
	strmod=5
}
function selfharmdagger:attacked_with(target,wielder)
  local dmg = wielder:damage(5)
  output:out(wielder:get_name() .. " cuts themselves on " .. self:get_name() .. ", taking " .. dmg .. " damage.")
  return true
end
function selfharmdagger:calc_attack(target,wielder)
  return "hit",1000
end
possibleItems['selfharmdagger'] = selfharmdagger

local firedagger = {
  name="fire dagger",
	description="A short-bladed dagger, wickedly sharp, and on fire.",
	symbol="†",
	itemType="weapon",
  equippable=true,
  throwable=true,
  equipSlot="weapon",
  hands=1,
	color={r=255,g=200,b=200,a=255},
	damage = 3,
	accuracy = 10,
	critical = 5,
	level = 1,
  damage_type="fire"
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
  equippable=true,
  throwable=true,
  equipSlot="weapon",
  hands=1,
	color={r=255,g=255,b=200,a=255},
	damage = 3,
	accuracy = 10,
	critical = 5,
	level = 1,
  damage_type="holy"
}
possibleItems['holydagger'] = holydagger

local cattleprod = {
  name="cattle prod",
	description="A cattle prod. Deals no damage, but stuns.",
	symbol="†",
	itemType="weapon",
  equippable=true,
  equipSlot="weapon",
  hands=1,
	color={r=200,g=200,b=200,a=255},
	damage = 3,
	accuracy = 10,
	level = 1
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
	color={r=200,g=200,b=200,a=255}
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
}
function dart:new()
  self.amount = tweak(100)
end
possibleItems['dart'] = dart

local holywater = {
  name = "holy water",
  pluralName = "vials of holy water",
  description = "A small, sharp dart.",
  symbol="/",
	itemType="throwable",
  throwable=true,
	color={r=0,g=200,b=200,a=255},
	--ranged_attack="holywater",
  stacks=true,
}
possibleItems['holywater'] = holywater

local painwand = {
  name = "Wand of Horrific Pain",
  description = "A horrible device that causes damage to a target.",
  symbol = "/",
  itemType = "usable",
  usable=true,
  color={r=255,g=0,b=255,a=255},
  charges=5,
  target_type = "creature"
}
function painwand:use(target,user)
  if self.charges < 1 then
    if user == player then output:out("The wand is out of charges.") end
    return false,"The wand is out of charges."
  end
  if target then
    local dmg = target:damage(5)
    if player:can_sense_creature(target) then output:out(user:get_name() .. " blasts " .. target:get_name() .. " with a wand, dealing " .. dmg .. " damage.") end
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
	itemType="armor_torso",
  equippable=true,
  equipSlot="torso",
  equipText = "You put on the iron breastplate. It's heavy.",
  unequipText = "You take off the iron breastplate and breathe easier.",
	color={r=150,g=150,b=150,a=255},
  equip = function(self,equipper)
    equipper.max_hp = 1000
    return true,"Woof!"
  end
}
possibleItems['breastplate'] = breastplate

local sexyring = {
  name="ring of +1000 sexiness",
	description="A ring that makes you incredibly hot.",
	symbol="o",
	itemType="accessory",
  equippable=true,
  equipSlot="accessory",
  damaged = function(self,possessor,attacker)
    possessor:give_condition('fireaura',random(5,10),attacker)
    conditions['fireaura']:advance(possessor)
	end,
	color={r=255,g=0,b=255,a=255}
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
	color={r=0,g=255,b=255,a=255}
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
	color={r=255,g=0,b=0,a=255}
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
	color={r=0,g=0,b=255,a=255}
}
possibleItems['sadring'] = sadring

local crossbow = {
  name = "crossbow",
  description="",
  symbol="]",
  itemType="weapon",
  equippable=true,
  equipSlot="weapon",
  hands=1,
  charges = 0,
  max_charges=1,
  ranged_attack="crossbow",
  usesAmmo="bolt",
  color={r=150,g=150,b=150,a=255}
}
possibleItems['crossbow'] = crossbow

local revolver = {
  name = "revolver",
  description="A trusty six shooter.",
  symbol="]",
  itemType="weapon",
  equippable=true,
  equipSlot="weapon",
  hands=1,
  charges = 0,
  charge_name="shots",
  max_charges=6,
  ranged_attack="revolver",
  usesAmmo="bullet",
  color={r=98,g=73,b=22,a=255}
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
  color={r=150,g=150,b=150,a=255}
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
  stacks=true,
  color={r=33,g=33,b=33,a=33}
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
  color={r=255,g=150,b=150,a=255}
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
  color={r=255,g=255,b=150,a=255}
}
function explosivebolt:new()
  self.amount = tweak(100)
end
function explosivebolt:hits(target,shooter)
  
end
possibleItems['explosivebolt'] = explosivebolt