possibleMonsters = {}

local rabidnerd = {
  name = "nerd",
  description = "This pimply-faced young man looks pretty angry. I guess it's true what they say about violent video games.",
  symbol = "n",
  types={"human","intelligent"},
  tags={"mainbranch"},
  nameType = "human",
  possible_inventory={{item="healthpotionminor",chance=100,min_amt=2,max_amt=5},{item="scroll",chance=50}},
  possible_weapon={"dagger"},
  possible_accessory={false,false,false,false,false,false,"sexyring","uglyring","strengthring","sadring"},
  max_hp = 6,
  level = 1,
  skills={strength=2,toughness=1,agility=7,melee=2,ranged=3},
  perception = 5,
  notice_chance = 75,
  aggression = 100,
  bravery = 1,
  min_distance = 3,
  color={r=255,g=255,b=255,a=255},
  rarity=50,
  gender="male",
  animated=true,
  spritesheet=true,
  animation_time=0.3,
  image_max=3,
  reverseAnimation=true,
  image_name = "rabidnerd1",
  image_varieties=3,
}
possibleMonsters['rabidnerd'] = rabidnerd

local slimemold = {
  name = "slime",
  description = "A disgusting creature, barely sentient. If you cut it in half, both halves will continue to live, and that's just gross.",
  types={"mindless","bloodless"},
  tags={"mainbranch"},
  symbol = "J",
  level = 1,
  skills={strength=4,agility=1,toughness=25,melee=6},
  max_hp = 200,
  perception = 4,
  aggression = 25,
  faction="chaos",
  ignore_distance = 2,
  color={r=0,g=255,b=255},
  corpse='slime',
  weaknesses={fire=25,ice=25,water=25},
  resistances={acid=50,electric=25},
  spells={'slimesplit'},
  animated=true,
  spritesheet=true,
  image_max=4,
  randomAnimation=true,
  animation_time = 0.33
}
possibleMonsters['slimemold'] = slimemold

local imp = {
  name = "imp",
  description = "A tiny demon with wings and a pitchfork.",
  symbol = "i",
  types={"demon","intelligent","flyer"},
  tags={"mainbranch"},
  pathType = "flyer",
  nameType = "imp",
  ai_flags={"bully"},
  factions={"demons"},
  ranged_attack="smallfireball",
  ranged_chance=33,
  max_hp = 5,
  level = 1,
  max_level=3,
  skills={strength=2,toughness=2,agility=10,melee=4,magic=5},
  perception = 5,
  notice_chance = 75,
  aggression = 100,
  bravery = 1,
  min_distance = 3,
  color={r=255,g=0,b=0,a=255},
  gender="neuter",
  animated=true,
  spritesheet=true,
  animation_time=0.3,
  image_max=3,
  reverseAnimation=true,
  image_name = "imp1",
  image_varieties=3
}
possibleMonsters['imp'] = imp

local cherub = {
  name = "cherub",
  description = "This tiny little flying baby is armed with a bow and arrow.",
  symbol = "c",
  types={"intelligent","angel","flyer"},
  tags={"mainbranch"},
  factions={"angels"},
  nameType = "angel",
  pathType="flyer",
  ranged_attack="cherubbow",
  level = 1,
  bravery=70,
  perception = 12,
  skills={strength=2,toughness=2,agility=10,ranged=5},
  max_hp=7,
  min_distance = 3,
  run_chance = 40,
  ranged_chance = 80,
  gender='neuter',
  corpse="lightflash",
  castsLight=true,
  lightDist=1,
  color={r=255,g=255,b=200,a=255},
  animated=true,
  spritesheet=true,
  animation_time=0.1,
  image_max=4,
  image_name = "cherub1",
  image_varieties=3
}
possibleMonsters['cherub'] = cherub

local demonhunter = {
  name = "demon hunter",
  description = "A holy warrior.",
  symbol = "h",
  types={"human","intelligent"},
  tags={"mainbranch"},
  nameType = "human",
  factions={"lightchurch"},
  max_hp = 25,
  max_mp = 10,
  level = 1,
  max_level=5,
  skills={strength=5,toughness=5,agility=5,melee=5,ranged=3,magic=3},
  perception = 5,
  notice_chance = 75,
  aggression = 100,
  learns_spells={{spell="smite",level=2}}, --These spells will be automatically granted once a certain level is reached
  color={r=150,g=150,b=150,a=255},
  gender="male",
  animated=true,
  spritesheet=true,
  animation_time=0.3,
  image_max=3,
  reverseAnimation=true,
  image_name = "demonhunter1",
  image_varieties=3,
}
possibleMonsters['demonhunter'] = demonhunter

