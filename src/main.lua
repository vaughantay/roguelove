--Custom error handler that logs errors
function love.errorhandler(msg)
	local m = debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")
  local date = os.date("%Y-%m-%d %H-%M-%S")
  
  if currGame and player then save_game(nil,currGame.fileName .. '-error-' .. date) end
  
  local printed = table.concat(printLog, "\n")
  love.filesystem.write('error ' .. date .. ".txt",printed .. "\n\n" .. m)
  return love.errhand(msg)
end
io.stdout:setvbuf("no")

--Custom print that saves everything printed, for logging later
originalPrint = print
printLog = {}
function print(...)
  originalPrint(...)
  local str = {}
	for i = 1, select('#', ...) do
		str[i] = tostring(select(i, ...))
	end
	table.insert(printLog, table.concat(str, "       "))
end

debugMode = false
for i,v in pairs(arg) do
  if string.find(v,"debug") then
    debugMode = true
    break
  end
end
if debugMode == true then
  require("lib.lovedebug")
  profiler = require("lib.profile")
  io.stdout:setvbuf("no")
end

--pClock = require("profileclock")

--[[Steam = nil
if pcall(function() Steam = require 'luasteam' end) and Steam and Steam.init() then
  --do nothing, it's already loaded
else
  Steam = nil
  print('Steam not loaded')
end]]

function love.load(arg)
  love.graphics.setDefaultFilter('nearest','nearest')
  love.keyboard.setKeyRepeat(true)
  local pTime = os.clock()
  load_libraries()
  load_engine()
  load_data()
  register_classes()
  images = {}
  sounds = {}
  music = {}
  pathfinders = {}
  grids = {}
  path_cache = {}
  timers = {}
  Gamestate.switch(loading)
  totalstats = load_stats()
 	load_prefs()
  quads = gen_quads()
  fonts = {
    titleFont = love.graphics.newFont("assets/fonts/VeniceClassic.ttf",36),
    headerFont = love.graphics.newFont("assets/fonts/VeniceClassic.ttf",24),
    buttonFont = love.graphics.newFont("assets/fonts/VeniceClassic.ttf",18),
    miniMapFont = love.graphics.newFont("assets/fonts/VeraMono.ttf",8),
    mapFont = love.graphics.newFont("assets/fonts/VeraMono.ttf",prefs['asciiSize']),
    --mapFontDys = love.graphics.newFont("OpenDyslexic-Regular.otf",prefs['asciiSize']),
    mapFontWithImages = love.graphics.newFont("assets/fonts/VeraMono.ttf",output:get_tile_size()),
    textFont = love.graphics.newFont(prefs['fontSize']),
    --fancyTextFont = love.graphics.newFont("assets/fonts/NotJamSignature.ttf",prefs['fontSize']),
    descFont = love.graphics.newFont(prefs['descFontSize']),
    menuFont = love.graphics.newFont("assets/fonts/VeniceClassic.ttf",36),
    --dysFont = love.graphics.newFont("OpenDyslexic-Regular.otf",14)
  }
  --[[if prefs['noImages'] ~= true then
    --output:load_all_images()
    output:load_ui()
  end]]
  soundTags = {}
  soundTags.sfx = ripple.newTag()
  soundTags.music = ripple.newTag()
  soundTags.sfx.volume = prefs['soundVolume']/100
  soundTags.music.volume = prefs['musicVolume']/100
  output.mouseX = love.mouse.getX()
	output.mouseY = love.mouse.getY()
	action = "moving"
  love.graphics.setDefaultFilter('nearest','nearest')
  random = love.math.random
  tween = output.tween
  setColor = function(r,g,b,a)
    r,g,b = r/255,g/255,b/255
    if a then a = a/255 end
    love.graphics.setColor(r,g,b,a)
  end
  if not Steam then 
    Steam = nil
  else
    print("Steam API loaded.")
  end
  print("Time to load game: " .. tostring(os.clock()-pTime))
end

function love.draw()
  local status,r = pcall(Gamestate.draw)
  love.graphics.setStencilTest()
  if status == false then
    if currGame then
      Gamestate.switch(game)
      output:out("Error in gamestate draw code: " .. r)
    else
      Gamestate.switch(menu)
    end
    print("Error in gamestate draw code: " .. r)
  end
  --Gamestate.draw()
  if output.notifications and output.notifications[1] then output.notifications[1]:draw() end
  if output.popups and output.popups[1] then output.popups[1]:draw() end
  if debugMode then love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 10, 10) end
  if debugMode then love.graphics.print("Gamepad: "..tostring(input:is_gamepad()), 10, 25) end
  if Gamestate.current() ~= game then
    love.mouse.setVisible(true)
  end
end

