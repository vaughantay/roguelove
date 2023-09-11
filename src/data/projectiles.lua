projectiles = {}

local bone = {
  name = "bone",
  description = "A bone, not terribly aerodynamic.",
  symbol = "|",
  color={r=255,g=255,b=255,a=255},
  damage = 2,
  time_per_tile = .01,
  miss_item="bone",
  update = function(self,dt)
    if self.symbol == "/" then self.symbol = "-"
    elseif self.symbol == "-" then self.symbol = "\\"
    elseif self.symbol == "\\" then self.symbol = "|"
    elseif self.symbol == "|" then self.symbol = "/" end
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end
}
projectiles['bone'] = bone

local skull = {
  name = "skull",
  description = "A skull. Spooky!",
  symbol = "*",
  color={r=255,g=255,b=255,a=255},
  damage = 2,
  time_per_tile = .01,
  hits = function(self,target)
    if target.baseType == "creature" and target:is_type('intelligent') then
      target.fear = target.fear+10
    end
    Projectile.hits(self,target,true) --just do a regular hit
  end
}
projectiles['skull'] = skull

local skellibone = {
  name = "bonerang",
  description = "A bone thrown by a skeleton.",
  symbol = "|",
  color={r=200,g=200,b=200},
  damage = 4,
  time_per_tile = .02,
  hit_sound="hit_stab",
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
  end,
  update = function(self,dt)
    if self.symbol == "/" then self.symbol = "-"
    elseif self.symbol == "-" then self.symbol = "\\"
    elseif self.symbol == "\\" then self.symbol = "|"
    elseif self.symbol == "|" then self.symbol = "/" end
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end,
  hits = function(self,target)
    if target.x == self.source.x and target.y == self.source.y then --if you're hitting the originator
      self:delete()
    elseif target.baseType == "creature" then --if it's not the source
      Projectile.hits(self,target,true) --just do a regular hit
    else --didn't hit a creature, turn around
      self.target = self.source
      self.path = nil
      self:advance()
    end
  end
}
projectiles['skellibone'] = skellibone

local boneshard = {
  name = "bone shard",
  description = "A bone shard from an exploding skeleton.",
  image_name="skellibone",
  neverInstant=true,
  symbol = "|",
  color={r=200,g=200,b=200},
  damage = 2,
  time_per_tile = .05,
  hit_sound = 'hit_stab',
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
  end,
  update = function(self,dt)
    if self.symbol == "/" then self.symbol = "-"
    elseif self.symbol == "-" then self.symbol = "\\"
    elseif self.symbol == "\\" then self.symbol = "|"
    elseif self.symbol == "|" then self.symbol = "/" end
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end
}
projectiles['boneshard'] = boneshard

local bullet = {
  name = "bullet",
  description = "A bullet.",
  symbol = ".",
  angled = true,
  color={r=50,g=50,b=50,a=255},
  damage = 3,
  time_per_tile = .01,
  extra_damage_per_level=2.5,
  hit_sound = 'hit_stab'
}
projectiles['bullet'] = bullet

local dart = {
  name = "dart",
  description = "A dart.",
  symbol = "/",
  angled = true,
  color={r=50,g=50,b=50,a=255},
  damage = 1,
  extra_damage_per_level=1,
  time_per_tile = .01,
  hit_sound = 'hit_stab',
  miss_item="dart",
}
projectiles['dart'] = dart

local dagger = {
  name = "dagger",
  description = "A dagger.",
  symbol = "/",
  angled = true,
  color={r=50,g=50,b=50,a=255},
  damage = 3,
  time_per_tile = .01,
  hit_sound = 'hit_stab',
  miss_item="dagger", --This should be replaced by the actual dagger when it's thrown though
  miss_item_on_hit=true
}
projectiles['dagger'] = dagger

