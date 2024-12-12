conditions = {
	poisoned=Condition({
		name = "Poisoned",
		bad = true,
    bonuses={fear=10},
		applied = function (self,possessor)
      if possessor:is_type('undead') or possessor:is_type('construct') then return false end
			if player:can_see_tile(possessor.x,possessor.y) and player:does_notice(possessor) then output:out(possessor:get_name() .. " is poisoned!") end
		end,
		advance = function(self,possessor)
			if (random(1,3) == 1) then 
        local dmg = possessor:damage(random(1,math.floor(possessor.max_hp/10)),possessor.conditions.poisoned.applier,"poison")
        if player:can_see_tile(possessor.x,possessor.y) and player:does_notice(possessor) then output:out(possessor:get_name() .. " takes " .. dmg .. " damage from poison.") end
      end
		end,
		cured = function (self,possessor)
      possessor.poisonBubbleClock = nil
			if player:can_see_tile(possessor.x,possessor.y) and player:does_notice(possessor)  then output:out(possessor:get_name() .. " is no longer poisoned.") end
		end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.poisonBubbleClock = (possessor.poisonBubbleClock or 0) - dt
        if (possessor.poisonBubbleClock <= 0 and random(1,5) == 1) and player:does_notice(possessor)  then
          local z = Effect('bubble',possessor.x,possessor.y)
          z.color = {r=0,g=255,b=0,a=255}
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.poisonBubbleClock = 1
        end
      end
    end
	}),

regenerating=Condition({
		name = "Regenerating",
    bonuses={fear=-10},
		advance = function(self,possessor)
			if (random(1,3) == 1) then 
        possessor:updateHP(math.floor(possessor:get_max_hp()/20))
      end
		end
	}),

disease = Condition({
		name = "Diseased",
    bonuses={notice_chance=-10,hit_chance=-15,dodge_chance=-15,damage_percent=-25,critical_chance=-100,speed=-10},
	}),

bleeding=Condition({
		name = "Bleeding",
		bad = true,
    bonuses={fear=10},
		applied = function (self,possessor)
      if possessor:is_type('bloodless') then return false end
			if player:can_see_tile(possessor.x,possessor.y) and player:does_notice(possessor) then
        output:out(possessor:get_name() .. " starts bleeding all over the place!")
        output:sound('bleeding')
      end
      local blood = currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="bleeding",symbol="",image_base="bloodmagicdamage",image_max=4,speed=0.20,color={r=255,g=0,b=0,a=125}}),possessor.x,possessor.y)
		end,
		advance = function(self,possessor)
			if (random(1,3) == 1) then 
        local dmg = possessor:damage(random(math.ceil(possessor.max_hp/20),math.floor(possessor.max_hp/10)),possessor.conditions.bleeding.applier,"physical")
        if player:can_see_tile(possessor.x,possessor.y) and player:does_notice(possessor) then output:out(possessor:get_name() .. " takes " .. dmg .. " damage from bleeding.") end
        if not currMap:tile_has_feature(possessor.x,possessor.y,'bloodstain') then currMap:add_feature(Feature('bloodstain',possessor.bloodColor),possessor.x,possessor.y) end
      end
		end
	}),
	
	onfire=Condition({
		name = "On Fire",
		bad = true,
    bonuses={fear=50,stealth=-1000,notice_chance=-10},
		applied = function (self,possessor)
			if possessor.id ~= "asteroidgolem" then
        if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " catches on fire!") end
        local fire = currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="onfire",symbol="#",symbols={"*","#","%","&"},image_base="onfireflame",image_max=4,speed=0.20,yMod=2,color={r=255,g=0,b=0,a=125}}),possessor.x,possessor.y)
      end
		end,
		advance = function(self,possessor)
			if not possessor:is_type('fireImmune') then possessor:damage(random(1,5),possessor.conditions.onfire.applier,"fire") end
      for _, feat in pairs(currMap:get_tile_features(possessor.x,possessor.y)) do
        if feat.fireChance and random(1,100) <= feat.fireChance then
          feat:combust()
        end
      end
		end,
		cured = function (self,possessor)
			if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " is no longer on fire.") end
      possessor.noWater = nil
		end,
    dies = function(self,possessor)
      return self:cured(possessor)
    end,
    ai = function(self,possessor)
      if possessor.target and possessor.target.water and possessor:can_move_to(possessor.target.x,possessor.target.y) then
        ai.dumbpathfind(possessor)
        return false
      elseif possessor.noWater then
        ai.basic(possessor)
        return false
      else
        local closestDist = nil
        local closest = nil
        for x=possessor.x-10,possessor.x+10,1 do
          for y=possessor.y-10,possessor.y+10,1 do
            local waters = currMap:get_tile_features(x,y)
            for _,feat in pairs(waters) do
              if feat.water == true then
                local dist = calc_distance_squared(x,y,possessor.x,possessor.y)
                if not closest or not closestDist or dist < closestDist and possessor:can_move_to(x,y) then
                  closest = feat
                  closestDist = dist
                  possessor.target = closest
                  break
                end --end closest if
              end --end water if
            end --end feature for
          end --end fory
        end --end forx
        if not closest then
          possessor.noWater = true
        end
        return self:ai(possessor)
      end
    end
	}),
	
	fireaura = Condition({
		name = "Fiery Aura",
    applied = function(self,possessor,applier)
      if player:can_see_tile(possessor.x,possessor.y) and possessor:has_condition('fireaura') == false and (possessor == player or applier == player) then
        output:sound('fireaura')
      end
    end,
		advance = function(self,possessor)
			for x=possessor.x-1,possessor.x+1,1 do
				for y=possessor.y-1,possessor.y+1,1 do
          if currMap:in_map(x,y) then
            local e = currMap:tile_has_effect(x,y,'fireaura')
            if not e then
              local fire = Effect('fireaura',possessor)
              currMap:add_effect(fire,x,y)
              fire:refresh_image_name()
            end
          end --end makeFire if
				end --end yfor
			end --end xfor
		end
	}),
	
	slimy = Condition({
		name = "Slimy",
		bad = true,
		bonuses={hit_chance=-15,dodge_chance=-10,speed=-20,animation_time_percent=1.25},
    applied = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="slimy",symbol="",image_base="personalcloud",spritesheet=true,image_max=5,speed=0.3,color={r=0,g=255,b=0,a=100},use_color_with_tiles=true}),possessor.x,possessor.y)
      if player:can_sense_creature(possessor) then output:sound('splat_hits_creature') end
    end
	}),

slipping = Condition({
    name = "Slipping",
    bad = true,
    update = function(self,possessor,dt)
      possessor.conditions['slipping'] = nil --Remove the condition so it never actually shows up
      if not possessor.slipX or not possessor.slipY then
        return
      end
      local newX,newY=possessor.x+possessor.slipX,possessor.y+possessor.slipY
      if not currMap:isClear(newX,newY) then
        local creat = currMap:get_tile_creature(newX,newY)
        if creat then
          local dmg = possessor:damage(tweak(possessor.max_hp/random(10,20)),possessor)
          local tdmg = creat:damage(tweak(possessor.max_hp/random(10,20)),possessor)
          if player:can_see_tile(possessor.x,possessor.y) then
            output:out(possessor:get_name() .. " slips and crashes into " .. creat:get_name() .. "! " .. ucfirst(possessor:get_name()) .. " takes " .. dmg .. " damage, and " .. creat:get_name() .. " takes " .. tdmg .. " damage.")
            output:sound('collision_creature')
          end
          return
        elseif currMap:tile_has_feature(newX,newY,"chasm") then
          if not possessor:is_type('knockedback') then
            if possessor.types then table.insert(possessor.types,'knockedback') else possessor.types = {'knockedback'} end --make them a "knockedback," so they can go over pits n shit
          end
          if player:can_see_tile(possessor.x,possessor.y) then
            output:out(possessor:get_name() .. " slips and falls into a chasm!")
          end
          possessor:moveTo(newX,newY)
          --remove knockedback so they'll actually fall
          local key = in_table('knockedback',possessor.types)
          if key then table.remove(possessor.types,key) end
          if count(possessor.types) == 0 then possessor.types = nil end
          currMap:enter(newX,newY,possessor)
          return
        else --no creat and no chasm, basically just a wall then
          if currMap[newX][newY] == "#" then
            local dmg = possessor:damage(tweak(possessor.max_hp/random(10,20)),possessor)
            if player:can_see_tile(possessor.x,possessor.y) then
              output:out(possessor:get_name() .. " slips and crashes into the wall! " .. ucfirst(possessor:get_name()) .. " takes " .. dmg .. " damage.")
              output:sound('collision_wall')
            end
          else
            local feat = nil
            for _,f in pairs(currMap:get_contents(newX,newY)) do
              if (f.blocksMovement == true) then
                feat = f
                break
              end
            end --end for
            local dmg = possessor:damage(tweak(possessor.max_hp/random(10,20)),possessor)
            local tdmg = 0
            if feat and feat.attackable then
              tdmg = feat:damage(tweak(possessor.max_hp/random(10,20)),possessor)
            end
            if player:can_see_tile(possessor.x,possessor.y) then
              output:out(possessor:get_name() .. " slips and crashes into " .. (feat and feat:get_name() or "something") .. "! " .. ucfirst(possessor:get_name()) .. " takes " .. dmg .. " damage" .. (feat and feat.attackable and type(tdmg) == "number" and " and " .. feat:get_name() .. " takes " .. tdmg .. " damage." or "."))
            end
          end
          return
        end --end type of obstacle if
      end --end isClear if
      --Generic slip:
      if player:can_see_tile(possessor.x,possessor.y) then
        output:out(possessor:get_name() .. " slips!")
        if possessor == player then output:sound('slip') end
      end
      possessor:moveTo(newX,newY)
    end
  }),

  webbed = Condition({
    name = "Webbed",
		bad = true,
		bonuses={hit_chance=-15,dodge_chance=-20,animation_time_percent=1.25},
    moves = function(self,possessor)
      if (random(1,4) == 2) then
        possessor:cure_condition('webbed')
        return true
      else
        if player:can_sense_creature(possessor) then output:out(possessor:get_name() .. " struggles against the webbing.") end
        return false
      end --end if
    end --end moves function
  }),
  
	
	teleportCountdown=Condition({
		name = "Teleport Countdown",
		--hidden=true,
		cured = function(self,possessor)
      local origX,origY = possessor.x,possessor.y
			local x,y=random(2,currMap.width-1), random(2,currMap.height-1)
			while (x<2 or y<2 or x>currMap.width or y>currMap.height or currMap:is_passable_for(x,y,possessor.pathType) == false) do
				x,y = random(2,currMap.width-1), random(2,currMap.height-1)
			end
			possessor:moveTo(x,y)
      if player:can_see_tile(origX,origY) then
        output:out(possessor:get_name() .. " teleports away!")
        currMap:add_effect(Effect('animation',{image_name='magicdamage',image_max=5,target={x=origX,y=origY},color={r=255,g=255,b=255}}),origX,origY)
        output:sound('teleport')
      end
		end
	}),
	
	trapped = Condition({
		name = "Trapped",
    applied = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="trapped",symbol="",image_base="trapshake",image_max=3,speed=possessor.animation_time,sequence=true,reverse=true,color={r=255,g=255,b=255,a=255},use_color_with_tiles=false,spritesheet=true}),possessor.x,possessor.y)
    end,
		moves = function(self, possessor)
      if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " struggles against the trap.") end
			return false
		end
	}),

