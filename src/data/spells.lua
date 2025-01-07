possibleSpells = {
  
teleportother = {
  name = "Teleport Other",
  description = "Teleport another creature somewhere nearby.",
  target_type="tile",
  min_targets=2,
  max_targets=2,
  cast_accepts_multiple_targets=true,
  cast = function(self,target,caster)
    local creat = currMap:get_tile_creature(target[1].x,target[1].y)
    creat:moveTo(target[2].x,target[2].y,true,true)
    creat:give_condition('stunned',1)
  end,
  target_requires = function(self,target,caster,target_number)
    if target_number == 1 then --selecting the creature
      local creat = currMap:get_tile_creature(target.x,target.y)
      if not creat then
        return false,"There's no one there to teleport."
      end
    else
      if not currMap:isClear(target.x,target.y) then
        return false,"You can't teleport them there."
      end
    end
  end,
  get_potential_targets = function(self,caster,target_number)
    if target_number == 1 then
      local targs = {}
      for _,t in pairs(caster:get_seen_creatures()) do
        targs[#targs+1] = t
      end
      return targs
    end
  end
},

blast = {
	name = "Psychic Blast",
	description = "Attack a target...with your mind!",
	target_type = "creature",
	flags = {aggressive=true},
  tags={'psychic','attack'},
  charges=5,
  max_charges=5,
  min_targets=1,
  max_targets=2,
  cooldown=2,
  settings={confusion={name="Confusion",description="Chance of causing confusion in the target.",requires_upgrades={confusion=1,stun=1},setting_exclusions={'stun'}},stun={name="Stunning",description="Chance of stunning the target.",requires_upgrades={stun=1,confusion=1},setting_exclusions={'confusion'}}},
  stats={
    min_damage={value=8,name="Minimum Damage",stat_type="damage",display_order=1},
    max_damage={value=15,name="Maximum Damage",stat_type="damage",display_order=2},
    confusion_chance={value=0,name="Chance of causing Confusion",hide_when_zero=true,stat_type="condition_chance",is_percentage=true,display_order=3},
    stun_chance={value=0,name="Chance of causing Stun",hide_when_zero=true,stat_type="condition_chance",is_percentage=true,display_order=4},
    min_stun={value=0,name="Minimum Stun Turns",stat_type="condition_turns",hide_when_zero=true,display_order=5},
    max_stun={value=0,name="Maximum Stun Turns",stat_type="condition_turns",hide_when_zero=true,display_order=6},
    min_confusion={value=0,name="Minimum Confusion Turns",stat_type="condition_turns",hide_when_zero=true,display_order=7},
    max_confusion={value=0,name="Maximum Confusion Turns",stat_type="condition_turns",hide_when_zero=true,display_order=8},
    amnesia={value=false,name="Amnesia",description="Causes the target to forget they ever saw you.",display_order=9} --values set to false will be hidden
  },
  possible_upgrades={
    damage={{min_damage=2,max_damage=3},{min_damage=5,max_damage=7,skill_requirements={magic=5}},name="Damage"},
    confusion={{confusion_chance=10,min_confusion=4,max_confusion=6},{confusion_chance=15,min_confusion=2,max_confusion=4},name="Confusion"},
    stun={{stun_chance=10,min_stun=2,max_stun=3},{stun_chance=15,min_stun=1,max_stun=2},name="Stunning"},
    amnesia={{amnesia=true,point_cost=2},name="Amnesia",description="Causes the target to forget they ever saw you.",playerOnly=true}, --Value set to true will just display the name and description
  },
  stat_bonuses_from_skills={
    max_damage={magic={[10]=5}}
  },
  stat_bonuses_per_x_skills={
    min_damage={magic={[5]=1}},
    max_damage={magic={[5]=1}}
  },
	cast = function(self,target,caster)
    local min,max = self:get_stat('min_damage'),self:get_stat('max_damage')
    local confusion = (self:get_stat('confusion_chance') or 0)
    local stun = (self:get_stat('stun_chance') or 0)
		local dmg = target:damage(random(min,max),caster,"magic")
    local text = caster:get_name() .. " blasts " .. target:get_name() .. " with " .. caster:get_pronoun('p') .. " mind, dealing " .. dmg .. " damage."
    if random(1,100) <= stun and (confusion == 0 or self:get_setting('stun')) then
      local turns = random(self:get_stat('min_stun'),self:get_stat('max_stun'))
      local s = target:give_condition('stunned',turns)
      if s then text = text .. " " .. ucfirst(target:get_pronoun('n') .. " is stunned!") end
    end
    if random(1,100) <= confusion and (stun == 0 or self:get_setting('confusion')) then
      local turns = random(self:get_stat('min_confusion'),self:get_stat('max_confusion'))
      local c = target:give_condition('confused',turns)
      if c then text = text .. " " .. ucfirst(target:get_pronoun('n') .. " is confused!") end
    end
    if self:get_stat('amnesia') then
      target:forget(caster)
    end
		if player:can_sense_creature(target) then
      output:out(text)
    end
	end
},

blink = {
	name = "Blink",
	description = "Instantly transports the caster to a random location nearby.",
	target_type = "self",
	cooldown=10,
  AIcooldown=30,
  sound="teleport",
  flags={fleeing=true,defensive=true},
  tags={'teleport','magic'},
  possible_upgrades={
    cooldown={{cooldown=-3},{cooldown=-2},{cooldown=-5},name="Cooldown"},
  },
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
      currMap:add_effect(Effect('animation',{image_name='magicdamage',image_max=5,target={x=origX,y=origY},color={r=255,g=255,b=255}}),origX,origY)
      output:out(caster:get_name() .. " blinks!")
    end
	end
},

demondamager = {
	name = "Demon Fighter",
	description = "You know a lot about demons. Particularly, how to hurt them.",
	target_type = "passive",
  tags={'knowledge'},
  stats = {
    extra_damage={value=25,name="Extra Damage % to demons"}
  },
  possible_upgrades={
    damage={{extra_damage=50,name="Demon Slayer"},{extra_damage=100,name="Demon Obliterator"},name="Increase Damage"}
  },
  calc_damage = function(self,possessor,target,damage)
    if target:is_type('demon') then
      local extra = math.ceil(damage * (self:get_stat('extra_damage')/100))
      return math.ceil(damage + extra)
    else
      return damage
    end
  end
},

scrawny = {
	name = "Scrawny Arms",
	description = "Your arms are basically noodles, and they're not al dente. You can never deal more than 1 damage in melee.",
	target_type = "passive",
  tags={'physical','negative'},
  freeSlot=true,
  forgettable=false,
  calc_damage = function(self,possessor,target,damage)
    return 1
  end
},

summonangel = {
	name = "Summon Angel",
	description = "Summon a holy angel of vengeance.",
	target_type = "self",
  cost=10,
  tags={'holy','summon'},
  level_requirement=3
},

smite = {
    name = "Smite",
    description = "Bring down holy wrath upon a demon, abomination, undead or possessed creature.",
    target_type="creature",
    projectile=false,
    cost=1,
    cooldown = 5,
    min_targets=1,
    max_targets=3,
    tags={'holy','attack'},
    stats = {
      damage={value=15,name="Damage"}
    },
    possible_upgrades={
      damage={{damage=25},{damage=40},name="Damage"},
      cooldown={{cooldown=-5},name="Remove Cooldown"}
    },
    cast = function(self,target,attacker)
      if target:is_type('demon') or target:is_type('undead') or target:is_type('abomination') or target == player or target:has_condition('possessed') then
        dmg = target:damage(tweak(self:get_stat('damage')),attacker,"holy")
        if player:can_see_tile(attacker.x,attacker.y) then output:out(attacker:get_name() .. " smites " .. target:get_name() .. " for " .. dmg .. " holy damage.") end
        if random(1,3) == 1 then
          target:give_condition('stunned',random(2,4))
        end
      else --if not a demon or undead
        output:out(attacker:get_name() .. " tries to smite " .. target:get_name() .. ", but " .. target:get_pronoun('n') .. " isn't an unholy being and remains unsmote.")
        return false
      end
    end, --end use function
    target_requires = function(self,target,caster)
      if target:is_type('demon') or target:is_type('undead') or target:is_type('abomination') or target:has_condition('possessed') then
        return true
      else
        return false,target:get_name() .. " isn't an unholy being and remains unsmote."
      end
    end
  },

homecoming = {
    name = "Homecoming",
    description = "Teleport to the town.",
    target_type = "self",
    tags={'teleport','magic'},
    toggled=true,
    no_manual_deactivate=true,
    max_active_turns=5,
    cast = function(self,caster)
      output:out("You start feeling homesick.")
    end,
    finish = function(self,caster)
      if caster == player then
        goToMap(1,"town",true)
      end
    end
  },
  
  zombieplague = {
    name = "Zombie Plague",
    description = "Living enemies killed by a zombie have a 50% to return as a zombie.",
    target_type = "passive",
    kills = function(self,possessor,victim)
      if random(1,2) == 1 and not victim:is_type("undead") and not victim:is_type("construct") then
        local zpc = Effect('zombieplaguecountdown')
        zpc.creator = possessor
        currMap:add_effect(zpc,victim.x,victim.y)
      end
    end
  },
  
  paralyzingtouch = {
    name = "Paralyzing Touch",
    description = "It is well-known that the touch of a ghoul can temporarily paralyze you. What's not well-known is WHY, but I guess it doesn't really matter.",
    target_type = "creature",
    range=1,
    cooldown=9,
    AIcooldown=18,
    sound="unholydamage",
    stats = {
      turns={value=3,name="Stun Turns"}
    },
    possible_upgrades={
      turns={{turns=5},{turns=7},{turns=10},name="Stun Turns"}
    },
    cast = function(self,target,caster)
      if player:can_see_tile(target.x,target.y) then
        output:out(caster:get_name() .. " paralyzes " .. target:get_name() .. " with a touch!")
        currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,target=target,color={r=150,g=0,b=150}}),target.x,target.y)
      end
      target:give_condition('stunned',tweak(self:get_stat('turns')))
    end
  },
  
  devourcorpse = {
	name = "Devour Corpse",
	description = "Eat a dead body (including a body in a grave) to regain health. Gross.",
  sound = "devourcorpse",
	target_type = "self",
	cast = function(self,target,caster)
		local contents = currMap.contents[caster.x][caster.y]
		local eaten = false
		for i, content in pairs(contents) do
			if content.id == "corpse"then -- if it's a corpse
				local hp = tweak(5)
				output:out("You chow down on the remains of " .. content.creature:get_name() .. ", regaining " .. hp .. " HP.")
				caster:updateHP(hp)
				currMap:add_feature(Feature('chunk',content.creature),caster.x,caster.y)
				currMap.contents[caster.x][caster.y][i] = nil
				eaten = true
      elseif content.id == "grave" and content.possessable == true then
        local hp = tweak(3)
        output:out("You dig up the grave and chow down on the rotting corpse held within, regaining " .. hp .. " HP.")
				caster:updateHP(hp)
        content.image_name = "emptygrave"
        content.symbol="ø"
        content.name = "Empty Grave"
        content.description = "Where a body used to be buried."
        content.possessable = false
				eaten = true
			end
		end
		if (eaten == false) then output:out("There's no corpse here to eat.") return false end
	end,
  requires = function(self,caster)
    for i, content in pairs(currMap.contents[caster.x][caster.y]) do
      if content.id == "corpse" or (content.id == "grave" and content.possessable == true) then
        return true
      end
    end
    return false,"There's no corpse here to eat."
  end
},

