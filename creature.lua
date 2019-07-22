Creature = Class{}

--Initiates a creature. Don't call this explicitly, it's called when you create a new creature.
--@param self The ID of the creature you want to create.
--@param level The level to set the creature to (optional)
--@return The creature itself.
function Creature:init(creatureType,level)
  local data = possibleMonsters[creatureType]
	for key, val in pairs(data) do
    if type(val) ~= "function" then
      self[key] = data[key]
    end
	end
  if self.gender == "either" then
    self.gender = (random(0,1) == 1 and 'male' or 'female')
  elseif not self.gender then
    self.gender = "neuter"
  end
  self.id = creatureType
	self.level = level or self.level or currMap.depth
  self.max_hp = tweak(self.max_hp)
	self.hp = self.max_hp
	self.conditions = {}
	self.spells = self.spells or {}
	self.cooldowns = {}
  self.thralls = {}
  self.checked = {}
	self.path = nil
	self.baseType = "creature"
  self.types = self.types or {}
  self.speed = self.speed or 100
  self.energy = self.speed
  self.color = copy_table(self.color)
  self.color.a = self.color.a or 255
  if self.animated and self.spritesheet then
    self.image_frame=1
  end
  self.animation_time = (self.animation_time and tweak(self.animation_time) or 0.5)
  if self.image_varieties then
    self.image_variety = random(1,self.image_varieties)
    self.image_name = self.id .. self.image_variety
    if not images['creature' .. self.image_name] then
      self.image_name = nil
    end
  end
  self.xMod,self.yMod = 0,0
  if (self.ranged_attack) then
    local ranged = rangedAttacks[self.ranged_attack]
    if ranged and ranged.max_charges then
      self.ranged_charges = ranged.max_charges
    end
  end --end ranged attack if
	if (self.isPlayer ~= true) then --used by NPCs only:
    self.fear = 0
		self.alert = 0 -- used by NPCs only, alertness countdown
		self.target=nil
    self.notices = {}
    self.shitlist = {}
    self.ignoring = {}
    self.lastSawPlayer = {x=nil,y=nil}
		self.aggression = self.aggression or 100 -- used by NPCs only, chance they'll be hostile when seeing player
    self.memory = self.memory or 10 --turns they remember seeing an enemy
    if possibleMonsters[self.id].nameGen then self.properName = possibleMonsters[self.id].nameGen(self)
    elseif self.nameType then self.properName = namegen:generate_name(self.nameType,self) end
	end
  
	return self
end

--Get the name of a creature
--@param self The creature itself
--@param full Whether to display the creature name after the proper name (optional) 
--@param force True/False. If set to true, will force display the name, even if the player can't see it (optional)
--@return The creature's name
function Creature:get_name(full,force)
  if force ~= true and not (player:can_sense_creature(self) or player:does_notice(self)) then return "something" end
	if (full == true) then
		if (self.properName ~= nil) then
			return self.properName .. ", " .. ucfirst(self.name)
		else
			return ucfirst(self.name) 
		end
	elseif (self.properName ~= nil) then
		return self.properName
	else
		return (self.properNamed ~= true and "the " or "") .. self.name
	end
end

--Get the pronoun of a creature
--@param self The creature itself
--@param ptype The pronoun type. n = nominative, p = possessive, o = objective
--@return The pronoun
function Creature:get_pronoun(ptype)
	ptype = ptype or 'n'
	if (self.gender == "male") then
		if (ptype == 'n') then return 'he' end
		if (ptype == 'p') then return 'his' end
		if (ptype == 'o') then return 'him' end
	elseif (self.gender == "female") then
		if (ptype == 'n') then return 'she' end
		if (ptype == 'p') then return 'her' end
		if (ptype == 'o') then return 'her' end
	elseif (self.gender == "neuter") then
		if (ptype == 'n') then return 'it' end
		if (ptype == 'p') then return 'its' end
		if (ptype == 'o') then return 'it' end
  else
    if (ptype == 'n') then return 'they' end
		if (ptype == 'p') then return 'their' end
		if (ptype == 'o') then return 'them' end
	end
  return "" --return an empty string if something went wrong, so there won't be a "concating nil" error
end

--Get the max HP of a creature
--@param self The creature itself
--@return Number, the max HP
function Creature:get_mhp()
	return self.max_hp+self:get_bonus('mhp')
end

--Change the HP of a creature
--@param self The creature itself
--@param amt A number, can be positive or negative.
function Creature:updateHP(amt)
  local alreadyDead = false
  if self.hp < 1 then alreadyDead = true end
	self.hp = self.hp + amt
	if (self.hp > self:get_mhp()) then
		self.hp = self:get_mhp()
	end
  if not alreadyDead then
    local p = Effect('dmgpopup',self.x,self.y)
    if (amt > 0) then
      p.color = {r=0,g=255,b=0,a=255}
      currMap:add_effect(Effect('animation','floatingpluses',5,self,{r=0,g=255,b=0,a=255},false,true),self.x,self.y)
    end --make it green if it's healing
    p.symbol = (amt > 0 and "+" or "") .. amt
    currMap:add_effect(p,self.x,self.y)
  end
end

--Damage a creature
--@param self Creature. The creature itself
--@param amt Number. The damage to do.
--@param attacker Entity. The source of the damage.
--@param damage_type String. The damage type of the attack. (optional)
--@param is_melee True/False. If set to true, this counts as a melee attack and can damage a ghost. (optional)
--@param noSound True/False. If set to true, no damage type sound will be played. (optional)
--@return Number. The final damage done.
function Creature:damage(amt,attacker,damage_type,is_melee,noSound)
  amt = math.ceil(amt) --just in case! to prevent fractional damage
  require "data.damage_types"
  damage_type = damage_type or "physical"
  --Don't damage ghosts if you're, f'rex, a spell or something
  if self:is_type('ghost') and is_melee ~= true then return 0 end
  
	if (self.armor ~= nil) then
		amt = amt - self.armor
	end
	amt = amt - self:get_bonus('armor')
  amt = amt + self:get_weakness(amt,damage_type)
  amt = amt - self:get_resistance(amt,damage_type)
  if (amt < 1) then amt = 1 end
  local bool,ret = self:callbacks('damaged',attacker,amt,damage_type,is_melee)
	if (bool ~= false) then
    if #ret > 0 then --handle possible returned damage values
      local count = 0
      local dmg = 0
      for _,val in pairs(ret) do --add up all returned damage values
        if type(val) == "number" then count = count + 1 dmg = dmg + val end
      end
    if count > 0 then amt = math.ceil(dmg/count) end --final damage is average of all returned damage values
    end
    if calc_distance(self.x,self.y,player.x,player.y) > player.perception*2 then
      amt = math.ceil(amt/10)
    elseif not player:can_see_tile(self.x,self.y) and (not attacker or not player:can_see_tile(attacker.x,attacker.y)) then
      amt = math.ceil(amt/4)
    end --if you're far away from the player
		self:updateHP(-amt)
    self.fear = self.fear + math.ceil(100*(amt/self:get_mhp())) --increase fear by % of MHP you just got damaged by
    if attacker then
      if attacker.baseType == "creature" and self:does_notice(attacker) == false then 
        if attacker == player then achievements:disqualify('hostile_only') end
        self:notice(attacker,false,true)
      end
      if self ~= player then --ignore this stuff for player because this is AI enemy stuff
        --Add the guy who attacked you to your list of enemies, if they're not already in an enemy faction
        --First, if it's a spell, realize the caster of the spell is the attacker:
        if (attacker.source and attacker.source.baseType == "creature") then attacker = attacker.source
        elseif (attacker.caster and attacker.caster.baseType == "creature") then attacker = attacker.caster end
        local hostile = false
        if attacker.baseType == "creature" and not (self.shitlist[attacker] or (self.ignoring and self.ignoring[attacker]) or self == attacker) then 
          hostile = self:become_hostile(attacker)
        end
        if hostile and (self.target == nil or self.target.baseType ~= "creature") then self.target = attacker end
      end --end self == player if
    end --end if attacker if
    --Set the "lastattacker" value to be who attacked you, for death purposes
    if attacker and attacker.baseType == "creature" then self.lastAttacker = attacker end
    if (self.hp < 1) then
      if damage_type == "explosive" then
        self.explosiveDeath = true
      end
    end
    if amt > 0 and damage_type and damage_types[damage_type] then
      damage_types[damage_type](self,attacker)
      if not noSound and player:can_see_tile(self.x,self.y) then
        output:sound(damage_type .. 'damage')
      end
    end
    if self == player and self.hp > 0 then
      output:shake(math.max(math.min((amt/self.hp)*25,25),2),.5)
    end
		return amt
	else
		return 0
	end