local bomb = {
  name = "bomb",
  description = "A bomb!",
  symbol = "*",
  color={r=200,g=200,b=200},
  damage = 2,
  time_per_tile = .01,
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
  end,
  update = function(self,dt)
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end,
  hits = function(self,target)
    for x = target.x-1,target.x+1,1 do
      for y = target.y-1,target.y+1,1 do
        currMap:add_effect(Effect('explosion'),x,y)
        output:sound('bomb')
        local creat = currMap:get_tile_creature(x,y)
        if creat then
          local dmg = creat:damage(10,self.source,"explosive")
          if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " gets caught in the explosion and takes " .. dmg .. " damage.") end
        end
        local mine = currMap:tile_has_feature(x,y,'landmine')
        if mine and not mine.exploding then
          if player:can_see_tile(mine.x,mine.y) then output:out("The explosion sets off a nearby landmine!") end
          mine:enter(nil)
        end
        local web = currMap:tile_has_feature(x,y,'web')
        if web then
          web:delete()
        end
      end --end fory
    end --end forx
    self:delete()
  end
}
projectiles['bomb'] = bomb

local thorn = {
  name = "thorn",
  description = "A triffid thorn.",
  symbol = "^",
  color={r=100,g=100,b=50,a=255},
  damage = 3,
  time_per_tile = .01,
  hit_sound = 'hit_stab',
}
projectiles['thorn'] = thorn
function thorn:hits(target)
  Projectile.hits(self,target,true)
  if target.baseType == "creature" then
    target:give_condition('poisoned',3)
  end --end creature if
end --end hits function

local smallfireball = {
  name = "fireball",
  description = "A small fireball.",
  symbol = "*",
  angled = true,
  color={r=150,g=0,b=0,a=255},
  damage = 7,
  damage_type="fire",
  time_per_tile = .01,
  extra_damage_per_level=2
}
function smallfireball:update(dt)
  local gas = currMap:tile_has_effect(self.x,self.y,'methane')
  if gas then
    gas.exploding = true
  end
  return Projectile.update(self,dt,true)
end
projectiles['smallfireball'] = smallfireball

local explodingfireball = {
  name = "explodingfireball",
  description = "A small fireball that isn't going to stay very small.",
  image_name = "smallfireball",
  symbol = "*",
  angled = true,
  color={r=150,g=0,b=0,a=255},
  time_per_tile = .01
}
function explodingfireball:hits(target)
  local fball = Effect('fireball')
  fball.creator = self.source
  fball.reproduceCountdown = .1
  currMap:add_effect(fball,target.x,target.y)
  fball:refresh_image_name()
  for x=target.x-1,target.x+1,1 do
    for y=target.y-1,target.y+1,1 do
      if (currMap[x][y] ~= "#") then
        local creat = currMap:get_tile_creature(x,y)
        if (creat) then
          local dmg = creat:damage(random(10,15),caster,"explosive")
          if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " gets caught in the blast and takes " .. dmg .. " damage.") end
          if (random(1,5) == 1) then
            creat:give_condition('onfire',tweak(5))
          end
        end --end creat
        for _,feat in pairs(currMap:get_tile_features(self.x,self.y)) do
          if feat.fireChance and random(1,100) <= feat.fireChance then
            feat:combust()
          end --end firechance if
        end --end feature for
      end --end if currmap
    end --end fory
  end --end forx
  if player:can_see_tile(self.x,self.y) then output:sound('explosion_fireball') end
  self:delete()
end
projectiles['explodingfireball'] = explodingfireball

local meteor = {
  name = "meteor",
  description = "A small fireball. That isn't going to stay very small...",
  image_name = "meteor",
  symbol = "*",
  angled = true,
  color={r=150,g=150,b=150,a=255},
  time_per_tile = .01,
  damage=10
}
function meteor:hits(target)
  if player:can_see_tile(target.x,target.y) then
    output:sound('bomb')
  end
  --Explosion and chance of combustion near target
  for x=target.x-1,target.x+1,1 do
    for y=target.y-1,target.y+1,1 do
      currMap:add_effect(Effect('explosion'),x,y)
      if x ~= target.x or y ~= target.y then
        for _,feat in pairs(currMap:get_tile_features(target.x,target.y)) do
          if feat.fireChance and random(1,100) <= feat.fireChance then
            feat:combust()
          end --end firechance if
        end --end feature for
      end --end check x and y
    end --end fory
  end --end forx
  
  --100% chance of combustion at target
  for _,feat in pairs(currMap:get_tile_features(target.x,target.y)) do
    if feat.fireChance then
      feat:combust()
    end --end firechance if
  end --end feature for
  Projectile.hits(self,target,true)
