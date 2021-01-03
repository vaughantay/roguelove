---@module gamelogic

---Starts a new game, and does all the bookkeeping necessary for that. Generates the first map, and puts the player on it.
--@param mapSeed Number. The seed to use to generate the world. (optional)
--@param playTutorial Boolean. Whether or not to show tutorial messages this game. (optional)
--@param cheats Table. A table listing all the cheats in use this game. (optional)
--@param branch String. The ID of the branch to start on. (optional)
function new_game(mapSeed,playTutorial,cheats,branch)
	maps = {}
  branch = branch or gamesettings.default_starting_branch
  currGame = {startTime=os.date(),fileName=player.properName,playTutorial=playTutorial,tutorialsSeen={},missionFlags={},achievementDisqualifications={},cheats={},autoSave=prefs['autosaveTurns'],seed=mapSeed,stats={}}
  if cheats then currGame.cheats = cheats end
  update_stat('games')
  currMap = mapgen:generate_map(branch,1)
  player:moveTo(currMap.stairsUp.x,currMap.stairsUp.y)
  currMap.creatures[player] = player
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
  update_stat('map_reached',currMap.id)
end

---Figures out which level to load based on a given string. Used for level-skip cheats. TODO: Redo this for branches (probably just remove it entirely)
--@param name String. The name of the level to load, or "level#" to load any level at a given depth, or "generic#" to load the generic level at the given depth.
function parse_name_for_level(name)
  local depth = (string.sub(name,1,5) == "level" and tonumber(string.sub(name,6)) or (string.sub(name,1,7) == "generic") and tonumber(string.sub(name,8)))
  if specialLevels[name] then
    player.properName="Dirty Cheater"
    return name,(specialLevels[name].depth or 1)
  elseif string.sub(name,1,5) == "level" and depth and depth > 0 and depth <= gamesettings.levels then
    player.properName="Dirty Cheater"
    return nil,depth
  elseif string.sub(name,1,7) == "generic" and depth and depth > 0 and depth <= gamesettings.levels then
    player.properName="Dirty Cheater"
    return "generic",depth
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
  stores = {}
  for id,store in pairs(stores_static) do
    stores[id] = Store(store)
    stores[id].id = id
  end
  --Generate Factions:
  factions = {}
  for id,fac in pairs(possibleFactions) do
    factions[id] = Faction(fac)
    factions[id].id = id
  end
  --Generate dungeon branches:
  branches = {}
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
  currWorld.stores = stores
  currWorld.factions = factions
  currWorld.branches = branches --TODO: use currWorld elsewhere in the code
end

---Calculates the chance of hitting an opponent.
--@param attacker Creature. The creature doing the attacking.
--@param target Creature. The creature getting potentially hit
--@param item Item. The item the attacker is using.
function calc_hit_chance(attacker,target,item)
  local hitMod = attacker.melee - (target.dodging or 0)
  return math.min(math.max(70 + (hitMod > 0 and hitMod*2 or hitMod) + attacker:get_bonus('hit_chance') - (target.get_bonus and target:get_bonus('dodge_chance') or 0) + (item and item:get_accuracy() or 0),25),95)
end

---Calculates whether an attacker hits a target, whether it was a critical, and how much damage was done. Important to note: This function just *calculates* the damage, it does not apply it!
--@param attacker Creature. The creature attacking.
--@param target Creature. The creature getting attacked.
--@param forceHit Boolean. Whether to ignore hit chance and force a hit. (optional)
--@param item Item. The item the attacker is using, if any. (optional)
--@return result String. "hit", "miss", or "critical
--@return dmg Number. The damage to do.
function calc_attack(attacker,target,forceHit,item)
	local dmg = (item and item:get_damage(target,attacker) or attacker:get_damage())
  local dbonus = .01*attacker:get_bonus('damage_percent',true)
  dmg = dmg * (dbonus ~= 0 and dbonus or 1)
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
  
  --[[if player.energy >= 200 and not extraTurn then extraTurn = true player.energy = player.energy-100 end
    output:out("Player energy after extra turn dealy: " .. player.energy)

  if extraTurn ~= 'player_missed_turn' then player.energy = player.energy-100 end]]

    
  --Update stats:
  update_stat('turns')
  update_stat('turns_as_creature',player.id)
  if player.id == "ghost" and totalstats['turns_as_creature']['ghost'] >= 500 then
    achievements:give_achievement('ghost_turns')
  end
  currGame.stats['turns_in_current_body'] = (currGame.stats['turns_in_current_body'] or 1) + 1
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
  --print("Time to run turn: " .. tostring(os.clock()-pTime))
  
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
    elseif not currGame.tutorialsSeen['afterFirstPossession'] and player.id ~= "ghost" and get_stat('turns_as_creature',player.id) > 5 then
      show_tutorial('afterFirstPossession')
    end
  end
  
  if type(currGame.autoSave) == "number" and currGame.autoSave <= 0 then
    love.graphics.captureScreenshot("saves/" .. currGame.fileName .. ".png")
    save_game()
    currGame.autoSave = prefs['autosaveTurns']
  end
  refresh_player_sight()
end --end advance_turn