entangled = Condition({
		name = "Entangled",
		moves = function(self, possessor)
			if possessor == player then output:out("You struggle against the entanglement.") end
			return false
		end,
    attacks = function(self, possessor)
			if possessor == player then output:out("You struggle against the entanglement.") end
			return false
		end
	}),

boundindarkness = Condition({
  name = "Bound in Darkness",
  advance = function(self,possessor)
    local darkness = currMap:tile_has_effect(possessor.x,possessor.y,'darkness')
    local dmg = tweak((darkness and 15 or 10))
    dmg = possessor:damage(dmg,possessor.conditions.boundindarkness.applier,"unholy")
    if player:can_sense_creature(possessor) then 
      output:out(possessor:get_name() .. " takes " .. dmg .. " damage from the unholy binds.")
    end
  end,
  moves = function(self, possessor)
    if player:can_sense_creature(possessor) then output:out(possessor:get_name() .. " struggles against the darkness.") end
    return false
  end,
  attacks = function(self, possessor)
    if player:can_sense_creature(possessor) then output:out(possessor:get_name() .. " struggles against the darkness.") end
    return false
  end
}),

stunned = Condition({
		name = "Stunned",
    bonuses={possession_chance=5,notice_chance=-1000,animation_time_percent=2},
    applied = function(self,possessor,applier)
      if player:can_see_tile(possessor.x,possessor.y) then
        output:out(possessor:get_name() .. " is stunned!")
        if not applier or applier.id ~= "chunkmaker" then
          output:sound('stunned')
        elseif applier.id == "chunkmaker" then
          output:sound('hedgehog_spikes')
        end
      end
    end,
		ai = function (self, possessor)
			if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " is stunned and does nothing.") end
			return false
		end,
    moves = function(self,possessor)
      if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " is stunned and does nothing.") end
			return false
    end,
    attacks = function(self,possessor)
      if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " is stunned and does nothing.") end
			return false
    end,
    casts = function(self,possessor)
      if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " is stunned and does nothing.") end
			return false
    end,
		cured = function (self,possessor)
			if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " is no longer stunned.") end
      possessor.stunClock = nil
		end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.stunClock = (possessor.stunClock or 0) - dt
        if (possessor.stunClock <= 0 and random(1,4) == 1) then
          local z = Effect('bubble',possessor.x,possessor.y)
          z.symbol = "*"
          z.color={r=255,g=255,b=201}
          z.image_name = "star"
          z.scale = 1
          z.scaleChange = -1
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.stunClock = random(5,10)*.1
        end
      end
    end
	}),
	
	cursed = Condition({
		name = "Cursed",
		bonuses={fear=10,hit_chance=-25,dodge_chance=-25,stealth=-10,notice_chance=-10},
    applied = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="cursed",symbol="",image_base="personalcloud",spritesheet=true,image_max=5,speed=0.3,color={r=33,g=0,b=50,a=100},use_color_with_tiles=true}),possessor.x,possessor.y)
    end,
    cured = function(self,possessor)
      possessor.curseClock = nil
    end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.curseClock = (possessor.curseClock or 0) - dt
        if (possessor.curseClock <= 0 and random(1,5) == 1) then
          local z = Effect('bubble',possessor.x,possessor.y)
          z.symbol = "."
          z.color={r=25,g=0,b=25}
          z.image_name = "particlemed"
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.curseClock = random(2,5)*.1
        end
      end
    end
	}),

blessed = Condition({
		name = "Blessed",
		bonuses={hit_chance=25,dodge_chance=25,stealth=10,notice_chance=10}
	}),

