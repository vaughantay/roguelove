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
    local vt = type(val)
    if vt == "table" then
      self[key] = copy_table(data[key])
    elseif vt ~= "function" then
      self[key] = data[key]
    end
	end
  self.baseType = "faction"
  self.inventory = {}
  self.offers_services = self.offers_services or {}
  self.teaches_spells = self.teaches_spells or {}
  self.teaches_skills = self.teaches_skills or {}
  self:generate_items()
  self:select_missions()
  if data.generateName then
    self.name = data.generateName(self)
  elseif self.nameType then
    self.name = namegen:generate_name(self.nameType,self)
  end
  self.event_countdown = self.event_cooldown or gamesettings.default_event_cooldown
	return self
end

---Returns the faction's name
--@return Text. The name
function Faction:get_name()
  return self.name
end

---Returns the faction's description
--@return Text. The description
function Faction:get_description()
  return self.description
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
  --Next, if the creature is a player ally and the faction is always hostile to the player regardless of reputation and membership, we can just assume they're an enemy
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
  --Next, look if the creature's reputation with your faction is low enough to be considered an enemy
  if self.hostile_threshold and creature.reputation and (creature.reputation[self.id] or 0) <= self.hostile_threshold then
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
  --Finally, look if the creature's reputation with your faction is high enough to be considered an friend
  if self.hostile_threshold and creature.reputation and (creature.reputation[self.id] or 0) >= self.friendly_threshold then
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
  if self.grants_spells then
    for _, spell in ipairs(self.grants_spells) do
      creature:learn_spell(spell,true)
    end
  end
  if self.grants_skills then
    for skillID,val in pairs(self.grants_skills) do
      local currVal = creature:get_skill(skillID)
      local increase = val-currVal
      if increase then
        creature:upgrade_skill(skillID,increase,true,true)
      end
    end
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
  if (creature.reputation[self.id] or 0) < self.join_threshold then
    reasons = (reasons and reasons .. " " or "") .. "You need more than " .. self.join_threshold .. " reputation to join."
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
  if spellInfo.moneyCost and spellInfo.moneyCost > 0 then
    creature:update_money(-(spellInfo.moneyCost+round(spellInfo.moneyCost*(self:get_cost_modifier(player)/100))))
  end
  if spellInfo.favorCost and spellInfo.favorCost > 0  then
    creature:update_favor(self.id,-spellInfo.favorCost,nil,nil,true)
  end
  if spellInfo.reputationCost and spellInfo.reputationCost > 0 then
    creature:update_reputation(self.id,-spellInfo.reputationCost,nil,nil,true)
  end
  --Teach it, finally:
  creature:learn_spell(spellID)
end

---Have a creature learn a skill from a faction.
--@param skillID String. The ID of the skill they're trying to learn.
--@param creature Creature. The creature learning the skill. (optional, defaults to the player)
--@return Boolean. Whether learning the skill was successful or not.
function Faction:teach_skill(skillID,creature)
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
  if skillInfo.moneyCost and skillInfo.moneyCost > 0 then
    creature:update_money(-skillInfo.moneyCost)
  end
  
  if skillInfo.favorCost and skillInfo.favorCost > 0 then
    creature:update_favor(self.id,-skillInfo.favorCost,nil,nil,true)
  end
  
  if skillInfo.reputationCost and skillInfo.reputationCost > 0 then
    creature:update_reputation(self.id,-skillInfo.reputationCost,nil,nil,true)
  end
  
  --Teach it, finally:
  creature:upgrade_skill(skillID,1,true)
end

---Generates the faction's inventory
function Faction:generate_items()
  --Do custom stocking code:
  if possibleFactions[self.id].generate_items then
    local status,r = pcall(possibleFactions[self.id].generate_items,self)
    if status == false then
      output:out("Error in faction " .. self.id .. " generate_items code: " .. r)
      print("Error in faction " .. self.id .. " generate_Items code: " .. r)
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

---Select missions to offer, if there's a limit
function Faction:select_missions()
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

