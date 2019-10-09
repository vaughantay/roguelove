local load_mod_media = function(modFolder)
  --Load images:
  local folders = love.filesystem.getDirectoryItems("mods/" .. modFolder .. '/images')
  for _,folderName in pairs(folders) do
    local info = love.filesystem.getInfo("mods/" .. modFolder .. '/images/' .. folderName)
    if info.type == "directory" then
      local files = love.filesystem.getDirectoryItems("mods/" .. modFolder .. '/images/' .. folderName)
      for _,fileName in pairs(files) do
        local extension = string.sub(fileName, -4)
        if extension == ".png" then
          fileName = string.sub(fileName,1,-5)
          images[folderName .. fileName] = love.graphics.newImage("mods/" .. modFolder .. "/images/" .. folderName .. "/" .. fileName .. ".png")
          print("loading mod image: " .. folderName .. fileName)
        end --end extension check
      end --end fileName for
    end --end is folder if
  end --end folderName for
  for _,tileset in pairs(love.filesystem.getDirectoryItems("mods/" .. modFolder .. '/images/levels')) do
    local files = love.filesystem.getDirectoryItems("mods/" .. modFolder .. '/images/levels/' .. tileset)
    for _,fileName in pairs(files) do
      local extension = string.sub(fileName, -4)
      if extension == ".png" then
        fileName = string.sub(fileName,1,-5)
        images[tileset .. fileName] = love.graphics.newImage("mods/" .. modFolder .. "/images/levels/" .. tileset .. "/" .. fileName .. ".png")
        print("loading mod image: " .. tileset .. fileName)
      end --end extension check
    end --end fileName for
  end
  --Load sounds:
  local files = love.filesystem.getDirectoryItems("mods/" .. modFolder .. "/sounds")
  for _,soundFile in pairs(files) do
    local extension = string.sub(soundFile, -4)
      if extension == ".mp3" or extension == ".ogg" or extension == ".wav" then
        local soundName = string.sub(soundFile,1,-5)
        sounds[soundName] = love.sound.newSoundData("mods/" .. modFolder .. "/sounds/" .. soundFile)
      print("loading mod sound: " .. soundName)
    end
  end --end for
end --end media load function

