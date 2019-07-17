local loader = require 'lib.love-loader'
loading = {}

function loading:enter()
  self.loading = false
  self.started = false
  self.loadingDone = false
end

function loading:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
	love.graphics.printf("Loading...",0,height/2,width,"center")
  --love.graphics.printf(loader.loadedCount .. "/" .. loader.resourceCount,0,height/2+15, width,"center")
end

function loading:update(dt)
  if self.loading == false then
    self.loading = true
    
  elseif self.loadingDone ~= true and self.started ~= true then
    self.started = true
    output:load_all_images()
    output:load_ui()
    self.loadingDone = true
  end
  if self.loadingDone == true then
    Gamestate.switch(modloader)
  end
end

function loading:load_all_images()
  local folders = love.filesystem.getDirectoryItems('images')
  for _,folderName in pairs(folders) do
    if love.filesystem.isDirectory('images/' .. folderName) then
      local files = love.filesystem.getDirectoryItems('images/' .. folderName)
      for _,fileName in pairs(files) do
        local extension = string.sub(fileName, -4)
        if extension == ".png" then
          fileName = string.sub(fileName,1,-5)
          loader.newImage(images, folderName .. fileName,"images/" .. folderName .. "/" .. fileName .. ".png")
        end --end extension check
      end --end fileName for
    end --end is folder if
  end --end folderName for
  for _,tileset in pairs(love.filesystem.getDirectoryItems('images/levels')) do
    local files = love.filesystem.getDirectoryItems('images/levels/' .. tileset)
    for _,fileName in pairs(files) do
      local extension = string.sub(fileName, -4)
      if extension == ".png" then
        fileName = string.sub(fileName,1,-5)
        loader.newImage(images, tileset .. fileName, "images/levels/" .. tileset .. "/" .. fileName .. ".png")
      end --end extension check
    end --end fileName for
  end
  --[[loader.start(function()
    self.loadingDone = true
  end)]]
end