chilled = Condition({
		name = "Chilled",
    bonuses={possession_chance=5,notice_chance=-5,hit_chance=-10,dodge_chance=-10,damage_percent=-10,speed=-20,animation_time_percent=1.10},
		cured = function (self,possessor)
      possessor.chilledClock = nil
		end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.chilledClock = (possessor.chilledClock or 0) - dt
        if (possessor.chilledClock <= 0 and random(1,4) == 1) then
          local z = Effect('bubble',possessor.x,possessor.y)
          z.symbol = "*"
          z.color={r=155,g=255,b=255}
          z.image_name = "snowflake"
          z.scale = 1
          z.scaleChange = -1
          z.spin=true
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.chilledClock = random(5,10)*.1
        end
      end
    end
	}),
	
	confused = Condition({
		name = "Confused",
    bonuses={possession_chance=10,stealth=-10,notice_chance=-15},
		ai = function(self,possessor)
			local moveX,moveY = random(possessor.x-1,possessor.x+1),random(possessor.y-1,possessor.y+1)
			local creat = currMap:get_tile_creature(moveX,moveY)
      local chasm = currMap:tile_has_feature(moveX,moveY,"chasm")
			if random(1,10) == 1 and possessor ~= player and possessor:is_type('intelligent') and player:can_see_tile(possessor.x,possessor.y) then
				local name = possessor:get_name()
				local vocalizations = {"\"Is this the real life, or is this just fantasy?\" muses " .. name .. ".",name .. " giggles softly.",name .. " weeps softly.",name .. " stares at " .. possessor:get_pronoun('p') .. " hands.","\"I won't let you take my body,\" " .. name .. " says.","\"Get behind me, Satan,\" " .. name .. " says.","\"Where am I?\" " .. name .. " asks.","\"Not my blood!\" " .. name .. " screams.","\"Who is " .. namegen:generate_human_name() .. "?\" asks " .. name .. ".","\"I should really spend more time with my parents,\" " .. name .. " realizes.","\"Why are you trying to kill me?\" " .. name .. " asks.","\"I don't want to die!\" " .. name .. " whimpers."}
				output:out(vocalizations[#vocalizations])
			end
			if (creat) then
				possessor:attack(creat,false,true)
			elseif chasm or currMap:isClear(moveX,moveY,false,true) then
        if chasm and possessor:is_type('flyer') == false then
          if player:can_see_tile(moveX,moveY) then output:out(possessor:get_name() .. " stumbles into a pit in " .. possessor:get_pronoun('p') .. " confusion!") end
          possessor:flyTo({x=moveX,y=moveY})
        else
          possessor:moveTo(moveX,moveY,true) end
			end
			return false
		end,
    moves = function(self,possessor)
      return self:ai(possessor)
    end,
    attacks = function(self,possessor)
      return self:ai(possessor)
    end,
    casts = function(self,possessor)
      if possessor == player then output:out("You're too confused to use your special abilities right now.") end
      return self:ai(possessor)
    end,
    use_ranged_ability = function(self,possessor)
      if possessor == player then output:out("You're too confused to use a ranged attack right now.") end
      return self:ai(possessor)
    end,
    cured = function(self,possessor)
      possessor.confusedClock = nil
    end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.confusedClock = (possessor.confusedClock or 0) - dt
        if (possessor.confusedClock <= 0 and random(1,5) == 1) then
          local z = Effect('sleepZ',possessor.x,possessor.y)
          z.symbol = "?"
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.confusedClock = random(4,8)*.1
        end
      end
    end
	}),
	
	jekyllhyde = Condition({
		name = "Jekyllhyde",
		bonuses={bravery=100,damage_percent=50,hit_chance=20,possession_chance=-10000},
    ai = function(self,possessor)
      ai.basic(possessor,{forceStupid=true,noRanged=true,noRunning=true})
      return false
    end,
    applied = function(self,possessor)
      possessor.image_name = "ratlingjekyllhyde" .. (possessor.isPlayer and "possessed" or "")
      possessor.symbol = "R"
    end,
		cured = function(self,possessor)
			possessor.max_hp = possessor.max_hp - math.ceil(possessor.max_hp/10)
			if (possessor.hp > possessor.max_hp) then possessor.hp = possessor.max_hp end
			if player:can_see_tile(possessor.x,possessor.y) then output:out("The Jekyllhyde wears off. " .. possessor:get_name() .. " looks weaker.") end
      possessor.image_name = "ratlingchemist" .. (possessor.isPlayer and "possessed" or "")
      possessor.symbol = "r"
		end,
    dies = function(self,possessor)
      possessor:cure_condition('jekyllhyde')
      return true
    end
	}),
	
	invincibility = Condition({
		name = "Invincibility",
		bonuses={dodge_chance=1000,all_armor=1000},
		damaged = function(self,possessor)
			output:out("The attack passes through you, as you are not completely corporeal yet.")
			return false
		end
	}),
	
	stoneskin = Condition({
		name = "Stoneskin",
		bonuses={bravery=30,all_armor=5,speed=-20,animation_time_percent=1.25,possession_chance=-1000,electric_resistance=100},
    ai = function(self,possessor)
      ai.basic(possessor,{forceStupid=true})
      return false
    end,
    apply = function(self,possessor)
      if possessor.id == "rockpriest" then possessor.image_name = "rockprieststoned" .. (possessor == player and "possessed" or "") end
    end,
    cured = function(self,possessor)
      if possessor.id == "rockpriest" then possessor.image_name = "rockpriest" .. (possessor == player and "possessed" or "") end
    end,
	}),
	
	petrified = Condition({
		name = "Stoned",
    bonuses={possession_chance=-1000},
    apply = function(self,possessor)
      local stoned = function(x, y, r, g, b, a)
        if a ~= 0 then
          r,g,b = r*255,g*255,b*255
          if r > 200 or g > 200 or b > 200 then
            r=150
            g=150
            b=150
          elseif r > 100 or g > 100 or b > 100 then
            r=100
            g=100
            b=100
          elseif r > 50 or g > 50 or b > 50 then
            r=75
            g=75
            b=75
          else
            r=33
            g=33
            b=33
          end
        end
        return r/255, g/255, b/255, a
      end --end stoned function
      
      if not images['featurepetrified_' .. (possessor.image_name or possessor.id)] then
        --local idOld = images['creature' .. (possessor.image_name or possessor.id)]:getData()
        local w = images['creature' .. (possessor.image_name or possessor.id)]:getWidth()
        local tempCan = love.graphics.newCanvas(32,32)
        love.graphics.setCanvas(tempCan)
        love.graphics.clear()
        love.graphics.setBlendMode("alpha")
        love.graphics.draw(images['creature' .. (possessor.image_name or possessor.id)],0,0)
        love.graphics.setCanvas()
        local idNew = tempCan:newImageData()
        --idNew:paste(idOld,0,0,0,0,32,32)
        idNew:mapPixel(stoned,0,0,32,32)
        images['featurepetrified_' .. (possessor.image_name or possessor.id)] = love.graphics.newImage(idNew)
      end
      possessor.noDraw = true
      local statue = Feature('petrify_victim')
      statue.symbol = possessor.symbol
      statue.image_name = 'petrified_' .. (possessor.image_name or possessor.id)
      statue.noDesc=true
      possessor.petrifiedStat = statue
      currMap:add_feature(statue,possessor.x,possessor.y)
      --[[possessor.imageType = "feature"
      possessor.image_name = 'petrified_' .. (possessor.image_name or possessor.id)
      possessor.animated=false]]
      
    end,
		ai = function(self,possessor)
			return false
		end,
    move = function(self,possessor)
      return false
    end,
		damaged = function(self,possessor)
			return false
		end,
		cured = function(self,possessor)
      possessor.petrifiedStat:delete()
      possessor.noDraw = nil
			if player:can_see_tile(possessor.x,possessor.y) then
        output:out(possessor:get_name() .. " crumbles and is no longer stoned. Bummer, man.")
        output:sound('stone_explode')
      end
      for x=possessor.x-1,possessor.x+1,1 do
        for y=possessor.y-1,possessor.y+1,1 do
          if x ~= possessor.x or y ~= possessor.y then
            Projectile('stonechunk',possessor,{x=x,y=y})
          end
        end --end fory
      end --end forx
		end
	}),

  undeadrepellent = Condition({
      name = "Repellent to Undead",
      applied = function(self,possessor)
        currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="undeadrepellent",symbol="(",symbols={"(",")"},image_base="stench",image_max=2,speed=0.5,sequence=true,color={r=255,g=255,b=255,a=125},use_color_with_tiles=true,yMod=-output:get_tile_size()}),possessor.x,possessor.y)
      end,
      noticed = function(self,possessor,noticer)
        if noticer:is_type('undead') and not noticer.shitlist[possessor] then noticer:ignore(possessor) end
      end,
      cured = function(self,possessor)
        for _,c in pairs(currMap.creatures) do
          if c:is_type('undead') then c:stop_ignoring(possessor) end
        end --end creature for
      end --end cured function
  }),

  statueform = Condition({
    name = "Statue Form",
    bonuses={stealth=25},
    moves = function(self,possessor)
      if possessor == player then --only emerge from stone if player tries to move. If NPC, remain in stone
        return self:exit(possessor)
      else
        return false
      end
		end,
    become_hostile = function(self,possessor,noticee)
      return self:exit(possessor)
    end,
		attacks = function(self,possessor)
			return self:exit(possessor)
		end,
    exit = function(self,possessor)
      if player:can_see_tile(possessor.x,possessor.y) then
        output:out(possessor:get_name() .. " emerges from the stone.")
        output:sound('stone_explode')
        for x=possessor.x-1,possessor.x+1,1 do
          for y=possessor.y-1,possessor.y+1,1 do
            if x ~= possessor.x or y ~= possessor.y then
              Projectile('stonechunk',possessor,{x=x,y=y})
            end
          end --end fory
        end --end forx
      end
      possessor:cure_condition('statueform')
      possessor.cooldowns['Statue Form'] = 15
      possessor.image_name = nil
      possessor.color={r=175,g=175,b=175,a=255}
      return false
    end,
		damaged = function(self,possessor)
			return false
		end
    }),

  zombait = Condition({
      name = "Baited",
      bonuses={fear=20},
      advance = function(self,possessor)
        for x=possessor.x-10,possessor.x+10,1 do
          for y=possessor.y-10,possessor.y+10,1 do
            if (x ~= self.x or y ~= self.y and x>1 and y>1 and x<currMap.width and y<currMap.height) then
              local creat = currMap:get_tile_creature(x,y)
              if creat and creat ~= possessor and (creat:is_type("undead") or creat:is_type("animal")) and not creat.target then
                creat:notice(possessor)
                creat.target = possessor end
            end --end x/y check
          end --end fory
        end --end forx
      end, --end advance
      apply = function(self,possessor)
        currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="zombait",symbol="(",symbols={"(",")"},image_base="stench",image_max=2,speed=0.5,sequence=true,color={r=200,g=0,b=0,a=125},use_color_with_tiles=true,yMod=-output:get_tile_size()}),possessor.x,possessor.y)
        for x=possessor.x-10,possessor.x+10,1 do
          for y=possessor.y-10,possessor.y+10,1 do
            if (x ~= self.x or y ~= self.y and x>1 and y>1 and x<currMap.width and y<currMap.height) then
              local creat = currMap:get_tile_creature(x,y)
              if creat and (creat:is_type("undead") or creat:is_type("animal")) and creat.target ~= possessor and creat ~= possessor then
                creat:notice(possessor)
                creat.target = possessor
              end
            end --end x/y check
          end --end fory
        end--end forx
      end --end applied function
  }),

demonbait = Condition({
      name = "Demonbaited",
      bonuses={fear=20},
      advance = function(self,possessor)
        for x=possessor.x-10,possessor.x+10,1 do
          for y=possessor.y-10,possessor.y+10,1 do
            if (x ~= self.x or y ~= self.y and x>1 and y>1 and x<currMap.width and y<currMap.height) then
              local creat = currMap:get_tile_creature(x,y)
              if creat and creat ~= possessor and creat:is_type("demon") and not creat.target then
                creat:notice(possessor)
                creat.target = possessor end
            end --end x/y check
          end --end fory
        end --end forx
      end, --end advance
      apply = function(self,possessor)
        currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="demonbait",symbol="(",symbols={"(",")"},image_base="stench",image_max=2,speed=0.5,sequence=true,color={r=200,g=255,b=255,a=125},use_color_with_tiles=true,yMod=-output:get_tile_size()}),possessor.x,possessor.y)
        for x=possessor.x-10,possessor.x+10,1 do
          for y=possessor.y-10,possessor.y+10,1 do
            if (x ~= self.x or y ~= self.y and x>1 and y>1 and x<currMap.width and y<currMap.height) then
              local creat = currMap:get_tile_creature(x,y)
              if creat and creat:is_type("demon") and creat.target ~= possessor and creat ~= possessor then
                creat:notice(possessor)
                creat.target = possessor
              end
            end --end x/y check
          end --end fory
        end--end forx
      end --end applied function
  }),