poisoncloud = {
	name = "Poison Gas",
	description = "Spray your exterminator's gas. Be careful not to get caught in the cloud, the gas is extremely poisonous!",
	cooldown = 10,
  range=5,
  projectile = true,
	flags = {aggressive=true},
	target_type = "tile",
  sound="spray_long",
	cast = function (self,target,caster)
		if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " sprays poison gas!") end
		for x=target.x-1,target.x+1,1 do
			for y=target.y-1,target.y+1,1 do
				if (currMap[x][y] ~= "#") then
          local hasGas = currMap:tile_has_feature(x,y,'poisongas')
          if hasGas then
            hasGas.strength = hasGas.strength+(6-hasGas.strength)
            if x == target.x and y == target.y then hasGas.strength = hasGas.strength+1 end
            hasGas.color.a = math.min(255,hasGas.strength*50)
          else
            local gas = Effect('poisongas')
            gas.creator = caster
            currMap:add_effect(gas,x,y)
            if (x ~= target.x or y ~= target.y) then
              gas.strength = 5
              gas.color.a = 200
            end
          end
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
  end --end target draw function
},

trap = {
	name = "Set Trap",
	description = "Lay down a trap to catch your enemies.",
	cooldown = 5,
	target_type = "self",
  flags={defensive=true, fleeing=true},
  sound="metal_click",
	cast = function (self,target,caster)
		local t = Feature('trap')
		currMap:add_feature(t,caster.x,caster.y)
	end
},

