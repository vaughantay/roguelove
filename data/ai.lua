ai = {}
  
--TODO: Use an item (probably split them up based on healing vs attacking)
--TODO: Notice items, move towards them and pick them up
--TODO: Handle pack animal behavior
--TODO: Dedicated decision-making for healing
--TODO: Swapping equipment if you find something better
  
--Possible arguments: "noRunning", "forceStupid", "noRanged", "forceWander"
ai['basic'] = function(self,args)
  local aitime = os.clock()
  args = args or {}
  
  --If you're not close to the player, just move randomly:
  if not self:has_ai_flag('stoic') and not self.target and not self:has_ai_flag('playerstalker') and (args.forceWander or calc_distance(self.x,self.y,player.x,player.y) > player.perception*2) then
    return ai.wander(self,args)
  end
  
  --Handle noticing creatures (and running, for creatures with a minimum distance to maintain)
  local creats = self:get_seen_creatures()
  local enemies,defRun = ai.handlenotice(self,creats,args)
  
  --print('after handlenotice: ' .. os.clock()-aitime)
  
  --Decrease fear, and if you don't see any enemies, decrease alertness. Also decrease memory of seen creatures
  local fearDec = 1 --base fear decrease by 1 every turn
  if (enemies == 0) then
    self.alert = math.max(self.alert - 1,0) --if you can't see any enemies, you alert will decrease by 1
    fearDec = fearDec+1 --and your fear will decrease by 2
    if self.alert < 1 then
      fearDec=fearDec+1 --if your "alert" state is over, your fear will be decreased by 3 total
    end
  end
  self.fear = math.max(self.fear - fearDec,0)
  self:decrease_notice(creats)
  
  local fearRun = self:get_fear() > self:get_bravery()
  --If you're too afraid, run away!
  if  (defRun == true or fearRun == true) and args.noRunning ~= true and enemies > 0 then
    if ai.run(self,(fearRun and 'fleeing' or 'defensive'),args) then return true end --pass it off to another function, don't deal with that shit here!
  end --end fear
  
  --print('after fear and running: ' .. os.clock()-aitime)
  
   --Handle targeting
  ai.target(self,args)
  
  --print('after targeting: ' .. os.clock()-aitime)
  
  --Deal with "target's last seen location" value
  if self.target and self.target.baseType == "creature" then
    self.lastSeen = {x=self.target.x,y=self.target.y} --this stores the value of the last seen location of target
  elseif not self.target and self.lastSeen then --so that if you're not able to reach your target, it'll set that location as your new target
    if self.lastSeen.x == self.x and self.lastSeen.y == self.y then self.lastSeen = nil
    else self.target = self.lastSeen end
  end
  
  --print('after lastseening: ' .. os.clock()-aitime)
  
  --Ranged attacks/spells: If you have a ranged attack, and are able/willing to attack them
  if not args.noRanged and self.ranged_chance and random(0,100) <= self.ranged_chance and (args.forceStupid or not self:is_type('intelligent') or currMap:is_passable_for(self.x,self.y,self.pathType,true)) then --I always get confused what this last clause is doing: Basically, don't use a ranged attack if you're standing in a hazardous area, unless you're too stupid to care
    local finished = ai.rangedAttack(self,args)
    if finished == true then return true end
  end --end ranged chance if
  
  --print('after ranged: ' .. os.clock()-aitime)
  
  --If you're next to your target, attack them:
  if self.target and self.target.baseType == "creature" and self:touching(self.target) and (args.forceStupid or not self:is_type('intelligent') or currMap:is_passable_for(self.x,self.y,self.pathType,true)) and self:attack(self.target) then
    return true
  end
  
  --print('after attack: ' .. os.clock()-aitime)
  
  --If you have a target and didn't cast a spell or use a ranged attack, move towards them, if it won't put you too close
  local moved = ai.moveToTarget(self,args)
  --print('after movetotarget: ' .. os.clock()-aitime)
  if moved == true then return true end
  
  --If you don't have a target or are too close to your target, just wander around, or cast a "random" spell. Later: head towards suspicious noise?
  if not args.noRanged and self.ranged_chance and random(0,100) <= self.ranged_chance then
    for _, spell in ipairs(self:get_spells()) do
      local id = spell.id
      if spell.flags['random'] == true and self.cooldowns[id] == nil then --cast friendly spells first
        local target = spell:decide(self,self,'random')
        if target == true then target = self.target end
        if target and target.x and target.y and (not spell.range or math.floor(calc_distance(self.x,self.y,target.x,target.y)) <= spell.range) then --if there's a valid target to the spell within range
          if spell:use(target,self) then return true end --this is on a seperate line because I want the rest to be skipped if the spell fails for some reason.
        end --end friendly spell range check
      end --end random flag check
    end --end spell for
  end
  
  --print('after random spell: ' .. os.clock()-aitime)
    
  local goX,goY = nil,nil
  --If you have a master, go towards them
  if (self.master and calc_distance(self.x,self.y,self.master.x,self.master.y) > tweak(2)) then
      local path = currMap:findPath(self.x,self.y,self.master.x,self.master.y,self.pathType)
    if (type(path) == "table" and #path>1) then
      goX,goY = path[2]['x'],path[2]['y']
    end --end if path == table
  end --end self.master if
    
  --Move to a random nearby spot:
  if not goX or not goY then
    if not self:has_ai_flag('stoic') then return ai.wander(self,args) end
  else
    self:moveTo(goX,goY)
  end --end goX/goY if
end -- end basic ai function

--This function causes the creature to randomly wander
ai['wander'] = function(self,args)
  if not self.direction or random(1,5) == 1 or currMap:is_passable_for(self.x+self.direction.x,self.y+self.direction.y,self.pathType) == false then
    local xMod,yMod = random(-1,1),random(-1,1)
    local count = 0
    while (count < 10) and ((xMod == 0 and yMod == 0) or (currMap:is_passable_for(self.x+xMod,self.y+yMod,self.pathType) == false)) do
      xMod,yMod = random(-1,1),random(-1,1)
      count = count+1
    end --end while
    self.direction={x=xMod,y=yMod}
  end --end self.direction if
  local goX,goY = self.x+self.direction.x,self.y+self.direction.y
  self:moveTo(goX,goY)
end

--This function handles noticing nearby enemies (and running, if this creature has a minimum distance they like to maintain)
ai['handlenotice'] = function(self,creats,args)
  local enemies,defRun = 0,false
  --First, get all seen creatures. See if enemy creatures are noticed. Go on alert if enemy targets are noticed:
  for _,creat in pairs(creats) do --Loop through all seen creatures
    local notice = self.notices[creat] or self:does_notice(creat)
    local enemy = self.shitlist[creat] or self:is_enemy(creat)
    local distance = calc_distance(self.x,self.y,creat.x,creat.y)
    
    --if they're an enemy and you notice them, keep count of enemies and go on alert:
    if enemy and notice then
      enemies = enemies+1
      if (self.alert < self.memory) then self.alert = self.memory end
      self.notices[creat] = math.ceil(self.memory/2)
    end
    --If you're too close to an enemy for comfort, run away from them:
    if enemy and self.min_distance and notice and distance < self.min_distance and (self.run_chance == nil or random(0,100) < self.run_chance) then
      defRun = true
      self.fear = self.fear + 2
    end
    --If you notice an enemy, see if you actually become hostile:
    if enemy and random(0,100) <= self:get_aggression() and notice and (self.shitlist == nil or self.shitlist[creat] == nil) and (self.ignore_distance == nil or distance < self.ignore_distance) then
      self:become_hostile(creat)
    end --end aggression check 
  end --end for
  return enemies,defRun
end

--This function handles targeting
ai['target'] = function(self,args)
  --If you have a master and they have a target, take your master's target
  if self:has_ai_flag('playerhater') and self:can_sense_creature(player) and self:does_notice(player) then self.target = player
  elseif self.master and self.master.target then self.target = self.master.target end
  
  --If your target no longer makes sense, drop it
  if self.target and
    ((self.target == self) or
    (self.target == self.lastSeen) or -- go ahead and erase this, so that an actual creature could become the next target if one is available
    (self.target.baseType == "creature" and self.target.hp < 1) or
    (self.x == self.target.x and self.y == self.target.y) or
    (not self.target.x or not self.target.y) or
    (self.target.baseType and currMap.contents[self.target.x][self.target.y][self.target] == nil) or
    (self.master and self.target.master and self.master == self.target.master) or
    (self.master and self.target == self.master) or
    (self.target.baseType == "creature" and (not self:has_ai_flag('stalker') and not self:can_sense_creature(self.target)))) then
      self.target = nil
  end
  
  if not self.target and self:has_ai_flag('playerstalker') then --for player stalkers, if they don't already have a target, they will head towards the player
    self.target = player
  end
  
  --If you're next to any (noticed and hostile-towards) enemy, set them as your target, even if you already have one (except for stubborn creatures and player haters):
  if self.target == nil or (not self:has_ai_flag('stubborn') and not (self:has_ai_flag('playerhater') and self.target == player)) then
    for x=self.x-1,self.x+1,1 do
      for y=self.y-1,self.y+1,1 do
        local creat = currMap:get_tile_creature(x,y)
        if creat and self.shitlist[creat] and self:does_notice(creat) then
          self.target = creat
        end --end enemy if
      end --end fory
    end --end forx
  end

  --If you have no target and there are nearby enemies, select one
  if self.target == nil and next(self.shitlist) ~= nil then
    if self:has_ai_flag('bully') or self:has_ai_flag('giantkiller') then --bullies and giantkillers will select least or most health, respectively
      local bully = self:has_ai_flag('bully') --assumption: if not bully, then giantkiller
      local currTar = nil
      local most = nil
      local least = nil
      for creat,_ in pairs(self.shitlist) do
        local hp = creat.hp
        if hp > 0 and self:can_sense_creature(creat) and self:does_notice(creat) then
          if not bully and (most == nil or hp > most) then
            currTar = creat
            most = hp
          end
          if bully and (least == nil or hp < least) then
            currTar = creat
            least = hp
          end
        end --end basic can-sense check
      end --end for
      if currTar then self.target = currTar end
    else --everyone else target a random enemy
      creat = get_random_key(self.shitlist)
      if creat.hp > 0 and self:can_sense_creature(creat) and self:does_notice(creat) then
        self.target = creat
      end
    end
  end --end target if
end

--This function handles moving towards your target
ai['moveToTarget'] = function(self,args)
  if self.target and (self.target.baseType ~= "creature" or self:touching(self.target) == false) and (self.target.baseType ~= "creature" or self.min_distance == nil or math.floor(calc_distance(self.x,self.y,self.target.x,self.target.y)) > self.min_distance) and (self.target.baseType ~= "creature" or self.approach_chance == nil or random(0,100) <= self.approach_chance) and (self.target.baseType ~= "creature" or self:can_sense_creature(self.target) or self:has_ai_flag('stalker') or (self.target == player and self:has_ai_flag('playerstalker'))) then
    if not args.forceStupid and self:is_type('intelligent') == true and calc_distance(self.x,self.y,self.target.x,self.target.y) <= self:get_perception() then
      --Intelligent creatures: first, see if you can draw a straight line to your target
      local path, complete = currMap:get_line(self.x,self.y,self.target.x,self.target.y,self.pathType)
      if complete and #path >= 1 and currMap:is_passable_for(path[1][1],path[1][2],self.pathType,true) then --if the path completed and it's safe to go to the first location on the path, do it!
        if self.min_distance == nil or math.floor(calc_distance(self.target.x,self.target.y,path[1][1],path[1][2])) > self.min_distance then --if following the path wouldn't put you too close to your target, do it!
          self:moveTo(path[1][1],path[1][2])
          return true
        end --end min_distance check
      else
        --If the line thing didn't work, make a Dijkstra map (to navigate hazards), and then go:
          if ai.dijkstra(self,args) then return end
      end --end line vs Dijkstra map if
    else --nonintelligent creatures or intelligent creatures out of range
      local complete = ai.dumbpathfind(self,args)
      if complete then return true end
    end --end intelligence check
  end --end have target/target min distance
end

--This function handles determining if you use a ranged attack
ai['rangedAttack'] = function(self,args)
  --Try regular ranged attack first:
  if (self.target and self.target.baseType == "creature") and self:touching(self.target) == false and (self.ranged_attack ~= nil and (rangedAttacks[self.ranged_attack].projectile == false or self:can_shoot_tile(self.target.x,self.target.y)) and rangedAttacks[self.ranged_attack]:use(self.target,self)) then return true end
  -- Then cast a spell, if possible
  for _, spell in ipairs(self:get_spells()) do
    local id = spell.id
    if spell.flags['friendly'] == true and self.cooldowns[id] == nil then --cast friendly spells first
      local target = spell:decide(self,self,'friendly')
      if target == true then target = self.target end
      if target and target.x and target.y and (not spell.range or math.floor(calc_distance(self.x,self.y,target.x,target.y)) <= spell.range) then --if there's a valid target to the spell within range
        if spell:use(target,self) then return true end --this is on a seperate line because I want the rest to be skipped if the spell fails for some reason.
      end --end friendly spell range check
    elseif (self.target and self.target.baseType == "creature") and (spell.flags['aggressive'] == true and self.cooldowns[id] == nil and (not spell.range or math.floor(calc_distance(self.x,self.y,self.target.x,self.target.y)) <= spell.range)) then
      local target = spell:decide(self.target,self,'aggressive')
      if target ~= false and (target == nil or target == true or target.x == nil or target.y == nil) then target = self.target end --if for some reason the decide function doesn't return an acceptable target
      if (target ~= false and spell:use(target,self)) then
        return true
      end --end if spell use
    end --end aggressive/friendly if
  end --end spell for
end

--This function handles running away
ai['run'] = function(self,runType,args)
  args = args or {}
  local sTime = os.clock()
  runType = runType or "fleeing"
  
  if self.ranged_chance and random(0,100) <= self.ranged_chance then
    -- Cast a defensive/fleeing spell, if possible
    for _, spell in ipairs(self:get_spells()) do
      local id = spell.id
      if spell.flags[runType] == true and self.cooldowns[id] == nil then
        local target = spell:decide(self,self,runType)
        if target ~= false and (target == nil or target.x == nil or target.y == nil) then target = self.target end --if for some reason the decide function doesn't return an acceptable target
        if (target ~= false and spell:use(target,self)) then
          return true
        end --end if spell use
      end --end if spell fleeing and no cooldowns
    end --end spell for
  end --end ranged chance if
  
  local lMap = self:make_fear_map()
  local largest = nil
  local largestX,largestY = nil,nil
  
  for x=self.x-1,self.x+1,1 do
    for y=self.y-1,self.y+1,1 do
      local xy = x .. "," .. y
      if lMap[xy] and (largest == nil or lMap[xy] > largest) then
        largest = lMap[xy]
        largestX,largestY = x,y
      end --end if
    end --end fory
  end --end forx
  
  if largest then
    self:moveTo(largestX,largestY)
    return true
  else --nowhere to run!
    return false
  end
  --output:out("Time to calc fear map: " .. tostring(os.clock()-sTime))
end --and AI run

--This function pathfinds to an enemy, ignoring hazards
ai['dijkstra'] = function(self,args)
  local createTime = 0
  local hTime = 0
  local lMap = {}
  local hazards = {}
  local cW,cH=currMap.width-1,currMap.height-1
  local sX,sY,perc = self.x,self.y,self:get_perception()
  local ctype = self.pathType
  for x=sX-perc,sX+perc,1 do
    for y=sY-perc,sY+perc,1 do
      local xy = x .. "," .. y
      if (x>1 and y>1 and x<cW and y<cH) then
        if (self:can_move_to(x,y) == false) then
          lMap[xy] = false
        elseif x == self.target.x and y == self.target.y then
          lMap[xy] = 0
        else
          lMap[xy] = 10
        end
        
        --Add hazard score:
        hazards[xy] = 0
        if type(currMap[x][y]) == "table" then --if the tile is hazardous, add hazard score
          local tile = currMap[x][y]
          if tile.hazard and tile:is_hazardous_for(ctype) then hazards[xy] = hazards[xy] + tile.hazard/10 end
        end --end tile hazard if
        for _,feat in pairs(currMap:get_tile_features(x,y)) do
          if feat.hazard and feat:is_hazardous_for(ctype) then hazards[xy] = hazards[xy] + feat.hazard/10 end
        end --end feature for
        for _, eff in pairs(currMap:get_tile_effects(x,y)) do
          if eff.hazard and eff:is_hazardous_for(ctype) then hazards[xy] = hazards[xy] + eff.hazard/10 end
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
          local min = nil --look at the tiles next to this tile, and set the score of this tile to be 1 higher than the lowest score of any neighbors
          for ix=x-1,x+1,1 do
            for iy=y-1,y+1,1 do
              local ixy = ix .. "," .. iy
              if (ix>1 and iy>1 and ix<cW and iy<cH and lMap[ixy]) and (min == nil or lMap[ixy] < min) then
                min = lMap[ixy]
              end --end min if
            end --end yfor
          end --end xfor
          if (min and min+2 < lMap[xy]-hazards[xy]) then
            lMap[xy] = min+1+hazards[xy]
            changed = true
          end --end min check
        end --end tile check
      end --end yfor
    end --end xfor
  end -- end while
  
  --Figure out what the smallest value is:
  local smallest = nil
  local smallestX,smallestY = nil,nil
  
  for x=self.x-1,self.x+1,1 do
    for y=self.y-1,self.y+1,1 do
      local xy = x .. "," .. y
      if lMap[xy] then
        if (smallest == nil or lMap[xy] < smallest or (lMap[xy] == smallest and random(1,2) == 1)) then
          smallest = lMap[xy]
          smallestX,smallestY = x,y
        end --end largest if
        if smallest == 1 then break end
      end --end if map exists if
    end --end fory
  end --end forx
  if smallest then
    self:moveTo(smallestX,smallestY)
    return true
  end
  return false
end

--This function handles pathfinding to an enemy, not avoiding hazards
ai['dumbpathfind'] = function(self,args)
  --Just dumbly walk in a straight line to your target, if possible. If not, pathfind.
  local path, complete = currMap:get_line(self.x,self.y,self.target.x,self.target.y)
  local creat = (path[1] and currMap:get_tile_creature(path[1][1],path[1][2]) or false) --is there a creature 
  if (path[1] and path[#path]) and (complete or self:can_move_to(path[#path][1],path[#path][2])) and self:can_move_to(path[1][1],path[1][2]) then --if the path completed, or was blocked due to a dangerous feature, who cares, keep going if you can
    if self.min_distance == nil or math.floor(calc_distance(self.target.x,self.target.y,path[1][1],path[1][2])) > self.min_distance then --if it doesn't put you too close to your target
      self:moveTo(path[1][1],path[1][2])
      return true
    end --end min_distance check
  elseif complete == false and creat then -- if the first tile in the path is blocked by a creature
    if self:is_enemy(creat) then --if it's an enemy, attack them
      self:attack(creat)
      return true
    else --if the blocking creature is not an enemy, move around them
      local dist = calc_distance(self.x,self.y,self.target.x,self.target.y) --how far you are already
      local xDir,yDir = (random(1,2) == 1 and 1 or -1),(random(1,2) == 1 and 1 or -1) --pick random starting direction, so the creatures don't always start at the upper left or whatever
      for x=self.x-xDir,self.x+xDir,xDir do
        for y=self.y-yDir,self.y+yDir,yDir do
          if calc_distance(x,y,self.target.x,self.target.y) < dist and self:can_move_to(x,y) then -- just move to the first open square you check that's closer
            self:moveTo(x,y)
            return true
          end --end calc_dist if
        end --end fory
      end --end forx
    end --end block creature ifs
  else --if the straight line won't work, do pathfinding
    --if (self.target.baseType == "creature" and self.target ~= player) then currMap:set_blocked(self.target.x,self.target.y,0) end
    local path = currMap:findPath(self.x,self.y,self.target.x,self.target.y,self.pathType)
    --if (self.target.baseType == "creature" and self.target ~= player) then currMap:set_blocked(self.target.x,self.target.y,1) end
    if type(path) == "table" and #path>1 then
      if self.min_distance == nil or math.floor(calc_distance(self.target.x,self.target.y,path[2]['x'],path[2]['y'])) > self.min_distance then
        self:moveTo(path[2]['x'],path[2]['y'])
        return true
      end --end min_distance check
    else --can't path there?
      if (self.target.baseType == "creature") then
        if debugMode then output:out(self:get_name() .. " unable to path to " .. self.target:get_name()) end
      else
        if debugMode then output:out(self:get_name() .. " unable to path to " .. self.target.x .. ", " .. self.target.y) end
      end --end target type if
      self.target = nil
    end--end if path == table
  end --end line vs path if
end

--[[ai['basicold'] = function(creature)
  -- Next to allied creature? attack them instead
	for x=creature.x-1,creature.x+1,1 do
		for y=creature.y-1,creature.y+1,1 do
			local creat = currMap:get_tile_creature(x,y)
			if creat and creat.ai == "ally" then
				creature:attack(creat)
				return true
			end
		end
	end
  
	if (creature:can_see_tile(player.x,player.y) and calc_distance(creature.x,creature.y,player.x,player.y) <= creature.aggression) then -- can you see the player?
		-- First commit the player to memory (trying to be more complicated than we are ;)
		if (creature.alert == 0) then
			if (player:can_see_tile(creature.x,creature.y)) then
				output:out(creature:get_name() .. " notices you!")
        currMap:add_effect(Effect('dmgpopup'),creature.x,creature.y)
			end
			creature.alert = creature.aggression
		end
		creature.lastSawPlayer.x = player.x
		creature.lastSawPlayer.y = player.y
		-- cast a spell, if possible
		for _, id in ipairs(creature.spells) do
			local spell = possibleSpells[id]
			if (spell.aggressive == true and creature.cooldowns[id] == nil and player.name ~= "ghost") then
				if (spell:use(player,creature) == true) then
					return true
				end
			end
		end
		-- head to player
		local path = currMap:findPath(creature.x,creature.y,player.x,player.y)
		if (type(path) == "table") then
			creature:moveTo(path[2]['x'],path[2]['y'])
		end
	else -- can't see player
		if (creature.lastSawPlayer.x ~= nil and creature.alert > 0) then -- if you recently saw the player
			creature.alert = creature.alert - 1 -- calm down
			if (creature.lastSawPlayer.x == creature.x and creature.lastSawPlayer.y == creature.y or creature.alert == 0) then --reached last seen player location?
				-- reset "last seen" counters
				creature.lastSawPlayer.x = nil
				creature.lastSawPlayer.y = nil
			else --haven't reached last seen location?
				local path = currMap:findPath(creature.x,creature.y,creature.lastSawPlayer.x,creature.lastSawPlayer.y)
				if (type(path) == "table") then
					creature:moveTo(path[2]['x'],path[2]['y'])
				end
			end
		else  -- can't see player now, haven't seen player recently, do a random move
			if (creature.alert > 0) then
				creature.alert = creature.alert - 1 -- calm down
			end
			local direction = random(1,5)
			if (direction == 1) then
				creature:moveTo(creature.x,creature.y-1)
			elseif (direction == 2) then
				creature:moveTo(creature.x+1,creature.y)
			elseif (direction == 3) then
				creature:moveTo(creature.x,creature.y+1)
			elseif (direction == 4) then
				creature:moveTo(creature.x-1,creature.y)
			end
		end
	end
end

ai['ally'] = function(self)
	if (target and target.hp > 0) then self.target = target end -- if the player has a target, take it as your own
  -- Next to unallied creature? attack them
  for x=self.x-1,self.x+1,1 do
		for y=self.y-1,self.y+1,1 do
			local creat = currMap:get_tile_creature(x,y)
			if creat and creat.ai ~= "ally" and creat ~= player then
				self:attack(creat)
				return true
			end
		end
	end
    
	if (self.target) then --if you already have a target, move towards them
		if (self.target == player or (self:can_see_tile(self.target.x,self.target.y) == false and player:can_see_tile(self.target.x,self.target.y) == false) or self.target.hp < 1) then -- if you can't see them or they're dead, clear it all and start over
			self.target = nil
		elseif (self:touching(self.target)) then --if you're next to them, attack them!
			self:attack(self.target)
		else
			currMap.pathfinder.grid.map[self.target.y][self.target.x] = 0
			local path = currMap:findPath(self.x,self.y,self.target.x,self.target.y) -- move towards them
			if (type(path) == "table") then
				self:moveTo(path[2]['x'],path[2]['y'])
			end
			currMap.pathfinder.grid.map[self.target.y][self.target.x] = 1
		end
	else  -- if there's no target
		-- find one
		-- if none's found, walk to player
    
		local path = currMap:findPath(self.x,self.y,player.x,player.y)
		if (type(path) == "table") then
			self:moveTo(path[2]['x'],path[2]['y'])
		end
	end
end]]