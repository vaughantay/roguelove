possibleMonsters = {}

local rabidnerd = {
  name = "nerd",
  description = "This pimply-faced young man looks pretty angry. I guess it's true what they say about violent video games.",
  symbol = "n",
  types={"human","intelligent"},
  tags={"mainbranch"},
  nameType = "human",
  possible_inventory={{item="healthpotionminor",chance=100,min_amt=2,max_amt=5},{item="scroll",chance=50}},
  possible_death_items={{item="uglyring",chance=75}},
  possible_weapon={"dagger","firedagger"},
  possible_accessory={false,false,false,false,false,false,"sexyring","uglyring","strengthring","sadring"},
  max_hp = 5,
  level = 1,
  melee = 25,
  dodging = 45,
  strength = 11,
  perception = 5,
  notice_chance = 75,
  aggression = 100,
  bravery = 1,
  min_distance = 3,
  color={r=255,g=255,b=255,a=255},
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
  strength = 4,
  melee = 6,
  dodging = 3,
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
  maxLevel=3,
  melee = 4,
  dodging = 10,
  strength = 2,
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
  spells={'angelicdefense'},
  extraSense="angelichivemind",
  level = 10,
  bravery=70,
  perception = 12,
  melee = 2,
  dodging = 10,
  strength=2,
  max_hp=5,
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
  maxLevel=5,
  melee = 5,
  dodging = 5,
  strength = 5,
  magic=2,
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
  maxLevel=7,
  melee = 10,
  dodging = 12,
  strength = 8,
  magic=2,
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

local dragonfly = {
  name = "dragonfly",
  description = "This brightly-colored insect eats mosquitos and breathes fire.",
  types={"animal","flyer","bug"},
  ranged_attack="smallfireball",
  pathType = "flyer",
  symbol = "d",
  corpse="firemaker",
  soundgroup="giantbug",
  color={r=255,g=0,b=0,a=255},
  bloodColor={r=200,g=255,b=200},
  level=3,
  melee = 20,
  dodging = 30,
  strength=8,
  possession_chance = 55,
  max_hp=80,
  perception=7,
  speed = 120,
  bravery=60,
  armor=-5,
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
  tags={"poison"},
  symbol = "p",
  melee = 20,
  dodging = 20,
  strength = 6,
  possession_chance = 100,
  max_hp = 65,
  perception = 4,
  aggression = 20,
  color={r=255,g=181,b=255},
  speed=90,
  level = 0,
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
  types={"animal","flyer","bug"},
  pathType = "flyer",
  symbol = "Q",
  soundgroup="giantbug",
  color={r=255,g=255,b=255,a=255},
  level=8,
  melee = 50,
  dodging = 50,
  strength=18,
  possession_chance = 50,
  max_hp=225,
  perception=7,
  spells={'vampirism'},
  hit_conditions={{condition='disease',minTurns=3,maxTurns=10,chance=10,crit_turns=10,crit_chance=100}},
  weaknesses={cold=50,fire=25},
  speed = 120,
  bravery=60,
  armor=-1,
  specialOnly = true,
  animated=true,
  spritesheet=true,
  image_max=4,
  animation_time = 0.1
}
possibleMonsters['mosquito'] = mosquito

local swampwitch = {
  name = "witch",
  description = "A hideous crone, covered in warts and boils. Apparently living in a swamp is really bad for your skin.",
  types={"human","intelligent"},
  nameType = "witch",
  symbol = "w",
  color={r=50,g=50,b=50,a=255},
  level=3,
  melee = 18,
  dodging = 23,
  strength=9,
  possession_chance = 50,
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
possibleMonsters['swampwitch'] = swampwitch

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
  level = 0,
  strength = 1,
  possession_chance = 80,
  max_hp = 10,
  melee = 1,
  dodging = 1,
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
  gender="either",
  specialOnly=true,
  level = 1,
  max_hp = 25,
  max_mp = 10,
  level = 1,
  maxLevel=10,
  melee = 5,
  dodging = 5,
  strength = 5,
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
  melee = 5,
  dodging = 5,
  strength = 5,
  ranged = 5,
  magic = 0,
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
  max_mp = 0,
  level = 1,
  melee = 2,
  dodging = 6,
  strength = 2,
  ranged = 5,
  magic = 0,
  perception = 8,
  hands=4,
  equipment_slots={head=1,torso=1,hands=2,legs=2,feet=2,accessory=3},
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
  max_mp = 0,
  level = 1,
  melee = 6,
  dodging = 6,
  strength = 6,
  ranged = 0,
  magic = 0,
  perception = 10,
  equipment_slots={accesory=3},
  hands=0,
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
  spells={"vampirism"},
  possible_inventory={{item="blood",chance=100,amount=5}},
  learns_spells={{spell="smite",level=2}}, --These spells will be automatically granted once a certain level is reached
  spell_purchases={{spell="vanish",level=5,cost=2}, {spell="auraoffear",level=2,cost=2}},
  crit_chance={{condition="bleeding",chance=100,turns=5}},
  favor={lightchurch=-1000}, --List of favor scores the character starts with
  nameType = "human",
  max_hp = 50,
  max_mp = 0,
  level = 1,
  melee = 5,
  dodging = 5,
  strength = 5,
  ranged = 5,
  magic = 0,
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
  playerSpecies=true
}
possibleMonsters['player_vampire'] = vampireHero