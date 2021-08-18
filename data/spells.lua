possibleSpells = {

blast = Spell({
	name = "Psychic Blast",
	description = "Attack a target...with your mind!",
	cooldown = 5,
	target_type = "creature",
	flags = {aggressive=true},
  tags={'psychic','attack'},
	cast = function(self,target,caster)
		local dmg = target:damage(random(8,15),caster,"magic")
		if player:can_sense_creature(target) then
      output:out(caster:get_name() .. " blasts " .. target:get_name() .. " with " .. target:get_pronoun('p') .. " mind, dealing " .. dmg .. " damage.")
    end
	end
}),

blink = Spell({
	name = "Blink",
	description = "Instantly transports the caster to a random location nearby.",
	target_type = "self",
	cooldown=10,
  AIcooldown=30,
  sound="teleport",
  flags={fleeing=true,defensive=true},
  tags={'teleport','magic'},
	cast = function(self,target,caster)
    local origX,origY = caster.x,caster.y
    local x,y = caster.x,caster.y
    local safe = false
    local tries = 0
    while (x<2 or y<2 or x>currMap.width or y>currMap.height or caster:can_move_to(x,y) == false) or (((x == origX and y == origY) or safe == false) and tries < 25) do
      x = random(caster.x-5,caster.x+5)
      y = random(caster.y-5,caster.y+5)
      safe = true
      tries = tries+1
      for x = x-1,x+1,1 do
        for y = y-1,y+1,1 do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= caster then
            safe = false
            break
          end --end if creat
        end --end fory
        if safe == false then break end
      end --end forx
		end --end while
		caster:moveTo(x,y)
		if caster:has_spell('blink') and player:can_see_tile(caster.x,caster.y) then
      currMap:add_effect(Effect('animation','magicdamage',5,{x=origX,y=origY},{r=255,g=255,b=255}),origX,origY)
      output:out(caster:get_name() .. " blinks!")
    end
	end
}),

demondamager = Spell({
	name = "Demon Fighter",
	description = "You know a lot about demons. Particularly, how to hurt them.",
	target_type = "passive",
  tags={'knowledge'},
  calc_damage = function(self,possessor,target,damage)
    if target:is_type('demon') then
      return math.ceil(damage * 1.5)
    else
      return damage
    end
  end
}),

demondamager2 = Spell({
	name = "Demon Slayer",
	description = "You know a ton about demons. Particularly, how to hurt them really badly.",
	target_type = "passive",
  calc_damage = function(self,possessor,target,damage)
    if target:is_type('demon') then
      return math.ceil(damage * 2)
    else
      return damage
    end
  end
}),

scrawny = Spell({
	name = "Scrawny Arms",
	description = "Your arms are basically noodles, and they're not al dente. You can never deal more than 1 damage in melee.",
	target_type = "passive",
  tags={'physical','negative'},
  calc_damage = function(self,possessor,target,damage)
    return 1
  end
}),

summonangel = Spell({
	name = "Summon Angel",
	description = "Summon a holy angel of vengeance.",
	target_type = "self",
  cost=10,
  tags={'holy','summon'},
  level_requirement=3
}),

smite = Spell({
    name = "Smite",
    description = "Bring down holy wrath upon a demon, abomination, undead or possessed creature.",
    target_type="creature",
    projectile=false,
    cost=1,
    cooldown = 5,
    tags={'holy','attack'},
    cast = function(self,target,attacker)
      if (attacker.mp and attacker.mp == 0) then
        if attacker == player then output:out("You don't have enough piety to smite your enemies.") end
        return false
      end
      if target:is_type('demon') or target:is_type('undead') or target:is_type('abomination') or target == player or target:has_condition('possessed') then
        dmg = target:damage(tweak(15),attacker,"holy")
        if player:can_see_tile(attacker.x,attacker.y) then output:out(attacker:get_name() .. " smites " .. target:get_name() .. " for " .. dmg .. " holy damage.") end
        if random(1,3) == 1 then
          target:give_condition('stunned',random(2,4))
        end
      else --if not a demon or undead
        output:out(attacker:get_name() .. " tries to smite " .. target:get_name() .. ", but " .. target:get_pronoun('n') .. " isn't an unholy being and remains unsmote.")
        return false
      end
    end, --end use function
  }),

homecoming = Spell({
    name = "Homecoming",
    description = "Teleport immediately to the town.",
    target_type = "self",
    tags={'teleport','magic'},
    cast = function(self,caster)
      if caster == player then
        goToMap(1,"town",true)
      end
    end
  }),


--Pyromancer class spells
smallfireball = Spell({
	name="Small Fireball",
	description="Shoots a small fireball.",
	cooldown=5,
  cost=5,
	target_type = "tile",
  projectile = true,
  tags={'fire','attack','magic'},
	flags = {aggressive=true},
	cast = function(self,target,caster)
    if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " shoots a fireball.") end
    Projectile('smallfireball',caster,target)
	end
}),

