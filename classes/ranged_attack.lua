---@classmod ranged_attack
ranged_attack = {}
ranged_attack.__index = ranged_attack

---Initiate a ranged attack from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the ranged attacks.
--@param data Table. The table of attack information.
--@return ranged_attack. The attack itself.
function ranged_attack:new(data)
	local newRanged = {}
	for key, val in pairs(data) do
		newRanged[key] = data[key]
	end
  newRanged.baseType = "ranged"
  if (not data.target_type) then newRanged.target_type = "creature" end
  if (data.projectile == nil) then newRanged.projectile = true end
	setmetatable(newRanged,ranged_attack)
	return newRanged
end

---Get the name of the ranged attack.
--@return String. The name of the attack.
function ranged_attack:get_name()
  return self.name
end

---Get the description of the ranged attack.
--@return String. The description of the attack.
function ranged_attack:get_description()
  return self.description
end

---Use the ranged attack.
--@param target Creature. The creature being targeted.
--@param attacker Creature. The creature doing the attack.
--@param item Item. The item being used to do the ranged attack (optional).
--@return Boolean. Whether the attack was successful.
function ranged_attack:use(target, attacker, item)
	-- check to see if it can be used
  if target == attacker then
    if attacker == player then output:out("You can't use a ranged attack on yourself. You're too close.") end
    return false
  end
  if not attacker:callbacks('use_ranged_ability',target,self) then return false end
  if (item and item.charges) or (not item and attacker.ranged_charges) then --if it's not an infinite attack
    if item and item.charges > 0 then
      item.charges = item.charges - 1
    elseif not item and attacker.ranged_charges and attacker.ranged_charges > 0 then
      attacker.ranged_charges = attacker.ranged_charges - 1
    elseif (item and item.charges < 1) or (not item and attacker.ranged_charges and attacker.ranged_charges < 1) then
      if self.active_recharge == true then --if it's actively reloaded
        self:recharge(attacker,item)
        return true
      else
        return false
      end
    end
  end -- end charges if
  
  --Do the attack itself:
  if attacker == player then update_stat('ability_used',self.name) end
  if (self:does_hit(attacker,target,item) == false) then --check to see if it hits
    local newX,newY = random(target.x-1,target.x+1),random(target.y-1,target.y+1)
    while(newX==attacker.x and newY==attacker.y) do
      newX,newY = random(target.x-1,target.x+1),random(target.y-1,target.y+1)
    end
    target = {x=newX,y=newY}
  end
  if self.sound and player:can_see_tile(attacker.x,attacker.y) then output:sound(self.sound) end
  --Create the projectile:
  local proj = Projectile((item and item.projectile_name or self.projectile_name),attacker,target)
  --Add enchantments:
  if item then
    if item.projectile_enchantments then
      proj.enchantments = item.projectile_enchantments
    end
    if item.enchantments and item.itemType == "throwable" or item.itemType == "ammo" then
      proj.enchantments = item.enchantments
    end
  end --end if item
  return proj
end

---Calculate whether the ranged attack hits.
--@param target Creature. The creature being targeted.
--@param attacker Creature. The creature doing the attack.
--@param item Item. The item being used to do the attack. (optional)
--@return Boolean. Whether the attack hits or not.
function ranged_attack:does_hit(attacker,target,item)
	local hitMod = self:calc_hit_chance(attacker,target,item)
	
  if (random(1,100) <= hitMod) then return true end
  return false
end

---Calculate the chance the ranged attack will hit.
--@param target Creature. The creature being targeted.
--@param attacker Creature. The creature doing the attack.
--@param item Item. The item being used to do the attack. (optional)
--@return Number. The % hit chance.
function ranged_attack:calc_hit_chance(attacker,target,item)
  local dist = calc_distance(attacker.x,attacker.y,target.x,target.y)
  if (self.range and dist > self.range) or (self.min_range and dist < self.min_range) or (self.projectile and not attacker:can_shoot_tile(target.x,target.y)) then
    return 0
  end
  local min,max = self.best_distance_min,self.best_distance_max
  local hitMod = self.accuracy + attacker:get_stat('ranged') + attacker:get_bonus('ranged_chance') - target:get_stat('dodging') - target:get_bonus('dodge_chance')
  if min and max then
    if dist < min or dist > max then --if within acceptable distance, return base accuracy
      local diff = (dist < min and min-dist or dist-max)
      local mod = (self.accuracy_decay or (self.accuracy/10))
      hitMod = hitMod - math.ceil(mod*diff)
    end
  end
  if item then hitMod = hitMod + item:get_ranged_accuracy() end
  if (hitMod > 95) then hitMod = 95 elseif (hitMod < 10) then hitMod = 10 end
  return hitMod
end

---Recharge the charges of the ranged attack.
--@param possessor Creature. The creature who has the attack.
--@param item Item. The item that has the attack.
--@return Boolean. Whether the recharging was successful.
function ranged_attack:recharge(possessor,item)
  local charges = (item and item.charges or possessor.ranged_charges)
  local max_charges = (item and item.max_charges or self.max_charges)
  local recharge_cooldown = (item and item.recharge_cooldown or possessor.ranged_recharge_countdown)
  if charges == max_charges then
    return false --don't do anything if the attack is already full
  elseif not recharge_cooldown or recharge_cooldown <= 1 then
    if item then
      item:reload(possessor)
    else --end item reloading. Start code for if it's an inborn ranged attack
      possessor.ranged_charges = possessor.ranged_charges + (self.recharge_amount or self.max_charges)
      if possessor.ranged_recharge_countdown and self.active_recharge ~= true and self.recharge_turns and self.recharge_turns > 1 then --if it's an auto-recharge, go ahead and start the countdown for the next one
        possessor.ranged_recharge_countdown = self.recharge_turns
      end
    end --end item or not if
    if (self.active_recharge == true) then
      if player:can_sense_creature(possessor) then
        if self.recharge_sound then
          output:sound(self.recharge_sound)
        end
        if self.recharge_text then
          output:out(possessor:get_name() .. " " .. self.recharge_text)
        end
      end
      if item then
        item.recharge_cooldown = nil -- don't start the countdown if it's an active recharge
      else
        possessor.ranged_recharge_countdown = nil -- don't start the countdown if it's an active recharge
      end
    end --end if active recharge 
    if item then
      if item.charges >= item.max_charges then
        item.charges = item.max_charges
        if item.charge_cooldown then item.charge_cooldown = nil end
      end
    elseif (possessor.ranged_charges >= self.max_charges) then --if we're fully (or over-)recharged, get rid of the countdown
      possessor.ranged_charges = self.max_charges
      if possessor.ranged_recharge_countdown then possessor.ranged_recharge_countdown = nil end
    end
  elseif (possessor.ranged_recharge_countdown == nil) then
    possessor.ranged_recharge_countdown = self.recharge_turns
  else
    possessor.ranged_recharge_countdown = possessor.ranged_recharge_countdown - 1
  end
  return true
end