afterdivebomb = Condition({
      name = "After Divebomb",
      update = function(self,possessor,dt)
        possessor.diveBombCount = (possessor.diveBombCount or 0)+dt
        if possessor.diveBombCount >= 0.25 then
          possessor:flyTo(possessor.diveBombFrom,Spell('landsafely'))
          possessor.diveBombFrom = nil
          possessor.diveBombCount = nil
          possessor.conditions['afterdivebomb'] = nil --Remove the condition so it never actually shows up
        end
      end
  }),

  falling = Condition({
      name = "Falling",
      apply = function(self,possessor,attacker)
        possessor.fallCountdown = .5
        possessor.spinCountdown = .1
        possessor.scale = 1
        possessor.angle = 0
        possessor.stopsInput=true
        if attacker == player then achievements:give_achievement('fall_kill') end
        if player:can_sense_creature(possessor) then
          output:sound('falling')
        end
      end,
      update = function(self,possessor,dt)
        possessor.fallCountdown = possessor.fallCountdown - dt
        if (possessor.fallCountdown <= 0) then
          possessor:cure_condition('falling')
          possessor.corpse=false
          possessor:die()
          possessor.stopsInput=nil
          return
        end
        possessor.spinCountdown = possessor.spinCountdown - dt
        if possessor.spinCountdown <= 0 then
          possessor.angle = possessor.angle + 8*dt
          possessor.scale = possessor.scale - 2*dt
          if (possessor.scale <= 0) then possessor.scale = 0 end
          possessor.spinCoundtown = .1
        end
      end
    }),

circleofprotection = Condition({
    name = "Circle of Protection",
    bonuses={bravery=25},
    attacked = function(self,possessor,attacker)
      if attacker:is_type('demon') then
        return false
      end
    end,
    moves = function(self,possessor)
      possessor.circle:delete()
      possessor:cure_condition('circleofprotection')
    end,
    dies = function(self,possessor)
      possessor.circle:delete()
    end
  }),

tranquilized = Condition({
    name = "Tranquilized",
    bad = true,
		bonuses={fear=25,hit_chance=-15,dodge_chance=-15,speed=-25,possession_chance=10,notice_chance=-25,animation_time_percent=2},
    applied = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="tranquilized",symbol="",image_base="personalcloud",spritesheet=true,image_max=5,speed=0.3,color={r=0,g=0,b=150,a=100},use_color_with_tiles=true}),possessor.x,possessor.y)
    end,
    advance = function(self,possessor)
      local roll = (possessor.hp < 100 and 100 or (possessor.hp < 200 and 200 or 300))
      if random(1,roll) >= possessor.hp then
        if player:can_see_tile(possessor.x,possessor.y) then output:out("The tranquilizer kicks in and " .. possessor:get_name() .. " falls asleep.") end
          possessor:give_condition('asleep',tweak(25))
      end
    end,
    become_hostile = function(self,possessor)
      return false
    end
  }),

lethargic = Condition({
    name = "Lethargic",
    bad = true,
		bonuses={fear=-10,hit_chance=-15,dodge_chance=-15,speed=-25,possession_chance=10,notice_chance=-10,aggression=-10,animation_time_percent=1.5},
    applied = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="lethargic",symbol="",image_base="personalcloud",spritesheet=true,image_max=5,speed=0.3,color={r=0,g=0,b=150,a=100},use_color_with_tiles=true}),possessor.x,possessor.y)
    end
  }),

frogcurse = Condition({
    name = "Frog Curse",
    bad = true,
    bonuses={fear=10000,aggression=-10000},
    cured = function(self,possessor)
      if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor.originalForm:get_name(false,true) .. " returns to " .. possessor:get_pronoun('p') .. " original form.") end
      possessor.originalForm.hp = possessor.hp
      if possessor == player then player = possessor.originalForm end
      possessor:remove()
      currMap:add_creature(possessor.originalForm,possessor.x,possessor.y)
    end
  }),

digesting = Condition({
    name = "Digesting",
    apply = function(self,possessor)
      if possessor.id == "gobblerlizard" then possessor.image_name = "gobblerlizarddigesting" .. (possessor == player and "possessed" or "") end
    end,
    cured = function(self,possessor)
      if possessor.id == "gobblerlizard" then possessor.image_name = "gobblerlizard" .. (possessor == player and "possessed" or "") end
    end,
    dies = function(self,possessor)
      possessor:explode() --this also frees the digested creature
      return false
    end,
    explode = function(self,possessor)
      --free digested creature, if applicable
      if possessor.digesting and possessor.digesting.hp >= 1 then
        local creat = possessor.digesting
        local targetX,targetY = random(possessor.x-5,possessor.x+5),random(possessor.y-5,possessor.y+5)
        local checkX = (targetX > possessor.x and 1 or (targetX < possessor.x and -1 or 0))
        local checkY = (targetY > possessor.y and 1 or (targetY < possessor.y and -1 or 0))
        while creat:can_move_to(possessor.x+checkX,possessor.y+checkY) == false do
          targetX,targetY = random(possessor.x-5,possessor.x+5),random(possessor.y-5,possessor.y+5)
          checkX = (targetX > possessor.x and 1 or (targetX < possessor.x and -1 or 0))
          checkY = (targetY > possessor.y and 1 or (targetY < possessor.y and -1 or 0))
        end
        creat:flyTo({x=targetX,y=targetY})
        creat:cure_condition('beingdigested')
        creat.digestor = nil
        creat.noDraw = nil
      end
      return true
    end,
    moved = function(self,possessor)
      --move digested creature
      if possessor.digesting and possessor.digesting.hp >= 1 then
        possessor.digesting:forceMove(possessor.x,possessor.y)
      end
    end,
    advance = function(self,possessor)
      if possessor.digesting and possessor.digesting.hp >= 1 then
        local creat = possessor.digesting
        local dmg = creat:damage(tweak(math.ceil(creat.max_hp/5)),possessor.conditions.digesting.applier)
        if creat.hp <= 0 then
          local hp = tweak(math.ceil(creat.max_hp/2))
          possessor:updateHP(hp)
          possessor.digesting = nil
          possessor:cure_condition('digesting')
          creat:remove()
          if possessor == player and creat.id == "samedi" then
            achievements:give_achievement('swamps_special')
          end
          if player:can_see_tile(possessor.x,possessor.y) then
            output:out(possessor:get_name() .. " fully digests " .. creat:get_name() .. ", healing " .. hp .. " HP!")
            output:sound('burp')
          end
        elseif player:can_see_tile(possessor.x,possessor.y) then
          output:out(possessor:get_name() .. " digests " .. creat:get_name() .. ", dealing " .. dmg .. " damage.")
        end
      else --if you're not digesting anyone, stop this shit
        possessor:cure_condition('digesting')
        return false
      end
    end
  }),

beingdigested = Condition({
    name = "Being Digested",
    moves = function(self,possessor)
      if possessor.digestor then possessor:attack(possessor.digestor) end
      return false
    end
  }),

invisible = Condition({
    name = "Invisible",
    bonuses={stealth=1000},
    apply = function(self,possessor)
      possessor.color = {r=possessor.color.r,g=possessor.color.g,b=possessor.color.b,a=100}
      for _,creat in pairs(currMap.creatures) do
        creat:forget(possessor)
        if creat.target == possessor then creat.target = nil end
      end
    end,
    attacks = function(self,possessor)
      possessor:cure_condition('invisible')
    end,
    cured = function(self,possessor)
      possessor.color = {r=possessor.color.r,g=possessor.color.g,b=possessor.color.b,a=255}
    end,
    noticed = function(self,possessor,noticer)
      --if noticer is psychic, return true
      return false
    end,
    became_enemy = function(self,possessor,noticer)
      --if noticer is psychic, return true
      return false
    end
  }),

hypnotized = Condition({
    name = "Hypnotized",
    bonuses={bravery=50,possession_chance=25},
    ai = function(self,possessor)
      ai.basic(possessor,{forceStupid=true,noRunning=true})
      return false
    end,
    cured = function(self,possessor)
      if possessor.master then
        if possessor.master.isPlayer then --if the player hypnotized you, hate them!
          possessor.playerAlly = false
        end
        possessor.master.thralls[possessor] = nil --no longer be counted as your hypnotizer's thrall
        possessor:become_hostile(possessor.master) --hate your hypnotizer
        possessor.target = possessor.master
      end
      if possessor.oldmaster then --return to your old master, if applicable
        possessor:become_thrall(possessor.oldmaster)
        possessor.oldmaster = nil
      else
        possessor.master = nil
      end
    end
  }),

fear = Condition({
    name = "Terrified",
    bad = true,
    bonuses={bravery=-10000,fear=10000,notice_chance=15},
    applied = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="fear",symbol="",image_base="characterflashes",image_max=4,speed=0.1,sequence=true,color={r=255,g=255,b=0,a=255},use_color_with_tiles=true,spritesheet=true}),possessor.x,possessor.y)
    end,
    ai = function(self,possessor)
      if random(1,10) == 1 and possessor:is_type('intelligent') and player:can_see_tile(possessor.x,possessor.y) then
				local name = possessor:get_name()
				local vocalizations = {"\"I won't let you take my body,\" " .. name .. " says.","\"Please! Not like this!\" " .. name .. " begs.","\"Why are you trying to kill me?\" " .. name .. " asks.","\"I don't want to die!\" " .. name .. " screams.","\"Just leave me alone!\" " .. name .. " begs."}
				output:out(vocalizations[#vocalizations])
			end
      ai.run(possessor,'fleeing')
      return false
    end
  }),

