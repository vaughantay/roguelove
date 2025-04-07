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
--@param controllerType String. The type of controller. Optional, defeaults to keyboard
function input:parse_key(key,scancode,isrepeat,controllerType)
  if not controllerType then controllerType = "keyboard" end
  for command, commandData in pairs(keybindings) do
    if not commandData[controllerType] then goto skip end

    if commandData[controllerType][1] == key or commandData[controllerType][2] == key then 
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
function input:get_button_name(command,controllerType)
  if not controllerType then controllerType = "keyboard" end
  if keybindings[command] then
    return keybindings[command][controllerType][1]
  end
end