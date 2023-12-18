possibleFeatures = {}

--Standard features used in the basic engine:

local corpse = {
  name = "corpse",
  id="corpse",
  symbol = "%",
  imageType = "creature",
  angle = .5*math.pi,
  useWalkedOnImage = true,
  description = "A dead body.",
  targetable = true,
  alwaysDisplay = true,
  new = function (self,creature)
    if creature.spritesheet then
      self.spritesheet = true
      self.image_max = creature.image_max
      self.image_frame=1
    end
    if creature.properName then
      self.name = "corpse of " .. creature.properName .. ", " .. creature.name
    else
      self.name = creature.name .. " corpse"
    end
    self.creature = creature
    self.image_name = (creature.image_name or creature.id)
    self.scale = .75
    self.color = creature.color
  end
}
possibleFeatures['corpse'] = corpse

local chunk = {
    name = "chunks",
    symbol = ".",
    description = "The bloody remains of some unfortunate creature.",
  image_name = "whitechunk1",
    color={r=255,g=0,b=0,a=255},
  use_color_with_tiles=true,
    new = function (self, creature)
        if (creature ~= nil) then
            self.name = creature.name .. " chunks"
        end
    self.angle = random(1,360)
        local chunkType = random(1,6)
        if (chunkType == 2) then
      self.image_name = "whitechunk2"
            self.symbol = "*"
        elseif (chunkType == 3) then
      self.image_name = "whitechunk2"
            self.symbol = "~"
    elseif (chunkType == 4) then
      self.image_name = "whitechunk3"
      self.symbol = ","
        end
    if creature and creature.bloodColor then
      self.color = copy_table(creature.bloodColor)
    end
    end
}
possibleFeatures['chunk'] = chunk

local door = {
    name="Door",
  id="door",
    symbol="+",
    color={r=133,g=87,b=0,a=255},
    description = "A closed door.",
  fireChance = 20,
  passableFor={ghost=true},
  blocksMovement = true,
  pathThrough = true,
  blocksSight = true,
  alwaysDisplay = true,
  actions={opendoor={text="Open Door",description="Open a nearby door."},closedoor={text="Close Door",description="Close a nearby door."}},
  closed=true,
  enter=function(self,entity)
    if not self.closed or entity:is_type('ghost') then
      return true
    elseif self.closed then
      self:action(entity,"opendoor")
      return false
    end
  end,
  action = function(self,entity,action)
    if self.closed then
      local squeak = self.squeak or self.sleeper or random(1,4) == 1
      if self.playerOnly and entity ~= player then return false end
      self.symbol="'"
      self.description = "An open door."
      self.blocksMovement = false
      self.blocksSight = false
      self.alwaysDisplay = false
      --self.actions={closedoor={text="Close Door",description="Close a nearby door."}}
      self.closed = false
      if player:can_see_tile(self.x,self.y) then
        if squeak then
          output:out("The door creaks loudly!")
          output:sound('door_open_squeak' .. random(1,2))
        else
          output:sound('door_open' .. random(1,2))
        end
      end
      if self.sleeper then
        self.sleeper:cure_condition('asleep')
        self.sleeper:become_hostile(entity)
      end
      if self.squeak then
        for x = self.x-5,self.x+5,1 do
          for y = self.y-5,self.y+5,1 do
            local creat = currMap:get_tile_creature(x,y)
            if creat and currMap:is_line(x,y,creat.x,creat.y) then
              if creat:has_condition('asleep') then
                creat:cure_condition('asleep')
              end
              creat:notice(entity)
            end --end if creat
          end --end fory
        end --end forx
      end --end if self squeak
      self.image_name = "dooropen"
    else -- close the door
      self.symbol="+"
      self.description = "A closed door."
      self.blocksMovement = true
      self.blocksSight = true
      self.alwaysDisplay = true
      --self.actions={opendoor={text="Open Door",description="Open the door."}}
      self.image_name = "doorclosed"
      self.closed=true
      if player:can_see_tile(self.x,self.y) then
        output:sound('door_close')
      end
    end
  end,
  action_requires = function(self,entity,action)
    if action == "opendoor" then return self.closed end
    if action == "closedoor" then return not self.closed end
  end
}
possibleFeatures['door'] = door

