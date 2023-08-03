gamesettings = {
  name = "Roguelove Example Game",
  id="rogueloveexample",
  author = "Weirdfellows",
  version_text = "In Development Version",
  copyright_text="Copyright 2023 Weirdfellows",
  url="http://weirdfellows.com",
  default_starting_branch="town",
  bosses=true,
  inventory=true,
  crafting=true,
  craft_anywhere=true,
  auto_learn_possible_crafts=true, --If true, then when you have the ability and ingredients required for a recipe, it'll be shown on the crafting page even if you haven't explictly learned it yet. UNLESS the recipe has the no_auto_learn flag set
  xp=true,
  leveling=true,
  events=true,
  player_tombstones=true, --If true, tombstones will be created on levels where players were previous killed listing their date and cause of death
  default_map_width=60,
  default_map_height=60,
  no_map_descriptions=false, --If true, do not display map description popups when entering a new map
  creature_density=3,
  item_density=1,
  enchantment_chance=50,
  artifact_chance=10,
  default_event_cooldown=20,
  default_event_chance=50,
  player_species=true,
  player_classes=true,
  default_player="player_human", --This is the ID of the creature definition in possibleMonsters that will be used for the player character
  tilesize=32,
  default_spell_slots=1, --if not defined, defaults to infinite. See Creature:get_spell_slots() to customize formula
  default_inventory_space=20, --if not defined, defaults to infinite. See Creature:get_inventory_space() to customize formula
  default_equipment_slots={wielded=2,head=1,torso=1,hands=1,legs=1,feet=1,accessory=3,ammo=1},
  default_inventory_order={'usable','throwable','weapon','offhand','armorhead','armortorso','armorhands','armorlegs','armorfeet','accessory','ammo','other'},
  default_equipment_order={'wielded','head','torso','hands','legs','feet','accessory','ammo'},
  inventory_filters={{filter='usable'},{filter='throwable'},{filter='equippable',itemType="weapon",label="Weapons"},{filter='equippable',itemType="weapon",subType="ranged",label="Ranged Weapons"},{filter='equippable',label="All Equipment"},{itemType="other",label="Miscellaneous"}},
  default_starting_missions={ascend=0},
  stats_per_level={skillPoints=5,spellPoints=1,max_hp=5},
  stats_at_level={[5]={skillPoints=10}},
  stats_per_x_levels={[3]={spell_slots=1}},
  heal_on_level_up=true, --reset to max HP and MP on a level up
  spells_forgettable_by_default=true, --If true, spells can be "forgotten" from the spell screen, unless the spell's forgettable flag is explicitly set to false. If not set to true, spells can be forgotten if their forgettable flag is true
  can_pickup_adjacent_items=true, --Allows picking up items from adjacent tiles, not just the tile you're standing on
  display_item_levels=true,
  display_creature_levels=true,
  money_prefix = nil,
  money_suffix = nil,
  money_name = "coins",
  money_name_single = "coin",
  always_use_color_with_tiles=true
}