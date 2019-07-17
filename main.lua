debugMode = false
for i,v in pairs(arg) do
  if string.find(v,"debug") then
    debugMode = true
    break
  end
end
if debugMode == true then
  require("lib.lovedebug")
  require("data.loopthrough")
end

--pClock = require("profileclock")

Steam = nil
if pcall(function() Steam = require 'luasteam' end) and Steam then
  Steam.init()
  --do nothing, it's already loaded
else
  Steam = nil
  print('Steam not loaded')
end

function love.load(arg)
  love.keyboard.setKeyRepeat(true)
  local pTime = os.clock()
  load_libraries()
  load_engine()
  load_data()
  register_classes()
  images = {}
  sounds = {}
  music = {}
  Gamestate.switch(loading)
  --highscores = load_scores()
  totalstats = load_stats()
 	load_prefs()
  quads = gen_quads()
  fonts = {
    graveFontBig = love.graphics.newFont("VeniceClassic.ttf",36),
    graveFontSmall = love.graphics.newFont("VeniceClassic.ttf",24),
    buttonFont = love.graphics.newFont("VeniceClassic.ttf",18),
    mapFont = love.graphics.newFont("VeraMono.ttf",prefs['asciiSize']),
    mapFontWithImages = love.graphics.newFont("VeraMono.ttf",24),
    textFont = love.graphics.newFont(14),
    descFont = love.graphics.newFont(prefs['descFontSize']),
    menuFont = love.graphics.newFont(24)
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
  --load_all_mods()
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
	Gamestate.draw()
  if output.popup then output.popup:draw() end
  if debugMode then love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 10, 10) end
end

function love.update(dt)
  Gamestate.update(dt)
  Timer.update(dt)
  if output.popup then output.popup:update(dt) end
end

function love.keypressed(key, unicode)
  Gamestate.keypressed(key,unicode)
end

function love.textinput(text)
  Gamestate.textinput(text)
end

function love.mousepressed(x,y,button)
  Gamestate.mousepressed(x,y,button)
end

function love.mousemoved(x,y,dx,dy,touch)
  Gamestate.mousemoved(x,y,dx,dy,touch)
end

function love.mousereleased(x,y,button)
  Gamestate.mousereleased(x,y,button)
end

function love.wheelmoved(x,y)
  Gamestate.wheelmoved(x,y)
end

function love.quit()
  --if (player ~= nil) then save_game() end
  --save_scores()
  save_prefs()
  save_stats()
  if Steam then Steam.shutdown() end
end

function love.resize()
  print('window resized by user')
  if Gamestate.current() == settings then
    settings:make_controls()
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
  menu:preDrawDirt()
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

function test_maps(depth)
  for i=1,50,1 do
    local pTime = os.clock()
    local build = mapgen:generate_map(100,100,depth)
      --layout(build,50,50,(depth or 1))
      print("Try " .. i ..": Success (Time: " .. tostring(os.clock() - pTime) .. ")")
      --build:refresh_pathfinder()
      --mapgen:addGenericStairs(build,50,50,depth)
  end
end

function load_data()
  require "data.achievements"
  require "data.ai"
  require "data.conditions"
  require "data.effects"
  require "data.features"
  require "data.gamedefinition"
  require "data.levelmodifiers"
  require "data.levels"
  require "data.monsters"
  require "data.projectiles"
  require "data.ranged_attacks"
  require "data.rooms"
  require "data.room_decorators"
  require "data.spells"
  require "data.tilesets"
  require "gamestates.characterscreen"
  require "gamestates.cheats"
  require "gamestates.credits"
  require "gamestates.game"
  require "gamestates.help"
  require "gamestates.gamestats"
  require "gamestates.loading"
  require "gamestates.loadsaves"
  require "gamestates.messages"
  require "gamestates.modloader"
  require "gamestates.monsterpedia"
  require "gamestates.menu"
  require "gamestates.newgame"
  require "gamestates.pausemenu"
  require "gamestates.settings"
  require "gamestates.spells"
end

function load_engine()
  require "achievement"
  require "map"
  require "mod"
  require "creature"
  require "output"
  require "util"
  require "magic"
  require "projectile"
  require "ranged_attack"
  require "effect"
  require "feature"
  require "saveload"
  require "namegen"
  require "condition"
  require "gamelogic"
end

function load_libraries()
  Class = require "lib.hump.class"
  Gamestate = require "lib.hump.gamestate"
  Timer = require "lib.hump.timer"
  Lady = require "lib.lady"
  bresenham = require 'lib.bresenham'
  ripple = require "lib.ripple"
end
