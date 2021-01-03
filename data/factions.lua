possibleFactions = {}

possibleFactions['lightchurch'] = {
  name = "Church of Sweetness and Light", --Name of the faction
  description = "A powerful organization dedicated to eradicating evil. Luckily for them, but unluckily for everyone else, they also get to determine what qualifies as evil.", --Description of the faction
  map_description = "A powerful organization dedicated to eradicating evil.", --Description that will show on the Feature tile used to access the faction
  friendlyTypes = {"angel"}, --Creature types this faction will not attack
  enemyTypes = {"demon","undead"}, --Creature types this faction will always attack
  friendlyFactions = {"grievers"}, --Factions whose members this faction will not attack
  enemyFactions = {"chaos"}, --Factions whose members this faction will always attack
  killFavor_types = {demon=2,undead=1,angel=-5}, --Favor granted for killing certain creature types
  killFavor_factions = {lightchurch=-5}, --Favor granted for killing members of certain factions
  attackAllNeutral = false, --Whether or not this faction everyone who isn't explicitly a friend. By default, they'll attack only enemies
  attackOwnFaction = false, --Whether or not members of this faction will attack each other
  alwaysAttackPlayer = false, --If set to true, this faction will always be hostile to the player regardless of faction membership or favor
  attackEnemyPlayerOnly = true, --If set to true, this faction is only hostile to the player if they're explicitly considered an enemy. If false, they'll be hostile to the player if they're not a friend
  hostileThreshold = -50, --The amount of favor below which the player is treated as an enemy. If left blank, the player will always be considered an enemy unless something else marks them as a friend (like faction membership or favor meeting the friendlyThreshold)
  friendlyThreshold = 100, --The amount of favor above which the player is treated as a friend. If left blank, this faction will never consider the player a friend based on favor alone (they'll still be treated as a friend due to faction membership, unless alwaysAttackPlayer is true)
  enterThreshold = 0, --The amount of favor below which you're not allowed to do business with the faction
  joinThreshold = 100, --The amount of favor you need to be eligible to join the faction
  sells_items = {{item="holywater",favorCost=5,moneyCost=50}, {item="dagger",favorCost=250,amount=1,membersOnly=true}}, --pre-defined items that this faction sells to friendly players
  markup=2, --Non-predefined items' values will be multiplied by this number to determine how much this shop will sell the items for
  buys_items = {demonblood={favorCost=2}}, --pre-defined items that this faction buys in return for favor or money
  buys_tags = {"magic","holy","unholy","demon"}, --Tags for non-predefined items that will be bought by the faction
  moneyPerFavor = 10, --When buying non-predefined items, divide the item's value by this number to get the favor paid (rounded down)
  onlyPaysFavor = true, --When buying non-predefined items, don't pay money for them, just favor
  teaches_spells = {{spell="demondamager",favorCost=100,moneyCost = 100}, {spell="summonangel",favorCost=100,membersOnly=true}}, --spells that this faction teaches to friendly players
  offers_services = {"healing","blessing"}, --services that this faction offers to friendly players
  offers_missions = {}, --missions that this faction offers to friendly players
  possible_inventory = {{item="scroll",chance=100}}, --items that all members of this faction might drop
  hidden = false, --If set to true, this faction won't appear on the faction list page
  neverJoin = false, --If set to true, this faction cannot be joined
  join_requirements = function(self,creature)
    if creature:is_type('demon') or creature:is_type('undead') then
      return false,"You are an unholy creature."
    end
  end
}

possibleFactions['grievers'] = {
  name = "The Grievers", --Name of the faction
  description = "A powerful organization dedicated to eradicating the undead. Pretty chill towards anyone who's not undead.", --Description of the faction
  map_description = "A powerful organization dedicated to eradicating the undead.", --Description that will show on the Feature tile used to access the faction
  enemyTypes = {"undead"}, --Creature types this faction will always attack
  friendlyFactions = {"lightchurch"}, --Factions whose members this faction will not attack
  killFavor_types = {undead=2}, --Favor granted for killing certain creature types
  killFavor_factions = {grievers=-5}, --Favor granted for killing members of certain factions
  attackAllNeutral = false, --Whether or not this faction everyone who isn't explicitly a friend. By default, they'll attack only enemies
  attackOwnFaction = false, --Whether or not members of this faction will attack each other
  alwaysAttackPlayer = false, --If set to true, this faction will always be hostile to the player regardless of faction membership or favor
  attackEnemyPlayerOnly = true, --If set to true, this faction is only hostile to the player if they're explicitly considered an enemy. If false, they'll be hostile to the player if they're not a friend
  hostileThreshold = 0, --The amount of favor below which the player is treated as an enemy. If left blank, the player will always be considered an enemy unless something else marks them as a friend (like faction membership or favor meeting the friendlyThreshold)
  friendlyThreshold = 10, --The amount of favor above which the player is treated as a friend. If left blank, this faction will never consider the player a friend based on favor alone (they'll still be treated as a friend due to faction membership, unless alwaysAttackPlayer is true)
  enterThreshold = 0, --The amount of favor below which you're not allowed to do business with the faction
  joinThreshold = 25, --The amount of favor you need to be eligible to join the faction
  sells_items = {{item="holywater",favorCost=5,moneyCost=50}}, --items that this faction sells to friendly players
}

possibleFactions['chaos'] = {
  name = "Chaos",
  description = "Not really a true faction. All creatures assigned to this faction will attack everyone on sight.",
  attackAllNeutral = true,
  attackOwnFaction = true,
  alwaysAttackPlayer = true,
  hidden = true,
  noHQ = true,
  neverJoin = true
}

possibleFactions['village'] = {
  name = "The Village",
  description = "The peaceful villagers.",
  hidden = true,
  noHQ = true,
  neverJoin = true,
  attackEnemyPlayerOnly = true,
  hostileThreshold = 0,
  friendlyThreshold = -1,
  killFavor_factions = {village=-1}
}