local pairs, ipairs, tostring, type, getmetatable, setmetatable, concat, sort, dump, format, floor = pairs, ipairs, tostring, type, getmetatable, setmetatable, table.concat, table.sort, string.dump, string.format, math.floor
local weakkeys = {__mode = 'k'}
local weakvalues = {__mode = 'v'}
local M = {
	_VERSION = 'Lady 0.2',
	_DESCRIPTION = 'Easy saving and loading for LÖVE games',
	_URL = 'http://github.com/gvx/Lady',
	_LICENSE = 'MIT License',
}
local registered_things_by_name = {}
local registered_things_by_value = {}
local joint_bodies = setmetatable({}, weakkeys)
local body_joints = setmetatable({}, weakkeys)
local kw = {['and'] = true, ['break'] = true, ['do'] = true, ['else'] = true,
	['elseif'] = true, ['end'] = true, ['false'] = true, ['for'] = true,
	['function'] = true, ['goto'] = true, ['if'] = true, ['in'] = true,
	['local'] = true, ['nil'] = true, ['not'] = true, ['or'] = true,
	['repeat'] = true, ['return'] = true, ['then'] = true, ['true'] = true,
	['until'] = true, ['while'] = true}
local function valid_identifier(s)
	return s:match '^[_%a][_%w]*$' and not kw[s]
end
local function valid_classname(s)
	return s:match '^%a[_%w]*$' and not kw[s]
end


function M.register_class(c, name)
	name = name or c.__name__ or c.name
	assert(type(name) == 'string', 'class must be given a string name')
	assert(valid_classname(name), 'name must be a valid identifier that doesn\'t start with an underscore')
	assert(registered_things_by_name[name] == nil, ('class with the name %s has already been registered'):format(name))
	assert(registered_things_by_value[c] == nil, 'class has already been registered')
	registered_things_by_name[name] = c
	registered_things_by_value[c] = name
	return c
end

function M.register_resource(r, name)
	assert(type(name) == 'string', 'resource must be given a string name')
	assert(valid_identifier(name), 'name must be a valid identifier')
	assert(registered_things_by_name['_R' .. name] == nil, ('resource with the name %s has already been registered'):format(name))
	assert(registered_things_by_value[r] == nil, 'resource has already been registered')
	name = '_R' .. name
	registered_things_by_name[name] = r
	registered_things_by_value[r] = name
	return r
end

function M.register_resource_table(rt, tname)
	tname = tname and tname .. '_' or ''
	for k, v in pairs(rt) do
		M.register_resource(v, tname .. k)
	end
	return rt
end