explodingfireball = Spell({
	name="Exploding Fireball",
	description="Blasts an enormous fireball at an area.",
	cooldown=20,
  cost=20,
	target_type = "tile",
  projectile = true,
  sound = "fireball_large",
	flags = {aggressive=true},
  tags={'fire','attack','magic'},
	cast = function(self,target,caster)
    if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " launches a huge fireball!") end
    Projectile('explodingfireball',caster,target)
	end, --end cast function
  get_target_tiles = function(self,target,caster)
    local targets = {}
    for x=target.x-1,target.x+1,1 do
      for y=target.y-1,target.y+1,1 do
        targets[#targets+1] = {x=x,y=y}
      end --end fory
    end --end forx
    return targets
  end --end target draw function
}),

firebrand = Spell({
	name = "Fire Brand",
	description = "Encases your weapon in flames, causing it to deal extra fire damage.",
  cost=10,
	target_type = "self",
	flags = {aggressive=true},
  tags={'fire','buff','magic'},
	cast = function (self,target,caster)
    local weapons = caster:get_equipped_in_slot('weapon')
    if #weapons > 0 then
      local done = false
      for _,weapon in pairs(weapons) do
        if done == true then break end
        if weapon:qualifies_for_enchantment('fireweapon') then
          if player:can_see_tile(caster.x,caster.y) then
            output:out(caster:get_name() .. " causes " .. weapon:get_name() ..  " to erupt in flames!")
            output:sound('firebrand')
          end
          weapon:apply_enchantment('fireweapon',5)
        end --end qualifies if
      end --end weapon for
		else
      if caster == player then output:out("You aren't wielding any weapons, so you can't cause them to light on fire.") end
      return false
    end
	end
}),

--Necromancer class spells:
reanimate = Spell({
	name = "Reanimate Corpse",
	description = "Brings a dead body back to life as a hideous zombie!",
	target_type = "tile",
  cost=5,
  tags={'unholy','summon','necromancy','magic'},
	cast = function (self,target, caster)
    if not caster:can_see_tile(target.x,target.y) then
      output:out("You can't see there, so you can't reanimate any corpses that may or may not be there.")
    end
		for id, content in pairs(currMap.contents[target.x][target.y]) do
			if (content.creature ~= nil) then
        local z = nil --define z so it holds the value later
				if (content.creature.id == "zombie") then
          z = Creature('skeleton',1)
          if player:can_see_tile(target.x,target.y) then
            output:out(caster:get_name() .. " reanimates the skeleton inside a battered zombie!")
            output:sound("unholydamage")
            output:sound("skeleton_aggro")
          end
        elseif content.id == "bonepile" then
          output:out("That dusty pile of bones has been through enough.")
          return false
        else
          z = Creature('zombie',1)
          if player:can_see_tile(target.x,target.y) then
            output:out(caster:get_name() .. " reanimates a corpse!")
            output:sound("unholydamage")
            output:sound("zombie_aggro")
          end
          local creat = content.creature
          if creat:is_type('ratling') then
            z.image_name = "zombieratling"
            z.name = "zombie ratling"
          elseif creat:is_type('troll') then
            z.image_name = "zombietroll"
            z.name = "zombie troll"
          elseif creat.id == "gargoyle" then
            z.image_name = "zombiegargoyle"
            z.name = "zombie gargoyle"
          end
				end
				content:delete()
				currMap:add_creature(z,target.x,target.y)
        z:become_thrall(caster)
        currMap:add_effect(Effect('animation','unholydamage',5,target,{r=150,g=0,b=150}),target.x,target.y)
				return true
			end
		end
		output:out("There's no corpse there to animate.")
		return false
	end
}),

