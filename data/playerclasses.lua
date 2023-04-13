playerClasses = {
  alchemist = {
    name="Alchemist",
    description="Mixes up the big booms.",
    recipe_tags={"alchemy"}, --These are the tags used to grant recipe knowledge to members of this class
    items={{item="weaponoil"},{item="alcahest",amount=5},{item="bomb",amount=5}}, --These items will be granted on game start
    recipe_tags={"alchemy"},
    resistances={fire=10,acid=10}, --These will be added the the characters' base resistances
    stat_modifiers={strength=2,melee=2,ranged=6,dodging=4,magic=3,max_mp=20}, --These values will be added to the characters' base stats
    money=100, --Amount of money the character starts with
    require_species_tags={"intelligent"} --This class will only be available if the player's species has tags or types listed in this table (or their species itself is listed in the require_species table)
    },
  demonhunter = {
    name="Demon Hunter",
    description="Fights those pesky demons.",
    favor={lightchurch=500,angels=100,demons=-100}, --List of favor scores the character starts with
    factions={"lightchurch"}, --List of factions the character begins as a member of
    spells={}, --These are spells the character will start with
    recipes={"healthpotionminor"}, --These are the specific recipes members of this class start with knowledge of
    items={{item="holywater",amount=2},{item="scroll",passed_info={'holy'},displayName = "3 Random Holy Scrolls",amount=3}}, --These items will be granted on game start
    equipment={{item="dagger",enchantment="blessed",enchantment_turns=5,displayName="Blessed Dagger"}}, --These items will be equipped on game start
    learns_spells={{spell="smite",level=2}}, --These spells will be automatically granted once a certain level is reached
    spell_purchases={{spell="demondamager",level=1,skill_point_cost=5},{spell="summonangel",level=1,spell_point_cost=2}, {spell="smite",level=1,spell_point_cost=2}}, --These spells will show up as options to learn (requiring spending points on them)
    spell_choices={}, --These spells will show up as options when you reach their level, and you can choose one of them
    weaknesses={}, --These will be added to the characters' base weaknesses
    resistances={holy=25}, --These will be added the the characters' base resistances
    stat_modifiers={strength=5,melee=5,ranged=5,dodging=2,magic=2,max_mp=10}, --These values will be added to the characters' base stats
    money=100, --Amount of money the character starts with
    starting_missions = {ascend=0,killdemons=0}, --What missions this class starts with, and what value to set the mission status to. Note: This will override default_starting_missions in gamedefinition.lua if it exists, so if you want the class to have both make sure to include the default starting missions in this table as well
    forbid_species_tags = {"undead","demon","unholy"} --This class will be unavailable if the player's species has a tag or type listed in this table
  },
  beefcake = {
    name="Beefcake",
    description="A super-tough warrior.",
    items={{item="healthpotionminor"},{item="dagger",amount=100},{item="breastplate"},{item="helmet"},{item="weaponpoison"}}, --These items will be granted on game start
    equipment={{item="greatsword"}}, --These items will be equipped on game start
    learns_spells={}, --These spells will be automatically granted once a certain level is reached
    spell_purchases={}, --These spells will show up as options to learn (requiring spending points on them)
    spell_choices={}, --These spells will show up as options when you reach their level, and you can choose one of them
    stat_modifiers={strength=10,melee=7,ranged=2,max_hp=25,armor=1}, --These values will be added to the characters' base stats
    stats_per_level={strength=1,max_hp=5}, --Stat increase per level
    stats_at_level={[5]={melee=5}}, --Stat increases given at a specific level
    money=100, --Amount of money the character starts with
    require_species={"player_human"} --This class will only be available if the player's species is listed in this table (or their species has tags or types in the require_species_tags table)
  },
  barbarian = {
    name="Barbarian",
    description="You too are not a bit tamed, you too are untranslatable.",
    equipment={{item="club"},{item="loincloth"}}, --These items will be equipped on game start
    spells={"yawp","passiverage"}, --These are spells the character will start with
    learns_spells={{spell="auraoffear",level=5}}, --These spells will be automatically granted once a certain level is reached
    favor={village=-1,barbariangod=100}, --List of favor scores the character starts with
    factions={"barbariangod"}, --List of factions the character begins as a member of
    stat_modifiers={strength=10,melee=10,armor=2}, --These values will be added to the characters' base stats
    stats_per_level={strength=2,max_hp=2}, --Stat increase per level
    extra_stats={fury={name="Fury",value=0,min=0,max=100,can_increase_with_points=true,increase_per_level=10,increase_per_point=10,bar_color={r=255,g=255,b=0,a=255}}},
    starting_branch="wilderness",
    placed = function(creature,map)
      for x=2,map.width,1 do
        for y=2,map.width,1 do
          local altar = map:tile_has_feature(x,y,'factionHQ')
          if altar and altar.faction.id == "barbariangod" then
            creature.x,creature.y=x,y
            return
          end
        end
      end
    end
  },
  demonologist = {
    name="Demonologist",
    description="Studies those pesky demons.",
    favor={lightchurch=-25}, --List of favor scores the character starts with
    spells={"demondamager"}, --These Fare spells the character will start with
    items={{item="holywater"},{item="bloodextractor"},{item="soul",amount=2},{item="demonblood"},{item="healthpotionminor",amount=2}}, --These items will be granted on game start
    equipment={{item="dagger",enchantment="sharpened",enchantment_turns=5,displayName="Sharpened Dagger"}}, --These items will be equipped on game start
    learns_spells={}, --These spells will be automatically granted once a certain level is reached
    spell_purchases={}, --These spells will show up as options to learn (requiring spending points on them)
    spell_choices={}, --These spells will show up as options when you reach their level, and you can choose one of them
    weaknesses={holy=10}, --These will be added to the characters' base weaknesses
    resistances={fire=10,unholy=10}, --These will be added the the characters' base resistances
    stat_modifiers={strength=5,melee=5,ranged=5,dodging=7,magic=5,max_mp=15}, --These values will be added to the characters' base stats
    money=100 --Amount of money the character starts with
  },
  wimp = {
    name="Total Wimp",
    description="A scrawny nerd.",
    items={{item="healthpotionminor",amount=5},{item="scroll",amount=3,displayName="Random Scrolls",unidentified=true},{item="scroll",passed_info="blink",displayName = "Scroll of Blink"},{item="scroll",passed_info="homecoming",displayName = "Scroll of Homecoming"},{item="crossbow"},{item="bolt",amount=25},{item="weaponpoison",amount=2},{item="painwand"},{item="dart",amount=25}}, --These items will be granted on game start
    stat_modifiers={strength=1,melee=1,ranged=5,magic=5,max_hp=-25,max_mp=5}, --These values will be added to the characters' base stats
    stats_per_level={skillPoints=1,spellPoints=1},
    stats_at_level={[3]={spell_slots=1},[5]={spell_slots=1},[10]={spell_slots=1}},
    spells={"scrawny","blast"}, --These are spells the character will start with
    money=100, --Amount of money the character starts with
    forbid_species = {"player_tiger"}
  },
  pyromancer = {
    name="Pyromancer",
    description="A fire-obsessed wizard.",
    resistances={fire=10}, --These will be added the the characters' base resistances
    favor={lightchurch=-10}, --List of favor scores the character starts with
    items={}, --These items will be granted on game start
    spells={"smallfireball",'fireaura'},
    --spells={"ignite","explodingfireball","flameline","flameshield","flameimmunity","firebrand"}, --These are spells the character will start with
    learns_spells={}, --These spells will be automatically granted once a certain level is reached
    spell_purchases={}, --These spells will show up as options to learn (requiring spending points on them)
    spell_choices={}, --These spells will show up as options when you reach their level, and you can choose one of them
    stat_modifiers={strength=3,melee=3,ranged=5,magic=10,max_mp=25}, --These values will be added to the characters' base stats
    money=0, --Amount of money the character starts with
    forbid_species = {"player_vampire"}, --This class will be unavailable if the player's species is listed in this table
  },
  necromancer = {
    name="Necromancer",
    description="A death-obsessed wizard.",
    resistances={unholy=10}, --These will be added the the characters' base resistances
    favor={lightchurch=-100}, --List of favor scores the character starts with
    items={{item="spellbook",passed_info={'necromancy'},displayName = "Necromancy Spellbook"}}, --These items will be granted on game start
    spells={'lifedrain'}, --These are spells the character will start with
    learns_spells={}, --These spells will be automatically granted once a certain level is reached
    spell_purchases={}, --These spells will show up as options to learn (requiring spending points on them)
    spell_choices={}, --These spells will show up as options when you reach their level, and you can choose one of them
    stat_modifiers={strength=2,melee=2,ranged=3,magic=15,max_mp=30}, --These values will be added to the characters' base stats
    money=0, --Amount of money the character starts with
  }
}