--Pyromancer class spells
smallfireball = {
	name="Small Fireball",
	description="Shoots a small fireball.",
	cooldown=5,
  cost=5,
	target_type = "creature",
  free_aim=true,
  projectile = true,
  tags={'fire','attack','magic'},
	flags = {aggressive=true},
	cast = function(self,target,caster)
    if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " shoots a fireball.") end
    Projectile('smallfireball',caster,target)
	end
},

fireaura = {
	name = "Fiery Aura",
	description = "A radius of intense heat flares out from you, dealing damage to all who dare approach.",
	toggled=true,
  cost_per_turn=2,
	target_type = "self",
	cast = function(self,target,caster)
    caster:give_condition('fireaura',-1,caster)
	end,
  finish = function(self,target,caster)
    caster:cure_condition('fireaura')
    for x=caster.x-1,caster.x+1,1 do
      for y=caster.y-1,caster.y+1,1 do
        if currMap:in_map(x,y) then
          local eff = currMap:tile_has_effect(x,y,'fireaura')
          if eff then
            eff:delete()
          end
        end
      end
    end
  end
},

explodingfireball = {
	name="Exploding Fireball",
	description="Blasts an enormous fireball at an area.",
	cooldown=20,
  cost=20,
	target_type = "creature",
  free_aim = true,
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
},

