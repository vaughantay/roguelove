stores_static = {}

local healthstore = {
  name = "Healthe & Well-ness Apotheckarie",
  description = "A ramshackled booth, stacked with potions.",
  sells_items = {{item="healthpotionminor",cost=10,amount=5},{item="dart",cost=1},{item="dagger",amount=5,cost=1}}, --The items sold by the shop
  noBuy = false, --If the store buys things or not
  buys_items = {healthpotionminor=5},
  currency_item = nil --The item to use as currency, instead of money
}
stores_static['healthstore'] = healthstore