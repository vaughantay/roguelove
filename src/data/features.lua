possibleFeatures = {}

local sign = {
  name="Sign",
  id="sign",
  symbol="¥",
  useWalkedOnImage = true,
  alwaysDisplay=true,
  color={r=133,g=87,b=0,a=255},
  new = function(self,text)
    if (text ~= nil) then
      self.description = "\"" .. text .. "\""
    else
      local warnings = {"Beware!","Adventurers Welcome!","Adventurers Not Welcome!","No Vacancy","No Soliciting","No Trespassing","Beware of Dog","Your message here","Made you look","Cave for rent","This space for rent","Municipal Lot #" .. random(10,1000),"Go Away","No Hoomanz Aloud","Private Property","Welcome!","Turn Back!","Have you heard the Good News of " .. namegen:generate_god_name() .. "?",namegen:generate_first_name() .. ", will you marry me?","Now entering " .. namegen:generate_town_name(),"Please do not feed the monsters","Please do not feed the " .. namegen:get_from_list('magicCreatures'),"This cave adopted by " .. namegen:generate_group_name(true),"This cave sanctified to " .. namegen:generate_god_name()}
      self.description = "\"" .. warnings[random(#warnings)] .. "\""
    end
  end
}
possibleFeatures['sign'] = sign

local bloodstain = {
  name = "blood",
  symbol = ".",
  description = "Someone bled here. Gross!",
  image_name = "whitechunk1",
  use_color_with_tiles=true,
  color={r=255,g=0,b=0,a=255},
  remove_on_cleanup=true,
  new = function (self,color)
    self.angle = random(1,360)
        self.image_name = "whitechunk" .. random(1,2)
    if color then self.color=copy_table(color) end
  end
}
possibleFeatures['bloodstain'] = bloodstain

local slipperyblood = {
  name = "Puddle of blood",
  symbol = "~",
  description = "A slippery puddle of blood. Gross!",
  image_name = "chunk1",
  color={r=255,g=0,b=0,a=255},
  remove_on_cleanup=true,
}
function slipperyblood:new()
  self.angle = random(1,360)
  self.image_name = "chunk" .. random(1,2)
end
function slipperyblood:enter(entity,fromX,fromY)
  local xMod,yMod = self.x-fromX,self.y-fromY
  if random(1,4) == 1 and not entity:is_type("flyer") then
    while xMod == 0 and yMod == 0 do
      xMod,yMod = random(-1,1),random(-1,1)
    end
    entity:give_condition('slipping',2)
    entity.slipX=xMod
    entity.slipY=yMod
  end --end if random
end
possibleFeatures['slipperyblood'] = slipperyblood

local acid = {
  name = "acid",
  id="acid",
  symbol = "≈",
  description = "And not the fun kind, either!",
  safeFor={flyer=true},
  pathThrough = true,
  color={r=0,g=200,b=0},
  hazard = 10,
  tilemap = true,
  remove_on_cleanup=true,
  enter = function(self,entity)
    if not entity:is_type('flyer') then
      local dmg = entity:damage(tweak(7),self.creator,"acid")
      if player:can_sense_creature(entity) then output:out("The acid on the floor damages " .. entity:get_name() .. " for " .. dmg .. " damage.") end
    end
  end
}
function acid:refresh_image_name()
  local directions = ""
  if currMap:in_map(self.x,self.y-1) and currMap[self.x][self.y-1] ~= "#" and currMap:tile_has_feature(self.x,self.y-1,'acid') == false then directions = directions .. "n" end
  if currMap:in_map(self.x,self.y+1) and currMap[self.x][self.y+1] ~= "#" and currMap:tile_has_feature(self.x,self.y+1,'acid') == false then directions = directions .. "s" end
  if currMap:in_map(self.x+1,self.y) and currMap[self.x+1][self.y] ~= "#" and currMap:tile_has_feature(self.x+1,self.y,'acid') == false then directions = directions .. "e" end
  if currMap:in_map(self.x-1,self.y) and currMap[self.x-1][self.y] ~= "#" and currMap:tile_has_feature(self.x-1,self.y,'acid') == false then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['acid'] = acid

local trap = {
  name = "trap",
  id="trap",
  symbol = "^",
  description = "A nasty immobilizing trap.",
  color={r=255,g=255,b=255},
  useWalkedOnImage = true,
  hazard = 10,
  remove_on_cleanup=true,
  enter=function(self,entity,fromX,fromY)
    local moved = not (self.x == fromX and self.y == fromY)
    if moved and entity:is_type('flyer') == false then
      local trapdmg = 7+2*(self.creator and self.creator.level or 1)
      local dmg = entity:damage(tweak(trapdmg),self.creator)
      entity:give_condition('trapped',random(3,6))
      self:delete()
      if player:can_see_tile(entity.x,entity.y) then
        output:out("A trap bites down on " .. entity:get_name() .. ", dealing " .. dmg .. " damage, and getting them stuck!")
        output:sound('trap_close')
        currMap:add_effect(Effect('animation',{image_name='trapclose',image_max=3,target=entity,color={r=255,g=255,b=255}},entity.x,entity.y,false,false))
      end
    end
  end
}
possibleFeatures['trap'] = trap

local statue = {
  name = "Statue",
  symbol="Ω",
  blocksMovement = true,
  alwaysDisplay=true,
  color={r=150,g=150,b=150,a=255},
  description="A stern stone statue.",
  useWalkedOnImage = true,
}
function statue:placed(map)
  if map.mapID == "eldritchcity" then
    local statues = {{name="guardian",img='eldritchguardianstatue',cid="eldritchguardian"},{name="eldritch aristocrat",img='eldritcharistocratstatue',cid="eldritcharistocrat"},{name="tentaclebeast",img='tentaclebeaststatue',cid="tentaclebeast"},{name="mi-go",img='migostatue',cid="migo"}}
    local statdat = statues[random(#statues)]
    self.image_name = statdat.img
    self.description = "A stone statue of a " .. statdat.name .. "."
    self.name = ucfirst(statdat.name) .. " Statue"
    self.cid = statdat.cid
  elseif map.mapID == "tombs" then
    local statueType = random(1,3)
    if statueType == 1 then --king
      self.description = "A sandstone statue of " .. (random(1,4) == 1 and "some ancient king or another." or "the ancient king " .. possibleMonsters['mummy']:nameGen() .. ".")
    elseif statueType == 2 then --kitty
      self.description = "A sandstone statue of a kitty!"
    elseif statueType == 3 then --anubis
      self.description = "A sandstone statue of some guy with a jackal's head. Weird."
    end
    self.image_name = "tombstatue" .. statueType
  else
    local statueType = (map.mapID == "temple" and random(1,3) or random(1,4))
    if statueType == 1 then --warrior
      self.description = "A stone statue of " .. (random(1,4) == 1 and "some warrior you don't recognize." or namegen:generate_ruler_name() .. ", a famous hero from olden times.")
    elseif statueType == 2 then -- angel
      self.description = "A stone statue of " .. (random(1,4) == 1 and "some angelic being." or namegen:generate_angel_name() ..", the angel of " .. ucfirst(namegen:get_from_list('concepts')).. ".")
    elseif statueType == 3 then --gargoyle
      self.description = "A statue of a hideous batlike creature."
    elseif statueType == 4 then --wizard
      self.description = "A stone statue of " .. (random(1,4) == 1 and "some wizard you don't recognize." or namegen:generate_wizard_name() .. ", a famous wizard from olden times.")
    end
    self.image_name = "statue" .. statueType
  end
end
possibleFeatures['statue'] = statue

local petrify_victim = {
  name = "Petrified Creature",
  symbol="Ω",
  alwaysDisplay=true,
  blocksMovement=true,
  color={r=150,g=150,b=150,a=255},
  description="Poor unfortunate soul.",
  useWalkedOnImage = true,
}
possibleFeatures['petrify_victim'] = petrify_victim

local gate = {
  name="Gate",
  symbol="+",
  color={r=100,g=100,b=100,a=255},
  description = "A closed iron gate.",
  passableFor={ghost=true},
  blocksMovement = true,
  pathThrough = true,
  enter=function(self,entity)
    if entity:is_type('ghost') then return true end
    if self.symbol == "+" then
      if self.playerOnly and entity ~= player then return false end
      self.symbol="'"
      self.description = "An open iron gate."
      self.blocksMovement = false
      self.blocksSight = false
      if player:can_see_tile(self.x,self.y) then
        output:out("The gate creaks loudly!")
        output:sound("gate_open")
      end
      if self.sleeper then
        self.sleeper:cure_condition('asleep')
        self.sleeper:become_hostile(entity)
      end
      self.image_name = "gateopen"
      return false
    end
  end
}
possibleFeatures['gate'] = gate

local valhallagate = {
  name="Gate to Valhalla",
  symbol="+",
  color={r=100,g=100,b=100,a=255},
  description = "A closed adamantium gate.",
  blocksMovement = true,
  pathThrough = true,
  closed=true,
  actions={unlock={text="Unlock the Gate to Valhalla",description="Unlock the Gate to Valhalla."}},
  enter=function(self,entity)
    if self.closed then
      self:action(entity)
      return false
    end
  end,
  action = function(self,entity)
    local herokey = player:has_item('heroskey')
    if entity ~= player or not herokey then output:out("You need a Hero's Key to unlock the gates to Valhalla.") return false end
    self.symbol="'"
    self.closed=false
    self.description = "An open iron gate."
    self.blocksMovement = false
    self.blocksSight = false
    if player:can_see_tile(self.x,self.y) then
      output:out("You place the Hero's Key in the gate and turn it. The gate opens, and the key fades away.")
      output:sound("gate_open")
    end
    self.image_name = "gateopen"
    player:delete_item(herokey,1)
    update_mission_status('ascend')
  end,
  action_requires=function(self,user)
    if self.closed and user:has_item('heroskey') then
      return true
    else
      return false
    end
  end
}
possibleFeatures['valhallagate'] = valhallagate

local tree = {
  name = "Tree",
  useWalkedOnImage = true,
  description = "A tall tree.",
  symbol = "7",
  passableFor={ghost=true},
  color={r=0,g=200,b=0},
  blocksMovement = true,
  alwaysDisplay = true,
  blocksSight = true,
  fireChance = 20,
  fireTime = 30,
}
function tree:new()
  self.image_name = "tree" .. random(1,3)
end
possibleFeatures['tree'] = tree

local deadtree = {
  name = "Dead Tree",
  useWalkedOnImage = true,
  description = "A dead tree. Kind of makes sense, since it's underground and there's no light.",
  symbol = "7",
  passableFor={ghost=true},
  color={r=150,g=150,b=150,a=255},
  blocksMovement = true,
  alwaysDisplay = true,
  blocksSight = true,
  fireChance = 100,
  fireTime = 15,
}
function deadtree:new()
  self.image_name = "deadtree" .. random(1,3)
end
possibleFeatures['deadtree'] = deadtree

local mushroom = {
  name = "Giant Mushroom",
  useWalkedOnImage = true,
  description = "A giant mushroom. Possibly poisonous, probably hallucinogenics.",
  symbol = "7",
  passableFor={ghost=true},
  color={r=133,g=129,b=105,a=255},
  blocksMovement = true,
  alwaysDisplay = true,
  blocksSight = true,
  attackable = true,
  fireChance = 10,
}
function mushroom:new()
  self.image_name = "mushroom" .. random(1,3)
end
function mushroom:damage(_,source)
  if source and source.baseType == "creature" and player:can_see_tile(self.x,self.y) then
    output:out(source:get_name() .. " smashes a mushroom, releasing a cloud of spores!")
    output:sound('smash_mushroom')
  end
  for i=1,random(2,5),1 do
    local s = Effect('spores')
    s.strength=3
    currMap:add_effect(s,self.x,self.y)
  end
  self:delete()
end
possibleFeatures['mushroom'] = mushroom

local grass = {
  name = "Grass",
  id="grass",
  description = "Green blades of grass.",
  symbol = ".",
  color={r=0,g=255,b=0},
  noDesc = true,
  fireChance = 5,
  fireTime = 5,
  tilemap = true,
  image_varieties=2,
  new = function(self)
        self.color.g = random(150,255)
    local symbol = random(1,3)
    if symbol == 1 then
      self.symbol = ","
    elseif symbol == 2 then
      self.symbol = ";"
    end
  end
}
function grass:refresh_image_name()
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'grass') == false then directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'grass') == false then directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'grass') == false then directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'grass') == false then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['grass'] = grass