---Restocks the faction's inventory. Default behavior: Restock all defined items up to their original amount, unless restock_amount or restock_to is set.
function Faction:restock()
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
  if possibleFactions[self.id].restock then
    local status,r = pcall(possibleFactions[self.id].restock,self)
    if status == false then
      output:out("Error in faction " .. self.id .. " restock code: " .. r)
      print("Error in faction " .. self.id .. " restock code: " .. r)
    end
    if r == false then
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
  
  if self.recruitable_creatures then
    for _,data in ipairs(self.recruitable_creatures) do
      if data.restock_amount then
        data.amount = (data.amount or 0) + data.restock_amount
        if data.restock_to then
          data.amount = math.min(data.amount,data.restock_to)
        end
      end
    end
  end
  
  self:select_missions()
end

---Adds an item to the faction store. If the store already has this item, increase the amount
--@param item Item. The item to add
--@param info Table. The information to pass
function Faction:add_item(item,info)
  local makeNew = true
  info = info or {}
  if not info.moneyCost and not info.favorCost and not info.reputationCost then
    local costs = self:get_sell_cost(item)
    if not self.no_sell_money then info.moneyCost = costs.moneyCost end
    if not self.no_sell_favor then info.favorCost = costs.favorCost end
  end
  local index = self:get_inventory_index(item)
  if index then
    if self.inventory[index].item.amount ~= -1 and item.amount ~= -1 then
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
  local alreadyChecked = {}
  for id,item in ipairs(creat.inventory) do
    local price = self:get_buy_cost(item)
    local acID = item.id .. "," .. item.name .. "," .. (item.sortBy and item[item.sortBy] or "") .. "," .. item:get_enchantment_string() .. "," .. (item.level or "")
    if price and not alreadyChecked[acID]  then
      local _,_,amt = creat:has_item(item.id,(item.sortBy and item[item.sortBy]),item.enchantments,item.level)
      buying[#buying+1] = {item=item,moneyCost=price.moneyCost,favorCost=price.favorCost,reputationCost=price.reputationCost,amount=amt}
      alreadyChecked[acID] = true
    end
  end
  return buying
end

---Determines the cost the faction will sell the item for
--@param item Item. The item to consider
--@return Table. With moneyCost and favorCost values
function Faction:get_sell_cost(item)
  local info = {}
  local price = item:get_value()
  local markup = self.sell_markup or 0
  local favorMarkup = self.sell_markup_favor or 0
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
  price = price + math.floor(price * markup/100)
  local favor_mod = (self.money_per_favor or 1)
  info.moneyCost =  math.max(price,1)
  local favorCost = math.floor(info.moneyCost/favor_mod)
  favorCost = favorCost + math.floor(favorCost * favorMarkup/100)
  info.favorCost = math.max(favorCost,1)
  return info
end

---Determines if a faction will buy an item, and returns the price if so
--@param item Item. The item to consider
--@return False or Number. False if the faction won't buy it, the price if it will
function Faction:get_buy_cost(item)
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
        local favorMarkup = self.buy_markup_favor or 0
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
        price = price + math.floor(price * markup/100)
        local moneyCost = math.max(price,1)
        local favorCost = math.max(math.floor(moneyCost/(self.money_per_favor or 1)),1)
        favorCost =  favorCost + math.floor(favorCost * favorMarkup/100)
        local reputationCost = 0
        if self.item_type_buy_reputation then
          local largest = 0
          for itype,reputation in pairs(self.item_type_buy_reputation) do
            if item:is_type(itype) then
              largest = math.max(largest,reputation)
            end
          end
          reputationCost = largest
          if reputationCost == 0 then reputationCost = nil end
        end
        return {favorCost=(not self.no_buy_favor and favorCost or nil),moneyCost=(not self.no_buy_money and moneyCost or nil),reputationCost=reputationCost}
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
        price = price + round(price * markup/100)
        local moneyCost = math.ceil(math.max(price,1))
        local favorCost = math.max(math.floor(moneyCost/(self.money_per_favor or 1)),1)
        local reputationCost = 0
        if self.item_type_buy_reputation then
          local largest = 0
          for itype,reputation in pairs(self.item_type_buy_reputation) do
            if item:is_type(itype) then
              largest = math.max(largest,reputation)
            end
          end
          reputationCost = largest
          if reputationCost == 0 then reputationCost = nil end
        end
        return {favorCost=(not self.no_buy_favor and favorCost or nil),moneyCost=(not self.no_buy_money and moneyCost or nil),reputationCost=reputationCost}
      end
    end
  end
  return false
end

---Sell an item to the faction
--@param item Item. The item being sold
--@param info Table. A table of information passed by the faction screen. Can include the following:
--@param moneyCost Number. The amount of money the faction will pay per item
--@param favorCost Number. The amount of favor the faction will pay per item
--@param reputationCost Number. The amount of reputation the faction will pay per item
--@param amt Number. The amount of the item being sold. Optional, defaults to 1
--@param creat Creature. The creature selling. Optional, defaults to the player
--@para stash Entity. Where the item is actually being held. Optional, defaults to the creature
function Faction:creature_sells_item(item,info)
  info = info or {}
  local creature = info.creature or player
  local stash = info.stash or creature
  local moneyCost = info.moneyCost or 0
  local favorCost = info.favorCost or 0
  local reputationCost = info.reputationCost or 0
  local amt = info.buyAmt or 1
  local _,_,totalAmt = stash:has_item(item.id,item.sortBy,item.enchantments,item.level)
  if amt > totalAmt then amt = totalAmt end
  local totalCost = moneyCost*amt
  local totalFavor = favorCost*amt
  local totalReputation = reputationCost*amt
  local givenItem = item
  if item.amount > amt then
    item.possessor = nil --This is done because item.possessor is the creature who owns the item, and Item:duplicate() does a deep copy of all tables, which means it will create a copy of the owner, which owns a copy of the item, which is owned by another copy of the owner which owns another copy of the item etc etc leading to a crash
    givenItem = item:duplicate()
    givenItem.amount = amt
    item.possessor = stash
  end
  self:add_item(givenItem)
  stash:delete_item(item,amt)
  creature:update_favor(self.id,totalFavor,nil,nil,true)
  creature:update_reputation(self.id,totalReputation)
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
    if not favorCost or favorCost == 0 then
      local favor_equivalent = math.floor(totalCost/(self.money_per_favor or 1))
      self.favor_spent = (self.favor_spent or 0) + math.abs(favor_equivalent)
      if self.reputation_per_favor_spent then
        while self.favor_spent >= self.reputation_per_favor_spent do
          creature:update_reputation(self.id,1,false)
          self.favor_spent = self.favor_spent - self.reputation_per_favor_spent
        end
      end
    end
  end
end

---Buy an item from the faction
--@param item Item. The item being sold
--@param info Table. A table of information passed by the faction screen. Can include the following:
--@param moneyCost Number. The amount of money the faction is charging per item.
--@param favorCost Number. The amount of favor the faction is charging per item.
--@param amt Number. The amount of the item being sold. Optional, defaults to 1.
--@param creat Creature. The creature selling. Optional, defaults to the player.
--@return Boolean, Text/nil. True and nil if the buying was successful, False and a string if there's a reason the buying didn't go through.
function Faction:creature_buys_item(item,info)
  info = info or {}
  local moneyCost = info.moneyCost or 0
  local favorCost = info.favorCost or 0
  local repCost = info.reputationCost or 0
  local amt = info.buyAmt or 1
  local creature = info.creature or player
  local totalAmt = item.amount or 1
  if totalAmt == -1 then totalAmt = 9999999 end
  if amt > totalAmt then amt = totalAmt end
  local totalCost = moneyCost*amt
  local totalFavorCost = favorCost*amt
  local totalRepCost = repCost*amt
  local total
  local canBuy = false
  local creatureItem = nil
  if self.currency_item then
    creatureItem = creature:has_item(self.currency_item)
    canBuy = (creatureItem.amount >= totalCost)
  else
    canBuy = (creature.money >= totalCost)
  end --end currency checks
  if canBuy and (creature.favor[self.id] or 0) >= totalFavorCost and (creature.reputation[self.id] or 0) >= totalRepCost then
    if amt == totalAmt then
      if item.stacks or totalAmt == 1 then
        creature:give_item(item)
      elseif not item.stacks then
        for i=1,amt,1 do
          local newItem = item:duplicate()
          newItem.amount = nil
          creature:give_item(newItem)
        end
      end
      local id = self:get_inventory_index(item)
      table.remove(self.inventory,id)
      creature:update_favor(self.id,-totalFavorCost,nil,nil,true)
      creature:update_reputation(self.id,-totalRepCost)
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        if not favorCost or favorCost == 0 then
          local favor_equivalent = math.floor(totalCost/(self.money_per_favor or 1))
          self.favor_spent = (self.favor_spent or 0) + math.abs(favor_equivalent)
          if self.reputation_per_favor_spent then
            while self.favor_spent >= self.reputation_per_favor_spent do
              creature:update_reputation(self.id,1,false)
              self.favor_spent = self.favor_spent - self.reputation_per_favor_spent
            end
          end
        end
        creature:update_money(-totalCost)
      end
    elseif item.stacks then
      local newItem = item:duplicate()
      if item.amount ~= -1 then item.amount = item.amount - amt end
      newItem.amount = amt
      creature:give_item(newItem)
      creature:update_favor(self.id,-totalFavorCost,nil,nil,true)
      creature:update_reputation(self.id,-totalRepCost)
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature:update_money(-totalCost)
      end
    else --if buying a nonstackable item
      for i=1,amt,1 do
        local newItem = item:duplicate()
        newItem.amount = 1
        creature:give_item(newItem)
      end
      if item.amount ~= -1 then item.amount = item.amount - amt end
      creature:update_favor(self.id,-totalFavorCost,nil,nil,true)
      creature:update_reputation(self.id,-totalRepCost)
      if self.currency_item then
        creatureItem.amount = creatureItem.amount-totalCost
      else
        creature:update_money(-totalCost)
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
            if not item.types or not in_table(itype,item.types) then
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
  end
  return possibles
end
  
---Generate a random item from the faction's possible random items list
--@param list Table. A list of item IDs to pull from. Optional, defaults to the list from get_possible_random_items()
--@param info. Table. A table of potential values including:
--@param artifact_chance Number.
--@param enchantment_chance Number.
--@param noAdd Boolean. If true, don't add the item to inventory
function Faction:generate_random_item(list,info)
  info = info or {}
  local possibles = list or self:get_possible_random_items()
  local itemID = possibles[random(#possibles)]
  local tags = self.passedTags
  local item = Item(itemID,tags)
  if random(1,100) <= (info.artifact_chance or self.artifact_chance or gamesettings.artifact_chance) then
    mapgen:make_artifact(item,tags)
  elseif random(1,100) <= (info.enchantment_chance or self.enchantment_chance or gamesettings.enchantment_chance) then
    local possibles = item:get_possible_enchantments(true)
    if count(possibles) > 0 then
      local eid = get_random_element(possibles)
      item:apply_enchantment(eid,-1)
    end
  end
  if not item.amount then item.amount = 1 end --This is here because non-stackable items don't generate with amounts
  if not info.noAdd then self:add_item(item,{randomly_generated=true,delete_on_restock=self.delete_random_items_on_restock}) end
  return item
end

---Generates a gift from the faction
--@param items Table. The items to give
function Faction:generate_gifts()
  --Do custom gift code:
  if possibleFactions[self.id].generate_gift then
    local status,r = pcall(possibleFactions[self.id].generate_gift,self)
    if status == false then
      output:out("Error in faction " .. self.id .. " generate_gift code: " .. r)
      print("Error in faction " .. self.id .. " generate_gift code: " .. r)
    end
    if r == false then
      return
    elseif type(r) == "table" then
      if r.baseType == "item" then
        return {r}
      else
        return r
      end
    end
  end
  
  local finalVal = tweak(self.gift_value or 0)
  if not finalVal or finalVal == 0 then
    return false
  end
  local possibles = self:get_possible_gift_items()
  local tags = self.passedTags
  possibles = shuffle(possibles)
  local gifts = {}
  local gift_value = 0
  local max_items = self.max_gift_items or 5
  local items_given = 0
  while gift_value < finalVal and items_given < max_items and count(possibles) > 0 do
    local item = self:generate_random_item(possibles,{noAdd=true,artifact_chance=0})
    if item.id == "money" then
      item.amount = finalVal - gift_value
    end
    local value = item:get_value()*item.amount
    if value <= (finalVal-gift_value) or items_given == 0 then
      gifts[#gifts+1] = item
      gift_value = gift_value + value*item.amount
      items_given = items_given+1
    else
      remove_from_array(possibles,item.id)
    end
  end
  return gifts
end

---Get all possible gift items the faction can offer
--@return Table. A list of the item IDs
function Faction:get_possible_gift_items()
  local possibles = copy_table(self.gift_items or {})
  local forbidden_types = self.gift_forbidden_types or self.forbidden_sells_types
  local required_types = self.gift_required_types or self.required_sells_types
  local forbidden_tags = self.gift_forbidden_tags or self.forbidden_sells_tags
  local required_tags = self.gift_required_tags or self.required_sells_tags
  local types = self.gift_types or self.sells_types
  local tags = self.gift_tags or self.sells_tags
  local value_max = self.gift_value or 0
  for id,item in pairs(possibleItems) do
    local alreadyDone = false
    for _,iid in ipairs(possibles) do
      if id == iid then
        alreadyDone = true
        break
      end
    end
    if not alreadyDone then
      if item.value and not item.neverSpawn and not item.neverStore and not item.delete_after_heist and item.value <= value_max then --don't sell valueless items or items that don't spawn naturally
        local done = false
        if forbidden_types then
          for _,itype in ipairs(forbidden_types) do
            if item.types and in_table(itype,item.types) then
              done = true
              break
            end
          end
        end
        if not done and required_types then
          for _,itype in ipairs(required_types) do
            if not item.types or not in_table(itype,item.types) then
              done = true
              break
            end
          end
        end
        if not done and forbidden_tags then
          for _,tag in ipairs(forbidden_tags) do
            if item.tags and in_table(tag,item.tags) then
              done = true
              break
            end
          end
        end
        if not done and required_tags then
          for _,tag in ipairs(required_tags) do
            if not item.tags or not in_table(tag,item.tags) then
              done = true
              break
            end
          end
        end
        if not done and types then
          for _,itype in ipairs(types) do --check tags
            if (item.types and in_table(itype,item.types)) then
              done = true
              possibles[#possibles+1] = id
              break
            end --end tags if
          end --end sells_tag for
        end
        if not done and tags then
          for _,tag in ipairs(tags) do --check tags
            if (item.tags and in_table(tag,item.tags)) then
              possibles[#possibles+1] = id
              break
            end --end tags if
          end --end sells_tag for
        end
      end
    end --end alreadySells if
  end --end value and neverSpawn if
  if count(possibles) == 0 and self.sells_items then
    for _,info in pairs(self.sells_items) do
      if not info.artifact then
        possibles[#possibles+1] = info.item
      end
    end
  end
  return possibles
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
  if self.reputation_cost_modifiers then
    local creatreputation = creature.reputation[self.id] or 0
    local highest = nil
    local tempMod = 0
    for reputation,mod in pairs(self.reputation_cost_modifiers) do
      if creatreputation >= reputation and (not highest or reputation > highest) then
        highest = reputation
        tempMod = mod
      end
    end --end reputation for
    finalMod = finalMod + tempMod
  end --end if reputation cost modifiers
  return finalMod+creature:get_bonus('cost_modifier')
end

---Gets the list of spells the faction can teach a given creature
--@param creature Creature. Optional, defaults to player
--@return Table. A list of possible spells
function Faction:get_teachable_spells(creature)
  creature = creature or player
  local spell_list = {}
  local spells = copy_table(self.teaches_spells or {})
  local costMod = self:get_cost_modifier(creature)
  
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
          local moneyCost = (self.spell_money_cost_per_level and self.spell_money_cost_per_level*(spell.level or 1) or self.spell_money_cost or 0)
          local favorCost = (self.spell_favor_cost_per_level and self.spell_favor_cost_per_level*(spell.level or 1) or self.spell_favor_cost or 0)
          local reputationCost = (self.spell_reputation_cost_per_level and self.spell_reputation_cost_per_level*(spell.level or 1) or self.spell_reputation_cost or 0)
          local members_only = self.spells_members_only
          local reputation_requirement = (self.spell_reputation_requirement_per_level and self.spell_reputation_requirement_per_level*(spell.level or 1) or self.spell_reputation_requirement or 0)
          spells[#spells+1] = {spell=spellID,moneyCost=moneyCost,favorCost=favorCost,reputationCost=reputationCost,reputation_requirement=reputation_requirement,members_only=members_only}
        end
      end
    end
  end
  
  --Determine which spells are available:
  for _,spellDef in pairs(spells) do
    if not player:has_spell(spellDef.spell,true,true) then
      local spellID = spellDef.spell
      local spell = possibleSpells[spellID]
      local moneyCost = (spellDef.moneyCost or 0)
      moneyCost = moneyCost + round(moneyCost*(costMod/100))
      local favorCost = (spellDef.favorCost or 0)
      local reputationCost = (spellDef.reputationCost or 0)
      local canLearn = true
      local reasonText = nil
      
      if spellDef.members_only and not self.playerMember then
        reasonText = "This ability is only taught to members."
        canLearn = false
      elseif spellDef.reputation_requirement and (creature.reputation[self.id] or 0) < spellDef.reputation_requirement then
        reasonText = "Requires at least " .. spellDef.reputation_requirement .. " reputation to learn this ability."
        canLearn = false
      elseif spellDef.favorCost and (creature.favor[self.id] or 0) < spellDef.favorCost then
        reasonText = "You don't have enough favor to learn this ability."
        canLearn = false
      elseif spellDef.moneyCost and creature.money < moneyCost then
        reasonText = "You don't have enough money to learn this ability."
        canLearn = false
      elseif spellDef.reputationCost and (creature.reputation[self.id] or 0) < reputationCost then
        reasonText = "You don't have enough reputation to learn this skill."
        canLearn = false
      else
        local ret,text = creature:can_learn_spell(spellDef.spell)
        if ret == false then
          reasonText = (text or "You're unable to learn this ability.")
          canLearn = false
        end
      end
      
      spell_list[#spell_list+1] = {spell=spellID,name=spell.name,description=spell.description,canLearn=canLearn,reasonText=reasonText,moneyCost=moneyCost,favorCost=favorCost,reputationCost=reputationCost}
    end
  end
  
  return spell_list
end

---Gets the list of skills the faction can teach a given creature
--@param creature Creature. Optional, defaults to player
--@return Table. A list of possible skills
function Faction:get_teachable_skills(creature)
  creature = creature or player
  local skill_list = {}
  local skills = copy_table(self.teaches_skills or {})
  local costMod = self:get_cost_modifier(creature)
  
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
          skills[#skills+1] = {skill=skillID,moneyCost=self.skill_money_cost,favorCost=self.skill_favor_cost,reputationCost=self.skill_reputation_cost,members_only=self.skills_members_only,reputation_requirement=self.skill_reputation_requirement,max=skill.max}
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
      local moneyCost = (skillDef.moneyCost or 0)*(player_val+1)
      moneyCost = moneyCost + round(moneyCost*(costMod/100))
      local favorCost = (skillDef.favorCost or 0)*(player_val+1)
      local reputationCost = (skillDef.reputationCost or 0)*(player_val+1)
      local canLearn = true
      local reasonText = nil
      
      if skillDef.members_only and not self.playerMember then
        reasonText = "This skill is only taught to members."
        canLearn = false
      elseif skillDef.reputation_requirement and (creature.reputation[self.id] or 0) < skillDef.reputation_requirement then
        reasonText = "Requires at least " .. skillDef.reputation_requirement .. " reputation to learn this skill."
        canLearn = false
      elseif skillDef.favorCost and (creature.favor[self.id] or 0) < favorCost then
        reasonText = "You don't have enough favor to learn this skill."
        canLearn = false
      elseif skillDef.moneyCost and creature.money < moneyCost then
        reasonText = "You don't have enough money to learn this skill."
        canLearn = false
      elseif skillDef.reputationCost and (creature.reputation[self.id] or 0) < reputationCost then
        reasonText = "You don't have enough reputation to learn this skill."
        canLearn = false
      elseif skill.upgrade_requires then
        local ret,text = skill:upgrade_requires(creature)
        if ret == false then
          reasonText = (text or "You're unable to learn this skill.")
          canLearn = false
        end
      end
      
      skill_list[#skill_list+1] = {skill=skillID,level=player_val+1,name=skill.name,description=skill.description,canLearn=canLearn,reasonText=reasonText,moneyCost=moneyCost,favorCost=favorCost,reputationCost=reputationCost}
    end
  end
  
  return skill_list
end

---Gets the list of services the faction can offer a given creature
--@param creature Creature. Optional, defaults to player
--@return Table. A list of possible services
function Faction:get_available_services(creature)
  creature = creature or player
  local services = {}
  
  if self.offers_services then
    local costMod = self:get_cost_modifier(creature)
    for i,servData in ipairs(self.offers_services) do
      local service_data = {service=servData.service}
      local servID = servData.service
      local service = possibleServices[servID]
      local costText = service:get_cost_text(creature) or servData.costText or service.costText
      if costText == nil then
        local moneyText = (servData.moneyCost and get_money_name(servData.moneyCost+round(servData.moneyCost*(costMod/100))) or nil)
        local favorText = (servData.favorCost and servData.favorCost.. " Favor" or nil)
        if moneyText then
          costText = moneyText .. (favorText and ", " .. favorText)
        else
          costText = favorText
        end
      end
      service_data.name = service.name
      service_data.description = (costText and " (Cost: " .. costText .. ")" or "") .. "\n" .. service.description
      
      local canDo,canDoText = nil,nil
      if servData.members_only and not creature:is_faction_member(self.id) then
        canDoText = "This service is only provided to members."
        canDo = false
      elseif servData.reputation_requirement and (creature.reputation[self.id] or 0) < servData.reputation_requirement then
        canDoText = "Requires at least " .. servData.reputation_requirement .. " reputation for this service to be performed."
        canDo = false
      elseif servData.favorCost and (creature.favor[self.id] or 0) < servData.favorCost then
        canDoText = "You don't have enough favor."
        canDo = false
      elseif servData.moneyCost and creature.money < servData.moneyCost+round(servData.moneyCost*(costMod/100)) then
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

---Gets the list of missions the faction can teach a given creature
--@param creature Creature. Optional, defaults to player
--@param ignoreCurrent. Optional, if true ignore the current_missions table
--@return Table. A list of possible missions
function Faction:get_available_missions(creature,ignoreCurrent)
  creature = creature or player
  local missions = {}
  
  if self.offers_missions then
    for i, mData in ipairs(self.offers_missions) do
      local missionID = mData.mission
      local active = get_mission_status(missionID)
      local mission = possibleMissions[missionID]
      if possibleMissions[missionID] and (not currGame.finishedMissions[missionID] or (mission.repeatable and (not mission.repeat_limit or currGame.finishedMissions[missionID].repetitions < mission.repeat_limit))) and (active or ignoreCurrent or not self.current_missions or in_table(missionID,self.current_missions)) then
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
          if canFinish == false then
            canFinishText = "You are currently on this mission" .. (canFinishText and ". " .. canFinishText or ".")
          end
          mData.disabled = (canFinish == false)
          mData.explainText = canFinishText
        else --Not active mission
          local canDo,canDoText = nil,nil
          if mData.members_only and not self.playerMember then
            canDoText = "This mission is only offered to members."
            canDo = false
          elseif mData.reputation_requirement and creature.reputation[self.id] < mData.reputation_requirement then
            canDoText = "Requires at least " .. mData.reputation_requirement .. " reputation."
            canDo = false
          elseif not mission.requires then
            canDo = true
          else
            canDo,canDoText = mission:requires(creature)
          end
          if canDo == false then
            canDoText = "You're not eligible for this mission" .. (canDoText and ": " .. canDoText or ".")
          end
          mData.disabled = (canDo == false)
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
  
---Gets the list of creatures the faction offers for recruitment
--@param creature Creature. Optional, defaults to player
--@return Table. A list of possible recruits
function Faction:get_recruitable_creatures(creature)
  creature = creature or player
  local recruitments = {}
  
  if self.recruitable_creatures then
    local costMod = self:get_cost_modifier(creature)
    for i,recruitData in ipairs(self.recruitable_creatures) do
      local data = copy_table(recruitData)
      data.index = i
      if not data.name then
        local name
        for cid,amt in pairs(data.creatures) do
          local creatInfo = possibleMonsters[cid]
          name = (name and name .. ", " or "") .. ucfirst(creatInfo.name) .. (amt > 1 and " x " .. amt or "")
        end
        data.name = name
      end
      if not data.description then
        local description
        for cid,amt in pairs(data.creatures) do
          local creatInfo = possibleMonsters[cid]
          description = (description and description .. "\n" or "") .. (count(data.creatures) > 1 and ucfirst(creatInfo.name) .. ": " or "") .. creatInfo.description
        end
        data.description = description
      end
      local moneyText = (data.moneyCost and get_money_name(data.moneyCost+round(data.moneyCost*(costMod/100))) or nil)
      local favorText = (data.favorCost and data.favorCost .. " Favor" or nil)
      local repText = (data.reputationCost and data.reputationCost.. " Reputation" or nil)
      local costText
      if moneyText then
        costText = moneyText
      end
      if favorText then
        costText = (costText and costText .. ", " .. favorText or favorText)
      end
      if repText then
        costText = (costText and costText .. ", " .. repText  or repText)
      end
      if costText then
        data.description = (costText and "Cost: " .. costText .. "" or "") .. (data.description and "\n" .. data.description or "")
      end
      
      local canDo,canDoText = nil,nil
      if data.members_only and not creature:is_faction_member(self.id) then
        canDoText = "Can only be recruited by members."
        canDo = false
      elseif data.reputation_requirement and (creature.reputation[self.id] or 0) < data.reputation_requirement then
        canDoText = "Requires at least " .. data.reputation_requirement .. " reputation to recruit."
        canDo = false
      elseif data.favorCost and (creature.favor[self.id] or 0) < data.favorCost then
        canDoText = "You don't have enough favor."
        canDo = false
      elseif data.moneyCost and creature.money < data.moneyCost+round(data.moneyCost*(costMod/100)) then
        canDoText = "You don't have enough money."
        canDo = false
      elseif data.reputationCost and (creature.reputation[self.id] or 0) < data.reputationCost then
        canDoText = "You don't have enough reputation."
        canDo = false
      elseif data.amount and data.amount < 1 then
        canDoText = "Currently unavailable."
        canDo = false
      end
      data.disabled = (canDo == false)
      data.explainText = canDoText
      if not (data.disabled and data.hide_when_disabled) then
        recruitments[#recruitments+1] = data
      end
    end
  end
  return recruitments
end

---Recruits a creature from a faction
--@param recruitData Table. The recruitment data
--@param creature Creature. The creature doing the recruiting
function Faction:recruit(recruitData,creature)
  creature = creature or player
  --Add creatures
  local dist=1
  for creatID,amt in pairs(recruitData.creatures) do
    for i = 1,amt,1 do
      local newCreat = Creature(creatID,recruitData.level,recruitData.passedTags,recruitData.passedInfo)
      ::placeCreat::
      for x=creature.x-dist,creature.x+dist,1 do
        for y=creature.y-dist,creature.y+dist,1 do
          if newCreat:can_move_to(x,y) then
            currMap:add_creature(newCreat,x,y)
            if not recruitData.noThrall then newCreat:become_thrall(creature) end
            goto creatContinue
          end
        end
      end
      dist = dist+1
      goto placeCreat
      ::creatContinue::
    end
  end
  if recruitData.moneyCost then
    creature:update_money(-recruitData.moneyCost)
  end
  if recruitData.favorCost then
    creature:update_favor(self.id,-recruitData.favorCost)
  end
  if recruitData.reputationCost then
    creature:update_reputation(self.id,-recruitData.reputationCost)
  end
  local baseData = self.recruitable_creatures[recruitData.index]
  if baseData.amount then
    baseData.amount = baseData.amount - 1
  end
end

---Registers an incident as having occured, to be processed by all other creatures who observe it
--@param incidentID String. The incident type
--@param actor Entity. The creature (or other entity) that caused the incident. Optional
--@param target Entity. The entity (or coordinates), that was the target of the incident. Optional
--@param args Table. Other information to use when processing this incident
function Faction:process_incident(incidentID,actor,target,args)
  if possibleFactions[self.id].process_incident then
    local status,r = pcall(possibleFactions[self.id].process_incident,self,incidentID,actor,target,args)
    if status == false then
      output:out("Error in faction " .. self.name .. " process_incident code: " .. r)
      print("Error in faction " .. self.name .. " process_incident code: " .. r)
    end
    if r == false then
      return r
    end
  end
  local incidentText = possibleIncidents[incidentID] and possibleIncidents[incidentID].name
  if self.incident_reputation and self.incident_reputation[incidentID] then
    actor:update_reputation(self.id,self.incident_reputation[incidentID],true,incidentText)
  end
end