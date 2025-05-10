conversation = {}

function conversation:enter(previous,speaker,asker,dialogID,args)
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  local tileSize = output:get_tile_size()
  width,height = round(width/uiScale), round(height/uiScale)
  self.speaker = speaker
  self.asker = asker
  self.history = {}
  self.current_text = nil
  self.text_table = nil
  self.text_index = 1
  self.max_text_index = 1
  self.responses = {}
  self.dialog = nil
  self.dialogID = nil
  
  self.maxTextY = 0
  self.scrollY = 0
  self.maxScrollY = 0
  self.textHeight = 0
  self.responseHeight = 0
  
  self.cursorY = 1
  self.yModPerc = 100
  tween(0.2,self,{yModPerc=0})
  output:sound('stoneslideshort',2)
  
  self.windowW,self.windowH = math.min(width-tileSize,550),math.min(height-tileSize,750)
  self.startX,self.startY = round(width/2-self.windowW/2)-round(tileSize/2),round(height/2-self.windowH/2)-round(tileSize/2)
  self.endX,self.endY = self.startX+self.windowW,self.startY+self.windowH
  
  currGame.dialog_seen = currGame.dialog_seen or {}
  if speaker then
    speaker.dialog_seen = speaker.dialog_seen or {}
  end
  
  if dialogID and speaker then
    self:load_dialog(dialogID,speaker,args)
  elseif speaker and speaker:get_dialog(asker) then
    self:load_dialog(speaker:get_dialog(asker),speaker,args)
  else --if we have no dialog to load, just go home
    self:switchBack()
  end
end