end
projectiles['meteor'] = meteor

local boozefirebreath = {
  name = "boozy firebreath",
  description = "A spew of alcohol someone spit out of their mouth and lit on fire. Incredibly dangerous and stupid.",
  symbol = "&",
  angled = true,
  damage = 15,
  damage_type = "fire",
  hit_conditions={{condition='onfire',turns=2,chance=33}},
  time_per_tile = .1,
  color={r=255,g=200,b=0,a=150}
}
function boozefirebreath:new(source,target)
  self.creator = source
  self.range = random(0,2)
  local xMod,yMod = get_unit_vector(source.x,source.y,target.x,target.y)
  local xPossibility = (xMod ~= 0 and (xMod == 1 and "<" or ">") or false)
  local yPossibility = (yMod ~= 0 and (yMod == 1 and "^" or "V") or false)
  if xPossibility and yPossibility then
    self.symbol = (random(1,2) == 1 and xPossibility or yPossibility)
  elseif xPossibility and not yPossibility then self.symbol = xPossibility
  elseif yPossibility and not xPossibility then self.symbol = yPossibility
  end
  return {x=target.x+(xMod*self.range),y=target.y+(yMod*self.range)}
end
function boozefirebreath:update(dt)
  if self.timer <= 0 then
    for _,feat in pairs(currMap:get_tile_features(self.x,self.y)) do
      if feat.fireChance and random(1,100) <= feat.fireChance then
        feat:combust()
      end
    end
  end --end timer if
  return Projectile.update(self,dt,true)
end
projectiles['boozefirebreath'] = boozefirebreath

local electroplasm = {
  name = "electroplasm",
  description = "A small blast of electroplasm.",
  image_name="smallblastblue",
  symbol = "*",
  angled = true,
  color={r=178,g=220,b=239,a=255},
  damage = 7,
  damage_type="electric",
  time_per_tile = .01,
  extra_damage_per_level=2
}
projectiles['electroplasm'] = electroplasm

local poisondart = {
  name = "poison dart",
  description = "A dart dipped in poison.",
  symbol = "/",
  angled = true,
  color = {r=0,g=75,b=0},
  time_per_tile = .02,
  hit_sound = 'hit_stab'
}
function poisondart:hits(target)
  if target.baseType == "creature" then
    target:give_condition('poisoned',3)
    if target:does_notice(self.source) == false and random(1,4) == 1 then
      target:notice(self.source)
    end --end notices if
  end --end creature if
  self:delete()
  output:sound('hit_stab')
end --end hits function
projectiles['poisondart'] = poisondart

local tranqdart = {
  name = "tranquilizer dart",
  description = "A dart filled with tranquilizer.",
  symbol = "/",
  angled = true,
  color = {r=200,g=200,b=255,a=255},
  time_per_tile = .02,
  hit_sound = 'hit_stab'
}
function tranqdart:hits(target)
  if target.baseType == "creature" then
    target:give_condition('tranquilized',25)
  end --end creature if
  self:delete()
  output:sound('hit_stab')
end --end hits function
projectiles['tranqdart'] = tranqdart