local deadgrass = {
  name = "Dead Grass",
  description = "Dead, crunchy, flammable grass.",
  symbol = ".",
  color={r=200,g=200,b=200,a=255},
  noDesc = true,
  fireChance = 100,
  fireTime = 2,
  tilemap = true,
  new = function(self)
    self.color.g = random(150,255)
    if (random(1,2) == 1) then self.symbol = "," end
  end
}
function deadgrass:refresh_image_name()
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'deadgrass') == false then directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'deadgrass') == false then directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'deadgrass') == false then directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'deadgrass') == false then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['deadgrass'] = deadgrass

local shallowwater = {
  name = "Shallow Water",
  description = "Cool, blue water.",
  symbol="≈",
  water = true,
  color={r=0,g=200,b=200},
  hazard = 1,
  hazardousFor = {fire=true},
  tilemap = true,
  walkedOnTilemap = true,
  walkedOnImage = "shallowwaterwading",
  enter = function(self,entity,fromX,fromY)
    if entity:has_condition('onfire') then entity:cure_condition('onfire') end
    local moved = not (self.x == fromX and self.y == fromY)
    if entity:is_type('flyer') == false and currMap:tile_has_feature(entity.x,entity.y,"bridge") == false then
      if entity:is_type('swimmer') then
        if not entity.conditions['swimming'] then
          entity:give_condition('swimming',-1)
          if player:can_see_tile(entity.x,entity.y) and moved then output:sound('enterwater') end
        elseif player:can_see_tile(entity.x,entity.y) and moved then
          output:sound('watersplash' .. random(1,2))
        end
      else
        if not entity.conditions['wadingshallowwater'] then
          entity:give_condition('wadingshallowwater',-1)
          if player:can_see_tile(entity.x,entity.y) and moved then output:sound('enterwater') end
        elseif player:can_see_tile(entity.x,entity.y) and moved then
          output:sound('watersplash' .. random(1,2))
        end --end wading shallowwater if
      end --end swimmmer if
    end --end flyer if
  end --end enter function
}
function shallowwater:refresh_image_name()
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'shallowwater') == false and currMap:tile_has_feature(self.x,self.y-1,'deepwater') == false then directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'shallowwater') == false and currMap:tile_has_feature(self.x,self.y+1,'deepwater') == false  then directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'shallowwater') == false and currMap:tile_has_feature(self.x+1,self.y,'deepwater') == false  then directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'shallowwater') == false and currMap:tile_has_feature(self.x-1,self.y,'deepwater') == false  then directions = directions .. "w" end
  if currMap:tile_has_feature(self.x,self.y,"bridge") == true then self.walkedOnImage = nil end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['shallowwater'] = shallowwater

local sewage = {
  name = "Sewage",
  description = "Smelly.",
  symbol="≈",
  tilemap = true,
  water = true,
  safeFor = {swimmer=true,flyer=true},
  walkedOnImage = "wadingsewage",
  color={r=55,g=70,b=60,a=255},
  enter = function(self,entity,fromX,fromY)
    if entity:has_condition('onfire') then entity:cure_condition('onfire') end
    local moved = not (self.x == fromX and self.y == fromY)
    if entity:is_type('flyer') == false and currMap:tile_has_feature(entity.x,entity.y,"bridge") == false then
      if entity:is_type('swimmer') then
        if not entity.conditions['swimming'] then
          entity:give_condition('swimming',-1)
          if player:can_see_tile(entity.x,entity.y) and moved then output:sound('enterwater') end
        elseif player:can_see_tile(entity.x,entity.y) and moved then
          output:sound('watersplash' .. random(1,2))
        end
      else
        if not entity.conditions['wadingshallowwater'] then
          entity:give_condition('wadingshallowwater',-1)
          if player:can_see_tile(entity.x,entity.y) and moved then output:sound('enterwater') end
        elseif player:can_see_tile(entity.x,entity.y) and moved then
          output:sound('watersplash' .. random(1,2))
        end --end wading shallowwater if
      end --end swimmmer if
    end --end flyer if
  end
}
function sewage:refresh_image_name()
  --[[local directions = ""
  if currMap[self.x][self.y-1] ~= "#" and currMap:tile_has_feature(self.x,self.y-1,'sewage') == false then directions = directions .. "n" end
  if currMap[self.x][self.y+1] ~= "#" and currMap:tile_has_feature(self.x,self.y+1,'sewage') == false then directions = directions .. "s" end
  if currMap[self.x+1][self.y] ~= "#" and currMap:tile_has_feature(self.x+1,self.y,'sewage') == false then directions = directions .. "e" end
  if currMap[self.x-1][self.y] ~= "#" and currMap:tile_has_feature(self.x-1,self.y,'sewage') == false then directions = directions .. "w" end
  self.image_name = ("sewage" .. directions)]]
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'sewage') == false then directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'sewage') == false then directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'sewage') == false then directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'sewage') == false then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
  if currMap:tile_has_feature(self.x,self.y,"bridge") == false then self.walkedOnImage = "wadingsewage" .. string.gsub(directions,"n","") end
end --end get_image
possibleFeatures['sewage'] = sewage

local swampwater = {
  name = "Swamp Water",
  description = "Still water, covered in a layer of slime.",
  symbol="≈",
  water = true,
  color={r=0,g=125,b=100},
  hazard = 1,
  hazardousFor = {fire=true},
  tilemap = true,
  walkedOnImage = "wadingswampwater",
  enter = function(self,entity,fromX,fromY)
    if entity:is_type('flyer') == false and currMap:tile_has_feature(entity.x,entity.y,"bridge") == false then
      local seen = player:can_see_tile(entity.x,entity.y)
      if entity:has_condition('onfire') then entity:cure_condition('onfire') end
      local moved = not (self.x == fromX and self.y == fromY)
      if entity:is_type('swimmer') then
        if not entity.conditions['swimming'] then
          entity:give_condition('swimming',-1)
          if seen and moved then output:sound('enterwater') end
        elseif seen and moved then
          output:sound('watersplash' .. random(1,2))
        end
      else
        if not entity.conditions['wadingshallowwater'] then
          entity:give_condition('wadingshallowwater',-1)
          if seen and moved then output:sound('enterwater') end
        elseif seen and moved then
          output:sound('watersplash' .. random(1,2))
        end --end wading shallowwater if
      end --end swimmmer if
    end --end flyer if
  end --end enter function
}
function swampwater:refresh_image_name()
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'swampwater') == false then directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'swampwater') == false then directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'swampwater') == false then directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'swampwater') == false then directions = directions .. "w" end
  if currMap:tile_has_feature(self.x,self.y,"bridge") == false then self.walkedOnImage = "wadingswampwater" .. string.gsub(directions,"n","") end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['swampwater'] = swampwater

local riverofthedead = {
  name = "River of the Dead",
  description = "Dark water that absorbs all light and casts no reflection. If you get too close, you can hear ghostly whispers.",
  symbol="≈",
  color={r=33,g=0,b=33,a=255},
  hazard = 1,
  absorbs = true,
  safeFor={flyer=true,undead=true},
  enter = function(self,entity,fromX,fromY)
    local moved = not (self.x == fromX and self.y == fromY)
    --Damage:
    if entity:is_type('undead') == false and entity:is_type('flyer') == false and entity:is_type('construct') == false then
      if currMap:tile_has_feature(self.x,self.y,'bridge') == false then
        local dmg = entity:damage(1,nil,'unholy',nil,true)
        if dmg and player:can_see_tile(entity.x,entity.y) then
          output:out("The river of the dead drains " .. dmg .. " HP from " .. entity:get_name())
        end
      end --end bridge if
    end --end entity type if
    
    --Splashes:
    if entity:is_type('flyer') == false and currMap:tile_has_feature(entity.x,entity.y,"bridge") == false then
      if entity:is_type('swimmer') then
        if not entity.conditions['swimming'] then
          entity:give_condition('swimming',-1)
          if player:can_see_tile(entity.x,entity.y) then output:sound('enterwater_deadriver') end
        elseif player:can_see_tile(entity.x,entity.y) then
          output:sound('watersplash' .. random(1,2) .. "_deadriver")
        end
      else
        if not entity.conditions['wadingshallowwater'] then
          entity:give_condition('wadingshallowwater',-1)
          if player:can_see_tile(entity.x,entity.y)  then output:sound('enterwater_deadriver') end
        elseif player:can_see_tile(entity.x,entity.y) then
          output:sound('watersplash' .. random(1,2) .. "_deadriver")
        end --end wading shallowwater if
      end --end swimmmer if
    end --end flyer if
  end --end enter function
}
function riverofthedead:refresh_image_name()
  local directions = ""
  if currMap:in_map(self.x,self.y-1) and currMap[self.x][self.y-1] ~= "#" and (currMap[self.x][self.y-1].id == nil or currMap[self.x][self.y-1].id ~= "riverofthedead") then directions = directions .. "n" end
  if currMap:in_map(self.x,self.y+1) and currMap[self.x][self.y+1] ~= "#" and (currMap[self.x][self.y+1].id == nil or currMap[self.x][self.y+1].id ~= "riverofthedead") then directions = directions .. "s" end
  if currMap:in_map(self.x+1,self.y) and currMap[self.x+1][self.y] ~= "#" and (currMap[self.x+1][self.y].id == nil or currMap[self.x+1][self.y].id ~= "riverofthedead") then directions = directions .. "e" end
  if currMap:in_map(self.x-1,self.y) and currMap[self.x-1][self.y] ~= "#" and (currMap[self.x-1][self.y].id == nil or currMap[self.x-1][self.y].id ~= "riverofthedead") then directions = directions .. "w" end
  self.image_name = ("deadriver" .. directions)
  if currMap:tile_has_feature(self.x,self.y,"bridge") == false then self.walkedOnImage = "wadingdeadriver" .. string.gsub(directions,"n","") end
