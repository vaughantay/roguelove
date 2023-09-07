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
    self.charges = self.max_charges
  end
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
  if self.active then --If the spell is already active, don't cast it
    if self.no_manual_deactivate then
      output:out("That ability can't be manually deactivated.")
      return false
    end
    local data = caster.active_spells[self.id]
    local t = data.target
    local mp = data.ignoreMP
    local cd = data.ignoreCooldowns
    return self:finish(t, caster, cd, mp)
  end
  
  --First, check whether we can use the spell:
  local canUse, result = self:can_use(target,caster,ignoreCooldowns,ignoreMP)
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
--@param ignoreMP Boolean. If set to true, this will make the spell not use MP when cast
--@return Boolean. Whether the spell was successfully able to be cast or not.
function Spell:use(target, caster, ignoreCooldowns, ignoreMP)
  if self.active then --If the spell is already active, don't cast it
    if self.no_manual_deactivate then
      output:out("That ability can't be manually deactivated.")
      return false
    end
    local data = caster.active_spells[self.id]
    local t = data.target
    local mp = data.ignoreMP
    local cd = data.ignoreCooldowns
    return self:finish(t, caster, cd, mp)
  end
  --First, check all requirements:
  local canUse, result = self:can_use(target,caster,ignoreCooldowns,ignoreMP)
  if canUse == false then
    if caster == player and result then
      output:out(result)
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
    if #target == 1 then target = target[1] end --if being passed only a single target, just set that as the target and don't loop
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
          local mp = data.ignoreMP
          local cd = data.ignoreCooldowns
          data.spell:finish(t, caster, cd, mp)
        end
      end
      if self.sound and player:can_see_tile(caster.x,caster.y) then output:sound(self.sound) end
      if caster == player then update_stat('ability_used',self.name) end
      self.uses = self.uses+1
      --Add cooldown
      if ((self.cooldown and self.cooldown > 0) or (caster ~= player and self.AIcooldown and self.AIcooldown > 0)) and not ignoreCooldowns and not self.toggled then --Don't add cooldown to a toggled spell, add it when the spell is finished
        caster.cooldowns[self.name] = (caster ~= player and self.AIcooldown or self.cooldown)
      end
      --Decrease MP
      if not ignoreMP and caster.mp and self.cost then
        caster.mp = caster.mp - self.cost
      end
      --Decrease charges
      if not ignoreMP and self.charges then
        self.charges = self.charges - 1
      end
      --If it's a toggled spell, save necessary info to the caster
      if self.toggled then
        caster.active_spells[self.id] = {caster=caster,target=target,ignoreMP=ignoreMP,ignoreCooldowns=ignoreCooldowns,turns=0,spell=self}
        self.active = true
      end
    end --end false/nil if
		return (result == nil and true or result) -- this looks weird, but it's so that spells return false by default if they don't return anything
	end
end

---Checks to see if the spell can be used right now
--@param target Entity. The target of the spell.
--@param caster Creature. The caster of the spell.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the spell is on a cooldown.
--@param ignoreMP Boolean. If set to true, this will make the spell not use MP when cast
--@return Boolean. Whether the spell can be used right now
function Spell:can_use(target, caster, ignoreCooldowns, ignoreMP)
  local req, reqtext = self:requires(caster)
  local targ, targtext = self:target_requires(target,player)
  if req == false then
    return false,(reqtext or "You can't use that ability right now.")
	elseif (not ignoreCooldowns and caster.cooldowns[self.name]) then
		return false,"You can't use that ability again for another " .. caster.cooldowns[self.name] .. " turns."
  elseif not ignoreMP and caster.mp and self.cost and self.cost > caster.mp then
		return false,"You don't have enough magic points to use that ability."
  elseif not ignoreMP and self.charges and self.charges < 1 then
		return false,"You're out of charges for that ability."
  elseif targ == false then
    return false,targtext or "You've selected an invalid target for this ability."
  elseif caster:callbacks('casts',target,self,ignoreCooldowns) == false then --We're hoping the callback itself will provide any necessary feedback
    return false
  end
  return true
end

