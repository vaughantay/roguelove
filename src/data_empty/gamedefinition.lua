gamesettings = {
  --Basic game definition:
  name = "Insert Game Title Here", --Will be displayed on the main screen
  id="rogueloveuntitled", --Used internally
  author = "You",
  --version_text = "In Development", --Will be displayed at the bottom of the screen
  --copyright_text="Copyright 2023", --Will be displayed at the bottom of the screen
  --url="http://yourwebsite.com", --Will be displayed at the bottom of the screen. Clicking it opens the URL
  
  --Display:
  --always_use_color_with_tiles=true, --If true, always tint sprites with the entity's color setting. If false, display them as-is
  tilesize=32, --Change the image tile size. This isn't fully implemented and a lot of parts of the engine still will assume 32 for images
  
  --Game features:
  --xp=true, --If true, this game awards XP on kills and uses it for leveling
  --leveling=true, --If true, this game features leveling
  --events=true, --If true, events can be fired
  default_starting_branch="main", --What branch to start the player in
  --bosses=true, --If true, bosses will spawn when trying to go to a new level
  --player_tombstones=true, --If true, tombstones will be created on levels where players were previous killed listing their date and cause of death
  --heal_on_level_up=true, --reset to max HP and MP on a level up
  --display_creature_levels=true, --If true, creature levels will be displayed. Otherwise they won't (but can still be used behind the scenes)
  --cleanup_on_map_exit=true, --If true, run Map:cleanup() when you exit a map
  --cleanup_on_branch_exit=true -- If true, run Map:cleanup() when you exit a branch (redundant if cleanup_on_map_exit is already true)
  
  --Map and world generation:
  default_map_width=60,
  default_map_height=60,
  --no_map_descriptions=true, --If true, do not display map description popups when entering a new map
  creature_density=1,
  item_density=1,
  --enchantment_chance=50,
  --artifact_chance=10,
  --default_event_cooldown=20,
  --default_event_chance=50,
  
  --Player definition:
  --player_species=true, --If true, there is species selection on the main screen
  --player_classes=true, --If true, there is class selection on the main screen
  default_player="player_human", --This is the ID of the creature definition in possibleMonsters that will be used for the player character
  --default_starting_missions={ascend=0}, --Default missions players are given, in format missionID=missionStatus
  
  --Stats and skills:
  --default_stats={}, --The stats the game will give every creature at a 0 by default
  --default_skills={'melee','ranged'}, --The skills the game will give every creature at a 0 by default
  --skill_type_order={'attribute','skill'}, --Skill types will be sorted in this order when skils are grouped. Any skill types not in this list will be displayed in alphabetical order
  --stats_per_level={upgrade_points_attribute=1,spellPoints=1,upgrade_points_skill=3,max_hp=5},
  --stats_at_level={[5]={upgrade_points_attribute=3,upgrade_points_skill=10}},
  --stats_per_x_levels={[3]={spell_slots=1}},
  --skills_per_level={},
  --skills_at_level={[5]={}},
  --skills_per_x_levels={[3]={},
  --Default stats and skills to use in attacks. Can be overridden by creatures or items
  --default_melee_damage_stats={strength=1}, --will apply extra damage of the stat/skill * its value
  --default_melee_accuracy_stats={melee=1}, -- will apply % chance to hit of the stat/skill * its value
  --default_ranged_damage_stats={}, -- will apply extra damage of the stat/skill * its value
  --default_ranged_accuracy_stats={ranged=1}, -- will apply % chance to hit of the stat/skill * its value
  --default_dodge_stats={agility=5}, --will apply % chance to dodge of the stat/skill * its value
  
  --Inventory and equipment:
  --inventory=true,
  --crafting=true,
  --craft_anywhere=true,
  --auto_learn_possible_crafts=true, --If true, then when you have the ability and ingredients required for a recipe, it'll be shown on the crafting page even if you haven't explictly learned it yet. UNLESS the recipe has the no_auto_learn flag set
  --default_inventory_space=20, --if not defined, defaults to infinite. See Creature:get_inventory_space() to customize formula
  --default_equipment_slots={wielded=2,head=1,torso=1,hands=1,legs=1,feet=1,accessory=3,ammo=1},
  --default_inventory_order={'usable','throwable','weapon','offhand','armorhead','armortorso','armorhands','armorlegs','armorfeet','accessory','ammo','other'},
  --default_equipment_order={'wielded','head','torso','hands','legs','feet','accessory','ammo'},
  --inventory_filters={{filter='usable'},{filter='throwable'},{filter='equippable',itemType="weapon",label="Weapons"},{filter='equippable',itemType="weapon",subType="ranged",label="Ranged Weapons"},{filter='equippable',label="All Equipment"},{itemType="other",label="Miscellaneous"}},
  --can_pickup_adjacent_items=true, --Allows picking up items from adjacent tiles, not just the tile you're standing on
  --display_item_levels=true, --If true, the levels of items will be displayed. Otherwise they won't (but can still be used behind the scenes)
  --money_prefix = nil,
  --money_suffix = nil,
  money_name = "coins",
  money_name_single = "coin",

  --Spells:
  --default_spell_slots=0, --if not defined, defaults to infinite. See Creature:get_spell_slots() to customize formula
  --mp=true, --If true, uses MP
  --spells_forgettable_by_default=true, --If true, spells can be "forgotten" from the spell screen, unless the spell's forgettable flag is explicitly set to false. If not set to true, spells can be forgotten if their forgettable flag is true
  --spells_locked_by_default=true --If true, spells cannot be forgotten/memorized from the spellscreen at will
}