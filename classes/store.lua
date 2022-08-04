---@classmod Store
Store = Class{}

---Initiate a store from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the stores.
--@param data Table. The table of store data.
--@return self Store. The faction itself.
function Store:init(store_id)
  local data = possibleStores[store_id]
	for key, val in pairs(data) do
		if type(val) ~= "function" then
      self[key] = data[key]
    end
	end
  self.id = self.id or store_id
  self.baseType = "store"
  if data.nameGen then
    self.name = data:nameGen()
  end
  self.inventory = {}
  self.offers_services = self.offers_services or {}
  self.teaches_spells = self.teaches_spells or {}
  self:generate_items()
	return self
end

---Generates the store's inventory
function Store:generate_items()
  --Do custom stocking code:
  if possibleStores[self.id].generate_items then
    if possibleStores[self.id].generate_items(self) == false then
      return
    end
  end
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
      self:add_item(item,info)
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
  --Delete items marked to delete on restock:
  for id,info in pairs(self.inventory) do
    if info.delete_on_restock then
      table.remove(self.inventory,id)
    end
  end
  
  --Do custom restocking code:
  if possibleStores[self.id].restock then
    if possibleStores[self.id].restock(self) == false then
      return
    end
  end
  
  --Do pre-defined items
  if self.sells_items then
    local tags = self.passedTags
    for _,info in pairs(self.sells_items) do
      if info.amount and info.amount ~= -1 then --don't restock infinite-stock items
        local itemID = info.item
        local item = Item(itemID,(info.passed_info or (possibleItems[itemID].acceptTags and tags) or nil),(info.amount or -1))
        local index = self:get_inventory_index(item)
        local currAmt = self:get_count(item) or 0
        local restock_amt = info.restock_amount or 0
        local restock_to = (info.restock_to or (restock_amt >= 0 and info.amount or 0))
        if (restock_amt >= 0 and currAmt < restock_to) or (restock_amt < 0 and currAmt > restock_to) then
          local final_restock = (restock_amt >= 0 and math.min((restock_amt > 0 and restock_amt or restock_to),restock_to-currAmt) or (restock_amt < 0 and math.max(restock_amt or restock_to,restock_to-currAmt)))
          if final_restock < 0 then
            self.inventory[index].item.amount = self.inventory[index].item.amount+final_restock
            if self.inventory[index].item.amount <= 0 then
              table.remove(self.inventory,index)
            end
          else
            self:add_item(item,info)
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

---Adds an item to the store. If the store already has this item, increase the amount
--@param item Item. The item to add
--@param info Table. The information to pass
function Store:add_item(item,info)
  local makeNew = true
  info = info or {}
  info.cost = info.cost or item:get_value()*(self.markup or 1)
  local index = self:get_inventory_index(item)
  if index then
    if self.inventory[index].item.amount ~= -1 then --dont "increase" the amount if the amount is supposed to be infinite
      self.inventory[index].item.amount = self.inventory[index].item.amount+item.amount
    end
    makeNew = false
  end
  if makeNew == true then
    local id = #self.inventory+1
    self.inventory[id] = {item=item,id=id}
    if info then
      for i,k in pairs(info) do
        self.inventory[id][i] = self.inventory[id][i] or k
      end
    end
  end --end if makenew
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
          break
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
  local givenItem = item
  if item.amount > amt then
    item.owner = nil --This is done because item.owner is the creature who owns the item, and Item:clone() does a deep copy of all tables, which means it will create a copy of the owner, which owns a copy of the item, which is owned by another copy of the owner which owns another copy of the item etc etc leading to a crash
    givenItem = item:clone()
    givenItem.amount = amt
    item.owner = creature
  end
  self:add_item(givenItem)
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

---Have a creature learn a spell from a faction.
--@param spellID String. The ID of the spell they're trying to learn.
--@param creature Creature. The creature learning the spell. (optional, defaults to the player)
--@return Boolean. Whether learning the spell was successful or not.
function Store:teach_spell(spellID,creature)
  creature = creature or player
  if creature:has_spell(spellID) then return false end
  
  --Get the spell info:
  local spellInfo = nil
  for _,s in ipairs(self.teaches_spells) do
    if s.spell == spellID then
      spellInfo = s
      break
    end
  end
  if not spellInfo then return false end
  
  --Pay the price:
  if spellInfo.cost then
    local costMod = 0
    if self.faction then
      costMod = self.faction:get_cost_modifier(creature)
    end
    if self.currency_item then
      local creatureItem = player:has_item(self.currency_item)
      creature:delete_item(creatureItem,spellInfo.cost+round(spellInfo.cost*(costMod/100)))
    else
      creature.money = creature.money - spellInfo.cost+round(spellInfo.cost*(costMod/100))
    end
  end
  
  --Teach it, finally:
  creature:learn_spell(spellID)
end

---Gets the index within the store's inventory of the item in question
--@param item Item. The item to seach for.
--@return Number. The index ID of the item.
--@return Number. The amount of the item we have
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
  for id,item in pairs(possibleItems) do --loop through all items to see if they can be sold
    if item.value and not item.neverSpawn and not item.neverStore then --don't sell valueless items or items that don't spawn naturally
      local alreadySells = false
      for _,itemInfo in ipairs(self.sells_items or {}) do --check if we're already selling the item
        if itemInfo.item == id then
          alreadySells = true
          break
        end
      end --end sells_Items for
      if not alreadySells then
        for _,tag in ipairs(self.sells_tags) do --check tags
          if (item.tags and in_table(tag,item.tags) or item.itemType == tag) then
            possibles[#possibles+1] = id
            break
          end --end tags if
        end --end sells_tag for
      end --end alreadySells if
    end --end value and neverSpawn if
  end --end possibleItems for
  return possibles
end

---Generate a random item from the store's possible random items list
--@param list Table. A list of item IDs to pull from. Optional, defaults to the list from get_possible_random_items()
function Store:generate_random_item(list)
  local possibles = list or self:get_possible_random_items()
  local itemID = possibles[random(#possibles)]
  local tags = self.passedTags
  local item = Item(itemID,(possibleItems[itemID].acceptTags and tags or nil))
  if random(1,100) <= (self.artifact_chance or gamesettings.artifact_chance or 0) then
    mapgen:make_artifact(item,tags)
  elseif random(1,100) <= (self.enchantment_chance or gamesettings.enchantment_chance or 0) then
    local possibles = item:get_possible_enchantments(true)
    if count(possibles) > 0 then
      local eid = get_random_element(possibles)
      item:apply_enchantment(eid,-1)
    end
  end
  if not item.amount then item.amount = 1 end --This is here because non-stackable items don't generate with amounts
  self:add_item(item,{randomly_generated=true,delete_on_restock=self.delete_random_items_on_restock})
end

---Placeholder for the requires() code, which is run to determine if the player can enter the store or not.
--@return True.
function Store:requires()
  return true
end