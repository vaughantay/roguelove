crafting = {}

function crafting:enter(previous,info)
  info = info or {}
  self.hideUncraftable = self.hideUncraftable or false
  self.stash = info.stash
  self.recipe_types = info.recipe_types
  self.tool_properties = info.tool_properties
  self:refresh_craft_list()
  self.craft_coordinates = {toggle={minX=0,maxX=0,minY=0,maxY=0}}
  self.makeAmt = 1
  self.cursorX = 1
  self.cursorY = 0
  self.sideCursorY = 0
  self.outText = nil
  self.yModPerc = 100
  self.scrollY = 0
  self.descScrollY = 0
  self.scrollMax = 0
  self.descScrollMax = 0
  self.sidebarX = 0
  self.startY = 0
  self.buttons = {}
  self.maxButtonY = 0
  self.lineCountdown = 0.5
  
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
end

function crafting:refresh_craft_list()
  local craft_list = player:get_all_possible_recipes(self.hideUncraftable,self.recipe_types,self.stash)
  local crafts = {}
  for _,craftID in ipairs(craft_list) do
    local craftData = {id=craftID,craftable=true,secondary_ingredients={},amount=1}
    local recipe = possibleRecipes[craftID]
    local modifiers = {}
    craftData.bonuses_from_ingredients = recipe.bonuses_from_ingredients
    craftData.replace_bonuses = recipe.replace_bonuses
    if recipe.types then
      for _,rtype in ipairs(recipe.types) do
        modifiers.property_requirements_percent = modifiers.property_requirements_percent or 0 + player:get_bonus(rtype .. '_recipe_property_requirements_percent')
      end
    end
    --First look at igredients:
    if recipe.ingredients then
      craftData.ingredients = {}
      for iid,amount in pairs(recipe.ingredients) do
        local stash
        local item = possibleItems[iid]
        local _,_,player_amount = player:has_item(iid)
        if player_amount < amount and self.stash then
          local _,_,stash_amount = self.stash:has_item(iid)
          if stash_amount >= amount then
            player_amount = stash_amount
            stash = self.stash
          end
        end
        local ing = {id=iid,amount=amount,player_amount=player_amount,enough=(player_amount>=amount),stash=stash}
        craftData.ingredients[ing.id] = ing
        if player_amount < amount then craftData.craftable = false end
      end
    end
    --Class check:
    if recipe.requires_class then
      craftData.requires_class = playerClasses[recipe.requires_class]
      craftData.is_class = (player.class == recipe.requires_class)
      if not craftData.is_class then craftData.craftable=false end
    end
    --Faction check:
    if recipe.requires_faction then
      craftData.requires_faction = currWorld.factions[recipe.requires_faction]
      craftData.is_faction_member = player:is_faction_member(recipe.requires_faction)
      if not craftData.is_faction_member then craftData.craftable=false end
    end
    --Spell check:
    if recipe.requires_spells then
      craftData.requires_spells = {}
      for _,spell in ipairs(recipe.requires_spells) do
        local has_spell = player:has_spell(spell)
        craftData.requires_spells[#craftData.requires_spells+1] = {spellID=spell,spell_name=possibleSpells[spell].name,has_spell=has_spell}
        if not has_spell then craftData.craftable = false end
      end
    end
    --Specific Tool Check:
    if recipe.requires_tools then
      craftData.requires_tools = {}
      for _,tool in ipairs(recipe.requires_tools) do
        local has_item = player:has_item(tool) or (self.stash and self.stash:has_item(tool))
        craftData.requires_tools[#craftData.requires_tools+1] = {toolID=tool,has_item=has_item}
        if not has_item then craftData.craftable=false end
      end
    end --end specific tool for

    --Tool Tag Check:
    if recipe.tool_properties then
      craftData.tool_properties = {}
      for _,prop in ipairs(recipe.tool_properties) do
        craftData.tool_properties[prop] = false
        if self.tool_properties and in_table(prop,self.tool_properties) then
          craftData.tool_properties[prop] = true
        else
          for _,item in pairs(player:get_inventory()) do
            if item.crafting_tool_properties and in_table(prop,item.crafting_tool_properties) then
              craftData.tool_properties[prop] = item
              break
            end --end if has_tag
          end -- end inventory for
          if not craftData.tool_properties[prop] and self.stash then
            for _,item in pairs(self.stash:get_inventory()) do
              if item.crafting_tool_properties and in_table(prop,item.crafting_tool_properties) then
                craftData.tool_properties[prop] = item
                break
              end --end if has_tag
            end -- end inventory for
          end
        end
        if not craftData.tool_properties[prop] then
          craftData.craftable=false
        end
      end --end tag for
    end --end tool tag for
    
    --Ingredient property check:
    if recipe.ingredient_properties then
      craftData.ingredient_properties = {}
      for prop,amt in pairs(recipe.ingredient_properties) do
        local actualAmt = math.max(1,round(amt + amt*((modifiers.property_requirements_percent or 0)/100)))
        craftData.ingredient_properties[prop] = {required=actualAmt,amount=0,selected=0,optional=(recipe.optional_properties and in_table(prop,recipe.optional_properties))}
        for _, item in pairs(player:get_inventory()) do
          if item.crafting_ingredient_properties and item.crafting_ingredient_properties[prop] and not recipe.results[item.id]  then
            local typeMatch = false
            if recipe.ingredient_types then
              if item.crafting_ingredient_types then
                for _,itype in pairs(recipe.ingredient_types) do
                  if in_table(itype,item.crafting_ingredient_types) then
                    typeMatch = true
                    break
                  end
                end
              end
            else --if ingredient types aren't set, don't worry about matching
              typeMatch = true
            end
            if typeMatch then
              if recipe.requiredTags then
                if item.tags then
                  for _,tag in ipairs(recipe.requiredTags) do
                    if not in_table(tag,item.tags) then
                      typeMatch = false
                      break
                    end
                  end
                else
                  typeMatch = false
                end
              end
              if typeMatch and recipe.forbiddenTags then
                if item.tags then
                  for _,tag in ipairs(recipe.forbiddenTags) do
                    if in_table(tag,item.tags) then
                      typeMatch = false
                      break
                    end
                  end
                end
              end
            end
            if typeMatch then
              craftData.ingredient_properties[prop][#craftData.ingredient_properties[prop]+1] = {item=item,amount=item.crafting_ingredient_properties[prop]}
              craftData.ingredient_properties[prop].amount = craftData.ingredient_properties[prop].amount + item.crafting_ingredient_properties[prop]*item.amount
              craftData.secondary_ingredients[item] = 0
            end
          end
        end
        if self.stash then
          for _, item in pairs(self.stash:get_inventory()) do
            if item.crafting_ingredient_properties and item.crafting_ingredient_properties[prop] and not recipe.results[item.id]  then
              local typeMatch = false
              if recipe.ingredient_types then
                if item.crafting_ingredient_types then
                  for _,itype in pairs(recipe.ingredient_types) do
                    if in_table(itype,item.crafting_ingredient_types) then
                      typeMatch = true
                      break
                    end
                  end
                end
              else --if ingredient types aren't set, don't worry about matching
                typeMatch = true
              end
              if typeMatch then
                craftData.ingredient_properties[prop][#craftData.ingredient_properties[prop]+1] = {item=item,amount=item.crafting_ingredient_properties[prop],stash=self.stash}
                craftData.ingredient_properties[prop].amount = craftData.ingredient_properties[prop].amount + item.crafting_ingredient_properties[prop]*item.amount
                craftData.secondary_ingredients[item] = 0
              end
            end
          end
        end
        if craftData.ingredient_properties[prop].amount < amt and not craftData.ingredient_properties[prop].optional then
          craftData.craftable = false
        end
      end
    end
    
    --Level Requirement Check:
    if recipe.required_level then
      craftData.required_level = recipe.required_level
      craftData.is_level = (player.level >= recipe.required_level)
      if not craftData.is_level then craftData.craftable = false end
    end
    
    if recipe.stat_requirements then
      craftData.stat_requirements = {}
      for stat,requirement in pairs(recipe.stat_requirements) do
        local player_stat = (player:get_stat(stat) or player:get_bonus_stat(stat)) or 0
        local meets_requirement = (player_stat >= requirement)
        craftData.stat_requirements[stat] = {requirement=requirement,player_stat=player_stat,meets_requirement=meets_requirement}
        if not meets_requirement  then
          craftData.craftable = false
        end
      end
    end
    
    if recipe.skill_requirements then
      craftData.skill_requirements = {}
      for skill,requirement in pairs(recipe.skill_requirements) do
        local player_skill = player:get_skill(skill)
        local meets_requirement = (player_skill >= requirement)
        craftData.skill_requirements[skill] = {requirement=requirement,player_stat=player_skill,meets_requirement=meets_requirement}
        if not meets_requirement  then
          craftData.craftable = false
        end
      end
    end
    
    if recipe.requires then
      local canCraft,result = recipe:requires(player)
      if canCraft == false then craftData.craftable = false end
      craftData.meets_requires_code = not (canCraft == false)
      if result and type(result) == "string" then 
        craftData.requires_text = result
      elseif recipe.requires_text then
        craftData.requires_text = recipe.requires_text
      elseif canCraft == false then
        craftData.requires_text = "You do not meet the other requirements needed to craft this."
      end
    end
    
    local resCount = 1
    if not self.hideUncraftable or craftData.craftable then crafts[#crafts+1] = craftData end
    if recipe.name then
      craftData.name = recipe.name
    else
      craftData.name = ""
      for item,amount in pairs(recipe.results) do
        if possibleItems[item] then
          if resCount > 1 then craftData.name = craftData.name .. ", " end
          if amount > 1 then
            craftData.name = craftData.name .. amount .. " " .. ucfirst(possibleItems[item].pluralName or "x " .. ucfirst(possibleItems[item].name))
          else
            craftData.name = craftData.name .. ucfirst(possibleItems[item].name)
          end
        end
        resCount = resCount + 1
      end
    end
  end --end craft list for
  sort_table(crafts,'name')
  self.crafts = crafts
end

function crafting:draw()
  local uiScale = (prefs['uiScale'] or 1)
  game:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
	local padX,padY = (prefs['noImages'] and 5 or 20),(prefs['noImages'] and 5 or 20)
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  local fontSize = prefs['fontSize']
  local tileSize = output:get_tile_size(true)
  local lineSize = math.max(fontSize,tileSize)
  local outHeight = 0
	
  self.screenMax = round((height/(fontSize+2)/2)/uiScale)
  local padding = (prefs['noImages'] and 16 or 32)
	love.graphics.setFont(fonts.textFont)
  local sidebarX = round(width/2/uiScale)+padding
  local window1w = sidebarX-padding-padX
  local window2w = round(width/uiScale)-sidebarX-padX-padding
  self.sidebarX = sidebarX
  output:draw_window(1,1,sidebarX-padding,height-padding)
  output:draw_window(sidebarX,1,width-padding,height-padding)
  
  love.graphics.printf("Crafting",padX,padY,window1w,"center")
  --Display output text:
  local printY=padY+prefs['fontSize']*2
  if self.outText then
    local _,olines = fonts.textFont:getWrap(self.outText, window1w)
    outHeight = (#olines+2)*prefs['fontSize']
    love.graphics.printf(self.outText,padX,printY,window1w,"center")
    printY=printY+outHeight
  end
  
  --Display box to filter out uncraftables
  local midX = round(window1w/2)
  local textW = fonts.textFont:getWidth("Show Only Craftable Recipes")
  local boxX = round(midX-textW/2)
  if self.cursorY == 0 then
    setColor(100,100,100,255)
    love.graphics.rectangle('fill',boxX-padX,printY-8,textW+32+padX*2,prefs['fontSize']+8)
    setColor(255,255,255,255)
  end
  if prefs['noImages'] then
    love.graphics.print((self.hideUncraftable and "(X)" or "( )"),boxX,printY)
  else
    love.graphics.draw((self.hideUncraftable and images.uicheckboxchecked or images.uicheckbox),boxX,printY)
  end
  self.craft_coordinates['toggle'] = {minX=boxX-padX,minY=printY-8,maxX=boxX+textW+32+padX*2,maxY=printY+prefs['fontSize']}
  love.graphics.print("Show Only Craftable Recipes",boxX+32,printY-8)
  printY=printY+prefs['fontSize']*2
  
  local startY = printY
  self.startY = startY
  
  --List crafts:
  love.graphics.push()
  --Create a "stencil" that stops 
  local function stencilFunc()
    love.graphics.rectangle("fill",padX,startY,window1w,height-printY-8)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scrollY)
	for i,craftInfo in ipairs(self.crafts) do
    local craftID = craftInfo.id
    local name = ""
    local recipe = possibleRecipes[craftID]
    name = craftInfo.name
    local _, nameLines = fonts.textFont:getWrap(name, window1w)
    if self.selected == i then
      setColor(150,150,150,255)
      love.graphics.rectangle("fill",padX,printY,window1w-padX,#nameLines*fontSize+2)
    elseif self.cursorY == i then
      setColor(75,75,75,255)
      love.graphics.rectangle("fill",padX,printY,window1w-padX,#nameLines*fontSize+2)
    end
    setColor(255,255,255,255)
    self.craft_coordinates[i] = {minX=padX,minY=printY,maxX=window1w-padX,maxY=printY+#nameLines*fontSize}
    if not craftInfo.craftable then
      setColor(200,0,0,255)
    end
		love.graphics.printf(name,padX,printY,window1w)
    if not craftInfo.craftable then
      setColor(255,255,255,255)
    end
		printY=printY+#nameLines*fontSize
	end
  if count(self.crafts) < 1 then
    love.graphics.printf("You can't craft anything right now.",padX,printY,window1w,"center")
  end
  love.graphics.setStencilTest()
  love.graphics.pop()
  --Scrollbars
  if printY*uiScale > height-startY then
    self.scrollMax = math.ceil((printY-(startY+(height/uiScale-startY))+padding))
    local scrollAmt = self.scrollY/self.scrollMax
    if self.cursorX == 2 then
      setColor(150,150,150,255)
      love.graphics.rectangle('fill',window1w,startY,32,math.floor((height-padding)/uiScale)-startY)
      setColor(255,255,255,255)
    end
    self.scrollPositions = output:scrollbar(window1w,startY,math.floor((height-padding)/uiScale),scrollAmt,true)
  else
    self.scrollMax = 0
  end
  self.scrollY = math.min(self.scrollY,self.scrollMax)
  
  --Print info on selected craft:
  self.buttons = {}
  
  if (self.crafts[self.selected or self.cursorY] ~= nil) then
    love.graphics.push()
    --Create a "stencil" that stops 
    local function stencilFunc()
      love.graphics.rectangle("fill",sidebarX+padX,padY,window2w,height-padY-8)
    end
    love.graphics.stencil(stencilFunc,"replace",1)
    love.graphics.setStencilTest("greater",0)
    love.graphics.translate(0,-self.descScrollY)
    local craftInfo = self.crafts[self.selected or self.cursorY]
    local recipe = possibleRecipes[craftInfo.id]
    local descY = padding
    --List Results:
    local resultCount = count(recipe.results)
    love.graphics.printf((resultCount > 1 and "Results:" or "Result:"),sidebarX+padX,descY,window2w,"left")
    descY = descY+fontSize
    
    local bonuses = {}
    for iid,amount in pairs(recipe.results) do
      local item = possibleItems[iid]
      if item then
        item.baseType = "item"
        if item.id == nil then item.id = iid end
        local resultText = (amount > 1 and item.pluralName and amount .. " " .. ucfirst(item.pluralName) or ucfirst(item.name) .. (amount > 1 and " x " .. amount or "")) .. " (" .. item.description .. ")"
        output.display_entity(item,sidebarX+padX,descY,"force")
        love.graphics.printf(resultText,sidebarX+padX+tileSize,descY,window2w,"left")
        local _, dlines = fonts.textFont:getWrap(resultText,window2w)
        descY = descY+math.max(fontSize*(#dlines+1),lineSize)
        bonuses = (not craftInfo.replace_bonuses and item.bonuses and copy_table(item.bonuses) or {})
      end
    end
    descY = descY+fontSize
    local enchantments = {}
    local cons = {}
    if craftInfo.ingredients and craftInfo.bonuses_from_ingredients then
      for iid,ingInfo in pairs(craftInfo.ingredients) do
        local itemInfo = possibleItems[iid]
        if itemInfo.crafting_given_bonuses then
          for bonus,bonusAmt in pairs(itemInfo.crafting_given_bonuses) do
            bonuses[bonus] = (bonuses[bonus] or 0)+bonusAmt*ingInfo.amount
          end
        end
        if itemInfo.crafting_given_enchantments then
          for _,ench in pairs(itemInfo.crafting_given_enchantments) do
            enchantments[ench] = true
          end
        end
      end
    end
    if craftInfo.secondary_ingredients and craftInfo.bonuses_from_ingredients then
      for item,amt in pairs(craftInfo.secondary_ingredients) do
        if amt > 0 then
          if item.crafting_given_bonuses then
            for bonus,bonusAmt in pairs(item.crafting_given_bonuses) do
              bonuses[bonus] = (bonuses[bonus] or 0)+amt*bonusAmt
            end
          end
          if item.crafting_given_enchantments then
            for _,ench in pairs(item.crafting_given_enchantments) do
              enchantments[ench] = true
            end
          end
          if item.crafting_given_conditions then
            for conID,turns in pairs(item.crafting_given_conditions) do
              cons[conID] = (cons[conID] or 0)+amt*turns
            end
          end
        end
      end
    end
    if craftInfo.bonuses_from_ingredients then
      local bonusText = "Selected ingredients will provide bonuses."
      if count(bonuses) > 0 or count(enchantments) > 0 or count(conditions) > 0 then
        bonusText = "Selected ingredients will provide bonuses:"
        if count(enchantments) > 0 then
          for enchID,_ in pairs(enchantments) do
            local enchantment = enchantments[enchID]
            bonusText = bonusText .. "\n\tEnchantment: " .. ucfirst(enchantment.name or enchID)
          end
        end
        if count(bonuses) > 0 then
          for bonus,amt in pairs(bonuses) do
            local isPercent = (string.find(bonus,"percent") or string.find(bonus,"chance"))
            local bonusName = ucfirstall(string.gsub(bonus, "_", " ")) .. (type(amt) == "number" and ": " .. (amt > 0 and "+" or "") .. amt .. (isPercent and "%" or "") or "")
            bonusText = bonusText .. "\n\t" .. bonusName
          end
        end
        if count(cons) > 0 then
          for conID,turns in pairs(cons) do
            local condition = conditions[conID]
            bonusText = bonusText .. "\n\tCondition: " .. condition.name
          end
        end
      end
      love.graphics.printf(bonusText,sidebarX+padX,descY,window2w,"left")
      local _, dlines = fonts.textFont:getWrap(bonusText,window2w)
      descY = descY+math.max(fontSize*(#dlines+1),lineSize)
    end
    local buttonY = 0
    
    --Craft Buttons:
    if not craftInfo.craftable or craftInfo.not_enough_due_to_amount then
      setColor(150,150,150,255)
    elseif craftInfo.ingredient_properties then
      for _,prop in pairs(craftInfo.ingredient_properties) do
        if prop.selected < prop.required*craftInfo.amount and not prop.optional then
          setColor(150,150,150,255)
          break
        end
      end
    end
    local craftSelected = (self.selected and (self.sideCursorY == 0 and self.cursorX==1) or false)
    local buttonW = fonts.buttonFont:getWidth("Create")+25
    local craftButton = output:button(sidebarX+padX,descY,buttonW,nil,(craftSelected and 'hover' or nil),"Create")
    craftButton.buttonX = 1
    craftButton.buttonY = buttonY
    craftButton.buttonType = "craft"
    self.buttons[1] = craftButton
    setColor(255,255,255,255)
    if not recipe.single_craft_only then
      local amountW = fonts.textFont:getWidth(" Amount: ")
      love.graphics.print(" Amount: ",sidebarX+padX+buttonW,descY)
      local amountBoxW = fonts.textFont:getWidth("100")+8
      local minusButtonX = sidebarX+padX+buttonW+amountW
      local amountBoxX = minusButtonX+48
      local plusButtonX = amountBoxX+amountBoxW+16
      
      --Minus Button:
      local minusButton = output:tinybutton(minusButtonX,descY-6,nil,(minusMouse or (self.sideCursorY == buttonY and self.cursorX == 2) and "hover" or false),"-")
      minusButton.craftInfo = craftInfo
      minusButton.buttonX = 2
      minusButton.buttonY = buttonY
      minusButton.buttonType = "minusmain"
      self.buttons[#self.buttons+1] = minusButton
      
      --Amount Box:
      local numberEntry = {minX=amountBoxX,minY=descY,maxX=amountBoxX+amountBoxW,maxY=descY-2+fontSize+4,buttonX=3,buttonY=buttonY,buttonType="boxmain"}
      numberEntry.craftInfo = craftInfo
      self.buttons[#self.buttons+1] = numberEntry
      local amountMouse = (mouseX > numberEntry.minX and mouseX < numberEntry.maxX and mouseY > numberEntry.minY-self.scrollY and mouseY < numberEntry.maxY-self.scrollY)
      if (self.cursorX == 3 and self.sideCursorY == buttonY) or amountMouse then
        setColor(75,75,75,255)
        love.graphics.rectangle('fill',numberEntry.minX,numberEntry.minY,amountBoxW,fontSize+4)
        setColor(255,255,255,255)
        if self.lineOn and self.cursorX == 2 and self.sideCursorY == buttonY then
          local w = fonts.textFont:getWidth(tostring(craftInfo.amount))
          local lineX = amountBoxX+math.ceil(amountBoxW/2+w/2)
          love.graphics.line(lineX,descY,lineX,descY+fontSize)
        end
      end
      love.graphics.rectangle('line',numberEntry.minX,numberEntry.minY,amountBoxW,fontSize+4)
      love.graphics.printf(craftInfo.amount,amountBoxX,descY,amountBoxW,"center")

      --Plus Button:
      local plusButton = output:tinybutton(plusButtonX,descY-6,nil,(plusMouse or (self.sideCursorY == buttonY and self.cursorX == 4) and "hover" or false),"+")
      plusButton.craftInfo = craftInfo
      plusButton.buttonType = "plusmain"
      plusButton.buttonX = 4
      plusButton.buttonY = buttonY
      self.buttons[#self.buttons+1] = plusButton
    end
    
    descY = descY+tileSize
    --Specific Ingredients:
    love.graphics.printf("Ingredients:",sidebarX+padX,descY,window2w,"left")
    descY=descY+prefs['fontSize']+8
    local amountBoxW = fonts.textFont:getWidth("100")+8
    local minusButtonX = sidebarX+padX
    local amountBoxX = minusButtonX+48
    local plusButtonX = amountBoxX+amountBoxW+16
    local iconX = plusButtonX+48
    local ingredientX = iconX+tileSize
    local ingredientW = window2w-(ingredientX-(sidebarX+padX))
    if craftInfo.ingredients then
      for iid,ingInfo in pairs(craftInfo.ingredients) do
        local item = possibleItems[iid]
        item.baseType = "item"
        if item.id == nil then item.id = iid end
        local player_amount = ingInfo.player_amount or 0
        local amount = ingInfo.amount*(craftInfo.amount)
        local ingText = (amount > 1 and item.pluralName and amount .. " " .. ucfirst(item.pluralName) or ucfirst(item.name) .. (amount > 1 and " x " .. amount or "")) .. " (have " .. player_amount .. ")" .. (ingInfo.stash and " (From " .. ingInfo.stash.name .. ")" or "")
        output.display_entity(item,sidebarX+padX,descY,"force")
        if amount > player_amount then
          craftInfo.not_enough_due_to_amount = true
          setColor(200,0,0,255)
        else
          craftInfo.not_enough_due_to_amount = false
        end
        love.graphics.printf(ingText,sidebarX+padX+tileSize,descY,window2w,"left")
        if amount > player_amount then
          setColor(255,255,255,255)
        end
        local _, dlines = fonts.textFont:getWrap(ingText,window2w)
        descY = descY+math.max(prefs['fontSize']*#dlines,lineSize)
      end
    end
    --Property-based ingredients:
    if craftInfo.ingredient_properties then
      for prop,propInfo in pairs(craftInfo.ingredient_properties) do
        local propText = (propInfo.optional and "(Optional) " or "") .. ucfirst(prop) .. " ingredients adding " .. (propInfo.optional and "up " or "") .. "to " .. propInfo.required*(craftInfo.amount) .. " (" .. propInfo.selected .. " selected):"
        if propInfo.required*(craftInfo.amount) > propInfo.amount and not propInfo.optional then
          setColor(200,0,0,255)
        elseif propInfo.required*(craftInfo.amount) > propInfo.selected and not propInfo.optional then
          setColor(200,200,0,255)
        end
        love.graphics.printf(propText,sidebarX+padX,descY,window2w,"left")
        if propInfo.required*(craftInfo.amount) > propInfo.amount or propInfo.required*(craftInfo.amount) > propInfo.selected then
          setColor(255,255,255,255)
        end
        local _, dlines = fonts.textFont:getWrap(propText,window2w)
        descY = descY+fontSize*#dlines
        --Loop through possibilities:
        if #propInfo == 0 then
          descY = descY+8
          love.graphics.printf("\tYou have none.",sidebarX+padX,descY,window2w,"left")
          local _, dlines = fonts.textFont:getWrap("\tYou have none.",window2w)
          descY = descY+fontSize*(#dlines+1)
        else
          descY = descY + fontSize
          for _,details in ipairs(propInfo) do
            local item = details.item
            buttonY = buttonY+1
            --Minus Button:
            local minusButton = output:tinybutton(minusButtonX,descY-6,nil,(minusMouse or (self.sideCursorY == buttonY and self.cursorX == 1) and "hover" or false),"-")
            minusButton.craftInfo = craftInfo
            minusButton.property = propInfo
            minusButton.details = details
            minusButton.buttonX = 1
            minusButton.buttonY = buttonY
            minusButton.buttonType = "minus"
            self.buttons[#self.buttons+1] = minusButton
            
            --Amount Box:
            local numberEntry = {minX=amountBoxX,minY=descY,maxX=amountBoxX+amountBoxW,maxY=descY-2+fontSize+4,buttonX=2,buttonY=buttonY,buttonType="box"}
            numberEntry.craftInfo = craftInfo
            numberEntry.property = propInfo
            numberEntry.details = details
            self.buttons[#self.buttons+1] = numberEntry
            local amountMouse = (mouseX > numberEntry.minX and mouseX < numberEntry.maxX and mouseY > numberEntry.minY-self.scrollY and mouseY < numberEntry.maxY-self.scrollY)
            if (self.cursorX == 2 and self.sideCursorY == buttonY) or amountMouse then
              setColor(75,75,75,255)
              love.graphics.rectangle('fill',numberEntry.minX,numberEntry.minY,amountBoxW,fontSize+4)
              setColor(255,255,255,255)
              if self.lineOn and self.cursorX == 2 and self.sideCursorY == buttonY then
                local w = fonts.textFont:getWidth(tostring(craftInfo.secondary_ingredients[item]))
                local lineX = amountBoxX+math.ceil(amountBoxW/2+w/2)
                love.graphics.line(lineX,descY,lineX,descY+fontSize)
              end
            end
            love.graphics.rectangle('line',numberEntry.minX,numberEntry.minY,amountBoxW,fontSize+4)
            love.graphics.printf(craftInfo.secondary_ingredients[item],amountBoxX,descY,amountBoxW,"center")
        
            --Plus Button:
            local plusButton = output:tinybutton(plusButtonX,descY-6,nil,(plusMouse or (self.sideCursorY == buttonY and self.cursorX == 3) and "hover" or false),"+")
            plusButton.craftInfo = craftInfo
            plusButton.property = propInfo
            plusButton.details = details
            plusButton.buttonType = "plus"
            plusButton.buttonX = 3
            plusButton.buttonY = buttonY
            self.buttons[#self.buttons+1] = plusButton
            
            --Item display:
            local itemText = item:get_name(true,1) .. ": " .. details.amount .. " (have " .. item.amount .. ")" .. (item.possessor ~= player and " (From " .. item.possessor.name .. ")" or "")
            output.display_entity(item,iconX,descY-6,true,true)
            love.graphics.printf(itemText,ingredientX,descY,ingredientW,"left")
            local _, dlines = fonts.textFont:getWrap(propText,ingredientW)
            descY = descY+math.max(prefs['fontSize']*#dlines,tileSize)
          end
        end
      end
    end
    
    descY=descY+prefs['fontSize']
    
    if craftInfo.requires_tools then
      local toolCount = count(craftInfo.requires_tools)
      love.graphics.printf("Requires Tool" .. (toolCount > 1 and "s:" or ":"),sidebarX+padX,descY,window2w,"left")
      descY=descY+prefs['fontSize']+8
      for _,toolInfo in ipairs(craftInfo.requires_tools) do
        local item = possibleItems[toolInfo.toolID]
        if not toolInfo.has_item then
          setColor(200,0,0,255)
        end
        local toolText = "*" .. ucfirst(item.name)
        love.graphics.printf(toolText,sidebarX+padX,descY,window2w,"left")
        if not toolInfo.has_item then
          setColor(255,255,255,255)
        end
        local _, dlines = fonts.textFont:getWrap(toolText,window2w)
        descY = descY+prefs['fontSize']*#dlines
      end
      descY=descY+prefs['fontSize']
    end
    
    if craftInfo.tool_properties then
      local toolCount = count(craftInfo.tool_properties)
      love.graphics.printf("Requires tool" .. (toolCount > 1 and "s" or "") .. " or workspace with propert" .. (toolCount > 1 and "ies:" or "y:"),sidebarX+padX,descY,window2w,"left")
      descY = descY + prefs['fontSize']+8
      for prop,item in pairs(craftInfo.tool_properties) do
        local toolText = "*" .. ucfirst(prop) .. (item and type(item) == "table" and " (" .. ucfirst(item.name) .. ")" or "")
        if not item then
          setColor(200,0,0,255)
        end
        love.graphics.printf(toolText,sidebarX+padX,descY,window2w,"left")
        local _, dlines = fonts.textFont:getWrap(toolText,window2w)
        descY = descY+prefs['fontSize']*#dlines
        if not item then
          setColor(255,255,255,255)
        end
      end
      descY=descY+prefs['fontSize']
    end
    
    if craftInfo.requires_spells then
      local spellCount = #craftInfo.requires_spells
      love.graphics.printf("Requires spell" .. (spellCount > 1 and "s:" or ":"),sidebarX+padX,descY,window2w,"left")
      descY = descY+prefs['fontSize']+8
      for _,spellData in ipairs(craftInfo.requires_spells) do
        local spellText = "*" .. ucfirst(spellData.spell_name)
        if not spellData.has_spell then
          setColor(200,0,0,255)
        end
        love.graphics.printf(spellText,sidebarX+padX,descY,window2w,"left")
        local _, dlines = fonts.textFont:getWrap(spellText,window2w)
        descY = descY+prefs['fontSize']*#dlines
        if not spellData.has_spell then
          setColor(255,255,255,255)
        end
      end
      descY = descY+prefs['fontSize']
    end
    
    if craftInfo.requires_class then
      local classText = "Only Craftable by: " .. craftInfo.requires_class.name
      if not craftInfo.is_class then
        setColor(200,0,0,255)
      end
      love.graphics.printf(classText,sidebarX+padX,descY,window2w,"left")
      if not craftInfo.is_class then
        setColor(255,255,255,255)
      end
      local _, dlines = fonts.textFont:getWrap(classText,window2w)
      descY = descY+prefs['fontSize']*(#dlines+1)
    end
    
    if craftInfo.requires_faction then
      local factionText = "Only Craftable by members of " .. craftInfo.requires_faction.name
      if not craftInfo.is_faction_member then
        setColor(200,0,0,255)
      end
      love.graphics.printf(factionText,sidebarX+padX,descY,window2w,"left")
      if not craftInfo.is_faction_member then
        setColor(255,255,255,255)
      end
      local _, dlines = fonts.textFont:getWrap(factionText,window2w)
      descY = descY+prefs['fontSize']*(#dlines+1)
    end
    
    if craftInfo.requires_level then
      local levelText = "Must be level " .. craftInfo.requires_level
      if not craftInfo.is_level then
        setColor(200,0,0,255)
      end
      love.graphics.printf(levelText,sidebarX+padX,descY,window2w,"left")
      if not craftInfo.is_level then
        setColor(255,255,255,255)
      end
      local _, dlines = fonts.textFont:getWrap(levelText,window2w)
      descY = descY+prefs['fontSize']*(#dlines+1)
    end
    
    if craftInfo.stat_requirements then
      love.graphics.printf("Stat Requirements:",sidebarX+padX,descY,window2w,"left")
      descY = descY+prefs['fontSize']+8
      for stat,info in pairs(craftInfo.stat_requirements) do
        local statText = "*" .. ucfirst(stat) .. ": " .. info.requirement .. " (have " .. info.player_stat .. ")"
        if not info.meets_requirement then
          setColor(200,0,0,255)
        end
        love.graphics.printf(statText,sidebarX+padX,descY,window2w,"left")
        local _, dlines = fonts.textFont:getWrap(statText,window2w)
        descY = descY+prefs['fontSize']*#dlines
        if not info.meets_requirement then
          setColor(255,255,255,255)
        end
      end
      descY = descY+prefs['fontSize']
    end
    
    if craftInfo.skill_requirements then
      love.graphics.printf("Skill Requirements:",sidebarX+padX,descY,window2w,"left")
      descY = descY+prefs['fontSize']+8
      for skill,info in pairs(craftInfo.skill_requirements) do
        local skillInfo = possibleSkills[skill]
        local statText = "*" .. skillInfo.name .. (skillInfo.max == 1 and "" or ": " .. info.requirement .. " (have " .. info.player_stat .. ")")
        if not info.meets_requirement then
          setColor(200,0,0,255)
        end
        love.graphics.printf(statText,sidebarX+padX,descY,window2w,"left")
        local _, dlines = fonts.textFont:getWrap(statText,window2w)
        descY = descY+prefs['fontSize']*#dlines
        if not info.meets_requirement then
          setColor(255,255,255,255)
        end
      end
      descY = descY+prefs['fontSize']
    end
    
    if craftInfo.requires_text then
      if not craftInfo.meets_requires_code then
        setColor(200,0,0,255)
      end
      love.graphics.printf(craftInfo.requires_text,sidebarX+padX,descY,window2w,"left")
      if not craftInfo.meets_requires_code then
        setColor(255,255,255,255)
      end
      local _, dlines = fonts.textFont:getWrap(craftInfo.requires_text,window2w)
      descY = descY+prefs['fontSize']*(#dlines+1)
    end
    self.maxButtonY = buttonY
    love.graphics.setStencilTest()
    love.graphics.pop()
    --Scrollbars
    if descY*uiScale > height-padY then
      self.descScrollMax = math.ceil((descY-(padY+(height/uiScale-padY))+padding))
      local scrollAmt = self.descScrollY/self.descScrollMax
      if self.cursorX == 5 then
        setColor(150,150,150,255)
        love.graphics.rectangle('fill',sidebarX+window2w,padY,32,math.floor((height-padding)/uiScale)-padY)
        setColor(255,255,255,255)
      end
      self.descScrollPositions = output:scrollbar(sidebarX+window2w,padY,math.floor((height-padding)/uiScale),scrollAmt,true)
    else
      self.descScrollMax = 0
    end
    self.descScrollY = math.min(self.descScrollY,self.descScrollMax)
  end --end showing selected craft
  self.closebutton = output:closebutton(padding,padding,nil,true)
  love.graphics.pop()
end

function crafting:buttonpressed(key)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local typed = key
  width,height = round(width/uiScale),round(height/uiScale)
  key = input:parse_key(key)
	if (key == "escape") then
    if self.selected then
      self.selected = nil
      self.cursorX = 1
      self.sideCursorY = 0
    else
      self:switchBack()
    end
	elseif (key == "enter") or key == "wait" then
    if not self.selected then
      if self.cursorY == 0 then
        self.hideUncraftable = not self.hideUncraftable
        self:refresh_craft_list()
      end
      if self.crafts[self.cursorY] ~= nil then
        self.selected = self.cursorY
        self.sideCursorY = 0
        self.cursorX = 1
      end
    else
      for _,button in pairs(self.buttons) do
        if (not button.buttonX or self.cursorX == button.buttonX) and self.sideCursorY == button.buttonY then
          self:select_button(button)
          break
        end
      end      
    end
  elseif key == "east" then
    if not self.selected and self.cursorY ~= 0 then
      self.selected = self.cursorY
      self.sideCursorY = 0
      self.cursorX = 1
    elseif self.selected then
      if self.cursorX < 5 then
        self.cursorX = self.cursorX+1
        if self.sideCursorY == 0 then
          local craftInfo = self.crafts[self.selected or self.cursorY]
          local recipe = possibleRecipes[craftInfo.id]
          if craftInfo and recipe and recipe.single_craft_only then
            self.cursorX = 5
          end
        elseif self.cursorX > 3 then
          self.cursorX = 5
        end
      end
    end
  elseif key == "west" then
    if self.cursorX > 1  then
      self.cursorX = self.cursorX - 1
      if self.sideCursorY == 0 then
        local craftInfo = self.crafts[self.selected or self.cursorY]
        local recipe = possibleRecipes[craftInfo.id]
        if craftInfo and recipe and recipe.single_craft_only then
          self.cursorX = 1
        end
      elseif self.cursorX==4 then
        self.cursorX=3
      end
    elseif self.selected then
      self.selected = nil
      self.sideCursorY = 0
      self.cursorX = 1
    end
	elseif (key == "north") then
    if not self.selected then
      if (self.cursorY > 0) then
        self.cursorY = self.cursorY - 1
        if not self.craft_coordinates[self.cursorY-1] or self.craft_coordinates[self.cursorY-1].minY-self.scrollY < self.startY then
          self:listScrollUp()
        end
      end
    else
      if self.cursorX == 5 then
        self:descScrollUp()
      end
      self.sideCursorY = math.max(self.sideCursorY-1,0)
    end
	elseif (key == "south") then
    if not self.selected then
      if (self.crafts[self.cursorY+1] ~= nil) then
        self.cursorY = self.cursorY + 1
        if not self.craft_coordinates[self.cursorY+1] or self.craft_coordinates[self.cursorY+1].maxY-self.scrollY > height then
          self:listScrollDown()
        end
      end
    else
      if self.sideCursorY < self.maxButtonY then
        if self.cursorX == 5 then
          self:descScrollDown()
        end
        self.sideCursorY = self.sideCursorY + 1
      end
    end
  elseif key == "nextTarget" then
    if not self.selected and self.cursorY ~= 0 then
      self.selected = self.cursorY
      self.sideCursorY = 0
      self.cursorX = 1
    elseif self.selected then
      if self.sideCursorY == 0 then
        self.sideCursorY = 1
      elseif self.cursorX < 3 then
        self.cursorX = self.cursorX+1
      elseif self.cursorX >= 3 then
        if self.sideCursorY < self.maxButtonY then
          self.cursorX = 1
          self.sideCursorY = self.sideCursorY+1
        else
          self.cursorX = 1
          self.sideCursorY = 0
        end
      end
    end
  elseif tonumber(typed) and ((self.sideCursorY > 0 and self.cursorX == 2) or (self.sideCursorY == 0 and self.cursorX==3)) then --Typing in box
    local box
    local item
    for _,button in pairs(self.buttons) do
      if button.buttonType == "boxmain" and button.buttonY == self.sideCursorY then
        local craft = button.craftInfo
        craft.amount = tonumber(typed)
        return
      elseif button.buttonType == "box" and button.buttonY == self.sideCursorY then
        box = button
        item = box.details.item
      end
    end
    if box and box.property.selected < box.property.required then
      local craft = box.craftInfo or self.crafts[self.selected or self.cursorY]
      local currAmt = craft.secondary_ingredients[item] or 0
      if string.len(currAmt) < 3 then
        local newAmt = math.min(tonumber(currAmt == 0 and typed or currAmt .. typed),item.amount)
        local diff = newAmt-currAmt
        local prop_amt = box.details.amount
        local addition = (diff*prop_amt)
        
        local overcharge = box.property.selected+addition-box.property.required
        if overcharge > 0 and overcharge >= prop_amt then
          local over_amt = math.floor(overcharge/prop_amt)
          newAmt = newAmt-over_amt
        end
        diff = newAmt-currAmt
        craft.secondary_ingredients[item] = newAmt
        
        for property,prop_amt in pairs(item.crafting_ingredient_properties) do
          local prop = craft.ingredient_properties and craft.ingredient_properties[property] or false
          if prop then
            local addition = (diff*prop_amt)
            prop.selected = prop.selected+addition
          end
        end
      end
    end
  elseif (typed == "backspace") and ((self.sideCursorY > 0 and self.cursorX == 2) or (self.sideCursorY == 0 and self.cursorX==3)) then
    local box
    local item
    for _,button in pairs(self.buttons) do
      if button.buttonType == "boxmain" and button.buttonY == self.sideCursorY then
        local craft = button.craftInfo
        craft.amount = 1
        return
      elseif button.buttonType == "box" and button.buttonY == self.sideCursorY then
        box = button
        item = box.details.item
      end
    end
    if box then
      local craft = box.craftInfo or self.crafts[self.selected or self.cursorY]
      local currAmt = tostring(craft.secondary_ingredients[item] or 0)
      local newAmt = tonumber(string.sub(currAmt,1,#currAmt-1))
      newAmt = newAmt or 0
      local diff = newAmt-currAmt
      craft.secondary_ingredients[item] = newAmt
      for property,prop_amt in pairs(item.crafting_ingredient_properties) do
        if craft.ingredient_properties and craft.ingredient_properties[property] then
          craft.ingredient_properties[property].selected = craft.ingredient_properties[property].selected+(diff*prop_amt)
        end
      end
    end
	end
end

function crafting:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y = round(x/uiScale), round(y/uiScale)
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then self:switchBack() end
  

  for id,coords in ipairs(self.craft_coordinates) do
    if x > coords.minX and x < coords.maxX and y+self.scrollY > coords.minY and y+self.scrollY < coords.maxY then
      self.selected = id
      self.cursorX = 2
    end
  end
  local toggle = self.craft_coordinates['toggle']
  if x > toggle.minX and x < toggle.maxX and y > toggle.minY and y < toggle.maxY then
    self.cursorY = 0
    self.selected = nil
    self.hideUncraftable = not self.hideUncraftable
    self:refresh_craft_list()
  end
  if self.buttons then
    for _,button in pairs(self.buttons) do
      if x > button.minX and x < button.maxX and y+self.descScrollY > button.minY and y+self.descScrollY < button.maxY then
        self:select_button(button)
        break
      end
    end
  end
end

function crafting:update(dt,forceMouse)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
  self.lineCountdown = self.lineCountdown-dt
  if self.lineCountdown <= 0 then
    self.lineCountdown = .5
    self.lineOn = not self.lineOn
  end
  
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = round(x/uiScale), round(y/uiScale)
	if (forceMouse or x ~= self.mouseX or y ~= self.mouseY) then -- only do this if the mouse has moved
    self.mouseX,self.mouseY = x,y
    for id,coords in ipairs(self.craft_coordinates) do
      if x > coords.minX and x < coords.maxX and y+self.scrollY > coords.minY and y+self.scrollY < coords.maxY then
        self.cursorY = id
      end
    end
    local toggle = self.craft_coordinates['toggle']
    if x > toggle.minX and x < toggle.maxX and y > toggle.minY and y < toggle.maxY then
      self.cursorY = 0
    end
	end
  --Scrollbars:
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local upArrow = self.scrollPositions.upArrow
    local downArrow = self.scrollPositions.downArrow
    local elevator = self.scrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:listScrollUp()
      return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:listScrollDown()
      return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then
        self:listScrollUp()
        return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
      elseif y>elevator.endY then
        self:listScrollDown()
        return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
      end
    end --end clicking on arrow
  end
  if (love.mouse.isDown(1)) and self.descScrollPositions then
    local upArrow = self.descScrollPositions.upArrow
    local downArrow = self.descScrollPositions.downArrow
    local elevator = self.descScrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:descScrollUp()
      return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:descScrollDown()
      return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then
        self:descScrollUp()
        return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
      elseif y>elevator.endY then
        self:descScrollDown()
        return true --This is done because mousepressed() looks for it, to prevent a click on the scrollbar as counting as a click on an item if they overlap
      end
    end --end clicking on arrow
  end
end

function crafting:doCraft(craftIndex)
  local craftInfo = self.crafts[craftIndex]
  local craftID = craftInfo.id
  if craftInfo.craftable and not craftInfo.not_enough_due_to_amount then
    local propCheck = true
    if craftInfo.ingredient_properties then
      for _,propInfo in pairs(craftInfo.ingredient_properties) do
        if propInfo.selected < propInfo.required*craftInfo.amount and not propInfo.optional then
          propCheck = false
          break
        end
      end
    end
    if propCheck then
      local result,text = player:craft_recipe(craftID,craftInfo.secondary_ingredients,self.stash,craftInfo.amount)
      if result == true and not text then
        text = possibleCrafts[craftID].result_text
      end
      self.outText = text
      self:refresh_craft_list()
      return true
    end
  end
  self.outText = "You can't craft that right now."
end

function crafting:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end

function crafting:wheelmoved(x,y)
  local mouseX,mouseY = love.mouse.getPosition()
  if y > 0 then
    if mouseX < self.sidebarX then self:listScrollUp() else self:descScrollUp() end
	elseif y < 0 then
    if mouseX < self.sidebarX then self:listScrollDown() else self:descScrollDown() end
  end --end button type if
end

function crafting:listScrollUp()
  local height = love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  height = round(height/uiScale)
  if self.scrollY > 0 then
    self.scrollY = self.scrollY - prefs.fontSize
    if self.scrollY < prefs.fontSize then
      self.scrollY = 0
    end
    if self.craft_coordinates[self.cursorY] and self.craft_coordinates[self.cursorY].maxY-self.scrollY > height then
      self.cursorY = self.cursorY-1
    end
  end
end

function crafting:listScrollDown()
  if self.scrollMax and self.scrollY < self.scrollMax then
    self.scrollY = self.scrollY+prefs.fontSize
    if self.scrollMax-self.scrollY < prefs.fontSize then
      self.scrollY = self.scrollMax
    end
    if self.craft_coordinates[self.cursorY] and self.craft_coordinates[self.cursorY].minY-self.scrollY < self.startY then
      self.cursorY = self.cursorY+1
    end
  end
end

function crafting:descScrollUp()
  if self.descScrollY > 0 then
    self.descScrollY = self.descScrollY - prefs.fontSize
    if self.descScrollY < prefs.fontSize then
      self.descScrollY = 0
    end
  end
end

function crafting:descScrollDown()
  if self.descScrollMax and self.descScrollY < self.descScrollMax then
    self.descScrollY = self.descScrollY+prefs.fontSize
    if self.descScrollMax-self.descScrollY < prefs.fontSize then
      self.descScrollY = self.descScrollMax
    end
  end
end

function crafting:select_button(button)
  if not button then return end
  
  local craft = button.craftInfo or self.crafts[self.selected or self.cursorY]
  
  if button.buttonType == "minusmain" then
    local craftInfo = button.craftInfo
    button.craftInfo.amount = math.max(1,button.craftInfo.amount-1)
  elseif button.buttonType == "plusmain" then
    local craftInfo = button.craftInfo
    button.craftInfo.amount = button.craftInfo.amount+1
  elseif button.buttonType == "minus" then
    local item = button.details.item
    if craft.secondary_ingredients[item] > 0 then
      craft.secondary_ingredients[item] = craft.secondary_ingredients[item]-1
      for property,amt in pairs(item.crafting_ingredient_properties) do
        if craft.ingredient_properties and craft.ingredient_properties[property] then
          craft.ingredient_properties[property].selected = craft.ingredient_properties[property].selected-amt
        end
      end
    end
  elseif button.buttonType == "plus" then
    local item = button.details.item
    local craftInfo = button.craftInfo
    if item.amount > craft.secondary_ingredients[item] and button.property.selected < button.property.required*craftInfo.amount then
      craft.secondary_ingredients[item] = craft.secondary_ingredients[item]+1
      for property,amt in pairs(item.crafting_ingredient_properties) do
        if craft.ingredient_properties and craft.ingredient_properties[property] then
          craft.ingredient_properties[property].selected = craft.ingredient_properties[property].selected+amt
        end
      end
    end
  elseif button.buttonType == "box" then
    self.cursorX,self.sideCursorY = button.buttonX,button.buttonY
  elseif button.buttonType == "craft" then
    self:doCraft(self.selected)
  end
end