local bridge = {
  name = "Bridge",
  description = "A bridge over troubled waters (or troubled lava, or whatever).",
  symbol = "|",
  color={r=120,g=85,b=6,a=255},
  tilemap=true,
  walkedOnTilemap = true,
  tileDirection = "nsew",
  image_name = "stonebridge",
  walkedOnImage = "stonebridgecrossing"
}
function bridge:refresh_image_name()
  local dir = ""
  if not currMap:tile_has_feature(self.x,self.y-1,"bridge") then dir = dir .. "n" self.symbol = "–" end
  if not currMap:tile_has_feature(self.x,self.y+1,"bridge") then dir = dir .. "s" self.symbol = "–" end
  if not currMap:tile_has_feature(self.x+1,self.y,"bridge") then dir = dir .. "e" end
  if not currMap:tile_has_feature(self.x-1,self.y,"bridge") then dir = dir .. "w" end
  if dir == "nsew" then end
  if dir == "" then
    self.symbol = "+"
    self.tileDirection = "middle"
  else
    self.tileDirection = dir
  end
  self.walkedOnImage = self.image_name .. "crossing"
end
function bridge:new(args)
  args = args or {}
  if (args.dir == 'ns') then self.symbol = "|" self.name = "bridgens"
  elseif (args.dir == 'ew') then self.symbol = "–" self.image_name="woodbridgeew" end
  if args.image_name then self.image_name = args.image_name end
end
possibleFeatures['bridge'] = bridge

local gravestone = {
  name = "Gravestone",
  symbol = "∏",
  color={r=100,g=100,b=100},
  new = function(self,text)
        if (text ~= nil) then
            self.description = "\"" .. text .. "\""
        else
      local creat = get_random_element(possibleMonsters)
      local obituary = random(0,1) == 1 and "R.I.P" or (random(0,1) == 1 and "Here Lies" or (random(0,1) == 1 and "Resting Place of" or "Always Remembered"))
      self.description = "\"" .. obituary .. " " .. namegen:generate_human_name() .. "\nKilled by " .. (creat.properNamed and "" or (vowel(creat.name) and "an " or "a ")) .. creat.name .. ".\""
        end
    end
}
possibleFeatures['gravestone'] = gravestone

local store = {
  name="Store",
  description = "A storefront.",
  image_name="store",
  symbol="^",
  alwaysDisplay=true,
  color={r=0,g=0,b=255,a=255},
  actions={enter={text="Enter",description="Shop at the store."}},
  new = function(self,storeID) --If storeID is a number, use the store with that ID number. If it's an actual store def, use that store. If it's a string, use the first instance of a store with that ID
    local whichStore = nil
    if type(storeID) == "table" and storeID.baseType == "store" then
      whichStore = storeID
    elseif type(storeID) == "string" then
      for sid,st in pairs(currWorld.stores) do
        if st.id == storeID then
          storeID = sid
          whichStore = currWorld.stores[storeID]
          break
        end
      end
    elseif type(storeID) == "number" then
      whichStore = currWorld.stores[storeID]
    end
    if not whichStore then
      print('Store feature created with storeID ' .. tostring(storeID) .. " which doesn't correspond to any store. Randomizing.")
      whichStore = get_random_element(currWorld.stores)
    end
    self.store = whichStore
    self.name = whichStore.name
    self.actions.enter.text = "Shop at " .. whichStore.name
    self.image_name = whichStore.image_name or self.image_name
    self.color = whichStore.color or self.color
    if whichStore.map_description then self.description = whichStore.map_description end
  end,
  placed = function(self)
    self.store.isPlaced = true
  end,
  enter = function(self,creature)
    if creature == player then self:action(player) end
  end,
  action = function(self,creature)
    if creature == player then Gamestate.switch(storescreen,self.store) return false end
  end
}
possibleFeatures['store'] = store

