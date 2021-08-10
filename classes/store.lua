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
  local tags = self.passedTags
  if self.sells_items then
    for _,info in pairs(self.sells_items) do
      local itemID = info.item
      local item = Item(itemID,(info.passed_info or (possibleItems[itemID].acceptTags and tags) or nil),(info.amount or -1)) --If an amount is not defined, set it to -1, which fills in for infinite
      if info.artifact then
        mapgen:make_artifact(item,tags)
      elseif info.enchantments then
        for _,eid in ipairs(info.enchantments) do
          item:apply_enchantment(eid,-1)
        end
      end
      local makeNew = true
      local index = self:get_inventory_index(item)
      if index then
        self.inventory[index].item.amount = self.inventory[index].item.amount+item.amount
        makeNew = false
      end
      if makeNew == true then
        local id = #self.inventory+1
        self.inventory[id] = {item=item,cost=info.cost,id=id}
      end
    end --end sells_items for
  end --end if self.sells_items
  --Generate dynamic inventory:
  if self.random_item_amount then
    local possibles = self:get_possible_random_items()
    if count(possibles) > 0 then
      for i=1,self.random_item_amount,1 do
        self:generate_random_item(possibles)
      end --end random_item_amount for
    end --end possibles count if
  end --end random items if
end

---Restocks the store. Default behavior: Restock all defined items up to their original amount, unless restock_amount or restock_to is set.
function Store:restock()
  --First, do defined items
  if self.sells_items then
    for _,info in pairs(self.sells_items) do
      if info.amount and info.amount ~= -1 then --don't restock infinite-stock items
        local itemID = info.item
        local item = Item(itemID,info.passed_info)
        local currAmt = self:get_count(item) or 0
        local restock_to = (info.restock_to or info.amount)
        if currAmt < (info.restock_to or info.amount) and currAmt ~= -1 then
          local final_restock = math.min(info.restock_amount or restock_to,restock_to-currAmt)
          local index = self:get_inventory_index(item)
          if index then
            self.inventory[index].item.amount = self.inventory[index].item.amount+final_restock
          else
            local id = #self.inventory+1
            item.amount = final_restock
            self.inventory[id] = {item=item,cost=info.cost,id=id}
          end
        end --end currAmt < restock to amount
      end --end if amount
    end --end sells_items for
  end --end if self.sells_items
  --Restock randomly generated items:
  if self.random_item_amount then
    local random_inv = 0
    local restock_to = (self.random_item_restock_to or self.random_item_amount)
    for _,inv in ipairs(self.inventory) do
      if inv.randomly_generated then
        random_inv = random_inv + (inv.item.amount or 1)
      end
    end --end random for
    local final_restock = math.min(self.random_item_restock_amount or restock_to,restock_to-random_inv)
    if final_restock > 0 then
      local possibles = self:get_possible_random_items()
      if count(possibles) > 0 then
        for i=1,final_restock,1 do
          self:generate_random_item(possibles)
        end --end random_item_amount for
      end --end possibles count if
    end
  end --end if random_item_amount
end

---Gets a list of the items the store is selling
--@return Table. The list of items the store has in stock
function Store:get_inventory()
  return self.inventory
end

---Gets the numbers of items this store has in its current inventory that matches a passed item
--@param item Item. The item to count.
--@return Number. The number of items
function Store:get_count(item)
  local iCount = 0
  for id,info in ipairs(self:get_inventory()) do
    if item:matches(info.item) then
      if info.amount == -1 then
        return -1
      end
      iCount = iCount + (info.item.amount or 1)
    end
  end
  return iCount
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
          buying[#buying+1]={item=item,cost=item:get_value()}
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
      elseif not item.stacks then
        for i=1,amt,1 do
          local newItem = item:clone()
          newItem.amount = 1
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
        newItem.amount=1
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
    if item:matches(info.item) then
      return id
    end
  end
end

---Get all possible random items the store can stock
--@return Table. A list of the item IDs
function Store:get_possible_random_items()
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
  return possibles
end

---Generate a random item from the store's possible random items list
--@param list Table. A list of item IDs to pull from. Optional, defaults to the list from get_possible_random_items()
function Store:generate_random_item(list)
  local possibles = list or self:get_possible_random_items()
  local itemID = possibles[random(#possibles)]
  local tags = self.passedTags
  local item = Item(itemID,(possibleItems[itemID].acceptTags and tags or nil))
  if random(1,100) <= (self.artifact_chance or gamesettings.artifact_chance) then
    mapgen:make_artifact(item,tags)
  elseif random(1,100) <= gamesettings.enchantment_chance then
    local possibles = item:get_possible_enchantments(true)
    if count(possibles) > 0 then
      local eid = get_random_element(possibles)
      item:apply_enchantment(eid,-1)
    end
  end
  if not item.amount then item.amount = 1 end --This is here because non-stackable items don't generate with amounts
  local makeNew = true
  local index = self:get_inventory_index(item)
  if index then
    self.inventory[index].item.amount = self.inventory[index].item.amount+item.amount
    makeNew = false
  end
  if makeNew == true then
    local id = #self.inventory+1
    self.inventory[id] = {item=item,cost=item:get_value()*(self.markup or 1),id=id,randomly_generated=true}
  end
end

---Placeholder for the requires() code, which is run to determine if the player can enter the store or not.
--@return True.
function Store:requires()
  return true
end