sacrificecorpse = Spell({
	name = "Sacrifice Corpse",
	description = "Sacrifice a recently-dead creature to the darkness, gaining evil power!",
	target_type = "tile",
  tags={'unholy','necromancy','magic'},
	cast = function (self,target, caster)
    local corpse = currMap:tile_has_feature(target.x,target.y,'corpse')
    if corpse and corpse.creature:is_type('undead') then
      output:out("You can't sacrifice the undead.")
      return false
    elseif corpse then
      if player:can_see_tile(caster.x,caster.y) then
        local mp = tweak((corpse.creature.level or 1)*10)
        output:out(caster:get_name() .. " sacrifices " .. corpse.creature:get_name() .. " to the darkness, gaining " .. mp .. " MP!")
        currMap:add_effect(Effect('animation','floatingpluses',5,caster,{r=235,g=137,b=49,a=255},true,true),caster.x,caster.y)
        output:sound("unholydamage")
      end
      currMap:add_effect(Effect('animation','unholydamage',5,target,{r=150,g=0,b=150}),target.x,target.y)
      caster.mp = caster.mp + mp
      corpse:delete()
      return true
		end
		output:out("There's no corpse there to sacrifice.")
		return false
	end,
  kills = function(self,possessor,victim)
    if not victim:is_type('undead') then
      possessor.magic = possessor.magic + 5
      currMap:add_effect(Effect('animation','floatingpluses',5,possessor,{r=235,g=137,b=49,a=255},true,true),possessor.x,possessor.y)
      currMap:add_effect(Effect('animation','unholydamage',5,false,{r=255,g=255,b=0}),victim.x,victim.y)
      if possessor == player then
        output:sound('unholydamage')
        output:out("Killing " .. victim:get_name() .. " grants you evil power!")
      end
    end
  end,
  ally_kills = function(self,possessor,victim,killer)
    if not victim:is_type('undead') then
      possessor.magic = possessor.magic + 2
      currMap:add_effect(Effect('animation','floatingpluses',5,possessor,{r=235,g=137,b=49,a=255},true,true),possessor.x,possessor.y)
      currMap:add_effect(Effect('animation','unholydamage',5,false,{r=255,g=255,b=0}),victim.x,victim.y)
      if possessor == player then
        output:sound('unholydamage')
        output:out("The death of " .. victim:get_name() .. (killer and " at the hands of " .. killer:get_name() or "") .. " grants you evil power!")
      end
    end
  end
}),

corpseburst = Spell({
	name = "Corpse Burst",
	description = "Accelerates the rate of decay in a dead body so much that the gases build up inside of it and explode. A completely grotesque spell, banned by most civilized nations.",
	target_type = "tile",
  tags={'unholy','necromancy','attack','magic'},
	cast = function (self,target,caster)
		local corpse = currMap:tile_has_feature(target.x,target.y,"corpse")
    if corpse == false then
      output:out("There's no corpse there.")
      return false
    end
    table.insert(currMap.creatures,corpse.creature)
    corpse.creature:forceMove(corpse.creature.x,corpse.creature.y)
    corpse.creature:explode()
    corpse:delete()
	end
}),

witheringcurse = Spell({
	name = "Withering Touch",
	description = "You're so full of pathogens that just touching a creature will give them a horrible disease that weakens their muscles and causes their skin to rot off their body.",
	target_type = "creature",
  cooldown=30,
  range=1,
  tags={'unholy','curse','necromancy','magic'},
	cast = function (self,target,caster)
		target:give_condition('witheringcurse',-1)
	end
}),

auraoffear = Spell({
    name = "Fearsome Visage",
    description = "You are either really scary or really ugly. Just being in your presence fills your enemies with fear.",
    target_type = "passive",
    tags={'physical'},
    advance = function(self,possessor)
      for x=possessor.x-10,possessor.x+10,1 do
        for y=possessor.y-10,possessor.y+10,1 do
          if currMap:in_map(x,y) then
            local creat = currMap:get_tile_creature(x,y)
            if creat and creat:is_enemy(possessor) and creat:does_notice(possessor) then creat.fear = creat.fear + random(2,4) end
          end
        end --end fory
      end --end forx
    end
  }),