local healthsyringe = {
  name = "healing syringe",
  description = "A dart filled with healthy stuff.",
  symbol = "/",
  angled = true,
  color = {r=224,g=111,b=139,a=255},
  use_color_with_tiles=true,
  time_per_tile = .01,
  hit_sound = 'hit_stab',
  image_name="syringe"
}
function healthsyringe:hits(target)
  if target.baseType == "creature" then
    local caster = self.source
    local amt = math.max(5,math.ceil(target:get_max_hp() *.05))
    if player:can_see_tile(caster.x,caster.y) then
      output:out(caster:get_name() .. " heals " .. target:get_name() .. " for " .. amt .. " damage.")
      output:sound('heal_other')
    end
    target:updateHP(amt)
    local enemy = target:is_enemy(caster)
    local shitlist = target.shitlist[caster]
    if enemy and not shitlist and random(1,100) < 50 then --50% chance of currently-non-hostile to ignore caster
      target:ignore(caster)
    elseif shitlist and random(1,100) < 10 then --10% chance of currently hostile to ignore caster
      target:ignore(caster)
    end
    if not shitlist and target.master == nil and target.faction ~= "chaos" and (caster.faction == nil or target.enemy_factions == nil or not in_table(caster.faction,target.enemy_factions)) and random(1,100) < 10 then --10% chance of currently non-hostile to become thrall of caster if they're not in an enemy faction
      target:become_thrall(caster)
    end
  end --end creature if
  self:delete()
end --end hits function
projectiles['healthsyringe'] = healthsyringe

local stimsyringe = {
  name = "stim syringe",
  description = "A dart filled with stimulating stuff.",
  symbol = "/",
  angled = true,
  color = {r=247,g=245,b=166,a=255},
  use_color_with_tiles=true,
  time_per_tile = .01,
  hit_sound = 'hit_stab',
  image_name="syringe"
}
function stimsyringe:hits(target)
  if target.baseType == "creature" then
    target:give_condition('enraged',15,self.source)
  end --end creature if
  self:delete()
end --end hits function
projectiles['stimsyringe'] = stimsyringe

local zombait = {
  name = "bait",
  description = "A hunk of rotten meat. Delicious to undead and animals.",
  symbol = "*",
  color={r=150,g=0,b=0,a=255},
  time_per_tile = .02,
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
  end,
  hits = function(self,target)
    local creat = currMap:get_tile_creature(target.x,target.y)
    if creat then
      if player:can_see_tile(target.x,target.y) then output:sound('splat_hits_creature') end
      creat:give_condition('zombait',15)
    else 
      if player:can_see_tile(target.x,target.y) then output:sound('splat_hits_ground') end
      local zb = Effect('zombait')
      local zbf = Feature('zombait',nil,target.x,target.y)
      zbf.angle = self.angle
      zb.bait = zbf
      currMap:add_feature(zbf,target.x,target.y)
      currMap:add_effect(zb,target.x,target.y)
    end
    self:delete()
  end, --end hits()
  update = function(self,dt)
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end
}
projectiles['zombait'] = zombait

local soul = {
  name = "soul",
  description = "A glowing soul. Delicious to demons, you monster.",
  symbol = "*",
  color={r=200,g=255,b=255,a=125},
  time_per_tile = .5,
  miss_sound="holydamage",
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
  end,
  hits = function(self,target)
    local creat = currMap:get_tile_creature(target.x,target.y)
    if creat then
      if creat:is_type('demon') then
        if self.source and self.source.baseType == "creature" then
          creat:become_thrall(self.source)
          if player:can_sense_creature(creat) then
            output:out(self.source:get_name() .. " feeds " .. creat:get_name() .. " a soul, buying " .. creat:get_pronoun('p') .. " loyalty.")
            output:sound('gulp')
          end
        end
      else
        creat:give_condition('demonbait',15)
      end
    else 
      local db = Effect('soul')
      currMap:add_effect(db,target.x,target.y)
    end
    self:delete()
  end, --end hits()
  update = function(self,dt)
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end
}
projectiles['soul'] = soul

local firearrow = {
  name = "fire arrow",
  description = "A fiery arrow.",
  symbol = "/",
  angled = true,
  damage = 4,
  damage_type="fire",
  color = {r=75,g=0,b=0,a=255},
  time_per_tile = .01
}
projectiles['firearrow'] = firearrow

local icearrow = {
  name = "ice arrow",
  description = "An icy arrow.",
  symbol = "/",
  angled = true,
  damage = 4,
  damage_type="ice",
  color = {r=200,g=200,b=255,a=255},
  time_per_tile = .01,
  hit_conditions={{condition='chilled',chance=50,turns=3}}
}
projectiles['icearrow'] = icearrow

