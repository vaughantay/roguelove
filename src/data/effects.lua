effects = {}

local poisonGas = {
	name = "poison gas",
	description = "A cloud of deadly gas!",
	strength = 6,
  hazard = 5,
	symbol = "§",
	color={r=0,g=255,b=0,a=250},
  remove_on_cleanup=true
}
function poisonGas:new()
  self.image_name = "poisongas" .. random(1,4)
  self.color = {r=0,g=255,b=0,a=250}
end
function poisonGas:advance()
	local creat = currMap:get_tile_creature(self.x,self.y)
	if (creat) and self.strength > 0 then
		local dmg = creat:damage(tweak(self.strength),self.creator,"poison")
    if (dmg > 0 and player:can_see_tile(self.x,self.y)) then output:out(creat:get_name() .. " chokes on the poison gas, taking " .. dmg .. " damage.") end
	end
	self.strength = self.strength - 1
  self.image_name = "poisongas" .. random(1,4)
  tween(.1,self.color,{a=self.strength*50})
  --self.color = {r=0,g=255,b=0,a=self.strength*50}
end
function poisonGas:update(dt)
  if self.strength <= 0 then
    self:delete()
  end
end
effects['poisongas'] = poisonGas

local smoke = {
  name = "smoke",
  description = "Thick smoke.",
  strength = 10,
  symbol = "#",
  blocksSight = true,
  color={r=200,g=200,b=200,a=200},
  image_varieties=4,
  remove_on_cleanup=true
}
function smoke:new()
  self.color={r=200,g=200,b=200,a=200}
end
function smoke:advance()
  self.strength = self.strength-1
  tween(.1,self.color,{a=self.strength*50})
  local imvar = random(1,4)
  self.image_name = "smoke" .. imvar
  self.image_variety = imvar
  --Spread to nearby tiles if you're strong enough:
  if (self.strength > 5) and not self.nospread then
    for x=self.x-1,self.x+1,1 do
      for y=self.y-1,self.y+1,1 do
        if (currMap[x][y] ~= "#") then
          local makeSmoke = true
          for _,eff in pairs(currMap:get_tile_effects(x,y)) do
            if eff.id == "smoke" then makeSmoke = false break end
          end -- end effects for
          if (makeSmoke == true) then
            local s = Effect('smoke')
            s.strength = self.strength
            currMap:add_effect(s,x,y)
          end --end makeSmoke if
        end --end wall if
      end --end fory
    end --end forx
  end
end
function smoke:update(dt)
  if self.strength <= 0 then self:delete() end
end
effects['smoke'] = smoke

local sandstorm = {
  name = "sandstorm",
  description = "A whirling, blinding cloud of sand.",
  symbol = "*",
  countdown = .25,
  turns = 10,
  color={r=98,g=73,b=22,a=150},
  blocksSight=true,
  image_name = "sandstorm1",
  hazard=5,
  remove_on_cleanup=true
  --sightReduction = .75
}
function sandstorm:advance()
  self.turns = self.turns - 1
  if self.turns == 0 then self:delete() return end
  local creat = currMap:get_tile_creature(self.x,self.y)
  if creat then
    creat:give_condition('instorm',-1) 
    if creat == player then refresh_player_sight() end
  end
end
function sandstorm:update(dt)
  self.countdown = self.countdown - dt
  if (self.countdown <= 0) then
    self.image_name = "sandstorm" .. random(1,4)
    self.symbol = (random(1,3) == 1 and "&" or (random(1,2) == 1 and "#" or "*"))
    self.countdown = .25
  end
end
effects['sandstorm'] = sandstorm

local darkness = {
  name = "darkness",
  description = "A patch of supernaturally deep darkness. It swallows all light that enters it.",
  symbol = "*",
  turns = 5,
  color={r=0,g=0,b=0,a=200},
  use_color_with_tiles=true,
  image_name="square",
  blocksSight=true,
  remove_on_cleanup=true
}
function darkness:advance()
  local creat = currMap:get_tile_creature(self.x,self.y)
  if creat then
    creat.fear = creat.fear + 5
  end
  self.turns = self.turns - 1
  if self.turns == 0 then self:delete() return end
end
effects['darkness'] = darkness

local bloodrain = {
  name = "rain of blood",
  description = "Blood rains down from above! This is both disgusting, and scary.",
  symbol = "'",
  turns = 10,
  color={r=190,g=38,b=51,a=150},
  image_varieties=2,
  animated=true,
  spritesheet=true,
  image_max=5,
  animation_time = 0.2,
  remove_on_cleanup=true
}
function bloodrain:advance()
  local creat = currMap:get_tile_creature(self.x,self.y)
  if creat then
    if not creat:is_type('undead') then
      creat.fear = creat.fear + 20
      if not creat:is_type('construct') and random(1,5) == 1 then
        creat:give_condition('disease',25)
      end
    end
    if creat:has_spell('vampirism') then
      creat:updateHP(5)
    end
  end
  self.turns = self.turns - 1
  if random(1,4) == 1 and not currMap:tile_has_feature(self.x,self.y,'slipperyblood') then
    currMap:add_feature(Feature('slipperyblood'),self.x,self.y)
  end
  if self.turns == 0 then self:delete() return end
end
function bloodrain:update(dt)
  if self.animCountdown - dt <= 0 then
    local symbol = random(1,3)
    if symbol == 1 then
      self.symbol = "'"
    elseif symbol == 2 then
      self.symbol = '"'
    elseif symbol == 3 then
      self.symbol = ""
    end
  end
end
effects['bloodrain'] = bloodrain

local graspingdead = {
  name = "Grasping Dead",
  description = "Undead hands reaching up through the ground to grab onto the living! Or other undead, they're really not picky.",
  symbol = "*",
  color={r=0,g=125,b=0,a=255},
  animated=true,
  spritesheet=true,
  image_max=7,
  animation_time = 0.1,
  image_varieties=8,
  hazard=20,
  safeFor={flyer=true},
  turns=5,
  remove_on_cleanup=true
}
function graspingdead:new()
  self.turns = random(4,7)
end
function graspingdead:update()
  if self.image_frame == 7 then
    self.image_name = "graspingdead" .. random(1,8)
    self.image_frame = 1
    self.animation_time = .01*random(7,20)
    local symbol = random(1,5)
    if symbol == 1 then
      self.symbol = "/"
    elseif symbol == 2 then
      self.symbol = "\\"
    elseif symbol == 3 then
      self.symbol = "|"
    elseif symbol == 4 then
      self.symbol = "*"
    elseif symbol == 5 then
      self.symbol = "^"
    end
  end
end
function graspingdead:advance()
  self.turns=self.turns-1
  if self.turns == 0 then
    self:delete()
  else
    local creat = currMap:get_tile_creature(self.x,self.y)
    if creat and not creat:is_type('flyer') and creat ~= self.creator then
      local hit = false
      local sees = player:can_see_tile(self.x,self.y)
      if random(1,2) == 1 then
        local dmg = creat:damage(tweak(creat:get_max_hp()/10),self.creator)
        if sees then output:out("The grasping hands of the dead deal " .. dmg .. " damage to " .. creat:get_name() .. "!") end
        hit = true
      end
      if random(1,2) == 1 then
        creat:give_condition('entangled',1)
        hit = true
      end
      if hit and sees then output:sound('graspingdead_hit') end
    end --end creat if
  end --end turns if
end
effects['graspingdead'] = graspingdead

local fireball = {
	name = "fireball",
	description = "Boom!",
	symbol = "#",
	countdown = .25,
  tilemap=true,
  castsLight = true,
	color={r=255,g=0,b=0,a=150},
  remove_on_cleanup=true
}
function fireball:new()
  self.image_name = "fireaura" .. random(1,4)
