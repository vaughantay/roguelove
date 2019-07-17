credits = {}

function credits:enter(previous)
  self.slide = 1
  self.timer=0
  output:play_playlist("credits")
  if previous == menu then
    self.rain = menu.rain
  else
    self.rain = {}
  end
end

function credits:draw()
  setColor(255,255,255,255)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  setColor(255,255,255,255)
  if prefs['noImages'] == true then
    love.graphics.setFont(fonts.mapFont)
    -- Calculate the dirt and sky:
    love.graphics.setFont(fonts.mapFont)
    --Draw the dirt and sky:
    if not self.dirtSkyCanvas then
      self:preDrawDirt()
    end
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(self.dirtSkyCanvas)
    love.graphics.setBlendMode("alpha")
    
    -- Draw the tombstone:
    setColor(0,0,0,255)
    love.graphics.rectangle('fill',math.ceil(width/2-256),56,520,490)
    setColor(255,255,255,255)
    for y = 50,540,14 do
      if (y == 50) then
        for x = width/2-256,(width/2)+256,13 do
          love.graphics.print("#",x,y)
        end
      else
        love.graphics.print("#",width/2-256,y)
        love.graphics.print("#",width/2+256,y)
      end
    end
    --Draw the grass:
    local grass = ""
    for i=1,width,7 do
      if (i % 5 == 0) then grass = grass .. "\\"
      elseif (i % 7 == 0 or i == 3) then grass = grass .. "/"
      elseif (i % 11 == 0 or i == 2) then grass = grass .. "|"
      else grass = grass .. " " end
    end
    setColor(0,255,0)
    love.graphics.print(grass,1,538)
  else --graphical menu:
    setColor(255,255,255,255)
    for x = 0, width, 512 do
      love.graphics.draw(images['uimenuskydark'],x,0)
    end
    love.graphics.draw(images['uimenuskydark'],width-512,0)
          
    love.graphics.draw(images['uigravestonenew'],width/2-256,50)
    for x = 0, width/64, 1 do
      for y=572,height,32 do
        setColor(255,255,255,255-(255*((y-572)/(height-572))))
        love.graphics.draw(images['uimenudirt'],x*64,y)
      end
      setColor(255,255,255,255)
      love.graphics.draw(images['uimenudirtgrass'],x*64,550)
      if (x % 3 == 0 or x % 13 == 0) then love.graphics.draw(images['uimenugrass1'],x*64,490)
      elseif (x % 7 == 0 or x % 9 == 0) then love.graphics.draw(images['uimenugrass2'],x*64,490)
      elseif (x % 5 == 0 or x % 11 == 0) then love.graphics.draw(images['uimenugrass3'],x*64,490) end
    end
  end --end if images
  
  love.graphics.setFont(fonts.graveFontBig)
  love.graphics.printf("Possession",14,100,width-28,"center")
  if self.slide == 1 then
    love.graphics.setFont(fonts.graveFontSmall)
    love.graphics.printf("Programming, Graphics, Music",math.floor(width/3),240,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf("Taylor Vaughan",math.floor(width/3),270,math.floor(width/3),"center")
  elseif self.slide == 2 then
    love.graphics.setFont(fonts.graveFontSmall)
    love.graphics.printf("Beta Testing",math.floor(width/3),240,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf([[Adam Hodges
Erlend F
Chris Neal
Tim Froburg
Tim Sandford
Joe Scamardella]],math.floor(width/3),270,math.floor(width/3),"center")
  elseif self.slide == 3 then
    love.graphics.setFont(fonts.graveFontSmall)
    love.graphics.printf("Uses Sounds Created By",math.floor(width/3),200,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf([[
Kenney Vleugels
http://www.kenney.nl
    
Iwan Gabovitch "qubodup"
http://qubodup.net
    
InspectorJ
http://www.jshaw.co.uk
    
ZapSplat
https://www.zapsplat.com/
    
FreeSFX
http://www.freesfx.co.uk]],math.floor(width/3),230,math.floor(width/3),"center")
  elseif self.slide == 4 then
    love.graphics.setFont(fonts.graveFontSmall)
    love.graphics.printf("Uses Sounds Created By",math.floor(width/3),140,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf([[
Tuomo Untinen "Reemax"
http://opengameart.org/users/reemax
    
Jesús Lastra "Jalastram" 
http://opengameart.org/users/jalastram
    
spookeymodem
http://opengameart.org/users/spookymodem
    
JaggedStone
http://opengameart.org/users/jaggedstone
    
Vataaa
http://freesound.org/people/vataaa/
    
3bagbrew
http://freesound.org/people/3bagbrew/
    
unfa
http://freesound.org/people/unfa/
    ]],math.floor(width/3)-5,170,math.floor(width/3)+10,"center")
  elseif self.slide == 5 then
    love.graphics.setFont(fonts.graveFontSmall)
    love.graphics.printf("Some Music Samples From",math.floor(width/3),140,math.floor(width/3),"center")
        love.graphics.printf("Fonts",math.floor(width/3),340,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf([[
Farmer's Samplepacks
Copyright 1997 Louis Gorenfeld
    ]],math.floor(width/3)-5,170,math.floor(width/3)+10,"center")
    love.graphics.printf([[Venice Classic, freeware by soixantedeux.
]],math.floor(width/3)-5,370,math.floor(width/3)+10,"center")
  elseif self.slide == 6 then
    love.graphics.setFont(fonts.graveFontSmall)
    love.graphics.printf("External Libraries",math.floor(width/3),140,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf([[LÖVE game development framework, ZLIB License.
    
An implementaion of the Bresenham Line Algorithm
by Enrique García Cota, Yuichi Tateno, Emmanuel Oga, MIT license.

Jumper by Roland Yonaba, MIT License.

Lady by Robin Wellner, MIT License.

Luasteam, USPGameDev, MIT License.

Helper Utilities for Massive Progression by Matthias Richter, MIT License.

Ripple by Andrew Minnich, MIT license.
]],math.floor(width/3),170,math.floor(width/3),"center")
  end
  self:drawrain()
  setColor(255,255,255,255)
end

function credits:drawrain()
  setColor(200,200,255,150)
  for _,r in pairs(self.rain) do
    love.graphics.print("|",r.x,r.y)
  end
end

function credits:updaterain(dt)
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()
  if random(1,5) == 1 then
    local r = {x=random(1,width),y=0}
    self.rain[r] = r
  end
  for _,r in pairs(self.rain) do
    r.y = r.y+height*dt
    if r.y > 550 then
      self.rain[r] = nil
    end
  end
end

function credits:keypressed(key)
  if key == "escape" then
    Gamestate.switch(menu)
  end
end

function credits:update(dt)
  self.timer = self.timer+dt
  if self.timer >= 3 then
    if self.slide == 6 then
      menu.rain = self.rain
      Gamestate.switch(menu)
    else
      self.slide = self.slide+1
      self.timer=0
    end
  end
  self:updaterain(dt)
end