firebrand = {
	name = "Fire Brand",
	description = "Encases your weapon in flames, causing it to deal extra fire damage.",
  cost=10,
	target_type = "self",
	flags = {aggressive=true},
  tags={'fire','buff','magic'},
  toggled=true,
	cast = function (self,target,caster)
    local weapons = caster:get_equipped_in_slot('wielded')
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
},

--Necromancer class spells:
reanimate = {
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
        currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,target=target,color={r=150,g=0,b=150}}),target.x,target.y)
				return true
			end
		end
		output:out("There's no corpse there to animate.")
		return false
	end
},

sacrificecorpse = {
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
      local mp = tweak((corpse.creature.level or 1)*10)
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " sacrifices " .. corpse.creature:get_name() .. " to the darkness, gaining " .. mp .. " MP!")
        currMap:add_effect(Effect('animation',{image_name='floatingpluses',image_max=5,target=caster,color={r=235,g=137,b=49,a=255},ascii=true,use_color_with_tiles=true}),caster.x,caster.y)
        output:sound("unholydamage")
      end
      currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,target=target,color={r=150,g=0,b=150}}),target.x,target.y)
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
      currMap:add_effect(Effect('animation',{image_name='floatingpluses',image_max=5,target=possessor,color={r=235,g=137,b=49,a=255},ascii=true,use_color_with_tiles=true}),possessor.x,possessor.y)
      currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,color={r=255,g=255,b=0}}),victim.x,victim.y)
      if possessor == player then
        output:sound('unholydamage')
        output:out("Killing " .. victim:get_name() .. " grants you evil power!")
      end
    end
  end,
  ally_kills = function(self,possessor,victim,killer)
    if not victim:is_type('undead') then
      possessor.magic = possessor.magic + 2
      currMap:add_effect(Effect('animation',{image_name='floatingpluses',image_max=5,target=possessor,color={r=235,g=137,b=49,a=255},ascii=true,use_color_with_tiles=true}),possessor.x,possessor.y)
      currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,color={r=255,g=255,b=0}}),victim.x,victim.y)
      if possessor == player then
        output:sound('unholydamage')
        output:out("The death of " .. victim:get_name() .. (killer and " at the hands of " .. killer:get_name() or "") .. " grants you evil power!")
      end
    end
  end
},

corpseburst = {
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
},

witheringcurse = {
	name = "Withering Touch",
	description = "You're so full of pathogens that just touching a creature will give them a horrible disease that weakens their muscles and causes their skin to rot off their body.",
	target_type = "creature",
  cooldown=30,
  range=1,
  tags={'unholy','curse','necromancy','magic'},
	cast = function (self,target,caster)
		target:give_condition('witheringcurse',-1)
	end
},

auraoffear = {
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
  },

undeadlegion = {
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
},

shademaker = {
    name = "Leader of the Dead",
    description = "Anytime you or your minions kill a living creature, you'll draw forth a shade to join your unholy crusade.",
    target_type = "passive",
    tags={'unholy','necromancy','summon','magic'},
    kills = function(self,possessor,victim)
      if possessor.id == "deathknight" or (possessor.master and possessor.master.id == "deathknight") then
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
  },

lifedrain = {
  name = "Life Drain",
  description = "Drain health out of a nearby target.",
  target_type = "creature",
  cooldown=10,
  AIcooldown=20,
  flags={aggressive=true},
  tags={'unholy','attack','magic'},
  toggled=true,
  deactivate_on_all_actions=true,
  no_manual_deactivate=true,
  cost_per_turn=1,
  max_active_turns=3,
  deactivate_on_damage_chance=50,
  stats = {
    damage={value=15,name="Damage"}
  },
  possible_upgrades={
    damage={{damage=20},{damage=30},name="Damage"},
    turns={{max_active_turns=2},{max_active_turns=5},name="Max Active Turns"},
    deactivate_chance={{deactivate_on_damage_chance=-25},{deactivate_on_damage_chance=-25},name="Deactivation Chance"}
  },
  stat_bonuses_from_spells={
    damage={vampirism=5}
  },
  stat_bonuses_per_x_skills={
    damage={bloodpotency={[1]=1}}
  },
  cast = function(self,target,caster)
    if target:is_type('undead') or target:is_type('construct') then
      if caster == player then output:out("You can't drain the life out of something that's not alive.") end
      return false
    end
    if player:can_see_tile(caster.x,caster.y) then
      output:out(caster:get_name() .. " begins draining the life from " .. target:get_name() .. ".")
    end
  end,
  advance_active = function(self,target,caster)
    local dmg = target:damage(tweak(self:get_stat('damage')),caster,'dark')
    caster:updateHP(dmg)
    if player:can_see_tile(caster.x,caster.y) then
      output:out(caster:get_name() .. " drains " .. dmg .. " HP from " .. target:get_name() .. ".")
      currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,target=target,color={r=150,g=0,b=150}}),target.x,target.y)
      output:sound('unholydamage')
    end
    if target.hp < 1 then
      self:finish(target,caster)
    end
  end
},