recitingpoetry = Condition({
    name = "Reciting Poetry",
    bonuses={stealth=-100,notice_chance=-5},
    advance = function(self,possessor)
      if possessor.mp < 1 then
        if player:can_see_tile(possessor.x,possessor.y) then output:out(posessor:get_name() .. " runs out of inspiration and stops reciting poetry.") end
        possessor:cure_condition('recitingpoetry')
        return false
      end
      possessor.mp = possessor.mp - 1
      currMap:add_effect(Effect('soundwavemaker',{r=240,g=120,b=255}),possessor.x,possessor.y)
      local drunk = ((possessor:has_condition('drunk') or possessor:has_condition('wasted')) and 2 or 1)
      
      for x=math.max(possessor.x-10,2),math.min(possessor.x+10,currMap.width-1) do
        for y=math.max(possessor.y-10,2),math.min(possessor.y+10,currMap.height-1) do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat:is_type('intelligent') and not creat.conditions['asleep'] and creat ~= possessor and creat.id ~= "ratlingpoet" then
            local dmg = creat:damage(random(6,8)*drunk,possessor)
            if player:can_see_tile(creat.x,creat.y) then
              output:out(creat:get_name() .. "'s ears bleed from " .. possessor:get_name() .. "'s horrible " .. (drunk == 2 and "drunken " or "") .. "poetry, taking " .. dmg .. " damage.")
            end
            creat.fear = creat.fear + 5
            if creat.master ~= possessor and (possessor ~= player or creat.playerAlly ~= true) then
              creat:become_hostile(possessor)
              creat.target = possessor
            end
          end
        end
      end
    end,
    moves = function(self,possessor)
      possessor:cure_condition('recitingpoetry')
    end,
    attacks = function(self,possessor)
      possessor:cure_condition('recitingpoetry')
    end,
    casts = function(self,possessor)
      possessor:cure_condition('recitingpoetry')
    end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.zClock = (possessor.zClock or 0) - dt
        if (possessor.zClock <= 0 and random(1,5) == 1) then
          local z = Effect('sleepZ',possessor.x,possessor.y)
          z.symbol = "BLAH"
          z.image_name = "blahblah"
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.zClock = random(2,5)*.1
        end
      end
    end
  }),

restrainingorder = Condition({
    name = "Restraining Order",
    bad = true,
    advance = function(self,possessor,first)
      if possessor:is_type('knockedback') then return end -- if already flying, don't fly again
      if possessor.restrainer == nil or possessor.restrainer.hp < 1 then
        possessor:cure_condition('restrainingorder')
      end
      local dist = math.max(calc_distance(possessor.x,possessor.y,possessor.restrainer.x,possessor.restrainer.y))
      if dist < 3 then
        local xMod,yMod = get_unit_vector(possessor.restrainer.x,possessor.restrainer.y,possessor.x,possessor.y)
        local newX,newY=possessor.x+xMod,possessor.y+yMod
        while math.max(calc_distance(newX,newY,possessor.restrainer.x,possessor.restrainer.y)) < 3 do
          newX,newY=newX+xMod,newY+yMod
        end
        possessor:flyTo({x=newX,y=newY})
        if first then possessor:flyTo({x=newX,y=newY})
        else possessor:flyTo({x=newX,y=newY},Spell('landsafely')) end
      end
    end,
    cured = function(self,possessor)
      possessor.restrainer = nil
    end
  }),

wadingshallowwater = Condition({
    name = "Wading",
    bonuses={speed=-25,hit_chance=-5,dodge_chance=-15,stealth=-10,fire_resistance=25,electric_weakness=100},
    advance = function(self,possessor)
      local water = false
      if type(currMap[possessor.x][possessor.y]) == "table" and currMap[possessor.x][possessor.y].water == true then water = true end
      for _,feat in pairs(currMap.contents[possessor.x][possessor.y]) do
        if feat.water == true then water = true end
      end
      if currMap:tile_has_feature(possessor.x,possessor.y,'bridge') or water == false then
        possessor:cure_condition('wadingshallowwater')
      end
      if possessor:has_condition('fireaura') then possessor:cure_condition('fireaura') end
    end
  }),

swimming = Condition({
    name = "Swimming",
    bonuses={speed=15,dodge_chance=10,stealth=10,fire_resistance=50,electric_weakness=100},
    advance = function(self,possessor)
      local water = false
      if type(currMap[possessor.x][possessor.y]) == "table" and currMap[possessor.x][possessor.y].water == true then water = true end
      for _,feat in pairs(currMap.contents[possessor.x][possessor.y]) do
        if feat.water == true then water = true end
      end
      if currMap:tile_has_feature(possessor.x,possessor.y,'bridge') or water == false or possessor:has_condition('underwater') then
        possessor:cure_condition('swimming')
      end
      if possessor:has_condition('fireaura') then possessor:cure_condition('fireaura') end
    end
  }),

drowning = Condition({
    name = "Drowning",
    bonuses={speed=-25,hit_chance=-25,dodge_chance=-25,stealth=-25,fire_resistance=25,electric_weakness=100},
    cured = function(self,possessor)
      possessor.waterBubbleClock = nil
    end,
    advance = function(self,possessor)
      if not currMap:tile_has_feature(possessor.x,possessor.y,'deepwater') then
        possessor:cure_condition('drowning')
        return
      end
      if currMap:tile_has_feature(possessor.x,possessor.y,'bridge') then
        possessor:cure_condition('drowning')
        return
      end
      if possessor:has_condition('onfire') then possessor:cure_condition('onfire') end
      if possessor:has_condition('fireaura') then possessor:cure_condition('fireaura') end
      if random(1,5) == 1 then
        local dmg = possessor:damage(tweak(5),possessor.conditions.drowning.applier)
        if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " thrashes around fruitlessly, inhaling water for " .. dmg .. " damage.") end
        local moveX,moveY = random(possessor.x-1,possessor.x+1),random(possessor.y-1,possessor.y+1)
        local tries = 0
        while tries < 10 and (not currMap:isClear(moveX,moveY,false,false,true) or (moveX == possessor.x and moveY == possessor.y)) do
          moveX,moveY = random(possessor.x-1,possessor.x+1),random(possessor.y-1,possessor.y+1)
          tries = tries + 1
        end
        if tries < 10 then possessor:moveTo(moveX,moveY,true) end
      end
    end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.waterBubbleClock = (possessor.waterBubbleClock or 0) - dt
        if (possessor.waterBubbleClock <= 0 and random(1,5) == 1) and player:does_notice(possessor)  then
          local z = Effect('bubble',possessor.x,possessor.y)
          local water = nil
          for _,feat in pairs(currMap:get_tile_features(possessor.x,possessor.y)) do
            if feat.water == true then water = feat end
          end
          z.color = water.color
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.waterBubbleClock = 1
        end
      end
    end
  }),

inbushes = Condition({
    name = "In the Bushes",
    bonuses={speed=-10,hit_chance=-5,dodge_chance=-15,stealth=10},
    advance = function(self,possessor)
      if not currMap:tile_has_feature(possessor.x,possessor.y,'bush') and not not currMap:tile_has_feature(possessor.x,possessor.y,'deadbush') then
        possessor:cure_condition('inbushes')
      end
    end
  }),

enraged = Condition({
    name = "Enraged",
    bonuses={bravery=10000,aggression=10000,damage_perecent=110,dodge_chance=-15,hit_chance=-5,critical_chance=5,speed=10,possession_chance=-10000,stealth=-10000,notice_chance=5},
    ai = function(self,possessor)
      ai.basic(possessor,{forceStupid=true,noRunning=true,noRanged=true})
      return false
    end,
    apply = function(self,possessor)
      if player:can_sense_creature(possessor) then output:sound('enraged') end
      if possessor.extra_stats.fury then
        possessor.extra_stats.fury.bar_color={r=255,g=0,b=0,a=255}
      end
    end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.cussClock = (possessor.cussClock or 0) - dt
        if (possessor.cussClock <= 0 and random(1,3) == 1) then
          local z = Effect('cussin',possessor)
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.cussClock = .5
        end
      end
    end,
    advance = function(self,possessor)
      if possessor.extra_stats.fury then
        possessor:update_extra_stat('fury',-5)
        if possessor.extra_stats.fury.value == 0 then
          possessor:cure_condition('enraged')
          possessor.extra_stats.fury.bar_color={r=255,g=255,b=0,a=255}
        end
      end
    end
  }),

strengthened = Condition({
    name = "Strengthened",
    bonuses={bravery=20,damage_perecent=150,critical_chance=2},
    applied = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="inspired",symbol="",image_base="characterflashes",image_max=4,speed=0.1,sequence=true,color={r=235,g=137,b=49,a=255},use_color_with_tiles=true,spritesheet=true}),possessor.x,possessor.y)
    end
  }),

guaranteedcrit = Condition({
    name = "Guaranteed Critical Hit",
    bonuses={critical_chance=1000,hit_chance=1000}
  }),

instorm = Condition({
    name = "Caught in the Storm",
    bonuses={speed=-25,hit_chance=-5,dodge_chance=-5,perception=-100,stealth=15,notice_chance=-10},
    advance = function(self,possessor)
      if currMap:tile_has_effect(possessor.x,possessor.y,"sandstorm") == false then
        possessor:cure_condition('instorm')
        refresh_player_sight()
      end
    end
  }),

bloodshield = Condition({
    name = "Blood Shield",
    bonuses={bravery=15},
    damaged = function(self,possessor,attacker,dmg,damage_type)
      if damage_type == "physical" then
        if not currMap:tile_has_feature(possessor.x,possessor.y,'bloodstain') then currMap:add_feature(Feature('bloodstain'),possessor.x,possessor.y) end
        if player:can_see_tile(possessor.x,possessor.y) then output:sound('bloodshield_hit') end
        return math.ceil(dmg/2)
      end
      return true
    end
  }),