end --end get_image
possibleFeatures['riverofthedead'] = riverofthedead

local deepwater = {
  name = "Deep Water",
  description = "Cool, blue water.",
  symbol="≈",
  water=true,
  absorbs = true,
  color={r=0,g=0,b=200},
  hazard=5,
  absorbs = true,
  safeFor={swimmer=true,flyer=true},
  tilemap = true,
  walkedOnTilemap = true,
  walkedOnImage = "deepwaterwading",
}
function deepwater:enter(entity)
  if entity:has_condition('onfire') then entity:cure_condition('onfire') end
  if entity:is_type('swimmer') then
    if not entity.conditions['swimming'] then
      entity:give_condition('swimming',-1)
      if player:can_see_tile(entity.x,entity.y) and moved then output:sound('enterwater') end
    elseif player:can_see_tile(entity.x,entity.y) and moved then
      output:sound('watersplash' .. random(1,2))
    end
  else
    if not entity.conditions['drowning'] then
      entity:give_condition('drowning',-1)
      if player:can_see_tile(entity.x,entity.y) and moved then output:sound('enterwater') end
    elseif player:can_see_tile(entity.x,entity.y) and moved then
      output:sound('watersplash' .. random(1,2))
    end --end wading shallowwater if
  end --end swimmmer if
end
function deepwater:refresh_image_name()
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'shallowwater') then directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'shallowwater') then directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'shallowwater') then directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'shallowwater') then directions = directions .. "w" end
  if currMap:tile_has_feature(self.x,self.y,"bridge") == true then self.walkedOnImage = nil end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['deepwater'] = deepwater

local lava = {
  name = "Lava",
  description = "Hot, hot, hot!",
  symbol="≈",
  color={r=255,g=40,b=0},
  hazard=20,
  absorbs = true,
  tilemap=true,
  tileDirection = "nsew",
  safeFor={fireImmune=true,flyer=true},
  image_varieties=2,
  walkedOnTilemap = true,
  enter = function(self,entity)
    if (entity:is_type('fireImmune') == false and entity:is_type('flyer') == false) then
      if currMap:tile_has_feature(self.x,self.y,'bridge') == false and currMap:tile_has_feature(self.x,self.y,'minetracks') == false then
        local dmg = entity:damage(tweak(15),nil,'fire')
        if player:can_see_tile(entity.x,entity.y) then output:out("The lava burns " .. entity:get_name() .. " for " .. dmg .. " fire damage!") end
      end --end bridge if
    end --end entity type if
  end
}
function lava:refresh_image_name()
  local directions = ""
  if currMap:in_map(self.x,self.y-1) and currMap[self.x][self.y-1] ~= "#" and (currMap[self.x][self.y-1].id == nil or currMap[self.x][self.y-1].id ~= "lava") or currMap:tile_has_feature(self.x,self.y-1,'lava') == false then directions = directions .. "n" end
  if currMap:in_map(self.x,self.y+1) and currMap[self.x][self.y+1] ~= "#" and (currMap[self.x][self.y+1].id == nil or currMap[self.x][self.y+1].id ~= "lava") or currMap:tile_has_feature(self.x,self.y+1,'lava') == false  then directions = directions .. "s" end
  if currMap:in_map(self.x+1,self.y) and currMap[self.x+1][self.y] ~= "#" and (currMap[self.x+1][self.y].id == nil or currMap[self.x+1][self.y].id ~= "lava") or currMap:tile_has_feature(self.x+1,self.y,'lava') == false  then directions = directions .. "e" end
  if currMap:in_map(self.x-1,self.y) and currMap[self.x-1][self.y] ~= "#" and (currMap[self.x-1][self.y].id == nil or currMap[self.x-1][self.y].id ~= "lava") or currMap:tile_has_feature(self.x-1,self.y,'lava') == false  then directions = directions .. "w" end
  if directions == "" then
    self.tileDirection = "middle"
  else
    self.tileDirection = directions
end
  if currMap:tile_has_feature(self.x,self.y,"bridge") or currMap:tile_has_feature(self.x,self.y,"minetracks") then
    self.walkedOnImage = nil
  else
    self.walkedOnImage = "lava" .. self.image_variety .. "wading"
  end
end --end get_image
possibleFeatures['lava'] = lava

local ember = {
  name = "Ember",
  description = "Hot embers are scattered on the ground.",
  symbol=".",
  color={r=150,g=0,b=0},
  hazard=10,
  tilemap=true,
  tileDirection = "middle",
  castsLight = true,
  lightDist=1,
  heat=8,
  use_color_with_tiles=true,
  safeFor={fireImmune=true,flyer=true},
  remove_on_cleanup=true,
  enter = function(self,entity)
    if (entity:is_type('fireImmune') == false and entity:is_type('flyer') == false) then
      local dmg = entity:damage(tweak(self.heat),nil,'fire')
      if player:can_see_tile(entity.x,entity.y) then output:out("The ember burns " .. entity:get_name() .. " for " .. dmg .. " fire damage!") end
    end --end entity type if
  end,
  placed = function(self,onMap)
    local anim = Effect('emberanimator')
    anim.ember = self
    onMap:add_effect(anim,self.x,self.y)
    for x=self.x-1,self.x+1,1 do
      for y=self.y-1,self.y+1,1 do
        local ember = currMap:tile_has_feature(x,y,'ember')
        if ember then
          ember:refresh_image_name()
        end --end ember if
      end --end fory
    end --end forx
  end,
  refresh_image_name = function(self)
    local directions = ""
    if currMap:tile_has_feature(self.x,self.y-1,'ember') == false then directions = directions .. "n" end
    if currMap:tile_has_feature(self.x,self.y+1,'ember') == false then directions = directions .. "s" end
    if currMap:tile_has_feature(self.x+1,self.y,'ember') == false then directions = directions .. "e" end
    if currMap:tile_has_feature(self.x-1,self.y,'ember') == false then directions = directions .. "w" end
    if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
  end --end get_image
}
possibleFeatures['ember'] = ember

local chasm = {
  name = "Chasm",
  id = "chasm",
  description = "A deep pit, leading into the depths of the earth.",
  symbol = "#",
  color={r=50,g=0,b=50},
  impassable = true,
  passableFor = {flyer=true,chasmDweller=true,knockedback=true},
  absorbs = true,
  tilemap = true
}
function chasm:refresh_image_name()
  local directions = ""
  if currMap:in_map(self.x,self.y-1) and (currMap[self.x][self.y-1].id == nil or currMap[self.x][self.y-1].id ~= "chasm") then directions = directions .. "n" end
  if currMap:in_map(self.x,self.y+1) and (currMap[self.x][self.y+1].id == nil or currMap[self.x][self.y+1].id ~= "chasm") then directions = directions .. "s" end
  if currMap:in_map(self.x+1,self.y) and (currMap[self.x+1][self.y].id == nil or currMap[self.x+1][self.y].id ~= "chasm") then directions = directions .. "e" end
  if currMap:in_map(self.x-1,self.y) and (currMap[self.x-1][self.y].id == nil or currMap[self.x-1][self.y].id ~= "chasm") then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
  self.image_name = "chasm" .. random(1,2)
end --end get_image
function chasm:enter(entity)
    if entity:is_type('flyer') == false and entity:is_type('chasmDweller') == false and entity:is_type('knockedback') == false and entity.hp > 0 then
      if currMap:tile_has_feature(self.x,self.y,'bridge') == false and currMap:tile_has_feature(self.x,self.y,'minetracks') == false then
        if player:can_sense_creature(entity) then output:out(entity:get_name() .. " falls into the pit!") end
        entity:give_condition('falling',-1,entity.lastAttacker)
      end --end bridge if
    end --end entity type if
  end
possibleFeatures['chasm'] = chasm

local brokenWall = {
  name = "Broken Wall",
  description = "A crumbling section of wall.",
  symbol = "*",
  impassable = true,
  wall = true,
  passableFor = {flyer=true},
  color={r=255,g=255,b=255,a=255}
}
function brokenWall:refresh_image_name()
  local direction = ""
  if currMap:in_map(self.x+1,self.y) and currMap[self.x+1][self.y] == "#" or (type(currMap[self.x+1][self.y]) == "table" and currMap[self.x+1][self.y].id == "brokenwall") or currMap:tile_has_feature(self.x+1,self.y,'door') then direction = direction .. "e" end
  if currMap:in_map(self.x-1,self.y) and currMap[self.x-1][self.y] == "#" or (type(currMap[self.x-1][self.y]) == "table" and currMap[self.x-1][self.y].id == "brokenwall") or currMap:tile_has_feature(self.x-1,self.y,'door') then direction = direction .. "w" end
  --if direction == "" and (currMap[self.x][self.y+1] == "#" or (type(currMap[self.x][self.y+1]) == "table" and currMap[self.x][self.y+1].id == "brokenwall") or currMap:tile_has_feature(self.x,self.y+1,'door')) then direction = "s" .. direction end
  self.image_name = (self.image_base or "brokenwall") .. direction
end
possibleFeatures['brokenwall'] = brokenWall

local brokentiles = {
  name = "Tile Floor",
  noDesc = true,
  symbol = ".",
  color={r=255,g=255,b=255},
  tilemap = true,
  image_varieties=2,
}
function brokentiles:refresh_image_name()
  local directions = ""
  if currMap:in_map(self.x,self.y-1) and (currMap[self.x][self.y-1].id == nil or currMap[self.x][self.y-1].id ~= "brokentiles") and currMap[self.x][self.y-1] ~= "<" and currMap[self.x][self.y-1] ~= ">" and currMap[self.x][self.y-1] ~= "#" then directions = directions .. "n" end
  if currMap:in_map(self.x,self.y+1) and (currMap[self.x][self.y+1].id == nil or currMap[self.x][self.y+1].id ~= "brokentiles") and currMap[self.x][self.y+1] ~= "<" and currMap[self.x][self.y+1] ~= ">" and currMap[self.x][self.y+1] ~= "#" then directions = directions .. "s" end
  if currMap:in_map(self.x+1,self.y) and  (currMap[self.x+1][self.y].id == nil or currMap[self.x+1][self.y].id ~= "brokentiles") and currMap[self.x+1][self.y] ~= "<" and currMap[self.x+1][self.y] ~= ">" and currMap[self.x+1][self.y] ~= "#" then directions = directions .. "e" end
  if currMap:in_map(self.x-1,self.y) and (currMap[self.x-1][self.y].id == nil or currMap[self.x-1][self.y].id ~= "brokentiles") and currMap[self.x-1][self.y] ~= "<" and currMap[self.x-1][self.y] ~= ">" and currMap[self.x-1][self.y] ~= "#" then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
  if self.tileDirection == "middle" and not self.fancy then
    self.image_name = "stonetile" .. random(1,7)
    self.tilemap = false
  elseif self.fancy then
    self.image_name = "brokentilesfancy"
  end
