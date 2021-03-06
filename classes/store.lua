---@classmod Store
Store = Class{}

---Initiate a store from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the stores.
--@param data Table. The table of store data.
--@return self Store. The faction itself.
function Store:init(data)
	for key, val in pairs(data) do
		if type(val) ~= "function" then
      self[key] = data[key]
    end
	end
  self.baseType = "store"
  if data.nameGen then
    self.name = data:nameGen()
  end
  self.inventory = {}
  self:generate_items()
	return self
end

---Generates the store's inventory
function Store:generate_items()
  --Generate items from list:
  if self.sells_items then
    for _,info in pairs(self.sells_items) do
      local itemID = info.item
      local item = Item(itemID,info.passed_info,(info.amount or -1))
      if not item.amount then item.amount = (info.amount or -1) end --This is here because non-stackable items don't generate with amounts
      local makeNew = true
      if item.sortBy then
        local index = self:get_inventory_index(item)
        if index then
          self.inventory[index].item.amount = self.inventory[index].item.amount+item.amount
          makeNew = false
        end
      end
      if makeNew == true then
        local id = #self.inventory+1
        self.inventory[id] = {item=item,cost=info.cost,id=id}
      end
    end --end sells_items for
  end --end if self.sells_items
  --Generate dynamic inventory:
  if self.random_item_amount then
    local possibles = {}
    for id,item in pairs(possibleItems) do
      local done = false
      for _,tag in ipairs(self.sells_tags) do
        if item.value and not item.neverSpawn and (in_table(tag,item) or item.itemType == tag) then
          possibles[#possibles+1] = id
          done = true
          break
        end
      end
    end
    if count(possibles) > 0 then
      for i=1,self.random_item_amount,1 do
        local itemID = possibles[random(#possibles)]
        local item = Item(itemID)
        if not item.amount then item.amount = 1 end --This is here because non-stackable items don't generate with amounts
        local makeNew = true
        if item.sortBy then
          local index = self:get_inventory_index(item)
          if index then
            self.inventory[index].item.amount = self.inventory[index].item.amount+item.amount
            makeNew = false
          end
        end
        if makeNew == true then
          local id = #self.inventory+1
          self.inventory[id] = {item=item,cost=item.value*(self.markup or 1),id=id}
        end
      end --end random_item_amount for
    end --end possibles count if
  end --end random items if
end

---Gets a list of the items the store is selling
--@return Table. The list of items the store has in stock
function Store:get_inventory()
  return self.inventory
end

---Gets a list of the items that a creature can sell to a store
--@param creat Creature. The creature selling to the store. Optional, defaults to the player
--@return Table. The list of items the player can sell, each of which is another table in the format {item=Item,cost=Number}
function Store:get_buy_list(creat)
  creat = creat or player
  local buying = {}
  for id,item in ipairs(creat.inventory) do
    if self.buys_items and self.buys_items[item.id] then
      buying[#buying+1]={item=item,cost=self.buys_items[item.id]}
    elseif self.buys_tags and item.value then
      for _,tag in ipairs(self.buys_tags) do
        if item:has_tag(tag) or item.itemType == tag then
          buying[#buying+1]={item=item,cost=item.value}
        end
      end
    end
  end
  return buying
end

---Sell an item to the store
--@param item Item. The item being sold
--@param cost Number. The amount the store will pay per item.
--@param amt Number. The amount of the item being sold. Optional, defaults to 1.
--@param creat Creature. The creature selling to the store. Optional, defaults to the player.
function Store:creature_sells_item(item,cost,amt,creature)
  creature = creature or player
  local totalAmt = item.amount or 1
  if amt > totalAmt then amt = totalAmt end
  local totalCost = cost*amt
  local index = self:get_inventory_index(item)
  if index and self.inventory[index].item.amount ~= -1 then
    self.inventory[index].item.amount = self.inventory[index].item.amount+amt
  end
  creature:delete_item(item,amt)
  if self.currency_item then
    local creatureItem = creature:has_item(self.currency_item)
    if not creatureItem then
      creatureItem = Item(self.currency_item)
      creature:give_item(creatureItem)
      creatureItem.amount = totalCost
    else
      creatureItem.amount = creatureItem.amount+totalCost
    end
  else
    creature.money = creature.money+totalCost
  end
end

---Buy an item from the store
--@param item Item. The item being sold
--@param cost Number. The amount the store is charging per item.
--@param amt Number. The amount of the item being sold. Optional, defaults to 1.
--@param creat Creature. The creature selling to the store. Optional, defaults to the player.
--@return Boolean, Text/nil. True and nil if the buying was successful, False and a string if there's a reason the buying didn't go through.
function Store:creature_buys_item(item,cost,amt,creature)
  creature = creature or player
  local totalAmt = item.amount or 1
  if totalAmt == -1 then totalAmt = 9999999 end
  if amt > totalAmt then amt = totalAmt end
  local totalCost = cost*amt
  local canBuy = false
  local creatureItem = nil
  if self.currency_item then
    creatureItem = creature:has_item(self.currency_item)
    canBuy = (creatureItem.amount >= totalCost)
  else
    canBuy = (creature.money >= totalCost)
  end --end currency checks
  if canBuy then
    if amt == totalAmt then --if buying all the store has
      if item.stacks or totalAmt == 1 then
        creature:give_item(item)
        if not item.stacks then item.amount = nil end
      elseif not item.stacks then
        for i=1,amt,1 do
          local newItem = item:clone()
          newItem.amount = nil
          creature:give_item(newItem)
        end
      end
      local id = self:get_inventory_index(item)
      table.remove(self.inventory,id)
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature.money = creature.money-totalCost
      end
    elseif item.stacks then --if buying a stackable item
      local newItem = item:clone()
      if item.amount ~= -1 then item.amount = item.amount - amt end
      newItem.amount = amt
      creature:give_item(newItem)
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature.money = creature.money-totalCost
      end
    else --if buying a nonstackable item
      for i=1,amt,1 do
        local newItem = item:clone()
        newItem.amount = nil
        creature:give_item(newItem)
      end
      if item.amount ~= -1 then item.amount = item.amount - amt end
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature.money = creature.money-totalCost
      end
    end
    return true
  end
  return false,"You don't have enough to buy " .. item:get_name(true,amt) .. " ."
end

---Gets the index within the store's inventory of the item in question
--@param item Item. The item to seach for.
--@return Number. The index ID of the item.
function Store:get_inventory_index(item)
  for id,info in ipairs(self:get_inventory()) do
    if info.item.id == item.id and item.stacks == true and (not item.sortBy or (item[item.sortBy] == info.item[item.sortBy])) then
      return id
    end
  end
end

---Placeholder for the requires() code, which is run to determine if the player can enter the store or not.
--@return True.
function Store:requires()
  return true
end