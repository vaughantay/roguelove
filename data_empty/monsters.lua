possibleMonsters = {}

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