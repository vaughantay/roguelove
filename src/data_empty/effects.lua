effects = {}

--Standard effects used in the base engine:

local fire = {
  name = "Fire",
  description = "A roaring flame.",
  symbol = "^",
  color={r=255,g=0,b=0},
  countdown = .25,
  timer = 10,
  firstturn = true,
  hazard = 1000,
  castsLight=true,
  lightDist=2,
  lightColor={r=255,g=255,b=0}
}
function fire:new(data)
  if data then
    if data.timer then self.timer = data.timer end
    if data.x and data.y then
      self.x,self.y = data.x,data.y
      local feats = currMap:get_tile_features(self.x,self.y)
      for _,feat in pairs(feats) do
        if feat.water == true then return false end
      end
      if type(currMap[self.x][self.y]) == "table" and currMap[self.x][self.y].water == true then return false end
    end
  end
  self.timer = tweak(self.timer)
  self.image_name = "fire" .. random(1,3)
  if self.x and self.y and player:can_see_tile(self.x,self.y) then output:sound('ignite') end
end --end new function
function fire:update(dt)
  self.countdown = self.countdown - dt
  if (self.countdown <= 0) then
    local newName = "fire" .. random(1,3)
    while (newName == self.image_name) do newName = "fire" .. random(1,3) end
    self.image_name = newName
    self.countdown = .25
    if (self.color.g == 0) then
      self.color.g=255
    elseif (self.color.g == 255) then
      self.color.g=142
    else
      self.color.g=0
    end
    self.lightColor={r=random(200,255),g=random(200,255),b=0,a=50}
    currMap:refresh_light(self)
  end
end --end update function
function fire:advance()
  local feats = currMap:get_tile_features(self.x,self.y)
  for _,feat in pairs(feats) do
    if feat.water == true then self:delete() return false end
  end
  if type(currMap[self.x][self.y]) == "table" and currMap[self.x][self.y].water == true then self:delete() return false end
  --Burn creatures on tile:
  local creat = currMap:get_tile_creature(self.x,self.y)
  if (creat and creat.fireImmune ~= true and not creat:has_condition('onfire')) then
    local dmg = creat:damage(tweak(5),self.creator,"fire")
    if dmg > 0 and player:can_see_tile(self.x,self.y) then output:out(creat:get_name() .. " takes " .. dmg .. " damage from fire.") end
    if (dmg> 0 and random(1,100) >= 60) then
      if creat.conditions['onfire'] == nil and player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " catches on fire!") end
      creat:give_condition('onfire',random(1,5))
    end
  end
  
  if (self.firstturn == false) then
    --Burn nearby features:
    for x = self.x-1,self.x+1,1 do
      for y = self.y-1,self.y+1,1 do
        if type(currMap[x][y]) == "table" and currMap[x][y].fireChance and random(1,100) <= currMap[x][y].fireChance then
          currMap[x][y]:combust()
          currMap:change_tile(".",x,y)
        end
        for id, content in pairs(currMap.contents[x][y]) do
          if content.fireChance and random(1,100) <= content.fireChance then
            content:combust()
          end --end feature check 
        end --end for loop
      end --end y loop
    end --end x loop
  else
    self.firstturn = false
  end --end grass and tree chunk
  
  -- Count down the fire:
  self.timer = self.timer - 1
  if (self.timer < 1) then
    self:delete()
  end
end --end advance function
effects['fire'] = fire

local dmgPopup = {
  name = "Damage",
  description = "Shows how much damage just got done.",
  countdown = 1,
  symbol = "!",
  noDesc = true,
  color={r=255,g=0,b=0,a=255},
  use_color_with_tiles = true,
  yMod = 0,
  speed=100
}
function dmgPopup:update(dt)
  if (self.y) then
    self.countdown = self.countdown - dt
    self.color.a = 255*self.countdown
    self.yMod = self.yMod - self.speed*dt-((1-self.countdown)*3)
    if (self.countdown <= 0) then
      self:delete()
    end --end countdown if
  end --end self.y if
end --end function
function dmgPopup:new()
  self.speed = random(25,150)
end
effects['dmgpopup'] = dmgPopup

