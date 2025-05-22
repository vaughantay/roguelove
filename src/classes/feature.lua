---@classmod Feature
Feature = Class{}

---Initiates a feature. Don't call this explicitly, it's called when you create a new feature using Feature('featureID').
--@param feature_type The ID of the feature you'd like to create
--@param info An argument to pass to the feature's new() function, if applicable (optional)
--@param x The x-coordinate (optional, will be set when it is added to the map)
--@param y The y-coordinate (optional, will be set when it is added to the map)
--@return The feature itself.
function Feature:init(feature_type,info)
  local data = possibleFeatures[feature_type]
  if not data then
    output:out("Error: Tried to create non-existent feature " .. feature_type)
    print("Error: Tried to create non-existent feature " .. feature_type)
    return false
  end
	for key, val in pairs(data) do
    local vt = type(val)
    if vt == "table" then
      self[key] = copy_table(data[key])
    elseif vt ~= "function" then
      self[key] = data[key]
    end
	end
  if self.container then self.inventory = {} end
	if (possibleFeatures[feature_type].new ~= nil) then 
    local status,r = pcall(possibleFeatures[feature_type].new,self,info)
    if status == false then
      output:out("Error in feature " .. self.name .. " new code: " .. r)
      print("Error in feature " .. self.name .. " new code: " .. r)
    end
	end
  if self.max_hp and not self.hp then
    self.hp = self.max_hp
  end
  self.id = self.id or feature_type
	self.baseType = "feature"
  if self.image_varieties and not self.image_name then
    self.image_variety = random(1,self.image_varieties)
    self.image_name = (self.image_base or self.id) .. self.image_variety
  end
	return self
end

---Returns the name of the feature.
--@param full Boolean. Whether to return the name in uppercase and without an article.
--@return String. The name.
function Feature:get_name(full)
  if (full == true) then
		return ucfirst(self.name)
	else
		return (self.article and self.article .. " " or (self.properNamed ~= true and (vowel(self.name) and "an " or "a " )) or "") .. self.name
	end
end

---Returns the description of the feature, and descriptive lines noting what you can do with it.
--@return String. The description.
function Feature:get_description()
	local txt = self.name .. "\n" .. self.description
  if self.attackable then txt = txt .. "\nYou can attack it." end
  if self.pushable then txt = txt .. "\nYou can push it." end
  if self.inventory and (not self.inventory_inaccessible or self.inventory_visible_if_inaccessible) and #self.inventory > 0 then
    txt = txt .. "\nIt contains: "
    for i,item in ipairs(self.inventory) do
      txt = txt .. (i ~= 1 and ", " or "") .. item:get_name(true)
    end
  end
  if self.turns_remaining and self.turns_remaining ~= -1 then
    txt = txt .. "Turns remaining: " .. self.turns_remaining
  end
  return txt
end

---Calls the can_enter() function of a feature, if it has one.
--@param enterer Creature. The creature entering the feature's tile.
--@param fromX Number. The x-coordinate the creature is coming from
--@param fromY Number. The y-coordinate the creature is coming from
--@return Boolean. Whether or not the creature was allowed to enter.
function Feature:can_enter(enterer,fromX,fromY)
  if not fromX or not fromY then
    fromX,fromY = self.x,self.y
  end
  if possibleFeatures[self.id].can_enter then
    local status,r = pcall(possibleFeatures[self.id].can_enter,self,enterer,fromX,fromY)
    if status == false then
      output:out("Error in feature " .. self.name .. " enter code: " .. r)
      print("Error in feature " .. self.name .. " enter code: " .. r)
    end
    return r
  end
	return true
end

---Calls the enter() function of a feature, if it has one.
--@param enterer Creature. The creature entering the feature's tile.
--@param fromX Number. The x-coordinate the creature is coming from
--@param fromY Number. The y-coordinate the creature is coming from
--@return Boolean. Whether or not the creature was allowed to enter.
function Feature:enter(enterer,fromX,fromY)
  if not fromX or not fromY then
    fromX,fromY = self.x,self.y
  end
  if possibleFeatures[self.id].enter then
    local status,r = pcall(possibleFeatures[self.id].enter,self,enterer,fromX,fromY)
    if status == false then
      output:out("Error in feature " .. self.name .. " enter code: " .. r)
      print("Error in feature " .. self.name .. " enter code: " .. r)
    end
    return r
  end
	return true
end