function conversation:draw()
  game:draw()
  if not self.speaker then
    return
  end
  local width, height = love.graphics:getWidth(),love.graphics:getHeight()
  local uiScale = (prefs['uiScale'] or 1)
  width = round(width/uiScale), round(height/uiScale)
  local fontSize = fonts.textFont:getHeight()
  local tileSize = output:get_tile_size()
  local padding = round(tileSize/2)
  local mouseX,mouseY = love.mouse.getPosition()
  mouseX,mouseY = round(mouseX/uiScale),round(mouseY/uiScale)
  
  love.graphics.push()
  love.graphics.scale(uiScale,uiScale)
  love.graphics.translate(0,height*(self.yModPerc/100))
  love.graphics.setFont(fonts.textFont)

  
  local startX,startY,windowW,windowH,endX,endY = self.startX,self.startY,self.windowW,self.windowH,self.endX,self.endY
  local textWidth = windowW-padding*2
  output:draw_window(startX,startY,endX,endY)
  love.graphics.push()
  
  local printX = startX+padding
  local printY = endY-padding
  
  --Print response options
  local responses = self.responses
  printY = endY-self.responseHeight
  for i,response in ipairs(self.responses) do
    response.minY = printY
    local text = response.text or "[NO RESPONSE TEXT FOUND]"
    local _,tlines = fonts.textFont:getWrap(text,textWidth)
    local thisHeight = #tlines*fontSize
    response.maxY = response.minY + thisHeight
    
    if self.cursorY == i then
      setColor(150,150,150,125)
      love.graphics.rectangle("fill",printX-2,response.minY-2,endX-printX,(response.maxY-response.minY)+4)
      setColor(255,255,255,255)
    elseif response.minY and response.maxY and mouseY > response.minY and mouseY <= response.maxY and mouseX > self.startX and mouseX < self.endX then
      setColor(100,100,100,125)
      love.graphics.rectangle("fill",printX-2,response.minY-2,endX-printX,(response.maxY-response.minY)+4)
      setColor(255,255,255,255)
    end
    
    if response.disabled then
      setColor(200,0,0,255)
    end
    love.graphics.printf(text,printX,printY,textWidth)
    setColor(255,255,255,255)
    printY = printY + thisHeight+4
  end
  love.graphics.line(startX+16,endY-self.responseHeight-4,endX+16,endY-self.responseHeight-4)
  printY = endY-self.responseHeight-8
  self.maxTextY = printY
  
  --If scrollbars, adjust the text width
  textWidth = textWidth-(self.maxScrollY > 0 and tileSize or 0)
  
  local function stencilFunc()
    love.graphics.rectangle("fill",printX,startY+18,windowW,self.maxTextY-startY-16)
  end
  love.graphics.stencil(stencilFunc,"replace",1)
  love.graphics.setStencilTest("greater",0)
  
  --Print text history:
  love.graphics.push()
  love.graphics.translate(0,(self.maxScrollY-self.scrollY))
  local lastSpeaker
  local histBorderY = printY
  printY = histBorderY-self.textHeight
  local textHeight = 0
  if #self.history > 0 then
    for i = 1,#self.history,1 do
      local entry = self.history[i]
      local text = entry.text
      if text then
        local speaker = entry.speaker
        if not speaker or speaker ~= lastSpeaker then
          printY = printY + fontSize
          textHeight = textHeight + fontSize
          if speaker then
            output.display_entity(speaker,printX,printY-8,true,true)
            love.graphics.printf(ucfirst(speaker:get_name()) .. ":",printX+tileSize,printY,textWidth)
            printY = printY + tileSize
            textHeight = textHeight + tileSize
          end
        end
        local _,tlines = fonts.textFont:getWrap((speaker and "\t" or "") .. text,textWidth)
        local currHeight = fontSize*#tlines+4
        love.graphics.printf((speaker and "\t" or "") .. text,printX,printY,textWidth)
        printY = printY+currHeight
        textHeight = textHeight+currHeight
        lastSpeaker = speaker
      end
    end
  end
  
  --Print Current Text
  if not self.current_text.speaker or self.current_text.speaker ~= lastSpeaker then
    printY = printY + fontSize
    textHeight = textHeight+fontSize
    if self.current_text.speaker then
      output.display_entity(self.current_text.speaker,printX,printY-8,true,true)
      love.graphics.printf(ucfirst(self.current_text.speaker:get_name()) .. ":",printX+tileSize,printY,textWidth)
      printY = printY + tileSize
      textHeight = textHeight+tileSize
    end
  end
  local text = (type(self.current_text.text) == "table" and self.current_text.text[self.text_index] or self.current_text.text) or ""
  local _,tlines = fonts.textFont:getWrap((self.current_text.speaker and "\t" or "") .. text,textWidth)
  local currSize = fontSize*#tlines+4
  love.graphics.printf((self.current_text.speaker and "\t" or "") .. text,printX,printY,textWidth)
  printY = printY+currSize
  textHeight = textHeight+currSize
  self.textHeight = textHeight
  
  love.graphics.pop()
  
  --Scrollbars:
  if textHeight+startY > self.maxTextY then
    local newMax = textHeight-(self.maxTextY)+fontSize*2
    if self.maxScrollY < newMax then
      self.scrollY = newMax
      self.maxScrollY = newMax
    end
    local scrollAmt = self.scrollY/self.maxScrollY
    if self.cursorY == 0 then
      setColor(150,150,150,125)
      love.graphics.rectangle('fill',endX-tileSize,startY+8,tileSize,self.maxTextY-4)
      setColor(255,255,255,255)
    end
    self.scrollPositions = output:scrollbar(endX-tileSize,startY+18,self.maxTextY,scrollAmt,true)
  end
  
  love.graphics.setStencilTest()
  love.graphics.pop()
  if not self.dialog or not self.dialog.noEscape then
    self.closebutton = output:closebutton(startX+16,startY+18,nil,true)
  end
  
  love.graphics.pop()
end

function conversation:load_dialog(dialogID,speaker,args)
  local dialog = possibleDialogs[dialogID]
  if not dialog then
    self:set_text("ERROR: No dialog with ID " .. dialogID .. " found.")
    return false
  end
	local text
  --Use the text function if it has one
  if dialog.display_text then
    local status,r = pcall(dialog.display_text,dialog,(speaker or self.speaker),self.asker,self.dialogID,args)
    if status == false then
      output:out("Error in dialog " .. dialogID .. " display_text code: " .. r)
      print("Error in dialog " .. dialogID .. " display_text code: " .. r)
    else
      text = r
    end
	end
  
  if dialog.after_dialog then
    local status,r = pcall(dialog.after_dialog,dialog,(speaker or self.speaker),self.asker,self.dialogID,args)
    if status == false then
      output:out("Error in dialog " .. dialogID .. " after_dialog: " .. r)
      print("Error in dialog " .. dialogID .. " after_dialog: " .. r)
    end
	end

  if not text then
    if dialog.text_random then
      text = get_random_element(dialog.text_random)
    else
      text = dialog.text
    end
  end
  self.max_text_index = 1
  
  if type(text) == "table" then
    self.text_table = text
    self.max_text_index = #text
    text = text[1]
  else
    self.text_table = nil
  end
  self:set_text(text,speaker or self.speaker)
  self.text_index = 1

  self.dialog = dialog
  self.dialogID = dialogID
  self.responses = self:load_responses(args)
  self:refresh_response_height()
  
	currGame.dialog_seen[dialogID] = (currGame.dialog_seen[dialogID] or 0)+1
  if not speaker.dialog_seen then
    speaker.dialog_seen = {}
  end
  speaker.dialog_seen[dialogID] = (speaker.dialog_seen[dialogID] or 0)+1