local heart = {
  name = "Heart",
  description = "It loves you!",
  countdown = 1.5,
  symbol = "<3",
  noDesc = true,
  color={r=255,g=0,b=0,a=225},
  yMod = -10,
  xMod = 0,
  xChange = 50
}
function heart:new()
  if random(1,2) == 1 then self.xChange = -50 end 
end
function heart:update(dt)
  if (self.y) then
    self.countdown = self.countdown - dt
    self.color = {r=255,g=0,b=0,a=150*self.countdown}
    self.yMod = self.yMod - 25*dt
    self.xMod = self.xMod + self.xChange*dt
    if self.xMod >= 10 then self.xChange = -50 elseif self.xMod <= -10 then self.xChange = 50 end
    if (self.countdown <= 0) then
      self:delete()
    end --end countdown if
  else
    self:delete()
  end --end self.y if
end --end function
effects['heart'] = heart

local chunkmaker = {
  name = "Chunkmaker",
  description = "Animated bit that makes creature chunks.",
  countdown = .01,
  symbol = "",
  noDesc = true,
  distance = 0,
  stopsInput = true,
  alreadyDone = {},
  color={r=255,g=255,b=255,a=0}
}
function chunkmaker:new(creat)
  self.creature = creat
  self.maxDist = (creat.level > 0 and math.ceil(creat.level/3) + 1 or 1)
  if self.creature and self.creature.bloodColor then
    self.bloodColor = self.creature.bloodColor
  end
end
function chunkmaker:update(dt)
  if (self.countdown <= 0 and self.chunked ~= true) then
    self.countdown = .01
    for x=self.x-self.distance,self.x+self.distance do
      for y=self.y-self.distance,self.y+self.distance do
        if self.alreadyDone[x .. "," .. y] ~= true and calc_distance(x,y,self.x,self.y) <= self.maxDist and currMap:is_line(self.creature.x,self.creature.y,x,y) then
          self.alreadyDone[x .. "," .. y] = true
          local chunk = Feature('chunk',self.creature)
          currMap:add_feature(chunk,x,y)
          --display wall or stairs if chunk lands on wall or stairs:
          if (currMap[x][y] == "#") then chunk.symbol="#"
          else --make features display properly
            local delete = false
            if (currMap[x][y].baseType == "feature") then
              if currMap[x][y].absorbs then delete = true
              elseif currMap[x][y].water == true then --make the water red
                chunk.color = (self.bloodColor or {r=255,g=0,b=0,a=125})
                chunk.symbol = "≈"
                currMap[x][y].color=(self.bloodColor or {r=255,g=0,b=0,a=255})
              elseif currMap[x][y].alwaysDisplay == true then
                content.color=(self.bloodColor or {r=255,g=0,b=0,a=content.color.a})
              end
            end ---end feature display if
            --now go over the features of the tile to display right:
            for id,content in pairs(currMap.contents[self.x][self.y]) do
              if (content.baseType == "feature") then
                if (content.id == "bridge") then delete = false --chunks will display on bridges
                elseif (content.water == true) then --make the water red
                  chunk.color = (self.creature.bloodColor or {r=255,g=0,b=0,a=125})
                  chunk.symbol = "≈"
                  content.color={r=255,g=0,b=0}
                elseif (content.alwaysDisplay == true) then content.color=(self.bloodColor or {r=255,g=0,b=0,a=content.color.a}) --color other features that demand to be displayed red
                elseif content.absorbs then delete = true end
              end --end feature if
            end --end content for
            if delete == true then chunk:delete() end
          end -- end tile display if
          
          --Damage creatures:
          local creat = currMap:get_tile_creature(x,y)
          if creat ~= false then
            local dmg = creat:damage(random(self.creature.level,self.creature.level*3))
            output:out(creat:get_name() .. " gets hit by a flying " .. self.creature.name .. " chunk and takes " .. dmg .. " damage!")
            if creat ~= player then creat:give_condition('stunned',1,self) end
            if creat.hp <= 0 then
              creat.explosiveDeath = true
              creat.secondaryExplosion = true
              achievements:give_achievement('explosion_kill')
              if self.creature.secondaryExplosion then
                achievements:give_achievement('chain_explosion_kill')
              end
            end
          end --end if creat
          
        end --end distance/line check
      end -- end fory
    end -- end forx
    --Increase distance for next chunks, or delete yourself
    if self.distance == self.maxDist then self:delete()
    else self.distance = self.distance + 1 end
  else --if self.countdown is not 0
    self.countdown = self.countdown - dt
  end