---Pushes a feature, if it's pushable. This also calls the push() callback of a feature, if applicable.
--@param pusher Creature. The creature pushing the feature. This will be used to determine where it is being pushed to.
--@return Boolean. Whether or not the push went through.
function Feature:push(pusher)
  if self.pushable == false then return false end
  if possibleFeatures[self.id].push then
    local status,r = pcall(possibleFeatures[self.id].push,self,pusher)
    if status == false then
      output:out("Error in feature " .. self.name .. " push code: " .. r)
      print("Error in feature " .. self.name .. " push code: " .. r)
    end
    return r
  end
  local xMod,yMod = get_unit_vector(pusher.x,pusher.y,self.x,self.y)
  if currMap:isClear(self.x+xMod,self.y+yMod) then
    self:moveTo(self.x+xMod,self.y+yMod)
    if player:can_see_tile(self.x,self.y) then
      output:sound('slide_wood')
    end
    return true
  else --if not clear, push any pushables in the way. If no pushables, just return false
    for _, feat in pairs(currMap:get_tile_features(self.x+xMod,self.y+yMod)) do
      if feat.pushable then
        if feat:push(self) then
          self:moveTo(self.x+xMod,self.y+yMod)
          return true
        end --end if push
        return false
      end --end if pusable
    end --end feature for
  end --end isclear if
  return false
end

---Moves a feature to a new location.
--@param x Number. The x-coordinate to move to.
--@param y Number. The y-coordinate to move to.
--@param noTween Boolean. If true, no tweening animation will be used. (optional)
--@return Boolean. Whether or not the move happened.
function Feature:moveTo(x,y,noTween)
  if not noTween and not prefs['noSmoothMovement'] then
    local tileSize = output:get_tile_size()
    local moveX,moveY=x-self.x,y-self.y
    local xChange,yChange = (x-self.x)*tileSize,(y-self.y)*tileSize
    self.xMod,self.yMod = (self.xMod or 0)-xChange,(self.yMod or 0)-yChange
    if timers[tostring(self) .. 'moveTween'] then
      Timer.cancel(timers[tostring(self) .. 'moveTween'])
    end
    timers[tostring(self) .. 'moveTween'] = tween(.1,self,{xMod=0,yMod=0},'linear')
  end
  currMap.contents[self.x][self.y][self] = nil
  currMap.feature_cache[x .. ',' .. y] = nil
  currMap.feature_cache[self.x .. ',' .. self.y] = nil
  self.x,self.y=x,y
  currMap.contents[x][y][self] = self
  if possibleFeatures[self.id].moves then
    local status,r = pcall(possibleFeatures[self.id].moves,self,x,y)
    if status == false then
      output:out("Error in feature " .. self.name .. " moves code: " .. r)
      print("Error in feature " .. self.name .. " moves code: " .. r)
    end
    return r
  end
	return true
end

---Damages a feature, destroying it if it has HP and the damage done was more than its HP.
--@param amt Number. How much damage is being done.
--@param source Entity. What is damaging the feature.
--@param damage_type String. The damage type. (optional)
--@param force Boolean. Whether or not to ignore the feature's damage() callback (optional)
--@param armor_piercing True/False, or Number. If set to true, it ignores all armor. If set to a number, ignores that much armor. (optional)
--@return Number. The final damage that was done.
function Feature:damage(amt,source,damage_type,force,armor_piercing)
  amt = math.ceil(amt) --just in case! to prevent fractional damage
  damage_type = damage_type or gamesettings.default_damage_type
  amt = self:calculate_damage_received(amt,damage_type,armor_piercing)
  
  if amt <= 0 then
    return 0
  end

  if not force and possibleFeatures[self.id].damage then --has custom damaged code?
    local status,ret = pcall(possibleFeatures[self.id].damage,self,amt,source,damage_type)
    if status == false then
      output:out("Error in feature " .. self.name .. " damage code: " .. ret)
      print("Error in feature " .. self.name .. " damage code: " .. ret)
    end
    if ret == false then
      return false
    elseif type(ret) == "number" then
      amt = ret
    end
  end
  if self.attackable then
    if self.hp then
      if not self.max_hp then self.max_hp = self.hp end
      self.hp = self.hp - amt
      local p = Effect('dmgpopup',self.x,self.y)
      p.symbol = "-" .. amt
      currMap:add_effect(p,self.x,self.y)
      if source then
        local xMod,yMod = get_unit_vector(source.x,source.y,self.x,self.y)
        self.xMod,self.yMod = (self.xMod or 0)+(xMod*5),(self.yMod or 0)+(yMod*5)
        if timers[tostring(self) .. 'moveTween'] then
          Timer.cancel(timers[tostring(self) .. 'moveTween'])
        end
        timers[tostring(self) .. 'moveTween'] = tween(.1,self,{xMod=0,yMod=0},'linear')
      end
    end --end if self.hp if
    if not self.hp or self.hp <= 0 then
      self:destroy(source,damage_type)
      return amt
    end --end hp <= 0
  end --end if self.attackable or damage
	return amt
