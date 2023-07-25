---@classmod Faction
Faction = Class{}

---Initiate a faction from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the factions.
--@param data Table. The table of faction data.
--@return self Faction. The faction itself.
function Faction:init(fid)
  local data = possibleFactions[fid]
  if not data then
    output:out("Error: Tried to create non-existent faction " .. fid)
    print("Error: Tried to create non-existent faction " .. fid)
    return false
  end
  self.id = fid
	for key, val in pairs(data) do
		if type(val) ~= "function" then
      self[key] = data[key]
    end
	end
  self.baseType = "faction"
  self.inventory = {}
  self.offers_services = self.offers_services or {}
  self.teaches_spells = self.teaches_spells or {}
  self:generate_items()
  if data.generateName then
    self.name = data.generateName(self)
  elseif self.nameType then
    self.name = namegen:generate_name(self.nameType,self)
  end
  self.event_countdown = self.event_cooldown or gamesettings.default_event_cooldown
	return self
end

---Determine if a creature is an enemy of the faction.
--@param creature Creature. The creature to test for enmity.
--@return Boolean. Whether the creature is an enemy or not.
function Faction:is_enemy(creature)
  --First things first, never consider fellow faction members an enemy (unless you're an infighting faction)
  if not self.attack_own_faction and creature:is_faction_member(self.id) then
    return false
  end
  --Secondly, if you just attack everyone who's not a friend, we can just assume you're an enemy
  if self.attack_all_neutral == true and not self:is_friend(creature) then
    return true
  end
  --Next, if the creature is a player ally and the faction is always hostile to the player regardless of favor and membership, we can just assume they're an enemy
  if creature.playerAlly == true and self.always_attack_player == true then
    return true
  end
  --Next, account for enemy factions:
  if self.enemy_factions then
    for _,fac in pairs(self.enemy_factions) do
      if creature:is_faction_member(fac) then
        return true
      end --end is_type if
    end --end faction for
  end
  --Next, account for enemy creature types:
  if self.enemy_types then
    for _,ctype in pairs(self.enemy_types) do
      if creature:is_type(ctype) then
        return true
      end --end is_type if
    end --end ctype for
  end --end if self.enemy_types
  --Next, look if the creature's favor with your faction is low enough to be considered an enemy
  if self.hostile_threshold and creature.favor and (creature.favor[self.id] or 0) < self.hostile_threshold then
    return true
  end
  --Next, if the creature is a player or a friend of the player, we'll look at some player-specific stuff
  if creature.playerAlly then
    --By default, everyone finds the player an enemy if they're not explicitly a friend
    if not self.attack_enemy_player_only and not self:is_friend(player) then
      return true
    end
    --We don't need to look into if the player's otherwise an enemy, because that'll be handled by the above sections
  end --end playerally if
  
  --Finally, if none of the above was true, they're not your enemy
  return false
end

---Determine if the faction considers a creature a friend or not.
--@param creature Creature. The creature to test for friendship.
--@return Boolean. Whether the creature is a friend or not.
function Faction:is_friend(creature)
  --First things first, always consider fellow faction members a friend (unless you're an infighting faction)
  if not self.attack_own_faction and creature:is_faction_member(self.id) then
    return true
  end
  --Next, look at factions:
  if self.friendly_factions then
    for _,fac in pairs(self.friendly_factions) do
      if creature:is_faction_member(fac) then
        return true
      end --end is_type if
    end --end faction for
  end --end if self.friendly_factions
  --Next, account for friendly creature types:
  if self.friendly_types then
    for _,ctype in pairs(self.friendly_types) do
      if creature:is_type(ctype) then
        return true
      end --end is_type if
    end --end ctype for
  end --end if self.friendly_types
  --Finally, look if the creature's favor with your faction is high enough to be considered an friend
  if self.hostile_threshold and creature.favor and (creature.favor[self.id] or 0) > self.friendly_threshold then
    return true
  end
  return false
end

---Have a creature become a member of the faction.
--@param creature Creature. The creature that's joining. (optional, defaults to the player)
function Faction:join(creature)
  creature = creature or player
  if not creature:is_faction_member(self.id) then
    creature.factions[#creature.factions+1] = self.id
  end
  if self.grants_recipes then
    for _,recipe in ipairs(self.grants_recipes) do
      creature:learn_recipe(recipe)
    end
  end
  if self.grants_recipe_tags then
    for id,recipe in pairs(possibleRecipes) do
      if recipe.tags then
        for _,tag in ipairs(self.grants_recipe_tags) do
          if in_table(tag,recipe.tags) then
            creature:learn_recipe(id)
          end --end in_table for
        end --end tag for
      end --end if recipe tags
    end --end possibleRecipes for
  end
end

---Have a creature leave as a member of the faction.
--@param creature Creature. The creature that's leaving. (optional, defaults to the player)
function Faction:leave(creature)
  creature = creature or player
  if creature:is_faction_member(self.id) then
    local k = in_table(self.id,creature.factions)
    table.remove(creature.factions,k)
  end
end

---Test if a creature can become a member of the faction.
--@param creature Creature. The creature that's a potential applicant. (optional, defaults to the player)
--@return Boolean. Whether the creature can join or not.
--@return String. Details on why the creature can't join. (nil if they can join)
function Faction:can_join(creature)
  creature = creature or player
  local canJoin = true
  local reasons = nil
  if self.never_join then
    return false,"This faction does not accept new members."
  end
  if (creature.favor[self.id] or 0) < self.join_threshold then
    reasons = (reasons and reasons .. " " or "") .. "You need more than " .. self.join_threshold .. " favor to join."
    canJoin = false
  end
  if self.enemy_factions then
    for _,enemy in ipairs(self.enemy_factions) do
      if player:is_faction_member(enemy) then
        reasons = (reasons and reasons .. " " or "") .. "You're a member of the enemy faction " .. currWorld.factions[enemy].name .. "."
        canJoin = false
      end
    end
  end
  if self.enemy_types then
    for _,ctype in pairs(self.enemy_types) do
      if creature:is_type(ctype) then
        reasons = (reasons and reasons .. " " or "") .. "Your kind is not welcome here."
        canJoin = false
      end --end is_type if
    end --end ctype for
  end --end if self.enemy_types
  if self.join_requirements then
    local bool,rejectionText = self:join_requirements(creature)
    if bool == false then
      canJoin = false
      if rejectionText then
        reasons = (reasons and reasons .. " " or "") .. rejectionText
      end
    end
  end --end join_requirements if
  return canJoin,reasons
end

---Have a creature learn a spell from a faction.
--@param spellID String. The ID of the spell they're trying to learn.
--@param creature Creature. The creature learning the spell. (optional, defaults to the player)
--@return Boolean. Whether learning the spell was successful or not.
function Faction:teach_spell(spellID,creature)
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
  if spellInfo.moneyCost then
    creature.money = creature.money - (spellInfo.moneyCost+round(spellInfo.moneyCost*(self:get_cost_modifier(player)/100)))
  end
  if spellInfo.favorCost then
    creature.favor[self.id] = creature.favor[self.id] - spellInfo.favorCost
  end
  --Teach it, finally:
  creature:learn_spell(spellID)
end

---Generates the faction's inventory
function Faction:generate_items()
  --Do custom stocking code:
  if possibleFactions[self.id].generate_items then
    if possibleFactions[self.id].generate_items(self) == false then
      return
    end
  end
  --Generate items from list:
  local tags = self.passedTags
  if not self.sells_items then return end
  for _,info in pairs(self.sells_items) do
    local itemID = info.item
    local item = Item(itemID,tags,info.passed_info)
    item.amount = (info.amount or -1)
    if info.artifact then
      mapgen:make_artifact(item,tags)
    elseif info.enchantments then
      for _,eid in ipairs(info.enchantments) do
        item:apply_enchantment(eid,-1)
      end
    end
    self:add_item(item,info)
  end
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

---Restocks the faction's inventory. Default behavior: Restock all defined items up to their original amount, unless restock_amount or restock_to is set.
function Faction:restock()
  --Delete items marked to delete on restock:
  for id,info in pairs(self.inventory) do
    if info.delete_on_restock then
      table.remove(self.inventory,id)
    end
  end
  
  --Do custom restocking code:
  if possibleFactions[self.id].restock then
    if possibleFactions[self.id].restock(self) == false then
      return
    end
  end
  
  --Do defined items
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

---Adds an item to the faction store. If the store already has this item, increase the amount
--@param item Item. The item to add
--@param info Table. The information to pass
function Faction:add_item(item,info)
  local makeNew = true
  info = info or {}
  if not info.moneyCost and not info.favorCost then
    info.moneyCost = (not self.only_sells_favor and math.max(item:get_value()*(self.sell_markup or 1),1) or nil)
    info.favorCost = math.max(math.ceil((item:get_value()*(self.buy_markup or 1))/(self.money_per_favor or 10)),1)
  end
  local index = self:get_inventory_index(item)
  if index then
    self.inventory[index].item.amount = self.inventory[index].item.amount+item.amount
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

---Gets a list of the items the faction is selling
--@return Table. The list of items the faction has in stock
function Faction:get_inventory()
  return self.inventory
end

---Gets the numbers of items this faction has in its current inventory that matches a passed item
--@param item Item. The item to count.
--@return Number. The number of items
function Faction:get_count(item)
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

---Gets a list of the items that a creature can sell to a faction
--@param creat Creature. The creature selling. Optional, defaults to the player
--@return Table. The list of items the player can sell, each of which is another table in the format {item=Item,cost=Number}
function Faction:get_buy_list(creat)
  creat = creat or player
  local buying = {}
  for id,item in ipairs(creat.inventory) do
    if self.buys_items and self.buys_items[item.id] then
      buying[#buying+1]={item=item,moneyCost=self.buys_items[item.id].moneyCost,favorCost=self.buys_items[item.id].favorCost}
    elseif self.buys_tags and item.value then
      for _,tag in ipairs(self.buys_tags) do
        if item:has_tag(tag) or item.itemType == tag then
          buying[#buying+1]={item=item,favorCost=math.max(math.floor((item:get_value()*(self.buy_markup or 1))/(self.money_per_favor or 10)),1),moneyCost=(not self.only_buys_favor and math.max(item:get_value()*(self.buy_markup or 1),1) or nil)}
        end
      end
    end
  end
  return buying
end

---Sell an item to the faction
--@param item Item. The item being sold
--@param moneyCost Number. The amount of money the faction will pay per item.
--@param favorCost Number. The amount of favor the faction will pay per item.
--@param amt Number. The amount of the item being sold. Optional, defaults to 1
--@param creat Creature. The creature selling. Optional, defaults to the player
function Faction:creature_sells_item(item,moneyCost,favorCost,amt,creature)
  creature = creature or player
  moneyCost = moneyCost or 0
  favorCost = favorCost or 0
  local totalAmt = item.amount or 1
  if amt > totalAmt then amt = totalAmt end
  local totalCost = moneyCost*amt
  local totalFavor = favorCost*amt
  local givenItem = item
  if item.amount > amt then
    item.owner = nil --This is done because item.owner is the creature who owns the item, and Item:clone() does a deep copy of all tables, which means it will create a copy of the owner, which owns a copy of the item, which is owned by another copy of the owner which owns another copy of the item etc etc leading to a crash
    givenItem = item:clone()
    givenItem.amount = amt
    item.owner = creature
  end
  self:add_item(givenItem)
  creature:delete_item(item,amt)
  creature.favor[self.id] = (creature.favor[self.id] or 0) + totalFavor
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

---Buy an item from the faction
--@param item Item. The item being sold
--@param moneyCost Number. The amount of money the faction is charging per item.
--@param favorCost Number. The amount of favor the faction is charging per item.
--@param amt Number. The amount of the item being sold. Optional, defaults to 1.
--@param creat Creature. The creature selling. Optional, defaults to the player.
--@return Boolean, Text/nil. True and nil if the buying was successful, False and a string if there's a reason the buying didn't go through.
function Faction:creature_buys_item(item,moneyCost,favorCost,amt,creature)
  creature = creature or player
  moneyCost = moneyCost or 0
  favorCost = favorCost or 0
  local totalAmt = item.amount or 1
  if totalAmt == -1 then totalAmt = 9999999 end
  if amt > totalAmt then amt = totalAmt end
  local totalCost = moneyCost*amt
  local totalFavorCost = favorCost*amt
  local canBuy = false
  local creatureItem = nil
  if self.currency_item then
    creatureItem = creature:has_item(self.currency_item)
    canBuy = (creatureItem.amount >= totalCost)
  else
    canBuy = (creature.money >= totalCost)
  end --end currency checks
  if canBuy and (creature.favor[self.id] or 0) >= totalFavorCost then
    if amt == totalAmt then
      if item.stacks or totalAmt == 1 then
        creature:give_item(item)
      elseif not item.stacks then
        for i=1,amt,1 do
          local newItem = item:clone()
          newItem.amount = nil
          creature:give_item(newItem)
        end
      end
      local id = self:get_inventory_index(item)
      table.remove(self.inventory,id)
      creature.favor[self.id] = (creature.favor[self.id] or 0) - totalFavorCost
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature.money = creature.money-totalCost
      end
    elseif item.stacks then
      local newItem = item:clone()
      if item.amount ~= -1 then item.amount = item.amount - amt end
      newItem.amount = amt
      creature:give_item(newItem)
      creature.favor[self.id] = (creature.favor[self.id] or 0) - totalFavorCost
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature.money = creature.money-totalCost
      end
    else --if buying a nonstackable item
      for i=1,amt,1 do
        local newItem = item:clone()
        newItem.amount = 1
        creature:give_item(newItem)
      end
      if item.amount ~= -1 then item.amount = item.amount - amt end
      creature.favor[self.id] = (creature.favor[self.id] or 0) - totalFavorCost
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature.money = creature.money-totalCost
      end
    end
    return true
  end
  return false,"You don't have enough money or favor to buy " .. item:get_name(true,amt) .. " ."
end

---Gets the index within the faction's inventory of the item in question
--@param item Item. The item to seach for.
--@return Number. The index ID of the item.
function Faction:get_inventory_index(item)
  for id,info in ipairs(self:get_inventory()) do
    if item:matches(info.item) then
      return id
    end
  end
end

---Get all possible random items the faction can stock
--@return Table. A list of the item IDs
function Faction:get_possible_random_items()
  local possibles = {}
  for id,item in pairs(possibleItems) do
      local done = false
      for _,tag in ipairs(self.sells_tags) do
        if item.value and not item.neverSpawn and ((item.tags and in_table(tag,item.tags)) or item.itemType == tag) then
          possibles[#possibles+1] = id
          done = true
          break
        end
      end
    end
    return possibles
  end
  
  ---Generate a random item from the faction's possible random items list
--@param list Table. A list of item IDs to pull from. Optional, defaults to the list from get_possible_random_items()
  function Faction:generate_random_item(list)
    local possibles = list or self:get_possible_random_items()
    local itemID = possibles[random(#possibles)]
    local tags = self.passedTags
    local item = Item(itemID,tags)
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
    self:add_item(item,{randomly_generated=true,delete_on_restock=self.delete_random_items_on_restock})
  end
  
  ---Gets the modifier for items sold in the faction store
  function Faction:get_cost_modifier(creature)
    creature = creature or player
    local finalMod = 0
    if self.faction_cost_modifiers then
      for faction,mod in pairs(self.faction_cost_modifiers) do
        if creature:is_faction_member(faction) then
          if math.abs(mod) > math.abs(finalMod) then
            finalMod = mod
          end
        end
      end --end faction for
    end --end if faction cost modifiers
    if self.favor_cost_modifiers then
      local creatFavor = creature.favor[self.id] or 0
      local highest = nil
      local tempMod = 0
      for favor,mod in pairs(self.favor_cost_modifiers) do
        if creatFavor >= favor and (not highest or favor > highest) then
          highest = favor
          tempMod = mod
        end
      end --end favor for
      finalMod = finalMod + tempMod
    end --end if favor cost modifiers
    return finalMod+creature:get_bonus('cost_modifier')
  end