---This function is called when you win. It saves the win for posterity, and blacks out the screen.
function win()
  print('winning!')
  action = "winning"
  update_stat('wins')
  save_win()
  delete_save(currGame.fileName,true)
  game:blackOut(5,true)
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
    update_stat('map_beaten',currMap.id)
    achievements:check('map_end')
    currMap.creatures[player] = nil
    if not maps[branch] then maps[branch] = {} end
		if (maps[branch][depth] == nil) then
			maps[branch][depth] = mapgen:generate_map(branch,depth)
		end
		currMap.contents[player.x][player.y][player] = nil
		currMap=maps[branch][depth]
    local playerX,playerY = nil,nil
    for _,exit in pairs(currMap.exits) do
      if exit.branch == oldBranch and exit.depth == oldDepth then
        playerX,playerY = exit.x,exit.y
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
    update_stat('map_reached',currMap.id)
    currGame.autoSave=true
    player.sees = nil
    currMap:refresh_lightMap(true) -- refresh the lightmap, forcing it to refresh all lights
    refresh_player_sight()
	else
		output:out("You can't leave until you defeat " .. currMap.boss:get_name(nil,true) .. ".")
	end
end

---Regenerates the current map.
function regen_map()
  print('regening')
  currMap = mapgen:generate_map(currMap.branch,currMap.depth,currMap.mapType)
  maps[currMap.depth] = currMap
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
function generate_boss()
  achievements:check('boss')
  local alreadyThere = false
  if currMap.boss then
    alreadyThere = true
  else
    player.sees = nil
    if currMap.mapID and mapTypes[currMap.mapID].generate_boss then --if the map has special boss code, run that
      return mapTypes[currMap.mapID]:generate_boss()
    elseif currMap.bossID then --if the map has a special boss set, use that as the boss
      currMap.boss = Creature(currMap.bossID,possibleMonsters[currMap.bossID].level)
    else --if none of those are true
      for id,c in pairs(possibleMonsters) do
        --TODO: Redo normal bosses for to account for branches
        --[[if (c.level == currMap.depth and c.isBoss == true and not c.specialOnly) then
          currMap.boss = Creature(id,c.level)
          break
        end -- end level if]]
      end --end monster for
      if not currMap.boss then
        currMap.boss = -1
        return false
      end --if there's no boss for this map, just ingore it
    end --end bossID vs generic boss if
  end
  
  if currMap.boss and currMap.boss.bossText then
    game:show_popup(currMap.boss.bossText)
  else
    local text = "As you're about to go up the stairs, a gate suddenly clangs shut in front of them!\nYou realize that you are being stalked by" .. (currMap.boss.properNamed ~= true and " a " or " ") .. currMap.boss.name .. "!"
    game:show_popup(text)
  end
  
  --Boss music:
  --[[local playlist = output:make_playlist(currMap.bossPlaylist)
  if not playlist then playlist = output:make_playlist('genericdungeonboss') end
  output:play_playlist('silence')
  if playlist then
    output:play_playlist(playlist)
  end]]
  
  if alreadyThere then return end
  
  local x,y = random(player.x-5,player.x+5),random(player.y-5,player.y+5)
  while (x<2 or y<2 or x>=currMap.width or y>=currMap.height or currMap.boss:can_move_to(x,y) == false or player:can_see_tile(x,y) == false) do
    x,y = random(player.x-5,player.x+5),random(player.y-5,player.y+5)
  end
  currMap:add_creature(currMap.boss,x,y)
  currMap.boss:notice(player)
  currMap.boss:become_hostile(player)
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
		if (actionResult.target_type == "square") then
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
    save_graveyard(player.properName,currMap.depth,currMap.branch,player.killer,currMap.name,currGame.stats)
    update_stat('losses')
    delete_save(currGame.fileName,true)
  end
end

---Function that causes things to happen during "downtime." What that means and when that happens is up to you.
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
  --Repopulate dungeons:
  for _, branch in pairs(maps) do
    for _, m in pairs(branch) do
      m:populate_creatures()
    end
  end
  --TODO: Refresh store inventories
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

---Gets the value of a "mission flag." Mission flags aren't pre-defined, you can use them as you see fit to track whatever information you want in a given playthrough.
--@param flag String. The ID of the mission flag.
--@return Anything. The value of the flag.
function get_mission_flag(flag)
  return currGame.missionFlags[flag]
end

---Sets a "mission flag" to a specific value. Mission flags aren't pre-defined, you can use them as you see fit to track whatever information you want in a given playthrough.
--@param flag String. The ID of the mission flag.
--@param value Anything. The value you'd like to store.
function set_mission_flag(flag,val)
  currGame.missionFlags[flag] = val
end

---Updates a "mission flags" value by a given number value. Mission flags aren't pre-defined, you can use them as you see fit to track whatever information you want in a given playthrough. Only call this function on a mission flag that's using number values!
--@param flag String. The ID of the mission flag.
--@param amt Number. The amount to increase the flag by. (optional, defaults to 1)
function update_mission_flag(flag,amt)
  local f = currGame.missionFlags[flag]
  amt = amt or 1
  if type(f) == "number" then
    currGame.missionFlags[flag] = f + amt
  else
    currGame.missionFlags[flag] = amt
  end
end