---@classmod Spell
Spell = Class{}

---Initiate a spell from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the spells.
--@param data Table. The table of spell information.
--@return Spell. The spell itself.
function Spell:init(spellID)
  local data = possibleSpells[spellID]
  if not data then
    output:out("Error: Tried to create non-existent spell " .. spellID)
    print("Error: Tried to create non-existent spell " .. spellID)
    return false
  end
	for key, val in pairs(data) do
    if type(val) ~= "function" then
      self[key] = data[key]
    end
	end
  self.baseType = "spell"
  self.id = spellID
  self.flags = self.flags or {}
  self.applied_upgrades = {}
  self.level = self.level or 1
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
    return self.description .. (no_reqtext and "" or reqtext)
end

---Start targeting a spell (unless it's a self-only spell, in which case it just goes ahead and casts it).
--@param target Entity. The target of the spell.
--@param caster Creature. The caster of the spell.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the spell is on a cooldown.
--@return Boolean. Whether the spell was successfully able to be cast/targeted or not.
function Spell:target(target,caster, ignoreCooldowns, ignoreMP)
  local req, reqtext = self:requires(caster)
  if (not ignoreCooldowns and caster.cooldowns[self.name]) then
		if (caster == player) then output:out("You can't use that ability again for another " .. caster.cooldowns[self.name] .. " turns.") end
		return false
  elseif req == false then
    if (caster == player) then output:out((reqtext or "You can't use that ability right now.")) end
    return false
  elseif not ignoreMP and caster.mp and self.cost and self.cost > caster.mp then
    if (caster == player) then output:out("You don't have enough magic points to use that ability.") end
		return false
  elseif not ignoreMP and self.charges and self.charges < 1 then
    if (caster == player) then output:out("You're out of charges for that ability.") end
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
--@param ignoreMP Boolean. If set to true, this will make the spell not use MP when cast
--@return Boolean. Whether the spell was successfully able to be cast or not.
function Spell:use(target, caster, ignoreCooldowns, ignoreMP)
  local req, reqtext = self:requires(caster)
	if (not ignoreCooldowns and caster.cooldowns[self.name]) then
		if (caster == player) then output:out("You can't use that ability again for another " .. caster.cooldowns[self.name] .. " turns.") end
		return false
  elseif req == false then
    if (caster == player) then output:out((reqtext or "You can't use that ability right now.")) end
    return false
  elseif not ignoreMP and caster.mp and self.cost and self.cost > caster.mp then
    if (caster == player) then output:out("You don't have enough magic points to use that ability.") end
		return false
  elseif not ignoreMP and self.charges and self.charges < 1 then
    if (caster == player) then output:out("You're out of charges for that ability.") end
		return false
	elseif possibleSpells[self.id].cast then
    local status,r = pcall(possibleSpells[self.id].cast,self,target,caster)
    if not status then
      local errtxt = "Error from " .. caster:get_name() .. " casting spell " .. self.name .. ": " .. r
      output:out(errtxt)
      print(errtxt)
      return false
    end
    if r ~= false or r == nil then
      if self.sound and player:can_see_tile(caster.x,caster.y) then output:sound(self.sound) end
      if caster == player then update_stat('ability_used',self.name) end
      if ((self.cooldown and self.cooldown > 0) or (caster ~= player and self.AIcooldown and self.AIcooldown > 0)) and not ignoreCooldowns then 
        caster.cooldowns[self.name] = (caster ~= player and self.AIcooldown or self.cooldown)
      end
      if not ignoreMP and caster.mp and self.cost then
        caster.mp = caster.mp - self.cost
      end
      if not ignoreMP and self.charges then
        self.charges = self.charges - 1
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
  if possibleSpells[self.id].decide then return possibleSpells[self.id].decide(self,target,caster,use_type) end
  return target --default to already-selected target
end

--Placeholder for the requires() callback, used to determine if the creature meets the requirements for using the spell
--@param possessor Creature. The creature who's trying to use the spell.
--@return true
function Spell:requires(possessor)
  if possibleSpells[self.id].requires then return possibleSpells[self.id].requires(self,possessor) end
  return true
end

--Placeholder for the learn_requires() callback, used to determine if the creature meets the requirements for using the spell
--@param possessor Creature. The creature who's trying to use the spell.
--@return true
function Spell:learn_requires(possessor)
  if possibleSpells[self.id].learn_requires then return possibleSpells[self.id].learn_requires(self,possessor) end
  return true
end

--Placeholder for the get_target_tiles() function
--@param possessor Creature. The creature who's trying to use the spell.
--@return true
function Spell:get_target_tiles(target,possessor)
  if possibleSpells[self.id].get_target_tiles then
    return possibleSpells[self.id].get_target_tiles(self,target,possessor)
  else
    return {}
  end
end

---Checks if a spell has a descriptive tag.
--@param tag String. The tag to check for
--@return Boolean. Whether or not it has the tag.
function Spell:has_tag(tag)
  if self.tags and in_table(tag,self.tags) then
    return true
  end
end

---Get the stat for a spell
--@param stat String. The stat to return
--@return Anything. Whatever the stat's value is (or false if not set)
function Spell:get_stat(stat)
  local value = false
  if self[stat] then 
    value = self[stat]
  elseif self.stats and self.stats[stat] then
    value = self.stats[stat].value
  end
  --TODO: Modifiers?
  return value
end

---Gets the possible upgrades for a spell
--@return Table. A table of the possible upgrades, with the format {upgradeID=upgradeLevel}
function Spell:get_possible_upgrades()
  local upgrades = {}
  if not self.possible_upgrades then return upgrades end
  for id,details in pairs(self.possible_upgrades) do
    local current_upgrade_level = self.applied_upgrades[id] or 0
    local max_upgrade_level = #details
    if current_upgrade_level < max_upgrade_level then
      upgrades[id] = current_upgrade_level + 1
    end
  end
  return upgrades
end

---Applies an upgrade to a spell
--@return Boolean. Whether the upgrade was applied
function Spell:apply_upgrade(upgradeID)
  local upgrades = self:get_possible_upgrades()
  local level = upgrades[upgradeID]
  if level then
    local stats = self.possible_upgrades[upgradeID][level]
    for stat,value in pairs(stats) do
      if self[stat] then
        self[stat] = (type(value) == "number" and self[stat] + value or value)
      elseif self.stats and self.stats[stat] then
        self.stats[stat].value = (type(value) == "number" and self.stats[stat].value + value or value)
      end
    end
    self.applied_upgrades[upgradeID] = level
    return true
  end
  return false
end