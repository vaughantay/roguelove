---@module gamelogic

---Starts a new game, and does all the bookkeeping necessary for that. Generates the first map, and puts the player on it.
--@param mapSeed Number. The seed to use to generate the world. (optional)
--@param playTutorial Boolean. Whether or not to show tutorial messages this game. (optional)
--@param cheats Table. A table listing all the cheats in use this game. (optional)
--@param branch String. The ID of the branch to start on. (optional)
function new_game(mapSeed,playTutorial,cheats,branch)
	maps = {}
  branch = parse_name_for_level(player.properName) or branch or gamesettings.default_starting_branch
  currGame = {startTime=os.date(),fileName=player.properName,playTutorial=playTutorial,tutorialsSeen={},missionStatus={},finishedMissions={},achievementDisqualifications={},cheats={},autoSave=prefs['autosaveTurns'],seed=mapSeed,stats={},events_occured={},event_countdown=0}
  if cheats then currGame.cheats = cheats end
  update_stat('games')
  currMap = mapgen:generate_map(branch,1)
  player:moveTo(currMap.stairsUp.x,currMap.stairsUp.y)
  currMap.creatures[player] = player
  --Do special class stuff if necessary:
  local startingMissions = true
  local class = playerClasses[player.class]
  if class then
    if class.placed then
      class.placed(player,currMap)
    end
    if class.starting_missions then
      startingMissions=false
      for mid,val in pairs(class.starting_missions) do
        start_mission(mid,val)
      end
    end
  end
  if startingMissions and gamesettings.default_starting_missions then
    for mid,val in pairs(gamesettings.default_starting_missions) do
      start_mission(mid,val)
    end
  end
  maps[currMap.branch] = {}
	maps[currMap.branch][currMap.depth] = currMap
	output:setCursor(0,0)
	action = "moving"
	actionResult = nil
	target = nil
  output.text = {}
  output.buffer = {}
  output.toDisp = {{1},{},{}}
  output:set_camera(player.x,player.y,true)
  update_stat('branch_reached',currMap.branch)
  update_stat('map_reached',currMap.id)
end

---Figures out which level to load based on a given string. Used for level-skip cheats.
--@param name String. If it matches a branch ID, start at that branch
function parse_name_for_level(name)
  if dungeonBranches[name] then
    print(name)
    return name
  end
end

---Creates the player character entity.
--@param creatureID String. The ID of the creature definition to use to create the player. Optional, defeaults to player_human
--@param class String. The ID of the playerclass to apply to the player entity. Optional
--@param name String. The name of the new player character. Optional, f blank, will be randomized.
--@param gender String. Either "male", "female", "neuter", "other", or "custom". Optional, if blank, will be set to "other" and use they/them pronouns.
--@param pronouns Table. A table of custom pronouns. Optional, only needed if using "custom" gender.
function initialize_player(creatureID,class,name,gender,pronouns)
  creatureID = creatureID or gamesettings.default_player
	player = Creature(creatureID,1)
  if class then player:apply_class(class) end
	player.isPlayer = true
  player.playerAlly = true
	if gender then player.gender = gender end
  if gender == "custom" then player.pronouns = pronouns end
  if name ~= nil then
    player.properName=name
  end
  player.symbol = "@"
  player.color={r=255,g=255,b=255,a=255}
end