end --end get_image
possibleFeatures['brokentiles'] = brokentiles

local flower = {
  name = "Flower",
  id = "flower",
  description = "A pretty flower.",
  symbol = "*",
  use_color_with_tiles = true,
  color={r=255,g=255,b=255},
  new = function(self)
    local r,g,b = random(0,255),random(0,255),random(0,255)
    self.color={r=r,g=g,b=b}
  end
}
possibleFeatures['flower'] = flower

local grave = {
  name = "Grave",
  description = "Where a body is buried.",
  symbol = "≈",
  color={r=98,g=73,b=22,a=255},
}
possibleFeatures['grave'] = grave

local bonepile = {
  name = "Pile of Bones",
  symbol = "%",
  description = "A pile of old bones.",
  color={r=200,g=200,b=200},
  new = function(self,creature)
    self.creature = creature
  end,
}
possibleFeatures['bonepile'] = bonepile

local zombait = {
  name = "Bait",
  description = "A bit of rotten meat. Animals and the undead find it irresistable.",
  symbol = "*",
  color={r=150,g=0,b=0,a=255},
  remove_on_cleanup=true
}
possibleFeatures['zombait'] = zombait

local slime = {
  name = "Slime",
  description = "A puddle of slippery slime.",
  symbol = "~",
  tilemap = true,
  tileDirection = "nsew",
  hazard=1,
  color={r=0,g=175,b=0,a=175},
  remove_on_cleanup=true,
  enter = function(self,entity,fromX,fromY)
    local xMod,yMod = self.x-fromX,self.y-fromY
    if entity:has_spell('slimetrail') == false and entity:is_type('flyer') == false then
      if entity.id == "slimemold" then
        entity.max_hp = entity.max_hp + 1
        entity:updateHP(1)
        self:delete()
        for x=self.x-1,self.x+1,1 do
          for y=self.y-1,self.y+1,1 do
            local s = currMap:tile_has_feature(x,y,'slime')
            if s then s:refresh_image_name() end
          end --end fory
        end --end forx
      else
        if random(1,3) == 1 then
          while xMod == 0 and yMod == 0 do
            xMod,yMod = random(-1,1),random(-1,1)
          end
          entity:give_condition('slipping',2)
          entity.slipX=xMod
          entity.slipY=yMod
        end --end if random
        if self.deletable then
          self:delete()
          for x=self.x-1,self.x+1,1 do
            for y=self.y-1,self.y+1,1 do
              local s = currMap:tile_has_feature(x,y,'slime')
              if s then s:refresh_image_name() end
            end --end fory
          end --end forx
        end --end if self.deletable
      end
    end --end slimetrail if
  end
}
function slime:placed(onMap)
  for x=self.x-1,self.x+1,1 do
    for y=self.y-1,self.y+1,1 do
      local slime = onMap:tile_has_feature(x,y,'slime')
      if slime then slime:refresh_image_name(onMap) end
    end --end fory
  end --end forx
end
function slime:refresh_image_name(onMap)
  onMap = onMap or currMap
  local directions = ""
  if onMap:tile_has_feature(self.x,self.y-1,'slime') == false then directions = directions .. "n" end
  if onMap:tile_has_feature(self.x,self.y+1,'slime') == false then directions = directions .. "s" end
  if onMap:tile_has_feature(self.x+1,self.y,'slime') == false then directions = directions .. "e" end
  if onMap:tile_has_feature(self.x-1,self.y,'slime') == false then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['slime'] = slime

local web = {
  name = "Web",
  description = "A spider web. Spiders can cross it freely, but everyone else will get stuck.",
  symbol = "&",
  hazard=3,
  safeFor={spider=true,flyer=true},
  pathThrough = true,
  color={r=200,g=200,b=200,a=255},
  tilemap=true,
  tileDirection = "nsew",
  alwaysDisplay=true,
  fireChance = 100,
  fireTime = 2,
  remove_on_cleanup=true,
  enter = function(self,entity)
    if (entity.id ~= "spider" and not entity:is_type('flyer')) then
      entity:give_condition("webbed",random(2,3))
      currMap:add_effect(Effect('conditionanimation',{owner=entity,condition="webbed",symbol="~",image_base="spiderwebtangle",image_max=2,speed=entity.animation_time,color={r=255,g=255,b=255,a=255},use_color_with_tiles=false,spritesheet=true}),entity.x,entity.y)
      if player:can_see_tile(self.x,self.y) then output:sound('webbed') end
      self:delete()
      for x=entity.x-1,entity.x+1,1 do
        for y=entity.y-1,entity.y+1,1 do
          local web = currMap:tile_has_feature(x,y,'web')
          if web then web:refresh_image_name() end
        end
      end --end forx
    end
  end
}
function web:refresh_image_name()
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'web') == false then directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'web') == false  then directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'web') == false  then directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'web') == false  then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['web'] = web

local treasure = {
  name = "Treasure",
  description = "Priceless treasure, undoubtedly of immense value to whoever is buried here. Probably best to leave it alone. Not like a ghost has much use for it anyway.",
  symbol = "$",
  color={r=255,g=255,b=0,a=255},
  enter = function(self,entity,fromX,fromY)
    local moved = not (self.x == fromX and self.y == fromY)
    if not moved then return end --don't jangle coins if you're standing still
    local seen = player:can_see_tile(entity.x,entity.y)
    local flyer = entity:is_type('flyer')
    if self.mummy and self.mummy.hp > 0 and self.sarcophagus.activated == false and self.mummy:is_enemy(entity) and not flyer then
      local activate = false
      self.sarcophagus.noise = (self.sarcophagus.noise or 0)+1
      if random(1,10) < self.sarcophagus.noise then activate = true end
      if seen then
        output:out(entity:get_name() .. " steps on some coins, which shift and jangle loudly.")
        if activate then
          output:out("There's a loud moan from the sarcophagus of " .. self.mummy:get_name(nil,true) ..". It begins to shake and thump, as if something is trying to get out...")
          self.sarcophagus.activated = true
          self.sarcophagus.shaker.activated = true
          self.sarcophagus.activator = entity
          output:sound('coinstep_awaken')
        elseif entity == player then
          output:sound('coinstep_player')
        else
          output:sound('coinstep_other')
        end
      end
    elseif seen and not flyer then --if mummy is already awakened
      output:out(entity:get_name() .. " steps on some coins, which shift and jangle loudly.")
      if entity == player then
        output:sound('coinstep_player')
      else
        output:sound('coinstep_other')
      end
    end
  end,
  new = function(self,entity)
    self.image_name = 'treasure' .. random(1,3)
  end
}
possibleFeatures['treasure'] = treasure

local sarcophagus = {
  name = "Sarcophagus",
  description = "The resting place of an ancient ruler.",
  symbol = "8",
  color={r=200,g=200,b=200,a=255},
  activated = false,
  blocksMovement = true,
}
function sarcophagus:new()
  self.image_name = "sarcophagus" .. random(1,2)
end
possibleFeatures['sarcophagus'] = sarcophagus

local coffin = {
  name = "Coffin",
  description = "Someone's final resting place.",
  symbol = "0",
  color={r=200,g=200,b=200,a=255},
  activated = false,
  blocksMovement = true,
  container=true,
  inventory_inaccessible=true,
  actions={open={text="Open Coffin",description="Open a coffin to see what's inside."}},
}
function coffin:new()
  self.image_name = "coffin" .. random(1,2)
