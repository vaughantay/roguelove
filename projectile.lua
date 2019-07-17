Projectile = Class{baseType = "projectile"}

--Initiates a projectile. Don't call this explicitly, it's called when you create a new effect.
--@param self The new projectile being created.
--@param projectile_type Text. The ID of the projectile you'd like to create
--@param source Entity. A table that contains the X and Y coordinates the projectile is starting at. Might be a creature.
--@param target Entity. A table that contains the X and Y coordinates the projectile is moving towards. Might be a creature.
--@param info Whatever you want to pass to the projectile's new() function
--@return The projectile itself.
function Projectile:init(projectile_type,source,target,info)
  local data = projectiles[projectile_type]
	for key, val in pairs(data) do
		if (type(val) ~= "function") then
			self[key] = data[key]
		end
	end
  if (data.new ~= nil) then 
		local r = data.new(self,source,target,(info or nil))
    if r and (r.x and r.y) then target = r end
	end
  self.baseType = "projectile"
  self.id = projectile_type
  self.source = source
	self.x,self.y = source.x,source.y
  self.xMod,self.yMod=0,0
  self.target = target
  self.timer = self.time_per_tile
  self.path = nil
  self.stopsInput = (self.stopsInput == nil and true or self.stopsInput)
  if self.extra_damage_per_level and source and source.baseType == "creature" then
    self.damage = self.damage + math.floor(self.extra_damage_per_level*source.level)
  end
  if self.damage and source and source == player then
    self.damage = self.damage + math.ceil(player.level/3)
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
  self.color = copy_table(self.color)
	return self
end

--Gets the description of the projectile
--@param self The projectile itself
--@return Text. The description of the projectile
function Projectile:get_description()
	return ucfirst(self.name) .. "\n" .. self.description
end

--Deletes a projectile
--@param self The projectile itself
function Projectile:delete()
	currMap.projectiles[self] = nil
end

--This code runs every turn a projectile is active. You shouldn't call it explicitly, it's called by the advance_turn() code
--@param self The projectile itself
function Projectile:advance()
  if (self.path == nil) then --first made?
    if (self.projectile == true) then
      self.path = currMap:get_line(self.x,self.y,self.target.x,self.target.y)
    else --if it passes through obstacles
      self.path = currMap:get_line(self.x,self.y,self.target.x,self.target.y,true)
    end --end projectile if
  else --not the first turn
    --Refresh the path in case the target moved
    if (self.projectile == true) then
      self.path = currMap:get_line(self.x,self.y,self.target.x,self.target.y)
    else --if it passes through obstacles
      self.path = currMap:get_line(self.x,self.y,self.target.x,self.target.y,true)
    end --end projectile if
    --Travel along the whole path instantly
    if not self.neverInstant then
      for id, path in ipairs(self.path) do
        local x,y = path[1],path[2]
        if id == #self.path or (self.passThrough ~= true and currMap:isClear(x,y,'flyer') == false) then
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= self.source then self:hits(creat)
          else self:hits({x=x,y=y}) end
        end
      end --end path for
    end --end if neverinstant
  end --end line if
  
	if (projectiles[self.id].advance) then return projectiles[self.id].advance(self) end
end

--This code runs every tick a projectile is active. You shouldn't call it explicity, it's called by the advance_turn() code
--@param self The projectile itself
--@param dt Number The number of seconds since the last tick
--@param force_generic True/False. If set to true, run this code and don't run the projectile's custom hits() code.
function Projectile:update(dt,force_generic)
  if (self.timer <= 0 or force_generic == true) then
    if (force_generic ~= true and projectiles[self.id].update) then return projectiles[self.id].update(self,dt) end
    if (self.timer <= 0) then self.timer = self.time_per_tile end --rechecks in case it's being forced
    --Generic update: (Move to next point on line. If collides with something, call hits()
    if (self.path and #self.path > 0) then
      local tileSize = output:get_tile_size()
      local xChange,yChange = (self.path[1][1]-self.x)*tileSize,(self.path[1][2]-self.y)*tileSize
      self.x, self.y = self.path[1][1],self.path[1][2]
      if not prefs['noSmoothMovement'] then
        self.xMod,self.yMod = self.xMod-xChange,self.yMod-yChange
        if self.moveTween then
          Timer.cancel(self.moveTween)
        end
        self.moveTween = tween(self.time_per_tile,self,{xMod=0,yMod=0})
      end
      table.remove(self.path,1)
      if self.passThrough ~= true and currMap:isClear(self.x,self.y,'flyer') == false then
        local creat = currMap:get_tile_creature(self.x,self.y,true)
        if creat and creat ~= self.source then self:hits(creat) end
      end
    else --reached the end of the line
      local creat = currMap:get_tile_creature(self.x,self.y)
      if creat and creat ~= self.source then self:hits(creat)
      else self:hits({x=self.x,y=self.y}) end --defaults to just deleting itself, but can be overwritten by projectiles
    end --end path check
  else
    self.timer = self.timer - dt
  end --end timer check
end --end update() function

--Called when a projectile hits something
--@param self The projectile itself
--@param target Entity. The thing it hit. At least a table with an X and Y coordinate, possibly a creature.
--@param force_generic True/False. If set to true, run this code and don't run the projectile's custom hits() code.
function Projectile:hits(target,force_generic)
  if (force_generic ~= true and projectiles[self.id].hits) then return projectiles[self.id].hits(self,target) end
  --Generic hits:
  local playersees = player:can_see_tile(target.x,target.y)
  if target and ((target.baseType == "creature" and not target:is_type('ghost')) or (target.baseType == "feature" and (target.attackable or target.damage))) then
    local dmg = target:damage(tweak(self.damage),self.source,self.damage_type)
    if playersees then
      if dmg and (type(dmg) ~= "number" or dmg > 0) then
        output:out("The " .. self.name .. " hits " .. target:get_name() .. " for " .. dmg .. (self.damage_type and " " .. self.damage_type or "") .. " damage.")
      else
        output:out("The " .. self.name .. " hits " .. target:get_name() .. ".")
      end --end dmg/nodmg if
    end --end playersees if
    if self.hit_conditions and target.baseType == "creature" then
      for _, condition in pairs(self.hit_conditions) do
				if (random(1,100) < condition.chance) then
					target:give_condition(condition.condition,tweak(condition.turns),self)
				end -- end condition chance
			end	-- end condition forloop
    end
  end -- end target if
  
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
end --end hits() function

--Gets the name of the projectile
--@param self The projectile itself
--@param full True/False. If true, return just the basic name of the projectile. If false, preface with "a" or "an"
--@return Text. The name of the projectile
function Projectile:get_name(full)
  if (full == true) then
		return ucfirst(self.name) 
	else
		return (vowel(self.name) ~= true and "a " or "an ") .. self.name
	end
end