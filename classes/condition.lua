Condition = Class{}

function Condition:init(data)
	for key, val in pairs(data) do
		self[key] = data[key]
	end
	return self
end

function Condition:advance(possessor)
	return true
end

function Condition:moves(possessor,target)
	return true
end

function Condition:attacks(possessor,target)
	return true
end

function Condition:apply(possessor,applier,turns)
	if (self.applied ~= nil) then
		return self:applied(possessor,applier,turns)
	end
end

function Condition:cure(possessor)
	if (self.cured ~= nil) then
		return self:cured(possessor)
	end
end