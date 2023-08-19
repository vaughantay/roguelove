conditions = {
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