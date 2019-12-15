Item = Class{}

function Item:init(type_name,info,amt)
  local data = possibleItems[type_name]
	for key, val in pairs(data) do
    if type(val) ~= "function" then
      self[key] = data[key]
    end
	end
	if (possibleItems[type_name].new ~= nil) then 
		possibleItems[type_name].new(self,(info or nil))
	end
  self.id = self.id or type_name
	self.baseType = "item"
  self.itemType = self.itemType or "other"
  self.color = copy_table(self.color)
  if (self.stacks) then
    self.amount = amt or 1
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

function Item:get_description(withName)
	return (withName and self:get_name(true) .. "\n"  or "") .. self.description
end

function Item:get_info()
	local uses = ""
  if self.charges and not self.hide_charges then
    uses = uses .. (self.charge_name and ucfirst(self.charge_name) or "Charges") .. ": " .. self.charges
  end
	if (self.itemType == "weapon") then
		if self.damage then uses = uses .. "Melee Damage: " .. self.damage .. (self.damage_type and " (" .. self.damage_type .. ")" or "") end
    if self.armor_piercing then uses = uses .. "Armor Piercing: " .. self.armor_piercing end
		if self.accuracy then uses = uses .. "\nAccuracy Modifier: " .. self.accuracy .. "%" end
		if self.critical then uses = uses .. "\nCritical Hit Chance: " .. self.critical .. "%" end
  end
  if self.ranged_attack then
    local attack = rangedAttacks[self.ranged_attack]
    uses = uses .. "\nRanged Attack: " .. attack:get_name()
    uses = uses .. "\n" .. attack:get_description()
    uses = uses .. "\nBase Accuracy: " .. attack.accuracy .. "%"
    if attack.min_range or attack.range then uses = uses .. "\nRange: " .. (attack.min_range and attack.min_range .. " (min)" or "") .. (attack.min_range and attack.range and " - " or "") .. (attack.range and attack.range .. " (max)" or "") end
    if attack.best_distance_min or attack.best_distance_max then uses = uses .. "\nBest Range: " .. (attack.best_distance_min and attack.best_distance_min .. " (min)" or "") .. (attack.best_distance_min and attack.best_distance_max and " - " or "") .. (attack.best_distance_max and attack.best_distance_max .. " (max)" or "") end
    uses = uses .. "\n"
  end
  if self.projectile_name then
    local projectile = projectiles[self.projectile_name]
    uses = uses .. "\nProjectile: " .. ucfirst(projectile.name)
    uses = uses .. "\n" .. projectile.description
    uses = uses .. "\nDamage: " .. projectile.damage .. (projectile.damage_type and " (" .. projectile.damage_type .. ")" or "")
  end
  if self.info then
    uses = uses .. "\n" .. self.info
  end
	return uses
end

function Item:get_name(full,amount)
  amount = amount or self.amount or 1
	if (full == true) then
		if (self.properName ~= nil) then
			return self.properName .. " (" .. self.name .. ")"
		else
      if self.stacks and amount > 1 then
        if self.pluralName then
          return amount .. " " .. ucfirst(self.pluralName)
        else
          return amount .. " x " .. ucfirst(self.name)
        end
      else
        return ucfirst(self.name)
      end
		end
	elseif (self.properName ~= nil) then
		return self.properName
	else
    if self.stacks and amount > 1 then
      if self.pluralName then
          return amount .. " " .. self.pluralName
        else
          return amount .. " x " .. self.name
        end
    else
      return (vowel(self.name) and "an " or "a " ) .. self.name
    end
	end
end

function Item:use(target,user)
	if possibleItems[self.id].use then
    return possibleItems[self.id].use(self,target,user)
  end
  --Generic item use here:
end

function Item:get_damage(target,wielder)
  if possibleItems[self.id].get_damage then
    return possibleItems[self.id].get_damage(self,target,wielder)
  end
  return self.damage or 0 + wielder.strength or 0
