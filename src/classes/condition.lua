---@classmod Condition
Condition = Class{}

---Initiate a condition from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the conditions.
--@param data Table. The table of condition information.
--@return Condition. The condition itself.
function Condition:init(data)
	for key, val in pairs(data) do
		self[key] = data[key]
	end
  if not self.removal_type then self.removal_type = "turn" end
	return self
end

---Gets the full description of the condition
--@param noBoosts Boolean. If true, don't display the boosts
--@param possessor Creature. The creature who has the condition. Used for displaying customized boosts
--@return String. The description
function Condition:get_description(noBoosts,possessor)
  local desc = self.description or ""
  
  if not noBoosts then
    local boosts = {}
    if self then end
  end
  
  return desc
end

---Placeholder for the advance() callback, code called by the condition every turn
--@param possessor Creature. The creature who's afflicted with the condition
--@return true
function Condition:advance(possessor)
	return true
end

---Placeholder for the moves() callback, code called by the condition when the possessor the condition moves
--@param possessor Creature. The creature who's afflicted with the condition
--@return true
function Condition:moves(possessor,target)
	return true
end

---Placeholder for the attacks() callback, code called by the condition when the possessor the condition attacks someone
--@param possessor Creature. The creature who's afflicted with the condition
--@return true
function Condition:attacks(possessor,target)
	return true
end

---Wrapper for the applied() callback
--@param possessor Creature. The creature who's afflicted with the condition
--@param applier Creature. The creature who inflicts the condition
--@param turns Number. The number of turns to apply the condition.
--@param args Anything. Arguments to pass to the condition.
--@return Boolean. Whether the application was successful or not.
function Condition:apply(possessor,applier,turns,args)
  if (self.applied ~= nil) then
    return self:applied(possessor,applier,turns,args)
  end
end

---Checks immune_creature_types of the condition, and the condition's can_apply() callback, if it exists
--@param possessor Creature. The creature who's afflicted with the condition
--@param applier Creature. The creature who inflicts the condition
--@param turns Number. The number of turns to apply the condition.
--@return Boolean. Whether the application was successful or not.
function Condition:can_apply(possessor,applier,turns)
  if self.immune_creature_types then
    for _,ctype in ipairs(self.immune_creature_types) do
      if possessor:is_type(ctype) then
        return false
      end
    end
  end
  if (self.requires ~= nil) then
    return self:requires(possessor,applier,turns)
  end
  return true
end

---Wrapper for the cured() callback
--@param possessor Creature. The creature who's afflicted with the condition
--@return Boolean. Whether the cure was successful or not.
function Condition:cure(possessor)
	if (self.cured ~= nil) then
		return self:cured(possessor)
	end
end

---Checks if an condition is of a type
--@param tag String. The tag to check for
--@return Boolean. Whether or not it has the tag.
function Condition:is_type(ctype)
  if self.types and in_table(ctype,self.types) then
    return true
  end
  return false
end