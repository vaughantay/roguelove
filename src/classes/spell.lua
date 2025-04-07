---@classmod Spell
Spell = Class{}

---Initiate a spell from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the spells.
--@param data Table. The table of spell information.
--@return Spell. The spell itself.
function Spell:init(spellID)
  local data = possibleSpells[spellID]
  if not data then
    output:out("Error: Tried to create non-existent spell " .. tostring(spellID))
    print("Error: Tried to create non-existent spell " .. tostring(spellID))
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
  self.baseType = "spell"
  self.id = spellID
  self.flags = self.flags or {}
  self.applied_upgrades = {}
  self.level = self.level or 1
  self.free_upgrades = 0
  self.spellPoints = 0
  self.uses = 0
  if self.max_charges then
    self.charges = self:get_stat('max_charges')
  end
	return self
end

---Get the description of the spell, its cost, and potentially a description of why you can't use it.
--@param no_reqtext Boolean. If true, don't show the text that explains why you can't use the ability.
--@return String. The description of the spell.
function Spell:get_description(no_reqtext)
  if self.possessor then
    local req, reqtext = self:requires(player)
    if reqtext then
      reqtext = "\n\nYou can't use this ability right now:\n" .. reqtext
    else
      if req == false then reqtext = "\n\nYou can't use this ability right now."
      else reqtext = "" end
    end
    return self.description .. (no_reqtext and "" or reqtext)
  else
    return self.description
  end
end

