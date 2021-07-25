stores_static = {}

local healthstore = {
  name = "Healthe & Well-ness Apotheckarie", --Name of the store
  description = "A ramshackle booth, stacked with potions. The proprietor beams at you, a strong medicinal stench wafting off of him.", --Description of the store
  map_description = "A ramshackle booth, stacked with potions.", --Description of the store that will show on the Feature tile used to enter the store
  sells_items = {{item="healthpotionminor",cost=10,amount=5},{item="dart",cost=1},{item="dagger",amount=5,cost=1},{item="scroll",amount=10,cost=1,passed_info="blink"},{item="scroll",amount=10,cost=1}}, --The items sold by the shop
  noBuy = false, --If the store buys things or not
  buys_items = {healthpotionminor=5,scroll=1},
  buys_tags = {"magic"}, --Tags for non-predefined items that will be bought by the shop
  tags={"organized"}, --Tags to be used to determine if a store can spawn in a map
  currency_item = nil, --The item to use as currency, instead of money
  multiple_locations=true --If this is set to true, this store can spawn in multiple locations. The locations will share inventory. If not set, the store can only spawn once per game
}
stores_static['healthstore'] = healthstore

local weaponstore = {
  name = "Weapons R Us", --Name of the store
  description = "A ramshackle booth, filled with dangerous implements. The proprietor beams at you, and gestures towards his wares with a hand missing several fingers.", --Description of the store
  map_description = "A ramshackle booth, filled with dangerous implements.", --Description that will show on the Feature tile used to enter the store
  sells_tags = {"weapon"}, --Tags for items that will be sold by the shop
  buys_tags = {"weapon"},
  markup=2, --Randomly-selected items' values will be multiplied by this number to determine how much this shop will sell the items for
  random_item_amount=10, --How many random items to fill the shop with
  min_artifacts=1,
  artifact_chance=1
}
stores_static['weaponstore'] = weaponstore