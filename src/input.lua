---@module input
input = {}

---Parse keyboard input, and return the proper command
--@param key String. Character of the pressed key
--@param scancode String. The scancode representing the pressed key
--@param isrepeat Boolean. Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings
function input:parse_key(key,scancode,isrepeat)
  for command,commandkey in pairs(keybindings) do
    if commandkey == key then
      return command,scancode,isrepeat
    elseif commandkey[1] == key or commandkey[2] == key then
      return command,scancode,isrepeat
    end
  end
  return key,scancode,isrepeat
end

function input:parse_gamepadbutton(joystick,button)
  if button == "a" then
    return "select"
  end
end


function input:parse_gamepadaxis(joystick,axis,value)
  
end