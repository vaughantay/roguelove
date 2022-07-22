gamesettings = {
  name = "Insert Game Title Here",
  id="rogueloveuntitled",
  author = "Weirdfellows",
  version_text = "In Development",
  copyright_text="Copyright 2022",
  url="http://weirdfellows.com",
  default_starting_branch="main",
  bosses=true,
  inventory=true,
  crafting=true,
  craft_anywhere=true,
  xp=true,
  leveling=true,
  events=true,
  player_tombstones=true,
  default_map_width=60,
  default_map_height=60,
  creature_density=5,
  item_density=1,
  enchantment_chance=50,
  artifact_chance=10,
  default_event_cooldown=20,
  default_event_chance=50,
  player_species=true,
  player_classes=true,
  default_player="player_human",
  tilesize=32,
  default_equipment_slots={head=1,torso=1,hands=1,legs=1,feet=1,accessory=3},
  default_inventory_order={'usable','throwable','weapon','offhand','armorhead','armortorso','armorhands','armorlegs','armorfeet','accessory','ammo','other'},
  default_equipment_order={'weapon','offhand','head','torso','hands','legs','feet','accessory','ammo'},
  inventory_filters={{filter='usable'},{filter='throwable'},{filter='equippable',itemType="weapon",label="Weapons"},{filter='equippable',itemType="weapon",subType="ranged",label="Ranged Weapons"},{filter='equippable',label="All Equipment"},{itemType="other",label="Miscellaneous"}},
  skill_points_per_level=5,
  can_pickup_adjacent_items=true
}