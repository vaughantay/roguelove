Popup = Class{}

function Popup:init(text,header,extraLines,blackout,enterOnly,afterFunc)
  local uiScale = prefs['uiScale']
  local fontSize = fonts.textFont:getHeight()
  local tileSize = output:get_tile_size(true)
  self.text,self.header=text,(header or "")
  self.blackout,self.enterOnly = blackout,enterOnly
  self.exitText = (self.enterOnly and "Press enter, escape, or click to continue..." or "Press any key or click to continue...")
  self.width = math.min(550,round(love.graphics.getWidth()/uiScale/2))
  self.padding = (prefs['noImages'] and 8 or 32)
  self.afterFunc = afterFunc
  extraLines = extraLines or 4
  
  local _,hlines = fonts.textFont:getWrap(self.header,self.width-self.padding)
  local _,tlines = fonts.textFont:getWrap(text,self.width-self.padding)
  local _,elines = fonts.textFont:getWrap(self.exitText,self.width-self.padding)
  self.headerHeight = (self.header ~= "" and #hlines*fontSize or 0)
  self.height = (#tlines+extraLines)*fontSize+self.headerHeight
  self.x,self.y=round(love.graphics.getWidth()/uiScale/2-self.width/2-tileSize/2),round(love.graphics.getHeight()/uiScale/2-self.height/uiScale/2-tileSize/2)
  self.exitHeight = self.y+self.height-(#elines*fontSize)
end

function Popup:draw()
  local uiScale = (prefs['uiScale'] or 1)
  local width, height = math.ceil(love.graphics:getWidth()/uiScale),math.ceil(love.graphics:getHeight()/uiScale)
  if self.blackout then
    setColor(0,0,0,75)
    love.graphics.rectangle('fill',0,0,width,height)
  end
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  output:draw_window(self.x,self.y,self.x+self.width,self.y+self.height)
  love.graphics.setFont(fonts.textFont)
  if self.header and self.header ~= "" then
    love.graphics.printf(self.header,self.x+self.padding,self.y+self.padding,self.width-self.padding,"center")
  end
  love.graphics.printf(self.text,self.x+self.padding+5,self.y+self.padding+self.headerHeight+5,self.width-self.padding,"left")
  love.graphics.printf(self.exitText,self.x,self.exitHeight,self.width-self.padding,"center")
  love.graphics.pop()
  setColor(255,255,255,255)
end