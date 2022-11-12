---@classmod Feature
Feature = Class{}

---Initiates a feature. Don't call this explicitly, it's called when you create a new feature using Feature('featureID').
--@param feature_type The ID of the feature you'd like to create
--@param info An argument to pass to the feature's new() function, if applicable (optional)
--@param x The x-coordinate (optional, will be set when it is added to the map)
--@param y The y-coordinate (optional, will be set when it is added to the map)
--@return The feature itself.
function Feature:init(feature_type,info,x,y)
  local data = possibleFeatures[feature_type]
  if not data then
    output:out("Error: Tried to create non-existent feature " .. feature_type)
    print("Error: Tried to create non-existent feature " .. feature_type)
    return false
  end
	for key, val in pairs(data) do
    if type(val) ~= "function" then
      self[key] = data[key]
    end
	end
  if x and y then self.x, self.y = x,y end
  if self.container then self.inventory = {} end
  if self.actions then self.actions = copy_table(self.actions) end
	if (possibleFeatures[feature_type].new ~= nil) then 
		possibleFeatures[feature_type].new(self,(info or nil),x,y)
	end
  self.id = self.id or feature_type
	self.baseType = "feature"
  self.color = copy_table(self.color)
  if self.image_varieties and not self.image_name then
    self.image_variety = random(1,self.image_varieties)
    self.image_name = self.id .. self.image_variety
    if not images['feature' .. self.image_name] then
      self.image_name = nil
    end
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
		return (self.properNamed ~= true and "a " or "") .. self.name
	end
end

---Returns the description of the feature, and descriptive lines noting what you can do with it.
--@return String. The description.
function Feature:get_description()
	local txt = self.name .. "\n" .. self.description
  if self.attackable then txt = txt .. "\nYou can attack it." end
  if self.pushable then txt = txt .. "\nYou can push it." end
  if self.inventory and not self.inventory_inaccessible then
    txt = txt .. "\nIt contains: "
    for i,item in ipairs(self.inventory) do
      txt = txt .. (i ~= 1 and ", " or "") .. item:get_name()
    end
  end
  return txt
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
  if possibleFeatures[self.id].enter then return possibleFeatures[self.id].enter(self,enterer,fromX,fromY) end
	return true
end

---Pushes a feature, if it's pushable. This also calls the push() callback of a feature, if applicable.
--@param pusher Creature. The creature pushing the feature. This will be used to determine where it is being pushed to.
--@return Boolean. Whether or not the push went through.
function Feature:push(pusher)
  if self.pushable == false then return false end
  if possibleFeatures[self.id].push then return possibleFeatures[self.id].push(self,pusher) end
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
    if self.moveTween then
      Timer.cancel(self.moveTween)
    end
    self.moveTween = tween(.1,self,{xMod=0,yMod=0},'linear')
  end
  currMap.contents[self.x][self.y][self] = nil
  self.x,self.y=x,y
  currMap.contents[x][y][self] = self
  if possibleFeatures[self.id].moves then return possibleFeatures[self.id].moves(self,x,y) end
	return true
end

---Damages a feature, destroying it if it has HP and the damage done was more than its HP.
--@param amt Number. How much damage is being done.
--@param source Entity. What is damaging the feature.
--@param damage_type String. The damage type. (optional)
--@param force Boolean. Whether or not to ignore the feature's damage() callback (optional)
--@return Number. The final damage that was done.
function Feature:damage(amt,source,damage_type,force)
  if not force and possibleFeatures[self.id].damage then --has custom damaged code?
    return possibleFeatures[self.id].damage(self,amt,source,damage_type)
  elseif self.attackable then
    if self.hp then
      self.hp = self.hp - amt
      local p = Effect('dmgpopup',self.x,self.y)
      p.symbol = "-" .. amt
      currMap:add_effect(p,self.x,self.y)
      local xMod,yMod = get_unit_vector(source.x,source.y,self.x,self.y)
      self.xMod,self.yMod = (self.xMod or 0)+(xMod*5),(self.yMod or 0)+(yMod*5)
      if self.moveTween then
        Timer.cancel(self.moveTween)
      end
      self.moveTween = tween(.1,self,{xMod=0,yMod=0},'linear')
    end --end if self.hp if
    if not self.hp or self.hp <= 0 then
      if possibleFeatures[self.id].destroyed then --has custom destroyed code
        return possibleFeatures[self.id].destroyed(self,source)
      else
        self:delete()
        return amt
      end --end custom destroyed code
    end --end hp <= 0
  end --end if self.attackable or damage
	return amt
end

---Delete a feature from the map
--@param map The map that the feature is on. If blank, defaults to the current map. (optional)
function Feature:delete(map)
  map = map or currMap
  for id,f in pairs(map.contents[self.x][self.y]) do
    if f == self or id == self then
      map.contents[self.x][self.y][id] = nil
    end --end if
  end --end for
  map.feature_cache[self.x .. ',' .. self.y] = nil
  if self.castsLight then map.lights[self] = nil end
  if self.blocksSight then refresh_player_sight() end
end

---Refresh the image name of a feature.
--Used for features that look different if they're next to each other, like water, when its surrounding has changed.
--@return Boolean. Whether the image name was refreshed or not
function Feature:refresh_image_name(map)
  if possibleFeatures[self.id].refresh_image_name then return possibleFeatures[self.id].refresh_image_name(self,map) end
	return false
end

---Checks if a feature is hazardous for a certain creature type.
--@param ctype String. The creature type we're checking for. If blank, just checks if it's generally hazardous. (optional)
--@return Boolean. Whether or not the feature is hazardous.
function Feature:is_hazardous_for(ctype)
  if self.hazard and ((self.hazardousFor == nil and (ctype == nil or self.safeFor == nil or self.safeFor[ctype] ~= true)) or (ctype ~= nil and self.hazardousFor and self.hazardousFor[ctype] == true)) then
    return true 
  end
end

---Checks a feature's combust() callback, if applicable, and then lights it on fire if applicable.
--@param skip_basic Boolean. Whether to skip the combust() callback and just go ahead and light the fire. (optional)
function Feature:combust(skip_basic)
  if not skip_basic and possibleFeatures[self.id].combust then return possibleFeatures[self.id].combust(self) end
  currMap:add_effect(Effect('fire',{x=self.x,y=self.y,timer=(self.fireTime or 10)}),self.x,self.y)
  self:delete()
end

---Perform a feature's action() callback, if applicable.
--@param activator Creature. The creature activating the feature.
--@param actionID Text. The ID of the action (optional, only if a feature has multiple actions available).
function Feature:action(activator,actionID)
  if possibleFeatures[self.id].action then return possibleFeatures[self.id].action(self,activator,actionID) end
  return false
end

---Transfer an item to a feature's inventory
--@param item Item. The item to give.
function Feature:give_item(item)
  if (item.stacks == true) then
    local _,inv_id = self:has_item(item.id,(item.sortBy and item[item.sortBy]),item.enchantments,item.level)
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
  item.owner = self
  return item
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
        return it,id,it.amount
      end
		end
	end --end inventory for
	return false,nil,0
end