end

---Calculates the damage amount a feature would receive based on damage types, weaknesses, armor, etc
--@param amt Number. The damage to deal.
--@param damage_type String. The damage type of the attack. (optional)
--@param armor_piercing True/False, or Number. If set to true, it ignores all armor. If set to a number, ignores that much armor. (optional)
--@param ignoreWeakness Boolean. If true, don't apply weakness (optional)
--@return Number. The final damage done.
function Feature:calculate_damage_received(amt,damage_type,armor_piercing,ignoreWeakness)
  local bonuses = 0
  damage_type = damage_type or gamesettings.default_damage_type
  --Apply damage weaknesses, resistances, and armor
  if damage_type then
    if self.damage_type_healing and in_table(damage_type,self.damage_type_healing) then
      self:updateHP(amt)
      return -amt
    end
    if self.damage_type_immunities and in_table(damage_type,self.damage_type_immunities) then
      return 0
    end
    if not ignoreWeakness and self.weaknesses and self.weaknesses[damage_type] then
      bonuses = bonuses + math.ceil(amt*(self.weaknesses[damage_type]/100))
    end
    bonuses = bonuses - math.ceil(amt*((self.resistances and self.resistances[damage_type] or 0)/100))
  end
  if not ignoreWeakness and self.weaknesses and self.weaknesses.all then
    bonuses = bonuses + math.ceil(amt*(self.weaknesses.all/100))
  end
  bonuses = bonuses - math.ceil(amt*((self.resistances and self.resistances.all or 0)/100))
  amt = amt + bonuses
  
  --Apply armor
  if self.armor and armor_piercing ~= true and (not damage_type or not damage_types[damage_type] or not damage_types[damage_type].armor_piercing) then
    local totalArmor = 0
    if type(self.armor) == "number" then
      totalArmor = self.armor
    else
      totalArmor = totalArmor + (self.armor.all or 0)
      if damage_type then totalArmor = totalArmor + (self.armor[damage_type] or 0) end
    end
    if type(armor_piercing) == "number" then
      totalArmor = math.max(totalArmor - armor_piercing,0)
    end
    amt = amt - totalArmor
  end
  return amt
end

---Destroy a feature. This is different from Feature:delete() in that it calls the destroy() callback and drops any items in its inventory
--@param source Entity. The source of the damage (optional)
--@param damage_type String. The damage type (optional)
function Feature:destroy(source,damage_type)
  local ret = true
  if possibleFeatures[self.id].destroy then --has custom destroyed code
    local status,ret = pcall(possibleFeatures[self.id].destroy,self,source,damage_type)
    if status == false then
      output:out("Error in feature " .. self.name .. " destroy code: " .. ret)
      print("Error in feature " .. self.name .. " destroy code: " .. ret)
    end
  end
  if ret ~= false then
    if self.destroy_feature and not currMap:tile_has_tag(self.x,self.y,'absorbs') then
      local feat = Feature(self.destroy_feature)
      feat.repair_feature = self.id
      if self.copy_color_to_destroy_feature then
        feat.color = copy_table(self.color)
      end
      currMap:add_feature(feat,self.x,self.y)
    end
    if self.destroy_effect then
      currMap:add_effect(Effect(self.destroy_effect),self.x,self.y)
    end
    if self.destroy_sound and player:can_see_tile(self.x,self.y) then
      output:sound(self.destroy_sound)
    end
    self:drop_all_items()
    self:delete()
  end
end

---Delete a feature from the map
--@param map The map that the feature is on. If blank, defaults to the current map. (optional)
function Feature:delete(map)
  map = map or currMap
  if map[self.x][self.y] == self then
    map[self.x][self.y] = "."
    map:refresh_tile_image(self.x,self.y)
  else
    for id,f in pairs(map.contents[self.x][self.y]) do
      if f == self or id == self then
        map.contents[self.x][self.y][id] = nil
      end --end if
    end --end for
  end
  map.feature_cache[self.x .. ',' .. self.y] = nil
  if self.animator then
    self.animator:delete(map)
  end
  if self.castsLight then map.lights[self] = nil end
  if self.blocksSight and map == currMap then refresh_player_sight() end