end
function coffin:placed(onMap)
  if random(1,3) == 1 then --enemy
    local creatures = {'zombie','skeleton'}
    self.creature = Creature(creatures[random(#creatures)],onMap:get_min_level())
  else --bones
    local bones = Item('bone')
    bones.possessor,bones.x,bones.y=self,self.x,self.y
    local skull = Item('humanskull')
    skull.possessor,skull.x,skull.y=self,self.x,self.y
    local boneAmt = random(5,10)
    bones.amount = boneAmt
    self:give_item(bones)
    self:give_item(skull)
  end
  if random(1,3) == 1 then --treasure
    --TODO: add treasure
  end
end
function coffin:action(entity,action)
  if action == "open" then
    self.inventory_inaccessible=false
    local text = "You open the coffin."
    if self.creature then
      text = text .. " A " .. self.creature.name .. " jumps out at you!"
      currMap:add_creature(self.creature,self.x,self.y)
      self.creature = nil
    end
    self.actions.open=nil
    output:out(text)
  end
end
possibleFeatures['coffin'] = coffin

local urn = {
  name = "Urn",
  symbol = "µ",
  description = "An urn, holding someone's remains.",
  color = {r=59,g=53,b=66,a=255},
  blocksMovement=true,
  passableFor={ghost=true},
  attackable=true,
  damage = function(self,_,attacker)
    if player:can_see_tile(self.x,self.y) then
      output:out((attacker.exploded and "A flying chunk" or attacker:get_name()) .. " breaks an urn.")
      output:sound('vase_smash')
    end
    for x=self.x-10,self.x+10,1 do
      for y =self.y-10,self.y+10,1 do
        local creat = currMap:get_tile_creature(x,y)
        if creat and attacker then
          creat:notice(attacker)
        end --end creat if
      end --end fory
    end --end forx
    currMap:add_feature(Feature('brokenvase',{image_base = "urn",broken_num = 3}),self.x,self.y)
    currMap:add_feature(Feature('ashpile'),self.x,self.y)
    self:delete()
  end
}
possibleFeatures['urn'] = urn

local gravedirtfloor = {
  name = "Gravedirt Floor",
  noDesc = true,
  symbol = ".",
  color={r=98,g=73,b=22,a=255},
  image_varieties=5
}
possibleFeatures['gravedirtfloor'] = gravedirtfloor

local icewall = {
  name = "Ice Wall",
  description = "A giant block of ice.",
  symbol = "#",
  color={r=200,g=200,b=255,a=255},
  blocksMovement = true,
  alwaysDisplay = true,
  blocksSight = false,
  attackable=true,
}
function icewall:damage(_,source)
  if source and source.baseType == "creature" and player:can_see_tile(self.x,self.y) then
    if self.cracked then
      self:delete()
    else
      self.cracked = true
      self.symbol = "%"
    end
  end
end
possibleFeatures['icewall'] = icewall

local bush = {
  name = "Bushes",
  description = "Thick bushes.",
  symbol = "œ",
  color={r=0,g=150,b=0,a=255},
  blocksSight = true,
  fireChance = 30,
  fireTime = 15,
  walkedOnNoFollow=true
}
function bush:new()
  local btype = random(1,3)
  self.image_name = "bush" .. btype
  self.walkedOnImage = "bushhiding" .. btype
end
function bush:enter(entity,fromX,fromY)
  if entity:is_type('flyer') == false and not entity:has_condition('inbushes') then
    entity:give_condition('inbushes',-1)
    if player:can_see_tile(entity.x,entity.y) then
      output:sound('grass_rustle' .. random(1,2))
    end
  end --end flyer if
end --end enter function
possibleFeatures['bush'] = bush

local deadbush = {
  name = "Dead Bushes",
  description = "Once-thick bushes.",
  symbol = "œ",
  color={r=150,g=150,b=150,a=255},
  blocksSight = true,
  fireChance = 100,
  fireTime = 20,
  walkedOnNoFollow=true
}
function deadbush:new()
  local btype = random(1,3)
  self.image_name = "deadbush" .. btype
  self.walkedOnImage = "deadbush" .. btype .. "hiding"
end
function bush:enter(entity,fromX,fromY)
  if entity:is_type('flyer') == false and not entity:has_condition('inbushes') then
    entity:give_condition('inbushes',-1)
  end --end flyer if
end --end enter function
possibleFeatures['deadbush'] = deadbush

local vines = {
  name = "Vines",
  description = "Thick vines.",
  symbol = "§",
  color={r=0,g=150,b=0,a=255},
  blocksMovement = true,
  fireChance = 25,
}
possibleFeatures['vines'] = vines

local fountain = {
  name = "Magic Fountain",
  symbol = "{",
  useWalkedOnImage = true,
  description = "A magic fountain full of magic water. Who knows what the effects will be?",
  color={r=255,g=255,b=255,a=255},
  hazard = 1,
  shootThrough = true,
  new = function(self,_,x,y)
    local fountainType = random(1,6)
    if fountainType == 1 then
      self.image_base = "fountainred"
      self.image_name = "fountainred1"
      self.color={r=190,g=38,b=51,a=255}
    elseif fountainType == 2 then
      self.image_base = "fountaingreen"
      self.image_name = "fountaingreen1"
      self.color={r=68,g=137,b=26,a=255}
    elseif fountainType == 3 then
      self.image_base = "fountainblue"
      self.image_name = "fountainblue1"
      self.color={r=49,g=162,b=242,a=255}
    elseif fountainType == 4 then
      self.image_base = "fountainpurple"
      self.image_name = "fountainpurple1"
      self.color={r=108,g=39,b=206,a=255}
    elseif fountainType == 5 then
      self.image_base = "fountainyellow"
      self.image_name = "fountainyellow1"
      self.color={r=198,g=196,b=28,a=255}
    elseif fountainType == 6 then
      self.image_base = "fountainorange"
      self.image_name = "fountainorange1"
      self.color={r=206,g=123,b=39,a=255}
    end
  end,
  placed = function(self,onMap)
    local anim = Effect('featureanimator',{x=self.x,y=self.y,feature=self,image_base=self.image_base,image_max=3,sequence=true})
    self.animator = anim
    onMap:add_effect(anim,self.x,self.y)
  end,
  enter = function(self,entity,fromX,fromY)
    local text = ""
    if self.image_base == "fountainempty" or entity ~= player then
      return false
    elseif self.image_base == "fountainred" then
      local hp = tweak(entity:get_max_hp()/4)
      entity:updateHP(hp)
      text = text ..  ucfirst(entity:get_pronoun('n')) .. " regains " .. hp .. " HP!"
    elseif self.image_base == "fountaingreen" then
      entity:give_condition('regenerating',tweak(entity:get_max_hp()/2))
      text = text ..  ucfirst(entity:get_pronoun('n')) .. " starts regenerating HP!"
    elseif self.image_base == "fountainblue" then
      text = text .. "A magical shield forms into being around " .. entity:get_pronoun('o') .. "!"
      entity:give_condition('magicshield',tweak(25))
    elseif self.image_base == "fountainorange" then
      text = text ..  ucfirst(entity:get_pronoun('p')) .. " muscles bulge!"
      entity:give_condition('strengthened',tweak(25))
    elseif self.image_base == "fountainyellow" then
      text = text .. ucfirst(entity:get_pronoun('n')) .. " starts moving really quickly!"
      entity:give_condition('haste',tweak(25))
    elseif self.image_base == "fountainpurple" then
      text = text ..  ucfirst(entity:get_pronoun('n')) .. " becomes filled with greatness!"
      entity:give_condition('inspired',tweak(25))
    end
    self.image_base = "fountainempty"
    self.image_name = "fountainempty"
    self.color={r=150,g=150,b=150,a=255}
    if player:can_see_tile(self.x,self.y) then
      output:out(entity:get_name() .. " drinks from a magic fountain. " .. text)
      output:sound('gulp')
    end
    self.animator:delete()
    self.animator = nil
    return false
  end
}
possibleFeatures['fountain'] = fountain

local landmine = {
  name = "suspicious mound of dirt",
  symbol = "^",
  description = "There's a strange mound of dirt here. Maybe you shouldn't step on it.",
  color={r=98,g=73,b=22,a=255},
  hazard = 5,
  enter=function(self,entity,fromX,fromY)
    local moved = not (self.x == fromX and self.y == fromY)
    if entity and not moved then return end -- don't blow up a landmine if you haven't moved
    if entity and player:can_see_tile(entity.x,entity.y) then output:out(entity:get_name() .. " steps on a landmine!") end
    self.exploding = true
    for x = self.x-1,self.x+1,1 do
      for y=self.y-1,self.y+1,1 do
        currMap:add_effect(Effect('explosion'),x,y)
        output:sound('bomb')
        local creat = currMap:get_tile_creature(x,y)
        if creat and creat:is_type('flyer') == false then
          local dmg = creat:damage((creat.x == self.x and creat.y == self.y and 25 or 10),self.creator)
          if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " gets caught in the explosion and takes " .. dmg .. " damage.") end
        end --end creat if
        local mine = currMap:tile_has_feature(x,y,'landmine')
        if mine and not mine.exploding then
          if player:can_see_tile(mine.x,mine.y) then output:out("The explosion sets off another nearby landmine!") end
          mine:enter(nil)
        end
        --Blow up webs:
        local web = currMap:tile_has_feature(x,y,'web')
        if web then
          web:delete()
        end
        --Knock out walls
        if currMap[x][y] == "#" and x>1 and y>1 and x<currMap.width and y<currMap.height then
          currMap:change_tile(".",x,y)
          currMap:clear_all_pathfinders()
          --Refresh all images in a 3x3 grid around the explosion, so the walls match
          for nx=x-1,x+1,1 do
            for ny=y-1,y+1,1 do
              currMap:refresh_tile_image(nx,ny)
            end --end refresh fory
          end --end refresh forx
        end --end wall if
      end --end fory
    end --end forx
    self:delete()
  end
}
possibleFeatures['landmine'] = landmine

local coins = {
  name = "Coins",
  symbol = "$",
  description = "A small pile of shiny gold coins. For some bizarre reason, the living are irresistably attracted to them.",
  color={r=200,g=200,b=0,a=255},
  new = function(self)
    self.image_name = "coin" .. random(1,4)
  end
}
possibleFeatures['coins'] = coins

local keg = {
  name = "Cask",
  symbol ="0",
  description = "A wooden barrel filled with alcohol.",
  passableFor={ghost=true},
  color={r=133,g=87,b=0,a=255},
  fireChance = 50,
  blocksMovement = true,
  blocksSight=true,
  pushable=true,
  attackable=true,
}
function keg:damage(_,_,_,dtype)
  if dtype == "fire" then
    self:combust()
  else
    if player:can_see_tile(self.x,self.y) then output:sound('smash_wood') end
    currMap:add_feature(Feature('smashedwood'),self.x,self.y)
    currMap:add_feature(Feature('spilledbooze'),self.x,self.y)
    self:delete()
  end
end
function keg:combust(source)
  if player:can_see_tile(self.x,self.y) then
    output:out("A barrel explodes!")
    output:sound('explosion_barrel')
  end
  self:delete()
  for x = self.x-1,self.x+1,1 do
    for y = self.y-1,self.y+1,1 do
      currMap:add_effect(Effect('explosion'),x,y)
      local creat = currMap:get_tile_creature(x,y)
      if creat then
        local dmg = creat:damage(10,(source and source.creator or nil),"fire")
        if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " gets caught in the explosion and takes " .. dmg .. " damage.") end
      end --end creat if
      local barrel = currMap:tile_has_feature(x,y,'keg')
      if barrel and random(1,100) <= barrel.fireChance then
        barrel:combust(source)
      end --end barrel if
    end --end fory
  end --end forx
end
possibleFeatures['keg'] = keg

local barrel = {
  name = "Barrel",
  symbol ="0",
  description = "A wooden barrel.",
  passableFor={ghost=true},
  color={r=133,g=87,b=0,a=255},
  fireChance = 50,
  blocksMovement = true,
  blocksSight=true,
  pushable=true,
  attackable=true,
}
function barrel:damage(_,_,_,dtype)
  if dtype == "fire" then
    self:combust()
  else
    if player:can_see_tile(self.x,self.y) then output:sound('smash_wood') end
    currMap:add_feature(Feature('smashedwood'),self.x,self.y)
    self:delete()
  end
end
possibleFeatures['barrel'] = barrel

local crate = {
  name = "Crate",
  symbol = "#",
  description = "A wooden crate.",
  passableFor={ghost=true},
  color={r=133,g=87,b=0,a=255},
  fireChance = 50,
  blocksMovement = true,
  blocksSight=true,
  pushable=true,
  attackable=true,
  image_varieties=2
}
function crate:damage(_,_,_,dtype)
  if dtype == "fire" then
    self:combust()
  else
    if player:can_see_tile(self.x,self.y) then output:sound('smash_wood') end
    currMap:add_feature(Feature('smashedwood'),self.x,self.y)
    self:delete()
  end
end
possibleFeatures['crate'] = crate

local bed = {
  name = "Bed",
  symbol ="#",
  description = "It actually looks fairly comfortable.",
  color={r=255,g=0,b=255,a=255},
  fireChance = 50,
  fireTime = 25,
}
possibleFeatures['bed'] = bed

local chest = {
  name = "Chest",
  symbol ="&",
  description = "A locked chest. It might be filled with treature, but, being dead, you don't really have much interest in treasure.",
  color={r=255,g=0,b=255,a=255},
  fireChance = 10,
  fireTime = 15,
  attackable = true
}
function chest:new(items)
  if items then
    
  else
    
  end
end
function chest:damage(_,source)
  self:delete()
  if player:can_see_tile(self.x,self.y) then output:sound('smash_wood') end
  currMap:add_feature(Feature('smashedwood'),self.x,self.y)
end
possibleFeatures['chest'] = chest

local bookshelf = {
  name = "Bookshelf",
  symbol ="#",
  description = "A wooden bookshelf, filled with tasty, flammable books.",
  color={r=129,g=94,b=0,a=255},
  fireChance = 75,
  fireTime = 25,
  passableFor={ghost=true},
  blocksMovement = true,
  blocksSight=true,
  pushable=true,
  attackable=true,
  alwaysDisplay=true
}
function bookshelf:placed(map)
  if map[self.x][self.y-1] == "#" then
    self.image_name = "bookshelfn" .. random(1,2)
  elseif map[self.x][self.y+1] == "#" then
    self.image_name = "bookshelfs" .. random(1,2)
  elseif map[self.x-1][self.y] == "#" then
    self.image_name = "bookshelfw" .. random(1,2)
  elseif map[self.x+1][self.y] == "#" then
    self.image_name = "bookshelfe" .. random(1,2)
  end
end
function bookshelf:damage(_,_,_,dtype)
  if dtype == "fire" then
    self:combust()
  else
    if player:can_see_tile(self.x,self.y) then output:sound('smash_wood') end
    currMap:add_feature(Feature('smashedwood'),self.x,self.y)
    self:delete()
  end
end
possibleFeatures['bookshelf'] = bookshelf

local chair = {
  name = "Chair",
  symbol ="π",
  image_name = "chairn",
  description = "A simple wooden chair.",
  color={r=98,g=73,b=22,a=255},
  fireChance = 25,
}
possibleFeatures['chair'] = chair

local table = {
  name = "Table",
  symbol = "∏",
  tilemap=true,
  description = "A wooden table, covered in scratches and stains.",
  color={r=98,g=73,b=22,a=255},
  passableFor={flyer=true},
  impassable = true,
  shootThrough = true,
  fireChance = 15,
}
function table:refresh_image_name()
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'table') == false then directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'table') == false then directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'table') == false then directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'table') == false then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['table'] = table