function love.update(dt)
  local status,r = pcall(Gamestate.update,dt)
  if status == false then
    if currGame then
      Gamestate.switch(game)
      output:out("Error in gamestate update code: " .. r)
    else
      Gamestate.switch(menu)
    end
    print("Error in gamestate update code: " .. r)
  end
  --Gamestate.update(dt)
  Timer.update(dt)
  if output.notifications and output.notifications[1] then
    output.notifications[1]:update(dt)
    if output.notifications[1].done then
      table.remove(output.notifications,1)
    end
  end
end

function love.keypressed(key, scancode, isRepeat)
  if output.popups and output.popups[1] then
    key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat)
    if not output.popups[1].enterOnly or key == "enter" or key == "escape" then
      if output.popups[1].afterFunc then output.popups[1].afterFunc() end
      table.remove(output.popups,1)
    end
    return
  end
  local status,r = pcall(Gamestate.buttonpressed,key, scancode, isRepeat, 'keyboard')
  if status == false then
    if currGame then
      output:out("Error in gamestate buttonpressed code: " .. r)
    end
    print("Error in gamestate buttonpressed code: " .. r)
  end
  --Gamestate.buttonpressed(key, scancode, isrepeat, 'keyboard')
end

function love.textinput(text)
  local status,r = pcall(Gamestate.textinput,text)
  if status == false then
    if currGame then
      output:out("Error in gamestate textinput code: " .. r)
    end
    print("Error in gamestate textinput code: " .. r)
  end
  --Gamestate.textinput(text)
end

if love._os == "NX" then
  local tx, ty = 1, 1

  function love.touchpressed(id, x, y)
    tx, ty = x, y
    --Gamestate.mousepressed(x, y, 1)
  end

  function love.touchmoved(id, x, y, dx, dy)
    Gamestate.mousemoved(x, y, dx, dy, true)
  end

  function love.touchreleased(id, x, y)
    Gamestate.mousereleased(x, y, 1, true)
  end
  
  function love.mouse.getPosition()
    return tx, ty
  end

  function love.mouse.getX()
    return tx
  end

  function love.mouse.getY()
    return ty
  end  
else
  function love.mousepressed(x,y,button)
    if output.popups and output.popups[1] then
      if output.popups[1].afterFunc then output.popups[1].afterFunc() end
      table.remove(output.popups,1)
      return
    end
    local status,r = pcall(Gamestate.mousepressed,x,y,button)
    if status == false then
      if currGame then
        output:out("Error in gamestate mousepressed code: " .. r)
      end
      print("Error in gamestate mousepressed code: " .. r)
    end
    --Gamestate.mousepressed(x,y,button)
  end
  
  function love.mousemoved(x,y,dx,dy,touch)
    local status,r = pcall(Gamestate.mousemoved,x,y,dx,dy,touch)
    if status == false then
      if currGame then
        output:out("Error in gamestate mousemoved code: " .. r)
      end
      print("Error in gamestate mousemoved code: " .. r)
    end
    --Gamestate.mousemoved(x,y,dx,dy,touch)
  end
  
  function love.mousereleased(x,y,button)
    local status,r = pcall(Gamestate.mousereleased,x,y,button)
    if status == false then
      if currGame then
        output:out("Error in gamestate mousereleased code: " .. r)
      end
      print("Error in gamestate mousereleased code: " .. r)
    end
    --Gamestate.mousereleased(x,y,button)
  end
  
  function love.wheelmoved(x,y)
    local status,r = pcall(Gamestate.wheelmoved,x,y)
    if status == false then
      if currGame then
        output:out("Error in gamestate wheelmoved code: " .. r)
      end
      print("Error in gamestate wheelmoved code: " .. r)
    end
    --Gamestate.wheelmoved(x,y)
  end  
end

function love.gamepadaxis(joystick,axis,value)
 -- TODO
end

function love.gamepadpressed(joystick,button)
  if output.popup and output.popups[1] then
    if output.popups[1].afterFunc then output.popups[1].afterFunc() end
    table.remove(output.popups,1)
    return
  end
  Gamestate.buttonpressed(button,nil,nil,'gamepad')
end

function love.joystickadded()
  input.gamepad = true
end

function love.joystickremoved()
  input.gamepad = nil
end

function love.quit()
  if (player ~= nil and currGame ~= nil) then save_game() end
  --save_scores()
  save_prefs()
  save_stats()
  if Steam then Steam.shutdown() end
  if profiler then print(profiler.report(25)) end
end