local electricarrow = {
  name = "electric arrow",
  description = "An electric arrow.",
  symbol = "/",
  angled = true,
  damage = 4,
  damage_type="electric",
  color = {r=200,g=200,b=255,a=255},
  time_per_tile = .01
}
function electricarrow:hits(target)
  local water = false
  local feats = currMap:get_tile_features(target.x,target.y)
  for _,feat in pairs(feats) do
    if feat.water == true then water = true break end
  end
  if not water and type(currMap[target.x][target.y]) == "table" and currMap[target.x][target.y].water == true then water = true end
  if water then
    local shocker = Effect('shocker')
    shocker.amt = self.damage
    shocker.source = self.source
    if target.baseType == "creature" then shocker.ignore = target end
    currMap:add_effect(shocker,target.x,target.y)
  end
  if target.baseType == "creature" then
    if water then
      if random(1,2) == 1 then creat:give_condition('stunned',random(3,5)) end
    else
      if random(1,4) == 1 then
        creat:give_condition('stunned',random(3,4))
      end
      for x = target.x-1,target.x+1,1 do
        for y=target.y-1,target.y+1,1 do
          local creat = currMap:get_tile_creature(x,y)
          if creat then
            local dmg = creat:damage(math.ceil(self.damage/2),self.source,'electric')
            if player:can_sense_creature(creat) then output:out("Electricity arcs to " .. creat:get_name() .. ", dealing " .. dmg .. " damage.") end
          end
        end --end fory
      end --end forx
    end
  end
  Projectile.hits(self,target,true)
end
projectiles['electricarrow'] = electricarrow

local phasearrow = {
  name = "phase arrow",
  description = "A phase arrow.",
  symbol = "/",
  angled = true,
  damage = 4,
  damage_type="magic",
  color = {r=50,g=0,b=50,a=255},
  time_per_tile = .01,
  passThrough = true
}
projectiles['phasearrow'] = phasearrow

local bolt = {
  name = "bolt",
  description = "A bolt fired from a crossbow.",
  symbol = "/",
  angled = true,
  damage = 4,
  color={r=255,g=255,b=255,a=255},
  time_per_tile = .01,
  miss_item="bolt",
  hit_sound = 'hit_stab',
  extra_damage_per_level=2,
}
projectiles['bolt'] = bolt

local arrow = {
  name = "arrow",
  description = "An arrow.",
  symbol = "/",
  damage = 4,
  angled = true,
  color = {r=200,g=200,b=200,a=255},
  time_per_tile = .01,
  hit_sound = 'hit_stab'
}
projectiles['arrow'] = arrow

local cherubarrow = {
  name = "holy arrow",
  description = "A holy arrow.",
  image_name="firearrow",
  symbol = "/",
  angled = true,
  damage = 2,
  damage_type="holy",
  color = {r=255,g=255,b=0},
  time_per_tile = .01
}
projectiles['cherubarrow'] = cherubarrow

local stonechunk = {
  name = "stone chunk",
  description = "A chunk of stone.",
  neverInstant=true,
  dontUseSource=true,
  symbol = "*",
  damage = 6,
  color={r=33,g=33,b=33,a=255},
  time_per_tile = .05,
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
  end
}
projectiles['stonechunk'] = stonechunk

local ratswarm = {
  name = "rat swarm",
	description = "A swarm of hungry rats!",
  damage = 0,
	symbol = "&",
	color={r=153,g=103,b=73,a=255},
  countdown = .05,
  image_name = "ratswarm1",
  imageType = "effect",
  time_per_tile = .05,
  hit_effect="ratswarm",
  miss_effect="ratswarm"
}
function ratswarm:update(dt)
  self.countdown = self.countdown - dt
  if (self.countdown <= 0) then
    self.image_name = "ratswarm" .. random(1,4)
    self.countdown = .1
    self.symbol = (random(1,3) == 1 and "&" or (random(1,2) == 1 and "%" or "#"))
  end
  Projectile.update(self,dt,true)
end
projectiles['ratswarm'] = ratswarm
    