local stonetable = {
  name = "Table",
  symbol = "∏",
  tilemap=true,
  description = "A stone table, covered in scratches and stains.",
  color={r=150,g=150,b=150,a=255},
  passableFor={flyer=true},
  impassable = true,
  shootThrough = true,
}
function stonetable:refresh_image_name()
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'stonetable') == false then directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'stonetable') == false then directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'stonetable') == false then directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'stonetable') == false then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['stonetable'] = stonetable

local altar = {
  name = "Atlar",
  symbol = "∏",
  description = "A stone altar",
  color={r=150,g=150,b=150,a=255},
  passableFor={flyer=true},
  impassable = true,
  shootThrough = true,
  castsLight=true,
  lightDist=1,
}
function altar:new(args)
  local altarType = ""
  local decoration = ""
  local types = {"","cloth","skull"}
  local decs = {"","blood","slime"}
 
  if args then
    if args['godName'] then
      self.description = self.description .. ". It is dedicated to " .. namegen:generate_god_name(args['godAdjectiveChance'],args['godName']) .. (args['noGodTitle'] and "" or ", the God of " .. ucfirst(namegen.lists.concepts[random(#namegen.lists.concepts)]))
    end
    if args['altarType'] then
      if args['altarType'] == "random" then
        altarType = types[random(#types)]
      elseif type(args['altarType']) == "string" then
        altarType = args['altarType']
      elseif type(args['altarType']) == "table" then
        altarType = get_random_element(args['altarType'])
      end
    end
    if args['decoration'] then
      if args['decoration'] == "random" then
        decoration = decs[random(#decs)]
      elseif type(args['decoration']) == "string" then
        decoration = args['decoration']
      elseif type(args['decoration']) == "table" then
        decoration = get_random_element(args['decoration'])
      end
    end
    self.image_name = "altar" .. (altarType ~= "" and "_" .. altarType or "") .. decoration
    
    if altarType == "cloth" then
      self.description = self.description .. ". It is covered in a white cloth"
      if self.decoration == "blood" then
        self.description = self.description .. ", which is stained with blood"
      elseif self.decoration == "slime" then
        self.description = self.description .. ", which is stained with slime"
      end
    else
      if decoration == "blood" then
        self.description = self.description .. ". It is stained with blood"
      elseif decoration == "slime" then
        self.description = self.description .. ". It is stained with slime"
      end
      if altarType == "skull" then
        self.description = self.description .. " and a skull sits in the center"
      end
    end --end altarType if
  end --end args if
  self.description = self.description .. ". A candle burns dimly on each side."
end
function altar:placed(onMap)
    local anim = Effect('featureanimator',{x=self.x,y=self.y,feature=self,noAnim=true,lightColors={{r=255,g=255,b=0,a=50},{r=200,g=200,b=0,a=50},{r=225,g=225,b=0,a=50}}})
    onMap:add_effect(anim,self.x,self.y)
  end
possibleFeatures['altar'] = altar

local pew = {
  name = "Pew",
  symbol ="π",
  image_name = "pewn",
  description = "A wooden church pew.",
  color={r=100,g=0,b=0,a=255},
  fireChance = 25,
}
possibleFeatures['pew'] = pew


local spilledbooze = {
  name = "Spilled Booze",
  symbol = "~",
  description = "No use crying over it, but be careful you don't slip and hurt yourself. Or come too close to it with a source of flame.",
  color={r=150,g=0,b=150,a=255},
  fireChance = 100,
  fireTime = 5,
  remove_on_cleanup=true,
}
function spilledbooze:new()
  self.angle = random(1,360)
  local boozenum = random(1,3)
  self.image_name = "spilledbooze" .. boozenum
end
function spilledbooze:enter(entity,fromX,fromY)
  local xMod,yMod = self.x-fromX,self.y-fromY
  if random(1,4) == 1 and not entity:is_type("flyer") then
    while xMod == 0 and yMod == 0 do
      xMod,yMod = random(-1,1),random(-1,1)
    end
    entity:give_condition('slipping',2)
    entity.slipX=xMod
    entity.slipY=yMod
  end --end if random
end
possibleFeatures['spilledbooze'] = spilledbooze

local brokenglass = {
  name = "broken glass",
  symbol = "^",
  description = "There are shards of broken glass all over the floor. Someone should really clean that up.",
  color={r=255,g=255,b=255},
  use_color_with_tiles=true,
  hazard = 10,
  remove_on_cleanup=true,
  enter = function(self,entity,fromX,fromY)
    local moved = not (self.x == fromX and self.y == fromY)
    if not moved then return end -- don't get damaged if you don't actually STEP on it but just stay there
    local dmg = entity:damage(tweak(3),self.creator)
    if player:can_see_tile(self.x,self.y) then output:out(entity:get_name() .. " steps on broken glass, taking " .. dmg .. " damage.") end
  end
}
possibleFeatures['brokenglass'] = brokenglass

local woodFloor = {
  name = "wooden floor",
  symbol = ".",
  description = "Wooden boards.",
  noDesc = true,
  color = {r=63,g=56,b=24,a=255},
}
possibleFeatures['woodfloor'] = woodFloor

local stoneFloor = {
  name = "stone floor",
  symbol = ".",
  description = "Stone tiles.",
  noDesc = true,
  color = {r=255,g=255,b=255,a=255},
}
possibleFeatures['stonefloor'] = stoneFloor

local steppingStone = {
  name = "stepping stone",
  symbol = ".",
  description = "A stone for stepping on.",
  noDesc = true,
  color = {r=255,g=255,b=255,a=255},
  new = function(self)
    self.angle = random(1,360)
  end
}
possibleFeatures['steppingstone'] = steppingStone

local ashpile = {
  name = "pile of ashes",
  symbol = "^",
  color = {r=100,g=100,b=100,a=255},
  description = "A pile of ashes.",
  remove_on_cleanup=true,
  new = function (self,data,x,y)
    local cdown = Effect('phoenixcountdown')
    cdown.ashpile = self
    currMap:add_effect(cdown,x,y)
    currMap:add_effect(Effect('fire',{x=self.x,y=self.y}),x,y)
  end
}
possibleFeatures['ashpile'] = ashpile

local minetracks = {
  name = "Minecart Tracks",
  description = "Tracks that minecarts drive on. Walking on them probably isn't a good idea.",
  symbol = "+",
  tilemap = true,
  tileDirection = "middle",
  hazard=1,
  directions = {n=true,s=true,e=true,w=true},
  color={r=63,g=56,b=24,a=255},
}
function minetracks:refresh_image_name()
  local directions = ""
  local dirs = {n=true,s=true,e=true,w=true}
  if currMap:tile_has_feature(self.x,self.y-1,'minetracks') == false then
    dirs['n'] = nil
    directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'minetracks') == false then
    dirs['s'] = nil
    directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'minetracks') == false then
    dirs['e'] = nil
    directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'minetracks') == false then
    dirs['w'] = nil
    directions = directions .. "w" end
    
  self.tileDirection = directions
  self.directions = dirs
  if directions == "" then
    self.tileDirection = "middle"
    self.symbol= "+"
  elseif directions == "n" or directions == "s" or directions == "ns" then
    self.symbol = "–"
  elseif directions == "e" or directions == "w" or directions == "ew" then
    self.symbol = "|"
  end
end --end get_image
possibleFeatures['minetracks'] = minetracks

local tnt = {
  name = "Explosive Barrel",
  symbol ="0",
  description = "A wooden barrel bearing the letters TNT. Humans didn't invent TNT until their Industrial Era, but dwarves love explosives so much they managed to invent it before inventing soap. They also managed to make it much more dangerous and explosive than should be possible.",
  passableFor={ghost=true},
  color={r=133,g=87,b=0,a=255},
  fireChance = 100,
  blocksMovement = true,
  pushable=true,
  attackable=true,
  alwaysDisplay=true,
}
function tnt:moves(x,y)
  if currMap:tile_has_feature(x,y,'lava') and not currMap:tile_has_feature(x,y,'minetracks') then
    self:combust()
  end
end
function tnt:damage(_,_,_,dtype)
  self:combust()
end
function tnt:combust(source)
  if player:can_see_tile(self.x,self.y) then
    output:out("A barrel explodes!")
    output:sound('explosion_barrel')
  end
  self:delete()
  for x = self.x-1,self.x+1,1 do
    for y = self.y-1,self.y+1,1 do
      currMap:add_effect(Effect('explosion'),x,y)
      if currMap[x][y] == "#" and x>1 and y>1 and x<currMap.width and y<currMap.height then
        currMap:change_tile(".",x,y)
        currMap:clear_all_pathfinders()
        --Refresh all images in a 3x3 grid around the explosion, so the walls match
        for nx=x-1,x+1,1 do
          for ny=y-1,y+1,1 do
            currMap:refresh_tile_image(nx,ny)
          end
        end
      end
      local creat = currMap:get_tile_creature(x,y)
      if creat then
        local dmg = creat:damage(tweak(25),(source and source.creator or nil),"explosive")
        if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " gets caught in the explosion and takes " .. dmg .. " damage.") end
        if creat.hp <= 0 and self.hitByCart then
          achievements:give_achievement('mines_special')
        end
      end --end creat if
      local barrel = currMap:tile_has_feature(x,y,'tnt')
      if barrel and random(1,100) <= barrel.fireChance then
        barrel:combust(source)
      end --end barrel if
    end --end fory
  end --end forx
end
possibleFeatures['tnt'] = tnt

local noisemaker = {
  name = "Noisemaker",
  symbol = "*",
  description = "A small device that continously emits distracting noises.",
  color={r=200,g=200,b=0,a=255},
  remove_on_cleanup=true,
}
possibleFeatures['noisemaker'] = noisemaker

local plantedtorch = {
  name = "Torch",
  symbol = "*",
  useWalkedOnImage = true,
  description = "A long torch stuck in the ground. Who put it here and why?",
  color={r=255,g=255,b=0,a=200},
  castsLight=true,
  lightDist=2,
  new = function(self,_,x,y)
    self.image_name = "plantedtorch" .. random(1,4)
  end,
  placed = function(self,onMap)
    local anim = Effect('featureanimator',{x=self.x,y=self.y,feature=self,image_base="plantedtorch",image_max=4,lightColors={{r=255,g=255,b=0,a=50},{r=200,g=200,b=0,a=50},{r=225,g=225,b=0,a=50}}})
    onMap:add_effect(anim,self.x,self.y)
  end
}
possibleFeatures['plantedtorch'] = plantedtorch

local walltorch = {
  name = "Torch",
  symbol = "*",
  useWalkedOnImage = true,
  description = "A torch stuck in the wall.",
  color={r=255,g=255,b=0,a=200},
  castsLight=true,
  lightDist=2,
  animation_frames=4,
  placed = function(self,onMap)
    onMap = onMap or currMap
    self.direction = ""
    if onMap[self.x][self.y+1] == "." and onMap[self.x][self.y] == "#" then
      self.direction = "n"
    elseif onMap[self.x+1][self.y] == "#" then
      self.direction = "e"
    elseif onMap[self.x-1][self.y] == "#" then
      self.direction = "w"
    end
    self.image_name = "walltorch" .. self.direction .. random(1,4)
    local anim = Effect('featureanimator',{x=self.x,y=self.y,feature=self,image_base="walltorch" .. self.direction,image_max=4,lightColors={{r=255,g=255,b=0,a=50},{r=200,g=200,b=0,a=50},{r=225,g=225,b=0,a=50}}})
    onMap:add_effect(anim,self.x,self.y)
  end
}
possibleFeatures['walltorch'] = walltorch

local skullcandle = {
  name = "Skullcandle",
  symbol = "8",
  description = "A candle stuck in a skull. Gothic.",
  color={r=255,g=255,b=0,a=200},
  castsLight=true,
  lightDist=2,
  new = function(self,_,x,y)
    self.image_name = "skullcandle" .. random(1,4)
  end,
  placed = function(self,onMap)
    local anim = Effect('featureanimator',{x=self.x,y=self.y,feature=self,image_base="skullcandle",image_max=5,lightColors={{r=255,g=255,b=0,a=50},{r=200,g=200,b=0,a=50},{r=225,g=225,b=0,a=50}}})
    onMap:add_effect(anim,self.x,self.y)
  end
}
possibleFeatures['skullcandle'] = skullcandle

local candelabra = {
  name = "Candelabra",
  symbol = "¥",
  blocksMovement=true,
  passableFor={ghost=true},
  description = "A freestanding candelabra.",
  color={r=255,g=255,b=0,a=200},
  castsLight=true,
  lightDist=2,
  new = function(self,_,x,y)
    self.image_name = "candelabra" .. random(1,5)
  end,
  placed = function(self,onMap)
    local anim = Effect('featureanimator',{x=self.x,y=self.y,feature=self,image_base="candelabra",image_max=5,lightColors={{r=255,g=255,b=0,a=50},{r=200,g=200,b=0,a=50},{r=225,g=225,b=0,a=50}}})
    onMap:add_effect(anim,self.x,self.y)
  end
}
possibleFeatures['candelabra'] = candelabra

local candles = {
  name = "Candles",
  symbol = "*",
  blocksMovement=false,
  description = "A bunch of candles, sitting on the floor.",
  color={r=255,g=255,b=0,a=200},
  castsLight=true,
  lightDist=2,
  new = function(self,_,x,y)
    self.image_name = "candles" .. random(1,4)
  end,
  placed = function(self,onMap)
    local anim = Effect('featureanimator',{x=self.x,y=self.y,feature=self,image_base="candles",image_max=4,lightColors={{r=255,g=255,b=0,a=50},{r=200,g=200,b=0,a=50},{r=225,g=225,b=0,a=50}}})
    onMap:add_effect(anim,self.x,self.y)
  end
}
possibleFeatures['candles'] = candles

local campfire = {
  name = "Campfire",
  symbol = "*",
  useWalkedOnImage = true,
  hazard = 1000,
  description = "A cheerful roaring campfire.",
  color={r=255,g=255,b=0,a=200},
  castsLight=true,
  lightDist=3,
  new = function(self,_,x,y)
    self.image_name = "campfire" .. random(1,4)
  end,
  placed = function(self,onMap)
    local anim = Effect('featureanimator',{x=self.x,y=self.y,feature=self,image_base="campfire",image_max=4,lightColors={{r=255,g=255,b=0,a=50},{r=200,g=200,b=0,a=50},{r=225,g=225,b=0,a=50}}})
    onMap:add_effect(anim,self.x,self.y)
  end
}
function campfire:advance()
  --Burn creatures on tile:
  local creat = currMap:get_tile_creature(self.x,self.y)
  if (creat and creat.fireImmune ~= true and not creat:has_condition('onfire') and not creat:is_type('flyer')) then
    local dmg = creat:damage(tweak(5),self.creator,"fire")
    if dmg > 0 and player:can_see_tile(self.x,self.y) then output:out(creat:get_name() .. " takes " .. dmg .. " damage from fire.") end
    if (dmg> 0 and random(1,100) >= 60) then
      if creat.conditions['onfire'] == nil and player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " catches on fire!") end
      creat:give_condition('onfire',random(1,5))
    end
    end
  end
possibleFeatures['campfire'] = campfire

local bedroll = {
  name = "Bedroll",
  symbol ="#",
  description = "It actually looks fairly comfortable.",
  color={r=138,g=88,b=40,a=255},
  fireChance = 25,
  fireTime = 3,
}
possibleFeatures['bedroll'] = bedroll

local pentagram = {
  name = "Pentagram",
  symbol = "®",
  description = "Someone's used some kind of red substance to draw a star on the ground. A red star...could they be communists?",
  color={r=255,g=0,b=0,a=255},
  use_color_with_tiles = true,
}
possibleFeatures['pentagram'] = pentagram

local gorespike = {
  name = "Impaled Meat",
  useWalkedOnImage = true,
  description = "Some unidentifiable flesh is impaled on a spike here.",
  symbol = "7",
  color={r=100,g=0,b=0},
  alwaysDisplay = true,
}
possibleFeatures['gorespike'] = gorespike

local idol = {
  name = "Demonic Idol",
  useWalkedOnImage = true,
  description = "A demonic idol. Your third eye can smell a great deal of power coming off of it.",
  symbol = "!",
  color={r=133,g=129,b=105,a=255},
  blocksMovement = true,
  alwaysDisplay = true,
  attackable = true
}
function idol:damage(_,source)
    self:delete()
    output:sound('stone_explode')
end
possibleFeatures['idol'] = idol

local giantpentagram = {
    name = "Giant Pentagram",
    description = "A giant pentagram drawn on the ground.",
    symbol="®",
    color={r=255,g=0,b=0},
  tilemap=true,
  tileDirection = "nsew",
}
function giantpentagram:refresh_image_name()
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'giantpentagram') == false then directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'giantpentagram') == false  then directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'giantpentagram') == false  then directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'giantpentagram') == false  then directions = directions .. "w" end
  if directions == "" then self.tileDirection = "middle" else self.tileDirection = directions end