undeadlegion = Spell({
	name = "Summon Undead Legion",
	description = "The dead will crawl their way out of the ground to serve you. (This spell is more effective if cast in a wide open space.) Also, undead with no masters will follow you.",
	cooldown = 25,
	flags = {aggressive=true,defensive=true},
	target_type = "self",
  tags={'unholy','necromancy','summon','magic'},
	cast = function (self,target,caster)
		if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " calls forth an army of the dead!") end
		local deadheads = random(4,6)
		while (deadheads > 1) do
			local x,y = random(caster.x-5,caster.x+5),random(caster.y-5,caster.y+5)
			if (x>1 and y>1 and x< currMap.width and y< currMap.height and currMap:isClear(x,y)) then
				--[[local deadite = (random(1,2) == 1 and Creature('zombie') or Creature('skeleton'))
				currMap:add_creature(deadite,x,y)
        deadite:become_thrall(caster)]]
			end
			deadheads = deadheads - 1
		end
	end,
  noticed = function(self,possessor,noticer)
    if not noticer.master and noticer:is_type('undead') and not noticer:is_type('intelligent') then
      noticer:become_thrall(possessor)
      if possessor == player then 
        output:out(noticer:get_name() .. " joins your unholy crusade.")
      end
      return false
    end
  end
}),

shademaker = Spell({
    name = "Leader of the Dead",
    description = "Anytime you kill a living creature, you'll draw forth a shade to join your unholy crusade.",
    target_type = "passive",
    tags={'unholy','necromancy','summon','magic'},
    kills = function(self,possessor,victim)
      if possessor.id == "deathknight" or possessor.master.id == "deathknight" then
        if not victim:is_type('undead') and not victim:is_type('construct') and victim ~= player then
          local shade = Creature('shade')
          currMap:add_creature(shade,victim.x,victim.y)
          shade:become_thrall((possessor.id == "deathknight" and possessor or possessor.master))
          possessor:notice(shade)
          output:sound('shade_create')
        end
      end
    end,
    dies = function(self,possessor)
      if player:can_sense_creature(possessor) then
        output:out(possessor:get_name() .. "'s shades disappear into the darkness.")
      end
      for _,thrall in pairs(possessor.thralls) do
        if thrall.id == "shade" then
          thrall:die()
        end
      end
    end
  }),

lifedrain = Spell({
  name = "Life Drain",
  description = "Drain health out of a nearby target.",
  target_type = "creature",
  cooldown=10,
  AIcooldown=20,
  flags={aggressive=true},
  tags={'unholy','attack','magic'},
  cast = function(self,target,caster)
    if target:is_type('undead') or target:is_type('construct') then
      if caster == player then output:out("You can't drain the life out of something that's not alive.") end
      return false
    end
    local dmg = target:damage(tweak(15),caster,'dark')
    caster:updateHP(dmg)
    if player:can_see_tile(caster.x,caster.y) then
      output:out(caster:get_name() .. " drains " .. dmg .. " HP from " .. target:get_name() .. ".")
      currMap:add_effect(Effect('animation','unholydamage',5,target,{r=150,g=0,b=150}),target.x,target.y)
      output:sound('unholydamage')
    end
  end
}),

graspingdead = Spell({
  name = "Grasping Dead",
  description = "Skeletal hands will erupt from the ground, grabbing onto all nearby, scratching them and preventing them from moving.",
  target_type = "tile",
  cooldown=15,
  AIcooldown=30,
  sound="graspingdead",
  flags={aggressive=true},
  tags={'unholy','necromancy','magic'},
  cast = function (self,target,caster)
		if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " calls forth grasping dead from the earth!") end
		for x=target.x-1,target.x+1,1 do
			for y=target.y-1,target.y+1,1 do
				if (currMap[x][y] ~= "#") then
          local dead = currMap:tile_has_effect(x,y,'graspingdead')
          if dead then
            dead.turns = dead.turns+(6-dead.turns)
          else
            local graspingdead = Effect('graspingdead')
            graspingdead.owner = owner
            currMap:add_effect(graspingdead,x,y)
          end --end already have if
				end
			end
		end
	end,
  get_target_tiles = function(self,target,caster)
    local targets = {}
    for x=target.x-1,target.x+1,1 do
      for y=target.y-1,target.y+1,1 do
        targets[#targets+1] = {x=x,y=y}
      end --end fory
    end --end forx
    return targets
  end, --end target draw function
  decide = function(self,target,caster)
    if target:is_type('flyer') then return false end
  end --end creature for
}),

