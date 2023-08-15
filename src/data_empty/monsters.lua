possibleMonsters = {}

--Creature definitions for player races:
local humanHero = {
  name = "human",
  description = "A real human being, and a real hero.",
  symbol = "n",
  types={"human","intelligent"},
  nameType = "human",
  max_hp = 1,
  level = 1,
  perception = 8,
  color={r=255,g=255,b=255,a=255},
  gender="either",
  neverSpawn=true,
  playerSpecies=true
}
possibleMonsters['player_human'] = humanHero