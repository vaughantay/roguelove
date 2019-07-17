gamestats = {}

function gamestats:enter(previous)
  self.previous = previous
  self.yModPerc = 100
  self.screen = "stats"
  self.cursorX,self.cursorY=1,1
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  self.transY = 0
  self.maxTransY = 0
  self.sideTransY = 0
  self.maxSideTransY = 0
  local graveyard = load_graveyard()
  local wins = load_wins()
  local gravesayings = {"R.I.P","Here Lies","In Memorium","Always Remembered"}
  self.graveyard = {}
  self.wins = {}
  self.stats = {}
  
  --Sorting functions:
  local sortByDate = function(a,b)
    return (a.date and a.date or 0) > (b.date and b.date or 0)
  end
  local sortByMost = function(a,b)
    return (a.sortBy and a.sortBy or 0) > (b.sortBy and b.sortBy or 0)
  end
  local sortByLeast = function(a,b)
    return (a.sortBy and a.sortBy or 0) < (b.sortBy and b.sortBy or 0)
  end
  
  --Deal with Stats:
  self.stats[1] = {id="achievements",header="Achievements",label = "Achievements",stats={},expand=true}
  
  local abilityStats = {}
  if totalstats.ability_used then
    for abil,uses in pairs(totalstats.ability_used) do
      local id = #abilityStats+1
      abilityStats[id] = {}
      abilityStats[id].ability = abil
      abilityStats[id].uses = uses
      abilityStats[id].sortBy = uses
    end
    table.sort(abilityStats,sortByMost)
    local whichAbil = abilityStats[1] and (abilityStats[1].ability == "Possession" or abilityStats[1].ability == "Repair Body") and (abilityStats[2] and (abilityStats[2].ability == "Possession" or abilityStats[2].ability == "Repair Body") and 3 or 2) or 1
  end
  self.stats[2] = {id="abilities",header="Ability Usage",label = (abilityStats[whichAbil] and "Favorite Ability: " .. abilityStats[whichAbil].ability .. " (" .. abilityStats[whichAbil].uses .. " uses)" or "Favorite Abilities"),stats=abilityStats,expand=true}
  
  local creatTurns,fav=0,nil
  local creatureStats = {}
  if totalstats.turns_as_creature then
    for creat,turns in pairs(totalstats.turns_as_creature) do
      local id = #creatureStats+1
      creatureStats[id] = {}
      creatureStats[id].creat = creat
      creatureStats[id].turns = turns
      if creat ~= "ghost" then
        creatureStats[id].kills = (totalstats.kills_as_creature and totalstats.kills_as_creature[creat] or 0)
        creatureStats[id].possessions = (totalstats.creature_possessions and totalstats.creature_possessions[creat] or 0)
        creatureStats[id].explosions = (totalstats.exploded_creatures and totalstats.exploded_creatures[creat] or 0)
        creatureStats[id].explosionPercent = round((creatureStats[id].explosions / creatureStats[id].possessions)*100)
        local ratio = round(turns/(totalstats.creature_possessions[creat] or 1))
        creatureStats[id].ratio = ratio
        creatureStats[id].sortBy = ratio
        creatureStats[id].killRatio = round((creatureStats[id].kills or 0)/((creatureStats[id].possessions and creatureStats[id].possessions > 0 and creatureStats[id].possessions) or 1))
        if ratio > creatTurns or fav==nil then
          creatTurns,fav=ratio,creat
        end
      end --end if creat ~= ghost
    end --end creat for
    table.sort(creatureStats,sortByMost)
  end
  self.stats[3] = {id="creatures",header="Creature Possession Stats",label = (fav and "Favorite Creature: " ..  ucfirst(possibleMonsters[fav].name) .. " (" .. creatTurns .. " average turns per possession)" or "Favorite Creatures"),stats=creatureStats,expand=true}
  
  local killStats = {}
  if totalstats.creature_kills then
    for creat,kills in pairs(totalstats.creature_kills) do
      local id = #killStats+1
      killStats[id] = {}
      killStats[id].creat = creat
      killStats[id].kills = kills
      killStats[id].sortBy = kills
    end
    table.sort(killStats,sortByMost)
  end
  self.stats[4] = {id="kills",header="Creature Kills",label=(killStats[1] and "Most Killed Creature: " .. ucfirst(possibleMonsters[killStats[1].creat].name) .. " (" .. killStats[1].kills .. " kills)" or "Kills"),stats=killStats,expand=true}
  
  --[[local explosionStats = {}
  for creat,explosions in pairs(totalstats.exploded_creatures) do
    local id = #explosionStats+1
    explosionStats[id] = {}
    explosionStats[id].creat = creat
    explosionStats[id].explosions = explosions
    explosionStats[id].sortBy = explosions
  end
  table.sort(explosionStats,sortByMost)
  self.stats[5] = {id="explosions",header="Creature Explosions",label=(killStats[1] and "Most Exploded Creature: " .. ucfirst(possibleMonsters[explosionStats[1].creat].name) .. " (" .. explosionStats[1].explosions .. " explosions)" or "Explosions"),stats=explosionStats,expand=true}]]
  
  local leaderStats = {}
  if totalstats.ally_kills_as_creature then
    for leader,kills in pairs(totalstats.ally_kills_as_creature) do
      if leader ~= "ghost" then
        local id = #leaderStats+1
        local deaths = (totalstats.ally_deaths_as_creature and totalstats.ally_deaths_as_creature[leader] or 0)
        local possessions = (totalstats.creature_possessions and totalstats.creature_possessions[leader] or 1)
        local thralls = (totalstats.thralls_by_body and totalstats.thralls_by_body[leader] or 1)
        local killsPerPossession = round(kills/(possessions or 1))
        local thrallsPerPossession = round(thralls/(possessions or 1))
        local killsPerFollower = round(kills/(thralls or 1))
        leaderStats[id] = {}
        leaderStats[id].creat = leader
        leaderStats[id].kills = kills
        leaderStats[id].thralls = thralls
        leaderStats[id].followerDeaths = deaths
        leaderStats[id].possessions = possessions
        leaderStats[id].killsPerFollower = killsPerFollower
        leaderStats[id].killsPerPossession = killsPerPossession
        leaderStats[id].thrallsPerPossession = thrallsPerPossession
        leaderStats[id].sortBy = killsPerFollower
      end
    end
    table.sort(leaderStats,sortByMost)
  end
  self.stats[5] = {id="leader_kills",header = "Follower Kills as Leader",label=(leaderStats[1] and "Most Effective Leader Body: " .. ucfirst(possibleMonsters[leaderStats[1].creat].name) .. " (" .. leaderStats[1].killsPerFollower .. " Average Follower Kills)" or "Follower Kills as Leader"),stats=leaderStats,expand=true}
  
  local followerStats = {}
  if totalstats.thralls then
    for follower,thralls in pairs(totalstats.thralls) do
      local id = #followerStats+1
      local deaths = (totalstats.creature_ally_deaths and totalstats.creature_ally_deaths[follower] or 0)
      local kills = (totalstats.allied_creature_kills and totalstats.allied_creature_kills[follower] or 0)
      local killsPer = round(kills/(thralls or 1))
      followerStats[id] = {}
      followerStats[id].creat = follower
      followerStats[id].thralls = thralls
      followerStats[id].kills = kills
      followerStats[id].deaths = deaths
      followerStats[id].killsPer = killsPer
      followerStats[id].sortBy = killsPer
    end
    table.sort(followerStats,sortByMost)
  end
  self.stats[6] = {id="follower_kills",header="Kills by Followers",label=(followerStats[1] and "Most Effective Follower: " .. ucfirst(possibleMonsters[followerStats[1].creat].name) .. " (" .. followerStats[1].kills .. " Average Kills per Follower)" or "Kills by Followers"),stats=followerStats,expand=true}
  
  
  local levelStats = {}
  if totalstats.level_reached then
    for level,reached in pairs(totalstats.level_reached) do
      local id = #levelStats+1
      levelStats[#levelStats+1] = {}
      local beaten = (totalstats.level_beaten and totalstats.level_beaten[level] or 0)
      local turns = (totalstats.turns_on_level and totalstats.turns_on_level[level] or 0)
      levelStats[id].reached = reached
      levelStats[id].beaten = beaten
      levelStats[id].losses = (totalstats.losses_per_level and totalstats.losses_per_level[level] or 0)
      levelStats[id].beatPercent = round((beaten/reached or 1)*100)
      levelStats[id].turns = turns
      levelStats[id].avgTurns = round(turns/(reached or 1))
      levelStats[id].avgTurnsBeat = beaten > 0 and round(turns/beaten) or "N/A"
      levelStats[id].name = (specialLevels[level] and (specialLevels[level].genericName or specialLevels[level].generateName()) or false)
      levelStats[id].depth = (specialLevels[level] and specialLevels[level].depth or false)
      if not levelStats[id].name then
        local depth = string.sub(level,8)
        levelStats[id].name = "Non-Special Level"
        levelStats[id].depth = tonumber(depth)
      end
      levelStats[id].sortBy = levelStats[id].depth
    end
    table.sort(levelStats,sortByLeast)
  end
  self.stats[7] = {id="levels",label="Stats by Level",header="Stats by Level",stats=levelStats,expand=true}
  
  self.stats[8] = {id="games",label="Total Games Started: " .. (totalstats.games or 0)}
  self.stats[9] = {id="wins",label="Games Won: " .. (totalstats.wins or 0)}
  self.stats[10] = {id="losses",label="Games Lost: " .. (totalstats.losses or 0)}
  self.stats[11] = {id="turns",label="Total Turns Played: " .. (totalstats.turns or 0)}
  self.stats[12] = {id="turnspergame",label="Average Turns/Game: " .. round((totalstats.turns or 0)/(totalstats.games or 1))}
  
  
  --Deal with Wins:
  for _, win in pairs(wins) do
    self.wins[#self.wins+1] = win
    if win.stats and win.stats.turns_as_creature then
      win.stats.turns_as_creature.ghost = nil
      win.stats.favoriteCreatTurns,win.stats.favoriteCreat = get_largest(win.stats.turns_as_creature)
      if win.stats.creature_possessions then win.stats.favoriteCreatPossessions = win.stats.creature_possessions[win.stats.favoriteCreat] end
    end
    if win.stats and win.stats.ability_used then
      win.stats.ability_used.Possession = nil
      win.stats.ability_used['Repair Body'] = nil
      win.stats.favoriteAbilityTurns,win.stats.favoriteAbility = get_largest(win.stats.ability_used)
    end
    if win.stats and win.stats.turns_on_level then
        win.stats.favoriteLevelTurns,win.stats.favoriteLevelID = get_largest(win.stats.turns_on_level)
        win.stats.favoriteLevel = (specialLevels[win.stats.favoriteLevelID] and specialLevels[win.stats.favoriteLevelID].generateName() or false)
        if not win.stats.favoriteLevel then
          local depth = (type(level) == "string" and string.sub(win.stats.favoriteLevelID,8) or win.stats.favoriteLevelID)
          win.stats.favoriteLevel = "Generic Level " .. depth
        end
      end
    win.stats.killPossessionAverage = (win.stats.total_possessions and round((win.stats.kills or 0)/win.stats.total_possessions) or "N/A")
  end
  table.sort(self.wins,sortByDate)
  
  --Deal with Deaths:
  for depth,level in pairs(graveyard) do
    for _, grave in pairs(level) do
      grave.saying = gravesayings[random(#gravesayings)]
      grave.depth = depth
      self.graveyard[#self.graveyard+1] = grave
      if grave.stats and grave.stats.turns_as_creature then
        grave.stats.turns_as_creature.ghost = nil
        grave.stats.favoriteCreatTurns,grave.stats.favoriteCreat = get_largest(grave.stats.turns_as_creature)
        if grave.stats.creature_possessions then grave.stats.favoriteCreatPossessions = grave.stats.creature_possessions[grave.stats.favoriteCreat] end
      end
      if grave.stats and grave.stats.ability_used then
        grave.stats.ability_used.Possession = nil
        grave.stats.favoriteAbilityTurns,grave.stats.favoriteAbility = get_largest(grave.stats.ability_used)
      end
      if grave.stats and grave.stats.turns_on_level then
        grave.stats.favoriteLevelTurns,grave.stats.favoriteLevelID = get_largest(grave.stats.turns_on_level)
        grave.stats.favoriteLevel = (specialLevels[grave.stats.favoriteLevelID] and specialLevels[grave.stats.favoriteLevelID].generateName() or false)
        if not grave.stats.favoriteLevel then
          local depth = (type(level) == "string" and string.sub(grave.stats.favoriteLevelID,8) or grave.stats.favoriteLevelID)
          grave.stats.favoriteLevel = "Generic Level " .. depth
        end
      end
      grave.stats.killPossessionAverage = (grave.stats.total_possessions and round((grave.stats.kills or 0)/grave.stats.total_possessions) or "N/A")
    end
  end
  table.sort(self.graveyard,sortByDate)
  
  --Last two stats, that depend on wins and losses
  local totalWinTurns = 0
  for _,win in pairs(self.wins) do
    totalWinTurns = totalWinTurns+win.stats.turns
  end
  self.stats[13] = {id="turnsperwin",label="Average Turns/Win: " .. (totalstats.wins and round(totalWinTurns/totalstats.wins) or "N/A"),stats={}}
  local totalLossTurns = 0
  for _,grave in pairs(self.graveyard) do
    totalLossTurns = totalLossTurns+grave.stats.turns
  end
  self.stats[14] = {id="turnsperloss",label="Average Turns/Loss: " .. round(totalLossTurns/(totalstats.losses or 1)),stats={}}
end

function gamestats:draw()
  self.previous:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local padding=prefs['noImages'] and 14 or 32
  local fontSize = prefs['fontSize']
  love.graphics.push()
  love.graphics.translate(0,height*(self.yModPerc/100))
  --Draw top nav bar:
  
  output:draw_window(0,0,width-padding,64)
  self.closebutton = output:closebutton(math.floor(padding/2),math.floor(padding/2))
  love.graphics.setFont(fonts.graveFontBig)
  local buttonWidth = fonts.graveFontBig:getWidth("Stats")
  self.statsbutton = output:button(padding,padding,buttonWidth,false,(self.cursorY == 1 and self.cursorX == 1 and "hover" or nil),"Stats")
  buttonWidth = fonts.graveFontBig:getWidth("Wins" .. (totalstats.wins and "(" .. totalstats.wins .. ")" or ""))
  self.winsbutton = output:button(math.floor((width-padding-buttonWidth)/2),padding,buttonWidth,false,(self.cursorY == 1 and self.cursorX == 2 and "hover" or nil),"Wins" .. (totalstats.wins and "(" .. totalstats.wins .. ")" or ""))
  buttonWidth = fonts.graveFontBig:getWidth("Losses" .. (totalstats.losses and "(" .. totalstats.losses .. ")" or ""))
  self.lossesbutton = output:button(width-padding-buttonWidth,padding,buttonWidth,false,(self.cursorY == 1 and self.cursorX == 3 and "hover" or nil),"Losses" .. (totalstats.losses and "(" .. totalstats.losses .. ")" or ""))
  --[[if self.cursorY == 1 and self.cursorX == 1 then
    local w = fonts.graveFontBig:getWidth("Stats")
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",math.floor(padding/3)*2,math.floor(padding/3)*2,w+math.floor(padding/3)*2,48)
    setColor(255,255,255,255)
  end
  love.graphics.printf("Stats",padding,math.floor(padding/3)*2,width-padding*2,"left")
  if self.cursorY == 1 and self.cursorX == 2 then
    local w = fonts.graveFontBig:getWidth("Wins (" .. (totalstats.wins or 0) .. ")")
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",math.floor(width/2)-w,math.floor(padding/3)*2,w+padding,48)
    setColor(255,255,255,255)
  end
  love.graphics.printf("Wins (" .. (totalstats.wins or 0) .. ")",padding,math.floor(padding/3)*2,width-padding*2,"center")
  if self.cursorY == 1 and self.cursorX == 3 then
    local w = fonts.graveFontBig:getWidth("Losses (" .. (totalstats.losses or 0) .. ")")
    setColor(100,100,100,255)
    love.graphics.rectangle("fill",width-(w+math.floor(padding/3)*2)-padding,math.floor(padding/3)*2,w+padding,48)
    setColor(255,255,255,255)
  end
  love.graphics.printf("Losses (" .. (totalstats.losses or 0) .. ")",padding,math.floor(padding/3)*2,width-padding*2,"right")]]
  if self.screen == "stats" then
    local sidebarX = round(width/2)+padding
    local stopSelect = sidebarX-padding*2
    output:draw_window(0,64+padding,sidebarX-padding,height-padding)
    output:draw_window(sidebarX,64+padding,width-padding,height-padding)
    love.graphics.setFont(fonts.graveFontBig)
    love.graphics.printf("Statistics",1,80+padding,sidebarX,"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.push()
    love.graphics.translate(0,self.transY)
    local printY = 80+padding*3
    local mouseX,mouseY = love.mouse.getPosition()
    local mouseMoved = false
    if mouseX ~= output.mouseX or mouseY ~= output.mouseY then
      mouseMoved = true
      output.mouseX,output.mouseY=mouseX,mouseY
    end
    
    --Display the stat list:
    for id,stat in ipairs(self.stats) do
      if self.cursorY-1 == id then
        setColor(100,100,100,255)
        love.graphics.rectangle("fill",padding,printY,stopSelect,2+fontSize)
        setColor(255,255,255,255)
      elseif mouseX > padding and mouseX < sidebarX-padding and mouseY > printY and mouseY < printY+fontSize and stat.expand then
        setColor(50,50,50,255)
        love.graphics.rectangle("fill",padding,printY,stopSelect,2+fontSize)
        setColor(255,255,255,255)
      end
      if printY+self.transY >= 80+padding*3 then
        local expand = false
        if stat.expand then
          expand = true
        end
        love.graphics.print(stat.label .. (expand and " > " or ""),padding,printY)
      end
      printY = printY + fontSize
      self.maxTransY = 0 --height-printY
    end--end stat for
    love.graphics.pop()
    
    --Display the selected stat:
    local stat = self.stats[self.cursorY-1]
    if stat and stat.expand then
      love.graphics.setFont(fonts.graveFontBig)
      love.graphics.printf(stat.header or "Stat?",sidebarX,80+padding,width-sidebarX,"center")
      love.graphics.setFont(fonts.textFont)
      local function stencilFunc()
        love.graphics.rectangle("fill",sidebarX,80+padding*2,width-sidebarX,height-padding*2-98)
      end
      love.graphics.stencil(stencilFunc,"replace",1)
      love.graphics.setStencilTest("greater",0)
      if stat.id == "achievements" then
        if self.maxSideTransY < 0 then
          local scrollAmt = self.sideTransY / self.maxSideTransY
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt)
        end
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        local printY = 96+padding*(prefs['noImages'] and 6 or 3)
        local printX = sidebarX+64
        local gridX,gridY=1,1
        local maxGridX=nil

        for id,achiev in pairs(achievementList) do
          local isMouse = (mouseX > printX-32 and mouseX < printX+96 and mouseY > printY-32+self.sideTransY and mouseY < printY+96+self.sideTransY)
          local selected = (gridX == self.cursorX-1 and gridY == (self.achievementCursorY or 1)) or (mouseMoved and isMouse)
          if selected then
            self.cursorX,self.achievementCursorY = gridX+1,gridY
            setColor(100,100,100,255)
            love.graphics.rectangle('fill',printX-32,printY-32,128,128)
            setColor(255,255,255,255)
            local _, tlines = fonts.descFont:getWrap(achiev.description,128)
            love.graphics.printf(achiev.description,printX-32,math.max(printY-32,math.floor(printY+64-8-(#tlines*fontSize))),128,"center")
            if not isMouse then
              if printY-32+self.sideTransY < 80+padding*2 then self:sidebarScrollUp()
              elseif printY+96+self.sideTransY > height then self:sidebarScrollDown() end
            end
          else
            local has = achievements:has_achievement(id)
            local img = (has and (images['achievement' .. id] and images['achievement' .. id] or images['achievementunknown']) or (images['achievement' .. id .. 'locked'] and images['achievement' .. id .. 'locked'] or images['achievementunknownlocked']))
            if prefs['noImages'] then
              if not has then
                setColor(125,125,125,255)
                love.graphics.printf(achiev.name,printX-32,printY+16,128,"center")
                setColor(255,255,255,255)
              else
                love.graphics.printf(achiev.name,printX-32,printY+16,128,"center")
              end
            else
              setColor(33,33,33,255)
              love.graphics.rectangle('fill',printX,printY-8,66,66)
              setColor(255,255,255,255)
              love.graphics.rectangle('line',printX-1,printY-9,66,66)
              love.graphics.draw(img,printX,printY-8)
              love.graphics.printf(achiev.name,printX-32,printY+64-8,128,"center")
            end
          end
          printX = printX+128
          gridX = gridX+1
          if printX+128 > width then
            printX = sidebarX+64
            printY = printY + 128
            maxGridX = gridX
            gridX = 1
            gridY = gridY+1
          end
        end --end achiev for
        local maxGridY = gridY
        local lastGridX = gridX
        if self.cursorX > maxGridX or ((self.achievementCursorY or 1) == maxGridY and self.cursorX > lastGridX) then
          if self.achievementCursorY < maxGridY then
            self.cursorX = maxGridX
          else
            self.cursorX = math.min(maxGridX,lastGridX)
          end
        end
        if (self.achievementCursorY or 1) > maxGridY then self.achievementCursorY = maxGridY end
        self.maxSideTransY = height-printY-128
        love.graphics.pop()
      elseif stat.id == "abilities" then
        if self.maxSideTransY < 0 then
          local scrollAmt = self.sideTransY / self.maxSideTransY
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt)
        end
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        local printY = 80+padding*3
        for _,abil in pairs(stat.stats) do
          love.graphics.print(abil.ability .. ": " .. abil.uses,sidebarX+padding,printY)
          printY = printY+fontSize
        end
        self.maxSideTransY = height-printY
        love.graphics.pop()
      elseif stat.id == "creatures" then
        if self.maxSideTransY < 0 then
          if self.cursorX == 2 then
            setColor(50,50,50,255)
            love.graphics.rectangle("fill",width-padding*2,96+padding*2,padding,height-padding-96-padding*2)
            setColor(255,255,255,255)
          end
          local scrollAmt = self.sideTransY / self.maxSideTransY
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt)
        end
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        love.graphics.printf("Total Possessions: " .. (totalstats.total_possessions or 0) .. ", Total Explosions: " .. (totalstats.explosions or 0),sidebarX,80+padding+fontSize*3,width-sidebarX,"center")
        local printY = 80+padding*3
        for _,creat in pairs(stat.stats) do
          local name = ucfirst(possibleMonsters[creat.creat].name)
          if creat.possessions then
            love.graphics.print("Total " .. name.. " possessions: " .. creat.possessions,sidebarX+padding*2,printY)
            printY = printY+fontSize
          end
          if creat.explosions then
            love.graphics.print("Total " .. name.. " explosions: " .. creat.explosions,sidebarX+padding*2,printY)
            printY = printY+fontSize
          end
          if creat.explosionPercent then
            love.graphics.print("Explosion ratio: " .. creat.explosionPercent .. "%",sidebarX+padding*2,printY)
            printY = printY+fontSize
          end
          love.graphics.print("Turns as " .. name.. ": " .. creat.turns,sidebarX+padding*2,printY)
          if creat.ratio then
            printY = printY+fontSize
            love.graphics.print("Average turns per possession: " .. creat.ratio,sidebarX+padding*2,printY)
          end
          if creat.kills then
            printY = printY+fontSize
            love.graphics.print("Kills as " .. name.. ": " .. creat.kills,sidebarX+padding*2,printY)
          end
          if creat.killRatio then
            printY = printY+fontSize
            love.graphics.print("Average Kills per possession: " .. creat.killRatio,sidebarX+padding*2,printY)
          end
          local c = possibleMonsters[creat.creat]
          c.image_frame = 1
          c.baseType = "creature"
          if c.id == nil then c.id = creat.creat end
          output.display_entity(c,sidebarX+padding-8,printY-round(fontSize*(creat.creat == "ghost" and 0.5 or 3.5)),"force")
          printY = printY+fontSize*2
        end
        self.maxSideTransY = height-printY-fontSize
        love.graphics.pop()
      elseif stat.id == "kills" then
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        love.graphics.printf("Total Kills: " .. (totalstats.kills or 0),sidebarX,80+padding+fontSize*3,width-sidebarX,"center")
        local printY = 80+padding*3
        for _,creat in pairs(stat.stats) do
          love.graphics.print(ucfirst(possibleMonsters[creat.creat].name) .. "s Killed: " .. creat.kills,sidebarX+padding,printY)
          printY = printY+fontSize
        end
        self.maxSideTransY = height-printY
        love.graphics.pop()
      elseif stat.id == "explosions" then
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        love.graphics.printf("Total Explosions: " .. totalstats.explosions,sidebarX,80+padding+fontSize*3,width-sidebarX,"center")
        local printY = 80+padding*3
        for _,creat in pairs(stat.stats) do
          love.graphics.print(ucfirst(possibleMonsters[creat.creat].name) .. "s Exploded: " .. creat.explosions,sidebarX+padding,printY)
          printY = printY+fontSize
        end
        self.maxSideTransY = height-printY
        love.graphics.pop()
      elseif stat.id == "leader_kills" then
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        local printY = 80+padding*3
        for _,creat in pairs(stat.stats) do
          local name = ucfirst(possibleMonsters[creat.creat].name)
          love.graphics.print("Total Followers as " .. name .. ": " .. creat.thralls,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Follower kills as " .. name .. ": " .. creat.kills,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Average Kills per Follower as " .. name .. ": " .. creat.killsPerFollower,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print(name .. " Possessions: " .. creat.possessions,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Average Number of Followers per " .. name .. " Possession: " .. creat.thrallsPerPossession,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Average Kills by Followers per " .. name .. " Possession: " .. creat.killsPerPossession,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Follower deaths as " .. name .. ": " .. creat.followerDeaths,sidebarX+padding*2,printY)
          local c = possibleMonsters[creat.creat]
          c.image_frame = 1
          c.baseType = "creature"
          if c.id == nil then c.id = creat.creat end
          output.display_entity(c,sidebarX+padding-8,printY-round(fontSize*(creat.creat == "ghost" and 0.5 or 3.5)),"force")
          printY = printY+fontSize*2
        end
        self.maxSideTransY = height-printY
        love.graphics.pop()
      elseif stat.id == "follower_kills" then
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        local printY = 80+padding*3
        for _,creat in pairs(stat.stats) do
          local name = ucfirst(possibleMonsters[creat.creat].name)
          love.graphics.print("Number of " .. name .. " Followers: " .. creat.thralls,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Kills by " .. name .. " Followers: " .. creat.kills,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Average Kills per " .. name .. " Follower: " .. creat.killsPer,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print(name .. " Follower Deaths: " .. creat.deaths,sidebarX+padding*2,printY)
          local c = possibleMonsters[creat.creat]
          c.image_frame = 1
          c.baseType = "creature"
          if c.id == nil then c.id = creat.creat end
          output.display_entity(c,sidebarX+padding-8,printY-round(fontSize*(creat.creat == "ghost" and 0.5 or 2)),"force")
          printY = printY+fontSize*2
        end
        self.maxSideTransY = height-printY
        love.graphics.pop()
      elseif stat.id == "levels" then
        if self.maxSideTransY < 0 then
          if self.cursorX == 2 then
            setColor(50,50,50,255)
            love.graphics.rectangle("fill",width-padding*2,96+padding*2,padding,height-padding-96-padding*2)
            setColor(255,255,255,255)
          end
          local scrollAmt = self.sideTransY / self.maxSideTransY
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt)
        end
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        local printY = 80+padding*3
        for level,stat in ipairs(stat.stats) do
          love.graphics.printf((stat.depth and "Depth " .. tostring(11-stat.depth) .. ": " or "") .. tostring(stat.name),sidebarX,printY,width-sidebarX,"center")
          printY=printY+fontSize
          love.graphics.print("Times Reached: " .. stat.reached,sidebarX+padding*2,printY)
          printY=printY+fontSize
          love.graphics.print("Times Beaten: " .. stat.beaten,sidebarX+padding*2,printY)
          printY=printY+fontSize
          love.graphics.print("Beaten Ratio: " .. stat.beatPercent .. "%",sidebarX+padding*2,printY)
          printY=printY+fontSize
          love.graphics.print("Total Turns on Level: " .. stat.turns,sidebarX+padding*2,printY)
          printY=printY+fontSize
          love.graphics.print("Average Turns on Level: " .. stat.avgTurns,sidebarX+padding*2,printY)
          printY=printY+fontSize
          love.graphics.print("Average Turns to Beat Level: " .. stat.avgTurnsBeat,sidebarX+padding*2,printY)
          printY=printY+fontSize*2
        end
        self.maxSideTransY = height-printY
        love.graphics.pop()
      end
      love.graphics.setStencilTest()
    end
  elseif self.screen == "wins" then
    local w1end,w2start,w2end = math.floor(width/2),math.ceil(width/2)+padding,math.ceil(width/2)+math.floor(width/2)-padding
    local windowY = 64+padding
    output:draw_window(0,windowY,w1end,height-padding)
    output:draw_window(w2start,windowY,w2end,height-padding)
    love.graphics.setFont(fonts.graveFontBig)
    love.graphics.printf("Wins",1,windowY+math.floor(padding/2),math.floor(width/2),"center")
    love.graphics.line(padding,windowY+math.floor(padding/2)+fontSize*3,w1end-padding,windowY+math.floor(padding/2)+fontSize*3)
    love.graphics.setFont(fonts.textFont)
    if self.maxTransY < 0 then
      local scrollAmt = self.transY / self.maxTransY
      self.scrollPositions = output:scrollbar(w1end-padding,96+padding*2,height-padding,scrollAmt)
    end
    love.graphics.push()
    local function stencilFunc()
      love.graphics.rectangle("fill",padding,windowY+math.floor(padding/2)+fontSize*3,w1end,height-padding-(windowY+math.floor(padding/2)+fontSize*2))
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,self.transY)
    local printY = windowY+padding*(prefs['noImages'] and 4 or 2)
    for id,grave in ipairs(self.wins) do
      local dateWidth = fonts.textFont:getWidth("Won " .. os.date("%H:%M, %b %d, %Y",grave.date))
      if self.cursorY-1 == id then
        setColor(100,100,100,255)
        love.graphics.rectangle("fill",padding,printY,w1end-padding*2,2+fontSize)
        setColor(255,255,255,255)
      else
        local mouseX,mouseY = love.mouse.getPosition()
        if mouseY-self.transY > printY and mouseY-self.transY < printY+fontSize and mouseX > padding and mouseX < w1end-padding then
          setColor(66,66,66,255)
          love.graphics.rectangle("fill",padding,printY,w1end-padding*2,2+fontSize)
          setColor(255,255,255,255)
        end
      end
      grave.printY = printY
      love.graphics.print(grave.name,padding,printY)
      love.graphics.printf("Won " .. os.date("%H:%M, %b %d, %Y",grave.date),w1end-padding-dateWidth,printY,dateWidth,"right")
      printY = printY+fontSize
    end
    self.maxTransY = height-printY-fontSize-padding
    love.graphics.setStencilTest()
    love.graphics.pop()
    if self.wins[self.cursorY-1] then
      local win = self.wins[self.cursorY-1]
      local printY = windowY+math.floor(padding/2)
      love.graphics.setFont(fonts.graveFontBig)
      love.graphics.printf(win.name,w2start,printY,w2end-w2start,"center")
      local _,lines = fonts.graveFontBig:getWrap(win.name,w2end-w2start+padding)
      printY = printY+padding*#lines
      love.graphics.setFont(fonts.graveFontSmall)
      love.graphics.printf("Won at " .. os.date("%H:%M, %b %d, %Y",win.date),w2start,printY,w2end-w2start,"center")
      printY = printY+padding
      if win.stats then
        love.graphics.setFont(fonts.textFont)
        love.graphics.print("Turns played: " .. (win.stats.turns or 0),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Kills: " .. (win.stats.kills or 0),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Possessions: " .. (win.stats.total_possessions or 0),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Average Kills per Body: " .. (win.stats.killPossessionAverage or 0),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Bodies exploded: " .. (win.stats.explosions or 0),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Most Time As: " .. (win.stats.favoriteCreat and ucfirst(possibleMonsters[win.stats.favoriteCreat].name) .. " (" .. win.stats.favoriteCreatTurns .. " turns, " .. (win.stats.favoriteCreatPossessions or "Unknown") .. " possessions)" or "Unknown"),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Favorite Ability: " .. (win.stats.favoriteAbility and win.stats.favoriteAbility .. " (" .. win.stats.favoriteAbilityTurns .. " uses)" or "Unknown"),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Most Time Spent On: " .. (win.stats.favoriteLevel and win.stats.favoriteLevel .. " (" .. win.stats.favoriteLevelTurns .. " turns)" or "Unknown"),w2start+padding,printY)
      end
    end
  elseif self.screen == "losses" then
    local w1end,w2start,w2end = math.floor(width/2),math.ceil(width/2)+padding,math.ceil(width/2)+math.floor(width/2)-padding
    local windowY = 64+padding
    output:draw_window(0,windowY,w1end,height-padding)
    output:draw_window(w2start,windowY,w2end,height-padding)
    love.graphics.setFont(fonts.graveFontBig)
    love.graphics.printf("Losses",1,windowY+math.floor(padding/2),math.floor(width/2),"center")
    love.graphics.line(padding,windowY+math.floor(padding/2)+fontSize*3,w1end-padding,windowY+math.floor(padding/2)+fontSize*3)
    love.graphics.setFont(fonts.textFont)
    if self.maxTransY < 0 then
      local scrollAmt = self.transY / self.maxTransY
      self.scrollPositions = output:scrollbar(w1end-padding,96+padding*2,height-padding,scrollAmt)
    end
    love.graphics.push()
    local function stencilFunc()
      love.graphics.rectangle("fill",padding,windowY+math.floor(padding/2)+fontSize*3,w1end,height-padding-(windowY+math.floor(padding/2)+fontSize*2))
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,self.transY)
    local printY = windowY+padding*(prefs['noImages'] and 4 or 2)
    for id,grave in ipairs(self.graveyard) do
      local dateWidth = fonts.textFont:getWidth("Died " .. os.date("%H:%M, %b %d, %Y",grave.date))
      if self.cursorY-1 == id then
        setColor(100,100,100,255)
        love.graphics.rectangle("fill",padding,printY,w1end-padding*2,2+fontSize)
        setColor(255,255,255,255)
      else
        local mouseX,mouseY = love.mouse.getPosition()
        if mouseY-self.transY > printY and mouseY-self.transY < printY+fontSize and mouseX > padding and mouseX < w1end-padding then
          setColor(66,66,66,255)
          love.graphics.rectangle("fill",padding,printY,w1end-padding*2,2+fontSize)
          setColor(255,255,255,255)
        end
      end
      grave.printY = printY
      love.graphics.print(grave.name,padding,printY)
      love.graphics.printf("Died " .. os.date("%H:%M, %b %d, %Y",grave.date),w1end-padding-dateWidth,printY,dateWidth,"right")
      printY = printY+fontSize
    end
    self.maxTransY = height-printY-fontSize-padding
    love.graphics.setStencilTest()
    love.graphics.pop()
    if self.graveyard[self.cursorY-1] then
      local grave = self.graveyard[self.cursorY-1]
      local printY = windowY+math.floor(padding/2)
      love.graphics.setFont(fonts.graveFontBig)
      love.graphics.printf(grave.saying,w2start,printY,w2end-w2start,"center")
      printY = printY+padding
      love.graphics.printf(grave.name,w2start,printY,w2end-w2start,"center")
      local _,lines = fonts.graveFontBig:getWrap(grave.name,w2end-w2start+padding)
      printY = printY+padding*#lines
      love.graphics.setFont(fonts.graveFontSmall)
      love.graphics.printf("Killed by " .. grave.killer,w2start,printY,w2end-w2start,"center")
      _,lines = fonts.graveFontBig:getWrap("Killed by " .. grave.killer,w2end-w2start+padding)
      printY = printY+math.floor(padding/3)*2*#lines
      love.graphics.printf("at " .. os.date("%H:%M, %b %d, %Y",grave.date),w2start,printY,w2end-w2start,"center")
      _,lines = fonts.graveFontBig:getWrap("at " .. os.date("%H:%M, %b %d, %Y",grave.date),w2end-w2start+padding)
      printY = printY+math.floor(padding/3)*2*#lines
      love.graphics.printf((grave.levelname and grave.levelname .. ", " or "") .. "Depth " .. grave.depth,w2start,printY,w2end-w2start,"center")
      printY = printY+padding
      if grave.stats then
        love.graphics.setFont(fonts.textFont)
        love.graphics.print("Turns played: " .. (grave.stats.turns or 0),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Kills: " .. (grave.stats.kills or 0),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Possessions: " .. (grave.stats.total_possessions or 0),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Average Kills per Body: " .. (grave.stats.killPossessionAverage or 0),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Bodies exploded: " .. (grave.stats.explosions or 0),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Most Time As: " .. (grave.stats.favoriteCreat and ucfirst(possibleMonsters[grave.stats.favoriteCreat].name) .. " (" .. grave.stats.favoriteCreatTurns .. " turns, " .. (grave.stats.favoriteCreatPossessions or "Unknown") .. " possessions)" or "Unknown"),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Favorite Ability: " .. (grave.stats.favoriteAbility and grave.stats.favoriteAbility .. " (" .. grave.stats.favoriteAbilityTurns .. " uses)" or "Unknown"),w2start+padding,printY)
        printY = printY + fontSize
        love.graphics.print("Most Time Spent On: " .. (grave.stats.favoriteLevel and grave.stats.favoriteLevel .. " (" .. grave.stats.favoriteLevelTurns .. " turns)" or "Unknown"),w2start+padding,printY)
      end
    end
  end
  love.graphics.pop()
end

function gamestats:keypressed(key)
  if key == "escape" then
    self:switchBack()
  elseif key == "up" then
    if self.screen == "stats" and self.cursorX > 1 and self.cursorY ~= 1 then
      if self.stats[self.cursorY-1] and self.stats[self.cursorY-1].id == "achievements" then
        self.achievementCursorY = math.max(self.achievementCursorY and self.achievementCursorY-1 or 1,1)
      else
        self:sidebarScrollUp()
        --self.sideTransY = math.min(self.sideTransY+prefs['fontSize']*5,0)
      end
    else
      self.cursorY = math.max(self.cursorY-1,1)
    end
  elseif key == "down" then
    local maxY = (self.screen == "losses" and #self.graveyard+1) or (self.screen == "stats" and #self.stats+1) or (self.screen == "wins" and #self.wins+1)
    if self.screen == "stats" and self.cursorX > 1 and self.cursorY ~= 1 then
      if self.stats[self.cursorY-1] and self.stats[self.cursorY-1].id == "achievements" then
        self.achievementCursorY = (self.achievementCursorY and self.achievementCursorY+1 or 2)
      else
        self:sidebarScrollDown()
        --self.sideTransY = math.max(self.sideTransY-prefs['fontSize']*5,self.maxSideTransY)
      end
    else
      if self.screen ~= "stats" or self.stats[self.cursorY].expand then
        self.cursorY = math.min(self.cursorY+1,(maxY or 1))
        if self.screen == "stats" then self.cursorX = 1 self.sideTransY = 0 end
      end
    end
  elseif key == "left" then
    if self.cursorY == 1 then
      self.cursorX = math.max(self.cursorX-1,1)
    else
      if self.screen == "stats" then
        self.cursorX = math.max(self.cursorX-1,1)
      else
        self.cursorY = 1
        self.cursorX = (self.screen == "losses" and 2 or 1)
      end
    end
  elseif key == "right" then
    if self.cursorY == 1 then
      self.cursorX = math.min(self.cursorX+1,3)
    else
      if self.screen == "stats" then
        if self.stats[self.cursorY-1] and self.stats[self.cursorY-1].expand and self.maxSideTransY < 0 then
          self.cursorX = self.cursorX + 1
          if not self.stats[self.cursorY-1] or self.stats[self.cursorY-1].id ~= "achievements" then
            self.cursorX = 2
          end
        end
      elseif self.screen == "wins" then
        self.cursorY = 1
        self.cursorX = 3
      end
    end
  elseif key == "return" then
    if self.cursorY == 1 then
      if self.cursorX == 1 then
        self.screen = "stats"
        self.transY = 0
        self.cursorY = 1
      elseif self.cursorX == 2 then
        self.screen = "wins"
        self.transY = 0
        self.cursorY = 1
      elseif self.cursorX == 3 then
        self.screen = "losses"
        self.transY = 0
        self.cursorY = 1
      end --end cursorX if
    end --end cursorY if
  end --end key if
end

function gamestats:wheelmoved(x,y)
  local padding=prefs['noImages'] and 14 or 32
  local sidebarX = round(love.graphics:getWidth()/2)+padding
  if self.screen ~= "stats" or love.mouse.getX() < sidebarX then
    if y < 0 then
      self:scrollDown()
    elseif y > 0 then
      self:scrollUp()
    end
  else
    if y > 0 then
      self:sidebarScrollUp()
      output.mouseX,output.mouseY=0,0
    elseif y < 0 then
      self:sidebarScrollDown()
      output.mouseX,output.mouseY=0,0
    end
  end
end

function gamestats:scrollDown()
  self.transY = math.max(self.transY-prefs['fontSize']*5,self.maxTransY)
end

function gamestats:scrollUp()
  self.transY = math.min(self.transY+prefs['fontSize']*5,0)
end

function gamestats:sidebarScrollDown()
  if self.maxSideTransY < 0 then self.sideTransY = math.max(self.sideTransY-prefs['fontSize']*5,self.maxSideTransY) end
end

function gamestats:sidebarScrollUp()
  if self.maxSideTransY < 0 then self.sideTransY = math.min(self.sideTransY+prefs['fontSize']*5,0) end
end

function gamestats:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
    return
  end
  
   --Handle scrolling:
  if (love.mouse.isDown(1)) and self.sideScrollPositions then
    local x,y = love.mouse.getPosition()
    local upArrow = self.sideScrollPositions.upArrow
    local downArrow = self.sideScrollPositions.downArrow
    local elevator = self.sideScrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:sidebarScrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:sidebarScrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then self:sidebarScrollUp()
      elseif y>elevator.endY then self:sidebarScrollDown() end
    end --end clicking on arrow
  end
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local x,y = love.mouse.getPosition()
    local upArrow = self.scrollPositions.upArrow
    local downArrow = self.scrollPositions.downArrow
    local elevator = self.scrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:scrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:scrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then self:scrollUp()
      elseif y>elevator.endY then self:scrollDown() end
    end --end clicking on arrow
  end
end

function gamestats:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function gamestats:mousepressed(x,y,button)
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    self:switchBack()
  elseif x > self.statsbutton.minX and x < self.statsbutton.maxX and y > self.statsbutton.minY and y < self.statsbutton.maxY then
    self.screen = "stats"
    self.transY = 0
    self.cursorY = 1
    self.cursorX = 1
  elseif x > self.winsbutton.minX and x < self.winsbutton.maxX and y > self.winsbutton.minY and y < self.winsbutton.maxY then
    self.screen = "wins"
    self.transY = 0
    self.cursorY = 1
    self.cursorX = 2
  elseif x > self.lossesbutton.minX and x < self.lossesbutton.maxX and y > self.lossesbutton.minY and y < self.lossesbutton.maxY then
    self.screen = "losses"
    self.transY = 0
    self.cursorY = 1
    self.cursorX = 3
  end 
   
  local padding=prefs['noImages'] and 14 or 32
  local fontSize = prefs['fontSize']
  local width = love.graphics:getWidth()
  local sidebarX = (self.screen == "stats" and round(width/2)+padding or math.ceil(width/2)+padding)
  local loopThrough = {}
  if self.screen == "stats" then
    loopThrough = self.stats
  elseif self.screen == "wins" then
    loopThrough = self.wins
  elseif self.screen == "losses" then
    loopThrough = self.graveyard
  end
  for id,item in ipairs(loopThrough) do
    local printY = (self.screen == "stats" and 80+padding*3+(id-1)*fontSize+self.transY or (item.printY and item.printY+self.transY or -1000))
    if x > padding and x < sidebarX-padding-(self.screen == "stats" and 0 or padding) and y > printY and y < printY+fontSize and (item.expand or self.screen ~= "stats") then
      self.cursorY = id+1
      self.cursorX = 1
      self.sideTransY = 0
      self.achievementCursorY=0
    end
  end
end