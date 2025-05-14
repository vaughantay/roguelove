---@classmod Creature
Creature = Class{}

---Initiates a creature. Don't call this explicitly, it's called when you create a new creature with Creature('creatureID').
--@param creatureType String. The ID of the creature you want to create.
--@param level Number. The level to set the creature to (optional)
--@param tags Table. A table of tags to pass to the creature's new() function
--@param info Anything. Passed to the new() function
--@param noTweak Boolean. If true, don't randomize certain values
--@param ignorenewFunc Boolean. Whether to ignore the new() function
--@return Creature. The creature itself.
function Creature:init(creatureType,level,tags,info,noTweak,ignoreNewFunc) --TODO: apply creature.items to creature
  local data = possibleMonsters[creatureType]
  if not data then
    output:out("Error: Tried to create non-existent creature " .. creatureType)
    print("Error: Tried to create non-existent creature " .. creatureType)
    return false
  end
  --Copy over all info from the creature definition:
	for key, val in pairs(data) do
    local vt = type(val)
    if vt == "table" then
      self[key] = copy_table(data[key])
    elseif vt ~= "function" then
      self[key] = data[key]
    end
	end
  
  --Basic stuff:
  noTweak = (noTweak == nil and data.noTweak or noTweak)
  if self.gender == "either" then
    local genders={"male","female","other"}
    self.gender = get_random_element(genders)
  elseif not self.gender then
    self.gender = "neuter"
  end
  self.id = creatureType
  self.baseType = "creature"
  self.xp = 0
  self.level = self.level or 0
  self.inventory_space = self.inventory_space or gamesettings.default_inventory_space
  self.spell_slots = self.spell_slots or gamesettings.default_spell_slots
  self.money = (noTweak and (self.money or 0) or tweak(self.money or 0))
  self.speed = (noTweak and (self.speed or 100) or tweak(self.speed or 100))
  self.energy = self.speed
  
  --Holding slots for various things:
	self.conditions = {}
	self.spells = {}
  self.spells_known = {}
  self.active_spells = {}
	self.cooldowns = {}
  self.thralls = {}
  self.inventory = {}
  self.equipment = {}
  self.equipment_list = {}
  self.hotkeys = {}
  self.known_recipes = self.known_recipes or {}
  self.forbidden_spell_types = self.forbidden_spell_types or self.forbidden_content_types or {}
  self.forbidden_item_types = self.forbidden_item_types or self.forbidden_content_types or {}
  self.reputation = self.reputation or {}
  self.favor = self.favor or {}
  self.factions = self.factions or {}
  self.types = self.types or {}
  
  --Caches:
  self.checked = {}
  self.seen_tile_cache = {}
  self.sensed_creatures = {}
  self.bonus_cache = {}
  self.can_move_cache = {}
  
  --Level up stuff:
  self.stats_per_level = self.stats_per_level or {}
  self.stats_at_level = self.stats_at_level or {}
  self.stats_per_x_levels = self.stats_per_x_levels or {}
  self.skills_per_level = self.skills_per_level or {}
  self.skills_at_level = self.skills_at_level or {}
  self.skills_per_x_levels = self.skills_per_x_levels or {}
  
  --Stats and skills:
  self.max_hp = (noTweak and self.max_hp or tweak(self.max_hp or 0))
  self.hp = self.max_hp
  self.max_mp = (noTweak and self.max_mp or tweak(self.max_mp or 0))
  self.mp = self.max_mp
  if gamesettings.default_stats then
    for _,stat in ipairs(gamesettings.default_stats) do
      if not self[stat] then
        self[stat] = 0
      elseif not noTweak then
        self[stat] = tweak(self[stat])
      end
    end
  end
  self.extra_stats = self.extra_stats or {}
  self.skills = {}
  if gamesettings.default_skills then
    for _,skill in ipairs(gamesettings.default_skills) do
      self.skills[skill] = 0
    end
  end
  if data.skills then
    for skill,level in pairs(data.skills) do
      if level == false then
        self.skills[skill] = false
      else
        self:upgrade_skill(skill,level,true)
      end
    end
  end

  --Add equipment, spells, and ranged attacks:
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
  if data.spells then
    for _,spellID in ipairs(data.spells) do
      self:learn_spell(spellID,true)
    end
  end
  if (self.ranged_attack) then
    local ranged = rangedAttacks[self.ranged_attack]
    if ranged and ranged.max_charges then
      self.ranged_charges = ranged.max_charges
    end
  end --end ranged attack if
  
  --AI stats:
  self.fear = 0
  self.alert = 0 -- used by NPCs only, alertness countdown
  self.target=nil
  self.notices = {}
  self.shitlist = {}
  self.ignoring = {}
  self.lastSawPlayer = {x=nil,y=nil}
  self.aggression = self.aggression or 100 -- used by NPCs only, chance they'll be hostile when seeing player
  self.memory = self.memory or 10 --turns they remember seeing an enemy
  
  --Run new() function
  if not ignoreNewFunc and (possibleMonsters[creatureType].new ~= nil) then
    local status,r = pcall(possibleMonsters[creatureType].new,self,tags,info)
    if status == false then
      output:out("Error in creature " .. self.id .. " new code: " .. r)
      print("Error in creature " .. self.id .. " new code: " .. r)
    end
	end
  
  --Generate Name:
  if possibleMonsters[self.id].nameGen then
    local status,r = pcall(possibleMonsters[self.id].nameGen,self)
    if status == false then
      output:out("Error in creature " .. self.id.. " nameGen code: " .. r)
      print("Error in creature " .. self.id .. " nameGen code: " .. r)
    else
      self.properName = r
    end
  elseif self.nameType then
    self.properName = namegen:generate_name(self.nameType,self)
  end
  
  --Inventory:
  if not noItems then
    self:generate_inventory(nil,tags) --generate inventory based on the creature definition's pre-set inventory chances
    --Generate inventory based on the creatures' creature types and factions:
    if self.types then
      for _,ctype in ipairs(self.types) do
        if creatureTypes[ctype] then self:generate_inventory(creatureTypes[ctype],tags) end
      end
    end
    if self.factions then
      for _,fac in ipairs(self.factions) do
        self:generate_inventory(currWorld.factions[fac],tags)
      end
    end
  end
  
  --Spells
  if self.learns_random_spells then
    self:learn_random_spells()
  end
  
  --Level up if necessary:
  if level and level > self.level then
    if self.max_level and level > self.max_level then
      level = self.max_level
    end
    for i=self.level+1,level,1 do
      self:level_up(true)
    end
	end
  self.hp = self:get_max_hp()
  self.mp = self:get_max_mp()
  
  --Display stuff:
  self.color = (self.noTweakColor and self.color or {r=tweak(self.color.r),g=tweak(self.color.g),b=tweak(self.color.b),a=self.color.a})
  self.color.a = self.color.a or 255
  if self.image_varieties and not self.image_name then
    self.image_variety = random(1,self.image_varieties)
    self.image_name = (self.image_base or self.id) .. self.image_variety
  end
  self.xMod,self.yMod = 0,0
  
  --Set animation if not already set:
  if not self.animated or not self.spritesheet or not self.image_max then
    local img = images[(self.imageType or 'creature')  .. (self.image_name or self.id)]
    if img then
      local tileSize = output:get_tile_size(true)
      local frames = img:getWidth()/tileSize
      if frames > 1 then
        self.animated=true
        self.spritesheet=true
        self.image_max = math.ceil(frames)
        self.image_frame=1
      end
    end
  end
  if self.animated then
    self.animation_time = (self.animation_time and tweak(self.animation_time) or 0.5)
    if not self.image_frame then
      self.image_frame=1
    end
  end
  
	return self
end

