---@classmod Effect
Effect = Class{}

---Initiates an effect. Don't call this explicitly, it's called when you create a new effect with Effect('effectID').
--@param effect_type String. The ID of the effect you want to create.
--@param anything Anything. The arguments to pass to the effect's new() callback. Can be any number of arguments.
--@return Effect. The effect itself.
function Effect:init(effect_type, ...)
	local data = effects[effect_type]
  if not data then
    output:out("Error: Tried to create non-existent effect " .. effect_type)
    print("Error: Tried to create non-existent effect " .. effect_type)
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
  self.id = effect_type
  self.baseType='effect'
  if (data.new ~= nil) then 
    local status,r = pcall(data.new,self,unpack({...}))
    if status == false then
      output:out("Error in effect " .. self.name .. " new code: " .. r)
      print("Error in effect " .. self.name .. " new code: " .. r)
    end
	end
  
  if self.image_varieties and not self.image_name then
    self.image_variety = random(1,self.image_varieties)
    self.image_name = (self.image_base or self.id) .. self.image_variety
  end
  
  --Set animation if not already set:
  if not self.animated or not self.spritesheet or not self.image_max then
    local img = images[(self.imageType or 'effect')  .. (self.image_name or self.id)]
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

---Returns the name of the effect.
--@param full Boolean. Whether to return the name in uppercase and without an article.
--@return String. The name.
function Effect:get_name(full)
  if (full == true) then
		return ucfirst(self.name)
	else
		return (self.article and self.article .. " " or (self.properNamed ~= true and (vowel(self.name) and "an " or "a " )) or "") .. self.name
	end
end

---Delete an effect from the map
--@param map The map that the effect is on. If blank, defaults to the current map. (optional)
function Effect:delete(map)
  map = map or currMap
	map.effects[self] = nil
  map.effect_cache[self.x .. ',' .. self.y] = nil
  self.deleted = true
  if self.castsLight then map.lights[self] = nil end
end


---Perform an effect's cleanup() callback, if applicable.
--@param map Map. The map the effect is on
function Effect:cleanup(map)
  map = map or currMap
  if effects[self.id].cleanup then
    local status,r = pcall(effects[self.id].cleanup,self,map)
    if status == false then
      output:out("Error in effect " .. self.name .. " cleanup code: " .. r)
      print("Error in effect " .. self.name .. " cleanup code: " .. r)
    end
    return r
  end
end

---Returns the name and description of the effect
function Effect:get_description()
	return self.name .. "\n" .. self.description .. (self.turns_remaining and self.turns_remaining ~= -1 and "\nTurns Remaining: " .. self.turns_remaining or "")
end

---Called every turn. Calls the advance() function of the effect.
function Effect:advance()
	if (effects[self.id].advance) then
    local status,r = pcall(effects[self.id].advance,self)
    if status == false then
      output:out("Error in effect " .. self.name .. " advance code: " .. r)
      print("Error in effect " .. self.name .. " advance code: " .. r)
    end
    return r
  end
end

---This function is run every tick and updates various things. You probably shouldn't call it yourself
--@param dt Number. The number of seconds since the last time update() was run. Most likely less than 1.
function Effect:update(dt)
  if self.animated then
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
        local image_base = (self.image_base or (effects[self.id].image_name or self.id))
        self.image_name = image_base .. imageNum
      end
      --Change the light color, if necessary
      if self.lightColors then
        self.lightColor = self.lightColors[imageNum]
        currMap:refresh_light(self)
      end --end lightcolor if
      if self.colors then
        self.color = self.colors[imageNum] or self.color
      end
      self.animCountdown = self.animation_time or 0.5
    end --end if self.countdown
  end --end animation for
  
  if self.doneMoving and self.xMod == self.originalXmod and self.yMod == self.originalYmod then
    self.doneMoving = nil
    self.xMod,self.yMod = self.originalXmod,self.originalYmod
    self.originalXmod,self.originalYmod = nil,nil
    if timers[tostring(self) .. 'moveTween']then
      Timer.cancel(timers[tostring(self) .. 'moveTween'])
      timers[tostring(self) .. 'moveTween'] = nil
    end
  end
  
	if (effects[self.id].update) then
    local status,r = pcall(effects[self.id].update,self,dt)
    if status == false then
      output:out("Error in effect " .. self.name .. " update code: " .. r)
      print("Error in effect " .. self.name .. " update code: " .. r)
    end
    return r
  end
end

---Refresh the image name of an effect.
--Used for effects that look different if they're next to each other, when its surrounding has changed.
function Effect:refresh_image_name()
  if effects[self.id] and effects[self.id].refresh_image_name then
    local status,r = pcall(effects[self.id].refresh_image_name,self)
    if status == false then
      output:out("Error in effect " .. self.name .. " refresh image name code: " .. r)
      print("Error in effect " .. self.name .. " refresh image name code: " .. r)
    end
    return r
  end
	return false
end