local bottle = {
  name = "bottle",
  description = "A bottle, whizzing through the air.",
  symbol = "|",
  color={r=33,g=33,b=33,a=255},
  damage = 2,
  time_per_tile = .01,
  use_color_with_tiles=true,
  hit_sound = 'breakingbottle',
  miss_sound = 'breakingbottle',
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
    self.color={r=random(0,255),g=random(0,255),b=random(0,255),a=150}
  end,
  update = function(self,dt)
    if self.symbol == "/" then self.symbol = "-"
    elseif self.symbol == "-" then self.symbol = "\\"
    elseif self.symbol == "\\" then self.symbol = "|"
    elseif self.symbol == "|" then self.symbol = "/" end
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end,
  hits = function(self,target)
    if currMap:isClear(target.x,target.y,nil,true) then
      local glass = Feature('brokenglass')
      glass.color = self.color
      currMap:add_feature(glass,target.x,target.y)
      if random(1,3) ==1 then
        currMap:add_feature(Feature('spilledbooze'),target.x,target.y)
      end
    end --end isclear if
    Projectile.hits(self,target,true)
  end
}
projectiles['bottle'] = bottle

local spear = {
  name = "spear",
  description = "A sharp spear.",
  symbol = "/",
  angled = true,
  color={r=150,g=150,b=150,a=255},
  damage = 25,
  time_per_tile = .01,
  hit_sound = 'hit_stab',
  hits = function(self,target)
    local spear = Feature('spear')
    currMap:add_feature(spear,target.x,target.y)
    Projectile.hits(self,target,true)
  end
}
projectiles['spear'] = spear

local molotov = {
  name = "molotov cocktail",
  description = "A bottle filled with flammable liquid.",
  symbol = "|",
  color={r=33,g=33,b=33,a=255},
  damage = 2,
  time_per_tile = .01,
  use_color_with_tiles=true,
  hit_sound = 'breakingbottle',
  miss_sound = 'breakingbottle',
  hit_effect="fire",
  miss_effect="fire",
  hit_feature="brokenglass",
  miss_feature="brokenglass",
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
  end,
  update = function(self,dt)
    if self.symbol == "/" then self.symbol = "-"
    elseif self.symbol == "-" then self.symbol = "\\"
    elseif self.symbol == "\\" then self.symbol = "|"
    elseif self.symbol == "|" then self.symbol = "/" end
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end,
  hits = function(self,target)
    local creat = currMap:get_tile_creature(target.x,target.y)
    if (creat and creat.fireImmune ~= true) then
      creat:give_condition('onfire',random(5,10))
    end
    Projectile.hits(self,target,true)
  end
}
projectiles['molotov'] = molotov

