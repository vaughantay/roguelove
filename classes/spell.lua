---@classmod Spell
Spell = Class{}

---Initiate a spell from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the spells.
--@param data Table. The table of spell information.
--@return Spell. The spell itself.
function Spell:init(data)
	for key, val in pairs(data) do
		self[key] = data[key]
	end
  self.baseType = "spell"
  self.flags = self.flags or {}
	return self
end

---Get the description of the spell, its cost, and potentially a description of why you can't use it.
--@param no_reqtext Boolean. If true, don't show the text that explains why you can't use the ability.
--@return String. The description of the spell.
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

---Start targeting a spell (unless it's a self-only spell, in which case it just goes ahead and casts it).
--@param target Entity. The target of the spell.
--@param caster Creature. The caster of the spell.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the spell is on a cooldown.
--@return Boolean. Whether the spell was successfully able to be cast/targeted or not.
function Spell:target(target,caster, ignoreCooldowns)
  local req, reqtext = self:requires(caster)
  if (not ignoreCooldowns and caster.cooldowns[self.name]) then
		if (caster == player) then output:out("You can't use that ability again for another " .. caster.cooldowns[self.name] .. " turns.") end
		return false
  elseif req == false then
    if (caster == player) then output:out((reqtext or "You can't use that ability right now.")) end
    return false
  end
  if not caster:callbacks('casts',target,self,ignoreCooldowns) then --We're hoping the callback itself will provide any necessary feedback
    return false
  end
  
	if (self.target_type == "self" or self.target_type == "passive") then
		if (self.target_type ~= "passive") then
			return self:use(target,caster,ignoreCooldowns)
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

---Cast a spell.
--@param target Entity. The target of the spell.
--@param caster Creature. The caster of the spell.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the spell is on a cooldown.
--@return Boolean. Whether the spell was successfully able to be cast or not.
function Spell:use(target, caster, ignoreCooldowns)
  local req, reqtext = self:requires(caster)
	if (not ignoreCooldowns and caster.cooldowns[self.name]) then
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
      if self.cooldown and self.cooldown > 0 and not ignoreCooldowns then 
        caster.cooldowns[self.name] = (caster ~= player and self.AIcooldown or self.cooldown)
      end
      if caster.magic and self.cost then
        caster.magic = caster.magic - self.cost
      end
    end --end false/nil if
		return (r == nil and true or r) -- this looks weird, but it's so that spells can return false
	end
end

--Placeholder for the decide() callback, which is used by the AI to decide where to target a spell. Defaults to the already-selected target.
--@param target Entity. The original target of the spell.
--@param caster Creature. The creature casting the spell.
--@param use_type String. The way in which this spell is being used. Either aggressive, defensive, fleeing or friendly.
--@return Entity. The new target of the spell.
function Spell:decide(target,caster,use_type)
  return target --default to already-selected target
end

--Placeholder for the requires() callback, used to determine if the creature meets the requirements for using the spell
--@param possessor Creature. The creature who's trying to use the spell.
--@return true
function Spell:requires(possessor)
  return true
end