ranged_attack = {}
ranged_attack.__index = ranged_attack

function ranged_attack:new(data)
	local newRanged = {}
	for key, val in pairs(data) do
		newRanged[key] = data[key]
	end
  if (not data.target_type) then newRanged.target_type = "creature" end
  if (data.projectile == nil) then newRanged.projectile = true end
	setmetatable(newRanged,ranged_attack)
	return newRanged
end

function ranged_attack:get_name()
  return self.name
end

function ranged_attack:get_description()
  return self.description
end

function ranged_attack:use(target, attacker)
	-- check to see if it can be used
  if target == attacker then
    if attacker == player then output:out("You can't use a ranged attack on yourself. You're too close.") end
    return false
  end
  if not attacker:callbacks('use_ranged_ability',target,self) then return false end
  if self.max_charges then --if it's not an infinite attack
    if attacker.ranged_charges > 0 then
      attacker.ranged_charges = attacker.ranged_charges - 1
    else
      if self.active_recharge == true then --if it's actively reloaded
        self:recharge(attacker)
        return true
      else
        return false
      end
    end
  end -- end charges if
  if attacker == player then update_stat('ability_used',self.name) end
  if (self:does_hit(attacker,target) == false) then --check to see if it hits
    local newX,newY = random(target.x-1,target.x+1),random(target.y-1,target.y+1)
    while(newX==attacker.x and newY==attacker.y) do
      newX,newY = random(target.x-1,target.x+1),random(target.y-1,target.y+1)
    end
    target = {x=newX,y=newY}
  end
  if self.sound and player:can_see_tile(attacker.x,attacker.y) then output:sound(self.sound) end
  return Projectile(self.projectile_name,attacker,target)
end

function ranged_attack:does_hit(attacker,target)
	local hitMod = self:calc_hit_chance(attacker,target)
	
  if (random(1,100) <= hitMod) then return true end
  return false
end

function ranged_attack:calc_hit_chance(attacker,target)
  local dist = calc_distance(attacker.x,attacker.y,target.x,target.y)
  local min,max = self.best_distance_min,self.best_distance_max
  local bonus = attacker:get_bonus('ranged_chance') - target:get_bonus('dodge_chance')
  local hitMod = 5
  if min and max then
    if dist >= min and dist <= max then --if within acceptable distance, return base accuracy
      return self.accuracy
    else
      local diff = (dist < min and min-dist or dist-max)
      local mod = (self.accuracy_decay or (self.accuracy/10))
      hitMod = self.accuracy - math.ceil(mod*diff) + bonus
    end
  else --if no min/max distance, accuracy is flat
    hitMod = self.accuracy + bonus
  end
  if (hitMod > 95) then hitMod = 95 elseif (hitMod < 10) then hitMod = 10 end
  return hitMod
end

function ranged_attack:recharge(possessor)
  if (possessor.ranged_charges == self.max_charges) then return false --don't do anything if the attack is already full
  elseif (self.recharge_turns == nil or possessor.ranged_recharge_countdown == 1) then
    possessor.ranged_charges = possessor.ranged_charges + (self.recharge_amount or self.max_charges)
    if possessor.ranged_recharge_countdown and self.active_recharge ~= true and self.recharge_turns and self.recharge_turns > 1 then --if it's an auto-recharge, go ahead and start the countdown for the next one
      possessor.ranged_recharge_countdown = self.recharge_turns
    end
    if (self.active_recharge == true) then
      if player:can_sense_creature(possessor) then
        if self.recharge_sound then
          output:sound(self.recharge_sound)
        end
        if self.recharge_text then
          output:out(possessor:get_name() .. " " .. self.recharge_text)
        end
      end
      possessor.ranged_recharge_countdown = nil -- don't start the countdown if it's an active recharge
    end
    if (possessor.ranged_charges >= self.max_charges) then --if we're fully (or over-)recharged, get rid of the countdown
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