end
effects['chunkmaker'] = chunkmaker

--Animation effects:
local animation = {
  name = "animation",
  description = "A n-frame animation..",
  noDesc = true,
  symbol = "",
  countdown = .1,
  tilemap = true,
  color={r=255,g=255,b=255,a=255}
}
function animation:new(info)
  --image_name,image_max,target,color,ascii,use_color_with_tiles,repetitions,backwards,ignoreTurns,stopsInput,time_per_tile
  self.image_name = info.image_name
  self.image_max = info.image_max
  self.color = info.color or {r=255,g=255,b=255,a=255}
  self.target = info.target
  self.ascii = info.ascii or true
  self.use_color_with_tiles = info.use_color_with_tiles
  self.repetitions = info.repetitions or 0
  self.time_per_tile = self.time_per_tile or .1
  self.countdown = self.time_per_tile

  self.image_frame = (info.backwards and info.frames or 1)
  self.firstTurn = true
  self.repetition = 1
  self.backwards=info.backwards
  self.ignoreTurns=info.ignoreTurns
  self.stopsInput=info.stopsInput
end
function animation:update(dt)
  self.countdown = self.countdown - dt
  if self.countdown <= 0 then
    self.countdown = self.time_per_tile
    self.image_frame = math.max(self.image_frame + (self.backwards and -1 or 1),1)
    if (not self.backwards and self.image_max >= self.image_frame) or (self.backwards and self.image_frame ~= 1) then --if you haven't reached the last frame
      if self.ascii then
        if self.image_frame == 2 then self.symbol = "*"
        elseif self.image_frame == 3 then self.symbol = "#"
        elseif self.image_frame == 4 then self.symbol = "*"
        elseif self.image_frame == 5 then self.symbol = "." end
      end
    else
      if self.repetitions == 0 or self.repetition == self.repetitions then
        self.done = true
        self:delete()
      else
        self.image_frame = (self.backwards and self.image_max or 1)
        self.repetition = self.repetition + 1
      end
    end
  end
end
function animation:advance()
  if self.firstTurn ~= true and not self.ignoreTurns then
    self.done = true
    self:delete()
  else
    self.firstTurn = false
    if self.target then self.x,self.y = self.target.x,self.target.y end
  end
end
effects['animation'] = animation

local featureanimator = {
  name = "Feature Animator",
  noDesc = true,
  noDisp = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "",
}
function featureanimator:new(info)
  self.x,self.y = info.x,info.y
  self.feature = info.feature
  self.feature.animated=true
  self.image_base = info.image_base
  self.image_max = info.image_max
  self.sequence = info.sequence
  self.reverse = info.reverse
  self.speed = info.speed or 0.25
  self.countdown = self.speed
  self.lightColors = info.lightColors
  self.lightColorsMatch = info.lightColorsMatch
  self.paused = info.paused
  self.noAnim = info.noAnim
end
function featureanimator:advance()
  if player:can_see_tile(self.x,self.y) then
    self.seen = true
  else
    self.seen = false
  end