graspingdead = {
  name = "Grasping Dead",
  description = "Skeletal hands will erupt from the ground, grabbing onto all nearby, scratching them and preventing them from moving.",
  target_type = "tile",
  cooldown=15,
  AIcooldown=30,
  sound="graspingdead",
  flags={aggressive=true},
  tags={'unholy','necromancy','magic'},
  stats = {
    radius={value=1,name="Tile Radius"},
  },
  possible_upgrades={
    radius={{radius=2},name="Tile Radius"}
  },
  cast = function (self,target,caster)
		if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " calls forth grasping dead from the earth!") end
    local radius = self:get_stat('radius')
		for x=target.x-radius,target.x+radius,1 do
			for y=target.y-radius,target.y+radius,1 do
				if (currMap[x][y] ~= "#") then
          local dead = currMap:tile_has_effect(x,y,'graspingdead')
          if dead then
            dead.turns = dead.turns+(6-dead.turns)
          else
            local graspingdead = Effect('graspingdead')
            graspingdead.creator = caster
            currMap:add_effect(graspingdead,x,y)
          end --end already have if
				end
			end
		end
	end,
  get_target_tiles = function(self,target,caster)
    local targets = {}
    local radius = self:get_stat('radius')
    for x=target.x-radius,target.x+radius,1 do
      for y=target.y-radius,target.y+radius,1 do
        targets[#targets+1] = {x=x,y=y}
      end --end fory
    end --end forx
    return targets
  end, --end target draw function
  decide = function(self,target,caster)
    if target:is_type('flyer') then return false end
  end --end creature for
},

bloodrain = {
  name = "Rain of Blood",
  description = "Causes blood to rain down, terrifying all in the area, and potentially getting them sick.",
  target_type = "tile",
  cooldown=10,
  sound="rain",
  tags={'unholy','blood','magic'},
  stats = {
    radius={value=3,name="Tile Radius"},
  },
  possible_upgrades={
    radius={{radius=5},name="Tile Radius"}
  },
  cast = function(self,target,caster)
    local radius = self:get_stat('radius')
    for x = target.x-radius,target.x+radius,1 do
      for y = target.y-radius,target.y+radius,1 do
        if currMap:in_map(x,y) and calc_distance(x,y,target.x,target.y) <= radius and currMap:isClear(x,y,nil,true) and currMap:is_line(x,y,target.x,target.y,true) then
          local rain = Effect('bloodrain')
          currMap:add_effect(rain,x,y)
        end --end x,y check if
      end --end fory
    end --end forx
  end,
  get_target_tiles = function(self,target,caster)
    local targets = {}
    local radius = self:get_stat('radius')
    for x=target.x-radius,target.x+radius,1 do
      for y=target.y-radius,target.y+radius,1 do
        if calc_distance(x,y,target.x,target.y) <= radius and currMap:is_line(x,y,target.x,target.y,true) then targets[#targets+1] = {x=x,y=y} end
      end --end fory
    end --end forx
    return targets
  end, --end target draw function
  decide = function(self,target,caster)
    if target:is_type('undead') or target:is_type('construct') then return false end
  end --end creature for --end target draw function
},

enfeeble = {
  name = "Enfeeble",
  description = "Permanently reduces a creature's maximum HP.",
  target_type = "creature",
  cooldown=25,
  sound="enfeeble",
  tags={'unholy','curse','magic'},
  stats = {
    reduction={value=25,name="HP Reduction %"},
  },
  possible_upgrades={
    reduction={{reduction=35},{reduction=50},name="HP Reduction %"}
  },
  cast = function(self,target,caster)
    if target:is_type('undead') then
      if caster == player then output:out("You can't destroy the life force of an undead creature.") end
      return false
    end
    local amt = math.ceil(target.max_hp * (self.get_stat('reduction')/100))
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
},

decayaura = {
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
},

painbolt = {
    name = "Bolt of Darkness",
    description = "Send unholy energy through a target's body. This deals damage to living creatures and heals undead ones.",
    projectile=false,
    target_type="creature",
    cost=1,
    tags={'unholy','attack','magic'},
    stats = {
      damage={value=10,name="Damage"},
    },
    possible_upgrades={
      damage={{damage=20},{damage=30},name="Damage"}
    },
    cast = function(self,target,attacker)
      local base_dmg = self:get_stat('damage')
      if target:is_type('undead') then
        local dmg = tweak(base_dmg)
        if player:can_see_tile(attacker.x,attacker.y) then
          output:out(attacker:get_name() .. " heals " .. target:get_name() .. " for " .. dmg .. " damage.")
          currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,target=target,color={r=150,g=0,b=150}}),target.x,target.y)
          output:sound("unholydamage")
        end
        target:updateHP(dmg)
      else
        local dmg = target:damage(tweak(base_dmg),attacker,"unholy")
        if player:can_see_tile(attacker.x,attacker.y) then
          output:out(attacker:get_name() .. " gestures at " .. target:get_name() .. ". " .. ucfirst(target:get_pronoun('n')) .. " convulses with pain, taking " .. dmg .. " damage.")
          currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,target=target,color={r=150,g=0,b=150}}),target.x,target.y)
          output:sound("unholydamage")
        end
      end
    end
  },