end

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
    local critConditions = self:get_crit_conditions()
		txt = txt .. (string.len(txt) > 0 and " " or "") .. ucfirst(wielder:get_name()) .. " attacks " .. target:get_name() .. " with " .. self:get_name() .. ". "

		if (result == "miss") then
			txt = txt .. ucfirst(wielder:get_pronoun('n')) .. " misses."
      dmg = 0
		else
      if not forceBasic and possibleItems[self.id].attack_hits then
        return possibleItems[self.id].attack_hits(self,target,wielder,dmg,result)
      end
			if (result == "critical") then txt = txt .. "CRITICAL HIT! " end
			dmg = target:damage(dmg,wielder,self.damage_type,self:get_armor_piercing(wielder))
			if dmg > 0 then txt = txt .. ucfirst(wielder:get_pronoun('n')) .. " hits " .. target:get_pronoun('o') .. " for " .. dmg .. (self.damage_type and " " .. self.damage_type or "") .. " damage."
      else txt = txt .. ucfirst(wielder:get_pronoun('n')) .. " hits " .. target:get_pronoun('o') .. " for no damage." end
      local xMod,yMod = get_unit_vector(wielder.x,wielder.y,target.x,target.y)
      target.xMod,target.yMod = target.xMod+(xMod*5),target.yMod+(yMod*5)
      if target.moveTween then
        Timer.cancel(target.moveTween)
      end
      target.moveTween = tween(.1,target,{xMod=0,yMod=0},'linear',function() target.doneMoving = true end)
      
      if possibleItems[self.id].after_damage then
        possibleItems[self.id].after_damage(self,target,wielder)
      end
			wielder:callbacks('damages',target,dmg)
      local cons = (result == "critical" and critConditions or hitConditions)
			for _, condition in pairs (cons) do
				if (random(1,100) < condition.chance) then
          local turns = ((condition.minTurns and condition.maxTurns and random(condition.minTurns,condition.maxTurns)) or tweak(condition.turns))
					target:give_condition(condition.condition,turns,wielder)
				end -- end condition chance
			end	-- end condition forloop
		end -- end hit if
    if player:can_see_tile(self.x,self.y) or player:can_see_tile(target.x,target.y) and player:does_notice(wielder) and player:does_notice(target) then
      output:out(txt)
      if result ~= "miss" then output:sound('punch') end
    end
		return dmg
	else -- if not touching target
		return false
	end
end

function Item:target()
  action = "targeting"
  actionResult = self
  actionItem = self
end

function Item:reload(possessor)
  if self.charges > 1 and self.usingAmmo then
    local it,id,amt = possessor:has_item(self.usingAmmo)
    amt = math.min((amt or 0),self.max_charges - self.charges) --don't reload more than the item can hold
    if amt > 0 then
      self.charges = self.charges + amt
      possessor:delete_item(it,amt)
      if player:can_sense_creature(possessor) then
        output:out(possessor:get_name() .. " reloads " .. self:get_name() .. " with " .. it:get_name(false,amt) .. ".")
      end
    else
      if possessor == player then output:out("You don't have any more of the specific type of ammo that is loaded in" .. self:get_name() .. ".") end
      return false
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
        return false
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
    self.projectile_name = usedAmmo.projectile_name
    if player:can_sense_creature(possessor) then
      output:out(possessor:get_name() .. " reloads " .. self:get_name() .. " with " .. usedAmmo:get_name(false,amt) .. ".")
    end
  end --end if using specific ammo
end

--Check what hit conditions an item can inflict
--@param self Item. The item itself
--@return Table. The list of hit conditions
function Item:get_hit_conditions()
	return (self.hit_conditions or {})
end

--Check what conditions an item can inflict on a critical hit
--@param self Item. The item itself
--@return Table. The list of hit conditions
function Item:get_crit_conditions()
	return (self.crit_conditions or self:get_hit_conditions())
end

--Check what conditions an item can inflict on a critical hit
--@param self Item. The item itself
--@return Table. The list of hit conditions
function Item:get_armor_piercing(wielder)
	return (self.armor_piercing or 0) + (wielder and wielder:get_bonus('armor_piercing') or 0)
end