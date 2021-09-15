possibleStores = {}

local healthstore = {
  name = "Healthe & Well-ness Apotheckarie", --Name of the store
  description = "A ramshackle booth, stacked with potions. The proprietor beams at you, a strong medicinal stench wafting off of him.", --Description of the store
  map_description = "A ramshackle booth, stacked with potions.", --Description of the store that will show on the Feature tile used to enter the store
  sells_items = {{item="healthpotionminor",cost=10,amount=5,restock_to=5},{item="dart",cost=1},{item="dagger",amount=5,cost=1},{item="scroll",amount=10,cost=1,passed_info="blink"},{item="scroll",amount=10,cost=1,delete_on_restock=true}}, --The items sold by the shop
  noBuy = false, --If the store buys things or not
  buys_items = {healthpotionminor=5,scroll=1},
  buys_tags = {"magic","healing"}, --Tags for non-predefined items that will be bought by the shop
  offers_services = {{service="healing"}}, --Services that this store offers
  teaches_spells = {{spell="heal_other",cost = 100}}, --spells that this store teaches
  tags={"organized"}, --Tags to be used to determine if a store can spawn in a map
  currency_item = nil, --The item to use as currency, instead of money
  multiple_locations=true --If this is set to true, this store can spawn in multiple locations. The locations will share inventory. If not set, the store can only spawn once per game
}
function healthstore:generate_items()
end
function healthstore:restock()
end
possibleStores['healthstore'] = healthstore

local weaponstore = {
  name = "Weapons R Us", --Name of the store
  description = "A ramshackle booth, filled with dangerous implements. The proprietor beams at you, and gestures towards his wares with a hand missing several fingers.", --Description of the store
  map_description = "A ramshackle booth, filled with dangerous implements.", --Description that will show on the Feature tile used to enter the store
  sells_tags = {"weapon"}, --Tags for items that will be sold by the shop
  buys_tags = {"weapon"},
  markup=2, --Randomly-selected items' values will be multiplied by this number to determine how much this shop will sell the items for
  random_item_amount=10, --How many random items to fill the shop with
  random_item_restock_amount=1, --How many random items to restock each restock cycle
  random_item_restock_to=5, --Only restock random items to this amount
  delete_random_items_on_restock=true, --If true, delete all random items when the store is restocked
  min_artifacts=1, --TODO: Make this do something
  artifact_chance=10 --% chance that an item spawned here will be an artifact
}
possibleStores['weaponstore'] = weaponstore