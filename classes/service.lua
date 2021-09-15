---@classmod Service
Service = Class{}

---Initiate a service from its definition. You shouldn't use this function, the game uses it at loadtime to instantiate the services.
--@param data Table. The table of service information.
--@return Service. The service itself.
function Service:init(data)
	for key, val in pairs(data) do
		self[key] = data[key]
	end
  self.baseType = "service"
	return self
end

---Activate a service, if the player meets its requires() code. Calls the use() code of the service.
--@param user Creature. The creature trying to use the service (defauls to player)
--@return Boolean. Whether or not the use of the service was successful.
--@return String. A string explaining why it wasn't successful.
function Service:activate(user)
  user = user or player
  local req, reqtext = self:requires(user)
  if req == false then
    return false,reqtext
  end
  return self:use(user)
end

---Gets the cost text of the service.
--@return String. The service's cost text.
function Service:get_cost_text()
  return self.cost_text
end

--Placeholder for the requires() callback, used to determine if the creature meets the requirements for using the serviec
--@param user Creature. The creature who's trying to use the service.
--@return true
function Service:requires(user)
  return true
end