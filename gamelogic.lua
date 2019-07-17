function new_game(mapSeed,playTutorial)
	maps = {}
  currGame = {startTime=os.date(),fileName=player.properName,playTutorial=playTutorial,tutorialsSeen={},missionFlags={},achievementDisqualifications={},cheats={},autoSave=prefs['autosaveTurns'],seed=mapSeed,stats={}}
  update_stat('games')
  currMap = nil
  local forceLevel,forceDepth = parse_name_for_level(player.properName)
	while (player.x == nil or player.y == nil) do
		currMap = mapgen:generate_map(75,75,(forceDepth or 1),forceLevel)
		player:moveTo(currMap.stairsDown.x,currMap.stairsDown.y)
		currMap.creatures[player] = player
	end
	table.insert(maps,currMap)
	output:setCursor(0,0)
	action = "moving"
	actionResult = nil
	target = nil
  output.text = {}
  output.buffer = {}
  output.toDisp = {{1},{},{}}
  output:set_camera(player.x,player.y,true)
  --This lil bastard will handle the beginning animation:
  player.color.a=0
  currMap:add_effect(Effect('beginningPlayerFlyer'),player.x,player.y)
  update_stat('level_reached',currMap.id or "graveyard")
end

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

function initialize_player()
	player = Creature('ghost',0)
	player.isPlayer = true
  player.playerAlly = true
	if (random(1,2) == 1) then
		player.gender = "male"
	else
		player.gender = "female"
	end
	player.properName=namegen:generate_human_name(player)
end

function calc_hit_chance(attacker,target)
  if attacker:is_type('ghost') then return 100 end
  local hitMod = attacker.melee - (target.dodging or 0)
  return math.min(math.max(70 + (hitMod > 0 and hitMod*2 or hitMod) + attacker:get_bonus('hit_chance') - (target.get_bonus and target:get_bonus('dodge_chance') or 0),25),95)
end

function calc_attack(attacker,target,forceHit)
	local dmg = attacker:get_damage()
  local dbonus = .01*attacker:get_bonus('damage_percent',true)
  dmg = dmg * (dbonus ~= 0 and dbonus or 1)
	local critChance = attacker:get_critical_chance()
	local hitMod = calc_hit_chance(attacker,target)
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
  update_stat('turns_on_level',currMap.id)
  
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

function win()
  print('winning!')
  action = "winning"
  update_stat('wins')
  save_win()
  delete_save(currGame.fileName,true)
  game:blackOut(5,true)
end

function game_over()
	player = nil
  currGame = nil
  game.blackAmt = nil
  Timer.cancel(game.blackOutTween)
  Timer.cancel(game.deadTween)
	Gamestate.switch(menu)
end

function goUp(force)
	if (currMap.boss == nil and force ~= true) then
    generate_boss()
	elseif (force or debugMode) or (currMap.boss == -1 or currMap.boss.hp < 1)  then
    update_stat('level_beaten',currMap.id)
    achievements:check('level_end')
    --[[if currMap.depth == 3 then
      win()
      return false
    end]]
    currMap.creatures[player] = nil
		if (maps[currMap.depth+1] == nil) then
			maps[currMap.depth+1] = mapgen:generate_map(75, 75,currMap.depth+1)
		end
		currMap.contents[player.x][player.y][player] = nil
		currMap=maps[currMap.depth+1]
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
    if currGame.cheats.fullMap == true then currMap:reveal() end
    game:show_level_description()
    output:set_camera(player.x,player.y,true)
    --Handle music:
    output:play_playlist(currMap.playlist)
    update_stat('level_reached',currMap.id)
    currGame.autoSave=true
    player.sees = nil
    refresh_player_sight()
    if currMap.depth == 2 then achievements:give_achievement('level_two')
    elseif currMap.depth == 6 then achievements:give_achievement('level_five')
    elseif currMap.depth == 11 then
      achievements:give_achievement('surface')
      achievements:check('game_end')
    end
	else
		output:out("You can't go to the next level until you defeat " .. currMap.boss:get_name(nil,true) .. ".")
	end
end

function regen_level()
  print('regening')
  local newGhost = Creature('ghost')
  local oldBody = player-- temporary variable to hold the player's old creature definition
  local oldMap = currMap
  currMap = mapgen:generate_map(75, 75,currMap.depth,currMap.levelID or "generic")
  maps[currMap.depth] = currMap
  oldMap.creatures[player] = nil
  oldMap.contents[player.x][player.y][player] = nil
  newGhost.x,newGhost.y = currMap.stairsDown.x,currMap.stairsDown.y
  currMap.contents[currMap.stairsDown.x][currMap.stairsDown.y][newGhost]=newGhost
  currMap.creatures[newGhost] = newGhost
  newGhost.properName = player.properName
  newGhost.isPlayer = true
  newGhost.gender = player.gender
  newGhost.playerAlly=true
  player = newGhost
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
    game.blackOutTween = tween(2,game,{blackAmt=0},'linear',function() if game.blackOutTween then Timer.cancel(game.blackOutTween) game:show_level_description() end action = "moving" end)
  else
    game:show_level_description()
  end
  if currGame.cheats.fullMap == true then currMap:reveal() end
  
   output:set_camera(player.x,player.y,true)
  --Handle music:
  output:play_playlist(currMap.playlist)
  currGame.autoSave=true
end

