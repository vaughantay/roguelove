warning = {}

function warning:draw()
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
	love.graphics.printf([[Thanks for trying out the preview of Possession 2! Please keep in mind that the game is still in development and the full version of the game will feature many more levels, creatures and powers, as well as music. This version also doesn't feature saving or high scores.
    
    Please send any bug reports, comments or questions to contact@weirdfellows.com, or post on the forums at weirdfellows.com!
    
    Keep up with updates on Possession 2 at possession2.com. Again, thanks for trying the game out, and remember to vote for us on Steam Greenlight!
	
	
	
	
	Press Any Key to Continue]],14,14,width-25,"center")
end

function warning:keypressed(key)
  Gamestate.switch(menu)
end

function warning:mousepressed()
  Gamestate.switch(menu)
end