newgame = {whiteAlpha=0,cheats = {}}

function newgame:enter(previous)
  self.lineCountdown = 0.5
  self.lineOn = true
  self.blackAmt=nil
  if previous ~= cheats and previous ~= pronoun_entry then
    --Clear all game variables, so there's not any bleed from the previous game
    player = nil
    initialize_game()
    initialize_world()
    currMap = nil
    if not self.seed or previous == menu then self.seed = random(999999,2147483647) end
    if not totalstats or not totalstats.games or totalstats.games == 0 then
      self.tutorial = true
    end
    self.cursorY = 1
    self.cursorX = 1
    self.descScrollY = 0
    self.classScrollY = 0
    self.classDescSplit = 0
    local genders={"male","female","other"}
    self.player = {name=nil,species=nil,class=nil,gender=get_random_element(genders),pronouns=nil,spells={}}
    if not gamesettings.player_species then
      self.player.species = gamesettings.default_player
    end
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
  local uiScale = (prefs['uiScale'] or 1)
  local width, height = math.floor(love.graphics:getWidth()/uiScale),math.floor(love.graphics:getHeight()/uiScale)
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = math.floor(mouseX/uiScale),math.floor(mouseY/uiScale)
  love.graphics.setFont(fonts.mapFont)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,math.floor(-((self.blackAmt and self.blackAmt/255 or 0/255))*height/2))

  -- Define some coordinates:
  local screen = self:getScreen()
  local fontSize = 24
  
  --Print the screen:
  if screen == "species" or screen == "classes" then
    setColor(255,255,255,255)
    love.graphics.setFont(fonts.headerFont)
    local fontSize = 24
    local windowPadding=8
    local classBoxW = 200
    local classBoxX = 32
    local classBoxY = 48
    local totalH = height-classBoxY-48
    local classBoxH = totalH
    local descBoxX = classBoxX+classBoxW+windowPadding*2+32
    local descBoxY = classBoxY
    local descBoxH = totalH
    local descBoxW = width-descBoxX-64
    local totalW = classBoxW+descBoxW
    self.maxClassLines = math.floor(classBoxH/fontSize)
    local maxDescLines = math.floor(descBoxH/prefs['fontSize'])
    love.graphics.printf("Select a " .. (screen =="species" and "Species" or "Class"),classBoxX,classBoxY-32,totalW,"center")
    output:draw_window(classBoxX-windowPadding,classBoxY-windowPadding,classBoxX+classBoxW,classBoxY+classBoxH)
    output:draw_window(descBoxX-windowPadding,descBoxY-windowPadding,descBoxX+descBoxW,descBoxY+descBoxH)
    self.classDescSplit = descBoxX-windowPadding

    --***Screen 1 - Species:
    if screen == "species" then
      local printY = classBoxY
      local whichSpecies = self.species[self.cursorY].creatureID

      love.graphics.push()
      --Create a "stencil" that stops stuff from being drawn outside borders
      local function stencilFunc()
        love.graphics.rectangle("fill",classBoxX,classBoxY,classBoxW,classBoxH+32)
      end
      love.graphics.stencil(stencilFunc,"replace",1)
      love.graphics.setStencilTest("greater",0)
      love.graphics.translate(0,-self.classScrollY*fontSize)
      --Loop through all species and display their names:
      for i,s in ipairs(self.species) do
        local id = s.creatureID
        local creature = possibleMonsters[id]
        local moused = (mouseY >= printY-self.classScrollY*fontSize and mouseY <= printY+fontSize-self.classScrollY*fontSize and mouseX >= classBoxX and mouseX <= classBoxX+classBoxW-(#self.species > self.maxClassLines and 0 or -32))
        if self.player.species == id then
          setColor(100,100,100,255)
          love.graphics.rectangle('fill',classBoxX,printY,classBoxW,fontSize)
        elseif self.cursorY == i or moused then
          self.cursorY = i
          whichSpecies = id
          if self.cursorX == 1 then
            setColor(50,50,50,255)
          else
            setColor(33,33,33,255)
          end
          love.graphics.rectangle('fill',classBoxX,printY,classBoxW-(#self.species > self.maxClassLines and 0 or -32),fontSize)
        end
        setColor(255,255,255,255)
        love.graphics.print(s.name,classBoxX+2,printY)
        self.species[i] = {creatureID=id,name=s.name,minX=classBoxX,maxX=classBoxX+classBoxW-(#self.species > self.maxClassLines and 0 or -32),minY=printY,maxY=printY+fontSize}
        printY = printY+fontSize
      end
      love.graphics.setStencilTest()
      love.graphics.pop()
      if #self.species > self.maxClassLines then
        local oldMax = self.maxClassScroll
        self.maxClassScroll = #self.species-self.maxClassLines
        if oldMax ~= self.maxClassScroll then self.classScrollY=0 end
        local scrollAmt = (self.classScrollY)/self.maxClassScroll
        self.classScrollPositions = output:scrollbar(classBoxX+classBoxW,classBoxY,classBoxY+classBoxH+28,scrollAmt,true)
      end
      --Display selected species:
      whichSpecies = whichSpecies or self.player.species
      if whichSpecies then
        local creature = possibleMonsters[whichSpecies]
        local desc = self:get_stat_text(whichSpecies)
        
        love.graphics.setFont(fonts.textFont)
        local _, tlines = fonts.textFont:getWrap(creature.name .. "\n" .. creature.description,descBoxW)
        local _,dlines = fonts.textFont:getWrap(desc,descBoxW)
        local descYpad = (#tlines+2)*prefs['fontSize']
        local finalTextHeight = descYpad+(#dlines+2)*prefs['fontSize']
        local finalY = descBoxY+finalTextHeight
        local totalLines = #tlines+#dlines+4
        if totalLines > maxDescLines then
          _, tlines = fonts.textFont:getWrap(creature.name .. "\n" .. creature.description,descBoxW-96)
          _,dlines = fonts.textFont:getWrap(desc,descBoxW-32)
          descYpad = (#tlines+2)*prefs['fontSize']
          finalTextHeight = descYpad+(#dlines+2)*prefs['fontSize']
          finalY = descBoxY+finalTextHeight
          totalLines = #tlines+#dlines+4
          love.graphics.push()
          --Create a "stencil" that stops stuff from being drawn outside borders
          local function stencilFunc()
            love.graphics.rectangle("fill",descBoxX,descBoxY,descBoxW+32,descBoxH+32)
          end
          love.graphics.stencil(stencilFunc,"replace",1)
          love.graphics.setStencilTest("greater",0)
          love.graphics.translate(0,-self.descScrollY*prefs['fontSize'])
          love.graphics.printf(ucfirst(creature.name) .. "\n" .. creature.description,descBoxX+32,descBoxY,descBoxW-64,"center")
          love.graphics.printf(desc,descBoxX+2,descBoxY+descYpad,descBoxW-32,"left")
          love.graphics.setStencilTest()
          love.graphics.pop()
          local oldMax = self.maxDescScroll
          self.maxDescScroll = totalLines-maxDescLines+1
          if oldMax ~= self.maxDescScroll then self.descScrollY=0 end
          local scrollAmt = (self.descScrollY)/self.maxDescScroll
          if self.cursorX == 2 then
            setColor(50,50,50,255)
            love.graphics.rectangle("fill",descBoxX+descBoxW-6+4,descBoxY,24,descBoxH+24)
            setColor(255,255,255,255)
          end
          self.descScrollPositions = output:scrollbar(descBoxX+descBoxW-6,descBoxY,descBoxY+descBoxH+24,scrollAmt,true)
        else
          love.graphics.printf(ucfirst(creature.name) .. "\n" .. creature.description,descBoxX,descBoxY,descBoxW,"center")
          love.graphics.printf(desc,descBoxX+2,descBoxY+descYpad,descBoxW,"left")
          self.descScrollPositions = nil
          self.maxDescScroll=0
          self.descScrollY=0
        end
        love.graphics.setFont(fonts.headerFont)
      end
    end
    
    --***Screen 2 - Classes:
    if screen == "classes" then
      local printY = classBoxY
      local whichClass = self.classes[self.cursorY].classID
      
      love.graphics.push()
      --Create a "stencil" that stops stuff from being drawn outside borders
      local function stencilFunc()
        love.graphics.rectangle("fill",classBoxX,classBoxY,classBoxW,classBoxH+32)
      end
      love.graphics.stencil(stencilFunc,"replace",1)
      love.graphics.setStencilTest("greater",0)
      love.graphics.translate(0,-self.classScrollY*fontSize)
      for i,c in ipairs(self.classes) do
        local id = c.classID
        local class = playerClasses[id]
        local moused = (mouseY >= printY-self.classScrollY*fontSize and mouseY <= printY+fontSize-self.classScrollY*fontSize and mouseX >= classBoxX and mouseX <= classBoxX+classBoxW-(#self.species > self.maxClassLines and 0 or -32))
        if self.player.class == id then
          setColor(100,100,100,255)
          love.graphics.rectangle('fill',classBoxX,printY,classBoxW,fontSize)
        elseif self.cursorY == i or moused then
          self.cursorY = i
          whichClass = id
          if self.cursorX == 1 then
            setColor(50,50,50,255)
          else
            setColor(33,33,33,255)
          end
          love.graphics.rectangle('fill',classBoxX,printY,classBoxW-(#self.classes > self.maxClassLines and 0 or -32),fontSize)
        end
        setColor(255,255,255,255)
        love.graphics.print(class.name,classBoxX+2,printY)
        self.classes[i] = {classID=id,minX=classBoxX,maxX=classBoxX+classBoxW-(#self.classes > self.maxClassLines and 0 or -32),minY=printY,maxY=printY+fontSize}
        printY = printY+fontSize
      end
      whichClass = whichClass or self.player.class
      if whichClass then
        local whichSpecies = self.player.species
        local class = playerClasses[whichClass]
        local desc = self:get_stat_text(whichSpecies,whichClass)
        
        love.graphics.setStencilTest()
        love.graphics.pop()
        if #self.classes > self.maxClassLines then
          local oldMax = self.maxClassScroll
          self.maxClassScroll = #self.classes-self.maxClassLines
          if oldMax ~= self.maxClassScroll then self.classScrollY=0 end
          local scrollAmt = (self.classScrollY)/self.maxClassScroll
          self.classScrollPositions = output:scrollbar(classBoxX+classBoxW,classBoxY,classBoxY+classBoxH+28,scrollAmt,true)
        end
        
        --Display selected class:
        love.graphics.setFont(fonts.textFont)
        local _, tlines = fonts.textFont:getWrap(class.name .. "\n" .. class.description,descBoxW)
        local _,dlines = fonts.textFont:getWrap(desc,descBoxW)
        local descYpad = (#tlines+2)*prefs['fontSize']
        local finalTextHeight = descYpad+(#dlines+2)*prefs['fontSize']
        local finalY = descBoxY+finalTextHeight
        local totalLines = #tlines+#dlines+4
        if totalLines > maxDescLines then
          _, tlines = fonts.textFont:getWrap(class.name .. "\n" .. class.description,descBoxW-64)
          _,dlines = fonts.textFont:getWrap(desc,descBoxW-32)
          descYpad = (#tlines+2)*prefs['fontSize']
          finalTextHeight = descYpad+(#dlines+2)*prefs['fontSize']
          finalY = descBoxY+finalTextHeight
          local totalLines = #tlines+#dlines+4
          love.graphics.push()
          --Create a "stencil" that stops stuff from being drawn outside borders
          local function stencilFunc()
            love.graphics.rectangle("fill",descBoxX,descBoxY,descBoxW+32,descBoxH+32)
          end
          love.graphics.stencil(stencilFunc,"replace",1)
          love.graphics.setStencilTest("greater",0)
          love.graphics.translate(0,-self.descScrollY*prefs['fontSize'])
          love.graphics.printf(ucfirst(class.name) .. "\n" .. class.description,descBoxX+32,descBoxY,descBoxW-64,"center")
          love.graphics.printf(desc,descBoxX+2,descBoxY+descYpad,descBoxW-32,"left")
          love.graphics.setStencilTest()
          love.graphics.pop()
          local oldMax = self.maxDescScroll
          self.maxDescScroll = totalLines-maxDescLines+1
          if oldMax ~= self.maxDescScroll then self.descScrollY=0 end
          local scrollAmt = (self.descScrollY)/self.maxDescScroll
          if self.cursorX == 2 then
            setColor(50,50,50,255)
            love.graphics.rectangle("fill",descBoxX+descBoxW-6+4,descBoxY,24,descBoxH+24)
            setColor(255,255,255,255)
          end
          self.descScrollPositions = output:scrollbar(descBoxX+descBoxW-6,descBoxY,descBoxY+descBoxH+24,scrollAmt,true)
        else
          love.graphics.printf(ucfirst(class.name) .. "\n" .. class.description,descBoxX,descBoxY,descBoxW,"center")
          love.graphics.printf(desc,descBoxX+2,descBoxY+descYpad,descBoxW,"left")
          self.descScrollPositions = nil
          self.maxDescScroll=0
          self.descScrollY=0
        end
        love.graphics.setFont(fonts.headerFont)
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
    local nameBoxX = 16
    local printY = 32
    local sideW = math.max(round(width/uiScale/2),512)
    local nameBoxWidth = math.min(sideW-116-nameBoxX-16,512)
    --Delete scroll info from previous screens:
    self.classScrollPositions = nil
    self.maxClassScroll = 0
    self.classScrollY=0
    setColor(255,255,255,255)
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Name:",nameBoxX,printY,nameBoxWidth,"center")
    printY=printY+24
    self.nameBox = {minX=nameBoxX,maxX=nameBoxX+nameBoxWidth,minY=printY,maxY=printY+24}
    if self.cursorY == 1 and self.cursorX == 1 then
      setColor(50,50,50,255)
      love.graphics.rectangle('fill',nameBoxX,printY,nameBoxWidth,24)
      setColor(255,255,255,255)
      love.graphics.printf(self.player.name,nameBoxX,printY,nameBoxWidth,"center")
      if self.lineOn then
        local w = fonts.headerFont:getWidth(self.player.name)
        local lineX = nameBoxX+math.ceil(nameBoxWidth/2+w/2)
        love.graphics.line(lineX,printY+4,lineX,printY+21)
      end
    elseif mouseY > self.nameBox.minY and mouseY < self.nameBox.maxY and mouseX > self.nameBox.minX and mouseX < self.nameBox.maxX then
      setColor(33,33,33,255)
      love.graphics.rectangle('fill',nameBoxX,printY,nameBoxWidth,24)
      setColor(255,255,255,255)
      love.graphics.printf(self.player.name,nameBoxX,printY,nameBoxWidth,"center")
    else
      love.graphics.printf(self.player.name,nameBoxX,printY,nameBoxWidth,"center")
    end
    love.graphics.rectangle('line',nameBoxX,printY,nameBoxWidth,24)
    
    --Randomize button:
    --function output:button(x,y,width,small,special,text,useScaling)
    self.randomNameButton = output:button(nameBoxX+nameBoxWidth+16,printY,100,nil,(self.cursorY == 1 and self.cursorX == 2 and "hover" or nil),"Randomize",true)
    
    printY=printY+32
    
    --Draw Pronouns:
    love.graphics.setFont(fonts.headerFont)
    local w = fonts.headerFont:getWidth("Pronouns: ")
    love.graphics.print("Pronouns: ",nameBoxX,printY)
    self.pronouns = {}
    local custom = self.player.pronouns and {n=self.player.pronouns.n,o=self.player.pronouns.o,p=self.player.pronouns.p} or {n="he",o="them",p="her"}
    local pnounlist = {male={n="he",o="him",p="his"},female={n="she",o="her",p="her"},neuter={n="it",o="it",p="its"},other={n="they",o="them",p="their"},custom=custom}
    local genderX = 1
    if self.cursorY == 2 or (mouseY > printY and mouseY < printY+24) then
      local printX = nameBoxX+w
      local pnouns = ucfirst(pnounlist[self.player.gender].n) .. "/" .. ucfirst(pnounlist[self.player.gender].o) .. "/" .. ucfirst(pnounlist[self.player.gender].p)
      w = fonts.headerFont:getWidth(pnouns)
      if (self.cursorX == genderX and (mouseY < printY or mouseY > printY+24)) or (mouseY > printY and mouseY < printY+24 and mouseX > printX and mouseX < printX+w) then
        setColor(50,50,50,255)
        love.graphics.rectangle("fill",printX,printY,w,24)
        setColor(255,255,255,255)
      end
      love.graphics.print(pnouns,printX,printY)
      self.pronouns[1] = {gender=self.player.gender,minX = printX,maxX = printX+w,minY=printY,maxY=printY+24}
      printX=printX+w+12
      if self.player.gender ~= "male" then
        genderX = genderX+1
        pnouns = "He"
        w = fonts.headerFont:getWidth(pnouns)
        if (self.cursorX == genderX and (mouseY < printY or mouseY > printY+24)) or (mouseY > printY and mouseY < printY+24 and mouseX > printX and mouseX < printX+w+12) then
          setColor(50,50,50,255)
          love.graphics.rectangle("fill",printX,printY,w,24)
          setColor(255,255,255,255)
        end
        love.graphics.print(pnouns,printX,printY)
        self.pronouns[#self.pronouns+1] = {gender="male",minX = printX,maxX = printX+w+12,minY=printY,maxY=printY+24}
        printX = printX+w+12
      end
      if self.player.gender ~= "female" then
        genderX = genderX+1
        pnouns = "She"
        w = fonts.headerFont:getWidth(pnouns)
        if (self.cursorX == genderX and (mouseY < printY or mouseY > printY+24)) or (mouseY > printY and mouseY < printY+24 and mouseX > printX and mouseX < printX+w+12) then
          setColor(50,50,50,255)
          love.graphics.rectangle("fill",printX,printY,w,24)
          setColor(255,255,255,255)
        end
        love.graphics.print(pnouns,printX,printY)
        self.pronouns[#self.pronouns+1] = {gender="female",minX = printX,maxX = printX+w+12,minY=printY,maxY=printY+24}
        printX = printX+w+12
      end
      if self.player.gender ~= "neuter" then
        genderX = genderX+1
        pnouns = "It"
        w = fonts.headerFont:getWidth(pnouns)
        if (self.cursorX == genderX and (mouseY < printY or mouseY > printY+24)) or (mouseY > printY and mouseY < printY+24 and mouseX > printX and mouseX < printX+w+12) then
          setColor(50,50,50,255)
          love.graphics.rectangle("fill",printX,printY,w,24)
          setColor(255,255,255,255)
        end
        love.graphics.print(pnouns,printX,printY)
        self.pronouns[#self.pronouns+1] = {gender="neuter",minX = printX,maxX = printX+w+12,minY=printY,maxY=printY+24}
        printX = printX+w+12
      end
      if self.player.gender ~= "other" then 
        genderX = genderX+1
        pnouns = "They"
        w = fonts.headerFont:getWidth(pnouns)
        if (self.cursorX == genderX and (mouseY < printY or mouseY > printY+24)) or (mouseY > printY and mouseY < printY+24 and mouseX > printX and mouseX < printX+w+12) then
          setColor(50,50,50,255)
          love.graphics.rectangle("fill",printX,printY,w,24)
          setColor(255,255,255,255)
        end
        love.graphics.print(pnouns,printX,printY)
        self.pronouns[#self.pronouns+1] = {gender="other",minX = printX,maxX = printX+printX+w+12,minY=printY,maxY=printY+24}
        printX = printX+w+12
      end
      genderX = genderX+1
      pnouns = "Custom"
      w = fonts.headerFont:getWidth(pnouns)
      if (self.cursorX == genderX and (mouseY < printY or mouseY > printY+24)) or (mouseY > printY and mouseY < printY+24 and mouseX > printX and mouseX < printX+w+12) then
        setColor(50,50,50,255)
        love.graphics.rectangle("fill",printX,printY,w,24)
        setColor(255,255,255,255)
      end
      love.graphics.print(pnouns,printX,printY)
      self.pronouns[#self.pronouns+1] = {gender="custom",minX = printX,maxX = printX+printX+w+12,minY=printY,maxY=printY+24}
      printX = printX+w+12
    else
      local pnouns = ucfirst(pnounlist[self.player.gender].n) .. "/" .. ucfirst(pnounlist[self.player.gender].o) .. "/" .. ucfirst(pnounlist[self.player.gender].p)
      w = fonts.headerFont:getWidth(pnouns)
      self.pronouns[1] = {gender=self.player.gender,minX = nameBoxX,maxX = nameBoxX+w,minY=printY,maxY=printY+24}
      love.graphics.print(pnouns,nameBoxX+w,printY)
    end
    --Tutorial Checkbox:
    printY = printY+50
    local padding = (prefs['noImages'] and 16 or 32)
    love.graphics.setFont(fonts.headerFont)
    local textWidth = fonts.headerFont:getWidth("Tutorial Messages? (Y)")
    local tutX = round(sideW/2-textWidth/2)
    if self.cursorY == 3 and self.cursorX == 1 then
      setColor(100,100,100,255)
      love.graphics.rectangle('fill',tutX-32,printY,textWidth+64,24)
      setColor(255,255,255,255)
    elseif (mouseY > printY and mouseY < printY+24 and mouseX > tutX and mouseX < tutX+textWidth) then
      setColor(50,50,50,255)
      love.graphics.rectangle('fill',tutX-32,printY,textWidth+64,24)
      setColor(255,255,255,255)
    end
    if prefs['noImages'] then
      love.graphics.print((self.tutorial and "(Y)" or "(N)"),tutX,printY)
    else
      love.graphics.draw((self.tutorial and images.uicheckboxchecked or images.uicheckbox),tutX-16,math.floor(printY+padding/8))
    end
    love.graphics.print("Tutorial Messages?",tutX+16,printY)
    self.tutorialBox = {minX=nameBoxX, maxX=nameBoxX+nameBoxWidth, minY=printY, maxY=printY+24}
    printY = printY+padding
    
    --Begin Button:
    self.beginButton = output:button(math.floor(sideW/2-75),printY,150,false,((self.cursorY == 4  and self.cursorX == 1) and "hover" or nil),"BEGIN",true)
    printY = printY+64
    
    --Seed info:
    local seedWidth = fonts.textFont:getWidth("Seed: 100000000000")
    local seedX = math.ceil(sideW/2-seedWidth/2)
    if self.cursorY == 5  and self.cursorX == 1  then
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
    self.seedBox = {minY=printY,maxY=printY+fontSize+4,minX=seedX,maxX=seedX+seedWidth}
    love.graphics.rectangle('line',seedX,printY,seedWidth,prefs['fontSize']+2)
    printY = self.seedBox.maxY+16

    --Copy/paste buttons:
    self.copyButton = output:button(math.floor(sideW/2-74),printY,64,false,((self.cursorY == 6 and self.cursorX == 1) and "hover" or nil),"Copy",true)
    self.pasteButton = output:button(math.ceil(sideW/2),printY,64,false,((self.cursorY == 6 and self.cursorX == 2) and "hover" or nil),"Paste",true)
    --Cheats button:
    self.cheatsButton = output:button(math.ceil(sideW/2)-64,printY+42,136,false,((self.cursorY == 7  and self.cursorX == 1) and "hover" or nil),"Game Modifiers",true)
    
    self.maxX = {[1]=2,[2]=genderX,[6]=2}
    
    --Display character info:
    local windowPadding=8
    local descBoxX = math.ceil(width/uiScale/2)
    local descBoxY = 32
    local descBoxH = height-descBoxY-48
    local descBoxW = width-descBoxX-windowPadding*2-32
    local maxDescLines = math.floor(descBoxH/prefs['fontSize'])
    self.classDescSplit = descBoxX
    output:draw_window(descBoxX-windowPadding,descBoxY-windowPadding,descBoxX+descBoxW+windowPadding,descBoxY+descBoxH+windowPadding)
    
    local desc = self:get_stat_text()
    local class = (self.player.class and playerClasses[self.player.class] or nil)
    local creature = possibleMonsters[(self.player.species or gamesettings.default_player)]
    love.graphics.setFont(fonts.textFont)
    local className = ucfirst(creature.name) .. (class and " " .. ucfirst(class.name) or "")
    local _, tlines = fonts.textFont:getWrap(className,descBoxW)
    local _,dlines = fonts.textFont:getWrap(desc,descBoxW)
    local descYpad = (#tlines+2)*prefs['fontSize']
    local finalTextHeight = descYpad+(#dlines+2)*prefs['fontSize']
    local finalY = descBoxY+finalTextHeight
    local totalLines = #tlines+#dlines+4
    if totalLines > maxDescLines then
      _, tlines = fonts.textFont:getWrap(className,descBoxW-64)
      _,dlines = fonts.textFont:getWrap(desc,descBoxW-32)
      descYpad = (#tlines+2)*prefs['fontSize']
      finalTextHeight = descYpad+(#dlines+2)*prefs['fontSize']
      finalY = descBoxY+finalTextHeight
      local totalLines = #tlines+#dlines+4
      love.graphics.push()
      --Create a "stencil" that stops stuff from being drawn outside borders
      local function stencilFunc()
        love.graphics.rectangle("fill",descBoxX,descBoxY,descBoxW+32,descBoxH+32)
      end
      love.graphics.stencil(stencilFunc,"replace",1)
      love.graphics.setStencilTest("greater",0)
      love.graphics.translate(0,-self.descScrollY*prefs['fontSize'])
      love.graphics.printf(className,descBoxX+32,descBoxY,descBoxW-64,"center")
      love.graphics.printf(desc,descBoxX+2,descBoxY+descYpad,descBoxW-32,"left")
      love.graphics.setStencilTest()
      love.graphics.pop()
      local oldMax = self.maxDescScroll
      self.maxDescScroll = totalLines-maxDescLines+1
      if oldMax ~= self.maxDescScroll then self.descScrollY=0 end
      local scrollAmt = (self.descScrollY)/self.maxDescScroll
      if self.cursorX > (self.maxX and self.maxX[self.cursorY] or 1) then
        setColor(50,50,50,255)
        love.graphics.rectangle("fill",descBoxX+descBoxW-6+4,descBoxY,24,descBoxH+24)
        setColor(255,255,255,255)
      end
      self.descScrollPositions = output:scrollbar(descBoxX+descBoxW-6,descBoxY,descBoxY+descBoxH+24,scrollAmt,true)
    else
      love.graphics.printf(className,descBoxX,descBoxY,descBoxW,"center")
      love.graphics.printf(desc,descBoxX+2,descBoxY+descYpad,descBoxW,"left")
      self.descScrollPositions = nil
      self.maxDescScroll=0
      self.descScrollY=0
    end
    love.graphics.setFont(fonts.headerFont)
  end
  
  --close button:
  self.closebutton = output:closebutton(14,14,nil,true)
  
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

function newgame:buttonpressed(key,scancode,isRepeat,controllerType)
  local origKey = key
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  local screen = self:getScreen()
  if self.blackAmt then return false end
  if key == "enter" or key == "wait" then
    if screen == "species" or screen == "classes" then
      if screen == "classes" then
        self.player.class = self.classes[self.cursorY].classID
        self.cursorY = 1
        self.cursorX = 1
      elseif screen == "species" then
        self.player.species = self.species[self.cursorY].creatureID
        self.cursorY = 1
        self.cursorX = 1
        self:randomize_player_name()
        self:refresh_class_list()
      end
    else
      if self.cursorX > (self.maxX and self.maxX[self.cursorY] or 1) then
        self.cursorX = self.cursorX - 1
      elseif self.cursorY == 0 then -- not selecting anyting
        self.cursorY = 4 --select button
      elseif self.cursorY == 1 and self.cursorX == 1 then -- name entry
        self.cursorY = 2
      elseif self.cursorY == 1 and self.cursorX == 2 then
        self:randomize_player_name()
      elseif (self.cursorY == 2) then --gender line
        self.player.gender = self.pronouns[self.cursorX].gender
        self.cursorY = 3
        if self.pronouns[self.cursorX].gender == "custom" then
          Gamestate.switch(pronoun_entry)
        end
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
  elseif origKey == "tab" or key == "nextTarget" then
    if screen == "name" then
      self.cursorY = self.cursorY+1
      if self.cursorY > 7 then self.cursorY = 1 end
    end
  elseif origKey == "backspace" then
    if self.cursorY == 1 then
      self.player.name = string.sub(self.player.name,1,#self.player.name-1)
    elseif self.cursorY == 5 then
      local seed = tostring(self.seed)
      local newSeed = tonumber(string.sub(seed,1,#seed-1))
      self.seed = newSeed
    end
  elseif key == "north" then
    if (self.cursorX == 2 and (screen == "species" or screen == "classes")) or (screen == "name" and self.cursorX > (self.maxX and self.maxX[self.cursorY] or 1)) then
      self:descScrollUp()
    elseif self.cursorY > 1 then
      self.cursorY = self.cursorY - 1
      if screen == "name" then
        self.cursorX = 1
      end
      if self.classScrollPositions and self.cursorY-self.classScrollY < 1 then
        self:classScrollUp()
      end
    end
  elseif key == "south" then
    if (screen == "species" and self.cursorX == 1 and self.cursorY < #self.species) or (screen == "classes" and self.cursorX == 1 and self.cursorY < #self.classes) or (screen == "name" and self.cursorY <= 6 and self.cursorX <= (self.maxX and self.maxX[self.cursorY] or 1)) then
      self.cursorY = self.cursorY + 1
      if screen == "name" then
        self.cursorX = 1
      end
      if self.classScrollPositions and self.cursorY-self.classScrollY > self.maxClassLines then
        self:classScrollDown()
      end
    elseif (self.cursorX == 2 and (screen == "species" or screen == "classes")) or (screen == "name" and self.cursorX > (self.maxX and self.maxX[self.cursorY] or 1)) then
      self:descScrollDown()
    end
  elseif key == "west" then
    self.cursorX = math.max(1,self.cursorX - 1)
  elseif key == "east" then
    if screen == "species" or screen == "classes" and self.descScrollPositions then
      self.cursorX = 2
    elseif screen == "name" and self.cursorX < (self.maxX and self.maxX[self.cursorY] or 1)+(self.descScrollPositions and 1 or 0) then
      self.cursorX = self.cursorX + 1
    end
  elseif tonumber(key) and self.cursorY == 5 and screen == "name" then
    local newSeed = tonumber((self.seed or "").. key)
    if newSeed < math.pow(2,32) then
      self.seed = newSeed
    end --end seed bounds check
  elseif origKey == "escape" then
    self:goBack()
  end --end key if
end

function newgame:mousepressed(x,y,button)
  local uiScale = prefs['uiScale'] or 1
  x,y = x/uiScale, y/uiScale
  local screen = self:getScreen()
  if self.blackAmt then return false end
  if button == 2 then
    self:goBack()
    return
  end
  local width = love.graphics.getWidth()
  local nameBoxX=math.floor(width/2)-256+48-(prefs['noImages'] and 32 or 0)
  local nameBoxWidth = 512-128+(prefs['noImages'] and 96 or 0)
  if x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY then
    self:goBack()
    return
  end
  
  --Name Selection:
  if self.randomNameButton and y >= self.randomNameButton.minY and y <= self.randomNameButton.maxY and x >= self.randomNameButton.minX and x <= self.randomNameButton.maxX then
    self:randomize_player_name()
  elseif self.nameBox and y > self.nameBox.minY and y<self.nameBox.maxY and x>self.nameBox.minX and x<self.nameBox.maxX then
    self.cursorY,self.cursorX = 1,1
  end
  
  --Pronoun Selection:
  if self.pronouns and y >= self.pronouns[1].minY and y <= self.pronouns[1].maxY then
    for i = 1,#self.pronouns,1 do
      if x >= self.pronouns[i].minX and x <= self.pronouns[i].maxX then
        self.player.gender = self.pronouns[i].gender
        self.cursorY = 3
        if self.pronouns[i].gender == "custom" then
          Gamestate.switch(pronoun_entry)
        end
      end
    end
  end --end gender if
  
  --Species and Class Selection:
  local fontSize = 24
  if screen == "species" then
    if y >= self.species[1].minY-self.classScrollY*fontSize and y <= self.species[#self.species].maxY-self.classScrollY*fontSize and x >= self.species[1].minX and x <= self.species[1].maxX then
      for i = 1,#self.species,1 do
        if y >= self.species[i].minY-self.classScrollY*fontSize and y <= self.species[i].maxY-self.classScrollY*fontSize then
          self.player.species = self.species[i].creatureID
          self.cursorY = 1
          self.cursorX = 1
          self:randomize_player_name()
          self:refresh_class_list()
        end
      end
    end --end class if
  elseif screen == "classes" then --Class selection
    if y >= self.classes[1].minY-self.classScrollY*fontSize and y <= self.classes[#self.classes].maxY-self.classScrollY*fontSize and x >= self.classes[1].minX and x <= self.classes[1].maxX then
      for i = 1,#self.classes,1 do
        if y >= self.classes[i].minY-self.classScrollY*fontSize and y <= self.classes[i].maxY-self.classScrollY*fontSize then
          self.player.class = self.classes[i].classID
          self.cursorY = 1
          self.cursorX = 1
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
  local mouseX,mouseY = love.mouse.getPosition()
  local uiScale = prefs['uiScale'] or 1
  mouseX,mouseY = mouseX/uiScale,mouseY/uiScale
  if self.blackAmt then return false end
  if self.classScrollPositions and mouseX < self.classDescSplit then
    if y > 0 then
      self:classScrollUp()
    elseif y < 0 then
      self:classScrollDown()
    end
  end
  if self.descScrollPositions and mouseX > self.classDescSplit then
    if y > 0 then
      self:descScrollUp()
    elseif y < 0 then
      self:descScrollDown()
    end
  end
end

function newgame:update(dt)
  local uiScale = prefs['uiScale'] or 1
  local screen = self:getScreen()
  if not self.cursorY then self.cursorY = 0 end
  if self.cursorY < 0 then self.cursorY = 0 end
  if self.cursorX < 1 then
    self.cursorX = 1
  end
	local x,y = love.mouse.getPosition()
  x,y = x/uiScale,y/uiScale
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
  if (love.mouse.isDown(1)) and self.descScrollPositions then
    local upArrow = self.descScrollPositions.upArrow
    local downArrow = self.descScrollPositions.downArrow
    local elevator = self.descScrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:descScrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:descScrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then self:descScrollUp()
      elseif y>elevator.endY then self:descScrollDown() end
    end --end clicking on arrow
  end
end

function newgame:textinput(text)
  if self.cursorY == 1 and self.cursorX == 1 and self:getScreen() == "name" then
    self.player.name = self.player.name .. text
  end
end

function newgame:startGame()
  initialize_player(self.player.species,self.player.class,self.player.name,self.player.gender,self.player.pronouns)
  local branch = (playerClasses[self.player.class] and playerClasses[self.player.class].starting_branch) or possibleMonsters[self.player.species].starting_branch or gamesettings.default_starting_branch
  new_game((tonumber(self.seed) > 0 and tonumber(self.seed) or 1),self.tutorial,self.cheats,branch)
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
  if (not self.player.species and gamesettings.player_species) then
    return "species"
  elseif (not self.player.class and gamesettings.player_classes) then
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

function newgame:descScrollUp()
  self.descScrollY = math.max(self.descScrollY-1,0)
end

function newgame:descScrollDown()
  self.descScrollY = math.min(self.descScrollY+1,(self.maxDescScroll or 0))
end

function newgame:goBack()
  local screen = self:getScreen()
  if screen == "species" then
    Gamestate.switch(menu)
  elseif screen == "classes" then
    self.player.species=nil
    self.cursorY = 1
  elseif screen == "name" then
    self.player.class=nil
    self.cursorY = 1
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

function newgame:get_stat_text(whichSpecies,whichClass)
  whichSpecies = whichSpecies or self.player.species or gamesettings.default_player
  whichClass = whichClass or self.player.class
  local class = (whichClass and playerClasses[whichClass] or {})
  
  local desc = ""
  local creature = possibleMonsters[whichSpecies]
  
  --Basic Stats:
  desc = desc .. "Base HP: " .. creature.max_hp + (class.stat_modifiers and class.stat_modifiers.max_hp or 0) .. "\n"
  desc = desc .. "Base MP: " .. (creature.max_mp or 0) + (class.stat_modifiers and class.stat_modifiers.max_mp or 0) .. "\n"
  desc = desc .. "Sight Radius: " .. creature.perception + (class.stat_modifiers and class.stat_modifiers.perception or 0) .. "\n"
  if creature.stealth or (class.stat_modifiers and class.stat_modifiers.stealth) then desc = desc .. "Stealth Modifier: " .. (creature.stealth or 0) + (class.stat_modifiers and class.stat_modifiers.stealth or 0) .. "%\n" end
  if creature.armor or (class.stat_modifiers and class.stat_modifiers.armor) then desc = desc .. "Damage Absorbtion: " .. (creature.armor or 0) + (class.stat_modifiers and class.stat_modifiers.armor or 0) .. "\n" end
  
  --Other stats:
  if creature.extra_stats or class.extra_stats then
    if creature.extra_stats then
      for stat_id,stat in pairs(creature.extra_stats) do
        desc = desc .. stat.name .. ": " .. stat.value .. (stat.max and " (" .. stat.max .. " max)" or "") .. "\n"
      end
    end
    if class.extra_stats then
      for stat_id,stat in pairs(class.extra_stats) do
        desc = desc .. stat.name .. ": " .. stat.value .. (stat.max and " (" .. stat.max .. " max)" or "") .. "\n"
      end
    end
  end
  
  --Weaknesses and resistances
  if (class.weaknesses and count(class.weaknesses) > 0) or (creature.weaknesses and count(creature.weaknesses) > 0) then
    local weak = {}
    desc = desc .. "Weaknesses: "
    for stat,amt in pairs(creature.weaknesses or {}) do
      weak[stat] = amt
    end
    for stat,amt in pairs(class.weaknesses or {}) do
      weak[stat] = (weak[stat] or 0) + amt
    end
     local first = true
    for stat,amt in pairs(weak) do
      desc = desc .. (not first and ", " or "") .. ucfirst(stat) .. " " .. amt .. "%"
      first = false
    end
    desc = desc .. "\n"
  end
  if (class.resistances and count(class.resistances) > 0) or (creature.resistances and count(creature.resistances) > 0) then
    local resist = {}
    desc = desc .. "Resistances: "
    for stat,amt in pairs(creature.resistances or {}) do
      resist[stat] = amt
    end
    for stat,amt in pairs(class.resistances or {}) do
      resist[stat] = (resist[stat] or 0) + amt
    end
     local first = true
    for stat,amt in pairs(resist) do
      desc = desc .. (not first and ", " or "") .. ucfirst(stat) .. " " .. amt .. "%"
      first = false
    end
    desc = desc .. "\n"
  end
  
  --Skills:
  if gamesettings.default_skills or creature.skills or class.skills then
    local skillVals = {}
    for _,skillID in ipairs(gamesettings.default_skills or {}) do
      skillVals[skillID] = 0
    end
    for skillID, value in pairs(creature.skills or {}) do
      if value == false then
        skillVals[skillID] = false
      elseif skillVals[skillID] ~= false then
        skillVals[skillID] = (skillVals[skillID] or 0) + value
      end
    end
    for skillID, value in pairs(class.skills or {}) do
      if value == false then
        skillVals[skillID] = false
      elseif skillVals[skillID] ~= false then
        skillVals[skillID] = (skillVals[skillID] or 0) + value
      end
    end
    
    local skill_lists = {}
    for skillID,value in pairs(skillVals) do
      local skill = possibleSkills[skillID]
      if skill then
        local sType = skill.skill_type or "skill"
        if not skill_lists[sType] then
          skill_lists[sType] = {}
        end
        skill_lists[sType][#skill_lists[sType]+1] = {skillID=skillID,value=value,name=skill.name}
      end
    end
    
    local ordered_list = {}
    if gamesettings.skill_type_order then
      for i,skillType in pairs(gamesettings.skill_type_order) do
        ordered_list[#ordered_list+1] = skillType
      end
    end
    local unordered = {} --sort unordered skill lists alphabetically so at least there's consistency
    for skillType,_ in pairs(skill_lists) do
      if not in_table(skillType,ordered_list) then
        unordered[#unordered+1] = skillType
      end
    end
    sort_table(unordered) --sort alphabetically
    for _,skillType in ipairs(unordered) do
      ordered_list[#ordered_list+1] = skillType
    end
    
    for _,sType in pairs(ordered_list) do
      local list = skill_lists[sType]
      if list then
        sort_table(list,'name')
        local typeDef = possibleSkillTypes[sType]
        desc = desc .. "\n" .. (typeDef and typeDef.name .. ":" or ucfirst(sType) .. ":") .. "\n"
        for _,skillInfo in pairs(list) do
          local skillID,value = skillInfo.skillID, skillInfo.value
          local skill = possibleSkills[skillID]
          if value then
            desc = desc .. "\t" .. skill.name .. (skill.max ~= 1 and ": " .. value or "") .. " - " .. skill.description .. "\n"
          end
        end --end for skillInfo
      end --end if list
    end --end ordered list for
  end
  
  --Abilities:
  local spells = merge_tables((class.spells or {}),(creature.spells or {}),self.player.spells)
  if count(spells) > 0 then
    desc = desc .. "\nAbilities:\n"
    for i,spell in ipairs(spells) do
      desc = desc .. "\t" .. possibleSpells[spell].name .. " - " .. possibleSpells[spell].description .. "\n"
    end
  end
  
  --Items:
  if (class.items and #class.items > 0) or (class.equipment and #class.equipment > 0) or (creature.items and #creature.items > 0) or (creature.equipment and #creature.equipment > 0) or (creature.money and creature.money > 0) or (class.money and class.money > 0) then
    desc = desc .. "\nItems:\n"
    local hasItems = false
    if (creature.items and #creature.items > 0) then --TODO: rewrite to use possible_inventory?
      for _,item in ipairs(creature.items) do
        local amount = item.amount or 1
        desc = desc .. "\t" .. (amount > 1 and amount .. " " or "") .. ucfirst(item.displayName or (amount > 1 and possibleItems[item.item].pluralName or possibleItems[item.item].name)) .. "\n"
        hasItems = true
      end
    end
    if (creature.equipment and #creature.equipment > 0) then
      for _,item in ipairs(class.equipment) do
        desc = desc .. "\t" .. ucfirst(item.displayName or possibleItems[item.item].name) .. "\n"
        hasItems=true
      end
    end
    if (class.items and #class.items > 0) then
      for _,item in ipairs(class.items) do
        local amount = item.amount or 1
        desc = desc .. "\t" .. (amount > 1 and amount .. " " or "") .. ucfirst(item.displayName or (amount > 1 and possibleItems[item.item].pluralName or possibleItems[item.item].name)) .. "\n"
        hasItems = true
      end
    end
    if (class.equipment and #class.equipment > 0) then
      for _,item in ipairs(class.equipment) do
        desc = desc .. "\t" .. ucfirst(item.displayName or possibleItems[item.item].name)  .. "\n"
      end
    end
  end
  if class.money or creature.money then
    desc = desc .."\t" .. get_money_name((class.money or 0)+(creature.money or 0)) .. "\n"
  end
  
  --Faction stuff:
  if (class.factions and #class.factions > 0) or (creature.factions and #creature.factions > 0) then
    desc = desc .. "\nFaction Membership:\n"
    for _,fac in ipairs(creature.factions or {}) do
      desc = desc .. "\t" .. currWorld.factions[fac].name .. currWorld.factions[fac].description  .. "\n"
    end
    for _,fac in ipairs(class.factions or {}) do
      desc = desc .. "\t" .. currWorld.factions[fac].name .. " - " .. currWorld.factions[fac].description  .. "\n"
    end
  end
  if (class.reputation and count(class.reputation) > 0) or (creature.reputation and count(creature.reputation) > 0 )then
    desc = desc .. "\nFaction Reputation:\n"
    local favs = {}
    for id,fav in pairs(creature.reputation or {}) do
      favs[id] = fav
    end
    for id,fav in pairs(class.reputation or {}) do
      favs[id] = (favs[id] or 0)+fav
    end
    for id,fav in pairs(favs) do
      desc = desc .. "\t" .. currWorld.factions[id].name .. ": " .. fav .. " - " .. currWorld.factions[id].description .. "\n"
    end
  end
  return desc
end