function generate_boss()
  achievements:check('boss')
  local alreadyThere = false
  if currMap.boss then
    alreadyThere = true
  else
    player.sees = nil
    if currMap.levelID and specialLevels[currMap.levelID].generate_boss then --if the level has special boss code, run that
      return specialLevels[currMap.levelID]:generate_boss()
    elseif currMap.bossID then --if the level has a special boss set, use that as the boss
      currMap.boss = Creature(currMap.bossID,possibleMonsters[currMap.bossID].level)
    else --if none of those are true
      for id,c in pairs(possibleMonsters) do
        if (c.level == currMap.depth and c.isBoss == true and not c.specialOnly) then
          currMap.boss = Creature(id,c.level)
          break
        end -- end level if
      end --end monster for
      if not currMap.boss then
        currMap.boss = -1
        game:show_popup("Weird. There's no boss for this level. Might want to do something about that. For now though, just go up again.")
        return
      end --if there's no boss for this level, just ingore it
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

function get_stat(stat_type,id)
  if stat_type and id then
    if currGame.stats[stat_type] == nil then return 0
    elseif currGame.stats[stat_type][id] == nil then return 0
    else return currGame.stats[stat_type][id] end
  end
end

function perform_move(direction)
	local xMod, yMod = 0,0
	if (direction == "left" or direction==keybindings.west) then
    xMod = -1
	elseif (direction == "right" or direction==keybindings.east) then
		xMod = 1
	elseif (direction == "up" or direction==keybindings.north) then
		yMod = -1
	elseif (direction == "down" or direction==keybindings.south) then
		yMod = 1
	elseif (direction==keybindings.northwest) then
		xMod = -1
		yMod = -1
	elseif (direction==keybindings.northeast) then
		xMod = 1
    yMod = -1
	elseif (direction==keybindings.southeast) then
		xMod = 1
    yMod = 1
	elseif (direction==keybindings.southwest) then
		xMod = -1
    yMod = 1
	end
  if action == "targeting" then
    output:moveCursor(xMod,yMod)
	elseif (action == "moving") then
    move_player(player.x+xMod,player.y+yMod)
  end
end
  
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
      local possession = actionResult.name == "Possession"
			if (actionResult:use({x=x,y=y},player) ~= false) then
        actionResult = nil
        if not possession then 
          advance_turn()
        end
				action="moving"
        output:setCursor(0,0)
			end
		elseif (actionResult.target_type == "creature") then
			if (creat) then
        local possession = actionResult.name == "Possession"
				if (actionResult:use(creat,player) ~= false and actionResult ~= possibleSpells['possession']) then
					actionResult = nil
          if not possession then 
            advance_turn()
          end
					action="moving"
          output:setCursor(0,0)
				end
			else --if no creature
				return false
			end --end if (creat)
		end --end square vs. creature if
	end --end main if
end --end function

function player_dies()
	if (player.id ~= "ghost") then
    update_stat('deaths_as_creature',player.id)
		local oldBody = player-- temporary variable to hold the player's old creature definition
		local newGhost = Creature('ghost',0)
		newGhost.properName = oldBody.properName
		--oldBody.properName = nil
		newGhost.isPlayer = true
		newGhost.gender = oldBody.gender
    newGhost.playerAlly=true
    output:out("You are ejected from the body of " .. oldBody:get_name(false,true) .. "!")
		newGhost:give_condition('invincibility',2)
    oldBody:remove()
    currMap:add_creature(newGhost,oldBody.x,oldBody.y)
    game.newGhost = newGhost
	else
    local killername = "!"
    if (player.killer and player.killer.baseType == "creature") then killername = ", courtesy of ".. player.killer:get_name() .. "."
  elseif (player.killer and player.killer.source and player.killer.source.baseType == "creature") then killername = ", courtesy of " .. player.killer.source:get_name() .. "." end
    output:out("Your spirit returns to the Nether Regions" .. killername)  
    if not currGame.cheats.regenLevelOnDeath then output:out("Press any key to continue...") end
		action = "dying"
    player.speed=100
    tween(1,player.color,{a=0})
    game.deadTween = Timer.every(1,advance_turn,5)
    tween(1,player,{perception=0},'linear',function() game:blackOut(5) end)
    if currGame.playTutorial == true then
      show_tutorial('death')
    end
    if not currGame.cheats.regenLevelOnDeath then
      save_graveyard(player.properName,currMap.depth,player.killer,currMap.name,currGame.stats)
      update_stat('losses')
      delete_save(currGame.fileName,true)
    end
	end
end

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

--10-20: 10
--20-30: 15
--30-50: 20
function calc_possession_cooldown()
  local possessions = currGame.stats['total_possessions']
  if possessions < 10 then
    return 0
  elseif possessions <= 30 then
    return math.floor(possessions-10)/2
  else
    return math.min(20,10+math.floor((possessions-30)/4))
  end
end

function show_tutorial(tutorial)
  require "data.tutorials"
  game:show_popup(tutorials[tutorial],nil,nil,nil,true)
  currGame.tutorialsSeen[tutorial] = true
end

function get_mission_flag(flag)
  return currGame.missionFlags[flag]
end

function set_mission_flag(flag,val)
  currGame.missionFlags[flag] = val
end

function update_mission_flag(flag,amt)
  local f = currGame.missionFlags[flag]
  amt = amt or 1
  if type(f) == "number" then
    currGame.missionFlags[flag] = f + amt
  else
    currGame.missionFlags[flag] = amt
  end
end