end

---Refresh the image name of a feature.
--Used for features that look different if they're next to each other, like water, when its surrounding has changed.
--@return Boolean. Whether the image name was refreshed or not
function Feature:refresh_image_name(map)
  map = map or currMap
  if self.x and self.y and possibleFeatures[self.id].refresh_image_name then
    local status,r = pcall(possibleFeatures[self.id].refresh_image_name,self,map)
    if status == false then
      output:out("Error in feature " .. self.name .. " refresh image code: " .. r)
      print("Error in feature " .. self.name .. " refresh image code: " .. r)
    end
    return r
  end
	return false
end

---Checks if a feature is hazardous for a certain creature type.
--@param ctype String. The creature type we're checking for. If blank, just checks if it's generally hazardous. (optional)
--@return Boolean. Whether or not the feature is hazardous.
function Feature:is_hazardous_for(ctype)
  if self.hazard and ((self.hazardousFor == nil and (ctype == nil or self.safeFor == nil or self.safeFor[ctype] ~= true)) or (ctype ~= nil and self.hazardousFor and self.hazardousFor[ctype] == true)) then
    return true 
  end
  return false
end

---Perform a feature's action() callback, if applicable.
--@param activator Creature. The creature activating the feature.
--@param actionID Text. The ID of the action (optional, only if a feature has multiple actions available).
--@param args. Anything. Other arguments to pass to the action (optional)
function Feature:action(activator,actionID,args)
  if possibleFeatures[self.id].action then
    local status,r,response = pcall(possibleFeatures[self.id].action,self,activator,actionID,args)
    if status == false then
      output:out("Error in feature " .. self.name .. " action code: " .. r)
      print("Error in feature " .. self.name .. " action code: " .. r)
    end
    return r,response
  end
  return false
end

---Check if a feature's action's requirements are met
--@param activator Creature. The creature activating the feature.
--@param actionID Text. The ID of the action (optional, only if a feature has multiple actions available).
function Feature:action_requires(activator,actionID)
  if possibleFeatures[self.id].action_requires then
    local status,r = pcall(possibleFeatures[self.id].action_requires,self,activator,actionID)
    if status == false then
      output:out("Error in feature " .. self.name .. " action requires code: " .. r)
      print("Error in feature " .. self.name .. " action requires code: " .. r)
    end
    return r
  end
  return true
end

---Perform a feature's take_item() callback, if applicable.
--@param taker Creature. The creature taking the item from the feature
--@param item Item. The item being taken
function Feature:take_item(taker,item)
  if possibleFeatures[self.id].take_item then
    local status,r = pcall(possibleFeatures[self.id].take_item,self,taker,item)
    if status == false then
      output:out("Error in feature " .. self.name .. " take_item code: " .. r)
      print("Error in feature " .. self.name .. " take_item code: " .. r)
    end
    return r
  end
  return true
end

---Perform a feature's cleanup() callback, if applicable.
--@param map Map. The map the feature is on
function Feature:cleanup(map)
  map = map or currMap
  if possibleFeatures[self.id].cleanup then
    local status,r = pcall(possibleFeatures[self.id].cleanup,self,map)
    if status == false then
      output:out("Error in feature " .. self.name .. " cleanup code: " .. r)
      print("Error in feature " .. self.name .. " cleanup code: " .. r)
    end
    return r
  end
  if self.hp and self.max_hp then
    self.hp = self.max_hp
  end
end