end

--Give a condition to a creature
--@param self Creature. The creature itself
--@param name String. The ID of the condition.
--@param turns Number. How many turns the condition should last.
--@param applier Entity. Who applied the condition. (optional)
--@param force True/False. Whether to force-apply the condition. (optional)
--@return True/False. Whether the condition was applied
function Creature:give_condition(name,turns,applier,force)
  if not force and self:is_type('ghost') and conditions[name].ghost ~= true then return false end
  local ap = ap
	if conditions[name]:apply(self,applier,turns) ~= false then
    self.conditions[name]=(type(ap) == "number" and ap or turns)
  end
	return true
end

--Called every turn, this advances all the conditions possessed by a creature.
--@param self Creature. The creature itself
function Creature:advance_conditions()
	for condition, turns in pairs(self.conditions) do
    local r = conditions[condition]:advance(self)
		if r == true or r == nil then
      if self.conditions[condition] and self.conditions[condition] ~= -1 then self.conditions[condition] = self.conditions[condition] - 1 end
      if not self.conditions[condition] or (self.conditions[condition] <= 0 and self.conditions[condition] ~= -1) then
        self:cure_condition(condition)
      end --end if condition <= 0
    end --end if advance
	end --end condition for
  for _,spell in pairs(self.spells) do
    if possibleSpells[spell].advance then
      possibleSpells[spell]:advance(self)
    end --end advance if
  end --end spell for
	for spell, cooldown in pairs(self.cooldowns) do
		if (cooldown <= 1) then
			self.cooldowns[spell] = nil
		else
			self.cooldowns[spell] = cooldown -1
		end
	end --end spell for
end

--Cure a condition
--@param self Creature. The creature itself
--@param condition Text. The ID of the condition to cure
function Creature:cure_condition(condition)
  if self.conditions[condition] then
    conditions[condition]:cure(self)
    self.conditions[condition] = nil
  end
end

--Check if a creature has a condition
--@param self Creature. The creature itself
--@param condition Text. The ID of the condition to check
--@return True/False. Whether the creature has the condition.
function Creature:has_condition(condition)
  if self.conditions[condition] then
    return true
  else
    return false
  end
end

--Checks the callbacks of the base creature type, any conditions the creature might have, and any spells the creature might have.
--@param self Creature. The creature itself
--@param callback_type String. The callback type to check.
--@param … Anything. Any info you want to pass to the callback. Each callback type is probably looking for something specific (optional)
--@return True/False. If any of the callbacks returned true or false.
--@return Table. Any other information that the callbacks might return.
function Creature:callbacks(callback_type,...)
  local ret = {}
  if possibleMonsters[self.id][callback_type] and type(possibleMonsters[self.id][callback_type]) == "function" then
    local r = possibleMonsters[self.id][callback_type](self,unpack({...}))
		if (r == false) then return false end
    if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
  end
	for condition, _ in pairs(self.conditions) do
		if type(conditions[condition][callback_type]) == "function" then
			local r = conditions[condition][callback_type](conditions[condition],self,unpack({...}))
			if (r == false) then return false end
      if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
		end
	end
	for id, spell in pairs(self.spells) do
		if type(possibleSpells[spell][callback_type]) == "function" then
			local r = possibleSpells[spell][callback_type](possibleSpells[spell],self,unpack({...}))
			if (r == false) then return false end
      if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
		end
	end
	return true,ret
end

--Get the description of a creature.
--@param self Creature. The creature itself
--@return Text. The description of the creature.
function Creature:get_description()
	local desc = self:get_name(true) .. "\n" .. self.description
	desc = desc .. "\n" .. self:get_health_text(true)
  if self.master and self.master ~= player then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " is under the command of " .. self.master:get_name(false,true) .. "." end
  if (self.isPlayer ~= true) then
    if (self.playerAlly == true) then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " is under your command."
    elseif self.notices[player] and self.ignoring[player] then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " is ignoring you."
    elseif self.notices[player] and not self.shitlist[player]  then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. ((self.faction=="passive" or (self.faction and player.faction and self.faction==player.faction)) and " is friendly towards you." or " is watching you suspiciously.")
    elseif (self.notices[player] and self.shitlist[player]) then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " is hostile towards you."
    else desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " has not noticed you." end
    if self:get_fear() > self:get_bravery() then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " is afraid, and will try to run from enemies if possible." end
    if (self.isPlayer ~= true) then desc = desc .. "\nPossession Chance: " .. self:get_possession_chance() .. "%" end
    --[[if action == "targeting" and actionResult then
      local dist = calc_distance(player.x,player.y,self.x,self.y)
      if actionResult.range and dist > actionResult.range then
        desc = desc .. "\nIt is too far away to be targeted."
      elseif actionResult.minRange and dist < actionResult.minRange then
        desc = desc .. "\nIt is too close to be targeted."
      elseif actionResult.projectile and not player:can_shoot_tile(self.x,self.y) then
        desc = desc .. "\nYou can't hit it from here."
      elseif actionResult.calc_hit_chance then
        desc = desc .. "\nRanged hit chance: " .. actionResult:calc_hit_chance(player,self) .. "%"
      end]]
    if player.ranged_attack then
      local attack = rangedAttacks[player.ranged_attack]
      local dist = calc_distance(player.x,player.y,self.x,self.y)
      if attack.range and dist > attack.range then
        desc = desc .. "\nIt is too far away to be targeted."
      elseif attack.min_range and dist < attack.min_range then
        desc = desc .. "\nIt is too close to be targeted."
      elseif attack.projectile and not player:can_shoot_tile(self.x,self.y) then
        desc = desc .. "\nYou can't hit it from here."
      else
        desc = desc .. "\nRanged hit chance: " .. attack:calc_hit_chance(player,self) .. "%"
      end
    end
    
    --Debug stuff:
    if self.target and debugMode then
      desc = desc .. "\nFear: " .. self:get_fear() .. "/" .. self:get_bravery()
      if self.target.baseType == "creature" then desc = desc .. "\nTarget: " .. self.target:get_name()
      else desc = desc .. "\nTarget: " .. self.target.x .. ", " .. self.target.y end
    end
  end --end isPlayer
	
	return desc
end

--Get a description of a creature's health
--@param self Creature. The creature itself
--@param full True/False. Whether to return a full sentence or just a short description (optional)
--@return Text. The health text
function Creature:get_health_text(full)
	local health = self.hp/self:get_mhp()
	if (health >= 1) then
		if (full == true) then return ucfirst(self:get_pronoun('n')) .. " is completely healthy."
		else return "healthy" end
	elseif (health > .75) then
		if (full == true) then return ucfirst(self:get_pronoun('n')) .. " is somewhat injured."
		else return "somewhat injured" end
	elseif (health > .5) then
		if (full == true) then return ucfirst(self:get_pronoun('n')) .. " is injured."
		else return "injured" end
	elseif (health > .25) then
		if (full == true) then return ucfirst(self:get_pronoun('n')) .. " is badly injured."
		else return "badly injured" end
	elseif (health > 0) then
		if (full == true) then return ucfirst(self:get_pronoun('n')) .. " is almost dead."
		else return "almost dead" end
	else
		if (full == true) then return ucfirst(self:get_pronoun('n')) .. " is dead."
		else return "dead" end
	end
end

