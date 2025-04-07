---@classmod Projectile
Projectile = Class{baseType = "projectile"}

---Initiates a projectile. Don't call this explicitly, it's called when you create a new projectile with Projectile('projectileID',source,target).
--@param projectile_type String. The ID of the projectile you'd like to create
--@param source Entity. A table that contains the X and Y coordinates the projectile is starting at. Might be a creature.
--@param target Entity. A table that contains the X and Y coordinates the projectile is moving towards. Might be a creature.
--@param info Whatever you want to pass to the projectile's new() function
--@return The projectile itself.
function Projectile:init(projectile_type,source,target,info)
  local data = projectiles[projectile_type]
  if not data then
    output:out("Error: Tried to create non-existent projectile " .. projectile_type)
    print("Error: Tried to create non-existent projectile " .. projectile_type)
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
  self.baseType = "projectile"
  self.id = projectile_type
  self.source = source
	self.x,self.y = source.x,source.y
  self.xMod,self.yMod=0,0
  self.target = target
  self.time_per_tile = self.time_per_tile or .02
  self.timer = 0
  self.path = nil
  self.stopsInput = (self.stopsInput == nil and true or self.stopsInput)
  if self.spin_speed then
    self.angle = random(0,math.ceil(2*math.pi))
  end
	currMap.projectiles[self] = self
  if self.angled == true then
    if self.symbol == "/" then
      if (source.x == target.x) then self.symbol = "|"
      elseif (source.y == target.y) then self.symbol = "–"
      elseif (source.x > target.x and source.y > target.y) or (source.x<target.x and source.y<target.y) then self.symbol = "\\"
      else self.symbol = "/" end
    end
    self.angle = calc_angle(source.x,source.y,target.x,target.y)
  end
  if (data.new ~= nil) then 
		local r = data.new(self,source,target,(info or nil))
    if r and (r.x and r.y) then target = r end
	end
  self:refresh_path()
  self.first_turn=true
	return self
end

---Gets the name and description of the projectile
--@return String. The name and description of the projectile
function Projectile:get_description()
	return ucfirst(self.name) .. "\n" .. self.description
end

---Deletes a projectile
function Projectile:delete()
	currMap.projectiles[self] = nil
end

---Refresh or create the projectile's path
function Projectile:refresh_path()
  if not self.target then
    print("ERROR: No target set for projectile " .. self.id .. ", deleting")
    output:out("ERROR: No target set for projectile " .. self.id .. ", deleting")
    self:delete()
    return
  end
  if (self.projectile == true) then
    self.path = currMap:get_line(self.x,self.y,self.target.x,self.target.y)
  else --if it passes through obstacles
    self.path = currMap:get_line(self.x,self.y,self.target.x,self.target.y,true)
  end --end projectile if
end

---This code runs every turn a projectile is active. Called by the advance_turn() code
function Projectile:advance()
  self:refresh_path() --refresh path in case your target moved
  if self.first_turn then
    self.first_turn = false
  else
    --Travel along the whole path instantly
    if not self.neverInstant then
      for id, path in ipairs(self.path) do
        local x,y = path[1],path[2]
        if id == #self.path or (self.passThrough ~= true and currMap:isClear(x,y,'airborne') == false) then
          local creat = currMap:get_tile_creature(x,y,true)
          if creat and creat ~= self.source then self:hits(creat)
          else self:hits({x=x,y=y}) end
        end
      end --end path for
    end --end if neverinstant
  end --end line if
  
	if (projectiles[self.id].advance) then
    local status,r = pcall(projectiles[self.id].advance,self)
    if status == false then
      output:out("Error in projectile " .. self.id .. " advance code: " .. r)
      print("Error in projectile " .. self.id .. " advance code: " .. r)
    end
    return r
  end
end

