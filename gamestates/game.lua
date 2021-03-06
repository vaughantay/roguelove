game = {spellButtons={},sidebarCreats={},hoveringCreat=nil,hp=0,playerID=nil,eventualHP=0,targetHP=0,targetEventualHP=0,targetID=nil,batches={},batchesDark={}}

function game:enter()
  love.graphics.setFont(fonts.mapFontWithImages)
  love.mouse.setGrabbed(true)
end
  
function game:leave()
  love.graphics.setFont(fonts.textFont)
  love.mouse.setGrabbed(false)
end
  
function game:draw()
  local dtime1 = os.clock()
  --Pie:attach()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  if (prefs['noImages'] == true) then love.graphics.setFont(fonts.mapFont) else love.graphics.setFont(fonts.mapFontWithImages) end
  setColor(255,255,255,255)
  love.graphics.push()
  love.graphics.translate(output.camera.xMod,output.camera.yMod)
  love.graphics.setFont(fonts.mapFont)
	self:display_map(currMap)
  if Gamestate.current() ~= settings and Gamestate.current() ~= monsterpedia and action ~="dying" then
    self:print_cursor_game()
  end
  love.graphics.pop()
  love.graphics.push()
  love.graphics.scale((prefs['uiScale'] or 1),(prefs['uiScale'] or 1))
  self:display_minimap(currMap)
	love.graphics.setFont(fonts.textFont)
  self:print_messages()
  self:print_sidebar()
  self:print_target_sidebar()
  love.graphics.pop()
  if self.contextualMenu then self.contextualMenu:draw() end
  love.graphics.setFont(fonts.textFont)
  setColor(0,0,0,100)
  love.graphics.rectangle('fill',0,0,width,16)
  setColor(255,255,255,255)
  local branch = currWorld.branches[currMap.branch]
  love.graphics.printf((not branch.hideName and branch.name or "") .. (not branch.hideDepth and " " .. (branch.depthName or "Depth") .. " " .. currMap.depth or "") .. (currMap.name and (not branch.hideName or not branch.hideDepth) and ": " or "") .. (currMap.name or ""),0,0,width,"center")
  self.menuButton = output:closebutton(8,8,false,true,'menu')
  if action == "targeting" then
    local text = "Select Target"
    if actionResult and actionResult.name then
      text = text .. " for " .. actionResult.name
    end
    text = text .. "\nPress Escape to Cancel"
    --local w = fonts.textFont:getWidth(text)
    --setColor(0,0,0,100)
    --love.graphics.rectangle('fill',math.ceil(width/2-w/2)-8,32,w+16,16)
    setColor(0,0,0,255)
    love.graphics.printf(text,2,33,width,"center")
    setColor(255,255,255,255)
    love.graphics.printf(text,0,32,width,"center")
  end
	love.graphics.setFont(fonts.mapFont)
  if self.warning then self.warning:draw() end
  if self.blackAmt then
    setColor(0,0,0,self.blackAmt)
    love.graphics.rectangle('fill',0,0,width,height)
  end
  if self.popup then
    --Autosave before drawing, so the screenshot won't have the popup in it
    if currGame.autoSave == true then
      love.graphics.captureScreenshot("saves/" .. currGame.fileName .. ".png")
      save_game()
      currGame.autoSave = prefs['autosaveTurns']
    end
    if self.popup.blackout then
      setColor(0,0,0,185)
      love.graphics.rectangle('fill',0,0,width,height)
    end
    self.popup:draw()
    setColor(255,255,255,255)
  end
  --Pie:draw()
  --Pie:detach()
  --print('total draw time: ' .. os.clock()-dtime1)
  --local stats = love.graphics.getStats()
  --print('draw calls: ' .. tostring(stats.drawcalls))
end

