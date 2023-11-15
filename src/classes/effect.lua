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
  if (data.new ~= nil) then 
		local n = data.new(self,unpack({...}))
	end
	self.id = effect_type
  self.baseType='effect'
  if self.animated and self.spritesheet then
    self.image_frame=1
  end
  if self.animation_time then
    self.animation_time = tweak(self.animation_time)
  end
  if self.image_varieties then
    self.image_variety = random(1,self.image_varieties)
    self.image_name = (self.image_base or self.id) .. self.image_variety
  end
	return self
end

---Delete an effect from the map
--@param map The map that the effect is on. If blank, defaults to the current map. (optional)
function Effect:delete(map)
  map = map or currMap
	map.effects[self] = nil
  map.effect_cache[self.x .. ',' .. self.y] = nil
  if self.castsLight then map.lights[self] = nil end
end


---Perform an effect's cleanup() callback, if applicable.
--@param map Map. The map the effect is on
function Effect:cleanup(map)
  map = map or currMap
  if effects[self.id].cleanup then return effects[self.id].cleanup(self,map) end
end

---Returns the name and description of the effect
function Effect:get_description()
	return self.name .. "\n" .. self.description
end

---Called every turn. Calls the advance() function of the effect.
function Effect:advance()
	if (effects[self.id].advance) then return effects[self.id].advance(self) end
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
        currMap:refresh_light(self,true)
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
    if self.moveTween then
      Timer.cancel(self.moveTween)
      self.moveTween = nil
    end
  end
  
	if (effects[self.id].update) then return effects[self.id].update(self,dt) end
end

---Refresh the image name of an effect.
--Used for effects that look different if they're next to each other, when its surrounding has changed.
function Effect:refresh_image_name()
  if effects[self.id].refresh_image_name then return effects[self.id].refresh_image_name(self) end
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
    if self.moveTween then
      Timer.cancel(self.moveTween)
    end
    self.moveTween = tween(tweenLength,self,{xMod=self.originalXmod,yMod=self.originalYmod},'linear',function() self.doneMoving = true end)
  end
  return xChange,yChange
end