end
function fireball:update(dt)
  if self.reproduceCountdown then
    self.reproduceCountdown = self.reproduceCountdown - dt
    if self.reproduceCountdown <= 0 then
      self.balls = {}
      self.reproduceCountdown = nil
      for x=self.x-1,self.x+1,1 do
        for y=self.y-1,self.y+1,1 do
          if x~=self.x or y~=self.y then
            local newBall = Effect('fireball')
            newBall.creator = self.creator
            currMap:add_effect(newBall,x,y)
            self.balls[#self.balls+1] = newBall
          end
        end
      end --end forx
      for _, ball in pairs(self.balls) do --immature
        ball:refresh_image_name()
        currMap:refresh_light(ball)
      end
      self:refresh_image_name()
      currMap:refresh_light(self)
    end --end reproducecoundown < 0if
  end --ennd if reproducseconndown
  self.countdown = self.countdown - dt
	if (self.countdown <= 0) then
		self:delete()
	end
end
function fireball:refresh_image_name()
  local directions = ""
  if currMap:tile_has_effect(self.x,self.y-1,'fireball') == false then directions = directions .. "n" end
  if currMap:tile_has_effect(self.x,self.y+1,'fireball') == false then directions = directions .. "s" end
  if currMap:tile_has_effect(self.x+1,self.y,'fireball') == false then directions = directions .. "e" end
  if currMap:tile_has_effect(self.x-1,self.y,'fireball') == false then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end
effects['fireball'] = fireball

local earthquake = {
	name = "earthquake",
	description = "I feel a rumbling.",
	symbol = "≈",
	countdown = .10,
	bigCountdown = .5,
	color={r=111,g=55,b=25,a=150},
  remove_on_cleanup=true
}
function earthquake:update(dt)
  local creat = currMap:get_tile_creature(self.x,self.y)
	if (self.bigCountdown <= 0) then
		self:delete()
    if creat then creat.xMod,creat.yMod = 0,0 end
	elseif (self.countdown <= 0) then
    if creat then creat.xMod,creat.yMod = random(-5,5),random(-5,5) end
		for x = self.x-1,self.x+1,1 do
			for y=self.y-1,self.y+1,1 do
        local makeQuake = true
        if currMap:tile_has_effect(x,y,'earthquake') then makeQuake = false end
        
				if (makeQuake == true and (x ~= self.x or y ~= self.y) and calc_distance(x,y,self.creator.x,self.creator.y) < 5) then
					local quake = Effect('earthquake')
					quake.creator = self.creator
					quake.bigCountdown = self.bigCountdown
          currMap:add_effect(quake,x,y)
				end --end makequake if
			end --end fory
		end --end forx
	end --end if countdown
	self.countdown = self.countdown-dt
	self.bigCountdown = self.bigCountdown-dt
end
effects['earthquake'] = earthquake

local fireaura = {
	name = "fiery aura",
	description = "The intense heat that surrounds an angry lava beast is almost as dangerous as the beast itself.",
	symbol = "#",
	color={r=255,g=0,b=0,a=100},
	countdown = .25,
  tilemap = true,
  hazard = 10,
  castsLight=true,
  remove_on_cleanup=true
}
function fireaura:new(creator)
  self.creator = creator
  self.image_name = "fireaura" .. random(1,4)
end
function fireaura:refresh_image_name()
  local directions = ""
  local xMod,yMod = self.creator.x-self.x,self.creator.y-self.y
  if yMod == 1 and currMap:tile_has_effect(self.x,self.y-1,'fireaura') == false then directions = directions .. "n" end
  if yMod == -1 and currMap:tile_has_effect(self.x,self.y+1,'fireaura') == false then directions = directions .. "s" end
  if xMod == -1 and currMap:tile_has_effect(self.x+1,self.y,'fireaura') == false then directions = directions .. "e" end
  if xMod == 1 and currMap:tile_has_effect(self.x-1,self.y,'fireaura') == false then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end
function fireaura:advance()
	if (self.creator.conditions['fireaura'] == nil or not currMap:touching(self.creator.x,self.creator.y,self.x,self.y) or self.creator.hp < 1) then
		self:delete()
	else
    self:refresh_image_name()
		local creat = currMap:get_tile_creature(self.x,self.y)
		if (creat and creat ~= self.creator) then
			local dmg = creat:damage(tweak(10),self.creator,"fire")
			if (dmg > 0) and player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " takes " .. dmg .. " damage from " .. self.creator:get_name() .. "'s fiery aura.") end
		end
    for _,feat in pairs(currMap:get_tile_features(self.x,self.y)) do
      if feat.fireChance and random(1,100) <= feat.fireChance then
        feat:combust()
      end --end firechance if
    end --end feature for
	end
end
function fireaura:update(dt)
  if math.floor(calc_distance(self.creator.x,self.creator.y,self.x,self.y)) > 1 then self:delete() end
	self.countdown = self.countdown - dt
	if (self.countdown <= 0) then
		self.countdown = .25
		if (self.color.g == 0) then
			self.color.g=255
		elseif (self.color.g == 255) then
			self.color.g=142
		else
			self.color.g=0
		end
    self.image_name = "fireaura" .. random(1,4)
    self:refresh_image_name()
    currMap:refresh_light(self)
	end
end
effects['fireaura'] = fireaura

local spores = {
	name = "fungal spores",
	description = "Mildly hallucinogenic fungal spores. They're perfectly harmless, as long as you don't breathe them in.",
	symbol = "*",
	color={r=0,g=255,b=0,a=250},
	strength = 5,
  remove_on_cleanup=true
}
function spores:new()
  self.color = {r=0,g=255,b=0,a=250}
end
function spores:advance()
	local creat = currMap:get_tile_creature(self.x,self.y)
	if (creat and creat.id ~= "shroomman") then
		local dmg = creat:damage(tweak(self.strength),self.creator,"poison")
		if (dmg > 0) then
      if player:can_see_tile(creat.x,creat.y) then
        output:out(creat:get_name() .. " chokes on the spores, taking " .. dmg .. " damage.")
        if creat == player then output:sound('cough') end
      end
      creat:give_condition('confused',2)
      self:delete()
    end
	end
	self.strength = self.strength - 1
  tween(.1,self.color,{a=self.strength*50})
  --self.color = {r=0,g=255,b=0,a=self.strength*25}
  local moveX,moveY = random(self.x-1,self.x+1),random(self.y-1,self.y+1)
  if currMap:in_map(moveX,moveY) and (currMap[moveX][moveY] ~= "#") then
    self:moveTo(moveX,moveY,.1)
		--self.x, self.y = moveX,moveY
  end
end
function spores:update(dt)
  if self.strength <= 0 then self:delete() end
end
effects['spores'] = spores

local slimemaker = {
  name = "Slimemaker",
  description = "Animated bit that makes creature chunks.",
  countdown = .05,
  symbol = "",
  chunked = false,
  noDesc = true,
  stopsInput = true,
  distance = 0,
  maxDist = 3,
  alreadyDone = {},
  slimes = {},
  color={r=255,g=255,b=255,a=0}
}
function slimemaker:new(creat)
  self.creature = creat