---Transfer an item to a feature's inventory
--@param item Item. The item to give.
function Feature:give_item(item,silent)
  local initial_amt = item.amount
  if item.possessor == self or self:has_specific_item(item) then return false end
  if (item.stacks == true) then
    local it,inv_id = self:has_item(item.id,(item.sortBy and item[item.sortBy]),item.enchantments,item.level)
    if inv_id then
      self.inventory[inv_id].amount = self.inventory[inv_id].amount + item.amount
      item = self.inventory[inv_id]
    else
      table.insert(self.inventory,item)
    end
  else
    table.insert(self.inventory,item)
  end
  item.x,item.y=self.x,self.y
  item.possessor = self
  --Add item popup:
  if currMap and self == currMap.stash and not silent then
    local popup1 = Effect('dmgpopup')
    popup1.symbol = "+" .. (initial_amt > 1 and initial_amt or "")
    popup1.color = {r=0,g=255,b=0,a=150}
    local tileMod = round(fonts.mapFontWithImages:getWidth(popup1.symbol)/2)
    popup1.xMod = -tileMod
    local popup2 = Effect('dmgpopup')
    popup2.image_name = item.image_name or item.id
    popup2.imageType = "item"
    popup2.xMod = tileMod
    popup2.speed = popup1.speed
    if (item.use_color_with_tiles ~= false or gamesettings.always_use_color_with_tiles) and item.color then
      popup2.color = {r=item.color.r,g=item.color.g,b=item.color.b,a=150}
    else
      popup2.color = {r=255,g=255,b=255,a=150}
    end
    popup1.paired = popup2
    popup2.paired = popup1
    popup2.itemID = item.id
    popup2.sortBy = (item.sortBy and item[item.sortBy] or nil)
    popup2.itemAmt = initial_amt
    popup1.display_when_unseen=true
    popup2.display_when_unseen=true
    currMap:add_effect(popup1,self.x,self.y)
    currMap:add_effect(popup2,self.x,self.y)
  end
  return item
end

---Have a feature "drop" an item it contains on to the tile it's on
--@param item Item. The item to drop
function Feature:drop_item(item)
	local id = in_table(item,self.inventory)
	if (id) then
    currMap:add_item(item,self.x,self.y,true)
		table.remove(self.inventory,id)
    item.x,item.y=self.x,self.y
    item.possessor=nil
	end
end

---Have a feature drop all their items on the tile they're on
function Feature:drop_all_items()
  if self.inventory then
    for _,item in ipairs(self.inventory) do
      currMap:add_item(item,self.x,self.y,true)
      item.x,item.y=self.x,self.y
      item.possessor=nil
    end --end inventory for loop
    self.inventory = {}
  end
end

---Delete an item from a feature's inventory
--@param item Item. The item to remove
--@param amt Number. The amount of the item to remove, if the item is stackable. Defaults to 1. 
function Feature:delete_item(item,amt,silent,noRecurs)
  amt = amt or 1
  local amount_to_delete = amt
	local id = in_table(item,self.inventory)
	if (id) then
    if amt == -1 or amt >= (item.amount or 0) then
      amount_to_delete = amount_to_delete - item.amount
      table.remove(self.inventory,id)
      local new_item = self:has_item(item.id,(item.sortBy and item[item.sortBy]),item.enchantments,item.level)
      while not noRecurs and (amt == -1 or amount_to_delete > 0) and new_item do
        self:delete_item(new_item,amount_to_delete,true,true)
        amount_to_delete = amount_to_delete - new_item.amount
        new_item = self:has_item(item.id,(item.sortBy and item[item.sortBy]),item.enchantments,item.level)
      end
    else
      item.amount = item.amount - amt
    end
	end
  --Add item popup:
  if currMap and self == currMap.stash and not silent then
    local popup1 = Effect('dmgpopup')
    popup1.symbol = (amt ~= 1 and -amt or "-")
    popup1.color = {r=255,g=0,b=0,a=150}
    local tileMod = round(fonts.mapFontWithImages:getWidth(popup1.symbol)/2)
    popup1.xMod = -tileMod
    local popup2 = Effect('dmgpopup')
    popup2.image_name = item.image_name or item.id
    popup2.imageType = "item"
    popup2.xMod = tileMod
    popup2.speed = popup1.speed
    if (item.use_color_with_tiles ~= false or gamesettings.always_use_color_with_tiles) and item.color then
      popup2.color = {r=item.color.r,g=item.color.g,b=item.color.b,a=150}
    else
      popup2.color = {r=255,g=255,b=255,a=150}
    end
    popup1.paired = popup2
    popup2.paired = popup1
    popup2.itemID = item.id
    popup2.sortBy = (item.sortBy and item[item.sortBy] or nil)
    popup2.itemAmt = -amt
    popup1.display_when_unseen=true
    popup2.display_when_unseen=true
    currMap:add_effect(popup1,self.x,self.y)
    currMap:add_effect(popup2,self.x,self.y)
  end
end

---Get every item in a feature's inventory:
function Feature:get_inventory()
  return self.inventory
end