end
function featureanimator:update(dt)
  if self.paused or (not self.seen and not self.feature.castsLight) then return false end
  self.countdown = self.countdown - dt
  if self.countdown < 0 then
    local imageNum = nil
    if not self.noAnim then
      if self.sequence == true then
        local currNum = tonumber(string.sub(self.feature.image_name,-1))
        if (not self.reversing and currNum == self.image_max) or (self.reversing and currNum == 1) then
          if self.reverse then
            self.reversing = not self.reversing
          else
            imageNum = 1
          end
        end -- end image loop if
        if imageNum == nil then imageNum = (currNum+(self.reversing and -1 or 1)) end
      else --random image
        imageNum = random(1,self.image_max)
        local loopCount = 0
        while self.image_base .. imageNum == self.feature.image_name and loopCount < 10 do --don't show the same image twice
          imageNum = random(1,self.image_max)
          loopCount = loopCount + 1
        end
      end
      self.feature.image_name = self.image_base .. imageNum
      if self.features then
        for _,feat in pairs(self.features) do
          feat.image_name = self.image_base .. imageNum
        end
      end
    end --end noanim if
    --Change the light color, if necessary
    if self.lightColorsMatch then
      self.feature.lightColor = self.lightColors[imageNum]
      currMap:refresh_light(self.feature)
      if self.features then
        for _,feat in pairs(self.features) do
          feat.lightColor = self.lightColors[imageNum]
          currMap:refresh_light(feat)
        end
      end
      currMap:refresh_light(self.feature)
    elseif self.lightColors then
      local lightNum = random(1,count(self.lightColors))
      local loopCount = 0
      local color = self.lightColors[lightNum]
      while self.feature.lightColor and (color.r == self.feature.lightColor.r and color.g == self.feature.lightColor.g and color.b == self.feature.lightColor.b and color.a == self.feature.lightColor.a and loopCount < 10) do
        lightNum = random(1,count(self.lightColors))
        loopCount = loopCount + 1
      end
      self.feature.lightColor = self.lightColors[lightNum]
      currMap:refresh_light(self.feature)
      if self.features then
        for _,feat in pairs(self.features) do
          feat.lightColor = self.lightColors[lightNum]
          currMap:refresh_light(feat)
        end
      end
    end --end color if
    self.countdown = self.speed
  end --end if self.countdown
end
effects['featureanimator'] = featureanimator

local featuremaker = {
  name = "Animated Feature Maker",
  noDesc = true,
  noDisp = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "",
  stopsInput = true,
}
function featuremaker:new(args)
  self.tiles = args.tiles
  self.speed = args.speed or 0
  self.feature = args.feature
  self.featureArgs = args.args
  self.replace = args.replace or false
  self.destroy = args.destroy or false
  self.features = {}
  self.countdown = self.speed
  self.shake = args.shake
  self.after = args.after
  self.avoidPlayer = args.avoidPlayer
  self.avoidCreatures = args.avoidCreatures
  self.requiresClear = args.requiresClear