--Get the bonus for a given bonus type
--@param self Creature. The creature itself
--@param bonusType Text. The type of bonus to check for. Usually a stat
--@param average True/False. Whether or not to average or return the total bonus (optional)
--@return Number. The bonus.
function Creature:get_bonus(bonusType,average)
	local bonus = 0
  local bcount = 0
	for id, turns in pairs(self.conditions) do
		if (conditions[id].bonuses ~= nil) then
			local b = conditions[id].bonuses[bonusType]
			if (b ~= nil) then
        bonus = bonus + b
        bcount = bcount+ 1
      end
		end
	end
  if average and bcount > 0 then bonus = math.ceil(bonus/bcount) end
	return bonus
end

--Check how much a damage type is reduced by a creature's resistances and bonuses
--@param self Creature. The creature itself
--@param amt Number. The original damage.
--@param damageType String. The damage type.
--@return Number. The amount by which the damage is reduced
function Creature:get_resistance(amt,damageType)
  local resist = (self.resistances and self.resistances[damageType] or 0)
  local bonus = self:get_bonus(damageType .. "_resistance")
  if bonus == 0 and resist == 0 then return 0 end
  local reduction = math.floor(amt*((resist+bonus)/100))
  return reduction
end --end get_resistance function

--Check how much a damage type is increased by a creature's weaknesses and bonuses
--@param self Creature. The creature itself
--@param amt Number. The original damage.
--@param damageType String. The damage type.
--@return Number. The amount by which the damage is increased
function Creature:get_weakness(amt,damageType)
  local weakness = (self.weaknesses and self.weaknesses[damageType] or 0)
  local bonus = self:get_bonus(damageType .. "_weakness")
  if bonus == 0 and weakness == 0 then return 0 end
  local increase = math.floor(amt*((weakness+bonus)/100))
  return increase
end --end get_resistance function

--Check what hit conditions a creature can inflict
--@param self Creature. The creature itself
--@return Table. The list of hit conditions
function Creature:get_hit_conditions()
	return (self.hit_conditions or {})
end

--Check what conditions a creature can inflict on a critical hit
--@param self Creature. The creature itself
--@return Table. The list of hit conditions
function Creature:get_crit_conditions()
	return (self.crit_conditions or {})
end

--Determine if you hit a target or not.
--@param self Creature. The creature itself
--@param target Entity. The creature they're attacking
--@param forceHit True/False. Whether to force the attack instead of rolling for it.
--@param ignore_callbacks True/False. Whether to ignore any of the callbacks involved with attacking
--@return String. Either "miss," "hit," or "critical"
--@return Number. How much damage (if any) was done
function Creature:attack(target,forceHit,ignore_callbacks)
  if target and target.x and target.x<self.x then
    self.faceLeft = true
  elseif target and target.x and target.x>self.x then
    self.faceLeft = false
  end
  if self.topDown then
    if target.y<self.y then 
      self.angle = (not self.faceLeft and (3*math.pi)/2 or math.pi/2)
    elseif target.y>self.y then
      self.angle = (self.faceLeft and (3*math.pi)/2 or math.pi/2)
    else
      self.angle = 0
    end
  end
  if target.baseType == "feature" and self:touching(target) then
    return target:damage(self.strength,self,self.damage_type)
	elseif self:touching(target) and (ignore_callbacks or self:callbacks('attacks',target) and target:callbacks('attacked',self)) then
		local result,dmg = calc_attack(self,target)
    if forceHit == true then result = 'hit' end
		local hitConditions = self:get_hit_conditions()
    local critConditions = self:get_crit_conditions()
    if count(critConditions) == 0 then critConditions = hitConditions end
		local txt = ""

		if (result == "miss") then
			txt = txt .. ucfirst(self:get_name()) .. " misses " .. target:get_name() .. "."
		else
			if (result == "critical") then txt = txt .. "CRITICAL HIT! " end
			dmg = target:damage(dmg,self,self.damage_type,true)
			if dmg > 0 then txt = txt .. ucfirst(self:get_name()) .. " hits " .. target:get_name() .. " for " .. dmg .. (self.damage_type and " " .. self.damage_type or "") .. " damage."
      else txt = txt .. ucfirst(self:get_name()) .. " hits " .. target:get_name() .. " for no damage." end
      local xMod,yMod = get_unit_vector(self.x,self.y,target.x,target.y)
      --target.xMod,target.yMod = xMod*3,yMod*3
      --tween(.1,target,{xMod=0,yMod=0})
      --Tweening
      target.xMod,target.yMod = target.xMod+(xMod*5),target.yMod+(yMod*5)
      if target.moveTween then
        Timer.cancel(target.moveTween)
      end
      target.moveTween = tween(.1,target,{xMod=0,yMod=0},'linear',function() target.doneMoving = true end)
      
			self:callbacks('damages',target,dmg)
			target.alert = target:get_aggression()
      local cons = (result == "critical" and critConditions or hitConditions)
			for _, condition in pairs (cons) do
				if (random(1,100) < condition.chance) then
          local turns = ((condition.minTurns and condition.maxTurns and random(condition.minTurns,condition.maxTurns)) or tweak(condition.turns))
					target:give_condition(condition.condition,turns,self)
				end -- end condition chance
			end	-- end condition forloop
		end -- end hit if
    if player:can_see_tile(self.x,self.y) or player:can_see_tile(target.x,target.y) and player:does_notice(self) and player:does_notice(target) then
      output:out(txt)
      if result ~= "miss" then output:sound('punch') end
    end
		return result,dmg
	else -- if not touching target
		return false
	end
end

--This function is run every turn. It handles advancing conditions, recharging attacks, and AI for NPCs
--@param self Creature. The creature itself
--@param skip_conditions True/False. Whether to skip running the condition advance code (optional)
function Creature:advance(skip_conditions)
  self.sees = nil --clear list of seen creatures
  self.checked = {} --clear list of unnoticed creatures you've checked
  --AI Decision:
  while self.energy >= player.speed and self ~= player do
    local x,y = self.x,self.y
    self.energy = self.energy - player:get_speed()
    if self:callbacks('ai') then
      if (self.ai == nil or ai[self.ai] == nil) then
        ai.basic(self)
      else
        ai[self.ai](self)
      end
    end --end decide callback if
    if self.x == x and self.y == y then --didn't move
      local enter = currMap:enter(x,y,self,x,y) --run the "enter" code for a feature, f'rex, lava burning you even if you don't move
    end
  end --end while
  
  --Conditions and attack recharging:
	if not skip_conditions then
    self.energy = self.energy + self:get_speed()
    self:advance_conditions()
    if self.ranged_attack then
      local attack = rangedAttacks[self.ranged_attack]
      if attack.max_charges and attack.active_recharge ~= true then
        attack:recharge(self)
      end --end max_charges if
    end --end ranged_attack if
  end --end skip_conditions if
end

--Check whether a creature can move to a given tile
--@param self Creature. The creature itself
--@param x Number. The x coordinate
--@param y Number. The y coordinate
--@param inMap Map. The map to check. Defaults to current map (optional)
--@return True/False. Whether or not the creature can move to that tile
function Creature:can_move_to(x,y,inMap)
  --First, check to see if the target is A) even in the map, B) has a wall or creature
  inMap = inMap or currMap
  if x<2 or y<2 or x>inMap.width-1 or y>inMap.height-1 then return false end
  if inMap[x][y] == "#" or inMap:get_tile_creature(x,y) then return false end
  --if a creature can only move in certain types of terrain, check for those types:
  if self.terrainLimit then
    local needed = false
    for _, terrain in pairs(self.terrainLimit) do
      if inMap:tile_has_feature(x,y,terrain) then
        needed = true
        break
      end
    end
    if needed == false then return false end --if your needed types were not found, you can't move there
  end --end terrain limit if
  --Check the features to see if there are any impassable/blocking ones, and if there are, if they're passable for you or not
  for _,feat in pairs(inMap:get_tile_features(x,y)) do
    if feat.baseType == "feature" and (feat.impassable or (feat.blocksMovement == true and feat.pathThrough ~= true)) then
      --If the tile isn't passable for anyone, or the creature has no special types, automatically return false
      if feat.passableFor == nil then return false end
      if self.types == nil then return false end
      --cycle through all the types to see if any of them match
      for ctype, _ in pairs(feat.passableFor) do
        if self:is_type(ctype) then return true end --if any of the types are true, you're good to go
      end
      return false --if no types match, can't go
    end --end feature if
  end --end for
  return true
