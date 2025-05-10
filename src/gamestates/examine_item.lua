examine_item = {}

function examine_item:enter(previous,item,container,noUse)
  if previous ~= hotkey and previous ~= splitstack and previous ~= nameitem then
    local width, height = love.graphics:getWidth(),love.graphics:getHeight()
    local uiScale = (prefs['uiScale'] or 1)
    width,height = round(width/uiScale),round(height/uiScale)
    self.previous=previous
    self.item=item
    self.container = container
    self.has_item = (not noUse and player:has_specific_item(self.item))
    self.cursorX,self.cursorY=1,1
    self.scroll=0
    self.scrollMax=0
    self.width = math.min(550,width-output:get_tile_size())
    self.x = round(width/2-self.width/2-output:get_tile_size()/2)
    self.height = self:calculate_height()
    self.y = round(height/2-self.height/2-output:get_tile_size()/2)
    self.yModPerc = 100
    tween(0.2,self,{yModPerc=0})
    output:sound('stoneslideshort',2)
    self.buttons = {}
  end
end

function examine_item:draw()
  self.previous:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width,height = round(width/uiScale),round(height/uiScale)
  local fontSize = fonts.textFont:getHeight()
  local tileSize = output:get_tile_size()
  local sizeDiff = math.ceil((tileSize-fontSize)/2)
  local padding = 16
  
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  
  output:draw_window(self.x,self.y,self.x+self.width,self.y+self.height)
  love.graphics.setFont(fonts.textFont)
  
  local item = self.item
  local name = item:get_name(true)
  local level = item.level
  local desc = item:get_description()
  local info = item:get_info(true)
  local textW = (self.scrollMax > 0 and self.width-32 or self.width)
  local _, nlines = fonts.textFont:getWrap(name,self.width)
  local nameH = #nlines*fontSize
  local _, dlines = fonts.textFont:getWrap(desc,textW)
  local descH = #dlines*fontSize
  local _, ilines = fonts.textFont:getWrap(info,textW)
  local infoH = (info == "" and fontSize or (#ilines+1)*fontSize)
  local printY = self.y+padding
  love.graphics.printf(name,self.x+padding,printY,self.width,"center")
  printY=printY+nameH
  if level and gamesettings.display_item_levels then
    local ltext = "Level " .. level
    local _, llines = fonts.textFont:getWrap(ltext,textW)
    local levelH = #llines*fontSize
    love.graphics.printf("Level " .. level,self.x+padding,printY,self.width,"center")
    printY=printY+levelH
  end
  
  self.buttons = {}
  
  local buttonStartX = self.x+padding
  local buttonX = buttonStartX
  local buttonMaxX = self.x+self.width
  local buttonY = printY+padding
  local buttonCursorX = 1
  local buttonCursorY = 1
  self.buttons.values = {}
  self.buttons.values[buttonCursorY]={}
  if self.has_item then
    if item.usable==true then
      local useText = (item.useVerb and ucfirst(item.useVerb) or "Use") .. " (" .. input:get_button_name("use") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      if not player:can_use_item(item) then
        setColor(175,175,175,255)
      end
      self.buttons.use = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      if not player:can_use_item(item) then
        setColor(255,255,255,255)
      end
      self.buttons.values[buttonCursorY][buttonCursorX] = "use"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.throwable==true then
      local useText = "Throw (" .. input:get_button_name("ranged") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.throw = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "throw"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true then
      local equipped = player:is_equipped(item)
      local useText = (equipped and "Unequip" or "Equip") .. " (" .. input:get_button_name("equip") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.equip = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "equip"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.charges and item.max_charges and item.max_charges > 0 and item.usesAmmo then
      local useText = "Reload/Recharge" .. " (" .. input:get_button_name("recharge") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      if item.charges >= item.max_charges then
        setColor(175,175,175,255)
      end
      self.buttons.reload = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      if item.charges >= item.max_charges then
        setColor(255,255,255,255)
      end
      self.buttons.values[buttonCursorY][buttonCursorX] = "reload"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true and not item.stacks then
      local useText = (item.properName and "Rename" or "Name")
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.name = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "name"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.stacks==true and item.amount and item.amount > 1 then
      local useText = "Split Stack"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.split = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "split"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable == true or item.usable == true or item.throwable == true then
      local hotkey = item.hotkey
      local hotkeyText = (hotkey and "Change Hotkey" or "Assign Hotkey")
      local buttonWidth = fonts.buttonFont:getWidth(hotkeyText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.hotkey = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),hotkeyText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "hotkey"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    local dropText = (self.container and "Place in " .. self.container:get_name(true) or "Drop") .. " (" .. input:get_button_name("drop") .. ")"
    local buttonWidth = fonts.buttonFont:getWidth(dropText)+25
    if buttonX+buttonWidth >= buttonMaxX then
      buttonCursorX=1
      buttonCursorY=buttonCursorY+1
      self.buttons.values[buttonCursorY] = {}
      buttonX = buttonStartX
      buttonY = buttonY+40
    end
    if not item.undroppable then
      self.buttons.drop = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),dropText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "drop"
    end
  elseif self.container then
    if player:get_free_inventory_space() > (item.size or 1) then
      local useText = "Take (" .. input:get_button_name("pickup") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.pickup = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "pickup"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true then
      local equipped = player:is_equipped(item)
      local useText = (equipped and "Unequip" or "Equip") .. " (" .. input:get_button_name("equip") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.equip = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "equip"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true and not item.stacks then
      local useText = (item.properName and "Rename" or "Name")
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.name = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "name"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.stacks==true and item.amount and item.amount > 1 then
      local useText = "Split Stack"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.split = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "split"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
  elseif (gamesettings.can_pickup_adjacent_items and player:touching(item)) or (player.x == item.x and player.y == item.y) or (self.container and self.container.inventory_accessible_anywhere) then
    if player:get_free_inventory_space() > (item.size or 1) then
      local useText = "Take (" .. input:get_button_name("pickup") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        self.buttons.values[buttonCursorY] = {}
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      self.buttons.pickup = output:button(buttonX,buttonY,buttonWidth,false,(self.cursorX == buttonCursorX and self.cursorY == buttonCursorY and "hover" or nil),useText,true)
      self.buttons.values[buttonCursorY][buttonCursorX] = "pickup"
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
  end --end if has_item
  printY=buttonY+(count(self.buttons) > 1 and 40 or 0)
  local startY = printY
  love.graphics.line(self.x+padding,printY,self.x+padding+self.width,printY)
  --Create a "stencil" that stops 
  love.graphics.push()
  local function stencilFunc()
    love.graphics.rectangle("fill",self.x,startY,self.width+tileSize,self.height)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  love.graphics.translate(0,-self.scroll)
  local scrollPadding = (self.scrollMax == 0 and 0 or tileSize)
  printY=printY+padding
  love.graphics.printf(desc,self.x+padding,printY,self.width-scrollPadding,"center")
  printY=printY+descH
  love.graphics.printf(info,self.x+padding,printY,self.width-scrollPadding,"center")
  printY=printY+infoH
  local armor = item:get_all_armor()
  if count(armor) > 0 then
    love.graphics.printf("Provides armor when equipped:",self.x+padding,printY,self.width-scrollPadding,"center")
    printY = printY+fontSize
    for dtype,amt in pairs(armor) do
      local thisPadX = 0
      local dtinfo = damage_types[dtype] or {}
      local dtName = ucfirst(dtinfo.name or dtype)
      local nameW = fonts.textFont:getWidth(dtName)
      local image = false
      if dtinfo.color then
        setColor(dtinfo.color.r,dtinfo.color.g,dtinfo.color.b,dtinfo.color.a)
      end
      if images['damage_type' .. (dtinfo.image_name or dtype)] then
        local imageX = self.x+math.floor(self.width/2-nameW/2)-tileSize
        love.graphics.draw(images['damage_type' .. (dtinfo.image_name or dtype)],imageX,printY)
        thisPadX = tileSize
        image = true
      end
      setColor(255,255,255,255)
      love.graphics.printf(dtName .. ": " .. amt,self.x+padding,printY+sizeDiff,self.width-scrollPadding,"center")
      printY = printY + tileSize
    end
    printY = printY + fontSize
  end
  if item.bonuses and count(item.bonuses) > 0 then
    love.graphics.printf("Bonuses granted when equipped:",self.x+padding,printY,self.width-scrollPadding,"center")
    printY=printY+fontSize
    for bonus,amt in pairs(item.bonuses) do
      local isPercent = (string.find(bonus,"percent") or string.find(bonus,"chance"))
      local bonusName = ucfirstall(string.gsub(bonus, "_", " ")) .. (type(amt) == "number" and ": " .. (amt > 0 and "+" or "") .. amt .. (isPercent and "%" or "") or "")
      love.graphics.printf(bonusName,self.x+padding,printY,self.width-scrollPadding,"center")
      local _,blines = fonts.textFont:getWrap(bonusName,self.width-scrollPadding)
      printY = printY + fontSize*#blines
    end
    printY=printY+fontSize
  end
  if count(item:get_condition_type_immunities()) > 0 then
    local immuneText = "Provides immunity to condition types: "
    for i,immunity in ipairs(item:get_condition_type_immunities()) do
      immuneText = immuneText .. (i > 1 and ", " or "") .. ucfirst(immunity)
    end
    love.graphics.printf(immuneText,self.x+padding,printY,self.width-scrollPadding,"center")
    local _,blines = fonts.textFont:getWrap(immuneText,textW)
    printY = printY + fontSize*#blines
    printY=printY+fontSize
  end
  if count(item:get_spells_granted()) > 0 then
    love.graphics.printf("Abilities granted when equipped:",self.x+padding,printY,self.width-scrollPadding,"center")
    printY=printY+fontSize
    for _,spell in ipairs(item:get_spells_granted()) do
      local spellText = spell.name .. (spell.target_type == "passive" and " (Passive)" or "")
      local spellW = fonts.textFont:getWidth(spellText)
      local image = false
      if images['spell' .. (spell.image_name or spell.id)] then
        local spellPrintX = self.x+math.floor(self.width/2-spellW/2)-tileSize
        if spell.color then
          setColor(spell.color.r,spell.color.g,spell.color.b,spell.color.a)
        end
        love.graphics.draw(images['spell' .. (spell.image_name or spell.id)],spellPrintX,printY)
        image = true
      end
      setColor(255,255,255,255)
      love.graphics.printf(spellText,self.x+padding,printY+sizeDiff or 0,self.width-scrollPadding,"center")
      printY = printY + (image and tileSize or fontSize)
      if spell.description then
        local _,dlines = fonts.textFont:getWrap(spell.description,self.width-scrollPadding)
        love.graphics.printf(spell.description,self.x+padding,printY,self.width-scrollPadding,"center")
        printY = printY + fontSize*#dlines
      end
    end
    printY = printY + fontSize
  end
  local val = item:get_value()
  if gamesettings.examine_item_value and item.value and val > 0 then
    love.graphics.printf("Value: " .. val,self.x+padding,printY,self.width-scrollPadding,"center")
    printY=printY+fontSize
  end
  local study_results = item:get_study_results(player)
  if count(study_results) > 0 or item.study_info then
    local itemText = "Can be studied at the desk in your tower" .. ((study_results.study_items or study_results.study_skills or study_results.study_recipes) and ", granting:" or ".")
    if item.study_amount then
      itemText = "\n(Requires " .. item.study_amount .. ")"
    end
    if item.study_skill_requirements then
      for skillID,val in pairs(item.study_skill_requirements) do
        local playerVal = player:get_skill(skillID)
        if playerVal < val then
          itemText = itemText .. "\nRequired skill to study: " .. (possibleSkills[skillID].name or skillID) .. (val > 1 and " at level " .. val .. (playerVal > 0 and "(have " .. playerVal .. ")" or "") or "")
          disabled = true
        end
      end
    end
    if study_results.study_items then
      for iid,amt in pairs(study_results.study_items) do
        local itemDef = possibleItems[iid]
        itemText = itemText .. "\n\t" .. amt .. " " .. ucfirst(itemDef.pluralName or itemDef.name)
      end
    end
    if study_results.study_skills then
      for skillID,amt in pairs(study_results.study_skills) do
        local skillDef = possibleSkills[skillID]
        itemText = itemText .. "\n\t+" .. amt .. " Level of " .. skillDef.name
      end
    end
    if study_results.study_recipes then
      for _,recipeID in pairs(study_results.study_recipes) do
        local recipeDef = possibleRecipes[recipeID]
        local recipeName = recipeDef.name
        if not recipeName then
          recipeName = ""
          local count = 0
          for item,amount in pairs(recipeDef.results) do
            if count > 1 then recipeName = recipeName .. ", " end
            if amount > 1 then
              recipeName = recipeName .. amount .. " " .. ucfirst(possibleItems.pluralName or "x " .. ucfirst(possibleItems[item].name))
            else
              recipeName = recipeName .. ucfirst(possibleItems[item].name)
            end
            count = count + 1
          end
        end
        itemText = itemText .. "\n\tRecipe: " .. recipeName
      end
    end
    if item.study_info then
      itemText = itemText .. "\n" .. item.study_info
    end
    itemText = itemText .. "\n"
    love.graphics.printf(itemText,self.x+padding,printY,self.width-scrollPadding,"center")
    local _, slines = fonts.textFont:getWrap(itemText,textW)
    local studyH = (#slines)*fontSize
    printY=printY+studyH
  end
  if item.crafting_ingredient_types then
    local recipeText = "Can be used as an ingredient in"
    for i,rtype in ipairs(item.crafting_ingredient_types) do
      if i > 1 and #item.crafting_ingredient_types > 2 then
        recipeText = recipeText .. ","
      end
      if i > 1 and i == #item.crafting_ingredient_types then
        recipeText = recipeText .. " and"
      end
      recipeText = recipeText .. " " .. rtype
    end
    recipeText = recipeText .. " recipes."
    local _, rlines = fonts.textFont:getWrap(recipeText,textW)
    local recipeH = (#rlines)*fontSize
    love.graphics.printf(recipeText,self.x+padding,printY,self.width-scrollPadding,"center")
    printY=printY+recipeH
  end
  if gamesettings.examine_item_recipes then
    local recipes = item:is_ingredient_in()
    local recipeCount = count(recipes)
    if recipeCount > 0 then
      local recipeText = "Ingredient in known recipes: "
      for i,recInfo in pairs(recipes) do
        local recipe = possibleRecipes[recInfo.id]
        if recipe then
          if i ~= 1 then
            recipeText = recipeText .. ", "
            if i == recipeCount then
              recipeText = recipeText .. "and "
            end
          end
          recipeText = recipeText .. recInfo.name
        end
      end
      recipeText = recipeText .. "\n"
      local _, rlines = fonts.textFont:getWrap(recipeText,textW)
      local recipeH = (#rlines)*fontSize
      love.graphics.printf(recipeText,self.x+padding,printY,self.width-scrollPadding,"center")
      printY=printY+recipeH
    end
  end --end if examine_item_recipes
  if gamesettings.examine_item_sellable and not item.noSell then
    local buyers = item:get_buyer_list()
    local buyerCount = count(buyers)
    if buyerCount > 0 then
      local buyText = "Can be sold to: "
      for i,buyInfo in pairs(buyers) do
        if i ~= 1 then
          buyText = buyText .. ", "
          if i == buyerCount then
            buyText = buyText .. "and "
          end
        end
        buyText = buyText .. buyInfo.text .. " (" .. (buyInfo.moneyCost and buyInfo.moneyCost > 0 and get_money_name(buyInfo.moneyCost) or "") .. (buyInfo.favorCost and buyInfo.favorCost > 0 and (buyInfo.moneyCost and ", " or "") .. buyInfo.favorCost .. " favor" or "") .. (buyInfo.reputationCost and buyInfo.reputationCost > 0 and ((buyInfo.moneyCost or buyInfo.favorCost) and ", " or "") .. buyInfo.reputationCost .. " reputation" or "") .. ")"
      end
      local _, blines = fonts.textFont:getWrap(buyText,textW)
      local buyH = (#blines)*fontSize
      love.graphics.printf(buyText,self.x+padding,printY,self.width-scrollPadding,"center")
      printY=printY+buyH
    end
  end --end if examine_item_recipes
  love.graphics.setStencilTest()
  love.graphics.pop()
  if printY > self.y+self.height then
    if self.cursorY == #self.buttons.values+1 then
      setColor(50,50,50,255)
      love.graphics.rectangle("fill",self.x+self.width-padding,startY+round(tileSize/2),tileSize,self.height-startY)
      setColor(255,255,255,255)
    end
    self.scrollMax = math.ceil(printY-(self.y+self.height))
    local scrollAmt = self.scroll/self.scrollMax
    self.scrollPositions = output:scrollbar(self.x+self.width-padding,startY+round(tileSize/2),self.y+self.height+padding,scrollAmt,true)
  else
    self.scrollMax = 0
  end
  self.closebutton = output:closebutton(self.x+round(padding/2),self.y+round(padding/2),nil,true)
  love.graphics.pop()
end

function examine_item:calculate_height()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width,height = round(width/uiScale),round(height/uiScale)
  local fontSize = fonts.textFont:getHeight()
  local tileSize = output:get_tile_size()
  local padding = 16
  
  local item = self.item
  local name = item:get_name(true)
  local level = item.level
  local desc = item:get_description()
  local info = item:get_info(true)
  local textW = (self.scrollMax > 0 and self.width-32 or self.width)
  local _, nlines = fonts.textFont:getWrap(name,self.width)
  local nameH = #nlines*fontSize
  local _, dlines = fonts.textFont:getWrap(desc,textW)
  local descH = #dlines*fontSize
  local _, ilines = fonts.textFont:getWrap(info,textW)
  local infoH = (info == "" and fontSize or (#ilines+1)*fontSize)
  local valueH, recipeH, buyH = 0,0,0
  local printY = padding
  printY=printY+nameH
  local armor = item:get_all_armor()
  if count(armor) > 0 then
    printY = printY+fontSize
    for dtype,amt in pairs(armor) do
      local thisPadX = 0
      local dtinfo = damage_types[dtype] or {}
      if images['damage_type' .. (dtinfo.image_name or dtype)] then
        thisPadX = tileSize
      end
      printY = printY + tileSize
    end
    printY = printY + fontSize
  end
  if item.bonuses and count(item.bonuses) > 0 then
    printY=printY+fontSize
    for bonus,amt in pairs(item.bonuses) do
      local isPercent = (string.find(bonus,"percent") or string.find(bonus,"chance"))
      local bonusName = ucfirstall(string.gsub(bonus, "_", " ")) .. ": " .. (type(amt) == "number" and (amt > 0 and "+" or "") .. amt .. (isPercent and "%" or "") or "")
      local _,blines = fonts.textFont:getWrap(bonusName,textW)
      printY = printY + fontSize*#blines
    end
    printY=printY+fontSize
  end
  if count(item:get_condition_type_immunities()) > 0 then
    local immuneText = "Provides immunity to condition types: "
    for i,immunity in ipairs(item:get_condition_type_immunities()) do
      immuneText = immuneText .. (i > 1 and ", " or "") .. immunity
    end
    local _,blines = fonts.textFont:getWrap(immuneText,textW)
    printY = printY + fontSize*#blines
    printY=printY+fontSize
  end
  if count(item:get_spells_granted()) > 0 then
    printY=printY+fontSize
    for _,spell in ipairs(item:get_spells_granted()) do
      local spellText = spell.name .. (spell.target_type == "passive" and " (Passive)" or "")
      local spellW = fonts.textFont:getWidth(spellText)
      local image = false
      if images['spell' .. (spell.image_name or spell.id)] then
        image = true
      end
      printY = printY + (image and tileSize or fontSize)
      if spell.description then
        local _,dlines = fonts.textFont:getWrap(spell.description,textW)
        printY = printY + fontSize*#dlines
      end
    end
    printY = printY + fontSize
  end
  if gamesettings.examine_item_value and item:get_value() > 0 then
    valueH = fontSize
  end
  local study_results = item:get_study_results(player)
  if count(study_results) > 0 or item.study_info then
    local itemText = "Can be studied at the desk in your tower" .. ((study_results.study_items or study_results.study_skills or study_results.study_recipes) and ", granting:" or ".")
    if item.study_amount then
      itemText = "\n(Requires " .. item.study_amount .. ")"
    end
    if item.study_skill_requirements then
      for skillID,val in pairs(item.study_skill_requirements) do
        local playerVal = player:get_skill(skillID)
        if playerVal < val then
          itemText = itemText .. "\nRequired skill to study: " .. (possibleSkills[skillID].name or skillID) .. (val > 1 and " at level " .. val .. (playerVal > 0 and "(have " .. playerVal .. ")" or "") or "")
          disabled = true
        end
      end
    end
    if study_results.study_items then
      for iid,amt in pairs(study_results.study_items) do
        local itemDef = possibleItems[iid]
        itemText = itemText .. "\n\t" .. amt .. " " .. ucfirst(itemDef.pluralName or itemDef.name)
      end
    end
    if study_results.study_skills then
      for skillID,amt in pairs(study_results.study_skills) do
        local skillDef = possibleSkills[skillID]
        itemText = itemText .. "\n\t+" .. amt .. " Level of " .. skillDef.name
      end
    end
    if study_results.study_recipes then
      for _,recipeID in pairs(study_results.study_recipes) do
        local recipeDef = possibleRecipes[recipeID]
        local recipeName = recipeDef.name
        if not recipeName then
          recipeName = ""
          local count = 0
          for item,amount in pairs(recipeDef.results) do
            if count > 1 then recipeName = recipeName .. ", " end
            if amount > 1 then
              recipeName = recipeName .. amount .. " " .. ucfirst(possibleItems.pluralName or "x " .. ucfirst(possibleItems[item].name))
            else
              recipeName = recipeName .. ucfirst(possibleItems[item].name)
            end
            count = count + 1
          end
        end
        itemText = itemText .. "\n\tRecipe: " .. recipeName
      end
    end
    if item.study_info then
      itemText = itemText .. "\n" .. item.study_info
    end
    itemText = itemText .. "\n"
    local _, slines = fonts.textFont:getWrap(itemText,textW)
    local studyH = (#slines)*fontSize
    printY=printY+studyH
  end
  if item.crafting_ingredient_types then
    local recipeText = "Can be used as an ingredient in"
    for i,rtype in ipairs(item.crafting_ingredient_types) do
      if i > 1 and #item.crafting_ingredient_types > 2 then
        recipeText = recipeText .. ","
      end
      if i > 1 and i == #item.crafting_ingredient_types then
        recipeText = recipeText .. " and"
      end
      recipeText = recipeText .. " " .. rtype
    end
    recipeText = recipeText .. " recipes."
    local _, rlines = fonts.textFont:getWrap(recipeText,textW)
    local recipeH = (#rlines)*fontSize
    printY=printY+recipeH
  end
  if gamesettings.examine_item_recipes then
    local recipes = item:is_ingredient_in()
    local recipeCount = count(recipes)
    if recipeCount > 0 then
      local recipeText = "Ingredient in known recipes: "
      for i,recInfo in pairs(recipes) do
        local recipe = possibleRecipes[recInfo.id]
        if recipe then
          if i ~= 1 then
            recipeText = recipeText .. ", "
          end
          recipeText = recipeText .. recInfo.name
        end
      end
      recipeText = recipeText .. "\n"
      local _, rlines = fonts.textFont:getWrap(recipeText,textW)
      recipeH = (#rlines)*fontSize
    end
  end --end if examine_item_recipes
  if gamesettings.examine_item_sellable then
    local buyers = item:get_buyer_list()
    local buyerCount = count(buyers)
    if buyerCount > 0 then
      local buyText = "Can be sold to: "
      for i,buyInfo in pairs(buyers) do
        if i ~= 1 then
          buyText = buyText .. ", "
        end
        buyText = buyText .. buyInfo.text .. " (" .. (buyInfo.moneyCost and buyInfo.moneyCost > 0 and get_money_name(buyInfo.moneyCost) or "") .. (buyInfo.favorCost and (buyInfo.moneyCost and ", " or "") .. buyInfo.favorCost .. " favor" or "") .. ")"
      end
      local _, blines = fonts.textFont:getWrap(buyText,textW)
      buyH = (#blines)*fontSize
    end
  end --end if examine_item_sellable
  if level and gamesettings.display_item_levels then
    local ltext = "Level " .. level
    local _, llines = fonts.textFont:getWrap(ltext,textW)
    local levelH = #llines*fontSize
    printY=printY+levelH
  end
  
  local buttonStartX = self.x+padding
  local buttonX = buttonStartX
  local buttonMaxX = self.x+self.width
  local buttonY = printY+padding
  local buttonCursorX = 1
  local buttonCursorY = 1
  printY = buttonY
  if self.has_item then
    if item.usable==true then
      local useText = (item.useVerb and ucfirst(item.useVerb) or "Use") .. " (" .. input:get_button_name("use") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.throwable==true then
      local useText = "Throw (" .. input:get_button_name("ranged") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true then
      local equipped = player:is_equipped(item)
      local useText = (equipped and "Unequip" or "Equip") .. " (" .. input:get_button_name("equip") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.charges and (item.max_charges and item.max_charges > 0) then
      local useText = "Reload" .. " (" .. input:get_button_name("recharge") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true and not item.stacks then
      local useText = (item.properName and "Rename" or "Name")
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.stacks==true and item.amount and item.amount > 1 then
      local useText = "Split Stack"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable == true or item.usable == true or item.throwable == true then
      local hotkey = item.hotkey
      local hotkeyText = (hotkey and "Change Hotkey" or "Assign Hotkey")
      local buttonWidth = fonts.buttonFont:getWidth(hotkeyText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    local dropText = "Drop (" .. input:get_button_name("drop") .. ")"
    local buttonWidth = fonts.buttonFont:getWidth(dropText)+25
    if buttonX+buttonWidth >= buttonMaxX then
      buttonCursorX=1
      buttonCursorY=buttonCursorY+1
      buttonX = buttonStartX
      buttonY = buttonY+40
    end
    printY=buttonY+40
  elseif self.container and (player:touching(self.container) or self.container.inventory_accessible_anywhere)then
    if player:get_free_inventory_space() > (item.size or 1) then
      local useText = "Take (" .. input:get_button_name("pickup") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true then
      local equipped = player:is_equipped(item)
      local useText = (equipped and "Unequip" or "Equip") .. " (" .. input:get_button_name("equip") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.equippable==true and not item.stacks then
      local useText = (item.properName and "Rename" or "Name")
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    if item.stacks==true and item.amount and item.amount > 1 then
      local useText = "Split Stack"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    printY=buttonY+40
  elseif (gamesettings.can_pickup_adjacent_items and player:touching(item)) or (player.x == item.x and player.y == item.y)  or (self.container and self.container.inventory_accessible_anywhere) then
    if player:get_free_inventory_space() > (item.size or 1) then
      local useText = "Take (" .. input:get_button_name("pickup") .. ")"
      local buttonWidth = fonts.buttonFont:getWidth(useText)+25
      if buttonX+buttonWidth >= buttonMaxX then
        buttonCursorX=1
        buttonCursorY=buttonCursorY+1
        buttonX = buttonStartX
        buttonY = buttonY+40
      end
      buttonX = buttonX+buttonWidth+25
      buttonCursorX = buttonCursorX+1
    end
    printY=buttonY+40
  end --end if has_item
  printY=printY+recipeH
  printY=printY+buyH
  printY=printY+valueH
  printY=printY+descH
  printY=printY+infoH
  printY=printY+padding
  return math.min(height-(prefs['noImages'] and 0 or output:get_tile_size()),printY)
end

function examine_item:buttonpressed(key,scancode,isRepeat,controllerType)
  local letter = key
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
	if (key == "escape") then
    self:switchBack()
	elseif key == "enter" or key == "wait" then
    if self.buttons.values[self.cursorY][self.cursorX] == "pickup" then
      player:pickup(self.item)
      advance_turn()
      self:switchBack()
    elseif self.buttons.values[self.cursorY][self.cursorX] == "use" then
      self:switchBack()
      inventory:useItem(self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "equip" then
      self:switchBack()
      if self.container then
        player:pickup(self.item)
      end
      inventory:equipItem(self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "drop" then
      self:switchBack()
      inventory:dropItem(self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "throw" then
      self:switchBack()
      inventory:throwItem(self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "hotkey" then
      Gamestate.switch(hotkey,self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "split" then
      Gamestate.switch(splitstack,self.item)
    elseif self.buttons.values[self.cursorY][self.cursorX] == "name" then
      Gamestate.switch(nameitem,self.item)
    elseif self.buttons.values[self.cursorY][self.cursorY] == "recharge" then
      self:switchBack()
      inventory:reloadItem(self.item)
    end
	elseif (key == "north") then
    if self.cursorY < #self.buttons.values+1 or self.scroll == 0 then
      self.cursorY = math.max(self.cursorY-1,1)
    else
      self:scrollUp()
    end
	elseif (key == "south") then
    if self.cursorY < #self.buttons.values+1 then
      self.cursorY = math.min(self.cursorY+1,#self.buttons.values+1)
    else
      self:scrollDown()
    end
  elseif key == "west" then
    self.cursorX = self.cursorX - 1
    if self.cursorX < 1 then
      if self.cursorY > 1 then
        self.cursorY = math.max(self.cursorY-1,1)
        self.cursorX = #self.buttons.values[self.cursorY]
      else
        self.cursorX = 1
      end
    end
  elseif key == "east" then
    if self.cursorY ~= #self.buttons.values+1 then
      self.cursorX = self.cursorX + 1
      if self.buttons.values[self.cursorY] and self.cursorX > #self.buttons.values[self.cursorY] then
        if self.cursorY < #self.buttons.values+1 then
          self.cursorY = math.min(self.cursorY+1,#self.buttons.values+1)
          self.cursorX = 1
        else
          self.cursorX = #self.buttons.values[self.cursorY]
        end
      end
    end
  elseif key == "use" and self.has_item then
    self:switchBack()
    inventory:useItem(self.item)
  elseif key == "pickup" and self.buttons.pickup then
    player:pickup(self.item)
    advance_turn()
    self:switchBack()
  elseif key == "equip" and self.buttons.equip then
    self:switchBack()
    if self.container then
      self.container:drop_item(self.item)
      player:pickup(self.item)
    end
    inventory:equipItem(self.item)
  elseif key == "drop" and self.has_item then
    self:switchBack()
    inventory:dropItem(self.item)
  elseif key == "recharge" and self.has_item then
    self:switchBack()
    inventory:reloadItem(self.item)
  elseif key == "ranged" and self.has_item then
    self:switchBack()
    inventory:throwItem(self.item)
  end
end

function examine_item:wheelmoved(x,y)
  if y > 0 then
    self:scrollUp()
	elseif y < 0 then
    self:scrollDown()
  end
end

function examine_item:scrollUp()
  self.scroll = math.max(self.scroll - prefs['fontSize'],0)
end

function examine_item:scrollDown()
  self.scroll = self.scroll or 0
  self.scroll = math.min(self.scroll + prefs['fontSize'],self.scrollMax)
end

function examine_item:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(self.previous)
    Gamestate.update(dt)
    return
  end
	local x,y = love.mouse.getPosition()
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale, y/uiScale
	if (x ~= output.mouseX or y ~= output.mouseY) then -- only do this if the mouse has moved
    output.mouseX,output.mouseY = x,y
	end
  --Scrollbars:
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local upArrow = self.scrollPositions.upArrow
    local downArrow = self.scrollPositions.downArrow
    local elevator = self.scrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:scrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:scrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then
        self:scrollUp()
      elseif y>elevator.endY then
        self:scrollDown()
      end
    end --end clicking on arrow
  end
end

function examine_item:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  local padding = prefs['noImages'] and 16 or 32
  x,y = round(x/uiScale),round(y/uiScale)
  if button == 2 or (x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) or (x < self.x or x > self.x+self.width or y < self.y or y > self.y+self.height+padding) then
    self:switchBack()
  end
  --Item use buttons:
  if self.buttons.pickup and x > self.buttons.pickup.minX and x < self.buttons.pickup.maxX and y > self.buttons.pickup.minY and y < self.buttons.pickup.maxY then
    player:pickup(self.item)
    advance_turn()
    self:switchBack()
  elseif self.buttons.use and x > self.buttons.use.minX and x < self.buttons.use.maxX and y > self.buttons.use.minY and y < self.buttons.use.maxY then
    self:switchBack()
    inventory:useItem(self.item)
  elseif self.buttons.equip and x > self.buttons.equip.minX and x < self.buttons.equip.maxX and y > self.buttons.equip.minY and y < self.buttons.equip.maxY then
    self:switchBack()
    if self.container then
      self.container:drop_item(self.item)
      player:pickup(self.item)
    end
    inventory:equipItem(self.item)
  elseif self.buttons.drop and x > self.buttons.drop.minX and x < self.buttons.drop.maxX and y > self.buttons.drop.minY and y < self.buttons.drop.maxY then
    self:switchBack()
    inventory:dropItem(self.item)
  elseif self.buttons.throw and x > self.buttons.throw.minX and x < self.buttons.throw.maxX and y > self.buttons.throw.minY and y < self.buttons.throw.maxY then
    self:switchBack()
    inventory:throwItem(self.item)
  elseif self.buttons.hotkey and x > self.buttons.hotkey.minX and x < self.buttons.hotkey.maxX and y > self.buttons.hotkey.minY and y < self.buttons.hotkey.maxY then
    Gamestate.switch(hotkey,self.item)
  elseif self.buttons.split and x > self.buttons.split.minX and x < self.buttons.split.maxX and y > self.buttons.split.minY and y < self.buttons.split.maxY then
    Gamestate.switch(splitstack,self.item)
  elseif self.buttons.name and x > self.buttons.name.minX and x < self.buttons.name.maxX and y > self.buttons.name.minY and y < self.buttons.name.maxY then
    Gamestate.switch(nameitem,self.item)
  elseif self.buttons.reload and x > self.buttons.reload.minX and x < self.buttons.reload.maxX and y > self.buttons.reload.minY and y < self.buttons.reload.maxY then
    self:switchBack()
    inventory:reloadItem(self.item)
  end
end

function examine_item:switchBack()
  tween(0.2,self,{yModPerc=100})
  output:sound('stoneslideshortbackwards',2)
  Timer.after(0.2,function() self.switchNow=true end)
end