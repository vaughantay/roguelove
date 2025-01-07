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
  teaches_spell_types={'healing'},
  spell_cost=100,
  tags={"organized"}, --Tags to be used to determine if a store can spawn in a map
  multiple_locations=true --If this is set to true, this store can spawn in multiple locations, each with separate inventory. If not set, the store can only spawn once per game
}
function healthstore:generate_items()
end
function healthstore:restock()
end
function healthstore:enter_requires(creature)
  if creature:is_type('undead') then
    return false,"The undead are not welcome in this place of healing."
  end
end
possibleStores['healthstore'] = healthstore

local weaponstore = {
  name = "Weapons R Us", --Name of the store
  description = "A ramshackle booth, filled with dangerous implements. The proprietor beams at you, and gestures towards his wares with a hand missing several fingers.", --Description of the store
  map_description = "A ramshackle booth, filled with dangerous implements.", --Description that will show on the Feature tile used to enter the store
  tags={"organized"}, --Tags to be used to determine if a store can spawn in a map
  sells_types = {"weapon"},
  buys_types = {"weapon"},
  sell_markup=100, --Randomly-selected items' values will be modified by this % to determine how much this shop will sell the items for
  buy_markup=-50, --Items' values will be modified by this % to determine how much the store will pay for them
  random_item_amount=10, --How many random items to fill the shop with
  random_item_restock_amount=1, --How many random items to restock each restock cycle
  random_item_restock_to=5, --Only restock random items to this amount
  delete_random_items_on_restock=true, --If true, delete all random items when the store is restocked
  min_artifacts=1, --TODO: Make this do something
  artifact_chance=10 --% chance that an item spawned here will be an artifact
}
possibleStores['weaponstore'] = weaponstore

local alchemystore = {
  name = "Alchemistry Supply Co.", --Name of the store
  description = "A ramshackle booth, with shelves stuffed full of all sorts of bizzare ingredients in bottles, jars, vials, phials, flasks, decanters, carboys, jugs, carafes, and other various containers.", --Description of the store
  map_description = "A ramshackle booth stuffed with bizzare ingredients.", --Description that will show on the Feature tile used to enter the store
  tags={"organized"}, --Tags to be used to determine if a store can spawn in a map
  sells_items = {{item="alcahest",cost=10},{item="bloodextractor",cost=250,amount=1}},
  sells_tags = {"ingredient","alchemy"}, --Tags for items that will be sold by the shop
  buys_tags = {"ingredient","alchemy","magic","bodypart"},
  sell_markup=100, --Randomly-selected items' values have this % added to determine how much this shop will sell the items for
  random_item_amount=10, --How many random items to fill the shop with
  random_item_restock_amount=5,
  random_item_restock_to=5, --Only restock random items to this amount
  teaches_skills={{skill="alchemy",cost=50,max=3}},
  teaches_skill_tags={'healing'},
  skill_cost=100
}
possibleStores['alchemystore'] = alchemystore