function load_mod(mod,mediaOnly)
  --Load media first:
    load_mod_media(mod)
    if mediaOnly then return end
    
  --Set up a "sandbox" environment 
  local env = {}
  setmetatable(env, {__index = _G}) --the sandbox environment will still have access to all the regular functions, but you won't be able to replace any global variables. You WILL, however, be able to replace global tables' values
  love.filesystem.setRequirePath("mods/" .. mod .. "/?.lua;mods/" .. mod .. "/?/init.lua")
  
  local fileToLoad = ("mods/" .. mod .. "/mod.lua")
  local ok, loadmod = pcall( love.filesystem.load, fileToLoad)
  if ok and loadmod then
    setfenv(loadmod, env) --s
    local ok2, loadedmod = pcall(loadmod)
    if ok2 then
      --Basic content loading:
      if loadedmod['ai'] then
        for id,newAI in pairs(loadedmod['ai']) do
          ai[id] = newAI --AI changes will replace by default! (because they're functions, not tables, and so can't have an replace flag
        end --end content for
      end
      if loadedmod['conditions'] then
        for id,condition in pairs(loadedmod['conditions']) do
          condition.modded=true
          if not conditions[id] or condition.replace then
            conditions[id] = condition
          else --if not new and not overwriting, just replace the fields that are defined in the mod file
            for key,value in pairs(condition) do
              conditions[id][key] = value
            end
          end
        end --end content for
      end
      if loadedmod['creatures'] then
        for id,creat in pairs(loadedmod['creatures']) do
          creat.modded=true
          if not possibleMonsters[id] or creat.replace then
            possibleMonsters[id] = creat
          else --if not new and not overwriting, just replace the fields that are defined in the mod file
            for key,value in pairs(creat) do
              possibleMonsters[id][key] = value
            end
          end
        end --end content for
      end
      if loadedmod['damage_types'] then
        for id,dtype in pairs(loadedmod['damage_types']) do
          damage_types[id] = dtype --damage type changes will replace by default! (because they're functions, not tables, and so can't have an replace flag
        end --end content for
      end
      if loadedmod['effects'] then
        for id,eff in pairs(loadedmod['effects']) do
          eff.modded=true
          if not effects[id] or eff.replace then
            effects[id] = eff
          else --if not new and not overwriting, just replace the fields that are defined in the mod file
            for key,value in pairs(eff) do
              effects[id][key] = value
            end
          end
        end --end content for
      end
      if loadedmod['features'] then
        for id,feat in pairs(loadedmod['features']) do
          feat.modded=true
          if not possibleFeatures[id] or feat.replace then
            possibleFeatures[id] = feat
          else --if not new and not overwriting, just replace the fields that are defined in the mod file
            for key,value in pairs(feat) do
              possibleFeatures[id][key] = value
            end
          end
        end --end content for
      end
      if loadedmod['layouts'] then
        for id,layout in pairs(loadedmod['layouts']) do
          layouts[id] = layout --layout changes will replace by default! (because they're functions, not tables, and so can't have an replace flag
        end --end content for
      end
      if loadedmod['levels'] then
        for id,level in pairs(loadedmod['levels']) do
          level.modded=true
          if not specialLevels[id] or level.replace then
            specialLevels[id] = level
          else --if not new and not overwriting, just replace the fields that are defined in the mod file
            for key,value in pairs(level) do
              specialLevels[id][key] = value
            end
          end
          if level.depth then
            if specialLevels.index[level.depth] then
              table.insert(specialLevels.index[level.depth],id)
            else
              specialLevels.index[level.depth] = {id}
            end --end if depth
          end
        end --end content for
      end
      if loadedmod['levelCreatures'] then
        for id, levelCreats in pairs(loadedmod['levelCreatures']) do
          if specialLevels[id] then
            for _,creat in pairs(levelCreats) do
              table.insert(specialLevels[id].creatures,creat)
            end
          end
        end
      end --end levelcreatures for
      if loadedmod['levelModifiers'] then
        for id,level in pairs(loadedmod['levelModifiers']) do
          levelModifiers[id] = level --level modifier changes will replace by default! (because they're functions, not tables, and so can't have an replace flag
        end --end content for
      end
      if loadedmod['projectiles'] then
        for id,projectile in pairs(loadedmod['projectiles']) do
          projectile.modded=true
          if not projectiles[id] or projectile.replace then
            projectiles[id] = projectile
          else --if not new and not overwriting, just replace the fields that are defined in the mod file
            for key,value in pairs(projectile) do
              projectiles[id][key] = value
            end
          end
        end --end content for
      end
      if loadedmod['rangedAttacks'] then
        for id,ranged in pairs(loadedmod['rangedAttacks']) do
          ranged.modded=true
          if not rangedAttacks[id] or ranged.replace then
            rangedAttacks[id] = ranged
          else --if not new and not overwriting, just replace the fields that are defined in the mod file
            for key,value in pairs(ranged) do
              rangedAttacks[id][key] = value
            end
          end
        end --end content for
      end
      if loadedmod['roomDecorators'] then
        for id,room in pairs(loadedmod['roomDecorators']) do
          roomDecorators[id] = room --room decorator changes will replace by default! (because they're functions, not tables, and so can't have an replace flag
        end --end content for
      end
      if loadedmod['roomTypes'] then
        for id,room in pairs(loadedmod['roomTypes']) do
          roomTypes[id] = room --room type changes will replace by default! (because they're functions, not tables, and so can't have an replace flag
        end --end content for
      end
      if loadedmod['nameLists'] then
        for id,list in pairs(loadedmod['nameLists']) do
          if list.replace or not namegen.lists[id] then
            list.replace = nil
            namegen.lists[id] = list
          else
            namegen.lists[id] = merge_arrays(namegen.lists[id],list)
          end
        end --end content for
      end
      if loadedmod['nameGenerators'] then
        for id,generator in pairs(loadedmod['nameGenerators']) do
          if id ~= "lists" then --we're not going to let someone replace the entire "lists" table, because that'll probably break stuff
            namegen[id] = generator --name generator changes will replace by default! (because they're functions, not tables, and so can't have an replace flag
          end
        end --end content for
      end
      if loadedmod['spells'] then
        for id,spell in pairs(loadedmod['spells']) do
          spell.modded=true
          if not possibleSpells[id] or spell.replace then
            possibleSpells[id] = spell
          else --if not new and not overwriting, just replace the fields that are defined in the mod file
            for key,value in pairs(spell) do
              possibleSpells[id][key] = value
            end
          end
        end --end content for
      end
      if loadedmod['tilesets'] then
        for id,tileset in pairs(loadedmod['tilesets']) do
          tileset.modded=true
          if not tilesets[id] or tileset.replace then
            tilesets[id] = tileset
          else --if not new and not overwriting, just replace the fields that are defined in the mod file
            for key,value in pairs(tileset) do
              tilesets[id][key] = value
            end
          end
        end --end content for
      end
      --[[if loadedmod['customCode'] and type(loadedmod['customCode']) == "function" then
        local ok3, custCode = pcall(loadedmod['customCode'])
        if ok3 then
          print("Custom code in mod " .. fileToLoad .. " succesfully ran, returned: " .. tostring(custCode))
        else
          print("Error in custom code in mod " .. fileToLoad .. ", returned: " .. tostring(custCode))
        end
      end]]
      print("Mod " .. fileToLoad .. " succesfully executed.")
      love.filesystem.setRequirePath("?.lua;?/init.lua")
      return true
    end --end if ok executing mod
    print("Error in executing mod " .. fileToLoad .. ": " .. tostring(loadedmod))
  end --end if ok loading mod
  print("Error in loading mod " .. fileToLoad .. ": " .. tostring(loadmod))
end

--[[function load_all_mods()
  if not love.filesystem.exists('mods/') then
    love.filesystem.createDirectory('mods')
  end
  local mods = love.filesystem.getDirectoryItems('mods')
  for _, fileName in pairs(mods) do
    local fileToLoad = nil
    if love.filesystem.isDirectory(fileName) then --if the file is a folder
      if love.filesystem.exists('mods/' .. fileName .. '/mod.lua') then
        fileToLoad = 'mods.' .. fileName .. '.mod'
      end
    end --end folder if
    local extension = string.sub(fileName, -4)
    if extension == ".lua" then --if the file is a lua file,
      fileToLoad = 'mods/' .. fileName
    end
    if fileToLoad then
      print('loading mod: ' .. fileToLoad)
      load_mod(fileToLoad)
    end --end file exists if
  end --end mod for
end]]

function load_all_mod_info()
  local modInfo = {}
  if not love.filesystem.getInfo('mods/') then
    love.filesystem.createDirectory('mods')
  end
  local mods = love.filesystem.getDirectoryItems('mods')
  for _, fileName in pairs(mods) do
    local fileToLoad = nil
    if love.filesystem.getInfo('mods/' .. fileName .. '/info.lua') then
      fileToLoad = 'mods/' .. fileName .. '/info.lua'
    end
    if fileToLoad then
      print('loading mod info: ' .. fileToLoad)
      local m = load_mod_info(fileToLoad)
      if m then
        m.id = fileName
        modInfo[#modInfo+1] = m
      end
    end --end file exists if
  end --end mod for
  return modInfo
end

function load_mod_info(mod)
  --Set up a "sandbox" environment 
  local env = {}
  setmetatable(env,{}) --the sandbox environment will still have access to all the regular functions, but you won't be able to replace any global variables
  
  local ok, loadmod = pcall( love.filesystem.load, mod)
  if ok and loadmod then
    setfenv(loadmod, env) --s
    local ok2, loadedmod,m2 = pcall(loadmod)
    if ok2 then
      return {name=loadedmod.name,description=loadedmod.description,author=loadedmod.author,modVersion=loadedmod.modVersion,gameVersion=loadedmod.gameVersion,requirements=loadedmod.requirements,incompatibilities=loadedmod.incompatibilities,graphicsOnly=loadedmod.graphicsOnly}
    end
  end
  return false
end