---This code runs every tick a projectile is active. You shouldn't call it explicitly.
--@param dt Number The number of seconds since the last tick
--@param force_generic Boolean. If set to true, run this code and don't run the projectile's custom update() code.
function Projectile:update(dt,force_generic)
  if self.pause and self.pause > 0 then
    self.pause = self.pause-dt
    return
  end
  if (self.timer <= 0 or force_generic == true) then
    if (force_generic ~= true and projectiles[self.id].update) then
      local status,r = pcall(projectiles[self.id].update,self,dt)
      if status == false then
        output:out("Error in projectile " .. self.id .. " update code: " .. r)
        print("Error in projectile " .. self.id .. " update code: " .. r)
      end
      return r
    end
    if (self.timer <= 0) then self.timer = self.time_per_tile end --rechecks in case it's being forced
    --Generic update: (Move to next point on line. If collides with something, call hits()
    if (self.path and #self.path > 0) then
      local tileSize = output:get_tile_size()
      local xChange,yChange = (self.path[1][1]-self.x)*tileSize,(self.path[1][2]-self.y)*tileSize
      self.x, self.y = self.path[1][1],self.path[1][2]
      if not prefs['noSmoothMovement'] then
        self.xMod,self.yMod = self.xMod-xChange,self.yMod-yChange
        if timers[tostring(self) .. 'moveTween'] then
          Timer.cancel(timers[tostring(self) .. 'moveTween'])
        end
        timers[tostring(self) .. 'moveTween'] = tween(self.time_per_tile,self,{xMod=0,yMod=0})
      end
      table.remove(self.path,1)
      if projectiles[self.id].enters_tile then
        local status,r = pcall(projectiles[self.id].enters_tile,self)
        if status == false then
          output:out("Error in projectile " .. self.id .. " enters_tile code: " .. r)
          print("Error in projectile " .. self.id.. " enters_tile code: " .. r)
        end
      end
      if self.passThrough ~= true and currMap:isClear(self.x,self.y,'airborne') == false then
        local creat = currMap:get_tile_creature(self.x,self.y,true)
        if creat and creat ~= self.source then
          local dmg = self:hits(creat)
          for ench,_ in pairs(self:get_enchantments()) do
            if enchantments[ench].after_damage then
              local status,r = pcall(enchantments[ench].after_damage,enchantments[ench],self,creat,dmg)
              if status == false then
                output:out("Error in enchantment " .. ench .. " after_damage code: " .. r)
                print("Error in enchantment " .. ench.. " after_damage code: " .. r)
              end
            end
          end --end enchantment after_damage for
        end
      end
    else --reached the end of the line
      local creat = currMap:get_tile_creature(self.x,self.y,true)
      if creat and creat ~= self.source then
        local dmg = self:hits(creat)
        for ench,_ in pairs(self:get_enchantments()) do
          if enchantments[ench].after_damage then
            local status,r = pcall(enchantments[ench].after_damage,enchantments[ench],self,creat,dmg)
            if status == false then
              output:out("Error in enchantment " .. ench .. " after_damage code: " .. r)
              print("Error in enchantment " .. ench.. " after_damage code: " .. r)
            end
          end
        end --end enchantment after_damage for
      else
        self:hits({x=self.x,y=self.y})
        for ench,_ in pairs(self:get_enchantments()) do
          if enchantments[ench].after_miss then
            local status,r = pcall(enchantments[ench].after_miss,enchantments[ench],self,{x=self.x,y=self.y})
            if status == false then
              output:out("Error in enchantment " .. ench .. " after_miss code: " .. r)
              print("Error in enchantment " .. ench.. " after_miss code: " .. r)
            end
          end
        end --end enchantment after_miss for
      end --defaults to just deleting itself, but can be overwritten by projectiles
    end --end path check
  else
    self.timer = self.timer - dt
  end --end timer check
  if self.spin_speed then
    if self.symbol == "/" then self.symbol = "-"
    elseif self.symbol == "-" then self.symbol = "\\"
    elseif self.symbol == "\\" then self.symbol = "|"
    elseif self.symbol == "|" then self.symbol = "/" end
    self.angle = (self.angle or 0)+dt*self.spin_speed*math.pi
  end
end --end update() function

---Called when a projectile hits something
--@param target Entity. The thing it hit. Must be a table with an X and Y coordinate, probably a creature.
--@param force_generic Boolean. If set to true, run this code and don't run the projectile's custom hits() code.
function Projectile:hits(target,force_generic)
  if (force_generic ~= true and projectiles[self.id].hits) then
    local status,r = pcall(projectiles[self.id].hits,self,target)
    if status == false then
      output:out("Error in projectile " .. self.id .. " hits code: " .. r)
      print("Error in projectile " .. self.id.. " hits code: " .. r)
    end
    return r
  end
  --Generic hits:
  local dmg = false
  local playersees = player:can_see_tile(target.x,target.y)
  if target and (target.baseType == "creature"  or (target.baseType == "feature" and (target.attackable or target.damage))) then
    if self.damage and self.damage > 0 then
      dmg = target:damage(tweak(self:get_damage()),self.source,self.damage_type,self.armor_piercing,nil,self.source_item)
    end
    if playersees then
      local txt = (type(self.miss_item) == "table" and self.miss_item:get_name() or "The " .. self.name) .. " hits " .. target:get_name()
      if dmg and dmg > 0 then
        txt = txt .. " for " .. dmg .. (self.damage_type and " " .. self.damage_type or "") .. " damage"
      elseif dmg and dmg < 0 then
        txt = txt .. ", healing " .. -dmg .. " HP"
      end --end dmg/nodmg if
      --Add extra damage
      local loopcount = 1
      local dtypes = self:get_extra_damage(target,dmg)
      local dcount = count(dtypes)
      for dtype,amt in pairs(dtypes) do
        if (not dmg or dmg < 1) and loopcount == 1 then
          txt = txt .. ", dealing "
        elseif loopcount == 1 and dcount == 1 then
          txt = txt .. " and "
        elseif loopcount == dcount then
          txt = txt .. ", and "
        else
          txt = txt .. ", "
        end
        txt = txt .. amt .. " " .. dtype .. " damage"
      end
      txt = txt .. "."
      if not self.silent then output:out(txt) end
    end --end playersees if
    local hitCons = self:get_hit_conditions()
    if hitCons and target.baseType == "creature" then
      for _, condition in pairs(hitCons) do
				if (random(1,100) < (condition.chance or 100)) then
          local turns = ((condition.minTurns and condition.maxTurns and random(condition.minTurns,condition.maxTurns)) or tweak(condition.turns))
					target:give_condition(condition.condition,turns,self)
				end -- end condition chance
			end	-- end condition forloop
    end
    if self.source_item then
      self.source_item:decrease_all_enchantments('hit')
    end
    --Hit effect:
    if self.hit_effect then
      local args = self.hit_effect_args or {}
      local eff = Effect(self.hit_effect,unpack(args))
      eff.creator = self.source
      currMap:add_effect(eff,target.x,target.y)
    end
    if self.hit_feature then
      local args = self.hit_feature_args or {}
      local feat = Feature(self.hit_feature,args)
      feat.creator = self.source
      currMap:add_feature(feat,target.x,target.y)
    end
  else --miss
    if self.miss_effect then
      local args = self.miss_effect_args or {}
      local eff = Effect(self.miss_effect,unpack(args))
      eff.creator = self.source
      currMap:add_effect(eff,target.x,target.y)
    end
    if self.miss_feature then
      local args = self.miss_feature_args or {}
      local feat = Feature(self.miss_feature,args)
      feat.creator = self.source
      currMap:add_feature(feat,target.x,target.y)
    end
  end
  
  --Handle creating an item if necessary:
  if self.miss_item and (self.miss_item_on_hit or not dmg) and (not self.miss_item_chance or random(1,100) <= self.miss_item_chance) and not currMap:isWall(target.x,target.y) and not currMap:has_tag(target.x,target.y,'absorbs') then
    local it = nil
    if type(self.miss_item) == "string" then
      it = currMap:add_item(Item(self.miss_item),target.x,target.y,true)
    else
      it = currMap:add_item(self.miss_item,target.x,target.y,true)
    end
    if self.enchantments and type(self.miss_item) == "string" then --Only apply enchantments if you're creating a new item. Otherwise we'll assume that the created item already has all the enchantments it needs
      for ench,turns in pairs(self.enchantments) do
        if turns ~= 0 then
          it:apply_enchantment(ench,turns)
        end
      end --end permanent check if
      it:decrease_all_enchantments('attack')
    end --end miss item == string
    if dmg then
      it:decrease_all_enchantments('hit')
    end
  end -- end miss_item if
  
  --Catch stuff on fire if you deal fire damage
  if self.damage_type == "fire" then
    for _,content in pairs(currMap:get_tile_features(target.x,target.y)) do
      if content.fireChance and random(1,100) <= content.fireChance then
        content:combust()
        if playersees then output:out("The " .. self.name .. " catches the " .. content.name .. " on fire!") end
      end
    end
  end
  
  --Play sounds:
  if playersees then
    if self.hit_sound and target and target.baseType == "creature" then
      output:sound(self.hit_sound)
    elseif self.miss_sound then
      output:sound(self.miss_sound)
    end
  end
  self:delete()
  
  return dmg
end --end hits() function

---Gets the name of the projectile
--@param full Boolean. If true, return just the basic name of the projectile. If false, preface with "a" or "an"
--@return String. The name of the projectile
function Projectile:get_name(full)
  if (full == true) then
		return ucfirst(self.name) 
	else
		return (vowel(self.name) ~= true and "a " or "an ") .. self.name
	end
end

---Return a list of all enchantments currently applied to an projectile
--@return Table. The list of enchantments
function Projectile:get_enchantments()
  return self.enchantments or {}
end

---Check what hit conditions a projectile can inflict
--@return Table. The list of hit conditions
function Projectile:get_hit_conditions()
  local cons = self.hit_conditions or {}
	for e,_ in pairs(self:get_enchantments()) do
    local ench = enchantments[e]
    if ench.hit_conditions then
      for _,con in ipairs(ench.hit_conditions) do
        local already = false
        for i, c in ipairs(cons) do --check current conditions, and if we already have this condition, use the maximum values between the condition we have and the condition applied by the enchantment
          if c.condition == con.condition then --c is the current condition, con is the new condition
            already = true
            c.minTurns = math.max(c.minTurns or 0,con.minTurns or 0)
            c.maxTurns = math.max(c.maxTurns or 0,con.maxTurns or 0)
            c.turns = math.max(c.turns or 0,con.turns or 0)
            if c.minTurns == 0 then c.minTurns = nil end
            if c.maxTurns == 0 then c.maxTurns = nil end
            if c.turns == 0 then c.turns = nil end
            c.chance = math.max(c.chance,con.chance)
          end
        end --end loopthrough of own conditions
        if not already then
          cons[#cons+1] = con
        end
      end --end ehcnatment's conditions loop
    end --end if the enchantment has hit conditions
  end --end enchantment loop
  return cons
end

---Return the damage done by the projectile
--@return Number. The damage done
function Projectile:get_damage()
  local damage = self.damage
  local level = ((self.source_item and self.source_item.level) or (not self.source_item and self.source and self.source.level))
  if self.extra_damage_per_level and level then
    damage = damage + math.floor(self.extra_damage_per_level*level)
  end
  if self.source and self.source.get_ranged_damage and (not self.source_item or not self.source_item.no_creature_damage) then
    damage = damage + self.source:get_ranged_damage((self.source_item and self.source_item.ranged_damage_stats) or self.ranged_damage_stats or (self.source_attack and self.source_attack.ranged_damage_stats))
  end
  if self.source_item then
    damage = damage + self.source_item:get_ranged_damage()
  end
  local bonus = .01*self:get_enchantment_bonus('damage_percent')
  damage = damage + math.ceil(damage * bonus)
  damage = damage + self:get_enchantment_bonus('damage')
  return damage
end

---Returns the total value of the bonuses of a given type provided by enchantments.
--@param bonusType Text. The bonus type to look at
--@return Number. The bonus
function Projectile:get_enchantment_bonus(bonusType)
  local total = 0
  for e,_ in pairs(self:get_enchantments()) do
    local enchantment = enchantments[e]
    if enchantment.bonuses and enchantment.bonuses[bonusType] then
      total = total + enchantment.bonuses[bonusType]
    end --end if it has the right bonus
  end --end enchantment for
  return total
end

---Find out how much extra damage an item will deal due to enchantments
--@param target Entity. The target of the item's attack.
--@param dmg Number. The base damage being done to the target
--@return Table. A table with values of the extra damage the item will deal.
function Projectile:get_extra_damage(target,dmg)
  local extradmg = {}
  
  for e,_ in pairs(self:get_enchantments()) do
    local ench = enchantments[e]
    if ench.extra_damage then
      local ed = ench.extra_damage
      local apply = true
      if ed.only_creature_types and target.baseType == "creature" then
        apply = false
        for _,ctype in ipairs(ed.only_creature_types) do
          if target:is_type(ctype) then
            apply = true
            break
          end
        end --end creature type for
      end --end if only creature types
      if ed.safe_creature_types and apply and target.baseType == "creature"  then
        for _,ctype in ipairs(ed.safe_creature_types) do
          if target:is_type(ctype) then
            apply = false
            break
          end
        end --end creature type for
      end --end if safe creature types
      if apply == true then
        local dmg = tweak((ed.damage or 0)+math.ceil((ed.damage_percent or 0)/100*dmg))
        dmg = target:damage(dmg,self.source,ed.damage_type,ed.armor_piercing,nil,self.source_item)
        extradmg[ed.damage_type] = extradmg[ed.damage_type] or 0 + dmg
      end
    end --end if it has an extra damage flag
  end --end enchantment for
  return extradmg
end

---Apply an enchantment to an projectile
--@param enchantment Text. The enchantment ID
--@param turns Number. The number of turns to apply the enchantment, if applicable. Generally only matters for projectiles if it misses and leaves an item behind. Use -1 to force this enchantment to be permanent. Use 0 to force the enchantment to not be applied to the item left behind.
function Projectile:apply_enchantment(enchantment,turns)
  turns = turns or 1
  if not self.enchantments then self.enchantments = {} end
  local currEnch = self.enchantments[enchantment]
  if currEnch == -1 or turns == -1 then --permanent enchantments are always permanent
    self.enchantments[enchantment] = -1
  elseif currEnch then --if you currently have this enchantment, add turns
    self.enchantments[enchantment] = currEnch+turns
  else --if you don't currently have this enchantment, set it to the passed turns value
    self.enchantments[enchantment] = turns
  end
end