end
function slimemaker:update(dt)
  if (self.countdown <= 0 and self.chunked ~= true) then
    self.countdown = .05
    for x=self.x-self.distance,self.x+self.distance do
      for y=self.y-self.distance,self.y+self.distance do
        if x>1 and y>1 and x<currMap.width and y<currMap.height and currMap[x][y] ~= "#" and self.alreadyDone[x .. "," .. y] ~= true and calc_distance(x,y,self.x,self.y) <= self.maxDist and currMap:is_line(self.creature.x,self.creature.y,x,y) then
          self.alreadyDone[x .. "," .. y] = true
          local chunk = Feature('slime',self.creature.name)
          chunk.x,chunk.y = x,y
          self.slimes[#self.slimes+1] = chunk
          --display wall or stairs if chunk lands on wall or stairs:
          local delete = false
          if (currMap[x][y] == "#") then delete = true
          else --make features display properly
            if (currMap[x][y].baseType == "feature") then
            if currMap[x][y].absorbs or currMap[x][y].blocksMovement or currMap[x][y].id == "slime" or currMap[x][y].water == true then delete = true end
            end ---end feature display if
            --now go over the features of the tile to display right:
            for id,content in pairs(currMap.contents[self.x][self.y]) do
              if (content.baseType == "feature") then
                if (content.id == "bridge") then delete = false --chunks will display on bridges
                elseif (content.alwaysDisplay == true) then content.color={r=0,g=255,b=0} --color other features that demand to be displayed green
                elseif content.absorbs or content.blocksMovement or content.id == "slime" or content.water == true then delete = true end
              end --end feature if
            end --end content for
            if delete == false then
              currMap:add_feature(chunk,x,y)
            end
          end -- end tile display if
          
          --Damage creatures:
          local creat = currMap:get_tile_creature(x,y)
          if creat ~= false then
            if player:can_sense_creature(creat) then output:out(creat:get_name() .. " gets covered in slime!") end
            creat:give_condition('slimy',5)
          end --end if creat
          
        end --end distance/line check
      end -- end fory
    end -- end forx
    --Increase distance for next chunks, or delete yourself
    if self.distance == self.maxDist then
      for _, slime in pairs(self.slimes) do
        slime:refresh_image_name()
      end
      self:delete()
    else self.distance = self.distance + 1 end
  else --if self.countdown is not 0
    self.countdown = self.countdown - dt
  end
end
effects['slimemaker'] = slimemaker

local lavamaker = {
  name = "Lavamaker",
  description = "Animated bit that makes creature chunks.",
  countdown = .05,
  symbol = "",
  chunked = false,
  noDesc = true,
  stopsInput = true,
  distance=0,
  maxDist = 3,
  alreadyDone = {},
  lavas = {},
  color={r=255,g=0,b=0,a=255}
}
function lavamaker:new(creat)
  self.creature = creat
end
function lavamaker:update(dt)
  if (self.countdown <= 0 and self.chunked ~= true) then
    self.countdown = .05
    for x=self.x-self.distance,self.x+self.distance do
      for y=self.y-self.distance,self.y+self.distance do
        local dist = calc_distance(x,y,self.x,self.y)
        if currMap:in_map(x,y) and self.alreadyDone[x .. "," .. y] ~= true and dist <= self.maxDist and currMap:is_line(self.creature.x,self.creature.y,x,y) then
          self.alreadyDone[x .. "," .. y] = true
          local chunk = Feature('ember',self.creature.name)
          chunk.heat = 10-dist
          --display wall or stairs if chunk lands on wall or stairs:
          local delete = false
          if (currMap[x][y] == "#") then delete = true
          else --make features display properly
            if (currMap[x][y].baseType == "feature") then
              if currMap[x][y].absorbs or currMap[x][y].blocksMovement or currMap[x][y].id == "lava" or currMap[x][y].water == true then delete = true end
            end ---end feature display if
            --now go over the features of the tile to display right:
            for id,content in pairs(currMap.contents[self.x][self.y]) do
              if (content.baseType == "feature") then
                if (content.id == "bridge") then delete = false --chunks will display on bridges
                elseif content.absorbs or content.blocksMovement or content.id == "lava" or content.id == "water" then delete = true end
              end --end feature if
            end --end content for
            if delete == true then
              chunk = nil
            else
              table.insert(self.lavas,chunk)
              currMap:add_feature(chunk,x,y)
              if random(1,(20-chunk.heat)) == 1 then
                currMap:add_effect(Effect('fire',{x=x,y=y,timer=chunk.heat}),x,y)
              end
            end
          end -- end tile display if
          
          --Damage creatures:
          local creat = currMap:get_tile_creature(x,y)
          if creat ~= false then
            local dmg = creat:damage(random(10,25),nil,"fire")
            output:out(creat:get_name() .. " gets hit by flying lava and takes " .. dmg .. " damage!")
          end --end if creat
          
        end --end distance/line check
      end -- end fory
    end -- end forx
    --Increase distance for next chunks, or delete yourself
    if self.distance == self.maxDist then
      self:delete()
      for _,lava in pairs(self.lavas) do
        for x=lava.x-1,lava.x+1,1 do
          for y=lava.y-1,lava.y+1,1 do
            local l = currMap:tile_has_feature(x,y,'ember')
            if l then l:refresh_image_name() end
          end --end fory
        end --end forx
      end --end lava for
    else
      self.distance = self.distance + 1
    end
  else --if self.countdown is not 0
    self.countdown = self.countdown - dt
  end
end
effects['lavamaker'] = lavamaker

local absinthefairy = {
  name = "Fairy",
  description = "It's...so...beautiful...",
  symbol = "&",
  color={r=255,g=255,b=255,a=125},
  use_color_with_tiles=true,
  remove_on_cleanup=true
}
function absinthefairy:new(creat)
  self.creature = creat
  self.color = {r=random(0,255),g=random(0,255),b=random(0,255),a=random(0,255)}
  self.toColor = {r=random(0,255),g=random(0,255),b=random(0,255),a=random(0,255)}
  self.toAmt = {r=math.ceil((self.toColor.r-self.color.r)/10),g=math.ceil((self.toColor.g-self.color.g)/10),b=math.ceil((self.toColor.b-self.color.b)/10),a=math.ceil((self.toColor.a-self.color.a)/10)} --
  self.countdown = .05 --switch colors every .05 of a second
  self.newColorCountdown = .5 --switch target colos every half a second
end --end new function
function absinthefairy:update(dt)
  if not player:has_condition('wasted') then
    return self:delete()
  end
  self.countdown = self.countdown - dt
  self.newColorCountdown = self.newColorCountdown - dt
  if self.newColorCountdown <= 0 then --every second, set a new target color
    self.toColor = {r=random(0,255),g=random(0,255),b=random(0,255),a=random(0,255)}
    self.toAmt = {r=math.ceil((self.toColor.r-self.color.r)*dt),g=math.ceil((self.toColor.g-self.color.g)*dt),b=math.ceil((self.toColor.b-self.color.b)*dt),a=math.ceil((self.toColor.a-self.color.a)*dt)}
    self.countdown = 0 --go ahead and switch the actual color too
    self.newColorCountdown = .5
    self.xMod,self.yMod = random(-2,2),random(-2,2)
  end
  if self.countdown <= 0 then
    self.countdown = .05
    self.color={r=self.color.r+self.toAmt.r,g=self.color.g+self.toAmt.g,b=self.color.b+self.toAmt.b,a=self.color.a+self.toAmt.a}
  end
end
function absinthefairy:advance()
  if random(1,20) == 1 then self:delete() return end
  local newX,newY=math.max(math.min(self.x+random(-1,1),currMap.width),1),math.max(math.min(self.y+random(-1,1),currMap.height),1)
  self:moveTo(newX,newY,.1)
end
effects['absinthefairy'] = absinthefairy

local ratswarm = {
	name = "rat swarm",
	description = "A swarm of hungry rats!",
	strength = 10,
  hazard = 25,
  safeFor={rat=true},
	symbol = "&",
	color={r=153,g=103,b=73,a=255},
  countdown = .1,
  image_name = "ratswarm1",
  remove_on_cleanup=true
}
function ratswarm:advance()
	local creat = currMap:get_tile_creature(self.x,self.y)
	if creat and not creat:is_type('rat') and not creat:is_type('ratling') then
		local dmg = creat:damage(tweak(creat:get_max_hp()/10),self.creator)
    if (dmg > 0 and player:can_see_tile(self.x,self.y)) then
      output:out("The rat swarm bites " .. creat:get_name() .. " for " .. dmg .. " damage.") self.strength = self.strength-1
      output:sound('ratswarm_damage')
    end
  elseif creat and creat == self.creator then
    self.creator.cooldowns['Rat Sarm'] = nil
    self:delete()
  else --if there's not a creature on your tile
    local startX,startY = (random(1,2) == 1 and 1 or -1),(random(1,2) == 1 and 1 or -1) --move in a random direction
    for x=self.x-startX,self.x+startX,startX do
      for y=self.y-startY,self.y+startY,startY do
        local creat = currMap:get_tile_creature(x,y)
        if creat and not creat:is_type('rat') and not creat:is_type('ratling') then --move to first seen non-rat creature
          local xChange,yChange = self:moveTo(x,y,false)
          if not prefs['noSmoothMovement'] then
            if self.moveTween then
              Timer.cancel(self.moveTween)
            end
            self.xMod,self.yMod = (self.xMod or 0)-xChange,(self.yMod or 0)-yChange
            self.moveTween = tween(.1,self,{xMod=0,yMod=0})
          end
          --self.x,self.y=x,y
          return self:advance() --then bite 'em!
        end --end if creat
      end --end fory
    end -- end forx
	end --end no creature else
  if self.strength < 1 then
    self:delete()
  end
  --if there's no creature on a nearby tile, then move towards master if seen
  local line = (creat == false and currMap:get_line(self.x,self.y,self.creator.x,self.creator.y,false,nil,true) or false)
  if line and #line > 0 then
    self.x,self.y = line[1][1],line[1][2]
  elseif creat == false then --if master's not seen, move in a random direction
    local xMod,yMod = random(-1,1),random(-1,1)
    if currMap:isClear(self.x+xMod,self.y+yMod) then
      self:moveTo(self.x+xMod,self.y+yMod)
      --self.x,self.y = self.x+xMod,self.y+yMod
    end
  end
end
function ratswarm:update(dt)
  self.countdown = self.countdown - dt
  if (self.countdown <= 0) then
    self.symbol = (random(1,3) == 1 and "&" or (random(1,2) == 1 and "%" or "#"))
    self.image_name = "ratswarm" .. random(1,4)
    self.countdown = .1
  end
end --end update function
effects['ratswarm'] = ratswarm

local scarabs = {
	name = "scarab swarm",
	description = "A swarm of hungry scarabs!",
	strength = 10,
  hazard = 25,
	symbol = "&",
	color={r=33,g=33,b=33,a=255},
  countdown = .1,
  image_name = "scarabs1",
  remove_on_cleanup=true
}
function scarabs:advance()
  self.strength = self.strength-1
  if self.strength == 0 then self:delete() return end
	local creat = currMap:get_tile_creature(self.x,self.y)
	if (creat) then
		local dmg = creat:damage(tweak(5),self.creator)
    if (dmg > 0 and player:can_see_tile(self.x,self.y)) then
      output:out("The scarab swarm bites " .. creat:get_name() .. " for " .. dmg .. " damage.")
      output:sound('squirming')
    end
  else --if there's not a creature on your tile
    local startX,startY = (random(1,2) == 1 and 1 or -1),(random(1,2) == 1 and 1 or -1) --move in a random direction
    for x=self.x-startX,self.x+startX,startX do
      for y=self.y-startY,self.y+startY,startY do
        local creat = currMap:get_tile_creature(x,y)
        if creat then --move to first seen creature
          self:moveTo(x,y,.1)
          --self.x,self.y=x,y
          return self:advance() --then bite 'em!
        end --end if creat
      end --end fory
    end -- end forx
    --if no creature has been found, move in random direction
    local xMod,yMod = random(-1,1),random(-1,1)
    local tries = 0
    while tries <= 10 and ((xMod == 0 and yMod == 0) or currMap:isClear(self.x+xMod,self.y+yMod,nil,false) == false) do --if you're not moving, or the new tile is blocked, select another random tile
      xMod,yMod = random(-1,1),random(-1,1)
      tries = tries + 1
    end
    self:moveTo(self.x+xMod,self.y+yMod)
    --self.x,self.y=self.x+xMod,self.y+yMod
	end --end no creature else
end
function scarabs:update(dt)
  self.countdown = self.countdown - dt
  if (self.countdown <= 0) then
    self.image_name = "scarabs" .. random(1,4)
    self.countdown = .1
    self.symbol = (random(1,3) == 1 and "&" or (random(1,2) == 1 and "%" or "#"))
  end
end --end update function
effects['scarabs'] = scarabs

local zombait = {
  name = "Bait",
  description = "A bit of raw meat. The undead and animals find it irresistable.",
  symbol = "",
  countdown = 15,
  color={r=150,g=0,b=0,a=0},
  remove_on_cleanup=true
}
function zombait:advance()
  self.countdown = self.countdown - 1
  if (self.countdown <= 0) then
    self:delete()
    self.bait:delete()
    for x=self.x-10,self.x+10,1 do
      for y=self.y-10,self.y+10,1 do
        if (x ~= self.x or y ~= self.y and x>1 and y>1 and x<currMap.width and y<currMap.height) then
          local creat = currMap:get_tile_creature(x,y)
          if creat and (creat:is_type("undead") or creat:is_type("animal")) and creat.target == self.bait then
            creat.target = nil
          end --end undead check
        end --end x/y check
      end --end fory
    end --end forx
    return
  end --end countdown if
  
  for x=self.x-10,self.x+10,1 do
    for y=self.y-10,self.y+10,1 do
      if (x ~= self.x or y ~= self.y and x>1 and y>1 and x<currMap.width and y<currMap.height) then
        local creat = currMap:get_tile_creature(x,y)
        if creat and (creat:is_type("undead") or creat:is_type("animal")) then
          creat.target = self.bait
        end --end undead if
      end --end if checking if it's your actual location
    end --end fory
  end --end forx
end --end advance
effects['zombait'] = zombait

local soul = {
  name = "Soul",
  description = "A glowing soul. Irresitable to demons. Sucks for whoever's soul it is, though.",
  symbol = "*",
  color={r=200,g=255,b=255,a=125},
  animated=true,
  spritesheet=true,
  randomAnimation=true,
  image_max=4,
  animation_time = 0.3,
  remove_on_cleanup=true
}
function soul:advance()
  local creat = currMap:get_tile_creature(self.x,self.y)
  if creat and creat:is_type('demon') then
    creat:updateHP(20)
    if player:can_see_tile(self.x,self.y) then
      output:out(creat:get_name() .. " eats the soul!")
    end
    self:delete()
    for x=self.x-10,self.x+10,1 do
      for y=self.y-10,self.y+10,1 do
        if (x ~= self.x or y ~= self.y and x>1 and y>1 and x<currMap.width and y<currMap.height) then
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat:is_type("demon") and creat.target == self.bait then
            creat.target = nil
          end --end undead check
        end --end x/y check
      end --end fory
    end --end forx
    return
  end

  for x=self.x-10,self.x+10,1 do
    for y=self.y-10,self.y+10,1 do
      if currMap:in_map(x,y) then
        local creat = currMap:get_tile_creature(x,y)
        if creat and creat:is_type("demon") then
          creat.target = {x=self.x,y=self.y}
        end --end undead if
      end --end if checking if it's your actual location
    end --end fory
  end --end forx
end --end advance
effects['soul'] = soul

local blaster = {
  name = "Blaster",
  description = "Animated bit that blasts a beam.",
  countdown = .01,
  symbol = "",
  noDesc = true,
  stopsInput = true,
  color={r=255,g=255,b=255,a=0},
  remove_on_cleanup=true
}
function blaster:new(info)
  self.x,self.y = info.x,info.y
  self.target = info.target
  self.targetLine = currMap:get_line(self.x,self.y,self.target.x,self.target.y,true)
  self.lineSpot = 1
  self.effect = info.effect
  local xDist,yDist = self.x-self.target.x, self.y-self.target.y
  if math.abs(yDist) > math.abs(xDist) then
    self.ns = true
  end
end
function blaster:update(dt)
  self.countdown = self.countdown - dt
  if self.countdown <= 0 then
    self.countdown = .005
    local x,y = self.targetLine[self.lineSpot][1], self.targetLine[self.lineSpot][2]
    local blast = Effect(self.effect)
    currMap:add_effect(blast,x,y)
    if self.ns then blast.angle = math.pi/2 end
    if currMap:isClear(x,y) == false and currMap:get_tile_creature(x,y) == false then --if blocked by something other than a creature, delete
      self:delete()
    else --otherwise, go to next spot, delete if at end of line
      self.lineSpot = self.lineSpot + 1
      if self.lineSpot > #self.targetLine then
        self:delete()
      end --end line length
    end --end isclear if
  end --end countdown if
end --end update fnction
effects['blaster'] = blaster

local rainbowblast = {
  name = "Rainbow Blast!",
  description = "YAY!",
  countdown = .25,
  symbol = "=",
  noDesc = true,
  stopsInput = true,
  color={r=255,g=255,b=255,a=255},
  remove_on_cleanup=true
}
function rainbowblast:new()
  self.color = {r=random(0,255),g=random(0,255),b=random(0,255),a=255}
end
function rainbowblast:update(dt)
  self.countdown = self.countdown - dt
  if self.countdown <= 0 then
    local creat = currMap:get_tile_creature(self.x,self.y)
    if creat then
      local dmg = creat:damage(20,self.creator,"magic")
      if player:can_see_tile(creat.x,creat.y) then output:out("The technicolor magic of the rainbow blasts "  .. creat:get_name() .. " for " .. dmg .. " damage.") end
    end
    for _,feat in pairs(currMap:get_tile_features(self.x,self.y)) do
      if feat.id ~= "grass" and feat.fireChance and random(1,100) <= feat.fireChance then
        feat:combust()
        if player:can_see_tile(feat.x,feat.y) then output:out("The rainbow catches " .. feat:get_name() .. " on fire!") end
      end --end firechance if
    end --end feature for
    self:delete()
  end
end
effects['rainbowblast'] = rainbowblast

local eyelaser = {
  name = "Eye laser",
  description = "Pew Pew Pew!",
  countdown = .25,
  symbol = "=",
  noDesc = true,
  stopsInput = true,
  color={r=255,g=0,b=0,a=255},
  remove_on_cleanup=true
}
function eyelaser:update(dt)
  self.countdown = self.countdown - dt
  if self.countdown <= 0 then
    local creat = currMap:get_tile_creature(self.x,self.y)
    if creat then
      local dmg = creat:damage(20,self.creator,"magic")
      output:out("The eye laser blasts "  .. creat:get_name() .. " for " .. dmg .. " damage.")
    end
    self:delete()
  end
end
effects['eyelaser'] = eyelaser

local snowstorm = {
  name = "snowstorm",
  description = "A blinding, freezing snowstorm.",
  strength = 10,
  countdown = .01,
  symbol = "*",
  blocksSight = true,
  color={r=200,g=200,b=200,a=255},
  remove_on_cleanup=true
}
function snowstorm:advance()
  self.strength = self.strength - 1
  if self.strength < 1 then
    self:delete()
    return
  end
  local creat = currMap:get_tile_creature(self.x,self.y)
  if creat then
    local dmg = creat:damage(tweak(5),self.creator,"ice")
    if dmg and player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " takes " .. dmg .. " damage from the snowstorm.") end
  end