local acid = {
  name = "acid flask",
  description = "A flask filled with acid.",
  symbol = "|",
  image_name = "bottle",
  color={r=0,g=255,b=0,a=255},
  damage = 2,
  time_per_tile = .01,
  use_color_with_tiles=true,
  hit_sound = 'breakingbottle',
  miss_sound = 'breakingbottle',
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
  end,
  update = function(self,dt)
    if self.symbol == "/" then self.symbol = "-"
    elseif self.symbol == "-" then self.symbol = "\\"
    elseif self.symbol == "\\" then self.symbol = "|"
    elseif self.symbol == "|" then self.symbol = "/" end
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end,
  hits = function(self,target)
    local acids = {}
		for x=target.x-2,target.x+2,1 do
			for y=target.y-2,target.y+2,1 do
				if (currMap[x][y] ~= "#" and calc_distance(target.x,target.y,x,y) <= 2) and currMap:is_line(target.x,target.y,x,y) then
          local make = true
          for _,feat in pairs(currMap:get_tile_features(x,y)) do
            if feat.id == "acid" or feat.absorbs or feat.water then
              make = false
              break
            end
          end
          if make then
            local acid = Feature('acid')
            acids[#acids+1] = acid
            currMap:add_feature(acid,x,y)
            local creat = currMap:get_tile_creature(x,y)
            if creat then
              local dmg = creat:damage(tweak(7),self.source,"acid")
              if player:can_sense_creature(creat) then output:out(creat:get_name() .. " gets caught in the acid splash and takes " .. dmg .. " damage.") end
            end
          end --end make if
				end --end tile isn't wall if
			end --end fory
		end --end forx
    for _, acid in pairs(acids) do --help them display right
      acid:refresh_image_name()
      for x=acid.x-1,acid.x+1,1 do
        for y=acid.y-1,acid.y+1,1 do
          local acid2 = currMap:tile_has_feature(x,y,'acid')
          if acid2 then
            acid2:refresh_image_name()
          end
        end --end fory
      end --end forx
    end
    Projectile.hits(self,target,true)
  end
}
projectiles['acid'] = acid

local venom = {
  name = "venom",
  description = "A glob of venom spit from a cobra.",
  symbol = "*",
  angled = true,
  color = {r=0,g=150,b=0},
  time_per_tile = .02
}
function venom:hits(target)
  if target.baseType == "creature" then
    target:give_condition('poisoned',tweak(10))
    if random(1,5) == 1 then target:give_condition('blinded',tweak(10)) end
    target:notice(self.source)
  end --end creature if
  self:delete()
end --end hits function
projectiles['venom'] = venom

local soundwave = {
  name = "soundwave",
  description = "A soundwave so powerful you can see it.",
  symbol = "^",
  angled = true,
  color = {r=255,g=255,b=255,a=255},
  use_color_with_tiles=true,
  time_per_tile = .05,
  stopsInput = false,
  passThrough = true,
  new = function(self,source,target,color)
    if color then
      self.color = {r=color.r,g=color.g,b=color.b}
    end
    if target.y == self.y then
      if target.x < self.x then self.symbol = "<"
      elseif target.x > self.x then self.symbol = ">" end
    elseif target.x == self.x then
      if target.y < self.y then self.symbol = "^"
      elseif target.y > self.y then self.symbol = "V" end
    end
  end,
  hits = function(self)
    self:delete()
  end
}
projectiles['soundwave'] = soundwave

local gust = {
  name = "gust of wind",
  description = "A powerful blast of air.",
  symbol = "^",
  angled = true,
  color = {r=178,g=220,b=239,a=255},
  use_color_with_tiles=true,
  time_per_tile = .01,
  stopsInput = false,
  passThrough = true,
  new = function(self,source,target,color)
    if color then
      self.color = {r=color.r,g=color.g,b=color.b}
    end
    if target.y == self.y then
      if target.x < self.x then self.symbol = "<"
      elseif target.x > self.x then self.symbol = ">" end
    elseif target.x == self.x then
      if target.y < self.y then self.symbol = "^"
      elseif target.y > self.y then self.symbol = "V" end
    end
  end,
  hits = function(self,target)
    if target and target.baseType == "creature" then
      local xMod,yMod = get_unit_vector(self.source.x,self.source.y,target.x,target.y)
      local dist = random(2,4)
      target:flyTo({x=target.x+(xMod*dist),y=target.y+(yMod*dist)})
    end
    self:delete()
  end
}
projectiles['gust'] = gust

local sewerglob = {
  name = "sewer glob",
  description = "A glob of sewer filth.",
  symbol = "*",
  angled = true,
  color = {r=0,g=150,b=0},
  time_per_tile = .1,
  damage=5
}
function sewerglob:hits(target)
  if target.baseType == "creature" then
    target:notice(self.source)
    target:give_condition('slimy',tweak(10))
    if random(1,5) == 1 then target:give_condition('blinded',tweak(10)) end
    target:give_condition('disease',tweak(4))
    if player:can_see_tile(target.x,target.y) then output:sound('splat_hits_creature') end
    Projectile.hits(self,target,true) --just do a regular hit to do the damage
  else
    if player:can_see_tile(target.x,target.y) then output:sound('splat_hits_ground') end
    currMap:add_feature(Feature('slime'),target.x,target.y)
  end --end creature if
  self:delete()
end --end hits function
projectiles['sewerglob'] = sewerglob

local slime = {
  name = "slimeball",
  description = "A glob of slime.",
  symbol = "*",
  angled = true,
  color = {r=0,g=150,b=0},
  time_per_tile = .1
}
function slime:hits(target)
  if target.baseType == "creature" then
    target:give_condition('slimy',tweak(10))
    target:notice(self.source)
    if player:can_see_tile(target.x,target.y) then output:sound('splat_hits_creature') end
  else
    if player:can_see_tile(target.x,target.y) then output:sound('splat_hits_ground') end
    currMap:add_feature(Feature('slime'),target.x,target.y)
    for x=self.x-1,self.x+1,1 do
      for y=self.y-1,self.y+1,1 do
        local s = currMap:tile_has_feature(x,y,'slime')
        if s then s:refresh_image_name() end
      end --end fory
    end --end forx
  end --end creature if
  self:delete()
end --end hits function
projectiles['slime'] = slime

local dirtchunk = {
  name = "Dirt Chunk",
  symbol = ".",
  noDesc = true,
  description = "A chunk of dirt",
  color = {r=98,g=73,b=22,a=255},
  use_color_with_tiles=true,
  time_per_tile = .1,
  image_name="particlemed",
}
function dirtchunk:hits(target)
  self:delete()
end
projectiles['dirtchunk'] = dirtchunk

local holywater = {
  name = "vial of holy water",
  description = "A vial filled with holy water.",
  symbol = "|",
  color={r=33,g=33,b=33,a=255},
  damage = 1,
  time_per_tile = .01,
  use_color_with_tiles=true,
  hit_sound = 'breakingbottle',
  miss_sound = 'breakingbottle',
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
  end,
  update = function(self,dt)
    if self.symbol == "/" then self.symbol = "-"
    elseif self.symbol == "-" then self.symbol = "\\"
    elseif self.symbol == "\\" then self.symbol = "|"
    elseif self.symbol == "|" then self.symbol = "/" end
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end,
  hits = function(self,target)
    Projectile.hits(self,target,true)
    if target.weaknesses and target.weaknesses.holy then --only deal damage to creature that actually have a weakness to holy damage
      local dmg = target:damage(5,self.source,'holy')
      if player:can_sense_creature(target) then
        output:out("The holy water burns " .. target:get_name() .. " for " .. dmg .. "damage.")
      end
    elseif target.baseType == "creature" then -- hit a creature, just not vulnerable?
      if player:can_sense_creature(target) then
        output:out("The holy water itself has no effect on " .. target:get_name() .. ".")
      end
    elseif not target.baseType == "creature" then --didn't hit a creature? leave a puddle
      
    end
  end
}
projectiles['holywater'] = holywater

local unholywater = {
  name = "vial of unholy water",
  description = "A vial filled with unholy water.",
  symbol = "|",
  color={r=33,g=33,b=33,a=255},
  damage = 1,
  time_per_tile = .01,
  use_color_with_tiles=true,
  hit_sound = 'breakingbottle',
  miss_sound = 'breakingbottle',
  new = function(self)
    self.angle = random(0,math.ceil(2*math.pi))
  end,
  update = function(self,dt)
    if self.symbol == "/" then self.symbol = "-"
    elseif self.symbol == "-" then self.symbol = "\\"
    elseif self.symbol == "\\" then self.symbol = "|"
    elseif self.symbol == "|" then self.symbol = "/" end
    self.angle = self.angle+dt*8*math.pi
    Projectile.update(self,dt,true)
  end,
  hits = function(self,target)
    Projectile.hits(self,target,true)
    if target.weaknesses and target.weaknesses.unholy then --only deal damage to creature that actually have a weakness to holy damage
      local dmg = target:damage(5,self.source,'unholy')
      if player:can_sense_creature(target) then
        output:out("The unholy water burns " .. target:get_name() .. " for " .. dmg .. "damage.")
      end
    elseif target.baseType == "creature" then -- hit a creature, just not vulnerable?
      if player:can_sense_creature(target) then
        output:out("The unholy water itself has no effect on " .. target:get_name() .. ".")
      end
    elseif not target.baseType == "creature" then --didn't hit a creature? leave a puddle
      
    end
  end
}
projectiles['unholywater'] = unholywater