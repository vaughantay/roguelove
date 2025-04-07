credits = {}

function credits:enter(previous)
  self.slide = 1
  self.timer=0
  output:play_playlist("credits")
end

function credits:draw()
  setColor(255,255,255,255)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  setColor(255,255,255,255)
  
  love.graphics.setFont(fonts.menuFont)
  setColor(255,255,255,255)
  love.graphics.printf(gamesettings.name,14,100,width-28,"center")
  if self.slide == 1 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Programming, Graphics, Music",math.floor(width/3),240,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf("Taylor Vaughan",math.floor(width/3),270,math.floor(width/3),"center")
  elseif self.slide == 2 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Beta Testing",math.floor(width/3),240,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf([[]],math.floor(width/3),270,math.floor(width/3),"center")
  elseif self.slide == 3 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Uses Sounds Created By",math.floor(width/3),200,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf([[]],math.floor(width/3),230,math.floor(width/3),"center")
  elseif self.slide == 4 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Uses Sounds Created By",math.floor(width/3),140,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf([[]],math.floor(width/3)-5,170,math.floor(width/3)+10,"center")
  elseif self.slide == 5 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("Some Music Samples From",math.floor(width/3),140,math.floor(width/3),"center")
        love.graphics.printf("Fonts",math.floor(width/3),340,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf([[]],math.floor(width/3)-5,170,math.floor(width/3)+10,"center")
    love.graphics.printf([[Venice Classic, freeware by soixantedeux.
]],math.floor(width/3)-5,370,math.floor(width/3)+10,"center")
  elseif self.slide == 6 then
    love.graphics.setFont(fonts.headerFont)
    love.graphics.printf("External Libraries",math.floor(width/3),140,math.floor(width/3),"center")
    love.graphics.setFont(fonts.textFont)
    love.graphics.printf([[LÖVE game development framework, ZLIB License.
    
An implementaion of the Bresenham Line Algorithm
by Enrique García Cota, Yuichi Tateno, Emmanuel Oga, MIT license.

Jumper by Roland Yonaba, MIT License.

Bitser by Jasmijn Wellner, MIT License.

Luasteam, USPGameDev, MIT License.

Helper Utilities for Massive Progression by Matthias Richter, MIT License.

Ripple by Andrew Minnich, MIT license.
]],math.floor(width/3),170,math.floor(width/3),"center")
  end
  setColor(255,255,255,255)
end

function credits:buttonpressed(key,scancode,isRepeat,controllerType)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if key == "escape" then
    Gamestate.switch(menu)
  end
end

function credits:update(dt)
  self.timer = self.timer+dt
  if self.timer >= 3 then
    if self.slide == 6 then
      Gamestate.switch(menu)
    else
      self.slide = self.slide+1
      self.timer=0
    end
  end
end