rigormortis = {
    name = "Rigor Mortis",
    target_type = "creature",
    cooldown = 15,
    AIcooldown=30,
    description = "Causes the target's joints to lock up, preventing them from moving for a short while.",
    flags={aggressive=true,defensive=true,fleeing=true},
    tags={'unholy','curse','magic'},
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " gestures at " .. target:get_name() .. ". " .. ucfirst(target:get_pronoun('p')) .. " joints lock up!") end
      currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,target=target,color={r=150,g=0,b=150}}),target.x,target.y)
      output:sound('unholydamage')
      target:give_condition('stunned',tweak((target:is_type('undead') and 8 or 4)))
    end
  },

deadlypremonition = {
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
        currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,target=target,color={r=150,g=0,b=150}}),target.x,target.y)
        target:give_condition('fear',tweak(30))
        target.fear = target.fear + 50
      else
        if caster == player then output:out(caster:get_name() .. " doesn't have a mind. You can't fill " .. target:get_pronoun('p') .. " mind with visions of death.") end
        return false
      end
    end
  },
  
--Mystic archer abilities:
firearrows = {
	name = "Fire Arrows",
	description = "Applies fire to your ranged weapon attacks.",
	target_type = "self",
	flags = {aggressive=true},
  tags={'fire','buff','magic'},
  toggled=true,
  freeSlot=true,
  mysticarrow=true,
  cast = function(self,target,caster)
    if caster == player then
      output:out("You feel a slight warmth in your hands.")
    end
    for _, spell in pairs(caster:get_spells()) do
      if spell ~= self and spell.active and spell.mysticarrow then
        spell:finish(target,caster)
      end
    end
	end,
  use_ranged_ability=function(self,attacker,target,ranged_attack,item)
    if self.active == true then
      if item:apply_enchantment('fireweapon',1) then
        attacker.mp = attacker.mp - 1
      end
    end
  end
},

icearrows = {
	name = "Ice Arrows",
	description = "Applies ice to your ranged weapon attacks.",
	target_type = "self",
	flags = {aggressive=true},
  tags={'ice','buff','magic'},
  toggled=true,
  freeSlot=true,
  mysticarrow=true,
  cast = function(self,target,caster)
    if caster == player then
      output:out("You feel a slight chill in your hands.")
    end
    for _, spell in pairs(caster:get_spells()) do
      if spell ~= self and spell.active and spell.mysticarrow then
        spell:finish(target,caster)
      end
    end
	end,
  use_ranged_ability=function(self,attacker,target,ranged_attack,item)
    if self.active == true then
      if item:apply_enchantment('iceweapon',1) then
        attacker.mp = attacker.mp - 1
      end
    end
  end
},
  
--Vampire abilities:

vampirism = {
	name = "Vampirism",
	description = "You regain some health when you damage an enemy.",
	target_type = "passive",
  unlearnable = true, --If true, this spell will not show up in spell books or factions to be learned unless explicitly put there
  forgettable=false,
  freeSlot=true,
  tags={'unholy','physical','vampire'},
  upgrade_stat="upgrade_points_vampirism",
  stats = {
    health_absorbed={value=25,name="Damage Converted to Health/Blood",is_percentage=true},
  },
  possible_upgrades = {
    health_absorbed={{health_absorbed=25},{health_absorbed=25},{health_absorbed=25},name="Health Absorbed"}
  },
	damages = function(self,possessor,target,damage)
    if (random(1,2) == 1 and not target:is_type('bloodless')) or target:has_condition('bleeding') then
      local hp = tweak(damage*math.ceil(self:get_stat('health_absorbed')/100))
      if player:can_see_tile(possessor.x,possessor.y) and hp > 0 then
        output:out(possessor:get_name() .. " drains some blood from " .. target:get_name() .. ", regaining " .. hp .. " HP!")
        if possessor.extra_stats.blood then
          possessor.extra_stats.blood.value = math.min(possessor.extra_stats.blood.value+hp,possessor.extra_stats.blood.max)
        end
        --local blood = currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="bleeding",symbol="",image_base="bloodmagicdamage",image_max=4,speed=0.20,color={r=255,g=0,b=0,a=125}}),possessor.x,possessor.y)
        local blood = currMap:add_effect(Effect('animation',{image_name='bloodmagicdamage',image_max=5,target=target,color={r=255,g=255,b=255}}),target.x,target.y)
        if possessor == player or target == player then output:sound('vampirism') end
      end
      possessor:updateHP(hp)
    end
	end,
  advance = function(self,possessor)
    if possessor == player and possessor.extra_stats.blood then
      local turns = math.max(possessor:get_skill('bloodmetabolism'),1)
      if currGame.stats.turns % turns == 0 then
        local val = 1 + possessor:get_bonus('blood_consumption')
        possessor.extra_stats.blood.value = math.max(possessor.extra_stats.blood.value-val,0)
      end
      if possessor.extra_stats.blood.value < 1 then
        possessor:give_condition('bloodstarved',-1)
      else
        possessor:cure_condition('bloodstarved',-1)
      end
    end
  end
},

batform = {
  name = "Bat Form",
	description = "You temporarily transform into a vampire bat. While in bat form, your blood pool will drain more quickly.",
	target_type = "self",
  unlearnable = true, --If true, this spell will not show up in spell books or factions to be learned unless explicitly put there
  forgettable=false,
  freeSlot=true,
  tags={'vampire','physical'},
  cast = function(self,target,caster)
    if player:can_sense_creature(caster) then
      output:out(caster:get_name() .. (caster:is_type('intelligent') and " shouts \"Bat!\" and " or "") .. " turns into a bat.")
    end
    caster:give_condition('batform',-1)
    local bat = caster:transform('vampirebat',nil,{level=caster.level,active_undo=true})
    bat.extra_stats.blood = caster.extra_stats.blood
    bat.skills.bloodpotency = caster.skills.bloodpotency
    for skillID,val in pairs(caster.skills) do
      local skill = possibleSkills[skillID]
      if skill.skill_type == "vampirism" then
        bat.skills[skillID] = val
      end
    end
  end
},

outforblood = {
    name = "Out for Blood",
    target_type = "self",
    description = "Increases the damage you deal in combat and the chance of a critical hit.",
    sound="bleeding",
    freeSlot=true,
    forgettable=false,
    stat_cost={blood=10},
    possible_upgrades = {
      cost={{stat_cost={blood=-1}}},
    },
    cast = function(self,target,caster)
      caster:give_condition('outforblood',25)
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " gives " .. caster:get_pronoun('o') .. "self bloodrage.")
        output:sound('haste')
      end
    end
  },

slimesplit = {
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
},

curse = {
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
},

knockbackimmunity = {
    name = "Immune to Knockbacks",
    description = "You're incredibly massive, and can't be knocked backwards. Good for you.",
    target_type = "passive",
    tags={'physical'}
  },

sleepless = {
    name = "Sleepless",
    description = "You don't sleep. On the plus side, spells and abilities that make people fall asleep don't work on you. On the minus side, you don't dream. On the plus side, you don't have nightmares.",
    target_type = "passive",
    tags={'physical'}
  },

sporedeath = {
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
  },