---Placeholder for the advance_active() callback, which is called every turn a spell is active
--@param target Entity. The target of the spell.
--@param caster Creature. The caster of the spell.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the spell is on a cooldown.
--@param ignoreMP Boolean. If set to true, this will make the spell not use MP when cast
--@return Boolean. False if the spell ends, true otherwise
function Spell:advance_active(target,caster, ignoreCooldowns, ignoreMP)
  local data = caster.active_spells[self.id]
  target = target or data.target
  ignoreCooldowns = ignoreCooldowns or data.ignoreCooldowns
  ignoreMP = ignoreMP or data.ignoreMP
  --First check to see if we have enough MP:
  if not ignoreMP and self.cost_per_turn then
    if caster.mp < self.cost_per_turn then
      self:finish(target, caster, ignoreCooldowns, ignoreMP)
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
  if self.cost_per_turn then caster.mp = caster.mp - self.cost_per_turn end
  --Increment turn count
    data.turns = (data.turns or 0) + 1
  --if turn count is too high, turn it off
  if self.max_active_turns and data.turns >= self.max_active_turns then
    self:finish(target, caster, ignoreCooldowns, ignoreMP)
    return false
  end
  return true
end

---Placeholder for the finish() callback, which is called when a spell is toggled off or stops being channeled.
--@param target Entity. The target of the spell.
--@param caster Creature. The caster of the spell.
--@param ignoreCooldowns Boolean. If set to true, this will ignore whether or not the spell is on a cooldown.
--@param ignoreMP Boolean. If set to true, this will make the spell not use MP when cast
function Spell:finish(target,caster, ignoreCooldowns, ignoreMP)
  local data = caster.active_spells[self.id]
  target = target or data.target
  ignoreCooldowns = ignoreCooldowns or data.ignoreCooldowns
  ignoreMP = ignoreMP or data.ignoreMP
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
    caster.cooldowns[self.name] = (caster ~= player and self.AIcooldown or self.cooldown)
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
  if possibleSpells[self.id].decide then return possibleSpells[self.id].decide(self,target,caster,use_type) end
  return target --default to already-selected target
end

---Placeholder for the requires() callback, used to determine if the creature meets the requirements for using the spell
--@param possessor Creature. The creature who's trying to use the spell.
--@return true
function Spell:requires(possessor)
  if possibleSpells[self.id].requires then return possibleSpells[self.id].requires(self,possessor) end
  return true
end

---Placeholder for the target_requires() callback, used to determine if the attempted target of the spell is acceptable
--@param target Entity. The attempted target of the spell.
--@param caster Creature. The creature who's trying to use the spell.
--@param target_number Number. Which target this is
--@return true
function Spell:target_requires(target,caster,target_number)
  if not target then return true end --If there's no target, then say true because it's either a nontargeted spell or we're just starting to target now
  if possibleSpells[self.id].target_requires then
    if #target == 1 then target = target[1] end --if there's only one target, bypass the loop
    if #target == 0 then
      return possibleSpells[self.id].target_requires(self,target,caster,(target_number or 1))
    else
      for tnum,t in ipairs(target) do
        return possibleSpells[self.id].target_requires(self,t,caster,tnum)
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
--@param possessor Creature. The creature to look at when determine the spell's stats
--@return Anything. Whatever the stat's value is (or false if not set)
function Spell:get_stat(stat,possessor)
  possessor = possessor or self.possessor
  local value = false
  if self[stat] then 
    value = self[stat]
  elseif self.stats and self.stats[stat] then
    value = self.stats[stat].value
  else
    return false
  end
  
  if type(value) ~= "number" then
    return value
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
  
  --Modifiers from get_bonus()
  if self.stats[stat] and self.stats[stat].stat_type and possessor and possessor.baseType == "creature" then
    value = value + possessor:get_bonus('spell_' .. self.stats[stat].stat_type)
  end
  
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
    if current_upgrade_level < max_upgrade_level and (self.possessor == player or not details.playerOnly) and (not use_requirements or self:can_upgrade(id,current_upgrade_level+1)) then
      local level = current_upgrade_level + 1
      upgrades[id] = level
    end
  end
  return upgrades
