Service = Class{}

function Service:init(data)
	for key, val in pairs(data) do
		self[key] = data[key]
	end
  self.baseType = "service"
	return self
end

function Service:activate(user)
  local req, reqtext = self:requires(user)
  if req == false then
    return false,reqtext
  end
  return self:use(user)
end

function Service:get_cost(user)
  return self.cost
end

function Service:requires(user)
  return true
end