game = {spellButtons={},sidebarCreats={},hoveringCreat=nil,hp=0,playerID=nil,eventualHP=0,targetHP=0,targetEventualHP=0,targetID=nil,batches={},batchesDark={},turns_to_advance=0,targets={}}

function game:enter()
  love.graphics.setFont(fonts.mapFontWithImages)
  if prefs.captureMouse then love.mouse.setGrabbed(true) end
end
  
function game:leave()
  love.graphics.setFont(fonts.textFont)
  love.mouse.setGrabbed(false)
end

function game:draw()
  local dtime1 = os.clock()
  --profiler:reset()
  --profiler:start()
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
  local mapName = currMap:get_name()
  love.graphics.printf(mapName,0,0,width,"center")
  self.menuButton = output:closebutton(8,8,false,true,'menu')
  if action == "targeting" then
    local text = "Select Target"
    if actionResult and actionResult.name then
      local max_targets = actionResult.max_targets or 1
      text = text ..  (max_targets > 1 and "s for " or " for ") .. actionResult.name .. (max_targets > 1 and ": " .. #game.targets .. "/" .. max_targets or "")
    end
    text = text .. "\n"
    if actionResult and actionResult.min_targets and #game.targets >= actionResult.min_targets then
      text = text .. "Press " .. ucfirst(input:get_button_name("spell")) .. " to use now, "
    end
    text = text .. "Press " .. ucfirst(input:get_button_name("escape")) .. " to Cancel"
    --local w = fonts.textFont:getWidth(text)
    --setColor(0,0,0,100)
    --love.graphics.rectangle('fill',math.ceil(width/2-w/2)-8,32,w+16,16)
    setColor(0,0,0,255)
    love.graphics.printf(text,2,33,width,"center")
    setColor(255,255,255,255)
    love.graphics.printf(text,0,32,width,"center")
  elseif action == "attacking" then
    local text = "Select Direction to Attack\nPress " .. ucfirst(input:get_button_name("escape")) .. " to Cancel"
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
  --profiler:stop()
  --print(profiler.report(10))
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
            setColor(255,255,0,125)
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
    --Description box for targeted tile:
    self.hoveringCreat = nil
    if (player:can_see_tile(output.cursorX,output.cursorY) and self.contextualMenu == nil and self.warning == nil) then
      local text = ""
      if (next(currMap.contents[output.cursorX][output.cursorY]) ~= nil) then
        for id, entity in pairs(currMap.contents[output.cursorX][output.cursorY]) do
          if entity.baseType == "creature" and player:does_notice(entity) then
            text = ucfirst(currMap.contents[output.cursorX][output.cursorY][id]:get_description()) .. (text == "" and "" or "\n----\n" .. text)
            if entity ~= player then self.hoveringCreat = entity end
          elseif entity.baseType ~= "creature" and not entity.noDesc then
            if (text ~= "") then text = text .. "\n----\n" end
            if entity.baseType == "item" then
              text = text .. entity:get_name(true,nil,true) .. "\n"
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
      if text ~= "" then output:description_box(text,printX+tileSize/2,printY+tileSize/2) end
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
  local upgrade_points_skill = ""
  if (player.upgrade_points_skill and player.upgrade_points_skill > 0) or (player.upgrade_points_attribute and player.upgrade_points_attribute > 0) then upgrade_points_skill = " (+)" end
  local char_screen_key = input:get_button_name("charScreen")
  local buttonWidth = whichFont:getWidth(char_screen_key .. ") " .. (gamesettings.leveling and " Level " .. player.level .. " " or " ") .. ucfirst(player.name) .. upgrade_points_skill)

  local middleX = round(printX+335/2)
  printY=printY+fontPad
  self.characterButton = output:button(round(middleX-buttonWidth/2)-8,printY,buttonWidth+16,smallButtons,nil,nil,true)
	if upgrade_points_skill ~= "" then setColor(255,255,0,255) end
  love.graphics.printf(char_screen_key .. ")" .. (gamesettings.leveling and " Level " .. player.level .. " " or " ") .. ucfirst(player.name) .. upgrade_points_skill,printX,printY+yBonus,335,"center")
  setColor(255,255,255,255) 
  if output.shakeTimer > 0 then
    love.graphics.push()
    local shakeDist = output.shakeDist*output.shakeTimer*2
    love.graphics.translate(random(-shakeDist,shakeDist),random(-shakeDist,shakeDist))
  end
  local ratio = self.hp/player:get_max_hp()
  local hpR = 200-(200*ratio)
  local hpG = 200*ratio
  printY=printY+math.max(math.floor(fontPad*1.5),24)
	output:draw_health_bar(self.hp,player:get_max_hp(),printX+xPad,printY,325,math.max(fontPad,16),{r=hpR,g=hpG,b=0,a=255})
 love.graphics.printf("Health: " .. math.ceil(self.hp) .. "/" .. player:get_max_hp(),printX,printY+yBonus,332,"center")
  if output.shakeTimer > 0 then
    love.graphics.pop()
  end
  
  if gamesettings.mp then
    local mhp = player:get_max_mp()
    if (mhp > 0) then
      printY=printY+math.max(math.floor(fontPad*1.5),24)
      output:draw_health_bar(player.mp,player:get_max_mp(),printX+xPad,printY,325,math.max(fontPad,16),{r=100,g=0,b=100,a=255})
      love.graphics.printf("Magic: " .. player.mp .. "/" .. mhp,printX+xPad,printY+yBonus,332,"center")
    end
  end
  
  if player.extra_stats then
    for stat_id,stat in pairs(player.extra_stats) do
      if stat.max and stat.bar_color then
        printY=printY+math.max(math.floor(fontPad*1.5),24)
        output:draw_health_bar(stat.value,stat.max,printX+xPad,printY,325,math.max(fontPad,16),stat.bar_color)
        love.graphics.printf(stat.name .. ": " .. stat.value .. "/" .. stat.max,printX+xPad,printY+yBonus,332,"center")
      else
        printY=printY+fontPad*2
        love.graphics.print(stat.name .. ": " .. stat.value .. (stat.max and "/" .. stat.max or ""),printX+xPad,printY)
      end
    end
  end
  printY = printY+fontPad*2
  
  setColor(255,255,255,255)
 
  self.spellButtons = {}
  local descBox = false
  local buttonPadding = (smallButtons and 20 or 36)
  --Buttons for ranged attacks:
 local ranged_attacks = player:get_ranged_attacks()
  if #ranged_attacks > 0 then
    local anyAvailable = false
    local ranged_text = input:get_button_name("ranged") .. ") Ranged: "
    local ranged_description_box = ""
    for i,attack_instance in ipairs(ranged_attacks) do
      local attack = rangedAttacks[attack_instance.attack]
      local item = attack_instance.item or nil
      ranged_text = ranged_text .. attack:get_name()
      if attack_instance.charges and attack_instance.hide_charges ~= true and attack_instance.hide_charges ~= true then
        ranged_text = ranged_text .. " (" .. attack_instance.charges .. ")"
      end
      if attack_instance.cooldown or attack_instance.recharge_turns then
        ranged_text = ranged_text .. " (" .. (attack_instance.cooldown or attack_instance.recharge_turns) .. " turns to recharge)"
      end
      if i < #ranged_attacks then ranged_text = ranged_text .. ", " end
      ranged_description_box = ranged_description_box .. (i > 1 and "\n\n" or "") .. attack.name .. "\n" .. attack.description
      if not attack_instance.cooldown and (not attack_instance.charges or attack_instance.charges > 0) then
        anyAvailable=true
      end
    end --end ranged attack for
    local rangedWidth = whichFont:getWidth(ranged_text)
    local minX,minY=printX+xPad-2,printY
    local maxX,maxY=minX+rangedWidth+4,minY+(smallButtons and 16 or 32)
    local buttonType = (not anyAvailable and "disabled" or (actionResult and actionResult == attack and "hover" or nil))
    self.spellButtons["ranged"] = output:button(minX,minY+2,(maxX-minX),smallButtons,buttonType,nil,true)
    if self.spellButtons["ranged"].hover == true then
      descBox = {desc=ranged_description_box,x=minX,y=minY}
    end
    if not anyAvailable then
      setColor(200,200,200,255)
    end
    --love.graphics.rectangle('line',printX+xPad-2,printY+yPad,rangedWidth+4,16)
    love.graphics.print(ranged_text,printX+xPad,printY-2)
    if not anyAvailable then
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
  --Button for abilities:
  if count(player:get_spells()) > 0 then
    local key_spell = input:get_button_name("spell")
    local buttonWidth = whichFont:getWidth(key_spell .. ") Abilities")
    local minX,minY=printX+xPad-2,printY
    local maxX,maxY=minX+buttonWidth+4,minY+16
    self.allSpellsButton = output:button(minX,minY+2,(maxX-minX),smallButtons,nil,nil,true)
    love.graphics.print(key_spell .. ") Abilities",printX+xPad,printY-2+yBonus)
    if self.allSpellsButton.hover == true then
      descBox = {desc="View and use abilities you have.",x=minX,y=minY}
    end
    printY=printY+buttonPadding
  end
  --Button for inventory:
  if gamesettings.inventory then
    local key_inventory = input:get_button_name("inventory")
    local invWidth = whichFont:getWidth(key_inventory .. ") Inventory")
    local minX,minY=printX+xPad-2,printY
    local maxX,maxY=minX+invWidth+4,minY+(smallButtons and 16 or 32)
    self.spellButtons["inventory"] = output:button(minX,minY+2,(maxX-minX),smallButtons,nil,nil,true)
    if self.spellButtons["inventory"].hover == true then
      descBox = {desc="View and use items and equipment.",x=minX,y=minY}
    end
    love.graphics.print(key_inventory .. ") Inventory",printX+xPad,printY-2+yBonus)
    printY = printY+buttonPadding
  end
  if gamesettings.crafting and gamesettings.craft_anywhere then
    local key_crafting = input:get_button_name("crafting")
    local invWidth = whichFont:getWidth(key_crafting .. ") Crafting")
    local minX,minY=printX+xPad-2,printY
    local maxX,maxY=minX+invWidth+4,minY+16
    self.spellButtons["crafting"] = output:button(minX,minY+2,(maxX-minX),smallButtons,nil,nil,true)
    if self.spellButtons["crafting"].hover == true then
      descBox = {desc="Make new items.",x=minX,y=minY}
    end
    love.graphics.print(key_crafting .. ") Crafting",printX+xPad,printY-2+yBonus)
    printY = printY+buttonPadding
  end
  
 --Button for feature actions:
  local featureActions = currMap:get_tile_actions(player.x,player.y,true)
  if #featureActions > 0 then
    local picktext = input:get_button_name("action") .. ") " .. (#featureActions > 1 and "Nearby Actions" or featureActions[1].text)
    local spellwidth = whichFont:getWidth(picktext)
    local minX,minY=printX+xPad-2,printY
    local maxX,maxY=minX+spellwidth+4,minY+16
    self.spellButtons["action"] = output:button(minX,minY+2,(maxX-minX),smallButtons,nil,nil,true)
    if self.spellButtons['action'].hover == true then
      descBox = {desc=(#featureActions > 1 and "Select a nearby action to perform." or featureActions[1].description),x=minX,y=minY}
    end
    love.graphics.print(picktext,printX+xPad,printY-2+yBonus)
    printY = printY+buttonPadding
  end
  local items = currMap:get_tile_items(player.x,player.y,gamesettings.can_pickup_adjacent_items)
  if #items > 0 then
    local picktext = input:get_button_name("pickup") .. ") Pick Up " .. (#items > 1 and "Items" or items[1]:get_name())
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
  
  --Buttons for hotkeys:
  local hkcount = 0
  for i = 1,10,1 do
    if player.hotkeys[i] then
      hkcount = hkcount+1
      local hotkeyInfo = player.hotkeys[i]
      local name = ""
      local canUse = true
      local canUseText = nil
      local hotkeyItem = hotkeyInfo.hotkeyItem
      if not hotkeyItem then
        player.hotkeys[i] = nil
      else
        if hotkeyInfo.type == "spell" then
          local no_deactivate = (hotkeyItem.active and hotkeyItem.no_manual_deactivate)
          name = hotkeyItem.name .. (player.cooldowns[hotkeyItem] and " (" .. player.cooldowns[hotkeyItem] .. " turns)" or "") .. (hotkeyItem.charges and " (" .. hotkeyItem.charges .. ")" or "") .. (hotkeyItem.active and " (Active)" or "")
          canUse = not player.cooldowns[hotkeyItem] and hotkeyItem:requires(player) and not no_deactivate
          if no_deactivate then
            canUseText = "You cannot manually deactivate this ability."
          end
        elseif hotkeyInfo.type == "item" then
          name = hotkeyItem:get_name(true) .. (player.cooldowns[hotkeyItem] and " (" .. player.cooldowns[hotkeyItem] .. " turns)" or "") .. (hotkeyItem.charges and " (" .. hotkeyItem.charges .. ")" or "")
          canUse,canUseText = player:can_use_item(hotkeyItem)
        end
        local description = hotkeyItem:get_description()
        
        --Draw the actual button:
        local spellwidth = whichFont:getWidth((i == 10 and 0 or i) .. ") " .. name)
        local minX,minY=printX+xPad-2,printY+buttonPadding*(hkcount-1)
        local maxX,maxY=minX+spellwidth+4,minY+(smallButtons and 16 or 32)
        local buttonType = ((canUse == false) and "disabled" or (actionResult and actionResult == hotkeyItem and "hover" or nil))
        self.spellButtons[i] = output:button(minX,minY+2,(maxX-minX),smallButtons,buttonType,nil,true)
        if self.spellButtons[i].hover == true then
          descBox = {desc=description .. (canUseText and "\n" .. canUseText or ""),x=minX,y=minY}
        end
        if hotkeyItem.active then
          setColor(100,(canUse and 255 or 175),100,255)
        elseif canUse == false then
          setColor(200,200,200,255)
        end
        love.graphics.print((i == 10 and 0 or i) .. ") " .. name,printX+xPad,printY+buttonPadding*(hkcount-1)-2+yBonus)
        setColor(255,255,255,255)
      end
    end
  end
  printY = printY+buttonPadding*hkcount
  
  --[[local spellcount = 1
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
        local target_type = spell.target_type
        local targetText = ""
        if target_type == "self" then
          targetText = "This ability does not require a target."
        elseif target_type == "creature" then
          targetText = "This ability can be used on creatures."
        elseif target_type == "tile" then
          targetText = "This ability can be used on any tile in range."
        elseif target_type == "passive" then
          targetText = "This ability is passive and is used automatically when needed."
        end
        descBox = {desc=spell:get_description() .. "\n" .. targetText,x=minX,y=minY}
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
  printY = printY+(buttonPadding*spellcount)]]
	
	if (next(player.conditions) ~= nil or next(player.active_spells) ~= nil) then
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
    for sid,data in pairs(player.active_spells) do
      if (count > 1) then conText = conText .. ", " end
      conText = conText .. data.spell.name
      count = count + 1
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
      if (printY+yPad < ((player.target or self.hoveringCreat) and height-240 or height-64) and thing ~= player and in_table(thing,alreadyPrinted) == false and player:does_notice(thing)) then
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
            if thing ~= player then self.hoveringCreat = thing end
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
  if descBox and descBox.desc then
    output:description_box(descBox.desc,descBox.x+20,descBox.y+fontSize)
  end
end

function game:print_target_sidebar()
  local uiScale = (prefs['uiScale'] or 1)
  local creat = self.hoveringCreat or target
  if (creat ~= nil) then
    local width, height = love.graphics:getWidth(),love.graphics:getHeight()
    local printX = math.ceil(width/uiScale)-365
    local maxX = printX+319
    local printY = math.ceil(height/uiScale)-225
    local maxY = ((next(creat.conditions) == nil and printY+65 or printY+95))
    local xPad = 5
    local yBonus = 2
    local fontPadding = 15
    
    if not prefs.plainFonts then
      love.graphics.setFont(fonts.buttonFont)
      yBonus = 0
    else
      fontPadding = prefs['fontSize']+2
    end
		if (creat.properName ~= nil) then
			love.graphics.printf(creat.properName,printX,printY,335,"center")
			printY = printY+fontPadding
		end
		love.graphics.printf((gamesettings.display_creature_levels and "Level " .. creat.level .. " " or "") .. ucfirst(creat.name),printX,printY,335,"center")
    if creat.master then 
      printY = printY+fontPadding
      love.graphics.printf("Master: " .. creat.master:get_name(false,true),printX,printY,335,"center")
    end
    local hp = (creat == target and self.targetHP or creat.hp)
    output:draw_health_bar(hp,creat:get_max_hp(),printX+xPad,printY+fontPadding+5,325,16)
    love.graphics.printf("Health: " .. math.ceil(hp) .. "/" .. creat:get_max_hp(),printX+xPad,printY+fontPadding+2+yBonus,335,"center")
    
    --Melee attack hit chance:
    local weapons = player:get_melee_attacks()
    local weapCount = count(weapons)
    printY = printY+fontPadding*3
    if weapCount == 0 then
      love.graphics.print("Hit chance: " .. calc_hit_chance(player,creat) .. "%",printX+xPad,printY)
      printY = printY+fontPadding
    elseif weapCount == 1 then
      love.graphics.print(weapons[1]:get_name(true) .. " hit chance: " .. calc_hit_chance(player,creat,weapons[1]) .. "%",printX+xPad,printY)
      printY = printY+fontPadding
    else
      for _,weap in pairs(weapons) do
        love.graphics.printf(weap:get_name(true) .. " hit chance" .. (weap.ranged_attack and " (melee)" or "") .. ": " .. calc_hit_chance(player,creat,weap) .. "%",printX+xPad,printY,335,"left")
        printY = printY+fontPadding
      end
    end --end weapon count if
    
    --Ranged attack hit chance:
    local ranged_attacks = player:get_ranged_attacks()
    if #ranged_attacks > 0 then
      local dist = calc_distance(player.x,player.y,creat.x,creat.y)
      for i,attack_instance in ipairs(ranged_attacks) do
        local attack = rangedAttacks[attack_instance.attack]
        local hit_chance = attack:calc_hit_chance(player,creat,attack.item)
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
    love.graphics.print("Chance to Be Hit: " .. calc_hit_chance(creat,player) .. "%",printX+xPad,printY+yPadNow)
		if (next(creat.conditions) ~= nil or next(creat.active_spells) ~= nil) then
      love.graphics.printf("Conditions:",printX,printY+fontPadding*2+yPadNow,335,"center")
      local conText = ""
      local count = 1
      for condition, turns in pairs(creat.conditions) do
        if (conditions[condition].hidden ~= true) then
          if (count > 1) then conText = conText .. ", " end
          conText = conText .. conditions[condition].name
          count = count + 1
        end
      end
      for sid, data in pairs(creat.active_spells) do
        if (count > 1) then conText = conText .. ", " end
        conText = conText .. data.spell.name
        count = count + 1
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
  local itemsToDisplay = {}
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
                if not seen then
                  setColor(50,50,50,255)
                elseif map.tileset and tilesets[map.tileset] and map[x][y] == "." and tilesets[map.tileset].floorColor then
                  local tc = tilesets[map.tileset].floorColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                elseif map.tileset and tilesets[map.tileset] and map[x][y] == "#" and tilesets[map.tileset].wallColor then
                  local tc = tilesets[map.tileset].wallColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                elseif map.tileset and tilesets[map.tileset] and tilesets[map.tileset].textColor then
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
            if tilesets[map.tileset] and tilesets[map.tileset].tilemap and map.images[x][y] and map.images[x][y].image then
              img = images[map.images[x][y].image]
            else
              img = images[map.images[x][y]]
            end
            if map.tileset and tilesets[map.tileset] and img and img ~= -1 then
              local sbColor={r=255,g=255,b=255,a=255}
              --Set color:
              if tilesets[map.tileset].use_color_with_tiles or (gamesettings.always_use_color_with_tiles and tilesets[map.tileset].use_color_with_tiles ~= false) then
                if (map[x][y] == "." or type(map[x][y]) == "table") and tilesets[map.tileset].floorColor then
                  local tc = tilesets[map.tileset].floorColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                  sbColor={r=tc.r/255,g=tc.g/255,b=tc.b/255,a=tc.a/255}
                elseif map[x][y] == "#" and tilesets[map.tileset].wallColor then
                  local tc = tilesets[map.tileset].wallColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                  sbColor={r=tc.r/255,g=tc.g/255,b=tc.b/255,a=tc.a/255}
                elseif tilesets[map.tileset].textColor then
                  local tc = tilesets[map.tileset].textColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                  sbColor={r=tc.r/255,g=tc.g/255,b=tc.b/255,a=tc.a/255}
                else
                  setColor(255,255,255,255)
                end
              else --if not using tileset colors
                if seen == false then setColor(100,100,100,255)
                else setColor(255,255,255,255) end
              end --end tileset color if
              
              --pClock:clearTime()
              if tilesets[map.tileset].tilemap and map[x][y] == "#" then
                if seen then
                  if not self.batches[img] then
                    self.batches[img] = love.graphics.newSpriteBatch(img,map.width*map.height)
                  end
                  self.batches[img]:setColor(sbColor.r,sbColor.g,sbColor.b,sbColor.a)
                  self.batches[img]:add(quads[map.images[x][y].direction],printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
                  self.batches[img]:setColor(1,1,1,1)
                else
                  if not self.batchesDark[img] then
                    self.batchesDark[img] = love.graphics.newSpriteBatch(img,map.width*map.height)
                  end
                  self.batchesDark[img]:setColor(sbColor.r,sbColor.g,sbColor.b,sbColor.a)
                  self.batchesDark[img]:add(quads[map.images[x][y].direction],printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
                  self.batchesDark[img]:setColor(1,1,1,1)
                end
                --love.graphics.draw(img,quads[map.images[x][y].direction],printX+16,printY+16,0,1,1,16,16)
              else --uses individual images? draw the image
                if seen then
                  if not self.batches[img] then
                    self.batches[img] = love.graphics.newSpriteBatch(img,map.width*map.height)
                  end
                  self.batches[img]:setColor(sbColor.r,sbColor.g,sbColor.b,sbColor.a)
                  self.batches[img]:add(printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
                  self.batches[img]:setColor(1,1,1,1)
                else
                  if not self.batchesDark[img] then
                    self.batchesDark[img] = love.graphics.newSpriteBatch(img,map.width*map.height)
                  end
                  self.batchesDark[img]:setColor(sbColor.r,sbColor.g,sbColor.b,sbColor.a)
                  self.batchesDark[img]:add(printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
                  self.batchesDark[img]:setColor(1,1,1,1)
                end
                setColor(255,255,255,255)
                --love.graphics.draw(img,printX+16,printY+16,0,1,1,16,16)
              end
            else --don't have an image
              love.graphics.setFont(fonts.mapFontWithImages)
              if (type(map[x][y]) == "string") then --if there are no creatures or features, just print the tile
                if not seen then
                  setColor(50,50,50,255)
                elseif map.tileset and tilesets[map.tileset] and map[x][y] == "." and tilesets[map.tileset].floorColor then
                  local tc = tilesets[map.tileset].floorColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                elseif map.tileset and tilesets[map.tileset] and map[x][y] == "#" and tilesets[map.tileset].wallColor then
                  local tc = tilesets[map.tileset].wallColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                elseif map.tileset and tilesets[map.tileset] and tilesets[map.tileset].textColor then
                  local tc = tilesets[map.tileset].textColor
                  setColor(tc.r,tc.g,tc.b,tc.a)
                else
                  setColor(255,255,255,255)
                end
                  love.graphics.print(map[x][y],printX,printY)
              else
                output.display_entity(map[x][y],printX,printY,seen)
              end
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
                elseif content.baseType == "feature" then
                  featuresToDisplay[#featuresToDisplay+1] = {feature=content,x=printX,y=printY,seen=seen}
                elseif content.baseType == "item" then
                  itemsToDisplay[#itemsToDisplay+1] = {item=content,x=printX,y=printY,seen=seen}
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
    if player:does_notice(creat) and (player:can_sense_creature(creat) or (creat.fromX and creat.fromY and timers[tostring(creat) .. 'moveTween'] and player:can_see_tile(creat.fromX,creat.fromY))) then
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
  for _,item in ipairs(itemsToDisplay) do
    output.display_entity(item.item,item.x,item.y,item.seen,nil,(currGame.zoom or 1))
  end
  --stats = love.graphics.getStats()
  --print('draw calls after features: ' .. tostring(stats.drawcalls))
  --pClock:flag('feature display')
  for creat,args in pairs(creaturesToDisplay) do
    output.display_entity(creat,args[1],args[2],args[3],nil,(currGame.zoom or 1))
    local mhp = creat:get_max_hp()
    if prefs['healthbars'] and creat.hp < mhp then
      local tileSize = output:get_tile_size()
      local barHeight = 8
      local ratio = creat.hp/mhp
      local hpR = 200-(200*ratio)
      local hpG = 200*ratio
      setColor(hpR,hpG,0,100)
      love.graphics.rectangle('fill',args[1],args[2]+tileSize-barHeight,round(tileSize*ratio),barHeight)
      setColor(255,255,255,100)
      love.graphics.rectangle('line',args[1],args[2]+tileSize-barHeight,tileSize,barHeight)
      setColor(255,255,255,255)
    end
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
      else
        setColor(100,50,100,125)
        love.graphics.draw(images.uicrosshair,printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
      end
      setColor(255,255,255,255)
    end --end for
    for _,tile in pairs(output.potentialTargets) do
      local creat = currMap:get_tile_creature(tile.x,tile.y)
      if not creat or player:does_notice(creat) then
        local printX,printY = output:tile_to_coordinates(tile.x,tile.y)
        local tileSize = output:get_tile_size() --tileSize is 14 without images, 32 with
        if prefs['noImages'] == true then
          setColor(100,100,100,255)
          love.graphics.rectangle("line",printX-2,printY+2,tileSize,tileSize)
        else
          setColor(255,255,0,75)
          love.graphics.draw(images.uicrosshair,printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
        end
        setColor(255,255,255,255)
      end --end notice if
    end --end for
    for _,tile in ipairs(game.targets) do
      local printX,printY = output:tile_to_coordinates(tile.x,tile.y)
      local tileSize = output:get_tile_size() --tileSize is 14 without images, 32 with
      if prefs['noImages'] == true then
        setColor(255,0,0,255)
        love.graphics.rectangle("line",printX-2,printY+2,tileSize,tileSize)
      else
        setColor(255,0,0,255)
        love.graphics.draw(images.uicrosshair,printX+16*(currGame.zoom or 1),printY+16*(currGame.zoom or 1),0,(currGame.zoom or 1),(currGame.zoom or 1),16,16)
      end
      setColor(255,255,255,255)
    end
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
  if map.tileset and tilesets[map.tileset] and tilesets[map.tileset].textColor then
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
      if seen or map.seenMap[x][y] == true then
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
          elseif map:get_blocking_feature(x,y) then
            local bf = map:get_blocking_feature(x,y)
            local tc= bf.color
            setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),math.ceil(255*(mouseOver and 0.25 or 1)))
            love.graphics.print("o",printX,printY)
          elseif type(map[x][y]) == "table" then
            local tc= map[x][y].color
            setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),math.ceil(255*(mouseOver and 0.25 or 1)))
            love.graphics.print("·",printX,printY)
          elseif map[x][y] == "." then
            if map.tileset and tilesets[map.tileset] and tilesets[map.tileset].textColor then
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
          elseif map:get_blocking_feature(x,y) then
            local bf = map:get_blocking_feature(x,y)
            local tc= bf.color
            setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),math.ceil(200*(mouseOver and 0.25 or 1)))
          elseif type(map[x][y]) == "table" then
            local tc= map[x][y].color
            setColor((seen and tc.r or math.ceil(tc.r*.5)),(seen and tc.g or math.ceil(tc.g*.5)),(seen and tc.b or math.ceil(tc.b*.5)),math.ceil(200*(mouseOver and 0.25 or 1)))
          elseif map[x][y] == "." then
            if map.tileset and tilesets[map.tileset] and tilesets[map.tileset].textColor then
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
  --profiler:reset()
  --profiler:start()
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
	if player.hp < 1 and action ~= "dying" then
		action = "dying"
	end
  
  if output.popup then return end
  
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
    if e.stopsInput and player:can_see_tile(e.x,e.y) then
      if (self.blockTime or 0) > 2 then
        print(e.name .. " blocking movement too long, cancelling block")
        e.stopsInput = false
      else
        self.moveBlocked = true
      end
    end
	end
  for _, p in pairs(currMap.projectiles) do
    p:update(dt)
    if p.stopsInput and player:can_see_tile(p.x,p.y) then
      if (self.blockTime or 0) > 2 then
        print(p.name .. " blocking movement too long, cancelling block")
        p.stopsInput = false
      else
        self.moveBlocked = true
      end
    end
  end
  for _, c in pairs(currMap.creatures) do
    c:update(dt)
    if c.stopsInput and player:can_see_tile(c.x,c.y) then
      if (self.blockTime or 0) > 2 then
        print(c.name .. " blocking movement too long, cancelling block")
        c.stopsInput = false
      else
        self.moveBlocked = true
      end
    end
  end
  if self.moveBlocked == false and self.turns_to_advance > 0 then
    turn_logic()
    self.turns_to_advance = self.turns_to_advance - 1
  end
  if self.moveBlocked == true then
    self.blockTime = (self.blockTime or 0)+dt
  else
    self.blockTime = nil
  end
  --[[if count(currMap.lights) > 0 then
    currMap:refresh_lightMap(true)
  end]]
  
  --Untarget if targeting self or unseen or dead creature
	if target == player or (target and (player:can_sense_creature(target) == false or target.hp < 1)) then target = nil end
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
          if action == "targeting" and actionResult ~= nil and (actionResult.get_potential_targets ~= nil or actionResult.target_type == "creature") and #output.potentialTargets > 0 and not actionResult.free_aim then
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
      local ptarg = (actionResult.get_potential_targets and actionResult:get_potential_targets(player,game.targets) or {})
      if ptarg then
        output.potentialTargets = ptarg
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
  
  --Add overload to player if they're carring too much:
  local space = player:get_free_inventory_space()
  if type(space) == "number" and space < 0 then
    player:give_condition('overloaded',-1)
  end
  --profiler:stop()
  --print(profiler.report(10))
  --print("update time: " .. os.clock()-utime)
end

function game:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  
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
      if x/uiScale > yes.minX and x/uiScale < yes.maxX and y/uiScale > yes.minY and y/uiScale < yes.maxY then
        local args = self.warning.afterArgs or {}
        self.warning.afterFunc(unpack(args))
        self.warning = nil
      elseif x/uiScale > no.minX and x/uiScale < no.maxX and y/uiScale > no.minY and y/uiScale < no.maxY then
        self.warning = nil
      end
      return
    end
    
    --Sidebar:
    local uiScale = (prefs['uiScale'] or 1)
    local sideBarX = (math.ceil(love.graphics:getWidth()/uiScale)-365)*uiScale
    if x >= sideBarX then
      x,y=round(x/uiScale),round(y/uiScale)
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
            if actionResult and actionResult.baseType == "ranged" then
              cancel_targeting()
            else
              self:buttonpressed(input:get_button_name("ranged"))
            end
          elseif spell == "recharge" then
            self:buttonpressed(input:get_button_name("recharge"))
          elseif spell == "pickup" then
            self:buttonpressed(input:get_button_name("pickup"))
          elseif spell == "inventory" then
            self:buttonpressed(input:get_button_name("inventory"))
          elseif spell == "crafting" then
            self:buttonpressed(input:get_button_name("crafting"))
          elseif spell == "action" then
            self:buttonpressed(input:get_button_name("action"))
          else
            local hotkeyInfo = player.hotkeys[spell]
            local hotkeyItem = hotkeyInfo.hotkeyItem
            if (hotkeyItem.target_type == "self" or not hotkeyItem.target_type) and hotkeyItem:use(player,player) ~= false then
              advance_turn()
            elseif (hotkeyItem.target_type and hotkeyItem.target_type ~= "self") then
              if actionResult == hotkeyItem or actionItem == hotkeyItem then
                cancel_targeting()
              else
                hotkeyItem:target(target,player)
              end
            end
          end
          return
        end
      end
      
      for creat,coords in pairs(self.sidebarCreats) do
        if x*uiScale >= coords.minX and x*uiScale <= coords.maxX and y*uiScale >= coords.minY and y*uiScale <= coords.maxY then
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
    --If doing multi-target, remove last target
    if action == "targeting" then
      self:buttonpressed(input:get_button_name("escape"))
      return
    end
    --Check if you right clicked on the sidebar
    for creat,coords in pairs(self.sidebarCreats) do
      if not self.contextualMenu and x >= coords.minX and x <= coords.maxX and y >= coords.minY and y <= coords.maxY then
        self.contextualMenu = ContextualMenu(creat.x,creat.y,x-300,y)
      end
    end
    --Check if you right clicked on a tile
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

function game:buttonpressed(key,scancode,isRepeat)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat)
  --Pie:keypressed(key)
  
  if self.moveBlocked then return false end -- If something is preventing movement, don't do anything
  
	if (action == "dying") then 
    if player.perception == 0 and not currGame.cheats.regenMapOnDeath then
      return game_over()
    end
    return false
	elseif player.path ~= nil then
		player.path = nil
		action = "moving"
  elseif self.warning then
    if key == "yes" or key == "enter" then
      local args = self.warning.afterArgs or {}
      self.warning.afterFunc(unpack(args))
      self.warning = nil
    elseif key == "no" or key == "escape" then
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
  elseif key == "camera_north" or key == "camera_south" or key == "camera_east" or key == "camera_west" or key == "camera_northwest" or key == "camera_northeast" or key == "camera_southwest" or key == "camera_southeast" then
    local x = (string.find(key,"east") and 1 or (string.find(key,"west") and -1 or 0))
    local y = (string.find(key,"south") and 1 or (string.find(key,"north") and -1 or 0))
    output:move_camera(x,y)
	elseif (key == "wait") and action=="moving" then
    output:sound('wait',0)
		advance_turn()
    local enter = currMap:enter(player.x,player.y,player,player.x,player.y) --run the "enter" code for a feature, f'rex, lava burning you even if you don't move
	elseif (key == "spell") then
    if action == "targeting" then
      if actionResult and actionResult.min_targets and #game.targets >= actionResult.min_targets then
        if perform_target_action(game.targets) then
          return
        end
      end
    end
    Gamestate.switch(spellscreen)
  elseif (key == "inventory") then
		Gamestate.switch(inventory)
  elseif (key == "drop") then
		Gamestate.switch(inventory,nil,"drop")
  elseif (key == "throw") then
		Gamestate.switch(inventory,{filter="throwable"},"throw")
  elseif (key == "use") then
		Gamestate.switch(inventory,{filter="usable"},"use")
  elseif (key == "equip") then
		Gamestate.switch(inventory,{filter="equippable"},"equip")
  elseif (key == "crafting" and gamesettings.crafting and gamesettings.craft_anywhere) then
		Gamestate.switch(crafting)
	elseif (key == "examine") then
		if action=="targeting" then
      cancel_targeting()
    else
      action="targeting"
    end
  elseif key == "attack" then
    if action == "moving" then
      action = "attacking"
    elseif action == "attacking" then
      action = "moving"
    elseif action == "targeting" then
      cancel_targeting()
      action="attacking"
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
      if (not attack.charges or attack.charges > 0) and not attack.cooldown then
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
      local projectile=nil
      local free_aim = true
      local i = 1
      for _,attack_instance in ipairs(player:get_ranged_attacks()) do
        local attack = rangedAttacks[attack_instance.attack]
        if (not attack_instance.charges or attack_instance.charges > 0) and not attack_instance.cooldown then
          attackName = attackName .. (i > 1 and ", " or "") .. attack.name
          i = i + 1
          if attack.min_range and (min_range == nil or attack.min_range < min_range) then
            min_range = attack.min_range
          end
          if attack.range and (range == nil or attack.range < range) then
            range = attack.range
          end
          if attack.projectile then
            projectile=true
          end
          if attack.free_aim == false then
            free_aim = false
          end
        end
      end --end ranged attack for
      local attackFunction = function(_,target)
        local result = false
        for i,attack_instance in ipairs(player:get_ranged_attacks()) do
          local attack = rangedAttacks[attack_instance.attack]
          if (not attack_instance.charges or attack_instance.charges > 0) and attack:calc_hit_chance(player,target,attack_instance.item) > 0 and not attack_instance.cooldown then
            local proj = attack:use(target,player,attack_instance.item)
            if proj ~= false then
              result = true
            end
            if proj and i > 1 then
              proj.pause = (i-1)/10
            end
          end --end can use attack if
        end --end ranged attack for
        return result
      end --end attackFunction
      allAttacks.name = attackName
      allAttacks.use = attackFunction
      allAttacks.min_range,allAttacks.range = min_range,range
      allAttacks.projectile=projectile
      allAttacks.target_type="creature"
      allAttacks.free_aim = free_aim
      allAttacks.baseType = "ranged"
      allAttacks.get_potential_targets = RangedAttack.get_potential_targets
      actionResult=allAttacks
      game.targets = {}
      if target then
        output:setCursor(target.x,target.y,true)
      else
        output:setCursor(player.x,player.y,true)
      end
    else --no attacks available, try to recharge if possible
      local recharge = false
      for i, attack_instance in ipairs(ranged_attacks) do
        local attack = rangedAttacks[attack_instance.attack]
        if not attack_instance.cooldown and ((attack_instance.item and attack_instance.item.charges) or (not attack_instance.item and attack.active_recharge)) then
          if attack:recharge(player,attack_instance.item) ~= false then
            recharge = true
          end
        end
      end
      if recharge == false then
        output:out("You can't use any ranged attacks right now.")
        return
      else
         advance_turn()
      end
    end
  elseif key == "recharge" then
    local recharge = false
    for i, attack_instance in ipairs(player:get_ranged_attacks()) do
      local attack = rangedAttacks[attack_instance.attack]
      if (attack_instance.item and attack_instance.item.charges) or (not attack_instance.item and attack.active_recharge) then
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
      if #self.targets > 0 then
        table.remove(self.targets,#self.targets)
      else
        cancel_targeting()
      end
    elseif action == "attacking" then
      action="moving"
		else
			Gamestate.switch(pausemenu)
		end
	elseif key == "messages" then
		Gamestate.switch(messages)
	elseif key == "enter" then
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
    local items = currMap:get_tile_items(player.x,player.y,gamesettings.can_pickup_adjacent_items)
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
      if actions[1].entity.baseType == "feature" then
        if actions[1].entity:action(player,actions[1].id) ~= false then
          advance_turn()
        end
      elseif actions[1].entity.baseType == "creature" then
        Gamestate.switch(conversation,actions[1].entity,player,actions[1].dialogID)
      end
    elseif #actions > 1 then
      local list = {}
      for _,action in ipairs(actions) do
        local direction = ""
        local entity = action.entity
        if entity.y < player.y then direction = direction .. "north"
        elseif entity.y > player.y then direction = direction .. "south" end
        if entity.x < player.x then direction = direction .. "west"
        elseif entity.x > player.x then direction = direction .. "east" end
        local selectFunction = (entity.baseType == "feature" and entity.action or (entity.baseType == "creature" and Gamestate.switch))
        local selectArgs = (entity.baseType == "feature" and {entity,player,action.id} or {conversation,entity,player,action.dialogID})
        list[#list+1] = {text=action.text .. ((direction ~= "" and not action.noDirection) and " (" .. ucfirst(direction) .. ")" or ""),description=action.description,selectFunction=selectFunction,selectArgs=selectArgs,image=(action.image or 'feature' .. (entity.image_name or entity.id)),image_color=(action.image_color or (entity.use_color_with_tiles or (gamesettings.always_use_color_with_tiles and entity.use_color_with_tiles ~= false) and entity.color) or nil),order=action.order}
      end
      Gamestate.switch(multiselect,list,"Select an Action",true,true)
    end
  elseif player.hotkeys and (player.hotkeys[key] or player.hotkeys[tonumber(key)] or (key == 0 and player.hotkeys[10])) then
    local hotkeyInfo = player.hotkeys[key] or player.hotkeys[tonumber(key)]
    local hotkeyItem = hotkeyInfo.hotkeyItem
    if action == "targeting" and actionResult == hotkeyItem then
      cancel_targeting()
    elseif (hotkeyItem.target_type == "self" or not hotkeyItem.target_type) and hotkeyItem:use(player,player) ~= false then
      advance_turn()
    elseif (hotkeyItem.target_type and hotkeyItem.target_type ~= "self") then
      hotkeyItem:target(target,player)
    elseif hotkeyItem.throwable then
      action="targeting"
      actionResult=rangedAttacks[hotkeyItem.ranged_attack]
      actionItem=hotkeyItem
      game.targets = {}
    elseif hotkeyItem.equippable then
      if not player:is_equipped(hotkeyItem) then
        local use,response = player:equip(hotkeyItem)
        output:out(response)
        if use ~= false then advance_turn() end
      end --end if it's equipped or not
    end --end hotkey check
  end -- end key if
end -- end function

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
        if currGame and currGame.cheats.regenMapOnDeath then 
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
  self.entries = {}
  local spellY = self.y
  if not self.creature then
    local feat = currMap:get_blocking_feature(x,y)
    if feat and feat.attackable then
      self.attackable_feature = feat
      self.entries[#self.entries+1] = {name="Attack " .. feat.name,y=spellY,action="attack"}
      spellY = spellY+fontPadding
    end
  end
  if self.creature then
    spellY = spellY+fontPadding
    local touching = player:touching(self.creature)
    if touching then
      self.entries[#self.entries+1] = {name="Attack",y=spellY,action="attack"}
      spellY = spellY+fontPadding
    end
    self.entries[#self.entries+1] = {name="Set as Target",y=spellY,action="target"}
    spellY = spellY+fontPadding
    local ranged_attacks = player:get_ranged_attacks()
    if #ranged_attacks > 0 then
      local max_cooldown = 0
      local ranged_text = "Ranged: "
      for i,attack_instance in ipairs(ranged_attacks) do
        local attack = rangedAttacks[attack_instance.attack]
        local item = attack_instance.item or nil
        ranged_text = ranged_text .. attack:get_name()
        if attack_instance.charges and attack_instance.hide_charges ~= true then
          ranged_text = ranged_text .. " (" .. attack_instance.charges .. ")"
        end
        if attack_instance.cooldown then
          ranged_text = ranged_text .. " (" .. attack_instance.cooldown .. " turns to recharge)"
        end
        if i < #ranged_attacks then ranged_text = ranged_text .. ", " end
      end --end ranged attack for
      
      self.entries[#self.entries+1] = {name=ranged_text,y=spellY,action="ranged"}
      spellY = spellY+fontPadding
      --[[if attack.active_recharge then
        self.entries[3] = {name="Recharge/Reload",y=spellY,action="recharge"}
        spellY=spellY+fontPadding
      end]]
    end
  else
    self.entries[#self.entries+1] = {name="Move To",y=spellY,action="moveto"}
    spellY = spellY+fontPadding
  end
  local touching = currMap:touching(player.x,player.y,x,y)
  if touching then
    local featureActions = currMap:get_tile_actions(x,y,player,not (x == player.x and y==player.y))
    if #featureActions > 0 then
      for _,action in ipairs(featureActions) do
        self.entries[#self.entries+1] = {name=action.text,action="featureAction",entity=action.entity,actionID=action.id,y=spellY}
        spellY = spellY+fontPadding
      end
    end
  end
  for _,spell in pairs(player:get_spells()) do
    local spellID = spell.id
    if spell.target_type == "tile" or spell.target_type == "self" or (spell.target_type == "creature" and self.creature) then
      self.entries[#self.entries+1] = {name=spell.name,y = spellY,action=spell,cooldown=player.cooldowns[spell],charges=spell.charges,active=spell.active}
      spellY = spellY+fontPadding
    end
  end
  if self.creature then
    self.entries[#self.entries+1] = {name="Examine " .. self.creature:get_name(),y=spellY,action="examine",creature=self.creature}
    spellY = spellY+fontPadding
  end
  if self.creature and totalstats.creature_kills and totalstats.creature_kills[self.creature.id] then
    self.entries[#self.entries+1] = {name="View " .. ucfirst(possibleMonsters[self.creature.id].name) .. " in Monsterpedia",y=spellY,action="monsterpedia"}
    spellY = spellY+fontPadding
  end
  local items = currMap:get_tile_items(self.target.x,self.target.y)
  if #items > 0 then
    for _,item in pairs(items) do
      self.entries[#self.entries+1] = {name="Examine " .. item:get_name(),y=spellY,action="examine",item=item}
      spellY = spellY+fontPadding
    end
    if (x == player.x and y == player.y) or (touching and gamesettings.can_pickup_adjacent_items) then
      if #items > 1 then
        self.entries[#self.entries+1] = {name="Pick up Items",y=spellY,action="pickup",}
      else
        self.entries[#self.entries+1] = {name="Pick up " .. items[1]:get_name(),y=spellY,action="pickup"}
      end
      spellY = spellY+fontPadding
    end
  end
  self.maxY = spellY
  self.height = spellY-self.y
end

function ContextualMenu:mouseSelect(mouseX,mouseY)
  local fontPadding = prefs['descFontSize']
  if mouseX>=self.x and mouseX<=self.maxX and mouseY>=self.y and mouseY<=self.maxY then
    for iid,item in ipairs(self.entries) do
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
    love.graphics.rectangle("fill",self.x,self.entries[self.selectedItem].y,self.width+1,fontPadding)
    setColor(255,255,255,255)
  end
  
  if self.creature then
    love.graphics.print(self.creature:get_name(true),self.x,self.y)
    love.graphics.line(self.x,self.y+fontPadding,self.x+self.width+1,self.y+fontPadding)
  end
  for _,item in ipairs(self.entries) do
    local no_deactivate = (item.active and item.no_manual_deactivate)
    if item.cooldown or no_deactivate then
      setColor(100,100,100,255)
    end
    love.graphics.print(item.name .. (item.cooldown and " (" .. item.cooldown .. " turns)" or "") .. (item.charges and " (" .. item.charges .. ")" or "") ..(item.active and " (Active)" or ""),self.x,item.y)
    if item.cooldown or no_deactivate then
      setColor(255,255,255,255)
    end
  end
  love.graphics.setFont(fonts.mapFont)
end

function ContextualMenu:click(x,y)
  local fontPadding = prefs['descFontSize']
  local useItem = nil
  if self.selectedItem then
    useItem = self.entries[self.selectedItem]
  else  
    for _,item in ipairs(self.entries) do
      if y>item.y-1 and y<item.y+fontPadding then
        useItem = item
        break
      end
    end
  end
  if useItem then
    if useItem.action == "attack" then
      player:attack(self.creature or self.attackable_feature)
      advance_turn()
    elseif useItem.action == "target" then
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
      local recharge = false
      for i, attack_instance in ipairs(player:get_ranged_attacks()) do
        local attack = rangedAttacks[attack_instance.attack]
        if (attack_instance.item and attack_instance.item.charges) or (not attack_instance.item and attack.active_recharge) then
          if attack:recharge(player,attack_instance.item) ~= false then
            recharge = true
          end
        end
      end
      if recharge ~= false then
        advance_turn()
      end
    elseif useItem.action == "featureAction" then
      if useItem.entity:action(player,useItem.actionID) ~= false then
        advance_turn()
      end
    elseif useItem.action == "examine" then
      if useItem.item then
        Gamestate.switch(examine_item,useItem.item)
      elseif useItem.creature then
        Gamestate.switch(examine_creature,useItem.creature)
      end
    elseif useItem.action == "pickup" then
      local items = currMap:get_tile_items(self.target.x,self.target.y)
      if #items == 1 then
        if player:pickup(items[1]) ~= false then
          advance_turn()
        end
      elseif #items > 1 then
        Gamestate.switch(multipickup)
      end
    elseif useItem.action == "ranged" then
      local ranged_attacks = player:get_ranged_attacks()
      local anyAvailable = false
      for i, attack in ipairs(ranged_attacks) do
        if not attack.cooldown and (not attack.charges or attack.charges > 0)then
          anyAvailable = true
          break
        end
      end --end loopthrough to check charges
      if anyAvailable then
        action="targeting"
        local allAttacks = {}
        local attackName = ""
        local min_range,range=nil,nil
        local i = 1
        for _,attack_instance in ipairs(player:get_ranged_attacks()) do
          if not attack_instance.cooldown and (not attack_instance.charges or attack_instance.charges > 0 ) then
            local attack = rangedAttacks[attack_instance.attack]
            i = i + 1
            attackName = attackName .. (i > 1 and ", " or "") .. attack.name
            if attack.min_range and (min_range == nil or attack.min_range < min_range) then
              min_range = attack.min_range
            end
            if attack.range and (range == nil or attack.range < range) then
              range = attack.range
            end
          end
        end --end ranged attack for
        local attackFunction = function(_,target)
          local result = false
          for i,attack_instance in ipairs(player:get_ranged_attacks()) do
            local attack = rangedAttacks[attack_instance.attack]
            if (not attack_instance.charges or attack_instance.charges > 0) and attack:calc_hit_chance(player,target,attack_instance.item) > 0 and not attack_instance.cooldown then
              local proj = attack:use(target,player,attack_instance.item)
              if proj ~= false then
                result = true
              end
              if proj and i > 1 then
                proj.pause = (i-1)/10
              end
            end --end can use attack if
          end --end ranged attack for
          return result
        end --end attackFunction
        allAttacks.name = attackName
        allAttacks.use = attackFunction
        allAttacks.min_range,allAttacks.range = min_range,range
        allAttacks.target_type="creature"
        actionResult=allAttacks
        game.targets = {}
        setTarget(self.target.x,self.target.y)
      else --no attacks available, try to recharge if possible
        local recharge = false
        for i, attack_instance in ipairs(ranged_attacks) do
          local attack = rangedAttacks[attack_instance.attack]
          if (attack_instance.item and type(attack_instance.item.charges) == "number" and not attack_instance.item.cooldown) or (not attack_instance.item and attack.active_recharge) then
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
    else
      if useItem.action.target_type == "self" then
        if useItem.action:use(self.creature or self.target,player) then advance_turn() end
      else
        useItem.action:target(nil,player)
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
    if self.selectedItem > #self.entries then self.selectedItem = #self.entries end
  else --if there's no selected item, set it to the first one
    self.selectedItem = 1
  end
end

-- Warning:
local Warning = Class{}

function game:warn_player(text,afterFunc,afterArgs)
  self.warning = Warning(text,afterFunc,afterArgs)
  if not self.warning.afterFunc then self.warning = nil end --if no function or an is passed, cancel the warning
end

function Warning:init(text,afterFunc,afterArgs)
  local uiScale = prefs['uiScale']
  local fontSize = fonts.textFont:getHeight()
  local tileSize = output:get_tile_size(true)
  self.text = text or "Are you sure you want to do that?"
  self.afterFunc = type(afterFunc) == "function" and afterFunc or nil
  self.afterArgs = afterArgs
  self.width = math.min(math.max(tileSize*3,fonts.textFont:getWidth(self.text)+tileSize),math.ceil(love.graphics.getWidth()/uiScale/2))
  local _,hlines = fonts.textFont:getWrap(self.text,self.width)
  self.height = (#hlines+2)*fontSize+(tileSize*1.5)
  self.x,self.y=round(love.graphics.getWidth()/uiScale/2-self.width/2),round(love.graphics.getHeight()/uiScale/2-self.height/2)
end

function Warning:draw()
  local uiScale = prefs['uiScale']
  local fontSize = fonts.textFont:getHeight()
  local tileSize = output:get_tile_size(true)
  local midX = round(self.x+self.width/2+tileSize/2)
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.setFont(fonts.textFont)
  output:draw_window(self.x,self.y,self.x+self.width,self.y+self.height)
  love.graphics.printf(self.text,self.x+math.ceil(tileSize/2),self.y+tileSize,self.width,"center")
  local buttonPad = tileSize
  local buttonW = math.max(fonts.buttonFont:getWidth("(Y)es"),fonts.buttonFont:getWidth("(N)o"))+buttonPad
  self.yesButton = output:button(midX-buttonW,self.y+self.height-tileSize,buttonW,nil,nil,"(Y)es",true)
  self.noButton = output:button(midX,self.y+self.height-tileSize,buttonW,nil,nil,"(N)o",true)
  love.graphics.pop()
end

--Popup stuff:
function game:show_map_description()
  local desc = currMap.description or ""
  local _, count = string.gsub(desc, "\n", "\n")
  local branch = currWorld.branches[currMap.branch]
  output:show_popup(desc,currMap:get_name() .. "\n" .. " ",4+count,true,false,nil,true)
end

function game:show_popup(...)
  return output:show_popup(...)
end