---Generate stores, factions, and dungeon branches
function initialize_world()
  currWorld = {stores={},factions={},branches={}}
  --Generate stores:
  local stores = currWorld.stores
  for id,store in pairs(possibleStores) do
    local s = Store(id)
    stores[#stores+1] = s
  end
  --Generate Factions:
  local factions = currWorld.factions
  for id,fac in pairs(possibleFactions) do
    factions[id] = Faction(id)
  end
  --Generate dungeon branches:
  local branches = currWorld.branches
  for id,branch in pairs(dungeonBranches) do
    branches[id] = mapgen:generate_branch(id)
  end
  --Make sure branch connections are reciprocal:
  for id,branch in pairs(branches) do
    for depth,depthExits in pairs(branch.exits) do
      for _,exit in ipairs(depthExits) do
        if not exit.oneway then
          local toBranch = exit.branch
          local toDepth = exit.exit_depth
          local exitExists = false
          local upReplaced = false --We keep track of these in case we want to replace the up/down stairs later
          local downReplaced = false
          if branches[toBranch].exits[toDepth] then
            for _,e in pairs(branches[toBranch].exits[toDepth]) do
              if e.replace_upstairs then upReplaced = true end
              if e.replace_downstairs then downReplaced = true end
              if e.branch == id and e.exit_depth == depth then
                exitExists = true
                break
              end --end if exit exists check
            end --end target branch/depth for
          end --end if this depth even has exits if
          if not exitExists then
            local newExit = {branch=id,exit_depth=depth}
            if toDepth == 1 and not upReplaced then newExit.replace_upstairs=true
            elseif toDepth == branches[toBranch].depth then newExit.replace_downstairs=true end
            if not branches[toBranch].exits[toDepth] then branches[toBranch].exits[toDepth] = {} end
            branches[toBranch].exits[toDepth][#branches[toBranch].exits[toDepth]+1] = newExit
          end --end exit doesn't exist if
        end --end oneway if
      end --end exit for
    end --end depthexit for
  end --end branch for
end

---Calculates the chance of hitting an opponent.
--@param attacker Creature. The creature doing the attacking.
--@param target Creature. The creature getting potentially hit
--@param item Item. The item the attacker is using.
function calc_hit_chance(attacker,target,item)
  local hitMod = attacker:get_stat('melee') - (target.get_stat and target:get_stat('dodging') or 0)
  return math.min(math.max(70 + (hitMod > 0 and hitMod*2 or hitMod) + attacker:get_bonus('hit_chance') - (target.get_bonus and target:get_bonus('dodge_chance') or 0) + (item and item:get_accuracy() or 0),25),95)
end

---Calculates whether an attacker hits a target, whether it was a critical, and how much damage was done. Important to note: This function just *calculates* the damage, it does not apply it!
--@param attacker Creature. The creature attacking.
--@param target Creature. The creature getting attacked.
--@param forceHit Boolean. Whether to ignore hit chance and force a hit. (optional)
--@param item Item. The item the attacker is using, if any. (optional)
--@return result String. "hit", "miss", or "critical"
--@return dmg Number. The damage to do.
function calc_attack(attacker,target,forceHit,item)
	local dmg = (item and item:get_damage(target,attacker) or attacker:get_damage())
  local dbonus = .01*attacker:get_bonus('damage_percent',true)
  dmg = dmg * math.ceil(dbonus > 0 and dbonus or 1)
	local critChance = attacker:get_critical_chance() + (item and item:get_critical_chance() or 0)
	local hitMod = calc_hit_chance(attacker,target,item)
  local result = "miss"

	local roll = random(1,100)
	if (roll > 100-critChance or (target.baseType == "creature" and target:does_notice(attacker) == false) and target ~= player) then --critical hit!
		result = "critical"
    if attacker.critical_damage then
      dmg = tweak(attacker.critical_damage)
    end
		dmg = tweak(math.ceil(dmg * 1.5))
	elseif (roll <= hitMod) or forceHit then --hit!
		result = "hit"
		dmg = tweak(dmg)
	else -- miss!
		result = "miss"
		dmg = 0
	end
	return result,dmg
end

---Advances the turn, causing NPCs to move, effects and projectiles to advance, the map's lighting to recalculate, creature conditions to do their thing, and the output buffer to clear.
function advance_turn()
  local pTime = os.clock()
  game.canvas=nil
  if game.moveBlocked == true then
    game.waitingToAdvance = true
  end
  output.buffering = true
    
  --Update stats:
  update_stat('turns')
  update_stat('turns_as_creature',player.id)
  update_stat('turns_as_class',player.class)
  update_stat('turns_as_creature_class_combo',player.id .. "_" .. player.class)
  update_stat('turns_on_branch',currMap.branch)
  update_stat('turns_on_map',currMap.id)
  
  player:advance()
  
	for id, creature in pairs(currMap.creatures) do
		if creature.hp < 1 then
			creature:die()
		elseif creature.isPlayer ~= true then
      creature:advance()
    end --end creature hp if
	end
  for _, effect in pairs(currMap.effects) do
    effect:advance()
  end
  for _, projectile in pairs(currMap.projectiles) do
    projectile:advance()
  end
  
  --Faction favor decay/growth and event countdown:
  for fid, faction in pairs(currWorld.factions) do
    if faction.favor_decay_turns and currGame.stats.turns % faction.favor_decay_turns == 0 and (faction.favor_decay_for_non_members or player:is_faction_member(fid)) then
      local newFavor = (player.favor[fid] or 0) - (faction.favor_decay or 1)
      if not faction.favor_decay_floor or newFavor > faction.favor_decay_floor then player.favor[fid] = newFavor end
    end
    if faction.favor_growth_turns and currGame.stats.turns % faction.favor_growth_turns == 0 and (faction.favor_growth_for_non_members or player:is_faction_member(fid)) then
      local newFavor = (player.favor[fid] or 0) + (faction.favor_growth or 1)
      if not faction.favor_growth_ceiling or newFavor < faction.favor_growth_ceiling then player.favor[fid] = newFavor end
    end
    faction.event_countdown = math.max(0,faction.event_countdown-1)
  end
  
  --Random Events:
  local event_chance = currMap.event_chance or gamesettings.default_event_chance
  currGame.event_countdown = math.max(0,currGame.event_countdown-1)
  run_all_events_of_type('random')
  
  for id, creature in pairs(currMap.creatures) do -- this is done after the creatures, effects and projectiles take their actions, in case a creature kills another one
		if creature.hp < 1 then
			if action ~= "dying" or creature ~= player then creature:die() end
		end
	end
  
  currMap:refresh_lightMap(true) -- refresh the lightmap, forcing it to refresh all lights
  if action ~= "dying" then action = "moving" end
  actionResult = nil
  
  if action ~= "dying" then
    -- Output stuff:
    output.targetLine = {}
    output.targetTiles = {}
    --currMap:refresh_pathfinder()
    for i=#output.toDisp,1,-1 do
      output.toDisp[i] = output.toDisp[i-1]
      output.toDisp[i-1] = {}
    end
    output.toDisp[1] = output.buffer
    output.buffer = {}
    output.buffering = false
    player.sees = nil
    player.sees = player:get_seen_creatures()
    player.checked = {}
    player:get_seen_creatures()
  end
  
  local px,py = output:tile_to_coordinates(player.x,player.y)
  if action ~= "dying" and (px < 1 or py < 1 or px > love.graphics.getWidth() or py > love.graphics.getHeight()) then
    output:set_camera(player.x,player.y)
  end
  
  if currGame.playTutorial == true then
    if not currGame.tutorialsSeen['firstTurn'] then
      show_tutorial('firstTurn')
    elseif not currGame.tutorialsSeen['lowHealth'] and player.hp < player.max_hp/3 then
      show_tutorial('lowHealth')
    elseif not currGame.tutorialsSeen['stairs'] and player:can_see_tile(currMap.stairsUp.x,currMap.stairsUp.y) then
      show_tutorial('stairs')
    end
  end
  
  if type(currGame.autoSave) == "number" and currGame.autoSave <= 0 then
    love.graphics.captureScreenshot("saves/" .. currGame.fileName .. ".png")
    save_game()
    currGame.autoSave = prefs['autosaveTurns']
  end
  refresh_player_sight()
  --print("Time to run turn: " .. tostring(os.clock()-pTime))
end --end advance_turn

---This function is called when you win. It saves the win for posterity, and blacks out the screen.
function win()
  print('winning!')
  action = "winning"
  update_stat('wins')
  save_win()
  delete_save(currGame.fileName,true)
  game:blackOut(5,true)
  game:show_popup([[You truly are a true hero.]]
    ,"",6,false,true,function() currGame = nil Gamestate.switch(credits) end)
end

---This function is called when you lose. It clears out the player and current game variables, and switches back to the main menu.
function game_over()
	player = nil
  currGame = nil
  game.blackAmt = nil
  Timer.cancel(game.blackOutTween)
  Timer.cancel(game.deadTween)
	Gamestate.switch(menu)
end

---Move to another map
--@param depth Number. The depth of the map you're trying to reach
--@param branch Text. Which branch the map is on
--@param force Boolean. Whether to force the game to go to the map, ignoring whether the boss is dead or not. (optional)
function goToMap(depth,branch,force)
  local oldBranch = currMap.branch
  local oldDepth = currMap.depth
  if not branch then branch = currMap.branch end
  if not depth then
    if oldBranch == branch then
      depth = currMap.depth+1
    else
      depth = 1
    end
  end
  
	if (currMap.boss == nil and force ~= true) then
    if generate_boss() == false then
      return goToMap(depth,branch,force) --if the generate boss function returns false, rerun this function again
    end
	elseif (force or debugMode) or (currMap.boss == -1 or currMap.boss.hp < 1) then
    local firstTime = false
    update_stat('map_beaten',currMap.id)
    achievements:check('map_end')
    currMap.creatures[player] = nil
    if not maps[branch] then
      maps[branch] = {}
      update_stat('branch_reached',branch)
    end
		if (maps[branch][depth] == nil) then
			maps[branch][depth] = mapgen:generate_map(branch,depth)
      firstTime = true
      update_stat('map_reached',currMap.id)
		end
		currMap.contents[player.x][player.y][player] = nil
		currMap=maps[branch][depth]
    local playerX,playerY = nil,nil
    for _,exit in pairs(currMap.exits) do
      exit.most_recent = false
      if exit.branch == oldBranch and exit.depth == oldDepth then
        playerX,playerY = exit.x,exit.y
        exit.most_recent=true
        break
      end
    end --end exit for
    if not playerX or not playerY then
      if branch == oldBranch then
        if depth < oldDepth then
          playerX,playerY = currMap.stairsDown.x,currMap.stairsDown.y
        else
          playerX,playerY = currMap.stairsUp.x,currMap.stairsUp.y
        end
      else
        playerX,playerY = currMap.stairsUp.x,currMap.stairsUp.y
      end
    end --end if not playerX or playerY
    player.x,player.y = playerX,playerY
    currMap.contents[playerX][playerY][player]=player
    currMap.creatures[player] = player
    target = nil
    if currGame.cheats.fullMap == true then currMap:reveal() end
    game:show_map_description()
    output:set_camera(player.x,player.y,true)
    --Handle music:
    output:play_playlist(currMap.playlist)
    currGame.autoSave=true
    player.sees = nil
    run_all_events_of_type('enter_map')
    player:callbacks('enter_map')
    if firstTime then
      run_all_events_of_type('enter_map_first_time')
      player:callbacks('enter_map_first_time')
    end
    if currMap.generate_boss_on_entry then
      generate_boss(true) --TODO: don't generate it near the player maybe?
    end
    currMap:refresh_lightMap(true) -- refresh the lightmap, forcing it to refresh all lights
    refresh_player_sight()
	else
		output:out("You can't leave until you defeat " .. currMap.boss:get_name(nil,true) .. ".")
    return false
	end
end

---Regenerates the current map.
function regen_map()
  print('regening')
  currMap = mapgen:generate_map(currMap.branch,currMap.depth,currMap.mapType)
  maps[currMap.branch][currMap.depth] = currMap
  player.x,player.y = currMap.stairsDown.x,currMap.stairsDown.y
  currMap.contents[currMap.stairsDown.x][currMap.stairsDown.y][player]=player
  currMap.creatures[player] = player
  target = nil
  -- Remove creatures near stairs
  for x=currMap.stairsDown.x-1,currMap.stairsDown.x+1,1 do
    for y= currMap.stairsDown.y-1,currMap.stairsDown.y+1,1 do
      local creat = currMap:get_tile_creature(x,y)
      if creat and creat ~= player then creat:remove() end
    end
  end
  if game.blackAmt then
    Timer.cancel(game.blackOutTween)
    game.blackOutTween = tween(2,game,{blackAmt=0},'linear',function() if game.blackOutTween then Timer.cancel(game.blackOutTween) game:show_map_description() end action = "moving" end)
  else
    game:show_map_description()
  end
  if currGame.cheats.fullMap == true then currMap:reveal() end
  
   output:set_camera(player.x,player.y,true)
  --Handle music:
  output:play_playlist(currMap.playlist)
  currGame.autoSave=true
end

---Generates the boss for the map.
--@param silent Boolean. If true, don't display any text when generating the boss
function generate_boss(silent)
  if currMap.noBoss or currMap.bossID == false then
    currMap.boss = -1
    return false
  end
  achievements:check('boss')
  if currMap.boss then
    return
  end
    
  player.sees = nil
  if currMap.mapID and mapTypes[currMap.mapID].generate_boss then --if the map has special boss code, run that
    return mapTypes[currMap.mapID]:generate_boss()
  elseif currMap.bossID then --if the map has a special boss set, use that as the boss
    currMap.boss = Creature(currMap.bossID,possibleMonsters[currMap.bossID].level)
  else --if a specific boss isn't set, make one
    --First look through the list of possible creatures who can spawn here and pick one that's got the boss flag set
    local madeBoss = false
    for id,cid in pairs(currMap:get_creature_list()) do
      local c = possibleMonsters[cid]
      if c.isBoss == true then
        local canDo = true
        if not c.repeatableBoss then --unless this boss says it can repeat, check that it hasn't already been used
          for branch,branchMaps in pairs(maps) do
            for depth,branchMap in pairs(branchMaps) do
              if branchMap ~= currMap and (branchMap.bossID == id or (branchMap.boss and branchMap.boss ~= -1 and branchMap.boss.id == cid)) then
                canDo = false
                break
              end --end bossID check
            end --end map for
          end --end branch for
        end --end repeatable boss if
        if canDo then
          local level = (c.max_level and math.min(c.max_level,currMap:get_max_level()) or c.level) --If the boss can level, level it to either its maximum level or the map's maximum level, whichever is lower
          currMap.boss = Creature(cid,level)
          madeBoss = true
          break
        end
      end -- end level if
    end --end monster for
    if not madeBoss then -- TODO: if a boss hasn't been generated, generate a random applicable creature and make a boss out of it
      
    end
    if not madeBoss then --if a boss still hasn't been generated, just ignore it
      currMap.boss = -1
      return false
    end
  end --end bossID vs generic boss if
  
  if not silent then
    if currMap.boss and currMap.boss ~= -1 and currMap.boss.bossText then
      game:show_popup(currMap.boss.bossText)
    elseif currMap.boss ~= -1 then
      local text = "As you're about to go up the stairs, a gate suddenly clangs shut in front of them!\nYou realize that you are being stalked by" .. (currMap.boss.properNamed ~= true and " a " or " ") .. currMap.boss.name .. "!"
      game:show_popup(text)
    end
  end
  
  --Boss music:
  --[[local playlist = output:make_playlist(currMap.bossPlaylist)
  if not playlist then playlist = output:make_playlist('genericdungeonboss') end
  output:play_playlist('silence')
  if playlist then
    output:play_playlist(playlist)
  end]]
  
  --Place the actual boss:
  local placed = false
  local x,y = currMap.stairsDown.x,currMap.stairsDown.y
  if currMap.spawn_points and #currMap.spawn_points > 0 then
    for i,sp in ipairs(currMap.spawn_points) do
      if sp.boss and currMap.boss:can_move_to(sp.x,sp.y) then
        local currCreat = currMap:get_tile_creature(sp.x,sp.y)
        if currCreat then
          --TODO: make the current creature move
        end
        x,y = sp.x,sp.y
        placed = true
      end --end sp.boss if
    end --end spawn points for
  end --end if we have spawn points if

  --If boss placement hasn't happened yet, put it randomly near the player
  if placed == false then
    x,y = random(player.x-5,player.x+5),random(player.y-5,player.y+5)
    while (x<2 or y<2 or x>=currMap.width or y>=currMap.height or currMap.boss:can_move_to(x,y) == false or player:can_see_tile(x,y) == false) do
      x,y = random(player.x-5,player.x+5),random(player.y-5,player.y+5)
    end
  end
  currMap:add_creature(currMap.boss,x,y)
  currMap.boss:notice(player)
  currMap.boss:become_hostile(player)
  return currMap.boss
end

---Update a game statistic (like turns played, creatures killed, etc.). Increments the given stat by 1.
--@param stat_type String. The stat type to return.
--@param id String. The sub-stat type to return (for example, kills of a specific creature type)
function update_stat(stat_type,id)
  if not currGame.stats then currgame.stats = {} end
  if stat_type and id then
    -- Update the game stat:
    if currGame.stats[stat_type] == nil then currGame.stats[stat_type] = {} end
    if currGame.stats[stat_type][id] == nil then currGame.stats[stat_type][id] = 1
    else currGame.stats[stat_type][id] = currGame.stats[stat_type][id] + 1 end
    --Update the total stat:
    if totalstats[stat_type] == nil then totalstats[stat_type] = {} end
    if totalstats[stat_type][id] == nil then totalstats[stat_type][id] = 1
    else totalstats[stat_type][id] = totalstats[stat_type][id] + 1 end
  elseif currGame.stats[stat_type] == nil or type(currGame.stats[stat_type]) == "number" then
    --Update the game stat:
    if currGame.stats[stat_type] == nil then currGame.stats[stat_type] = 1
    else currGame.stats[stat_type] = currGame.stats[stat_type] + 1 end
    --Update the total stat:
    if totalstats[stat_type] == nil then totalstats[stat_type] = 1
    else totalstats[stat_type] = totalstats[stat_type] + 1 end
  end
end

---Get the value of a game statistic (like turns played, creatures killed, etc.)
--@param stat_type String. The stat type to return.
--@param id String. The sub-stat type to return (for example, kills of a specific creature type)
function get_stat(stat_type,id)
  if stat_type and id then
    if currGame.stats[stat_type] == nil then return 0
    elseif currGame.stats[stat_type][id] == nil then return 0
    else return currGame.stats[stat_type][id] end
  end
end

---Handle movement keys. If action is set to "targeting" then it'll move the cursor, otherwise it'll move the player.
--@param direction String. The keycode of the pressed key.
function perform_move(direction)
	local xMod, yMod = 0,0
	if (direction == "west") then
    xMod = -1
	elseif (direction == "east") then
		xMod = 1
	elseif (direction == "north") then
		yMod = -1
	elseif (direction == "south") then
		yMod = 1
	elseif (direction=="northwest") then
		xMod = -1
		yMod = -1
	elseif (direction=="northeast") then
		xMod = 1
    yMod = -1
	elseif (direction=="southeast") then
		xMod = 1
    yMod = 1
	elseif (direction=="southwest") then
		xMod = -1
    yMod = 1
	end
  if action == "targeting" then
    output:moveCursor(xMod,yMod)
	elseif (action == "moving") then
    move_player(player.x+xMod,player.y+yMod)
  end
end
  
---Move the player to a new location. Also handles warnings for moving into a dangerous area, and advances the turn if the player moves.
--@param newX Number. The X-coordinate to move the player to.
--@param newY Number. The Y-coordinate to move the player to.
--@param force Boolean. Whether to ignore warnings and move the player into a potentially dangerous tile. (optional)
--@return Boolean. Whether the move was successful or not.
function move_player(newX,newY,force)
	output:setCursor(0,0)
  local clear = player:can_move_to(newX,newY)
  local entity = currMap:get_tile_creature(newX,newY,true)
  local possessed = false
	if (clear) then
    --If player is a ghost, see if their new location will put them next to any enemies, and warn them:
    if not force then 
      if player.id == "ghost" then
        for x = newX-1,newX+1,1 do
          for y = newY-1,newY+1,1 do
            local creat = currMap:get_tile_creature(x,y)
            if creat ~= false and creat.id ~= "ghost" and creat:is_enemy(player) and player:can_sense_creature(creat) and player:does_notice(creat) then
              game:warn_player(newX,newY,creat)
              return false --break here, so turn doesn't pass
            end --end creat if
          end --end fory
        end --end forx
      end --end ghost if
    end --end force if
    
    --Check whether or not there are any dangerous features or effects at the new location, and give a warning if so
    if (force or player.id == "ghost" or currMap:is_passable_for(newX,newY,player.pathType,true) or currMap:is_passable_for(player.x,player.y,player.pathType,true) == false) then --the second is_passable check means that it won't pop up a warning moving FROM dangerous territory TO dangerous territory
      player:moveTo(newX,newY)
    else
      game:warn_player(newX,newY)
      return false --break here, so turn doesn't pass
    end
  elseif entity then
    for id, entity in pairs(currMap.contents[newX][newY]) do
      if (entity.baseType == "creature") then
        if (player.id == "ghost") then
          possessed = true
          if not possibleSpells['possession']:use(entity,player) then return false end --if you try to possess a non-possessable creature, return false so it doesn't pass a turn
        else
          if (entity.playerAlly == true) then
            currMap:swap(player,entity)
            output:out("You swap places with " .. entity:get_name() .. ".")
          else
            target = entity
            player:attack(entity)
          end
        end
        break --if there's a creature, we'll deal with them and ignore features
      elseif entity.baseType == "feature" then
        if entity.pushable == true and player.id ~= "ghost" and entity:push(player) then
          player:moveTo(newX,newY)
        elseif entity.attackable == true and player.id ~= "ghost" then
          player:attack(entity)
        elseif entity.possessable == true and player.id == "ghost" then
          possibleSpells['possession']:use(entity,player)
          possessed = true
        else
          --return false
        end --end possessable if
      end --end feature/creature if
    end --end entity for
	end
  if not possessed and (clear or (entity and (entity.baseType == "creature" or (entity.baseType == "feature" and player.id ~= "ghost")))) then
    advance_turn()
    return true
  end
end

---Find a path from the player's location to a new location, and start the player moving along it.
--@param x Number. The x-coordinate to move to.
--@param y Number. The y-coordinate to move to.
--@param noMsg Boolean. Whether to suppress the "moving to" notification.
function pathTo(x,y,noMsg)
  local path = currMap:findPath(player.x,player.y,x,y,player.pathType)
	if (path ~= false) then
		table.remove(path,1)
		player.path = path
		if noMsg ~= true then output:out("Moving to location, press any key to stop...") end
		output:setCursor(0,0)
    player.ignoring = player.sees
    player.pathStartHP = player.hp
	end
end

---Set the player's target, and if targeting an action, apply that action to the target. If targeting a tile with a creature, that creature will be the player's target for UI purposes.
--@param x Number. The x-coordinate of the target.
--@param y Number. The y-coordinate of the target.
function setTarget(x,y)
	local creat = currMap:get_tile_creature(x,y)
	if (creat) then target = creat end
	if (actionResult ~= nil) then
    if actionResult.range and math.floor(calc_distance(player.x,player.y,x,y)) > actionResult.range then
      output:out("That target is too far away.")
      return false
    elseif actionResult.min_range and math.floor(calc_distance(player.x,player.y,x,y)) < actionResult.min_range then
      output:out("That target is too close.")
      return false
    end
    if (actionResult.projectile == true and #output.targetLine > 0) then --if it's a projectile-type spell, target the first thing it passes through rather than the "actual" target
      x,y = output.targetLine[#output.targetLine].x,output.targetLine[#output.targetLine].y
      creat = currMap:get_tile_creature(x,y)
    end --end projectile if
		if (actionResult.target_type == "tile") then
      local arg = (actionResult.baseType == "spell" and actionIgnoreCooldown or actionItem)
			if actionResult:use({x=x,y=y},player,arg) ~= false then
        if actionItem then
          if actionItem.throwable or actionItem.consumed then
            player:delete_item(actionItem,1)
          elseif actionItem.charges then
            actionItem.charges = actionItem.charges - 1
          end
        end
        actionResult = nil
        actionItem = nil
        actionIgnoreCooldown = nil
        advance_turn()
				action="moving"
        output:setCursor(0,0)
			end
		elseif (actionResult.target_type == "creature") then
			if (creat) then
        local arg = (actionResult.baseType == "spell" and actionIgnoreCooldown or actionItem)
				if actionResult:use(creat,player,arg) ~= false then
          if actionItem then
            if actionItem.throwable or actionItem.consumed then
              player:delete_item(actionItem,1)
            elseif actionItem.charges then
              actionItem.charges = actionItem.charges - 1
            end
          end
					actionResult = nil
          actionItem = nil
          actionIgnoreCooldown = nil
          advance_turn()
					action="moving"
          output:setCursor(0,0)
				end
			else --if no creature
				return false
			end --end if (creat)
		end --end square vs. creature if
	end --end main if
end --end function

---Called when the player dies. Starts the screen going black, saves a graveyard file, and updates death statistics.
function player_dies()
  local killername = "!"
  if (player.killer and player.killer.baseType == "creature") then killername = ", courtesy of ".. player.killer:get_name() .. "."
  elseif (player.killer and player.killer.source and player.killer.source.baseType == "creature") then killername = ", courtesy of " .. player.killer.source:get_name() .. "." end
  output:out("You were killed" .. killername)  
  if not currGame.cheats.regenMapOnDeath then output:out("Press any key to continue...") end
  action = "dying"
  player.speed=100
  tween(1,player.color,{a=0})
  game.deadTween = Timer.every(1,advance_turn,5)
  tween(1,player,{perception=0},'linear',function() game:blackOut(5) end)
  if currGame.playTutorial == true then
    show_tutorial('death')
  end
  if not currGame.cheats.regenMapOnDeath then
    save_graveyard(player,currMap,player.killer,currGame.stats)
    update_stat('losses')
    delete_save(currGame.fileName,true)
  end
end

---Function that causes things to happen during "downtime." What that means and when that happens is up to you, this is just an example.
function downtime()
  --Max out HP and MP
  player.hp = player.max_hp
  player.mp = player.max_mp
  --Remove all non-permanent conditions:
  for condition,turns in pairs(player.conditions) do
    if turns ~= -1 then
      player:cure_condition(condition)
    end
  end
  --Repopulate dungeons, restock stores and factions:
  for _, branch in pairs(maps) do
    for _, m in pairs(branch) do
      m:populate_creatures()
    end
  end
  for _, store in pairs(currWorld.stores) do
    store:restock()
  end
  for _, faction in pairs(currWorld.factions) do
    faction:restock()
  end
end


---Refreshes the player's sightmap. Called every turn, may need to be called if something changes visibility for some reason (new lights or something that blocks sight showing up)
function refresh_player_sight()
  if not currMap then return end
  if not player.seeTiles then player.seeTiles = {} end
  for x=1,currMap.width,1 do
    if not player.seeTiles[x] then player.seeTiles[x] = {} end
    for y=1,currMap.height,1 do
      player.seeTiles[x][y] = player:can_see_tile(x,y,true)
    end
  end
end

---Show a tutorial message
--@param tutorial String. The ID of the tutorial to show.
function show_tutorial(tutorial)
  require "data.tutorials"
  game:show_popup(tutorials[tutorial],nil,nil,nil,true)
  currGame.tutorialsSeen[tutorial] = true
end

---Starts a mission at 0 and runs its begin() code
--@param missionID String. The ID of the mission. Can either be a pre-defined mission, or you can use any ad-hoc value if you want to use this to track something that's not an actual mission.
--@param startVal Anything. The starting status of the mission (Optional, defaults to 0)
--@param source Object. Where the mission came from (Optional)
--@param values Table. A table of values to store in the mission table in the format {index=value,index2=value2}
--@param skipFunc Boolean. Whether to skip the start() function (assuming the mission actually has one) (Optional)
--@return Anything. Either false if the mission didn't start, the returned value of the start() function if there was one, or true.
function start_mission(missionID,startVal,source,values,skipFunc)
  local mission = possibleMissions[missionID]
  local ret = true
  if not skipFunc and mission and mission.start then
    ret = mission.start(startVal)
  end
  if ret ~= false then --If the mission isn't pre-defined or doesn't have a finish() code
    set_mission_status(missionID,startVal or 0)
    if source then
      set_mission_data(missionID,'source',source)
    end
    if values then
      for i,v in pairs(values) do
        set_mission_data(missionID,i,v)
      end
    end
  end
  return ret
end

---Gets the status of a given mission.
--@param missionID String. The ID of the mission. Can either be a pre-defined mission, or you can use any ad-hoc value if you want to use this to track something that's not an actual mission.
--@return Anything. The status of the mission.
function get_mission_status(missionID)
  return (currGame.missionStatus[missionID] and currGame.missionStatus[missionID].status or nil)
end

---Sets a the status value of a mission to a specific value.
--@param missionID String. The ID of the mission. Can either be a pre-defined mission, or you can use any ad-hoc value if you want to use this to track something that's not a pre-defined mission.
--@param value Anything. The value you'd like to store.
function set_mission_status(missionID,val)
  if not currGame.missionStatus[missionID] then currGame.missionStatus[missionID] = {} end
  currGame.missionStatus[missionID].status = val
  return val
end

---Gets the value of an index of a given mission.
--@param missionID String. The ID of the mission. Can either be a pre-defined mission, or you can use any ad-hoc value if you want to use this to track something that's not a pre-defined mission.
--@param index String. The string that used as the index to search
--@return Anything. The value stored in the index given
function get_mission_data(missionID,index)
  return (currGame.missionStatus[missionID] and currGame.missionStatus[missionID][index] or nil)
end

---Sets a particular index of a mission to a specific value.
--@param missionID String. The ID of the mission. Can either be a pre-defined mission, or you can use any ad-hoc value if you want to use this to track something that's not an actual mission.
--@param index String. The string that will be used as the index to store this value
--@param value Anything. The value you'd like to store.
function set_mission_data(missionID,index,val)
  if not currGame.missionStatus[missionID] then currGame.missionStatus[missionID] = {} end
  currGame.missionStatus[missionID][index] = val
  return val
end

---Updates a mission's status value by a given number value. Generally, you should inly call this function on a mission that's already has number values as it status. If you don't, though, it'll just set the mission status to whatever the number you passed.
--@param missionID String. The ID of the mission. Can either be a pre-defined mission, or you can use any ad-hoc value if you want to use this to track something that's not an actual mission.
--@param amt Number. The amount to increase the status by. (optional, defaults to 1)
function update_mission_status(missionID,amt)
  local f = (currGame.missionStatus[missionID] and currGame.missionStatus[missionID].status or nil)
  amt = amt or 1
  local newVal = nil
  if type(f) == "number" then
    newVal = f + amt
  else
    newVal = amt
  end
  set_mission_status(missionID,newVal)
  return newVal
end

---Marks a mission as finished, removing it from the active mission table. Also runs the mission's finish() code if it's a pre-defined mission.
--@param missionID String. The ID of the mission. Can either be a pre-defined mission, or you can use any ad-hoc value if you want to use this to track something that's not an actual mission.
--@param endVal Anything. A value you want to store in the finished missions table (eg to determine how the mission ended if it has multiple endings). (Optional)
--@param skipFunc Boolean. Whether to skip the finish() function (assuming the mission actually has one) (Optional)
--@return Anything. Either false if the mission didn't end, the returned value of the finish() function if there was one, or true.
function finish_mission(missionID,endVal,skipFunc)
  local mission = possibleMissions[missionID]
  local ret = true
  if not skipFunc and mission and mission.finish then
    ret = mission.finish(endVal)
  end
  if ret ~= false then --If the mission isn't pre-defined or doesn't have a finish() code
    if not currGame.finishedMissions[missionID] then currGame.finishedMissions[missionID] = currGame.missionStatus[missionID] end
    currGame.finishedMissions[missionID].status = endVal or true
    currGame.finishedMissions[missionID].repetitions = (currGame.finishedMissions[missionID].repetitions or 0)+1
    currGame.missionStatus[missionID] = nil
  end
  return ret
end

---Checks whether an event can fire
--@param eid Number. The ID of the event
--@return Boolean. Whether or not the event can fire
function check_event(eid)
  local event = possibleEvents[eid]
  local faction = event.faction and currWorld.factions[event.faction] or false
  local favor = event.faction and player.favor[event.faction] or 0
  local basic_event_chance = currMap.event_chance or gamesettings.default_event_chance
  local countdown = faction and faction.event_countdown or currGame.event_countdown
  
  --Check if this event can occur on this map based on mapType, branches, and tags
  local acceptableMap = false
  if not event.mapTypes and not event.branches and not event.tags then
    acceptableMap = true
  else --Only run this if the event actually has a list of mapTypes, branches, or tags
    if (event.mapTypes and in_table(currMap.mapType,event.mapTypes)) or (event.branches and in_table(currMap.branch,event.branches)) then
      acceptableMap = true
    elseif event.tags then --Only run this if mapTypes and branches haven't matched yet
      local foundTag = false
      for _,tag1 in ipairs(event.tags) do
        for _,tag2 in ipairs(currMap.tags) do
          if tag1 == tag2 then
            foundTag = true
            break
          end
        end
      end
      if foundTag then acceptableMap = true end
    end
  end
  if not acceptableMap then return false end

  --Random event chance and cooldown checks:
  if event.event_type~="random" or ((event.ignore_basic_chance or random(1,100) < basic_event_chance) and (event.ignore_cooldown or countdown < 1)) then
    --Faction checks:
    if not event.faction or ((not event.faction_members_only or player:is_faction_member(event.faction)) and (not event.max_favor or favor < event.max_favor) and (not event.min_favor or favor > event.min_favor)) then
      --Standard checks:
      if (not event.chance or random(1,100) < event.chance) and (not event.max_occurances or not currGame.events_occured[eid] or currGame.events_occured[eid] < event.max_occurances) then
        return true
      end --end basic if
    end --end faction check if
  end --end random chance if
  return false
end --end check_event function

---Cause an event to run its code
--@param eid Number. The event ID
--@param force Boolean. Whether to ignore the requires() code for the event
function activate_event(eid,force)
  local event = possibleEvents[eid]
  if force or not event.requires or event.requires() ~= false then
    event.action()
    currGame.events_occured[eid] = (currGame.events_occured[eid] or 0)+1
    if event.faction then
      local faction = currWorld.factions[event.faction]
      faction.event_countdown = math.max(faction.event_countdown,(event.cooldown or faction.event_cooldown or gamesettings.default_event_cooldown))
    else
      currGame.event_countdown = math.max(currGame.event_countdown,(event.cooldown or currMap.event_cooldown or gamesettings.default_event_cooldown))
    end
  end
end

---Loop through the list of events and activate all eligible ones of a given type
--@param event_type Text. The type of event. Possible event types: enter_map, enter_map_first_time, random, player_kills, boss_dies
function run_all_events_of_type(event_type)
  for eid, event in pairs(possibleEvents) do
    if event.event_type==event_type and (not event.faction or not currMap.forbid_faction_events) then
      if check_event(eid) then
        activate_event(eid)
      end
    end --end random event type
  end --end event for
end