---Returns all the stats of the spell
--@return String. The stats of the spell
function Spell:get_info()
  local statText = ""
  if self.charges then
    statText = statText .. "Charges: " .. self.charges .. (self.max_charges and "/" .. self:get_stat('max_charges') or "") .. "\n"
  end
  if self.mp_cost then
    statText = statText .. "MP Cost: " .. self.mp_cost .. "\n"
  end
  if self.mp_cost_per_turn then
    statText = statText .. "MP Cost per Turn: " .. self.mp_cost_per_turn .. "\n"
  end
  if self.stat_cost then
    for stat,cost in pairs(self.stat_cost) do
      local name = (self.possessor and self.possessor.extra_stats[stat].name or ucfirst(stat))
      statText = statText .. name .. " Cost: " .. cost .. "\n"
    end
  end
  if self.items_consumed then
    for itemID,amount in pairs(self.items_consumed) do
      local has_amt
      if self.possessor then 
        _,_,has_amt = self.possessor:has_item(itemID)
      end
      local name = ucfirst(possibleItems[itemID].name)
      statText = statText .. name .. " Cost: " .. amount .. (type(has_amt) == "number" and " (You have " .. has_amt .. ")" or "") .. "\n"
    end
  end
  if self.max_active_turns then
    statText = statText .. "Max Active Turns: " .. self.max_active_turns .. "\n"
  end
  if self.cooldown then
    statText = statText .. "Cooldown: " .. self.cooldown .. " Turns" .. "\n"
  end
  if self.min_range then
    statText = statText .. "Min Range: " .. self.min_range .. "\n"
  end
  if self.range then
    statText = statText .. "Max Range: " .. self.range .. "\n"
  end
  if (self.min_targets and self.min_targets > 1) or (self.max_targets and self.max_targets > 1) then
    local min,max = (self.min_targets or 1), (self.max_targets or self.min_targets or 1)
    statText = statText .. "Number of targets: " .. (min == max and min or (min .. " - " .. max)) .. "\n"
  end
  if self.deactivate_on_damage_chance then
    statText = statText .. "Chance of Deactivation when Damaged: " .. self.deactivate_on_damage_chance .. "%" .. "\n"
  end
  if self.stats then
    local tempstats = {}
    local stats = {}
    local unsorted = {}
    local lastorder = 0
    for stat,info in pairs(self.stats) do
      info.id = stat
      if not info.name then info.name = ucfirst(info.id) end
      local display_order = info.display_order
      if display_order then
        lastorder = math.max(lastorder,display_order)
        if not tempstats[display_order] then
          tempstats[display_order] = info
        else
          table.insert(unsorted,info)
        end
      else
        table.insert(unsorted,info)
      end
    end
    sort_table(unsorted,'name')
    for i,info in ipairs(unsorted) do
      table.insert(tempstats,info)
      lastorder = math.max(lastorder,#tempstats)
    end
    for i=1,lastorder,1 do
      if tempstats[i] then
        stats[#stats+1] = tempstats[i]
      end
    end
    for i,stat in ipairs(stats) do
      local value = self:get_stat(stat.id)
      local baseValue = self:get_stat(stat.id,nil,true)
      if value ~= false and stat.hide ~= true and (value ~= 0 or stat.hide_when_zero ~= true) then
        statText = statText .. stat.name .. (type(value) ~= "boolean" and ": " .. value .. (stat.is_percentage and "%" or "") or "") .. (value ~= baseValue and " (" .. baseValue .. (stat.is_percentage and "%" or "") .. " base)" or "") .. (stat.description and " (" .. stat.description .. ")" or "") .. "\n"
      end
    end
  end
  return statText
end

---Start targeting a spell (unless it's a self-only spell, in which case it just goes ahead and casts it).
--@param target Entity. The target of the spell.
--@param caster Creature. The caster of the spell.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the spell is on a cooldown.
--@return Boolean. Whether the spell was successfully able to be cast/targeted or not.
function Spell:target(target,caster, ignoreCooldowns, ignoreCost)
  if self.active then --If the spell is already active, don't cast it
    if self.no_manual_deactivate then
      output:out("That ability can't be manually deactivated.")
      return false
    end
    local data = caster.active_spells[self.id]
    local t = data.target
    local mp = data.ignoreCost
    local cd = data.ignoreCooldowns
    return self:finish(t, caster, cd, mp)
  end
  
  --First, check whether we can use the spell:
  local canUse, result = self:can_use(target,caster,ignoreCooldowns,ignoreCost)
  if canUse == false then
    if caster == player and result then
      output:out(result)
    end
    return false
  end
  
	if (self.target_type == "self" or self.target_type == "passive") then
		if (self.target_type ~= "passive") then
			return self:use(target,caster,ignoreCooldowns)
		end
	else
		action = "targeting"
		actionResult = self
    game.targets = {}
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
--@param ignoreCost Boolean. If set to true, this will make the spell not use MP when cast
--@return Boolean. Whether the spell was successfully able to be cast or not.
function Spell:use(target, caster, ignoreCooldowns, ignoreCost)
  if self.active then --If the spell is already active, don't cast it
    if self.no_manual_deactivate then
      output:out("That ability can't be manually deactivated.")
      return false
    end
    local data = caster.active_spells[self.id]
    local t = data.target
    local mp = data.ignoreCost
    local cd = data.ignoreCooldowns
    return self:finish(t, caster, cd, mp)
  end
  --First, check all requirements:
  local canUse, result = self:can_use(target,caster,ignoreCooldowns,ignoreCost)
  local targ, targtext = self:target_requires(target,caster)
  if canUse == false then
    if caster == player and result then
      output:out(result)
    end
    return false
  end
  if targ == false then
    if caster == player then
      output:out((targtext or "You have selected an invalid target for this spell."))
    end
    return false
  end
  --Check targeting requirements:
  if self.min_targets and #target < self.min_targets then
    if caster == player then output:out("Not enough targets selected. You need at least " .. self.min_targets .. ".") end
    return false
  end
  --Cast the actual spell:
  if possibleSpells[self.id].cast then
    if target and #target == 1 and not self.cast_accepts_multiple_targets then target = target[1] end --if being passed only a single target, just set that as the target and don't loop
    local result = nil
    if not target or #target == 0 or self.cast_accepts_multiple_targets then
      local status, r = pcall(possibleSpells[self.id].cast,self,target,caster)
      result = r
      if not status then
        local errtxt = "Error from " .. caster:get_name() .. " casting spell " .. self.name .. ": " .. result
        output:out(errtxt)
        print(errtxt)
        return false
      end
    else --if there are multiple targets and the spell's cast() function isn't set up to handle them, loop through the targets and cast() on each one
      for tnum,t in ipairs(target) do
        local status, r = pcall(possibleSpells[self.id].cast,self,t,caster)
        if r == false then result = false end --if any cast returns false, we want to know
        if not status then
          local errtxt = "Error from " .. caster:get_name() .. " casting spell " .. self.name .. ": " .. tostring(result)
          output:out(errtxt)
          print(errtxt)
          return false
        end
      end --end target for
    end --end #target if
    if result ~= false or result == nil then --if the cast succeeded
      --Stop active spells that deactivate on cast
      for id,data in pairs(caster.active_spells) do
        if data.spell.deactivate_on_cast or data.spell.deactivate_on_all_actions then
          local t = data.target
          local mp = data.ignoreCost
          local cd = data.ignoreCooldowns
          data.spell:finish(t, caster, cd, mp)
        end
      end
      if self.sound and player:can_see_tile(caster.x,caster.y) then output:sound(self.sound) end
      if caster == player then update_stat('ability_used',self.name) end
      self.uses = self.uses+1
      --Add cooldown
      if ((self.cooldown and self.cooldown > 0) or (caster ~= player and self.AIcooldown and self.AIcooldown > 0)) and not ignoreCooldowns and not self.toggled then --Don't add cooldown to a toggled spell, add it when the spell is finished
        caster.cooldowns[self] = (caster ~= player and self.AIcooldown or self.cooldown)
      end
      --Account for the cost of the spell
      if not ignoreCost then 
        if caster.mp and self.mp_cost then
          caster.mp = caster.mp - self.mp_cost
        end
        if self.charges then
          self:update_charges(-1,true)
        end
        if self.stat_cost then
          for stat,cost in pairs(self.stat_cost) do
            if caster.extra_stats[stat] then
              caster.extra_stats[stat].value = caster.extra_stats[stat].value - cost
            else
              caster[stat] = caster[stat] - cost
            end
          end
        end
        if self.items_consumed then
          for itemID,amount in pairs(self.items_consumed) do
            local item = caster:has_item(itemID)
            caster:delete_item(item,amount)
          end
        end
      end
      --If it's a toggled spell, save necessary info to the caster
      if self.toggled then
        caster.active_spells[self.id] = {caster=caster,target=target,ignoreCost=ignoreCost,ignoreCooldowns=ignoreCooldowns,turns=0,spell=self}
        self.active = true
      end
      caster:callbacks('after_cast',target,self)
      caster:decrease_all_conditions('spell')
    end --end false/nil if
		return (result == nil and true or result) -- this looks weird, but it's so that spells return true by default if they don't return anything
	end
end

---Checks to see if the spell can be used right now
--@param target Entity. The target of the spell.
--@param caster Creature. The caster of the spell.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the spell is on a cooldown.
--@param ignoreCost Boolean. If set to true, this will make the spell not use MP when cast
--@return Boolean. Whether the spell can be used right now
function Spell:can_use(target, caster, ignoreCooldowns, ignoreCost)
  local req, reqtext = self:requires(caster)
  if req == false then
    return false,(reqtext or "You can't use that ability right now.")
	elseif (not ignoreCooldowns and caster.cooldowns[self]) then
		return false,"You can't use that ability again for another " .. caster.cooldowns[self] .. " turns."
  elseif not ignoreCost and caster.mp and self.mp_cost and self.mp_cost > caster.mp then
		return false,"You don't have enough magic points to use that ability."
  elseif not ignoreCost and self.charges and self.charges < 1 then
		return false,"You're out of charges for that ability."
  elseif caster:callbacks('casts',target,self,ignoreCooldowns) == false then --We're hoping the callback itself will provide any necessary feedback
    return false
  end
  if self.stat_cost then
    for stat,cost in pairs(self.stat_cost) do
      if caster.extra_stats[stat] and caster.extra_stats[stat].value < cost then
        return false,"You don't have enough " .. caster.extra_stats[stat].name .. " to use that ability."
      elseif caster[stat] and caster[stat] < cost then
        return false,"You don't have enough " .. stat .. " to use that ability."
      end
    end
  end
  if self.items_consumed then
    for itemID,amount in pairs(self.items_consumed) do
      local has,_,has_amt = caster:has_item(itemID)
      if not has or has_amt < amount then
        return false,"You don't have enough " .. (amount > 1 and possibleItems[item_details.item].pluralName or possibleItems[item_details.item].name) .. " to use that ability."
      end
    end
  end
  return true
end

---Placeholder for the advance_active() callback, which is called every turn a spell is active
--@param target Entity. The target of the spell.
--@param caster Creature. The caster of the spell.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the spell is on a cooldown.
--@param ignoreCost Boolean. If set to true, this will make the spell not use MP when cast
--@return Boolean. False if the spell ends, true otherwise
function Spell:advance_active(target,caster, ignoreCooldowns, ignoreCost)
  local data = caster.active_spells[self.id]
  target = target or data.target
  ignoreCooldowns = ignoreCooldowns or data.ignoreCooldowns
  ignoreCost = ignoreCost or data.ignoreCost
  --First check to see if we have enough MP:
  if not ignoreCost and self.mp_cost_per_turn then
    if caster.mp < self.mp_cost_per_turn then
      self:finish(target, caster, ignoreCooldowns, ignoreCost)
      return false
    end
  end
  --Do the spell code:
  if possibleSpells[self.id].advance_active then
    local status,r = pcall(possibleSpells[self.id].advance_active,self,target,caster)
    if not status then
      local errtxt = "Error from " .. caster:get_name() .. " channeling spell " .. self.name .. ": " .. r
      output:out(errtxt)
      print(errtxt)
      return false
    end
    if r == false then return false end
  end
  --The below should only run if the cast was successful:
  --Decrease MP
  if self.mp_cost_per_turn then caster.mp = caster.mp - self.mp_cost_per_turn end
  --Increment turn count
    data.turns = (data.turns or 0) + 1
  --if turn count is too high, turn it off
  if self.max_active_turns and data.turns >= self.max_active_turns then
    self:finish(target, caster, ignoreCooldowns, ignoreCost)
    return false
  end
  return true
end

---Placeholder for the finish() callback, which is called when a spell is toggled off or stops being channeled.
--@param target Entity. The target of the spell.
--@param caster Creature. The caster of the spell.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the spell is on a cooldown.
--@param ignoreCost Boolean. If set to true, this will make the spell not use MP when cast
function Spell:finish(target,caster, ignoreCooldowns, ignoreCost)
  local data = caster.active_spells[self.id]
  target = target or data.target
  ignoreCooldowns = ignoreCooldowns or data.ignoreCooldowns
  ignoreCost = ignoreCost or data.ignoreCost
  if possibleSpells[self.id].finish then
    local status,r = pcall(possibleSpells[self.id].finish,self,target,caster)
    if not status then
      local errtxt = "Error from " .. caster:get_name() .. " finishing spell " .. self.name .. ": " .. r
      output:out(errtxt)
      print(errtxt)
      return false
    end
    if r == false then return false end
  end
  if ((self.cooldown and self.cooldown > 0) or (caster ~= player and self.AIcooldown and self.AIcooldown > 0)) and not ignoreCooldowns then 
    caster.cooldowns[self] = (caster ~= player and self.AIcooldown or self.cooldown)
  end
  caster.active_spells[self.id] = nil
  self.active = false
  return true
end

---Placeholder for the decide() callback, which is used by the AI to decide where to target a spell. Defaults to the already-selected target.
--@param target Entity. The original target of the spell.
--@param caster Creature. The creature casting the spell.
--@param use_type String. The way in which this spell is being used. Either aggressive, defensive, fleeing or friendly.
--@return Entity. The new target of the spell.
function Spell:decide(target,caster,use_type)
  if possibleSpells[self.id].decide then
    local status,r = pcall(possibleSpells[self.id].decide,self,target,caster,use_type)
    if not status then
      local errtxt = "Error from " .. caster:get_name() .. " decide code " .. self.name .. ": " .. r
      output:out(errtxt)
      print(errtxt)
      return false
    end
    if r and type(r) == "table" then
      return r
    end
  end
  return target --default to already-selected target
end

---Placeholder for the requires() callback, used to determine if the creature meets the requirements for using the spell
--@param possessor Creature. The creature who's trying to use the spell.
--@return true
function Spell:requires(possessor)
  if possibleSpells[self.id].requires then
    local status,r,text = pcall(possibleSpells[self.id].requires,self,possessor)
    if status == false then
      output:out("Error in spell " .. self.name .. " requires code: " .. r)
      print("Error in spell " .. self.name .. " requires code: " .. r)
    end
    return r,text
  end
  return true
end

---Placeholder for the target_requires() callback, used to determine if the attempted target of the spell is acceptable
--@param target Entity. The attempted target of the spell.
--@param caster Creature. The creature who's trying to use the spell.
--@param previous_targets Table. The already-targeted targets of the spell, if applicable
--@return true
function Spell:target_requires(target,caster,previous_targets)
  if not target then return true end --If there's no target, then say true because it's either a nontargeted spell or we're just starting to target now
  if possibleSpells[self.id].target_requires then
    if #target == 1 then target = target[1] end --if there's only one target, bypass the loop
    if #target == 0 then
      return possibleSpells[self.id].target_requires(self,target,caster,previous_targets)
    else
      for tnum,t in ipairs(target) do
        return possibleSpells[self.id].target_requires(self,t,caster,previous_targets)
      end
    end --end if #target
  end --end if target_requires exists
  return true
end

---Placeholder for the learn_requires() callback, used to determine if the creature meets the requirements for using the spell
--@param possessor Creature. The creature who's trying to use the spell.
--@return true
function Spell:learn_requires(possessor)
  if possibleSpells[self.id].learn_requires then return possibleSpells[self.id].learn_requires(self,possessor) end
  return true
end

---Placeholder for the get_target_tiles() function
--@param target Entity. The potential target of the spell
--@param possessor Creature. The creature who's trying to use the spell.
--@param previous_targets Table. The already-targeted targets of the spell, if applicable
--@return true
function Spell:get_target_tiles(target,caster,previous_targets)
  if possibleSpells[self.id].get_target_tiles then
    return possibleSpells[self.id].get_target_tiles(self,target,caster,previous_targets)
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

---Checks if a spell is of a specific type
--@param tag String. The tag to check for
--@return Boolean. Whether or not it has the tag.
function Spell:is_type(stype)
  if self.types and in_table(stype,self.types) then
    return true
  end
end

---Get the stat for a spell
--@param stat String. The stat to return
--@param possessor Creature. The creature to look at when determine the spell's stats
--@param noBonus Boolean. If true, don't apply any bonuses, just return the base stat
--@return Anything. Whatever the stat's value is (or false if not set)
function Spell:get_stat(stat,possessor,noBonus)
  possessor = possessor or self.possessor
  local value = false
  local stat_type = nil
  if self[stat] then 
    value = self[stat]
  elseif self.stats and self.stats[stat] then
    value = self.stats[stat].value
    stat_type = self.stats[stat].stat_type
  else
    return false
  end
  
  if type(value) ~= "number" then
    return value
  end
  
  if value == 0 or noBonus then return value end --don't add bonuses to stats are set to 0
  
  --Modifiers from Creature:get_bonus()
  if possessor and possessor.baseType == "creature" then
    local bonus = 0
    local perc = 0
    if stat_type then
      bonus = bonus + possessor:get_bonus('spell_' .. stat_type)
      perc = perc + possessor:get_bonus('spell_' .. stat_type .. '_percent')
      if self.types then
        for _,stype in pairs(self.types) do
          bonus = bonus + possessor:get_bonus(stype .. '_spell_' .. stat_type)
          perc = perc + possessor:get_bonus(stype .. '_spell_' .. stat_type .. '_percent')
        end
      end
    end
    if stat ~= stat_type then --this is done because frequently the name of the stat is "damage" and the stat type is also "damage" and we don't want to apply the bonus twice
      bonus = bonus + possessor:get_bonus('spell_' .. stat)
      perc = perc + possessor:get_bonus('spell_' .. stat .. '_percent')
      if self.types then
        for _,stype in pairs(self.types) do
          bonus = bonus + possessor:get_bonus(stype .. '_spell_' .. stat)
          perc = perc + possessor:get_bonus(stype .. '_spell_' .. stat .. '_percent')
        end
      end
    end
    value = value + math.ceil(value*(perc/100))
    value = value + bonus
    if possessor ~= player and self.stat_bonuses_for_AI then
      for stat,amt in pairs(self.stat_bonuses_for_AI) do
        value = value+amt
      end
    end
  end
  
  --Modifiers from having other abilities:
  local spellBonuses = self.stat_bonuses_from_spells and self.stat_bonuses_from_spells[stat]
  if spellBonuses and possessor and possessor.baseType == "creature" then
    for spellID,amt in pairs(spellBonuses) do
      if possessor:has_spell(spellID) then
        value = value + amt
      end
    end --end spell for
  end --end spell bonuses
  
  --Modifiers from having settings enabled:
  local settingBonuses = self.stat_bonuses_from_settings and self.stat_bonuses_from_settings[stat]
  if settingBonuses then
    for settingID,amt in pairs(settingBonuses) do
      if self.settings[settingID] and self.settings[settingID].enabled then
        value = value + amt
      end
    end --end spell for
  end --end spell bonuses
  
  --Modifiers from creature stats
  local statBonuses = self.stat_bonuses_from_creature_stats and self.stat_bonuses_from_creature_stats[stat]
  if statBonuses and possessor and possessor.baseType == "creature" then
    for cstat,bonuses in pairs(statBonuses) do
      local possessorStat = possessor:get_stat(cstat)
      for statValue,bonus in pairs(bonuses) do
        if possessorStat >= statValue then
          value = value + bonus
        end
      end --end for statValue
    end --end statBonus for
  end --end if statBonuses
  
  --Modifiers from "every X" creature stats
  local perStatBonuses = self.stat_bonuses_per_x_creature_stats and self.stat_bonuses_per_x_creature_stats[stat]
  if perStatBonuses and possessor and possessor.baseType == "creature" then
    for cstat,bonuses in pairs(perStatBonuses) do
      local possessorStat = possessor:get_stat(cstat)
      for interval,bonus in pairs(bonuses) do
        local intervalCount = math.floor(possessorStat / interval)
        value = value + bonus*intervalCount
      end --end for statValue
    end --end statBonus for
  end --end if statBonuses
  
  --Modifiers from creature skills
  local skillBonuses = self.stat_bonuses_from_skills and self.stat_bonuses_from_skills[stat]
  if skillBonuses and possessor and possessor.baseType == "creature" then
    for skill,bonuses in pairs(skillBonuses) do
      local possessorSkill = possessor:get_skill(skill)
      for statValue,bonus in pairs(bonuses) do
        if possessorSkill >= statValue then
          value = value + bonus
        end
      end --end for statValue
    end --end statBonus for
  end --end if skillBonuses
  
  --Modifiers from "every X" creature skills
  local perSkillBonuses = self.stat_bonuses_per_x_skills and self.stat_bonuses_per_x_skills[stat]
  if perSkillBonuses and possessor and possessor.baseType == "creature" then
    for skill,bonuses in pairs(perSkillBonuses) do
      local possessorSkill = possessor:get_skill(skill)
      for interval,bonus in pairs(bonuses) do
        local intervalCount = math.floor(possessorSkill / interval)
        value = value + bonus*intervalCount
      end --end for statValue
    end --end statBonus for
  end --end if skillBonuses
  return round(value)
end

---Gets the possible upgrades for a spell
--@param use_requirements. If true, only return upgrades that you meet the requirements for, otherwise return all upgrades that aren't maxed out
--@return Table. A table of the possible upgrades, with the format {upgradeID=upgradeLevel}
function Spell:get_possible_upgrades(use_requirements)
  local upgrades = {}
  if not self.possible_upgrades then return upgrades end
  for id,details in pairs(self.possible_upgrades) do
    local current_upgrade_level = self.applied_upgrades[id] or 0
    local max_upgrade_level = #details
    if current_upgrade_level < max_upgrade_level and (self.possessor == player or not details.playerOnly) and (not use_requirements or self:can_upgrade(id)) then
      local level = current_upgrade_level + 1
      upgrades[id] = level
    end
  end
  return upgrades
end

---Determines whether you're able to perform an upgrade
--@param upgrade String. The ID of the upgrade
function Spell:can_upgrade(upgrade)
  local level = (self.applied_upgrades[upgrade] or 0)+1
  local details = (self.possible_upgrades and self.possible_upgrades[upgrade] and self.possible_upgrades[upgrade][level])
  local broad_details = (self.possible_upgrades and self.possible_upgrades[upgrade]) --Details of the upgrade path in general
  local possessor = self.possessor
  local canDo = true
  local returnText = false
  if details and possessor then
    --First, check requirements:
    local lvlReq = details.level_requirement or broad_details.level_requirement
    if lvlReq then 
      if possessor.level < lvlReq then
        local text = "Requires being level " .. lvlReq .. "."
        canDo = false
        returnText = (returnText and returnText .. "\n" .. text or text)
      end
    end
    local statReqs = details.creature_stat_requirements or broad_details.creature_stat_requirements
    if statReqs then
      for statID, req in pairs(statReqs) do
        if not possessor[statID] or possessor[statID] < req then
          local text = "Requires " .. ucfirst(statID) .. (req > 1 and " level " .. req or ".")
          canDo = false
          returnText = (returnText and returnText .. "\n" .. text or text)
        end
      end
    end
    local skillReqs = details.skill_requirements or broad_details.skill_requirements
    if skillReqs then
      for skillID, req in pairs(skillReqs) do
        local possLvl = possessor:get_skill(skillID)
        if possLvl < req then
          local skillName = possibleSkills[skillID].name
          local text = "Requires " .. skillName .. (req > 1 and " level " .. req or ".")
          canDo = false
          returnText = (returnText and returnText .. "\n" .. text or text)
        end
      end
    end
    local upgradeReqs = details.upgrade_requirements or broad_details.upgrade_requirements
    if upgradeReqs then
      for upgradeID,level in pairs(upgradeReqs) do
        if not self.applied_upgrades[upgradeID] or self.applied_upgrades[upgradeID] < level then
          local badName = self.possible_upgrades[upgradeID].name
          local text = "Requires " .. badName .. " upgrade" .. (level > 1 and " level " .. level or ".")
          canDo = false
          returnText = (returnText and returnText .. "\n" .. text or text)
        end
      end
    end
    local exclusions = details.upgrade_exclusions or broad_details.upgrade_exclusions
    if exclusions then
      for upgradeID,level in pairs(exclusions) do
        local badName = self.possible_upgrades[upgradeID].name
        local text = "Incompatible with " .. badName .. " upgrade" .. (level > 1 and " level " .. level or ".")
        returnText = (returnText and returnText .. "\n" .. text or text)
        if self.applied_upgrades[upgradeID] and (type(level) ~= "number" or self.applied_upgrades[upgradeID] >= level) then
          canDo = false
        end
      end
    end
    local ret,text = self:upgrade_requires(possessor,upgrade)
    if ret == false then
      canDo = false
      returnText = (returnText and returnText .. "\n" .. text or text)
    end
    --Then check costs:
    if self.free_upgrades < 1 then
      local cost = self:get_upgrade_cost(upgrade)
      local pointCost = cost.point_cost
      local upgrade_stat = cost.upgrade_stat or "spellPoints"
      if (possessor[upgrade_stat] or 0) + (self.spellPoints or 0) < pointCost then
        return false,returnText
      end
      if cost.item_cost then
        for _,item_details in pairs(cost.item_cost) do
          local amount = item_details.amount or 1
          local sortByVal = item_details.sortBy
          local _,_,has_amt = self.possessor:has_item(item_details.item,sortByVal)
          if has_amt < amount then
            return false,returnText
          end
        end --end item_cost for
      end --end if item_cost
    end
    return canDo,returnText
  elseif not possessor then --you can upgrade a free-floating spell at any point
    return true
  end --end if details and possessor
  return false
end

---Gets the costs associated with a spell upgrade
--@param upgradeID String. The ID of the upgrade
function Spell:get_upgrade_cost(upgradeID)
  local cost = {}
  local currLvl = self.applied_upgrades[upgradeID] or 0
  local details = (self.possible_upgrades and self.possible_upgrades[upgradeID] and self.possible_upgrades[upgradeID][currLvl+1])
  local broad_details = (self.possible_upgrades and self.possible_upgrades[upgradeID]) --Details of the upgrade path in general
  local possessor = self.possessor
  
  --Increase upgrade costs based on applied upgrades
  local applied_upgrades = 0
  for _,lvl in pairs(self.applied_upgrades) do
    applied_upgrades = applied_upgrades + lvl
  end
  local point_cost_increase_per_level = (self.point_cost_increase_per_upgrade or gamesettings.default_spell_point_cost_increase_per_upgrade or 0)
  local point_increase = applied_upgrades*point_cost_increase_per_level
  
  local pointCost = details.point_cost or broad_details.point_cost or self.upgrade_point_cost or 1
  if pointCost ~= 0 then pointCost = pointCost + point_increase end
  cost.point_cost = pointCost
  cost.upgrade_stat = self.upgrade_stat
  cost.upgrade_stat_name = self.upgrade_stat_name
  if self.upgrade_stat and not self.upgrade_stat_name then
    for _,stInfo in pairs(possibleSkillTypes) do
      if stInfo.upgrade_stat == self.upgrade_stat then
        cost.upgrade_stat_name = stInfo.upgrade_stat_name
        break
      end
    end
  end
  local item_cost = details.item_cost or broad_details.item_cost or self.upgrade_item_cost
  if item_cost then
    cost.item_cost = {}
    for _,item_details in ipairs(item_cost) do
      local item_cost_increase_per_level = (item_details.cost_increase_per_upgrade or self.item_cost_increase_per_upgrade or gamesettings.default_spell_item_cost_increase_per_upgrade or 0)
      local amount = (item_details.amount or 1)+(applied_upgrades*item_cost_increase_per_level)
      local sortByVal = item_details.sortBy
      local index = item_details.item .. (item_details.sortBy or "")
      cost.item_cost[index] = {item=item_details.item,sortBy=item_details.sortBy,amount=amount,displayName=item_details.displayName}
    end --end item_cost for
  end --end if item_cost
  return cost
end

---Applies an upgrade to a spell
--@param upgradeID String. The ID of the upgrade to apply
--@param force Boolean. If true, ignore upgrade requirements
--@return Boolean. Whether the upgrade was applied
function Spell:apply_upgrade(upgradeID,force)
  local upgrades = self:get_possible_upgrades()
  local level = upgrades[upgradeID]
  if level and (force or self:can_upgrade(upgradeID)) then
    local stats = self.possible_upgrades[upgradeID][level]
    for stat,value in pairs(stats) do
      if self[stat] then
        if stat == "stat_cost" then
          for scost, val in pairs(value) do
            self.stat_cost[scost] = (self.stat_cost[scost] or 0) + val
          end
        elseif stat == "items_consumed" then
          for itemID,val in pairs(value) do
            self.items_consumed[itemID] = (self.items_consumed[itemID] or 0) + val
          end
        else
          self[stat] = (type(value) == "number" and self[stat] + value or value)
        end
      elseif self.stats and self.stats[stat] then
        self.stats[stat].value = (type(value) == "number" and self.stats[stat].value + value or value)
        local bonusName = self.stats[stat].apply_to_bonus
        if bonusName then
          self.bonuses = self.bonuses or {}
          self.bonuses[bonusName] = self.stats[stat].value
        end
      end
    end
    if self.possessor then
      if self.free_upgrades > 0 then --if you have upgrade points, use those first rather than the spell point and item costs
        self.free_upgrades = self.free_upgrades - 1
      else
        local cost = self:get_upgrade_cost(upgradeID)
        local point_cost = cost.point_cost
        if self.spellPoints then
          if self.spellPoints < point_cost then
            point_cost = point_cost - self.spellPoints
            self.spellPoints = 0
          else
            self.spellPoints = self.spellPoints - point_cost
            point_cost = 0
          end
        end
        if point_cost > 0 then
          local upgrade_stat = cost.upgrade_stat or "spellPoints"
          self.possessor.spellPoints = self.possessor[upgrade_stat] - point_cost
        end
        if cost.item_cost then
          for _,item_details in pairs(cost.item_cost) do
            local amount = item_details.amount or 1
            local sortByVal = item_details.sortBy
            local item = self.possessor:has_item(item_details.item,sortByVal)
            self.possessor:delete_item(item,amount)
          end
        end
      end --end if upgrade points or not
    end --end if self possessor
    self.applied_upgrades[upgradeID] = level
    return true
  end
  return false
end

---Get upgrade items that can be applied to a spell
--@possessor Creature. The possessor of the spell.
function Spell:get_appliable_items(possessor)
  local upgrade_items = {}
  local alreadyChecked = {}
  for _,item in ipairs(possessor:get_inventory()) do
    if item.applied_to_spell_types then
      for _,sType in ipairs(item.applied_to_spell_types) do
        if self:is_type(sType) then
          for stat,bonus in pairs(item.applied_to_spell_bonus) do
            if stat == "spellPoints" and count(self:get_possible_upgrades()) == 0 then
              break
            end
            if self[stat] or (self.stats and self.stats[stat] and not self.stats[stat].no_upgrade and (not self.stats[stat].max or self.stats[stat].max > self.stats[stat].value)) then --Check to make sure at least one bonus can apply to this spell
              upgrade_items[#upgrade_items+1] = {item=item,bonuses=item.applied_to_spell_bonus,amount_required=(item.applied_to_spell_required_amount or 1)}
              alreadyChecked[item.id .. (item.sortBy and item[item.sortBy] or "")] = true
              break
            end
          end
        end
      end
    end
  end
  
  if self.appliable_items then
    for _,itemDetails in ipairs(self.appliable_items) do
      if not alreadyChecked[itemDetails.itemID .. (itemDetails.sortBy and itemDetails.sortBy or "")] then
        if itemDetails.bonuses then
          for stat,bonus in pairs(itemDetails.bonuses) do
            if stat == "spellPoints" and count(self:get_possible_upgrades()) == 0 then
              break
            end
            if self[stat] or (self.stats and self.stats[stat] and not self.stats[stat].no_upgrade and (not self.stats[stat].max or self.stats[stat].max > self.stats[stat].value)) then --Check to make sure at least one bonus can apply to this spell
              upgrade_items[#upgrade_items+1] = itemDetails
              alreadyChecked[itemDetails.itemID .. (itemDetails.sortBy and itemDetails.sortBy or "")] = true
              break
            end
          end
        end
      end
    end
  end

  if self.arcana then
    for _,arcID in ipairs(self.arcana) do
      local arcDetails = arcana_list[arcID]
      if arcDetails.appliable_items then
        for _,itemDetails in ipairs(arcDetails.appliable_items) do
          if not alreadyChecked[itemDetails.itemID .. (itemDetails.sortBy and itemDetails.sortBy or "")] then
            if itemDetails.bonuses then
              for stat,bonus in pairs(itemDetails.bonuses) do
                if stat == "spellPoints" and count(self:get_possible_upgrades()) == 0 then
                  break
                end
                if self[stat] or (self.stats and self.stats[stat] and not self.stats[stat].no_upgrade and (not self.stats[stat].max or self.stats[stat].max > self.stats[stat].value)) then --Check to make sure at least one bonus can apply to this spell
                  upgrade_items[#upgrade_items+1] = itemDetails
                  alreadyChecked[itemDetails.itemID .. (itemDetails.sortBy and itemDetails.sortBy or "")] = true
                  break
                end
              end
            end
          end
        end
      end
    end
  end
  return upgrade_items
end

---Apply an item to a spell, gaining its bonuses
--@param item Item. The item to apply
function Spell:apply_item(item)
  --TODO: custom apply code
  if item.applied_to_spell_bonus then
    for stat,bonus in pairs(item.applied_to_spell_bonus) do
      if self[stat] then
        if type(self[stat]) == "number" and type(bonus) == "number" then
          self[stat] = self[stat] + bonus
        else
          self[stat] = bonus
        end
      elseif self.stats and self.stats[stat] then
        if type(self.stats[stat].value) == "number" and type(bonus) == "number" then
          self.stats[stat].value = self.stats[stat].value + bonus
          if self.stats[stat].max then self.stats[stat].value = math.min(self.stats[stat].max,self.stats[stat].value) end
        else
          self.stats[stat].value = true
        end
        local bonusName = self.stats[stat].apply_to_bonus
        if bonusName then
          self.bonuses = self.bonuses or {}
          self.bonuses[bonusName] = self.stats[stat].value
        end
      end
    end
    item:delete(nil,(item.applied_to_spell_required_amount or 1))
    return
  end
  
  --If the appliability is defined in the spell or the arcana:
  local upgrade_items = self:get_appliable_items(self.possessor)
  for _,itemInfo in ipairs(upgrade_items) do
    if itemInfo.item == item.id and itemInfo.sortBy == item[item.sortBy] and item.amount >= (itemInfo.amount or 1) then
      --TODO: custom applied code
      if itemInfo.bonuses then
        for stat,bonus in pairs(itemInfo.bonuses) do
          if self[stat] then
            if type(self[stat]) == "number" and type(bonus) == "number" then
              self[stat] = self[stat] + bonus
            else
              self[stat] = bonus
            end
          elseif self.stats and self.stats[stat] then
            if type(self.stats[stat]) == "number" and type(bonus) == "number" then
              self.stats[stat].value = self.stats[stat].value + bonus
            else
              self.stats[stat].value = true
            end
            local bonusName = self.stats[stat].apply_to_bonus
            if bonusName then
              self.bonuses = self.bonuses or {}
              self.bonuses[bonusName] = self.stats[stat].value
            end
          end
        end
      end
    end
  end
end

---Placeholder for the upgrade_requires() callback, used to determine if the creature meets the requirements for upgrading the spell
--@param possessor Creature. The creature who's trying to upgrade the spell
--@param upgradeID String. The ID of the upgrade
--@return true
function Spell:upgrade_requires(possessor,upgradeID)
  if possibleSpells[self.id].upgrade_requires then return possibleSpells[self.id].upgrade_requires(self,possessor,upgradeID) end
  return true
end

---Gets potential targets of a spell. Uses the spell's own get_potential_targets() function if it has one, or defaults to seen creatures if it doesn't and it's a creature-spell
--@param caster Creature. The caster of the spell
--@param previous_targets Table. The already-targeted targets of the spell, if applicable
--@return Table. A list of potential targets
function Spell:get_potential_targets(caster,previous_targets)
  local targets = {}
  if possibleSpells[self.id].get_potential_targets then
    targets = possibleSpells[self.id].get_potential_targets(self,caster,previous_targets)
    if not targets then targets = {} end
    return targets
  end
  if self.target_type == "creature" then
    for _,creat in pairs(caster:get_seen_creatures()) do
      local dist = ((self.range or self.min_range) and calc_distance(caster.x,caster.y,creat.x,creat.y) or 0)
      if caster:does_notice(creat) and (self.range == nil or calc_distance(caster.x,caster.y,creat.x,creat.y) <= self.range) and (self.min_range == nil or dist >= self.min_range) then
        targets[#targets+1] = {x=creat.x,y=creat.y}
      end --end range if
    end --end creature for
    if self.can_target_self then
      targets[#targets+1] = {x=caster.x,y=caster.y}
    end
    return targets
  end --end creature if
  return {}
end

--Get settings that are currently available for this spell
--@return Table. A list of settings
function Spell:get_all_settings()
  local settings = {}
  if self.settings then
    for settingID,info in pairs(self.settings) do
      if self:setting_available(settingID) then
        settings[settingID] = info
      end --end setting available if
    end --end settings for
  end --end if settings
  return settings
end

---Get the value of a spell setting
--@return Boolean. Whether the setting is set or not
function Spell:get_setting(settingID)
  if self:setting_available(settingID) then
    return self.settings[settingID].enabled
  end
  return false
end

---Checks whether a spell setting is available
--@return Boolean. Whether the setting is available or not
function Spell:setting_available(settingID)
  if self.settings and self.settings[settingID] then
    local setting = self.settings[settingID]
    if setting.requires_upgrades then
      for upgradeID,req in pairs(setting.requires_upgrades) do
        local applied = self.applied_upgrades[upgradeID]
        if not applied or (type(applied) == "number" and applied < req) then
          return false
        end --end applied if
      end --end upgrade for
    end --end requires upgrades if
    return true
  else --if no settings, or doesn't have a setting with that ID
    return false
  end
end

---Toggle a setting on or off
--@param settingID String. The ID of the setting
--@return Boolean. The setting's new value, false for off, true for on
function Spell:toggle_setting(settingID)
  if self:setting_available(settingID) then
    self.settings[settingID].enabled = not self.settings[settingID].enabled
    if self.settings[settingID].setting_exclusions then
      for _,exclusionID in pairs(self.settings[settingID].setting_exclusions) do
        if self:setting_available(exclusionID) then
          self.settings[exclusionID].enabled = false
        end
      end
    end --end exlucions if
  end
end

---Update the charges for a spell
--@param amount Number. The amount to change it by
--@param silent Boolean. If true, don't show a popup
function Spell:update_charges(amount,silent)
  if self.from_item and self.from_item.charges then
    return self.from_item:update_charges(amount,silent)
  end
  self.charges = self.charges + amount
  if self.max_charges and self.charges > self:get_stat('max_charges') then self.charges = self:get_stat('max_charges') end
  if self.charges < 0 then self.charges = 0 end
  if self.charges == 0 and self.possessor == player and not currGame.tutorialsSeen['lowSpells'] and currMap.mapType ~= "home" then
    show_tutorial('lowSpells')
  end
  --Add item popup:
  if self.possessor == player and not silent then
    local popup1 = Effect('dmgpopup')
    popup1.symbol = (amount > 0 and "+" or "") .. (amount ~= 1 and amount or "")
    if amount > 0 then
      popup1.color = {r=0,g=255,b=0,a=150}
    else
      popup1.color = {r=255,g=0,b=0,a=150}
    end
    local tileMod = round(fonts.mapFontWithImages:getWidth(popup1.symbol)/2)
    popup1.xMod = -tileMod
    local popup2 = Effect('dmgpopup')
    popup2.image_name = self.image_name or self.id
    popup2.imageType = "spell"
    popup2.xMod = tileMod
    popup2.speed = popup1.speed
    if (self.use_color_with_tiles ~= false or gamesettings.always_use_color_with_tiles) and self.color then
      popup2.color = {r=self.color.r,g=self.color.g,b=self.color.b,a=150}
    else
      popup2.color = {r=255,g=255,b=255,a=150}
    end
    popup1.paired = popup2
    popup2.paired = popup1
    currMap:add_effect(popup1,self.possessor.x,self.possessor.y)
    currMap:add_effect(popup2,self.possessor.x,self.possessor.y)
  end
end