bloodrain = Spell({
  name = "Rain of Blood",
  description = "Causes blood to rain down, terrifying all in the area, and potentially getting them sick.",
  target_type = "tile",
  cooldown=10,
  sound="rain",
  tags={'unholy','blood','magic'},
  cast = function(self,target,caster)
    for x = target.x-3,target.x+3,1 do
      for y = target.y-3,target.y+3,1 do
        if currMap:in_map(x,y) and calc_distance(x,y,target.x,target.y) <= 3 and currMap:isClear(x,y,nil,true) and currMap:is_line(x,y,target.x,target.y,true) then
          local rain = Effect('bloodrain')
          currMap:add_effect(rain,x,y)
        end --end x,y check if
      end --end fory
    end --end forx
  end,
  get_target_tiles = function(self,target,caster)
    local targets = {}
    for x=target.x-3,target.x+3,1 do
      for y=target.y-3,target.y+3,1 do
        if calc_distance(x,y,target.x,target.y) <= 3 and currMap:is_line(x,y,target.x,target.y,true) then targets[#targets+1] = {x=x,y=y} end
      end --end fory
    end --end forx
    return targets
  end, --end target draw function
  decide = function(self,target,caster)
    if target:is_type('undead') or target:is_type('construct') then return false end
  end --end creature for --end target draw function
}),

enfeeble = Spell({
  name = "Enfeeble",
  description = "Permanently reduces a creature's maximum HP by half.",
  target_type = "creature",
  cooldown=25,
  sound="enfeeble",
  tags={'unholy','curse','magic'},
  cast = function(self,target,caster)
    if target:is_type('undead') then
      if caster == player then output:out("You can't destroy the life force of an undead creature.") end
      return false
    end
    local amt = math.ceil(target.max_hp/2)
    target.max_hp = target.max_hp - amt
    if target.hp > target.max_hp then
      target.hp = target.max_hp
    end
    target.fear = target.fear+50
    if player:can_see_tile(target.x,target.y) then
      output:out(caster:get_name() .. " permanently cripples " .. target:get_name() .. "'s health!")
      local p = Effect('dmgpopup')
      p.color = {r=255,g=0,b=0,a=255}
      p.symbol = "-" .. amt .. "!"
      currMap:add_effect(p,target.x,target.y)
    end
  end
}),

decayaura = Spell({
	name = "Aura of Decay",
	description = "An aura of death and decay surrounds you, causing nearby plants to wither and die.",
	target_type = "passive",
  tags={'unholy','magic'},
  advance = function(self,possessor)
    local grasses = {}
    for x=possessor.x-1,possessor.x+1,1 do
      for y=possessor.y-1,possessor.y+1,1 do
        if currMap:in_map(x,y) then
          local tree = currMap:tile_has_feature(x,y,'tree')
          if tree then
            local deadtree = Feature('deadtree')
            deadtree.image_name = "dead" .. tree.image_name
            tree:delete()
            currMap:add_feature(deadtree,x,y)
          end --end tree if
          local bush = currMap:tile_has_feature(x,y,'bush')
          if bush then
            local deadbush = Feature('deadbush')
            deadbush.image_name = "dead" .. bush.image_name
            bush:delete()
            currMap:add_feature(deadbush,x,y)
          end --end tree if
          local grass = currMap:tile_has_feature(x,y,'grass')
          if grass then
            local deadgrass = Feature('deadgrass')
            if currMap[x][y] == grass then
              currMap:change_tile(deadgrass,x,y,true)
              deadgrass.x,deadgrass.y = x,y
            else
              currMap:add_feature(deadgrass,x,y)
            end
            grass:delete()
            grasses[#grasses+1] = deadgrass
          end --end tree if
        end --end inmap if
      end --end fory
    end --end forx
    
    for _, deadgrass in pairs(grasses) do
      for x=deadgrass.x-1,deadgrass.x+1,1 do
        for y = deadgrass.y-1,deadgrass.y+1,1 do
          local grass = currMap:tile_has_feature(x,y,'grass')
          if grass then grass:refresh_image_name() end
          local deadgrass = currMap:tile_has_feature(x,y,'deadgrass')
          if deadgrass then deadgrass:refresh_image_name() end
        end
      end
      deadgrass:refresh_image_name()
    end
  end
}),

painbolt = Spell({
    name = "Bolt of Darkness",
    description = "Send unholy energy through a target's body. This deals damage to living creatures and heals undead ones.",
    projectile=false,
    target_type="creature",
    cost=1,
    tags={'unholy','attack','magic'},
    cast = function(self,target,attacker)
      if target:is_type('undead') then
        local dmg = tweak(10)
        if player:can_see_tile(attacker.x,attacker.y) then
          output:out(attacker:get_name() .. " heals " .. target:get_name() .. " for " .. dmg .. " damage.")
          currMap:add_effect(Effect('animation','unholydamage',5,target,{r=150,g=0,b=150}),target.x,target.y)
          output:sound("unholydamage")
        end
        target:updateHP(dmg)
      else
        local dmg = target:damage(tweak(10),attacker,"unholy")
        if player:can_see_tile(attacker.x,attacker.y) then
          output:out(attacker:get_name() .. " gestures at " .. target:get_name() .. ". " .. ucfirst(target:get_pronoun('n')) .. " convulses with pain, taking " .. dmg .. " damage.")
          currMap:add_effect(Effect('animation','unholydamage',5,target,{r=150,g=0,b=150}),target.x,target.y)
          output:sound("unholydamage")
        end
      end
    end
  }),

rigormortis = Spell({
    name = "Rigor Mortis",
    target_type = "creature",
    cooldown = 15,
    AIcooldown=30,
    description = "Causes the target's joints to lock up, preventing them from moving for a short while.",
    flags={aggressive=true,defensive=true,fleeing=true},
    tags={'unholy','curse','magic'},
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " gestures at " .. target:get_name() .. ". " .. ucfirst(target:get_pronoun('p')) .. " joints lock up!") end
      currMap:add_effect(Effect('animation','unholydamage',5,target,{r=150,g=0,b=150}),target.x,target.y)
      output:sound('unholydamage')
      target:give_condition('stunned',tweak((target:is_type('undead') and 8 or 4)))
    end
  }),

deadlypremonition = Spell({
    name = "Deadly Premonition",
    target_type = "creature",
    cooldown = 15,
    AIcooldown=30,
    description = "Causes a target to experience visions of their own death, terrifying them.",
    sound="deadlypremonition",
    tags={'curse','psychic'},
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      if target == player then return false end
      if not target:is_type('mindless') then
        if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " gives " .. target:get_name() .. " visions of " .. target:get_pronoun('p') .. " own death, terrifying " .. target:get_pronoun('n') .. "!") end
        currMap:add_effect(Effect('animation','unholydamage',5,target,{r=150,g=0,b=150}),target.x,target.y)
        target:give_condition('fear',tweak(30))
        target.fear = target.fear + 50
      else
        if caster == player then output:out(caster:get_name() .. " doesn't have a mind. You can't fill " .. target:get_pronoun('p') .. " mind with visions of death.") end
        return false
      end
    end
  }),

