---@classmod Creature
Creature = Class{}

---Initiates a creature. Don't call this explicitly, it's called when you create a new creature with Creature('creatureID').
--@param creatureType String. The ID of the creature you want to create.
--@param level Number. The level to set the creature to (optional)
--@param noItems Boolean. Whether to generate without items (optional)
--@return Creature. The creature itself.
function Creature:init(creatureType,level,noItems)
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
  self.level = self.level or 0
  self.max_hp = tweak(self.max_hp)
	self.hp = self.max_hp
  self.mp = self.max_mp
	self.conditions = {}
	self.spells = self.spells or {}
	self.cooldowns = {}
  self.thralls = {}
  self.checked = {}
  self.inventory = {}
  self.equipment = {}
  self.extra_stats = self.extra_stats or {}
  self.forbidden_spell_tags = self.forbidden_spell_tags or self.forbidden_tags or {}
  self.forbidden_item_tags = self.forbidden_item_tags or self.forbidden_tags or {}
  self.money = tweak(self.money or 0)
  self.xp = 0
  self.favor = self.favor or {}
  self.factions = self.factions or {}
  self.hands = self.hands or (self.noEquip and 0 or 2)
  if self.equipment_slots then
    local slotcount = 1
    for slot,count in pairs(self.equipment_slots) do
      self.equipment[slot] = {slots=count}
    end
    self.equipment_slots=nil
  elseif not self.noEquip then
    for slot,count in pairs(gamesettings.default_equipment_slots) do
      self.equipment[slot] = {slots=count}
    end
  end
  if not self.noEquip and self.hands and self.hands > 0 then
    self.equipment.weapon = self.equipment.weapon or {slots=self.hands}
    self.equipment.offhand = self.equipment.offhand or {slots=self.hands}
    self.equipment.ammo = self.equipment.ammo or {slots=1}
  end
	self.path = nil
	self.baseType = "creature"
  self.types = self.types or {}
  self.speed = tweak(self.speed or 100)
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
  --Inventory:
  if not noItems then
    self:generate_inventory() --generate inventory based on the creature definition's pre-set inventory chances
    --Generate inventory based on the creatures' creature types and factions:
    if self.types then
      for _,ctype in ipairs(self.types) do
        if creatureTypes[ctype] then self:generate_inventory(creatureTypes[ctype]) end
      end
    end
    if self.factions then
      for _,fac in ipairs(self.factions) do
        self:generate_inventory(currWorld.factions[fac])
      end
    end
  end
  --Weaknesses and resistances from your creature types:
  if self.types then
    for _,ctype in ipairs(self.types) do
      local typ = creatureTypes[ctype]
      if typ then
        if typ.weaknesses then
          if not self.weaknesses then self.weaknesses = {} end
          for dtype,amt in pairs(typ.weaknesses) do
            self.weaknesses[dtype] = (self.weaknesses[dtype] or 0) + amt
          end
        end --end if weaknesses
        if typ.resistances then
          if not self.resistances then self.resistances = {} end
          for dtype,amt in pairs(typ.resistances) do
            self.resistances[dtype] = (self.resistances[dtype] or 0) + amt
          end
        end --end if resistances
      end --end if type is defined
    end --end ctype for
  end --end if self.types
  --Level up if necessary:
  if level and level > self.level then
    if self.max_level and level > self.max_level then
      level = self.max_level
    end
    for i=self.level+1,level,1 do
      self:level_up(true)
    end
	end
	return self
end