end --end get_image
possibleFeatures['giantpentagram'] = giantpentagram

local brickwall = {
  name = "Brick Wall",
  noDesc = true,
  symbol = "#",
  color = {r=255,g=255,b=255}
}
function brickwall:refresh_image_name()
  if (currMap:in_map(self.x,self.y+1) and currMap[self.x][self.y+1] == "#") or currMap:tile_has_feature(self.x,self.y+1,'brickwall') then self.image_name = "brickwallplain" end
end
possibleFeatures['brickwall'] = brickwall

local vase = {
  name = "Vase",
  symbol = "µ",
  description = "A priceless antique vase.",
  color = {r=0,g=0,b=255,a=255},
  blocksMovement=true,
  passableFor={ghost=true},
  blocksSight = true,
  attackable=true,
  new = function(self,args)
    if type(args) == "table" then
      if args.image_base then
        self.image_base = args.image_base
        self.image_name = args.image_base .. (args.image_num and random(1,args.image_num) or "")
      end
      if args.broken_num then self.broken_num = args.broken_num end
    end
  end,
  damage = function(self,_,attacker)
    if player:can_see_tile(self.x,self.y) then
      output:out((attacker.exploded and "A flying chunk" or attacker:get_name()) .. " breaks a vase.")
      output:sound('vase_smash')
    end
    for x=self.x-10,self.x+10,1 do
      for y =self.y-10,self.y+10,1 do
        local creat = currMap:get_tile_creature(x,y)
        if creat and attacker then
          creat:notice(attacker)
        end --end creat if
      end --end fory
    end --end forx
    currMap:add_feature(Feature('brokenvase',{image_base = self.image_base,broken_num = self.broken_num}),self.x,self.y)
    self:delete()
end
}
possibleFeatures['vase'] = vase

local brokenvase = {
  name = "Broken Shards of Pottery",
  symbol = "*",
  description = "Someone broke something.",
  color = {r=0,g=0,b=255,a=255},
  remove_on_cleanup=true,
  new = function(self,args)
    if type(args) == "table" and args.image_base then
      self.image_name = args.image_base .. "broken" .. (args.broken_num and random(1,args.broken_num) or "")
    end
  end
}
possibleFeatures['brokenvase'] = brokenvase

local smashedwood = {
  name = "Smashed Wood",
  symbol = "*",
  description = "Someone smashed something something.",
  color={r=129,g=94,b=0,a=255},
  image_varieties=3,
  remove_on_cleanup=true,
}
possibleFeatures['smashedwood'] = smashedwood