---Check if a feature has an instance of an item ID
--@param item String. The item ID to check for
--@param sortBy Text. What the "sortBy" value you're checking is (optional)
--@param enchantments Table. The table of echantments to match (optional)
--@param level Number. The level of the item (optional)
--@return either Boolean or Item. False, or the specific item they have in their inventory
--@return either nil or Number. The index of the item in the inventory
--@return either nil or Number. The amount of the item the player has
function Feature:has_item(itemID,sortBy,enchantments,level)
  enchantments = enchantments or {}
  local item,index,amount = false,nil,0
  local largestAmt = 0
	for id, it in ipairs(self.inventory) do
		if (itemID == it.id) and (not level or it.level == level) and (not it.sortBy or sortBy == it[it.sortBy]) then
      local matchEnch = true
      --Compare enchantments:
      if (enchantments and count(enchantments) or 0) == (it.enchantments and count(it.enchantments) or 0) then
        for ench,turns in pairs(enchantments) do
          if it.enchantments[ench] ~= turns then
            matchEnch = false
            break
          end
        end --end enchantment for
      else --if the number of enchantments doesn't match, obviously the enchantments themselves won't match
        matchEnch = false
      end
      
      if matchEnch == true then
        amount = amount + it.amount
        if not item or it.amount > largestAmt and (not it.max_stack or it.amount < it.max_stack) then --we want to select the largest stack of items that's not a maxed-out stack of items
          if not it.max_stack or it.amount < it.max_stack then --don't set largest amount to a full stack
            largestAmt = it.amount
          end
          item,index = it,id
        end
      end
		end
	end --end inventory for
	return item,index,amount
end

---Check if a feature has a specific item
--@param item Item. The item to check for
--@return either Boolean or Item. False, or the specific item they have in their inventory
--@return either nil or Number. The index of the item in the inventory
--@return either nil or Number. The amount of the item the feature has
function Feature:has_specific_item(item)
	for id, it in ipairs(self.inventory) do
    if item == it then
      return it,id,it.amount
		end
	end --end inventory for
	return false
end

---Checks if a feature has a descriptive tag.
--@param tag String. The tag to check for
--@return Boolean. Whether or not it has the tag.
function Feature:has_tag(tag)
  if self.tags and in_table(tag,self.tags) then
    return true
  end
  return false
end

