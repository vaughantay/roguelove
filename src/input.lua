---@module input
input = {}

---Return if gamepad is connected
function input:is_gamepad()
  return input.gamepad or false
end

---Parse keyboard input, and return the proper command
--@param key String. Character of the pressed key
--@param scancode String. The scancode representing the pressed key
--@param isrepeat Boolean. Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings
function input:parse_key(key,scancode,isrepeat)
  for command, commandData in pairs(keybindings) do
    if not commandData.gamepad and not commandData.keyboard then goto skip end

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

---Return keys for specific command 
--@param command String. Command name
function input:get_keys(command)
  if keybindings[command] then
    local command = keybindings[command]
    --[[if input:is_gamepad() and command.gamepad then
      return command.gamepad[1], command.gamepad[2]
    end]]
    if not command.keyboard then goto empty end
    return command.keyboard[1], command.keyboard[2]
  end
  ::empty::
  return nil, nil
end

---Returns button name for command
--@param command String. Command name
function input:get_button_name(command)
  if keybindings[command] then
    if input:is_gamepad() and keybindings[command].gamepad then
      return keybindings[command].gamepad[1]
    end
    return keybindings[command].keyboard[1]
  end
end