end
effects['snowstorm'] = snowstorm

local cussin = {
  name = "cussin",
  description = "Angry!",
  noDesc=true,
  symbol = "!",
  countdown = .05,
  disappearTime = 1,
  image_name = "symbolssmall1",
  color={r=255,g=0,b=0,a=150},
  remove_on_cleanup=true
}
function cussin:new(creature)
  local tSize = output:get_tile_size()
  --self.yModBase = -tSize
  --self.xModBase = 0
  self.xModMax = math.ceil(tSize/2)
  self.dir = (random(1,2) == 1 and "l" or "r")
  --self.creature = creature
  self.x,self.y = creature.x,creature.y
  self.xMod,self.yMod = creature.xMod,creature.yMod-round(tSize/2)
end
function cussin:update(dt)
  --self.x,self.y = self.creature.x,self.creature.y
  --self.xMod,self.yMod = self.creature.xMod+self.xModBase,self.creature.yMod+self.yModBase
  self.countdown = self.countdown - dt
  if self.dir == "l" then
    self.xMod = round(self.xMod - 100*dt)
    if self.xMod <= -self.xModMax then self.dir = "r" end
  else
    self.xMod = round(self.xMod + 100*dt)
    if self.xMod >= self.xModMax then self.dir = "l" end
  end
  self.yMod = round(self.yMod-50*dt)
  self.color.a = 255*self.disappearTime
  if (self.countdown <= 0) then
    local symbol = random(1,5)
    self.image_name = "symbolssmall" .. symbol
    if symbol == 1 then
      self.symbol = "!"
    elseif symbol == 2 then
      self.symbol = "%"
    elseif symbol == 3 then
      self.symbol = "#"
    elseif symbol == 4 then
      self.symbol = "@"
    elseif symbol == 5 then
      self.symbol = "&"
    end
    self.countdown = .05
  end
  self.disappearTime = self.disappearTime - dt
  if self.disappearTime <= 0 then
    self:delete()
  end