outforblood = Condition({
    name = "Out for Blood",
    removal_type="attack",
    bonuses={bravery=15,damage_percent=100,critical_chance=5,hit_chance=5,speed=10},
    apply = function(self,possessor)
      if possessor.id == "bloodmage" then possessor.image_name = "bloodmage" .. possessor.image_variety .. "outforblood" .. (possessor == player and "possessed" or "") end
    end,
    cured = function(self,possessor)
      if possessor.id == "bloodmage" then possessor.image_name = "bloodmage" .. possessor.image_variety .. (possessor == player and "possessed" or "") end
    end,
  }),

bloodbond = Condition({
    name = "Blood Bonded",
    bonuses={possession_chance=10},
    apply = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="bloodbond",symbol="",image_base="chains",image_max=2,speed=0.3,sequence=true,color={r=255,g=0,b=0,a=125},use_color_with_tiles=true,spritesheet=true,yMod=-output:get_tile_size()}),possessor.x,possessor.y)
    end,
    dies = function(self,possessor)
      possessor.bloodbond:cure_condition('bloodbond')
      possessor.bloodbond.bloodbond = nil
    end,
    damaged = function(self,possessor,attacker,dmg,damage_type)
      if attacker ~= posssessor and damage_type ~= "bloodmagic" and attacker ~= possessor.bloodbond then --damage done to the possessor by itself doesn't transfer. Also, damage from the transfer will count as being done by the possessor to itself
        if player:can_sense_creature(possessor.bloodbond) then
          output:out(possessor.bloodbond:get_name() .. " takes " .. dmg .. " damage from their blood bond to " .. possessor:get_name() .. ".")
        end
        dmg = math.ceil(dmg/2)
        possessor.bloodbond:damage(dmg,nil,"bloodmagic")
        return dmg
      end
    end
  }),

	witheringcurse = Condition({
		name = "Withering Curse",
		bonuses={fear=20,hit_chance=-10,dodge_chance=-10,damage_percent=-25},
    advance = function(self,possessor)
      possessor:damage(random(1,5),possessor.conditions.witheringcurse.applier,"unholy")
    end
	}),
    
  inshell = Condition({
      name = "Hiding in Shell",
      bonuses={stealth=10,notice_chance=-10},
      damaged = function(self,possessor,attacker)
        if attacker and attacker.baseType == "creature" and possessor:touching(attacker) then
          if player:can_see_tile(possessor.x,possessor.y) then
            output:out(attacker:get_name() .. " kicks " .. possessor:get_name() .. "'s shell!")
            output:sound('kick_turtleperson')
          end
          local xMod,yMod = get_unit_vector(attacker.x,attacker.y,possessor.x,possessor.y)
          local dist = random(3,6)
          possessor:flyTo({x=possessor.x+xMod*dist,y=possessor.y+yMod*dist})
          if possessor:has_condition('asleep') then possessor:cure_condition('asleep') end
          possessor:notice(attacker)
          possessor:become_hostile(attacker)
        end
        return false
      end,
      moves = function(self,possessor)
        possessor:cure_condition('inshell')
      end,
      attacks = function(self,possessor)
        possessor:cure_condition('inshell')
      end,
      cured = function(self,possessor)
        if self ~= player then possessor.symbol = "T" possessor.image_name = nil
        else possessor.image_name = "tmntpossessed" end
        possessor.color = {r=0,g=100,b=0,a=255}
        player.cooldowns['Turtle Up!'] = 10
        if player:can_sense_creature(possessor) then output:sound('turtle_show') end
      end
    }),
  
  drunk = Condition({
      name = "Drunk",
      moves = function(self,possessor,x,y)
        if random(1,4) ~= 1 then return true end -- 1 in 4 chance of stumbling
        local newX,newY = x,y
        local tries = 0
        if (possessor.y == y or random(1,2) == 1) and possessor.x ~= x then --keep x-axis, stumble on y-axist
          newY = random(y-1,y+1)
          while tries < 10 and (not possessor:can_move_to(newX,newY) or not possessor:touching({x=newX,y=newY})) do
            newY = random(y-1,y+1)
            tries = tries+1
          end
        else -- keep y-axis, stumble on x-axis
          newX = random(x-1,x+1)
          while tries < 10 and (not possessor:can_move_to(newX,newY) or not possessor:touching({x=newX,y=newY})) do
            newX = random(x-1,x+1)
            tries = tries+1
          end
        end -- end x/y if
        if tries < 10 then
          return {x=newX,y=newY}
        else
          return {x=x,y=y}
        end --end tries if
      end, --end moves function
      attacked = function(self,possessor,attacker)
        if random(1,10) == 1 then
          if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " spills some of "  .. possessor:get_pronoun('p') .. " drink. It begins dissolving the floorboards.") end
          currMap:add_feature(Feature('spilledbooze'),possessor.x,possessor.y)
        end
      end
  }),

  wasted = Condition({
      name = "Wasted!",
      bonuses={bravery=50,dodge_chance=-10,hit_chance=-10,stealth=-5,notice_chance=-15},
      ai = function(self,possessor)
        ai.basic(possessor,{forceStupid=true,noRunning=true})
        return false
      end,
      moves = function(self,possessor,x,y)
        local newX,newY = random(x-1,x+1),random(y-1,y+1)
        local tries = 0
        while tries < 10 and (not possessor:can_move_to(newX,newY) or not possessor:touching({x=newX,y=newY})) do
          newX,newY = random(x-1,x+1),random(y-1,y+1)
          tries = tries+1
        end
        if tries < 10 then
          return {x=newX,y=newY}
        else
          return {x=x,y=y}
        end --end tries if
      end,
      apply = function(self,possessor)
      if possessor.faction then
        possessor.oldfaction = possessor.faction
      end
      possessor.faction = "chaos"
    end,
    cured = function(self,possessor)
      if possessor.oldfaction then
        possessor.faction = possessor.oldfaction
        possessor.oldfaction = nil
      else
        possessor.faction = nil
      end
      possessor.drunkBubbleClock = nil
    end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.drunkBubbleClock = (possessor.drunkBubbleClock or 0) - dt
        if (possessor.drunkBubbleClock <= 0 and random(1,5) == 1) then
          local z = Effect('bubble',possessor.x,possessor.y)
          z.color = {r=170,g=155,b=62,a=255}
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.drunkBubbleClock = 1
        end
      end
    end
    }),
  
  grappled = Condition({
      name = "Grappled",
      bonuses={dodge_chance=-10,damage_percent=-40,notice_chance=-5},
      apply = function(self,possessor,applier)
        possessor.grappler = applier
        applier:give_condition('grappling',-1,possessor.grappler)
        if player:can_see_tile(possessor.x,possessor.y) then
          output:out(possessor.grappler:get_name() .. " grabs onto " .. possessor:get_name() .. "!")
          if applier.id == "tentaclebeast" then output:sound('tentaclebeast_grapple') end
        end
      end,
      moves = function(self,possessor)
        if not possessor.grappler or not possessor:touching(possessor.grappler) then possessor:cure_condition('grappled') return true end
        --try to break grapple. if you fail, you can't move
        local pStr = random(1,possessor:get_stat('strength'))
        local gStr = random(1,possessor.grappler:get_stat('strength'))
        if pStr >= gStr then
          if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " breaks " .. possessor.grappler:get_name() .. "'s grapple.") end
          possessor:cure_condition('grappled')
          return true
        else
          if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " struggles against " .. possessor.grappler:get_name() .. "'s grapple.") end
          return false
        end
      end,
      attacks = function(self,possessor,target)
        if target ~= possessor.grappler then return self:moves(possessor) end --if trying to fight someone other thatn your grappler, you have to try to break free first
        -- If trying to fight your grappler, you will also try to break the grapple. If you do, you do full damage. If not, you deal half damage.
        self:moves(possessor) --this runs the grapple-break check, and removes the condition if necessary
        --Either way, a normal attack will be done. But if you're stilled grappled, you'll do less damage due to the condition's bonuses
      end,
      cured = function(self,possessor)
        possessor.grappler:cure_condition('grappling')
        possessor.grappler = nil
      end
  }),

grappling = Condition({
    name = "Grappling",
    bonuses={hit_chance=10,dodge_chance=-10},
    apply = function(self,possessor,applier)
      possessor.graplee = applier
    end,
    moves = function(self,possessor)
      if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " releases " .. possessor:get_pronoun('p') .. " hold on " .. possessor.graplee:get_name() .. ".") end
      possessor:cure_condition('grappling')
      possessor.graplee:cure_condition('grappled')
    end,
    attacks = function(self,possessor,target)
      if target ~= possessor.graplee then --if you attack someone other than your grapplee, break the grapple
        return self:moves(possessor)
      end
    end,
    cured = function(self,possessor)
      possessor.grapplee = nil
    end
  }),

peacefulpatron = Condition({
    name = "Stasis",
    ai = function(self,possessor)
      return false
    end,
    damaged = function(self,possessor,attacker)
      return false
    end,
  }),

