possibleFactions = {}

possibleFactions['lightchurch'] = {
  name = "Church of Sweetness and Light", --Name of the faction
  description = "A powerful organization dedicated to eradicating evil. Luckily for them, but unluckily for everyone else, they also get to determine what qualifies as evil.", --Description of the faction
  map_description = "A powerful organization dedicated to eradicating evil.", --Description that will show on the Feature tile used to access the faction
  tags={"organized","holy"}, --Tags used to describe the faction, for deciding what maps to put them in
  friendly_types = {"angel"}, --Creature types this faction will not attack
  enemy_types = {"demon","undead"}, --Creature types this faction will always attack
  friendly_factions = {"grievers","angels"}, --Factions whose members this faction will not attack
  enemy_factions = {"chaos","demons"}, --Factions whose members this faction will always attack
  kill_favor_types = {demon=2,undead=1,angel=-10}, --Favor granted for killing certain creature types
  kill_favor_factions = {lightchurch=-5}, --Favor granted for killing members of certain factions
  kill_reputation_types = {demon=2,undead=1,angel=-10}, --Reputation granted for killing certain creature types
  kill_reputation_factions = {lightchurch=-5}, --Reputation granted for killing members of certain factions
  attack_all_neutral = false, --Whether or not this faction attacks non-player characters who aren't explicitly friends. By default, they'll attack only enemy NPCs
  attack_own_faction = false, --Whether or not members of this faction will attack each other
  always_attack_player = false, --If set to true, this faction will always be hostile to the player regardless of faction membership or reputaton
  attack_enemy_player_only = true, --If set to true, this faction is only hostile to the player if they're explicitly considered an enemy. If false, they'll be hostile to the player if they're not a friend
  hostile_threshold = -50, --The amount of reputation below which the player is treated as an enemy. If left blank, the player will always be considered an enemy unless something else marks them as a friend (like faction membership or reputation meeting the friendly_threshold)
  friendly_threshold = 100, --The amount of reputatin above which the player is treated as a friend. If left blank, this faction will never consider the player a friend based on reputation alone (they'll still be treated as a friend due to faction membership, unless always_attack_player is true)
  enter_threshold = 0, --The amount of reputation below which you're not allowed to do business with the faction
  join_threshold = 100, --The amount of reputation you need to be eligible to join the faction
  banish_threshold=0, --If your reputation falls below this, you'll be kicked out of the faction
  faction_cost_modifiers={lightchurch=-10,grievers=-5}, --table of percentages by which monetary (not favor!) costs of goods and services are increased/decreased based on faction membership. Does not stack with multiple factions; the highest absolute value is used. Does stack with favor cost modifier.
  reputation_cost_modifiers={[0]=10,[50]=0,[100]=-5,[150]=-10,[200]=-15}, --table of percentages by which monetary (not favor!) costs of goods and services are increased/decreased based on reputation with this faction. Stacks with faction cost modifier. The highest absolute value is used.
  sells_items = {{item="holywater",favorCost=5,moneyCost=50,amount=10,restock_amount=2,restock_to=5,reputation_requirement=10}, {item="dagger",favorCost=250,amount=1,members_only=true,artifact=true},{item="dagger",favorCost=10,amount=5,enchantments={"blessed"}},{item="scroll",favorCost=1,moneyCost=5,amount=5,restock_amount=1}}, --pre-defined items that this faction sells to friendly players
  sells_tags = {"holy"}, --Tags for randomly-generated items that will be sold by the shop
  passedTags = {"holy"}, --These tags will be given priority for enchantments applied to items, and passed to items to do with what they will (ex: scrolls, to put preference on spells with these tags)
  sell_markup=100, --Randomly-selected items' values will have this % added to determine how much this shop will sell the items for
  item_type_buy_markups={unholy=100},
  random_item_amount=5, --How many random items to fill the shop with
  random_item_restock_amount=1, --How many random items to restock each restock cycle
  random_item_restock_to=3, --Don't restock random items if the random item count is above this amount
  buys_items = {demonblood={favorCost=2}}, --pre-defined items that this faction buys in return for favor or money
  buys_tags = {"magic","holy","unholy","demon"}, --Tags for non-predefined items that will be bought by the faction
  money_per_favor = 10, --When buying/selling non-predefined items, divide the item's value by this number to get the favor paid (rounded down for buying, up for selling), defaults to 10
  only_buys_favor = true, --When buying non-predefined items, don't pay money for them, just favor
  only_sells_favor = true, --When selling non-predefined items, don't charge money for them, just favor
  teaches_spells = {{spell="demondamager",favorCost=100,moneyCost = 100}, {spell="summonangel",favorCost=100,members_only=true}}, --spells that this faction teaches to friendly players
  teaches_spell_tags = {'holy'},
  teaches_spell_types = {'holy'},
  recruitable_creatures = {{amount=2,creatures={demonhunter=1},moneyCost=50,favorCost=25,reputationCost=105,description="Hire a faithful demon hunter to accompany you on your crusade against evil.",restock_amount=1,restock_to=2,reputation_requirement=10},{creatures={demonhunter=3,cherub=1},moneyCost=100,favorCost=50,reputationCost=25,description="Hire a group of faithful demon hunters to accompany you on your crusade against evil.",members_only=true}},
  spell_money_cost=100,
  spell_favor_cost=100,
  grants_skills={divinity=1},
  offers_services = {{service="healing_church",reputation_requirement=10},{service="blessing",favorCost=10,moneyCost=10,members_only=true},{service="exorcism"}}, --services that this faction offers to friendly players
  offers_missions = {{mission='killdemons'},{mission='killundead'},{mission='findtreasure',members_only=true}}, --missions that this faction offers to friendly players
  possible_inventory = {{item="scroll",chance=100}}, --items that all members of this faction might have in their inventory
  grants_recipe_tags={"holy"},
  teaches_skill_tags={'holy'},
  skill_favor_cost=50,
  hidden = false, --If set to true, this faction won't appear on the faction list page
  never_join = false, --If set to true, this faction cannot be joined
  event_cooldown=5,
  join_requirements = function(self,creature)
    if creature:is_type('demon') or creature:is_type('undead') then
      return false,"You are an unholy creature."
    end
  end,
  generateName = function(self)
    local w1 = namegen:get_from_list('goodConcepts')
    local w2 = w1
    while (w2 == w1) do
      w2 = namegen:get_from_list('goodConcepts')
    end
    return ucfirst(namegen:get_from_list('religiousGroups')) .. " of " .. ucfirst(w1) .. " and " .. ucfirst(w2)
  end
}

possibleFactions['grievers'] = {
  name = "Grievers", --Name of the faction
  description = "A powerful organization dedicated to eradicating the undead. Pretty chill towards anyone who's not undead.", --Description of the faction
  map_description = "A powerful organization dedicated to eradicating the undead.", --Description that will show on the Feature tile used to access the faction
  tags={"organized","death"}, --Tags used to describe the faction, for deciding what maps to put them in
  enemy_types = {"undead"}, --Creature types this faction will always attack
  friendly_factions = {"lightchurch"}, --Factions whose members this faction will not attack
  kill_favor_types = {undead=2}, --Favor granted for killing certain creature types
  kill_favor_factions = {grievers=-5}, --Favor granted for killing members of certain factions
  kill_reputation_types = {undead=2}, --Reputation granted for killing certain creature types
  kill_reputation_factions = {grievers=-5}, --Reputation granted for killing members of certain factions
  attack_all_neutral = false, --Whether or not this faction everyone who isn't explicitly a friend. By default, they'll attack only enemies
  attack_own_faction = false, --Whether or not members of this faction will attack each other
  always_attack_player = false, --If set to true, this faction will always be hostile to the player regardless of faction membership or reputation
  attack_enemy_player_only = true, --If set to true, this faction is only hostile to the player if they're explicitly considered an enemy. If false, they'll be hostile to the player if they're not a friend
  hostile_threshold = 0, --The amount of reputation below which the player is treated as an enemy. If left blank, the player will always be considered an enemy unless something else marks them as a friend (like faction membership or reputation meeting the friendly_threshold)
  friendly_threshold = 10, --The amount of reputation above which the player is treated as a friend. If left blank, this faction will never consider the player a friend based on reputation alone (they'll still be treated as a friend due to faction membership, unless always_attack_player is true)
  enter_threshold = 0, --The amount of reputation below which you're not allowed to do business with the faction
  join_threshold = 25, --The amount of reputation you need to be eligible to join the faction
  sells_items = {{item="holywater",favorCost=5,moneyCost=50}}, --items that this faction sells to friendly players
}

possibleFactions['barbariangod'] = {
  name = "God of Destruction", --Name of the faction
  description = "The God of Death and Destruction loves killing, and rewards their followers with incredible power.", --Description of the faction
  tags={"wild"}, --Tags that will be used to determine if this faction can spawn on a given map
  map_name = "Altar to the God of Destruction", --The name of the feature used to interact with this faction
  map_description = "A bloodstained altar.", --Description that will show on the Feature tile used to access the faction
  enter_text = "Bow to", --The text that will display for interacting with this faction
  multiple_locations = true, --If set to true, this faction can spawn in multiple locations. Otherwise, will only spawn on one map per game
  kill_favor = 1, --Gain/lose this much favor on any kill
  kill_reputation = 1, --Gain/lose this much reputation on any kill
  favor_decay_turns=10, --Favor with this faction will decrease by 1 after this many turns
  favor_decay=1, --The amount of favor to lose when favor_decay-turns ticks around. Optional, defaults to 1
  reputation_decay_turns=10, --Reputation with this faction will decrease by 1 after this many turns
  reputation_decay=1, --The amount of reputation to lose when reputation_decay-turns ticks around. Optional, defaults to 1
  reputation_decay_floor=-100, --The lowest value to which favor will decay over time. Optional, if blank there is no floor
  members_only_favor=true, --If this is true, you can only gain/lose favor with this faction if you're a member
  members_only_reputation=true, --If this is true, you can only gain/lose reputation with this faction if you're a member
  attack_all_neutral = true, --Whether or not this faction attacks non-player characters who aren't explicitly friends. By default, they'll attack only enemy NPCs
  attack_own_faction = true, --Whether or not members of this faction will attack each other
  always_attack_player = true, --If set to true, this faction will always be hostile to the player regardless of faction membership or reputation
  enter_threshold = -1000, --The amount of reputation below which you're not allowed to do business with the faction
  join_threshold = -1000, --The amount of reputation you need to be eligible to join the faction
  money_per_favor = 20, --When buying non-predefined items, divide the item's value by this number to get the favor paid (rounded down)
  only_pays_favor = true, --When buying non-predefined items, don't pay money for them, just favor
  teaches_spells = {}, --spells that this faction teaches to friendly players
  offers_services = {}, --services that this faction offers to friendly players
  offers_missions = {{mission="killtownies"}}, --missions that this faction offers to friendly players
  generateName = function(self)
    local name = namegen:generate_guttural_name()
    self.map_name = "Altar to " .. name .. ", God of Destruction"
    self.god_name = name
    return name .. ", God of Destruction"
  end,
  placed = function(self,HQ,map)
    for x=HQ.x-1,HQ.x+1,1 do
      for y=HQ.y-1,HQ.y+1,1 do
        map[x][y] = "."
        if x ~= HQ.x or y ~= HQ.y then
          local blood = Feature('chunk')
          map:add_feature(blood,x,y)
        end
      end
    end
  end
}

possibleFactions['demons'] = {
  name = "The Hosts of Hell",
  description = "While Hell is politically fragmented, demons generally refrain from attacking each other if other enemies are present.",
  enemy_factions = {"angels"}, --Factions whose members this faction will always attack
  kill_reputation_types = {angel=2,demon=-5}, --reputation granted for killing certain creature types
  no_hq = true,
  never_join = true
}

possibleFactions['angels'] = {
  name = "The Heavenly Horde",
  description = "The angelic hivemind.",
  friendly_factions = {"lightchurch"}, --Factions this faction will not attack
  enemy_factions = {"demons","chaos"}, --Factions whose members this faction will always attack
  enemy_types = {"demon","undead"}, --Creature types this faction will always attack
  kill_reputation_types = {demon=5,angel=-10}, --reputation granted for killing certain creature types
  no_hq = true,
  never_join = true
}

possibleFactions['village'] = {
  name = "Villagers",
  description = "The peaceful villagers.",
  hidden = true,
  no_hq = true,
  never_join = true,
  attack_enemy_player_only = true,
  hostile_threshold = -2,
  friendly_threshold = -1,
  kill_reputation_factions = {village=-10},
  faction_cost_modifiers={lightchurch=-5,grievers=-5},
  reputation_cost_modifiers={[-25]=20,[-10]=10,[0]=0},
  enter_threshold=-25
}

possibleFactions['chaos'] = {
  name = "Chaos",
  description = "Not really a true faction. All creatures assigned to this faction will attack everyone on sight.",
  attack_all_neutral = true,
  attack_own_faction = true,
  always_attack_player = true,
  hidden = true,
  no_hq = true,
  never_join = true
}

possibleFactions['passive'] = {
  name = "Passive",
  description = "Not really a true faction. All creatures assigned to this faction will only attack if attacked first.",
  attack_enemy_player_only = true,
  hostile_threshold = -1000,
  friendly_threshold = -1000,
  hidden = true,
  no_hq = true,
  never_join = true
}