end
effects['cussin'] = cussin

local explosion = {
  name = "explosion",
  description = "BOOM!",
  noDesc = true,
  symbol = ".",
  countdown = .1,
  tilemap = true,
  stopsInput = true,
  image_name = "explosion",
  color={r=255,g=255,b=0,a=255},
  image_max = 5,
  remove_on_cleanup=true
}
function explosion:new()
  self.image_frame = 1
end
function explosion:update(dt)
  self.countdown = self.countdown - dt
  if self.countdown <= 0 then
    self.countdown = .1
    self.image_frame = self.image_frame + 1
    if 5 < self.image_frame then --if you reached the last frame
      self:delete()
    end
    if self.image_frame == 2 then self.symbol = "*"
    elseif self.image_frame == 3 then self.sumbol = "#"
    elseif self.image_frame == 4 then self.symbol = "*"
    elseif self.image_frame == 5 then self.symbol = "." end
  end
end
effects['explosion'] = explosion

local methane = {
  name = "cloud of methane",
  description = "A thick cloud of methane gas has congregated here. It smells bad, and is pretty flammable too.",
  symbol = "§",
  tilemap = true,
  color={r=0,g=200,b=0,a=75}
}
function methane:update(dt)
  if self.exploding then
    local neighbors = 1
    currMap:add_effect(Effect('explosion'),self.x,self.y)
    for x=self.x-1,self.x+1,1 do
      for y= self.y-1,self.y+1,1 do
        local gas2 = currMap:tile_has_effect(x,y,"methane")
        if gas2 then
          gas2.exploding = true
          neighbors = neighbors+1
        end --end if gas2
      end ---end fory
    end --end forx
    local creat = currMap:get_tile_creature(self.x,self.y)
    if creat then
      local dmg = creat:damage(5*neighbors,nil,"explosive")
      if player:can_sense_creature(creat) and player:does_notice(creat) then output:out(creat:get_name() .. " is caught in a methane gas explosion and takes " .. dmg .. " damage!") end
      if creat.hp <= 0 and creat.id == "plumber" then
        achievements:give_achievement('sewers_special')
      end
    end
    if player:can_see_tile(self.x,self.y) then output:sound('bomb') end
    self:delete()
  end --end if self.exploding
end --end update function
function methane:refresh_image_name()
  local directions = ""
  if currMap:tile_has_effect(self.x,self.y-1,'methane') == false then directions = directions .. "n" end
  if currMap:tile_has_effect(self.x,self.y+1,'methane') == false then directions = directions .. "s" end
  if currMap:tile_has_effect(self.x+1,self.y,'methane') == false then directions = directions .. "e" end
  if currMap:tile_has_effect(self.x-1,self.y,'methane') == false then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
effects['methane'] = methane