---Generate items for a creature's inventory. Usually called when the creature first spawns
--@param source Table. The source of potential item lists. Defaults to the creature itself, and will frequently be either a creature type or a faction, but can be any table containing a possible_inventory or possible_death_items table. (optional)
function Creature:generate_inventory(source,tags)
  tags = self.passedTags or tags or {}
  source = source or self
  --Add inventory items:
  if source.possible_inventory then
    for _,def in ipairs(source.possible_inventory) do
      if not def.chance or random(1,100) <= def.chance then
        local amt = def.amount or random((def.min_amt or 1),(def.max_amt or 1))
        if def.item_group then
          local items = mapgen:generate_items_from_item_group(def.item_group,amt,{passedTags=def.passedTags or tags})
          for _,it in ipairs(items) do
            if it.requires_identification and not def.unidentified then
              it.identified=true
            end
            if def.drop_chance then
              it.drop_chance = def.drop_chance
            end
            self:give_item(it,true)
            if it.equippable then
              self:equip(it)
            end
          end
        elseif def.item then
          for i=1,amt,1 do
            if def.item then
              local it = Item(def.item,tags)
              if it.requires_identification and not def.unidentified then
                it.identified=true
              end
              if def.drop_chance then
                it.drop_chance = def.drop_chance
              end
              self:give_item(it,true)
              if it.equippable then
                self:equip(it)
              end
            end
          end
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
        if def.item_group then
          local items = mapgen:generate_items_from_item_group(def.item_group,amt,{passedTags=def.passedTags or tags})
          for _,it in ipairs(items) do
            self.death_items[#self.death_items+1] = item
            if def.drop_chance then
              it.drop_chance = def.drop_chance
            end
          end
        elseif def.item then
          for i=1,amt,1 do
            local item = Item(def.item,tags)
            self.death_items[#self.death_items+1] = item
            if def.drop_chance then
              item.drop_chance = def.drop_chance
            end
          end
        end
      end --end chance
    end --end loopthrough possible_inventory
  end --end if possible inventory
  
  --Delete the vistigial item lists:
  if source == self then
    self.possible_inventory = nil
    self.possible_death_items = nil
  end
end

---Applies a class definition to a creature, granting it that class's starting reputation, spells, factions and items
--@param classID String. The ID of the class to apply
function Creature:apply_class(classID)
  local class = playerClasses[classID]
  self.class = classID
  self.name = self.name .. " " .. class.name
  if class.reputation then
    for faction,reputation in pairs(class.reputation) do
      self.reputation[faction] = (self.reputation[faction] or 0) + reputation
    end
  end --end reputation if
  if class.factions then
    for _,faction in ipairs(class.factions) do
      if not self:is_faction_member(faction) then
        currWorld.factions[faction]:join(self)
      end
    end --end factions for
  end --end factions if
  if class.recipes then
    for _,recipe in ipairs(class.recipes) do
      self:learn_recipe(recipe)
    end
  end --end if recipes
  if class.recipe_tags then
    for id,recipe in pairs(possibleRecipes) do
      if recipe.tags then
        for _,tag in ipairs(class.recipe_tags) do
          if in_table(tag,recipe.tags) and not (recipe.requires_class or recipe.requires_class == classID) then
            self:learn_recipe(id)
          end --end in_table for
        end --end tag for
      end --end if recipe tags
    end --end possibleRecipes for
  end --end recipe tags if
  if class.items then
    for _,item in ipairs(class.items) do
      local itemID = item.item
      local count = item.amount or 1
      for i=1,count,1 do
        local it = Item(itemID,item.passedTags,item.passed_info)
        if it.requires_identification and not item.unidentified then
          it.identified=true
        end
        if item.enchantment then
          it:apply_enchantment(item.enchantment,item.enchantment_turns or -1)
        end
        self:give_item(it,true)
      end
    end
  end --end if items
  if class.equipment then
    for _,item in ipairs(class.equipment) do
      local itemID = item.item
      local it = Item(itemID,item.passedTags,item.passed_info)
      if it.requires_identification and not item.unidentified then
        it.identified=true
      end
      if item.enchantment then
        it:apply_enchantment(item.enchantment,item.enchantment_turns or -1)
      end
      self:give_item(it,true)
      self:equip(it)
    end
  end--end if equipment
  --Add skills and stats:
  if class.skills then
    for skill,mod in pairs(class.skills) do
      if mod == false then
        self.skills[skill] = false
      else
        self:upgrade_skill(skill,mod,true)
      end
    end
  end
  if class.stat_modifiers then
    for stat,mod in pairs(class.stat_modifiers) do
      self[stat] = math.max((self[stat] or 0) + mod,0)
    end
  end --end if stat_modifiers
  self.hp = self:get_max_hp()
  self.mp = self:get_max_mp()
  if class.stats_per_level then
    self.stats_per_level = (self.stats_per_level or {})
    for stat,mod in pairs(class.stats_per_level) do
      self.stats_per_level[stat] = (self.stats_per_level[stat] or 0) + mod
    end
  end --end if stats_per_level
  if class.stats_at_level then
    self.stats_at_level = (self.stats_at_level or {})
    for level,stats in pairs(class.stats_at_level) do
      self.stats_at_level[level] = (self.stats_at_level[level] or {})
      for stat,amt in pairs(stats) do
        self.stats_at_level[level][stat] = (self.stats_at_level[level][stat] or 0) + amt
      end
    end
  end --end if stats_at_level
  if class.stats_per_x_levels then
    self.stats_per_x_levels = (self.stats_per_x_levels or {})
    for level,stats in pairs(class.stats_per_x_levels) do
      self.stats_per_x_levels[level] = (self.stats_per_x_levels[level] or {})
      for stat,amt in pairs(stats) do
        self.stats_per_x_levels[level][stat] = (self.stats_per_x_levels[level][stat] or 0) + amt
      end
    end
  end --end if stats_at_level
  if class.skills_per_level then
    self.skills_per_level = (self.skills_per_level or {})
    for stat,mod in pairs(class.skills_per_level) do
      self.skills_per_level[stat] = (self.skills_per_level[stat] or 0) + mod
    end
  end --end if skills_per_level
  if class.skills_at_level then
    self.skills_at_level = (self.skills_at_level or {})
    for level,skills in pairs(class.skills_at_level) do
      self.skills_at_level[level] = (self.skills_at_level[level] or {})
      for stat,amt in pairs(skills) do
        self.skills_at_level[level][stat] = (self.skills_at_level[level][stat] or 0) + amt
      end
    end
  end --end if skills_at_level
  if class.skills_per_x_levels then
    self.skills_per_x_levels = (self.skills_per_x_levels or {})
    for level,skills in pairs(class.skills_per_x_levels) do
      self.skills_per_x_levels[level] = (self.skills_per_x_levels[level] or {})
      for stat,amt in pairs(skills) do
        self.skills_per_x_levels[level][stat] = (self.skills_per_x_levels[level][stat] or 0) + amt
      end
    end
  end --end if skills_at_level
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
  if class.spells then
    for _,spell in ipairs(class.spells) do
      self:learn_spell(spell)
    end
  end --end if spells
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

---Get the max HP of a creature *MAY WANT TO CHANGE FOR YOUR OWN GAME*
--@return Number. The max HP
function Creature:get_max_hp()
  local mhp = self.max_hp or 0
  mhp = mhp + round(mhp*(self:get_bonus('max_hp_percent')/100)) + self:get_bonus('max_hp')
	return mhp
end

---Get the max magic points of a creature
--@return Number. The max MP
function Creature:get_max_mp()
  if not gamesettings.mp then return 0 end
  local mmp = self.max_mp or 0
  mmp = mmp + round(mmp*(self:get_bonus('max_mp_percent')/100)) + self:get_bonus('max_mp')
	return mmp
end

---Change the HP of a creature
--@param amt Number. Can be positive or negative.
--@param damage_type String. The ID of a damage type
function Creature:updateHP(amt,damage_type)
  local alreadyDead = false
  if self.hp < 1 then alreadyDead = true end
	self.hp = self.hp + amt
	if (self.hp > self:get_max_hp()) then
		self.hp = self:get_max_hp()
	end
  if not alreadyDead then
    local p = Effect('dmgpopup',self.x,self.y)
    if (amt > 0) then
      p.color = {r=0,g=255,b=0,a=255}
      currMap:add_effect(Effect('animation',{image_name='floatingpluses',image_max=5,target=self,color={r=0,g=255,b=0,a=255},use_color_with_tiles=true}),self.x,self.y)
    else
      if self.hp > 0 then
        local oldColor = self.temporaryColor
        local clearFunc = function() self.temporaryColor = nil end
        self.temporaryColor={r=255,g=0,b=0}
          local r,g,b = (oldColor and oldColor.r or self.color.r or 255), (oldColor and oldColor.g or self.color.g or 255), (oldColor and oldColor.b or self.color.b or 255)
          tween(.25,self.temporaryColor,{r=r,g=b,b=b},'linear',(oldColor and nil or clearFunc))
      end
    end --make it green if it's healing
    p.symbol = (amt > 0 and "+" or "") .. math.abs(amt)
    currMap:add_effect(p,self.x,self.y)
    if damage_type then
      local dtInfo = damage_types[damage_type] or {}
      if images['damage_type' .. (dtInfo.image_name or damage_type)] then
        local tileMod = round(fonts.mapFontWithImages:getWidth(p.symbol)/2)
        p.xMod = -tileMod
        local popup2 = Effect('dmgpopup')
        popup2.image_name = dtInfo.image_name or damage_type
        popup2.imageType = "damage_type"
        popup2.xMod = tileMod
        popup2.speed = p.speed
        if dtInfo.color then
          popup2.color = {r=dtInfo.color.r,g=dtInfo.color.g,b=dtInfo.color.b,a=150}
        else
          popup2.color = {r=255,g=255,b=255,a=150}
        end
        p.paired = popup2
        popup2.paired = p
        currMap:add_effect(popup2,self.x,self.y)
      end
    end
  end
end

---Damage a creature
--@param amt Number. The damage to deal.
--@param attacker Entity. The source of the damage.
--@param damage_type String. The damage type of the attack. (optional)
--@param armor_piercing True/False, or Number. If set to true, it ignores all armor. If set to a number, ignores that much armor. (optional)
--@param noSound Boolean. If set to true, no damage type sound will be played. (optional)
--@param item Item. The weapon used to do the damage. (optional)
--@param ignoreWeakness Boolean. If true, don't apply weakness
--@return Number. The final damage done.
function Creature:damage(amt,attacker,damage_type,armor_piercing,noSound,item,ignoreWeakness)
  amt = math.ceil(amt) --just in case! to prevent fractional damage
  damage_type = damage_type or gamesettings.default_damage_type
  local dtInfo = damage_types[damage_type] or {}
  
  amt = self:calculate_damage_received(amt,damage_type,armor_piercing)

  if (amt == 0) then
    local popup = Effect('dmgpopup')
    popup.image_name = "damage_blocked"
    popup.symbol="x"
    if dtInfo.color then
      popup.color = {r=dtInfo.color.r,g=dtInfo.color.g,b=dtInfo.color.b,a=150}
    else
      popup.color = {r=255,g=255,b=255,a=150}
    end
    currMap:add_effect(popup,self.x,self.y)
    if images['damage_type' .. (dtInfo.image_name or damage_type)] then
      local tileMod = round(output:get_tile_size()/2)
      popup.xMod = -tileMod
      local popup2 = Effect('dmgpopup')
      popup2.image_name = dtInfo.image_name or damage_type
      popup2.imageType = "damage_type"
      popup2.xMod = tileMod
      popup2.color = popup.color
      popup2.speed = popup.speed
      popup.paired = popup2
      popup2.paired = popup
      currMap:add_effect(popup2,self.x,self.y)
    end
    return 0
  elseif amt < 0 then
    self:updateHP(-amt,damage_type)
    return 0
  end
  local bool,ret = self:callbacks('damaged',attacker,amt,damage_type)
	if (bool ~= false) then
    if #ret > 0 then --handle possible returned damage values
      local count = 0
      local dmg = 0
      for _,val in pairs(ret) do --add up all returned damage values
        if type(val) == "number" then
          count = count + 1
          dmg = dmg + val
        end
      end
      if count > 0 then amt = math.ceil(dmg/count) end --final damage is average of all returned damage values
    end
    if calc_distance(self.x,self.y,player.x,player.y) > player.perception*2 then
      amt = math.ceil(amt/10)
    elseif not player:can_see_tile(self.x,self.y) and (not attacker or not player:can_see_tile(attacker.x,attacker.y)) then
      amt = math.ceil(amt/4)
    end --if you're far away from the player
    if amt > 0 and damage_type and damage_types[damage_type] and damage_types[damage_type].damages then
      local ret = damage_types[damage_type].damages(self,attacker,amt)
      if type(ret) == "number" then
        amt = ret
      elseif ret == false then
        return 0
      end
      if not noSound and player:can_see_tile(self.x,self.y) then
        output:sound(damage_type .. 'damage')
      end
    end
    if amt <= 0 then
      return 0
    end
		self:updateHP(-amt,damage_type)
    self.fear = self.fear + math.ceil(100*(amt/self:get_max_hp())) --increase fear by % of MHP you just got damaged by
    self.alert = self.memory
    if attacker then
      if attacker.baseType == "creature" then
        attacker:callbacks('damages',self,amt,damage_type)
        if attacker.master then
          attacker.master:callbacks('ally_damages',self,attacker,amt,damage_type)
        end
        if self:does_notice(attacker) == false then 
          if attacker == player then achievements:disqualify('hostile_only') end
          self:notice(attacker,false,true)
        end
        currMap:register_incident('damages',attacker,self,{damage=amt})
      end
      if self ~= player then --ignore this stuff for player because this is AI enemy stuff
        --Add the guy who attacked you to your list of enemies, if they're not already in an enemy faction
        --First, if it's a spell, realize the caster of the spell is the attacker:
        if (attacker.source and attacker.source.baseType == "creature") then attacker = attacker.source
        elseif (attacker.creator and attacker.creator.baseType == "creature") then attacker = attacker.creator end
        local hostile = false
        if attacker.baseType == "creature" and not (self.shitlist[attacker] or self == attacker or (self.master == attacker and (self.summoned or self:has_condition('summoned') or self:is_type('mindless') or self:has_condition('enthralled')))) then 
          hostile = self:become_hostile(attacker,true)
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
    if self == player and self.hp > 0 then
      output:shake(math.max(math.min((amt/self.hp)*25,25),2),.5)
    end
    for _,item in pairs(self.equipment_list) do
      item:decrease_all_enchantments('damaged')
      if damage_type then
        item:decrease_all_enchantments('damaged_' .. damage_type)
      end
    end
    self:decrease_all_conditions('damaged')
    if damage_type then
      self:decrease_all_conditions('damaged_' .. damage_type)
    end
    --Cancel active spells if applicable:
    for id,data in pairs(self.active_spells) do
      if data.spell.deactivate_on_damage_chance and random(1,100) <= data.spell.deactivate_on_damage_chance then
        local t = data.target
        local mp = data.ignoreCost
        local cd = data.ignoreCooldowns
        data.spell:finish(t, self, cd, mp)
      end
    end
		return amt
	else
		return 0
	end
end

---Calculates the damage amount a creature would receive based on damage types, weaknesses, armor, etc
--@param amt Number. The damage to deal.
--@param damage_type String. The damage type of the attack. (optional)
--@param armor_piercing True/False, or Number. If set to true, it ignores all armor. If set to a number, ignores that much armor. (optional)
--@param ignoreWeakness Boolean. If true, don't apply weakness (optional)
--@return Number. The final damage done.
function Creature:calculate_damage_received(amt,damage_type,armor_piercing,ignoreWeakness)
  local bonuses = 0
  damage_type = damage_type or gamesettings.default_damage_type
  --Apply damage weaknesses, resistances, and armor
  if damage_type then
    if self:is_healed_by_damage_type(damage_type) then
      return -amt
    end
    if self:is_immune_to_damage_type(damage_type) then
      return 0
    end
    if not ignoreWeakness then
      bonuses = bonuses + self:get_weakness(amt,damage_type)
    end
    bonuses = bonuses - self:get_resistance(amt,damage_type)
    bonuses = bonuses + self:get_bonus('exta_' .. damage_type .. '_damage_taken')
  end
  if not ignoreWeakness then
    bonuses = bonuses + self:get_weakness(amt,'all')
  end
  bonuses = bonuses - self:get_resistance(amt,'all')
  bonuses = bonuses + self:get_bonus('exta_damage_taken')
  amt = amt + bonuses
  
  --Apply armor
  if armor_piercing ~= true and (not damage_type or not damage_types[damage_type] or not damage_types[damage_type].armor_piercing) then
    local totalArmor = self:get_armor(damage_type)
    
    if type(armor_piercing) == "number" then
      totalArmor = totalArmor - armor_piercing
    end
    amt = amt - totalArmor
  end
  return amt
end

---Checks if a creature qualifies for a condition
--@param name String. The ID of the condition.
--@return Boolean. Whether or not the creature qualifies
function Creature:qualifies_for_condition(name)
  if not conditions[name] then return false end
  
  if conditions[name].types then
    for _,contype in ipairs(conditions[name].types) do
      if self:is_immune_to_condition_type(contype) then
        return false
      end
    end
  end
  if conditions[name].required_creature_types then
    local meets_reqs = false
    for _,ctype in ipairs(conditions[name].required_creature_types) do
      if self:is_type(ctype) then
        meets_reqs = true
        break
      end
    end
    if not meets_reqs then
      return false
    end
  end
  return true
end

---Give a condition to a creature
--@param name String. The ID of the condition.
--@param turns Number. How many turns the condition should last.
--@param applier Entity. Who applied the condition. (optional)
--@param args Anything. Arguments to pass to the condition's apply() code (optional)
--@param force Boolean. Whether to force-apply the condition. (optional)
--@param stack Boolean. If true, add the new turns to the current turns (if applicable). If false, sets the turns to turns passed
--@param silent Boolean. If true, don't pop up to show the condition was given
--@return Boolean. Whether the condition was applied
function Creature:give_condition(name,turns,applier,args,force,stack,silent)
	if not conditions[name] then return false end
  local conditionInfo = conditions[name]
  if self == player and conditionInfo.player_turn_modifier then
    turns = math.ceil(turns * conditions[name].player_turn_modifier)
  end
  
  --Check condition type immunities first:
  local qualifies = force or self:qualifies_for_condition(name)
  if qualifies == false then return false end

  if force or conditionInfo:can_apply(self,applier,turns,args) ~= false then
    local has = self.conditions[name]
    local result = conditionInfo:apply(self,applier,turns,args)
    if force or result ~= false then
      if type(result) == "number" then
        turns = result
      end
      local addition = 0
      if turns ~= -1 and (stack or conditions[name].turns_stack == true) then
        addition = (self.conditions[name] and self.conditions[name].turns) or 0
      end
      self.conditions[name] = {turns=turns+addition,applier=applier}
      if args and type(args) == "table" then
        for arg,val in pairs(args) do
          self.conditions[name][arg] = val
        end
      end
      if type(result) == "table" then
        for arg,val in pairs(result) do
          self.conditions[name][arg] = val
        end
      end
      if silent then
        self.conditions[name].silent=true
      end
      if applier and applier.baseType == "creature" then
        self.lastAttacker = applier
      end
      --Add condition popup:
      if (not has or stack) and not conditionInfo.hidden and not conditionInfo.silent and not silent and self.x and self.y then
        local popup1 = Effect('dmgpopup')
        popup1.symbol = "+"
        popup1.color = {r=255,g=255,b=255,a=150}
        local tileMod = round(fonts.mapFontWithImages:getWidth(popup1.symbol)/2)
        popup1.xMod = -tileMod
        local popup2 = Effect('dmgpopup')
        popup2.image_name = conditionInfo.image_name or name
        popup2.imageType = "condition"
        popup2.xMod = tileMod
        popup2.speed = popup1.speed
        if (conditionInfo.use_color_with_tiles ~= false or gamesettings.always_use_color_with_tiles) and conditionInfo.color then
          popup2.color = {r=conditionInfo.color.r,g=conditionInfo.color.g,b=conditionInfo.color.b,a=150}
        else
          popup2.color = {r=255,g=255,b=255,a=150}
        end
        popup1.paired = popup2
        popup2.paired = popup1
        currMap:add_effect(popup1,self.x,self.y)
        currMap:add_effect(popup2,self.x,self.y)
      end
      return true
    end
  end
	return false
end

---Cure a condition.
--@param condition String. The ID of the condition to cure
--@param silent Boolean. If true, don't show a popup
function Creature:cure_condition(condition,silent)
  if self.conditions[condition] then
    silent = silent or self.conditions[condition].silent
    self.conditions[condition] = nil
    conditions[condition]:cure(self)
    --Add condition popup:
    if not conditions[condition].hidden and not conditions[condition].silent and not silent and self.x and self.y then
      local conditionInfo = conditions[condition]
      local popup1 = Effect('dmgpopup')
      popup1.symbol = "-"
      popup1.color = {r=255,g=255,b=255,a=150}
      local tileMod = round(fonts.mapFontWithImages:getWidth(popup1.symbol)/2)
      popup1.xMod = -tileMod
      local popup2 = Effect('dmgpopup')
      popup2.image_name = conditionInfo.image_name or condition
      popup2.imageType = "condition"
      popup2.xMod = tileMod
      popup2.speed = popup1.speed
      if (conditionInfo.use_color_with_tiles ~= false or gamesettings.always_use_color_with_tiles) and conditionInfo.color then
        popup2.color = {r=conditionInfo.color.r,g=conditionInfo.color.g,b=conditionInfo.color.b,a=150}
      else
        popup2.color = {r=255,g=255,b=255,a=150}
      end
      popup1.paired = popup2
      popup2.paired = popup1
      currMap:add_effect(popup1,self.x,self.y)
      currMap:add_effect(popup2,self.x,self.y)
    end
  end
end

---Check if a creature has a condition
--@param condition String. The ID of the condition to check
--@return Number or False. The number of turns left in the condition if it has it, or false if it doesn't
function Creature:has_condition(condition)
  if self.conditions[condition] then
    return self.conditions[condition].turns
  else
    return false
  end
end

---Decrease all conditions of a given type
--@param removal_type Text. The removal type of the condition (defaults to turns)
function Creature:decrease_all_conditions(removal_type)
  removal_type = removal_type or 'turn'
  
  for condition, info in pairs(self.conditions) do
    local turns = info.turns
    local con = conditions[condition]
    if con and con.removal_type == removal_type and turns ~= -1 then
      self.conditions[condition].turns = self.conditions[condition].turns - 1
      if self.conditions[condition].turns <= 0 or con.cure_when_decreasing then
        self:cure_condition(condition)
      end --end if condition <= 0
    end --end condition for
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
        print("Error in creature " .. self.name .. " callback \"" .. callback_type .. "\": " .. r)
      end
		if (r == false) then return false end
    if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
  end
	for condition, _ in pairs(self.conditions) do
		if type(conditions[condition][callback_type]) == "function" then
			local status,r = pcall(conditions[condition][callback_type],conditions[condition],self,unpack({...}))
      if status == false then
        output:out("Error in condition " .. conditions[condition].name .. " callback \"" .. callback_type .. "\": " .. r)
        print("Error in condition " .. conditions[condition].name .. " callback \"" .. callback_type .. "\": " .. r)
      end
			if (r == false) then return false end
      if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
		end
	end
	for id, spell in pairs(self:get_spells()) do
    local spellID = spell.id
		if possibleSpells[spellID] then
      if type(possibleSpells[spellID][callback_type]) == "function" then
        local status,r = pcall(possibleSpells[spellID][callback_type],spell,self,unpack({...}))
        if status == false then
          output:out("Error in spell " .. spell.name .. " callback \"" .. callback_type .. "\": " .. r)
          print("Error in spell " .. spell.name .. " callback \"" .. callback_type .. "\": " .. r)
        end
        if (r == false) then return false end
        if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
      end
    else
      output:out("Error attempting to callback spell " .. spellID .. ", which does not exist.")
      print("Error attempting to callback spell " .. spellID .. ", which does not exist.")
    end
	end
  for skillID,rank in pairs(self.skills) do
    local skill = possibleSkills[skillID]
    if skill and type(skill[callback_type]) == "function" then
      local status,r = pcall(skill[callback_type],skill,self,unpack({...}))
      if status == false then
        output:out("Error in skill " .. skill.name .. " callback \"" .. callback_type .. "\": " .. r)
        print("Error in skill " .. skill.name .. " callback \"" .. callback_type .. "\": " .. r)
      end
			if (r == false) then return false end
      if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
    end
  end
  for _,ctype in ipairs(self:get_types()) do
    if creatureTypes[ctype] and type(creatureTypes[ctype][callback_type]) == "function" then
      local status,r = pcall(creatureTypes[ctype][callback_type],creatureTypes[ctype],self,unpack({...}))
      if status == false then
        output:out("Error in creature type " .. (creatureTypes[ctype].name or ctype) .. " callback \"" .. callback_type .. "\": " .. r)
        print("Error in creature type " .. (creatureTypes[ctype].name or ctype) .. " callback \"" .. callback_type .. "\": " .. r)
      end
			if (r == false) then return false end
      if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
    end
  end
  for _, equip in pairs(self.equipment_list) do
    local r = equip:callbacks(callback_type,self,...)
    if r == false then return false end
	end
  for missionID, missionStatus in pairs(currGame.missionStatus) do
    local mission = possibleMissions[missionID]
    if mission and type(mission[callback_type]) == "function" then
      local status,r = pcall(mission[callback_type],mission,self,unpack({...}))
      if status == false then
        output:out("Error in mission " .. mission.name .. " callback \"" .. callback_type .. "\": " .. r)
        print("Error in mission " .. mission.name .. " callback \"" .. callback_type .. "\": " .. r)
      end
      if (r == false) then return false end
      if r ~= nil and type(r) ~= "boolean" then table.insert(ret,r) end
    end
  end
	return true,ret
end

---Get the name and description of a creature, including information like its health info, friendliness to the player, etc.
--@return String. The description of the creature.
--@param noInfo Boolean. If true, only show the description, not extra info.
function Creature:get_description(noInfo)
	local desc = self:get_name(true) .. "\n" .. self.description
  if not noInfo then
    desc = desc .. "\n" .. self:get_info()
  end
	
	return desc
end

---Gets the extended description of a creature
--@param noHealth Boolean. If true, don't display health text
function Creature:get_info(noHealth)
  local desc
  if not noHealth then
    desc = (desc and desc .. "\n" or "") .. self:get_health_text(true)
  end
  if self.master and self.master ~= player then
    desc = (desc and desc .. "\n" or "") .. ucfirst(self:get_pronoun('n')) .. " is under the command of " .. self.master:get_name(false,true) .. "."
  end
  if (self.isPlayer ~= true) then
    if (self.master == player) then
      desc = (desc and desc .. "\n" or "") .. ucfirst(self:get_pronoun('n')) .. " is under your command."
    elseif self.notices[player] and self.ignoring[player] then
      desc = (desc and desc .. "\n" or "") .. ucfirst(self:get_pronoun('n')) .. " is ignoring you."
    elseif self.notices[player] and not self.shitlist[player] then
      desc = (desc and desc .. "\n" or "") .. ucfirst(self:get_pronoun('n')) .. (self:is_friend(player) and " is friendly towards you." or " is aware of you but not hostile.")
    elseif (self.notices[player] and self.shitlist[player]) then
      desc = (desc and desc .. "\n" or "") .. ucfirst(self:get_pronoun('n')) .. " is hostile towards you."
    else
      desc = (desc and desc .. "\n" or "") .. ucfirst(self:get_pronoun('n')) .. " has not noticed you" .. ((self.shitlist[player] or self:is_enemy(player)) and ", but might be hostile towards you" or "") .. (self:is_friend(player) and ", but will be friendly towards you" or "") .. "."
    end
    if self:get_fear() > self:get_bravery() then
      desc = (desc and desc .. "\n" or "") .. ucfirst(self:get_pronoun('n')) .. " is afraid, and will try to run away."
    end
    if action == "targeting" and actionResult then
      local dist = calc_distance(player.x,player.y,self.x,self.y)
      if actionResult.range and dist > actionResult.range then
        desc = (desc and desc .. "\n" or "") .. "It is too far away to be targeted."
      elseif actionResult.minRange and dist < actionResult.minRange then
        desc = (desc and desc .. "\n" or "") .. "It is too close to be targeted."
      elseif actionResult.projectile and not player:can_shoot_tile(self.x,self.y) then
        desc = (desc and desc .. "\n" or "") .. "You can't hit it from here."
      elseif actionResult.calc_hit_chance then
        desc = (desc and desc .. "\n" or "") .. actionResult.name .. " hit chance: " .. actionResult:calc_hit_chance(player,self,actionItem) .. "%"
      end
    end
    if self.equipment then
      local equipment = self:get_all_equipped()
      if #equipment > 0 then
        desc = (desc and desc .. "\n" or "") .. "Equipment: "
        for i,item in ipairs(equipment) do
          desc = desc .. item:get_name(true) .. (i ~= #equipment and ", " or "")
        end
      end
    end --end self.equipment if
    --Debug stuff:
    if debugMode then
      desc = (desc and desc .. "\n" or "") .. "Fear: " .. self:get_fear() .. "/" .. self:get_bravery()
      if self.target then
        if self.target.baseType == "creature" then desc = (desc and desc .. "\n" or "") .. "Target: " .. self.target:get_name()
        else desc = (desc and desc .. "\n" or "") .. "Target: " .. self.target.x .. ", " .. self.target.y end
      end --end if self.target
      if self.inventory then
        desc = (desc and desc .. "\n" or "") .. "Inventory : "
        for _,item in ipairs(self.inventory) do
          desc = desc .. item:get_name(true) .. ", "
        end
      end
    end --end debugmode if
  end --end isPlayer
  return desc
end

---Get a description of a creature's health
--@param full Boolean. Whether to return a full sentence or just a short description (optional)
--@return String. The health text
function Creature:get_health_text(full)
	local health = self.hp/self:get_max_hp()
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
function Creature:get_bonus(bonusType)
  if not self.bonus_cache then self.bonus_cache = {} end
  if self.bonus_cache[bonusType] then
    return self.bonus_cache[bonusType]
  end
	local bonus = 0
  if self.bonuses and self.bonuses[bonusType] then
    bonus = bonus + self.bonuses[bonusType]
  end
	for id, info in pairs(self.conditions) do
		if conditions[id].bonuses or (info.bonuses and info.bonuses[bonusType]) then
			local b = (info.bonuses and info.bonuses[bonusType] or conditions[id].bonuses[bonusType])
			if (b ~= nil) then
        bonus = bonus + b
      end
		end
	end
  for _, spell in pairs(self:get_spells()) do
    local spellID = spell.id
		if spell.bonuses ~= nil and (not spell.bonuses_only_when_active or spell.active) then
			local b = spell.bonuses[bonusType]
			if (b ~= nil) then
        bonus = bonus + b
      end
		end
	end
  for _, equip in pairs(self.equipment_list) do
    if equip.bonuses ~= nil then
      local b = equip.bonuses[bonusType]
      if b ~= nil then
        bonus = bonus + b
      end
    end --end bonuses if
  end --end equipment for
  if not possibleSkills[bonusType] and not possibleSkills[string.sub(bonusType,1,-9)] then --in order to avoid infinite loops, skills cannot grant bonuses to other skills
    for skillID,skillVal in pairs(self.skills) do
      local skill = possibleSkills[skillID]
      if skill then
        local skillB = false
        local skillVal = self:get_skill(skillID)
        if skill.bonuses and skill.bonuses[bonusType] then
          bonus = bonus + skill.bonuses[bonusType]
          skillB = true
        end
        if skill.bonuses_per_level and skill.bonuses_per_level[bonusType] then
          bonus = bonus + skill.bonuses_per_level[bonusType] * skillVal
          skillB = true
        end
        if skill.bonuses_at_level then
          for i = skillVal,1,-1 do
            if skill.bonuses_at_level[i] and skill.bonuses_at_level[i][bonusType] then
              bonus = bonus + skill.bonuses_at_level[i][bonusType]
              skillB = true
              break
            end
          end
        end
        if skill.bonuses_per_x_levels then
          for lvl,bonuses in pairs(skill.bonuses_per_x_levels) do
            if bonuses[bonusType] and skillVal % lvl == 0 then
              bonus = bonus + bonuses[bonusType]
              skillB = true
            end
          end
        end --end bonuses_per_x_levels
      end --end skill if
    end --end skill for
  end --end bonus type is a skill if
  self.bonus_cache[bonusType] = bonus
	return bonus
end

---Returns the total bonus from a skill
--@param skillID String. The ID of the skill
--@param skillVal Number. The level of the skill (optional, defaults to current level)
--@return Table. A table of values in the form bonus=amt
function Creature:get_bonuses_from_skill(skillID,skillVal)
  local skill = possibleSkills[skillID]
  skillVal = skillVal or (self.skills[skillID] and self:get_skill(skillID) or 1)
  
  local bonuses = {}
  
  if skill.bonuses then
    for bonus,val in pairs(skill.bonuses) do
      bonuses[bonus] = val
    end
  end
  
  if skill.bonuses_per_level then
    for bonus,val in pairs(skill.bonuses_per_level) do
      bonuses[bonus] = (bonuses[bonus] or 0) + val*skillVal
    end
  end
  
  if skill.bonuses_at_level then
    for i = skillVal,1,-1 do
      if skill.bonuses_at_level[i] then
        for bonus,val in pairs(skill.bonuses_at_level[i]) do
          bonuses[bonus] = (bonuses[bonus] or 0) + val
        end
      end
    end
  end
  
  if skill.bonuses_per_x_levels then
    for lvl,lvlbonuses in pairs(skill.bonuses_per_x_levels) do
      if skillVal >= lvl then
        for bonus,val in pairs(lvlbonuses) do
          bonuses[bonus] = (bonuses[bonus] or 0) + val*math.floor(skillVal/lvl)
        end
      end
    end
  end
  return bonuses
end

---Check how much damage of a given damage type is reduced by a creature's resistances and bonuses
--@param damageType String. The damage type.
--@param noBonus Boolean. If true, don't add bonuses
--@param base_only Boolean. If true, don't look at creature types applied by conditions
--@return Number. The amount by which the damage is reduced
function Creature:get_resistance(damageType,noBonus,base_only)
  local resistance = (self.resistance and self.resistances[damageType] or 0)
  
  for _,ctype in ipairs(self:get_types(base_only)) do
    local typ = creatureTypes[ctype]
    if typ then
      if typ.resistances and typ.resistances[damageType] then
        resistance = math.max(resistance,typ.resistances[damageType])
      end --end if weaknesses
    end --end if type is defined
  end --end ctype for
  
  local bonus = (noBonus and 0 or self:get_bonus(damageType .. "_resistance"))
  return resistance+bonus
end --end get_resistance function

---Check how much damage of a given damage type is increased by a creature's weaknesses and bonuses
--@param damageType String. The damage type.
--@param noBonus Boolean. If true, don't add bonuses
--@param base_only Boolean. If true, don't look at creature types applied by conditions
--@return Number. The amount by which the damage is increased
function Creature:get_weakness(damageType,noBonus,base_only)
  local weakness = (self.weaknesses and self.weaknesses[damageType] or 0)
  
  for _,ctype in ipairs(self:get_types(base_only)) do
    local typ = creatureTypes[ctype]
    if typ then
      if typ.weaknesses and typ.weaknesses[damageType] then
        weakness = math.max(weakness,typ.weaknesses[damageType])
      end --end if weaknesses
    end --end if type is defined
  end --end ctype for
  
  local bonus = (noBonus and 0 or self:get_bonus(damageType .. "_weakness"))
  return weakness+bonus
end --end get_resistance function

---Check the total damage modifier (resistance - weakness) for a damage type. Capped to 75% reduction, or 100% increase
--@param damageType String. The damage type.
--@param noBonus Boolean. If true, don't add bonuses
--@param base_only Boolean. If true, don't look at creature types applied by conditions
--@return Number. The amount by which the damage is increased
function Creature:get_total_resistance(damageType,noBonus,base_only)
  if self:is_healed_by_damage_type(damageType) then
    return 10000
  end
  if self:is_immune_to_damage_type(damageType) then
    return 1000
  end
  local weakness = math.max(0,self:get_weakness(damageType,noBonus,base_only))
  local resistance = math.max(0,self:get_resistance(damageType,noBonus,base_only))
  
  local final = math.min(75,math.max(-100,resistance-weakness))
  return final
end --end get_total_resistance function

---Gets a list of all damage type weaknesses a creature has
--@param noBonus Boolean. If true, don't add bonuses
--@param base_only Boolean. If true, don't look at creature types applied by conditions
--@return Table. A table of damage types and the weakness value
function Creature:get_all_weaknesses(noBonus,base_only)
  local weaknesses = self.weaknesses or {}
  
  for _,ctype in ipairs(self:get_types(base_only)) do
    local typ = creatureTypes[ctype]
    if typ and typ.weaknesses then
      for dtype,amt in pairs(typ.weaknesses) do
        weaknesses[dtype] = math.max(amt,weaknesses[dtype] or 0)
      end
    end
  end
  if not noBonus then
    for dtype,_ in pairs(damage_types) do
      local bonus = self:get_bonus(dtype .. "_weakness")
      if bonus then
        weaknesses[dtype] = (weaknesses[dtype] or 0)+bonus
      end
      if weaknesses[dtype] == 0 then weaknesses[dtype] = nil end
    end
  end
  return weaknesses
end

---Gets a list of all damage type resistances a creature has
--@param noBonus Boolean. If true, don't add bonuses
--@param base_only Boolean. If true, don't look at creature types applied by conditions
--@return Table. A table of damage types and the resistance value
function Creature:get_all_resistances(noBonus,base_only)
  local resistances = self.resistances or {}
  
  for _,ctype in ipairs(self:get_types(base_only)) do
    local typ = creatureTypes[ctype]
    if typ and typ.resistances then
      for dtype,amt in pairs(typ.resistances) do
        resistances[dtype] = math.max(amt,resistances[dtype] or 0)
      end
    end
  end
  if not noBonus then
    for dtype,_ in pairs(damage_types) do
      local bonus = self:get_bonus(dtype .. "_resistance")
      if bonus then
        resistances[dtype] = (resistances[dtype] or 0)+bonus
      end
      if resistances[dtype] == 0 then resistances[dtype] = nil end
    end
  end
  return resistances
end

---Gets a list of all damage type weaknesses a creature has
--@param noBonus Boolean. If true, don't add bonuses
--@param base_only Boolean. If true, don't look at creature types applied by conditions
--@return Table. A table of damage types and the weakness value
function Creature:get_all_total_resistances(noBonus,base_only)
  local mods = {}
  
  for dtype,_ in pairs(damage_types) do
    mods[dtype] = self:get_total_resistance(dtype,noBonus,base_only)
  end
  return mods
end

---Checks whether a creature has blanket immunity to a damage type
--@param damageType String. The damage type.
--@return Boolean. Whether or not they have immunity to that damage type
function Creature:is_immune_to_damage_type(damageType)
  if self.damage_type_immunities and in_table(damageType,self.damage_type_immunities) then
    return true
  end
  for _,ctID in ipairs(self:get_types()) do
    local ctype = creatureTypes[ctID] 
    if ctype and ctype.damage_type_immunities and in_table(damageType,ctype.damage_type_immunities) then
      return true
    end
  end
  return false
end

---Checks whether a creature is healed by a damage type
--@param damageType String. The damage type.
--@return Boolean. Whether or not they are healed by that damage type
function Creature:is_healed_by_damage_type(damageType)
  if self.damage_type_healing and in_table(damageType,self.damage_type_healing) then
    return true
  end
  for _,ctID in ipairs(self:get_types()) do
    local ctype = creatureTypes[ctID] 
    if ctype and ctype.damage_type_healing and in_table(damageType,ctype.damage_type_healing) then
      return true
    end
  end
  return false
end

---Returns the armor value for a given damage type
--@param damage_type String. The damage type. If blank, look only at "all" armor value
--@param noBonus Boolean. If true, don't apply bonuses
--@param equipSlot String. If set, only look at equipment from this equipment slot. If false, don't apply equipment armor at all
--@param no_all Boolean. If set, don't add "all" armor value
--@return Number. The armor value
function Creature:get_armor(damage_type,noBonus,equipSlot,no_all)
  local totalArmor = 0
  --First, apply built in armor values:
  if damage_type then
    if damage_types[damage_type] and damage_types[damage_type].no_all then
      no_all = true
    end
  end
  if self.armor then
    if not no_all and type(self.armor) == "number" then
      totalArmor = totalArmor + self.armor
    else
      if damage_type and self.armor[damage_type] then
        totalArmor = totalArmor + self.armor[damage_type]
      elseif not no_all and self.armor.all then
        totalArmor = totalArmor + self.armor.all
      end
    end
  end
  
  --Next, apply armor values for creature types:
  if self.types then
    for _,ctype in ipairs(self.types) do
      local ctypeInfo = creatureTypes[ctype]
      if ctypeInfo and ctypeInfo.armor then
        if not no_all and type(ctypeInfo.armor) == "number" then
          totalArmor = totalArmor + ctypeInfo.armor
        else
          if damage_type and ctypeInfo.armor[damage_type] then
            totalArmor = totalArmor + ctypeInfo.armor[damage_type]
          elseif not no_all and ctypeInfo.armor.all then
            totalArmor = totalArmor + ctypeInfo.armor.all
          end
        end
      end
    end
  end
  
  --Next, apply armor values from equipment:
  if equipSlot ~= false then
    local equipment = (equipSlot and self:get_equipped_in_slot(equipSlot) or self:get_all_equipped())
    for _,eq in ipairs(equipment) do
      if eq.armor then
        if not no_all and type(eq.armor) == "number" then
          totalArmor = totalArmor + eq.armor
        else
          totalArmor = totalArmor + eq:get_armor(damage_type,noBonus,no_all)
        end
      end
      
    end
  end
  
  --Finally, apply bonuses:
  if not noBonus then
    local pre_boost = totalArmor
    if damage_type then
      totalArmor = totalArmor + round(pre_boost*(self:get_bonus(damage_type .. '_armor_percent')/100)) + self:get_bonus(damage_type .. '_armor')
    end
    if not no_all then
      totalArmor = totalArmor + round(pre_boost*(self:get_bonus('armor_percent')/100)) + self:get_bonus('armor')
      totalArmor = totalArmor + round(pre_boost*(self:get_bonus('all_armor_percent')/100)) + self:get_bonus('all_armor')
    end
    if totalArmor > 0 then --only apply armor boost enchantments if the armor type > 0
      totalArmor = totalArmor + round(pre_boost*(self:get_bonus('armor_modifier_percent')/100)) + self:get_bonus('armor_modifier')
    end
  end
  if totalArmor < 0 then totalArmor = 0 end
  return totalArmor
end

---Gets a list of all armor values a creature has
--@param noBonus Boolean. If true, don't add bonuses
--@param base_only Boolean. If true, don't look at creature types applied by conditions
--@return Table. A table of damage types and the weakness value
function Creature:get_all_armor(noBonus,equipSlot)
  local armor = {}
  
  for dtype,_ in pairs(damage_types) do
    local val = self:get_armor(dtype,noBonus,equipSlot)
    if val ~= 0 then
      armor[dtype] = val
    end
  end
  return armor
end

---Checks whether a creature has immunity to a condition type
--@param conditionType String. The condition type.
--@return Boolean. Whether or not they have immunity to that condition type
function Creature:is_immune_to_condition_type(conditionType)
  if self.condition_type_immunities and in_table(conditionType,self.condition_type_immunities) then
    return true
  end
  for _,ctID in ipairs(self:get_types()) do
    local ctype = creatureTypes[ctID]
    if ctype and ctype.condition_type_immunities and in_table(conditionType,ctype.condition_type_immunities) then
      return true
    end
  end
  for _,item in pairs(self.equipment_list) do
    local immunities = item:get_condition_type_immunities()
    if in_table(conditionType,immunities) then
      return true
    end
  end
  return false
end

---Check what hit conditions a creature can inflict
--@return Table. The list of hit conditions
function Creature:get_hit_conditions()
	return (self.hit_conditions or {})
end

---Attack another entity. If any weapons are equipped, this function will call their attack code instead.
--@param target Entity. The creature (or feature) they're attacking
--@param forceHit Boolean. Whether to force the attack instead of rolling for it.
--@param ignore_callbacks Boolean. Whether to ignore any of the callbacks involved with attacking
--@return Number or False. How much damage (if any) was done, false if attacking is impossible
function Creature:attack(target,forceHit,ignore_callbacks)
  if self.noMelee then return false end
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
  
  local weapons = self:get_melee_attacks()
  if #weapons > 0 then
    local totaldmg = 0
    for _,weapon in pairs(weapons) do
      totaldmg = totaldmg + (weapon:attack(target,self) or 0)
    end
    currMap:register_incident('attacks',self,target,{damage=totaldmg})
    return totaldmg
  end
  
  --Basic attack:
  if target.baseType == "feature" and self:touching(target) then
    local dmg = target:damage(self:get_damage(),self,self.damage_type)
    self:decrease_all_conditions('attack')
    if dmg ~= false or dmg > 0 then
      self:decrease_all_conditions('hit')
    end
    if player:can_see_tile(self.x,self.y) or player:can_see_tile(target.x,target.y) and player:does_notice(self) then
      output:out(self:get_name() .. ' attacks ' .. target:get_name() .. ", dealing " .. dmg .. " damage.")
    end
    currMap:register_incident('attacks',self,target,{damage=dmg})
    return dmg
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
        local popup = Effect('dmgpopup')
        popup.image_name = "miss"
        popup.symbol=""
        popup.color = {r=0,g=0,b=150,a=150}
        currMap:add_effect(popup,target.x,target.y)
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
      local dtype = (self.damage_type and " " .. (damage_types[self.damage_type] and damage_types[self.damage_type].name or self.damage_type) or "")
			if dmg > 0 then txt = txt .. ucfirst(self:get_name()) .. " hits " .. target:get_name() .. " for " .. dmg .. dtype .. " damage."
      else txt = txt .. ucfirst(self:get_name()) .. " hits " .. target:get_name() .. " for no damage." end
      local xMod,yMod = get_unit_vector(self.x,self.y,target.x,target.y)
      --target.xMod,target.yMod = xMod*3,yMod*3
      --tween(.1,target,{xMod=0,yMod=0})
      --Tweening
      target.xMod,target.yMod = target.xMod+(xMod*5),target.yMod+(yMod*5)
      if timers[tostring(target) .. 'moveTween'] then
        Timer.cancel(timers[tostring(target) .. 'moveTween'])
      end
      timers[tostring(target) .. 'moveTween'] = tween(.1,target,{xMod=0,yMod=0},'linear',function() target.doneMoving = true end)
      
      if player:can_see_tile(self.x,self.y) or player:can_see_tile(target.x,target.y) and player:does_notice(self) and player:does_notice(target) then
        output:out(txt)
      end
			self:callbacks('melee_attack_hits',target,dmg)
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
      self:decrease_all_conditions('hit')
		end -- end hit if
    --Cancel active spells if applicable:
    for id,data in pairs(self.active_spells) do
      if data.spell.deactivate_on_attack or data.spell.deactivate_on_all_actions then
        local t = data.target
        local mp = data.ignoreCost
        local cd = data.ignoreCooldowns
        data.spell:finish(t, self, cd, mp)
      end
    end
    self:decrease_all_conditions('attack')
    currMap:register_incident('attacks',self,target,{damage=dmg})
		return dmg
	else -- if not touching target
		return false
	end
end

---This function is run every turn. It handles advancing conditions, recharging attacks, and AI for NPCs
--@param skip_conditions Boolean. Whether to skip running the condition advance code (optional)
function Creature:advance(skip_conditions)
  --profiler.reset()
  --profiler.start()
  local startTime = os.clock()
  local aiTime = 0
  local advTime = 0
  
  self.sees = nil --clear list of seen creatures
  self.checked = {} --clear list of unnoticed creatures you've checked
  self.seen_tile_cache = {} --clear list of tiles you've checked for site
  self.sensed_creatures = {} --clear listed of sensed creatures
  self.bonus_cache = {}
  self.can_move_cache = {}
  
  --AI Decision:
  local runs = 1
  while self.energy >= player:get_speed() and self ~= player do
    local x,y = self.x,self.y
    self.energy = self.energy - player:get_speed()
    if self:callbacks('ai') then
      if (self.ai == nil or ai[self.ai] == nil) then
        local aistart = os.clock()
        --profiler.reset()
        --profiler.start()
        ai.basic(self)
        --profiler.stop()
        aiTime = os.clock()-aistart
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
    
    --Call advance() callback on conditions, spells, equipment, etc.
    self:callbacks('advance')
    
    --Decrease condition time:
    self:decrease_all_conditions('turn')
    
    --Decrease cooldowns:
    for thing, cooldown in pairs(self.cooldowns) do
      if (cooldown <= 1) then
        self.cooldowns[thing] = nil
      else
        self.cooldowns[thing] = cooldown - 1
      end
    end --end spell for
    
    --Recharge ranged attack:
    if self.ranged_attack then
      local attack = rangedAttacks[self.ranged_attack]
      if attack and self.ranged_charges and not attack.active_recharge then
        attack:recharge(self)
      end --end max_charges if
    end --end ranged_attack if
  end --end skip_conditions if
  
  --Active spells:
  if self.active_spells then
    for id,data in pairs(self.active_spells) do
      local spell = data.spell
      spell:advance_active(data.target,self,data.ignoreColldowns,data.ignoreCost)
    end
  end
  local totalTime = os.clock()-startTime
  --profiler.stop()
  if totalTime >= 0.005 then
    print(self.name,self.x,self.y)
    print('AI time: ' .. aiTime)
    print('Total time: ' .. totalTime)
    --print(profiler.report(25))
  end
end

---Check whether a creature can move to a given tile
--@param x Number. The x coordinate
--@param y Number. The y coordinate
--@param inMap Map. The map to check. Defaults to current map (optional)
--@param ignoreCache Boolean. If true, ignore the can_move_cache (optional)
--@return Boolean. Whether or not the creature can move to that tile
function Creature:can_move_to(x,y,inMap,ignoreCache)
  --First, check to see if the target is A) even in the map, B) has a wall or creature
  inMap = inMap or currMap
  if not inMap:in_map(x,y) then return false end
  if not ignoreCache and self.can_move_cache[x .. ',' .. y] ~= nil then return self.can_move_cache[x .. ',' .. y] end
  if inMap[x][y] == "#" or inMap:get_tile_creature(x,y) then
    self.can_move_cache[x .. ',' .. y] = false
    return false
  end
  --if a creature can only move in certain types of terrain, check for those types:
  if self.terrainLimit then
    local needed = false
    for _, terrain in pairs(self.terrainLimit) do
      if inMap:tile_has_feature(x,y,terrain) then
        needed = true
        break
      end
    end
    if needed == false then
      self.can_move_cache[x .. ',' .. y] = false
      return false
    end --if your needed types were not found, you can't move there
  end --end terrain limit if
  --Check the features to see if there are any impassable/blocking ones, and if there are, if they're passable for you or not
  for _,feat in pairs(inMap:get_tile_features(x,y)) do
    if feat.baseType == "feature" and (feat.impassable or (feat.blocksMovement == true and feat.pathThrough ~= true)) then
      --If the tile isn't passable for anyone, or the creature has no special types, automatically return false
      if feat.passableFor == nil then
        self.can_move_cache[x .. ',' .. y] = false
        return false
      end
      --cycle through all the types to see if any of them match
      for ctype, _ in pairs(feat.passableFor) do
        if self:is_type(ctype) then
          self.can_move_cache[x .. ',' .. y] = true
          return true
        end --if any of the types are true, you're good to go
      end
      self.can_move_cache[x .. ',' .. y] = false
      return false --if no types match, can't go
    end --end feature if
  end --end for
  self.can_move_cache[x .. ',' .. y] = true
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
    if (val and val[1] and val[1].x and val[1].y) or (val and val.x and val.y) then --if a callback returned a tile, set that as the new destination instead
      if val[1] then
        x,y = val[1].x,val[1].y
      else
        x,y = val.x,val.y
      end
    end
		if (self:can_move_to(x,y)) then
      local canEnter = skip_callbacks or currMap:can_enter(x,y,self,self.x,self.y)
      if (canEnter) then
        local oldX, oldY = self.x,self.y
        if (self.x and self.y) then --if you're already on the board
          currMap.contents[self.x][self.y][self] = nil --empty old tile
          currMap.creature_cache[self.x .. "," .. self.y] = nil
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
            if self:is_type('airborne') == false then
              self.yMod = self.yMod-2
            end
            if timers[tostring(self) .. 'moveTween'] then
              Timer.cancel(timers[tostring(self) .. 'moveTween'])
            end
            timers[tostring(self) .. 'moveTween'] = tween(.1,self,{xMod=0,yMod=0},'linear',function() self.doneMoving = true end)
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
        currMap.creature_cache[self.x .. "," .. self.y] = self
        self:callbacks('moved',self.fromX,self.fromY,self.x,self.y)
        currMap:enter(x,y,self,oldX,oldY)
        --Update seen creatures:
        self.sees = nil
        if self == player then self.sees = self:get_seen_creatures() end
        --Cancel active spells if applicable:
        for id,data in pairs(self.active_spells) do
          if data.spell.deactivate_on_move or data.spell.deactivate_on_all_actions then
            local t = data.target
            local mp = data.ignoreCost
            local cd = data.ignoreCooldowns
            data.spell:finish(t, self, cd, mp)
          end
        end
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
function Creature:forceMove(x,y)
  if self.x and self.y then
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
  if not target or not target.x or not self.x or not target.y or not self.y then --You're definitely not touching something that doesn't exist in corporeal space
    return false
  end
	if (math.abs(target.x-self.x) <= 1 and math.abs(target.y-self.y) <= 1) then
		return true
	end
	return false
end

---Kill a creature.
--@param killer Entity. Whodunnit? By default, nothing actually passes in a killer, but it's here just in case
--@param silent Boolean. If true, don't output anything
function Creature:die(killer,silent)
  if self.isDead then
    if self == player then
      return
    else
      return self:remove()
    end
  end
  if killer then self.killer = killer end
  if killer == nil and self.lastAttacker then
    self.killer = self.lastAttacker
  end
  if self:callbacks('dies',self.killer) then
    local seen = (not silent and player:can_see_tile(self.x,self.y))
    if seen then
      if self.deathSound then output:sound(self.deathSound)
      elseif self.soundgroup then output:sound(self.soundgroup .. "_death")
      elseif not output:sound(self.id .. "_death") then --output:sound return false if a sound doesn't exist
        output:sound('genericdeath') --default death
      end --end sound type if
      if self.death_animation then
        local color = self.death_animation_color or (self.death_animation_use_creature_color and copy_table(self.color) or nil)
        currMap:add_effect(Effect('animation',{image_name=self.death_animation,time_per_tile=self.death_animation_time_per_tile,target={x=self.x,y=self.y},color=color,use_color_with_tiles=(self.color and true or false)}),self.x,self.y)
      end
    end --end seen if
    if self.playerAlly == true and self ~= player then
      update_stat('ally_deaths')
      update_stat('ally_deaths_as_creature',player.id)
      if player.class then
        update_stat('ally_deaths_as_class',player.class)
        update_stat('ally_deaths_as_creature_class_combo',player.id .. "_" .. player.class)
      end
      update_stat('creature_ally_deaths',self.id)
    end
    if (self.killer and self.killer.baseType == "creature") then
      local xp = math.max(0,10-(self.killer.level-self.level))
      if (self.killer.playerAlly == true) then
        local mod = 0.1*self.killer:get_bonus('xp_percent')
        local xpgain = xp + math.ceil(xp * mod)
        if self.killer == player then
          update_stat('kills')
          update_stat('kills_as_creature',player.id)
          if player.class then
            update_stat('kills_as_class',player.class)
            update_stat('kills_as_creature_class_combo',player.id .. "_" .. player.class)
          end
          update_stat('creature_kills',self.id)
          update_stat('branch_kills',currMap.branch)
          update_stat('map_kills',currMap.id)
          achievements:check('kill')
          output:out("You kill " .. self:get_name() .. "!" .. (xpgain > 0 and " You gain " .. xpgain .. " XP!" or ""))
        else
          update_stat('ally_kills')
          update_stat('ally_kills_as_creature',player.id)
          if player.class then
            update_stat('ally_kills_as_class',player.class)
            update_stat('ally_kills_as_creature_class_combo',player.id .. "_" .. player.class)
          end
          update_stat('allied_creature_kills',self.killer.id)
          update_stat('creature_kills_by_ally',self.id)
          output:out(self.killer:get_name() .. " kills " .. self:get_name() .. "!" .. (xpgain > 0 and " You gain " .. xpgain .. " XP!" or ""))
        end
        run_all_events_of_type('player_kills')
      else --killed by a non-player ally
        if player:can_sense_creature(self) then output:out(self.killer:get_name() .. " kills " .. self:get_name() .. "!") end
      end
      --XP:
      if xp > 0 then self.killer:give_xp(xp) end
      
      --Run kills() callbacks
      if self.killer and self.killer.callbacks then
        self.killer:callbacks('kills',self)
      end
      if self.killer and self.killer.master and self.killer.master.hp > 0 and self.killer.master.callbacks then
        self.killer.master:callbacks('ally_kills',self,killer)
      end
    
      --Give/Remove Favor and Reputation:
      local reputation = self:get_kill_reputation()
      for fac,reputation in pairs(reputation) do
        self.killer:update_reputation(fac,reputation,true,"killing " .. self:get_name(),true)
      end --end faction for
      local favor = self:get_kill_favor()
      for fac,favor in pairs(favor) do
        self.killer:update_favor(fac,favor,true,"killing " .. self:get_name())
      end --end faction for
      self.killer:decrease_all_conditions('kill')
    elseif seen then --killed by something other than a creature
      output:out(self:get_name() .. " dies!")
    end --end playerally killer if
    
    --Carve a notch into the killer's weapon:
    local weap = self.lastAttackerWeapon 
    if self.lastAttackerWeapon then
      weap.kills = (weap.kills or 0)+1
      weap:decrease_all_enchantments('kill') --decrease the turns left for any enchantments that decrease on kill
    end
    
    --Deactivate all active spells:
    for id,data in pairs(self.active_spells) do
      local t = data.target
      local mp = data.ignoreCost
      local cd = data.ignoreCooldowns
      data.spell:finish(t, self, cd, mp)
    end
    
    --Register the death incident on the map, for other creatures to respond to:
    currMap:register_incident('dies',self)
    if self.killer and self.killer.baseType == "creature" then
      currMap:register_incident('kills',self.killer,self)
    end
    
    if self == player then
      return player_dies() --handle special player death stuff elsewhere
    end
    self.isDead = true
    self.hp = 0
    
    --Free Thralls:
    if self.master then self.master.thralls[self] = nil end
    self:free_thralls()
    
    --Corpse time:
    if self.explosiveDeath then
      return self:explode()
    end
    local absorbs = false
    if currMap:tile_has_feature(self.x,self.y,'bridge') == false and currMap:tile_has_feature(self.x,self.y,'minetracks') == false then --if there's a bridge, it's OK for a corpse to show
      absorbs = currMap:tile_has_tag(self.x,self.y,'absorbs')
    end --end bridge if
    
    if not absorbs then
      if self.corpse == nil and not self:is_type('bloodless') then
        local chunk = currMap:add_feature(Feature('chunk',self),self.x,self.y)
      end --put a chunk in, no matter what
      if self.corpse == nil then
        local corpse = Feature('corpse',self)
        currMap:add_feature(corpse,self.x,self.y)
      elseif self.corpse then
        local corpse = Feature(self.corpse,self)
        currMap:add_feature(corpse,self.x,self.y)
      end --end special corpse vs regular corpse if
      self:drop_all_items(true)
    end --end absorbs if
  
    self:remove()
  end --end dies callback if
end

---Make a creature explode.
function Creature:explode()
	-- EXPLODE!
	if not self:is_type('incorporeal') then
    self.exploded = true
    if self == player then
      update_stat('explosions')
      update_stat('exploded_creatures',self.id)
    end
    if self:callbacks('explode') then
      if possibleMonsters[self.id].explode then
        --do nothing here, it already got done in the callbacks. This is just to keep from running the "normal" explosion
      elseif not self:is_type('bloodless') then
        if player:can_see_tile(self.x,self.y) then
          output:out(self:get_name(false,true) .. " explodes!")
          output:sound('explode')
        end
        local chunkmaker = Effect('chunkmaker',self)
        if self.killer then chunkmaker.creator = self.killer end
        currMap:add_effect(chunkmaker,self.x,self.y)
      end --end special explosion code check
    end --end callback check
	end -- end initial if
  --Add fear to creatures that saw the explosion
  currMap:register_incident('explodes',self)
  
  
  if self == player then
    player:die()
  else
    self:drop_all_items(true)
    self:remove()
  end
end -- end function

---Remove a creature from the map without killing it. Called to clean up after the creature dies, but can also be called whenever to remove them for some other reason.
--@param map Map. The map to remove the creature from. Defaults to current map (optional)
function Creature:remove(map)
  map = map or currMap
  map.contents[self.x][self.y][self] = nil
  map.creature_cache[self.x .. "," .. self.y] = nil
  if self.castsLight then map.lights[self] = nil end
  map.creatures[self] = nil
  
  --[[Handle thrall stuff:
  if self.master then self.master.thralls[self] = nil end
  self:free_thralls()--]]
  
	--self.hp = 0
	if (target == self) then
		target = nil
	end
  --currMap:set_blocked(self.x,self.y,0)
end

---Gets the list of items the creature has
--@return Table. The creature's inventory
function Creature:get_inventory(ignoreEquip)
  if ignoreEquip then
    local inv = {}
    for _,item in ipairs(self.inventory) do
      if not item.equipped then
        inv[#inv+1] = item
      end
    end
    return inv
  else
    return self.inventory
  end
end

---Gets the number of slots the creature has used in its inventory
--@return Number. The number of slots the creature has used in its inventory
function Creature:get_used_inventory_space()
  local used_slots = 0
  for _,item in ipairs(self:get_inventory(true)) do
    if not item.equipped then
      used_slots = used_slots + (item.size or 1)
    end
  end --end inventory for
  return used_slots
end

---Gets the number of free inventory slots a creature has
--@return Number. The number of slots the creature has free in its inventory, or false if the creature has no inventory space set (which translates to infinite space)
function Creature:get_free_inventory_space()
  if not self.inventory_space then return false end
  
  return self:get_inventory_space()-self:get_used_inventory_space()
end

---Gets the total inventory space the creature has *MAY WANT TO CHANGE FOR YOUR OWN GAME*
function Creature:get_inventory_space()
  if not self.inventory_space then return false end
  
  return self:get_stat('inventory_space')
end

---Have a creature pick up an item from a tile.
--@param item Item. The item to pick up
--@param tileOnly Boolean. Whether to only allow pickups from the tile the creature is standing on. If not set to TRUE, creatures can also pick up from adjacent tiles.
--@param silent Boolean. If true, don't say anything
function Creature:pickup(item,tileOnly,silent)
  --First check if it fits in your free inventory space
  local slots = self:get_free_inventory_space()
  local size = (item.size or 1)
  local has_item,inv_id = self:has_item(item.id,(item.sortBy and item[item.sortBy]),item.enchantments,item.level)
  if slots and size > 0 and slots < size and (not has_item or not has_item.stacks or (has_item.max_stack and has_item.amount >= has_item.max_stack)) then
    local tooBigText = "You are carrying too much to pick that up."
    if self == player then output:out(tooBigText) end
    return false,tooBigText
  end
  local didIt,pickupText = item:callbacks('pickup',self)
  if didIt == false then
    if pickupText then output:out(pickupText) end
    return false,pickupText
  end
  local x,y = self.x,self.y
  if ((tileOnly ~= true and not self:touching(item)) or (tileOnly == true and (item.x ~= x or item.y ~= y))) and (not item.possessor or not item.possessor.inventory_accessible_anywhere) then return false end
  local original_possessor = item.possessor
  local original_x,original_y = item.x, item.y
  if item.possessor and (not item.possessor.take_item or item.possessor:take_item(self,item)) ~= false then
    if not silent and player:can_sense_creature(self) then
      output:out(pickupText or self:get_name() .. " takes " .. item:get_name() .. " from " .. item.possessor:get_name() .. ".")
    end
    item.possessor:drop_item(item)
  elseif not silent and player:can_sense_creature(self) then
    output:out(pickupText or self:get_name() .. " picks up " .. item:get_name() .. ".")
  end
  currMap.contents[item.x][item.y][item] = nil
  if item.castsLight then
    currMap.lights[item] = nil
  end
  self:give_item(item)
  currMap:register_incident('take_item',self,item,{original_possessor=original_possessor,original_x=original_x,original_y=original_y})
end

---Transfer an item to a creature's inventory
--@param item Item. The item to give.
--@param silent Boolean. If true, don't show a popup
function Creature:give_item(item,silent)
  if item.possessor == self or self:has_specific_item(item) then return false end
  local initial_amt = item.amount
  if not item or type(item) ~= "table" or item.baseType ~= "item" then
    output:out("Error: Tried to give non-existent item to creature " .. self:get_name())
    print("Tried to give non-existent item to creature " .. self:get_name())
    return false
  end
  if self == player and item.identified and item.identify_all_of_type then
    item:identify() --If this instance of the item is already identified, run identify() so that ALL instances of this item are now identified
  end
  if (item.stacks == true) then
    local has_item,inv_id = self:has_item(item.id,(item.sortBy and item[item.sortBy]),item.enchantments,item.level)
    if inv_id and (not has_item.max_stack or has_item.amount < has_item.max_stack) then
      local max_stack = has_item.max_stack
      local space_in_stack = (max_stack and max_stack - has_item.amount or nil)
      if not max_stack or space_in_stack >= item.amount then
        has_item.amount = has_item.amount + item.amount
        item = has_item
      else --if picking up would cause too big of a stack
        has_item.amount = max_stack
        local new_stack_amt = item.amount - space_in_stack
        item.amount = new_stack_amt
        return self:give_item(item,silent) --run this again, so it'll look at the next stack
      end
    else
      table.insert(self.inventory,item)
      item.x,item.y=self.x,self.y
      item.possessor = self
      while item.max_stack and item.amount > item.max_stack do --if the item stack is too large then split it up into multiple items
        item:splitStack(item.max_stack)
      end
    end
  else
    table.insert(self.inventory,item)
  end
  item.x,item.y=self.x,self.y
  item.possessor = self
  --Add item popup:
  if self == player and not silent then
    local popup1 = Effect('dmgpopup')
    popup1.symbol = "+" .. (initial_amt > 1 and initial_amt or "")
    popup1.color = {r=0,g=255,b=0,a=150}
    local tileMod = round(fonts.mapFontWithImages:getWidth(popup1.symbol)/2)
    popup1.xMod = -tileMod
    local popup2 = Effect('dmgpopup')
    popup2.image_name = item.image_name or item.id
    popup2.imageType = "item"
    popup2.xMod = tileMod
    popup2.speed = popup1.speed
    if (item.use_color_with_tiles ~= false or gamesettings.always_use_color_with_tiles) and item.color then
      popup2.color = {r=item.color.r,g=item.color.g,b=item.color.b,a=150}
    else
      popup2.color = {r=255,g=255,b=255,a=150}
    end
    popup1.paired = popup2
    popup2.paired = popup1
    popup2.itemID = item.id
    popup2.sortBy = (item.sortBy and item[item.sortBy] or nil)
    popup2.itemAmt = initial_amt
    currMap:add_effect(popup1,self.x,self.y)
    currMap:add_effect(popup2,self.x,self.y)
  end
  return item
end

---Have a creature drop an item on the tile they're on
--@param item Item. The item to drop
--@param silent Boolean. If true, don't display drop text
function Creature:drop_item(item,silent)
  if item.undroppable then return false end
	local _,id = self:has_specific_item(item)
	if (id) then
    if not silent and player:can_sense_creature(self) then output:out(self:get_name() .. " dropped " .. item:get_name() .. ".") end
    currMap:add_item(item,self.x,self.y,true)
		table.remove(self.inventory,id)
    if self:is_equipped(item) then
      self:unequip(item)
    end
    item.x,item.y=self.x,self.y
    item.possessor=nil
    item.equipped=false
    if self.hotkeys then
      for hkid,hkinfo in pairs(self.hotkeys) do
        if hkinfo.type == "item" and hkinfo.hotkeyItem == item then
          local item = self:has_item(item.id,(item.sortBy and item[item.sortBy] or nil))
          if item then
            self.hotkeys[hkid] = {type='item',hotkeyItem=item}
            item.hotkey = hkid
          else
            self.hotkeys[hkid] = nil
          end
        end
      end
    end
	end
end

---Have a creature drop all their items on the tile they're on
--@param deathItems Boolean. Whether to also drop death items
function Creature:drop_all_items(deathItems)
	for _,item in ipairs(self.inventory) do
    if not item.drop_chance or random(1,100) <= item.drop_chance then
      currMap:add_item(item,self.x,self.y,true)
      if self:is_equipped(item) then
        self:unequip(item)
      end
      item.x,item.y=self.x,self.y
      item.possessor=nil
      item.equipped=false
    else
      self:delete_item(item)
    end
	end --end inventory for loop
  if deathItems and self.death_items and not self.summoned and not self:has_condition('summoned') then
    for _,item in ipairs(self.death_items) do
      if not item.drop_chance or random(1,100) <= item.drop_chance then
        currMap:add_item(item,self.x,self.y,true)
        item.x,item.y=self.x,self.y
        item.possessor=nil
        item.equipped=false
      else
        self:delete_item(item)
      end
    end --end inventory for loop
  end
  --Money:
  if self.money and self.money > 0 then
    local money = Item('money')
    money.amount = self.money
    currMap:add_item(money,self.x,self.y,true)
  end
  self.inventory = {}
  self.death_items = nil
end

---Remove an item from a creature's inventory
--@param item Item. The item to remove
--@param amt Number. The amount of the item to remove, if the item is stackable. Defaults to 1.
--@param silent Boolean. If true, don't show the popup
function Creature:delete_item(item,amt,silent)
  amt = amt or 1
	local _,id = self:has_specific_item(item)
	if (id) then
    if amt == -1 or amt >= (item.amount or 0) then
      table.remove(self.inventory,id)
      if self.hotkeys then
        for hkid,hkinfo in pairs(self.hotkeys) do
          if hkinfo.type == "item" and hkinfo.hotkeyItem == item then
            local item = self:has_item(item.id,(item.sortBy and item[item.sortBy] or nil))
            print(item)
            if item then
              self.hotkeys[hkid] = {type='item',hotkeyItem=item}
              item.hotkey = hkid
            else
              self.hotkeys[hkid] = nil
            end
          end
        end
      end
      item.possessor=nil
      item.equipped=false
    else
      item.amount = item.amount - amt
    end
    if self:is_equipped(item) then
      self:unequip(item)
    end
    --Add item popup:
    if self == player and not silent then
      local popup1 = Effect('dmgpopup')
      popup1.symbol = (amt ~= 1 and -amt or "-")
      popup1.color = {r=255,g=0,b=0,a=150}
      local tileMod = round(fonts.mapFontWithImages:getWidth(popup1.symbol)/2)
      popup1.xMod = -tileMod
      local popup2 = Effect('dmgpopup')
      popup2.image_name = item.image_name or item.id
      popup2.imageType = "item"
      popup2.xMod = tileMod
      popup2.speed = popup1.speed
      if (item.use_color_with_tiles ~= false or gamesettings.always_use_color_with_tiles) and item.color then
        popup2.color = {r=item.color.r,g=item.color.g,b=item.color.b,a=150}
      else
        popup2.color = {r=255,g=255,b=255,a=150}
      end
      popup1.paired = popup2
      popup2.paired = popup1
      popup2.itemID = item.id
      popup2.sortBy = (item.sortBy and item[item.sortBy] or nil)
      popup2.itemAmt = -amt
      currMap:add_effect(popup1,self.x,self.y)
      currMap:add_effect(popup2,self.x,self.y)
    end
	end
end
  
---Check if a creature has an instance of an item ID
--@param item String. The item ID to check for
--@param sortBy Text. What the "sortBy" value you're checking is (optional)
--@param enchantments Table. The table of echantments to match (optional)
--@param level Number. The level of the item (optional)
--@return either Boolean or Item. False, or the specific item they have in their inventory
--@return either nil or Number. The index of the item in the inventory
--@return either nil or Number. The amount of the item the creature has
function Creature:has_item(itemID,sortBy,enchantments,level)
  enchantments = enchantments or {}
  local item,index,amount = false,nil,0
  local largestAmt = 0
	for id, it in ipairs(self.inventory) do
		if (itemID == it.id) and (not level or it.level == level) and (not it.sortBy or sortBy == it[it.sortBy]) then
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
        amount = amount + it.amount
        if not item or it.amount > largestAmt and (not it.max_stack or it.amount < it.max_stack) then --we want to select the largest stack of items that's not a maxed-out stack of items
          if not it.max_stack or it.amount < it.max_stack then --don't set largest amount to a full stack
            largestAmt = it.amount
          end
          item,index = it,id
        end
      end
		end
	end --end inventory for
	return item,index,amount
end

---Check if a creature has a specific item
--@param item Item. The item to check for
--@return either Boolean or Item. False, or the specific item they have in their inventory
--@return either nil or Number. The index of the item in the inventory
--@return either nil or Number. The amount of the item the creature has
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

---Get a list of all equipment a creature has equipped 
--@return Table. A list of the equipment.
function Creature:get_all_equipped()
  local equipped = {}
  for slotID, slotData in pairs(self.equipment) do
    for id,equip in ipairs(slotData) do
      equipped[#equipped+1] = equip
    end
  end
  return equipped
end

---Equip an item
--@param item Item. The item to equip
--@return Boolean. Whether or not the item was equipped.
--@return String. Text describing the equipping.
function Creature:equip(item)
  local slot = item.equipSlot
  local equipDef = self.equipment[slot]
  local equipText = ""
  if not slot or not equipDef then return false,"You can't equip this type of item." end
  
  --Check for level/stat requirements, etc
  local canEquip,noText = self:can_use_item(item,"equip")
  if canEquip == "false" then
    return false,noText
  end
  
  --Check to see if an item's equipped size makes sense here
  local size = item.equipSize or 1
  local slots = equipDef.slots or 0
  if size > 0 then
    --First, check to make sure we even have the correct number of slots available
    if size > slots then
      return false, ucfirst(item:get_name() .. " is too big for you to equip.")
    end
    --Add up all the slots currently being used:
    local slotsUsed = 0
    for i=1,slots,1 do
      local eqItem = self.equipment[slot][i]
      if eqItem then
        slotsUsed = slotsUsed + (eqItem.equipSize or 1)
      end
    end
    if slotsUsed + size > slots then
      local didIt = false
      --Figure out what items to unequip
      local initialslots = 0
      local unequips = {}
      for i=1,slots,1 do
        if equipDef[i] then
          initialslots = initialslots + (equipDef[i].equipSize or 1)
          unequips[#unequips+1] = equipDef[i]
        end
        if (slotsUsed+initialslots) >= size then
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
        didIt,equipText = item:callbacks('equip',self)
        if didIt ~= false then
          equipSlot[i] = item
          equipText = (equipText or "") .. (item.equipText or "You equip " .. item:get_name() .. ".")
          self.equipment_list[item] = item
          item.equipped = true
          if item.castsLight then
            currMap.lights[item] = item
          end
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
    equipText = (equipText or "") .. newText
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
      didIt,unequipText = item:callbacks('unequip',self)
      if didIt ~= false then
        self.equipment[equipSlot][i] = nil
        unequipText = (unequipText or "") .. (item.unequipText or "You unequip " .. item:get_name() .. ".")
        self.equipment_list[item] = nil
        item.equipped = nil
        if item.castsLight then
          currMap.lights[item] = nil
        end
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
--@param verb Text. The verb the item uses. Or "equip" if it's equipment we're looking at
--@return Boolean. Whether or not it's equippable
--@return Text. Why you can't equip it, if applicable. Nil if it is equipable.
function Creature:can_use_item(item,verb)
  verb = verb or "use"
  if item.level_requirement and self.level < item.level_requirement then
    return false,"You're not a high enough level to " .. verb .. " " .. item:get_name() .. "."
  end
  if item.stat_requirements then
    for stat,requirement in pairs(item.stat_requirements) do
      if self:get_stat(stat,true) < requirement then
        return false,"Your " .. stat .. " stat is too low to " .. verb .. " "  .. item:get_name() .. "."
      end
    end
  end
  if item.skill_requirements then
    for skill,requirement in pairs(item.skill_requirements) do
      if self:get_skill(skill,true) < requirement then
        return false,"Your " .. possibleSkills[skill].name .. " skill is too low to " .. verb .. " "  .. item:get_name() .. "."
      end
    end
  end
  if self.forbidden_item_types and count(self.forbidden_item_types) > 0 then
    for _,itype in ipairs(self.forbidden_item_types) do
      if item:is_type(itype) then
        return false,"You can't " .. verb .. " this type of item."
      end
    end
  end
  if self.cooldowns[item] then
    return false,"You can't use this item again for " .. self.cooldowns[item] .. " more turns."
  end
  return true
end

---Check if a creature can see a given tile
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@param forceRefresh Boolean. Whether to force actually calculating if a creature can see it, versus just looking at the stored values of player sight. Useful only when calling this for the player.
--@return Boolean. Whether or not they can see it.
function Creature:can_see_tile(x,y,forceRefresh)
  if (self == player) and currGame.cheats.seeAll==true then return true end
  if not currMap or not currMap:in_map(x,y) then return false end
  if not self.x or not self.y then output:out(self:get_name() .. " does not have a location but is trying to see stuff somehow.") return false end --If you don't exist, you can't see anything
  
  if self == player and not forceRefresh then
    if not player.seeTiles then
      refresh_player_sight()
    else
      return player.seeTiles[x][y]
    end
  elseif self ~= player and self.seen_tile_cache[x .. ',' .. y] ~= nil then
    return self.seen_tile_cache[x .. ',' .. y]
  end
  
  local lit = false
  
  if x == self.x and y == self.y and self.hp > 0 then
    self.seen_tile_cache[x .. ',' .. y] = true
    return true
  end --you can always see your own tile
  
  local perc = self:get_perception()
  if perc <= 0 then --if your perception is less than 1, you can't see anything outside of your own tile
    self.seen_tile_cache[x .. ',' .. y] = false
    return false
  end
  
  if currMap.lightMap[x][y] or perc > calc_distance(self.x,self.y,x,y) then -- if it's a lit tile, or within your view distance, it's "lit"
    lit = true
  end
  
  if lit then --if it's not "lit," you can't see it anyway, so don't run bresenham
    if bresenham.los(self.x,self.y,x,y, currMap.can_see_through,currMap) then --if there's a clear path to the square, you can see it!
      self.seen_tile_cache[x .. ',' .. y] = true
      return true
    end
  end
  self.seen_tile_cache[x .. ',' .. y] = false
  return false --default to not being able to see
end

---Check if a creature can sense another, either through sight or spooky senses.
--@param creat Creature. The creature to check.
--@param skipSight Boolean. Whether to skip running can_see_tile and just look at extra senses (optional)
--@return Boolean. If the target can be seen.
function Creature:can_sense_creature(creat,skipSight)
  if not creat then return false end
  if self.sensed_creatures[creat] ~= nil then
    return self.sensed_creatures[creat]
  end
  if creat == self then
    self.sensed_creatures[creat] = true
    return true
  end
  if not currMap then
    self.sensed_creatures[creat] = false
    return false
  end
  if creat.master and creat.master == self then
    self.sensed_creatures[creat] = true
    return true
  end
  if skipSight ~= true and (creat.baseType ~= "creature" or not creat:has_condition('invisible')) and self:can_see_tile(creat.x,creat.y) then
    self.sensed_creatures[creat] = true
    return true
  end
  if self.extraSense == nil then
    self.sensed_creatures[creat] = false
    return false
  else
    local sense = possibleSpells[self.extraSense]:sense(self,creat)
    self.sensed_creatures[creat] = sense
    return sense
  end
end

---Check if you can draw a straight line between the creature and a tile.
--@param x Number. The x-coordinate
--@param y Number. The y-coordinate
--@return Boolean. Whether or not they can shoot it.
function Creature:can_shoot_tile(x,y)
  --if (self == player) then return true end
	local dist = calc_distance(self.x,self.y,x,y)
	if self:can_see_tile(x,y) then
		return currMap:is_line(self.x,self.y,x,y,false,'airborne',false,true,true)
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
    if target.playerAlly ~= true and (target.shitlist[player] or self:is_faction_enemy(target) or self:is_enemy_type(target)) then return true end --if the target is not a player ally, and is an enemy of the player, an enemy of your faction, or an enemy creature type, they're your enemy too
  else --if we're not a player ally
    if self:is_faction_enemy(target) or self:is_enemy_type(target) then
      return true --if the target is an enemy of your faction, or a creature type you consider an enemy then they're you're enemy too
    elseif not self.attack_enemy_player_only and (not self.factions or count(self.factions) == 0) and (target.playerAlly == true or target == player) and not self:is_friendly_type(target) then
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

---Gets a list of all creature types a creature is
--@param base_only Boolean. If true, don't look at types applied by conditions
--@return Table. A table of creature types
function Creature:get_types(base_only)
  if base_only then
    return self.types
  end
  
  local temptypes = {}
  local blockedtypes = {}
  for conID,_ in pairs(self.conditions) do
    local con = conditions[conID]
    if con and con.removes_creature_types then
      for _,blocked in ipairs(con.removes_creature_types) do
        blockedtypes[blocked] = blocked
        temptypes[blocked] = nil
      end
    end
    if con and con.applies_creature_types then
      for _,ctype in ipairs(con.applies_creature_types) do
        if not blockedtypes[ctype] then
          temptypes[ctype] = ctype
        end
      end
    end
  end --end condition for
  for _,spell in ipairs(self.spells) do
    if spell.removes_creature_types then
      for _,blocked in ipairs(spell.removes_creature_types) do
        blockedtypes[blocked] = blocked
        temptypes[blocked] = nil
      end
    end
    if spell.applies_creature_types then
      for _,ctype in ipairs(spell.applies_creature_types) do
        if not blockedtypes[ctype] then
          temptypes[ctype] = ctype
        end
      end
    end
  end --end spell for
  for _,ctype in ipairs(self.types) do
    if not blockedtypes[ctype] then
      temptypes[ctype] = ctype
    end
  end
  local ctypes = {}
  for _,ctype in pairs(temptypes) do
    ctypes[#ctypes+1] = ctype
  end
 
  return ctypes
end

---Checks if a creature is of a certain type
--@param ctype String. The creature type to check for
--@param base_only Boolean. If true, don't look at types applied by conditions
--@return Boolean. Whether or not the creature is that type
function Creature:is_type(ctype,base_only)
  if base_only then
    if not self.types then return false end
    return in_table(ctype,self.types)
  end
  for _,c in pairs(self:get_types()) do
    if c == ctype then return true end
  end --end for
  return false
end --end function

---Determine if a creature is an enemy type of yours (this function ignores factions, but does look at your creature types' enemy types list)
--@param target Creature. The creature to check
--@return Boolean. If they're an enemy type
function Creature:is_enemy_type(target)
  if self.enemy_types then
    for _,ctype in ipairs(self.enemy_types) do
      if target:is_type(ctype) then return true end
    end
  end
  for _,ctype in ipairs(self:get_types()) do
    if creatureTypes[ctype] and creatureTypes[ctype].enemy_types then
      for _,ct in ipairs(creatureTypes[ctype].enemy_types) do
        if target:is_type(ct) then return true end
      end --end enemy_types for
    end --end if creatureTypes[ctype]
  end --end self ctype for
  return false
end

---Determine if a creature is a friendly type of yours (this function ignores factions, but does look at your creature types' friendly types list)
--@param target Creature. The creature to check
--@return Boolean. If they're a friendly type
function Creature:is_friendly_type(target)
  if self.friendly_types then
    for _,ctype in pairs(self.friendly_types) do
      if target:is_type(ctype) then return true end
    end
  end
  for _,ctype in ipairs(self:get_types()) do
    if creatureTypes[ctype] and creatureTypes[ctype].friendly_types then
      for _,ct in ipairs(creatureTypes[ctype].friendly_types) do
        if target:is_type(ct) then return true end
      end --end enemy_types for
    end --end if creatureTypes[ctype]
  end --end self ctype for
  return false
end

---Determine if a creature is an ignored type of yours (this function ignores factions, but does look at your creature types' ignore types list)
--@param target Creature. The creature to check
--@return Boolean. If they're a friendly type
function Creature:is_ignore_type(target)
  if self.ignore_types then
    for _,ctype in pairs(self.ignore_types) do
      if target:is_type(ctype) then return true end
    end
  end
  for _,ctype in ipairs(self:get_types()) do
    if creatureTypes[ctype] and creatureTypes[ctype].ignore_types then
      for _,ct in ipairs(creatureTypes[ctype].ignore_types) do
        if target:is_type(ct) then return true end
      end --end enemy_types for
    end --end if creatureTypes[ctype]
  end --end self ctype for
  return false
end

---Checks if a creature is an enemy of any of your factions
--@param target Creature. The creature to check
--@return Boolean. Whether or not the creature is an enemy of any of your factions
function Creature:is_faction_enemy(target)
  if not self.factions then return false end
  local resident_faction = currMap.resident_use_faction_reputation
  if resident_faction and self:is_faction_member('residents') then
    if target:has_condition('trespassing') then return true end
    if currWorld.factions[resident_faction] then return currWorld.factions[resident_faction]:is_enemy(target) end
  end
  for _,f in pairs(self.factions) do
    if currWorld.factions[f] and not currWorld.factions[f].ignore_hostility and currWorld.factions[f]:is_enemy(target) then
      return true
    end
  end
  if self.enemy_factions then
    for _,fac in ipairs(self.enemy_factions) do
      if target:is_faction_member(fac) then return true end
    end
  end
  for _,ctype in ipairs(self:get_types()) do
    if creatureTypes[ctype] and creatureTypes[ctype].enemy_factions then
      for _,fac in ipairs(creatureTypes[ctype].enemy_factions) do
        if target:is_faction_member(fac) then return true end
      end --end enemy_types for
    end --end if creatureTypes[ctype]
  end --end self ctype for
  return false
end --end function

--Checks if a creature is a friend of any of your factions
--@param target Creature. The creature to check
--@return Boolean. Whether or not the creature is a friend of any of your factions
function Creature:is_faction_friend(target)
  if not self.factions then return false end
  local resident_faction = currMap.resident_use_faction_reputation
  if resident_faction and self:is_faction_member('residents') then
    if currWorld.factions[resident_faction] then return currWorld.factions[resident_faction]:is_friend(target) end
  end
  for _,f in pairs(self.factions) do
    if currWorld.factions[f] and not currWorld.factions[f].ignore_hostility and currWorld.factions[f]:is_friend(target) then
      return true
    end
  end
  if self.friendly_factions then
    for _,fac in ipairs(self.friendly_factions) do
      if target:is_faction_member(fac) then return true end
    end
  end
  for _,ctype in ipairs(self:get_types()) do
    if creatureTypes[ctype] and creatureTypes[ctype].friendly_factions then
      for _,fac in ipairs(creatureTypes[ctype].friendly_factions) do
        if target:is_faction_member(fac) then return true end
      end --end enemy_types for
    end --end if creatureTypes[ctype]
  end --end self ctype for
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
  --Next, loop through all the factions in the game to look at their kill_favor stats
  for fid,faction in pairs(currWorld.factions) do
    favorMax[fid] = favorMax[fid] or 0
    favorMin[fid] = favorMin[fid] or 0
    if faction.kill_favor then --If the faction has a straight favor score for killing anything
      if faction.kill_favor > 0 then favorMax[fid] = faction.kill_favor
      else favorMin[fid] = faction.kill_favor end
    end
    --Favor for killing this type of creature:
    if faction.kill_favor_types then
      for _,typ in pairs(self:get_types(true)) do
        if faction.kill_favor_types[typ] then
          local newFavor = faction.kill_favor_types[typ]
          if (newFavor > 0 and favorMax[fid] < newFavor) then
            favorMax[fid] = newFavor
          elseif (newFavor < 0 and favorMin[fid] > newFavor) then
            favorMin[fid] = newFavor 
          end
        end --end if kill_favor_types if
      end --end self.types for
    end --end if faction.kill_favor_types
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

---Gets the reputation you get for killing this creature.
--@return Table. A table of factions, and the reputation scores
function Creature:get_kill_reputation()
  local reputation = {}
  local reputationMax = {}
  local reputationMin = {}
  --Kill reputation defined in the creature definition itself:
  if self.kill_reputation then
    for faction,score in pairs(self.kill_reputation) do
      reputation[faction] = (reputation[faction] or 0) + score
      if score > 0 then reputationMax[faction] = score
      else reputationMin[faction] = score end
    end
  end --end if self.kill_reputation
  --Next, loop through all the factions in the game to look at their kill_reputation stats
  for fid,faction in pairs(currWorld.factions) do
    reputationMax[fid] = reputationMax[fid] or 0
    reputationMin[fid] = reputationMin[fid] or 0
    if faction.kill_reputation then --If the faction has a straight reputation score for killing anything
      if faction.kill_reputation > 0 then reputationMax[fid] = faction.kill_reputation
      else reputationMin[fid] = faction.kill_reputation end
    end
    --reputation for killing this type of creature:
    if faction.kill_reputation_types then
      for _,typ in pairs(self:get_types(true)) do
        if faction.kill_reputation_types[typ] then
          local newreputation = faction.kill_reputation_types[typ]
          if (newreputation > 0 and reputationMax[fid] < newreputation) then
            reputationMax[fid] = newreputation
          elseif (newreputation < 0 and reputationMin[fid] > newreputation) then
            reputationMin[fid] = newreputation 
          end
        end --end if kill_reputation_types if
      end --end self.types for
    end --end if faction.kill_reputation_types
    --reputation for killing creatures of this faction:
    if self.factions and faction.kill_reputation_factions then
      for _,fac in pairs(self.factions) do
        if faction.kill_reputation_factions[fac] then
          local newreputation = faction.kill_reputation_factions[fac]
          if (newreputation > 0 and reputationMax[fid] < newreputation) then
            reputationMax[fid] = newreputation
          elseif (newreputation < 0 and reputationMin[fid] > newreputation) then
            reputationMin[fid] = newreputation 
          end
        end --end if faction.kill_reputation_factions
      end --end self.factions for
    end --end if self.factions
    reputation[fid] = reputationMax[fid]+reputationMin[fid]
  end --end faction for
  return reputation
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

---Modifies the reputation of a creatue with a faction TODO: custom rep change callbacks
--@param factionID String. The faction ID
--@param amount Number. The amount to change the reputation by
--@param display Boolean. If true, display text noting the reputation change
--@param reason String. Display this text after
--@param noEnemies Boolean. if true, don't update enemy factions' reputation
function Creature:update_reputation(factionID,amount,display,reason,noEnemies)
  --If you're under player control, update player rep instead
  if self.master and self.master == player then
    return player:update_reputation(factionID,amount,display,reason,noEnemies)
  end
  
  local faction = currWorld.factions[factionID]
  local member = self:is_faction_member(factionID)
  
  --If rep only applies to members of this faction, don't do anything
  if faction.members_only_reputation and not member then
    return false
  end
  
  if faction.contacted_when_reputation_changes then
    faction.contacted = true
  end
  
  self.reputation[factionID] = (self.reputation[factionID] or 0) + amount
  if currGame.heist and self == player then
    currGame.heist.reputation_change[factionID] = (currGame.heist.reputation_change[factionID] or 0) + amount
  end
  if display and self == player and amount ~= 0 and faction.contacted and not faction.hidden then
    output:out("You " .. (amount > 0 and "gain " or "lose ") .. math.abs(amount) .. " reputation with the " .. faction.name .. (reason and " for " .. reason or "") .. ".")
  end
  if faction.banish_threshold and member and self.reputation[factionID] < faction.banish_threshold then
    faction:leave(self)
    if self == player then
      output:out("You are kicked out of " .. faction.name .. "!")
    end
  end --end banish reputation if
  if amount < 0 and faction.hostile_threshold and self.reputation[factionID] <= faction.hostile_threshold then
    if self.thralls and count(self.thralls) > 0 then
      for _,thrall in pairs(self.thralls) do
        if thrall:is_faction_member(factionID) and not (thrall.summoned or thrall:has_condition('summoned') or thrall:is_type('mindless') or thrall:has_condition('enthralled')) then
          thrall:become_free()
          thrall:become_hostile(self,true)
        end
      end
    end
  end
  if amount > 0 and not noEnemies then
    for _,enemyFac in pairs(currWorld.factions) do
      if enemyFac.enemy_factions and in_table(factionID,enemyFac.enemy_factions) then
        self:update_reputation(enemyFac.id,-amount,display,"fraternizing with the " .. faction.name .. "")
      end
    end
  end
end

---Modifies the favor of a creatue with a faction
--@param factionID String. The faction ID
--@param amount Number. The amount to change the favor by
--@param display Boolean. If true, display text noting the favor change
--@param reason String. Display this text after
--@param track Boolean. If true, track this favor change for purposes of reputation increase
function Creature:update_favor(factionID,amount,display,reason,track)
  --If you're under player control, update player rep instead
  if self.master and self.master == player then
    return player:update_favor(factionID,amount,display,reason,track)
  end

  local faction = currWorld.factions[factionID]
  local member = self:is_faction_member(factionID)
  
  --If rep only applies to members of this faction, don't do anything
  if faction.members_only_favor and not member then
    return false
  end
  
  self.favor[factionID] = (self.favor[factionID] or 0) + amount
  if display and self == player and amount ~= 0 and faction.contacted and not faction.hidden then
    output:out("You " .. (amount > 0 and "gain " or "lose ") .. math.abs(amount) .. " favor with the " .. faction.name .. (reason and " for " .. reason or "") .. ".")
  end
  if track and faction.reputation_per_favor_spent and faction.reputation_per_favor_spent > 0 then
    faction.favor_spent = (faction.favor_spent or 0) + math.abs(amount)
    while faction.favor_spent >= faction.reputation_per_favor_spent do
      self:update_reputation(factionID,1,display)
      faction.favor_spent = faction.favor_spent - faction.reputation_per_favor_spent
    end
  end
end

function Creature:update_money(amt,silent)
  local initial_amt = amt
  if amt > 0 then
    if currGame.heist then
      local money = Item('money')
      money.amount = amt
      self:give_item(money,true)
    else
      self.money = self.money+amt
    end
  elseif amt < 0 then
    --subtract from money item first
    local money = self:has_item('money')
    while money and amt < 0 do
      local deleted_amt = math.min(math.abs(amt),money.amount)
      amt = amt + deleted_amt
      self:delete_item(money,deleted_amt,true)
      money = self:has_item('money')
    end
    if amt < 0 then
      self.money = self.money + amt
    end
  end
  --Add item popup:
  if amt ~= 0 and self == player and not silent then
    local money_item = possibleItems['money']
    local popup1 = Effect('dmgpopup')
    popup1.symbol = (initial_amt > 1 and "+" or "") .. initial_amt
    popup1.color = (initial_amt > 1 and {r=0,g=255,b=0,a=150} or {r=255,g=0,b=0,a=150})
    local tileMod = round(fonts.mapFontWithImages:getWidth(popup1.symbol)/2)
    popup1.xMod = -tileMod
    local popup2 = Effect('dmgpopup')
    popup2.image_name = (money_item and money_item.image_name or "money")
    popup2.imageType = "item"
    popup2.symbol = "$"
    popup2.xMod = tileMod
    popup2.speed = popup1.speed
    if money_item and (money_item.use_color_with_tiles ~= false or gamesettings.always_use_color_with_tiles) and money_item.color then
      popup2.color = {r=money_item.color.r,g=money_item.color.g,b=money_item.color.b,a=150}
    else
      popup2.color = {r=255,g=255,b=255,a=150}
    end
    popup1.paired = popup2
    popup2.paired = popup1
    popup2.itemId = "money"
    popup2.itemAmt = initial_amt
    currMap:add_effect(popup1,self.x,self.y)
    currMap:add_effect(popup2,self.x,self.y)
  end
  return true
end

---Checks if the creature has already noticed a creature. If not, see if they notice them now.
--@return Boolean. Whether the creature has noticed the target.
function Creature:does_notice(creat)
  if self == creat or self.notices[creat] then
    return true
  elseif not self.checked[creat] then
    self.checked[creat] = creat
    return self:can_notice(creat)
  end
  return false
end

---Checks if a creature is able to notice another, and sets them as noticed if yes
--@param creat Creature. The creature to try and notice
--@return Boolean. Whether the creature is able to notice the target
function Creature:can_notice(creat)
  if not self.x or not self.y or not creat.x or not creat.y then return false end --If something isn't on the map, you can't notice it
  if creat.baseType ~= "creature" then return true end
  local nTime = os.clock()
  --Creatures are more likely to notice others the closer they get
  local noticeChance = self:get_notice_chance()
  local stealth = creat:get_stealth()
  local dist = calc_distance(self.x,self.y,creat.x,creat.y)
  local distPerc = dist/self:get_perception()
  stealth = (stealth > 0 and stealth+math.ceil(stealth*distPerc) or stealth-math.floor((stealth*distPerc)/2)) -- positive stealth increases based on % of total perception distance, up to 2x. Negative stealth reduces based on % of total perception distance, up to 1/2
      
  if random(1,100) <= noticeChance-stealth and self:can_sense_creature(creat)  then
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
  if self.shitlist[creat] then self.shitlist[creat] = nil end
end

---Become hostile to another creature
--@param creat Creature. The creature to become hostile towards
--@param force. Boolean. Whether to force hostility, even if the callbacks return false (optional)
--@param silent Boolean. Whether to become hostile without playing a sound or displaying text(optional)
--@return Boolean. Whether the creature became hostile to the target.
function Creature:become_hostile(creat,force,silent)
  if self == player or not creat or creat.baseType ~= "creature" then return false end
  if self.shitlist[creat] then --if already hostile then just refresh alert status
    self.alert = self.memory
    return false
  end
  if force or (creat:callbacks('can_become_enemy',self) and self:callbacks('can_become_hostile',creat)) then
    creat:callbacks('become_enemy',self)
    self:callbacks('become_hostile',creat)
    if creat == player and player:can_see_tile(self.x,self.y) and self.shitlist[player] == nil and player:does_notice(creat) and player:can_sense_creature(creat) then
      local popup = Effect('dmgpopup')
      popup.image_name = "exclamation"
      currMap:add_effect(popup,self.x,self.y)
      if not silent then
        output:out(self:get_name() .. " becomes hostile!")
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
    if c ~= self and c.x > self.x-perc and c.x < self.x+perc and c.y > self.y-perc and c.y < self.y+perc and self:can_sense_creature(c)  then
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
      local xy = x .. "," .. y
      if (x>1 and y>1 and x<cW and y<cH) then
        local creat = currMap:get_tile_creature(x,y)
          if creat and self:is_enemy(creat) and self:can_sense_creature(creat) then
            lMap[xy] = 0
          else if self:can_move_to(x,y) == false then
            lMap[xy] = false
          else
            lMap[xy] = 10
          end
        end
      end --end range check
    end --end yfor
  end --end xfor
  
  local changed = true
  while (changed) do
    changed = false
    for x=sX-perc,sX+perc,1 do
      for y=sY-perc,sY+perc,1 do
        local xy = x .. "," .. y
        if (lMap[xy]) then
          local min = nil
          for ix=x-1,x+1,1 do
            for iy=y-1,y+1,1 do
              local ixy = ix .. "," .. iy
              if (ix>1 and iy>1 and ix<cW and iy<cH and lMap[ixy]) and (min == nil or lMap[ixy] < min) then
                min = lMap[ixy]
              end --end min if
            end --end yfor
          end --end xfor
          if (min and min+2 < lMap[xy]) then lMap[xy] = min+1 changed = true end
        end --end tile check
      end --end yfor
    end --end xfor
  end -- end while
  return lMap
end --end make_fear_map

---This function is run every tick and updates various things. You probably shouldn't call it yourself
--@param dt Number. The number of seconds since the last time update() was run. Most likely less than 1.
function Creature:update(dt) --for charging, and other special effects
  --profiler.reset()
  --profiler.start()
  if self == player and self.sees == nil then self.sees = self:get_seen_creatures() end --update player sees if for some reason they don't see anything
  --Delete tween if done moving:
  if self.doneMoving and self.xMod < 0.00001 and self.yMod < 0.00001 then
    self.doneMoving = nil
    if timers[tostring(self) .. 'moveTween'] then
      Timer.cancel(timers[tostring(self) .. 'moveTween'])
      timers[tostring(self) .. 'moveTween'] = nil
    end
    self.fromX,self.fromY=self.x,self.y
    self.xMod,self.yMod = 0,0
  end
  
  --Hearts for allies:
  if self.master == player and self ~= player then
    self.heartClock = (self.heartClock or 2) - dt
    if (self.heartClock <= 0 and random(1,5) == 1) then
      local heart = Effect('floater',{image_name="heart",symbol="<3",color={r=255,g=0,b=0}})
      currMap:add_effect(heart,self.x,self.y)
      self.heartClock = 2
    end
  end
  
  if (self.zoomTo ~= nil) then --handle charging, knockbacks and the like
    local oldX,oldY=self.x,self.y
    local originalZoomX,originalZoomY=self.zoomTo.x,self.zoomTo.y
    if (self.zoomLine == nil or #self.zoomLine == 0 or self.zoomLine[#self.zoomLine][1] ~= self.zoomTo.x or self.zoomLine[#self.zoomLine][2] ~= self.zoomTo.y) then
      --if we haven't made a zoomline yet, or the zoomline's target doesn't match the actual target's location anymore (ie a creature moved), make the zoomline
      self.zoomLine = currMap:get_line(self.x,self.y,self.zoomTo.x,self.zoomTo.y,false,self:get_pathType())
    end --end if line == nil
    if (self.zoomLine and #self.zoomLine > 0 and self:can_move_to(self.zoomLine[1][1],self.zoomLine[1][2],currMap,true) == true) and not currMap:get_blocking_feature(self.zoomLine[1][1],self.zoomLine[1][2]) then --if first spot in line an empty, go there
      self:moveTo(self.zoomLine[1][1],self.zoomLine[1][2],true)
			table.remove(self.zoomLine,1)
    elseif self.zoomLine and #self.zoomLine > 0 then --if you can't go to the next point in the line, handle collision:
      local c = currMap:get_tile_creature(self.zoomLine[1][1],self.zoomLine[1][2])
      if c and c ~= self then
        self.zoomTo = c --set the creature as your new target
      else
        self.zoomTo = {x=self.zoomLine[1][1],y=self.zoomLine[1][2]}
      end --set the square as your new target
      self.zoomLine = {{self.zoomTo.x,self.zoomTo.y}}
    end
    
    if (self.x == self.zoomTo.x and self.y == self.zoomTo.y and (self.xMod < .00001 or not self.xMod) and (self.yMod < .00001 or not self.yMod)) or ((self:can_move_to(self.zoomTo.x,self.zoomTo.y,currMap,true) == false or currMap:get_blocking_feature(self.zoomTo.x,self.zoomTo.y)) and (self:touching(self.zoomTo) or #self.zoomLine < 1 or not self.zoomLine)) then
      local dist_remaining = math.floor(calc_distance(self.x,self.y,originalZoomX,originalZoomY))
      if self.zoomResult then
        if type(self.zoomResult) == "string" then
          local result = Spell(self.zoomResult)
          result:use(self.zoomTo,self)
        elseif self.zoomResult.use then
          self.zoomResult:use(self.zoomTo,self) --if you're charging, do whatever is at the end of the charge
        end
      else --if you're not charging, get hurt and hurt whoever you ran into
        self:collide(self.zoomTo,dist_remaining)
      end -- end charging or not if
      self.zoomFrom = nil
      self.zoomTo = nil
      self.zoomLine = nil
      self.zoomResult = nil
      currMap:enter(self.x,self.y,self,oldX,oldY)
    end --end hit the end of the line
  elseif self.hp < 1 and (self ~= player or action ~="dying") then --If not zooming, check to see if you need to die (we don't do this while zooming to avoid awkwardness)
    self:die()
  end --end if self zoomto

  for condition, info in pairs(self.conditions) do --for special effects like glowing, shaking, whatever
		if (conditions[condition].update ~= nil) then conditions[condition]:update(self,dt) end
  end -- end for
  
  if self.animated and prefs['creatureAnimations'] and not prefs['noImages'] and (self.animateSleep or not self:has_condition('asleep')) and player:does_notice(self) and player:can_sense_creature(self) then
    self.animCountdown = (self.animCountdown or 0) - dt
    if self.animCountdown < 0 then
      local imageNum = nil
      local currNum = self.image_frame
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
      self.image_frame = imageNum
      if not self.spritesheet then
        local image_base = (self.image_base or (possibleMonsters[self.id].image_name or self.id))
        self.image_name = image_base .. self.image_frame
      end
      --Change the light color, if necessary
      if self.lightColors then
        self.lightColor = self.lightColors[imageNum]
        currMap:refresh_light(self)
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
  --profiler.stop()
  --print(profiler.report(10))
end --end function

---Collide with another creature or object
--@param target Entity or coordinates. The entity or coordinates collided with
--@param dist Number. The distance still remaining in the knockback prior to collision
function Creature:collide(target,dist)
  local dmg = dist*2
  if target and target.x and target.y and currMap:isWall(target.x,target.y) then
    local dmg = self:damage(tweak(dmg),self.lastAttacker) --get damaged
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
        local dmg = self:damage(tweak(dmg),self.lastAttacker) --get damaged
        if f.baseType == "creature" or f.attackable then
          local tdmg = f:damage(tweak(dmg),self.lastAttacker or self) --damage creature you hit
          if player:can_see_tile(self.x,self.y) then
            output:out(self:get_name() .. " slams into " .. f:get_name() .. ", taking " .. dmg .. " damage. " .. (tdmg and ucfirst(f:get_name()) .. " takes " .. tdmg .. " damage." or ""))
            if f.baseType == "creature" then
              output:sound('collision_creature')
            else
              output:sound('collision_wall')
            end
          end
          if f.hp and f.hp <= 0 and dist > 2 then
            f.explosiveDeath = true
          elseif random(1,10) < dist*2 then --chance of knockback increases if the hitter was farther away
            local knockback = random(1,math.floor(dist))
            if knockback > 0 and f.baseType == "creature" then f:give_condition('knockback',knockback,self) end
          end --end hp if
        else
          if player:can_see_tile(self.x,self.y) then
            output:out(self:get_name() .. " slams into the " .. f.name .. ", taking " .. dmg .. " damage!")
            output:sound('collision_wall')
          end
         end --end feature vs. creature if
        if self.hp <= 0 and dist > 2 then self.explosiveDeath = true end
        break
      end --end blocks movement if
    end --end feature for
  end --end wall if
end

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
  local perc = self.perception or 1
  perc = perc + round(perc*(self:get_bonus('perception_percent')/100)) + self:get_bonus('perception')
  return perc
end

---Gets the threat level of a given creature
function Creature:get_threat()
  local base = self.threat
  if base and gamesettings.creature_threat_definitions and gamesettings.creature_threat_definitions[base] then
    base = gamesettings.creature_threat_definitions[base]
  end
  if not base or type(base) ~= "number" then
    base = gamesettings.default_creature_threat or 1
  end
  local level_threat = (self.level or 1)*(self.threat_per_level or gamesettings.creature_threat_per_level or 0)
  local per_level = (self.threat_per_level_difference or gamesettings.creature_threat_per_level_difference or self.threat_per_level or gamesettings.creature_threat_per_level)
  if player and player.level and per_level then
    level_threat = level_threat + (self.level - player.level)*per_level
  end
  local threat = base + level_threat
  if self.inventory then
    for _,item in ipairs(self:get_inventory()) do
      threat = threat + item:get_threat()
    end
  end
  if self.get_bonus then --This is to ensure that this is a substantiated creature, rather than get_threat() being called on a creature definition
    threat = threat + round(threat * (self:get_bonus('threat_percent')/100)) + self:get_bonus('threat')
  end
  if base > 0 and threat < 0 then --Only become a negative threat if you begin as a negative threat
    threat = 1
  end
  return threat
end

---Makes a creature fly through the air to a target
--@param target Table. A table containing at least an x and y index. Can be a creature, a feature, or just a table with nothing but x and y.
--@param result Spell. What spell to use after the zoom is done. A spell object itself, not the ID (optional)
function Creature:flyTo(target,result)
  self.zoomFrom = {x=self.x,y=self.y}
  self.zoomTo = target --make the creature fly to the target
  --Make them fly through the air
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
      pop.color={r=255,g=0,b=0,a=255}
      pop.image_name = "heart"
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
  if gamesettings.xp then
    local gain = xp
    local mod = 0.1*self:get_bonus('xp_percent')
    gain = gain + math.ceil(gain * mod)
    self.xp = self.xp+gain
    while self.xp >= self:get_level_up_cost() and gamesettings.leveling do
      self:level_up()
      if self == player then
        output:out("You are now level " .. self.level .. "!")
        --TODO: add an effect?
      end
    end
  end
end

---How much XP do you need to level up? *MAY WANT TO CHANGE FOR YOUR OWN GAME*
--@return Number. The XP required to level up
function Creature:get_level_up_cost()
  return self.level*10
end

---Level Up, granting stat points (for players), or randomly increasing stats (for NPCs)
--@param force Boolean. Whether or not to ignore XP costs
--@param ignore_callback Boolean. Whether to ignore level_up callbacks
function Creature:level_up(force,ignore_callback)
  local cost = self:get_level_up_cost()
  if not ignore_callback then
    local leveled = self:callbacks('level_up',self.level+1)
    if leveled == false then return false end
  end
  if not force then 
    if self.xp < cost then return false end
    self.xp = self.xp - cost
  end
  self.level = self.level + 1
  --Do stats per level:
  local stat_increases = self:get_stat_increases_for_level(self.level)
  for stat_id,value in pairs(stat_increases) do
    self[stat_id] = (self[stat_id] or 0)+value
    if stat_id == "max_hp" then
      self.hp = self.hp+value
    elseif stat_id == "max_mp" then
      self.mp = self.mp+value
    end
  end
  local skill_increases = self:get_skill_increases_for_level(self.level)
  for skill_id,value in pairs(skill_increases) do
    self:upgrade_skill(skill_id,value,true)
  end
  --If an NPC, or the player has autoleveling turned on, then apply stats randomly:
  if self ~= player or prefs.autoLevel then
    --Upgrade skills:
    local upgradable_skills_by_upgrade_stat = self:get_upgradable_skills(true)
    local tries = 0
    while count(upgradable_skills_by_upgrade_stat) > 0 and tries < 10 do
      tries = tries+1
      for pointID,skillList in pairs(upgradable_skills_by_upgrade_stat) do
        local points = self[pointID] or 0
        local tries2 = 0
        while points > 0 and tries2 < 10 do
          tries2=tries2+1
          local skillID = get_random_element(skillList)
          if self:can_upgrade_skill(skillID) then
            self:upgrade_skill(skillID)
            points = self[pointID] or 0
          end --end upgradable if
        end --end points for
      end --end pointID for
      upgradable_skills_by_upgrade_stat = self:get_upgradable_skills(true)
    end --end while
    
    --Upgrade spells:
    if self.spellPoints and self.spellPoints > 0 then
      local upgradable_spells = {}
      for id,spell in ipairs(self:get_spells(true)) do
        local upgrades = spell:get_possible_upgrades(true)
        if count(upgrades) > 0 then
          upgradable_spells[#upgradable_spells+1] = spell
        end
      end
      if #upgradable_spells > 0 then
        local tries = 0
        while tries < 100 and self.spellPoints > 0 do
          tries = tries + 1
          local spell = get_random_element(upgradable_spells)
          local upgrades = spell:get_possible_upgrades(true)
          if count(upgrades) > 0 then --upgrades may no longer be possible because we applied some already
            local up_id = get_random_key(upgrades)
            local up_level = upgrades[up_id]
            spell:apply_upgrade(up_id,up_level)
          end -- end #upgrades > 0
        end --end spellpoints do
      end --end upgradable_spells if
    end --end self.spellpoints > 0 if
  end
  --Increase extra stats that are part of this creature
  if self.extra_stats then
    for stat_id,stat in pairs(self.extra_stats) do
      if stat.increase_per_level then
        if stat.max then
          stat.max = stat.max+stat.increase_per_level
        else
          stat = stat+stat.increase_per_level
        end
      end
    end
  end
  --Learn spells, if applicable:
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
  if self.learns_random_spells then
    self:learn_random_spells()
  end
  --Heal, if heal on level up is set
  if gamesettings.heal_on_level_up then
    self.hp = self:get_max_hp()
    self.mp = self:get_max_mp()
  end
end

---Learns random spells based on spells this creature is capable of learning. Used for NPCs
function Creature:learn_random_spells()
  --Add spells:
  local slots = self:get_free_spell_slots()
  if not slots or slots == 0 then return false end
  
  --Make a list of learnable spells:
  local learnable_base = self:get_purchasable_spells()
  local learnable_spells = {}
  local recommended_spells = {}
  for _,spellInfo in pairs(learnable_base) do
    local spellID = spellInfo.spell
    learnable_spells[spellID] = spellID
    if possibleSpells[spellID].recommended then
      recommended_spells[#recommended_spells+1] = spellID
    end
  end
  
  --First, add a recommended spell from the list if you don't know any spells:
  if count(self.known_spells) == 0 and count(recommended_spells) > 0 then
    shuffle(recommended_spells)
    for _,spellID in ipairs(recommended_spells) do
      if not self:has_spell(spellID,true,true) then
        self:learn_spell(spellID)
        learnable_spells[spellID] = nil
        slots = self:get_free_spell_slots()
        break
      end
    end
  end
  
  --Next, add random spells:
  local whilecount = 0
  while slots > 0 and whilecount < 100 and count(learnable_spells) > 0 do
    local spellID = get_random_element(learnable_spells)
    if self:has_spell(spellID,true,true) then
      learnable_spells[spellID] = nil
    else
      self:learn_spell(spellID)
      slots = self:get_free_spell_slots()
      learnable_spells[spellID] = nil
    end
    whilecount = whilecount+1
  end
end

---Get a list of what the stat increase will be for a given level
--@param level Number. The level to look at the stat increases for
--@return Table. A list of stats and increases in the format {stat=1}
function Creature:get_stat_increases_for_level(level)
  local statInc = {}
  if self.stats_per_level then
    for stat_id,value in pairs(self.stats_per_level) do
      statInc[stat_id] = (statInc[stat_id] or 0)+value
    end
  end --end stats_per_level
  if gamesettings.stats_per_level then
    for stat_id,value in pairs(gamesettings.stats_per_level) do
      statInc[stat_id] = (statInc[stat_id] or 0)+value
    end
  end --end gamesettings stats_per_level
  if self.stats_at_level and self.stats_at_level[self.level] then
    for stat_id,value in pairs(self.stats_at_level[self.level]) do
      statInc[stat_id] = (statInc[stat_id] or 0)+value
    end
  end --end stats_at_level
  if gamesettings.stats_at_level and gamesettings.stats_at_level[self.level] then
    for stat_id,value in pairs(gamesettings.stats_at_level[self.level]) do
      statInc[stat_id] = (statInc[stat_id] or 0)+value
    end
  end --end gamesettings stats_at_level
  if self.stats_per_x_levels then
    for lvl,stats in pairs(self.stats_per_x_levels) do
      if level % lvl == 0 then
        for stat_id,value in pairs(stats) do
          statInc[stat_id] = (statInc[stat_id] or 0)+value
        end
      end
    end
  end --end if stats_per_x_levels
  if gamesettings.stats_per_x_levels then
    for lvl,stats in pairs(gamesettings.stats_per_x_levels) do
      if level % lvl == 0 then
        for stat_id,value in pairs(stats) do
          statInc[stat_id] = (statInc[stat_id] or 0)+value
        end
      end
    end
  end --end if gamesettings stats_per_x_levels
  return statInc
end

---Get a list of what the skill increase will be for a given level
--@param level Number. The level to look at the stat increases for
--@return Table. A list of stats and increases in the format {stat=1}
function Creature:get_skill_increases_for_level(level)
  local skillInc = {}
  if self.skills_per_level then
    for skill_id,value in pairs(self.skills_per_level) do
      skillInc[skill_id] = (skillInc[skill_id] or 0)+value
    end
  end --end skills_per_level
  if gamesettings.skills_per_level then
    for skill_id,value in pairs(gamesettings.skills_per_level) do
      skillInc[skill_id] = (skillInc[skill_id] or 0)+value
    end
  end --end gamesettings skills_per_level
  if self.skills_at_level and self.skills_at_level[self.level] then
    for skill_id,value in pairs(self.skills_at_level[self.level]) do
      skillInc[skill_id] = (skillInc[skill_id] or 0)+value
    end
  end --end skills_at_level
  if gamesettings.skills_at_level and gamesettings.skills_at_level[self.level] then
    for skill_id,value in pairs(gamesettings.skills_at_level[self.level]) do
      skillInc[skill_id] = (skillInc[skill_id] or 0)+value
    end
  end --end gamesettings skills_at_level
  if self.skills_per_x_levels then
    for lvl,skills in pairs(self.skills_per_x_levels) do
      if level % lvl == 0 then
        for skill_id,value in pairs(skills) do
          skillInc[skill_id] = (skillInc[skill_id] or 0)+value
        end
      end
    end
  end --end if skills_per_x_levels
  if gamesettings.skills_per_x_levels then
    for lvl,skills in pairs(gamesettings.skills_per_x_levels) do
      if level % lvl == 0 then
        for skill_id,value in pairs(skills) do
          skillInc[skill_id] = (skillInc[skill_id] or 0)+value
        end
      end
    end
  end --end if gamesettings skills_per_x_levels
  return skillInc
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
    elseif self:is_friend(creat) then
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
--@param damage_stats Table. A table of stats and skills that increase damage in the format stat=amt_per_level
--@return Number. The damage value
function Creature:get_damage(damage_stats)
  local stats = damage_stats or self.melee_damage_stats or gamesettings.default_melee_damage_stats
  local dmg = 0
  if stats then
    for stat,mod in pairs(stats) do
      dmg = dmg + mod*(self:get_stat(stat))
    end --end stat for
  end --end if stats
  dmg = dmg + round(dmg * (self:get_bonus('damage_percent')/100)) + self:get_bonus('damage')
  return dmg 
end

---Gets the total of a creature's melee accuracy stats, including bonuses
--@param damage_stats Table. A table of stats and skills that increase damage in the format stat=amt_per_level
--@return Number. The damage value
function Creature:get_melee_accuracy(accuracy_stats)
  local stats = accuracy_stats or self.melee_accuracy_stats or gamesettings.default_melee_accuracy_stats
  local hit_mod = 0
  if stats then
    for stat,mod in pairs(stats) do
      hit_mod = hit_mod + mod*(self:get_stat(stat))
    end --end stat for
  end --end if stats
  return hit_mod
end

---Gets the creature's damage value, including bonuses
--@param damage_stats Table. A table of stats and skills that increase damage in the format stat=amt_per_level
--@return Number. The damage value
function Creature:get_ranged_damage(damage_stats)
  local stats = damage_stats or self.ranged_damage_stats or gamesettings.default_ranged_damage_stats
  local dmg = 0
  if stats then
    for stat,mod in pairs(stats) do
      dmg = dmg + mod*(self:get_stat(stat))
    end --end stat for
  end --end if stats
  dmg = dmg + round(dmg * (self:get_bonus('ranged_damage_percent')/100)) + self:get_bonus('ranged_damage')
  return dmg
end

---Gets the total of a creature's melee accuracy stats, including bonuses
--@param damage_stats Table. A table of stats and skills that increase damage in the format stat=amt_per_level
--@return Number. The damage value
function Creature:get_ranged_accuracy(accuracy_stats)
  local stats = accuracy_stats or self.ranged_accuracy_stats or gamesettings.default_ranged_accuracy_stats
  local hit_mod = 0
  if stats then
    for stat,mod in pairs(stats) do
      hit_mod = hit_mod + mod*(self:get_stat(stat))
    end --end stat for
  end --end if stats
  return hit_mod
end

---Gets the creature's dodge stat values, including bonuses
--@param damage_stats Table. A table of stats and skills that increase dodge in the format stat=amt_per_level
--@return Number. The damage value
function Creature:get_dodging(dodge_stats)
  local stats = dodge_stats or self.dodge_stats or gamesettings.default_dodge_stats
  local dodge = 0
  if stats then
    for stat,mod in pairs(stats) do
      dodge = dodge + mod*(self:get_stat(stat))
    end --end stat for
  end --end if stats
  return dodge
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

---Gets the creature's pathType, set in the creature definition or in the 
function Creature:get_pathType()
  local pathType = self.pathType
  for conID,_ in pairs(self.conditions) do
    if conditions[conID].applies_pathType then
      pathType = conditions[conID].applies_pathType
    end
  end
  for _,spell in pairs(self.spells) do
    if spell.applies_pathType then
      pathType = spell.applies_pathType
    end
  end
  return pathType
end

---A generic function for getting a stat and its bonus. Looks at base stats first, then extra_stats, then skills
--@param stat Text. The stat to get
--@param noBonus Boolean. If true, don't add the bonus to the stat
--@return Number. The stat value
function Creature:get_stat(stat,noBonus)
  local base = self[stat] or (self.extra_stats[stat] and self.extra_stats[stat].value)
  if not base and self.skills[stat] then return self:get_skill(stat,noBonus) end
  base = base or 0
  
  if not noBonus and type(base) == "number" then
    local percBonus = round(base*(self:get_bonus(stat .. '_percent')/100))
    base = base + percBonus + self:get_bonus(stat)
  end
  return base
end

---Returns a list of all the skills a creature has
--@param noBonus
--@return Table. A list of all skills in the format skillID=value
function Creature:get_skills(noBonus)
  if noBonus then return self.skills end
  local skills ={}
  for skillID, val in pairs(self.skills) do
    skills[skillID] = self:get_skill(skillID)
  end
  return skills
end

---Returns a list of all upgradable skills a creature has, and the points required
--@param sorted_by_stat Boolean. If true, the table will return in the format {upgrade_stat1={skill1,skill2},upgradestat2={skill3,skill4}}. If false, it will just return a flat list of skills
--@return Table. A list of all skills in the format skillID=upgrade_stat
function Creature:get_upgradable_skills(sorted_by_stat)
  local skills = {}
  local sorted = {}
  for skillID,val in pairs(self.skills) do
    if val ~= false then
      if self:can_upgrade_skill(skillID) then
        local skill = possibleSkills[skillID]
        local sType = skill.skill_type or "skill"
        local typeDef = possibleSkillTypes[sType]
        local pointID = skill.upgrade_stat or (typeDef and typeDef.upgrade_stat) or "upgrade_points_" .. sType
        local points = self[pointID] or 0
        if points > 0 then
          skills[#skills+1] = skillID
          if sorted_by_stat then
            if not sorted[pointID] then sorted[pointID] = {} end
            sorted[pointID][#sorted[pointID]+1] = skillID
          end --end sorted by stat if
        end --end if points > 0
      end --end only_unmaxed if
    end --end not false if
  end --end skill for
  if sorted_by_stat then return sorted else return skills end
end

---A generic function for getting a skill and its bonus
--@param stat Text. The skill to get
--@param noBonus Boolean. If true, don't add the bonus to the stat
--@return Number. The stat value
function Creature:get_skill(skill,noBonus)
  if not self.skills[skill] then return 0 end
  local val = self.skills[skill] or 0
  if not noBonus then
    local percBonus = round(val*(self:get_bonus(skill .. '_percent')/100))
    val = val + percBonus + self:get_bonus(skill)
  end
  local skillDef = possibleSkills[skill]
  if skillDef and skillDef.max and val > skillDef.max then val = skillDef.max end
  return val
end

---Returns whether or not the creature has enough points to upgrade the skill
--@param skill Text. The ID of the skill
--@param ignore_cost Boolean. If true, just check non-cost requirements
--@return Boolean. Whether the skill is upgradable or not
function Creature:can_upgrade_skill(skillID,ignore_cost)
  local currVal = self.skills[skillID]
  local skill = possibleSkills[skillID]
  if skill.max and currVal and currVal+1 > skill.max then
    return false
  end
  if currVal == false then
    return false
  elseif not currVal then
    currVal = 0
  end
  if skill.upgrade_requires then
    local ret,text = skill:upgrade_requires(self)
    if ret == false then return false,text end
  end
  
  --Check required skills:
  if skill.requires_skills then
    for skill,val in pairs(skill.requires_skills) do
      if not self.skills[skill] or self.skills[skill] < val then
        return false
      end
    end
  end
  
  --Check costs:
  if not ignore_cost then
    local cost = self:get_skill_upgrade_cost(skillID)
    if cost.point_cost then
      local sType = skill.skill_type or "skill"
      local typeDef = possibleSkillTypes[sType]
      local pointID = skill.upgrade_stat or (typeDef and typeDef.upgrade_stat) or "upgrade_points_" .. sType
      local points = self[pointID] or 0
      if points < cost.point_cost then
        return false
      end
    end
      
    if cost.item_cost then
      for _,item_details in pairs(cost.item_cost) do
        local amount = (item_details.amount or 1)
        local sortByVal = item_details.sortBy
        local has,_,has_amt = self:has_item(item_details.item,sortByVal)
        if not has or has_amt < amount then 
          return false
        end
      end --end item details for
    end --end cost.item_cost if
  end --end if not ignore costs
  return true
end

---Changes the skill value
--@param skillID Text. The ID of the skill
--@param val Number. The amount to change the skill by, defaults to 1
--@param ignore_cost Boolean. If true, don't pay the cost of the upgrade
function Creature:upgrade_skill(skillID,val,ignore_cost)
  val = val or 1
  local currVal = self.skills[skillID]
  if currVal == false then
    return
  elseif not currVal then
    currVal = 0
  end
  local skillDef = possibleSkills[skillID]
  if not skillDef then
    output:out("Error: Tried to update nonexistent skill " .. skillID)
    print("Error: Tried to update nonexistent skill " .. skillID)
    return false
  end
  local sType = skillDef.skill_type or "skill"
  local typeDef = possibleSkillTypes[sType]

  --Remove points and items:
  if val > 0 then
    for i = 1,val,1 do
      if not self:can_upgrade_skill(skillID,ignore_cost) then
        return false
      end
      if not ignore_cost then
        local cost = self:get_skill_upgrade_cost(skillID,val)
        if cost.point_cost then
          local sType = skillDef.skill_type or "skill"
          local typeDef = possibleSkillTypes[sType]
          local pointID = skillDef.upgrade_stat or (typeDef and typeDef.upgrade_stat) or "upgrade_points_" .. sType
          self[pointID] = self[pointID] - cost.point_cost
        end
          
        if cost.item_cost then
          for _,item_details in pairs(cost.item_cost) do
            local amount = (item_details.amount or 1)
            local sortByVal = item_details.sortBy
            local item = self:has_item(item_details.item,sortByVal)
            self:delete_item(item,amount)
          end --end item details for
        end --end cost.item_cost if
      end --end costs
    end
  end --end if val > 0
  
  self.bonus_cache = {} --in case the skill increases boosts
  
  val = val*(skillDef.increase_per_point or 1)
  local newValue = currVal + val
  if newValue < 0 then newValue = 0 end
  if currVal == newValue then return end
  local mod = (val > 0 and 1 or -1)
  if skillDef and (not skillDef.max or currVal < skillDef.max) and val ~= 0 then
    --Custom level up code:
    if skillDef.upgrade then
      local result = skillDef:upgrade(self,val,newValue)
      if result == false then return false end
    end
    --Do the skill increase:
    if skillDef.max and newValue > skillDef.max then newValue = skillDef.max end
    self.skills[skillID] = newValue
    
    --Grant stat changes
    local statInc = {}
    if skillDef.stats_per_level then
      for stat_id,value in pairs(skillDef.stats_per_level) do
        statInc[stat_id] = (statInc[stat_id] or 0)+(value*val)
      end
    end
    local checkStart = currVal+(mod > 0 and 1 or 0) --if going negative, you want to check the level you're at and unapply it
    local checkEnd = newValue+(mod > 0 and 0 or 1) --if going negative, you don't want to check the level you're ending at
    for level = checkStart,checkEnd,mod do
      if skillDef.stats_at_level and skillDef.stats_at_level[level] then
        for stat_id,value in pairs(skillDef.stats_at_level[level]) do
          statInc[stat_id] = (statInc[stat_id] or 0)+(val > 0 and value or -value)
        end
      end --end stats_at_level
      if skillDef.stats_per_x_levels then
        for lvl,stats in pairs(skillDef.stats_per_x_levels) do
          if level % lvl == 0 then
            for stat_id,value in pairs(stats) do
              statInc[stat_id] = (statInc[stat_id] or 0)+(val > 0 and value or -value)
            end
          end
        end
      end --end if stats_per_x_levels
    end
    for stat,mod in pairs(statInc) do
      self[stat] = (self[stat] or 0) + mod
    end
    --Grant spells:
    if skillDef.learns_spells then
      for _,info in pairs(skillDef.learns_spells) do
        if (not info.level or (info.level > currVal and info.level <= newValue) or (info.level < currVal and info.level >= newValue)) and self:can_learn_spell(info.spell) then
          self:learn_spell(info.spell)
        end
      end
    end --end if learns_spells
    return true
  end
  return false
end

---Returns the cost to upgrade a skill by a given amount
--@param skillID. String. The skill ID to check
--@param Table. A table. Will potentially have two entries: points for skill points used, and items, a table of items with the format {item=itemID,sortBy="text",amount=1,displayName="text"}
function Creature:get_skill_upgrade_cost(skillID)
  local cost = {}

  local currVal = self:get_skill(skillID,true)
  local newVal = currVal+1
  local skill = possibleSkills[skillID]
  --Check points:
  local sType = skill.skill_type or "skill"
  local typeDef = possibleSkillTypes[sType]
  local pointID = skill.upgrade_stat or (typeDef and typeDef.upgrade_stat) or "upgrade_points_" .. sType
  
  local point_cost = skill.point_cost or (typeDef and typeDef.point_cost or nil)
  local learn_point_cost = skill.learn_point_cost or (typeDef and typeDef.learn_point_cost or nil)
  local learn_point_cost_increase_per_skill = skill.learn_point_cost_increase_per_skill or (typeDef and typeDef.learn_point_cost_increase_per_skill or nil)
  local point_cost_increase_per_level = skill.point_cost_increase_per_level or (typeDef and typeDef.point_cost_increase_per_level or nil)
  local point_cost_increase_at_level = skill.point_cost_increase_at_level or (typeDef and typeDef.point_cost_increase_at_level or nil)
  local point_cost_increase_per_x_levels = skill.point_cost_increase_per_x_levels or (typeDef and typeDef.point_cost_increase_per_x_levels or nil)
  
  local skills_known = 0
  for skID,_ in pairs(self.skills) do
    if possibleSkills[skID] and possibleSkills[skID].skill_type == sType then
      skills_known = skills_known+1
    end
  end
  
  local points = 0
  local level_cost = 0
  if currVal == 0 and learn_point_cost then
    points = points + learn_point_cost
  else
    if point_cost then
      points = points + point_cost
    end
    if point_cost_increase_per_level then
      level_cost = level_cost + point_cost_increase_per_level*newVal
    end
    if point_cost_increase_at_level then
      for lvl,amt in pairs(point_cost_increase_at_level) do
        if newVal >= lvl then
          level_cost = level_cost+amt
        end
      end
    end
    if point_cost_increase_per_x_levels then
      for lvl,amt in pairs(point_cost_increase_per_x_levels) do
        level_cost = level_cost + (math.floor(newVal/lvl)*amt)
      end
    end
    if level_cost == 0 and not point_cost then --If no point cost values are set anywhere, default to 1
      level_cost = 1
    end
    points = points + level_cost
  end --end learn cost if
  if currVal == 0 and learn_point_cost_increase_per_skill and sType then
    points = points + learn_point_cost_increase_per_skill*skills_known
  end
  if points > 0 then
    cost.point_cost = points
    cost.upgrade_stat = pointID
    cost.upgrade_stat_name = skill.upgrade_stat_name
    if not cost.upgrade_stat_name then
      for _,stInfo in pairs(possibleSkillTypes) do
        if stInfo.upgrade_stat == pointID then
          cost.upgrade_stat_name = stInfo.upgrade_stat_name
          break
        end
      end
    end
    if not cost.upgrade_stat_name then
      cost.upgrade_stat_name = "point"
    end
    cost.upgrade_stat_plural_name = (skill.upgrade_stat_plural_name or cost.upgrade_stat_name) .. "s"
  end

  --Check items:
  local item_cost = skill.item_cost or (typeDef and typeDef.item_cost or nil)
  local learn_item_cost = skill.learn_item_cost or (typeDef and typeDef.learn_item_cost or nil)
  if currVal == 0 and learn_item_cost then
    if not cost.item_cost then cost.item_cost = {} end
    for _,item_details in ipairs(learn_item_cost) do
      local amount = (item_details.amount or 1)
      local index = item_details.item .. (item_details.sortBy or "")
      cost.item_cost[index] = {item=item_details.item,sortBy=item_details.sortBy,amount=amount,displayName=item_details.displayName}
      if item_details.learn_cost_increase_per_skill then
        cost.item_cost[index].amount = cost.item_cost[index].amount + (item_details.learn_cost_increase_per_skill*skills_known)
      end
    end --end item cost for
  elseif item_cost then
    if not cost.item_cost then cost.item_cost = {} end
    for _,item_details in ipairs(item_cost) do
      local amount = item_details.amount or 0
      local cost_increase_per_level = item_details.cost_increase_per_level
      local cost_increase_at_level = item_details.cost_increase_at_level
      local cost_increase_per_x_levels = item_details.cost_increase_per_x_levels
      
      if cost_increase_per_level then
        amount = amount + cost_increase_per_level*newVal
      end
      if cost_increase_at_level then
        for lvl,amt in pairs(cost_increase_at_level) do
          if newVal >= lvl then
            amount = amount+amt
          end
        end
      end
      if cost_increase_per_x_levels then
        for lvl,amt in pairs(cost_increase_per_x_levels) do
          amount = amount + (math.floor(newVal/lvl)*amt)
        end
      end
      
      if amount == 0 and not item_details.amount then
        amount = 1
      end
      if currVal == 0 and item_details.learn_cost_increase_per_skill then
        amount = amount + (item_details.learn_cost_increase_per_skill*skills_known)
      end
      local index = item_details.item .. (item_details.sortBy or "")
      cost.item_cost[index] = {item=item_details.item,sortBy=item_details.sortBy,amount=amount,displayName=item_details.displayName}
    end --end item cost for
  end
  
  return cost
end

---A generic function for getting an extra stat and its bonuses
--@param stat Text. The stat to get
--@param noBonus Boolean. If true, don't add the bonus to the stat
--@return Number. The stat value
function Creature:get_extra_stat(stat,noBonus)
  local value = (self.extra_stats[stat] and self.extra_stats[stat].value or 0)
  local max = self:get_extra_stat_max(stat)
  if not noBonus then
    value = value + round(value*(self:get_bonus(stat .. '_percent')/100))
    value = value + self:get_bonus(stat)
  end
  if max and value > max then
    value = max
  end
  return value
end

---A generic function for getting the max for an extra stat, if applicable
--@param stat Text. The stat to get
--@param noBonus Boolean. If true, don't add the bonus to the stat
--@return Number. The stat value
function Creature:get_extra_stat_max(stat,noBonus)
  local max = self.extra_stats[stat].max
  if not max then return false end
  if not noBonus then
    max = max + round(max*(self:get_bonus(stat .. '_max_percent')/100))
    max = max + self:get_bonus(stat .. '_max')
  end
  return max
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
  local max = self:get_extra_stat_max(stat)
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
  if noEquip or count(self.equipment_list) == 0 then
    return self.spells
  end
  local spells = {}
  for _, equip in pairs(self.equipment_list) do
    if equip.spells_granted then
     for _, spell in ipairs(equip.spells_granted) do
      spells[#spells+1] = spell
     end
    end --end bonuses if
  end --end equipment for
  if #spells == 0 then
    return self.spells
  end
  return merge_tables(self.spells,spells)
end


---Gets a list of spells in spells_known but not in spells
--@return Table. A list of creature's unmemorized spells
function Creature:get_unmemorized_spells()
  local spells ={}
  for _,spell in ipairs(self.spells_known) do
    if not self:has_spell(spell.id,true) then
      spells[#spells+1] = spell
    end
  end
  return spells
end

---Checks if the creature possesses a certain spell
--@param spellName String. The name of the spell
--@param noEquip Boolean. If true, ignore spells granted by equipment
--@param included_unmemorized Boolean. If true, also look in the spells_known table
--@return Number or Boolean. Either the index of the spell in the caster's "spellbook," or false if they don't know it
--@return Spell or nil. The spell itself
function Creature:has_spell(spellID,noEquip,included_unmemorized)
  for index,spell in ipairs(self:get_spells(noEquip)) do
    if spell.id == spellID then return index,spell end
  end
  if included_unmemorized then
    for index,spell in ipairs(self.spells_known) do
      if spell.id == spellID then return index,spell end
    end
  end
  return false
end

---Add a spell to a creature's spell list
--@param spellID Text. The ID of the spell to learn
--@param force Boolean. Ignore spell requirements
function Creature:learn_spell(spellID,force)
  if not self:has_spell(spellID,true,true) then
    local newSpell = Spell(spellID)
    if newSpell then
      if not force then
        local ret,text = self:can_learn_spell(spellID)
        if ret == false then
          return false,text
        end
      end
      self.spells_known[#self.spells_known+1] = newSpell
      newSpell.possessor = self
      local slots = self:get_free_spell_slots()
      if not slots or slots > 0 or newSpell.forgettable == false or newSpell.freeSlot then
        self:memorize_spell(newSpell)
      end
      if newSpell.max_charges then
        newSpell.charges = newSpell:get_stat('max_charges')
      end
      return newSpell
    else
      output:out("Error: Creature " .. self.name .. " tried to learn non-existent spell " .. spellID)
      print("Error: Creature " .. self.name .. " tried to learn non-existent spell " .. spellID)
    end
  end
end

---Remove a spell from a creature's spell "inventory"
--@param spell Spell. The spell to forget
--@param force Boolean. If true, remove the spell even if it's normally not supposed to be forgettable
function Creature:unmemorize_spell(spell,force)
  local spellID = spell.id
  local index = self:has_spell(spellID,true)
  if spell and index and (force or spell.forgettable or (gamesettings.spells_forgettable_by_default and spell.forgettable ~= false)) then
    table.remove(self.spells,index)
    for hkid,hkinfo in pairs(self.hotkeys) do
      if hkinfo.type == "spell" and hkinfo.hotkeyItem == spell then
        self.hotkeys[hkid] = nil
        spell.hotkey = nil
      end
    end
  end
end

---Add a spell to a creature's spell "inventory"
--@param spell Spell. The spell to memorize
--@param force Boolean. If true, add the spell even if it overfills the slots
function Creature:memorize_spell(spell,force)
  local spellID = spell.id
  local index = self:has_spell(spellID,true,true)
  local slots = self:get_free_spell_slots()
  if spell and index and not self:has_spell(spellID,true) and (force or spell.freeSlot or spell.forgettable == false or (not slots or slots > 0)) then
    self.spells[#self.spells+1] = spell
    if self.hotkeys and spell.target_type ~= "passive" then
      for i=1,10,1 do
        if not self.hotkeys[i] then
          self.hotkeys[i] = {type="spell",hotkeyItem=spell}
          spell.hotkey=i
          break
        end
      end
    end --end hotkey if
  end
end

---Determine if a creature can learn this spell or not
--@param spellID Text. The ID of the spell to check
--@return Boolean. Whether or not it can be learned
--@return Text. The reason it can't be learned (or nil if it can)
function Creature:can_learn_spell(spellID)
  local spell = possibleSpells[spellID]
  if not spell then return false end
  --Check if you already have it:
  if self:has_spell(spellID,true,true) then
    return false,"You already know this spell."
  end
  if self ~= player and spell.player_only then
    return false
  end
  --Check level:
  if spell.level_requirement and self.level < spell.level_requirement then
    return false,"You're not a high enough level to learn this ability."
  end
  --Check stats:
  if spell.stat_requirements then
    for stat,requirement in pairs(spell.stat_requirements) do
      if self:get_stat(stat,true) < requirement then
        return false,"Your " .. stat .. " stat is too low to learn this ability."
      end
    end
  end
  --Check skills:
  if spell.skill_requirements then
    for skill,requirement in pairs(spell.skill_requirements) do
      if self:get_skill(skill,true) < requirement then
        return false,"Your " .. skill .. " skill is too low to learn this ability."
      end
    end
  end
  --Check spell tags:
  if self.forbidden_spell_types and count(self.forbidden_spell_types) > 0 then
    for _,stype in ipairs(self.forbidden_spell_types) do
      if spell:is_type(stype) then
        return false,"You're unable to learn this type of ability."
      end
    end
  end
  
  --Check spell's learn_requires() code
  local s = Spell(spellID)
  local ret,text = s:learn_requires(self)
  if ret == false then
    return false,text
  end
  return true
end

---Gets the number of free spell slots a creature has
--@return Number. The number of slots the creature has free in its spell list, or false if the creature has no inventory space set (which translates to infinite space)
function Creature:get_free_spell_slots()
  local allSlots = self:get_spell_slots()
  if not allSlots then return false end
  
  local used_slots = 0
  for _,spell in pairs(self:get_spells(true)) do
    if not spell.freeSlot then used_slots = used_slots+1 end
  end
  
  return allSlots-used_slots
end

---Gets the number of total spell slots the creature has *MAY WANT TO CHANGE FOR YOUR OWN GAME*
function Creature:get_spell_slots()
  if not self.spell_slots then return false end
  local slots = self:get_stat('spell_slots')
  if not slots then return false end
  return slots
end

---Gets a list of all the spells a creature can currently learn from its definition, class, or skills
--@return Table. A table of the spells available to purchase
function Creature:get_purchasable_spells()
  local spell_purchases = {}
  local IDs = {}
  if self.class and playerClasses[self.class].spell_purchases then
    for _,info in ipairs(playerClasses[self.class].spell_purchases) do
      if not IDs[info.spell] and (not info.level or info.level <= self.level) and self:can_learn_spell(info.spell) then
        spell_purchases[#spell_purchases+1] = info
        IDs[info.spell] = true
      end --end level check if
    end --end spell purchase list for
  end --end if player class has spell purchases
  if possibleMonsters[self.id].spell_purchases then
    for _,info in ipairs(possibleMonsters[self.id].spell_purchases) do
      if not IDs[info.spell] and (not info.level or info.level <= self.level) and self:can_learn_spell(info.spell) then
        spell_purchases[#spell_purchases+1] = info
        IDs[info.spell] = true
      end --end level check if
    end --end spell purchase list for
  end --end if player definition has spell purchases
  for skill,skillRank in pairs(self.skills) do
    local skillDef = possibleSkills[skill]
    if skillDef and skillDef.spell_purchases then
      for _,info in pairs(skillDef.spell_purchases) do
        if not IDs[info.spell] and (not info.level or info.level <= skillRank) and self:can_learn_spell(info.spell) then
          spell_purchases[#spell_purchases+1] = info
          IDs[info.spell] = true
        end
      end --end spell_purchases for
    end --end skilldef if
  end
  local spellList = possibleSpells
  if self.spellTags then
    local spellIDs = mapgen:get_content_list_from_tags('spell',self.spellTags)
    spellList = {}
    for _,spID in ipairs(spellIDs) do
      spellList[spID] = possibleSpells[spID]
    end
  end
  for spellID,spinfo in pairs(spellList) do
    if not IDs[spellID] and (spinfo.always_learnable or (gamesettings.spells_learnable_by_default and spinfo.always_learnable ~= false)) and self:can_learn_spell(spellID) then
      spell_purchases[#spell_purchases+1] = {spell=spellID,point_cost=spinfo.learn_point_cost or 1,upgrade_stat=spinfo.upgrade_stat,upgrade_stat_name=spinfo.upgrade_stat_name,upgrade_stat_plural_name=spinfo.upgrade_stat_plural_name}
      IDs[spellID] = true
    end
  end --end skill for
  return spell_purchases
end

---Gets a list of all the skills a creature can currently learn from its definition, class, or generally purchasable skills
--@param skillType String. Limit to a particular skill tpyre (optional)
--@return Table. A table of the skills available to purchase
function Creature:get_purchasable_skills(skillType)
  local skill_purchases = {}
  local possibilities = {}
  if self.class and playerClasses[self.class].skill_purchases then
    for _,info in ipairs(playerClasses[self.class].skill_purchases) do
      local skillDef = possibleSkills[info.skill]
      if not possibilities[info.skill] and skillDef and self.skills[info.skill] == nil  and (not skillType or skillDef.skill_type == skillType) and (not info.level or info.level <= self.level) and self:can_upgrade_skill(info.skill) then
        info.name = skillDef.name
        skill_purchases[#skill_purchases+1] = info
        possibilities[info.skill] = true
      end --end level check if
    end --end skill purchase list for
  end --end if player class has skill purchases
  if possibleMonsters[self.id].skill_purchases then
    for _,info in ipairs(possibleMonsters[self.id].skill_purchases) do
      local skillDef = possibleSkills[info.skill]
      if not possibilities[info.skill] and skillDef and self.skills[info.skill] == nil and (not skillType or skillDef.skill_type == skillType) and (not info.level or info.level <= self.level) and self:can_upgrade_skill(info.skill) then
        info.name = skillDef.name
        skill_purchases[#skill_purchases+1] = info
        possibilities[info.skill] = true
      end --end level check if
    end --end skill purchase list for
  end --end if player definition has skill purchases
  for skillID,info in pairs(possibleSkills) do
    if not possibilities[skillID] and self.skills[skillID] == nil and (not skillType or info.skill_type == skillType) and (info.always_learnable or (info.always_learnable ~= false and info.skill_type and possibleSkillTypes[info.skill_type] and possibleSkillTypes[info.skill_type].always_learnable)) and self:can_upgrade_skill(skillID) then
      skill_purchases[#skill_purchases+1] = {skill=skillID,point_cost=(info.learn_point_cost or info.point_cost),item_cost=(info.learn_item_cost or info.item_cost),name=info.name}
      possibilities[skillID] = true
    end --end skilldef if
  end --end skill for
  return skill_purchases
end


---Get all items equipped that can be used for melee attacks
--@return Table. A list of items that can be used for melee attacks
function Creature:get_melee_attacks()
  local melee = {}
  for _, item in pairs(self.equipment_list) do
    if item.melee_attack then
      melee[#melee+1] = item
    end --end bonuses if
  end --end equipment for
  return melee
end

---Get all ranged attacks the creature has, including those granted by equipment
--@return Table. A list of the creature's ranged attacks
function Creature:get_ranged_attacks()
  local ranged = {}
  if self.ranged_attack then
    local attack = rangedAttacks[self.ranged_attack]
    local cooldownIsRecharge = attack.max_charges
    ranged[#ranged+1] = {attack=self.ranged_attack,charges=self.ranged_charges,cooldown=(not cooldownIsRecharge and self.cooldowns[attack] or nil),recharge_turns=(cooldownIsRecharge and self.cooldowns[attack] or nil),hide_charges=rangedAttacks[self.ranged_attack].hide_charges}
  end
  for _, equip in pairs(self.equipment_list) do
    if equip.ranged_attack then
      local charges = equip.charges or 0
      if equip.usesAmmo and (not equip.max_charges or equip.max_charges == 0) then --if it's a use-ammo-from-inventory item, then show the total amount of ammo in inventory
        for _,ammo in ipairs(equip:get_possible_ammo(self)) do
          charges = charges+ammo.amount
        end
      end
      ranged[#ranged+1] = {attack=equip.ranged_attack,item=equip,charges=charges,hide_charges=equip.hide_charges,cooldown=self.cooldowns[equip]}
    end --end bonuses if
  end --end equipment for
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

---Transform into another creature. This replaces the original creature with a somewhat modified version of the creature they turn into, but leaves the original self unmodified (which enables the possibility of transfomring back). Differentiated from Creature:evolve() which uses the original creature as the base and modifies it permanently.
--@param newBody Creature or String. The creature to transform into, or the creature ID if a string
--@param info Anything. Info to pass to the new() function of the new creature
--@param modifiers Table. Table containing possible modifiers: 
--level=number (Level to spawn the new body at)
--tags=table (Table of tags to pass to the new creature)
--permanent=true (if true, don't save a reference to the old body as it will not be needed)
--include_spells=true (if true, move old body's spells over)
--include_skills=true (if true, move old body's skills over)
--active_undo=true (if true, give the undo transformation spell to the new body)
--no_hp_transfer=true (if true, don't make HP ratio transfer when transforming)
--no_inventory_transfer=true (if true, don't transfer inventory to the new body)
function Creature:transform(newBody,info,modifiers)
  modifiers = modifiers or {}
  if self.oldBody then --let's not get into multiple transformations quite yet
    return false
  end
  if type(newBody) == 'string' then
    newBody = Creature(newBody,(modifiers and modifiers.level or nil),(modifiers and modifiers.tags or nil),info)
  end
  if not modifiers.permanent then
    newBody.oldBody = self
  end
  
  --Conditions and cooldowns:
  newBody.conditions = self.conditions
  newBody.cooldowns = self.cooldowns
  
  --Identity stuff:
  newBody.properName = self.properName
  newBody.gender = self.gender
  newBody.pronouns = self.pronouns
  newBody.playerAlly = self.playerAlly
  newBody.master = self.master
  
  --AI stuff:
  newBody.notices = self.notices
  newBody.shitlist = self.shitlist
  newBody.ignoring = self.ignoring
  newBody.alert = self.alert
  
  --Other creature relationship stuff
  for _,creat in pairs(currMap.creatures) do
    if creat:can_sense_creature(self) then
      if creat.notices[self] then creat.notices[newBody] = creat.notices[self] end
      if creat.shitlist[self] then creat.shitlist[newBody] = true end
      if creat.ignoring[self] then creat.ignoring[newBody] = newBody end
    end
    if creat.master == self then
      creat.master = newBody
      newBody.thralls[creat] = creat
    end
  end
  
  --Transfer spells and skills
  if modifiers.include_skills then
    for skillID,val in pairs(self.skills) do
      local diff = val-(newBody:get_skill(skillID,true))
      if diff > 0 then
        newBody:upgrade_skill(skillID,val,true)
      end
    end
  end
  if modifiers.include_spells then
    for _,spellInfo in pairs(self.spells_known) do
      local bodySpell = newBody:has_spell(spellInfo.id,true,true)
      if not bodySpell then
        bodySpell = newBody:learn_spell(spellInfo.id,true)
      end
      for upgradeID,val in pairs(spellInfo.applied_upgrades) do
        local selfVal = bodySpell.applied_upgrades[upgradeID] or 0
        local diff = val-selfVal
        while val > 0 do
          val = val - 1
          bodySpell:apply_upgrade(upgradeID,true)
        end
      end --end upgrade ID
    end
  end
  if modifiers.active_undo then
    newBody:learn_spell('undotransform',true)
  end
  
  --Inventory and equipment
  newBody.no_inventory_transfer = modifiers.no_inventory_transfer
  if not newBody.no_inventory_transfer then
    newBody.inventory = self.inventory
    for slot,details in pairs(self.equipment) do
      if newBody.equipment[slot] then
        for _,item in ipairs(details) do
          newBody:equip(item)
        end
      end
    end
  end
  
  newBody.no_hp_transfer = modifiers.no_hp_transfer
  if newBody.no_hp_transfer then
    local hpRatio = self.hp/self.max_hp
    newBody.hp = math.ceil(newBody.max_hp*hpRatio)
    if self.mp then
      local mpRatio = self.mp/self.max_mp
      newBody.mp = math.ceil(newBody.max_mp*mpRatio)
    end
  end
  
  --Transfer the bodies:
  local x,y = self.x,self.y
  self:remove()
  currMap:add_creature(newBody,x,y)
  newBody.faceLeft = self.faceLeft
  if self == player then
    player = newBody
    newBody.isPlayer = true
    refresh_player_sight()
  end
  return newBody
end

--Undo a creature's transformation, returning them to their original form.
function Creature:undo_transformation()
  if not self.oldBody then
    return false
  end
  local oldBody = self.oldBody
  
  if not self.no_hp_transfer then
    local hpRatio = self.hp/self.max_hp
    oldBody.hp = math.ceil(oldBody.max_hp*hpRatio)
    if self.mp then
      local mpRatio = self.mp/self.max_mp
      oldBody.mp = math.ceil(oldBody.max_mp*mpRatio)
    end
  end
  
  --Identity stuff:
  oldBody.playerAlly = self.playerAlly
  oldBody.master = self.master
  
  --AI stuff:
  oldBody.notices = self.notices
  oldBody.shitlist = self.shitlist
  oldBody.ignoring = self.ignoring
  oldBody.alert = self.alert
  
  --Other creature relationship stuff
  for _,creat in pairs(currMap.creatures) do
    if creat:can_sense_creature(self) then
      if creat.notices[self] then creat.notices[oldBody] = creat.notices[self] end
      if creat.shitlist[self] then creat.shitlist[oldBody] = true end
      if creat.ignoring[self] then creat.ignoring[oldBody] = oldBody end
    end
    if creat.master == self then
      creat.master = oldBody
      oldBody.thralls[creat] = creat
    end
  end
  
  --Inventory and equipment
  if not self.no_inventory_transfer then
    for slot,details in pairs(self.equipment) do
      if oldBody.equipment[slot] then
        for _,item in ipairs(details) do
          oldBody:equip(item)
        end
      end
    end
  elseif self.inventory then
    for _,item in ipairs(self:get_inventory()) do
      if not oldBody:give_item(item) then
        self:drop_item(item)
      end
    end
  end
  
  local x,y = self.x,self.y
  self:remove()
  oldBody.faceLeft = self.faceLeft
  currMap:add_creature(oldBody,x,y)
  if self == player then
    player = oldBody
    oldBody.isPlayer = true
    refresh_player_sight()
  end
end

---Permanently evolve into another creature. It uses the initial creature as a base, and changes it to keep the highest value of skills, stats, reputation, and favor. Factions membership, spells, reputation, and favor are combined, and AI-related stuff is overwritten. Generally will be a net positive. This is differentiated from Creature:transform(), which leaves the original creature intact but effectively creates a new body and moves some limited information over to it.
--@param creature Creature or string. The creature to transform into, or the creature ID if a string
--@param info Anything. Info to pass to the new() function of the new creature
--@param include_items Boolean. Whether or not to keep the items and equipment the new creature would normally spawn with
function Creature:evolve(newCreature,info,include_items)
  if type(newCreature) == 'string' then
    newCreature = Creature(newCreature,nil,self.tags,info)
  end
  if self.class then
    newCreature:apply_class(self.class)
  end
  
  --Basic stats:
  local levelDiff = newCreature.level - self.level
  while levelDiff > 0 do
    levelDiff = levelDiff-1
    self:level_up(true)
  end
  self.level = math.max(self.level,newCreature.level)
  local hp_ratio = self.hp/self.max_hp
  self.max_hp = math.max(self.max_hp,newCreature.max_hp)
  self.hp = math.ceil(self.max_hp*hp_ratio)
  local mp_ratio = (self.mp or 0)/(self.max_mp or 1)
  self.max_mp = math.max(self.max_mp or 0, newCreature.max_mp or 0)
  self.mp = math.ceil(newCreature.max_mp*mp_ratio)
  self.perception = math.max(self.perception,newCreature.perception)
  local speedMod = self.speed-(possibleMonsters[self.id].speed or 100)
  self.speed = newCreature.speed+speedMod
  local armorMod = (self.armor or 0)-(possibleMonsters[self.id].armor or 0)
  self.armor =(newCreature.armor or 0)+armorMod
  local stealthMod = (self.stealth or 0)-(possibleMonsters[self.id].stealth or 0)
  self.stealth = (newCreature.stealth or 0)+stealthMod
  self.ranged_attack = newCreature.ranged_attack
  self.critical_chance = newCreature.critical_chance
  
  --AI stuff:
  self.ranged_chance = newCreature.ranged_chance
  self.memory = newCreature.memory
  self.aggression = newCreature.aggression
  self.bravery = newCreature.bravery
  self.min_distance = newCreature.min_distance
  self.ignore_distance = newCreature.ignore_distance
  self.pathType = newCreature.pathType
  self.run_chance = newCreature.run_chance
  self.notice_chance = newCreature.notice_chance
  self.ai_flags = newCreature.ai_flags
  self.extraSense = newCreature.extraSense
  self.terrainLimit = newCreature.terrainLimit
  self.immobile = newCreature.immobile
  self.guardWanderDistance = newCreature.guardWanderDistance or self.guardWanderDistance

  --Death items
  self.death_items = newCreature.death_items
  self.corpse = newCreature.corpse
  
  --Weaknesses, resistances and conditions
  self.weaknesses = newCreature.weaknesses
  self.resistances = newCreature.resistances
  self.hit_conditions = newCreature.hit_conditions
  
  --Extra stats:
  if newCreature.extra_stats then
    for statID,info in pairs(newCreature.extra_stats) do
      if not self.extra_stats[statID] then
        self.extra_stats[statID] = info
      else
        if not self.extra_stats[statID].max or not info.max then
          self.extra_stats[statID].max = nil
          self.extra_stats[statID].value = math.max(self.extra_stats[statID].value or 0,info.value or 0)
        else
          local ratio = self.extra_stats[statID].value/self.extra_stats[statID].max
          self.extra_stats[statID].max = math.max(self.extra_stats[statID].max,info.max)
          self.extra_stats[statID].value = math.ceil(ratio*self.extra_stats[statID].max)
        end
      end
    end
  end
  
  --Spells:
  if self.spell_slots and newCreature.spell_slots then
    self.spell_slots = math.max(self.spell_slots,newCreature.spell_slots)
  else
    self.spell_slots = nil
  end
  for _,spell in pairs(newCreature.spells_known) do
    local spellID = spell.id
    local _,selfSpell = self:has_spell(spellID,true,true)
    if not selfSpell then
      selfSpell = self:learn_spell(spellID,true)
    end
    for upgradeID,val in pairs(spell.applied_upgrades) do
      local selfVal = selfSpell.applied_upgrades[upgradeID] or 0
      local diff = val-selfVal
      while val > 0 do
        val = val - 1
        selfSpell:apply_upgrade(upgradeID,true)
      end
    end --end upgrade ID
  end
  
  --Equipment slots and inventory/equipment
  if self.inventory_space and newCreature.inventory_space then
    self.inventory_space = math.max(self.inventory_space,newCreature.inventory_space)
  else
    self.inventory_space = nil
  end
  --Replace old equipment slots with new equipment slots
  local newEquip = {}
  for slot,details in pairs(newCreature.equipment) do
    newEquip[slot] = {slots=details.slots}
  end
  if self.include_items then
    for _,item in ipairs(newCreature:get_inventory()) do
      self:give_item(item)
    end
  end
  --Equip any potential equipment. TODO: Make it select the best option if there's multiple options
  for _,item in ipairs(self:get_inventory()) do
    if item.equippable and not item.equipped then
      self:equip(item)
    end
  end
  
  --Types and tags:
  self.types = newCreature.types
  self.tags = newCreature.tags
  self.forbidden_spell_tags = newCreature.forbidden_spell_tags or newCreature.forbidden_tags
  self.forbidden_item_tags = newCreature.forbidden_item_tags or newCreature.forbidden_tags
  
  --Factions and Favor:
  for _,factionID in ipairs(newCreature.factions) do
    if not self:is_faction_member(factionID) then
      local faction = currWorld.factions[factionID]
      if faction then
        faction:join(self)
      end
    end
  end
  for faction,favor in pairs(newCreature.favor) do
    self.favor[faction] = (newCreature.favor[faction] or 0)+favor
  end
  for faction,reputation in pairs(newCreature.reputation) do
    self.reputation[faction] = (newCreature.reputation[faction] or 0)+reputation
  end
  if newCreature.enemy_factions then
    self.enemy_factions = newCreature.enemy_factions or {}
  end
  if newCreature.enemy_types then
    self.enemy_types = newCreature.enemy_types or {}
  end
  
  --Skills:
  for skillID,val in pairs(newCreature.skills) do
    self.skills[skillID] = math.max(self.skills[skillID] or 0,val) --we aren't using upgrade_skill because that could increase stats, spells, etc. which we already accounted for in the above
  end
  self.stats_per_level = newCreature.stats_per_level
  self.stats_at_level = newCreature.stats_at_level
  self.stats_per_x_levels = newCreature.stats_per_x_levels
  self.skills_per_level = newCreature.skills_per_level
  self.skills_at_level = newCreature.skills_at_level
  self.skills_per_x_levels = newCreature.skills_per_x_levels
  
  --Identity:
  self.name = newCreature.name
  self.description = newCreature.description
  self.id = newCreature.id

  --Display and sound stuff:
  self.image_name = newCreature.image_name
  self.color = newCreature.color
  self.symbol = newCreature.symbol
  self.bloodColor = newCreature.bloodColor
  self.animated=newCreature.animated
  self.animation_time = newCreature.animation_time
  self.spritesheet=newCreature.spriteSheet
  self.image_max=newCreature.image_max
  self.topdown = newCreature.topDown
  self.deathSound = newCreature.deathSound
  self.soundgroup = newCreature.soundgroup
  self.bossText = newCreature.bossText
  self.randomAnimation = newCreature.randomAnimation
  self.reverseAnimation = newCreature.reverseAnimation
  self.castsLight = newCreature.castsLight
  self.lightDist = newCreature.lightDist
  self.lightColor = newCreature.lightColor
end

---Get all possible recipes the creature can craft
--@param hide_uncraftable Boolean. If true, only show recipes that are currently craftable. If false or nil, show all known crafts even if they can't be crafted right now (optional)
--@param recipe_type String. Filter by recipe type (optional)
--@return Table. A table with the IDs of all craftable recipes
function Creature:get_all_possible_recipes(hide_uncraftable,recipe_type)
  local canCraft = {}
  for id,recipe in pairs(possibleRecipes) do
    if not recipe_type or (recipe.types and in_table(recipe_type,recipe.types)) then
      local known = recipe.always_known or (self.known_recipes and self.known_recipes[id])
      if self:can_craft_recipe(id) or (known and not hide_uncraftable) then
        canCraft[#canCraft+1] = id
        self:learn_recipe(id)
      end
    end
  end
  return canCraft
end

---Check if it's possible to craft a recipe
--TODO: Forbidden tags on recipes
--@param recipeID String. The ID of the recipe
--@param stash Entity. An entity containing items to use in addition to the creature's own inventory
--@param amount Number. The number of times to craft it
--@return Boolean. Whether or not the recipe can be crafted
--@return Text. A description of why you can't craft the recipe.
function Creature:can_craft_recipe(recipeID,stash,amount)
  amount = amount or 1
  if debugMode then return true end
  local recipe = possibleRecipes[recipeID]
  local auto_learn = (recipe.auto_learn == nil and gamesettings.auto_learn_possible_crafts or recipe.auto_learn)
  local known = self.known_recipes and self.known_recipes[id] or recipe.always_known
  if not auto_learn and not known then
    return false
  end
  if recipe.requires then
    if not recipe:requires(self,amount) then return false end
  end
  if recipe.requires_class then
    if self.class ~= recipe.requires_class then return false end
  end
  if recipe.requires_faction then
    if not self:is_faction_member(recipe.requires_faction) then return false end
  end
  if recipe.requires_spells then
    for _,spell in ipairs(recipe.requires_spells) do
      if not self:has_spell(spell) then return false end
    end
  end
  if recipe.requires_tools then
    for _,tool in ipairs(recipe.requires_tools) do
      if not self:has_item(tool) and (not stash or not stash:has_item(tool)) then return false end
    end
  end
  if recipe.ingredients then
    for item,amt in pairs(recipe.ingredients) do
      local i = self:has_item(item) or (stash and stash:has_item(item))
      if not i or (i.amount or 1) < amt*amount then return false end
    end
  end
  if recipe.ingredient_properties then
    for property,amt in pairs(recipe.ingredient_properties) do
      local found = 0
      for _,item in pairs(self:get_inventory()) do
        if item.crafting_ingredient_properties and item.crafting_ingredient_properties[property] and not recipe.results[item.id] then
          local typeMatch = false
          if recipe.ingredient_types then
            if item.crafting_ingredient_types then
              for _,itype in pairs(recipe.ingredient_types) do
                if in_table(itype,item.crafting_ingredient_types) then
                  typeMatch = true
                  break
                end
              end
            end
          else --if ingredient types aren't set, don't worry about matching
            typeMatch = true
          end
          if typeMatch then
            found = found + item.crafting_ingredient_properties[property]*item.amount
            if found >= amt*amount then break end
          end
        end
      end
      if found < amt*amount and stash then 
        for _,item in pairs(stash:get_inventory()) do
          if item.crafting_ingredient_properties and item.crafting_ingredient_properties[property] and not recipe.results[item.id] then
            local typeMatch = false
            if recipe.ingredient_types then
              if item.crafting_ingredient_types then
                for _,itype in pairs(recipe.ingredient_types) do
                  if in_table(itype,item.crafting_ingredient_types) then
                    typeMatch = true
                    break
                  end
                end
              end
            else --if ingredient types aren't set, don't worry about matching
              typeMatch = true
            end
            if typeMatch then
              found = found + item.crafting_ingredient_properties[property]*item.amount
              if found >= amt*amount then break end
            end
          end
        end
      end
      if found < amt*amount then return false end
    end --end property for
  end --end if ingredient_properties
  if recipe.tool_properties then
    for _,prop in ipairs(recipe.tool_properties) do
      local has = false
      for _,item in pairs(self:get_inventory()) do
        if item.crafting_tool_properties and in_table(prop,item.crafting_tool_properties) then
          has = true
          break
        end --end if has_tag
      end -- end inventory for
      if not has and stash then
        for _,item in pairs(stash:get_inventory()) do
          if item.crafting_tool_properties and in_table(prop,item.crafting_tool_properties) then
            has = true
            break
          end --end if has_tag
        end -- end inventory for
      end
      if not has then return false end
    end --end tag for
  end
  if recipe.required_level and self.level < recipe.required_level then
    return false
  end
  if recipe.skill_requirements then
    for skill,rank in pairs(recipe.skill_requirements) do
      if self:get_skill(skill) < rank then return false end
    end
  end
  if recipe.stat_requirements then
    for stat,requirement in pairs(recipe.stat_requirements) do
      if self:get_stat(stat) < requirement then
        return false
      end
    end
  end
  return true --if no requirements have been false, we should be good to go
end

---Craft a recipe
--@param recipeID Text. The ID of the recipe to craft
--@param secondary_ingredients Table. Secondary ingredients provided for the recipe based on the ingredient_properties
--@param stash Entity. An entity containing items to use in addition to the creature's own inventory
--@param amount Number. The number of times to craft it
--@return Boolean. If the recipe was successfully created
--@return Text. The result text of the recipe
function Creature:craft_recipe(recipeID,secondary_ingredients,stash,amount)
  amount = amount or 1
  local recipe = possibleRecipes[recipeID]
  local results = recipe.results
  local text = recipe.result_text
  local name_prefix = ""
  local checkedNames = {}
  
  --[[Custom craft code TODO: return to this later
  if recipe.craft then
    local ret,rettext = recipe.craft(self,recipe.ingredients,secondary_ingredients)
    if ret == false then
      if rettext then output:out(rettext) end
      return false,rettext
    elseif type(ret) == "table" then
      results = ret
      if rettext then text = rettext end
    end
  end--]]
  
  local passedTags = {}
  local givenTags = {}
  local givenTypes = {}
  local enchantments = {}
  local bonuses = {}
  if recipe.ingredients then --TODO: delete items mixed between main and stash
    for item,amt in pairs(recipe.ingredients) do
      local amount_to_delete = amt*amount
      local amount_deleted = 0
      while amount_deleted < amount_to_delete do
        local i = self:has_item(item)
        if not i and stash then
          i = stash:has_item(item)
          amount_deleted = amount_deleted + math.min((item.amount or 1),amt)
          stash:delete_item(i,amt)
        elseif i then
          amount_deleted = amount_deleted + math.min((item.amount or 1),amt)
          self:delete_item(i,amt)
        else
          --if for some reason we run out of items, which shouldn't happen, but if it does, break out of the infinite loop
          break
        end
        if i.crafting_passed_tags then
          for _,tag in pairs(i.crafting_passed_tags) do
            passedTags[#passedTags+1] = tag
          end
        end
        if i.crafting_given_tags then
          for _,tag in pairs(i.crafting_given_tags) do
            givenTags[#givenTags+1] = tag
          end
        end
        if i.crafting_given_enchantments then
          for _,tag in pairs(i.crafting_given_enchantments) do
            enchantments[#enchantments+1] = tag
          end
        end
        if i.crafting_given_bonuses then
          for bonus,bonusAmt in pairs(i.crafting_given_bonuses) do
            bonuses[bonus] = (bonuses[bonus] or 0)+amt*bonusAmt
          end
        end
      end
    end
  end
  if secondary_ingredients then
    local ingNames = {}
    for item,amt in pairs(secondary_ingredients) do
      if amt > 0 then
        if not checkedNames[item.name] then
          ingNames[#ingNames+1] = item.name
          checkedNames[item.name] = true
        end
        if item.possessor == stash then
          stash:delete_item(item,amt)
        else
          self:delete_item(item,amt)
        end
        if item.crafting_passed_tags then
          for _,tag in pairs(item.crafting_passed_tags) do
            passedTags[#passedTags+1] = tag
          end
        end
        if item.crafting_given_tags then
          for _,tag in pairs(item.crafting_given_tags) do
            givenTags[#givenTags+1] = tag
          end
        end
        if item.crafting_given_types then
          for _,itype in pairs(item.crafting_given_types) do
            givenTypes[#givenTypes+1] = itype
          end
        end
        if item.crafting_given_enchantments then
          for _,tag in pairs(item.crafting_given_enchantments) do
            enchantments[#enchantments+1] = tag
          end
        end
        if item.crafting_given_bonuses then
          for bonus,bonAmt in pairs(item.crafting_given_bonuses) do
            print('bonus from',item.name,amt,(amt*bonAmt))
            bonuses[bonus] = (bonuses[bonus] or 0)+(amt*bonAmt)
          end
        end
      end
    end
    if recipe.add_ingredients_to_name then
      for i,name in ipairs(ingNames) do
        if i ~= 1 then
          print(i,#ingNames,name)
          if i == #ingNames then
            name_prefix = name_prefix .. (#ingNames > 2 and "," or "") .. " and "
          else
            name_prefix = name_prefix .. ", "
          end
        end
        name_prefix = name_prefix .. name
      end
    end
  end
  local resultCount = 0
  local resultText = nil
  for i=1,amount,1 do
    for item,amt in pairs(results) do
      resultCount = resultCount + 1
      local newItem = Item(item,passedTags)
      newItem.amount = amt
      for _,tag in ipairs(givenTags) do
        if not newItem:has_tag(tag) then
          newItem.tags[#newItem.tags+1] = tag
        end
      end
      for _,itype in ipairs(givenTypes) do
        if not newItem:is_type(itype) then
          newItem.types[#newItem.types+1] = itype
        end
      end
      for _,enchantment in ipairs(enchantments) do
        if newItem:qualifies_for_enchantment(enchantment) then
          newItem:apply_enchantment(enchantment,-1)
        end
      end
      for bonus,amt in pairs(bonuses) do
        newItem.bonuses = newItem.bonuses or {}
        newItem.bonuses[bonus] = (newItem.bonuses[bonus] or 0)+amt
      end
      self:give_item(newItem)
      if recipe.add_ingredients_to_name then
        newItem.name = name_prefix .. " " .. newItem.name
      end
      if resultText then
        resultText = resultText .. (resultCount == count(recipe.results) and (resultCount ~= 2 and ", and " or " and ") or ", ") .. newItem:get_name()
      else
        resultText = newItem:get_name()
      end
    end
  end
  if not text and resultText then text = "You create " .. resultText .. "." end
  output:out(text)
  update_stat('recipes_crafted',recipeID)
  self:learn_recipe(recipeID)
  return true,text
end

---Learn a recipe
--@param recipeID Text. The ID of the recipe to learn
function Creature:learn_recipe(recipeID)
  self.known_recipes[recipeID] = true
end

---Restores HP, MP, spells, removes cooldowns and conditions
function Creature:refresh()
  for condition,info in pairs(self.conditions) do
    local turns = info.turns
    if turns ~= -1 then
      self:cure_condition(condition)
    end
  end
  for _,spell in ipairs(self.spells_known) do
    spell.charges = (spell:get_stat('max_charges') or spell.charges)
  end
  self.hp = self:get_max_hp()
  self.mp = self:get_max_mp()
  self.cooldowns = {}
  --Reset AI stuff:
  self.fear = 0
  self.alert = 0
  self.target=nil
  self.notices = {}
  self.shitlist = {}
  self.ignoring = {}
  self.lastSawPlayer = {x=nil,y=nil}
  self.path = nil
  --Clear Caches:
  self.checked = {}
  self.seen_tile_cache = {}
  self.sensed_creatures = {}
  self.bonus_cache = {}
  self.can_move_cache = {}
end

---Registers an incident as having occured, to be processed by all other creatures who observe it
--@param incidentID String. The incident type
--@param actor Entity. The creature (or other entity) that caused the incident. Optional
--@param target Entity. The entity (or coordinates), that was the target of the incident. Optional
--@param args Table. Other information to use when processing this incident
function Creature:process_incident(incidentID,actor,target,args)
  if actor == self or target == self then
    return false
  end
  local bool,ret = self:callbacks('process_incident',incidentID,actor,target,args)
  if (bool == false) then return end
  if possibleIncidents and possibleIncidents[incidentID] and possibleIncidents[incidentID].process then
    local status,r = pcall(possibleIncidents[incidentID].process,possibleIncidents[incidentID],self,actor,target,args)
    if status == false then
      output:out("Error in incident " .. incidentID .. " process code: " .. r)
      print("Error in incident " .. incidentID .. " process code: " .. r)
    end
  end
end

---Returns the ID of the dialog most applicable to this creature at the moment
--@param asker Creature. The creature speaking to this creature
function Creature:get_dialog(asker)
  asker = asker or player
  local dialogID
  
  if possibleMonsters[self.id].get_dialog then
    local status,r = pcall(possibleMonsters[self.id].get_dialog,self,asker)
    if status == false then
      output:out("Error in creature " .. self.name .. " get_dialog code: " .. r)
      print("Error in creature " .. self.name .. " get_dialog code: " .. r)
    end
    if r == false then
      return false
    elseif r ~= true and r ~= nil and possibleDialogs[r] then
      return r
    end
  end
  
  for conID,conInfo in pairs(self.conditions) do
    local dialogID = conInfo.replaces_dialog or (conditions[conID] and conditions[conID].replaces_dialog)
    if dialogID then
      return dialogID
    end
  end
  
  local possible_moods = {}
  local selected
  --These are ordered in order of preference
  if self:get_fear() >= self:get_bravery()  then
    possible_moods[#possible_moods+1] = "afraid"
  end
  if self.shitlist[asker] then
    possible_moods[#possible_moods+1] = "hostile"
  end
  if self.master == asker then
    possible_moods[#possible_moods+1] = "thrall"
  end
  if self:is_friend(asker) then
    possible_moods[#possible_moods+1] = "friendly"
  end
  if #possible_moods == 0 then
    possible_moods[#possible_moods+1] = "neutral"
  end
  --First check to see if the creature instance has any dialogs specifically set for given moods
  for _,mood in pairs(possible_moods) do
    if self['dialog_' .. mood] ~= nil then
      return self['dialog_' .. mood]
    end
  end
  --If no specific mood dialogs set, but there's a generic dialog ID set, use that
  if self.dialog then return self.dialog end
  
  local dialog_base = (self.dialog_base or self.id)
  
  if #possible_moods > 0 then
    --If no dialog IDs are not set in the creature instance, look at dialog IDs in the game and use any that match the creature ID
    for _,mood in pairs(possible_moods) do
      if possibleDialogs[dialog_base .. "_" .. mood] then
        return dialog_base .. "_" .. mood
      end
    end
  end
  --If no specific mood dialogs set, but there's a generic dialog for this creature, use that
  if possibleDialogs[dialog_base] then
    return dialog_base
  end
  return false
end

function Creature:get_all_impressions()
  local impressions = {}
  for _,item in pairs(self.equipment_list) do
    for _,imp in pairs(item:get_impressions()) do
      impressions[imp] = imp
    end
  end
  for conID,conInfo in pairs(self.conditions) do
    local impressions = conInfo.impressions or (conditions[conID] and conditions[conID].impressions)
    if impressions then
      for _,imp in pairs(impressions) do
        impressions[imp] = imp
      end
    end
  end
  for _,spell in pairs(self:get_spells()) do
    if spell.impressions then
      for _,imp in pairs(spell.impressions) do
        impressions[imp] = imp
      end
    end
  end
  return impressions
end

function Creature:has_impression(impression_type)
  local impressions = self:get_all_impressions()
  return impressions[impression_type]
end