end
function featuremaker:update(dt)
  self.countdown = self.countdown - dt
  if self.shake then output.camera.xMod,output.camera.yMod = random(-5,5),random(-5,5) end
  if count(self.tiles) == 0 then
    if self.after then
      self.after()
    end
    self:delete()
    currMap:clear_all_pathfinders()
    refresh_player_sight()
    if self.shake then output.camera.xMod,output.camera.yMod = 0,0 end
  elseif self.countdown <= 0 then
    self.countdown = self.speed
    local tileID = next(self.tiles)
    local tile = self.tiles[tileID]
    if self.avoidCreatures and currMap:tile_has_creature(tile.x,tile.y) then
      table.remove(self.tiles,tileID)
      return
    elseif self.avoidPlayer and player.x == tile.x and player.y == tile.y then
      table.remove(self.tiles,tileID)
      return
    end
    if self.requiresClear and not currMap:isClear(tile.x,tile.y,nil,true,true) then
      table.remove(self.tiles,tileID)
      return
    end
    if currMap:tile_has_feature(tile.x,tile.y,self.feature) then
      table.remove(self.tiles,tileID)
      return
    end
    local f = Feature(self.feature)
    f.x,f.y = tile.x,tile.y
    if self.replace then
      currMap:change_tile(f,tile.x,tile.y,true)
      if possibleFeatures[f.id].placed then possibleFeatures[f.id].placed(f,currMap) end
    else
      currMap:add_feature(f,tile.x,tile.y)
    end --end replace if
    if self.destroy then
      for _,feat in pairs(currMap:get_tile_features(tile.x,tile.y)) do
        feat:delete()
      end
    end
    for x=f.x-1,f.x+1,1 do
      for y=f.y-1,f.y+1,1 do
        currMap:refresh_tile_image(x,y)
      end --end fory
    end --end forx
    self.features[#self.features+1] = f
    table.remove(self.tiles,tileID)
  end --end countdown if
end --end function
effects['featuremaker'] = featuremaker

local projectileemitter = {
  name = "Projectile Emitter",
  noDesc = true,
  noDisp = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "Emits projectiles randomly in the area around itself.",
  turns=5,
  countdown=5,
  range=3
}
function projectileemitter:new(info)
  self.projectileID = info.projectileID
  self.turns = info.turns or 5
  self.range = info.range or 3
  self.tweakCountdown = info.tweakCountdown
  self.countdown = (self.tweakCountdown and tweak(self.turns) or self.turns)
  self.feature = info.feature --the feature, if any, this projectileemitter is attached to. The emitter will delete itself if this feature stops existing
  self.tiles = info.tiles --a table of x and y values for potential targets. Defaults to selecting them randomly
  self.sequence = info.sequence --if true, the tiles listed will be targeted in order
  self.current_tile = info.current_tile or 1 --if sequence is true, this is the number in the sequence to start with
  self.reverse = info.reverse --if true, and sequence is also true, then at the end of the tile list
  self.reversing = info.reversing or false --if true, and sequence is also true, go through the tile list backwards. If reverse is true, upon reaching the end of the list the direction will flip
  self.shots = info.shots or 1
end
function projectileemitter:advance()
  if self.feature and not currMap:tile_has_feature(self.feature.x,self.feature.y,self.feature.id) then
    self:delete()
    return
  end
  self.countdown = self.countdown - 1
  if self.countdown < 1 then
    local selectedTiles = {}
    for i=1,self.shots,1 do
      local tile={}
      if self.tiles then
        if self.sequence then --If tiles are set to display in a sequence
          if not selectedTiles[self.current_tile] then tile = self.tiles[self.current_tile] end
          selectedTiles[self.current_tile] = true
          local tries = 0
          while tries < 10 and selectedTiles[self.current_tile] do
            self.current_tile = self.current_tile + (self.reversing and -1 or 1)
            if self.current_tile > #self.tiles then --if we've reached the end
              self.current_tile = (self.reverse and #self.tiles-1 or 1)
              if self.reverse then self.reversing = not self.reversing end
            elseif self.current_tile < 1 then --if we've reached the beginning, this will only happen if we're counting down (ie reversing is set to TRUE)
              self.current_tile = (self.reverse and 2 or #self.tiles)
              if self.reverse then self.reversing = not self.reversing end
            end
            tries = tries+1
          end
        else --pick a random tile
          local tileK = get_random_key(self.tiles)
          local tries = 0
          while selectedTiles[tileK] and tries < 10 do
            tileK = get_random_key(self.tiles)
            tries = tries + 1
          end
          if tries >= 10 then
            tile = false
          else
            tile = self.tiles[tileK]
            selectedTiles[tileK] = true
          end
        end
      else --no preset tiles, pick a random spot in range
        local x,y = random(self.x-self.range,self.x+self.range),random(self.y-self.range,self.y+self.range)
        local tries = 0
        local dist = calc_distance(self.x,self.y,x,y)
        while (dist > self.range or selectedTiles[x .. ',' .. y] == true) and tries < 10 do
          local x,y = random(self.x-self.range,self.x+self.range),random(self.y-self.range,self.y+self.range)
          dist = calc_distance(self.x,self.y,x,y)
          tries = tries + 1
        end
        if tries >= 10 then
          tile = false
        else
          tile.x,tile.y = x,y
          selectedTiles[x .. ',' .. y] = true
        end
      end
      if tile then Projectile(self.projectileID,(self.feature or self),tile) print('tile ' .. i,tile.x,tile.y) end
    end
    self.countdown = (self.tweakCountdown and tweak(self.turns) or self.turns)
  end
end
effects['projectileemitter'] = projectileemitter

local conditionanimation = {
  name = "Condition Animation",
  noDesc = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "a",
  remove_on_cleanup=true
}
function conditionanimation:new(info)
  --Don't add multiples of the same animation:
  for _,con in pairs(currMap.effects) do
    if con.id == "conditionanimation" and con.condition == info.condition and con.image_base == info.image_base and con.owner == info.owner then
      self.selfDestruct=true
    end
  end
  self.owner = info.owner
  self.condition = info.condition
  self.x,self.y = self.owner.x,self.owner.y
  self.image_base = info.image_base
  self.image_max = info.image_max
  self.image_name = self.image_base .. (not info.spritesheet and "1" or "")
  self.sequence = info.sequence
  self.reverse = info.reverse
  self.reversing = info.reversing
  self.speed = info.speed or 0.25
  self.countdown = self.speed
  self.symbol = info.symbol or ""
  self.symbols = info.symbols
  self.color = info.color or {r=0,g=0,b=0,a=0}
  self.colors = info.colors
  self.use_color_with_tiles = info.use_color_with_tiles
  self.castsLight=info.castsLight
  self.lightDist=info.lightDist
  self.lightColors = info.lightColors
  self.seen = true
  self.yMod = info.yMod
  self.yModBase = info.yMod or 0
  self.xMod = info.xMod
  self.xModBase = info.xMod or 0
  self.tilemap = info.tilemap
  self.spritesheet = info.spritesheet
  if self.spritesheet then self.image_frame = 1 end
end
function conditionanimation:advance()
  if player:can_see_tile(self.x,self.y) then
    self.seen = true
  else
    self.seen = false
  end
  if not self.owner:has_condition(self.condition) or self.owner.hp < 1 then
    self:delete()
  end
end
function conditionanimation:update(dt)
  if self.selfDestruct == true then
    return self:delete()
  end
  self.x,self.y = self.owner.x,self.owner.y
  self.xMod,self.yMod = self.owner.xMod+self.xModBase,self.owner.yMod+self.yModBase
  if not self.seen then return false end
  self.countdown = self.countdown - dt
  if self.countdown < 0 then
    local imageNum = nil
    if self.sequence == true then
      local currNum = (self.spritesheet and self.image_frame or tonumber(string.sub(self.image_name,-1)))
      if (not self.reversing and currNum == self.image_max) or (self.reversing and currNum == 1) then
        if self.reverse then
          self.reversing = not self.reversing
        elseif self.reversing then
          imageNum = self.image_max
        else
          imageNum = 1
        end
      end -- end image loop if
      if imageNum == nil then imageNum = (currNum+(self.reversing and -1 or 1)) end
    else --random image
      imageNum = random(1,self.image_max)
      local loopCount = 0
      while self.image_base .. imageNum == self.image_name and loopCount < 10 do --don't show the same image twice
        imageNum = random(1,self.image_max)
        loopCount = loopCount + 1
      end
    end
    if self.spritesheet then
      self.image_frame = imageNum
    else
      self.image_name = self.image_base .. imageNum
    end
    --Change the light color, if necessary
    if self.lightColors then
      self.lightColor = self.lightColors[imageNum]
      currMap:refresh_light(self)
    end --end lightcolor if
    if self.colors then
      self.color = self.colors[imageNum] or self.color
    end
    self.countdown = self.speed
  end --end if self.countdown
end
effects['conditionanimation'] = conditionanimation

local screenShaker = {
  name = "Screen Shaker",
  noDesc = true,
  noDisp = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "This invisible effect shakes the screen.",
  stopsInput = true,
  shakeTime=2,
}
function screenShaker:new(time)
  self.shakeTime = time or 2
end
function screenShaker:update(dt)
  if self.shakeTime > 0 then
    self.shakeTime = self.shakeTime - dt
    output.camera.xMod,output.camera.yMod = random(-5,5),random(-5,5)
  else
    self:delete()
    output.camera.xMod,output.camera.yMod = 0,0
  end
end
effects['screenshaker'] = screenShaker

local angelofdeath = {
  name = "Angel of Death",
  noDesc = true,
  noDisp = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "This invisible effect KILLS EVERYONE.",
}
function angelofdeath:update(dt)
  for _,creat in pairs(currMap.creatures) do
    if creat ~= player then
      if random(1,4) == 1 then
          creat.level = random(1,5)
          creat:explode()
      else
        creat:die()
      end
    end
  end
  self:delete()
end
effects['angelofdeath'] = angelofdeath