vampirism = Spell({
	name = "Vampirism",
	description = "You regain some health when you damage an enemy.",
	target_type = "passive",
  unlearnable = true, --If true, this spell will not show up in spell books or factions to be learned unless explicitly put there
  tags={'unholy','physical'},
	damages = function(self,possessor,target,damage)
    if (random(1,2) == 1 and not target:is_type('bloodless')) or target:has_condition('bleeding') then
      local hp = tweak(math.ceil(damage*(random(2,6)/10)))
      if player:can_see_tile(possessor.x,possessor.y) and hp > 0 then
        output:out(possessor:get_name() .. " drains some blood from " .. target:get_name() .. ", regaining " .. hp .. " HP!")
        --local blood = currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="bleeding",symbol="",image_base="bloodmagicdamage",image_max=4,speed=0.20,color={r=255,g=0,b=0,a=125}}),possessor.x,possessor.y)
        local blood = currMap:add_effect(Effect('animation','bloodmagicdamage',5,target,{r=255,g=255,b=255}),target.x,target.y)
        if possessor == player or target == player then output:sound('vampirism') end
      end
      possessor:updateHP(hp)
    end
	end
}),

slimesplit = Spell({
	name = "Mitosis",
	description = "You split in half when you are damaged.",
	target_type = "passive",
  tags={'physical'},
	damaged = function(self,possessor, attacker,amt,dtype)
		if (dtype ~= "fire" and possessor.hp > 20 and random(1,3) == 1 ) then
			for x = possessor.x-1,possessor.x+1,1 do
				for y=possessor.y-1,possessor.y+1,1 do
					if (possessor:can_move_to(x,y)) then
						local newmax = math.ceil(possessor.hp/2)
						local split = Creature('slimemold')
            currMap:add_creature(split,x,y)
						possessor.max_hp,possessor.hp = newmax,newmax		
						split.max_hp,split.hp = newmax,newmax
            if possessor.master then split:become_thrall(possessor.master) else split:become_thrall(possessor) end
            if player:can_see_tile(possessor.x,possessor.y) then
              output:sound('slime_split')
            end
						return true
					end
				end
			end
		end
	end
}),