function love.resize()
  if Gamestate.current() == settings then
    settings:make_controls()
  elseif Gamestate.current() == loadsaves then
    loadsaves:create_coordinates()
  end
  local fs,fstype = love.window.getFullscreen()
  if fs then
    prefs['oldwidth'],prefs['oldheight'] = prefs['width'],prefs['height']
  else
    prefs['oldwidth'],prefs['oldheight'] = nil
  end
  prefs['fullscreen'] = fs
  prefs['width'] = love.graphics.getWidth()
  prefs['height'] = love.graphics.getHeight()
  prefs['fstype'] = fstype
  prefs['maximizedWindow'] = love.window.isMaximized()
  output.mapWidth,output.mapHeight=nil,nil
  game.canvas=love.graphics.newCanvas(prefs['width'],prefs['height'])
end

function gen_quads()
  local qs = {
    nw = love.graphics.newQuad(0, 0, 32, 32, 128, 128),
    n = love.graphics.newQuad(32, 0, 32, 32, 128, 128),
    ne = love.graphics.newQuad(64, 0, 32, 32, 128, 128),
    new = love.graphics.newQuad(96, 0, 32, 32, 128, 128),
    w = love.graphics.newQuad(0, 32, 32, 32, 128, 128),
    middle = love.graphics.newQuad(32, 32, 32, 32, 128, 128),
    e = love.graphics.newQuad(64, 32, 32, 32, 128, 128),
    ew = love.graphics.newQuad(96, 32, 32, 32, 128, 128),
    sw = love.graphics.newQuad(0, 64, 32, 32, 128, 128),
    s = love.graphics.newQuad(32, 64, 32, 32, 128, 128),
    se = love.graphics.newQuad(64, 64, 32, 32, 128, 128),
    sew = love.graphics.newQuad(96, 64, 32, 32, 128, 128),
    nsw = love.graphics.newQuad(0, 96, 32, 32, 128, 128),
    ns = love.graphics.newQuad(32, 96, 32, 32, 128, 128),
    nse = love.graphics.newQuad(64, 96, 32, 32, 128, 128),
    nsew = love.graphics.newQuad(96, 96, 32, 32, 128, 128),
    sprites = {}
  }
  return qs
end

function test_maps(branch,depth)
  for i=1,50,1 do
    local pTime = os.clock()
    local build = mapgen:generate_map(branch,depth)
      --layout(build,50,50,(depth or 1))
      print("Try " .. i ..": Success (Time: " .. tostring(os.clock() - pTime) .. ")")
      --build:refresh_pathfinder()
      --mapgen:addGenericStairs(build,50,50,depth)
  end
end

function test_spells()
  player.max_hp=1000
  player.hp = 1000
  player.max_mp = 1000
  player.mp = 1000
  for _,spell in pairs(possibleSpells) do
    if spell.target_type ~= "passive" then
      print(spell.name)
      for key,func in pairs(spell) do
        if type(spell[key]) == "function" then
          local ok, err = pcall(func,spell,player,player)
          if not ok then print(err) end
        end
      end
      player.max_hp=1000
      player.hp = 1000
      player.max_mp = 1000
      player.mp = 1000
    end
  end
end

function load_data()
  for _,file in ipairs(love.filesystem.getDirectoryItems('data')) do
    local info = love.filesystem.getInfo('data/' .. file)
    if string.sub(file,-4) == ".lua" then
      local fileName = string.sub(file,1,-5)
      require("data." .. fileName)
    elseif info.type == "directory" then
      require("data." .. file)
    end
  end
  for _,file in ipairs(love.filesystem.getDirectoryItems('gamestates')) do
    local info = love.filesystem.getInfo('gamestates/' .. file)
    if string.sub(file,-4) == ".lua" then
      local fileName = string.sub(file,1,-5)
      require("gamestates." .. fileName)
    elseif info.type == "directory" then
      require("gamestates." .. file)
    end
  end
end

function load_engine()
  for _,file in ipairs(love.filesystem.getDirectoryItems('classes')) do
    local info = love.filesystem.getInfo('classes/' .. file)
    if string.sub(file,-4) == ".lua" then
      local fileName = string.sub(file,1,-5)
      require("classes." .. fileName)
    elseif info.type == "directory" then
      require("classes." .. file)
    end
  end
  for _,file in ipairs(love.filesystem.getDirectoryItems('ui')) do
    local info = love.filesystem.getInfo('ui/' .. file)
    if string.sub(file,-4) == ".lua" then
      local fileName = string.sub(file,1,-5)
      require("ui." .. fileName)
    elseif info.type == "directory" then
      require("ui." .. file)
    end
  end
  require "util"
  require "achievement"
  require "input"
  require "mapgen"
  require "mod"
  require "namegen"
  require "output"
  require "saveload"
  require "util"
  require "gamelogic"
end

function load_libraries()
  Class = require "lib.hump.class"
  Gamestate = require "lib.hump.gamestate"
  Timer = require "lib.hump.timer"
  bitser = require "lib.bitser.bitser"
  bresenham = require 'lib.bresenham'
  ripple = require "lib.ripple"
end