local demonbrute = {
  name = "demon brute",
  description = "A big, hulking demon.",
  symbol = "d",
  types={"demon","intelligent"},
  nameType = "demon",
  factions={"demons"},
  ai_flags={"bully"},
  max_hp = 30,
  level = 3,
  max_level=7,
  skills={strength=12,agility=8,toughness=10,melee=10,magic=2},
  perception = 5,
  notice_chance = 75,
  aggression = 100,
  color={r=255,g=0,b=0,a=255},
  gender="male",
  animated=true,
  spritesheet=true,
  animation_time=0.3,
  image_max=3,
  reverseAnimation=true
}
possibleMonsters['demonbrute'] = demonbrute


--Swamp creatures:

local dragonfly = {
  name = "dragon fly",
  description = "This brightly-colored insect eats mosquitos and breathes fire.",
  types={"animal","flyer","bug","fire"},
  possible_death_items={{item="insectwing",chance=75,max_amt=2},{item="dragonflyheart",change=100}},
  enemy_types={'mosquito'},
  ranged_attack="smallfireball",
  pathType = "flyer",
  symbol = "d",
  corpse="firemaker",
  soundgroup="giantbug",
  color={r=255,g=0,b=0,a=255},
  bloodColor={r=200,g=255,b=200},
  level=1,
  skills={strength=2,toughness=3,agility=10,melee=4},
  max_hp=15,
  perception=7,
  speed = 120,
  bravery=60,
  ranged_chance=65,
  resistances={fire=50},
  weaknesses={ice=50},
  topDown = true,
  specialOnly = true,
  animated=true,
  spritesheet=true,
  image_max=2,
  animation_time = 0.1,
  image_name = "dragonfly1",
  image_varieties=6,
  new = function(self)
    local color = self.image_variety --random(1,6)
    --self.image_name = "dragonfly" .. color
    if color == 1 then
      self.color = {r=255,g=0,b=0,a=255}
    elseif color == 2 then
      self.color = {r=0,g=255,b=0,a=255}
    elseif color == 3 then
      self.color = {r=0,g=0,b=255,a=255}
    elseif color == 4 then
      self.color = {r=255,g=255,b=0,a=255}
    elseif color == 5 then
      self.color = {r=255,g=0,b=255,a=255}
    elseif color == 6 then
      self.color = {r=0,g=255,b=255,a=255}
    end
  end
}
possibleMonsters['dragonfly'] = dragonfly

local shroomman = {
  name = "mellow mushroom man",
  description = "A foot-tall semi-sentient fungus!",
  types={"mindless","plant","bloodless"},
  possible_death_items={{item="spores",chance=50},{item="mushroomcap",chance=75}},
  tags={"poison"},
  symbol = "p",
  skills={strength=4,toughness=3,agility=2,melee=5},
  max_hp = 15,
  perception = 4,
  aggression = 20,
  color={r=255,g=181,b=255},
  group_spawn_min=2,
  group_spawn_max=3,
  speed=90,
  level = 1,
  corpse = false,
  spells={'sporedeath','sleepless'},
  specialOnly=true,
  resistances={poison=75},
  animated=true,
  spritesheet=true,
  image_max=5,
  reverseAnimation=true,
  animation_time = 0.25
}
function shroomman:explode()
  output:out(self:get_name() .. " explodes into spores!")
  for i=1,random(2,4),1 do
    currMap:add_effect(Effect('spores'),self.x,self.y)
  end
  return true
end
possibleMonsters['shroomman'] = shroomman

local mosquito = {
  name = "giant mosquito",
  description = "A giant bloodsucking pest.",
  types={"animal","flyer","bug","mosquito"},
  possible_death_items={{item="insectwing",chance=75,max_amt=2}},
  pathType = "flyer",
  symbol = "Q",
  soundgroup="giantbug",
  color={r=255,g=255,b=255,a=255},
  level=1,
  skills={strength=2,toughness=3,agility=10,melee=6},
  max_hp=5,
  perception=12,
  group_spawn_max=3,
  spells={'vampirism'},
  hit_conditions={{condition='disease',minTurns=3,maxTurns=10,chance=10,crit_turns=10,crit_chance=100}},
  weaknesses={cold=50,fire=25},
  speed = 120,
  bravery=60,
  specialOnly = true,
  animated=true,
  spritesheet=true,
  image_max=4,
  animation_time = 0.1
}
possibleMonsters['mosquito'] = mosquito