local tornado = {
  name = "tornado",
  description = "A fierce mini-tornado! Thank goodness your house is nowhere around here.",
  symbol = "{",
  color={r=175,g=175,b=255,a=255},
  countdown=0.1,
  turns = 20,
  hazard=100,
  image_name = "tornado1",
  remove_on_cleanup=true,
  advance = function(self)
    self.turns = self.turns - random(1,2)
    if (self.turns <= 0) then
      self:delete()
    end
    
    local moveX,moveY = math.max(math.min(currMap.width,random(self.x-1,self.x+1)),2),math.max(math.min(currMap.height,random(self.y-1,self.y+1)),2)
		if (currMap[moveX][moveY] ~= "#") then
      self:moveTo(moveX,moveY,.1)
			--self.x, self.y = moveX,moveY
		end
    if currMap:isClear(self.x,self.y) then --if current location is clear, pull a random nearby creature into yourself
      local neighbors = {}
      for x=self.x-1,self.x+1,1 do
        for y=self.y-1,self.y+1,1 do
          local c = currMap:get_tile_creature(x,y)
          if c then neighbors[#neighbors+1] = c end
        end --end fory
      end --end forx
      if #neighbors > 0 then
        local pulled = get_random_element(neighbors)
        pulled:moveTo(self.x,self.y)
        if player:can_see_tile(self.x,self.y) then output:out("The tornado sucks in " .. pulled:get_name() .. ".") end
      end
    end
    local creat = currMap:get_tile_creature(self.x,self.y)
    if creat then
      local dmg = creat:damage(tweak(25),self.creator)
      if dmg and player:can_sense_creature(creat) then output:out("The tornado deals " .. dmg .. " damage to " .. creat:get_name() .. ".") end
    end
    --Pull creatures 2 tiles out to you
    for x=self.x-2,self.x+2,1 do
      for y=self.y-2,self.y+2,1 do
        local creat = currMap:get_tile_creature(x,y)
        if creat then
          local line,complete = currMap:get_line(self.x,self.y,creat.x,creat.y)
          if complete and line and #line > 0 then
            creat:moveTo(line[1][1],line[1][2])
          end --end if line
        end --end if creat
      end --end fory
    end --end forx
  end,
  update = function(self,dt)
    self.countdown = self.countdown - dt
    if self.countdown <= 0 then
      self.countdown = 0.1
      if self.image_name == "tornado1" then
        self.image_name = "tornado2"
        self.symbol = "T"
      elseif self.image_name == "tornado2" then
        self.image_name = "tornado3"
        self.symbol = "}"
      elseif self.image_name == "tornado3" then
        self.image_name = "tornado1"
        self.symbol = "{"
      end --end image_name if
    end --end countdown if
  end --end update function
}
effects['tornado'] = tornado

local stormcloud = {
  name = "storm cloud",
  description = "A localized storm cloud that seems to be following someone around. If meteorology had been invented yet, meteorologists would find this fascinating.",
  yMod = -5,
  symbol = "#",
  image_name = "stormcloud1",
  countdown = 0.1,
  color = {r=100,g=100,b=100,a=200},
  turns = 10,
  remove_on_cleanup=true,
  advance = function(self)
    self.turns = self.turns - 1
    if self.turns <= 0 or self.target.hp <= 0 then
      self:delete()
      self.target:cure_condition('clouded')
    end
    self:moveTo(self.target.x,self.target.y,.1)
    --self.x,self.y = self.target.x,self.target.y
    if random(1,5) == 1 then
      local dmg =  self.target:damage(random(5,10),self.creator,"electric")
      if player:can_see_tile(self.x,self.y) then output:out("A bolt of lightning shoots out of the cloud and strikes " .. self.target:get_name() .. " for " .. dmg .. " damage.") end 
      self.target:give_condition('stunned',2)
    end
  end, --end advance function
  update = function(self,dt)
    self.countdown = self.countdown - dt
    if self.countdown <= 0 then
      self.countdown = 0.1
      if self.image_name == "stormcloud1" then
        self.image_name = "stormcloud2"
      elseif self.image_name == "stormcloud2" then
        self.image_name = "stormcloud3"
        self.color = {r=100,g=100,b=255,a=200}
      elseif self.image_name == "stormcloud3" then
        self.image_name = "stormcloud4"
        self.color = {r=100,g=100,b=100,a=200}
      elseif self.image_name == "stormcloud4" then
        self.image_name = "stormcloud5"
      elseif self.image_name == "stormcloud5" then
        self.image_name = "stormcloud1"
      end --end image_name if
    end --end countdown if
    if self.x ~= self.target.x or self.y ~= self.target.y then
      self:moveTo(self.target.x,self.target.y,.1)
    end
  end --end update function
}
effects['stormcloud'] = stormcloud

local chasmeye = {
  name = "chasm eye",
  description = "EYE THE EYE THE EYE THE EYE THE",
  color={r=255,g=255,b=255,a=255},
  symbol="",
  noDesc=true,
  animated=true,
  spritesheet=true,
  reverseAnimation=true,
  image_max=4,
  animation_time = 0.5
}
function chasmeye:update()
  if self.animCountdown == self.animation_time and self.image_frame == 1 and self.reversing == true then
    local x,y = random(2,currMap.width-1),random(2,currMap.height-1)
    while currMap:get_tile_creature(x,y) do
      x,y = random(2,currMap.width-1),random(2,currMap.height-1)
    end --end while
    self:moveTo(x,y)
  end
end
effects['chasmeye'] = chasmeye

local lavabubble = {
  name = "lavabubble",
  description = "Hot pops",
  color={r=255,g=255,b=255,a=255},
  symbol="",
  noDesc=true,
  animated=true,
  spritesheet=true,
  image_max=4,
  animation_time = 0.25
}
function lavabubble:update()
  if self.animCountdown == self.animation_time and self.image_frame == 1 then
    local x,y = random(2,currMap.width-1),random(2,currMap.height-1)
    while not currMap:tile_has_feature(x,y,'lava') or currMap:get_tile_creature(x,y) do
      x,y = random(2,currMap.width-1),random(2,currMap.height-1)
    end --end while
    self:moveTo(x,y)
    self.animCountdown=self.animation_time
  end
end
effects['lavabubble'] = lavabubble

local shocker = {
  name = "shocker",
  description = "Zzzzap!",
  color={r=255,g=255,b=255,a=255},
  symbol="",
  noDesc=true,
  noDisp=true,
  stopsInput=true,
  alreadyDone={},
  dist=0,
  amt=5,
  remove_on_cleanup=true
}
function shocker:update(dt)
  if not self.countdown then self.countdown = .1 end
  self.countdown = self.countdown - dt
  if self.countdown > 0 then return end
  self.countdown=.1
  for x=self.x-self.dist,self.x+self.dist,1 do
    for y=self.y-self.dist,self.y+self.dist,1 do
      if not self.alreadyDone[x .. ',' .. y] and currMap:in_map(x,y) then
        self.alreadyDone[x .. ',' .. y] = true
        local water = false
        local feats = currMap:get_tile_features(x,y)
        for _,feat in pairs(feats) do
          if feat.water == true then water = true break end
        end
        if not water and type(currMap[x][y]) == "table" and currMap[x][y].water == true then water = true end
        if water then
          local creat = currMap:get_tile_creature(x,y)
          if creat and self.ignore ~= creat then
            local dmg = creat:damage(self.amt-self.dist,self.source,'electric')
            if dmg > 0 and random(1,4) == 1 then creat:give_condition('stunned',random(2,3)) end
            if player:can_sense_creature(creat) then
              output:out(creat:get_name() .. " is shocked for " .. dmg .. "damage!")
            end
          else --if there is a creature, the electricdamage animation will already happen, so we don't need to do it again
            currMap:add_effect(Effect('animation',{image_name='electricdamage',image_max=5,target={x=x,y=y},color={r=255,g=255,b=255}}),x,y)
          end
        end --end water if
      end --end alreadydone if
    end --end fory
  end --end forx
  self.dist = self.dist + 1
  if self.dist > self.amt then
    self:delete()
  end
end
effects['shocker'] = shocker

local minecart = {
  name = "minecart",
  description = "To improve efficiency (and to make things as dangerous as possible), the dwarves have invented rocket-propelled self-driving minecarts. There's no way this could possibly go wrong.",
  symbol = "#",
  color = {r=150,g=150,b=150,a=255},
  countdown = 0.1,
  moves=3,
  hazard=1000,
  advance = function(self)
    self.moves = 3
    self.stopsInput = true
    self.countdown = 0.05
  end,
  update = function(self,dt)
    if self.moves > 0 then
      self.countdown = self.countdown - dt
    else
      self.stopsInput = false
    end
    
    if self.countdown <= 0 and self.moves > 0 then
      --Move to the next direction:
      local t = currMap:tile_has_feature(self.x,self.y,'minetracks')
      t.impassable = false
      t.passableFor = false
      local lookTile = {x=self.x,y=self.y}      
      local newX,newY=self.x,self.y
      if self.direction == "n" and currMap:tile_has_feature(self.x,self.y-1,'minetracks') then
        newY = newY-1
        lookTile.y = lookTile.y-2
      elseif self.direction == "s" and currMap:tile_has_feature(self.x,self.y+1,'minetracks') then
        newY = newY+1
        lookTile.y = lookTile.y+2
      elseif self.direction == "e" and currMap:tile_has_feature(self.x+1,self.y,'minetracks') then
        newX = newX+1
        lookTile.x = lookTile.x+2
      elseif self.direction == "w" and currMap:tile_has_feature(self.x-1,self.y,'minetracks') then
        newX = newX-1
        lookTile.x = lookTile.x-2
      end
      self:moveTo(newX,newY,.05)
      
      --Set the new direction:
      if random(1,2) == 1 or not currMap:tile_has_feature(lookTile.x,lookTile.y,'minetracks') or not self.direction then --If you reach the end of the line, change direction. If you haven't, 50/50 chance to change direction
        local track = currMap:tile_has_feature(self.x,self.y,'minetracks')
        local newDir = get_random_key(track.directions)
        local c = 1
        while newDir == self.oppositeDir and count(track.directions) > 1 and c < 25 do
          newDir = get_random_key(track.directions)
          c = c + 1
        end
        self.direction = newDir
        if newDir == "n" then self.oppositeDir = "s"
        elseif newDir == "s" then self.oppositeDir = "n"
        elseif newDir == "e" then self.oppositeDir = "w"
        elseif newDir == "w" then self.oppositeDir = "e" end
      end
      
      --Look to see if you bumped into any creatures:
      local creat = currMap:get_tile_creature(self.x,self.y)
      if creat then
        local flyTo = {x=self.x,y=self.y}
        if self.direction == "e" then
          flyTo.x = flyTo.x + random(self.moves+1,4) -- Don't move just a bit and then get hit again
        elseif self.direction == "w" then
          flyTo.x = flyTo.x - random(self.moves+1,4)
        elseif self.direction == "s" then
          flyTo.y = flyTo.y + random(self.moves+1,4)
        elseif self.direction == "n" then
          flyTo.y = flyTo.y - random(self.moves+1,4)
        end
        --Possibly be thrown to the side:
        if flyTo.x == self.x then flyTo.x = flyTo.x + random(-2,2) end
        if flyTo.y == self.y then flyTo.y = flyTo.y + random(-2,2) end
        
        creat:flyTo(flyTo)
        local dmg = creat:damage(random(5,15))
        if player:can_see_tile(self.x,self.y) then
          output:out("A minecart rams into " .. creat:get_name() .. ", dealing " .. dmg .. " damage!")
          output:sound('minecart_crash')
        end
        if creat.hp <= 0 then creat.explosiveDeath = true end
        self.direction,self.oppositeDir = self.oppositeDir,self.direction
      end
      local tnt = currMap:tile_has_feature(self.x,self.y,'tnt')
      if tnt then
        tnt.hitByCart=true
        tnt:combust()
      end
      
      -- Look to see if you bump into any minecarts:
      if (lookTile.x ~= self.x and lookTile.y ~= self.y) and currMap:tile_has_effect(lookTile.x,lookTile.y,'minecart') then
        self.direction,self.oppositeDir = self.oppositeDir,self.direction
      end
      
      self.moves = self.moves - 1
      self.countdown = 0.05
      self.image_name = "minecart" .. self.direction
      if self.moves == 0 then
        local track = currMap:tile_has_feature(self.x,self.y,"minetracks")
        track.impassable = true
        track.passableFor = {ghost=true}
      end --end if self.moves == 0
    end --end if self.countdown
  end --end update function
}
effects['minecart'] = minecart

local soundwavemaker = {
  name = "Soundwavemaker",
  description = "Animated bit that makes soundwaves.",
  symbol = "",
  noDesc = true,
  dist = 10,
  color={r=255,g=255,b=255,a=0},
  remove_on_cleanup=true
}
function soundwavemaker:new(color,dist)
  self.color = color
  self.dist = dist or 10
end
function soundwavemaker:update(dt)
  for x=self.x-1,self.x+1,1 do
    for y=self.y-1,self.y+1,1 do
      local xMod,yMod = get_unit_vector(self.x,self.y,x,y)
      if xMod ~= 0 or yMod ~=0 then
        local wave = Projectile('soundwave',{x=self.x,y=self.y},{x=self.x+(xMod*self.dist),y=self.y+(yMod*self.dist)},self.color)
        wave:advance()
      end
    end
  end
  self:delete()
end
effects['soundwavemaker'] = soundwavemaker

local noisemakerattractor = {
  name = "Noisemaker Attractor",
  description = "Draws enemies to noisemaker.",
  noDesc = true,
  symbol = "",
  color={r=150,g=150,b=0,a=0},
  time = 10,
  remove_on_cleanup=true
}
function noisemakerattractor:new(info)
  self.x,self.y = info.x,info.y
  local n = Feature('noisemaker')
  self.noisemaker = n
  currMap:add_feature(n,self.x,self.y)
  self.color = {r=random(100,255),g=random(100,255),b=random(100,255)}
end
function noisemakerattractor:advance()
  self.time = self.time - 1
  if self.time == 0 then
    for x=self.x-10,self.x+10,1 do
      for y=self.y-10,self.y+10,1 do
        local creat = currMap:get_tile_creature(x,y)
        if creat then creat:cure_condition('distracted') end
      end --end fory
    end --end forx
    self.noisemaker.image_name = nil
    self:delete()
    return
  end
  
  local newImage = "noisemaker" .. random(1,4)
  if newImage ~= self.noisemaker.image_name then self.noisemaker.image_name = newImage end
  local r,g,b = random(100,255),random(100,255),random(100,255)
  self.color = {r=r,g=g,b=b}
  currMap:add_effect(Effect('soundwavemaker',{r=r,g=g,b=b}),self.x,self.y)
  for x=self.x-10,self.x+10,1 do
    for y=self.y-10,self.y+10,1 do
      if (x>1 and y>1 and x<currMap.width and y<currMap.height) then
        local creat = currMap:get_tile_creature(x,y)
        if creat and not creat.target then
          creat.target = self.noisemaker
          creat:give_condition('distracted',-1)
        end --end intelligent if
      end --end if checking if it's your actual location
    end --end fory
  end --end forx
  if player:can_see_tile(self.x,self.y) then
    output:sound('noisemaker' .. random(1,2))
  end
end --end advance
effects['noisemakerattractor'] = noisemakerattractor

local zombieplaguecountdown = {
  name = "Zombie Plague Countdown",
  noDesc = true,
  noDisp = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "Invisible countdown to reanimate a corpse as a zombie.",
}
function zombieplaguecountdown:new(countdown)
  if not self.countdown then
    self.countdown = random(4,10)
  else
    self.countdown = tweak(countdown)
  end
end
function zombieplaguecountdown:advance()
  self.countdown = self.countdown - 1
  if self.countdown < 1 and currMap:isClear(self.x,self.y) then --if tile is not clear, this will continue to try every turn until it is
    local corpse = currMap:tile_has_feature(self.x,self.y,"corpse")
    if corpse then
      local z = Creature('zombie')
      local creat = corpse.creature
      if creat:is_type('ratling') then
        z.image_name = "zombieratling"
        z.name = "zombie ratling"
      elseif creat:is_type('troll') then
        z.image_name = "zombietroll"
        z.name = "zombie troll"
      elseif creat.id == "gargoyle" then
        z.image_name = "zombiegargoyle"
        z.name = "zombie gargoyle"
      end
      currMap:add_creature(z,self.x,self.y)
      if self.creator then
        if self.creator.master then
          z:become_thrall(self.creator.master)
        elseif self.creator.hp > 1 then
          z:become_thrall(self.creator)
        end --end owner has master if
      end --end owner if
      if player:can_see_tile(self.x,self.y) then
        output:out("A " .. corpse.name .. " rises as a zombie!")
        output:sound("zombie_aggro")
        currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,target=target,color={r=255,g=255,b=0}}),corpse.x,corpse.y)
      end
      corpse:delete()
    end
    self:delete()
  end --end countdown if