---Checks if an effect is hazardous for a certain creature type.
--@param ctype String. The creature type we're checking for. If blank, just checks if it's generally hazardous. (optional)
--@return Boolean. Whether or not the effectis hazardous.
function Effect:is_hazardous_for(ctype)
  if self.hazard and ((self.hazardousFor == nil and (ctype == nil or self.safeFor == nil or self.safeFor[ctype] ~= true)) or (ctype ~= nil and self.hazardousFor and self.hazardousFor[ctype] == true)) then
    return true 
  end
end

---Move an effect between tiles.
--@param x Number. The x coordinate
--@param y Number. The y coordinate
--@param tweenLength Number. How long it takes to animate the movement between the tiles. If left blank, instantaneous. (optional)
--@return Number. The x-coordinate (in pixels) of the effect's movement.
--@return Number. The y-coordinate (in pixels) of the effect's movement.
function Effect:moveTo(x,y,tweenLength)
  local tileSize = output:get_tile_size()
  local xChange,yChange = (x-self.x)*tileSize,(y-self.y)*tileSize
  self.x,self.y = x,y
  if tweenLength and not prefs['noSmoothMovement'] then
    if not self.originalXmod and not self.originalYmod then
      self.originalXmod,self.originalYmod=self.xMod or 0,self.yMod or 0
    end
    self.xMod,self.yMod = (self.xMod or 0)-xChange,(self.yMod or 0)-yChange
    if timers[tostring(self) .. 'moveTween'] then
      Timer.cancel(timers[tostring(self) .. 'moveTween'])
    end
    timers[tostring(self) .. 'moveTween'] = tween(tweenLength,self,{xMod=self.originalXmod,yMod=self.originalYmod},'linear',function() self.doneMoving = true end)
  end
  return xChange,yChange
end

---Checks if a feature has a descriptive tag.
--@param tag String. The tag to check for
--@return Boolean. Whether or not it has the tag.
function Effect:has_tag(tag)
  if self.tags and in_table(tag,self.tags) then
    return true
  end
  return false
end

--Combustion, freezing, etc.

---Checks a effect's combust() callback, if applicable, and then lights it on fire if applicable.
--@param skip_basic Boolean. Whether to skip the combust() callback and just go ahead and light the fire. (optional)
--@param source Entity. The cause of the combustion
function Effect:combust(skip_basic,source)
  if not skip_basic and effects[self.id].combust then
    local status,r = pcall(effects[self.id].combust,self,source)
    if status == false then
      output:out("Error in effect " .. self.name .. " combust code: " .. r)
      print("Error in effect " .. self.name .. " combust code: " .. r)
    end
    return r
  end
  currMap:add_effect(Effect('fire',{creator=source,turns=(self.fireTime or 10)}),self.x,self.y)
  currMap:register_incident('light_fire',source,self)
  self:delete()
end

---Checks a effect's apply_cold() callback, if applicable, or its cold_feature flag, if applicable
--@param source Entity. The cause of the freezing
function Effect:apply_cold(source)
  if effects[self.id].apply_cold then
    local status,r = pcall(effects[self.id].apply_cold,self,source)
    if status == false then
      output:out("Error in effect " .. self.name .. " apply_cold code: " .. r)
      print("Error in effect " .. self.name .. " apply_cold code: " .. r)
    end
    return r
  end
  local chilled = false
  if self.cold_feature then
    local newfeat = Feature(self.cold_feature)
    if currMap[self.x][self.y] == self and not self.remain_on_cold then
      currMap:change_tile(newfeat,self.x,self.y)
    else
      currMap:add_feature(newfeat,self.x,self.y)
    end
    chilled = true
  end
  if self.cold_effect then
    local neweff = Effect(self.cold_effect)
    neweff.creator = source
    currMap:add_effect(neweff,self.x,self.y)
    chilled = true
  end
  if chilled and not self.remain_on_cold then self:delete() end
end

---Checks a effect's apply_heat() callback, if applicable, or its heat_feature flag, if applicable
--@param source Entity. The cause of the melting
function Effect:apply_heat(source)
  if effects[self.id].melt then
    local status,r = pcall(effects[self.id].apply_heat,self,source)
    if status == false then
      output:out("Error in effect " .. self.name .. " apply_heat code: " .. r)
      print("Error in effect " .. self.name .. " apply_heat code: " .. r)
    end
    return r
  end
  local heated = false
  if self.heat_feature then
    local newfeat = Feature(self.heat_feature)
    if currMap[self.x][self.y] == self and not self.remain_on_heat then
      currMap:change_tile(newfeat,self.x,self.y)
    else
      currMap:add_feature(newfeat,self.x,self.y)
    end
    heated = true
  end
  if self.heat_effect then
    local neweff = Effect(self.heat_effect)
    neweff.creator = source
    currMap:add_effect(neweff,self.x,self.y)
    heated = true
  end
  if heated and not self.remain_on_heat then self:delete() end
end