---Populate items in a feature
--@param map Map. The map the feature is in.
--@param room Room. The room the feature is in.
--@param forceDefault Boolean. If true, don't use any custom populate_items code
function Feature:populate_items(map,room,forceDefault)
  if possibleFeatures[self.id].populate_items and not forceDefault then
    local status,r = pcall(possibleFeatures[self.id].populate_items,self,map,room)
    if status == false then
      output:out("Error in feature " .. self.name .. " populate_items code: " .. r)
      print("Error in feature " .. self.name .. " populate_items code: " .. r)
    end
    self.used=true
    for _,item in pairs(self.inventory) do
      item.origin_map = map.id
      item.origin_branch = map.branch
    end
    return r
  end
  
  if self.item_chance and random(1,100) > self.item_chance then
    return {}
  end
  local newItems = {}
  local item_list = {}
  local min_level = self.min_level or map:get_min_level(true)
  local max_level = self.max_level or map:get_max_level(true)
  local decTags = (room and room.decorator and roomDecorators[room.decorator].passedTags or {})
  local mapPassed = map:get_content_tags('passed')
  local mapTags = (not self.noMapTags and map:get_content_tags('item') or nil)
  local passedTags = merge_tables(decTags, mapPassed,(self.passedTags or {}))
  local artifact_chance = self.artifact_chance or map.artifact_chance or gamesettings.artifact_chance or 0
  local enchantment_chance = self.enchantment_chance or map.enchantment_chance or gamesettings.enchantment_chance or 0
  
  --Create item list:
  if self.items then
    item_list = self.items or {}
  end --end if items
  if self.itemTags or self.contentTags or self.forbiddenTags then
    local tags = self.itemTags or self.contentTags or {}
    local forbidden = self.forbiddenTags
    local required = self.requiredTags
    local tagged_items = mapgen:get_content_list_from_tags('item',tags,{forbiddenTags=forbidden,requiredTags=required,mapTags=mapTags})
    item_list = merge_tables(item_list,tagged_items)
  elseif not self.items then --if there's no item list or tag list set, just use the item list of the room
    item_list = (room and room:get_item_list() or map:get_item_list())
  end
  
  ::gen_item::
  local ni = mapgen:generate_item(min_level,max_level,item_list,passedTags,nil,enchantment_chance,artifact_chance)
  newItems[#newItems+1] = ni
  self:modify_generated_item(ni,map,room)
  ni.origin_branch = map.branch
  ni.origin_map = map.id
  --ni.origin_room = room
  
  if self.inventory then
    self:give_item(ni)
    if #self:get_inventory() >= (self.inventory_space or 1) then
      self.used = true
    else
      goto gen_item
    end
  else
    map:add_item(ni,self.x,self.y)
    self.used = true
  end
  return newItems
end

---Modify an item generated by a feature
--@param item Item. The item to modify.
--@param map Map. The map the feature is in.
--@param room Room. The room the feature is in.
function Feature:modify_generated_item(item,map,room)
  if possibleFeatures[self.id].modify_generated_item then
    local status,r = pcall(possibleFeatures[self.id].modify_generated_item,self,item,map,room)
    if status == false then
      output:out("Error in feature " .. self.name .. " modify_generated_item code: " .. r)
      print("Error in feature " .. self.name .. " modify_generated_item code: " .. r)
    end
    return r
  end
  if self.apply_enchantments then
    for _,ench in ipairs(self.apply_enchantments) do
      if item:qualifies_for_enchantment(ench) then
        item:apply_enchantment(ench,-1)
      end
    end
  end
end

--Combustion, freezing, etc.

---Checks a feature's combust() callback, if applicable, and then lights it on fire if applicable.
--@param skip_basic Boolean. Whether to skip the combust() callback and just go ahead and light the fire. (optional)
--@param source Entity. The cause of the combustion
function Feature:combust(skip_basic,source)
  if not skip_basic and possibleFeatures[self.id].combust then
    local status,r = pcall(possibleFeatures[self.id].combust,self,source)
    if status == false then
      output:out("Error in feature " .. self.name .. " combust code: " .. r)
      print("Error in feature " .. self.name .. " combust code: " .. r)
    end
    return r
  end
  currMap:add_effect(Effect('fire',{creator=source,turns=(self.fireTime or 10)}),self.x,self.y)
  currMap:register_incident('light_fire',source,self)
  self:delete()
end

---Checks a feature's apply_cold() callback, if applicable, or its cold_feature flag, if applicable
--@param source Entity. The cause of the freezing
function Feature:apply_cold(source)
  if possibleFeatures[self.id].apply_cold then
    local status,r = pcall(possibleFeatures[self.id].apply_cold,self,source)
    if status == false then
      output:out("Error in feature " .. self.name .. " apply_cold code: " .. r)
      print("Error in feature " .. self.name .. " apply_cold code: " .. r)
    end
    return r
  end
  local chilled = false
  if self.cold_feature then
    local newfeat = Feature(self.cold_feature)
    if currMap[self.x][self.y] == self and not self.remain_on_cold then
      currMap:change_tile(newfeat,self.x,self.y)
    else
      currMap:add_feature(newfeat,self.x,self.y)
    end
    chilled = true
  end
  if self.cold_effect then
    local neweff = Effect(self.cold_effect)
    neweff.creator = source
    currMap:add_effect(neweff,self.x,self.y)
    chilled = true
  end
  if chilled and not self.remain_on_cold then self:delete() end
end

---Checks a feature's apply_heat() callback, if applicable, or its heat_feature flag, if applicable
--@param source Entity. The cause of the melting
function Feature:apply_heat(source)
  if possibleFeatures[self.id].melt then
    local status,r = pcall(possibleFeatures[self.id].apply_heat,self,source)
    if status == false then
      output:out("Error in feature " .. self.name .. " apply_heat code: " .. r)
      print("Error in feature " .. self.name .. " apply_heat code: " .. r)
    end
    return r
  end
  local heated = false
  if self.heat_feature then
    local newfeat = Feature(self.heat_feature)
    if currMap[self.x][self.y] == self and not self.remain_on_heat then
      currMap:change_tile(newfeat,self.x,self.y)
    else
      currMap:add_feature(newfeat,self.x,self.y)
    end
    heated = true
  end
  if self.heat_effect then
    local neweff = Effect(self.heat_effect)
    neweff.creator = source
    currMap:add_effect(neweff,self.x,self.y)
    heated = true
  end
  if heated and not self.remain_on_heat then self:delete() end
end