end

--Move a creature to a tile
--@param self Creature. The creature itself
--@param x Number. The x coordinate
--@param y Number. The y coordinate
--@param skip_callbacks True/False. Whether to skip any callbacks related to movement (optional)
--@param noTween True/False. If true, move there instantly, no tweening (optional)
--@return True/False. If the creature successfully moved
function Creature:moveTo(x,y, skip_callbacks,noTween)
  noTween = noTween or prefs['noSmoothMovement']
  local canMove, val = nil,nil
  if skip_callbacks then
    canMove = true
  else
    canMove, val = self:callbacks('moves',x,y)
  end
	if (skip_callbacks or canMove) and not self.immobile then
    if val and val[1] and val[1].x and val[1].y then --if a callback returned a tile, set that as the new destination instead
      x,y = val[1].x,val[1].y
    end
		if (self:can_move_to(x,y)) then
      local canEnter = skip_callbacks or currMap:enter(x,y,self,self.x,self.y)
      if (canEnter) then
        if (self.x and self.y) then --if you're already on the board
          currMap.contents[self.x][self.y][self] = nil --empty old tile
          if x<self.x then self.faceLeft = true elseif x>self.x then self.faceLeft = false end
          if self.topDown then
            if y<self.y then 
              self.angle = (not self.faceLeft and (3*math.pi)/2 or math.pi/2)
            elseif y>self.y then
              self.angle = (self.faceLeft and (3*math.pi)/2 or math.pi/2)
            else
              self.angle = 0 end
          end
          --Move camera:
          local moveX,moveY=x-self.x,y-self.y
          if self == player then
            output:move_camera(moveX,moveY)
          end
          --Tweening shit:
          if not noTween then
            local tileSize = output:get_tile_size()
            
            self.xMod,self.yMod=self.xMod-moveX*tileSize,self.yMod-moveY*tileSize
            if self:is_type('flyer') == false then
              self.yMod = self.yMod-2
            end
            if self.moveTween then
              Timer.cancel(self.moveTween)
            end
            self.moveTween = tween(.1,self,{xMod=0,yMod=0},'linear',function() self.doneMoving = true end)
            --[[elseif self ~= player then
              self.xMod = (self.x-x)*32
              tween(.1,self,{xMod=0})
              self.yMod = (self.y-y)*32
              tween(.1,self,{yMod=0})
            end]]
            self.fromX,self.fromY=self.x,self.y
            self.x,self.y=x,y
          else --if you're not tweening, just set your location
            self.fromX,self.fromY=self.x,self.y
            self.x = x
            self.y = y
          end
        else --if you're being put in a location for the first time, just set your location
          self.x = x
          self.y = y
        end
        --if self.x and self.y and self ~= player then currMap:set_blocked(self.x,self.y,0) end
        --if self ~= player then currMap:set_blocked(x,y,1) end
        currMap.contents[self.x][self.y][self] = self
        self:callbacks('moved',self.fromX,self.fromY,self.x,self.y)
        --Update seen creatures:
        self.sees = nil
        if self == player then self.sees = self:get_seen_creatures() end
      end --end if(canEnter)
		else -- if the square isn't clear
			local blocker = currMap:get_tile_creature(x,y,true)
			if blocker ~= false and (blocker.baseType ~= "creature" or self:is_enemy(blocker)) then
        if blocker.baseType ~= "feature" or not blocker.pushable or not blocker:push(self) or (blocker.baseType == "feature" and blocker.attackable) then --always attack creatures, push pushable features, and then attack attackable features (including attackable pushables if you can't push for some reason)
          self:attack(blocker)
        end
			end
      if self == player then refresh_player_sight() end
			return false
		end -- end clear if
	end -- end callback if
  if self == player then refresh_player_sight() end
end

--Forcibly move a creature to a tile, no matter what. Please don't use this function unless it's absolutely necessary.
--@param self Creature. The creature itself
--@param x Number. The x coordinate
--@param y Number. The y coordinate
function Creature:forceMove(x,y) -- Do not use this function unless you absolutely have to
  --It is terrible and goes against everything we stand for
  --But sometimes you have to do something bad to do something good (or something)
  --Whatever, knock yourself out but don't cry if something shitty happens
  if (self.x and self.y) then
    currMap.contents[self.x][self.y][self] = nil --empty old tile
    if x<self.x then self.faceLeft = true elseif x>self.x then self.faceLeft = false end
    if self.topDown then
      if y<self.y then 
        self.angle = (not self.faceLeft and (3*math.pi)/2 or math.pi/2)
      elseif y>self.y then
        self.angle = (self.faceLeft and (3*math.pi)/2 or math.pi/2)
      else
        self.angle = 0
      end
    end
  end
  self.x = x
  self.y = y
  currMap.contents[self.x][self.y][self] = self
end

--Check if a creature is touching something else
--@param self Creature. The creature itself
--@param target Entity. The entity to check
--@return True/False. Whether they're touching
function Creature:touching(target)
	if (math.abs(target.x-self.x) <= 1 and math.abs(target.y-self.y) <= 1) then
		return true
	end
	return false
end

--Kill a creature.
--@param self Creature. The creature itself
--@param killer Entity. Whodunnit?
function Creature:die(killer)
  if self.isDead then return self:remove() end
  if killer then self.killer = killer end
  if killer == nil and self.lastAttacker then self.killer = self.lastAttacker end
  if self:callbacks('dies',self.killer) and (not self.killer or (self.killer.callbacks and self.killer:callbacks('kills',self))) then
    self.isDead = true
    if self.killer and self.killer.master and self.killer.master.hp > 0 and self.killer.master.callbacks then
      self.killer.master:callbacks('ally_kills',self,killer)
    end
    local seen = player:can_see_tile(self.x,self.y)
    if seen then
      if self.deathSound then output:sound(self.deathSound)
      elseif self.soundgroup then output:sound(self.soundgroup .. "_death")
      elseif not output:sound(self.id .. "_death") then --output:sound return false if a sound doesn't exist
        output:sound('genericdeath') --default death
      end --end sound type if
    end --end seen if
    if self.playerAlly == true and self ~= player then
      update_stat('ally_deaths')
      update_stat('ally_deaths_as_creature',player.id)
      update_stat('creature_ally_deaths',self.id)
    end
    if (self.killer and self.killer.playerAlly == true) then
      if self.killer == player then
        update_stat('kills')
        update_stat('kills_as_creature',player.id)
        update_stat('creature_kills',self.id)
        update_stat('level_kills',currMap.id)
        currGame.stats['kills_in_current_body'] = (currGame.stats['kills_in_current_body'] or 0)+1
        achievements:check('kill')
      else
        update_stat('ally_kills')
        update_stat('ally_kills_as_creature',player.id)
        update_stat('allied_creature_kills',self.killer.id)
        update_stat('creature_kills_by_ally',self.id)
      end
      local hp = tweak(math.ceil(self.max_hp/4))
      output:out(self:get_name() .. " dies! You absorb some of " .. self:get_pronoun('p') ..  " life force, and regain " .. hp .. " HP.")
      player:updateHP(hp)
    elseif seen and not self:is_type('ghost') then
      output:out(self:get_name() .. " dies!")
    end --end playerally killer if
    
    if (self.killer and self.killer.baseType == "creature") then
      self.killer:level_up()
    end
    
    --Corpse time:
    if self.explosiveDeath then
      return self:explode()
    end
    local absorbs = false
    if currMap:tile_has_feature(self.x,self.y,'bridge') == false and currMap:tile_has_feature(self.x,self.y,'minetracks') == false then --if there's a bridge, it's OK for a corpse to show
      absorbs = (type(currMap[self.x][self.y]) == 'table' and currMap[self.x][self.y].absorbs == true)
      for _,feat in pairs(currMap:get_tile_features(self.x,self.y)) do
        if feat.absorbs == true then absorbs = true break end
      end --end feature for
    end --end bridge if
  
    if (absorbs == false) then
      if self.corpse == nil and not self:is_type('ghost') and not self:is_type('bloodless') then
        local chunk = currMap:add_feature(Feature(('chunk'),self),self.x,self.y)
      end --put a chunk in, no matter what
      if (self.corpse == nil and not self:is_type('ghost') and self.isPlayer ~= true) then
        local corpse = Feature('corpse',self,self.x,self.y)
        currMap:add_feature(corpse,self.x,self.y)
        corpse:refresh_image_name()
      elseif not self:is_type("ghost") and self.isPlayer ~= true and self.corpse then
        local corpse = Feature(self.corpse,self,self.x,self.y)
        currMap:add_feature(corpse,self.x,self.y)
      end --end special corpse vs regular corpse if
    end --end absorbs if
    
    --Final cleanup:
    self:free_thralls()
  
    if self == player then
      if action ~= "dying" then player_dies() end
    else
      self:remove()
    end
  end --end dies callback if
end

--Make a creature explode.
--@param self Creature. The creature itself
function Creature:explode()
	-- EXPLODE!
	if not self:is_type('ghost') then
    self.exploded = true
    if self == player then
      update_stat('explosions')
      update_stat('exploded_creatures',self.id)
    end
    if self:callbacks('explode') then
      if possibleMonsters[self.id].explode then
        --do nothing here, it already got done in the callbacks. This is just to keep from running the "normal" explosion
      else
        if player:can_see_tile(self.x,self.y) then
          output:out(self:get_name(false,true) .. " explodes!")
          output:sound('explode')
        end
        local chunkmaker = Effect('chunkmaker',self)
        currMap:add_effect(chunkmaker,self.x,self.y)
      end --end special explosion code check
    end --end callback check
	end -- end initial if
  --Add fear to creatures that saw the explosion:
  for x=self.x-10,self.x+10,1 do
    for y=self.y-10,self.y+10,1 do
      if currMap:in_map(x,y) then
        local creat = currMap:get_tile_creature(x,y)
        if creat and creat:can_see_tile(self.x,self.y) then --if they can't see it, they can't be scared of it
          if creat.master and creat.master == self then
            creat.fear = creat.fear + 25 --seeing your master explode? really scary
          elseif creat.faction and self.faction and creat.faction == self.faction then
            creat.fear = creat.fear + 10 -- seeing a friend explode? scary
          elseif not creat:is_enemy(self) then --seeing an enemy explode is not scary
            creat.fear = creat.fear + 5  --seeing a rando explode is a little scary
          end
        end
      end --end in_map if
    end --end fory
  end --end forx
  if self == player then player_dies()
  else self:remove() end
end -- end function

--Remove a creature from the map without killing it
--@param self Creature. The creature itself
--@param map Map. The map to remove the creature from. Defaults to current map (optional)
function Creature:remove(map)
  map = map or currMap
  map.contents[self.x][self.y][self] = nil
  if self.castsLight then map.lights[self] = nil end
  map.creatures[self] = nil
  
  --Handle thrall stuff:
  if self.master then self.master.thralls[self] = nil end
  self:free_thralls()
  
	self.hp = 0
	if (target == self) then
		target = nil
	end
	for condition, turns in pairs(self.conditions) do
		self.conditions[condition] = nil
	end
  --currMap:set_blocked(self.x,self.y,0)
end

--Get the possession chance of a creature.
--@param self Creature. The creature itself
--@return Number. The possession chance.
function Creature:get_possession_chance()
	local chance = (self.possession_chance or 0)
  if chance <= 0 then return 0 end -- unpossessable creatures always unpossessable no matter what
	local mod = (self:get_mhp() - self.hp)/self:get_mhp() -- get the % of HP that has been lost
	chance = math.floor(chance + chance*mod)+self:get_bonus('possession_chance') -- add on that % (as % of original chance) to the chance, as well as possession bonus from conditions or whatever
  if not self:does_notice(player) then chance = chance + 10 end --if they haven't noticed the player, they're more susceptible
  if currGame.cheats.easierPossession then
    chance = math.ceil(chance * 1.5)
  end
	if (chance > 100) then chance = 100
  elseif chance < 0 then chance = 0
  elseif (chance < 10) then chance = 10 end
	return chance
end

--Check if a creature can see a given tile
--@param self Creature. The creature itself
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param forceRefresh True/False. Whether to force actually calculating if a player can see it, versus just looking at the stored values of player sight
--@return True/False. Whether or not they can see it.
function Creature:can_see_tile(x,y,forceRefresh)
  if (self == player) and currGame.cheats.seeAll==true then return true end
  if not currMap or not currMap:in_map(x,y,true) then return false end
  if not self.x or not self.y then output:out(self:get_name() .. " does not exist but is trying to see stuff somehow.") end --If you don't exist, you can't see anything
  
  if not self == player and not forceRefresh then
    if not player.seeTiles then
      refresh_player_sight()
    else
      return player.seeTiles[x][y]
    end
  end
  
  local lit = false
  
  if x == self.x and y == self.y and self.hp > 0 then
    return true
  end --you can always see your own tile
  
  if currMap.lightMap[x][y] ~= false or self:get_perception() > calc_distance(self.x,self.y,x,y) then -- if it's a lit tile, or within your view distance, it's "lit"
    lit = true
  end
  
  if lit then --if it's not "lit," you can't see it anyway, so don't run bresenham
    if bresenham.los(self.x,self.y,x,y, currMap.can_see_through,currMap) then --if there's a clear path to the square, you can see it!
      return true
    end
  end
  return false --default to not being able to see
end

--Check if a creature can sense another, either through sight, or...spooky methods.
--@param self Creature. The creature itself
--@param creat Creature. The creature to check.
--@param skipSight True/False. Whether to skip run can_see_tile first and just look at extra senses (optional)
--@return True/False. If the target can be seen.
function Creature:can_sense_creature(creat,skipSight)
  if creat == self then return true end
  if not currMap then return false end
  if action == "dying" and self == player and currMap.seenMap[creat.x] and currMap.seenMap[creat.x][creat.y] then return true end
  if creat.master and creat.master == self then return true end
  if skipSight ~= true and not creat:has_condition('invisible') and self:can_see_tile(creat.x,creat.y) then return true end
  if self.extraSense == nil then return false else
    return possibleSpells[self.extraSense]:sense(self,creat)
  end
end

--Check if you can draw a straight line between the creature and a tile.
--@param self Creature. The creature itself
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return True/False. Whether or not they can shoot it.
function Creature:can_shoot_tile(x,y)
  --if (self == player) then return true end
	local dist = calc_distance(self.x,self.y,x,y)
	if (self:get_perception() > dist) then
		return currMap:is_line(self.x,self.y,x,y,false,'flyer',false,true,true)
	end
	return false
end

--Check if a creature is a potential enemy of another creature. This is NOT to check if they're actually currently hostile.
--@param self Creature. The creature itself
--@param target Creature. The target to check
--@param dontSend True/False. The dontSend argument here is used when is_enemy() is called for checking a master's enemies. In the weird (but possible) case where two creatures were masters of each other, this would result in an infinite loop. Don't use it youself. (optional)
--@return True/False. Whether or not they're enemies
function Creature:is_enemy(target,dontSend)
  if target == self then return false end -- You are never an enemy of yourself
  if self.master and ((target == self.master) or (target.master and self.master == target.master)) then return false end --You are never an enemy of your master or your master's thralls
  if not dontSend and self.master and target:is_enemy(self.master,true) then return true end -- if they're an enemy of your master, they're also your enemy
  if self.ignoring and self.ignoring[target] then return false end -- if you're ignoring it, you won't consider it an enemy
  if self.shitlist and self.shitlist[target] then return true end --if it's on your shitlist, it's your enemy regardless of faction
  if self.faction == "passive" then return false end --passive only attacks those who attack them
  
  if (self.playerAlly == true) then
    if target.playerAlly == true then return false end --if you're both player allies, you're not enemies
    if target.playerAlly ~= true and (target:is_enemy(player,dontSend) or (target.faction == nil or self.faction or target.faction ~= self.faction)) then return true end --if the target is not a player ally, and is an enemy of the player or not in your faction, they're your enemy too
  else --if not a player ally
    if target.playerAlly == true and (target.faction == nil or self.faction == nil or self.faction ~= target.faction) then
      return true --if the target is a player ally, and is not in your faction, they're your enemy
    elseif(self.faction == "chaos" and target.facton ~= "chaos") or (self.faction ~="chaos" and target.faction == "chaos") then
      return true --if you're chaos, or your target is chaos, they are an enemy, UNLESS you are both chaos!
    elseif self.enemy_factions and in_table(target.faction,self.enemy_factions) then
      return true --if neither of you are player allies or chaos, they're only your enemy if they're in an enemy faction
    end
  end --end playerally or not check
  return false --default to not enemy
end

--Checks if a creature is of a certain type
--@param self Creature. The creature itself
--@param ctype String. The creature type to check for
--@return True/False. Whether or not the creature is that type
function Creature:is_type(ctype)
  if not self.types then return false end
  for _,c in pairs(self.types) do
    if c == ctype then return true end
  end --end for
  return false
end --end function

--Cause a creature to notice another creature
--@param self Creature. The creature itself
--@param creat Creature. The target to notice.
--@param skip_callbacks Whether to force notice and skip the notices() callbacks (optional)
--@param force Whether to force notice, but still run the callbacks (optional)
--@return True/False. Whether the creature successfully noticed the target
function Creature:notice(creat, skip_callbacks,force)
  if skip_callbacks == true or (creat:callbacks('noticed',self) and self:callbacks('notices',creat)) or force == true then
    self.notices[creat] = math.ceil(self.memory/2)
    if self.shitlist[creat] then self:become_hostile(creat,true) end
    if self:has_condition('asleep') then self:cure_condition('asleep') end
    return true
  else
    return false
  end --end callbacks if
end --end notice function

--Checks if a creature has already noticed a creature. If not, see if they notice them now.
--@param self Creature. The creature itself
--@param creat Creature. The target to check
--@return True/False. Whether the creature has noticed the target.
function Creature:does_notice(creat)
  if self == creat or self.notices[creat] then
    return true
  else
    if not self.checked[creat] then
      self.checked[creat] = creat
      return self:can_notice(creat)
    end
    return false
  end
end

--Checks if a creature is able to notice another, and sets them as noticed if yes
--@param self Creature. The creature itself
--@param creat Creature. The creature to try and notice
--@return True/False. Whether the creature is able to notice the target
function Creature:can_notice(creat)
  if self.id == "ghost" and self:can_see_tile(creat.x,creat.y) then return self:notice(creat,false,true) end -- ghost always notices, so you don't get killed by "invisible" enemy
  --Creatures are more likely to notice others the closer they get
  local noticeChance = self:get_notice_chance()
  local stealth = creat:get_stealth()
  local dist = calc_distance(self.x,self.y,creat.x,creat.y)
  local distPerc = dist/self:get_perception()
  stealth = (stealth > 0 and stealth+math.ceil(stealth*distPerc) or stealth-math.floor((stealth*distPerc)/2)) -- positive stealth increases based on % of total perception distance, up to 2x. Negative stealth reduces based on % of total perception distance, up to 1/2
      
  if self:can_sense_creature(creat) and random(1,100) <= noticeChance-stealth then
    return self:notice(creat) --even if you could normally notice, callbacks might prevent it eg an invisibility spell
  end
  return false
end

--Decrease the "noticed" value for all creatures that this creature has noticed
--@param self Creature. The creature itself
--@param seenCreats Table. A table full of creatures currently seen, whose noticed value will not be decreased (optional)
function Creature:decrease_notice(seenCreats)
  for creat,amt in pairs(self.notices) do
    if not in_table(creat,seenCreats) then
      amt = amt -1
      if amt < 1 then self.notices[creat] = nil else self.notices[creat] = amt end
    end
  end
end

--Forget that you saw a creature
--@param self Creature. The creature itself
--@param creat Creature. The creature to forget
function Creature:forget(creat)
  if self.notices[creat] then self.notices[creat] = nil end
end

--Become hostile to another creature
--@param self Creature. The creature itself
--@param creat Creature. The creature to become hostile towards
--@param skip_callbacks. True/False. Whether to skip hostility-related callbacks (optional)
--@param noSound True/False. Whether to become hostile without playing a sound (optional)
--@return True/False. Whether the creature became hostile to the target.
function Creature:become_hostile(creat, skip_callbacks,noSound,noText)
  if self == player then return false end
  if skip_callbacks == true or (creat:callbacks('became_enemy',self) and self:callbacks('become_hostile',creat)) then
    if creat == player and player:can_see_tile(self.x,self.y) and self.shitlist[player] == nil and player:does_notice(creat) and player:can_sense_creature(creat) then
      if not noText then output:out(self:get_name() .. " becomes hostile!") end
      local popup = Effect('dmgpopup')
      popup.image_name = "exclamation"
      currMap:add_effect(popup,self.x,self.y)
      if not noSound then
        if self.aggroSound then output:sound(self.aggroSound)
        elseif self.soundgroup then output:sound(self.soundgroup .. "_aggro")
        elseif not output:sound(self.id .. "_aggro") then --output:sound return false if a sound doesn't exist
          output:sound('aggro') --default aggro
        end
      end
    end --end if creat == player
    self:stop_ignoring(creat)
    self.shitlist[creat] = true
    self.alert = self.memory
    if not self:does_notice(creat) then self:notice(creat) end
    if self.master == creat then self:become_free() end
    return true
  end --end callbacks if
  return false
end --end notice function

--Add a creature to your ignore list
--@param self Creature. The creature itself
--@param creat Creature. The creature to ignore
function Creature:ignore(creat)
  self.shitlist[creat] = nil
  self.ignoring[creat] = creat
end

--Remove a creature to your ignore list
--@param self Creature. The creature itself
--@param creat Creature. The creature to stop ignoring
function Creature:stop_ignoring(creat)
  self.ignoring[creat] = nil
end

--Get a list of all creatures you can see
--@param self Creature. The creature itself
--@return Table. A numbered list of the creatures.
function Creature:get_seen_creatures()
  if self.sees then return self.sees end
  local creats = {}
  local perc = self:get_perception()
  for _, c in pairs(currMap.creatures) do
    if c.x > self.x-perc and c.x < self.x+perc and c.y > self.y-perc and c.y < self.y+perc and self:can_sense_creature(c) and c ~= self then
      creats[#creats+1] = c
    end --end perception if
  end --end for
  self.sees = creats
  return creats
end --end get_all_seen_creatures function

--Make a fear map for the given creature
--@param self Creature. The creature itself
--@return Table. A fear map, with coordinates in t[x][y] format
function Creature:make_fear_map()
  local lMap = {}
  local cW,cH=currMap.width-1,currMap.height-1
  local sX,sY,perc = self.x,self.y,self:get_perception()
  for x=sX-perc,sX+perc,1 do
    for y=sY-perc,sY+perc,1 do
      if (x>1 and y>1 and x<cW and y<cH) then
        if (lMap[x] == nil) then lMap[x] = {} end
        local creat = currMap:get_tile_creature(x,y)
        if (creat == false and self:can_move_to(x,y) == false) then lMap[x][y] = false
        elseif creat and self:is_enemy(creat) then lMap[x][y] = 0
        else lMap[x][y] = 10 end
      end --end range check
    end --end yfor
  end --end xfor
  
  local changed = true
  while (changed) do
    changed = false
    for x=sX-perc,sX+perc,1 do
      for y=sY-perc,sY+perc,1 do
        if (lMap[x] and lMap[x][y]) then
          local min = nil
          for ix=x-1,x+1,1 do
            for iy=y-1,y+1,1 do
              if (ix>1 and iy>1 and ix<cW and iy<cH and lMap[ix] and lMap[ix][iy]) and (min == nil or lMap[ix][iy] < min) then
                min = lMap[ix][iy]
              end --end min if
            end --end yfor
          end --end xfor
          if (min and min+2 < lMap[x][y]) then lMap[x][y] = min+1 changed = true end
        end --end tile check
      end --end yfor
    end --end xfor
  end -- end while
  return lMap
end --end make_fear_map

--This function is run every tick and updates various things. You probably shouldn't run it yourself
--@param self Creature. The creature itself
--@param dt Number. The number (or fractional number) of seconds since the last time update() was run
function Creature:update(dt) --for charging, and other special effects
  if self == player and self.sees == nil then self.sees = self:get_seen_creatures() end --update player sees if for some reason they don't see anything (after a possession f'rex)
  --Delete tween if done moving:
  if self.doneMoving and self.xMod == 0 and self.yMod == 0 then
    self.doneMoving = nil
    if self.moveTween then
      Timer.cancel(self.moveTween)
      self.moveTween = nil
    end
    self.fromX,self.fromY=self.x,self.y
  end
  
  --Hearts for allies:
  if self.playerAlly == true and self ~= player then
    self.heartClock = (self.heartClock or 2) - dt
    if (self.heartClock <= 0 and random(1,5) == 1) then
      local heart = Effect('heart',self.x,self.y)
      currMap:add_effect(heart,self.x,self.y)
      self.heartClock = 2
    end
  end
  
  if (self.zoomTo ~= nil) then --handle charging, knockbacks and the like
    local oldX,oldY=self.x,self.y
    if (self.zoomLine == nil or #self.zoomLine == 0 or self.zoomLine[#self.zoomLine][1] ~= self.zoomTo.x or self.zoomLine[#self.zoomLine][2] ~= self.zoomTo.y) then
      --if we haven't made a zoomline yet, or the zoomline's target doesn't match the actual target's location anymore (ie a creature moved), make the zoomline
      self.zoomLine = currMap:get_line(self.x,self.y,self.zoomTo.x,self.zoomTo.y,false,self.pathType)
    end --end if line == nil
    
    if (self.zoomLine and #self.zoomLine > 0 and self:can_move_to(self.zoomLine[1][1],self.zoomLine[1][2]) == true) then --if first spot in line an empty, go there
      self:moveTo(self.zoomLine[1][1],self.zoomLine[1][2],true)
			table.remove(self.zoomLine,1)
    elseif self.zoomLine and #self.zoomLine > 0 then --if you can't go to the next point in the line, handle collision:
      local c = currMap:get_tile_creature(self.zoomLine[1][1],self.zoomLine[1][2])
      if c and c ~= self then self.zoomTo = c --set the creature as your new target
      else self.zoomTo = {x=self.zoomLine[1][1],y=self.zoomLine[1][2]} end --set the square as your new target
      self.zoomLine = {{self.zoomTo.x,self.zoomTo.y}}
    end
    
    if (self.x == self.zoomTo.x and self.y == self.zoomTo.y) or (self:can_move_to(self.zoomTo.x,self.zoomTo.y) == false and (self:touching(self.zoomTo) or #self.zoomLine < 1 or not self.zoomLine)) then
      local dist = math.floor(calc_distance(self.zoomFrom.x,self.zoomFrom.y,self.zoomTo.x,self.zoomTo.y))
      if (self.zoomResult) then
        self.zoomResult:use(self.zoomTo,self) --if you're charging, do whatever is at the end of the charge
      else --if you're not charging, get hurt and hurt whoever you ran into
        if self.zoomTo and currMap[self.zoomTo.x][self.zoomTo.y] == "#" and not self:touching(self.zoomFrom) then
          local dmg = self:damage(tweak((self.max_hp/random(10,20)*dist)),self.lastAttacker) --get damaged
          if player:can_see_tile(self.x,self.y) then
            output:out(self:get_name() .. " slams into a wall, taking " .. dmg .. " damage!")
            output:sound('collision_wall')
          end
          if self.hp <= 0 then
            self.explosiveDeath = true
            if self.lastAttacker == player then
              achievements:give_achievement('knockback_kill')
            end
          end
        else
          for _,f in pairs(currMap:get_contents(self.zoomTo.x,self.zoomTo.y)) do
            if (f.blocksMovement == true or f.baseType == "creature" and f ~= self) and (f.baseType == "creature" or f.attackable or not self:touching(self.zoomFrom)) then
              local dmg = self:damage(tweak((self.max_hp/random(10,20)*dist)),self.lastAttacker) --get damaged
              if f.baseType == "creature" or f.attackable then
                local tdmg = f:damage(tweak((self.max_hp/random(10,20)*dist)),self.lastAttacker) --damage creature you hit
                if player:can_see_tile(self.x,self.y) then
                  output:out(self:get_name() .. " slams into " .. f:get_name() .. ", taking " .. dmg .. " damage. " .. (tdmg and ucfirst(f:get_name()) .. " takes " .. tdmg .. " damage." or ""))
                  if f.baseType == "creature" then
                    output:sound('collision_creature')
                  else
                    output:sound('collision_wall')
                  end
                end
                if f.hp and f.hp <= 0 then
                  f.explosiveDeath = true
                  if self == player and f.id == "tentacle" then
                    achievements:give_achievement('eldritch_special')
                  end
                elseif random(1,10) < dist*2 then --chance of knockback increases if the hitter was farther away
                  local knockback = random(0,math.floor(dist))
                  if knockback > 0 and f.baseType == "creature" then f:give_condition('knockback',knockback,self) end
                end --end hp if
               else
                if player:can_see_tile(self.x,self.y) then
                  output:out(self:get_name() .. " slams into the " .. f.name .. ", taking " .. dmg .. " damage!")
                  output:sound('collision_wall')
                end
               end --end feature vs. creature if
              if self.hp <= 0 then self.explosiveDeath = true end
              break
            end --end blocks movement if
          end --end feature for
        end --end wall if
      end -- end charging or not if
      self.zoomFrom = nil
      self.zoomTo = nil
      self.zoomLine = nil
      self.zoomResult = nil
      local key = in_table('knockedback',self.types)
      if key then table.remove(self.types,key) end
      if count(self.types) == 0 then self.types = nil end
      currMap:enter(self.x,self.y,self,oldX,oldY)
    end --end hit the end of the line
  elseif self.hp < 1 and (self ~= player or not self:is_type('ghost') or action ~="dying") then --If not zooming, check to see if you need to die (we don't do this while zooming to avoid awkwardness)
    self:die()
  end --end if self zoomto

  for condition, turns in pairs(self.conditions) do --for special effects like glowing, shaking, whatever
		if (conditions[condition].update ~= nil) then conditions[condition]:update(self,dt) end
  end -- end for
  
  if self.animated and prefs['creatureAnimations'] and (self.animateSleep or not self:has_condition('asleep')) and player:does_notice(self) and player:can_sense_creature(self) then
    self.animCountdown = (self.animCountdown or 0) - dt
    if self.animCountdown < 0 then
      local imageNum = nil
      --Get the current image frame #
      local currNum = 1
      if self.spritesheet then
        currNum = self.image_frame
      else
        currNum = self.image_name and tonumber(string.sub((self.image_name),-1)) or 1
      end
      --Now actually go about selecting the image
      if self.randomAnimation ~= true then --Images in sequence?
        --If you've reached the end of the line:
        if (not self.reversing and currNum == self.image_max) or (self.reversing and currNum == 1) then
          if self.reverseAnimation then
            self.reversing = not self.reversing
          else
            imageNum = 1
          end
        end -- end image loop if
        --If imageNum wasn't set to 1 above, set it to itself+1 or -1, depending on what direction we're going
        if imageNum == nil then imageNum = (currNum+(self.reversing and -1 or 1)) end
      else --random image
        imageNum = random(1,self.image_max)
        local loopCount = 0
        while imageNum == currNum and loopCount < 10 do
          imageNum = random(1,self.image_max)
          loopCount = loopCount + 1
        end --end while image == currNum
      end --end random-or-not if
      if self.spritesheet then
        self.image_frame = imageNum
      else
        local image_base = ((self.image_base or (possibleMonsters[self.id].image_name or self.id)) .. ((self == player and self.id ~= "ghost") or self:has_condition('possessed')) and "possessed" or "")
        self.image_name = image_base .. imageNum
      end
      --Change the light color, if necessary
      if self.lightColors then
        self.lightColor = self.lightColors[imageNum]
        currMap:refresh_light(self,true)
      end --end lightcolor if
      if self.colors then
        self.color = self.colors[imageNum] or self.color
      end
      if not self.isPlayer and self.master ~= player and (not self.notices[player] or not self.shitlist[player]) then --slower if doesn't notice player
        self.animCountdown = self:get_animation_time()*1.25
      else
        self.animCountdown = self:get_animation_time()
      end
    end --end if self.countdown
  end --end animation for
end --end function

--Placeholder. Don't use.
--@return False.
function Creature:refresh_image_name()
  return false
end

--Gets a creature's speed stat value, including bonuses
--@param self Creature. The creature itself
--@return Number. The stat value
function Creature:get_speed()
  return self.speed+self:get_bonus('speed')
end

--Gets a creature's perception stat value, including bonuses
--@param self Creature. The creature itself
--@return Number. The stat value
function Creature:get_perception()
  return self.perception+self:get_bonus('perception')
end

--Makes a creature fly through the air to a target
--@param self Creature. The creature itself
--@param target Table. A table containing, at the least an x and y index. Can be a creature, a feature, or just a table with nothing but x and y.
--@param result Spell. What spell to use after the zoom is done. A spell object itself, not the ID (optional)
function Creature:flyTo(target,result)
  self.zoomFrom = {x=self.x,y=self.y}
  self.zoomTo = target --make the creature fly to the target
  --Make them fly through the air
  if not self:is_type('knockedback') then
    if self.types then table.insert(self.types,'knockedback') else self.types = {'knockedback'} end --make them a "knockedback," so they can go over pits n shit
  end
  if result then self.zoomResult = result end
end

--Become a thrall to another creature
--@param self Creature. The creature itself
--@param master Creature. The creature to become a thrall to
--@param skip_callbacks True/False. Whether to skip thrall callbacks (optional)
function Creature:become_thrall(master,skip_callbacks,skip_stats)
  --If you had an earlier master, unset yourself as their thrall first:
  if not self:become_free(skip_callbacks) then return false end
  if skip_callbacks == true or self:callbacks('became_thrall',master) then
    self.master = master
    master.thralls[self] = self
    if master.isPlayer == true then
      self.playerAlly = true
      local pop = Effect('dmgpopup')
      pop.color={r=0,g=0,b=255,a=255}
      pop.image_name = "exclamation"
      currMap:add_effect(pop,self.x,self.y)
      if not skip_stats then
        update_stat('thralls',self.id)
        update_stat('thralls_per_body',master.id)
      end
    end
    if self.target and master.thralls[self.target] then
      self.shitlist[self.target] = nil
      self.target = nil
    end -- if you were targetting your master's thrall, don't target them anymore
    for _, thrall in pairs(master.thralls) do
      if thrall.target and thrall.target == self then
        thrall.target = nil
      end -- if a thrall was targetting you, they won't be anymore
      --Unset hostility btwn self and master's thralls:
      thrall.shitlist[self] = nil
      self.shitlist[thrall] = nil
    end
    --If your target is not an enemy of your master, they are no longer your target
    if self.target and self.target.baseType == "creature" then
      if not self.target:is_enemy(master) then
        self.shitlist[self.target] = nil
        self.target = nil
      end
    end
  end
end

--Become free from your master
--@param self Creature. The creature itself
--@param skip_callbacks True/False. Whether to skip freedom callbacks (optional)
function Creature:become_free(skip_callbacks)
  if skip_callbacks == true or self:callbacks('became_free') then
    if not self.master then return true end
    if self.master == player then
      self.playerAlly = false
    end
    self.master.thralls[self] = nil
    self.master = nil
    return true
  end
end

--Free all this creature's thralls
--@param self Creature. The creature itself
function Creature:free_thralls()
  for _,creat in pairs(self.thralls) do
    creat:become_free()
  end
end

--"Level Up" a random stat. Either strength, dodging or melee
--@param self Creature. The creature itself
function Creature:level_up()
  local stats = {'strength','dodging','melee'}
  local stat = get_random_element(stats)
  if player:can_see_tile(self.x,self.y) and player:does_notice(self) then output:out(self:get_name() .. "'s " .. stat .. (stat ~= "strength" and " skill" or "") .. " increases!") end
  self[stat] = self[stat] + 1
end

--Gets how afraid a creature is
--@param self Creature. The creature itself
--@return Number. The fear value
function Creature:get_fear()
  local enemies = 0
  local friends = 0
  for _, creat in pairs(self:get_seen_creatures()) do
    if creat:is_enemy(self) then
      enemies = enemies + 1
    elseif creat == self or (self.faction and creat.faction and self.faction == creat.faction) or (self.playerAlly and creat.playerAlly) or (self.master and (creat == self.master or creat.master == self.master)) then
      friends = friends+1
    end --end enemy/friend if
  end --end creat for
  return (self.fear or 0)+(enemies-friends)+self:get_bonus('fear')
end

--Gets a creature's bravery stat value, including bonuses
--@param self Creature. The creature itself
--@return Number. The stat value
function Creature:get_bravery()
  return (self.bravery or 10000)+self:get_bonus('bravery')
end

--Gets a creature's aggression stat value, including bonuses
--@param self Creature. The creature itself
--@return Number. The stat value
function Creature:get_aggression()
  return (self.aggression or 100)+self:get_bonus('aggression')
end

--Gets a creature's animation_time stat value, including bonuses
--@param self Creature. The creature itself
--@return Number. The stat value
function Creature:get_animation_time()
  local perc_bonus = self:get_bonus('animation_time_percent') or 1
  return math.max(0,(self.animation_time or 0.5)*(perc_bonus ~= 0 and perc_bonus or 1)+self:get_bonus('animation_time'))
end

--Gets a creature's notice chance value, including bonuses
--@param self Creature. The creature itself
--@return Number. The stat value
function Creature:get_notice_chance()
  --Player's notice chance defaults to 100%, but can be changed by conditions or whatnot
  return (self == player and 100 or (self.notice_chance or 100))+self:get_bonus('notice_chance')
end

--Gets a creature's stealth stat value, including bonuses
--@param self Creature. The creature itself
--@return Number. The stat value
function Creature:get_stealth()
  if self.zoomTo then return -1000 end --if you're zooming somewhere, you're going to get noticed
  return (self.stealth or 0)+self:get_bonus('stealth')
end

--Gets a creature's damage value, including bonuses
--@param self Creature. The creature itself
--@return Number. The damage value
function Creature:get_damage()
  return self.strength + self:get_bonus('damage')
end

--Gets a creature's critical_chance stat value, including bonuses
--@param self Creature. The creature itself
--@return Number. The stat value
function Creature:get_critical_chance()
  return (self.critical_chance or 1)+self:get_bonus('critical_chance')
end

--Checks if a creature possesses a certain spell
--@param spellName Text. The name of the spell
--@return True/False. Whether the creature has the spell
function Creature:has_spell(spellName)
  return in_table(spellName,self.spells)
end

--Checks if a creature possesses a certain AI flag
--@param spellName Text. The AI flag
--@return True/False. Whether the creature has the AI flag
function Creature:has_ai_flag(flag)
  if self.ai_flags == nil then return false end
  for _,f in pairs(self.ai_flags) do
    if f == flag then return true end
  end --end for
  return false
end