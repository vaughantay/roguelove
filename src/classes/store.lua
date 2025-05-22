---@classmod Store
Store = Class{}

---Initiate a store from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the stores.
--@param data Table. The table of store data.
--@return self Store. The store itself.
function Store:init(store_id)
  local data = possibleStores[store_id]
  if not data then
    output:out("Error: Tried to create non-existent store " .. store_id)
    print("Error: Tried to create non-existent store " .. store_id)
    return false
  end
	for key, val in pairs(data) do
    local vt = type(val)
    if vt == "table" then
      self[key] = copy_table(data[key])
    elseif vt ~= "function" then
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
  self:select_missions()
	return self
end

---Generates the store's inventory
function Store:generate_items()
  --Do custom stocking code:
  if possibleStores[self.id].generate_items then
    local status,r = pcall(possibleStores[self.id].generate_items,self)
    if status == false then
      output:out("Error in store " .. self.id .. " generate_items code: " .. r)
      print("Error in store " .. self.id .. " generate_Items code: " .. r)
    end
    if r == false then
      return
    end
  end
  --Generate items from list:
  local tags = self.passedTags
  if self.sells_items then
    for _,info in pairs(self.sells_items) do
      local itemID = info.item
      local item = Item(itemID,tags,info.passed_info)
      item.amount = (info.amount or -1) --If an amount is not defined, set it to -1, which fills in for infinite
      if info.artifact then
        mapgen:make_artifact(item,tags)
      elseif info.enchantments then
        for _,eid in ipairs(info.enchantments) do
          item:apply_enchantment(eid,-1)
        end
      end
      if item.requires_identification and not info.unidentified then
        item.identified = true --default to all items in a store being identified
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

