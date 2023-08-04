---@module input
input = {}

---Parse keyboard input, and return the proper command
--@param key String. Character of the pressed key
--@param scancode String. The scancode representing the pressed key
--@param isrepeat Boolean. Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings
function input:parse_key(key,scancode,isrepeat)
  for command, commandData in pairs(keybindings) do
    if not commandData.keyboard then goto skip end
    if commandData.keyboard[1] == key or commandData.keyboard[2] == key then 
      return command, scancode, isrepeat
    end
    if not commandData.gamepad then goto skip end
    if commandData.gamepad[1] == key then 
      return command, scancode, isrepeat
    end
    ::skip::
  end
  return key,scancode,isrepeat
end