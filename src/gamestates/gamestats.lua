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
  self.achievementCursorY=1
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
  if count(achievementList) > 0 then
    self.stats[1] = {id="achievements",header="Achievements",label = "Achievements",stats={},expand=true}
  end
  
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
  end
  self.stats[#self.stats+1] = {id="abilities",header="Ability Usage",label = (abilityStats[1] and "Favorite Ability: " .. abilityStats[1].ability .. " (" .. abilityStats[1].uses .. " uses)" or "Favorite Abilities"),stats=abilityStats,expand=true}
  
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
  self.stats[#self.stats+1] = {id="kills",header="Creature Kills",label=(killStats[1] and "Most Killed Creature: " .. ucfirst(possibleMonsters[killStats[1].creat].name) .. " (" .. killStats[1].kills .. " kills)" or "Kills"),stats=killStats,expand=true}
  
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
  self.stats[#self.stats+1] = {id="follower_kills",header="Kills by Followers",label=(followerStats[1] and "Most Effective Follower: " .. ucfirst(possibleMonsters[followerStats[1].creat].name) .. " (" .. followerStats[1].kills .. " Average Kills per Follower)" or "Kills by Followers"),stats=followerStats,expand=true}
  
  self.stats[#self.stats+1] = {id="games",label="Total Games Started: " .. (totalstats.games or 0)}
  self.stats[#self.stats+1] = {id="wins",label="Games Won: " .. (totalstats.wins or 0)}
  self.stats[#self.stats+1] = {id="losses",label="Games Lost: " .. (totalstats.losses or 0)}
  self.stats[#self.stats+1] = {id="turns",label="Total Turns Played: " .. (totalstats.turns or 0)}
  self.stats[#self.stats+1] = {id="turnspergame",label="Average Turns/Game: " .. round((totalstats.turns or 0)/(totalstats.games or 1))}
  
  
  --Deal with Wins:
  for _, win in pairs(wins) do
    self.wins[#self.wins+1] = win
    if win.stats and win.stats.ability_used then
      win.stats.favoriteAbilityTurns,win.stats.favoriteAbility = get_largest(win.stats.ability_used)
    end
  end
  table.sort(self.wins,sortByDate)
  
  --Deal with Deaths:
  for i,grave in pairs(graveyard) do
    grave.saying = gravesayings[random(#gravesayings)]
    self.graveyard[#self.graveyard+1] = grave
    if grave.stats and grave.stats.ability_used then
      grave.stats.favoriteAbilityTurns,grave.stats.favoriteAbility = get_largest(grave.stats.ability_used)
    end
  end
  table.sort(self.graveyard,sortByDate)
  
  --Last two stats, that depend on wins and losses
  local totalWinTurns = 0
  for _,win in pairs(self.wins) do
    totalWinTurns = totalWinTurns+(win.stats.turns or 0)
  end
  self.stats[#self.stats+1] = {id="turnsperwin",label="Average Turns/Win: " .. (totalstats.wins and round(totalWinTurns/totalstats.wins) or "N/A"),stats={}}
  local totalLossTurns = 0
  for _,grave in pairs(self.graveyard) do
    totalLossTurns = totalLossTurns+(grave.stats and grave.stats.turns or 0)
  end
  self.stats[#self.stats+1] = {id="turnsperloss",label="Average Turns/Loss: " .. round(totalLossTurns/(totalstats.losses or 1)),stats={}}
end

function gamestats:draw()
  self.previous:draw()
  local padding=prefs['noImages'] and 14 or 32
  local fontSize = prefs['fontSize']
  local uiScale = prefs['uiScale'] or 1
  local width, height = math.floor(love.graphics:getWidth()/uiScale),math.floor(love.graphics:getHeight()/uiScale)
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = math.floor(mouseX/uiScale),math.floor(mouseY/uiScale)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  --Draw top nav bar:
  
  output:draw_window(0,0,width-padding,64)
  self.closebutton = output:closebutton(math.floor(padding/2),math.floor(padding/2))
  love.graphics.setFont(fonts.menuFont)
  local buttonWidth = fonts.menuFont:getWidth("Stats")
  self.statsbutton = output:button(padding,padding,buttonWidth,false,(self.cursorY == 1 and self.cursorX == 1 and "hover" or nil),"Stats",true)
  buttonWidth = fonts.menuFont:getWidth("Wins" .. (totalstats.wins and "(" .. totalstats.wins .. ")" or ""))
  self.winsbutton = output:button(math.floor((width-padding-buttonWidth)/2),padding,buttonWidth,false,(self.cursorY == 1 and self.cursorX == 2 and "hover" or nil),"Wins" .. (totalstats.wins and "(" .. totalstats.wins .. ")" or ""),true)
  buttonWidth = fonts.menuFont:getWidth("Losses" .. (totalstats.losses and "(" .. totalstats.losses .. ")" or ""))
  self.lossesbutton = output:button(width-padding-buttonWidth,padding,buttonWidth,false,(self.cursorY == 1 and self.cursorX == 3 and "hover" or nil),"Losses" .. (totalstats.losses and "(" .. totalstats.losses .. ")" or ""),true)
  if self.screen == "stats" then
    local w1end,w2start,w2end = math.floor(width/2),math.ceil(width/2)+padding,math.ceil(width/2)+math.floor(width/2)-padding
    local windowY = 64+padding
    local sidebarX = round(width/2)+padding
    local stopSelect = sidebarX-padding*2-(self.maxTransY < 0 and 32 or 0)
    output:draw_window(0,64+padding,sidebarX-padding,height-padding)
    output:draw_window(sidebarX,64+padding,width-padding,height-padding)
    love.graphics.setFont(fonts.menuFont)
    love.graphics.printf("Statistics",1,80+padding,sidebarX,"center")
    love.graphics.setFont(fonts.textFont)
    if self.maxTransY < 0 then
      local scrollAmt = self.transY / self.maxTransY
      self.scrollPositions = output:scrollbar(w1end-padding,96+padding*2,height-padding,scrollAmt,true)
    end
    love.graphics.push()
    local function stencilFunc()
      love.graphics.rectangle("fill",padding,windowY+padding*2,w1end,height-padding-(windowY+padding*2))
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,self.transY)
    local printY = 80+padding*3
    
    --Display the stat list:
    for id,stat in ipairs(self.stats) do
      local expand = false
      if stat.expand then
        expand = true
      end
      local _,tlines = fonts.textFont:getWrap(stat.label .. (expand and " > " or ""),stopSelect)
      if self.cursorY-1 == id then
        setColor(100,100,100,255)
        love.graphics.rectangle("fill",padding,printY,stopSelect,math.ceil(2+fontSize*#tlines*1.15))
        setColor(255,255,255,255)
      elseif mouseX > padding and mouseX < sidebarX-padding and mouseY > printY and mouseY < math.ceil(printY+fontSize*#tlines*1.15) and stat.expand then
        setColor(50,50,50,255)
        love.graphics.rectangle("fill",padding,printY,stopSelect,math.ceil(2+fontSize*#tlines*1.15))
        setColor(255,255,255,255)
      end
      love.graphics.printf(stat.label .. (expand and " > " or ""),padding,printY,stopSelect)
      stat.printY=printY
      printY = printY + math.ceil(fontSize*#tlines*1.25)
      stat.maxY=printY
      self.maxTransY = height-printY-fontSize
    end--end stat for
    love.graphics.pop()
    love.graphics.setStencilTest()
    
    --Display the selected stat:
    local stat = self.stats[self.cursorY-1]
    if stat and stat.expand then
      love.graphics.setFont(fonts.menuFont)
      love.graphics.printf(stat.header or "Stat?",sidebarX,80+padding,width-sidebarX,"center")
      love.graphics.setFont(fonts.textFont)
      local function stencilFunc()
        love.graphics.rectangle("fill",sidebarX,80+padding*2,width-sidebarX,height-padding*2-98)
      end
      love.graphics.stencil(stencilFunc,"replace",1)
      love.graphics.setStencilTest("greater",0)
      if stat.id == "achievements" and count(achievementList) > 0 then
        if self.maxSideTransY < 0 then
          local scrollAmt = self.sideTransY / self.maxSideTransY
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt,true)
        end
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        local printY = 96+padding*(prefs['noImages'] and 6 or 3)
        local printX = sidebarX+64
        local gridX,gridY=1,1
        local maxGridX=nil
        local largestY=64
        local lastY=0
        local selectedAchievement=nil
        
        for id,achiev in pairs(achievementList) do
          local _, nlines = fonts.textFont:getWrap(achiev.name,128)
          local maxY = printY+#nlines*fontSize
          achiev.maxY = maxY
          local isMouse = (mouseX > printX-32 and mouseX < printX+96 and mouseY > printY-32+self.sideTransY and mouseY < maxY+self.sideTransY)
          local selected = (gridX == self.cursorX-1 and gridY == (self.achievementCursorY or 1)) or isMouse
          achiev.selected = selected
          if selected then
            if isMouse or selectedAchievement == nil then selectedAchievement = id end
            setColor(100,100,100,255)
            love.graphics.rectangle('fill',printX-8,printY-16,80,80)
            setColor(255,255,255,255)
          end
          achiev.gridX,achiev.gridY=gridX,gridY
          achiev.printY=printY
          achiev.printX=printX
          local has = achievements:has_achievement(id)
          local img = (has and (images['achievement' .. id] and images['achievement' .. id] or images['achievementunknown']) or (images['achievement' .. id .. 'locked'] and images['achievement' .. id .. 'locked'] or images['achievementunknownlocked']))
          if prefs['noImages'] then
            if not has then
              setColor(125,125,125,255)
              love.graphics.printf("( )",printX-32,printY,128,"center")
              love.graphics.printf(achiev.name,printX-32,printY+prefs['fontSize'],128,"center")
              setColor(255,255,255,255)
            else
              love.graphics.printf("(X)",printX-32,printY,128,"center")
              love.graphics.printf(achiev.name,printX-32,printY+prefs['fontSize'],128,"center")
            end
            local _,tlines = fonts.textFont:getWrap(achiev.name,128)
            lastY=printY+prefs['fontSize']+#tlines*fontSize
          else
            setColor(33,33,33,255)
            love.graphics.rectangle('fill',printX,printY-8,66,66)
            setColor(255,255,255,255)
            love.graphics.rectangle('line',printX-1,printY-9,66,66)
            love.graphics.draw(img,printX,printY-8)
            love.graphics.printf(achiev.name,printX-32,printY+64-8,128,"center")
            local _,tlines = fonts.textFont:getWrap(achiev.name,128)
            lastY=printY+64-8+#tlines*fontSize
          end
          printX = printX+128
          gridX = gridX+1
          largestY = math.max(largestY,(#nlines+1)*fontSize)
          if printX+128 > width then
            printX = sidebarX+64
            printY = printY + largestY+64
            maxGridX = gridX
            gridX = 1
            gridY = gridY+1
            largestY = 64
          end
        end --end achiev for
        if selectedAchievement then
          local achiev = achievementList[selectedAchievement]
          local _, tlines = fonts.descFont:getWrap(achiev.description,300)
          local boxHeight = #tlines*(prefs['descFontSize']+3)+math.ceil(prefs['descFontSize']/2)
          local x = math.min(width-332,achiev.printX)
          local y = math.min(height-boxHeight-32-self.sideTransY,achiev.printY)
          love.graphics.setFont(fonts.descFont)
          setColor(255,255,255,185)
          love.graphics.rectangle("line",x+22,y+20,302,boxHeight)
          setColor(0,0,0,185)
          love.graphics.rectangle("fill",x+23,y+21,301,boxHeight-1)
          setColor(255,255,255,255)
          love.graphics.printf(achiev.description,x+24,y+22,300)
          love.graphics.setFont(fonts.textFont)
        end
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
        self.maxSideTransY = height-lastY-128
        love.graphics.pop()
      elseif stat.id == "abilities" then
        if self.maxSideTransY < 0 then
          local scrollAmt = self.sideTransY / self.maxSideTransY
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt,true)
        end
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        local printY = 80+padding*3
        for _,abil in pairs(stat.stats) do
          love.graphics.print(abil.ability .. ": " .. abil.uses,sidebarX+padding,printY)
          printY = printY+fontSize
        end
        self.maxSideTransY = height-printY-fontSize*2
        love.graphics.pop()
      elseif stat.id == "creatures" then
        if self.maxSideTransY < 0 then
          if self.cursorX == 2 then
            setColor(50,50,50,255)
            love.graphics.rectangle("fill",width-padding*2,96+padding*2,padding,height-padding-96-padding*2)
            setColor(255,255,255,255)
          end
          local scrollAmt = self.sideTransY / self.maxSideTransY
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt,true)
        end
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        local printY = 80+padding*2+fontSize*4
        for _,creat in pairs(stat.stats) do
          if possibleMonsters[creat.creat] then --check to make sure this creature exists (it might not due to mods loaded)
            local name = ucfirst(possibleMonsters[creat.creat].name)
            love.graphics.printf(name,sidebarX,printY,width-sidebarX,"center")
            printY=printY+fontSize
            love.graphics.print("Turns: " .. creat.turns,sidebarX+padding*2,printY)
            if creat.ratio then
              printY = printY+fontSize
              love.graphics.print("Average turns: " .. creat.ratio,sidebarX+padding*2,printY)
            end
            if creat.kills then
              printY = printY+fontSize
              love.graphics.print("Kills as: " .. creat.kills,sidebarX+padding*2,printY)
            end
            if creat.killRatio then
              printY = printY+fontSize
              love.graphics.print("Average kills: " .. creat.killRatio,sidebarX+padding*2,printY)
            end
            local c = possibleMonsters[creat.creat]
            c.image_frame = 1
            c.baseType = "creature"
            if c.id == nil then c.id = creat.creat end
            output.display_entity(c,sidebarX+padding-8,printY-round(fontSize*(creat.creat == "ghost" and 0.5 or 3.5)),"force")
            printY = printY+fontSize*2
          end
        end
        self.maxSideTransY = height-printY-fontSize
        love.graphics.pop()
      elseif stat.id == "kills" then
        if self.maxSideTransY < 0 then
          if self.cursorX == 2 then
            setColor(50,50,50,255)
            love.graphics.rectangle("fill",width-padding*2,96+padding*2,padding,height-padding-96-padding*2)
            setColor(255,255,255,255)
          end
          local scrollAmt = self.sideTransY / self.maxSideTransY
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt,true)
        end
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        love.graphics.printf("Total Kills: " .. (totalstats.kills or 0),sidebarX,80+padding*2,width-sidebarX,"center")
        local printY = 80+padding*2+fontSize*2
        for _,creat in pairs(stat.stats) do
          love.graphics.print(ucfirst(possibleMonsters[creat.creat].name) .. ": " .. creat.kills,sidebarX+padding,printY)
          printY = printY+fontSize
        end
        self.maxSideTransY = height-printY-fontSize*2
        love.graphics.pop()
      elseif stat.id == "explosions" then
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        love.graphics.printf("Total Explosions: " .. totalstats.explosions,sidebarX,80+padding*2,width-sidebarX,"center")
        local printY = 80+padding*2+fontSize*2
        for _,creat in pairs(stat.stats) do
          love.graphics.print(ucfirst(possibleMonsters[creat.creat].name) .. "s Exploded: " .. creat.explosions,sidebarX+padding,printY)
          printY = printY+fontSize
        end
        self.maxSideTransY = height-printY
        love.graphics.pop()
      elseif stat.id == "leader_kills" then
        if self.maxSideTransY < 0 then
          if self.cursorX == 2 then
            setColor(50,50,50,255)
            love.graphics.rectangle("fill",width-padding*2,96+padding*2,padding,height-padding-96-padding*2)
            setColor(255,255,255,255)
          end
          local scrollAmt = self.sideTransY / self.maxSideTransY
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt,true)
        end
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        local printY = 80+padding*3
        for _,creat in pairs(stat.stats) do
          local name = ucfirst(possibleMonsters[creat.creat].name)
          love.graphics.printf(name,sidebarX,printY,width-sidebarX,"center")
          printY=printY+fontSize
          love.graphics.print("Total Followers: " .. creat.thralls,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Follower kills: " .. creat.kills,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Kills/Follower: " .. creat.killsPerFollower,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Possessions: " .. creat.possessions,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Followers/Possession: " .. creat.thrallsPerPossession,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Follower Kills/Possession: " .. creat.killsPerPossession,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Follower deaths: " .. creat.followerDeaths,sidebarX+padding*2,printY)
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
        if self.maxSideTransY < 0 then
          if self.cursorX == 2 then
            setColor(50,50,50,255)
            love.graphics.rectangle("fill",width-padding*2,96+padding*2,padding,height-padding-96-padding*2)
            setColor(255,255,255,255)
          end
          local scrollAmt = self.sideTransY / self.maxSideTransY
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt,true)
        end
        love.graphics.push()
        love.graphics.translate(0,self.sideTransY)
        local printY = 80+padding*3
        for _,creat in pairs(stat.stats) do
          local name = ucfirst(possibleMonsters[creat.creat].name)
          love.graphics.printf(name,sidebarX,printY,width-sidebarX,"center")
          printY=printY+fontSize
          love.graphics.print("Number Followed by: " .. creat.thralls,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Follower Kills: " .. creat.kills,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Average Kills: " .. creat.killsPer,sidebarX+padding*2,printY)
          printY = printY+fontSize
          love.graphics.print("Follower Deaths: " .. creat.deaths,sidebarX+padding*2,printY)
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
          self.sideScrollPositions = output:scrollbar(width-padding*2,96+padding*2,height-padding,scrollAmt,true)
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
          love.graphics.print("Average Turns to Beat: " .. stat.avgTurnsBeat,sidebarX+padding*2,printY)
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
    love.graphics.setFont(fonts.menuFont)
    love.graphics.printf("Wins",1,windowY+math.floor(padding/2),math.floor(width/2),"center")
    love.graphics.line(padding,windowY+padding*2,w1end-padding,windowY+padding*2)
    love.graphics.setFont(fonts.textFont)
    if self.maxTransY < 0 then
      local scrollAmt = self.transY / self.maxTransY
      self.scrollPositions = output:scrollbar(w1end-padding,96+padding*2,height-padding,scrollAmt,true)
    end
    love.graphics.push()
    local function stencilFunc()
      love.graphics.rectangle("fill",padding,windowY+padding*2,w1end,height-padding-(windowY+padding*2))
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,self.transY)
    local printY = windowY+padding*2
    for id,grave in ipairs(self.wins) do
      local dateWidth = fonts.textFont:getWidth(os.date("%H:%M, %b %d, %Y",grave.date))
      local _,tlines = fonts.textFont:getWrap(grave.properName .. ", " .. ucfirst(grave.name),w1end-padding-dateWidth)
      if self.cursorY-1 == id then
        setColor(100,100,100,255)
        love.graphics.rectangle("fill",padding,printY,w1end-padding*2,math.ceil(2+fontSize*#tlines*1.15))
        setColor(255,255,255,255)
      else
        local mouseX,mouseY = love.mouse.getPosition()
        if mouseY-self.transY > printY and mouseY-self.transY < printY+fontSize*#tlines*1.25 and mouseX > padding and mouseX < w1end-padding then
          setColor(66,66,66,255)
          love.graphics.rectangle("fill",padding,printY,w1end-padding*2,math.ceil(2+fontSize*#tlines*1.15))
          setColor(255,255,255,255)
        end
      end
      grave.printY = printY
      love.graphics.printf(grave.properName .. ", " .. ucfirst(grave.name),padding,printY,w1end-padding-dateWidth,"left")
      love.graphics.printf(os.date("%H:%M, %b %d, %Y",grave.date),w1end-padding*2-dateWidth,printY,dateWidth,"right")
      printY = math.ceil(printY+fontSize*#tlines*1.25)
      grave.maxY = printY
    end
    self.maxTransY = height-printY-fontSize-padding
    love.graphics.setStencilTest()
    love.graphics.pop()
    if self.wins[self.cursorY-1] then
      local win = self.wins[self.cursorY-1]
      local printY = windowY+math.floor(padding/2)
      love.graphics.setFont(fonts.menuFont)
      love.graphics.printf(win.properName .. "\n" .. ucfirst(win.name),w2start,printY,w2end-w2start,"center")
      local _,lines = fonts.menuFont:getWrap(win.properName .. "\n" .. ucfirst(win.name),w2end-w2start+padding)
      printY = printY+padding*#lines
      love.graphics.setFont(fonts.headerFont)
      love.graphics.printf(os.date("%H:%M, %b %d, %Y",win.date),w2start,printY,w2end-w2start,"center")
      printY = printY+padding
      if win.stats then
        love.graphics.setFont(fonts.textFont)
        local winText = "Turns played: " .. (win.stats.turns or 0)
        winText = winText .. "\nKills: " .. (win.stats.kills or 0)
        winText = winText .. "\nFavorite Ability: " .. (win.stats.favoriteAbility and win.stats.favoriteAbility .. " (" .. win.stats.favoriteAbilityTurns .. " uses)" or "Unknown")
        love.graphics.printf(winText,w2start+padding,printY,w2end-w2start-padding,"left")
      end
    end
  elseif self.screen == "losses" then
    local w1end,w2start,w2end = math.floor(width/2),math.ceil(width/2)+padding,math.ceil(width/2)+math.floor(width/2)-padding
    local windowY = 64+padding
    output:draw_window(0,windowY,w1end,height-padding)
    output:draw_window(w2start,windowY,w2end,height-padding)
    love.graphics.setFont(fonts.menuFont)
    love.graphics.printf("Losses",1,windowY+math.floor(padding/2),math.floor(width/2),"center")
    love.graphics.line(padding,windowY+padding*2,w1end-padding,windowY+padding*2)
    love.graphics.setFont(fonts.textFont)
    if self.maxTransY < 0 then
      local scrollAmt = self.transY / self.maxTransY
      self.scrollPositions = output:scrollbar(w1end-padding,96+padding*2,height-padding,scrollAmt,true)
    end
    love.graphics.push()
    local function stencilFunc()
      love.graphics.rectangle("fill",padding,windowY+padding*2,w1end,height-padding-(windowY+padding*2))
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,self.transY)
    local printY = windowY+padding*2
    for id,grave in ipairs(self.graveyard) do
      local dateWidth = fonts.textFont:getWidth(os.date("%H:%M, %b %d, %Y",grave.date))
      local _,tlines = fonts.textFont:getWrap(grave.properName .. ", " .. ucfirst(grave.name),w1end-padding-dateWidth)
      if self.cursorY-1 == id then
        setColor(100,100,100,255)
        love.graphics.rectangle("fill",padding,printY,w1end-padding*2,math.ceil(2+fontSize*#tlines*1.15))
        setColor(255,255,255,255)
      else
        if mouseY-self.transY > printY and mouseY-self.transY < printY+fontSize*(#tlines*1.25) and mouseX > padding and mouseX < w1end-padding then
          setColor(66,66,66,255)
          love.graphics.rectangle("fill",padding,printY,w1end-padding*2,math.ceil(2+fontSize*#tlines*1.15))
          setColor(255,255,255,255)
        end
      end
      grave.printY = printY
      love.graphics.printf(grave.properName .. ", " .. ucfirst(grave.name),padding,printY,w1end-padding*2-dateWidth,"left")
      love.graphics.printf(os.date("%H:%M, %b %d, %Y",grave.date),w1end-padding-dateWidth,printY,dateWidth,"right")
      printY = printY+math.ceil(fontSize*#tlines*1.25)
      grave.maxY = printY
    end
    self.maxTransY = height-printY-fontSize-padding
    love.graphics.setStencilTest()
    love.graphics.pop()
    if self.graveyard[self.cursorY-1] then
      local grave = self.graveyard[self.cursorY-1]
      local printY = windowY+math.floor(padding/2)
      love.graphics.setFont(fonts.menuFont)
      love.graphics.printf(grave.saying,w2start,printY,w2end-w2start,"center")
      printY = printY+padding
      love.graphics.printf(grave.properName .. "\n" .. ucfirst(grave.name),w2start,printY,w2end-w2start,"center")
      local _,lines = fonts.menuFont:getWrap(grave.properName .. "\n" .. ucfirst(grave.name),w2end-w2start+padding)
      printY = printY+padding*#lines
      love.graphics.setFont(fonts.headerFont)
      love.graphics.printf("Killed by " .. grave.killer,w2start,printY,w2end-w2start,"center")
      _,lines = fonts.menuFont:getWrap("Killed by " .. grave.killer,w2end-w2start+padding)
      printY = printY+math.floor(padding/3)*2*#lines
      love.graphics.printf("at " .. os.date("%H:%M, %b %d, %Y",grave.date),w2start,printY,w2end-w2start,"center")
      _,lines = fonts.menuFont:getWrap("at " .. os.date("%H:%M, %b %d, %Y",grave.date),w2end-w2start+padding)
      printY = printY+math.floor(padding/3)*2*#lines
      love.graphics.printf((grave.mapname and grave.mapname or ""),w2start,printY,w2end-w2start,"center")
      printY = printY+padding
      if grave.stats then
        love.graphics.setFont(fonts.textFont)
        local graveText = "Turns played: " .. (grave.stats.turns or 0)
        graveText = graveText .. "\nKills: " .. (grave.stats.kills or 0)
        graveText = graveText .. "\nFavorite Ability: " .. (grave.stats.favoriteAbility and grave.stats.favoriteAbility .. " (" .. grave.stats.favoriteAbilityTurns .. " uses)" or "Unknown")
        love.graphics.printf(graveText,w2start+padding,printY,w2end-w2start-padding,"left")
      end
    end
  end
  love.graphics.pop()
end

function gamestats:buttonpressed(key,scancode,isRepeat,controllerType)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if key == "escape" then
    self:switchBack()
  elseif key == "north" then
    if self.screen == "stats" and self.cursorX > 1 and self.cursorY ~= 1 then
      if self.stats[self.cursorY-1] and self.stats[self.cursorY-1].id == "achievements" then
        self.achievementCursorY = math.max(self.achievementCursorY and self.achievementCursorY-1 or 1,1)
        for _,achiev in pairs(achievementList) do
          if achiev.gridX==self.cursorX-1 and achiev.gridY==self.achievementCursorY then
            while achiev.printY-32+self.sideTransY < 96 do self:sidebarScrollUp() end
            break
          end
        end
      else
        self:sidebarScrollUp()
      end
    else
      self.cursorY = math.max(self.cursorY-1,1)
      local which = (self.screen == "losses" and "graveyard" or self.screen)
      while self[which][self.cursorY].printY+self.transY <= 96+prefs['fontSize'] do
        self:scrollUp()
      end
    end
  elseif key == "south" then
    local maxY = (self.screen == "losses" and #self.graveyard+1) or (self.screen == "stats" and #self.stats+1) or (self.screen == "wins" and #self.wins+1)
    if self.screen == "stats" and self.cursorX > 1 and self.cursorY ~= 1 then
      if self.stats[self.cursorY-1] and self.stats[self.cursorY-1].id == "achievements" then
        self.achievementCursorY = (self.achievementCursorY and self.achievementCursorY+1 or 2)
        for _,achiev in pairs(achievementList) do
          if achiev.gridX==self.cursorX-1 and achiev.gridY==self.achievementCursorY then
            while achiev.maxY+self.sideTransY > love.graphics:getHeight() do self:sidebarScrollDown() end
            break
          end
        end
      else
        self:sidebarScrollDown()
      end
    elseif self.screen == "stats" and not self.stats[self.cursorY].expand then
      self:scrollDown()
    else
      if self.screen ~= "stats" or self.stats[self.cursorY].expand then
        self.cursorY = math.min(self.cursorY+1,(maxY or 1))
        if self.screen ~= "stats" then
          local which = (self.screen == "losses" and "graveyard" or self.screen)
          if self[which][self.cursorY] and (self[which][self.cursorY-1].maxY > love.graphics.getHeight()-32-self.transY) then
            self:scrollDown()
          end
        elseif self.screen == "stats" then
          self.cursorX = 1
          self.sideTransY = 0
        end
      end
    end
  elseif key == "west" then
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
  elseif key == "east" then
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
  elseif key == "enter" or key == "wait" then
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
  if self.maxTransY < 0 then self.transY = math.max(self.transY-prefs['fontSize']*5,self.maxTransY) end
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
  local uiScale = prefs['uiScale'] or 1
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
    return
  end
  
  --Handle scrolling:
  local x,y = love.mouse.getPosition()
  x,y = math.floor(x/uiScale),math.floor(y/uiScale)
  if (love.mouse.isDown(1)) and self.sideScrollPositions then
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
  local uiScale = prefs['uiScale'] or 1
  x,y = math.floor(x/uiScale),math.floor(y/uiScale)
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    self:switchBack()
  elseif x > self.statsbutton.minX and x < self.statsbutton.maxX and y > self.statsbutton.minY and y < self.statsbutton.maxY then
    self.screen = "stats"
    self.transY = 0
    self.cursorY = 1
    self.cursorX = 1
    return
  elseif x > self.winsbutton.minX and x < self.winsbutton.maxX and y > self.winsbutton.minY and y < self.winsbutton.maxY then
    self.screen = "wins"
    self.transY = 0
    self.cursorY = 1
    self.cursorX = 2
    return
  elseif x > self.lossesbutton.minX and x < self.lossesbutton.maxX and y > self.lossesbutton.minY and y < self.lossesbutton.maxY then
    self.screen = "losses"
    self.transY = 0
    self.cursorY = 1
    self.cursorX = 3
    return
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
    if x > padding and x < sidebarX-padding-(self.screen == "stats" and 0 or padding) and y-self.transY > item.printY and y-self.transY < item.maxY and (item.expand or self.screen ~= "stats") then
      self.cursorY = id+1
      self.cursorX = 1
      self.sideTransY = 0
      self.achievementCursorY=0
    end
  end
end