---Select missions to offer, if there's a limit
function Store:select_missions()
  local all_missions = self:get_available_missions(nil,true)
  local availableIDs = {}
  local actives = 0
  for _,mission in ipairs(all_missions) do
    if mission.active then
      actives = actives + 1
    else
      availableIDs[#availableIDs+1] = mission.missionID
    end
  end
  
  if self.mission_limit then
    local limit = self.mission_limit-actives
    if limit > 0 then
      availableIDs = shuffle(availableIDs)
      local actual_availables = {}
      for i=1,limit,1 do
        actual_availables[i] = availableIDs[i]
      end
      self.current_missions = actual_availables
    else
      self.current_missions = {}
    end
  else
    self.current_missions = availableIDs
  end
end

---Restocks the store. Default behavior: Restock all defined items up to their original amount, unless restock_amount or restock_to is set.
function Store:restock()
  --Delete items marked to delete on restock:
  local i = 1
  while i <= #self.inventory do
    if self.inventory[i].delete_on_restock then
      table.remove(self.inventory,i)
    else
      i = i + 1
    end
  end
  
  --Do custom restocking code:
  if possibleStores[self.id].restock then
    local status,r = pcall(possibleStores[self.id].restock,self)
    if status == false then
      output:out("Error in store " .. self.id .. " restock code: " .. r)
      print("Error in store " .. self.id .. " restock code: " .. r)
    end
    if r == false then
      return
    end
  end
  
  --Do pre-defined items
  if self.sells_items then
    local tags = self.passedTags
    for _,info in pairs(self.sells_items) do
      if info.amount and info.amount ~= -1 then --don't restock infinite-stock items
        local itemID = info.item
        local item = Item(itemID,tags,info.passed_info)
        item.amount = (info.amount or -1)
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
            if item.requires_identification and not info.unidentified then
              item.identified = true --default to all items in a store being identified
            end
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
  
  self:select_missions()
end

---Adds an item to the store. If the store already has this item, increase the amount
--@param item Item. The item to add
--@param info Table. The information to pass
function Store:add_item(item,info)
  local makeNew = true
  info = info or {}
  info.cost = info.cost 
  if not info.cost then
    local price = item:get_value()
    local markup = self.sell_markup or 0
    if self.item_type_sell_markups then
      local largest = 0
      local smallest = 0
      for itype,mark in pairs(self.item_type_sell_markups) do
        if item:is_type(itype) then
          largest = math.max(largest,mark)
          smallest = math.min(smallest,mark)
        end
      end
      markup = markup+largest+smallest
    end
    price = price + (price * markup/100)
    local currency_mod = (self.currency_item and (self.money_per_currency_item or 10) or 1)
    info.cost =  math.max(math.ceil(price/currency_mod),1)
  end
  local index = self:get_inventory_index(item)
  if index then
    if self.inventory[index].item.amount ~= -1 and item.amount ~= -1 then --dont "increase" the amount if the amount is supposed to be infinite
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
  local alreadyChecked = {}
  for id,item in ipairs(creat.inventory) do
    local price = self:get_buy_cost(item)
    local acID = item.id .. "," .. item.name .. "," .. (item.sortBy and item[item.sortBy] or "") .. "," .. item:get_enchantment_string() .. "," .. (item.level or "")
    if price and not alreadyChecked[acID] then
      local _,_,amt = creat:has_item(item.id,(item.sortBy and item[item.sortBy]),item.enchantments,item.level)
      buying[#buying+1]={item=item,cost=price,amount=amt}
      alreadyChecked[acID] = true
    end
  end
  return buying
end

---Determines if a store will buy an item, and returns the price if so
--@param item Item. The item to consider
--@return False or Number. False if the store won't buy it, the price if it will
function Store:get_buy_cost(item)
  if self.buys_items and self.buys_items[item.id] then
    return self.buys_items[item.id]
  elseif self.buys_types and item:get_value() > 0 then
    if self.forbidden_buys_types then
      for _,itype in ipairs(self.forbidden_buys_types) do
        if item:is_type(itype) then
          return false
        end
      end
    end
    if self.required_buys_types then
      for _,itype in ipairs(self.required_buys_types) do
        if not item:is_type(itype) then
          return false
        end
      end
    end
    for _,itype in ipairs(self.buys_types) do
      if item:is_type(itype) then
        local price = item:get_value()
        local markup = self.buy_markup or 0
        if self.item_type_buy_markups then
          local largest = 0
          local smallest = 0
          for itype,mark in pairs(self.item_type_buy_markups) do
            if item:is_type(itype) then
              largest = math.max(largest,mark)
              smallest = math.min(smallest,mark)
            end
          end
          markup = markup+largest+smallest
        end
        price = price + (price * markup/100)
        local currency_mod = (self.currency_item and (self.money_per_currency_item or 10) or 1)
        return math.max(math.floor(price/currency_mod),1)
      end
    end
  elseif self.buys_tags and item:get_value() > 0 then
    if self.forbidden_buys_tags then
      for _,tag in ipairs(self.forbidden_buys_tags) do
        if item:has_tag(tag) then
          return false
        end
      end
    end
    if self.required_buys_tags then
      for _,tag in ipairs(self.required_buys_tags) do
        if not item:has_tag(tag) then
          return false
        end
      end
    end
    for _,tag in ipairs(self.buys_tags) do
      if item:has_tag(tag) then
        local price = item:get_value()
        local markup = self.buy_markup or 0
        if self.item_type_buy_markups then
          local largest = 0
          local smallest = 0
          for itype,mark in pairs(self.item_type_buy_markups) do
            if item:is_type(itype) then
              largest = math.max(largest,mark)
              smallest = math.min(smallest,mark)
            end
          end
          markup = markup+largest+smallest
        end
        price = price + (price * markup/100)
        local currency_mod = (self.currency_item and (self.money_per_currency_item or 10) or 1)
        return math.max(math.floor(price/currency_mod),1)
      end
    end
  end
  return false
end

---Sell an item to the store
--@param item Item. The item being sold
--@param info Table. A table of information passed by the store screen. Can include:
--@param cost Number. The amount the store will pay per item.
--@param amt Number. The amount of the item being sold. Optional, defaults to 1.
--@param creat Creature. The creature selling to the store. Optional, defaults to the player.
--@para stash Entity. Where the item is actually being held. Optional, defaults to the creature
function Store:creature_sells_item(item,info)
  info = info or {}
  local cost = info.cost or 0
  local amt = info.buyAmt or 1
  local creature = info.creature or player
  local stash = info.stash or creature
  local _,_,totalAmt = stash:has_item(item.id,item.sortBy,item.enchantments,item.level)
  if amt > totalAmt then amt = totalAmt end
  local totalCost = cost*amt
  local givenItem = item
  if item.amount > amt then
    item.possessor = nil --This is done because item.possessor is the creature who owns the item, and Item:duplicate() does a deep copy of all tables, which means it will create a copy of the owner, which owns a copy of the item, which is owned by another copy of the owner which owns another copy of the item etc etc leading to a crash
    givenItem = item:duplicate()
    givenItem.amount = amt
    item.possessor = stash
  end
  self:add_item(givenItem)
  givenItem.possessor=self
  stash:delete_item(item,amt)
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
    creature:update_money(totalCost)
  end
end

---Buy an item from the store
--@param item Item. The item being sold
--@param info Table. A table of information passed by the store screen. Can include:
--@param cost Number. The amount the store is charging per item.
--@param amt Number. The amount of the item being sold. Optional, defaults to 1.
--@param creat Creature. The creature selling to the store. Optional, defaults to the player.
--@return Boolean, Text/nil. True and nil if the buying was successful, False and a string if there's a reason the buying didn't go through.
function Store:creature_buys_item(item,info)
  info = info or {}
  local cost = info.cost or 0
  local amt = info.buyAmt or 1
  local creature = info.creature or player
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
          local newItem = item:duplicate()
          newItem.amount = 1
          creature:give_item(newItem)
        end
      end
      local id = self:get_inventory_index(item)
      table.remove(self.inventory,id)
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature:update_money(-totalCost)
      end
    elseif item.stacks then --if buying a stackable item
      local newItem = item:duplicate()
      if item.amount ~= -1 then item.amount = item.amount - amt end
      newItem.amount = amt
      creature:give_item(newItem)
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature:update_money(-totalCost)
      end
    else --if buying a nonstackable item
      for i=1,amt,1 do
        local newItem = item:duplicate()
        newItem.amount=1
        creature:give_item(newItem)
      end
      if item.amount ~= -1 then item.amount = item.amount - amt end
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature:update_money(-totalCost)
      end
    end
    return true
  end
  return false,"You don't have enough to buy " .. item:get_name(true,amt) .. " ."
end

---Have a creature learn a spell from a store.
--@param spellID String. The ID of the spell they're trying to learn.
--@param creature Creature. The creature learning the spell. (optional, defaults to the player)
--@return Boolean. Whether learning the spell was successful or not.
function Store:teach_spell(spellID,creature)
  creature = creature or player
  if creature:has_spell(spellID,true,true) then return false end
  
  --Get the spell info:
  local spellInfo = nil
  for _,s in ipairs(self:get_teachable_spells()) do
    if s.spell == spellID then
      spellInfo = s
      break
    end
  end
  if not spellInfo then return false end
  
  --Pay the price:
  if spellInfo.cost and spellInfo.cost > 0 then
    local costMod = 0
    if self.faction then
      costMod = currWorld.factions[self.faction]:get_cost_modifier(creature)
    end
    if self.currency_item then
      local creatureItem = player:has_item(self.currency_item)
      creature:delete_item(creatureItem,spellInfo.cost+round(spellInfo.cost*(costMod/100)))
    else
      creature:update_money(-(spellInfo.cost+round(spellInfo.cost*(costMod/100))))
    end
  end
  
  --Teach it, finally:
  creature:learn_spell(spellID)
end

---Have a creature learn a skill from a store.
--@param skillID String. The ID of the skill they're trying to learn.
--@param creature Creature. The creature learning the skill. (optional, defaults to the player)
--@return Boolean. Whether learning the skill was successful or not.
function Store:teach_skill(skillID,creature)
  creature = creature or player
  
  --Get the skill info:
  local skillInfo = nil
  for _,s in ipairs(self:get_teachable_skills()) do
    if s.skill == skillID then
      skillInfo = s
      break
    end
  end
  if not skillInfo then return false end
  
  --Pay the price:
  if skillInfo.cost and skillInfo.cost > 0 then
    local costMod = 0
    if self.faction then
      costMod = currWorld.factions[self.faction]:get_cost_modifier(creature)
    end
    if self.currency_item then
      local creatureItem = player:has_item(self.currency_item)
      creature:delete_item(creatureItem,skillInfo.cost+round(skillInfo.cost*(costMod/100)))
    else
      creature:update_money(-(skillInfo.cost+round(skillInfo.cost*(costMod/100))))
    end
  end
  
  --Teach it, finally:
  creature:upgrade_skill(skillID,1,true)
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
        local done = false
        if self.forbidden_sells_types then
          for _,itype in ipairs(self.forbidden_sells_types) do
            if item.types and in_table(itype,item.types) then
              done = true
              break
            end
          end
        end
        if not done and self.required_sells_types then
          for _,itype in ipairs(self.required_sells_types) do
            if not item.types or not in_table(types,item.ttypesags) then
              done = true
              break
            end
          end
        end
        if not done and self.forbidden_sells_tags then
          for _,tag in ipairs(self.forbidden_sells_tags) do
            if item.tags and in_table(tag,item.tags) then
              done = true
              break
            end
          end
        end
        if not done and self.required_sells_tags then
          for _,tag in ipairs(self.required_sells_tags) do
            if not item.tags or not in_table(tag,item.tags) then
              done = true
              break
            end
          end
        end
        if not done and self.sells_types then
          for _,itype in ipairs(self.sells_types) do --check tags
            if (item.types and in_table(itype,item.types)) then
              done = true
              possibles[#possibles+1] = id
              break
            end --end tags if
          end --end sells_tag for
        end
        if not done and self.sells_tags then
          for _,tag in ipairs(self.sells_tags) do --check tags
            if (item.tags and in_table(tag,item.tags)) then
              possibles[#possibles+1] = id
              break
            end --end tags if
          end --end sells_tag for
        end
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
  local item = Item(itemID,tags)
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
  if item.requires_identification and not self.random_items_unidentified then
    item.identified = true
  end
  self:add_item(item,{randomly_generated=true,delete_on_restock=self.delete_random_items_on_restock})
end

---Gets the list of spells the store can teach a given creature
--@param creature Creature. Optional, defaults to player
--@return Table. A list of possible spells
function Store:get_teachable_spells(creature)
  creature = creature or player
  local spell_list = {}
  local spells = copy_table(self.teaches_spells or {})
  local costMod = (self.faction and currWorld.factions[self.faction]:get_cost_modifier(player) or 0)
  
  --Determine any teachable spells from tags
  if self.teaches_spell_tags or self.teaches_spell_types then
    local alreadyTeaches = {}
    if count(spells) > 0 then
      for _,spInfo in ipairs(spells) do
        alreadyTeaches[spInfo.spell] = true
      end
    end
    for spellID,spell in pairs(possibleSpells) do
      if not alreadyTeaches[spellID] and (spell.tags or spell.types) then
        local canTeach = true
        local doTeach = false
        if self.forbidden_spell_types then
          for _,tag in ipairs(self.forbidden_spell_types) do
            if spell.types and in_table(tag,spell.types) then
              canTeach = false
              break
            end
          end
        end
        if canTeach and self.required_spell_types then
          for _,tag in ipairs(self.required_spell_types) do
            if not spell.types or not in_table(tag,spell.types) then
              canTeach = false
              break
            end
          end
        end
        if canTeach and self.forbidden_spell_tags then
          for _,tag in ipairs(self.forbidden_spell_tags) do
            if spell.tags and in_table(tag,spell.tags) then
              canTeach = false
              break
            end
          end
        end
        if canTeach and self.required_spell_tags then
          for _,tag in ipairs(self.required_spell_tags) do
            if not spell.tags or not in_table(tag,spell.tags) then
              canTeach = false
              break
            end
          end
        end
        if canTeach and self.teaches_spell_types and spell.types then
          for _,tag in ipairs(self.teaches_spell_types) do
            if spell.types and in_table(tag,spell.types) then
              doTeach = true
              break
            end
          end
        end
        if canTeach and not doTeach and self.teaches_spell_tags and spell.tags then
          for _,tag in ipairs(self.teaches_spell_tags) do
            if in_table(tag,spell.tags) then
              doTeach = true
              break
            end
          end
        end
        if doTeach then
          local cost = (self.spell_cost_per_level and self.spell_cost_per_level*(spell.level or 1) or self.spell_cost or 0)
          spells[#spells+1] = {spell=spellID,cost=cost}
        end
      end
    end
  end
  
  --Determine which spells are available:
  for _,spellDef in pairs(spells) do
    if not player:has_spell(spellDef.spell,true,true) then
      local spellID = spellDef.spell
      local spell = possibleSpells[spellID]
      local cost = (spellDef.cost or 0)
      cost = cost + round(cost*(costMod/100))
      local currencyItem = self.currency_item
      local playerItem = (currencyItem and player:has_item(currencyItem) or nil)
      local canLearn = true
      local reasonText = nil
      
      if not currencyItem and spellDef.cost and creature.money < cost then
        reasonText = "You don't have enough money to learn this ability."
        canLearn = false
      elseif currencyItem and (not playerItem or playerItem.amount < cost) then
        reasonText = "You don't have enough " .. (possibleItems[currencyItem].pluralName or possibleItems[currencyItem].name) .. " to learn this ability."
        canLearn = false
      else
        local ret,text = creature:can_learn_spell(spellDef.spell)
        if ret == false then
          reasonText = (text or "You're unable to learn this ability.")
          canLearn = false
        end
      end
      
      spell_list[#spell_list+1] = {spell=spellID,name=spell.name,description=spell.description,canLearn=canLearn,reasonText=reasonText,cost=cost}
    end
  end
  
  return spell_list
end

---Gets the list of skills the store can teach a given creature
--@param creature Creature. Optional, defaults to player
--@return Table. A list of possible skills
function Store:get_teachable_skills(creature)
  creature = creature or player
  local skill_list = {}
  local skills = copy_table(self.teaches_skills or {})
  local costMod = (self.faction and currWorld.factions[self.faction]:get_cost_modifier(player) or 0)
  
  --Determine any teachable skills from tags
  if self.teaches_skill_tags then
    local alreadyTeaches = {}
    if count(skills) > 0 then
      for _,spInfo in ipairs(skills) do
        alreadyTeaches[spInfo.skill] = true
      end
    end
    for skillID,skill in pairs(possibleSkills) do
      if not alreadyTeaches[skillID] and skill.tags then
        local canTeach = true
        local doTeach = false
        if canTeach and self.forbidden_skill_tags then
          for _,tag in ipairs(self.forbidden_skill_tags) do
            if skill.tags and in_table(tag,skill.tags) then
              canTeach = false
              break
            end
          end
        end
        if canTeach and self.required_skill_tags then
          for _,tag in ipairs(self.required_skill_tags) do
            if not skill.tags or not in_table(tag,skill.tags) then
              canTeach = false
              break
            end
          end
        end
        if canTeach and not doTeach and self.teaches_skill_tags and skill.tags then
          for _,tag in ipairs(self.teaches_skill_tags) do
            if in_table(tag,skill.tags) then
              doTeach = true
              break
            end
          end
        end
        if doTeach then
          skills[#skills+1] = {skill=skillID,cost=self.skill_cost,max=skill.max}
        end
      end
    end
  end
  
  --Determine which skills are available:
  for _,skillDef in pairs(skills) do
    local skillID = skillDef.skill
    local skill = possibleSkills[skillID]
    local player_val = creature:get_skill(skillID,true)
    if not skillDef.max and skill.max then skillDef.max = skill.max end
    if not player_val or not skillDef.max or player_val < skillDef.max then
      local cost = (skillDef.cost or 0)*(player_val+1)
      cost = cost + round(cost*(costMod/100))
      local currencyItem = self.currency_item
      local playerItem = (currencyItem and player:has_item(currencyItem) or nil)
      local canLearn = true
      local reasonText = nil
      
      if not currencyItem and skillDef.cost and creature.money < cost then
        reasonText = "You don't have enough money to learn this skill."
        canLearn = false
      elseif currencyItem and (not playerItem or playerItem.amount < cost) then
        reasonText = "You don't have enough " .. (possibleItems[currencyItem].pluralName or possibleItems[currencyItem].name) .. " to learn this skill."
        canLearn = false
      elseif skill.upgrade_requires then
        local ret,text = skill:upgrade_requires(creature)
        if ret == false then
          reasonText = (text or "You're unable to learn this skill.")
          canLearn = false
        end
      end
      
      skill_list[#skill_list+1] = {skill=skillID,level=player_val+1,name=skill.name,description=skill.description,canLearn=canLearn,reasonText=reasonText,cost=cost}
    end
  end
  
  return skill_list
end

--@param creature Creature. Optional, defaults to player
--@return Table. A list of possible services
function Store:get_available_services(creature)
  local services = {}
  
  if self.offers_services then
    local costMod = (self.faction and currWorld.factions[self.faction]:get_cost_modifier(player) or 0)
    for i,servData in ipairs(self.offers_services) do
      local service_data = {service=servData.service}
      local servID = servData.service
      local service = possibleServices[servID]
      local costText = service:get_cost_text(creature) or servData.costText or service.costText
      if costText == nil then
        local moneyText = (servData.cost and get_money_name(servData.cost+round(servData.cost*(costMod/100))) or nil)
        costText = moneyText
      end
      service_data.name = service.name
      service_data.description = (costText and " (Cost: " .. costText .. ")" or "") .. "\n" .. service.description
      
      local canDo,canDoText = nil,nil
      if servData.cost and creature.money < servData.cost+round(servData.cost*(costMod/100)) then
        canDoText = "You don't have enough money."
        canDo = false
      elseif not service.requires then
        canDo=true
      else
        canDo,canDoText = service:requires(creature)
        if canDo == false then
          canDoText = "You're not eligible for this service" .. (canDoText and ": " .. canDoText or ".")
        end
      end
      service_data.disabled = (canDo == false)
      service_data.explainText = canDoText
      if not (service_data.disabled and service.hide_when_disabled) then
        services[#services+1] = service_data
      end
    end
  end
  return services
end

---Gets the list of missions the store can teach a given creature
--@param creature Creature. Optional, defaults to player
--@param ignoreCurrent. Optional, if true ignore the current_missions table
--@return Table. A list of possible missions
function Store:get_available_missions(creature,ignoreCurrent)
  local missions = {}
  
  if self.offers_missions then
    for i, mData in ipairs(self.offers_missions) do
      local missionID = mData.mission
      local active = get_mission_status(missionID)
      local mission = possibleMissions[missionID]
      if possibleMissions[missionID] and (not currGame.finishedMissions[missionID] or (mission.repeatable and (not mission.repeat_limit or currGame.finishedMissions[missionID].repetitions < mission.repeat_limit))) and (active or ignoreCurrent or not self.current_missions or in_table(missionID,self.current_missions))  then
        local mData = {missionID=missionID}
        mData.name = mission.name
        mData.description = (get_mission_data(missionID,'description') or mission.description)
        mData.rewards = mission.rewards
        
        if active then
          mData.active = true
          local canFinish,canFinishText = nil,nil
          if mission.can_finish then
            canFinish,canFinishText = mission:can_finish(player)
          end
          if not canFinish then
            canFinishText = "You are currently on this mission" .. (canFinishText and ". " .. canFinishText or ".")
          end
          mData.disabled = not canFinish
          mData.explainText = canFinishText
        else --Not active mission
          local canDo,canDoText = nil,nil
          if not mission.requires then
            canDo = true
          else
            canDo,canDoText = mission:requires(creature)
          end
          if not canDo then
            canDoText = "You're not eligible for this mission" .. (canDoText and ": " .. canDoText or ".")
          end
          mData.disabled = not canDo
          mData.explainText = canDoText
        end --end active mission or not if
        if active or not (mData.disabled and mission.hide_when_disabled) then
          missions[#missions+1] = mData
        end
      end
    end
  end
  
  return missions
end

---Placeholder for the requires() code, which is run to determine if the player can enter the store or not.
--@return True.
function Store:requires()
  return true
end