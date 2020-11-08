---@module input
input = {}

---Parse keyboard input, and return the proper command
--@param key String. Character of the pressed key
--@param scancode String. The scancode representing the pressed key
--@param isrepeat Boolean. Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings
function input:parse_key(key,scancode,isrepeat)
  if key == "return" or key == "kpenter" then
    return "return"
  elseif ((prefs['arrowKeys'] and key == "up") or key == keybindings.north) then
    return "north",scancode,isrepeat
  elseif ((prefs['arrowKeys'] and key == "down") or key == keybindings.south) then
    return "south",scancode,isrepeat
  elseif ((prefs['arrowKeys'] and key == "right") or key == keybindings.east) then
    return "east",scancode,isrepeat
  elseif ((prefs['arrowKeys'] and key == "left") or key == keybindings.west) then
    return "west",scancode,isrepeat
  elseif key == keybindings.northwest then
    return "northwest",scancode,isrepeat
  elseif key == keybindings.northeast then
    return "northeast",scancode,isrepeat
  elseif key == keybindings.southwest then
    return "southwest",scancode,isrepeat
  elseif key == keybindings.southeast then
    return "southeast",scancode,isrepeat
  elseif ((prefs['arrowKeys'] and key == "space") or key == keybindings.wait) then
    return "wait",scancode,isrepeat
  elseif (key == keybindings.spell) then
		return "spell",scancode,isrepeat
  elseif (key == keybindings.inventory) then
		return "inventory",scancode,isrepeat
  elseif (key == keybindings.throw) then
		return "throw",scancode,isrepeat
  elseif (key == keybindings.use) then
		return "use",scancode,isrepeat
  elseif (key == keybindings.equip) then
		return "equip",scancode,isrepeat
  elseif (key == keybindings.crafting) then
		return "crafting",scancode,isrepeat
	elseif (key == keybindings.examine) then
		return "examine",scancode,isrepeat
  elseif (key == keybindings.nextTarget) then
    return "nextTarget",scancode,isrepeat
  elseif (key == keybindings.action) then
    return "action",scancode,isrepeat
  else
    return key,scancode,isrepeat
  end
end

function input:parse_gamepadbutton(joystick,button)
  if button == "a" then
    return "select"
  end
end


function input:parse_gamepadaxis(joystick,axis,value)
  
end