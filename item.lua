item = {}
item.__index = item

function item:new(type_name)
	local newItem = {}
	local data = possibleLoot[type_name]
	for key, val in pairs(data) do
		if (type(val) ~= "function") then
			newItem[key] = data[key]
		end
	end
	if (data.new ~= nil) then
		data.new(newItem)
	end
	newItem.type = newItem.type or "other"
	newItem.baseType = "item"
	newItem.itemType = type_name
	if (newItem.stacks) then newItem.amount = 1 end
	setmetatable(newItem,item)
	return newItem
end

function item:generate(level)
	local newItem = nil
	-- This selects a random item from the table of possible loot, and compares the desired item level to this item's level. If it's a match, continue, otherwise select another one
	while (newItem == nil) do
		local n = get_random_key(possibleLoot)
		if (1==1) then
			newItem = n
		end
	end
	
	-- Create the actual item:
	newItem = item:new(newItem)
	return newItem
end

function item:get_description()
	return self:get_name(true) .. "\n" .. self.description
end

function item:print_full_description()
	local uses = ""
	love.graphics.printf(ucfirst(self:get_name(true)),450,25,335,"center")
	love.graphics.printf(self.description,450,50,335,"left")
	if (self.type == "weapon") then
		love.graphics.print("Damage: " .. self.damage,450,100)
		love.graphics.print("Accuracy Bonus: " .. self.accuracy .. "%",450,115)
		if (self.critical ~= nil) then
			love.graphics.print("Critical Bonus: " .. self.critical .. "%",450,130)
		end
	elseif (self.type == "armor") then
		love.graphics.print("Protection: " .. self.protection,450,100)
	end
	if (self.use) then
		uses = "Use (" .. keybindings.use .. ")\n"
	elseif (self.type == "weapon" or self.type == "armor") then
		if (player.wielding == self or player.armor == self) then
			uses = uses .. "Unequip (" .. keybindings.equip .. ")\n"
		else
			uses = uses .. "Equip (" .. keybindings.equip .. ")\n"
		end
	end
	uses = uses .. "Drop (" .. keybindings.drop .. ")"
	love.graphics.print(uses,450,200)
end

function item:get_name(full)
	if (full == true) then
		if (self.properName ~= nil) then
			return self.properName .. " (" .. self.name .. ")"
		else
			return self.name
		end
	elseif (self.properName ~= nil) then
		return self.properName
	else
		return (vowel(self.name) and "an " or "a " ) .. self.name
	end
end

function item:use(user,target)
	possibleLoot[self.itemType].use(self,user,target)
end

function item:attack(attacker,target)
	if (attacker:touching(target) and self.type == "weapon") then
		dmg = tweak(attacker.strength + self.damage)
		target:updateHP(-dmg)
		local txt = attacker:get_name() .. " attacks " .. target:get_name() .. " with " .. self:get_name() .. ", dealing " .. dmg .. " damage."
		output:out(txt)
	else
		return false
	end
end