function register_classes()
  bitser.registerClass('Creature',Creature)
  bitser.registerClass('Effect',Effect)
  bitser.registerClass('Feature',Feature)
  bitser.registerClass('Map',Map)
  bitser.registerClass('Projectile',Projectile)
  bitser.registerClass('Item',Item)
  bitser.registerClass('Store',Store)
  bitser.registerClass('Faction',Faction)
  bitser.registerClass('Spell',Spell)
end

function save_game(screenshot,fileName)
  fileName = fileName or currGame.fileName
	for _, branch in pairs(maps) do
    for _, m in pairs(branch) do
      m:clear_all_pathfinders()
    end
	end
  --maps = {} --comment this if you want to save all the maps in the saved game
  local inf = love.filesystem.getInfo("saves")
  if not inf or inf.fileType ~= "directory" then
    love.filesystem.createDirectory("saves")
  end
  if screenshot then
    screenshot:encode('png', "saves/" .. fileName .. ".png");
  end
  local saveData = {player=player, maps=maps, currMap=currMap,currGame=currGame,currWorld=currWorld,gamesettings=gamesettings}
  local ok, err = pcall(bitser.dumpLoveFile,"saves/" .. fileName .. ".sav",saveData) -- load the chunk safely
  if not ok or err then
    output:out("Saving error:" .. tostring(err))
    print("Saving error: ",err)
    return false
  else
    output:out("Game Saved.")
  end
end

function load_game(fileName)
	if (love.filesystem.getInfo(fileName) == false) then
		return false
	end
  local saveData = bitser.loadLoveFile(fileName)
  if type(saveData) == "table" and saveData.player and saveData.maps and saveData.currMap and saveData.currGame and saveData.currWorld then
    player,maps,currMap,currGame,currWorld = saveData.player, saveData.maps, saveData.currMap, saveData.currGame, saveData.currWorld
    currMap:clear_all_pathfinders()
    if not currGame.cheats then currGame.cheats = {} end --delet this eventually I guess
    currGame.fileName = string.sub(fileName,7,-5) --in case the file's name got changed
    cancel_targeting()
    target = nil
    output.text = {}
    output.buffer = {}
    output.toDisp = {{1},{},{}}
    output:set_camera(player.x,player.y,true)
    output:out("Welcome back.")
    output:play_playlist(currMap.playlist)
    return true
  end
  return false
end