local factionHQ = {
  name="Faction HQ",
  image_name="store",
  description = "The HQ of a faction.",
  symbol="^",
  alwaysDisplay=true,
  color={r=0,g=0,b=255,a=255},
  actions={enter={text="Enter",description="Interact with the faction."}},
  new = function(self,whichFac)
    if type(whichFac) == "string" then
      whichFac = currWorld.factions[whichFac]
    end
    if not whichFac then
      whichFac = get_random_element(currWorld.factions)
    end
    self.faction = whichFac
    self.name = whichFac.name
    self.actions.enter.text = (whichFac.enter_text or "Enter") .. " " .. whichFac.name
    self.image_name = whichFac.image_name or self.image_name
    self.color = whichFac.color or self.color
    if whichFac.map_description then self.description = whichFac.map_description end
    if whichFac.map_name then self.name = whichFac.map_name end
  end,
  placed = function(self,map)
    local placeFunc = possibleFactions[self.faction.id].placed
    if placeFunc and type(placeFunc) == "function" then
      placeFunc(self.faction,self,map)
    end
    self.faction.isPlaced = true
  end,
  enter = function(self,creature)
    if creature == player then self:action(player) end
  end,
  action = function(self,creature)
    if creature == player then Gamestate.switch(factionscreen,self.faction.id) return false end
  end
}
possibleFeatures['factionHQ'] = factionHQ

local exit = {
  name = "Exit",
  description = "An exit to another area.",
  symbol = ">",
  alwaysDisplay=true,
  color={r=255,g=255,b=255,a=255},
  actions={exit={text="Exit",description="Exit the current location."}},
}
function exit:new(args)
  self.branch = args.branch
  self.depth = args.depth or 1
  self.oneway = args.oneway
  self.locked = args.locked
  self.exitName = args.exitName or "Exit"
  self.color = args.color
  self.image_name = args.image_name
end
function exit:placed(map)
  local tileset = tilesets[map.tileset] or {}
  self.color = tileset.wallColor or tileset.textColor or {r=255,g=255,b=255,a=255}
  local matches = (map.branch == self.branch)
  self.name = (matches and self.exitName .. " to " .. (currWorld.branches[self.branch].depthName or "Depth") .. " " .. self.depth or self.exitName .. " to " .. currWorld.branches[self.branch].name)
  if matches and self.depth < map.depth then self.symbol = "<" end
  self.actions.exit.text = (matches and (self.depth < map.depth and "Go up" or "Go down") or "Enter " .. currWorld.branches[self.branch].name)
  map.exits[#map.exits+1] = self
  if not self.image_name then
    self.image_name = "stairs" .. (self.depth < map.depth and "up" or "down")
  end
  print('placed exit to ' .. self.branch .. ' ' .. self.depth .. ' at ',self.x,self.y)
end
function exit:action(entity,action)
  if not self.locked then
    goToMap(self.depth,self.branch,(self.most_recent and true or false))
  end
end
possibleFeatures['exit'] = exit

--Not required but potentially useful:

local bossActivator = {
  name = "boss activator",
  noDesc = true,
  noDisp = true,
  symbol = "",
  description = "Invisible tile that activates the boss when stepped on.",
  color ={r=0,g=0,b=0,a=0},
  enter = function(self,entity)
    if entity == player then
      generate_boss()
      for x=2,currMap.width-1,1 do
        for y=2,currMap.height-1,1 do
          local ba = currMap:tile_has_feature(x,y,'bossactivator')
          if ba then ba:delete() end
        end
      end
    end
  end --end enter functiomn
}
possibleFeatures['bossactivator'] = bossActivator