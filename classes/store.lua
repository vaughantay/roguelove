---@classmod Store
Store = Class{}

---Initiate a store from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the stores.
--@param data Table. The table of store data.
--@return self Store. The faction itself.
function Store:init(data)
	for key, val in pairs(data) do
		self[key] = data[key]
	end
  self.baseType = "store"
  if self.nameGen then
    self.name = self:nameGen()
  end
  self.inventory = {}
  self:generate_items()
	return self
end

function Store:generate_items()
  --Generate items from list:
  for _,info in pairs(self.sells_items) do
    local itemID = info.item
    local item = Item(itemID,nil,(info.amount or -1))
    if not item.amount then item.amount = (info.amount or -1) end
    self.inventory[#self.inventory+1] = item
    item.store_cost = info.cost
  end
  --Generate dynamic items:
end

function Store:get_inventory()
  return self.inventory
end

function Store:get_buy_list(creat)
end

function Store:creature_sells_item(item,amt,creature)
end

function Store:creature_buys_item(item,amt,creature)
  creature = creature or player
  local totalAmt = item.amount or 1
  local totalCost = item.store_cost*amt 
  if totalAmt == -1 then totalAmt = 9999999 end
  if amt > totalAmt then amt = totalAmt end
  if creature.money > totalCost then
    if amt == totalAmt then
      if item.stacks or totalAmt == 1 then
        creature:give_item(item)
        item.store_cost = nil
        if not item.stacks then item.amount = nil end
      elseif not item.stacks then
        for i=1,amt,1 do
          local newItem = item:clone()
          newItem.amount = nil
          newItem.store_cost = nil
          creature:give_item(newItem)
        end
      end
      local id = in_table(item,self.inventory)
      table.remove(self.inventory,id)
      creature.money = creature.money-totalCost
    elseif item.stacks then
      local newItem = item:clone()
      if item.amount ~= -1 then item.amount = item.amount - amt end
      newItem.amount = amt
      newItem.store_cost = nil
      creature:give_item(newItem)
      creature.money = creature.money-totalCost
    else
      for i=1,amt,1 do
        local newItem = item:clone()
        newItem.amount = nil
        newItem.store_cost = nil
        creature:give_item(newItem)
      end
      if item.amount ~= -1 then item.amount = item.amount - amt end
      creature.money = creature.money-totalCost
    end
  end
  return false,"You don't have enough money to buy " .. item:get_name(true,amt) .. " ."
end

function Store:requires()
end