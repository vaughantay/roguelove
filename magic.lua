Spell = Class{}

function Spell:init(data)
	for key, val in pairs(data) do
		self[key] = data[key]
	end
  self.flags = self.flags or {}
	return self
end

function Spell:get_description(no_reqtext)
  local req, reqtext = self:requires(player)
  if reqtext then
    reqtext = "\n\nYou can't use this ability right now:\n" .. reqtext
  else
    if req == false then reqtext = "\n\nYou can't use this ability right now."
    else reqtext = "" end
  end
    return self.description .. (self.cost and "\nCost: " .. self.cost .. " " .. player.magicName or "") .. (no_reqtext and "" or reqtext)
end

function Spell:target(target,caster)
  local req, reqtext = self:requires(caster)
  if (caster.cooldowns[self.name]) then
		if (caster == player) then output:out("You can't use that ability again for another " .. caster.cooldowns[self.name] .. " turns.") end
		return false
  elseif req == false then
    if (caster == player) then output:out((reqtext or "You can't use that ability right now.")) end
    return false
  end
  if not caster:callbacks('casts',target,self) then --We're hoping the callback itself will provide any necessary feedback
    return false
  end
  
	if (self.target_type == "self" or self.target_type == "passive") then
		if (self.target_type ~= "passive") then
			return self:use(target,caster)
		end
	else
		action = "targeting"
		actionResult = self
		if (target) then
			output:setCursor(target.x,target.y,true)
		end
		return false
	end
end

function Spell:use(target, caster)
  local req, reqtext = self:requires(caster)
	if (caster.cooldowns[self.name]) then
		if (caster == player) then output:out("You can't use that ability again for another " .. caster.cooldowns[self.name] .. " turns.") end
		return false
  elseif req == false then
    if (caster == player) then output:out((reqtext or "You can't use that ability right now.")) end
    return false
  elseif caster.magic and self.cost and self.cost > caster.magic then
    if (caster == player) then output:out("You don't have enough " .. (caster.magicName or "magic") .. " to use that ability.") end
		return false
	else
		local r = self:cast(target,caster)
    if r ~= false or r == nil then
      if self.sound and player:can_see_tile(caster.x,caster.y) then output:sound(self.sound) end
      if caster == player then update_stat('ability_used',self.name) end
      if self.cooldown and self.cooldown > 0 then 
        caster.cooldowns[self.name] = (caster ~= player and self.AIcooldown or self.cooldown)
      end
      if caster.magic and self.cost then
        caster.magic = caster.magic - self.cost
      end
    end --end false/nil if
		return (r == nil and true or r) -- this looks weird, but it's so that spells can return false
	end
end

function Spell:attacked(possessor)
	return true
end

function Spell:attacks(possessor)
	return true
end

function Spell:damages(possessor,amount)
	return amount
end

function Spell:damaged(possessor,amount)
	return amount
end

function Spell:decide(target,caster,use_type)
  return target --default to already-selected target
end

function Spell:requires(possessor)
  return true
end