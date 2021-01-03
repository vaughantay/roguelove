newgame = {whiteAlpha=0,cheats = {}}

function newgame:enter(previous)
  self.lineCountdown = 0.5
  self.lineOn = true
  self.blackAmt=nil
  if previous ~= cheats then
    --Clear all game variables, so there's not any bleed from the previous game
    player = nil
    currGame = nil
    currWorld = nil
    currMap = nil
    if not self.seed or previous == menu then self.seed = random(999999,2147483647) end
    if not totalstats or not totalstats.games or totalstats.games == 0 then
      self.tutorial = true
    end
    self.cursorY = 1
    self.cursorX = 1
    self.descScrollY = 0
    self.classScrollY = 0
    self.player = {name=nil,species=nil,class=nil,gender="other",pronouns=nil}
  end
  self:refresh_class_list()
  self.species = {}
  for id,creature in pairs(possibleMonsters) do
    if creature.playerSpecies then
      self.species[#self.species+1] = {creatureID=id,name=ucfirst(creature.name)}
    end
  end
  sort_table(self.species,"name")
end

function newgame:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local mouseX,mouseY = love.mouse.getPosition()
  love.graphics.setFont(fonts.mapFont)
  love.graphics.push()
  love.graphics.translate(0,math.floor(-((self.blackAmt and self.blackAmt/255 or 0/255))*height/2))

  -- Define some coordinates:
  local nameBoxX=math.floor(width/2)-256+48-(prefs['noImages'] and 32 or 0)
  local nameBoxY = 32
  local nameBoxWidth = 512-128+(prefs['noImages'] and 96 or 0)
  local selectBoxX = math.floor(width/3)+85
  local selectBoxWidth = math.floor(width/3)-170
  local pronounY = nameBoxY+32
  local screen = self:getScreen()
  local fontSize = 24
  
  --Species and class print:
  if screen == "species" or screen == "classes" then
    setColor(255,255,255,255)
    love.graphics.setFont(fonts.graveFontSmall)
    local fontSize = 24
    local classBoxX = nameBoxX
    local classBoxY = 48
    local classBoxW = nameBoxWidth
    local totalH = height-classBoxY-48
    local classBoxH = math.min((screen == "species" and count(self.species) or count(self.classes))*fontSize,math.floor(totalH/4))
    self.maxClassLines = math.floor(classBoxH/fontSize)
    local descBoxY = classBoxY+classBoxH
    local descBoxH = totalH-classBoxH
    local maxDescLines = math.floor(descBoxH/prefs['fontSize'])
    love.graphics.printf("Select a " .. (screen =="species" and "Species" or "Class"),classBoxX,classBoxY-32,classBoxW,"center")
    love.graphics.rectangle("line",classBoxX,classBoxY,classBoxW,classBoxH)
    love.graphics.rectangle("line",classBoxX,descBoxY,classBoxW,descBoxH)
  
    --***Screen 1 - Species:
    if not self.player.species and not gamesettings.noSpecies then
      local printY = classBoxY
      local whichSpecies = self.species[self.cursorY].creatureID

      love.graphics.push()
      --Create a "stencil" that stops stuff from being drawn outside borders
      local function stencilFunc()
        love.graphics.rectangle("fill",classBoxX,classBoxY,classBoxW,classBoxH)
      end
      love.graphics.stencil(stencilFunc,"replace",1)
      love.graphics.setStencilTest("greater",0)
      love.graphics.translate(0,-self.classScrollY*fontSize)
      --Loop through all species and display their names:
      for i,s in ipairs(self.species) do
        local id = s.creatureID
        local creature = possibleMonsters[id]
        local moused = (mouseY >= printY-self.classScrollY*fontSize and mouseY <= printY+fontSize-self.classScrollY*fontSize and mouseX >= classBoxX and mouseX <= classBoxX+classBoxW-(#self.species > self.maxClassLines and 32 or 0))
        if self.player.species == id then
          setColor(100,100,100,255)
          love.graphics.rectangle('fill',classBoxX,printY,classBoxW,fontSize)
        elseif self.cursorY == i or moused then
          if moused or (mouseY < classBoxY or mouseY > classBoxY+classBoxH or mouseX < classBoxX or mouseX > classBoxX+classBoxW) then
            setColor(50,50,50,255)
            whichSpecies = id
          else
            setColor(33,33,33,255)
          end
          love.graphics.rectangle('fill',classBoxX,printY,classBoxW-(#self.species > self.maxClassLines and 32 or 0),fontSize)
        end
        setColor(255,255,255,255)
        love.graphics.print(s.name,classBoxX+2,printY)
        self.species[i] = {creatureID=id,name=s.name,minX=classBoxX,maxX=classBoxX+classBoxW-(#self.species > self.maxClassLines and 32 or 0),minY=printY,maxY=printY+fontSize}
        printY = printY+fontSize
      end
      love.graphics.setStencilTest()
      love.graphics.pop()
      if #self.species > self.maxClassLines then
        local oldMax = self.maxClassScroll
        self.maxClassScroll = #self.species-self.maxClassLines
        if oldMax ~= self.maxClassScroll then self.classScrollY=0 end
        local scrollAmt = (self.classScrollY)/self.maxClassScroll
        self.classScrollPositions = output:scrollbar(classBoxX+classBoxW-32,classBoxY,classBoxY+classBoxH,scrollAmt,true)
      end
      --Display selected species:
      whichSpecies = whichSpecies or self.player.species
      if whichSpecies then
        local creature = possibleMonsters[whichSpecies]
        
        local desc = ""
        desc = desc .. "Base HP: " .. creature.max_hp .. "\n"
        desc = desc .. "Base MP: " .. (creature.max_mp or 0).. "\n"
        desc = desc .. "Strength: " .. (creature.strength or 0) .. "\n"
        desc = desc .. "Melee Skill: " .. (creature.melee or 0) .. "\n"
        desc = desc .. "Ranged Skill: " .. (creature.ranged or 0) .. "\n"
        desc = desc .. "Magic Skill: " .. (creature.magic or 0) .. "\n"
        desc = desc .. "Dodging Skill: " .. (creature.dodging or 0) .. "\n"
        desc = desc .. "Sight Radius: " .. creature.perception .. "\n"
        if creature.stealth then desc = desc .. "Stealth Modifier: " .. creature.stealth .. "\n" end
        if creature.armor then desc = desc .. "Damage Absorbtion: " .. creature.armor .. "\n" end
        if creature.weaknesses and count(creature.weaknesses) > 0 then
          desc = desc .. "Weaknesses - "
          local i = 1
          for stat,amt in pairs(creature.weaknesses) do
            if i ~= 1 then desc = desc .. ", "  end
            desc = desc .. ucfirst(stat) .. ": " .. amt .. "%"
            i = i + 1
          end
          desc = desc .. "\n"
        end
        if creature.resistances and count(creature.resistances) > 0 then
          desc = desc .. "Resistances - "
          local i = 1
          for stat,amt in pairs(creature.resistances) do
            if i ~= 1 then desc = desc .. ", "  end
            desc = desc .. ucfirst(stat) .. ": " .. amt .. "%"
            i = i + 1
          end
          desc = desc .. "\n"
        end
        if creature.spells and #creature.spells > 0 then
          desc = desc .. "Abilities - "
          for i,spell in ipairs(creature.spells) do
            if i ~= 1 then desc = desc .. ", " end
            desc = desc .. possibleSpells[spell].name
          end
          desc = desc .. "\n"
        end
        if (creature.items and #creature.items > 0) or (creature.equipment and #creature.equipment > 0) then
          desc = desc .. "Items - "
          local hasItems = false
          if (creature.items and #creature.items > 0) then
            for i,item in ipairs(creature.items) do
              if i ~= 1 then desc = desc .. ", " end
              local amount = item.amount or 1
              desc = desc .. (amount > 1 and amount .. " " or "") .. ucfirst(item.displayName or (amount > 1 and possibleItems[item.item].pluralName or possibleItems[item.item].name))
              hasItems = true
            end
          end
          if (creature.equipment and #creature.equipment > 0) then
            for i,item in ipairs(creature.equipment) do
              if i ~= 1 or hasItems then desc = desc .. ", " end
              desc = desc .. ucfirst(item.displayName or possibleItems[item.item].name)
            end
          end
          desc = desc .. "\n"
        end
        if creature.factions and #creature.factions > 0 then
          desc = desc .. "Faction Membership - "
          for i,fac in ipairs(creature.factions) do
            if i ~= 1 then desc = desc .. ", " end
            desc = desc .. possibleFactions[fac].name
          end
          desc = desc .. "\n"
        end
        if creature.money then
          desc = desc .. "Money: $" .. creature.money .. "\n"
        end
        if creature.favor and count(creature.favor) > 0 then
          desc = desc .. "Favor - "
          local i = 1
          for id,fav in pairs(creature.favor) do
            if i ~= 1 then desc = desc .. ", "  end
            desc = desc .. possibleFactions[id].name .. ": " .. fav
            i = i + 1
          end
          desc = desc .. "\n"
        end
        
        love.graphics.setFont(fonts.textFont)
        local _, tlines = fonts.textFont:getWrap(creature.name .. "\n" .. creature.description,classBoxW)
        local _,dlines = fonts.textFont:getWrap(desc,classBoxW)
        local descYpad = (#tlines+2)*prefs['fontSize']
        local finalTextHeight = descYpad+(#dlines+2)*prefs['fontSize']
        local finalY = descBoxY+finalTextHeight
        local totalLines = #tlines+#dlines+4
        if totalLines > maxDescLines then
          _, tlines = fonts.textFont:getWrap(creature.name .. "\n" .. creature.description,classBoxW-96)
          _,dlines = fonts.textFont:getWrap(desc,classBoxW-32)
          descYpad = (#tlines+2)*prefs['fontSize']
          finalTextHeight = descYpad+(#dlines+2)*prefs['fontSize']
          finalY = descBoxY+finalTextHeight
          local totalLines = #tlines+#dlines+4
          love.graphics.push()
          --Create a "stencil" that stops stuff from being drawn outside borders
          local function stencilFunc()
            love.graphics.rectangle("fill",classBoxX,classBoxY+classBoxH,classBoxW,descBoxH)
          end
          love.graphics.stencil(stencilFunc,"replace",1)
          love.graphics.setStencilTest("greater",0)
          love.graphics.translate(0,-self.descScrollY*prefs['fontSize'])
          love.graphics.printf(ucfirst(creature.name) .. "\n" .. creature.description,classBoxX+32,classBoxY+classBoxH,classBoxW-64,"center")
          love.graphics.printf(desc,classBoxX+2,classBoxY+classBoxH+descYpad,classBoxW-32,"left")
          love.graphics.setStencilTest()
          love.graphics.pop()
          local oldMax = self.maxDescScroll
          self.maxDescScroll = totalLines-maxDescLines
          if oldMax ~= self.maxDescScroll then self.descScrollY=0 end
          local scrollAmt = (self.descScrollY)/self.maxDescScroll
          self.descScrollPositions = output:scrollbar(classBoxX+classBoxW-32,classBoxY+classBoxH,classBoxY+classBoxH+descBoxH,scrollAmt,true)
        else
          love.graphics.printf(ucfirst(creature.name) .. "\n" .. creature.description,classBoxX,classBoxY+classBoxH,classBoxW,"center")
          love.graphics.printf(desc,classBoxX+2,classBoxY+classBoxH+descYpad,classBoxW,"left")
          self.descScrollPositions = nil
          self.maxDescScroll=0
          self.descScrollY=0
        end
        love.graphics.setFont(fonts.graveFontSmall)
      end
    end
    
    --***Screen 2 - Classes:
    if screen == "classes" then
      local printY = classBoxY
      local whichClass = self.classes[self.cursorY].classID
      
      love.graphics.push()
      --Create a "stencil" that stops stuff from being drawn outside borders
      local function stencilFunc()
        love.graphics.rectangle("fill",classBoxX,classBoxY,classBoxW,classBoxH)
      end
      love.graphics.stencil(stencilFunc,"replace",1)
      love.graphics.setStencilTest("greater",0)
      love.graphics.translate(0,-self.classScrollY*fontSize)
      for i,c in ipairs(self.classes) do
        local id = c.classID
        local class = playerClasses[id]
        local moused = (mouseY >= printY-self.classScrollY*fontSize and mouseY <= printY+fontSize-self.classScrollY*fontSize and mouseX >= classBoxX and mouseX <= classBoxX+classBoxW-(#self.classes > self.maxClassLines and 32 or 0))
        if self.player.class == id then
          setColor(100,100,100,255)
          love.graphics.rectangle('fill',classBoxX,printY,classBoxW,fontSize)
        elseif self.cursorY == i or moused then
          if moused or (mouseY < classBoxY or mouseY > classBoxY+classBoxH or mouseX < classBoxX or mouseX > classBoxX+classBoxW-(#self.classes > self.maxClassLines and 32 or 0)) then
            setColor(50,50,50,255)
            whichClass = id
          else
            setColor(33,33,33,255)
          end
          love.graphics.rectangle('fill',classBoxX,printY,classBoxW-(#self.classes > self.maxClassLines and 32 or 0),fontSize)
        end
        setColor(255,255,255,255)
        love.graphics.print(class.name,classBoxX+2,printY)
        self.classes[i] = {classID=id,minX=classBoxX,maxX=classBoxX+classBoxW-(#self.classes > self.maxClassLines and 32 or 0),minY=printY,maxY=printY+fontSize}
        printY = printY+fontSize
      end
      whichClass = whichClass or self.player.class
      if whichClass then
        local class = playerClasses[whichClass]
        
        local desc = ""
        if class.factions and #class.factions > 0 then
          desc = desc .. "Faction Membership - "
          for i,fac in ipairs(class.factions) do
            if i ~= 1 then desc = desc .. ", " end
            desc = desc .. possibleFactions[fac].name
          end
          desc = desc .. "\n"
        end
        if class.spells and #class.spells > 0 then
          desc = desc .. "Abilities - "
          for i,spell in ipairs(class.spells) do
            if i ~= 1 then desc = desc .. ", " end
            desc = desc .. possibleSpells[spell].name
          end
          desc = desc .. "\n"
        end
        if (class.items and #class.items > 0) or (class.equipment and #class.equipment > 0) then
          desc = desc .. "Items - "
          local hasItems = false
          if (class.items and #class.items > 0) then
            for i,item in ipairs(class.items) do
              if i ~= 1 then desc = desc .. ", " end
              local amount = item.amount or 1
              desc = desc .. (amount > 1 and amount .. " " or "") .. ucfirst(item.displayName or (amount > 1 and possibleItems[item.item].pluralName or possibleItems[item.item].name))
              hasItems = true
            end
          end
          if (class.equipment and #class.equipment > 0) then
            for i,item in ipairs(class.equipment) do
              if i ~= 1 or hasItems then desc = desc .. ", " end
              desc = desc .. ucfirst(item.displayName or possibleItems[item.item].name)
            end
          end
          desc = desc .. "\n"
        end
        if class.money then
          desc = desc .. "Money: $" .. class.money .. "\n"
        end
        if class.favor and count(class.favor) > 0 then
          desc = desc .. "Favor - "
          local i = 1
          for id,fav in pairs(class.favor) do
            if i ~= 1 then desc = desc .. ", "  end
            desc = desc .. possibleFactions[id].name .. ": " .. fav
            i = i + 1
          end
          desc = desc .. "\n"
        end
        if class.stat_modifiers and count(class.stat_modifiers) > 0  then
          desc = desc .. "Stat Modifiers - "
          local i = 1
          for stat,amt in pairs(class.stat_modifiers) do
            if i ~= 1 then desc = desc .. ", "  end
            desc = desc .. ucfirst(stat) .. (amt > 0 and " +" or " ") .. amt
            i = i + 1
          end
          desc = desc .. "\n"
        end
        if class.weaknesses and count(class.weaknesses) > 0 then
          desc = desc .. "Weaknesses - "
          local i = 1
          for stat,amt in pairs(class.weaknesses) do
            if i ~= 1 then desc = desc .. ", "  end
            desc = desc .. ucfirst(stat) .. ": " .. amt .. "%"
            i = i + 1
          end
          desc = desc .. "\n"
        end
        if class.resistances and count(class.resistances) > 0 then
          desc = desc .. "Resistances - "
          local i = 1
          for stat,amt in pairs(class.resistances) do
            if i ~= 1 then desc = desc .. ", "  end
            desc = desc .. ucfirst(stat) .. ": " .. amt .. "%"
            i = i + 1
          end
          desc = desc .. "\n"
        end
        love.graphics.setStencilTest()
        love.graphics.pop()
        if #self.classes > self.maxClassLines then
          local oldMax = self.maxClassScroll
          self.maxClassScroll = #self.classes-self.maxClassLines
          if oldMax ~= self.maxClassScroll then self.classScrollY=0 end
          local scrollAmt = (self.classScrollY)/self.maxClassScroll
          self.classScrollPositions = output:scrollbar(classBoxX+classBoxW-32,classBoxY,classBoxY+classBoxH,scrollAmt,true)
        end
        
        --Display selected class:
        love.graphics.setFont(fonts.textFont)
        local _, tlines = fonts.textFont:getWrap(class.name .. "\n" .. class.description,classBoxW)
        local _,dlines = fonts.textFont:getWrap(desc,classBoxW)
        local descYpad = (#tlines+2)*prefs['fontSize']
        local finalTextHeight = descYpad+(#dlines+2)*prefs['fontSize']
        local finalY = descBoxY+finalTextHeight
        local totalLines = #tlines+#dlines+4
        if totalLines > maxDescLines then
          _, tlines = fonts.textFont:getWrap(class.name .. "\n" .. class.description,classBoxW-96)
          _,dlines = fonts.textFont:getWrap(desc,classBoxW-32)
          descYpad = (#tlines+2)*prefs['fontSize']
          finalTextHeight = descYpad+(#dlines+2)*prefs['fontSize']
          finalY = descBoxY+finalTextHeight
          local totalLines = #tlines+#dlines+4
          love.graphics.push()
          --Create a "stencil" that stops stuff from being drawn outside borders
          local function stencilFunc()
            love.graphics.rectangle("fill",classBoxX,classBoxY+classBoxH,classBoxW,descBoxH)
          end
          love.graphics.stencil(stencilFunc,"replace",1)
          love.graphics.setStencilTest("greater",0)
          love.graphics.translate(0,-self.descScrollY*prefs['fontSize'])
          love.graphics.printf(ucfirst(class.name) .. "\n" .. class.description,classBoxX+32,classBoxY+classBoxH,classBoxW-64,"center")
          love.graphics.printf(desc,classBoxX+2,classBoxY+classBoxH+descYpad,classBoxW-32,"left")
          love.graphics.setStencilTest()
          love.graphics.pop()
          local oldMax = self.maxDescScroll
          self.maxDescScroll = totalLines-maxDescLines
          if oldMax ~= self.maxDescScroll then self.descScrollY=0 end
          local scrollAmt = (self.descScrollY)/self.maxDescScroll
          self.descScrollPositions = output:scrollbar(classBoxX+classBoxW-32,classBoxY+classBoxH,classBoxY+classBoxH+descBoxH,scrollAmt,true)
        else
          love.graphics.printf(ucfirst(class.name) .. "\n" .. class.description,classBoxX,classBoxY+classBoxH,classBoxW,"center")
          love.graphics.printf(desc,classBoxX+2,classBoxY+classBoxH+descYpad,classBoxW,"left")
          self.descScrollPositions = nil
          self.maxDescScroll=0
          self.descScrollY=0
        end
        love.graphics.setFont(fonts.graveFontSmall)
      end
    end
  end
  
  --***Screen 3: Name/pronouns/seed
  --1: Name
  --2: Pronouns
  --3: Tutorial
  --4: Begin
  --5: Seed
  --6: Copy/Paste buttons
  --7: Game Modifiers
  if screen == "name" then
    --Delete scroll info from previous screens:
    self.classScrollPositions = nil
    self.maxClassScroll = 0
    self.classScrollY=0
    self.descScrollPositions = nil
    self.maxDescScroll=0
    self.descScrollY=0
    setColor(255,255,255,255)
    love.graphics.setFont(fonts.graveFontSmall)
    local w = fonts.graveFontSmall:getWidth("Name: ")
    love.graphics.print("Name: ",nameBoxX-w,nameBoxY)
    if self.cursorY == 1 and self.cursorX == 1 then
      setColor(50,50,50,255)
      love.graphics.rectangle('fill',nameBoxX,nameBoxY,nameBoxWidth,24)
      setColor(255,255,255,255)
      love.graphics.printf(self.player.name,nameBoxX,nameBoxY,nameBoxWidth,"center")
      if self.lineOn then
        local w = fonts.graveFontSmall:getWidth(self.player.name)
        local lineX = nameBoxX+math.ceil(nameBoxWidth/2+w/2)
        love.graphics.line(lineX,nameBoxY+4,lineX,nameBoxY+21)
      end
    elseif mouseY > 32 and mouseY < 56 and self.randomNameButton and (mouseY < self.randomNameButton.minY or mouseY > self.randomNameButton.maxY or mouseX < self.randomNameButton.minX or mouseX > self.randomNameButton.maxX) then
      setColor(33,33,33,255)
      love.graphics.rectangle('fill',nameBoxX,nameBoxY,nameBoxWidth,24)
      setColor(255,255,255,255)
      love.graphics.printf(self.player.name,nameBoxX,nameBoxY,nameBoxWidth,"center")
    else
      love.graphics.printf(self.player.name,nameBoxX,nameBoxY,nameBoxWidth,"center")
    end
    love.graphics.rectangle('line',nameBoxX,nameBoxY,nameBoxWidth,24)
    
    --Randomize button:
    --function output:button(x,y,width,small,special,text,useScaling)
    self.randomNameButton = output:button(nameBoxX+nameBoxWidth+16,nameBoxY,100,nil,(self.cursorY == 1 and self.cursorX == 2 and "hover" or nil),"Randomize")
    
    --Draw Pronouns:
    love.graphics.setFont(fonts.graveFontSmall)
    local w = fonts.graveFontSmall:getWidth("Pronouns: ")
    love.graphics.print("Pronouns: ",nameBoxX-w,pronounY)
    self.pronouns = {}
    local custom = self.player.pronouns and {n=self.player.pronouns.n,o=self.player.pronouns.o,p=self.player.pronouns.p} or {n="NA",o="NA",p="NA"}
    local pnounlist = {male={n="he",o="him",p="his"},female={n="she",o="her",p="her"},neuter={n="it",o="it",p="its"},other={n="they",o="them",p="their"},custom=custom}
    if self.cursorY == 2 or (mouseY > pronounY and mouseY < pronounY+24) then
      local genderX = 1
      local printX = nameBoxX
      local pnouns = ucfirst(pnounlist[self.player.gender].n) .. "/" .. ucfirst(pnounlist[self.player.gender].o) .. "/" .. ucfirst(pnounlist[self.player.gender].p)
      w = fonts.graveFontSmall:getWidth(pnouns)
      if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w) then
        setColor(50,50,50,255)
        love.graphics.rectangle("fill",printX,pronounY,w,24)
        setColor(255,255,255,255)
      end
      love.graphics.print(pnouns,printX,pronounY)
      self.pronouns[1] = {gender=self.player.gender,minX = printX,maxX = printX+w,minY=pronounY,maxY=pronounY+24}
      printX=printX+w+12
      if self.player.gender ~= "male" then
        genderX = genderX+1
        pnouns = "He"
        w = fonts.graveFontSmall:getWidth(pnouns)
        if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w+12) then
          setColor(50,50,50,255)
          love.graphics.rectangle("fill",printX,pronounY,w,24)
          setColor(255,255,255,255)
        end
        love.graphics.print(pnouns,printX,pronounY)
        self.pronouns[#self.pronouns+1] = {gender="male",minX = printX,maxX = printX+w+12,minY=pronounY,maxY=pronounY+24}
        printX = printX+w+12
      end
      if self.player.gender ~= "female" then
        genderX = genderX+1
        pnouns = "She"
        w = fonts.graveFontSmall:getWidth(pnouns)
        if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w+12) then
          setColor(50,50,50,255)
          love.graphics.rectangle("fill",printX,pronounY,w,24)
          setColor(255,255,255,255)
        end
        love.graphics.print(pnouns,printX,pronounY)
        self.pronouns[#self.pronouns+1] = {gender="female",minX = printX,maxX = printX+w+12,minY=pronounY,maxY=pronounY+24}
        printX = printX+w+12
      end
      if self.player.gender ~= "neuter" then
        genderX = genderX+1
        pnouns = "It"
        w = fonts.graveFontSmall:getWidth(pnouns)
        if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w+12) then
          setColor(50,50,50,255)
          love.graphics.rectangle("fill",printX,pronounY,w,24)
          setColor(255,255,255,255)
        end
        love.graphics.print(pnouns,printX,pronounY)
        self.pronouns[#self.pronouns+1] = {gender="neuter",minX = printX,maxX = printX+w+12,minY=pronounY,maxY=pronounY+24}
        printX = printX+w+12
      end
      if self.player.gender ~= "other" then 
        genderX = genderX+1
        pnouns = "They"
        w = fonts.graveFontSmall:getWidth(pnouns)
        if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w+12) then
          setColor(50,50,50,255)
          love.graphics.rectangle("fill",printX,pronounY,w,24)
          setColor(255,255,255,255)
        end
        love.graphics.print(pnouns,printX,pronounY)
        self.pronouns[#self.pronouns+1] = {gender="other",minX = printX,maxX = printX+printX+w+12,minY=pronounY,maxY=pronounY+24}
        printX = printX+w+12
      end
      if self.player.gender ~= "custom" then
        genderX = genderX+1
        pnouns = "Custom"
        w = fonts.graveFontSmall:getWidth(pnouns)
        if (self.cursorX == genderX and (mouseY < pronounY or mouseY > pronounY+24)) or (mouseY > pronounY and mouseY < pronounY+24 and mouseX > printX and mouseX < printX+w+12) then
          setColor(50,50,50,255)
          love.graphics.rectangle("fill",printX,pronounY,w,24)
          setColor(255,255,255,255)
        end
        love.graphics.print(pnouns,printX,pronounY)
        self.pronouns[#self.pronouns+1] = {gender="custom",minX = printX,maxX = printX+printX+w+12,minY=pronounY,maxY=pronounY+24}
        printX = printX+w+12
      end
    else
      local pnouns = ucfirst(pnounlist[self.player.gender].n) .. "/" .. ucfirst(pnounlist[self.player.gender].o) .. "/" .. ucfirst(pnounlist[self.player.gender].p)
      w = fonts.graveFontSmall:getWidth(pnouns)
      self.pronouns[1] = {gender=self.player.gender,minX = nameBoxX,maxX = nameBoxX+w,minY=pronounY,maxY=pronounY+24}
      love.graphics.print(pnouns,nameBoxX,pronounY)
    end
    --Tutorial Checkbox:
    local printY = 100
    local padding = (prefs['noImages'] and 16 or 32)
    love.graphics.setFont(fonts.graveFontSmall)
    local textWidth = fonts.graveFontSmall:getWidth("Tutorial Messages?")
    if self.cursorY == 3 then
      setColor(100,100,100,255)
      love.graphics.rectangle('fill',nameBoxX,printY,nameBoxWidth,24)
      setColor(255,255,255,255)
    elseif (mouseY > printY and mouseY < printY+24 and mouseX > nameBoxX and mouseX < nameBoxX+nameBoxWidth) then
      setColor(50,50,50,255)
      love.graphics.rectangle('fill',nameBoxX,printY,nameBoxWidth,24)
      setColor(255,255,255,255)
    end
    if prefs['noImages'] then
      love.graphics.print((self.tutorial and "(Y)" or "(N)"),math.floor(width/2-textWidth/2-padding*2),printY)
    else
      love.graphics.draw((self.tutorial and images.uicheckboxchecked or images.uicheckbox),math.floor(width/2-textWidth/2-padding/2),math.floor(printY+padding/8))
    end
    love.graphics.print("Tutorial Messages?",math.floor(width/2-textWidth/2+padding/2),printY)
    self.tutorialBox = {minX=nameBoxX, maxX=nameBoxX+nameBoxWidth, minY=printY, maxY=printY+24}
    printY = printY+padding
    
    --Begin Button:
    if self.player.class then
      self.beginButton = output:button(math.floor(width/2-75),printY,150,false,(self.cursorY == 4 and "hover" or nil))
      love.graphics.printf("BEGIN",math.floor(width/4),printY,width/2,"center")
    else
      love.graphics.printf("Select a Class to Begin",math.floor(width/4),printY,width/2,"center")
    end
    printY = printY+64
    
    --Seed info:
    local seedWidth = fonts.textFont:getWidth("Seed: 100000000000")
    local seedX = math.ceil(width/2-seedWidth/2)
    if self.cursorY == 5 then
      setColor(50,50,50,255)
      love.graphics.rectangle('fill',seedX,printY,seedWidth,prefs['fontSize']+2)
      local w = fonts.textFont:getWidth("Seed: " .. (self.seed or ""))
      if self.lineOn then
        local lineX = seedX+math.ceil(seedWidth/2+w/2)
        setColor(255,255,255,255)
        love.graphics.line(lineX,printY+2,lineX,printY+prefs['fontSize'])
      end
      setColor(255,255,255,255)
    elseif mouseY >= printY and mouseY <=printY+prefs['fontSize']+2 and mouseX >= seedX and mouseX <= seedX+seedWidth then
      setColor(33,33,33,255)
      love.graphics.rectangle('fill',seedX,printY,seedWidth,prefs['fontSize']+2)
    end
    setColor(255,255,255,255)
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf("Seed: " .. (self.seed or ""),seedX,printY,seedWidth,"center")
    self.seedBox = {minY=printY,maxY=printY+16,minX=seedX,maxX=seedX+seedWidth}
    love.graphics.rectangle('line',seedX,printY,seedWidth,prefs['fontSize']+2)
    printY = printY+fontSize+4

    --Copy/paste buttons:
    self.copyButton = output:button(math.floor(width/2-74),printY,64,false,((self.cursorY == 6 and self.cursorX == 1) and "hover"),"Copy")
    self.pasteButton = output:button(math.ceil(width/2+seedWidth/2)-64,printY,64,false,((self.cursorY == 6 and self.cursorX == 2) and "hover"),"Paste")
    --Cheats button:
    self.cheatsButton = output:button(math.ceil(width/2)-64,printY+42,136,false,(self.cursorY == 7 and "hover"),"Game Modifiers")
  end
  
  --close button:
  self.closebutton = output:closebutton(14,14)
  
  love.graphics.pop()
  --White and black for flashes and fadeouts
  setColor(255,255,255,self.whiteAlpha)
  love.graphics.rectangle('fill',0,0,width,height)
  if self.blackAmt then
    setColor(0,0,0,self.blackAmt)
    love.graphics.rectangle('fill',0,0,width,height)
  end
  setColor(255,255,255,255)
end

function newgame:keypressed(key)
  key = input:parse_key(key)
  local screen = self:getScreen()
  if self.blackAmt then return false end
  if key == "return" then
    if screen == "species" or screen == "classes" then
      if screen == "classes" then
        self.player.class = self.classes[self.cursorY].classID
        self.cursorY = 1
      elseif screen == "species" then
        self.player.species = self.species[self.cursorY].creatureID
        self.cursorY = 1
        self:randomize_player_name()
        self:refresh_class_list()
      end
    else
      if self.cursorY == 0 then -- not selecting anyting
        self.cursorY = 4 --select button
      elseif self.cursorY == 1 and self.cursorX == 1 then -- name entry
        self.cursorY = 2
      elseif self.cursorY == 1 and self.cursorX == 2 then
        self:randomize_player_name()
      elseif (self.cursorY == 2) then --gender line
        self.player.gender = self.pronouns[self.cursorX].gender
        self.cursorY = 3
      elseif self.cursorY == 3 then
        self.tutorial = not self.tutorial
      elseif self.cursorY == 4 then --"begin" line
        self:startGame()
      elseif self.cursorY == 5 then --seed line
        self.cursorY = 4
      elseif self.cursorY == 6 then --copy/paste buttons
        if self.cursorX == 1 then --copy
          love.system.setClipboardText((self.seed or ""))
        elseif self.cursorX == 2 then -- paste
          self.seed = tonumber(love.system.getClipboardText())
        end
      elseif self.cursorY == 7 then --cheats button
        Gamestate.switch(cheats)
      end -- end cursor check
    end
  elseif key == "tab" then
    if screen == "name" then
      self.cursorY = self.cursorY+1
      if self.cusorY > 7 then self.cursorY = 1 end
    end
  elseif key == "backspace" then
    if self.cursorY == 1 then
      self.player.name = string.sub(self.player.name,1,#self.player.name-1)
    elseif self.cursorY == 5 then
      local seed = tostring(self.seed)
      local newSeed = tonumber(string.sub(seed,1,#seed-1))
      self.seed = newSeed
    end
  elseif key == "north" then
    if self.cursorY > 1 then
      self.cursorY = self.cursorY - 1
      if self.cursorY == 2 and screen == "name" then
        self.cursorX = 1
      end
      if self.classScrollPositions and self.cursorY-self.classScrollY < 1 then
        self:classScrollUp()
      end
    end
  elseif key == "south" then
    if (screen == "species" and self.cursorY < #self.species) or (screen == "classes" and self.cursorY < #self.classes) or (screen == "name" and self.cursorY <= 6) then
      self.cursorY = self.cursorY + 1
      if self.cursorY == 2 and screen == "name" then
        self.cursorX = 1
      end
      if self.classScrollPositions and self.cursorY-self.classScrollY > self.maxClassLines then
        self:classScrollDown()
      end
    end
  elseif key == "west" then
    self.cursorX = math.max(1,self.cursorX - 1)
  elseif key == "east" then
    self.cursorX = self.cursorX + 1
  elseif tonumber(key) and self.cursorY == 5 and screen == "name" then
    local newSeed = tonumber((self.seed or "").. key)
    if newSeed < math.pow(2,32) then
      self.seed = newSeed
    end --end seed bounds check
  elseif key == "escape" then
    if screen == "species" then
      Gamestate.switch(menu)
    elseif screen == "classes" then
      self.player.species=nil
      self.cursorY = 1
    elseif screen == "name" then
      self.player.class=nil
      self.cursorY = 1
    end
  end --end key if
end

function newgame:mousepressed(x,y,button)
  local screen = self:getScreen()
  if self.blackAmt then return false end
  if button == 2 then
    Gamestate.switch(menu)
    return
  end
  local width = love.graphics.getWidth()
  local nameBoxX=math.floor(width/2)-256+48-(prefs['noImages'] and 32 or 0)
  local nameBoxWidth = 512-128+(prefs['noImages'] and 96 or 0)
  if x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY then
    Gamestate.switch(menu)
    return
  end
  
  --Name Selection:
  if self.randomnNameButton and y >= self.randomNameButton.minY and y <= self.randomNameButton.maxY and x >= self.randomNameButton.minX and x <= self.randomNameButton.maxX then
    self:randomize_player_name()
  elseif y > 32 and y<56 then
    self.cursorY = 1
  end
  
  --Pronoun Selection:
  if self.pronouns and y >= self.pronouns[1].minY and y <= self.pronouns[1].maxY then
    for i = 1,4,1 do
      if x >= self.pronouns[i].minX and x <= self.pronouns[i].maxX then
        self.player.gender = self.pronouns[i].gender
        self.cursorY = 3
      end
    end
  end --end gender if
  
  --Species and Class Selection:
  if screen == "species" then
    if y >= self.species[1].minY and y <= self.species[#self.species].maxY and x >= self.species[1].minX and x <= self.species[1].maxX then
      for i = 1,#self.species,1 do
        if y >= self.species[i].minY and y <= self.species[i].maxY then
          self.player.species = self.species[i].creatureID
          self.cursorY = 1
          self:randomize_player_name()
          self:refresh_class_list()
        end
      end
    end --end class if
  elseif screen == "classes" then --Class selection
    if y >= self.classes[1].minY and y <= self.classes[#self.classes].maxY and x >= self.classes[1].minX and x <= self.classes[1].maxX then
      for i = 1,#self.classes,1 do
        if y >= self.classes[i].minY and y <= self.classes[i].maxY then
          self.player.class = self.classes[i].classID
          self.cursorY = 1
        end
      end
    end --end class if
  end
  
  --Tutorial Box:
  if self.tutorialBox and y >= self.tutorialBox.minY and y <= self.tutorialBox.maxY and x >= self.tutorialBox.minX and x <= self.tutorialBox.maxX then
    self.tutorial = not self.tutorial
  end
  
  --Begin Button:
  if self.beginButton and self.beginButton and y > self.beginButton.minY and y < self.beginButton.maxY and x > self.beginButton.minX and x < self.beginButton.maxX then
    self:startGame()
  end
  
  --Seedbox:
  if self.seedBox and y >= self.seedBox.minY and y <= self.seedBox.maxY and x >= self.seedBox.minX and x <= self.seedBox.maxX then
    self.cursorY = 5
  end
  
  --Copy Button:
  if self.copyButton and y >= self.copyButton.minY and y <= self.copyButton.maxY and x >= self.copyButton.minX and x <= self.copyButton.maxX then
    love.system.setClipboardText((self.seed or ""))
  end
  
  --Paste Button:
  if self.pasteButton and y >= self.pasteButton.minY and y <= self.pasteButton.maxY and x >= self.pasteButton.minX and x <= self.pasteButton.maxX then
    self.seed = tonumber(love.system.getClipboardText())
  end
  
  --Cheats Button:
  if self.cheatsButton and y >= self.cheatsButton.minY and y <= self.cheatsButton.maxY and x >= self.cheatsButton.minX and x <= self.cheatsButton.maxX then
    Gamestate.switch(cheats)
  end
end

function newgame:wheelmoved(x,y)
  if self.blackAmt then return false end
  if self.classScrollPositions then
    if y > 0 then
      self:classScrollUp()
    elseif y < 0 then
      self:classScrollDown()
    end
  end
  if self.descScrollPositions then
    if y > 0 then
      self.descScrollY = math.max(self.descScrollY-1,0)
    elseif y < 0 then
      self.descScrollY = math.min(self.descScrollY+1,(self.maxDescScroll or 0))
    end
  end
end

function newgame:update(dt)
  local screen = self:getScreen()
  if not self.cursorY then self.cursorY = 0 end
  if self.cursorY < 0 then self.cursorY = 0 end
  if self.cursorX < 1 then
    self.cursorX = 1
  elseif self.pronouns and self.cursorY == 2 and self.cursorX > #self.pronouns then
    self.cursorX = #self.pronouns
  elseif self.cursorX > 2 and self.cursorY ~= 2 then
    self.cursorX = 2
  end
	local x,y = love.mouse.getPosition()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
	if x > math.floor(width/3) and x < math.floor(width/3)*2 and (y ~= output.mouseY or x ~= output.mouseX) then -- only do this if the mouse has moved, and if it's in range
		output.mouseX,output.mouseY = x,y
	end
  self.lineCountdown = self.lineCountdown-dt
  if self.lineCountdown <= 0 then
    self.lineCountdown = .5
    self.lineOn = not self.lineOn
  end
  if self.player.name == "" and self.cursorY ~= 1 then
    self:randomize_player_name()
  end
  
  --Scrollbars:
  if (love.mouse.isDown(1)) and self.classScrollPositions then
    local x,y = love.mouse.getPosition()
    local upArrow = self.classScrollPositions.upArrow
    local downArrow = self.classScrollPositions.downArrow
    local elevator = self.classScrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:classScrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:classScrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then self:classScrollUp()
      elseif y>elevator.endY then self:classScrollDown() end
    end --end clicking on arrow
  end
end

function newgame:textinput(text)
  if self.cursorY == 1 and self.cursorX == 1 then
    self.player.name = self.player.name .. text
  end
end

function newgame:startGame()
  initialize_player(self.player.species,self.player.class,self.player.name,self.player.gender,self.player.pronouns)
  new_game((tonumber(self.seed) > 0 and tonumber(self.seed) or 1),self.tutorial,self.cheats)
  self.cursorY=0
  self.blackAmt = 0
  tween(1,self,{blackAmt=255})
  Timer.after(1.5,function()
      output:play_playlist('silence')
      Gamestate.switch(game)
      tween(1,game,{blackAmt=0})
      Timer.after(1,function () game.blackAmt=nil end)
  end)
  game.blackAmt=255
  output:setCursor(0,0)
  currGame.cheats = self.cheats
  if currGame.cheats.fullMap == true then currMap:reveal() end
  currMap:refresh_lightMap(true) -- refresh the lightmap, forcing it to refresh all lights
  refresh_player_sight()
end

function newgame:randomize_player_name()
  local creature = self.player.species and possibleMonsters[self.player.species]
  if creature and creature.nameGen then
    self.player.name = creature.nameGen(self.player)
  else
    self.player.name = namegen:generate_name(creature and creature.nameType or "human",player)
  end
end

function newgame:getScreen()
  if (not self.player.species and not gamesettings.no_player_species) then
    return "species"
  elseif (not self.player.class and not gamesettings.no_player_classes) then
    return "classes"
  else
    return "name"
  end
end

function newgame:classScrollUp()
  self.classScrollY = math.max(self.classScrollY-1,0)
  if self.classScrollPositions and self.cursorY-self.classScrollY > self.maxClassLines then
    self.cursorY = self.cursorY-1
  end
end

function newgame:classScrollDown()
  self.classScrollY = math.min(self.classScrollY+1,(self.maxClassScroll or 0))
  if self.classScrollPositions and self.cursorY-self.classScrollY <= 0 then
    self.cursorY = self.cursorY+1
  end
end

function newgame:refresh_class_list()
  self.classes = {}
  for id,class in pairs(playerClasses) do
    local classOK = true --classes all default to being available
    if self.player.species then --don't bother checking the player's species if they don't have one yet
      local creat = possibleMonsters[self.player.species]
      if class.require_species or class.require_species_tags then --First, check if the species requirements are met
        classOK = false --If there are species requirements, default the class to being unavailable
        if class.require_species and in_table(self.player.species,class.require_species) then --check if the species ID matches the requirement
          classOK = true
        end --end require_species if
        if classOK == false and class.require_species_tags then --check if the species tags matches the requirements
          for _,tag in pairs(class.require_species_tags) do
            if (creat.tags and in_table(tag,creat.tags)) or (creat.types and in_table(tag,creat.types)) then
              classOK = true
              break
            end
          end --end require_species_tags for
        end --end require_species_tags if
      end --end require_species if
      if classOK == true and (class.forbid_species or class.forbid_species_tags) then --only check forbidden species if we're still OK after checking species requirements
        if class.forbid_species and in_table(self.player.species,class.forbid_species) then --check if the species ID matches the requirement
          classOK = false
        end --end forbid_species if
        if classOK == true and class.forbid_species_tags then
          for _,tag in pairs(class.forbid_species_tags) do
            if (creat.tags and in_table(tag,creat.tags)) or (creat.types and in_table(tag,creat.types)) then
              classOK = false
              break
            end
          end --end forbid_species_tags for
        end
      end --end forbid_species if
    end
    if classOK then
      self.classes[#self.classes+1] = {classID=id,name=class.name}
    end
  end
  sort_table(self.classes,"name")
end