end

---Determines whether you're able to perform an upgrade
--@param upgradeID String. The ID of the upgrade
--@param level Number. The level of the upgrade
function Spell:can_upgrade(upgrade,level)
  local details = (self.possible_upgrades and self.possible_upgrades[upgrade] and self.possible_upgrades[upgrade][level])
  local broad_details= (self.possible_upgrades and self.possible_upgrades[upgrade]) --Details of the upgrade path in general
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
      local pointCost = details.spell_point_cost or 1
      if (possessor.spellPoints or 0) + (self.spellPoints or 0) < pointCost then
        return false,returnText
      end
      if details.item_cost then
        for _,item_details in ipairs(details.item_cost) do
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

---Applies an upgrade to a spell
--@param upgradeID String. The ID of the upgrade to apply
--@param force Boolean. If true, ignore upgrade requirements
--@return Boolean. Whether the upgrade was applied
function Spell:apply_upgrade(upgradeID,force)
  local upgrades = self:get_possible_upgrades()
  local level = upgrades[upgradeID]
  if level and (force or self:can_upgrade(upgradeID,level)) then
    local stats = self.possible_upgrades[upgradeID][level]
    for stat,value in pairs(stats) do
      if self[stat] then
        self[stat] = (type(value) == "number" and self[stat] + value or value)
      elseif self.stats and self.stats[stat] then
        self.stats[stat].value = (type(value) == "number" and self.stats[stat].value + value or value)
        local bonusName = self.stats[stat].apply_to_bonus
        if bonusName then
          self.bonuses = self.bonuses or {}
          self.bonuses[bonusName] = self.stats[stat].value
        end
      end
    end
    self.applied_upgrades[upgradeID] = level
    if self.possessor then
      if self.free_upgrades > 0 then --if you have upgrade points, use those first rather than the spell point and item costs
        self.free_upgrades = self.free_upgrades - 1
      else
        local spell_point_cost = stats.spell_point_cost or 1
        if self.spellPoints then
          if self.spellPoints < spell_point_cost then
            spell_point_cost = spell_point_cost - self.spellPoints
            self.spellPoints = 0
          else
            self.spellPoints = self.spellPoints - spell_point_cost
            spell_point_cost = 0
          end
        end
        self.possessor.spellPoints = self.possessor.spellPoints - spell_point_cost
        if stats.item_cost then
          for _,item_details in pairs(stats.item_cost) do
            local amount = item_details.amount or 1
            local sortByVal = item_details.sortBy
            local item = self.possessor:has_item(item_details.item,sortByVal)
            self.possessor:delete_item(item,amount)
          end
        end
      end --end if upgrade points or not
    end --end if self possessor
    return true
  end
  return false
end

---Placeholder for the upgrade_requires() callback, used to determine if the creature meets the requirements for using the spell
--@param possessor Creature. The creature who's trying to upgrade the spell
--@param upgradeID String. The ID of the upgrade
--@return true
function Spell:upgrade_requires(possessor,upgradeID)
  if possibleSpells[self.id].upgrade_requires then return possibleSpells[self.id].upgrade_requires(self,possessor,upgradeID) end
  return true
end

---Gets potential targets of a spell. Uses the spell's own get_potential_targets() function if it has one, or defaults to seen creatures if it doesn't and it's a creature-spell
--@param caster Creature. The caster of the spell
--@param target_number Number. Which target of the spell it is
function Spell:get_potential_targets(caster,target_number)
  local targets = {}
  if possibleSpells[self.id].get_potential_targets then
    targets = possibleSpells[self.id].get_potential_targets(self,caster,target_number)
    if not targets then targets = {} end
    return targets
  end
  if self.target_type == "creature" then
    for _,creat in pairs(caster:get_seen_creatures()) do
      if caster:does_notice(creat) and (self.range == nil or calc_distance(caster.x,caster.y,creat.x,creat.y) <= self.range) then
        targets[#targets+1] = {x=creat.x,y=creat.y}
      end --end range if
    end --end creature for
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

--Toggle a setting on or off
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