local witch = {
  name = "Witch of the Woods",
  description = "A hideous crone, covered in warts and boils. Apparently living in the wilderness is really bad for your skin.",
  types={"human","intelligent"},
  nameType = "witch",
  symbol = "w",
  color={r=50,g=50,b=50,a=255},
  level=3,
  skills={strength=9,agility=23,toughness=6,melee=18,magic=20},
  possible_inventory={{item="bosskey",chance=100}},
  max_hp=90,
  perception=8,
  ranged_chance = 25,
  bravery=60,
  spells={'blink','curse'},
  isBoss=true,
  resistances={poison=20,dark=10},
  specialOnly = true,
  animated=true,
  spritesheet=true,
  image_max=2,
  animation_time = 0.5
}
possibleMonsters['witch'] = witch

--Graveyard creatures:

local zombie = {
  name="zombie",
  description="A dead body that tried to follow its former soul to the Nether Regions, but was refused entry. Now it wanders aimlessly, full of hunger and pain.",
  symbol = "z",
  types={"undead","mindless"},
  tags={"undead","death","necromancy"},
  ai_flags={"stubborn"},
  max_hp = 25,
  level = 1,
  max_level=5,
  skills={strength=5,toughness=10,melee=5},
  toughness=10,
  perception = 5,
  stealth = -5,
  notice_chance = 40,
  weaknesses={fire=50,holy=50},
  resistances={dark=50},
  crit_conditions={{condition="disease",turns=10,chance=100}},
  enemy_factions={'rat'},
  spells={"zombieplague"},
  speed=90,
  color={r=0,g=150,b=0,a=255},
  bloodColor={r=55,g=15,b=15},
}
function zombie:became_thrall(master)
  if master.id ~= "zombie" then self.name = "zombie of " .. master:get_name(false,true) end
end
function zombie:became_free()
  self.name = "zombie"
end
possibleMonsters['zombie'] = zombie

local ghoul = {
  name="ghoul",
  description="A disgusting creature that feeds on the dead. Weak and scrawny, but filled with a ravenous appetite.",
  symbol = "g",
  types={"undead"},
  tags={"undead","death"},
  max_hp = 15,
  level = 1,
  max_level=5,
  skills={strength=3,tougness=5,agility=7,melee=5},
  perception = 7,
  aggression = 50,
  notice_chance = 75,
  spells={'devourcorpse','paralyzingtouch','sleepless'},
  weaknesses={fire=50,holy=50},
  resistances={dark=50},
  color={r=96,g=90,b=6,a=255},
  bloodColor={r=55,g=15,b=15},
}
possibleMonsters['ghoul'] = ghoul

local skeleton = {
  name="skeleton",
  description="How a skeleton can ",
  symbol = "s",
  types={"undead","mindless","bloodless"},
  tags={"undead","necromancy"},
  max_hp = 10,
  level = 1,
  max_level=5,
  skills={strength=2,agility=6,toughness=3,melee=6,ranged=10},
  perception = 7,
  color={r=200,g=200,b=200,a=255},
  notice_chance = 60,
  ranged_attack="skellibone",
  weaknesses={holy=50},
  resistances={dark=50},
  ranged_chance=33,
  corpse="bonepile"
}
function skeleton:explode()
  if player:can_see_tile(self.x,self.y) then
    output:out(self:get_name() .. " explodes into shards of bone!")
    output:sound('skeleton_explode')
  end
  for x=self.x-1,self.x+1,1 do
    for y=self.y-1,self.y+1,1 do
      Projectile('boneshard',self,{x=x,y=y})
    end --end fory
  end --end forx
  return true
end
function skeleton:became_thrall(master)
  self.name = "skeleton of " .. master:get_name(false,true)
end
function skeleton:became_free()
  self.name = "skeleton"
end
possibleMonsters['skeleton'] = skeleton

local vampireBat = {
  name = "vampire bat",
  description = "A small bat with extremely sharp fangs. Is it really a vampire, or is it just rabid? Either way, you can't stop here.",
  symbol = "b",
  types={"undead","animal","flyer","vampire"},
  tags={"undead","vampire"},
  pathType = "flyer",
  max_hp = 10,
  level = 1,
  max_level=5,
  skills={strength=3,toughness=5,agility=10,melee=7},
  perception = 10,
  aggression = 50,
  notice_chance = 70,
  stealth = 10,
  color={r=70,g=0,b=143,a=255},
  weaknesses={fire=50,holy=50},
  resistances={dark=50},
  speed=125,
  spells={'vampirism'}
}
possibleMonsters['vampirebat'] = vampireBat