end


function conversation:load_responses(args)
  self.cursorY = 1
  local dialog = self.dialog
  local text_done = self.text_index >= self.max_text_index
  if not text_done then
    return {{text="...",advance=true}}
  end
  if dialog.moves_to_dialog then
    return {{text="...",moves_to_dialog=dialog.moves_to_dialog}}
  end
  if dialog.ends_conversation then
    return {{text="[End Conversation]",ends_conversation=true}}
  end

  --Custom display_responses function
  local responses
  if dialog.display_responses then
    local status,r = pcall(dialog.display_responses,dialog,self.speaker,self.asker,args)
    if status == false then
      output:out("Error in dialog " .. self.dialogID .. " display_responses code: " .. r)
      print("Error in dialog " .. self.dialogID .. " display_responses code: " .. r)
    else
      responses = r
    end
    if type(responses) == "table" and #responses > 0 then
      --TODO: check that responses have all necessary features
      return responses
    end
  end

	--if no response list from the function, then use the responses embedded in the dialog list
	if type(responses) ~= "table" and dialog.responses then
    responses = {}
    for respID,respData in pairs(dialog.responses) do
      local requires, showAnyway = true,true
      local disabled = false
      if respData.requires then
        local status,requires, showAnyway = pcall(respData.requires,respData,self.speaker,self.asker,args)
        if status == false then
          output:out("Error in response" .. respID .. " of " .. self.dialogID .. " requires code: " .. r)
          print("Error in response" .. respID .. " of " .. self.dialogID .. " requires code: " .. r)
        end
        disabled = (not requires and showAnyway)
      elseif dialog.response_requires and respData.id then
        local status,requires, showAnyway = pcall(dialog.response_requires,dialog,self.speaker,self.asker,respData.id,args)
        if status == false then
          output:out("Error in response " .. respData.id .. " of " .. self.dialogID .. " response_requires code: " .. r)
          print("Error in response " .. respData.id .. " of " .. self.dialogID .. " response_requires code: " .. r)
        end
        disabled = (not requires and showAnyway)
      end
      if requires ~= false or disabled then
        local text
        if respData.display_text then
          local status,r = pcall(respData.display_text,respData,self.speaker,self.asker,self.dialogID,args)
          if status == false then
            output:out("Error in response " .. respID .. " of " .. self.dialogID .. " display_text code: " .. r)
            print("Error in response " .. respID .. " of " .. self.dialogID .. " display_text code: " .. r)
          else
            text = r
          end
        end
        if not text then
          text = (respData.text_random and get_random_element(respData.text_random) or respData.text)
        end
        responses[#responses+1] = {text=text, moves_to_dialog=respData.moves_to_dialog, ends_conversation = respData.ends_conversation, disabled = disabled, data=respData,id=respData.id}
      end --end requires or disabled
    end --end response for
    if #responses > 0 then
      return responses
    end
  end

  --If responses aren't set for this dialog, or no responses were possible:
  return {{text="[End conversation]",ends_conversation=true}}
end

function conversation:refresh_response_height()
  local fontSize = fonts.textFont:getHeight()
  local tileSize = output:get_tile_size()
  local padding = tileSize
  local textWidth = self.windowW-padding
  self.responseHeight = 0
  for i,response in ipairs(self.responses) do
    local text = response.text or "[NO RESPONSE TEXT FOUND]"
    local _,tlines = fonts.textFont:getWrap(text,textWidth)
    local thisHeight = #tlines*fontSize
    self.responseHeight = self.responseHeight + thisHeight+4
  end
end

function conversation:advance_dialog(args)
  local dialog = self.dialog
  if self.max_text_index > self.text_index then
    self.text_index = self.text_index+1
    self:set_text(self.text_table[self.text_index],self.current_text.speaker)
    if self.text_index == self.max_text_index then
      self.responses = self:load_responses(args)
      self:refresh_response_height()
    end
    return
  end
end

function conversation:set_text(text,speaker)
	if self.current_text then
		self.history[#self.history+1] = self.current_text
  end
	self.current_text = {text=text,speaker=speaker}
end

function conversation:select_response(response)
  local speaker = response.speaker or self.speaker
  local args = response.args
  local dialog = self.dialog
  if response.text ~= "..." and not response.silent then
    self:set_text(response.text,self.asker)
  end
  
  local status,ret
	if response.data and response.data.selected then
    status,ret = pcall(response.data.selected,speaker,self.asker,args)
    if status == false then
      output:out("Error in response " .. response.text .. " of " .. self.dialogID .. " selected code: " .. ret)
      print("Error in response " .. response.text .. " of " .. self.dialogID .. " selected code: " .. ret)
    end
  elseif dialog.response_selected and response.id then
    status,ret = pcall(dialog.response_selected,dialog,self.speaker,self.asker,response.id,args)
    if status == false then
      output:out("Error in response " .. response.id .. " of " .. self.dialogID .. " response_selected code: " .. ret)
      print("Error in response " .. response.id .. " of " .. self.dialogID .. " response_selected code: " .. ret)
    end
  end
  if ret == false then
    return self:end_conversation()
  end
  if ret and possibleDialogs[ret] then
    return self:load_dialog(ret,speaker,args)
  end
	if response.advance then
		return self:advance_dialog(args)
  end
	if response.ends_conversation then
		return self:end_conversation()
	end
	if response.moves_to_dialog then
		return self:load_dialog(response.moves_to_dialog,speaker,args)
	end
	--If none of those are set, do nothing
	self:set_text("ERROR: No action set for response \"" .. (response.text or "nil") .. "\"")
  return self:load_dialog(self.dialogID,self.speaker)
end

function conversation:end_conversation()
  self:switchBack()
end
function conversation:update(dt)
  if self.switchNow == true then
    self.switchNow = nil
    Gamestate.switch(game)
    Gamestate.update(dt)
    return
  end
  if (love.mouse.isDown(1)) and self.scrollPositions then
    local x,y = love.mouse.getPosition()
    local upArrow = self.scrollPositions.upArrow
    local downArrow = self.scrollPositions.downArrow
    local elevator = self.scrollPositions.elevator
    if x>upArrow.startX and x<upArrow.endX and y>upArrow.startY and y<upArrow.endY then
      self:scrollUp()
    elseif x>downArrow.startX and x<downArrow.endX and y>downArrow.startY and y<downArrow.endY then
      self:scrollDown()
    elseif x>elevator.startX and x<elevator.endX and y>upArrow.endY and y<downArrow.startY then
      if y<elevator.startY then self:scrollUp()
      elseif y>elevator.endY then self:scrollDown() end
    end --end clicking on arrow
  end
end

function conversation:buttonpressed(key,scancode,isRepeat,controllerType)
  key,scancode,isRepeat = input:parse_key(key,scancode,isRepeat,controllerType)
  if (key == "north") then
    if self.cursorY == 0 then
      self:scrollUp()
    else
      self.cursorY = math.max((self.scrollPositions and 0 or 1),self.cursorY-1)
    end
  elseif (key == "south") then
    if self.cursorY == 0 and self.scrollY < self.maxScrollY then
      self:scrollDown()
    elseif self.cursorY < #self.responses then
      self.cursorY = self.cursorY + 1
    end
  elseif key == "enter" or key == "wait" then
    if self.responses[self.cursorY] and not self.responses[self.cursorY].disabled then
      self:select_response(self.responses[self.cursorY])
    end
  elseif key == "escape" then
    self:switchBack()
  end
end

function conversation:mousepressed(x,y,button)
  local uiScale = (prefs['uiScale'] or 1)
  x,y = x/uiScale, y/uiScale
  if button == 2 or (self.closebutton and x > self.closebutton.minX and x < self.closebutton.maxX and y > self.closebutton.minY and y < self.closebutton.maxY) then
    self:switchBack()
  end
  for _,response in ipairs(self.responses) do
    if response.minY and response.maxY and y > response.minY and y <= response.maxY and x > self.startX and x < self.endX and not response.disabled then
      self:select_response(response)
    end
  end
end

function conversation:wheelmoved(x,y)
	if y > 0 then
    conversation:scrollUp()
	elseif y < 0 then
    conversation:scrollDown()
  end
end

function conversation:scrollUp()
  if self.scrollY > 0 then
    self.scrollY = math.max(self.scrollY - prefs.fontSize,0)
  end
end

function conversation:scrollDown()
  if self.scrollY < self.maxScrollY then self.scrollY = math.min(self.scrollY+prefs.fontSize,self.maxScrollY) end
end

function conversation:switchBack()
  if not self.dialog or not self.dialog.noEscape then
    tween(0.2,self,{yModPerc=100})
    output:sound('stoneslideshortbackwards',2)
    Timer.after(0.2,function() self.switchNow=true end)
  end
end