end
effects['zombieplaguecountdown'] = zombieplaguecountdown

local emberanimator = {
  name = "Ember Animator",
  noDesc = true,
  noDisp = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "Animates embers and causes them to cool.",
  speed=.25,
  countdown = .25,
  remove_on_cleanup=true
}
function emberanimator:new()
  self.speed = tweak(25)/100
  self.countdown = self.speed
end
function emberanimator:update(dt)
  self.countdown = self.countdown-dt
  if self.countdown < 0 then
    self.countdown = self.speed
    local color = 0
    if self.ember.color.r == math.floor(100*(self.ember.heat/4)) then
      color = math.floor(255*(self.ember.heat/4))
		elseif self.ember.color.r == math.floor(255*(self.ember.heat/4)) then
      color = math.floor(200*(self.ember.heat/4))
		else
      color = math.floor(100*(self.ember.heat/4))
		end
    self.ember.color.r=color
    if not prefs['noImages'] then
      self.ember.color.g=color
      self.ember.color.b=color
    end
  end
end
function emberanimator:advance()
  self.ember.heat = self.ember.heat - 1
  self.ember.hazard = self.ember.heat
  if self.ember.heat < 1 then
    self.ember:delete()
    self:delete()
    for x=self.x-1,self.x+1,1 do
      for y=self.y-1,self.y+1,1 do
        local ember = currMap:tile_has_feature(x,y,'ember')
        if ember then
          ember:refresh_image_name()
        end --end ember if
      end --end fory
    end --end forx
  end
end
effects['emberanimator'] = emberanimator

local graveshaker = {
  name = "Grave Shaker",
  noDesc = true,
  noDisp = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "Used to make a grave look unrestful, and to pop out a zombo or skelli if someone gets too close.",
  activated = false
}
function graveshaker:new()
  self.speed = tweak(25)/100
  self.countdown = self.speed
  self.zombocountdown = random(1,5)