local function add_body_joint(body, joint)
	if not body_joints[body] then
		body_joints[body] = {}
	end
	body_joints[body][#body_joints[body] + 1] = joint
end

if love.physics then
	local newDistanceJoint = love.physics.newDistanceJoint
	function love.physics.newDistanceJoint(body1, body2, ...)
		local joint = newDistanceJoint(body1, body2, ...)
		joint_bodies[joint] = setmetatable({body1, body2}, weakvalues)
		add_body_joint(body1, joint)
		add_body_joint(body2, joint)
		return joint
	end
	local newFrictionJoint = love.physics.newFrictionJoint
	function love.physics.newFrictionJoint(body1, body2, ...)
		local joint = newFrictionJoint(body1, body2, ...)
		joint_bodies[joint] = setmetatable({body1, body2}, weakvalues)
		add_body_joint(body1, joint)
		add_body_joint(body2, joint)
		return joint
	end
	local newGearJoint = love.physics.newGearJoint
	function love.physics.newGearJoint(joint1, joint2, ...)
		local joint = newGearJoint(joint1, joint2, ...)
		joint_bodies[joint] = setmetatable({joint1, joint2}, weakvalues)
		add_body_joint(joint1, joint)
		add_body_joint(joint2, joint)
		return joint
	end
	local newMouseJoint = love.physics.newMouseJoint
	function love.physics.newMouseJoint(body, ...)
		local joint = newMouseJoint(body, ...)
		joint_bodies[joint] = setmetatable({body}, weakvalues)
		add_body_joint(body, joint)
		add_body_joint(body, joint)
		return joint
	end
	local newPrismaticJoint = love.physics.newPrismaticJoint
	function love.physics.newPrismaticJoint(body1, body2, ...)
		local joint = newPrismaticJoint(body1, body2, ...)
		joint_bodies[joint] = setmetatable({body1, body2}, weakvalues)
		add_body_joint(body1, joint)
		add_body_joint(body2, joint)
		return joint
	end
	local newPulleyJoint = love.physics.newPulleyJoint
	function love.physics.newPulleyJoint(body1, body2, ...)
		local joint = newPulleyJoint(body1, body2, ...)
		joint_bodies[joint] = setmetatable({body1, body2}, weakvalues)
		add_body_joint(body1, joint)
		add_body_joint(body2, joint)
		return joint
	end
	local newRevoluteJoint = love.physics.newRevoluteJoint
	function love.physics.newRevoluteJoint(body1, body2, ...)
		local joint = newRevoluteJoint(body1, body2, ...)
		joint_bodies[joint] = setmetatable({body1, body2}, weakvalues)
		add_body_joint(body1, joint)
		add_body_joint(body2, joint)
		return joint
	end
	local newRopeJoint = love.physics.newRopeJoint
	function love.physics.newRopeJoint(body1, body2, ...)
		local joint = newRopeJoint(body1, body2, ...)
		joint_bodies[joint] = setmetatable({body1, body2}, weakvalues)
		add_body_joint(body1, joint)
		add_body_joint(body2, joint)
		return joint
	end
	local newWeldJoint = love.physics.newWeldJoint
	function love.physics.newWeldJoint(body1, body2, ...)
		local joint = newWeldJoint(body1, body2, ...)
		joint_bodies[joint] = setmetatable({body1, body2}, weakvalues)
		add_body_joint(body1, joint)
		add_body_joint(body2, joint)
		return joint
	end
	local newWheelJoint = love.physics.newWheelJoint
	function love.physics.newWheelJoint(body1, body2, ...)
		local joint = newWheelJoint(body1, body2, ...)
		joint_bodies[joint] = setmetatable({body1, body2}, weakvalues)
		add_body_joint(body1, joint)
		add_body_joint(body2, joint)
		return joint
	end

end

local function getchr(c)
	return "\\" .. c:byte()
end

local function make_safe(text)
	return ("%q"):format(text):gsub('\n', 'n'):gsub("[\128-\255]", getchr)
end

local oddvals = {[tostring(1/0)] = '1/0', [tostring(-1/0)] = '-1/0', [tostring(0/0)] = '0/0'}
local userdata_constructor = {}
local function write(t, memo, rev_memo)
	local ty = type(t)
	if ty == 'number' then
		t = format("%.17g", t)
		return oddvals[t] or t
	elseif ty == 'boolean' or ty == 'nil' then
		return tostring(t)
	elseif ty == 'string' then
		return make_safe(t)
	elseif ty == 'table' or ty == 'function' or (ty == 'userdata' and userdata_constructor[t:type()] and not registered_things_by_value[t]) then
		if not memo[t] then
			local index = #rev_memo + 1
			memo[t] = index
			rev_memo[index] = t
		end
		return '_[' .. memo[t] .. ']'
	elseif ty == 'userdata' then
		if registered_things_by_value[t] then
			return registered_things_by_value[t]
		end
		error("Trying to serialize unregistered userdata " .. t:type())
	else
		error("Trying to serialize unsupported type " .. ty)
	end
end

local function write_key_value_pair(k, v, memo, rev_memo, name)
	if type(k) == 'string' and valid_identifier(k) then
		return (name and name .. '.' or '') .. k ..'=' .. write(v, memo, rev_memo)
	else
		return (name or '') .. '[' .. write(k, memo, rev_memo) .. ']=' .. write(v, memo, rev_memo)
	end
end

-- fun fact: this function is not perfect
-- it has a few false positives sometimes
-- but no false negatives, so that's good
local function is_cyclic(memo, sub, super)
	local m = memo[sub]
	local p = memo[super]
	return m and p and m < p
end

function userdata_constructor:World(srefs, memo, rev_memo)
	local s = memo[self]
	if self:getCallbacks() ~= nil then
		srefs[#srefs + 1] = {s, ':', 'setCallbacks', self:getCallbacks()}
	end
	if self:getContactFilter() ~= nil then
		srefs[#srefs + 1] = {s, ':', 'setContactFilter', self:getContactFilter()}
	end
	local x, y = self:getGravity( )
	return x, y, self:isSleepingAllowed()
end
function userdata_constructor:Body(srefs, memo, rev_memo)
	local s = memo[self]
	srefs[#srefs + 1] = {s, ':', 'setSleepingAllowed', self:isSleepingAllowed()}
	srefs[#srefs + 1] = {s, ':', 'setAngle', self:getAngle()}
	srefs[#srefs + 1] = {s, ':', 'setAngularDamping', self:getAngularDamping()}
	srefs[#srefs + 1] = {s, ':', 'setAngularVelocity', self:getAngularVelocity()}
	srefs[#srefs + 1] = {s, ':', 'setGravityScale', self:getGravityScale()}
	srefs[#srefs + 1] = {s, ':', 'setInertia', self:getInertia()}
	srefs[#srefs + 1] = {s, ':', 'setLinearDamping', self:getLinearDamping()}
	srefs[#srefs + 1] = {s, ':', 'setLinearVelocity', self:getLinearVelocity()}
	srefs[#srefs + 1] = {s, ':', 'setMass', self:getMass()}
	srefs[#srefs + 1] = {s, ':', 'setAwake', self:isAwake()}
	srefs[#srefs + 1] = {s, ':', 'setBullet', self:isBullet()}

	if body_joints[self] then
		for i, joint in ipairs(body_joints[self]) do
			if not memo[joint] then
				local index = #rev_memo + 1
				memo[joint] = index
				rev_memo[index] = joint
			end
		end
	end

	local x, y = self:getPosition()
	return self.getWorld and self:getWorld() or rev_memo[1], x, y, self:getType()
end
function userdata_constructor:ChainShape(srefs)
	return false, self:getPoints()
end
function userdata_constructor:CircleShape(srefs)
	local x, y = self:getPoint()
	return x, y, self:getRadius()
end
function userdata_constructor:EdgeShape(srefs)
	return self:getPoints()
end
function userdata_constructor:PolygonShape(srefs)
	return self:getPoints()
end
function userdata_constructor:Fixture(srefs, memo, rev_memo)
	local s = memo[self]
	--the ones commented out are just replicating the data from get/setFilterData
	--srefs[#srefs + 1] = {s, ':', 'setCategory', self:getCategory()}
	srefs[#srefs + 1] = {s, ':', 'setFilterData', self:getFilterData()}
	srefs[#srefs + 1] = {s, ':', 'setFriction', self:getFriction()}
	--srefs[#srefs + 1] = {s, ':', 'setGroupIndex', self:getGroupIndex()}
	--srefs[#srefs + 1] = {s, ':', 'setMask', self:getMask()}
	srefs[#srefs + 1] = {s, ':', 'setRestitution', self:getRestitution()}
	srefs[#srefs + 1] = {s, ':', 'setSensor', self:isSensor()}
	if self:getUserData() ~= nil then
		srefs[#srefs + 1] = {s, ':', 'setUserData', self:getUserData()}
	end
	return self:getBody(), self:getShape(), self:getDensity()
end
function userdata_constructor:DistanceJoint(srefs)
	local s = memo[self]
	srefs[#srefs + 1] = {s, ':', 'setDamping', self:getDamping()}
	srefs[#srefs + 1] = {s, ':', 'setDampingRatio', self:getDampingRatio()}
	srefs[#srefs + 1] = {s, ':', 'setFrequency', self:getFrequency()}
	srefs[#srefs + 1] = {s, ':', 'setLength', self:getLength()}
	local body1, body2 = unpack(joint_bodies)
	local x1, y1, x2, y2 = self:getAnchors()
	return body1, body2, x1, y1, x2, y2, self:getCollideConnected()
end
function userdata_constructor:FrictionJoint(srefs)
	local s = memo[self]
	srefs[#srefs + 1] = {s, ':', 'setMaxForce', self:getMaxForce()}
	srefs[#srefs + 1] = {s, ':', 'setMaxTorque', self:getMaxTorque()}
	local body1, body2 = unpack(joint_bodies)
	local x1, y1 = self:getAnchors()
	return body1, body2, x1, y1, self:getCollideConnected()
end
function userdata_constructor:GearJoint(srefs)
	local joint1, joint2 = unpack(joint_bodies)
	return joint1, joint2, self:getRatio(), self:getCollideConnected()
end
function userdata_constructor:MouseJoint(srefs)
	local s = memo[self]
	srefs[#srefs + 1] = {s, ':', 'setDampingRatio', self:getDampingRatio()}
	srefs[#srefs + 1] = {s, ':', 'setFrequency', self:getFrequency()}
	srefs[#srefs + 1] = {s, ':', 'setMaxForce', self:getMaxForce()}
	local body = unpack(joint_bodies)
	return body, self:getTarget()
end
function userdata_constructor:PrismaticJoint(srefs)
	local s = memo[self]
	srefs[#srefs + 1] = {s, ':', 'setLimits', self:getLimits()}
	srefs[#srefs + 1] = {s, ':', 'setLimitsEnabled', self:hasLimitsEnabled()}
	srefs[#srefs + 1] = {s, ':', 'setMaxMotorForce', self:getMaxMotorForce()}
	srefs[#srefs + 1] = {s, ':', 'setMotorEnabled', self:isMotorEnabled()}
	local body1, body2 = unpack(joint_bodies)
	local x1, y1, x2, y2 = self:getAnchors()
	return body1, body2, x1, y1, x2, y2, self:getCollideConnected()
end
function userdata_constructor:PulleyJoint(srefs)
	local s = memo[self]
	srefs[#srefs + 1] = {s, ':', 'setConstant', self:getConstant()}
	srefs[#srefs + 1] = {s, ':', 'setMaxLengths', self:getMaxLengths()}
	local body1, body2 = unpack(joint_bodies)
	local gx1, gy1, gx2, gy2 = self:getGroundAnchors()
	local x1, y1, x2, y2 = self:getAnchors()
	return body1, body2, gx1, gy1, gx2, gy2, gx1, gy1, gx2, gy2, self:getRatio(), self:getCollideConnected()
end
function userdata_constructor:RevoluteJoint(srefs)
	local s = memo[self]
	srefs[#srefs + 1] = {s, ':', 'setLimits', self:getLimits()}
	srefs[#srefs + 1] = {s, ':', 'setLimitsEnabled', self:hasLimitsEnabled()}
	srefs[#srefs + 1] = {s, ':', 'setMaxMotorTorque', self:getMaxMotorTorque()}
	srefs[#srefs + 1] = {s, ':', 'setMotorEnabled', self:isMotorEnabled()}
	srefs[#srefs + 1] = {s, ':', 'setMotorSpeed', self:getMotorSpeed()}
	local body1, body2 = unpack(joint_bodies)
	local x1, y1 = self:getAnchors()
	return body1, body2, x1, y1, self:getCollideConnected()
end
function userdata_constructor:RopeJoint(srefs)
	local body1, body2 = unpack(joint_bodies)
	local x1, y1, x2, y2 = self:getAnchors()
	return body1, body2, x1, y1, x2, y2, self:getMaxLength(), self:getCollideConnected()
end
function userdata_constructor:WeldJoint(srefs)
	local s = memo[self]
	srefs[#srefs + 1] = {s, ':', 'setDampingRatio', self:getDampingRatio()}
	srefs[#srefs + 1] = {s, ':', 'setFrequency', self:getFrequency()}
	local body1, body2 = unpack(joint_bodies)
	local x1, y1, x2, y2 = self:getAnchors()
	return body1, body2, x1, y1, x2, y2, self:getCollideConnected()
end
function userdata_constructor:WheelJoint(srefs)
	local s = memo[self]
	srefs[#srefs + 1] = {s, ':', 'setMaxMotorTorque', self:getMaxMotorTorque()}
	srefs[#srefs + 1] = {s, ':', 'setMotorEnabled', self:isMotorEnabled()}
	srefs[#srefs + 1] = {s, ':', 'setMotorSpeed', self:getMotorSpeed()}
	srefs[#srefs + 1] = {s, ':', 'setSpringDampingRatio', self:getSpringDampingRatio()}
	srefs[#srefs + 1] = {s, ':', 'setSpringFrequency', self:getSpringFrequency()}
	local body1, body2 = unpack(joint_bodies)
	local x1, y1, x2, y2 = self:getAnchors()
	return body1, body2, x1, y1, x2, y2, self:getCollideConnected()
end
function userdata_constructor:ParticleSystem(srefs)
	local s = memo[self]
	srefs[#srefs + 1] = {s, ':', 'setAreaSpread', self:getAreaSpread()}
	srefs[#srefs + 1] = {s, ':', 'setColors', self:getColors()}
	srefs[#srefs + 1] = {s, ':', 'setDirection', self:getDirection()}
	srefs[#srefs + 1] = {s, ':', 'setEmissionRate', self:getEmissionRate()}
	srefs[#srefs + 1] = {s, ':', 'setEmitterLifetime', self:getEmitterLifetime()}
	srefs[#srefs + 1] = {s, ':', 'setInsertMode', self:getInsertMode()}
	srefs[#srefs + 1] = {s, ':', 'setLinearAcceleration', self:getLinearAcceleration()}
	srefs[#srefs + 1] = {s, ':', 'setOffset', self:getOffset()}
	srefs[#srefs + 1] = {s, ':', 'setParticleLifetime', self:getParticleLifetime()}
	srefs[#srefs + 1] = {s, ':', 'setPosition', self:getPosition()}
	srefs[#srefs + 1] = {s, ':', 'setRadialAcceleration', self:getRadialAcceleration()}
	srefs[#srefs + 1] = {s, ':', 'setRelativeRotation', self:getRelativeRotation()}
	srefs[#srefs + 1] = {s, ':', 'setRotation', self:getRotation()}
	srefs[#srefs + 1] = {s, ':', 'setSizeVariation', self:getSizeVariation()}
	srefs[#srefs + 1] = {s, ':', 'setSizes', self:getSizes()}
	srefs[#srefs + 1] = {s, ':', 'setSpeed', self:getSpeed()}
	srefs[#srefs + 1] = {s, ':', 'setSpin', self:getSpin()}
	srefs[#srefs + 1] = {s, ':', 'setSpinVariation', self:getSpinVariation()}
	srefs[#srefs + 1] = {s, ':', 'setSpread', self:getSpread()}
	srefs[#srefs + 1] = {s, ':', 'setTangentialAcceleration', self:getTangentialAcceleration()}
	if self:isActive() then
		srefs[#srefs + 1] = {s, ':', 'start('}
	end
	local body1, body2 = unpack(joint_bodies)
	local x1, y1, x2, y2 = self:getAnchors()
	return self:getTexture(), self:getBufferSize()
end

local function write_table_ex(t, memo, rev_memo, srefs, name)
	if type(t) == 'function' then
		return '_[' .. name .. ']=_L' .. make_safe(dump(t))
	elseif type(t) == 'userdata' then
		local m = {}
		for i, arg in ipairs{userdata_constructor[t:type()](t, srefs, memo, rev_memo)} do
			m[i] = write(arg, memo, rev_memo)
		end
		return '_[' .. name .. ']=love.physics.new' .. t:type() .. '(' + concat(m, ',') + ')'
	end
	-- check for class
	local pretable = '{'
	local posttable = '}'
	local classkey = nil
	local classname = nil
	if registered_things_by_value[t.class] then
		-- assume MiddleClass
		classname = registered_things_by_value[t.class]
		classkey = 'class'
		pretable = '_S({'
		posttable = '},' .. classname .. '.__instanceDict)'
	elseif registered_things_by_value[t.__baseclass] then
		-- assume SECS
		classname = registered_things_by_value[t.__baseclass]
		classkey = '__baseclass'
		pretable = '_S({'
		posttable = '},_M(' .. classname .. '))'
	elseif registered_things_by_value[getmetatable(t)] then
		-- assume hump.class
		classname = registered_things_by_value[getmetatable(t)]
		pretable = '_S({'
		posttable = '},' .. classname .. ')'
	elseif registered_things_by_value[t.__class__] then
		-- assume Slither
		classname = registered_things_by_value[t.__class__]
		pretable = '_M(' .. classname .. ').allocate{'
		posttable = '}'
	end
	local m = {}
	local mi = 1
	for i = 1, #t do -- don't use ipairs here, we need the gaps
		local v = t[i]
		if v == t or is_cyclic(memo, v, t) then
			srefs[#srefs + 1] = {name, '.', i, v}
			m[mi] = 'nil'
			mi = mi + 1
		else
			m[mi] = write(v, memo, rev_memo)
			mi = mi + 1
		end
	end
	for k,v in pairs(t) do
		if type(k) ~= 'number' or floor(k) ~= k or k < 1 or k > #t then
			if k == classkey then
				m[mi] = k .. '=' .. classname
				mi = mi + 1
			elseif v == t or k == t or is_cyclic(memo, v, t) or is_cyclic(memo, k, t) then
				srefs[#srefs + 1] = {name, '.', k, v}
			else
				m[mi] = write_key_value_pair(k, v, memo, rev_memo)
				mi = mi + 1
			end
		end
	end
	return '_[' .. name .. ']=' .. pretable .. concat(m, ',') .. posttable
end

local function orderobjects(a, b)
	if type(a[2]) == 'userdata' then
		if type(b[2]) ~= 'userdata' then
			return true
		end
		if a[2]:typeOf('World') then
			return true
		end
		if b[2]:typeOf('World') then
			return false
		end
		if a[2]:typeOf('Fixture') then
			return false
		end
		if b[2]:typeOf('Fixture') then
			return true
		end
		if a[2]:typeOf('Joint') then
			return false
		end
		if b[2]:typeOf('Joint') then
			return true
		end
	elseif type(b[2]) == 'userdata' then
		return false
	end
	return b[1] < a[1]
end

function M.save_all(savename, ...)
	local memo = {}
	local rev_memo = {...}
	for k, v in ipairs(rev_memo) do
		memo[v] = k
	end
	local srefs = {}
	local result = {}

	-- phase 1: recursively descend the table structure
	local n = 1
	while rev_memo[n] do
		result[n] = {n, rev_memo[n], write_table_ex(rev_memo[n], memo, rev_memo, srefs, n)}
		n = n + 1
	end

	-- phase 2: the right order
	sort(result, orderobjects)
	for i = 1, #result do
		result[i] = result[i][3]
	end

	-- phase 3: add all the tricky cyclic stuff
	for i, v in ipairs(srefs) do
		if v[2] == '.' then
			result[n] = write_key_value_pair(v[3], v[4], memo, rev_memo, '_[' .. v[1] .. ']')
		else
			local tmp = {'_[', v[1], ']:', v[3], '('}
			for i = 4, #v do
				tmp[i * 2 - 2] = write(v[i], memo, rev_memo)
				tmp[i * 2 - 1] = ','
			end
			tmp[#tmp] = ')'
			result[n] = concat(tmp)
		end
		n = n + 1
	end

	-- phase 4: add something about returning the main tables
	local r = {'return '}
	for i = 1, select('#', ...) do
		r[i * 3 - 1] = '_['
		r[i * 3] = tostring(i)
		r[i * 3 + 1] = '],'
	end
	r[#r] = ']'
	result[n] = concat(r)

	-- phase 5: just concatenate everything
	local contents = concat(result, '\n')
	
	-- phase 6: store contents
	love.filesystem.write(savename, n > 1 and 'local _={}\n' .. contents or contents)
end

local load_mt = {__index = registered_things_by_name}
function M.load_all(savename)
	local contents = love.filesystem.read(savename)
	if contents then
		local s = loadstring(contents)
		if not s then return nil end
		setfenv(s, setmetatable({_L = loadstring, _S = setmetatable, _M = getmetatable, love = love}, load_mt))
		return s()
	else
		return nil
	end
end

return M
