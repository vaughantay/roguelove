ai = {}
  
--TODO: Use an item (probably split them up based on healing vs attacking)
--TODO: Notice items, move towards them and pick them up
--TODO: Handle pack animal behavior
--TODO: Dedicated decision-making for healing
--TODO: Swapping equipment if you find something better

---Basic AI code
--Decision making process is as follows:
--1. If too far from the player for us to care about, just wander (possible finish point)
--2. Look at creatures nearby to determine who you notice and who's an enemy
--3. Decrease fear and alertness if no enemies are nearby
--4. If too afraid and enemies are nearby, run away (possible finish point)
--4. Pick a nearby target from nearby enemies
--5. Perform a ranged attack if applicable (possible finish point)
--6. Attack, if next to your target (possible finish point)
--7. If you have a path set, move along that path (possible finish point)
--8. If you don't have a path, but have a target, move towards them (possible finish point)
--9. Cast a "random" spell if applicable (possible finish point)
--10. If you have a master you're too far away from, move towards them (possible finish point)
--11. If you have a guard point you're too far away from, move towards it (possible finish point)
--12. If you're a patroller, move along your patrol route (possible finish point)
--13. If you've exhausted all the above possibilities, just wander (final finish point)
--Possible arguments: "noRunning", "forceStupid", "noRanged", "forceWander"
ai['basic'] = function(self,args)
  local aitime = os.clock()
  args = args or {}
  
  --If you're not close to the player, just move randomly:
  if args.forceWander or (not self.guard_point and not self.patrol_points and not self.target and not self:has_ai_flag('playerstalker')) then
    return ai.wander(self,args)
  end
  
  --Determine whether we're currently in danger (or too stupid to care)
  local noDanger = (args.forceStupid or not self:is_type('intelligent') or currMap:is_passable_for(self.x,self.y,self.pathType,true))
  args.noDanger = noDanger
  
  --Handle noticing creatures (and running, for creatures with a minimum distance to maintain)
  local creats = self:get_seen_creatures()
  local enemies,defRun = ai.handlenotice(self,creats,args)
  
  --print('after handlenotice: ' .. os.clock()-aitime)
  
  --Decrease fear, and if you don't see any enemies, decrease alertness. After that, decrease memory of seen creatures
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
  
  --If you're too afraid, run away!
  local fearRun = self:get_fear() > self:get_bravery()
  if (defRun == true or fearRun == true) and args.noRunning ~= true and enemies > 0 then
    local ran = ai.run(self,(fearRun and 'fleeing' or 'defensive'),args)
    if ran == true then return true end
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
  if not args.noRanged and self.ranged_chance and random(0,100) <= self.ranged_chance and noDanger then
    local finished = ai.rangedAttack(self,args)
    if finished == true then return true end
  end --end ranged chance if
  
  --print('after ranged: ' .. os.clock()-aitime)
  
  --If you're next to your target, attack them:
  if self.target and self.target.baseType == "creature" and self:touching(self.target) and noDanger then
    local attack = self:attack(self.target)
    if attack == true then return true end
  end
  
  --print('after attack: ' .. os.clock()-aitime)
  
  --If you have a path already, and its endpoint matches your target's tile, continue to move along your path
  if self.path and #self.path > 1 and self.target then
    local endX,endY = (self.path[#self.path].x or self.path[#self.path[1]]),(self.path[#self.path].y or self.path[#self.path[2]])
    if endX == self.target.x and endY == self.target.y then
      local moved = ai.moveAlongPath(self,args)
      if moved == true then
        return true
      end
      self.path = nil --if we weren't able to move along the path for some reason, delete it
    else --if the path does not end at your target anymore, delete it
      self.path = nil
    end
  end
  
  --If you have a target and didn't cast a spell or use a ranged attack, move towards them, if it won't put you too close
  if self.target then
    local moved = ai.moveToTarget(self,args)
    --print('after movetotarget: ' .. os.clock()-aitime)
    if moved == true then return true end
  end
  
  --If you don't have a target or are too close to your target, cast a "random" spell if applicable
  if not args.noRanged and self.ranged_chance and random(0,100) <= self.ranged_chance then
    for _, spell in ipairs(self:get_spells()) do
      local id = spell.id
      if spell.flags['random'] == true and self.cooldowns[spell] == nil then --cast friendly spells first
        local target = spell:decide(self,self,'random')
        if target == true then target = self.target end
        if target and target.x and target.y and (not spell.range or math.floor(calc_distance(self.x,self.y,target.x,target.y)) <= spell.range) then --if there's a valid target to the spell within range
          local used = spell:use(target,self)
          if used == true then return true end
        end --end friendly spell range check
      end --end random flag check
    end --end spell for
  end
  
  --print('after random spell: ' .. os.clock()-aitime)
  
  --If you have a master, go towards them
  if self.master and not self:touching(self.master) and calc_distance(self.x,self.y,self.master.x,self.master.y) > tweak(self.max_master_distance or self:get_perception()) then
    local path = currMap:findPath(self.x,self.y,self.master.x,self.master.y,self.pathType)
    if (type(path) == "table" and #path>1) then
      self.path = path
      local moved = ai.moveAlongPath(self,args)
      if moved then return true end
    end --end if path == table
  end --end self.master if
  
  --If you have a spot you're supposed to be guarding, go back there
  if self.guard_point then
    local guard = ai.guard(self,args)
    if guard then return true end
  end
  
  --If you have a patrol route, move along it
  if self.patrol_points then
    local patrol = ai.patrol(self,args)
    if patrol then return true end
  end
  
  --If none of the above has applied, just wander
  if not self.guard_point or (self.guard_wander_distance and calc_distance(self.x,self.y,self.guard_point.x,self.guard_point.y) <= self.guard_wander_distance) then
    return ai.wander(self,args)
  end
end -- end basic ai function

---This function causes the creature to randomly wander
ai['wander'] = function(self,args)
  if not args.forceWander and self:has_ai_flag('stoic') then return false end
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
  return self:moveTo(goX,goY)
end

---This function handles noticing nearby enemies (and running, if this creature has a minimum distance they like to maintain)
ai['handlenotice'] = function(self,creats,args)
  local enemies,defRun = 0,false
  --First, get all seen creatures. See if enemy creatures are noticed. Go on alert if enemy targets are noticed:
  for _,creat in pairs(creats) do --Loop through all seen creatures
    local enemy = self.shitlist[creat] or self:is_enemy(creat)
    local notice = self.notices[creat] or self:does_notice(creat)
    
    if enemy and notice then
      local distance = calc_distance(self.x,self.y,creat.x,creat.y)
      --Keep count of enemies and go on alert:
      enemies = enemies+1
      if (self.alert < self.memory) then self.alert = self.memory end
      self.notices[creat] = math.ceil(self.memory/2)
      
      --If you're too close to an enemy for comfort, run away from them:
      if self.min_distance and distance < self.min_distance and (self.run_chance == nil or random(0,100) < self.run_chance) then
        defRun = true
        self.fear = self.fear + 2
      end
      
      --See if you actually become hostile:
      if (self.shitlist == nil or self.shitlist[creat] == nil) and (self.ignore_distance == nil or distance < self.ignore_distance) and random(0,100) <= self:get_aggression() then
        self:become_hostile(creat)
      end --end aggression check 
    end --end enemy if
  end --end for
  return enemies,defRun
end

--This function handles setting a target among nearby hostile creatures
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
  if (self.target == nil or self.target.baseType ~= "creature") and next(self.shitlist) ~= nil then
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

---This function handles moving towards your target
ai['moveToTarget'] = function(self,args)
  if self.target and (self.target.baseType ~= "creature" or self:touching(self.target) == false) and (self.target.baseType ~= "creature" or self.min_distance == nil or math.floor(calc_distance(self.x,self.y,self.target.x,self.target.y)) > self.min_distance) and (self.target.baseType ~= "creature" or self.approach_chance == nil or random(0,100) <= self.approach_chance) and (self.target.baseType ~= "creature" or self:can_sense_creature(self.target) or self:has_ai_flag('stalker') or (self.target == player and self:has_ai_flag('playerstalker'))) then
    if not args.forceStupid and self:is_type('intelligent') == true and calc_distance(self.x,self.y,self.target.x,self.target.y) <= self:get_perception() then
      --Intelligent creatures: first, see if you can draw a straight line to your target
      local path, complete = currMap:get_line(self.x,self.y,self.target.x,self.target.y,self.pathType)
      if complete and #path >= 1 and currMap:is_passable_for(path[1][1],path[1][2],self.pathType,true) and (self.min_distance == nil or math.floor(calc_distance(self.target.x,self.target.y,path[1][1],path[1][2])) > self.min_distance) then --if the path completed and it's safe to go to the first location on the path, do it!
        self.path = path
        return ai.moveAlongPath(self,args)
      else
        --If the line thing didn't work, make a Dijkstra map (to navigate hazards), and then go:
        local dij = ai.dijkstra(self,args)
        if dij then return true end
      end --end line vs Dijkstra map if
    else --nonintelligent creatures or intelligent creatures out of range
      local complete = ai.dumbpathfind(self,args)
      if complete then return true end
    end --end intelligence check
  end --end have target/target min distance
end

---This function handles determining if you use a ranged attack
ai['rangedAttack'] = function(self,args)
  --Try regular ranged attack first:
  if (self.target and self.target.baseType == "creature") and self:touching(self.target) == false and (self.ranged_attack ~= nil and (rangedAttacks[self.ranged_attack].projectile == false or self:can_shoot_tile(self.target.x,self.target.y)) and rangedAttacks[self.ranged_attack]:use(self.target,self)) then return true end
  -- Then cast a spell, if possible
  for _, spell in ipairs(self:get_spells()) do
    local id = spell.id
    if spell.flags['friendly'] == true and self.cooldowns[spell] == nil then --cast friendly spells first
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

---This function handles running away
ai['run'] = function(self,runType,args)
  args = args or {}
  local sTime = os.clock()
  runType = runType or "fleeing"
  
  if self.ranged_chance and random(0,100) <= self.ranged_chance then
    -- Cast a defensive/fleeing spell, if possible
    for _, spell in ipairs(self:get_spells()) do
      local id = spell.id
      if spell.flags[runType] == true and self.cooldowns[spell] == nil then
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

---This function pathfinds to an enemy, accounting for hazards
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

---This function handles moving along your pre-set path
ai['moveAlongPath'] = function(self,args)
  if self.path then
    local intelligent = self:is_type('intelligent')
    local moved = false
    local path = self.path
    local x,y = (path[2] and path[2].x or path[1][1]), (path[2] and path[2].y or path[1][2])
    if not x or not y then
      self.path = nil
      return false
    end
    local creat = (currMap:get_tile_creature(x,y) or false) --is there a creature 
    if creat then -- if the first tile in the path is blocked by a creature
      if self:is_enemy(creat) then --if it's an enemy, attack them
        self:attack(creat)
        return true
      else --if the blocking creature is not an enemy, move around them
        if not self.target then self.target = {x=path[#path].x,y=path[#path].y} end
        local dist = calc_distance(self.x,self.y,self.target.x,self.target.y) --how far you are already
        local xDir,yDir = (random(1,2) == 1 and 1 or -1),(random(1,2) == 1 and 1 or -1) --pick random starting direction, so the creatures don't always start at the upper left or whatever
        local emergX,emergY = nil,nil
        for tx=self.x-xDir,self.x+xDir,xDir do
          for ty=self.y-yDir,self.y+yDir,yDir do
            if moved == false and currMap:touching(self.x,self.y,tx,ty) and self:can_move_to(tx,ty) and (args.forceStupid or not intelligent or (intelligent and currMap:is_passable_for(tx,ty,self.pathType,true))) then -- check to make sure it's a tile that makes sense to enter
              local tDist = calc_distance(tx,ty,self.target.x,self.target.y)
              if tDist < dist then --if the distance to the new tile is less than your current distance, move there
                moved = self:moveTo(tx,ty)
                if moved ~= false then
                  self.path = nil --delete the path if we stepped off it, since we'll need to recalculate
                end
              elseif tDist == dist or not emergX or not emergY then --if the distance to the new tile isn't less but it's a tile you could move to , store it as an emergency option
                emergX,emergY = tx,ty
              end --end calc_dist if
            end --end can move to if
          end --end fory
        end --end forx
        if emergX and emergY and moved == false then --if you didn't move to a "better" tile, just move to an available tile if there is one
          moved = self:moveTo(emergX,emergX)
          if moved ~= false then
            self.path = nil --delete the path if we stepped off it, since we'll need to recalculate
          end
        end
      end --end enemy or not if
    else -- no blocking creature
      if self:can_move_to(x,y) and (args.forceStupid or not intelligent or (intelligent and currMap:is_passable_for(x,y,self.pathType,true))) then
        moved = self:moveTo(x,y)
      end      
    end --end block creature ifs
    if moved ~= false then
      if self.path and #self.path > 1 then
        table.remove(self.path,1)
      end
      if self.path and (#self.path == 0) then
        self.path = nil
      end
      return true
    end
  end
  self.path = nil --If we weren't able to move, delete the path
  return false
end

---This function handles pathfinding to an enemy, not avoiding hazards
ai['dumbpathfind'] = function(self,args)
  --Just dumbly walk in a straight line to your target, if possible. If not, pathfind.
  local path, complete = currMap:get_line(self.x,self.y,self.target.x,self.target.y)
  
  if (path[1] and path[#path]) and (complete or self:can_move_to(path[#path][1],path[#path][2])) and self:can_move_to(path[1][1],path[1][2]) then --if the path completed, or was blocked due to a dangerous feature, who cares, keep going if you can
    if self.min_distance == nil or math.floor(calc_distance(self.target.x,self.target.y,path[1][1],path[1][2])) > self.min_distance then --if it doesn't put you too close to your target TODO: move this elsewhere
      self.path = path
      return ai.moveAlongPath(self,args)
    end --end min_distance check
  else --if the straight line won't work, do pathfinding
    --if (self.target.baseType == "creature" and self.target ~= player) then currMap:set_blocked(self.target.x,self.target.y,0) end
    local path = currMap:findPath(self.x,self.y,self.target.x,self.target.y,self.pathType)
    --if (self.target.baseType == "creature" and self.target ~= player) then currMap:set_blocked(self.target.x,self.target.y,1) end
    if type(path) == "table" and #path>1 then
      if self.min_distance == nil or math.floor(calc_distance(self.target.x,self.target.y,path[2]['x'],path[2]['y'])) > self.min_distance then
        --[[for i,v in ipairs(path) do
          print(self.name .. " " .. i .. ":",v.x,v.y)
        end]]
        self.path = path
        return ai.moveAlongPath(self,args)
      end --end min_distance check
    else --can't path there?
      if (self.target.baseType == "creature") then
        if debugMode then output:out(self:get_name() .. " unable to path to " .. self.target:get_name()) end
      else
        if debugMode then output:out(self:get_name() .. " unable to path to " .. self.target.x .. ", " .. self.target.y) end
      end --end target type if
      self.target = nil
      self.path = nil
      return false
    end--end if path == table
  end --end line vs path if
end

---This code handles creatures guarding a specific point
ai['guard'] = function(self,args)
  if self.guard_point and (self.x ~= self.guard_point.x or self.y ~= self.guard_point.y) and (not self.guard_wander_distance or calc_distance(self.x,self.y,self.guard_point.x,self.guard_point.y) > tweak(self.guard_wander_distance)) then
    local gmoved = false
    if not self.target then
      self.target = self.guard_point
    end
    if not self.path then 
      gmoved = ai.moveToTarget(self,args)
    end
    if gmoved then return true end
  end
end

---This code handles patrolling creatures moving between patrol points
ai['patrol'] = function(self,args)
  if self.patrol_points then
    local pmoved = false
    local atPoint = false
    
    local advance_path = function(atPoint)
      local pointCount = #self.patrol_points
      local maxPoint = (self.reverse_patrol_direciton and 1 or pointCount)
      if atPoint == maxPoint then
        if self.reverse_patrol_direction_at_end then
          self.reverse_patrol_direction = not self.reverse_patrol_direction
        end
      end
      local newPoint = atPoint+(self.reverse_patrol_direction and -1 or 1)
      --Handle rollover:
      if newPoint < 1 then newPoint = pointCount
      elseif newPoint > pointCount then
        newPoint = 1
      end
      --Set your current patrol point to be the new point:
      self.current_patrol_target=newPoint
    end
    
    
    --First, check to see if you've reached your current target
    if self.current_patrol_target then
      local x,y = self.patrol_points[self.current_patrol_target].x,self.patrol_points[self.current_patrol_target].y
      if self.x == x and self.y == y or currMap:touching(self.x,self.y,x,y) then
        atPoint = self.current_patrol_target
      else --if you haven't reached it, set it as your target and start moving
        if not self.target then
          self.target = self.patrol_points[self.current_patrol_target]
        end
      end
    else --if you don't have a current patrol target, set it to the nearest point
      local nearestDist = nil
      local nearestPoint = nil
      local nearestIndex = nil
      for id,point in ipairs(self.patrol_points) do
        local dist = calc_distance(self.x,self.y,point.x,point.y)
        if not nearestDist or dist < nearestDist then
          nearestDist = dist
          nearestPoint = point
          nearestIndex = id
          if dist == 0 then
            atPoint = id
            break
          end
        end
      end
      self.current_patrol_target = nearestIndex
    end
    
    --If you've reached a point on the path:
    if atPoint then
      advance_path(atPoint)
    end
    
    --Start moving to your new point target if applicable:
    if not self.target and self.current_patrol_target then
      self.target = self.patrol_points[self.current_patrol_target]
    end
    --Try to pathfind to your new targte:
    if self.target and not self.path then 
      pmoved = ai.moveToTarget(self,args)
    end
    if pmoved then
      return true
    else --if weren't able to pathfind to it then ignore it and just move to the next target point:
      advance_path(self.current_patrol_target)
    end
  end
end

--[[
Old AI code, kept here for reference:
ai['basicold'] = function(creature)
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