local undeadexterminator = {
  name = "undead undead exterminator",
  description = "This guy came here to exterminate the undead. Then he got killed, and became undead himself.",
  symbol = "h",
  types={"undead"},
  tags={"undead","technology","poison"},
  max_hp = 15,
  level = 1,
  max_level=5,
  skills={strength=3,toughness=5,agility=5,melee=4},
  perception = 6,
  notice_chance = 80,
  spells = {'poisoncloud','trap'},
  color={r=163,g=161,b=116},
  bloodColor={r=55,g=15,b=15},
  weaknesses={fire=50,holy=50},
  resistances={dark=50,poison=25}
}
possibleMonsters['undeadexterminator'] = undeadexterminator
  
local caretaker = {
  name = "caretaker",
  description = "An unfortunate caretaker of this graveyard.",
  symbol = "p",
  types={"intelligent","human"},
  nameType = "human",
  factions={"grievers"},
  color={r=100,g=100,b=100},
  max_hp = 25,
  max_mp = 5,
  level = 1,
  max_level=5,
  skills={strength=3,toughness=5,agility=6,melee=5,magic=2,ranged=4},
  perception = 7,
  bravery = 50,
  aggression = 40,
  notice_chance = 90,
  ranged_chance = 20,
  stealth=10,
  resistances={dark=10},
  gender='either',
  --spells = {'zombait','undeadrepellent'},
  crit_conditions={{condition="stunned",turns=3,chance=100}},
}
possibleMonsters['caretaker'] = caretaker

--Town creatures:

local townsperson = {
  name="townsperson",
  description="A simple farmer, salt of the earth.",
  types = {"intelligent","human"},
  ai_flags={"passive"},
  factions={"village"},
  symbol = "t",
  nameType = "human",
  gender="either",
  specialOnly=true,
  money=10,
  level = 0,
  skills={strength=1,agility=1,toughness=5,melee=1,ranged=1},
  max_hp = 10,
  perception = 5,
  aggression = 0,
  notice_chance = 100,
  bravery=0,
  color={r=219,g=150,b=79,a=255},
  animated=true,
  spritesheet=true,
  animation_time=0.5,
  image_max=2,
  image_name = "villager1",
  image_varieties=3,
  new = function(self)
    self.soundgroup = "human_" .. self.gender .. "_medium"
    self.description = namegen:generate_villager_description(self)
    local r,g,b=random(0,255),random(0,255),random(0,255)
    while r+g+b < 100 do
      r,g,b=random(0,255),random(0,255),random(0,255)
    end
    self.color={r=r,g=g,b=b,a=255}
    local careers = {'butcher','baker','candlestick maker','hot dog vendor','clockmaker','banker','shopkeeper','IT specialist','town drunk','wastrel','drug dealer','hunter','lumberjack','carpenter','beekeeper','innkeeper','brewer','bartender','soapmaker','cheesemaker','farmer','dairy farmer','naturalist','doctor','witch doctor','apothecary','chemist','pharmacist','lawyer','beggar','cowhand','engineer','scientist','writer','musician','painter','artist','sculptor','dancer','construction worker','stonemason','priest','medium','atheist','bookkeeper','librarian','accountant','food scientist','tinker','tailor','soldier','spy','philosopher'}
    local career = careers[random(#careers)]
    self.name = career
    self.description = "A simple " .. career .. ", salt of the earth."
  end
}
possibleMonsters['townsperson'] = townsperson

local townguard = {
  name="guard",
  description="A guard, tasked with keeping the peace. Which really just means causing harm to those the people in the town dislike.",
  types = {"intelligent","human"},
  factions={"village"},
  symbol = "p",
  nameType = "human",
  guardWanderDistance=5,
  gender="either",
  specialOnly=true,
  level = 1,
  max_hp = 25,
  skills={strength=5,agility=5,toughness=5,melee=5,ranged=5},
  level = 1,
  max_level=10,
  perception = 5,
  aggression = 100,
  notice_chance = 50,
  bravery=75,
  color={r=150,g=150,b=150,a=255}
}
possibleMonsters['townguard'] = townguard

--Creature definitions for player races:
local humanHero = {
  name = "human",
  description = "A real human being, and a real hero.",
  symbol = "n",
  types={"human","intelligent"},
  nameType = "human",
  max_hp = 50,
  max_mp = 0,
  level = 1,
  skills={strength=5,agility=5,toughness=5},
  perception = 8,
  color={r=255,g=255,b=255,a=255},
  gender="either",
  animated=true,
  spritesheet=true,
  animation_time=0.3,
  image_max=3,
  reverseAnimation=true,
  image_name = "hero1",
  image_varieties=3,
  neverSpawn=true,
  playerSpecies=true
}
possibleMonsters['player_human'] = humanHero

local spiderHero = {
  name = "spiderperson",
  description = "Half-spider, half-person, all creepy. Fairly weak and fragile, but can shoot webs. Also has 4 arms and 4 legs, meaning they can weild 4 weapons, and wear two different pairs of pants, boots, and gloves.",
  symbol = "n",
  types={"intelligent","insect"},
  nameType = "human",
  spells={"webshot"},
  learns_spells={{spell="poisonbite",level=3}}, --These spells will be automatically granted once a certain level is reached
  max_hp = 30,
  level = 1,
  skills={strength=2,agility=7,toughness=3},
  perception = 8,
  equipment_slots={wielded=4,head=1,torso=1,hands=2,legs=2,feet=2,accessory=3},
  color={r=255,g=255,b=255,a=255},
  gender="either",
  animated=true,
  spritesheet=true,
  animation_time=0.3,
  image_max=3,
  reverseAnimation=true,
  image_name = "hero1",
  image_varieties=3,
  neverSpawn=true,
  playerSpecies=true
}
possibleMonsters['player_spiderperson'] = spiderHero

local tigerHero = {
  name = "tiger",
  description = "A literal tiger. Can't equip anything but has really sharp claws.",
  symbol = "C",
  types={"animal"},
  hit_chance={{condition="bleeding",chance=10,turns=3,crit_chance=100,crit_turns=5}},
  max_hp = 65,
  level = 1,
  skills={strength=6,agility=6,toughness=7},
  perception = 10,
  skills={melee=5},
  skills_per_level={melee=1},
  stats_at_level={[5]={strength=5}},
  stats_per_x_levels={[2]={strength=1}},
  equipment_slots={accesory=3},
  color={r=255,g=255,b=255,a=255},
  gender="either",
  animated=true,
  spritesheet=true,
  animation_time=0.3,
  image_max=3,
  reverseAnimation=true,
  image_name = "hero1",
  image_varieties=3,
  neverSpawn=true,
  playerSpecies=true
}
possibleMonsters['player_tiger'] = tigerHero

local vampireHero = {
  name = "vampire",
  description = "A bloodsucking monster of the night.",
  symbol = "v",
  types={"undead","intelligent","vampire"},
  extra_stats={blood = {name="Blood",description="The amount of blood in your body. Used to power vampiric abilities.",value=100,bar_color={r=155,g=0,b=0,a=255}}},
  forbidden_tags={'holy','healing','food'},
  spells={"vampirism"},
  possible_inventory={{item="blood",chance=100,amount=5}},
  spell_purchases={{spell="batform",level=1,point_cost=3,upgrade_stat="upgrade_points_vampirism"}, {spell="auraoffear",level=5,point_cost=1,upgrade_stat="upgrade_points_vampirism"}, {spell="outforblood",level=3,point_cost=1,upgrade_stat="upgrade_points_vampirism"}},
  hit_conditions={{condition="bleeding",crit_chance=100,turns=5}},
  reputation={lightchurch=-1000}, --List of favor scores the character starts with
  nameType = "human",
  max_hp = 50,
  level = 1,
  skills={strength=5,agility=5,toughness=5,bloodpotency=1,bloodpool=10,bloodmetabolism=1},
  skills_per_x_levels={[5]={bloodpotency=1}},
  stealth = 10,
  perception = 8,
  color={r=255,g=255,b=255,a=255},
  gender="either",
  animated=true,
  spritesheet=true,
  animation_time=0.3,
  image_max=3,
  reverseAnimation=true,
  image_name = "hero1",
  image_varieties=3,
  neverSpawn=true,
  playerSpecies=true,
  weaknesses={fire=50}, --other weaknesses and resistances are applied from the undead creature type
}
possibleMonsters['player_vampire'] = vampireHero