passiverage = {
    name = "Anger Management Problems",
    description = "You're very angry. As you take damage, your fury builds, eventually exploding into a terrible rage.",
    target_type="passive",
    tags={'physical'},
    freeSlot=true,
    forgettable=false,
    damaged = function(self,possessor, attacker,amt,dtype)
      local perc = math.ceil((amt/possessor:get_max_hp())*100)*2
      if possessor.extra_stats.fury then
        local newVal = possessor:update_extra_stat('fury',perc)
        if newVal >= possessor.extra_stats.fury.max then
          possessor:give_condition('enraged',-1)
        end
      end
    end
  },
  
  activerage = {
    name = "Willful Rage",
    description = "You can rage at will.",
    cooldown=25,
    target_type="self",
    tags={'physical'},
    freeSlot=true,
    forgettable=false,
    cast = function(self,target,caster)
      if player:can_sense_creature(caster) then
        output:out(caster:get_name() .. " enters a rage!")
      end
      caster:give_condition('enraged',-1)
    end
  },
  
  ragefulsmack = {
    name = "Raging Smackdown",
    description = "Your anger fills your swings with power! Perform an attack that's guaranteed to critically hit.",
    cooldown=5,
    range=1,
    stat_cost={fury=10},
    target_type="creature",
    tags={'physical'},
    freeSlot=true,
    forgettable=false,
    cast = function(self,target,caster)
      caster:give_condition('guaranteedcrit',1)
      caster:attack(target)
    end
  },

yawp = {
    name = "Barbaric Yawp",
    description = "Sound a barbaric yawp over the roofs of the world, stunning and/or terrifying all who hear.",
    target_type="self",
    sound="yawp",
    cooldown=10,
    stat_cost={fury=10},
    flags={aggressive=true,defensive=true,fleeing=true},
    tags={'physical'},
    freeSlot=true,
    forgettable=false,
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
},

webshot = {
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
  },

poisonbite = {
    name = "Poison Bite",
    description = "Sink your fangs and/or mandibles in.",
    target_type = "creature",
    range=1,
    cooldown=9,
    AIcooldown=18,
    sound="unholydamage",
    tags={'physical','poison'},
    cast = function(self,target,caster)
      if player:can_see_tile(target.x,target.y) then
        output:out(caster:get_name() .. " injects " .. target:get_name() .. " with poison!")
        currMap:add_effect(Effect('animation',{image_name='poisondamage',image_max=5,target=target,color={r=150,g=0,b=150}}),target.x,target.y)
      end
      target:give_condition('poisoned',tweak(5))
    end
  },

heal_other = {
    name = "Heal Other",
    target_type = "creature",
    cooldown = 5,
    description = "Practice the healing arts on a nearby creature. If cast on an unfriendly creature, there's a chance they will become friendly towards you.",
    flags={friendly=true},
    types={'healing','holy'},
    always_learnable = true,
    learn_point_cost = 3,
    cast = function(self,target,caster)
      if target == caster then output:out("You can't use this ability to heal yourself. That's too selfish.") return false end
      if target.hp < target:get_max_hp() then
        if caster:touching(target) then
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
          --[[if not shitlist and target.master == nil and target.faction ~= "chaos" and (caster.faction == nil or target.enemy_factions == nil or not in_table(caster.faction,target.enemy_factions)) and random(1,100) < 10 then --10% chance of currently non-hostile to become thrall of caster if they're not in an enemy faction
            target:become_thrall(caster)
          end]]
        else --if not touching
          Projectile('healthsyringe',caster,target)
        end
      else
        if caster == player then output:out(target:get_name()  .. " isn't hurt. Healing them wouldn't be worthwhile.") end
        return false
      end
    end,
    decide = function(self,target,caster)
      local creats = caster:get_seen_creatures()
      local mostDmg, dmgedCreat = nil,nil
      if creats then
        for _,creat in pairs(creats) do
          if caster:is_enemy(creat) == false and creat ~= caster then
            local dmg = (creat:get_max_hp()-creat.hp)
            if (mostDmg == nil or dmg > mostDmg) and dmg > 0 then
              mostDmg,dmgedCreat = dmg,creat
            end --end damage if
          end --end enemy if
        end --end creature for
      end --end self sees if
      return dmgedCreat or false
    end
  },
}

possibleSpells['doubleshot'] = {
  name = "Double Shot",
  description = "If you're holding two guns, you can shoot at two different targets at once.",
  target_type="creature",
  free_aim=true,
  min_targets=2,
  max_targets=2,
  cast_accepts_multiple_targets=true,
  forgettable=false,
  freeSlot=true,
  cast = function(self,targets,caster)
    for _,target in pairs(targets) do
      for _, attack in pairs(caster:get_ranged_attacks()) do
        
      end
    end
  end,
  requires = function(self,caster)
    
  end
}

possibleSpells['fanhammer'] = {
  name = "Fan the Hammer",
  description = "Unload all your ammo at a target.",
  target_type="creature",
  free_aim=true,
  forgettable=false,
  freeSlot=true,
  cast = function(self,target,caster)
    
  end
}

possibleSpells['undotransform'] = {
  name = "Undo Transformation",
  description = "Transform back into your regular self.",
  target_type="self",
  freeSlot=true,
  forgettable=false,
  cast = function(self,target,caster)
    caster:undo_transformation()
  end
}