curse = Spell({
	name = "Curse",
	description = "Curse an enemy with bad luck, reducing their hit and dodge chances.",
	cooldown = 10,
	target_type = "creature",
  sound="unholydamage",
	flags = {aggressive=true},
  tags={'curse','magic'},
	cast = function (self,target,caster)
    if target == caster then
      if caster == player then output:out("Don't curse yourself. Instead, curse the wretched world that made you this way, and swear revenge!") end
      return false
    elseif target.id == "mummy" then
      if caster == player then output:out("Mummies don't curse each other. Professional courtesy.") end
      return false
    elseif target.id == "witch" then
      if caster == player then output:out("Witches don't curse each other. Professional courtesy.") end
      return false
    elseif target:is_type('undead') then
      if caster == player then output:out("You can't curse the undead. They're already cursed with the darksign.") end
      return false
    elseif target:is_type('demon') then
      if caster == player then output:out("You can't curse a being of pure evil. Well, you could, but it would just end up being a blessing instead.") end
      return false
    elseif target:is_type('construct') then
      if caster == player then output:out("You can't curse an animated object. Since they're not really alive, they can't have bad luck.") end
      return false
    end
		target:give_condition('cursed',random(5,10))
		if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " curses " .. target:get_name() .. " with bad luck.") end
	end
}),

knockbackimmunity = Spell({
    name = "Immune to Knockbacks",
    description = "You're incredibly massive, and can't be knocked backwards. Good for you.",
    target_type = "passive",
    tags={'physical'}
  }),

sleepless = Spell({
    name = "Sleepless",
    description = "You don't sleep. On the plus side, spells and abilities that make people fall asleep don't work on you. On the minus side, you don't dream. On the plus side, you don't have nightmares.",
    target_type = "passive",
    tags={'physical'}
  }),

sporedeath = Spell({
    name = "Filled with Spores",
    description = "You are full of spores. When you die, they'll explode into the air.",
    target_type = "passive",
    tags={'physical','nature'},
    dies = function(self,possessor)
      if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " explodes into spores!") end
      for i=1,random(2,4),1 do
        currMap:add_effect(Effect('spores'),possessor.x,possessor.y)
      end
      if player:can_see_tile(possessor.x,possessor.y) then output:sound('shroomman_death') end
    end
  }),

passiverage = Spell({
    name = "Anger Management Problems",
    description = "You're very angry. Your fury builds in battle, eventually exploding into a terrible rage.",
    target_type="passive",
    tags={'physical'},
    damaged = function(self,possessor, attacker,amt,dtype)
      local perc = math.ceil((amt/possessor:get_mhp())*100)*2
      if possessor.extra_stats.fury then
        local newVal = possessor:update_extra_stat('fury',perc)
        if newVal >= possessor.extra_stats.fury.max then
          possessor:give_condition('enraged',-1)
        end
      end
    end
  }),