---Generate items for a creature's inventory. Usually called when the creature first spawns
--@param source Table. The source of potential item lists. Defaults to the creature itself, and will frequently be either a creature type or a faction, but can be any table containing a possible_inventory, possible_death_items, or any possible_[equipslot] table. (optional)
function Creature:generate_inventory(source)
  source = source or self
  --Add inventory items:
  if source.possible_inventory then
    for _,def in ipairs(source.possible_inventory) do
      if not def.chance or random(1,100) <= def.chance then
        local amt = def.amount or random((def.min_amt or 1),(def.max_amt or 1))
        for i=1,amt,1 do
          self:give_item(Item(def.item))
        end
      end --end chance
    end --end loopthrough possible_inventory
  end --end if possible inventory
  --Add death items:
  if source.possible_death_items then
    self.death_items = {}
    for _,def in ipairs(source.possible_death_items) do
      if not def.chance or random(1,100) <= def.chance then
        local amt = (def.max_amt and random((def.min_amt or 1),def.max_amt) or 1)
        for i=1,amt,1 do
          local item = Item(def.item)
          self.death_items[#self.death_items+1] = item
        end
      end --end chance
    end --end loopthrough possible_inventory
  end --end if possible inventory
  --Equipment:
  if source.possible_weapon then
    local weapID = source.possible_weapon[random(#self.possible_weapon)]
    local hands = self.hands
    if weapID then
      local weap1 = self:give_item(Item(weapID))
      self:equip(weap1)
      hands = hands - weap1.hands
    end
    if self.dual_wielding and hands > 1 then
      
    end
  end
  for slot,info in pairs(self.equipment) do
    for i=1,(info.slots or 1) do
      if self['possible_' .. slot] and slot ~= "weapon" then
        local itemID = source['possible_' .. slot][(random(#self['possible_' .. slot]))]
        if itemID then
          local item = self:give_item(Item(itemID))
          self:equip(item)
        end --end if itemID
      end --end if checking if we have a possible list set
    end --end slots for
  end --end equipment_slots for
  
  --Delete the vistigial item lists:
  if source == self then
    self.possible_inventory = nil
    self.possible_death_items = nil
    self.possible_weapon = nil
    for slot,_ in pairs(self.equipment) do
      self['possible_' .. slot] = nil
    end
  end
end

---Applies a class definition to a creature, granting it that class's starting favor, spells, factions and items
--@param classID String. The ID of the class to apply
function Creature:apply_class(classID)
  local class = playerClasses[classID]
  self.class = classID
  self.name = self.name .. " " .. class.name
  if class.favor then
    for faction,favor in pairs(class.favor) do
      self.favor[faction] = (self.favor[faction] or 0) + favor
    end
  end --end favor if
  if class.factions then
    for _,faction in ipairs(class.factions) do
      if not self:is_faction_member(faction) then
        currWorld.factions[faction]:join(self)
      end
    end --end factions for
  end --end factions if
  if class.spells then
    for _,spell in ipairs(class.spells) do
      self:learn_spell(spell)
    end
  end --end if spells
  if class.items then
    for _,item in ipairs(class.items) do
      local itemID = item.item
      local count = item.amount or 1
      for i=1,count,1 do
        local it = self:give_item(Item(itemID,item.passed_info))
        if item.enchantment then
          it:apply_enchantment(item.enchantment,item.enchantment_turns or -1)
        end
      end
    end
  end --end if items
  if class.equipment then
    for _,item in ipairs(class.equipment) do
      local itemID = item.item
      local it = self:give_item(Item(itemID,item.passed_info))
      self:equip(it)
      if item.enchantment then
        it:apply_enchantment(item.enchantment,item.enchantment_turns or -1)
      end
    end
  end--end if equipment
  if class.stat_modifiers then
    for stat,mod in pairs(class.stat_modifiers) do
      self[stat] = (self[stat] or 0) + mod
    end
    self.hp = self.max_hp
    self.mp = self.max_mp
  end --end if stat_modifiers
  if class.extra_stats then
    for id,stat in pairs(class.extra_stats) do
      self.extra_stats[id] = copy_table(stat)
    end
  end
  if class.forbidden_spell_tags then
    for _, tag in pairs(class.forbidden_spell_tags) do
      self.forbidden_spell_tags[#self.forbidden_spell_tags+1] = tag
    end
  end
  if class.forbidden_item_tags then
    for _, tag in pairs(class.forbidden_item_tags) do
      self.forbidden_item_tags[#self.forbidden_item_tags+1] = tag
    end
  end
  if class.forbidden_tags then
    for _, tag in pairs(class.forbidden_tags) do
      self.forbidden_spell_tags[#self.forbidden_spell_tags+1] = tag
      self.forbidden_item_tags[#self.forbidden_item_tags+1] = tag
    end
  end
  if class.money then
    self.money = class.money
  end
end

---Get the name of a creature
--@param full Boolean. Whether to display the creature name after the proper name (optional)
--@param force Boolean. If set to true, will force display the name, even if the player can't see it (otherwise, will show as "Something"). (optional)
--@return String. The creature's name
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

---Get the pronoun of a creature
--@param ptype String. The pronoun type: n = nominative, p = possessive, o = objective
--@return String. The pronoun.
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
  elseif (self.gender == "custom") then
    if (ptype == 'n') then return (self.pronouns and self.pronouns.n or 'they') end
		if (ptype == 'p') then return (self.pronouns and self.pronouns.p or 'their') end
		if (ptype == 'o') then return (self.pronouns and self.pronouns.o or 'them') end
  else
    if (ptype == 'n') then return 'they' end
		if (ptype == 'p') then return 'their' end
		if (ptype == 'o') then return 'them' end
	end
  return "" --return an empty string if something went wrong, so there won't be a "concating nil" error
end

---Get the max HP of a creature
--@return Number. the max HP
function Creature:get_mhp()
	return self.max_hp+self:get_bonus('mhp')
end

---Get the max magic points of a creature
--@return Number. The max MP
function Creature:get_max_mp()
	return self.max_mp+self:get_bonus('max_mp')
end

---Change the HP of a creature
--@param amt Number. Can be positive or negative.
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

---Damage a creature
--@param amt Number. The damage to deal.
--@param attacker Entity. The source of the damage.
--@param damage_type String. The damage type of the attack. (optional)
--@param armor_piercing True/False, or Number. If set to true, it ignores all armor. If set to a number, ignores that much armor. (optional)
--@param noSound Boolean. If set to true, no damage type sound will be played. (optional)
--@param item Item. The weapon used to do the damage. (optional)
--@return Number. The final damage done.
function Creature:damage(amt,attacker,damage_type,armor_piercing,noSound,item)
  amt = math.ceil(amt) --just in case! to prevent fractional damage
  require "data.damage_types"
  damage_type = damage_type or "physical"
  
  --Apply damage weaknesses, resistances, and armor
  amt = amt + self:get_weakness(amt,damage_type)
  amt = amt - self:get_resistance(amt,damage_type)
  if armor_piercing ~= true then
    local totalArmor = (self.armor or 0)
    totalArmor = totalArmor + self:get_bonus('armor')
    totalArmor = totalArmor + self:get_bonus(damage_type .. '_armor')
    if type(armor_piercing) == "number" then
      totalArmor = totalArmor - armor_piercing
    end
    amt = amt - totalArmor
  end

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
    self.alert = self.memory
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
    if attacker and attacker.baseType == "creature" then
      self.lastAttacker = attacker
      self.lastAttackerWeapon = item
    else
      self.lastAttackerWeapon = nil --This is done so if you hit someone, then they die from a non-attack, we'll still call you the killer. But not your weapon
    end
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
    for _,slot in pairs(self.equipment) do
      for _,item in ipairs(slot) do
        item:decrease_all_enchantments('damaged')
      end
    end
		return amt
	else
		return 0
	end
end

---Give a condition to a creature
--@param name String. The ID of the condition.
--@param turns Number. How many turns the condition should last.
--@param applier Entity. Who applied the condition. (optional)
--@param force Boolean. Whether to force-apply the condition. (optional)
--@return Boolean. Whether the condition was applied
function Creature:give_condition(name,turns,applier,force)
  if not force and self:is_type('ghost') and conditions[name].ghost ~= true then return false end
  local ap = ap
	if conditions[name]:apply(self,applier,turns) ~= false then
    self.conditions[name]=(type(ap) == "number" and ap or turns)
  end
	return true
end

---Called every turn, this advances all the conditions and decreases all the spell cooldowns 
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
  for _,spell in pairs(self:get_spells()) do
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

---Cure a condition.
--@param condition String. The ID of the condition to cure
function Creature:cure_condition(condition)
  if self.conditions[condition] then
    conditions[condition]:cure(self)
    self.conditions[condition] = nil
  end
end

---Check if a creature has a condition
--@param condition String. The ID of the condition to check
--@return Boolean. Whether the creature has the condition.
function Creature:has_condition(condition)
  if self.conditions[condition] then
    return true
  else
    return false
  end
end

---Checks the callbacks of the base creature type, any conditions the creature might have, any items the creature has equipped, and any spells the creature might have.
--@param callback_type String. The callback type to check.
--@param … Anything. Any info you want to pass to the callback. Each callback type is probably looking for something specific (optional)
--@return Boolean. If any of the callbacks returned true or false.
--@return Table. Any other information that the callbacks might return.
function Creature:callbacks(callback_type,...)
  local ret = {}
  if type(possibleMonsters[self.id][callback_type]) == "function" then
    local status,r = pcall(possibleMonsters[self.id][callback_type],self,unpack({...}))
    if status == false then
        output:out("Error in creature " .. self.name .. " callback \"" .. callback_type .. "\": " .. r)
      end
		if (r == false) then return false end
    if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
  end
	for condition, _ in pairs(self.conditions) do
		if type(conditions[condition][callback_type]) == "function" then
			local status,r = pcall(conditions[condition][callback_type],conditions[condition],self,unpack({...}))
      if status == false then
        output:out("Error in condition " .. conditions[condition].name .. " callback \"" .. callback_type .. "\": " .. r)
      end
			if (r == false) then return false end
      if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
		end
	end
	for id, spell in pairs(self:get_spells()) do
		if type(possibleSpells[spell][callback_type]) == "function" then
			local status,r = pcall(possibleSpells[spell][callback_type],possibleSpells[spell],self,unpack({...}))
      if status == false then
        output:out("Error in spell " .. possibleSpells[spell].name .. " callback \"" .. callback_type .. "\": " .. r)
      end
			if (r == false) then return false end
      if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
		end
	end
  for _, equipslot in pairs(self.equipment) do
    for _, equip in ipairs(equipslot) do
      if type(possibleItems[equip.id][callback_type]) == "function" then
        local status,r = pcall(possibleItems[equip.id][callback_type],equip,self,unpack({...}))
        if status == false then
          output:out("Error in item " .. possibleItems[equip.id].name .. " callback \"" .. callback_type .. "\": " .. r)
        end
        if (r == false) then return false end
        if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
      end --end function exists if
      for ench,_ in pairs(equip:get_enchantments()) do --TODO: This might be a potential slowdown spot
        if type(enchantments[ench][callback_type]) == "function" then
          local status,r = pcall(enchantments[ench][callback_type],equip,self,unpack({...}))
          if status == false then
            output:out("Error in enchantment " .. enchantments[ench].name .. " callback \"" .. callback_type .. "\": " .. r)
          end
          if (r == false) then return false end
          if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
        end --end function exists if
      end --end enchantment for
    end
	end
  for missionID, missionStatus in pairs(currGame.missionStatus) do
    local mission = possibleMissions[missionID]
    if mission and type(mission[callback_type]) == "function" then
      local status,r = pcall(mission[callback_type],mission,self,unpack({...}))
      if status == false then
        output:out("Error in mission " .. mission.name .. " callback \"" .. callback_type .. "\": " .. r)
      end
      if (r == false) then return false end
      if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
    end
  end
	return true,ret
end

---Get the extended description of a creature, including information like its health info, friendliness to the player, etc.
--@return String. The description of the creature.
function Creature:get_description()
	local desc = self:get_name(true) .. "\n" .. self.description
	desc = desc .. "\n" .. self:get_health_text(true)
  if self.master and self.master ~= player then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " is under the command of " .. self.master:get_name(false,true) .. "." end
  if (self.isPlayer ~= true) then
    if (self.playerAlly == true) then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " is under your command."
    elseif self.notices[player] and self.ignoring[player] then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " is ignoring you."
    elseif self.notices[player] and not self.shitlist[player] then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. (self:is_friend(player) and " is friendly towards you." or " is watching you suspiciously.")
    elseif (self.notices[player] and self.shitlist[player]) then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " is hostile towards you."
    else desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " has not noticed you." end
    if self:get_fear() > self:get_bravery() then desc = desc .. "\n" .. ucfirst(self:get_pronoun('n')) .. " is afraid, and will try to run from enemies if possible." end
  if action == "targeting" and actionResult then
    local dist = calc_distance(player.x,player.y,self.x,self.y)
    if actionResult.range and dist > actionResult.range then
      desc = desc .. "\nIt is too far away to be targeted."
    elseif actionResult.minRange and dist < actionResult.minRange then
      desc = desc .. "\nIt is too close to be targeted."
    elseif actionResult.projectile and not player:can_shoot_tile(self.x,self.y) then
      desc = desc .. "\nYou can't hit it from here."
    elseif actionResult.calc_hit_chance then
      desc = desc .. "\n" .. actionResult.name .. " hit chance: " .. actionResult:calc_hit_chance(player,self,actionItem) .. "%"
    end
  end
    --Debug stuff:
    if debugMode then
      desc = desc .. "\nFear: " .. self:get_fear() .. "/" .. self:get_bravery()
      if self.target then
        if self.target.baseType == "creature" then desc = desc .. "\nTarget: " .. self.target:get_name()
        else desc = desc .. "\nTarget: " .. self.target.x .. ", " .. self.target.y end
      end --end if self.target
      desc = desc .. "\nWeapons : "
      for _,item in ipairs(self.equipment.weapon) do
        desc = desc .. item:get_name(true) .. ", "
      end
      desc = desc .. "\nAccessories : "
      for _,item in ipairs(self.equipment.accessory) do
        desc = desc .. item:get_name(true) .. ", "
      end
      desc = desc .. "\nInventory : "
      for _,item in ipairs(self.inventory) do
        desc = desc .. item:get_name(true) .. ", "
      end
    end --end debugmode if
  end --end isPlayer
	
	return desc
end

---Get a description of a creature's health
--@param full Boolean. Whether to return a full sentence or just a short description (optional)
--@return String. The health text
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

---Get the bonus of a certain type, looking at conditions and equipment.
--@param bonusType String. The type of bonus to check for. Usually a stat
--@param average Boolean. Whether or not to average the total bonus before returning it (optional)
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
  for whichSlot, equipslot in pairs(self.equipment) do
    for _, equip in ipairs(equipslot) do
      if equip.bonuses ~= nil then
        local b = equip.bonuses[bonusType]
        if b ~= nil then
          bonus = bonus + b
          bcount = bcount + 1
        end
      end --end bonuses if
      --Get bonuses from equipment enchantment:
      if whichSlot ~= "weapon" then --Don't apply any enchantment bonuses from weapons. We have to assume those bonuses are intended only for attacks done with the weapon
        local b = equip:get_enchantment_bonus(bonusType)
        if b ~= 0 then
          bonus = bonus + b
          bcount = bcount + 1
        end
      end
    end --end equipment for
	end --end equipslot for
  if average and bcount > 0 then bonus = math.ceil(bonus/bcount) end
	return bonus
end

---Check how much damage of a given damage type is reduced by a creature's resistances and bonuses
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

---Check how much damage of a given damage type is increased by a creature's weaknesses and bonuses
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

---Check what hit conditions a creature can inflict
--@return Table. The list of hit conditions
function Creature:get_hit_conditions()
	return (self.hit_conditions or {})
end

---Attack another entity. If any weapons are equipped, this function will call their attack code instead.
--@param target Entity. The creature (or feature) they're attacking
--@param forceHit Boolean. Whether to force the attack instead of rolling for it.
--@param ignore_callbacks Boolean. Whether to ignore any of the callbacks involved with attacking
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
  
  local weapons = self:get_equipped_in_slot('weapon')
  if #weapons > 0 then
    local totaldmg = 0
    for _,weapon in pairs(weapons) do
      totaldmg = totaldmg + (weapon:attack(target,self) or 0)
    end
    return totaldmg
  end
  
  --Basic attack:
  if target.baseType == "feature" and self:touching(target) then
    return target:damage(self:get_damage(),self,self.damage_type)
	elseif self:touching(target) and (ignore_callbacks or self:callbacks('attacks',target) and target:callbacks('attacked',self)) then
		local result,dmg = calc_attack(self,target)
    if forceHit == true then result = 'hit' end
		local hitConditions = self:get_hit_conditions()
		local txt = ""

		if (result == "miss") then
			txt = txt .. ucfirst(self:get_name()) .. " misses " .. target:get_name() .. "."
      dmg = 0
      if player:can_see_tile(self.x,self.y) or player:can_see_tile(target.x,target.y) and player:does_notice(self) and player:does_notice(target) then
        output:out(txt)
      end
		else
			if (result == "critical") then txt = txt .. "CRITICAL HIT! " end
      local bool,ret = self:callbacks('calc_damage',target,dmg)
      if (bool ~= false) and #ret > 0 then --handle possible returned damage values
        local count = 0
        local amt = 0
        for _,val in pairs(ret) do --add up all returned damage values
          if type(val) == "number" then count = count + 1 amt = amt + val end
        end
        if count > 0 then dmg = math.ceil(amt/count) end --final damage is average of all returned damage values
      end
			dmg = target:damage(dmg,self,self.damage_type,self:get_armor_piercing())
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
      
      if player:can_see_tile(self.x,self.y) or player:can_see_tile(target.x,target.y) and player:does_notice(self) and player:does_notice(target) then
        output:out(txt)
      end
			self:callbacks('damages',target,dmg)
      --Handle conditions:
			for _, condition in pairs (hitConditions) do
        local targetNum = (result == "critical" and condition.crit_chance or (condition.hit_chance or 0)) --If a critical, use critical chance, defaulting to regular chance. If it's a critical-only condition, regular chance defaults to 0
				if (random(1,100) < targetNum) then
          local turns = nil
          if result == "critical" then
            turns = (condition.crit_minTurns and condition.crit_maxTurns and random(condition.crit_minTurns,condition.crit_maxTurns) or (condition.critTurns and tweak(condition.critTurns) or nil))
          end
          if not turns then
            turns = ((condition.minTurns and condition.maxTurns and random(condition.minTurns,condition.maxTurns)) or tweak(condition.turns or 0))
          end
					target:give_condition(condition.condition,turns,self)
				end -- end condition chance
			end	-- end condition forloop
		end -- end hit if
		return dmg
	else -- if not touching target
		return false
	end
end

---This function is run every turn. It handles advancing conditions, recharging attacks, and AI for NPCs
--@param skip_conditions Boolean. Whether to skip running the condition advance code (optional)
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

---Check whether a creature can move to a given tile
--@param x Number. The x coordinate
--@param y Number. The y coordinate
--@param inMap Map. The map to check. Defaults to current map (optional)
--@return Boolean. Whether or not the creature can move to that tile
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

---Move a creature to a tile
--@param x Number. The x coordinate
--@param y Number. The y coordinate
--@param skip_callbacks Boolean. Whether to skip any callbacks related to movement (optional)
--@param noTween Boolean. If true, move there instantly, no tweening animation (optional)
--@return Boolean. If the creature successfully moved
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

---Forcibly move a creature to a tile, no matter what. Do not use this function unless you absolutely have to, it is terrible and goes against everything we stand for, and can lead to creatures being stuck in places they shouldn't be, multiple creatures in a tile, or other things that you generally don't want.
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

---Check if a creature is touching something else
--@param target Entity. The entity to check (can be any table with an X and Y coordinate)
--@return Boolean. Whether they're touching
function Creature:touching(target)
	if (math.abs(target.x-self.x) <= 1 and math.abs(target.y-self.y) <= 1) then
		return true
	end
	return false
end

---Kill a creature.
--@param killer Entity. Whodunnit? By default, nothing actually passes in a killer, but it's here just in case
function Creature:die(killer)
  if self.isDead then return self:remove() end
  if killer then self.killer = killer end
  if killer == nil and self.lastAttacker then
    self.killer = self.lastAttacker
  end
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
      update_stat('ally_deaths_as_class',player.class)
      update_stat('ally_deaths_as_creature_class_combo',player.id .. "_" .. player.class)
      update_stat('creature_ally_deaths',self.id)
    end
    if (self.killer and self.killer.baseType == "creature") then
      local xp = math.max(0,10-(self.killer.level-self.level))
      if xp > 0 then self.killer:give_xp(xp) end
      local favor = self:get_kill_favor()
      if (self.killer.playerAlly == true) then
        if self.killer == player then
          update_stat('kills')
          update_stat('kills_as_creature',player.id)
          update_stat('kills_as_class',player.class)
          update_stat('kills_as_creature_class_combo',player.id .. "_" .. player.class)
          update_stat('creature_kills',self.id)
          update_stat('branch_kills',currMap.branch)
          update_stat('map_kills',currMap.id)
          achievements:check('kill')
          output:out("You kill " .. self:get_name() .. "!" .. (xp > 0 and " You gain " .. xp .. " XP!" or ""))
        else
          update_stat('ally_kills')
          update_stat('ally_kills_as_creature',player.id)
          update_stat('ally_kills_as_class',player.class)
          update_stat('ally_kills_as_creature_class_combo',player.id .. "_" .. player.class)
          update_stat('allied_creature_kills',self.killer.id)
          update_stat('creature_kills_by_ally',self.id)
          output:out(self.killer:get_name() .. " kills " .. self:get_name() .. "!" .. (xp > 0 and " You gain " .. xp .. " XP!" or ""))
        end
        run_all_events_of_type('player_kills')
      else --killed by a non-player ally
        if player:can_sense_creature(self) then output:out(self.killer:get_name() .. " kills " .. self:get_name() .. "!") end
      end
      for fac,favor in pairs(favor) do
        local member = self.killer:is_faction_member(fac)
        if not currWorld.factions[fac].members_only_favor or member then
          self.killer.favor[fac] = (self.killer.favor[fac] or 0) + favor
          if self.killer.playerAlly == true and favor ~= 0 then
            output:out("You " .. (favor > 0 and "gain " or "lose ") .. math.abs(favor) .. " favor with " .. currWorld.factions[fac].name .. ".")
          end
          if currWorld.factions[fac].banish_threshold and member and self.killer.favor[fac] < currWorld.factions[fac].banish_threshold then
            currWorld.factions[fac]:leave(self.killer)
            if self.killer.playerAlly == true  then
              output:out("You are kicked out of " .. currWorld.factions[fac].name .. "!")
            end
          end --end banich favor if
        end --end if member/members only favor
      end --end faction for
    elseif seen and not self:is_type('ghost') then --killed by something other than a creature
      output:out(self:get_name() .. " dies!")
    end --end playerally killer if
    
    --Free Thralls:
    self:free_thralls()
    
    --Carve a notch into the killer's weapon:
    local weap = self.lastAttackerWeapon 
    if self.lastAttackerWeapon then
      weap.kills = (weap.kills or 0)+1
      weap:decrease_all_enchantments('kill') --decrease the turns left for any enchantments that decrease on kill
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
      
      self:drop_all_items(true)
    end --end absorbs if
  
    if self == player then
      if action ~= "dying" then player_dies() end
    else
      self:remove()
    end
  end --end dies callback if
end

---Make a creature explode.
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
          elseif self:is_friend(creat) then
            creat.fear = creat.fear + 10 -- seeing a friend explode? scary
          elseif not creat:is_enemy(self) then --seeing an enemy explode is not scary
            creat.fear = creat.fear + 5  --seeing a rando explode is a little scary
          end
        end
      end --end in_map if
    end --end fory
  end --end forx
  
  self:drop_all_items(true)
  if self == player then player_dies()
  else self:remove() end
end -- end function

---Remove a creature from the map without killing it. Called to clean up after the creature dies, but can also be called whenever to remove them for some other reason.
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

---Have a creature pick up an item from a tile.
--@param item Item. The item to pick up
--@param tileOnly Boolean. Whether to only allow pickups from the tile the creature is standing on. If not set to TRUE, creatures can also pick up from adjacent tiles.
function Creature:pickup(item,tileOnly)
  local didIt,pickupText = nil,nil
  if possibleItems[item.id].pickup then
    didIt,pickupText = possibleItems[item.id].pickup(item,self)
  end
  if didIt ~= false then
    local x,y = self.x,self.y
    if (tileOnly ~= true and not self:touching(item)) or (tileOnly == true and (item.x ~= x or item.y ~= y)) then return false end
    currMap.contents[item.x][item.y][item] = nil
    self:give_item(item)
    if player:can_sense_creature(self) then
      output:out(pickupText or self:get_name() .. " picks up " .. item:get_name() .. ".")
    end
  end
end

---Transfer an item to a creature's inventory
--@param item Item. The item to give.
function Creature:give_item(item)
  if (item.stacks == true) then
    local _,inv_id = self:has_item(item.id,(item.sortBy and item[item.sortBy]),item.enchantments)
    if inv_id then
      self.inventory[inv_id].amount = self.inventory[inv_id].amount + item.amount
      item = self.inventory[inv_id]
    else
      table.insert(self.inventory,item)
    end
  else
    table.insert(self.inventory,item)
  end
  item.x,item.y=self.x,self.y
  item.owner = self
  return item
end

---Have a creature drop an item on the tile they're on
--@param item Item. The item to drop
function Creature:drop_item(item)
	local id = in_table(item,self.inventory)
	if (id) then
    currMap:add_item(item,self.x,self.y,true)
		table.remove(self.inventory,id)
		if player:can_sense_creature(self) then output:out(self:get_name() .. " dropped " .. item:get_name() .. ".") end
    if self:is_equipped(item) then
      self:unequip(item)
      item.x,item.y=self.x,self.y
      item.owner=nil
    end
	end
end

---Have a creature drop all their items on the tile they're on
--@param deathItems Boolean. Whether to also drop death items
function Creature:drop_all_items(deathItems)
	for _,item in ipairs(self.inventory) do
    currMap:add_item(item,self.x,self.y,true)
    if self:is_equipped(item) then
      self:unequip(item)
      item.x,item.y=self.x,self.y
    end
	end --end inventory for loop
  if deathItems and self.death_items then
    for _,item in ipairs(self.death_items) do
      currMap:add_item(item,self.x,self.y,true)
    end --end inventory for loop
  end
  --Money:
  if self.money then
    local money = Item('money',self.money)
    currMap:add_item(money,self.x,self.y,true)
  end
  self.inventory = {}
  self.death_items = nil
end

---Remove an item from a creature's inventory
--@param item Item. The item to remove
--@param amt Number. The amount of the item to remove, if the item is stackable. Defaults to 1. 
function Creature:delete_item(item,amt)
  amt = amt or 1
	local id = in_table(item,self.inventory)
	if (id) then
    if amt == -1 or amt >= (item.amount or 0) then
      table.remove(self.inventory,id)
    else
      item.amount = item.amount - amt
    end
    if self:is_equipped(item) then
      self:unequip(item)
    end
	end
end
  
---Check if a creature has an instance of an item ID
--@param item String. The item ID to check for
--@param sortBy Text. What the "sortBy" value you're checking is
--@param enchantments Table. The table of echantments to match (optional)
--@return either Boolean or Item. False, or the specific item they have in their inventory
--@return either nil or Number. The index of the item in the inventory
--@return either nil or Number. The amount of the item the player has
function Creature:has_item(itemID,sortBy,enchantments)
  enchantments = enchantments or {}
	for id, it in ipairs(self.inventory) do
		if (itemID == it.id) and (not it.sortBy or sortBy == it[it.sortBy]) then
      local matchEnch = true
      --Compare enchantments:
      if (enchantments and count(enchantments) or 0) == (it.enchantments and count(it.enchantments) or 0) then
        for ench,turns in pairs(enchantments) do
          if it.enchantments[ench] ~= turns then
            matchEnch = false
            break
          end
        end --end enchantment for
      else --if the number of enchantments doesn't match, obviously the enchantments themselves won't match
        matchEnch = false
      end
      
      if matchEnch == true then
        return it,id,it.amount
      end
		end
	end --end inventory for
	return false
end

---Check if a creature has a specific item
--@param item Item. The item to check for
--@return either Boolean or Item. False, or the specific item they have in their inventory
--@return either nil or Number. The index of the item in the inventory
--@return either nil or Number. The amount of the item the player has
function Creature:has_specific_item(item)
	for id, it in ipairs(self.inventory) do
    if item == it then
      return it,id,it.amount
		end
	end --end inventory for
	return false
end

---Check if a creature has a specific item equipped
--@param item Item. The item to check for
--@return Boolean. Whether the item is equipped.
function Creature:is_equipped(item)
  local equipSlot = item.equipSlot
  if not equipSlot or not self.equipment[equipSlot] then return false end
  
  for i=1,self.equipment[equipSlot].slots,1 do
    if self.equipment[equipSlot][i] == item then
      return true
    end --end if item == item if
  end --end slot check for
	return false
end

---Get a list of all equipment a creature has equipped in an equipment slot
--@param slot String. The equipment slot to check
--@return Table. A list of the equipment.
function Creature:get_equipped_in_slot(slot)
  local equipped = {}
  if not slot or not self.equipment[slot] then return {} end
  for id,equip in ipairs(self.equipment[slot]) do
    equipped[#equipped+1] = equip
  end
  return equipped
end

---Equip an item
--@param item Item. The item to equip
--@return Boolean. Whether or not the item was equipped.
--@return String. Text describing the equipping.
function Creature:equip(item)
  local slot = item.equipSlot
  local equipText = ""
  if not slot then return false,"You can't equip this type of item." end
  
  --Check for level/stat requirements, etc
  local canEquip,noText = self:can_use_item(item,"equip")
  if canEquip == "false" then
    return false,noText
  end
  
  --For items that require "hands" to equip (presumably weapons and offhand items only)
  if item.hands then
    --First, check to make sure we even have the correct number of hands
    if item.hands > (self.hands or 0) then
      return false,"You don't have enough hands to equip " .. item:get_name() .. "."
    end
    --Add up all the hands currently being used:
    local handsUsed = 0
    for i=1,self.equipment.weapon.slots,1 do
      local weap = self.equipment.weapon[i]
      if weap then
        handsUsed = handsUsed + weap.hands
      end
    end
    for i=1,self.equipment.offhand.slots,1 do
      local off = self.equipment.offhand[i]
      if off then
        handsUsed = handsUsed + off.hands
      end
    end
    if handsUsed + item.hands > self.hands then
      local didIt = false
      --Figure out what items to unequip
      local initialslots = 0
      local unequips = {}
      --Start with the type you're trying to equip first (so you'll unequip weapons first if equipping a weapon, or offhands if equipping an offhand)
      for i=1,self.equipment[slot].slots,1 do
        if self.equipment[slot][i] and self.equipment[slot][i].hands then
          initialslots = initialslots + self.equipment[slot][i].hands
        end
        unequips[#unequips+1] = self.equipment[slot][i]
        if initialslots >= item.hands then
          for i=1,#unequips,1 do
            self:unequip(unequips[i])
          end
          return self:equip(item)
        end
      end --end equipment slot for
      
      local slot2 = (slot == "weapon" and "offhand" or "weapon")
      for i=1,self.equipment[slot2].slots,1 do
        if self.equipment[slot2][i] and self.equipment[slot2][i].hands then
          initialslots = initialslots + self.equipment[slot2][i].hands
        end
        unequips[#unequips+1] = self.equipment[slot2][i]
        if initialslots >= item.hands then
          for i=1,#unequips,1 do
            self:unequip(unequips[i])
          end
          return self:equip(item)
        end
      end --end equipment slot for
      
      return false,equipText
    end
  end
  
  --Do the actual equipping:
  local equipSlot = self.equipment[slot]
  if equipSlot then
    for i=1,equipSlot.slots,1 do
      if not equipSlot[i] then --if there's an empty slot, just use that
        local didIt = true
        if possibleItems[item.id].equip then
          didIt,equipText = possibleItems[item.id].equip(item,self)
        end
        if didIt ~= false then
          equipSlot[i] = item
          equipText = equipText .. (item.equipText or "You equip " .. item:get_name() .. ".")
        end
        return didIt,equipText
      end --end if empty slot if
    end --end slots for
    
    --If there aren't any empty slots, unequip the last one:
    local unequipped,uqtext = self:unequip(equipSlot[1])
    equipText = equipText .. uqtext
    if not unequipped then  --if for whatever reason unequipping the item failed, return false
      return false,equipText
    end
    --Now that we've unequipped the item, try equipping again by just running this function again:
    local didIt,newText = self:equip(item)
    equipText = equipText .. newText
    return didIt,equipText
  else
    return false,"You don't have the right body type to equip that."
  end
end

---Unequip an item
--@param item Item. The item to unequip
--@return Boolean. Whether or not the item was successfully unequipped. The only reason this would be false would be if the item had an unequip callback, or if the creature didn't even have the item equipped in the first place.
--@return String. Text describing the unequipping.
function Creature:unequip(item)
  local equipSlot = item.equipSlot
  local unequipText = ""
  if not equipSlot or not self.equipment[equipSlot] then return false,"That item is not equipped." end
  
  for i=1,self.equipment[equipSlot].slots,1 do
    if self.equipment[equipSlot][i] == item then
      local didIt = true
      if possibleItems[item.id].unequip then
        didIt,unequipText = possibleItems[item.id].unequip(item,self)
      end
      if didIt ~= false then
        self.equipment[equipSlot][i] = nil
        unequipText = unequipText .. (item.unequipText or "You unequip " .. item:get_name() .. ".")
        --Slide other items of this equiptype to fill empty slot
        if i ~= self.equipment[equipSlot].slots then
          for i2=i+1,self.equipment[equipSlot].slots,1 do
            self.equipment[equipSlot][i2-1] = self.equipment[equipSlot][i2]
            self.equipment[equipSlot][i2] = nil
          end
        end --end if i ~= max slot
      end --end if didIt
      return didIt,unequipText
    end --end if item == item if
  end --end slot check for
	return false,unequipText
end

---Determine if a creature can use this item or not
--@param item Item. The item to check
--@param verb Text. The verb the item uses. Or "equip" if it's equipment we're looking at, which also makes it check hands
--@return Boolean. Whether or not it's equippable
--@return Text. Why you can't equip it, if applicable. Nil if it is equipable.
function Creature:can_use_item(item,verb)
  verb = verb or "use"
  if item.level_requirement and self.level < item.level_requirement then
    return false,"You're not a high enough level to " .. verb .. " " .. item:get_name() .. "."
  elseif item.stat_requirements then
    for stat,requirement in pairs(item.stat_requirements) do
      if self:get_stat(stat,true) < requirement and self:get_bonus_stat(stat,true) < requirement then
        return false,"Your " .. stat .. " stat is too low to " .. verb .. " "  .. item:get_name() .. "."
      end
    end
  elseif player.forbidden_item_tags and count(player.forbidden_item_tags) > 0 then
    for _,tag in ipairs(player.forbidden_item_tags) do
      if item:has_tag(tag) then
        return false,"You can't " .. verb .. " this type of item."
      end
    end
  end
  return true
end

---Check if a creature can see a given tile
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param forceRefresh Boolean. Whether to force actually calculating if a player can see it, versus just looking at the stored values of player sight. Useful only when calling this for the player.
--@return Boolean. Whether or not they can see it.
function Creature:can_see_tile(x,y,forceRefresh)
  if (self == player) and currGame.cheats.seeAll==true then return true end
  if not currMap or not currMap:in_map(x,y,true) then return false end
  if not self.x or not self.y then output:out(self:get_name() .. " does not have a location but is trying to see stuff somehow.") return false end --If you don't exist, you can't see anything
  
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

---Check if a creature can sense another, either through sight or spooky senses.
--@param creat Creature. The creature to check.
--@param skipSight Boolean. Whether to skip running can_see_tile and just look at extra senses (optional)
--@return Boolean. If the target can be seen.
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

---Check if you can draw a straight line between the creature and a tile.
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Boolean. Whether or not they can shoot it.
function Creature:can_shoot_tile(x,y)
  --if (self == player) then return true end
	local dist = calc_distance(self.x,self.y,x,y)
	if (self:get_perception() > dist) then
		return currMap:is_line(self.x,self.y,x,y,false,'flyer',false,true,true)
	end
	return false
end

---Check if a creature is a potential enemy. This is NOT to check if they're actually currently hostile.
--@param target Creature. The target to check
--@param dontSend Boolean. The dontSend argument here is used when is_enemy() is called for checking a master's enemies. In the weird (but possible) case where two creatures were masters of each other, this would result in an infinite loop. Don't use it yourself. (optional)
--@return Boolean. Whether or not they're enemies
function Creature:is_enemy(target,dontSend)
  if target == self then return false end -- You are never an enemy of yourself
  if self.master and ((target == self.master) or (target.master and self.master == target.master)) then return false end --You are never an enemy of your master or your master's thralls
  if not dontSend and self.master and target:is_enemy(self.master,true) then return true end -- if they're an enemy of your master, they're also your enemy
  if self.ignoring and self.ignoring[target] then return false end -- if you're ignoring it, you won't consider it an enemy
  if self.shitlist and self.shitlist[target] then return true end --if it's on your shitlist, it's your enemy regardless of faction
  if self:is_faction_member('passive') then return false end --passive only attacks those who attack them
  
  if (self.playerAlly == true) then
    if target.playerAlly == true then return false end --if you're both player allies, you're not enemies
    if target.playerAlly ~= true and (target:is_enemy(player,dontSend) or self:is_faction_enemy(target) or self:is_enemy_type(target)) then return true end --if the target is not a player ally, and is an enemy of the player, an enemy of your faction, or an enemy creature type, they're your enemy too
  else --if we're not a player ally
    if self:is_faction_enemy(target) or self:is_enemy_type(target) then
      return true --if the target is an enemy of your faction, or a creature type you consider an enemy then they're you're enemy too
    elseif not self.factions and target.playerAlly == true and not self:is_friendly_type(target) then
      return true --default behavior for non-faction enemies is to treat player and their allies as enemies unless they're a creature type they like
    end
  end --end playerally or not check
  return false --default to not enemy
end

---Check if a creature is a potential friend. This is NOT to check if they're actually currently friendly.
--@param target Creature. The target to check.
--@return Boolean. Whether or not they're friends.
function Creature:is_friend(target)
  if target == self then return true end --You're always a friend to yourself
  if self.master and ((target == self.master) or (target.master and self.master == target.master)) then return true end --You're always a friend to your master and their other thralls
  if self:is_faction_member('passive') and not self.shitlist[target] then return true end --passive only attacks those who attack them
  if self:is_friendly_type(target) or self:is_faction_friend(target) then return true end --if it's a type you're friendly to, or someone your faction considers a friend, then you're a friend too
  return false
end

---Checks if a creature is of a certain type
--@param ctype String. The creature type to check for
--@return Boolean. Whether or not the creature is that type
function Creature:is_type(ctype)
  if not self.types then return false end
  for _,c in pairs(self.types) do
    if c == ctype then return true end
  end --end for
  return false
end --end function

---Determine if a creature is an enemy type of yours (this function ignores factions, but does look at your creature types' enemy types list)
--@param target Creature. The creature to check
--@return Boolean. If they're an enemy type
function Creature:is_enemy_type(target)
  if not target.types then return false end
  if self.enemy_types then
    for _,ctype in ipairs(self.enemy_types) do
      if target:is_type(ctype) then return true end
    end
  end
  if self.types then --Check through the enemy types for all your creature types
    for _,ctype in ipairs(self.types) do
      if creatureTypes[ctype] and creatureTypes[ctype].enemy_types then
        for _,ct in ipairs(creatureTypes[ctype].enemy_types) do
          if target:is_type(ct) then return true end
        end --end enemy_types for
      end --end if creatureTypes[ctype]
    end --end self ctype for
  end --end if self.types
  return false
end

---Determine if a creature is a friendly type of yours (this function ignores factions, but does look at your creature types' friendly types list)
--@param target Creature. The creature to check
--@return Boolean. If they're a friendly type
function Creature:is_friendly_type(target)
  if not target.types then return false end
  if self.friendly_types then
    for _,ctype in pairs(self.friendly_types) do
      if target:is_type(ctype) then return true end
    end
  end
  if self.types then --Check through the enemy types for all your creature types
    for _,ctype in ipairs(self.types) do
      if creatureTypes[ctype] and creatureTypes[ctype].friendly_types then
        for _,ct in ipairs(creatureTypes[ctype].friendly_types) do
          if target:is_type(ct) then return true end
        end --end enemy_types for
      end --end if creatureTypes[ctype]
    end --end self ctype for
  end --end if self.types
  return false
end

---Checks if a creature is an enemy of any of your factions
--@param target Creature. The creature to check
--@return Boolean. Whether or not the creature is an enemy of any of your factions
function Creature:is_faction_enemy(target)
  if not self.factions then return false end
  for _,f in pairs(self.factions) do
    if currWorld.factions[f]:is_enemy(target) then return true end
  end
  return false
end --end function

--Checks if a creature is a friend of any of your factions
--@param target Creature. The creature to check
--@return Boolean. Whether or not the creature is a friend of any of your factions
function Creature:is_faction_friend(target)
  if not self.factions then return false end
  for _,f in pairs(self.factions) do
    if currWorld.factions[f]:is_friend(target) then return true end
  end
  return false
end --end function

---Checks if the creature is a member of a certain faction
--@param fac String. The faction ID to check for
--@return Boolean. Whether or not the creature is a member of that faction
function Creature:is_faction_member(fac)
  if not self.factions then return false end
  for _,f in pairs(self.factions) do
    if f == fac then return true end
  end
  return false
end --end function

---Gets the favor you get for killing this creature.
--@return Table. A table of factions, and the favor scores
function Creature:get_kill_favor()
  local favor = {}
  local favorMax = {}
  local favorMin = {}
  --Kill favor defined in the creature definition itself:
  if self.kill_favor then
    for faction,score in pairs(self.kill_favor) do
      favor[faction] = (favor[faction] or 0) + score
      if score > 0 then favorMax[faction] = score
      else favorMin[faction] = score end
    end
  end --end if self.kill_favor
  --Next, loop through all the factions in the game to look at their kill_favor skills
  for fid,faction in pairs(currWorld.factions) do
    favorMax[fid] = favorMax[fid] or 0
    favorMin[fid] = favorMin[fid] or 0
    if faction.kill_favor then --If the faction has a straight favor score for killing anything
      if faction.kill_favor > 0 then favorMax[fid] = faction.kill_favor
      else favorMin[fid] = faction.kill_favor end
    end
    --Favor for killing this type of creature:
    if self.types and faction.kill_favor_types then
      for _,typ in pairs(self.types) do
        if faction.kill_favor_types[typ] then
          local newFavor = faction.kill_favor_types[typ]
          if (newFavor > 0 and favorMax[fid] < newFavor) then
            favorMax[fid] = newFavor
          elseif (newFavor < 0 and favorMin[fid] > newFavor) then
            favorMin[fid] = newFavor 
          end
        end --end if kill_favor_types if
      end --end self.types for
    end --end if self.types
    --Favor for killing a creature with these tags:
    if self.tags and faction.kill_favor_tags then
      for _,tag in pairs(self.tags) do
        if faction.kill_favor_tags[tag] then
          local newFavor = faction.kill_favor_tags[tag]
          if (newFavor > 0 and favorMax[fid] < newFavor) then
            favorMax[fid] = newFavor
          elseif (newFavor < 0 and favorMin[fid] > newFavor) then
            favorMin[fid] = newFavor 
          end
        end --end if kill_favor_tags if
      end --end self.types for
    end --end if self.types
    --Favor for killing creatures of this faction:
    if self.factions and faction.kill_favor_factions then
      for _,fac in pairs(self.factions) do
        if faction.kill_favor_factions[fac] then
          local newFavor = faction.kill_favor_factions[fac]
          if (newFavor > 0 and favorMax[fid] < newFavor) then
            favorMax[fid] = newFavor
          elseif (newFavor < 0 and favorMin[fid] > newFavor) then
            favorMin[fid] = newFavor 
          end
        end --end if faction.kill_favor_factions
      end --end self.factions for
    end --end if self.factions
    favor[fid] = favorMax[fid]+favorMin[fid]
  end --end faction for
  return favor
end


---Cause the creature to notice another creature
--@param creat Creature. The target to notice.
--@param skip_callbacks Whether to force notice and skip the notices() callbacks (optional)
--@param force Whether to force notice, but still run the callbacks (optional)
--@return Boolean. Whether the creature successfully noticed the target
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

---Checks if the creature has already noticed a creature. If not, see if they notice them now.
--@return Boolean. Whether the creature has noticed the target.
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

---Checks if a creature is able to notice another, and sets them as noticed if yes
--@param creat Creature. The creature to try and notice
--@return Boolean. Whether the creature is able to notice the target
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

---Decrease the "noticed" value for all creatures that this creature has noticed
--@param seenCreats Table. A table full of creatures currently seen, whose noticed value will not be decreased (optional)
function Creature:decrease_notice(seenCreats)
  for creat,amt in pairs(self.notices) do
    if not in_table(creat,seenCreats) then
      amt = amt -1
      if amt < 1 then self.notices[creat] = nil else self.notices[creat] = amt end
    end
  end
end

---Forget that you saw a creature
--@param creat Creature. The creature to forget
function Creature:forget(creat)
  if self.notices[creat] then self.notices[creat] = nil end
end

---Become hostile to another creature
--@param creat Creature. The creature to become hostile towards
--@param skip_callbacks. Boolean. Whether to skip hostility-related callbacks (optional)
--@param noSound Boolean. Whether to become hostile without playing a sound (optional)
--@return Boolean. Whether the creature became hostile to the target.
function Creature:become_hostile(creat, skip_callbacks,noSound,noText)
  if self == player or not creat or creat.baseType ~= "creature" then return false end
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

---Add a creature to your ignore list
--@param creat Creature. The creature to ignore
function Creature:ignore(creat)
  self.shitlist[creat] = nil
  self.ignoring[creat] = creat
end

---Remove a creature from your ignore list
--@param creat Creature. The creature to stop ignoring
function Creature:stop_ignoring(creat)
  self.ignoring[creat] = nil
end

---Get a list of all creatures you can see
--@return Table. An array of the creatures.
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

---Make a fear map for the given creature
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

---This function is run every tick and updates various things. You probably shouldn't call it yourself
--@param dt Number. The number of seconds since the last time update() was run. Most likely less than 1.
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
      if (self.zoomResult and self.zoomResult.use) then
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

---Placeholder. Doesn't do anything.
--@return False.
function Creature:refresh_image_name()
  return false
end

---Gets a creature's speed stat value, including bonuses
--@return Number. The stat value
function Creature:get_speed()
  return self.speed+self:get_bonus('speed')
end

---Gets a creature's perception stat value, including bonuses
--@param self Creature. The creature itself
--@return Number. The stat value
function Creature:get_perception()
  return self.perception+self:get_bonus('perception')
end

---Makes a creature fly through the air to a target
--@param target Table. A table containing at least an x and y index. Can be a creature, a feature, or just a table with nothing but x and y.
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

---Become a thrall to another creature. If you already have a master, unset your previous master.
--@param master Creature. The creature to become a thrall to
--@param skip_callbacks Boolean. Whether to skip thrall callbacks (optional)
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

---Become free from your master
--@param skip_callbacks Boolean. Whether to skip freedom callbacks (optional)
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

---Free all this creature's thralls
function Creature:free_thralls()
  for _,creat in pairs(self.thralls) do
    creat:become_free()
  end
end

---Grant XP to a creature
--@param xp Number. The amount of XP to give
function Creature:give_xp(xp)
  self.xp = self.xp+xp
  if self.xp >= self:get_level_up_cost() then self:level_up() end
end

---How much XP do you need to level up?
--@return Number. The XP required to level up
function Creature:get_level_up_cost()
  return self.level*1
end

---Level Up, granting skill points (for players), or randomly increasing skills (for NPCs)
--@param force Boolean. Whether or not to ignore XP costs
function Creature:level_up(force)
  local cost = self:get_level_up_cost()
  if not force then 
    if self.xp < cost then return false end
    self.xp = self.xp - cost
  end
  self.level = self.level + 1
  if self == player and not prefs.autoLevel then
    self.skillPoints = (self.skillPoints or 0) + gamesettings.skill_points_per_level
  else
    local hpInc = random(2,6)
    self.max_hp = self.max_hp + hpInc
    self.hp = self.hp + hpInc
    self.strength = self.strength + random(1,2)
    self.dodging = self.dodging + random(1,2)
    self.melee = self.melee + random(1,2)
    if self.magic and self.magic > 0 then self.magic = self.magic + random(1,2) end
    if self.ranged and self.ranged > 0 then self.ranged = self.ranged + random(1,2) end
    if self.stealth and self.stealth > 0 then self.stealth = self.stealth + 1 end
    if self.max_mp and self.max_mp > 0 then
      local mpInc = random(2,6)
      self.max_mp = self.max_mp + mpInc
      self.mp = self.mp + mpInc
    end
  end
  if self.extra_stats then
    for stat_id,stat in pairs(self.extra_stats) do
      if stat.increase_per_level then
        stat.max = stat.max+stat.increase_per_level
      end
    end
  end
  if self.class and playerClasses[self.class].learns_spells then
    for _,spell in ipairs(playerClasses[self.class].learns_spells) do
      if spell.level == self.level then
        self:learn_spell(spell.spell)
      end
    end
  end
  if possibleMonsters[self.id].learns_spells then
    for _,spell in ipairs(possibleMonsters[self.id].learns_spells) do
      if spell.level == self.level then
        self:learn_spell(spell.spell)
      end
    end
  end
end

---Find out how afraid the creature is
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

---Gets the creature's bravery stat value, including bonuses
--@return Number. The stat value
function Creature:get_bravery()
  return (self.bravery or 10000)+self:get_bonus('bravery')
end

---Gets the creature's aggression stat value, including bonuses
--@param self Creature. The creature itself
--@return Number. The stat value
function Creature:get_aggression()
  return (self.aggression or 100)+self:get_bonus('aggression')
end

---Gets the creature's animation_time stat value, including bonuses
--@return Number. The stat value
function Creature:get_animation_time()
  local perc_bonus = self:get_bonus('animation_time_percent') or 1
  return math.max(0,(self.animation_time or 0.5)*(perc_bonus ~= 0 and perc_bonus or 1)+self:get_bonus('animation_time'))
end

---Gets the creature's notice chance value, including bonuses
--@return Number. The stat value
function Creature:get_notice_chance()
  --Player's notice chance defaults to 100%, but can be changed by conditions or whatnot
  return (self == player and 100 or (self.notice_chance or 100))+self:get_bonus('notice_chance')
end

---Gets the creature's stealth stat value, including bonuses
--@return Number. The stat value
function Creature:get_stealth()
  if self.zoomTo then return -1000 end --if you're zooming somewhere, you're going to get noticed
  return (self.stealth or 0)+self:get_bonus('stealth')
end

---Gets the creature's damage value, including bonuses
--@return Number. The damage value
function Creature:get_damage()
  return self:get_stat('strength') + self:get_bonus('damage')
end

---Gets the creature's armor piercing value, including bonuses
--@return Number. The damage value
function Creature:get_armor_piercing()
  return (self.armor_piercing or 0) + self:get_bonus('armor_piercing')
end

---Gets the creature's critical_chance stat value, including bonuses
--@return Number. The stat value
function Creature:get_critical_chance()
  return (self.critical_chance or 1)+self:get_bonus('critical_chance')
end

---A generic function for getting a stat and its bonus
--@param stat Text. The stat to get
--@param noBonus Boolean. If true, don't add the bonus to the stat
--@return Number. The stat value
function Creature:get_stat(stat,noBonus)
  return (self[stat] or 0)+(not noBonus and self:get_bonus(stat) or 0)
end

---A generic function for getting an extra stat and its bonuses
--@param stat Text. The stat to get
--@param noBonus Boolean. If true, don't add the bonus to the stat
--@return Number. The stat value
function Creature:get_extra_stat(stat,noBonus)
  return (self.extra_stats[stat] and self.extra_stats[stat].value or 0)+(not noBonus and self:get_bonus(stat) or 0)
end

---Sets an extra stat to a value
--@param stat Text. The stat to set
--@param val Number. What to set the stat to
function Creature:set_extra_stat(stat,val)
  self.extra_stats[stat].value = val
end

---Adds/subtracts a value to an extra stat
--@param stat Text. The stat to set
--@param val Number. What to add to the stat
--@return Number. The stat value
function Creature:update_extra_stat(stat,val)
  local newVal = self:get_extra_stat(stat,true) + val
  local max = self.extra_stats[stat].max
  local min = self.extra_stats[stat].min
  if max and newVal > max then newVal = max end
  if min and newVal < min then newVal = min end
  self.extra_stats[stat].value = newVal
  return newVal
end

---Get all spells the creature has, including those granted by equipment
--@param noEquip Boolean. If true, ignore spells granted by equipment.
--@return Table. A list of the creature's spells
function Creature:get_spells(noEquip)
  local spells = (self.spells and copy_table(self.spells) or {})
  if noEquip then
    return spells
  end
  for _, equipslot in pairs(self.equipment) do
    for _, equip in ipairs(equipslot) do
      if equip.spells_granted then
       for _, spell in ipairs(equip.spells_granted) do
         if not in_table(spell,self.spells) then spells[#spells+1] = spell end
       end
      end --end bonuses if
    end --end equipment for
	end --end equipslot for
  return spells
end

---Checks if the creature possesses a certain spell
--@param spellName String. The name of the spell
--@param noEquip Boolean. If true, ignore spells granted by equipment
--@return Boolean. Whether the creature has the spell
function Creature:has_spell(spellName,noEquip)
  return in_table(spellName,self:get_spells(noEquip))
end

---Add a spell to a creature's spell list
--@param spellID Text. The ID of the spell to learn
function Creature:learn_spell(spellID)
  if not self:has_spell(spellID,true) then
    self.spells[#self.spells+1] = spellID
  end
end

---Determine if a creature can learn this spell or not
--@param spellID Text. The ID of the spell to check
--@return Boolean. Whether or not it can be learned
--@return Text. The reason it can't be learned (or nil if it can)
function Creature:can_learn_spell(spellID)
  local spell = possibleSpells[spellID]
  if spell.level_requirement and self.level < spell.level_requirement then
    return false,"You're not a high enough level to learn this ability."
  elseif spell.stat_requirements then
    for stat,requirement in pairs(spell.stat_requirements) do
      if self:get_stat(stat,true) < requirement and self:get_bonus_stat(stat,true) < requirement then
        return false,"Your " .. stat .. " stat is too low to learn this ability."
      end
    end
  elseif player.forbidden_spell_tags and count(player.forbidden_spell_tags) > 0 then
    for _,tag in ipairs(player.forbidden_spell_tags) do
      if spell:has_tag(tag) then
        return false,"You're unable to learn this type of ability."
      end
    end
  else
    local ret,text = spell:learn_requires(self)
    if ret == false then
      return false,text
    end
  end
  return true
end

---Get all ranged attacks the creature has, including those granted by equipment
--@return Table. A list of the creature's ranged attacks
function Creature:get_ranged_attacks()
  local ranged = {}
  if self.ranged_attack then ranged[#ranged+1] = {attack=self.ranged_attack,charges=player.ranged_charges} end
  if self.equipment.weapon then
    for _, equip in ipairs(self.equipment.weapon) do
      if equip.ranged_attack then
        ranged[#ranged+1] = {attack=equip.ranged_attack,item=equip,charges=equip.charges}
      end --end bonuses if
    end --end equipment for
  end
  return ranged
end

---Checks if the creature possesses a certain AI flag
--@param spellName String. The AI flag
--@return Boolean. Whether the creature has the AI flag
function Creature:has_ai_flag(flag)
  if self.ai_flags == nil then return false end
  for _,f in pairs(self.ai_flags) do
    if f == flag then return true end
  end --end for
  return false
end

---Checks if an creature has a descriptive tag.
--@param tag String. The tag to check for
--@return Boolean. Whether or not it has the tag.
function Creature:has_tag(tag)
  if self.tags and in_table(tag,self.tags) then
    return true
  end
  return false
end

---Get all possible recipes the creature can craft
--@return Table. A table with the IDs of all craftable recipes
function Creature:get_all_possible_recipes()
  local canCraft = {}
  for id,recipe in pairs(possibleRecipes) do
    if self:can_craft_recipe(id) then
      canCraft[#canCraft+1] = id
    end
  end
  return canCraft
end

---Check if it's possible to craft a recipe
--@param recipeID String. The ID of the recipe
--@return Boolean. Whether or not the recipe can be crafted
function Creature:can_craft_recipe(recipeID)
  local recipe = possibleRecipes[recipeID]
  if recipe.requires then
    if not recipe:requires(self) then return false end
  end
  if recipe.requires_class then
    if self.class ~= recipe.requires_class then return false end
  end
  if recipe.requires_spells then
    for _,spell in ipairs(recipe.requires_spells) do
      if not self:has_spell(spell) then return false end
    end
  end
  if recipe.specific_tools then
    for _,tool in ipairs(recipe.specific_tools) do
      if not self:has_item(tool) then return false end
    end
  end
  if recipe.tool_tags then
    for _,tag in ipairs(recipe.tool_tags) do
      local has = false
      for _,item in pairs(self.inventory) do
        if item:has_tag(tag) then
          has = true
          break
        end --end if has_tag
      end -- end inventory for
      if not has then return false end
    end --end tag for
  end
  for item,amt in pairs(recipe.ingredients) do
    local i = self:has_item(item)
    if not i or (i.amount or 1) < amt then return false end
  end
  return true --if no requirements have been false, we should be good to go
end

---Craft a recipe
--@param recipeID Text. The ID of the recipe to craft
--@return Boolean. If the recipe was successfully created
--@return Text. The result text of the recipe
function Creature:craft_recipe(recipeID)
  local recipe = possibleRecipes[recipeID]
  for item,amt in pairs(recipe.ingredients) do
    local i = self:has_item(item)
      self:delete_item(i,amt)
  end
  for item,amt in pairs(recipe.results) do
    local newItem = Item(item)
      newItem.amount = amt
      self:give_item(newItem)
  end
  local text = recipe.result_text or "You make stuff."
  output:out(text)
  update_stat('recipes_crafted',recipeID)
  return true,text
end