end
function graveshaker:update(dt)
  if self.activated == true then
    self.countdown = self.countdown - dt
    if self.countdown < 0 then
      self.countdown = self.speed
      if self.grave then
        if self.grave.id == "grave" then
          self.grave.image_name = "grave_zombie" .. random(1,4)
        end
        self.grave.xMod = random(-1,1)
        self.grave.yMod = random(-1,1)
      end
    end
    if self.grave.possessable == false or (not currMap:tile_has_feature(self.grave.x,self.grave.y,'grave') and not currMap:tile_has_feature(self.grave.x,self.grave.y,'sarcophagus')) then
      self.grave.xMod,self.grave.yMod = 0,0
      self:delete()
    end
  end
end
function graveshaker:advance()
  if self.activated then
    self.zombocountdown = self.zombocountdown - 1
    if self.zombocountdown < 1 and not currMap:get_tile_creature(self.x,self.y) then
      if self.grave and self.grave.id == "grave" then
        if random(1,4) == 1 then -- add grasping dead hands
          local grasper = currMap:add_effect(Effect('graspingdead'),self.x,self.y)
          grasper.turns=-1
          self:delete()
          self.grave.possessable=false
        else --pop a zombo or skelly
          local z = (random(1,2) == 1 and Creature('zombie',currMap:get_min_level()) or Creature('skeleton',currMap:get_min_level()))
          currMap:add_creature(z,self.x,self.y)
          for x=self.x-1,self.x+1,1 do
            for y=self.y-1,self.y+1,1 do
              Projectile('dirtchunk',{x=self.x,y=self.y},{x=x,y=y})
            end --end fory
          end --end forx
          self.grave.image_name = "emptygrave"
          self.grave.possessable = false
          self.grave.symbol="ø"
          self.grave.name = "Empty Grave"
          self.grave.description = "Where a body used to be buried."
          self.grave.inventory_inaccessible=false
          if player:can_see_tile(self.x,self.y) then
            output:out("A " .. z.name .. " bursts from the grave!")
            z:become_hostile(player)
            output:sound('misc_explode')
          end
        end --end grasping dead vs zombo if
      elseif self.grave and self.grave.id == "sarcophagus" then
        currMap:add_creature(self.grave.mummy,self.grave.x,self.grave.y)
        self.grave.activated = true
        self.grave.image_name = self.grave.image_name .. "open"
        self.grave.name = "Open Sarcophagus"
        self.grave.description = "The former resting place of an ancient ruler."
        self.grave.symbol = 0
        self.grave.possessable = false
        if player:can_see_tile(self.x,self.y) then
          output:out(self.grave.mummy:get_name() .. " has awakened!")
          output:sound('mummy_awaken')
          player:notice(self.grave.mummy,true,true) --to make sure it shows up turn 1
        end
        self.grave.mummy:notice(self.grave.activator)
        self.grave.mummy:become_hostile(self.grave.activator,nil,true)
        self.grave.mummy.target = self.grave.activator
      end
      self:delete()
    end
  else
    if self.grave.id == "grave" and calc_distance(self.x,self.y,player.x,player.y) < random(1,5) and player:can_see_tile(self.x,self.y) then
      self.activated = true
    end
  end
end
effects['graveshaker'] = graveshaker

local gargoylecreator = {
  name = "Gargoyle Creator",
  noDesc = true,
  noDisp = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "Causes a statue to turn into a gargoyle!",
  activated = false
}
function gargoylecreator:advance()
  if self.statue.x ~= self.x and self.statue.y ~= self.y then
    self:delete()
    return
  end
  if calc_distance(self.x,self.y,player.x,player.y) < random(1,5) and random(1,10) == 1 and player:can_see_tile(self.x,self.y) then
    self.statue:delete()
    local garg=Creature('gargoyle')
    currMap:add_creature(garg,self.x,self.y,true)
    player:notice(garg)
    garg:notice(player)
    garg:become_hostile(player)
    if player:can_see_tile(self.x,self.y) then
      output:out("A statue flaps its wings and rises into the air. Turns out it was a gargoyle all along!")
      output:sound('stone_explode')
      for x=self.x-1,self.x+1,1 do
        for y=self.y-1,self.y+1,1 do
          if x ~= self.x or y ~= self.y then
            Projectile('stonechunk',garg,{x=x,y=y})
          end
        end --end fory
      end --end forx
    end
    self:delete()
  end
end
effects['gargoylecreator'] = gargoylecreator

local lavabeastcreator = {
  name = "Lavabeast Creator",
  noDesc = true,
  noDisp = true,
  color={r=0,g=0,b=0,a=0},
  symbol = "",
  description = "A beast rises from the lava!",
}
function lavabeastcreator:advance()
  if calc_distance(self.x,self.y,player.x,player.y) < random(1,5) and random(1,10) == 1 and player:can_see_tile(self.x,self.y) then
    local beast=Creature('lavabeast')
    currMap:add_creature(beast,self.x,self.y,true)
    player:notice(beast)
    beast:notice(player)
    beast:become_hostile(player)
    if player:can_see_tile(self.x,self.y) then output:out("A hideous beast rises from the lava!") end
    self:delete()
  end
end
effects['lavabeastcreator'] = lavabeastcreator

local sleepZ = {
  name = "Snore",
  description = "zzzzzz",
  countdown = 1.5,
  symbol = "z",
  noDesc = true,
  color={r=0,g=255,b=255,a=225},
  yMod = -10,
  xMod = 0,
  xChange = 50,
  remove_on_cleanup=true
}
function sleepZ:new()
  if random(1,2) == 1 then self.xChange = -50 end 
end
function sleepZ:update(dt)
  if (self.y) then
    self.countdown = self.countdown - dt
    self.color = {r=0,g=255,b=255,a=150*self.countdown,255}
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
effects['sleepZ'] = sleepZ

local bubble = {
  name = "Bubble",
  description = "Fun!",
  countdown = 1.5,
  symbol = "o",
  noDesc = true,
  use_color_with_tiles=true,
  color={r=255,g=255,b=255,a=225},
  yMod = -10,
  xMod = 0,
  xChange = 50,
  scaleChange = 0,
  spinDir=1,
  remove_on_cleanup=true,
}
function bubble:new()
  if random(1,2) == 1 then self.xChange = -50 self.spinDir = -1 end 
end
function bubble:update(dt)
  if (self.y) then
    self.countdown = self.countdown - dt
    self.color = {r=self.color.r,g=self.color.g,b=self.color.b,a=150*self.countdown,255}
    self.yMod = self.yMod - 25*dt
    self.xMod = self.xMod + self.xChange*dt
    if self.xMod >= 10 then self.xChange = -50 elseif self.xMod <= -10 then self.xChange = 50 end
    if self.scaleChange ~= 0 then
      self.scale = self.scale+self.scaleChange*dt
      if self.scale >= 1 or self.scale <= .50 then
        self.scaleChange = -self.scaleChange
      end
    end
    if self.spin then
      self.angle = (self.angle or 0)+dt*math.pi*self.spinDir
    end
    if (self.countdown <= 0) then
      self:delete()
    end --end countdown if
  else
    self:delete()
  end --end self.y if
end --end function
effects['bubble'] = bubble

--Standard effects used in the base engine:

local fire = {
  name = "Fire",
  description = "A roaring flame.",
  symbol = "^",
  color={r=255,g=0,b=0},
  countdown = .25,
  turns_remaining = 10,
  firstturn = true,
  hazard = 1000,
  castsLight=true,
  lightDist=2,
  lightColor={r=255,g=255,b=0}
}
function fire:new(data)
  if data then
    if data.turns_remaining then self.turns_remaining = data.turns_remaining end
    if data.x and data.y then
      self.x,self.y = data.x,data.y
      local feats = currMap:get_tile_features(self.x,self.y)
      for _,feat in pairs(feats) do
        if feat.water == true then return false end
      end
      if type(currMap[self.x][self.y]) == "table" and currMap[self.x][self.y].water == true then return false end
    end
  end
  self.turns_remaining = tweak(self.turns_remaining)
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
  self.turns_remaining = self.turns_remaining - 1
  if (self.turns_remaining < 1) then
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
  speed=100,
  remove_on_cleanup=true
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
  xChange = 50,
  remove_on_cleanup=true
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
  color={r=255,g=255,b=255,a=255},
  remove_on_cleanup=true
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
  remove_on_cleanup=true,
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
  remove_on_cleanup=true
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