Effect = Class{}

function Effect:init(effect_type, ...)
	local data = effects[effect_type]
	for key, val in pairs(data) do
		if (type(val) ~= "function") then
			self[key] = data[key]
		end
	end
  self.color = copy_table(self.color)
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
    self.image_name = self.id .. self.image_variety
  end
	return self
end

function Effect:delete(map)
  map = map or currMap
	map.effects[self] = nil
  if self.castsLight then map.lights[self] = nil end
end

function Effect:get_description()
	return self.name .. "\n" .. self.description
end

function Effect:advance()
	if (effects[self.id].advance) then return effects[self.id].advance(self) end
end

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

function Effect:refresh_image_name()
  if effects[self.id].refresh_image_name then return effects[self.id].refresh_image_name(self) end
	return false
end

function Effect:is_hazardous_for(ctype)
  if self.hazard and ((self.hazardousFor == nil and (ctype == nil or self.safeFor == nil or self.safeFor[ctype] ~= true)) or (ctype ~= nil and self.hazardousFor and self.hazardousFor[ctype] == true)) then
    return true 
  end
end

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