function load_all_saves()
  local sortByDate = function(a,b)
    return a.date > b.date
  end
  
  local saveFiles = love.filesystem.getDirectoryItems('saves')
  local saveData = {}
  for _,fileName in pairs(saveFiles) do
    if string.sub(fileName,-4) == ".sav" then
      local sd = {}
      local info = love.filesystem.getInfo("saves/" .. fileName)
      sd.fileName = fileName
      sd.date = info.modtime
      saveData[#saveData+1] = sd
    end
  end --end for
  table.sort(saveData,sortByDate)
  return saveData
end

function load_save_info(fileName)
  if love.filesystem.getInfo("saves/" .. fileName) then
    local sd = bitser.loadLoveFile("saves/" .. fileName)
    sd.fileName = fileName
    local info = love.filesystem.getInfo("saves/" .. fileName)
    sd.date = info.modtime
    if sd.player and sd.maps and sd.currMap then
      if love.filesystem.getInfo("saves/" .. string.sub(fileName,1,-5) .. ".png") then
        sd.screenshot = love.graphics.newImage("saves/" .. string.sub(fileName,1,-5) .. ".png")
      end --end screenshot if
      return sd
    end --end if sd.player etc
  end -- end if exists
  return false
end

--[[function load_all_save_info()
  local sortByDate = function(a,b)
    return a.date > b.date
  end

  local saveFiles = love.filesystem.getDirectoryItems('saves')
  local saveData = {}
  for _,fileName in pairs(saveFiles) do
    local sd = {}
    sd.player,sd.maps,sd.currMap,sd.stats = Lady.load_all("saves/" .. fileName)
    sd.fileName = fileName
    sd.date = love.filesystem.getLastModified("saves/" .. fileName)
    if sd.player and sd.maps and sd.currMap and sd.stats then
      if love.filesystem.exists("saves/" .. string.sub(fileName,1,-5) .. ".png") then
        sd.screenshot = love.graphics.newImage("saves/" .. string.sub(fileName,1,-5) .. ".png")
      end
      saveData[#saveData+1] = sd
    end
  end
  table.sort(saveData,sortByDate)
  return saveData
end]]

function delete_save(fileName,noSuffix)
  if not noSuffix then fileName = string.sub(fileName,1,-5) end
  if love.filesystem.getInfo("saves/" .. fileName .. ".sav") then
    love.filesystem.remove("saves/" .. fileName .. ".sav")
  end
  if love.filesystem.getInfo("saves/" .. fileName .. ".png") then
    love.filesystem.remove("saves/" .. fileName .. ".png")
  end
end

--[[function save_scores()
	Lady.save_all("scores.sav", highscores)
end

function load_scores()
	if (love.filesystem.exists("scores.sav") == false) then
		return {}
	else
		local ok, loadedScores = pcall( love.filesystem.load, "scores.sav" ) -- load the chunk safely
		if not ok then
			return {}
		end
		return loadedScores()
	end
end]]

function save_stats()
  require "lib.serialize"
	love.filesystem.write("stats.sav",serialize(totalstats))
end

function load_stats()
  if (love.filesystem.getInfo("stats.sav") == false) then
		return {}
	else
		local ok, loadedStats = pcall( love.filesystem.load, "stats.sav" ) -- load the chunk safely
		if not ok or not loadedStats then
			return {}
		end
		return loadedStats()
	end
end

--[[function save_monsterpedia()
	require "lib.serialize"
	love.filesystem.write("monsterpedia.sav",serialize(monsterpedia))
end

function load_monsterpedia()
	if (love.filesystem.exists("monsterpedia.sav") == false) then
		return {}
	else
	local ok, loadedpedia = pcall( love.filesystem.load, "monsterpedia.sav" ) -- load the chunk safely
		if not ok then
			return {}
		end
		return loadedpedia()
	end
end]]

function save_prefs()
  require "lib.serialize"
  prefs['keys'] = keybindings
  love.filesystem.write("prefs.sav",serialize(prefs))
end

function load_prefs()
  require "defaultprefs"
  if (love.filesystem.getInfo('prefs.sav')) then
    local ok, loadedprefs = pcall( love.filesystem.load, "prefs.sav" ) -- load the chunk safely
    if ok then
      loadedprefs = loadedprefs()
      -- Preferences is outdated. Regenerate.
      if loadedprefs.prefsVersion ~= prefs.prefsVersion then
        love.filesystem.remove("prefs.sav")
        return
      end
      for action, info in pairs(keybindings) do
        if loadedprefs['keys'][action].keyboard then
          keybindings[action].keyboard = loadedprefs['keys'][action].keyboard
        end
        if loadedprefs['keys'][action].gamepad then
          keybindings[action].gamepad = loadedprefs['keys'][action].gamepad
        end
      end
      for pref,val in pairs (prefs) do
        if loadedprefs[pref] ~= nil then
          prefs[pref] = loadedprefs[pref]
        end
      end
      love.window.setMode(prefs['width'],prefs['height'],{fullscreen=prefs['fullscreen'],fullscreentype=(prefs['fstype'] or nil),resizable=true,minwidth=1024,minheight=768,vsync=prefs['vsync']})
      if prefs['maximizedWindow'] == true then love.window.maximize() end
    end
  end
end

function save_graveyard(creature,map,killer,stats)
  require "lib.serialize"
  local graves = load_graveyard()
  if killer and killer.baseType == "creature" then
    if killer.properName then killer = killer.properName .. (vowel(killer.name) and ", an " or (", a ")) .. killer.name
    else killer = (killer.properNamed and "" or (vowel(killer.name) and "an " or "a ")) .. killer.name end
  else
    killer = "an unknown scary thing"
  end
  graves[#graves+1] = {properName=creature.properName,name=creature.name,date=os.time(),killer = killer,mapname=map:get_name(),stats=stats,branch=map.branch,depth=map.depth}
  love.filesystem.write("graveyard.sav",serialize(graves))
end

function load_graveyard()
  if (love.filesystem.getInfo('graveyard.sav')) then
    local ok, loadedgrave = pcall( love.filesystem.load, "graveyard.sav" ) -- load the chunk safely
    if ok then
      loadedgrave = loadedgrave()
      return loadedgrave
    end
  end
  return {} --if no loaded graveyard then return empty
end

function save_win()
  require "lib.serialize"
  local wins = load_wins()
  wins[#wins+1] = {properName=player.properName,name=player.name,date=os.time(),stats=currGame.stats,player={properName=player.properName,name=player.name,class=player.class,species=player.id}} --TODO: Save more player info in a way that doesn't break the game
  love.filesystem.write("wins.sav",serialize(wins))
end

function load_wins()
  if (love.filesystem.getInfo('wins.sav')) then
    local ok, loadedwins = pcall( love.filesystem.load, "wins.sav" ) -- load the chunk safely
    if not ok or not loadedwins then
      loadedwins = {}
    else
      loadedwins = loadedwins()
    end
    return loadedwins
  end
  return {} --if no loaded wins then return empty
end