---@classmod Item
Item = Class{}

---Create an instance of the item. Don't call this directly. Called via Item('itemID')
--@param itemID String. The ID of the item.
--@param tags Table. A table of tags to pass to the item's new() function
--@param info Anything. Argument to pass into the item's new() function.
--@param ignoreNewFunc Boolean. Whether to ignore the item's new() function
--@return Item. The item itself.
function Item:init(itemID,tags,info,ignoreNewFunc)
  local data = possibleItems[itemID]
  if not data then
    output:out("Error: Tried to create non-existent item " .. itemID)
    print("Error: Tried to create non-existent item " .. itemID)
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
  self.id = self.id or itemID
	self.baseType = "item"
  self.types = self.types or {}
  self.category = self.category or "other"
  self.amount = self.amount or 1
  if self.max_charges then
    self.charges = self.charges or self.max_charges or 0
  end
  if not ignoreNewFunc and (possibleItems[itemID].new ~= nil) then
    local status,r = pcall(possibleItems[itemID].new,self,tags,info)
    if status == false then
      output:out("Error in item " .. itemID .. " new code: " .. r)
      print("Error in item " .. itemID .. " new code: " .. r)
    end
	end
  if data.spells_granted then
    self.spells_granted = {}
    for _,spellID in ipairs(data.spells_granted) do
      local newSpell = Spell(spellID)
      newSpell.from_item = self
      self.spells_granted[#self.spells_granted+1] = newSpell
      if self.charges and newSpell.charges then
        newSpell.charges = self.charges
        if self.max_charges then
          newSpell.max_charges = self.max_charges
        end
      end
    end
  end
  if self.image_varieties and not self.image_name then
    self.image_variety = random(1,self.image_varieties)
    self.image_name = (self.image_base or self.id) .. self.image_variety
  end
	return self
end

---Duplicates an instance of the item.
--@return Item. The item itself.
function Item:duplicate()
  local newItem = Item(self.id,nil,nil,true)
	for key, val in pairs(self) do
    if type(val) ~= "function" and type(val) ~= "table" then
      newItem[key] = self[key]
    elseif type(val) == "table" then
      if val.baseType then --if the value is an entity of some kind, don't create a copy, just use the same entity
        newItem[key] = self[key]
      else
        newItem[key] = copy_table(self[key])
      end
    end
	end
  return newItem
end

---Get the description of the item.
--@param withName Boolean. Whether to also include the name of the item.
--@return String. The description of the item.
function Item:get_description(withName)
	return (withName and self:get_name(true) .. "\n"  or "") .. (not self:is_identified() and self.unidentified_description or self.description)
end

--Get the extended information of the item. Charges, damage, range, etc.
--@return String. The info text of the item.
function Item:get_info()
  if not self:is_identified() then return "Its properties are unknown." end
	local uses = ""
  if self.mission then
    uses = uses .. "Important item for a mission" .. (possibleMissions[self.mission] and ": " .. possibleMissions[self.mission].name or ".")
  end
  if self.equippable then
    local equipText = "Can be equipped"
    if self.equipSlot then
      local equipSize = self.equipSize or 1
      equipText = equipText .. " in the \"" .. ucfirst(self.equipSlot) .. "\" equipment slot" .. (equipSize > 1 and " (requires " .. equipSize .. " spaces)" or "") .. "."
    end
    local impressions = self:get_impressions()
    if count(impressions) > 0 then
      local i =1
      equipText = equipText .. "\nYou will give the " .. (count(impressions) > 1 and "impressions " or "impression ")
      for _,imp in pairs(impressions) do
        equipText = equipText .. (i > 1 and i == count(impressions) and " and " or "") .. "\"" .. ucfirst(imp) .. (count(impressions) > 2 and i ~= count(impressions) and "," or "") .. "\""
        i = i+1
      end
      equipText = equipText .. " if it's equipped."
    end
    uses = uses .. "\n" .. equipText
  end
  if self.kills then
    uses = uses .. "\nKills: " .. self.kills
  end
  if self.charges and not self.hide_charges then
    uses = uses .. "\n" .. (self.charge_name and ucfirst(self.charge_name) or (self.ammo_name and "Current Ammo" or "Charges")) .. (self.ammo_name and " (" .. self.ammo_name .. ")" or "") .. ": " .. self.charges .. (self.max_charges and "/" .. self.max_charges or "")
  end
  if self.possessor and self.possessor.cooldowns and self.possessor.cooldowns[self] then
    uses = uses .. "\nYou can't use this item again for another " .. self.possessor.cooldowns[self] .. " turns."
  end
	if self.melee_attack then
    local damage = self:get_damage(self.possessor)
    local base_damage = self:get_damage()
    local ap = self:get_armor_piercing()
    local accuracy = self:get_accuracy()
    local crit = self:get_critical_chance()
    
    uses = uses .. "\nMelee Damage: " .. damage .. (self.damage_type and " (" .. self.damage_type .. ")" or "") .. (base_damage ~= damage and ' (' .. base_damage .. ' base)' or "")
    
    if ap > 0 then uses = uses .. "\nArmor Piercing: " .. ap end
		if accuracy > 0 then uses = uses .. "\nAccuracy Modifier: " .. accuracy .. "%" end
		if crit > 0 then uses = uses .. "\nCritical Hit Chance: " .. crit .. "%" end
  end
  if self.ranged_attack and rangedAttacks[self.ranged_attack] then
    local attack = rangedAttacks[self.ranged_attack]
    uses = uses .. "\n\nRanged Attack: " .. attack:get_name() .. " (" .. attack:get_description() .. ")"
    uses = uses .. "\nRanged Accuracy: " .. (attack.accuracy + self:get_ranged_accuracy()) .. "%"
    if attack.min_range or attack.range then uses = uses .. "\nRange: " .. (attack.min_range and attack.min_range .. " (min)" or "") .. (attack.min_range and attack.range and " - " or "") .. (attack.range and attack.range .. " (max)" or "") end
    if attack.best_distance_min or attack.best_distance_max then uses = uses .. "\nBest Range: " .. (attack.best_distance_min and attack.best_distance_min .. " (min)" or "") .. (attack.best_distance_min and attack.best_distance_max and " - " or "") .. (attack.best_distance_max and attack.best_distance_max .. " (max)" or "") end
  end
  local projectile_id = self.usingAmmo or self.projectile_name or (self.ranged_attack and rangedAttacks[self.ranged_attack] and rangedAttacks[self.ranged_attack].projectile_name)
  if projectile_id and projectiles[projectile_id] then
    local projectile = projectiles[projectile_id]
    uses = uses .. "\n\nProjectile: " .. ucfirst(projectile.name) .. " (" .. projectile.description .. ")"
    local damage = projectile.damage
    if damage then
      if projectile.extra_damage_per_level and self.level then
        damage = damage+(projectile.extra_damage_per_level*self.level)
      end
      damage = damage+self:get_ranged_damage() + (not self.no_creature_damage and self.possessor and self.possessor.get_ranged_damage and self.possessor:get_ranged_damage(self.ranged_damage_stats) or 0)
      uses = uses .. "\nDamage: " .. damage .. (projectile.damage_type and " (" .. projectile.damage_type .. ")" or "")
    end
  end
  if self.info then
    uses = uses .. "\n" .. self.info
  end
  local slots = self:get_open_enchantment_slots()
  local slotCount = count(slots)
  if slotCount > 0 then
    local slotText = "\n\nOpen Enchantment Slots: "
    local i = 0
    for slot,amt in pairs(slots) do
      i = i + 1
      slotText = slotText .. ucfirst(slot) .. ": " .. amt .. (i < slotCount and ", " or "")
    end
    uses = uses .. slotText
  end
  local enches = self:get_enchantments()
  if count(enches) > 0 then
    for ench,turns in pairs(enches) do
      local enchantment = enchantments[ench]
      uses = uses .. "\n\n" .. ucfirst(enchantment.name) .. ((enchantment.removal_type and turns ~= -1) and " (" .. turns .. " " .. enchantment.removal_type .. "s remaining)" or "") .. (enchantment.enchantment_type and (not gamesettings.hidden_enchantment_slots or not in_table(enchantment.enchantment_type,gamesettings.hidden_enchantment_slots)) and "\nEnchantment Type: " .. ucfirst(enchantment.enchantment_type) or "") .. "\n" .. enchantment.description
      if enchantment.bonuses then
        for bonus,amt in pairs(enchantment.bonuses) do
          if bonus ~= 'value' and bonus ~= 'value_percent' then
            local isPercent = (string.find(bonus,"percent") or string.find(bonus,"chance"))
            uses = uses .. "\n\t* " .. ucfirstall(string.gsub(string.gsub(bonus, "_", " "), "percent", "")) .. (type(amt) == "number" and ": " .. (amt > 0 and "+" or "") .. amt .. (isPercent and "%" or "") or "")
          end
        end
      end
      local ed = enchantment.extra_damage
      if ed then
        local toOnly = ""
        if ed.only_creature_types then
          toOnly = " to "
          for i,ctype in ipairs(ed.only_creature_types) do
            if i ~= 1 and #ed.only_creature_types ~= 2 then
              toOnly = toOnly .. ", "
            end
            if i ~= 1 and i == #ed.only_creature_types then
              toOnly = toOnly .. "and "
            end
            toOnly = toOnly .. (creatureTypes[ctype] and creatureTypes[ctype].name or ctype)
          end
          toOnly = toOnly .. " creatures"
        end
        uses = uses .. "\n\t* " .. (ed.damage and "+" .. ed.damage .. " " or "") .. (ed.damage_percent and (ed.damage and ", " or "") .. "+ " .. ed.damage_percent .. "% ") .. "additional " .. (ed.damage_type and damage_types[ed.damage_type] and damage_types[ed.damage_type].name or ed.damage_type or "") .. " damage" .. toOnly
      end
    end
  end
	return uses
end

---Get the name of the item.
--@param full Boolean. If false, the item will be called "a dagger", if true, the item will be called "Dagger".
--@param amount Number. The number of items in question. (optional)
--@param withLevel Boolean. If true, show the item's level if it has one (optional)
--@param noProper Boolean. If true, don't show the proper name
--@return String. The name of the item
function Item:get_name(full,amount,withLevel,noProper)
  local identified = self:is_identified()
  local name = (not identified and self.unidentified_name or self.name)
  local pname = (not identified and self.unidentified_plural_name or self.pluralName)
  amount = amount or self.amount or 1
  local prefix = ""
  local suffix = ""
  local levelSuffix = (withLevel and gamesettings.display_item_levels and self.level and identified and " (Level " .. self.level .. ")" or "")
  local levelPrefix = (withLevel and gamesettings.display_item_levels and self.level and identified and "Level " .. self.level .. " " or "")
  if self.enchantments and identified then
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
		if not noProper and (identified or self.proper_name_when_unidentified) and self.properName ~= nil then
			return self.properName .. " (" .. levelPrefix .. prefix .. name .. suffix .. ")"
		else
      if self.stacks and amount > 1 then
        if pname then
          return amount .. " " .. ucfirst(prefix .. pname .. suffix .. levelSuffix)
        else
          return amount .. " x " .. ucfirst(prefix .. name .. suffix .. levelSuffix)
        end
      else
        return ucfirst(prefix .. name .. suffix .. levelSuffix)
      end
		end
	elseif not noProper and (identified or self.proper_name_when_unidentified) and self.properName ~= nil then
		return self.properName
	else
    if self.stacks and amount > 1 then
      if pname then
          return amount .. " " .. prefix .. pname .. suffix .. levelSuffix
        else
          return amount .. " x " .. prefix .. name .. suffix .. levelSuffix
        end
    else
      return (self.article and self.article .. " " or (vowel(prefix .. name) and "an " or "a " )) .. prefix .. name .. suffix
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
    local status,r = pcall(possibleItems[self.id].target,self,target,user)
    if status == false then
      output:out("Error in item " .. self.id .. " target code: " .. r)
      print("Error in item " .. self.id .. " target code: " .. r)
    end
    return r
  end
  
  if (self.target_type == "self" or self.target_type == "passive") then
		if (self.target_type ~= "passive") then
			return self:use(target,user,ignoreCooldowns)
		end
	else
		action = "targeting"
		actionResult = (self.throwable and rangedAttacks[self.ranged_attack] or self)
    actionItem = self
    game.targets = {}
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
    if target and #target == 1 and not self.accepts_multiple_targets then target = target[1] end --if being passed only a single target, just set that as the target
    local status,r,other = pcall(possibleItems[self.id].use,self,target,user)
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
        self:delete(nil,1)
      elseif self.charges and not self.no_automatic_charge_decrease then
        self:update_charges(-1)
      end
    end
    --Deactivate applicable spells:
    for id,data in pairs(user.active_spells) do
    if data.spell.deactivate_on_item or data.spell.deactivate_on_all_actions then
      local t = data.target
      local mp = data.ignoreCost
      local cd = data.ignoreCooldowns
      data.spell:finish(t, user, cd, mp)
    end
  end
    return (r == nil and true or r),other
  end
  --TODO: Generic item use here:
end

---Find out how much damage an item will deal. The item's damage value + the wielder's get_damage(), but might be overridden by an item's get_damage() code
--@param wielder Creature. The creature using the item.
--@return Number. The damage the item will deal.
function Item:get_damage(wielder)
  if possibleItems[self.id].get_damage then
    return possibleItems[self.id].get_damage(self,wielder)
  end
  local dmg = (self.damage or 0)
  local bonus = .01*self:get_enchantment_bonus('damage_percent')
  dmg = dmg + math.ceil(dmg * bonus)
  
  return dmg + self:get_enchantment_bonus('damage') + (wielder and wielder.baseType == "creature" and not self.no_creature_damage and wielder:get_damage(self.melee_damage_stats) or 0)
end

---Find out how much extra damage an item will deal due to enchantments
--@param target Entity. The target of the item's attack.
--@param wielder Creature. The creature using the item.
--@param dmg Number. The base damage being done to the target
--@return Table. A table with values of the extra damage the item will deal.
function Item:get_extra_damage(target,wielder)
  local extradmg = {}
  local dmg = self:get_damage(wielder)
  
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
        dmg = target:damage(dmg,wielder,ed.damage_type,ed.armor_piercing,nil,self,ed.ignoreWeakness)
        extradmg[ed.damage_type] = extradmg[ed.damage_type] or 0 + dmg
      end
    end --end if it has an extra damage flag
  end --end enchantment for
  
  if self.extra_damage then
    local ed = self.extra_damage
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
      dmg = target:damage(dmg,wielder,ed.damage_type,ed.armor_piercing,nil,self,ed.ignoreWeakness)
      extradmg[ed.damage_type] = extradmg[ed.damage_type] or 0 + dmg
    end
  end --end if it has an extra damage flag
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
    local dmg = target:damage(self:get_damage(wielder),wielder,self.damage_type)
    self:callbacks('after_damage',target,wielder,dmg)
    self:decrease_all_enchantments('attack') --decrease the turns left for any enchantments that decrease on attack
    wielder:decrease_all_conditions('attack')
    if dmg > 0 then
      wielder:decrease_all_conditions('hit')
      self:decrease_all_enchantments('hit') --decrease the turns left for any enchantments that decrease on hit
    end
    if player:can_see_tile(wielder.x,wielder.y) or player:can_see_tile(target.x,target.y) and player:does_notice(wielder) then
      output:out(wielder:get_name() .. ' attacks ' .. target:get_name() .. " with " .. self:get_name()  .. ", dealing " .. dmg .. " damage.")
    end
    return dmg
	elseif wielder:touching(target) and (ignore_callbacks or wielder:callbacks('attacks',target) and target:callbacks('attacked',wielder)) then
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
      if player:can_see_tile(wielder.x,wielder.y) or player:can_see_tile(target.x,target.y) and player:does_notice(wielder) and player:does_notice(target) then
        output:out(txt)
        local popup = Effect('dmgpopup')
        popup.image_name = "miss"
        popup.symbol=""
        popup.color = {r=0,g=0,b=150,a=150}
        currMap:add_effect(popup,target.x,target.y)
      end
      for ench,_ in pairs(self:get_enchantments()) do
        if enchantments[ench].after_miss then
          enchantments[ench]:after_miss(self,wielder,target,dmg)
        end
      end --end enchantment after_miss for
		else --if it's a hit
      if not forceBasic and possibleItems[self.id].attack_hits then --custom attack hit code:
        local ret = possibleItems[self.id].attack_hits(self,target,wielder,dmg,result)
        if ret ~= false then
          --TODO: Test if extra damage and after_damage work for items with custom attack_hits code
          --Add extra damage
          local dtypes = self:get_extra_damage(target,wielder)
          local dcount = count(dtypes)
          local dTypeCount = (dmg > 0 and 1 or 0)
          if dmg > 0 or dcount > 0 then
            txt = txt .. ucfirst(wielder:get_pronoun('n')) .. " hits " .. target:get_pronoun('o') .. " for"
            if dmg > 0 then
              txt = txt .. " " .. dmg .. (self.damage_type and " " .. self.damage_type or "") .. " damage"
            end
            --Add extra damage
            if dcount > 0 then
              local loopcount = 0
              local dtexts = {}
              for dtype,amt in pairs(dtypes) do
                if amt > 0 then
                  dtexts[#dtexts+1] = amt .. " " .. dtype .. " damage"
                end
              end
              for index,dtext in ipairs(dtexts) do
                if dTypeCount == 0 then
                  txt = txt .. " " .. dtext
                elseif index == #dtexts then
                  txt = txt .. (dTypeCount > 1 and ", and " or " and ") .. dtext
                else
                  txt = txt .. ", " .. dtext
                end
                dTypeCount = dTypeCount+1
              end
            end
          end
          if dTypeCount == 0 then
            txt = txt .. ucfirst(wielder:get_pronoun('n')) .. " hits " .. target:get_pronoun('o') .. " for no damage"
          end
          txt = txt .. "."
          output:out(txt)
          self:callbacks('after_damage',target,wielder,dmg)
        end
        return ret
      end
      --Basic attack hit code:
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
      local dtypes = self:get_extra_damage(target,wielder)
      local dcount = count(dtypes)
      local dTypeCount = (dmg > 0 and 1 or 0)
			if dmg > 0 or dcount > 0 then
        txt = txt .. ucfirst(wielder:get_pronoun('n')) .. " hits " .. target:get_pronoun('o') .. " for"
        if dmg > 0 then
          txt = txt .. " " .. dmg .. (self.damage_type and " " .. self.damage_type or "") .. " damage"
        end
        --Add extra damage
        if dcount > 0 then
          local loopcount = 0
          local dtexts = {}
          for dtype,amt in pairs(dtypes) do
            if amt > 0 then
              dtexts[#dtexts+1] = amt .. " " .. dtype .. " damage"
            end
          end
          for index,dtext in ipairs(dtexts) do
            if dTypeCount == 0 then
              txt = txt .. " " .. dtext
            elseif index == #dtexts then
              txt = txt .. (dTypeCount > 1 and ", and " or " and ") .. dtext
            else
              txt = txt .. ", " .. dtext
            end
            dTypeCount = dTypeCount+1
          end
        end
      end
      if dTypeCount == 0 then
        txt = txt .. ucfirst(wielder:get_pronoun('n')) .. " hits " .. target:get_pronoun('o') .. " for no damage"
      end
      txt = txt .. "."
      --Bump
      local xMod,yMod = get_unit_vector(wielder.x,wielder.y,target.x,target.y)
      target.xMod,target.yMod = target.xMod+(xMod*5),target.yMod+(yMod*5)
      if timers[tostring(target) .. 'moveTween'] then
        Timer.cancel(timers[tostring(target) .. 'moveTween'])
      end
      timers[tostring(target) .. 'moveTween'] = tween(.1,target,{xMod=0,yMod=0},'linear',function() target.doneMoving = true end)
      --Text
      if player:can_see_tile(wielder.x,wielder.y) or player:can_see_tile(target.x,target.y) and player:does_notice(wielder) and player:does_notice(target) then
        output:out(txt)
      end
      --Callbacks
      self:callbacks('after_damage',target,wielder,dmg)
			wielder:callbacks('melee_attack_hits',target,dmg)
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
      wielder:decrease_all_conditions('hit')
		end -- end hit if
    self:decrease_all_enchantments('attack') --decrease the turns left for any enchantments that decrease on attack
    wielder:decrease_all_conditions('attack')
		return dmg
	else -- if not touching target
		return false
	end
end

---Reload an item.
--@param possessor Creature. The creature using the item.
--@param ammo Item. The item to use as ammo
--@return Boolean. Whether the reload was successful.
function Item:reload(possessor,ammo)
  if not self.usesAmmo then
    output:out(ucfirst(self:get_name() .. " is not reloadable."))
    return false,ucfirst(self:get_name() .. " is not reloadable.")
  end
  if self.max_charges and self.max_charges ~= 0 and self.charges >= self.max_charges then
    output:out(ucfirst(self:get_name() .. " is already fully loaded."))
    return false,ucfirst(self:get_name() .. " is already fully loaded.")
  end
  if ammo then --Actual reloading only done if ammo is actually passed
    if ammo.baseType ~= "item" or ammo.ammoType ~= self.usesAmmo then
      if debug then output:out("Tried to load " .. self:get_name() .. " with incorrect ammo " .. ammo:get_name(false) .. ".") end
      return false,"Tried to load " .. self:get_name() .. " with incorrect ammo " .. ammo:get_name(false) .. "."
    end
    --TODO: unload active ammo first
    local ammo_used = 1
    if self.max_charges and self.max_charges > 0 then --only actually load the ammo into the item if it's a reloadable item
      local missing_ammo = self.max_charges - self.charges
      local charges_granted = ammo.charges_granted or 1
      local items_per_turn = self.reload_limit_per_turn
      
      local ammo_used = math.min(ammo.amount,math.ceil(missing_ammo/charges_granted))
      if items_per_turn and items_per_turn < ammo_used then ammo_used = items_per_turn end
      
      local amt = math.min(missing_ammo,ammo_used*charges_granted) --don't reload more than the item can hold
      
      self:update_charges(amt)
      possessor:delete_item(ammo,ammo_used)
    end
    self.usingAmmo = ammo.id
    self.ammo_name = ammo.ammo_name or ammo:get_name(true,1)
    self.projectile_name = ammo.projectile_name
    self.projectile_enchantments = ammo.enchantments
    if player:can_sense_creature(possessor) and self.max_charges and self.max_charges > 0 then
      output:out(possessor:get_name() .. " reloads " .. self:get_name() .. " with " .. ammo:get_name(false,ammo_used) .. ".")
      output:sound(self.recharge_sound or self.id .. "_recharge")
    end
    return true,(self.max_charges and self.max_charges > 0 and "You reload " .. self:get_name() .. " with " .. ammo:get_name(false,ammo_used) .. "." or false)
  elseif self.charges and self.charges > 1 and self.usingAmmo then --If ammo is already loaded, use the same type of ammo you're currently using
    local it,id,amt = possessor:has_item(self.usingAmmo,nil,self.projectile_enchantments)
    if it then
      return self:reload(possessor,it)
    else
      if possessor == player then output:out("You don't have any more of the specific type of ammo that is loaded in" .. self:get_name() .. ".") end
      return false,"You don't have any more of the specific type of ammo that is loaded in" .. self:get_name() .. "."
    end
  else --not using specific ammo, or empty
    --First go for whatever's equipped in the ammo slot:
    local usedAmmo = nil
    if possessor.equipment.ammo and #possessor.equipment.ammo > 0 then
      for _,ammo in ipairs(possessor.equipment.ammo) do
        if ammo.ammoType == self.usesAmmo then
          return self:reload(possessor,ammo)
        end
      end
    end
    --Were we previously using an ammo type? If so then reload with that if it can fully fill the item
     if self.usingAmmo then --if you were previously using a specific type of ammo, prioritize that first
      local it,id,amt = possessor:has_item(self.usingAmmo,nil,self.projectile_enchantments)
      if it and (it.amount or 1) >= (self.max_charges or 1) then
        return self:reload(possessor,it)
      end
    end --end if you have the previous ammo
    
    --Select random ammo from the inventory, with preference to ammo that the player is holding enough of to reload entirely
    local ammoTypes = self:get_possible_ammo(possessor)
    if #ammoTypes < 1 then
      if possessor == player then output:out("You don't have ammo for " .. self:get_name() .. ".") end
      return false,"You don't have ammo for " .. self:get_name() .. "."
    end
    ammoTypes = shuffle(ammoTypes)
    usedAmmo = ammoTypes[random(1,#ammoTypes)] --pick a random one at first
    for _,ammo in ipairs(ammoTypes) do --loop through and pick the first one you see that fills the item to full
      if (ammo.amount or 1) >= (self.max_charges or 1) then
        return self:reload(possessor,ammo)
      end
    end
  end --end ammotype for
end

---Get a list of items that can be used as ammo for this item
--@param possessor Creature. The creature using the item.
--@return Table. A list of items that can be used for ammo.
function Item:get_possible_ammo(possessor)
  local ammoTypes = {}
  for id,it in ipairs(possessor:get_inventory()) do
    if it.ammoType == self.usesAmmo then
      ammoTypes[#ammoTypes+1] = it
    end --end ammotype match
  end --end inventory for
  return ammoTypes
end

---Determines if another item is the same as this item
--@param item Item. The item to check
--@return Boolean. Whether or not the items are the same
function Item:matches(item)
  if self.id == item.id and self.level == item.level and (not self.sortBy or (self[self.sortBy] == item[self.sortBy])) and (not item.properName or not self.properName or item.properName == self.properName) then
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
function Item:qualifies_for_enchantment(eid,permanent,artifactOnly)
  if not self.enchantable then return false end
  local enchantment = enchantments[eid]
  
  if not enchantment or (permanent and enchantment.neverPermanent) or (artifactOnly and enchantment.neverArtifact) then
    return false
  end
  if self.max_enchantments and #self.enchantments >= self.max_enchantments then
    return false
  end
  
  if enchantment.enchantment_type then
    local slots_used = 0
    if self.enchantments then
      for enID,_ in pairs(self.enchantments) do
        local enc = enchantments[enID]
        if enc.enchantment_type == enchantment.enchantment_type then
          slots_used = slots_used+1
        end
      end
    end
    if slots_used >= (self.enchantment_slots and self.enchantment_slots[enchantment.enchantment_type] or 0) then
      return false
    end
  end
  
  if enchantment.item_type and (not self:is_type(enchantment.item_type)) then
    return false
  elseif enchantment.item_types then
    local ok = false
    for _,itype in pairs(enchantment.item_types) do
      if self:is_type(itype) then
        ok = true
        break
      end
    end --end item type for
    if not ok then
      return false
    end
  end
  if enchantment.requires_types then
    for _,itype in ipairs(enchantment.requires_types) do
      if not self:is_type(itype) then
        return false
      end --end if self:is_type
    end --end tag for
  end --end requires_types if
  if enchantment.forbidden_types then
    for _,itype in ipairs(enchantment.forbidden_types) do
      if self:is_type(itype) then
        return false
      end
    end
  end
  if enchantment.requires_tags then
    for _,tag in ipairs(enchantment.requires_tags) do
      if not self:has_tag(tag) then
        return false
      end --end if self:has_tag
    end --end tag for
  end --end requires_tags if
  if enchantment.forbiddenTags then
    for _,tag in ipairs(enchantment.forbiddenTags) do
      if self:has_tag(tag) then
        return false
      end
    end
  end
  if enchantment.forbiddenEnchantments then
    for _,eid in ipairs(enchantment.forbiddenEnchantments) do
      if self.enchantments and self.enchantments[eid] then
        return false
      end
    end
  end
  return true
end

function Item:get_open_enchantment_slots()
  if self.enchantment_slots then
    local slots = self.enchantment_slots
    if self.enchantments then
      for enID,_ in pairs(self.enchantments) do
        local enc = enchantments[enID]
        local slot = enc.enchantment_type
        if slot and slots[slot] then
          slots[slot] = slots[slot]-1
          if slots[slot] < 1 then slots[slot] = nil end
        end
      end
    end
    for slot,openings in pairs(slots) do
      if gamesettings.hidden_enchantment_slots and in_table(slot,gamesettings.hidden_enchantment_slots) then
        slots[slot] = nil
      end
    end
    return slots
  end
end

---Get a list of all possible enchantments the item could have
--@param permanent Boolean. Whether the enchantment has to qualify as a permanent enchantment (optional)
--@param artifactOnly Boolean. Whether to only consider enchantments without the neverArtifact flag
--@param enchantment_type String. The enchantment type to look at (Optional)
--@return Table. A list of all enchantment IDs
function Item:get_possible_enchantments(permanent,artifactOnly,enchantment_type)
  if not self.enchantable then return {} end
  local possibles = {}
  for eid,ench in pairs(enchantments) do
    if (not enchantment_type or ench.enchantment_type == enchantment_type) and not ench.specialOnly and self:qualifies_for_enchantment(eid,permanent,artifactOnly) then
      possibles[#possibles+1] = eid
    end
  end
  return possibles
end

---Apply an enchantment to an item
--@param enchantment Text. The enchantment ID
--@param turns Number. The number of turns to apply the enchantment, if applicable. What "turns" refers to will vary by enchantment, and some are always permanent, and so this number will do nothing. Add a -1 to make force this enchantment to be permanent.
function Item:apply_enchantment(enchantment,turns)
  local enchData = enchantments[enchantment]
  turns = turns or 1
  if enchData then
    if not self.enchantments then self.enchantments = {} end
    local currEnch = self.enchantments[enchantment]
    if currEnch == -1 or turns == -1 then --permanent enchantments are always permanent
      self.enchantments[enchantment] = -1
    elseif currEnch then --if you currently have this enchantment, add turns
      self.enchantments[enchantment] = currEnch+turns
    else --if you don't currently have this enchantment, set it to the passed turns value
      self.enchantments[enchantment] = turns
    end
    if enchData.spells_granted then
      for _,spellID in ipairs(enchData.spells_granted) do
        local already = false
        if self.spells_granted then
          for _,selfspell in ipairs(self.spells_granted) do
            if selfspell.id == spellID then
              already = true
              break
            end
          end
        end
        if not already then
          if not self.spells_granted then self.spells_granted = {} end
          local newSpell = Spell(spellID)
          newSpell.from_item = self
          newSpell.from_enchantment = enchantment
          self.spells_granted[#self.spells_granted+1] = newSpell
        end
      end
    end
  end
end

function Item:has_enchantment(enchantment)
  if not self.enchantments then return false end
  for enchID,turns in pairs(self.enchantments) do
    if enchID == enchantment then return turns end
  end
end

---Remove an enchantment from an item
--@param enchantment Text. The ID of the enchantment
function Item:remove_enchantment(enchantment)
  self.enchantments[enchantment] = nil
  if self.spells_granted then
    for index,spell in pairs(self.spells_granted) do
      if spell.from_enchantment == enchantment then
        remove_from_array(self.spells_granted,spell)
      end
    end
  end
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
--@param permanentOnly Boolean. If true, only look at permanent enchantments
--@return Number. The bonus
function Item:get_enchantment_bonus(bonusType,permanentOnly)
  local total = 0
  for e,turns in pairs(self:get_enchantments()) do
    local enchantment = enchantments[e]
    if enchantment.bonuses and enchantment.bonuses[bonusType] and (turns == -1 or not permanentOnly) then
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
	return (self.armor_piercing or 0) + self:get_enchantment_bonus('armor_piercing') + (wielder and wielder:get_bonus('armor_piercing') or 0)
end

---Returns the accuracy (modifier to the hit roll) of a weapon.
--@return Number. The accuracy of the weapon.
function Item:get_accuracy()
  return (self.accuracy or 0)+self:get_enchantment_bonus('hit_chance')
end

---Returns the ranged accuracy (modifier to the hit roll) of a weapon.
--@return Number. The accuracy of the weapon.
function Item:get_ranged_accuracy()
  return (self.ranged_accuracy or 0)+self:get_enchantment_bonus('ranged_accuracy')
end

---Returns the ranged accuracy (modifier to the hit roll) of a weapon.
--@return Number. The accuracy of the weapon.
function Item:get_ranged_damage()
  local ranged_damage = (self.ranged_damage or 0)
  ranged_damage = ranged_damage + round(ranged_damage * (self:get_enchantment_bonus('ranged_damage_percent')/100)) + self:get_enchantment_bonus('ranged_damage')
  return ranged_damage 
end

---Checks the critical chance of a weapon.
--@return Number. The crit chance of the weapon.
function Item:get_critical_chance()
  return (self.critical_chance or 0)+self:get_enchantment_bonus('critical_chance')
end

---Checks the value of an item
--@return Number. The value of the item
function Item:get_value()
  local base = (self.value or 0)
  return base + round(base*(self:get_enchantment_bonus('value_percent',true)/100)) + self:get_enchantment_bonus('value',true)
end

---Checks the threatvalue of an item
--@return Number. The value of the item
function Item:get_threat()
  local base = (self.threat or 0)
  return base + round(base*(self:get_enchantment_bonus('threat_percent')/100)) + self:get_enchantment_bonus('threat')
end

---Checks the threat_modifier value of an item
--@return Number. The value of the item
function Item:get_threat_modifier()
  local base = (self.threat_modifier or 0)
  return base + round(base*(self:get_enchantment_bonus('threat_modifier_percent')/100)) + self:get_enchantment_bonus('threat_modifier')
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
      if enchantment.applies_tags and in_table(tag,enchantment.applies_tags) then
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
--@param map Map. The map to the delete the item off of (optional, defaults to current map)
--@param amount Number. The amount of the item to delete. If nil, delete it all
function Item:delete(map,amount)
  if self.possessor then
    return self.possessor:delete_item(self,amount)
  end
  map = map or currMap
  if amount and amount < self.amount then
    self.amount = self.amount - amount
    return true
  end
  --If no amount or amount > self.amount, remove it entirely
  for id,f in pairs(map.contents[self.x][self.y]) do
    if f == self or id == self then
      map.contents[self.x][self.y][id] = nil
    end --end if
  end --end for
  if self.castsLight then map.lights[self] = nil end
end

---Increase an item's level
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

---Checks whether an item is identified
function Item:is_identified()
  local ID = self.id .. (self.sortBy and self[self.sortBy] or "")
  if not self.requires_identification or self.identified or currGame.identified_items[ID] then
    return true
  end
  return false
end

---Mark an item as identified
function Item:identify()
  self.identified=true
  if self.identify_all_of_type then
    local ID = self.id .. (self.sortBy and self[self.sortBy] or "")
    currGame.identified_items[ID] = true
  end
end

---Perform an item's cleanup() callback, if applicable.
--@param map Map. The map the item is on
function Item:cleanup(map)
  map = map or currMap
  if possibleItems[self.id].cleanup then return possibleItems[self.id].cleanup(self,map) end
end

---Determines what recipes the item is an ingredient in:
--@param all Boolean. If true, get all recipes, not just known recipes.
function Item:is_ingredient_in(all)
  local recipes = {}
  local tool_recipes = {}
  local done = false
  for _,rid in pairs(player:get_all_possible_recipes()) do
    done = false
    local recipe = possibleRecipes[rid]
    if recipe.ingredients and recipe.ingredients[self.id] and not recipe.results[self.id] then
      local name = recipe.name
      if not name then
        name = ""
        local c=1
        for item,amount in pairs(recipe.results) do
          if c > 1 then name = name .. ", " end
          if amount > 1 then
            name = name .. amount .. " " .. ucfirst(possibleItems[item].pluralName or "x " .. ucfirst(possibleItems[item].name))
          else
            name = name .. ucfirst(possibleItems[item].name)
          end
          c = c + 1
        end
      end
      recipes[#recipes+1] = {id=rid,name=name}
      done = true
    end
    if not done and not recipe.results[self.id] then
      if recipe.ingredient_properties and self.crafting_ingredient_properties then
        for prop,_ in pairs(self.crafting_ingredient_properties) do
          if recipe.ingredient_properties[prop] then
            local typeMatch = false
            if recipe.ingredient_types then
              if self.crafting_ingredient_types then
                for _,itype in pairs(recipe.ingredient_types) do
                  if in_table(itype,self.crafting_ingredient_types) then
                    typeMatch = true
                    break
                  end
                end
              end
            else --if ingredient types aren't set, don't worry about matching
              typeMatch = true
            end
            if typeMatch then
              local name = recipe.name
              if not name then
                name = ""
                local c=1
                for item,amount in pairs(recipe.results) do
                  if c > 1 then name = name .. ", " end
                  if amount > 1 then
                    name = name .. amount .. " " .. ucfirst(possibleItems[item].pluralName or "x " .. ucfirst(possibleItems[item].name))
                  else
                    name = name .. ucfirst(possibleItems[item].name)
                  end
                  c = c + 1
                end
              end
              recipes[#recipes+1] = {id=rid,name=name}
              done = true
            end
          end
        end
      end
    end
    --TODO: tool check
  end
  if count(recipes) > 0 then
    sort_table(recipes,'name')
  end
  return recipes
end

---Split off a new stack of an item
--@param amount Number. The number in the new stack
--@return Item. The new item stack
function Item:splitStack(amount)
  if self.stacks and amount > 0 and amount < self.amount then
    local oldPossessor = self.possessor
    local oldOwner = self.owner
    self.possessor = nil --This is done because item.possessor is the creature who has the item, and Item:duplicate() does a deep copy of all tables, which means it will create a copy of the owner, which owns a copy of the item, which is owned by another copy of the owner which owns another copy of the item etc etc leading to a crash
    self.owner = nil
    local newItem = self:duplicate()
    self.amount = self.amount - amount
    newItem.amount = amount
    newItem.stacks = false --To prevent the new stack from being re-added to the old stack
    if oldOwner then
      self.owner,newItem.owner = oldOwner
    end
    if oldPossessor then
      self.possessor,newItem.possessor = oldPossessor
      oldPossessor:give_item(newItem,true)
    end
    newItem.stacks = true
    return newItem
  end
end

---Returns a list of spells granted to the wearer of this equipment
--@return Table. A list of the spells
function Item:get_spells_granted()
  return (self.spells_granted or {})
end

---Returns the value 
function Item:get_armor(damageType,noBonus,no_all)
  local armor = 0
  if damageType then
    if damage_types[damageType] and damage_types[damageType].no_all then
      no_all = true
    end
  end
  
  if self.armor then
    if not no_all and type(self.armor) == "number" then
      armor = armor + self.armor
    else
      if damageType and self.armor[damageType] then
        armor = armor + self.armor[damageType]
      elseif not no_all and self.armor.all then
        armor = armor + self.armor.all
      end
    end
  end
  
  if not noBonus then
    for _,ench in ipairs(self:get_enchantments()) do
      local enchantment = enchantments[ench]
      if enchantment and enchantment.armor then
        if damageType and enchantment.armor[damageType] then
          armor = armor + enchantment.armor[damageType]
        elseif not no_all and enchantment.armor.all then
          armor = armor + self.armor.all
        end
      end
    end
    local pre_enchant = armor
    if damageType then
      armor = armor + round(pre_enchant*(self:get_enchantment_bonus(damageType .. '_armor_percent')/100)) + self:get_enchantment_bonus(damageType .. '_armor')
    end
    if not no_all then
      armor = armor + round(pre_enchant*(self:get_enchantment_bonus('all_armor_percent')/100)) + self:get_enchantment_bonus('all_armor')
      armor = armor + round(pre_enchant*(self:get_enchantment_bonus('armor_percent')/100)) + self:get_enchantment_bonus('armor')
    end
    if armor > 0 then --only apply armor boost enchantments if the armor type > 0
      armor = armor + round(pre_enchant*(self:get_enchantment_bonus('armor_modifier_percent')/100)) + self:get_enchantment_bonus('armor_modifier')
    end
  end
  
  if armor < 0 then armor = 0 end
  return armor
end

---Returns a list of armor granted to the wearer of this equipment
--@return Table. A list of the armor values
function Item:get_all_armor(noBonus)
  local armor = {}
  
  for dtype,_ in pairs(damage_types) do
    local val = self:get_armor(dtype,noBonus)
    if val ~= 0 then
      armor[dtype] = val
    end
  end
  return armor
end

---Returns a list of shops and factions that will buy an item
function Item:get_buyer_list()
  local options = {}
  for id,faction in pairs(currWorld.factions) do
    if faction.contacted and not faction.hidden then
      local cost = faction:get_buy_cost(self)
      if cost then
        options[#options+1] = {text=faction.name,moneyCost=cost.moneyCost,favorCost=cost.favorCost,reputationCost=cost.reputationCost}
      end
    end
  end --end faction for
  for id,store in pairs(currWorld.stores) do
    if store.contacted then
      local cost = store:get_buy_cost(self)
      if cost then
        options[#options+1] = {text=store.name, moneyCost=cost}
      end
    end
  end --end store for
  if count(options) > 0 then
    sort_table(options,'text')
  end
  return options
end

---Gets the highest cost of known stores/factions that will buy an item
function Item:get_highest_sell_cost()
  local buyers = self:get_buyer_list()
  local bestCost = 0
  local bestBuyer
  local bestFavor = 0
  local bestFavorBuyer
  
  for _,buyerInfo in ipairs(buyers) do
    if buyerInfo.moneyCost and buyerInfo.moneyCost >= bestCost then
      bestCost = buyerInfo.moneyCost
      bestBuyer = buyerInfo.text
    end
    if buyerInfo.favorCost and buyerInfo.favorCost >= bestFavor then
      bestFavor = buyerInfo.favorCost
      bestFavorBuyer = buyerInfo.text
    end
  end
  return bestCost,bestBuyer,bestFavor,bestFavorBuyer
end

---Gets a list of all types a item is
--@param base_only Boolean. If true, don't look at types applied by enchantments
--@return Table. A table of item types
function Item:get_types(base_only)
  if base_only then
    return self.types
  end
  
  local temptypes = {}
  local blockedtypes = {}
  for ench,_ in pairs(self:get_enchantments()) do
    local enchantment = enchantments[ench]
    if enchantment and enchantment.removes_item_types then
      for _,blocked in ipairs(enchantment.removes_item_types) do
        blockedtypes[blocked] = blocked
        temptypes[blocked] = nil
      end
    end
    if enchantment and enchantment.applies_item_types then
      for _,itype in ipairs(enchantment.applies_item_types) do
        if not blockedtypes[itype] then
          temptypes[itype] = itype
        end
      end
    end
  end
  for _,itype in ipairs(self.types) do
    if not blockedtypes[itype] then
      temptypes[itype] = itype
    end
  end
  local itypes = {}
  for _,itype in pairs(temptypes) do
    itypes[#itypes+1] = itype
  end
 
  return itypes
end

---Checks if an item is of a certain type
--@param ctype String. The item type to check for
--@param base_only Boolean. If true, don't look at types applied by enchantments
--@return Boolean. Whether or not the item is that type
function Item:is_type(itype,base_only)
  if base_only then
    if not self.types then return false end
    return in_table(itype,self.types)
  end
  for _,i in pairs(self:get_types()) do
    if i == itype then return true end
  end --end for
  return false
end --end function

---Checks the callbacks of the base item type and any enchantments the item has
--@param callback_type String. The callback type to check.
--@param … Anything. Any info you want to pass to the callback. Each callback type is probably looking for something specific (optional)
--@return Boolean. If any of the callbacks returned true or false.
--@return Table. Any other information that the callbacks might return.
function Item:callbacks(callback_type,...)
  local ret = nil
  if type(possibleItems[self.id][callback_type]) == "function" then
    local status,r,other = pcall(possibleItems[self.id][callback_type],self,unpack({...}))
    if status == false then
        output:out("Error in item " .. self.id .. " callback \"" .. callback_type .. "\": " .. r)
        print("Error in item " .. self.id .. " callback \"" .. callback_type .. "\": " .. r)
      end
		if (r == false) then return false,other end
    ret = other
  end
  for ench,_ in pairs(self:get_enchantments()) do
    if type(enchantments[ench][callback_type]) == "function" then
      local status,r,other = pcall(enchantments[ench][callback_type],enchantments[ench],self,unpack({...}))
      if status == false then
        output:out("Error in enchantment " .. ench .. " callback \"" .. callback_type .. "\": " .. r)
        print("Error in enchantment " .. ench .. " callback \"" .. callback_type .. "\": " .. r)
      end
			if (r == false) then return false end
      if not ret then
        ret = other
      elseif type(ret) == "string" and type(other) == "string" then
        ret = ret .. " " .. other
      else
        ret = other
      end
    end
  end
  return true,ret
end

---Gets potential targets of a item. Uses the item's own get_potential_targets() function if it has one, or defaults to seen creatures if it doesn't and it's a creature-targeting item
--@param user Creature. The caster of the spell
--@param previous_targets Table. The already-targeted targets of the item, if applicable
--@return Table. A list of potential targets
function Item:get_potential_targets(user,previous_targets)
  if possibleItems[self.id].get_potential_targets then
    local status,r = pcall(possibleItems[self.id].get_potential_targets,self,user,previous_targets)
    if status == false then
      output:out("Error in item " .. self.name .. " get_potential_targets code: " .. r)
      print("Error in item " .. self.name .. " get_potential_targets code: " .. r)
    end
    if type(r) ~= "table" then r = {} end
    return r
  end
  local targets = {}
  if self.target_type == "creature" then
    for _,creat in pairs(user:get_seen_creatures()) do
      local dist = ((self.range or self.min_range) and calc_distance(user.x,user.y,creat.x,creat.y) or 0)
      if user:does_notice(creat) and (self.range == nil or calc_distance(user.x,user.y,creat.x,creat.y) <= self.range) and (self.min_range == nil or dist >= self.min_range) then
        targets[#targets+1] = {x=creat.x,y=creat.y}
      end --end range if
    end --end creature for
    if self.can_target_self then
      targets[#targets+1] = {x=user.x,y=user.y}
    end
    return targets
  end --end creature if
  return {}
end

---Changes the amount of charges that an item has
--@param amt The amount to change the charges by
function Item:update_charges(amt)
  if self.charges then
    self.charges = self.charges + amt
    if self.charges < 0 then self.charges = 0
    elseif self.max_charges and self.charges > self.max_charges then self.charges = self.max_charges end
    if self.spells_granted then
      for _,spell in pairs(self.spells_granted) do
        if spell.charges then
          spell.charges = self.charges
        end
      end
    end
  end
end

---Get the items and skills that you will receive from studying an item
function Item:get_study_results(studier)
  local study_results = {}
  if self.study_items then
    study_results.study_items = copy_table(self.study_items)
  end
  if self.study_skills then
    study_results.study_skills = copy_table(self.study_skills)
  end
  if self.study_recipes then
    study_results.study_recipes = copy_table(self.study_recipes)
  end
  if self.arcana then
    study_results.arcana = (type(self.arcana) == "table" and copy_table(self.arcana) or {self.arcana})
  end
  if self.study_passed_tags then
    study_results.study_passed_tags = copy_table(self.study_passed_tags)
  end
  
  for enchID,turns in pairs(self.enchantments or {}) do
    if turns == -1 then --only look at permanent enchantments
      local enchantmentData = enchantments[enchID]
      if enchantmentData.study_items then
        if not study_results.study_items then study_results.study_items = {} end
        for item,amt in pairs(enchantmentData.study_items) do
          study_results.study_items[item] = (study_results.study_items[item] or 0)+amt
        end
      end
      if enchantmentData.study_skills then
        if not study_results.study_skills then study_results.study_skills = {} end
        for skill,amt in pairs(enchantmentData.study_skills) do
          study_results.study_skills[skill] = (study_results.study_skills[skill] or 0)+amt
        end
      end
      if enchantmentData.study_recipes then
        study_results.study_recipes = merge_tables(study_results.study_recipes or {},enchantmentData.study_recipes)
      end
      if enchantmentData.arcana then
        study_results.arcana = merge_tables(study_results.arcana or {},(type(enchantmentData.arcana) == "table" and enchantmentData.arcana or {enchantmentData.arcana}))
      end
      if enchantmentData.study_passed_tags then
        study_results.study_passed_tags = merge_tables(study_results.study_passed_tags or {},enchantmentData.study_passed_tags)
      end
    end
  end --end enchantment for
  
  if study_results.study_recipes then
    local unlearned = {}
    for _,recipeID in ipairs(study_results.study_recipes) do
      if not player.known_recipes[recipeID] then
        unlearned[#unlearned+1] = recipeID
      end
    end
    study_results.study_recipes = (count(unlearned) > 0 and unlearned or nil)
  end
  
  --If arcana is the only entry in the study_results table, don't return it
  if study_results.arcana and count(study_results) == 1 then
    return {}
  end
  
  if study_results.study_items and studier then
    local bonus_perc = studier:get_bonus('study_results_percent')
    if self.types then
      for _,itype in ipairs(self.types) do
        bonus_perc = bonus_perc + studier:get_bonus(itype .. '_study_results_percent')
      end
    end
    for item,amt in pairs(study_results.study_items) do
      if amt > 1 then
        study_results.study_items[item] = math.max(1,round(amt + amt*(bonus_perc/100)))
      end
    end
  end
  
  return study_results
end

---Gets impressions provided when equipping an item.
--@return Table. A list of impressions
function Item:get_impressions()
  local impressions = {}
  
  if self.impressions then
    for _,impression in pairs(self.impressions) do
      impressions[impression] = impression
    end
  end
  
  for enchID,turns in pairs(self.enchantments or {}) do
    local enchantmentData = enchantments[enchID]
    if enchantmentData.impressions then
      for _,impression in pairs(enchantmentData.impressions) do
        impressions[impression] = impression
      end
    end
  end
  
  return impressions
end

---Gets condition type immunities provided when equipping an item.
--@return Table. A list of impressions
function Item:get_condition_type_immunities()
  local immunities = {}
  
  if self.condition_type_immunities then
    for _,immunity in pairs(self.condition_type_immunities) do
      immunities[#immunities+1] = immunity
    end
  end
  
  for enchID,turns in pairs(self.enchantments or {}) do
    local enchantmentData = enchantments[enchID]
    if enchantmentData.condition_type_immunities then
      for _,immunity in pairs(enchantmentData.condition_type_immunities) do
        immunities[#immunities+1] = immunity
      end
    end
  end
  
  return immunities
end