yawp = Spell({
    name = "Barbaric Yawp",
    description = "Sound a barbaric yawp over the roofs of the world, stunning and/or terrifying all who hear.",
    target_type="self",
    sound="yawp",
    cooldown=10,
    flags={aggressive=true,defensive=true,fleeing=true},
    tags={'physical'},
    cast = function(self,target,caster)
      currMap:add_effect(Effect('soundwavemaker',{r=100,g=100,b=100},5),caster.x,caster.y)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " sounds " .. caster:get_pronoun('p') .. " barbaric yawp over the roofs of the world.") end
      for x=math.max(caster.x-10,2),math.min(currMap.width-1,caster.x+10) do
        for y=math.max(caster.y-10,2),math.min(currMap.height-1,caster.y+10) do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= caster then
            local dist = calc_distance(caster.x,caster.y,creat.x,creat.y)
            creat:notice(caster)
            if not creat:is_type('mindless') then creat.fear = creat.fear + random(10,25) end
            if dist < 3 and random(1,2) == 1 then
              if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " is stunned by the yawp!") end
              creat:give_condition('stunned',tweak(4))
            elseif random(1,2) == 1 and not creat:is_type('mindless') then
              if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " is terrified by the yawp!") end
              creat:give_condition('fear',tweak(30))
            end --end fear or stunned if
          end
        end --end fory
      end --end forx
    end
}),

angelichivemind = Spell({
    name = "Angelic Hivemind",
    description = "Can sense the presence of other angels on the same map.",
    target_type = "passive",
    tags={'holy'},
    sense = function(self,possessor,target)
      if target:is_type('angel') then return true end
      if possessor:can_see_tile(target.x,target.y) then return true end
      return false
    end
  }),

angelicdefense = Spell({
    name = "Angelic Defense",
    description = "When one angel is attacked, all other angels on the level come running.",
    target_type = "passive",
    tags={'holy'},
    attacked = function(self,possessor,attacker)
      for _,creat in pairs(currMap.creatures) do
        if creat:is_type('angel') then
          creat:become_hostile(attacker)
          if not creat.target or creat.target.baseType ~= "creature" then
            if creat:can_see_tile(attacker.x,attacker.y) then
              creat.target = attacker
            else
              creat.target = {x=attacker.x,y=attacker.y}
            end
          end
        end
      end
    end
  }),

webshot = Spell({
    name = "Spray Webbing",
    description = "Spray sticky webbing in an area to trap your victims.",
    cooldown = 25,
    AIcooldown=50,
    target_type = "tile",
    projectile = true,
    sound="spit",
    flags={aggressive=true,defensive=true,fleeing=true},
    tags={'physical'},
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " sprays webbing all over the place.") end
      local tiles = mapgen:make_blob(currMap,target.x,target.y,false,25)
      for _,t in pairs(tiles) do
        local creat = currMap:get_tile_creature(t.x,t.y)
        local web = true
        if creat and creat.id ~= "spider" then
          creat:give_condition('webbed',tweak(5))
          currMap:add_effect(Effect('conditionanimation',{owner=creat,condition="webbed",symbol="~",image_base="spiderwebtangle",image_max=2,speed=creat.animation_time,color={r=255,g=255,b=255,a=255},use_color_with_tiles=false,spritesheet=true}),creat.x,creat.y)
          web = false
        end
        for _, f in pairs(currMap:get_tile_features(t.x,t.y)) do
          if web == false or f.water or f.absorbs or f.id == "web" then web = false break end --if there's already slime, don't reapply
        end
        if web then
          local w = Feature('web')
          currMap:add_feature(w,t.x,t.y)
          w:refresh_image_name()
          for x=t.x-1,t.x+1,1 do
            for y=t.y-1,t.y+1,1 do
              local web = currMap:tile_has_feature(x,y,'web')
              if web then web:refresh_image_name() end
            end
          end --end forx
        end
      end
    end --end cast function
  }),

poisonbite = Spell({
    name = "Poison Bite",
    description = "Sink your fangs and/or mandibles in..",
    target_type = "creature",
    range=1,
    cooldown=9,
    AIcooldown=18,
    sound="unholydamage",
    tags={'physical','poison'},
    cast = function(self,target,caster)
      if player:can_see_tile(target.x,target.y) then
        output:out(caster:get_name() .. " injects " .. target:get_name() .. " with poison!")
        currMap:add_effect(Effect('animation','poisondamage',5,target,{r=150,g=0,b=150}),target.x,target.y)
      end
      target:give_condition('poisoned',tweak(5))
    end
  }),
}