function game:print_cursor_game()
  local mapWidth,mapHeight = output:get_map_dimensions()
  local width,height = love.graphics:getWidth(),love.graphics:getHeight()
  local tileSize = output:get_tile_size()
  local printX,printY = output:tile_to_coordinates(output.cursorX,output.cursorY)
  
	if (printX+tileSize >= 0 and printY+tileSize >= 0 and printX < width and printY < height and output.cursorX ~= 0 and output.cursorY ~= 0) then --if the cursor is contained in the map
    
    if (action ~= "targeting" or actionResult == nil) --if you're not targeting a spell, don't worry
      or (((actionResult.range == nil or actionResult.range >= math.floor(calc_distance(player.x,player.y,output.cursorX,output.cursorY))) and (actionResult.minRange == nil or actionResult.minRange >= math.floor(calc_distance(player.x,player.y,output.cursorX,output.cursorY))))--if you're targeting a spell, make sure it is in range, or has infinite range
        and (actionResult.projectile ~= true or player:can_shoot_tile(output.cursorX,output.cursorY))) then --if you're targeting a spell, also make sure there's LOS to the target, or the spell ignores LOS
      if prefs['noImages'] == true then
        setColor(255,255,0,255)
        love.graphics.rectangle("line",printX-2,printY+2,tileSize,tileSize)
        setColor(255,255,255,255)
      else
        setColor(255,0,0,125)
        if action == "moving" and player:can_move_to(output.cursorX,output.cursorY) then
          setColor(0,255,0,125)
          love.graphics.draw(images.uimovearrow,printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
        else
          love.graphics.draw(images.uicrosshair,printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
        end
      end
      
    else --if you can't reach the target
      if (#output.targetLine > 0) then --if you're targeting, draw the yellow box at the location you'll be targeting, even if it's not the cursor
        --Draw the "actual" target
        local pY = mapHeight/2-((output.camera.y-output.targetLine[#output.targetLine].y)*tileSize)
        local pX = mapWidth/2-((output.camera.x-output.targetLine[#output.targetLine].x)*tileSize)
        if pX ~= printX and pY ~= printY then
          if prefs['noImages'] == true then
            setColor(255,255,0,255)
            love.graphics.rectangle("line",pX-2,pY+2,tileSize,tileSize)
          else
            setColor(255,0,0,125)
            love.graphics.draw(images.uicrosshair,pX+16*(currGame.zoom or 1),pY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
          end
        end --end targetline if
      end
      
      --Draw the cursor crosshair:
      if prefs['noImages'] == true then
        setColor(255,0,0,255)
        love.graphics.rectangle("line",printX-2,printY+2,tileSize,tileSize)
        setColor(255,255,255,255)
      else
        setColor(255,255,255,100)
        love.graphics.draw(images.uicrosshair,printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
      end
    end
          setColor(255,255,255,255)
          love.graphics.setFont(fonts.mapFont)
          if debugMode then love.graphics.print("(" .. output.cursorX .. "," .. output.cursorY .. ")",printX,printY ) end
          love.graphics.setFont(fonts.mapFontWithImages)
		
    if (player:can_see_tile(output.cursorX,output.cursorY) and self.contextualMenu == nil and self.warning == nil) then
      local text = ""
      if (next(currMap.contents[output.cursorX][output.cursorY]) ~= nil) then
        for id, entity in pairs(currMap.contents[output.cursorX][output.cursorY]) do
          if entity.baseType == "creature" and player:does_notice(entity) then
            text = ucfirst(currMap.contents[output.cursorX][output.cursorY][id]:get_description()) .. (text == "" and "" or "\n----\n" .. text)
            self.hoveringCreat = entity
          elseif entity.baseType ~= "creature" and not entity.noDesc then
            if (text ~= "") then text = text .. "\n----\n" end
            if entity.baseType == "item" then
              text = text .. entity:get_name(true) .. "\n"
            end
            text = text .. ucfirst(currMap.contents[output.cursorX][output.cursorY][id]:get_description())
          end --end entity check
        end --end content for
      end --end content if
      for _, effect in pairs(currMap:get_tile_effects(output.cursorX,output.cursorY)) do
        if not effect.noDesc then
          if (text ~= "") then text = text .. "\n----\n" end
          text = text .. ucfirst(effect:get_description())
        end --end noDesc if
      end --end effect for
      
      if (currMap[output.cursorX][output.cursorY].baseType == "feature" and not currMap[output.cursorX][output.cursorY].noDesc) then
        if (text ~= "") then text = text .. "\n----\n" end
        text = text .. ucfirst(currMap[output.cursorX][output.cursorY]:get_description())
      end
      if text ~= "" then self:description_box(text,printX,printY) end
    end
  else --if you move the cursor to a spot you can't see and aren't targeting, clear the line display
    output.targetLine = {}
    output.targetTiles = {}
	end
end

function game:print_messages()
  --Move the buffer to the current turn's display
  for _,mid in ipairs(output.buffer) do
    output.toDisp[1][#output.toDisp[1]+1] = mid
  end
  output.buffer = {}
  
  local uiScale = (prefs['uiScale'] or 1)
	local cursor = math.ceil((love.graphics.getHeight()-16)/uiScale)
  local length = 0
  local width = math.ceil(love.graphics.getWidth()/uiScale-365-(prefs['noImages'] and 0 or 32))
	for id,disp in ipairs(output.toDisp) do
    for i=#disp,1,-1 do
      if (output.text[disp[i]] ~= nil and length<=10) then
        local _, tlines = fonts.textFont:getWrap(output.text[disp[i]],width)
        cursor = cursor - math.floor((prefs['fontSize']*1.25)*#tlines)
        setColor(0,0,0,255)
        love.graphics.printf(ucfirst(output.text[disp[i]]),15+2,cursor+1,width,"left")   --Print a shadow to make messages more readable: 
        setColor(255,255,255,255/((id < 3 and id) or id+1))
        love.graphics.printf(ucfirst(output.text[disp[i]]),15,cursor,width,"left")
        length = length+1*#tlines
      end --end text ~= nil
		end --end for ipairs(disp)
	end --end for ipairs(output.toDisp)
  setColor(255,255,255,255)
end

function game:print_sidebar()
  local uiScale = (prefs['uiScale'] or 1)
  local width, height = math.ceil(love.graphics:getWidth()/uiScale),math.ceil(love.graphics:getHeight()/uiScale)
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = math.ceil(mouseX/uiScale),math.ceil(mouseY/uiScale)
  local printX = width-365
  local sidebarW = 319
  local maxX = printX+sidebarW
  local printY = 48/uiScale
  local xPad = 5
  local yBonus = 0
  local whichFont = (prefs.plainFonts and fonts.textFont or fonts.buttonFont)
  local fontSize = (prefs.plainFonts and prefs['fontSize'] or fonts.buttonFont:getHeight())
  local fontPad = fontSize+2
  local smallButtons = (not prefs['bigButtons'] and (not prefs.plainFonts or fontSize<16))
  if not prefs.plainFonts then
    love.graphics.setFont(fonts.buttonFont)
    yBonus = 0
  end
  --Draw shaded background:
  setColor(20,20,20,200)
  love.graphics.rectangle("fill",printX,printY,maxX-printX+14,height-32-printY)
  setColor(255,255,255,255)
  if prefs['noImages'] ~= true then
    local bottomBorderY = math.ceil(height-48)
    local bottomLR = math.ceil(height-80)
    for x=printX,maxX-16,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.u,x,printY-18)
      love.graphics.draw(images.borders.borderImg,images.borders.d,x,bottomBorderY)
    end
    for y=printY,bottomBorderY,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.l,printX-18,y)
      love.graphics.draw(images.borders.borderImg,images.borders.r,maxX,y)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.l,printX-18,bottomLR)
    love.graphics.draw(images.borders.borderImg,images.borders.r,maxX,bottomLR)
    love.graphics.draw(images.borders.borderImg,images.borders.ul,printX-18,printY-18)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,maxX,printY-18)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,printX-18,bottomBorderY)
    love.graphics.draw(images.borders.borderImg,images.borders.lr,maxX,bottomBorderY)
  else
    setColor(20,20,20,200)
    love.graphics.rectangle("fill",printX-7,printY-7,maxX-printX+32,height-48) --sidebar background
    setColor(255,255,255,255)
    love.graphics.rectangle("line",printX-7,printY-7,maxX-printX+32,height-48) -- sidebar
  end
	love.graphics.printf(player.properName,printX,printY-4+yBonus,335,"center")
  local skillPoints = ""
  if player.skillPoints and player.skillPoints > 0 then skillPoints = " (+)" end
  local buttonWidth = whichFont:getWidth(keybindings.charScreen .. ") Level " .. player.level .. " " .. player.name .. skillPoints)

  local middleX = round(printX+335/2)
  printY=printY+fontPad
  self.characterButton = output:button(round(middleX-buttonWidth/2)-8,printY,buttonWidth+16,smallButtons,nil,nil,true)
	if skillPoints ~= "" then setColor(255,255,0,255) end
  love.graphics.printf(keybindings.charScreen .. ") Level " .. player.level .. " " .. player.name .. skillPoints,printX,printY+yBonus,335,"center")
  setColor(255,255,255,255) 
  if output.shakeTimer > 0 then
    love.graphics.push()
    local shakeDist = output.shakeDist*output.shakeTimer*2
    love.graphics.translate(random(-shakeDist,shakeDist),random(-shakeDist,shakeDist))
  end
  local ratio = self.hp/player:get_mhp()
  local hpR = 200-(200*ratio)
  local hpG = 200*ratio
  printY=printY+math.max(math.floor(fontPad*1.5),24)
	output:draw_health_bar(self.hp,player:get_mhp(),printX+xPad,printY,325,math.max(fontPad,16),{r=hpR,g=hpG,b=0,a=255})
 love.graphics.printf("Health: " .. math.ceil(self.hp) .. "/" .. player:get_mhp(),printX,printY+yBonus,332,"center")
  if output.shakeTimer > 0 then
    love.graphics.pop()
  end
  
  printY=printY+math.max(math.floor(fontPad*1.5),24)
  local mhp = player:get_max_mp()
  if (mhp > 0) then
    output:draw_health_bar(player.mp,player:get_max_mp(),printX+xPad,printY,325,math.max(fontPad,16),{r=100,g=0,b=100,a=255})
    love.graphics.printf("Magic: " .. player.mp .. "/" .. mhp,printX+xPad,printY+yBonus,332,"center")
    printY = printY+fontPad*2
  end
  
  setColor(255,255,255,255)
  if prefs.statsOnSidebar then
    love.graphics.print("Base Damage: " .. player.strength,printX+xPad,printY)
    love.graphics.print("Melee Skill: " .. player.melee,printX+xPad,printY+fontPad)
    love.graphics.print("Ranged Skill: " .. player.melee,printX+xPad,printY+fontPad*2)
    love.graphics.print("Dodge Skill: " .. player.dodging,printX+xPad,printY+fontPad*3)
    love.graphics.print("Magic Skill: " .. player.melee,printX+xPad,printY+fontPad*4)
    printY = printY+fontPad*5
  end
 
  self.spellButtons = {}
  local descBox = false
  local buttonPadding = (smallButtons and 20 or 36)
  --Button for inventory:
  if gamesettings.inventory then
    local invWidth = whichFont:getWidth(keybindings.inventory .. ") Inventory")
    local minX,minY=printX+xPad-2,printY
    local maxX,maxY=minX+invWidth+4,minY+(smallButtons and 16 or 32)
    self.spellButtons["inventory"] = output:button(minX,minY+2,(maxX-minX),smallButtons,nil,nil,true)
    if self.spellButtons["inventory"].hover == true then
      descBox = {desc="View and use items and equipment.",x=minX,y=minY}
    end
    love.graphics.print(keybindings.inventory .. ") Inventory",printX+xPad,printY-2+yBonus)
    printY = printY+buttonPadding
  end
  if gamesettings.crafting then
    local invWidth = whichFont:getWidth(keybindings.crafting .. ") Crafting")
    local minX,minY=printX+xPad-2,printY
    local maxX,maxY=minX+invWidth+4,minY+16
    self.spellButtons["crafting"] = output:button(minX,minY+2,(maxX-minX),smallButtons,nil,nil,true)
    if self.spellButtons["crafting"].hover == true then
      descBox = {desc="Make new items.",x=minX,y=minY}
    end
    love.graphics.print(keybindings.crafting .. ") Crafting",printX+xPad,printY-2+yBonus)
    printY = printY+buttonPadding
  end
  
 --Buttons for ranged attacks:
 local ranged_attacks = player:get_ranged_attacks()
  if #ranged_attacks > 0 then
    local ranged_text = keybindings.ranged .. ") Ranged: "
    local ranged_description_box = ""
    for i,attack_instance in ipairs(ranged_attacks) do
      local attack = rangedAttacks[attack_instance.attack]
      local item = attack_instance.item or nil
      ranged_text = ranged_text .. attack:get_name()
      if attack_instance.charges and attack.hide_charges ~= true then
        ranged_text = ranged_text .. " (" .. attack_instance.charges .. ")"
      end
      if i < #ranged_attacks then ranged_text = ranged_text .. ", " end
      ranged_description_box = ranged_description_box .. (i > 1 and "\n\n" or "") .. attack.name .. "\n" .. attack.description
    end --end ranged attack for
    local rangedWidth = whichFont:getWidth(ranged_text)
    local minX,minY=printX+xPad-2,printY
    local maxX,maxY=minX+rangedWidth+4,minY+(smallButtons and 16 or 32)
    local buttonType = (player.ranged_recharge_countdown and "disabled" or (actionResult and actionResult == attack and "hover" or nil))
    self.spellButtons["ranged"] = output:button(minX,minY+2,(maxX-minX),smallButtons,buttonType,nil,true)
    if player.ranged_recharge_countdown then
      ranged_text = ranged_text .. " \n(" .. player.ranged_recharge_countdown .. " turns to recharge)"
    end
    if self.spellButtons["ranged"].hover == true then
      descBox = {desc=ranged_description_box,x=minX,y=minY}
    end
    --[[if actionResult and actionResult.name == attack.name or (output.mouseX >= minX and output.mouseY >= minY and output.mouseX <= maxX and output.mouseY <= maxY and not player.ranged_recharge_countdown) then
      setColor(100,100,100,255)
      love.graphics.rectangle('fill',printX+xPad-2,printY+yPad,rangedWidth+4,16)
      setColor(255,255,255,255)
    end]]
    if player.ranged_recharge_countdown then
      setColor(100,100,100,255)
    end
    --love.graphics.rectangle('line',printX+xPad-2,printY+yPad,rangedWidth+4,16)
    love.graphics.print(ranged_text,printX+xPad,printY-2)
    if player.ranged_recharge_countdown then
      setColor(255,255,255,255)
    end
    --[[if attack.active_recharge then
      yPad = yPad+20
      local textWidth = fonts.buttonFont:getWidth(keybindings.recharge .. ") Recharge/Reload")
      maxX = minX+textWidth+4
      self.spellButtons["recharge"] = output:button(minX,minY+22,(maxX-minX),true,nil,nil,true)
      love.graphics.print(keybindings.recharge .. ") Recharge/Reload",printX+xPad,printY+yPad-2+yBonus)
    end]]
    printY = printY+buttonPadding
  end
  local featureActions = currMap:get_tile_actions(player.x,player.y,true)
  if #featureActions > 0 then
    local picktext = keybindings.action .. ") " .. (#featureActions > 1 and "Nearby Actions" or featureActions[1].text)
    local spellwidth = whichFont:getWidth(picktext)
    local minX,minY=printX+xPad-2,printY
    local maxX,maxY=minX+spellwidth+4,minY+16
    self.spellButtons["action"] = output:button(minX,minY+2,(maxX-minX),smallButtons,nil,nil,true)
    if self.spellButtons['action'].hover == true then
      descBox = {desc=(#featureActions > 1 and "Select a nearby action to perform." or featureActions[1].description),x=minX,y=minY}
    end
    love.graphics.print(picktext,printX+xPad,printY-2+yBonus)
  end
  printY = printY+buttonPadding
  local items = currMap:get_tile_items(player.x,player.y,true)
  if #items > 0 then
    local picktext = keybindings.pickup .. ") Pick Up " .. (#items > 1 and "Items" or items[1]:get_name())
    local spellwidth = whichFont:getWidth(picktext)
    local minX,minY=printX+xPad-2,printY
    local maxX,maxY=minX+spellwidth+4,minY+16
    self.spellButtons["pickup"] = output:button(minX,minY+2,(maxX-minX),smallButtons,nil,nil,true)
    if self.spellButtons['pickup'].hover == true then
      descBox = {desc=(#items > 1 and "Pick up items in the area." or items[1]:get_description()),x=minX,y=minY}
    end
    love.graphics.print(picktext,printX+xPad,printY-2+yBonus)
    printY = printY+buttonPadding
  end
  
  local spellcount = 1
  for _,spellID in pairs(player:get_spells()) do
    local spell = possibleSpells[spellID]
    if spell.innate ~= true and spell.target_type ~= "passive" then
      if spellcount == 1 then
        local buttonWidth = whichFont:getWidth(keybindings.spell .. ") Abilities:")
        local middleX = round(printX+335/2)
        self.allSpellsButton = output:button(round(middleX-buttonWidth/2)-8,printY,buttonWidth+16,smallButtons,nil,nil,true)
        love.graphics.printf(keybindings.spell .. ") Abilities:",printX,printY-4+yBonus,335,"center")
      end
      local spellwidth = whichFont:getWidth((prefs['spellShortcuts'] and spellcount .. ") " or "") .. spell.name)
      local minX,minY=printX+xPad-2,printY+(buttonPadding*spellcount)
      local maxX,maxY=minX+spellwidth+4,minY+(smallButtons and 16 or 32)
      local buttonType = ((player.cooldowns[spell.name] or spell:requires(player) == false) and "disabled" or (actionResult and actionResult.name == spell.name and "hover" or nil))
      self.spellButtons[spellID] = output:button(minX,minY+2,(maxX-minX),smallButtons,buttonType,nil,true)
      if self.spellButtons[spellID].hover == true then
        descBox = {desc=spell.name .. "\n" .. spell:get_description(),x=minX,y=minY}
      end
      if player.cooldowns[spell.name] or spell:requires(player) == false then
        setColor(100,100,100,255)
      end
      love.graphics.print((prefs['spellShortcuts'] and spellcount .. ") " or "") .. spell.name .. (player.cooldowns[spell.name] and " (" .. player.cooldowns[spell.name] .. " turns to recharge)" or ""),printX+xPad,printY+(buttonPadding*spellcount)-2+yBonus)
      if player.cooldowns[spell.name] or spell:requires(player) == false then
        setColor(255,255,255,255)
      end
      spellcount = spellcount + 1
    end
  end
  printY = printY+(buttonPadding*spellcount)
	
	if (next(player.conditions) ~= nil) then
    love.graphics.printf("Conditions:",printX,printY,335,"center")
		local conText = ""
		local count = 1
		for condition, turns in pairs(player.conditions) do
			if (conditions[condition].hidden ~= true) then
				if (count > 1) then conText = conText .. ", " end
				conText = conText .. conditions[condition].name
				count = count + 1
			end
		end
		love.graphics.printf(conText,printX+xPad,printY+fontSize,335)
    local currFont = love.graphics.getFont()
    local _,wrapText = currFont:getWrap(conText,335)
    printY = printY+fontSize*(#wrapText+2)
	end
	
  local yPad=0
	love.graphics.printf("You can see:",printX+5,printY+yPad,335,"center")
	local alreadyPrinted = {}
  local tileSize = 34
  yPad = yPad+(prefs['noImages'] and tileSize or math.max(fontSize,math.ceil(tileSize/2)))+8
  self.sidebarCreats = {}
  if player.sees ~= nil then
    for id, thing in ipairs(player.sees) do
      if (printY+yPad < (player.target and height-240 or height-64) and thing ~= player and in_table(thing,alreadyPrinted) == false and player:does_notice(thing)) then
        local minY,maxY,minX,maxX = printY+yPad-4,printY+yPad+tileSize,printX+5,printX+5+sidebarW
        self.sidebarCreats[thing] = {minX=minX*uiScale,maxX=maxX*uiScale,minY=minY*uiScale,maxY=maxY*uiScale}
        local trueHover = Gamestate.current() == game and (mouseX > minX and mouseX < maxX and mouseY > minY and mouseY < maxY)
        if (thing == self.hoveringCreat or trueHover) and not self.contextualMenu then
          if target == thing then
            setColor(255,255,255,125)
          else
            setColor(100,100,100,125)
          end
          love.graphics.rectangle('fill',minX,minY,maxX-minX,maxY-minY)
          if trueHover then
            --descBox = {desc=ucfirst(thing:get_description()),x=minX,y=minY}
            output:setCursor(thing.x,thing.y)
            self.hoveringCreat = thing
          else
            self.hoveringCreat = nil
          end
        elseif target == thing then
          setColor(175,175,175,125)
          love.graphics.rectangle('fill',minX,minY,maxX-minX,maxY-minY)
        end
        setColor(255,255,255,255)
        output.display_entity(thing,printX+5,printY+yPad,true,true)
        --[[if target == thing then
          if not prefs['noImages'] then
            setColor(255,0,0,125)
            love.graphics.draw(images.uicrosshair,printX+5+16,printY+yPad+16,0,1,1,16,16)
            setColor(255,255,255,255)
          else
            local tileSize = output:get_tile_size() --tileSize is 14 without images, 32 with
            setColor(100,50,100,150)
            love.graphics.rectangle("fill",printX+2,printY+yPad,tileSize,tileSize)
            setColor(255,255,255,255)
          end
        end]]
        setColor(255,255,255,255)
        local currFont = love.graphics.getFont()
        if (prefs['noImages']) then
          local text = "- " .. thing:get_name(true) .. " (" .. thing:get_health_text(false) .. ")"
          local width, tlines = currFont:getWrap(text,300)
          love.graphics.printf(text,printX+25,printY+yPad+(#tlines == 1 and 0 or -7),300,"left")
        else
          local text = thing:get_name(true) .. " (" .. thing:get_health_text(false) .. ")"
          local width, tlines = currFont:getWrap(text,300)
          love.graphics.printf(text,printX+42,printY+(#tlines == 1 and 0 or -8)+yPad,300,"left")
        end
        yPad = yPad + tileSize+math.ceil(fontSize/2)
        table.insert(alreadyPrinted,thing)
      end
    end
  end --end player sees if
  setColor(255,255,255,255)
  if descBox then
    self:description_box(descBox.desc,descBox.x,descBox.y)
  end
end

function game:print_target_sidebar()
  local uiScale = (prefs['uiScale'] or 1)
  if (target ~= nil) then
    local width, height = love.graphics:getWidth(),love.graphics:getHeight()
    local printX = math.ceil(width/uiScale)-365
    local maxX = printX+319
    local printY = math.ceil(height/uiScale)-225
    local maxY = ((next(target.conditions) == nil and printY+65 or printY+95))
    local xPad = 5
    local yBonus = 2
    local fontPadding = 15
    if not prefs.plainFonts then
      love.graphics.setFont(fonts.buttonFont)
      yBonus = 0
    else
      fontPadding = prefs['fontSize']+2
    end
		if (target.properName ~= nil) then
			love.graphics.printf(target.properName,printX,printY,335,"center")
			printY = printY+fontPadding
		end
		love.graphics.printf("Level " .. target.level .. " " .. ucfirst(target.name),printX,printY,335,"center")
    if target.master then 
      printY = printY+fontPadding
      love.graphics.printf("Master: " .. target.master:get_name(false,true),printX,printY,335,"center")
    end
    output:draw_health_bar(self.targetHP,target:get_mhp(),printX+xPad,printY+fontPadding+5,325,16)
    love.graphics.printf("Health: " .. math.ceil(self.targetHP) .. "/" .. target:get_mhp(),printX+xPad,printY+fontPadding+2+yBonus,335,"center")
    
    --Melee attack hit chance:
    local weapons = player:get_equipped_in_slot('weapon')
    local weapCount = count(weapons)
    printY = printY+fontPadding*3
    if weapCount == 0 then
      love.graphics.print("Hit chance: " .. calc_hit_chance(player,target) .. "%",printX+xPad,printY)
      printY = printY+fontPadding
    elseif weapCount == 1 then
      love.graphics.print(weapons[1]:get_name(true) .. " hit chance: " .. calc_hit_chance(player,target,player.equipment.weapon[1]) .. "%",printX+xPad,printY)
      printY = printY+fontPadding
    else
      for _,weap in pairs(weapons) do
        love.graphics.printf(weap:get_name(true) .. " hit chance" .. (weap.ranged_attack and " (melee)" or "") .. ": " .. calc_hit_chance(player,target,weap) .. "%",printX+xPad,printY,335,"left")
        printY = printY+fontPadding
      end
    end --end weapon count if
    
    --Ranged attack hit chance:
    local ranged_attacks = player:get_ranged_attacks()
    if #ranged_attacks > 0 then
      local dist = calc_distance(player.x,player.y,target.x,target.y)
      for i,attack_instance in ipairs(ranged_attacks) do
        local attack = rangedAttacks[attack_instance.attack]
        local hit_chance = attack:calc_hit_chance(player,target,attack.item)
        local rangedText = attack:get_name() .. " hit chance: "
        if hit_chance < 1 then
          rangedText = rangedText .. "Impossible"
        else
          rangedText = rangedText .. hit_chance .. "%"
        end
        love.graphics.printf(rangedText,printX+xPad,printY+(i-1)*fontPadding,335)
      end --end ranged attack for
    end --end if #ranged_attacks> 0

    local yPadNow = fontPadding*#ranged_attacks
    love.graphics.print("Chance to Be Hit: " .. calc_hit_chance(target,player) .. "%",printX+xPad,printY+yPadNow)
		if (next(target.conditions) ~= nil) then
      love.graphics.printf("Conditions:",printX,printY+fontPadding*2+yPadNow,335,"center")
      local conText = ""
      local count = 1
      for condition, turns in pairs(target.conditions) do
        if (conditions[condition].hidden ~= true) then
          if (count > 1) then conText = conText .. ", " end
          conText = conText .. conditions[condition].name
          count = count + 1
        end
      end
      love.graphics.printf(conText,printX+5,printY+fontPadding*3+yPadNow,335)
    end
	end
end

function game:display_map(map)
  local mapWidth,mapHeight = output:get_map_dimensions()
  local width,height = love.graphics:getWidth(),love.graphics:getHeight()
  local tileSize = output.get_tile_size()*(currGame.zoom or 1)
  local creaturesToDisplay = {}
  local featuresToDisplay = {}
  local projectilesToDisplay = {}
  local alwaysDisplay = {}
  local effectsToDisplay = {}
  local lightsToDisplay = {}
  local terrainStringUnseen = ""
  local terrainStringSeen = ""
  if not player.seeTiles then refresh_player_sight() end
  local seeTiles = player.seeTiles
  local coordMap = output.coordinate_map
  
  --pClock:start()
  local xMod,yMod = output.camera.xMod,output.camera.yMod
	for y = 1, map.height, 1 do
		for x = 1, map.width, 1 do
      local coords = (coordMap and coordMap[x] and coordMap[x][y])
      local printX,printY = 0,0
      if coords then
        printX,printY=math.ceil(coords.x),math.ceil(coords.y)
      else
        printX,printY=output:tile_to_coordinates(x,y)
      end
      if (printY+tileSize+yMod >= 0 and printY+yMod <= height and printX+tileSize+xMod >= 0 and printX+xMod <= width) then
        --pClock:flag('after tiletocoords')
        local seen = seeTiles[x][y]
        --if seen == nil then seen = player:can_see_tile(x,y) end
        --pClock:flag('after seetile')
				if (seen or map.seenMap[x][y] == true) then
          map.seenMap[x][y] = true
            
          if prefs['noImages'] == true then
            if map.images == nil then map:refresh_images() end --even though there are no actual images to refresh, call this because some tiles need it
            --Display order: 1) creature, 2) feature (with priority to some), 3) base tile
            local creat = currMap:get_tile_creature(x,y)
            local noFloor = false
            if creat ~= false and (seen == true or player:can_sense_creature(creat,true)) and player:does_notice(creat) then -- creatures get first priority to display if you can see them
              output.display_entity(creat,printX,printY,seen)
              noFloor = true
            elseif (#map:get_tile_features(x,y) > 0 and map[x][y] ~= ">" and map[x][y] ~= "<") then -- if no creatures, make sure we have contents to loop through
              local f = map:get_tile_features(x,y)
              local dispCont = nil
              for id, content in pairs(f) do
                if not content.noDisp then dispCont = content end
                if content.alwaysDisplay == true then -- display corpses first
                  break
                end -- end display if
              end -- end for
              if dispCont then
                noFloor = true
                output.display_entity(dispCont,printX,printY,seen)
              end
            end
            if not noFloor then
              if (type(map[x][y]) == "string") then --if there are no creatures or features, just print the tile
                if seen == false and map[x][y] ~= "<" then
                  setColor(50,50,50,255)
                elseif map[x][y] == "<" then
                  setColor(255,255,0,255)
                elseif map.tileset and map[x][y] == "." and tilesets[map.tileset].floorColor then
                  local tc = tilesets[map.tileset].floorColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                elseif map.tileset and map[x][y] == "#" and tilesets[map.tileset].wallColor then
                  local tc = tilesets[map.tileset].wallColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                elseif map.tileset and tilesets[map.tileset].textColor then
                  local tc = tilesets[map.tileset].textColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                else
                  setColor(255,255,255,255)
                end
                  love.graphics.print(map[x][y],printX,printY)
              else
                output.display_entity(map[x][y],printX,printY,seen)
              end
            end
          else --Display for images enabled:
            if map.images == nil then map:refresh_images() end
            --Display order: 1) Base tile, 2)Features, 3)Creature
            -- Display tile first:
            local img = false
            if tilesets[map.tileset].tilemap and map.images[x][y] and map.images[x][y].image then
              img = images[map.images[x][y].image]
            else
              img = images[map.images[x][y]]
            end
            if map.tileset and img and img ~= -1 then
              --Set color depending on Fog of War
              if seen == false then setColor(100,100,100,255)
              else setColor(255,255,255,255) end
              --pClock:clearTime()
              if tilesets[map.tileset].tilemap and map[x][y] == "#" then
                if seen then
                  if not self.batches[img] then
                    self.batches[img] = love.graphics.newSpriteBatch(img,map.width*map.height)
                  end
                  self.batches[img]:add(quads[map.images[x][y].direction],printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
                else
                  if not self.batchesDark[img] then
                    self.batchesDark[img] = love.graphics.newSpriteBatch(img,map.width*map.height)
                  end
                  self.batchesDark[img]:add(quads[map.images[x][y].direction],printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
                end
                --love.graphics.draw(img,quads[map.images[x][y].direction],printX+16,printY+16,0,1,1,16,16)
              else --uses individual images? draw the image
                if seen then
                  if not self.batches[img] then
                    self.batches[img] = love.graphics.newSpriteBatch(img,map.width*map.height)
                  end
                  self.batches[img]:add(printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
                else
                  if not self.batchesDark[img] then
                    self.batchesDark[img] = love.graphics.newSpriteBatch(img,map.width*map.height)
                  end
                  self.batchesDark[img]:add(printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
                end
                --love.graphics.draw(img,printX+16,printY+16,0,1,1,16,16)
              end
            else
              if seen == false then setColor(50,50,50,255)
              else setColor(255,255,255,255) end
              love.graphics.print(map[x][y],printX,printY)
            end --end tile set or not if
            --pClock:flag('after batching etc')
              
            --If there's a special tile:
            if type(map[x][y]) == "table" then 
              featuresToDisplay[#featuresToDisplay+1] = {feature=map[x][y],x=printX,y=printY,seen=seen}
              --output.display_entity(map[x][y],printX,printY,seen)
            end
            --pClock:flag('after special tile display')
              
            --Then display features:
            for _,content in pairs (currMap.contents[x][y]) do
              --Don't display creatures again
              if content.baseType ~= "creature" then
                if content.alwaysDisplay == true then --don't display "alwaysdisplay" content yet, save it for later
                  alwaysDisplay[content] = {printX,printY,seen} --store the content
                else
                  featuresToDisplay[#featuresToDisplay+1] = {feature=content,x=printX,y=printY,seen=seen}
                  --output.display_entity(content,printX,printY,seen)
                end
              end
            end --end for
            --pClock:flag('after figuring out what features to do')
              --[[Display the "alwaysdisplay" content now, so it'll always be on top
              for _,content in pairs(alwaysDisplay) do
                output.display_entity(content,printX,printY,seen)
              end]]
              
            --[[Finally, display creatures
            local creat = currMap:get_tile_creature(x,y)
            if creat ~= false and (seen == true or player:can_sense_creature(creat,true)) and player:does_notice(creat) then
              creaturesToDisplay[creat] = {printX,printY,seen}
            end]]
          end --end no images check
            
          --Display lights:
          if (seen) then
            if type(currMap.lightMap[x][y]) == "table" --[[and calc_distance(x,y,player.x,player.y) > player:get_perception()]] then
              lightsToDisplay[#lightsToDisplay+1] = {x=x,y=y,color=currMap.lightMap[x][y]}
            end
          end --end seen if for effects and projectiles
          --pClock:flag('after lights')
        else --if you can't see or haven't seen an area, still check to see if there's a creature and you can sense it through other means
          local creat = currMap:get_tile_creature(x,y)
          if creat ~= false and player:can_sense_creature(creat,true) and player:does_notice(creat) then
            creaturesToDisplay[creat] = {printX,printY,false}
          end
				end --end if seen or has seen
      end --end width check
      setColor(255,0,0,125) --I'm not sure why this is here...
      if currMap.lMap and currMap.lMap[x] and currMap.lMap[x][y] then love.graphics.print(currMap.lMap[x][y],printX,printY) end --This was for testing the dijkstra map of the final boss ghost. Re-enable for later testing if it's acting weird
		end --end x for
	end --end y for

  --pClock:clearTime()
  --Figure out what creatures to display:
  for _,creat in pairs(currMap.creatures) do
    if player:does_notice(creat) and (player:can_sense_creature(creat) or (creat.fromX and creat.fromY and creat.moveTween and player:can_see_tile(creat.fromX,creat.fromY))) then
      local printX,printY = output:tile_to_coordinates(creat.x,creat.y)
      if (printY+tileSize+yMod >= 0 and printY+yMod <= height and printX+tileSize+xMod >= 0 and printX+xMod <= width) then
        creaturesToDisplay[creat] = {printX,printY,true}
      end
    end
  end
  
  --Figure out what projectiles and effects to display:
  for _,p in pairs(currMap.projectiles) do
    if player:can_see_tile(p.x,p.y) then
      local printX,printY = output:tile_to_coordinates(p.x,p.y)
      if (printY+tileSize+yMod >= 0 and printY+yMod <= height and printX+tileSize+xMod >= 0 and printX+xMod <= width) then
        projectilesToDisplay[p] = {printX,printY,true}
      end
    end
  end --end projectile for
  for _,e in pairs(currMap.effects) do
    if not e.noDisp and player:can_see_tile(e.x,e.y) then
      local printX,printY = output:tile_to_coordinates(e.x,e.y)
      if (printY+tileSize+yMod >= 0 and printY+yMod <= height and printX+tileSize+xMod >= 0 and printX+xMod <= width) then
        effectsToDisplay[e] = {printX,printY,true}
      end
    end
  end --end effect for
  --pClock:flag('calculate what to display')
  
  --local stats = love.graphics.getStats()
 --print('draw calls before batches: ' .. tostring(stats.drawcalls))
  --Display all stuff that was previously put off:
  setColor(100,100,100,255)
  for _,batch in pairs(self.batchesDark) do
    love.graphics.draw(batch)
    batch:clear()
  end
  setColor(255,255,255,255)
  for _,batch in pairs(self.batches) do
    love.graphics.draw(batch)
    batch:clear()
  end
  --stats = love.graphics.getStats()
  --print('draw calls after batches: ' .. tostring(stats.drawcalls))
  --pClock:clearTime()
  for _,feat in ipairs(featuresToDisplay) do
    output.display_entity(feat.feature,feat.x,feat.y,feat.seen,nil,(currGame.zoom or 1))
  end
  for f,args in pairs(alwaysDisplay) do
    output.display_entity(f,args[1],args[2],args[3],nil,(currGame.zoom or 1))
  end
  --stats = love.graphics.getStats()
  --print('draw calls after features: ' .. tostring(stats.drawcalls))
  --pClock:flag('feature display')
  for creat,args in pairs(creaturesToDisplay) do
    output.display_entity(creat,args[1],args[2],args[3],nil,(currGame.zoom or 1))
  end
  --stats = love.graphics.getStats()
  --print('draw calls after creatures: ' .. tostring(stats.drawcalls))
  --pClock:flag('creature display')
  for feat,args in pairs(projectilesToDisplay) do
    output.display_entity(feat,args[1],args[2],args[3],nil,(currGame.zoom or 1))
  end
  --stats = love.graphics.getStats()
  --print('draw calls after projectiles: ' .. tostring(stats.drawcalls))
  --pClock:flag('projectile display')
  for eff,args in pairs(effectsToDisplay) do
    output.display_entity(eff,args[1],args[2],args[3],nil,(currGame.zoom or 1))
  end
  --stats = love.graphics.getStats()
  --print('draw calls after effects: ' .. tostring(stats.drawcalls))
  --pClock:flag('effect display')
  for _,args in pairs(lightsToDisplay) do
    local printX,printY = output:tile_to_coordinates(args.x,args.y)
    local color = args.color
    setColor(color.r,color.g,color.b,(color.a or 25))
    local tileSize = output:get_tile_size()
    love.graphics.rectangle('fill',printX,printY,tileSize,tileSize)
  end
  
  --The arrow on the upstairs:
  if map[map.stairsUp.x][map.stairsUp.y] == "<" and map.seenMap[map.stairsUp.x][map.stairsUp.y] then
    local printX,printY=output:tile_to_coordinates(map.stairsUp.x,map.stairsUp.y)
    setColor(255,255,255,255)
    love.graphics.draw(images.uistairsuparrow,printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
  end
  --stats = love.graphics.getStats()
  --print('draw calls after lights: ' .. tostring(stats.drawcalls))
  --pClock:flag('entity display')
  --countclock = (countclock or 0) + 1
  --if countclock == 100 then pClock:stop() countclock = 0 end
  
  if action ~= "dying" then
    local tileSize = output:get_tile_size() --tileSize is 14 without images, 32 with
    for tileCount,tile in ipairs(output.targetLine) do
      if (tile.x ~= player.x or tile.y ~= player.y) then
        local printX,printY = output:tile_to_coordinates(tile.x,tile.y)
        if tileCount ~= #output.targetLine then
          if prefs['noImages'] == true then
            setColor(255,255,0,150)
            love.graphics.rectangle("fill",printX-2,printY+2,tileSize,tileSize)
            setColor(255,255,255,255)
          else
            setColor(255,255,0,150)
            love.graphics.draw(images.uidot,printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
            setColor(255,255,255,255)
          end
        end
      end -- end checking the end of the line
    end --end for
    for _,tile in pairs(output.targetTiles) do
      local printX,printY = output:tile_to_coordinates(tile.x,tile.y)
      local tileSize = output:get_tile_size() --tileSize is 14 without images, 32 with
      if prefs['noImages'] == true then
        setColor(100,50,100,150)
        love.graphics.rectangle("fill",printX-2,printY+2,tileSize,tileSize)
        setColor(255,255,255,255)
      else
        setColor(100,50,100,125)
        love.graphics.draw(images.uicrosshair,printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
      end
    end --end for
    for _,tile in pairs(output.potentialTargets) do
      local creat = currMap:get_tile_creature(tile.x,tile.y)
      if not creat or player:does_notice(creat) then
        local printX,printY = output:tile_to_coordinates(tile.x,tile.y)
        local tileSize = output:get_tile_size() --tileSize is 14 without images, 32 with
        if prefs['noImages'] == true then
          setColor(100,100,100,255)
          love.graphics.rectangle("line",printX-2,printY+2,tileSize,tileSize)
          setColor(255,255,255,255)
        else
          setColor(255,255,0,75)
          love.graphics.draw(images.uicrosshair,printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
        end
      end --end notice if
    end --end for
  end --end not dying display
end --end display map function

function game:display_minimap(map)
  if not prefs['minimap'] then return false end
  local uiScale = (prefs['uiScale'] or 1)
  local baseX,baseY=math.ceil(16/uiScale),math.ceil(32/uiScale)
  local tileSize = (prefs['noImages'] and 6 or 4)
  local width,height = tileSize*map.width,tileSize*map.height
  local seeTiles = player.seeTiles
  local mouseX,mouseY = love.mouse.getPosition()
  local mouseOver = false
  if Gamestate.current() == game and mouseX > baseX*uiScale and mouseX < (baseX+width)*uiScale and mouseY > baseY*uiScale and mouseY < (baseY+height)*uiScale then 
    mouseOver = true
  end
  
  --Calculate the boundaries of what the player has seen
  local nearestX,nearestY,farthestX,farthestY=map.width,map.height,1,1
  for x=1,map.width,1 do
    for y=1,map.height,1 do
      if currMap.seenMap[x][y] == true then
        if x < nearestX then nearestX = x end
        if x > farthestX then farthestX = x end
        if y < nearestY then nearestY = y end
        if y > farthestY then farthestY = y end
      end
    end --end fory
  end --end forx
  
  local xMid, yMid = farthestX-math.floor((farthestX-nearestX)/2), farthestY-math.floor((farthestY-nearestY)/2)
  local xMod,yMod = (math.floor(map.width/2)-xMid)*tileSize, (math.floor(map.height/2)-yMid)*tileSize

  --[[local xMod,yMod = 0,0
  local xModNear = (math.floor(map.width/2)-nearestX)*4
  local yModNear = (math.floor(map.height/2)-nearestY)*4
  local xModFar = (math.floor(map.width/2)-farthestX)*4
  local yModFar = (math.floor(map.height/2)-farthestY)*4
  
  if math.abs(xModNear) > math.abs(xModFar) then xMod = xModNear else xMod = xModFar end
  if math.abs(yModNear) > math.abs(yModFar) then yMod = yModNear else yMod = yModFar end]]
  
  --Draw the border:
  setColor(25,25,25,math.ceil((prefs['noImages'] and 225 or 150)*(mouseOver and 0.25 or 1)))
  love.graphics.rectangle('fill',baseX-tileSize,baseY-tileSize,width+tileSize,height+tileSize)
  if map.tileset and tilesets[map.tileset].textColor then
    local tc = tilesets[map.tileset].textColor
    setColor(tc.r,tc.g,tc.b,math.ceil(tc.a*(mouseOver and 0.25 or 1)))
  end
  setColor(150,150,150,math.ceil(255*(mouseOver and 0.25 or 1)))
  love.graphics.rectangle('line',baseX-tileSize,baseY-tileSize,width+tileSize,height+tileSize)
  
  baseX,baseY = baseX+xMod-(prefs['noImages'] and 3 or 16),baseY+yMod-(prefs['noImages'] and 3 or 16)
  love.graphics.setFont(fonts.miniMapFont)
  for x=1,map.width,1 do
    for y=1,map.width,1 do
      local seen = seeTiles[x][y]
      if map.seenMap[x][y] == true then
        if prefs['noImages'] == true then
          local printX,printY=baseX+x*6,baseY+y*6
          
          if player.x == x and player.y == y then
            setColor(255,255,255,math.ceil(255*(mouseOver and 0.25 or 1)))
            love.graphics.print("@",printX,printY)
          elseif map[x][y] == "#" then
            if seen then setColor(100,100,100,math.ceil(255*(mouseOver and 0.25 or 1))) else setColor(50,50,50,math.ceil(255*(mouseOver and 0.25 or 1))) end
            love.graphics.print("#",printX,printY)
          elseif map:tile_has_feature(x,y,'exit') then
            setColor(255,255,0,math.ceil(255*(mouseOver and 0.25 or 1)))
            love.graphics.print(">",printX,printY)
          elseif currMap:get_tile_creature(x,y) and seen then
            setColor(255,0,0,math.ceil(255*(mouseOver and 0.25 or 1)))
            love.graphics.print("x",printX,printY)
          elseif type(map[x][y]) == "table" then
            local tc= map[x][y].color
            setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),math.ceil(255*(mouseOver and 0.25 or 1)))
            love.graphics.print("·",printX,printY)
          elseif map:get_blocking_feature(x,y) then
            local bf = map:get_blocking_feature(x,y)
            local tc= bf.color
            setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),math.ceil(255*(mouseOver and 0.25 or 1)))
            love.graphics.print("o",printX,printY)
          elseif map[x][y] == "." then
            if map.tileset and tilesets[map.tileset].textColor then
              local tc = tilesets[map.tileset].textColor
              setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),math.ceil(255*(mouseOver and 0.25 or 1)))
            else
              if seen then setColor(150,150,150,math.ceil(255*(mouseOver and 0.25 or 1))) else setColor(75,75,75,math.ceil(255*(mouseOver and 0.25 or 1))) end
            end
            love.graphics.print("·",printX,printY)
          end --end tile type if
          --[[if player.x == x and player.y == y then
            setColor(255,255,255,255)
            love.graphics.print('@',printX,printY)
          elseif type(map[x][y]) == "string" then
            if map[x][y] ~= "<" and map.tileset and tilesets[map.tileset].textColor then
              local tc = tilesets[map.tileset].textColor
              setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),255)
            elseif map[x][y] == "<" then
              setColor(255,255,0,255)
            end
            love.graphics.print(map[x][y],printX,printY)
          else
            output.display_entity(map[x][y],printX,printY,seen)
          end]]
        else --minimap for image mode
          local printX,printY=baseX+x*4,baseY+y*4
          if player.x == x and player.y == y then
            setColor(255,255,255,math.ceil(200*(mouseOver and 0.25 or 1)))
          elseif map[x][y] == "#" then
            if seen then setColor(125,125,125,math.ceil(200*(mouseOver and 0.25 or 1))) else setColor(50,50,50,math.ceil(200*(mouseOver and 0.25 or 1))) end
          elseif map:tile_has_feature(x,y,'exit') then
            setColor(255,255,0,math.ceil(200*(mouseOver and 0.25 or 1)))
          elseif currMap:get_tile_creature(x,y) and seen then
            setColor(255,0,0,math.ceil(200*(mouseOver and 0.25 or 1)))
          elseif type(map[x][y]) == "table" then
            local tc= map[x][y].color
            setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),math.ceil(200*(mouseOver and 0.25 or 1)))
          elseif map:get_blocking_feature(x,y) then
            local bf = map:get_blocking_feature(x,y)
            local tc= bf.color
            setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),math.ceil(200*(mouseOver and 0.25 or 1)))
          elseif map[x][y] == "." then
            if map.tileset and tilesets[map.tileset].textColor then
              local tc = tilesets[map.tileset].textColor
              setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),math.ceil(200*(mouseOver and 0.25 or 1)))
            else
              if seen then setColor(200,200,200,math.ceil(200*(mouseOver and 0.25 or 1))) else setColor(75,75,75,math.ceil(200*(mouseOver and 0.25 or 1))) end
            end
          end --end tile type if
          love.graphics.draw(images['effectparticlemed'],printX,printY)
        end
      end --end if seenMap
    end --end fory
  end --end forx
  setColor(255,255,255,255)
  love.graphics.setFont(fonts.mapFont)
end

function game:update(dt)
  if game.newGhost then player = game.newGhost game.newGhost = nil end
  local utime = os.clock()
  if output.shakeTimer > 0 then
    output.shakeTimer = output.shakeTimer - dt
  end
  if player.hp ~= self.hp then
    if self.playerID == player.id then
      if self.eventualHP ~= player.hp then
        self.eventualHP = player.hp
        self.hpTween = tween(.25,self,{hp=player.hp},'linear',function() self.hp = player.hp end)
      end
    else
      self.playerID = player.id
      self.hp = player.hp
      if self.hpTween then Timer.cancel(self.hpTween) end
    end
  end
  if target and self.target and target == self.target and target.hp ~= self.targetHP then
    if self.targetEventualHP ~= target.hp then
      self.targetEventualHP = target.hp
      self.targetHPtween = tween(.25,self,{targetHP=target.hp},'linear',function() if target then self.targetHP = target.hp end end)
    end
  elseif target and (not self.target or self.target ~= target) then
    self.target = target
    self.targetHP = target.hp
    if self.targetHPtween then Timer.cancel(self.targetHPtween) end
  elseif not target and self.target then
    self.target = nil
  end
  
  --If dying, gradually reduce the visible area
  if (action == "dying") then
    if player.perception >= 1 then
      refresh_player_sight()
    end
	end
	if player.hp < 1 and player.id == "ghost" and action ~= "dying" then
		action = "dying"
	end
  
  if self.popup then return end
  
  --Auto-move along player path
  if (player.path ~= nil) then
    if player.hp < player.pathStartHP then
      output:out("Damaged! Cancelling movement!")
      player.path = nil
      player.ignoring = {}
      player.pathStartHP = nil
		elseif player.path and count(player.path) > 0 and move_player(player.path[1]["x"],player.path[1]["y"]) then
      if player.path ~= nil then
        table.remove(player.path,1)
        if (#player.path == 0) then
          player.path = nil
          player.ignoring = {}
          player.pathStartHP = nil
        end
      end
    else
      output:out("Hazard in path! Cancelling movement!")
      player.path = nil
      player.ignoring = {}
      player.pathStartHP = nil
    end
		if (player.path and player.sees and #player.sees > 0) then
      for _, creat in pairs(player.sees) do
        if creat ~= player and creat:is_enemy(player) and not in_table(creat,player.ignoring) then
          output:out(creat.name .. " spotted! Cancelling movement.")
          player.path = nil
          player.ignoring = {}
          player.pathStartHP = nil
          break
        end
      end
		end
	end --end player path if

  self.moveBlocked = false
  --Run effects,creatures and projectiles
	for _, e in pairs(currMap.effects) do --run effects code:
		e:update(dt)
    if e.stopsInput and player:can_see_tile(e.x,e.y) then self.moveBlocked = true end
	end
  for _, p in pairs(currMap.projectiles) do
    p:update(dt)
    if p.stopsInput and player:can_see_tile(p.x,p.y) then self.moveBlocked = true end
  end
  for _, c in pairs(currMap.creatures) do
    c:update(dt)
    if c.stopsInput and player:can_see_tile(c.x,c.y) then self.moveBlocked = true end
  end
  if self.moveBlocked == false and self.waitingToAdvance == true then
    self.waitingToAdvance = false
    advance_turn()
  end
  if count(currMap.lights) > 0 then
    currMap:refresh_lightMap(true)
  end
  
  --Untarget if targeting self or unseen creature
	if (target == player or (target and player:can_sense_creature(target) == false)) then target = nil end
  player.target = target
  if self.contextualMenu and not player:can_see_tile(self.contextualMenu.target.x,self.contextualMenu.target.y) then
    self.contextualMenu = nil
  end
    
  --Handle mouse cursor:
	local x,y = love.mouse.getPosition()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local mapWidth,mapHeight = width-32,height-32
  local tileSize = prefs['noImages'] and 14 or 32
	if (x ~= output.mouseX or y ~= output.mouseY) then -- if you're targeting with keyboard, only do this if the mouse has moved
		output.mouseX = x
		output.mouseY = y
    if self.contextualMenu and x >= self.contextualMenu.x and x <= self.contextualMenu.maxX and y >= self.contextualMenu.y and y <= self.contextualMenu.maxY then
      self.contextualMenu:mouseSelect(x,y)
		elseif self.warning == nil then
      local uiScale = (prefs['uiScale'] or 1)
      local sideBarX = (math.ceil(love.graphics:getWidth()/uiScale)-365)*uiScale
      if Gamestate.current() == game and (x < sideBarX and y < mapHeight and x > 17 and y > 17) then
        local tileX,tileY = output:coordinates_to_tile(x,y)
        if (currMap[tileX] ~= nil and currMap[tileX][tileY] ~= nil) then
          local retarget = true
          if action == "targeting" and actionResult ~= nil and (actionResult.get_potential_targets ~= nil or actionResult.target_type == "creature") and #output.potentialTargets > 0 then
            retarget = false
            for _,t in ipairs(output.potentialTargets) do
              if tileX == t.x and tileY == t.y then
                retarget = true
                break
              end
            end
          end
          if retarget == true then
            output:setCursor(tileX,tileY,false,true)
          end
        end
      end
		end
  elseif (output.cursorX == 0 or output.cursorY == 0) and action == "targeting" then --if the cursor isn't set on anything, set it to the player
    output:setCursor(player.x,player.y,true)
	end --end if output.mouseX
  if self.contextualMenu then
    output:setCursor(self.contextualMenu.target.x,self.contextualMenu.target.y)
  elseif prefs.mouseMovesMap and love.window.hasFocus() then
    if x < 17 then output:move_camera(-1,0) end
    if y < 17 then output:move_camera(0,-1) end
    if x > width-17 then output:move_camera(1,0) end
    if y > height-17 then output:move_camera(0,1) end 
  end
  if action == "targeting" and actionResult ~= nil then
    if #output.potentialTargets == 0 then
      if actionResult.get_potential_targets ~= nil then
        output.potentialTargets = actionResult:get_potential_targets(player)
      elseif actionResult.target_type == "creature" then
        for _,creat in pairs(player.sees) do
          if player:does_notice(creat) and (actionResult.range == nil or calc_distance(player.x,player.y,creat.x,creat.y) <= actionResult.range) then
            output.potentialTargets[#output.potentialTargets+1] = {x=creat.x,y=creat.y}
          end --end range if
        end --end creature for
      end --end default-or-not if
    end --end if count == 0 if
  elseif #output.potentialTargets > 0 then
    output.potentialTargets = {}
  end
  --print("update time: " .. os.clock()-utime)
end

function game:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  if self.popup then
    if self.popup.afterFunc then self.popup.afterFunc() end
    self.popup = nil
    if self.blackAmt and action ~= "winning" and not self.blackOutTween then
      tween(.5,self,{blackAmt=0})
      Timer.after(.5,function() self.blackAmt = nil end)
    end
    return
  end
  
  if x/uiScale > self.menuButton.minX and x/uiScale < self.menuButton.maxX and y/uiScale > self.menuButton.minY and y/uiScale < self.menuButton.maxY then
    Gamestate.switch(pausemenu)
  end
  
  if self.moveBlocked then return false end --If something is preventing movement don't do anything
	if (action == "dying") then
    if player.perception == 0 and not currGame.cheats.regenMapOnDeath then
      return game_over()
    end
    return
  end
  
  if self.contextualMenu then
    if x >= self.contextualMenu.x and x <= self.contextualMenu.maxX and y >= self.contextualMenu.y and y <= self.contextualMenu.maxY then
      self.contextualMenu:click(x,y)
      return
    else --if you click outside the menu, close it
      self.contextualMenu = nil
      return
    end
  end
  
  if button == 1 then
    if self.warning then
      local yes = self.warning.yesButton
      local no = self.warning.noButton
      if x > yes.minX and x < yes.maxX and y > yes.minY and y < yes.maxY then
        if self.warning.possession then
          player.possessTarget = self.warning.danger
          possibleSpells['possession']:cast(self.warning.danger,player)
        else
          move_player(self.warning.tile.x,self.warning.tile.y,true)
        end
        self.warning = nil
      elseif x > no.minX and x < no.maxX and y > no.minY and y < no.maxY then
        self.warning = nil
      end
      return
    end
    
    --Sidebar:
    local uiScale = (prefs['uiScale'] or 1)
    local sideBarX = (math.ceil(love.graphics:getWidth()/uiScale)-365)*uiScale
    if x >= sideBarX then
      local asb = self.allSpellsButton
      if asb and x >= asb.minX and x <= asb.maxX and y >= asb.minY and y <= asb.maxY then
        Gamestate.switch(spellscreen)
      end
      local cb = self.characterButton
      if cb and x >= cb.minX and x <= cb.maxX and y >= cb.minY and y <= cb.maxY then
        Gamestate.switch(characterscreen)
      end
      
      for spell,coords in pairs(self.spellButtons) do
        if x >= coords.minX and x <= coords.maxX and y >= coords.minY and y <= coords.maxY then
          if spell == "ranged" then
            action="targeting"
            actionResult=rangedAttacks[player.ranged_attack]
            if (output.cursorX == 0 or output.cursorY == 0) and target then
              output:setCursor(target.x,target.y,true,true)
            else
              output:setCursor(player.x,player.y,true,true)
            end
          elseif spell == "recharge" then
            if rangedAttacks[player.ranged_attack]:recharge(player) then
              advance_turn()
            end
          elseif spell == "pickup" then
            self:keypressed(keybindings.pickup)
          elseif spell == "inventory" then
            self:keypressed(keybindings.inventory)
          elseif spell == "crafting" then
            self:keypressed(keybindings.crafting)
          elseif spell == "action" then
            self:keypressed(keybindings.action)
          else
           possibleSpells[spell]:target(target,player)
          end
          return
        end
      end
      
      for creat,coords in pairs(self.sidebarCreats) do
        if x >= coords.minX and x <= coords.maxX and y >= coords.minY and y <= coords.maxY then
          setTarget(creat.x,creat.y)
        end
      end
    else --If clicked on a tile:
      local tileX,tileY = output:coordinates_to_tile(x,y)
      local creat = currMap:get_tile_creature(tileX,tileY)
      if (tileX and tileY and x < love.graphics.getWidth()-365) then --a tile and not on sidebar
        output:setCursor(tileX,tileY,false,true)
        if action == "targeting" then
          setTarget(tileX,tileY)
        else
          if tileX == player.x and tileY == player.y then --if you click yourself, skip a turn
            output:sound('wait',0)
            advance_turn()
            local enter = currMap:enter(player.x,player.y,player,player.x,player.y) --run the "enter" code for a feature, f'rex, lava burning you even if you don't move
          elseif player:touching({x=tileX,y=tileY}) and (not creat or (creat and (creat == target or not player:does_notice(creat) or not player:can_see_tile(tileX,tileY))))  then --if you're next to the tile move there (attacking if necessary)
            move_player(tileX,tileY)
            return
          end --end click self or next-to-tile if
          --This only happens if the player is not touching the tile:
          if action == "targeting" or (creat ~= false and player:does_notice(creat)) then --if targeting, or if there's a creature there
            if creat ~= false and player:does_notice(creat) and action ~= "targeting" then
              if creat == target then --if they're already you're target, move towards them
                pathTo(tileX,tileY,true)
              end
            end
            setTarget(tileX,tileY)
          elseif currMap:isClear(tileX,tileY,player.pathType) or (creat and not player:does_notice(creat)) then --not targeting, and chose empty space
            pathTo(tileX,tileY,true)
          end --end isclear/targeting if
        end --end targeting or not if
      end
    end
  elseif button == 2 then
    for creat,coords in pairs(self.sidebarCreats) do
      if not self.contextualMenu and x >= coords.minX and x <= coords.maxX and y >= coords.minY and y <= coords.maxY then
        self.contextualMenu = ContextualMenu(creat.x,creat.y,x-300,y)
      end
    end
    local tileX,tileY = output:coordinates_to_tile(x,y)
    local uiScale = (prefs['uiScale'] or 1)
    local sideBarX = (math.ceil(love.graphics:getWidth()/uiScale)-365)*uiScale
    if tileX and tileY and x < sideBarX then --not on sidebar, and actually a real tile
      self.contextualMenu = ContextualMenu(tileX,tileY)
      output:setCursor(tileX,tileY)
    end
	end
end

function game:wheelmoved(x,y)
  if self.contextualMenu then
    if y > 0 then
      self.contextualMenu:scrollUp()
    elseif y < 0 then
      self.contextualMenu:scrollDown()
    end
  else
    if y > 0 then
      currGame.zoom = math.min((currGame.zoom or 1)+0.1,2)
      output:refresh_coordinate_map()
    elseif y < 0 then
      currGame.zoom = math.max((currGame.zoom or 1)-0.1,0.5)
      output:refresh_coordinate_map()
    end
  end
end

function game:keypressed(key,scancode,isRepeat)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat)
  --Pie:keypressed(key)
  if self.popup then
    if not self.popup.enterOnly or key == "return" then
      if self.popup.afterFunc then self.popup.afterFunc() end
      self.popup = nil
      if self.blackAmt and action ~= "winning" and not self.blackOutTween then
        tween(.5,self,{blackAmt=0})
        Timer.after(.5,function() self.blackAmt = nil end)
      end
    end
    return
  end
  
  if self.moveBlocked then return false end -- If something is preventing movement, don't do anything
  
	if (action == "dying") then 
    if player.perception == 0 and not currGame.cheats.regenMapOnDeath then
      return game_over()
    end
    return false
	elseif (player.path ~= nil or action=="exploring") then
		player.path = nil
		action = "moving"
  elseif self.warning then
    if key == "y" or key == "return" then
      if self.warning.possession then
        player.possessTarget = self.warning.danger
        possibleSpells['possession']:cast(self.warning.danger,player)
      else
        move_player(self.warning.tile.x,self.warning.tile.y,true)
      end
      self.warning = nil
    elseif key == "n" or key == "escape" then
      self.warning = nil
    end
	elseif key == "north" or key == "south" or key == "east" or key == "west" or key == "northwest" or key == "northeast" or key == "southwest" or key == "southeast" then
    if self.contextualMenu then
      if key == "north" then
        self.contextualMenu:scrollUp()
      elseif key == "south" then
        self.contextualMenu:scrollDown()
      end
    else
      perform_move(key)
    end
	elseif (key == "wait") and action=="moving" then
    output:sound('wait',0)
		advance_turn()
    local enter = currMap:enter(player.x,player.y,player,player.x,player.y) --run the "enter" code for a feature, f'rex, lava burning you even if you don't move
	elseif (key == "spell") then
		Gamestate.switch(spellscreen)
  elseif (key == "inventory") then
		Gamestate.switch(inventory)
  elseif (key == "throw") then
		Gamestate.switch(inventory,"throwable")
  elseif (key == "use") then
		Gamestate.switch(inventory,"usable")
  elseif (key == "equip") then
		Gamestate.switch(inventory,"equippable")
  elseif (key == "crafting") then
		Gamestate.switch(crafting)
	elseif (key == "examine") then
		if action=="targeting" then
      action="moving"
      actionResult = nil
			output.cursorX = 0
			output.cursorY = 0
    else
      action="targeting"
    end
  elseif (key == "nextTarget") then
    if action == "targeting" and #output.potentialTargets > 0 then
      local targetID = nil
      if output.cursorX ~=0 and output.cursorY ~=0 then
        for i, t in pairs(output.potentialTargets) do
          local creat = currMap:get_tile_creature(t.x,t.y)
          if not creat or player:does_notice(creat) then
            if output.cursorX == t.x and output.cursorY == t.y then
              targetID = i
              break
            end --end if cursorX/y if
          end --end potentialTargets for
        end --end notice if
      end --end if/else
      if targetID == nil then targetID = 0 end
      while true do
        local newTarget = output.potentialTargets[(targetID == #output.potentialTargets and 1 or targetID+1)]
        local creat = currMap:get_tile_creature(newTarget.x,newTarget.y)
        if not creat or player:does_notice(creat) then
          output:setCursor(newTarget.x,newTarget.y)
          break
        end
        targetID = targetID+1
      end
    elseif #player.sees > 0 then
      local targetID = (target and in_table(target,player.sees) or 0)
      while true do
        targetID = (targetID == #player.sees and 1 or targetID+1)
        local creat = currMap:get_tile_creature(player.sees[targetID].x,player.sees[targetID].y)
        if not creat or player:does_notice(creat) then
          target = player.sees[targetID]
          output:setCursor(player.sees[targetID].x,player.sees[targetID].y)
          break
        end
      end
    end
  elseif (key == "ranged" and count(player:get_ranged_attacks()) > 0) then
    local ranged_attacks = player:get_ranged_attacks()
    local anyAvailable = false
    for i, attack in ipairs(ranged_attacks) do
      if not attack.charges or attack.charges > 0 then
        anyAvailable = true
        break
      end
    end --end loopthrough to check charges
    if action == "targeting" then
      setTarget(output.cursorX,output.cursorY)
    elseif anyAvailable then
      action="targeting"
      local allAttacks = {}
      local attackName = ""
      local min_range,range=nil,nil
      for i,attack_instance in ipairs(player:get_ranged_attacks()) do
        local attack = rangedAttacks[attack_instance.attack]
        attackName = attackName .. (i > 1 and ", " or "") .. attack.name
        if attack.min_range and (min_range == nil or attack.min_range < min_range) then
          min_range = attack.min_range
        end
        if attack.range and (range == nil or attack.range < range) then
          range = attack.range
        end
      end --end ranged attack for
      local attackFunction = function(_,target)
        for i,attack_instance in ipairs(player:get_ranged_attacks()) do
          local attack = rangedAttacks[attack_instance.attack]
          if (not attack.charges or attack.charges > 0) and attack:calc_hit_chance(player,target,attack_instance.item) > 0 then
            local proj = attack:use(target,player,attack_instance.item)
            if proj and i > 1 then
              proj.pause = (i-1)/10
            end
          end --end can use attack if
        end --end ranged attack for
      end --end attackFunction
      allAttacks.name = attackName
      allAttacks.use = attackFunction
      allAttacks.min_range,allAttacks.max_range = min_range,range
      allAttacks.target_type="creature"
      actionResult=allAttacks
      if (output.cursorX == 0 or output.cursorY == 0) and target then
        output:setCursor(target.x,target.y,true)
      else
        output:setCursor(player.x,player.y,true)
      end
    else --no attacks available, try to recharge if possible
      local recharge = false
      for i, attack_instance in ipairs(ranged_attacks) do
        local attack = rangedAttacks[attack_instance.attack]
        if (attack.active_recharge) then
          if attack:recharge(player,attack_instance.item) ~= false then
            recharge = true
          end
        end
      end
      if recharge == false then
        output:out("You can't use any ranged attacks right now.")
      else
         advance_turn()
      end
    end
  elseif key == "recharge" then
    local recharge = false
    for i, attack_instance in ipairs(player:get_ranged_attacks()) do
      local attack = rangedAttacks[attack_instance.attack]
      if (attack_instance.item and type(attack_instance.item.charges) == "number" and not attack_instance.item.cooldown) or (not attack_instance.item and attack.active_recharge) then
        if attack:recharge(player,attack_instance.item) ~= false then
          recharge = true
        end
      end
    end
    if recharge ~= false then
      advance_turn()
    end
	elseif (key == "escape") then
    if self.contextualMenu then
      self.contextualMenu = nil
		elseif (action=="targeting") then
			action="moving"
			actionResult = nil
			output.cursorX = 0
			output.cursorY = 0
		else
			Gamestate.switch(pausemenu)
		end
	elseif key == "messages" then
		Gamestate.switch(messages)
	elseif key == "return" then
    if self.contextualMenu and self.contextualMenu.selectedItem then
      self.contextualMenu:click()
    elseif (action == "targeting") then
      if actionResult then
        setTarget(output.cursorX,output.cursorY)
      else
        self.contextualMenu = ContextualMenu(output.cursorX,output.cursorY)
        setTarget(output.cursorX,output.cursorY)
      end
    elseif output.cursorX ~= 0 and output.cursorY ~= 0 then
      self.contextualMenu = ContextualMenu(output.cursorX,output.cursorY)
      setTarget(output.cursorX,output.cursorY)
    end
   elseif (key == "q" and action=="moving") then --TODO: Take this out, it's a test
     test_spells()
    --Gamestate.switch(factionscreen,"lightchurch")
  elseif (key == "s" and action=="moving") then --TODO: Take this out, it's a test
    Gamestate.switch(storescreen,"healthstore")
	elseif key == "charScreen" then
		Gamestate.switch(characterscreen)
	elseif key == "save" then
		save_game()
		output:out("Game saved.")
  elseif key == "zoomIn" then
    currGame.zoom = math.min((currGame.zoom or 1)+0.1,2)
    output:refresh_coordinate_map()
  elseif key == "zoomOut" then
    currGame.zoom = math.max((currGame.zoom or 1)-0.1,0.5)
    output:refresh_coordinate_map()
  elseif key == "pickup" then
    local items = currMap:get_tile_items(player.x,player.y,true)
    if #items == 1 then
      if player:pickup(items[1]) ~= false then
        advance_turn()
      end
    elseif #items > 1 then
      Gamestate.switch(multipickup)
    end
  elseif key == "action" then
    local actions = currMap:get_tile_actions(player.x,player.y)
    if #actions == 1 then
      if actions[1].entity:action(player,actions[1].id) ~= false then
        advance_turn()
      end
    elseif #actions > 1 then
      local list = {}
      for _,action in ipairs(actions) do
        local direction = ""
        local entity = action.entity
        if entity.y < player. y then direction = direction .. "north"
        elseif entity.y > player. y then direction = direction .. "south" end
        if entity.x < player. x then direction = direction .. "west"
        elseif entity.x > player. x then direction = direction .. "east" end
        if direction == "" then direction = "Your Tile" end
        list[#list+1] = {text=action.text .. " (" .. ucfirst(direction) .. ")",description=action.description,selectFunction=entity.action,selectArgs={entity,player,action.id}}
      end
      Gamestate.switch(multiselect,list,"Select an Action",true,true)
    end
  elseif tonumber(key) and prefs.spellShortcuts then
    local spellcount = 1
    for _,spellID in pairs(player:get_spells()) do
      local spell = possibleSpells[spellID]
      if spell.innate ~= true and spell.target_type ~= "passive" then
        if tonumber(key) == spellcount then
          if action == "targeting" and actionResult == spell then
            setTarget(output.cursorX,output.cursorY)
          elseif spell:target(target,player) and spell.target_type == "self" then
            advance_turn()
          end
        end
        spellcount = spellcount+1
      end --end innate/passive
    end --end spell for
  end -- end key if
end -- end function

function game:description_box(text,x,y)
  if Gamestate.current() == game then
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(fonts.descFont)
    local width, tlines = fonts.descFont:getWrap(text,300)
    local height = #tlines*(prefs['descFontSize']+3)+math.ceil(prefs['fontSize']/2)
    x,y = round(x),round(y)
    if (y+20+height < love.graphics.getHeight()) then
      setColor(255,255,255,185)
      love.graphics.rectangle("line",x+22,y+20,302,height)
      setColor(0,0,0,185)
      love.graphics.rectangle("fill",x+23,y+21,301,height-1)
      setColor(255,255,255,255)
      love.graphics.printf(ucfirst(text),x+24,y+22,300)
    else
      setColor(255,255,255,185)
      love.graphics.rectangle("line",x+22,y+20-height,302,height)
      setColor(0,0,0,185)
      love.graphics.rectangle("fill",x+23,y+21-height,301,height-1)
      setColor(255,255,255,255)
      love.graphics.printf(ucfirst(text),x+24,y+22-height,300)
    end
    love.graphics.setFont(oldFont)
  end
end

function game:blackOut(seconds,win)
  seconds = seconds or 5
  self.blackAmt = 0
  self.blackOutTween = tween(seconds,self,{blackAmt=255},'linear',
    function() 
      if self.blackOutTween then 
        Timer.cancel(self.blackOutTween)
      end 
      if not win then 
        if self.deadTween then 
          --Timer.cancel(self.deadTween)
        end 
        if currGame.cheats.regenMapOnDeath then 
          regen_map() 
        end 
      end
    end)
end


-- Contextual menu:
ContextualMenu = Class{}

function ContextualMenu:init(x,y,printX,printY)
  --if player:can_see_tile(x,y) == false then return false end
  self.x,self.y = output:tile_to_coordinates(x,y)
  self.creature = currMap:get_tile_creature(x,y)
  if self.creature and not player:does_notice(self.creature) then self.creature=false end
  self.target = {x=x,y=y}
  self.x,self.y=(printX and printX or self.x)+22,(printY and printY or self.y)+20
  self.width = math.max(300,fonts.descFont:getWidth(self.creature and self.creature:get_name(true) or ""))
  self.maxX=self.x+self.width
  local fontPadding = prefs['descFontSize']+2
  -- Make the box:
  self.items = {}
  local spellY = self.y
  if self.creature then
    self.items[1] = {name="Set as Target",y=spellY+fontPadding,action="target"}
    spellY = spellY+fontPadding*2
    if player.ranged_attack then
      local attack = rangedAttacks[player.ranged_attack]
      self.items[2] = {name=attack:get_name(),y=spellY,action=attack,cooldown=player.ranged_recharge_countdown}
      spellY = spellY+fontPadding
      if attack.active_recharge then
        self.items[3] = {name="Recharge/Reload",y=spellY,action="recharge"}
        spellY=spellY+fontPadding
      end
    end
  else
    self.items[1] = {name="Move To",y=spellY,action="moveto"}
    spellY = spellY+fontPadding
  end
  if currMap:touching(player.x,player.y,x,y) then
    local featureActions = currMap:get_tile_actions(x,y,player,not (x == player.x and y==player.y))
    if #featureActions > 0 then
      for _,action in ipairs(featureActions) do
        self.items[#self.items+1] = {name=action.text,action="featureAction",entity=action.entity,actionID=action.id,y=spellY}
        spellY = spellY+fontPadding
      end
    end
  end
  for _,spellID in pairs(player:get_spells()) do
    local spell = possibleSpells[spellID]
    if spell.target_type == "square" or spell.target_type == "self" or (spell.target_type == "creature" and self.creature) then
      self.items[#self.items+1] = {name=spell.name,y = spellY,action=spell,cooldown=player.cooldowns[spell.name]}
      spellY = spellY+fontPadding
    end
  end
  if self.creature and totalstats.creature_possessions and totalstats.creature_possessions[self.creature.id] then
    self.items[#self.items+1] = {name="View in Monsterpedia",y=spellY,action="monsterpedia"}
    spellY = spellY+fontPadding
  end
  self.maxY = spellY
  self.height = spellY-self.y
end

function ContextualMenu:mouseSelect(mouseX,mouseY)
  local fontPadding = prefs['descFontSize']
  if mouseX>=self.x and mouseX<=self.maxX and mouseY>=self.y and mouseY<=self.maxY then
    for iid,item in ipairs(self.items) do
      if mouseY>item.y-1 and mouseY<item.y+fontPadding then
        self.selectedItem = iid
        break
      end
    end
  end
end

function ContextualMenu:draw()
  love.graphics.setFont(fonts.descFont)
  local fontPadding = prefs['descFontSize']+2
  setColor(0,0,0,185)
  love.graphics.rectangle("fill",self.x,self.y,self.width+1,self.height-1)
  setColor(255,255,255,255)
  love.graphics.rectangle("line",self.x,self.y,self.width+2,self.height)
  
  if self.selectedItem then
    setColor(100,100,100,185)
    love.graphics.rectangle("fill",self.x,self.items[self.selectedItem].y,self.width+1,fontPadding)
    setColor(255,255,255,255)
  end
  
  if self.creature then
    love.graphics.print(self.creature:get_name(true),self.x,self.y)
    love.graphics.line(self.x,self.y+fontPadding,self.x+self.width+1,self.y+fontPadding)
  end
  for _,item in ipairs(self.items) do
    if item.cooldown then
      setColor(100,100,100,255)
    end
    love.graphics.print(item.name .. (item.cooldown and " (" .. item.cooldown .. " turns)" or ""),self.x,item.y)
    if item.cooldown then
      setColor(255,255,255,255)
    end
  end
  love.graphics.setFont(fonts.mapFont)
end

function ContextualMenu:click(x,y)
  local fontPadding = prefs['descFontSize']
  local useItem = nil
  if self.selectedItem then
    useItem = self.items[self.selectedItem]
  else  
    for _,item in ipairs(self.items) do
      if y>item.y-1 and y<item.y+fontPadding then
        useItem = item
        break
      end
    end
  end
  if useItem then
    if useItem.action == "target" then
      target = self.creature
    elseif useItem.action == "moveto" then
      if player:touching(self.target) then
        move_player(self.target.x,self.target.y)
      else
        pathTo(self.target.x,self.target.y,(self.creature == nil))
      end
    elseif useItem.action == "monsterpedia" then
      Gamestate.switch(monsterpedia,self.creature.id)
    elseif useItem.action == "recharge" then
      if rangedAttacks[player.ranged_attack]:recharge(player) then
        advance_turn()
      end
    elseif useItem.action == "featureAction" then
      if useItem.entity:action(player,useItem.actionID) ~= false then
        advance_turn()
      end
    else
      if useItem.action.target_type == "self" then
        if useItem.action:use(self.creature or self.target,player) then advance_turn() end
      else
        action = "targeting"
        actionResult = useItem.action
        setTarget(self.target.x,self.target.y)
      end --end target type if
    end
    game.contextualMenu = nil
  end
end

function ContextualMenu:scrollUp()
  if self.selectedItem then
    self.selectedItem = self.selectedItem - 1
    if self.selectedItem < 1 then self.selectedItem = nil end
  end
end

function ContextualMenu:scrollDown()
  if self.selectedItem then
    self.selectedItem = self.selectedItem + 1
    if self.selectedItem > #self.items then self.selectedItem = #self.items end
  else --if there's no selected item, set it to the first one
    self.selectedItem = 1
  end
end

-- Warning bullshit:
local Warning = Class{}

function game:warn_player(x,y,creat,possession)
  local w = Warning(x,y,creat,possession)
  if w.possession or w.danger then self.warning = w end
end

function Warning:init(x,y,creat,possession)
  self.tile={x=x,y=y}
  if possession then self.possession = true end
  if creat then
    self.danger = creat
  elseif type(currMap[x][y]) == "table" and currMap[x][y].baseType == "feature" and currMap[x][y]:is_hazardous_for(player.pathType) then
    self.danger = currMap[x][y]
  else  --if the tile is a boring old square, or nonthreatening feature
    for _,feat in pairs(currMap:get_tile_features(x,y)) do
      if feat:is_hazardous_for(player.pathType) then
        self.danger = feat
        break
      end --end hazard if
    end --end feature for
    for _,eff in pairs(currMap:get_tile_effects(x,y)) do
      if eff:is_hazardous_for(player.pathType) then
        self.danger = eff
        break
      end --end hazard if
    end --end effect for
  end --end feature if
  self.x,self.y=round(love.graphics.getWidth()/2-100),round(love.graphics.getHeight()/2-50)
  if not self.danger then return false end
end

function Warning:draw()
  love.graphics.setFont(fonts.textFont)
  if prefs['noImages'] ~= true then
    setColor(20,20,20,150)
    love.graphics.rectangle("fill",self.x,self.y,200,93+(self.possession and 32 or 0))
    setColor(255,255,255,255)
    for x=self.x,self.x+182,32 do
      love.graphics.draw(images.borders.borderImg,images.borders.u,x,self.y-18)
      love.graphics.draw(images.borders.borderImg,images.borders.d,x,self.y+75+(self.possession and 32 or 0))
    end
    for y=self.y,self.y+(self.possession and 96 or 64),32 do
      love.graphics.draw(images.borders.borderImg,images.borders.l,self.x-18,y)
      love.graphics.draw(images.borders.borderImg,images.borders.r,self.x+182,y)
    end
    love.graphics.draw(images.borders.borderImg,images.borders.ul,self.x-18,self.y-18)
    love.graphics.draw(images.borders.borderImg,images.borders.ur,self.x+182,self.y-18)
    love.graphics.draw(images.borders.borderImg,images.borders.ll,self.x-18,self.y+75+(self.possession and 32 or 0))
    love.graphics.draw(images.borders.borderImg,images.borders.lr,self.x+182,self.y+75+(self.possession and 32 or 0))
  else
    setColor(20,20,20,150)
    love.graphics.rectangle("fill",self.x-8,self.y,208,(self.possession and 136 or 104))
    setColor(255,255,255,255)
    love.graphics.rectangle("line",self.x-8,self.y-8,208,(self.possession and 136 or 104)) -- warning outline
  end
  if self.possession == true then
    love.graphics.printf("If you fail this possession, a nearby enemy could hit you and send you back to the Nether Regions. Are you sure you want to try?",self.x,self.y,190,"center")
  else
    if self.danger.baseType == "creature" then
      love.graphics.printf("Are you sure you want to move next to " .. self.danger:get_name() .. "?",self.x,self.y,190,"center")
    else
      love.graphics.printf("Are you sure you want to step into the " .. self.danger.name .. "?",self.x,self.y,190,"center")
    end
  end
  self.yesButton = output:button(self.x+20,self.y+55+(self.possession and 32 or 0),32)
  love.graphics.print("(Y)es",self.x+30,self.y+60+(self.possession and 32 or 0))
  self.noButton = output:button(self.x+120,self.y+55+(self.possession and 32 or 0),32)
  love.graphics.print("(N)o",self.x+130,self.y+60+(self.possession and 32 or 0))
end

--Popup stuff:
local Popup = Class{}

function game:show_map_description()
  local _, count = string.gsub(currMap.description, "\n", "\n")
  local branch = currWorld.branches[currMap.branch]
  self.popup = Popup(currMap.description,(not branch.hideName and branch.name or "") .. (not branch.hideDepth and " " .. (branch.depthName or "Depth") .. " " .. currMap.depth or "") .. (currMap.name and (not branch.hideName or not branch.hideDepth) and "\n" or "") .. (currMap.name or "") .. "\n" .. " ",4+count,true)
  output:sound('interface_bang')
end

function game:show_popup(text,header,extraLines,blackout,enterOnly,afterFunc,sound)
  self.popup = Popup(text,header,extraLines,blackout,enterOnly,afterFunc)
  if sound then output:sound('interface_bang') end
end

function Popup:init(text,header,extraLines,blackout,enterOnly,afterFunc)
  self.text,self.header=text,(header or "")
  self.blackout,self.enterOnly = blackout,enterOnly
  self.width = math.ceil(love.graphics.getWidth()/2)
  self.padding = (prefs['noImages'] and 8 or 16)
  self.afterFunc = afterFunc
  extraLines = extraLines or 4
  local _,hlines = fonts.textFont:getWrap(self.header,self.width)
  local _,tlines = fonts.textFont:getWrap(text,self.width)
  self.headerHeight = #hlines*prefs['fontSize']
  self.height = (#tlines+extraLines)*prefs['fontSize']+self.headerHeight
  self.x,self.y=round(love.graphics.getWidth()/4),round(love.graphics.getHeight()/2-self.height/2)
end

function Popup:draw()
  output:draw_window(self.x,self.y,self.x+self.width,self.y+self.height)
  love.graphics.setFont(fonts.textFont)
  if self.header then
    love.graphics.printf(self.header,self.x+self.padding,self.y+self.padding,self.width-self.padding,"center")
  end
  love.graphics.printf(self.text,self.x+self.padding+5,self.y+self.padding+self.headerHeight+5,self.width-self.padding,"left")
  if self.enterOnly then
    love.graphics.printf("Press enter or click to continue...",self.x,self.y+self.height-(prefs['noImages'] and 10 or 5),self.width,"center")
  else
    love.graphics.printf("Press any key or click to continue...",self.x,self.y+self.height-(prefs['noImages'] and 10 or 5),self.width,"center")
  end
end