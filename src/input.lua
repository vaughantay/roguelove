---@module input
input = {}

function input:is_gamepad()
  local joysticks = love.joystick.getJoysticks()
  return next(joysticks) ~= nil
end

---Parse keyboard input, and return the proper command
--@param key String. Character of the pressed key
--@param scancode String. The scancode representing the pressed key
--@param isrepeat Boolean. Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings
function input:parse_key(key,scancode,isrepeat)
  for command, commandData in pairs(keybindings) do
    if not commandData.gamepad or not commandData.keyboard then goto skip end

    if commandData.gamepad and commandData.gamepad[1] == key then 
      return command, scancode, isrepeat
    end
    if commandData.keyboard and commandData.keyboard[1] == key or commandData.keyboard[2] == key then 
      return command, scancode, isrepeat
    end

    ::skip::
  end
  return key,scancode,isrepeat
end

function input:get_button_name(command)
  if keybindings[command] then
    if input:is_gamepad() and keybindings[command].gamepad then
      return keybindings[command].gamepad[1]
    end
    return keybindings[command].keyboard[1]
  end
end