Faction = Class{}

function Faction:init(data)
	for key, val in pairs(data) do
		self[key] = data[key]
	end
  self.baseType = "faction"
	return self
end

function Faction:is_enemy(creature)
  --First things first, never consider fellow faction members an enemy (unless you're an infighting faction)
  if not self.attackOwnFaction and creature:is_faction_member(self.id) then
    return false
  end
  --Secondly, if you just attack everyone who's not a friend, we can just assume you're an enemy
  if self.attackAllNeutral == true and not self:is_friend(creature) then
    return true
  end
  --Next, if the creature is a player ally and the faction is always hostile to the player regardless of favor and membership, we can just assume they're an enemy
  if creature.playerAlly == true and self.alwaysAttackPlayer == true then
    return true
  end
  --Next, account for enemy factions:
  if self.enemyFactions then
    for _,fac in pairs(self.enemyFactions) do
      if creature:is_faction_member(fac) then
        return true
      end --end is_type if
    end --end faction for
  end
  --Next, account for enemy creature types:
  if self.enemyTypes then
    for _,ctype in pairs(self.enemyTypes) do
      if creature:is_type(ctype) then
        return true
      end --end is_type if
    end --end ctype for
  end --end if self.enemyTypes
  --Next, look if the creature's favor with your faction is low enough to be considered an enemy
  if self.hostileThreshold and creature.favor and (creature.favor[self.id] or 0) < self.hostileThreshold then
    return true
  end
  --Next, if the creature is a player or a friend of the player, we'll look at some player-specific stuff
  if creature.playerAlly then
    --By default, everyone finds the player an enemy if they're not explicitly a friend
    if not self.attackEnemyPlayerOnly and not self:is_friend(player) then
      return true
    end
    --We don't need to look into if the player's otherwise an enemy, because that'll be handled by the above sections
  end --end playerally if
  
  --Finally, if none of the above was true, they're not your enemy
  return false
end

function Faction:is_friend(creature)
  --First things first, always consider fellow faction members a friend (unless you're an infighting faction)
  if not self.attackOwnFaction and creature:is_faction_member(self.id) then
    return true
  end
  --Next, look at factions:
  if self.friendlyFactions then
    for _,fac in pairs(self.friendlyFactions) do
      if creature:is_faction_member(fac) then
        return true
      end --end is_type if
    end --end faction for
  end --end if self.friendlyFactions
  --Next, account for friendly creature types:
  if self.friendlyTypes then
    for _,ctype in pairs(self.friendlyTypes) do
      if creature:is_type(ctype) then
        return true
      end --end is_type if
    end --end ctype for
  end --end if self.friendlyTypes
  --Finally, look if the creature's favor with your faction is high enough to be considered an friend
  if self.hostileThreshold and creature.favor and (creature.favor[self.id] or 0) > self.friendlyThreshold then
    return true
  end
  return false
end

function Faction:join(creature)
  creature = creature or player
  if not creature:is_faction_member(self.id) then
    creature.factions[#creature.factions+1] = self.id
  end
end

function Faction:can_join(creature)
  creature = creature or player
  local canJoin = true
  local reasons = nil
  if self.neverJoin then
    return false,"This faction does not accept new members."
  end
  if creature.favor[self.id] < self.joinThreshold then
    reasons = (reasons and reasons .. " " or "") .. "You need at least " .. self.joinThreshold .. " favor to join."
    canJoin = false
  end
  for _,enemy in ipairs(self.enemyFactions) do
    if player:is_faction_member(enemy) then
      reasons = (reasons and reasons .. " " or "") .. "You're a member of the enemy faction " .. factions[enemy].name .. "."
      canJoin = false
    end
  end
  if self.join_requirements then
    local bool,rejectionText = self:join_requirements(creature)
    if bool == false then
      canJoin = false
      if rejectionText then
        reasons = (reasons and reasons .. " " or "") .. rejectionText
      end
    end
  end --end join_requirements if
  return canJoin,reasons
end

function Faction:teach_spell(spellID,creature)
  creature = creature or player
  if creature:has_spell(spellID) then return false end
  
  --Get the spell info:
  local spellInfo = nil
  for _,s in ipairs(self.teaches_spells) do
    if s.spell == spellID then
      spellInfo = s
      break
    end
  end
  if not spellInfo then return false end
  
  --Pay the price:
  if spellInfo.moneyCost then
    creature.money = creature.money - spellInfo.moneyCost
  end
  if spellInfo.favorCost then
    creature.favor[self.id] = creature.favor[self.id] - spellInfo.favorCost
  end
  --Teach it, finally:
  creature.spells[#creature.spells+1] = spellID
end