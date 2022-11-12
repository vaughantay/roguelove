---@classmod Item
Item = Class{}

---Create an instance of the item. Don't call this directly. Called via Item('itemID')
--@param type_name String. The ID of the item.
--@param info Anything. Argument to pass into the item's new() function.
--@param amt Number. The amount of the item to create.
--@param ignoreNewFunc Boolean. Whether to ignore the item's new() function
--@return Item. The item itself.
function Item:init(type_name,info,amt,ignoreNewFunc)
  local data = possibleItems[type_name]
  if not data then
    output:out("Error: Tried to create non-existent item " .. type_name)
    print("Error: Tried to create non-existent item " .. type_name)
    return false
  end
	for key, val in pairs(data) do
    if type(val) ~= "function" then
      self[key] = data[key]
    end
	end
	if not ignoreNewFunc and (possibleItems[type_name].new ~= nil) then
		possibleItems[type_name].new(self,(info or nil))
	end
  self.id = self.id or type_name
	self.baseType = "item"
  self.itemType = self.itemType or "other"
  self.color = copy_table(self.color)
  self.amount = amt or 1
  if data.spells_granted then
    self.spells_granted = {}
    for _,spellID in ipairs(data.spells_granted) do
      self.spells_granted[#self.spells_granted+1] = Spell(spellID)
    end
  end
  if self.image_varieties and not self.image_name then
    self.image_variety = random(1,self.image_varieties)
    self.image_name = self.id .. self.image_variety
    if not images['item' .. self.image_name] then
      self.image_name = nil
    end
  end
	return self
end

---Clones an instance of the item.
--@param type_name String. The ID of the item.
--@param info Anything. Argument to pass into the item's new() function.
--@param amt Number. The amount of the item to create.
--@param ignoreNewFunc Boolean. Whether to ignore the item's new() function
--@return Item. The item itself.
function Item:clone()
  local newItem = Item(self.id,nil,nil,true)
	for key, val in pairs(self) do
    if type(val) ~= "function" and type(val) ~= "table" then
      newItem[key] = self[key]
    elseif type(val) == "table" then
      newItem[key] = copy_table(self[key])
    end
	end
  return newItem
end

---Get the description of the item.
--@param withName Boolean. Whether to also include the name of the item.
--@return String. The description of the item.
function Item:get_description(withName)
	return (withName and self:get_name(true) .. "\n"  or "") .. self.description
end

--Get the extended information of the item. Charges, damage, range, etc.
--@return String. The info text of the item.
function Item:get_info()
	local uses = ""
  if self.charges and not self.hide_charges then
    uses = uses .. (self.charge_name and ucfirst(self.charge_name) or "Charges") .. (self.ammo_name and " (" .. self.ammo_name .. ")" or "") .. ": " .. self.charges .. (self.max_charges and "/" .. self.max_charges or "")
  end
  if self.owner and self.owner.cooldowns and self.owner.cooldowns[self] then
    uses = uses .. "\nYou can't use this item again for another " .. self.owner.cooldowns[self] .. " turns."
  end
	if (self.itemType == "weapon") then
		if self.damage then uses = uses .. "Melee Damage: " .. self.damage .. (self.damage_type and " (" .. self.damage_type .. ")" or "") end
    if self.armor_piercing then uses = uses .. "Armor Piercing: " .. self.armor_piercing end
		if self.accuracy then uses = uses .. "\nAccuracy Modifier: " .. self.accuracy .. "%" end
		if self.critical then uses = uses .. "\nCritical Hit Chance: " .. self.critical .. "%" end
  end
  if self.ranged_attack then
    local attack = rangedAttacks[self.ranged_attack]
    uses = uses .. "\nRanged Attack: " .. attack:get_name() .. " (" .. attack:get_description() .. ")"
    uses = uses .. "\nRanged Accuracy: " .. (attack.accuracy + self:get_ranged_accuracy_modifier()) .. "%"
    if attack.min_range or attack.range then uses = uses .. "\nRange: " .. (attack.min_range and attack.min_range .. " (min)" or "") .. (attack.min_range and attack.range and " - " or "") .. (attack.range and attack.range .. " (max)" or "") end
    if attack.best_distance_min or attack.best_distance_max then uses = uses .. "\nBest Range: " .. (attack.best_distance_min and attack.best_distance_min .. " (min)" or "") .. (attack.best_distance_min and attack.best_distance_max and " - " or "") .. (attack.best_distance_max and attack.best_distance_max .. " (max)" or "") end
  end
  if self.kills then
    uses = uses .. "\nKills: " .. self.kills
  end
  local projectile_id = self.usingAmmo or self.projectile_name or (self.ranged_attack and rangedAttacks[self.ranged_attack].projectile_name)
  if projectile_id and projectiles[projectile_id] then
    local projectile = projectiles[projectile_id]
    uses = uses .. "\n\nProjectile: " .. ucfirst(projectile.name) .. " (" .. projectile.description .. ")"
    local damage = projectile.damage
    if projectile.extra_damage_per_level and self.level then
      damage = damage+(projectile.extra_damage_per_level*self.level)
    end
    damage = damage+self:get_ranged_damage_modifier()
    if projectile.damage then uses = uses .. "\nDamage: " .. damage .. (projectile.damage_type and " (" .. projectile.damage_type .. ")" or "") end
  end
  if self.info then
    uses = uses .. "\n" .. self.info
  end
  local enches = self:get_enchantments()
  if count(enches) > 0 then
    for ench,turns in pairs(enches) do
      local enchantment = enchantments[ench]
      uses = uses .. "\n\n" .. ucfirst(enchantment.name) .. ((enchantment.removal_type and turns ~= -1) and " (" .. turns .. " " .. enchantment.removal_type .. "s remaining)" or "") .. "\n" .. enchantment.description
    end
  end
	return uses
end

---Get the name of the item.
--@param full Boolean. If false, the item will be called "a dagger", if true, the item will be called "Dagger".
--@param amount Number. The number of items in question. (optional)
--@param withLevel Boolean. If true, show the item's level if it has one (optional)
--@return String. The name of the item
function Item:get_name(full,amount,withLevel)
  amount = amount or self.amount or 1
  local prefix = ""
  local suffix = ""
  local levelSuffix = (withLevel and gamesettings.display_item_levels and self.level and " (Level " .. self.level .. ")" or "")
  local levelPrefix = (withLevel and gamesettings.display_item_levels and self.level and "Level " .. self.level .. " " or "")
  if self.enchantments then
    for ench,_ in pairs(self:get_enchantments()) do
      local enchantment = enchantments[ench]
      if enchantment.prefix then
        prefix = prefix .. enchantment.prefix .. " "
      end
      if enchantment.suffix then
        suffix = suffix .. " " .. enchantment.suffix
      end
    end
  end --end enchantment info
	if (full == true) then
		if (self.properName ~= nil) then
			return self.properName .. " (" .. levelPrefix .. prefix .. self.name .. suffix .. ")"
		else
      if self.stacks and amount > 1 then
        if self.pluralName then
          return amount .. " " .. ucfirst(prefix .. self.pluralName .. suffix .. levelSuffix)
        else
          return amount .. " x " .. ucfirst(prefix .. self.name .. suffix .. levelSuffix)
        end
      else
        return ucfirst(prefix .. self.name .. suffix .. levelSuffix)
      end
		end
	elseif (self.properName ~= nil) then
		return self.properName
	else
    if self.stacks and amount > 1 then
      if self.pluralName then
          return amount .. " " .. prefix .. self.pluralName .. suffix .. levelSuffix
        else
          return amount .. " x " .. prefix .. self.name .. suffix .. levelSuffix
        end
    else
      return (vowel(prefix .. self.name) and "an " or "a " ) .. prefix .. self.name .. suffix
    end
	end
end

---Set the item as the thing currently being used to target (so it'll display as targeting in the game UI)
--@param target Entity. The target of the item
--@param user User. The owner and user of the item
--@param skip Boolean. Whether to skip item-specific targetting code and go straight to the generic (optional)
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the item is on a cooldown (optional)
function Item:target(target,user,skip,ignoreCooldowns)
  if not self.usable and not self.throwable then return false end
  local canUse,text = user:can_use_item(self,self.useVerb)
  if canUse == false then return false,text end
  if (not ignoreCooldowns and user.cooldowns[self]) then
    if user == player then output:out("You can't use that item again for another " .. user.cooldowns[self] .. " turns.") end
		return false,"You can't use that item again for another " .. user.cooldowns[self] .. " turns."
  end
  
  if not skip and possibleItems[self.id].target then
    return possibleItems[self.id].target(self,target,user)
  end
  
  if (self.target_type == "self" or self.target_type == "passive") then
		if (self.target_type ~= "passive") then
			return self:use(target,user,ignoreCooldowns)
		end
	else
		action = "targeting"
		actionResult = (self.throwable and rangedAttacks[self.ranged_attack] or self)
    actionItem = self
		if (target) then
			output:setCursor(target.x,target.y,true)
		end
		return false
	end
end

---"Use" the item. Calls the item's use() code.
--@param target Entity. The target of the item's use. Might be another creature, a tile, even the user itself.
--@param user Creature. The creature using the item.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the item is on a cooldown (optional)
--@return Boolean. Whether the use was successful.
function Item:use(target,user,ignoreCooldowns)
  if not self.usable then return false end
  local canUse,text = user:can_use_item(self,self.useVerb)
  if canUse == false then return false,text end
  if (not ignoreCooldowns and user.cooldowns[self]) then
    if user == player then output:out("You can't use that item again for another " .. user.cooldowns[self] .. " turns.") end
		return false,"You can't use that item again for another " .. user.cooldowns[self] .. " turns."
  end
	if possibleItems[self.id].use then
    local status,r = pcall(possibleItems[self.id].use,self,target,user)
    if not status then
      local errtxt = "Error from " .. user:get_name() .. " using item " .. self.name .. ": " .. r
      output:out(errtxt)
      print(errtxt)
      return false
    end
    if r ~= false or r == nil then
      if user == player then update_stat('item_used',self.id) end
      if ((self.cooldown and self.cooldown > 0) or (user ~= player and self.AIcooldown and self.AIcooldown > 0)) and not ignoreCooldowns then 
        user.cooldowns[self] = (user ~= player and self.AIcooldown or self.cooldown)
      end
      if self.consumed then
        player:delete_item(self,1)
      elseif self.charges then
        self.charges = self.charges - 1
      end
    end
    return (status == nil and true or status),r
  end
  --TODO: Generic item use here:
end

---Find out how much damage an item will deal. Defaults to the item's damage value + the wielder's strength, but might be overridden by an item's get_damage() code
--@param target Entity. The target of the item's attack.
--@param wielder Creature. The creature using the item.
--@return Number. The damage the item will deal.
function Item:get_damage(target,wielder)
  if possibleItems[self.id].get_damage then
    return possibleItems[self.id].get_damage(self,target,wielder)
  end
  local dmg = (self.damage or 0)
  local bonus = .01*self:get_enchantment_bonus('damage_percent')
  dmg = dmg * math.ceil(bonus > 0 and bonus or 1)
  
  return dmg + self:get_enchantment_bonus('damage') + (wielder:get_stat('strength'))
end

---Find out how much extra damage an item will deal due to enchantments
--@param target Entity. The target of the item's attack.
--@param wielder Creature. The creature using the item.
--@param dmg Number. The base damage being done to the target
--@return Table. A table with values of the extra damage the item will deal.
function Item:get_extra_damage(target,wielder,dmg)
  local extradmg = {}
  
  for e,_ in pairs(self:get_enchantments()) do
    local ench = enchantments[e]
    if ench.extra_damage then
      local ed = ench.extra_damage
      local apply = true
      if ed.only_creature_types then
        apply = false
        for _,ctype in ipairs(ed.only_creature_types) do
          if target:is_type(ctype) then
            apply = true
            break
          end
        end --end creature type for
      end --end if only creature types
      if ed.safe_creature_types and apply then
        for _,ctype in ipairs(ed.safe_creature_types) do
          if target:is_type(ctype) then
            apply = false
            break
          end
        end --end creature type for
      end --end if safe creature types
      if apply == true then
        local dmg = tweak((ed.damage or 0)+math.ceil((ed.damage_percent or 0)/100*dmg))
        dmg = target:damage(dmg,wielder,ed.damage_type,ed.armor_piercing,nil,self)
        extradmg[ed.damage_type] = extradmg[ed.damage_type] or 0 + dmg
      end
    end --end if it has an extra damage flag
  end --end enchantment for
  return extradmg
end

---Attack another entity.
--@param target Entity. The creature (or feature) they're attacking
--@param wielder Creature. The creature attacking with the item.
--@param forceHit Boolean. Whether to force the attack instead of rolling for it. (optional)
--@param ignore_callbacks Boolean. Whether to ignore any of the callbacks involved with attacking (optional)
--@param forceBasic Boolean. Whether to ignore the weapon's attacked_with and attack_hits code and just do a basic attack. (optional)
--@return Number. How much damage (if any) was done
function Item:attack(target,wielder,forceHit,ignore_callbacks,forceBasic)
  local txt = ""
  self:decrease_all_enchantments('attack') --decrease the turns left for any enchantments that decrease on attack
  if not forceBasic and possibleItems[self.id].attacked_with then
    local result, damage, text = possibleItems[self.id].attacked_with(self,target,wielder)
    if result == false then
      if text then output:out(text) end
      return damage
    end
    if text then txt = txt .. text end
  end
  
  --Basic attack:
  if target.baseType == "feature" and wielder:touching(target) then
    return target:damage(self:get_damage(target,wielder),wielder,self.damage_type)
	elseif wielder:touching(target) and (ignore_callbacks or wielder:callbacks('attacks',target) and target:callbacks('attacked',self)) then
    local result,dmg="miss",0
    if possibleItems[self.id].calc_attack then
      result,dmg = possibleItems[self.id].calc_attack(self,target,wielder)
    else
      result,dmg = calc_attack(wielder,target,nil,self)
    end
    if forceHit == true then result = 'hit' end
		local hitConditions = self:get_hit_conditions()
		txt = txt .. (string.len(txt) > 0 and " " or "") .. ucfirst(wielder:get_name()) .. " attacks " .. target:get_name() .. " with " .. self:get_name() .. ". "

		if (result == "miss") then
			txt = txt .. ucfirst(wielder:get_pronoun('n')) .. " misses."
      dmg = 0
      if player:can_see_tile(self.x,self.y) or player:can_see_tile(target.x,target.y) and player:does_notice(wielder) and player:does_notice(target) then
        output:out(txt)
      end
      for ench,_ in pairs(self:get_enchantments()) do
        if enchantments[ench].after_miss then
          enchantments[ench]:after_miss(self,wielder,target,dmg)
        end
      end --end enchantment after_miss for
		else --if it's a hit
      if not forceBasic and possibleItems[self.id].attack_hits then
        local ret = possibleItems[self.id].attack_hits(self,target,wielder,dmg,result)
        if ret ~= false then
          --TODO: Test if extra daamge and after_damage work for items with custom attack_hits code
          --Add extra damage
          local txt = nil
          local loopcount = 1
          local dtypes = self:get_extra_damage(target,wielder,dmg)
          local dcount = count(dtypes)
          for dtype,amt in pairs(dtypes) do
            if loopcount == 1 and dcount == 1 then
              txt = ucfirst(self:get_name()) .. " deals "
            elseif loopcount == dcount then
              txt = txt .. ", and "
            else
              txt = txt .. ", "
            end
            txt = txt .. amt .. " " .. dtype .. " damage"
          end
          txt = txt .. " to " .. target:get_name() .. "."
          output:out(txt)
          if possibleItems[self.id].after_damage then
            possibleItems[self.id].after_damage(self,target,wielder,dmg)
          end
          for ench,_ in pairs(self:get_enchantments()) do
            if enchantments[ench].after_damage then
              enchantments[ench]:after_damage(self,wielder,target,dmg)
            end
          end --end enchantment after_damage for
        end
        return ret
      end
			if (result == "critical") then txt = txt .. "CRITICAL HIT! " end
      local bool,ret = wielder:callbacks('calc_damage',target,dmg)
      if (bool ~= false) and #ret > 0 then --handle possible returned damage values
        local count = 0
        local amt = 0
        for _,val in pairs(ret) do --add up all returned damage values
          if type(val) == "number" then count = count + 1 amt = amt + val end
        end
        if count > 0 then dmg = math.ceil(amt/count) end --final damage is average of all returned damage values
      end
			dmg = target:damage(dmg,wielder,self.damage_type,self:get_armor_piercing(wielder),nil,self)
			if dmg > 0 then
        txt = txt .. ucfirst(wielder:get_pronoun('n')) .. " hits " .. target:get_pronoun('o') .. " for " .. dmg .. (self.damage_type and " " .. self.damage_type or "") .. " damage"
        --Add extra damage
        local loopcount = 1
        local dtypes = self:get_extra_damage(target,wielder,dmg)
        local dcount = count(dtypes)
        for dtype,amt in pairs(dtypes) do
          if loopcount == 1 and dcount == 1 then
            txt = txt .. " and "
          elseif loopcount == dcount then
            txt = txt .. ", and "
          else
            txt = txt .. ", "
          end
          txt = txt .. amt .. " " .. dtype .. " damage"
        end
        txt = txt .. "."
      else
        txt = txt .. ucfirst(wielder:get_pronoun('n')) .. " hits " .. target:get_pronoun('o') .. " for no damage."
      end
      local xMod,yMod = get_unit_vector(wielder.x,wielder.y,target.x,target.y)
      target.xMod,target.yMod = target.xMod+(xMod*5),target.yMod+(yMod*5)
      if target.moveTween then
        Timer.cancel(target.moveTween)
      end
      target.moveTween = tween(.1,target,{xMod=0,yMod=0},'linear',function() target.doneMoving = true end)
      if player:can_see_tile(wielder.x,wielder.y) or player:can_see_tile(target.x,target.y) and player:does_notice(wielder) and player:does_notice(target) then
        output:out(txt)
      end
      if possibleItems[self.id].after_damage then
        possibleItems[self.id].after_damage(self,target,wielder,dmg)
      end
      for ench,_ in pairs(self:get_enchantments()) do
        if enchantments[ench].after_damage then
          enchantments[ench]:after_damage(self,wielder,target,dmg)
        end
      end --end enchantment after_damage for
			wielder:callbacks('damages',target,dmg)
      --Handle conditions:
			for _, condition in pairs (hitConditions) do
        local targetNum = (result == "critical" and condition.crit_chance or (condition.hit_chance or 0)) --If a critical, use critical chance, defaulting to regular chance. If it's a critical-only condition, regular chance defaults to 0
				if (random(1,100) < targetNum) then
          local turns = nil
          if result == "critical" then
            turns = (condition.crit_minTurns and condition.crit_maxTurns and random(condition.crit_minTurns,condition.crit_maxTurns) or (condition.critTurns and tweak(condition.critTurns) or nil))
          end
          if not turns then
            turns = ((condition.minTurns and condition.maxTurns and random(condition.minTurns,condition.maxTurns)) or tweak(condition.turns or 0))
          end
					target:give_condition(condition.condition,turns,wielder)
				end -- end condition chance
			end	-- end condition forloop
      self:decrease_all_enchantments('hit') --decrease the turns left for any enchantments that decrease on hit
		end -- end hit if
		return dmg
	else -- if not touching target
		return false
	end
end

---Reload an item.
--@param possessor Creature. The creature using the item.
--@return Boolean. Whether the reload was successful.
function Item:reload(possessor)
  if self.max_charges and self.charges >= self.max_charges then
    return false,ucfirst(self:get_name() .. " is already fully loaded.")
  end
  if self.charges > 1 and self.usingAmmo then
    local it,id,amt = possessor:has_item(self.usingAmmo,nil,self.projectile_enchantments)
    amt = math.min((amt or 0),self.max_charges - self.charges) --don't reload more than the item can hold
    if amt > 0 then
      self.charges = self.charges + amt
      possessor:delete_item(it,amt)
      if player:can_sense_creature(possessor) then
        output:out(possessor:get_name() .. " reloads " .. self:get_name() .. " with " .. it:get_name(false,amt) .. ".")
        output:sound(self.recharge_sound or self.id .. "_recharge")
      end
      return true,"You reload " .. self:get_name() .. " with " .. it:get_name(false,amt) .. "."
    else
      if possessor == player then output:out("You don't have any more of the specific type of ammo that is loaded in" .. self:get_name() .. ".") end
      return false,"You don't have any more of the specific type of ammo that is loaded in" .. self:get_name() .. "."
    end
  else --not using specific ammo, or empty
    --First use whatever's equipped:
    local usedAmmo = nil
    if possessor.equipment.ammo and #possessor.equipment.ammo > 0 then
      for _,ammo in ipairs(possessor.equipment.ammo) do
        if ammo.ammoType == self.usesAmmo then
          usedAmmo = ammo
          break
        end
      end
    end
    --if there's not a usable ammo equipped, select a random type from the inventory, with preference to ammo types the player is holding enough of to reload
    if not usedAmmo then 
      local ammoTypes = {}
      for id,it in ipairs(possessor.inventory) do
        if it.ammoType == self.usesAmmo then
          ammoTypes[#ammoTypes+1] = it
        end --end ammotype match
      end --end inventory for
      --Do you even have any ammo that matches?
      if #ammoTypes < 1 then
        if possessor == player then output:out("You don't have any more ammo for " .. self:get_name() .. ".") end
        return false,"You don't have any more ammo for " .. self:get_name() .. "."
      end
      --If you do have ammo, use it:
      ammoTypes = shuffle(ammoTypes) --do this so it picks a random one
      usedAmmo = ammoTypes[random(1,#ammoTypes)] --pick a random one at first, not paying attention to the amount the possessor has
      for _,ammo in ipairs(ammoTypes) do --loop through and pick the first one you see that fills the item to full
        if (ammo.amount or 1) >= (self.max_charges - self.charges) then --if 
          usedAmmo = ammo
          break
        end
      end
    end
    --Now actually do the reloading, with whatever ammo you've decided on:
    local amt = math.min((usedAmmo.amount or 1),self.max_charges - self.charges) --don't reload more than the item can hold
    self.charges = self.charges + amt
    possessor:delete_item(usedAmmo,amt)
    self.usingAmmo = usedAmmo.id
    self.ammo_name = usedAmmo:get_name(false,1)
    self.projectile_name = usedAmmo.projectile_name
    self.projectile_enchantments = usedAmmo.enchantments
    if player:can_sense_creature(possessor) then
      output:out(possessor:get_name() .. " reloads " .. self:get_name() .. " with " .. usedAmmo:get_name(false,amt) .. ".")
      output:sound(self.recharge_sound)
    end
    return true,"You reload " .. self:get_name() .. " with " .. usedAmmo:get_name(false,amt) .. "."
  end --end if using specific ammo
end

---Determines if another item is the same as this item
--@param item Item. The item to check
--@return Boolean. Whether or not the items are the same
function Item:matches(item)
  if self.id == item.id and self.level == item.level and (not self.sortBy or (self[self.sortBy] == item[self.sortBy])) then
    local matchEnch = true
    --Compare enchantments:
    if (self.enchantments and count(self.enchantments) or 0) == (item.enchantments and count(item.enchantments) or 0) then
      for ench,turns in pairs(self.enchantments or {}) do
        if item.enchantments[ench] ~= turns then
          matchEnch = false
          break
        end
      end --end enchantment for
    else --if the number of enchantments doesn't match, obviously the enchantments themselves won't match
      matchEnch = false
    end
    
    if matchEnch == true then
      return true
    end
  end
  return false
end

---Determine if an item qualifies for a particular enchantment
--@param enchantment Text. The enchantment ID
--@param permanent Boolean. Whether the enchantment has to qualify as a permanent enchantment (optional)
--@return Boolean. Whether or not the item qualifies for the enchantment
function Item:qualifies_for_enchantment(eid,permanent)
  if self.noEnchantments then return false end
  local enchantment = enchantments[eid]
  
  if permanent and enchantment.neverPermanent then
    return false
  end
  
  if enchantment.itemType and (self.itemType ~= enchantment.itemType or (enchantment.subType and self.subType ~= enchantment.subType)) then
    return false
  elseif enchantment.itemTypes then
    local ok = false
    for _,itype in pairs(enchantment.itemTypes) do
      if self.itemType == itype then
        ok = true
        break
      end
    end --end item type for
    if not ok then
      return false
    end
  end
  if enchantment.requires_tags then
    for _,tag in ipairs(enchantment.requires_tags) do
      if not self:has_tag(tag) then
        return false
      end --end if self:has_tag
    end --end tag for
  end --end requires_tags if
  return true
end

---Get a list of all possible enchantments the item could have
--@param permanent Boolean. Whether the enchantment has to qualify as a permanent enchantment (optional)
--@return Table. A list of all enchantment IDs
function Item:get_possible_enchantments(permanent)
  if self.noEnchantments then return {} end
  local possibles = {}
  for eid,ench in pairs(enchantments) do
    if not ench.specialOnly and self:qualifies_for_enchantment(eid,permanent) then
      possibles[#possibles+1] = eid
    end
  end
  return possibles
end

---Apply an enchantment to an item
--@param enchantment Text. The enchantment ID
--@param turns Number. The number of turns to apply the enchantment, if applicable. What "turns" refers to will vary by enchantment, and some are always permanent, and so this number will do nothing. Add a -1 to make force this enchantment to be permanent.
function Item:apply_enchantment(enchantment,turns)
  turns = turns or 1
  if not self.enchantments then self.enchantments = {} end
  local currEnch = self.enchantments[enchantment]
  if currEnch == -1 or turns == -1 then --permanent enchantments are always permanent
    self.enchantments[enchantment] = -1
  elseif currEnch then --if you currently have this enchantment, add turns
    self.enchantments[enchantment] = currEnch+turns
  else --if you don't currently have this enchantment, set it to the passed turns value
    self.enchantments[enchantment] = turns
  end
end

---Remove an enchantment from an item
--@param enchantment Text. The ID of the enchantment
function Item:remove_enchantment(enchantment)
  self.enchantments[enchantment] = nil
end

---Decrease the amount of enchantment on an item
--@param removal_type Text. The removal type of the enchantment
function Item:decrease_all_enchantments(removal_type)
  for ench,turns in pairs(self:get_enchantments()) do
    if turns ~= -1 and enchantments[ench].removal_type == removal_type then
      turns = turns - 1
      if turns > 0 then
        self.enchantments[ench] = turns
      else
        self:remove_enchantment(ench)
      end
    end
  end
end

---Return a list of all enchantments currently applied to an item
--@return Table. The list of enchantments
function Item:get_enchantments()
  return self.enchantments or {}
end

---Returns the total value of the bonuses of a given type provided by enchantments.
--@param bonusType Text. The bonus type to look at
--@return Number. The bonus
function Item:get_enchantment_bonus(bonusType)
  local total = 0
  for e,_ in pairs(self:get_enchantments()) do
    local enchantment = enchantments[e]
    if enchantment.bonuses and enchantment.bonuses[bonusType] then
      total = total + enchantment.bonuses[bonusType]
    end --end if it has the right bonus
  end --end enchantment for
  return total
end

---Check what hit conditions an item can inflict
--@return Table. The list of hit conditions
function Item:get_hit_conditions()
  local cons = self.hit_conditions or {}
	for e,_ in pairs(self:get_enchantments()) do
    local ench = enchantments[e]
    if ench.hit_conditions then
      for _,con in ipairs(ench.hit_conditions) do
        local already = false
        for i, c in ipairs(cons) do --check current conditions, and if we already have this condition, use the maximum values between the condition we have and the condition applied by the enchantment
          if c.condition == con.condition then --c is the current condition, con is the new condition
            already = true
            c.minTurns = math.max(c.minTurns or 0,con.minTurns or 0)
            c.maxTurns = math.max(c.maxTurns or 0,con.maxTurns or 0)
            c.turns = math.max(c.turns or 0,con.turns or 0)
            if c.minTurns == 0 then c.minTurns = nil end
            if c.maxTurns == 0 then c.maxTurns = nil end
            if c.turns == 0 then c.turns = nil end
            c.chance = math.max(c.chance,con.chance)
          end
        end --end loopthrough of own conditions
        if not already then
          cons[#cons+1] = con
        end
      end --end ehcnatment's conditions loop
    end --end if the enchantment has hit conditions
  end --end enchantment loop
  return cons
end

---Checks the armor-piercing quality of a weapon.
--@param wielder Creature. The creature wielding the weapon.
--@return Number. The armor piercing value.
function Item:get_armor_piercing(wielder)
	return (self.armor_piercing or 0) + (wielder and wielder:get_bonus('armor_piercing') or 0)
end

---Returns the accuracy (modifier to the hit roll) of a weapon.
--@return Number. The accuracy of the weapon.
function Item:get_accuracy()
  return (self.accuracy or 0)+self:get_enchantment_bonus('hit_chance')
end

---Returns the ranged accuracy (modifier to the hit roll) of a weapon.
--@return Number. The accuracy of the weapon.
function Item:get_ranged_accuracy_modifier()
  return (self.ranged_accuracy_modifier or 0)+self:get_enchantment_bonus('ranged_accuracy_modifier')
end

---Returns the ranged accuracy (modifier to the hit roll) of a weapon.
--@return Number. The accuracy of the weapon.
function Item:get_ranged_damage_modifier()
  return (self.ranged_damage_modifier or 0)+self:get_enchantment_bonus('ranged_damage_modifier')
end

---Checks the critical chance of a weapon.
--@return Number. The crit chance of the weapon.
function Item:get_critical_chance()
  return (self.critical_chance or 0)+self:get_enchantment_bonus('critical_chance')
end

---Checks the value of an item
--@return Number. The value of the item
function Item:get_value()
  if not self.value then return 0 end
  return self.value+self:get_enchantment_bonus('value')
end

---Checks if an item has a descriptive tag.
--@param tag String. The tag to check for
--@param ignore_enchantments Boolean. Whether to ignore looking at enchantments' tags.
--@return Boolean. Whether or not it has the tag.
function Item:has_tag(tag,ignore_enchantments)
  if self.tags and in_table(tag,self.tags) then
    return true
  end
  if not ignore_enchantments then
    for e,_ in pairs(self:get_enchantments()) do
      local enchantment = enchantments[e]
      if enchantment.tags and in_table(tag,enchantment.tags) then
        return true
      end --end if it has the right bonus
    end --end enchantment for
  end
  return false
end

---Add a tag to an item
--@param tag String. The tag to add
function Item:add_tag(tag)
  if not self.tags then
    self.tags = {tag}
  elseif not in_table(tag,self.tags) then
    self.tags[#self.tags+1] = tag
  end
  return
end

---Add multiple tags to an item
--@param tags Table. The tags to add
function Item:add_tags(tags)
  for _,tag in pairs(tags) do
    self:add_tag(tag)
  end
end

---Delete an item
function Item:delete(map)
  if self.owner then
    return self.owner:delete_item(self)
  end
  map = currMap
  for id,f in pairs(map.contents[self.x][self.y]) do
    if f == self or id == self then
      map.contents[self.x][self.y][id] = nil
    end --end if
  end --end for
  if self.castsLight then map.lights[self] = nil end
end

---Increase an items level
function Item:level_up()
  if self.stats_per_level or self.bonuses_per_level then
    self.level = self.level+1
    if self.stats_per_level then
      for stat_id,value in pairs(self.stats_per_level) do
        self[stat_id] = (self[stat_id] or 0)+value
      end
    end
    if self.bonuses_per_level then
      for bonus_id,value in pairs(self.bonuses_per_level) do
        if not self.bonuses then self.bonuses = {} end
        self.bonuses[bonus_id] = (self.bonuses[bonus_id] or 0) + value
      end
    end
  end
end