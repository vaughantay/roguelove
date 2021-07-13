---@classmod Faction
Faction = Class{}

---Initiate a faction from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the factions.
--@param data Table. The table of faction data.
--@return self Faction. The faction itself.
function Faction:init(data)
	for key, val in pairs(data) do
		if type(val) ~= "function" then
      self[key] = data[key]
    end
	end
  self.baseType = "faction"
  self.inventory = {}
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
    creature.money = creature.money - spellInfo.moneyCost
  end
  if spellInfo.favorCost then
    creature.favor[self.id] = creature.favor[self.id] - spellInfo.favorCost
  end
  --Teach it, finally:
  creature.spells[#creature.spells+1] = spellID
end

---Generates the faction's store's inventory
function Faction:generate_items()
  --Generate items from list:
  if not self.sells_items then return end
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
      self.inventory[id] = {item=item,favorCost=info.favorCost,moneyCost=info.moneyCost,membersOnly=info.membersOnly,id=id}
    end
  end
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

---Gets a list of the items the faction is selling
--@return Table. The list of items the faction has in stock
function Faction:get_inventory()
  return self.inventory
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
        if item:has_tag(tag) then
          buying[#buying+1]={item=item,favorCost=math.floor(item.value/(self.money_per_favor or 10)),moneyCost=(not self.only_pays_favor and item.value or nil)}
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
  local index = self:get_inventory_index(item)
  if index and self.inventory[index].item.amount ~= -1 then
    self.inventory[index].item.amount = self.inventory[index].item.amount+amt
  end
  creature:delete_item(item,amt)
  creature.favor[self.id] = (creature.favor[self.id] or 0) + totalFavor
  creature.money = creature.money+totalCost
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
  if creature.money >= totalCost and creature.favor[self.id] >= totalFavorCost then
    if amt == totalAmt then
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
      creature.favor[self.id] = (creature.favor[self.id] or 0) - totalFavorCost
      creature.money = creature.money-totalCost
    elseif item.stacks then
      local newItem = item:clone()
      if item.amount ~= -1 then item.amount = item.amount - amt end
      newItem.amount = amt
      creature:give_item(newItem)
      creature.favor[self.id] = (creature.favor[self.id] or 0) - totalFavorCost
      creature.money = creature.money-totalCost
    else
      for i=1,amt,1 do
        local newItem = item:clone()
        newItem.amount = nil
        creature:give_item(newItem)
      end
      if item.amount ~= -1 then item.amount = item.amount - amt end
      creature.favor[self.id] = (creature.favor[self.id] or 0) - totalFavorCost
      creature.money = creature.money-totalCost
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
    if info.item.id == item.id and item.stacks == true and (not item.sortBy or (item[item.sortBy] == info.item[item.sortBy])) then
      return id
    end
  end
end