local obelisk = {
  name = "Obelisk",
  symbol = "∆",
  useWalkedOnImage = true,
  blocksMovement=true,
  passableFor={ghost=true},
  description = "A creepy obelisk.",
  color={r=255,g=255,b=255,a=255},
  new = function(self,glowing,x,y)
    if glowing then
      self.castsLight=true
      self.lightDist=2
      self.image_name = "glowingobelisk" .. random(1,6)
    end
  end,
  placed = function(self,onMap)
    if self.castsLight then
      local anim = Effect('featureanimator',{x=self.x,y=self.y,speed=.5,feature=self,image_base ="glowingobelisk",image_max=6,lightColorsMatch=true,lightColors={{r=100,g=100,b=100,a=100},{r=100,g=100,b=0,a=100},{r=100,g=0,b=0,a=100},{r=100,g=0,b=255,a=100},{r=0,g=100,b=100,a=100},{r=0,g=100,b=0,a=100}}})
      onMap:add_effect(anim,self.x,self.y)
    end
  end
}
possibleFeatures['obelisk'] = obelisk

local crystal = {
  name = "Glowing Crystal",
  symbol = "∆",
  useWalkedOnImage = true,
  blocksMovement=true,
  passableFor={ghost=true},
  description = "A giant glowing crystal.",
  image_name="crystal1",
  color={r=0,g=255,b=255,a=255},
  castsLight=true,
  lightDist=2,
  placed = function(self,onMap)
    if self.castsLight then
      local anim = Effect('featureanimator',{x=self.x,y=self.y,speed=.5,feature=self,image_base ="crystal" .. random(1,2) .. "_",image_max=3,sequence=true,reverse=true,lightColorsMatch=true,lightColors={{r=0,g=100,b=100,a=100},{r=0,g=150,b=150,a=100},{r=0,g=200,b=200,a=100}}})
      onMap:add_effect(anim,self.x,self.y)
    end
  end
}
possibleFeatures['crystal'] = crystal

local lectern = {
  name = "Lectern",
  symbol = "¥",
  useWalkedOnImage = true,
  blocksMovement=true,
  passableFor={ghost=true},
  description = "A lectern, on which sits a heavy book that's undoubtedly very boring.",
  color={r=255,g=255,b=255,a=255}
}
function lectern:placed(map)
  local bookType = random(1,4)
  if map.mapID == "eldritchcity" then bookType = 1
  elseif map.mapID == "demonruins" then bookType = 2
  elseif map.mapID == "temple" then bookType = 4 end
 
  if bookType == 1 then --tomb of forbidden knowledge
    self.name = namegen.lists.bookNames[random(#namegen.lists.bookNames)] .. " of Forbidden Knowledge"
    self.description = "A lectern, on which sits a heavy book that contains Terrible Secrets Man Was Not Meant to Know (No, Nor Woman Neither). Unfortunately, it's written in Ancient Cthulian, and you didn't take Ancient Cthulian as your foreign language in high school because you're not a gigantic nerd."
  elseif bookType == 2 then --demonic book
    self.name = namegen.lists.bookNames[random(#namegen.lists.bookNames)] .. " of Demonic Secrets"
    self.description = "A lectern, on which sits a heavy book containing blasphemous knowledge obtained from demons. The words are written in human blood (of course), which is dramatic but tends to smudge a lot, meaning most of the demonic secrets in the book are basically unreadable."
  elseif bookType == 3 then --magic book
    self.name = namegen:generate_book_name()
    self.description = "A lectern, on which sits a book filled with magickal secrets. If you were a wizard, you'd be able to get all up in those secrets. You're not a wizard though, so it's pretty much worthless to you."
  elseif bookType == 4 then --holy light book
    self.name = "The Book of Sweetness and Light"
    self.description = "A lectern, on which sits the holy text of the Church of Sweetness and Light. You don't really feel like reading it; religion holds little interest for someone who's already dead."
  end
end
possibleFeatures['lectern'] = lectern

local firemaker = {
  name = "firemaker",
  symbol = "",
  noDesc = true,
  noDisp = true,
  color = {r=0,g=0,b=0,a=0},
  description = "An invisible feature that turns into fire. Used for demon deaths.",
  new = function (self,data,x,y)
    currMap:add_effect(Effect('fire',{x=self.x,y=self.y}),x,y)
    self:delete()
  end
}
possibleFeatures['firemaker'] = firemaker

local lightflash = {
  name = "flash of light",
  symbol = "",
  noDesc = true,
  noDisp = true,
  color = {r=0,g=0,b=0,a=0},
  description = "An invisible feature that turns into a flash of light. Used for angel deaths.",
  new = function (self,data,x,y)
    currMap:add_effect(Effect('animation','holydamage',5,self,{r=255,g=255,b=0}),x,y)
    self:delete()
  end
}
possibleFeatures['lightflash'] = lightflash

local darkflash = {
  name = "flash of darkness",
  symbol = "",
  noDesc = true,
  noDisp = true,
  color = {r=0,g=0,b=0,a=0},
  description = "An invisible feature that turns into a flash of darkness. Used for spooky deaths.",
  new = function (self,data,x,y)
    currMap:add_effect(Effect('animation','unholydamage',5,self,{r=150,g=0,b=150}),x,y)
    self:delete()
  end
}
possibleFeatures['darkflash'] = darkflash

local magicflash = {
  name = "flash of magic",
  symbol = "",
  noDesc = true,
  noDisp = true,
  color = {r=0,g=0,b=0,a=0},
  description = "An invisible feature that turns into a flash of magic. Used for magical deaths.",
  new = function (self,data,x,y)
    currMap:add_effect(Effect('animation','magicdamage',5,self,{r=255,g=255,b=0}),x,y)
    self:delete()
  end
}
possibleFeatures['magicflash'] = magicflash

local cage = {
  name = "Cage",
  symbol ="Œ",
  description = "A metal cage.",
  passableFor={ghost=true},
  color={r=150,g=150,b=150,a=255},
  blocksMovement = true,
  pushable=true,
}
possibleFeatures['cage'] = cage

local archerytarget = {
  name = "Archery Target",
  symbol ="ø",
  description = "A big target, used to practice archery. Whoever was using it wasn't very good.",
  passableFor={ghost=true},
  color={r=255,g=255,b=255,a=255},
  blocksMovement = true,
  image_varieties=3,
  attackable=true,
  hp=100000
}
possibleFeatures['archerytarget'] = archerytarget

local trainingdummy = {
  name = "Training Dummy",
  symbol ="4",
  description = "A stuffed leather dummy in the vague shape of a person. It's used by other dummies to get good at hitting stuff.",
  passableFor={ghost=true},
  color={r=164,g=100,b=34,a=255},
  blocksMovement = true,
  attackable=true,
  hp=100000
}
possibleFeatures['trainingdummy'] = trainingdummy

local weaponrack = {
  name = "Weapon Rack",
  symbol ="λ",
  description = "A wooden rack holding weapons. They're of pretty poor quality, though. A lot of them are even rusty.",
  passableFor={ghost=true},
  color={r=164,g=100,b=34,a=255},
  image_varieties=3
}
possibleFeatures['weaponrack'] = weaponrack

local anvil = {
  name = "Anvil",
  symbol ="ń",
  description = "A heavy anvil",
  passableFor={flyer=true},
  color={r=66,g=66,b=66,a=255},
}
possibleFeatures['anvil'] = anvil

local torturedevice = {
  name = "Torture Device",
  symbol ="8",
  description = "A horrible device used to do really mean things to people.",
  passableFor={ghost=true},
  color={r=255,g=255,b=255,a=255},
  blocksMovement = true,
  image_varieties=3,
}
possibleFeatures['torturedevice'] = torturedevice

local fence = {
  name = "Chainlink Fence",
  symbol = "ø",
  description = "A metal fence.",
  passableFor={ghost=true},
  color={r=150,g=150,b=150,a=255},
  blocksMovement = true,
  attackable = true,
  tilemap = true,
  tileDirection = "middle"
}
function fence:refresh_image_name()
  local directions = ""
  if currMap:tile_has_feature(self.x,self.y-1,'fence') == false then
    directions = directions .. "n" end
  if currMap:tile_has_feature(self.x,self.y+1,'fence') == false then
    directions = directions .. "s" end
  if currMap:tile_has_feature(self.x+1,self.y,'fence') == false then
    directions = directions .. "e" end
  if currMap:tile_has_feature(self.x-1,self.y,'fence') == false then
    directions = directions .. "w" end
    
  self.tileDirection = directions
  if directions == "" then
    self.tileDirection = "middle"
    self.symbol= "ø"
  elseif directions == "n" or directions == "s" or directions == "ns" then
    self.symbol = "–"
  elseif directions == "e" or directions == "w" or directions == "ew" then
    self.symbol = "|"
  end
end --end get_image
possibleFeatures['fence'] = fence

local valhalla = {
  name = "Portal to Valhalla",
  description = "A gateway to the afterlife of true heroes.",
  symbol = "0",
  alwaysDisplay=true,
  color={r=255,g=0,b=255,a=255},
  actions={exit={text="Ascend",description="Ascend to valhalla."}},
  castsLight = true,
  lightDist=1,
}
function valhalla:action(entity,action)
  win()
end
possibleFeatures['valhalla'] = valhalla

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
  remove_on_cleanup=true,
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
    if not creature:is_type('bloodless') then
      if not self.actions then self.actions = {} end
      self.actions['extractblood'] = {text="Extract blood from " .. creature.name .. " corpse",description="Extract blood from a corpse."}
      self.actions['drainblood'] = {text="Drain blood from " .. creature.name .. " corpse",description="Extract blood from a corpse."}
    end
  end
}
function corpse:action_requires(user,action)
  if action == 'extractblood' then
    if not self.bloodless and user:has_item('bloodextractor') then
      return true
    end
    return false
  elseif action == "drainblood" then
    if not self.bloodless and user:has_spell('vampirism') then
      return true
    end
    return false
  end
end
function corpse:action(entity,action)
  if action == "extractblood" and not self.bloodless then
    local extractor = entity:has_item('bloodextractor')
    if extractor then return extractor:use(self,entity) end
  elseif action == "drainblood" and not self.bloodless and entity:has_spell('vampirism') then
    local hp = self.creature.level
    entity:updateHP(hp)
    if entity.extra_stats.blood then
      entity.extra_stats.blood.value = math.min(entity.extra_stats.blood.value+hp,entity.extra_stats.blood.max)
    end
    self.bloodless = true
    if entity == player then
      output:out("You drain cold, congealed blood from the " .. self.creature.name .. " corpse. Gross and unsatisfying, but you do regain " .. hp .. " HP.")
    end
  end
end
possibleFeatures['corpse'] = corpse

local chunk = {
  name = "chunks",
  symbol = ".",
  description = "The bloody remains of some unfortunate creature.",
  image_name = "whitechunk1",
  color={r=255,g=0,b=0,a=255},
  use_color_with_tiles=true,
  remove_on_cleanup=true,
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