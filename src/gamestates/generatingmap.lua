generatingmap = {}

function generatingmap:enter()
  local thread = love.thread.newThread("thread.lua")
	local channel = love.thread.getChannel("test")
	thread:start()
end

function generatingmap:draw()
end