spearless = Condition({
    name = "Spearless",
    bonuses = {damage=-5},
    apply = function(self,possessor)
      if possessor.id == "spartan" then possessor.image_name = "spartannospear" .. possessor.image_variety .. (possessor == player and "possessed" or "") end
    end,
    cured = function(self,possessor)
      if possessor.id == "spartan" then possessor.image_name = "spartan" .. possessor.image_variety .. (possessor == player and "possessed" or "") end
    end,
  }),
  
  rearingback = Condition({
      name = "Rearing Back for a Slap",
      apply = function(self,possessor)
        possessor.image_name = "tentacleback"
        possessor.symbol = "Y"
        possessor.image_base = "tentacleback"
        if player:can_see_tile(possessor.x,possessor.y) then
          output:out("A tentacle rears back, preparing to deliver a massive slap!")
          output:sound('tentaclerearback')
        end
      end,
      cured = function(self,possessor)
        possessor.image_name = nil
        possessor.image_base = "tentacle"
        possessor.symbol = "T"
        
        --Is there a victim nearby we can slap?
        local victim = nil
        for x=possessor.x-1,possessor.x+1,1 do
          for y= possessor.y-1,possessor.y+1,1 do
            local creat = currMap:get_tile_creature(x,y)
            if creat and creat ~= possessor and possessor:is_enemy(creat) then victim = creat break end
          end
        end
        
        if victim then --slap that fucker hard!
          --move any tentacles out of the way so that fucker can fly!
          local xMod,yMod = get_unit_vector(possessor.x,possessor.y,victim.x,victim.y)
          for dist=1,5,1 do
            local blocker = currMap:get_tile_creature(victim.x+(xMod*dist),victim.y+(yMod*dist))
            if blocker and blocker.id == "tentacle" then
              local xMove = xMod
              local yMove = yMod
              while xMove == xMod and yMove == yMod do
                xMove = random(-1,1)
                yMove = random(-1,1)
              end --end while
              blocker:moveTo(blocker.x+xMove,blocker.y+yMove)
            end --end if blocker id
          end --end distance for
          local dmg = victim:damage(tweak(8),possessor)
          if player:can_see_tile(victim.x,victim.y) then
            output:out("The tentacle smacks " .. victim:get_name() .. ", dealing " .. dmg .. " damage and knocking them backwards!")
          end
          if victim.hp > 0 then victim:give_condition('knockback',5,possessor) end
        end
      end,
      attacks = function(self,possessor,target)
        return false
      end,
      moves = function(self,possessor,target)
        return false
      end
    }),
  
  inspired = Condition({
      name = "Inspired",
      bonuses={bravery=30,hit_chance=10,dodge_chance=10,damage_percent=25,notice_chance=10},
      ai = function(self,possessor)
        ai.basic(possessor,{noRunning=true})
        return false
      end,
      applied = function(self,possessor)
        currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="inspired",symbol="",image_base="characterflashes",image_max=4,speed=0.1,sequence=true,color={r=254,g=255,b=211,a=255},use_color_with_tiles=true,spritesheet=true}),possessor.x,possessor.y)
      end,
      cured = function(self,possessor)
        if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " is no longer inspired.") end
      end
    }),
  
 magicshield = Condition({
		name = "Magic Shield",
		bonuses={bravery=10,possession_chance=-1000},
    apply = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="magicshield",symbol="0",image_base="magicshieldfloat",spritesheet=true,image_max=3,speed=0.3,reverse=true,color={r=178,g=220,b=239,a=125},use_color_with_tiles=true}),possessor.x,possessor.y)
      if player:can_see_tile(possessor.x,possessor.y) then
        output:sound('magicshield')
      end
    end,
    damaged = function(self,possessor,attacker,dmg,dtype)
        local absorb = math.ceil(dmg/4)
        if player:can_see_tile(possessor.x,possessor.y) then
          output:out(possessor:get_name() .. "'s magic shield absorbs " .. absorb .. " damage.")
          output:sound('magicshield_hit')
          local flash = currMap:add_effect(Effect('animation',{image_name='magicshieldhit',image_max=3,target=possessor,color={r=178,g=220,b=239,a=255}}),possessor.x,possessor.y)
        end
        return (dmg-absorb)
    end
	}),

 firebrand = Condition({
		name = "Fire Brand",
    damages = function(self,possessor,target)
      local dmg = target:damage(5,possessor,"fire")
      if dmg > 0 and player:can_see_tile(possessor.x,possessor.y) then output:out("The fire around " .. possessor:get_name() .. "'s weapon burns " .. target:get_name() .. " for " .. dmg .. ".") end
    end,
    apply = function(self,possessor)
      if possessor.id == "battlemage" then possessor.image_name = "battlemagefiresword" .. possessor.image_variety .. (possessor == player and "possessed" or "") end
    end,
    cured = function(self,possessor)
      if possessor.id == "battlemage" then possessor.image_name = "battlemage" .. possessor.image_variety .. (possessor == player and "possessed" or "") end
    end,
	}),

 haste = Condition({
		name = "Hasted",
		bonuses={speed=25,animation_time_percent=0.5},
    update = function(self,possessor)
      if possessor.xMod <= 1 and possessor.xMod >= -1 and possessor.yMod >= -1 and possessor.yMod <= 1 then
        possessor.xMod,possessor.yMod = random(-1,1),random(-1,1)
      end
    end
	}),

clouded = Condition({
		name = "Head in the Clouds",
		bonuses={perception=-3,notice_chance=-10}
	}),

blinded = Condition({
    name = "Blinded",
    bonuses={fear=15,hit_chance=-10,dodge_chance=-10,perception=-100,notice_chance=-40},
    applied = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="blinded",symbol="",image_base="personalcloud",spritesheet=true,image_max=5,speed=0.3,color={r=0,g=0,b=0,a=100},use_color_with_tiles=true}),possessor.x,possessor.y)
    end
  }),

moneyshield = Condition({
    name = "Economic Bubble",
    bonuses={bravery=20,possession_chance=-1000},
    damaged = function(self,possessor,attacker,dmg,dtype)
      if possessor.mp > math.ceil(dmg/2) then
        local absorb = math.ceil(dmg/2)
        if player:can_see_tile(possessor.x,possessor.y) then
          output:out(possessor:get_name() .. "'s economic bubble absorbs " .. absorb .. " damage.")
          output:sound('economicbubble_hit')
          for x=possessor.x-1,possessor.x+1,1 do
            for y=possessor.y-1,possessor.y+1,1 do
              local c = Projectile('dirtchunk',{x=possessor.x,y=possessor.y},{x=x,y=y})
              c.symbol = "$"
              c.image_name = "coin"
              c.color = {r=255,g=255,b=0,a=255}
              c.use_color_with_tiles=false
            end --end fory
          end --end forx
        end
        possessor.mp = possessor.mp - (dmg-absorb)
        return (dmg-absorb)
      else
        if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. "'s economic bubble bursts!") end
        possessor.mp = 0
        possessor:cure_condition('moneyshield')
        return true
      end
    end, --end damaged code
    advance = function(self,possessor)
      possessor.mp = possessor.mp - 1
      if possessor.mp < 1 then
        if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " runs out of money to invest in the economic bubble, so it collapses.") end
        possessor:cure_condition('moneyshield')
      end
    end,
    cured = function(self,possessor)
      if player:can_see_tile(possessor.x,possessor.y) then
        output:sound('economicbubble_stop')
      end
    end
  }),

distracted = Condition({
    name = "Distracted",
    notices = function(self,possessor,target)
      if possessor:touching(target) and random(1,2) == 1 then return true end --50% chance of noticing someone next to you
      return false --otherwise don't notice them
    end
  }),

astralprojection = Condition({
    name = "Astral Projection",
    cured = function(self,possessor)
      if possessor == player then
        player:moveTo(possessor.body.x,possessor.body.y)
        player = possessor.body
        output:out("Your astral form returns to your body.")
      end
      possessor:remove()
      possessor.body.projection = nil
      possessor.body:cure_condition('outofbody')
    end,
    noticed = function(self,possessor,noticer)
      return false
    end,
    became_enemy = function(self,possessor,noticer)
      return false
    end,
    attacked = function(self,possessor,attacker)
      return false
    end,
    attacks = function(self,possessor,target)
      if possessor == player then output:out("Your astral form can't attack.") end
      return false
    end
  }),

outofbody = Condition({
    name = "Out of Body",
    bonuses={possession_chance=1000},
    damaged = function(self,possessor)
      output:out("Damage to your body causes your astral form to be pulled violently back!")
      possessor.projection:cure_condition('astralprojection')
      possessor:give_condition('stunned',2)
    end,
  }),

astralbanish = Condition({
    name = "Banished to the Astral Plane",
    bonuses={possession_chance=-1000},
    apply = function(self,possessor)
      possessor.color = {r=possessor.color.r,g=possessor.color.g,b=possessor.color.b,a=100}
      for _,creat in pairs(currMap.creatures) do
        if creat.target == possessor then creat.target = nil end
      end
    end,
    damaged = function(self,possessor)
      if player:can_see_tile(possessor.x,possessor.y) then output:out("The attack passes through " .. possessor:get_name() .. "'s astral form.") end
      return false
    end,
    attacks = function(self,possessor)
      if possessor == player then output:out("You can't attack anyone while in astral form.") end
      return false
    end,
    cured = function(self,possessor)
      possessor.color = {r=possessor.color.r,g=possessor.color.g,b=possessor.color.b,a=255}
    end,
  }),

channeling = Condition({
    name = "Channeling Spirits",
    bonuses={possession_chance=-1000},
    cured = function(self,possessor)
      for _, spirit in pairs(possessor.spirits) do
        spirit:remove()
        currMap:add_effect(Effect('animation',{image_name='unholydamage',image_max=5,target=spirit,color={r=150,g=150,b=0}}),spirit.x,spirit.y)
      end
      possessor.spirits = nil
      if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. "'s concentraion is broken. " .. ucfirst(possessor:get_pronoun('p')) .. " summoned spirits are banished back to wherever spirits come from.") end
      possessor.cooldowns['Channel the Spirits'] = 10
    end,
    moves = function(self,possessor)
      possessor:cure_condition('channeling')
    end, --end moves function
    attacks = function(self,possessor)
      possessor:cure_condition('channeling')
    end, --end attacks function
    damaged = function(self,possessor)
      possessor:cure_condition('channeling')
    end,
    ai = function(self,possessor)
      for x=possessor.x-1,possessor.x+1,1 do
        for y=possessor.y-1,possessor.y+1,1 do
          local creat = currMap:get_tile_creature(x,y)
          if creat and possessor:is_enemy(creat) then
            return true --return true to do normal AI
          end
        end --end fory
      end --end forx
      return false -- don't do anything
    end
  }),

illusorydouble = Condition({
    name = "Illusion",
    hidden=true,
    attacks = function(self,possessor,target)
      if possessor == player then
        output:out("You suddenly realize you are possessing an illusion! The illusion fades away.")
        possessor:die()
        currMap:add_effect(Effect('animation',{image_name='magicdamage',image_max=5,target={x=possessor.x,y=possessor.y},color={r=255,g=255,b=255}}),possessor.x,possessor.y)
      elseif player:can_sense_creature(possessor) and possessor.master ~= player then
        output:out(possessor:get_name() .. " misses " .. target:get_name() .. ".")
      end
      return false
    end,
    cured = function(self,possessor)
      possessor:die()
    end
  }),

  fervor = Condition({
    name = "Religious Fervor",
    bonuses={damage=10,critical_chance=5,hit_chance=5,dodge_chance=-5,aggression=100,bravery=100,notice_chance=15,speed=15,possession_chance=-1000,animation_time_percent=0.8},
    ai = function(self,possessor)
      ai.basic(possessor,{forceStupid=true,noRunning=true})
      return false
    end,
    apply = function(self,possessor)
      currMap:add_effect(Effect('conditionanimation',{owner=possessor,condition="fervor",symbol="",image_base="characterflashes",image_max=4,speed=0.1,sequence=true,color={r=200,g=0,b=0,a=255},use_color_with_tiles=true,spritesheet=true}),possessor.x,possessor.y)
    end
  }),

  shieldwall = Condition({
    name = "Shield Wall",
    bonuses={speed=-25,damage_percent=-25,notice_chance=-5,all_armor=10,hit_chance=-10},
    apply = function(self,possessor)
      if possessor.id == "templeguard" then possessor.image_name = "templeguardshielding" .. (possessor == player and "possessed" or "") end
    end,
    cured = function(self,possessor)
      if possessor.id == "templeguard" then possessor.image_name = "templeguard" .. (possessor == player and "possessed" or "") end
    end,
    damaged = function(self,possessor)
      if player:can_sense_creature(possessor) then
        output:sound('hit_metal')
      end
    end
  }),

spindashing = Condition({
		name = "Spinning",
    update = function(self,possessor,dt)
      if not possessor.zoomTo then possessor:cure_condition('spindashing') end
    end,
    apply = function(self,possessor)
      if possessor.id == "hedgehog" then possessor.image_name = "hedgehogrolling" .. (possessor == player and "possessed" or "") end
    end,
    cured = function(self,possessor)
      if possessor.id == "hedgehog" then possessor.image_name = "hedgehog" .. (possessor == player and "possessed" or "") end
    end,
	}),
  
  underwater = Condition({
    name = "Under Water",
    bonuses={stealth=50,dodge_chance=20,notice_chance=-25},
    apply=function(self,possessor)
      possessor.invisible=true
    end,
    cured=function(self,possessor)
      possessor.invisible=nil
      possessor.waterBubbleClock = nil
    end,
    attacks=function(self,possessor)
      possessor:cure_condition('underwater')
      return true
    end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.waterBubbleClock = (possessor.waterBubbleClock or 0) - dt
        if (possessor.waterBubbleClock <= 0 and random(1,5) == 1) and player:does_notice(possessor)  then
          local z = Effect('bubble',possessor.x,possessor.y)
          local water = nil
          for _,feat in pairs(currMap:get_tile_features(possessor.x,possessor.y)) do
            if feat.water == true then water = feat end
          end
          if not water then possessor:cure_condition('underwater') end
          z.color = water.color
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.waterBubbleClock = 1
        end
      end
      if currMap:tile_has_feature(possessor.x,possessor.y,'bridge') then
        possessor:cure_condition('underwater')
        return
      end
      if type(currMap[possessor.x][possessor.y]) == "table" and currMap[possessor.x][possessor.y].water == true then return true end
      for _,feat in pairs(currMap.contents[possessor.x][possessor.y]) do
        if feat.water == true then return true end
      end
      possessor:cure_condition('underwater')
    end
  }),

  exploding = Condition({
      name = "Exploding",
      apply = function(self,possessor)
        possessor.explodeCountdown = .5
        if possessor.deathSound then output:sound(possessor.deathSound)
        elseif possessor.soundgroup then output:sound(possessor.soundgroup .. "_death")
        elseif not output:sound(possessor.id .. "_death") then --output:sound return false if a sound doesn't exist
          output:sound('genericdeath') --default death
        end --end sound type if
      end,
      update = function(self,possessor,dt)
        possessor.explodeCountdown = possessor.explodeCountdown - dt
        possessor.xMod,possessor.yMod = random(-5,5),random(-5,5)
        if possessor.explodeCountdown <= 0 then
          possessor:explode()
        end --end countdown if
      end --end update function
    }),
  
  bloodstarved = Condition({
    name = "Starved for Blood",
    bonuses={hit_chance=-25,strength=-5,dodge_chance=-25}
  }),

  batform = Condition({
    name = "Bat Form",
    bonuses={blood_consumption=1},
    advance = function(self,possessor)
      if possessor.id ~= "vampirebat" then
        possessor:cure_condition('batform')
      elseif possessor.extra_stats.blood and possessor.extra_stats.blood.value < 1 then
        possessor:cure_condition('batform')
      end
    end,
    cured = function(self,possessor)
      if player:can_sense_creature(possessor) then
        output:out(possessor:get_name() .. " turns back into their normal form.")
      end
      possessor:undo_transformation()
    end
  }),
  
  --Basic conditions assumed to exist by the base game:
  
  knockback = Condition({
      name = "Knockback",
      apply = function(self,possessor,applier,turns)
        if possessor:has_spell('knockbackimmunity') then return false end
        local xMod,yMod = 0,0
        possessor.lastAttacker = applier
        if applier.x < possessor.x then xMod=1*random(1,turns)
        elseif applier.x>possessor.x then xMod=-1*random(1,turns) end
        if applier.y < possessor.y then yMod=1*random(1,turns)
        elseif applier.y>possessor.y then yMod=-1*random(1,turns) end
        possessor:flyTo({x=possessor.x+xMod,y=possessor.y+yMod})
        if applier and applier.baseType == "creature" and player:can_see_tile(possessor.x,possessor.y) then
          output:sound('collision_creature')
          currMap:add_effect(Effect('animation',{image_name='holydamage',image_max=5,color={r=255,g=255,b=0}}),possessor.x,possessor.y)
        end
      end,
      update = function(self,possessor)
        --This is here so the message shows up in the right place.
        if player:can_sense_creature(possessor) then output:out(possessor:get_name() .. " is knocked backwards!") end
        possessor.conditions['knockback'] = nil --Remove the condition so it never actually shows up
      end
  }),

asleep = Condition({ --Assumed to exist by the base game
		name = "Asleep",
    bonuses = {possession_chance=25,stealth=10,notice_chance=-30},
		ai = function (self, possessor)
			return false
		end,
    moves = function(self,possessor)
      return false
    end,
    damaged = function(self,possessor,attacker)
      possessor:cure_condition('asleep')
    end,
		attacks = function (self, possessor, target)
			return false
		end,
    attacks = function(self,possessor)
			return false
    end,
    apply = function (self,possessor)
      if (possessor.conditions['recentlyawoken'] and not currMap:tile_has_feature(possessor.x,possessor.y,"bed")) or possessor:has_spell('sleepless') then return false end --if the creature woke up recently, they can't fall asleep again. Unless they're on a bed because them shits are just so comfy.
      if player:can_sense_creature(possessor) then
        output:sound('fall_asleep')
      end
    end,
		cured = function (self,possessor)
      possessor.zClock = nil
			if player:can_see_tile(possessor.x,possessor.y) then output:out(possessor:get_name() .. " wakes up.") end
      possessor:give_condition('recentlyawoken',100)
		end,
    notices = function (self,possessor,target)
      if (possessor.id == 'mummy') then --mummies sleep until explicitly woken
        return false
      end
      if possessor:is_enemy(target) then --only enemies wake creatures
        local dist = calc_distance(possessor.x,possessor.y,target.x,target.y)
        if random(1,possessor:get_perception()) < dist then
          return false
        else
          possessor:cure_condition('asleep')
        end
      end
    end,
    update = function(self,possessor,dt)
      if player:does_notice(possessor) then
        possessor.zClock = (possessor.zClock or 0) - dt
        if (possessor.zClock <= 0 and random(1,5) == 1) then
          local z = Effect('sleepZ',possessor.x,possessor.y)
          currMap:add_effect(z,possessor.x,possessor.y)
          possessor.zClock = 1
        end
      end
    end
	}),

recentlyawoken = Condition({ --Assumed to exist by the base game
    name = "Recently Awoken",
  }),

overloaded = Condition({ --Assumed to exist by the base game if using inventory space. Do with this what you will, does nothing by default except clear itself if it's not needed. If you're not using inventory space, feel free to delete
    name = "Overloaded",
    update = function(self,possessor,dt)
      local space = possessor:get_free_inventory_space()
      if not space or (type(space) == "number" and space >= 0) then
        possessor:cure_condition('overloaded')
      end
    end
  }),
}