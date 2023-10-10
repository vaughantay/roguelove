--The below spells were pulled straight from Possession, so may need some tweaking to work correctly.
possibleSpells = {

repairBody = Spell({
	name = "Repair Body",
	description = "Repairs all damage to your body, but reduces its maximum health.",
	cooldown = 10,
  innate = true,
	target_type = "self",
  sound="repair_body",
	cast = function (self,target,caster)
		local mhp_cost = math.max(math.ceil(caster.max_hp/5),5)
		if (caster.max_hp - mhp_cost < 10) then
			output:out("This body is already too decayed. It would fall apart entirely if you tried to repair it.")
			return false
		else
			output:out("You convert some of the body's life force into magical energy, and use it to heal the damage.")
			output:out("Your max health decreases by " .. mhp_cost .. ".")
			caster.max_hp = caster.max_hp - mhp_cost
			caster:updateHP(math.floor(caster.max_hp/2))
		end
	end,
  requires = function(self,caster)
    local mhp_cost = math.max(math.ceil(caster.max_hp/5),5)
    if (caster.max_hp - mhp_cost < 10) then
			return false,"This body is already too decayed. It would fall apart entirely if you tried to repair it."
    end
  end
}),

invisibility = Spell({
    name = "Invisibility",
    description = "Become temporarily invisible. Attacking or casting any offensive spells will cause you to become visible again. Because that's just how things like this work.",
    cooldown = 25,
    target_type = "self",
    flags={fleeing=true,defensive=true},
    cast = function(self,target,caster)
      caster:give_condition('invisible',10)
      output:sound('invisible')
    end
  }),

randomTeleport = Spell({
	name = "Random Teleport",
	description = "Teleports you to a random area somewhere in the dungeon.",
	target_type = "self",
  flags={fleeing=true},
	cast = function(self,target,caster)
		caster:give_condition("teleportCountdown",random(2,6))
	end
}),

devourcorpse = Spell({
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
        output:out("You dig up the grave and chow down on the rotting corpse heald within, regaining " .. hp .. " HP.")
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
}),

banish = Spell({
	name="Banishment",
	description="Teleports an enemy away from you.",
	cooldown=20,
	target_type="creature",
  flags={fleeing=true},
  sound="teleport",
	cast = function(self,target,caster)
    local origX,origY = target.x,target.y
		local x,y=random(2,currMap.width-1), random(2,currMap.height-1)
		while (x<2 or y<2 or x>currMap.width or y>currMap.height or target:can_move_to(x,y) == false) do
			x,y = random(2,currMap.width-1), random(2,currMap.height-1)
		end
		target:moveTo(x,y)
    if player:can_see_tile(origX,origY) then
      output:out(caster:get_name() .. " teleports " .. target:get_name() .. " away!")
      currMap:add_effect(Effect('animation','magicdamage',5,{x=origX,y=origY},{r=255,g=255,b=255}),origX,origY)
    end
	end
}),

spores = Spell({
	name = "Spore Cloud",
	description = "Blast a cloud of intoxicating spores at your enemies!",
	cooldown = 20,
  AIcooldown=35,
	flags = {aggressive=true},
	target_type = "tile",
  sound="summon_spores",
	cast = function (self,target,caster)
    if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " summons a cloud of spores!") end
		for x = target.x-2,target.x+2,1 do
			for y=target.y-2,target.y+2,1 do
				if (x>1 and y> 1 and x<currMap.width and y< currMap.height and currMap[x][y] ~= "#") then
          local spore = Effect('spores')
          spore.creator = caster
					currMap:add_effect(spore,x,y)
				end
			end
		end
	end,
  get_target_tiles = function(self,target,caster)
    local tiles = {}
    for x = target.x-2,target.x+2,1 do
			for y=target.y-2,target.y+2,1 do
				if (x>1 and y> 1 and x<currMap.width and y< currMap.height and currMap[x][y] ~= "#") then
					tiles[#tiles+1] = {x=x,y=y}
				end
			end
		end
    return tiles
  end
}),

mushroommen = Spell({
	name = "Summon Mushroom Men",
	description = "Summon the helpful friendly mushroom people!",
	cooldown = 25,
	flags = {aggressive=true,defensive=true},
	target_type = "self",
  sound="summon_shrooms",
	cast = function (self,target,caster)
		if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " summons a bunch of sentient shrooms!") end
		local shroomies = random(2,4)
    local tries = 0
		while (shroomies >= 1 and tries < 50) do
			local x,y = random(caster.x-3,caster.x+3),random(caster.y-3,caster.y+3)
			if (x>1 and y>1 and x< currMap.width and y< currMap.height and currMap:isClear(x,y)) then
				local shroomer = Creature('shroomman')
				currMap:add_creature(shroomer,x,y)
        shroomer:become_thrall(caster)
        shroomies = shroomies - 1
			end
      tries = tries + 1
		end
	end
}),

poisoncloud = Spell({
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
}),

trap = Spell({
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
}),

camera = Spell({
	name = "Snapshot",
	description = "Oh, what a weird-looking animal! Quick, take a picture of it!",
	cooldown = 5,
	range = 3,
	flags = {aggressive=true},
	target_type = "creature",
  sound = "camera",
  advance = function(self,possessor)
    if possessor.cooldowns['camera'] == nil then possessor.run_chance = 0 else possessor.run_chance = 100 end --if you can take a picture, don't run away
  end,
	cast = function (self, target, caster)
		if (calc_distance(caster.x,caster.y,target.x,target.y) > 3) then
			if (caster == player) then output:out(target:get_name() .. " is too far away to take a picture of in this dark dungeon. Your camera's flash isn't THAT good.") end
			return false
		else
      if player:can_see_tile(caster.x,caster.y) then
        if (target.baseType == "creature") then output:out("Say cheese! " .. ucfirst(caster:get_name()) .. " snaps a picture of " .. target:get_name() .. ".")
        else output:out("Say cheese! " .. ucfirst(caster:get_name()) .. " snaps a picture.") end
        if caster.isPlayer ~= true then caster.target = nil caster.run_chance=100 end --if NPC tourist, don't target your current target any more, and also run away until you can take a picture again
      end --end seen if
			for x=target.x-1,target.x+1,1 do
				for y=target.y-1,target.y+1,1 do
          currMap:add_effect(Effect('animation','holydamage',5,false,{r=255,g=255,b=0}),x,y)
					local creat = currMap:get_tile_creature(x,y)
					if (creat and creat ~= caster) then
            local result = random(1,3)
            if result == 1 then
              if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " is stunned by the flash!") end
              creat:give_condition("stunned",random(2,4))
            elseif result == 2 then
              if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " is temporarily blinded by the flash!") end
              creat:give_condition("blinded",random(4,6))
            elseif result == 3 then
              if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " is stunned and blinded by the flash!") end
              creat:give_condition("stunned",random(2,4))
              creat:give_condition("blinded",random(4,6))
            end
            if random(1,2) == 1 then --50% chance of pissing off the photographed creature
              creat.shitlist[caster] = true
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
}),

striketheearth = Spell({
	name = "Strike the Earth!",
	description = "Strike the Earth!",
	cooldown = 15,
  range = 5,
  flags = {aggressive=true},
	target_type = "self",
  sound="striketheearth",
	cast = function (self,target,caster)
		if player:can_sense_creature(caster) then output:out(caster:get_name() .. " strikes the earth!") end
		local ripple = Effect('earthquake')
    currMap:add_effect(ripple,caster.x,caster.y)
		ripple.creator = caster
		for x=caster.x-5,caster.x+5,1 do
			for y=caster.y-5,caster.y+5,1 do
				if (x>1 and y>1 and x<currMap.width and y<currMap.height) then
					local creat = currMap:get_tile_creature(x,y)
					if (creat and creat ~= caster) then
						local dmg = creat:damage(random(7,12),caster)
						if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " gets shaken up for " .. dmg .. " damage!") end
            if random(1,5) == 1 then creat:give_condition('stunned',2) end
					end
          local tnt = currMap:tile_has_feature(x,y,'tnt')
          if tnt then tnt:combust() end
				end
			end
		end
	end
}),

bodyslam = Spell({
	name = "Bodyslam",
	description = "Smash an opponent into the ground, stunning them!",
	cooldown = 10,
	range = 1,
	flags = {aggressive=true},
	target_type = "creature",
	cast = function (self,target,caster)
    local result,dmg = calc_attack(caster,target,true)
    target:give_condition('stunned',random(2,4))
    if player:can_see_tile(caster.x,caster.y) then
      output:out(caster:get_name() .. " bodyslams " .. target:get_name() .. " into the ground, dealing " .. dmg .. " damage and stunning " .. target:get_pronoun('o') .. ".")
      output:sound('collision_creature')
    end
	end
}),

flyingkick = Spell({
    name = "Flying Dropkick",
    description = "Jump towards a nearby enemy and kick them in the face! You'll need a bit of space to get up to speed.",
    cooldown = 10,
    range = 3,
    min_range=2,
    projectile = true,
    target_type = "creature",
    sound="dash",
    flags={aggressive=true},
    cast = function(self,target,caster)
      caster:flyTo(target,possibleSpells['flyingkickbash'])
    end
  }),

flyingkickbash = Spell({
  name = "Flying Kick Bash",
  description = "What happens after you flying kick someone.",
  target_type = "creature",
  cast = function(self,target,caster)
    local _,dmg = calc_attack(caster,target,true)
    if target and type(target) == "table" and target.baseType == "feature" or target.baseType == "creature" then
      dmg = target:damage(dmg,caster)
      local stun = (random(1,4) == 1)
      if player:can_see_tile(target.x,target.y) or player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " flies at " .. target:get_name() .. " and kicks " .. target:get_pronoun('o') .. " in the face, dealing " .. dmg .. " damage " .. (stun and " and stunning " .. target:get_pronoun('o') .. "." or "."))
        output:sound('collision_creature')
      end
      if stun then
        target:give_condition('stunned',random(3,5))
      end
      if random(1,4) == 1 then
        target:give_condition('knockback',random(1,2),caster)
      end
    end
  end
}),

shove = Spell({
    name = "Shove",
    target_type = "creature",
    flags={aggressive=true},
    description = "Shove an opponent backwards.",
    range = 1,
    projectile=true,
    cooldown = 10,
    AIcooldown = 20,
    cast = function(self,target,caster)
      target:give_condition('knockback',random(1,3),caster)
    end
  }),

spikes = Spell({
	name = "Spikes",
	description = "Spikes cover your body!",
	cooldown = 0,
	target_type = "passive",
	attacked = function(self,possessor,attacker)
		if (random(1,2) == 1) then
			local dmg = attacker:damage(random(4,7),possessor)
			if player:can_see_tile(possessor.x,possessor.y) then
        output:out(attacker:get_name() .. " runs into " .. possessor:get_name() .. "'s spikes as " .. attacker:get_pronoun('n') .. " attacks, taking " .. dmg .. " damage.")
        output:sound('hedgehog_spikes')
      end
		end
	end
}),

fireshield = Spell({
	name = "Flame Shield",
	description = "You're surrounded by flames. Anyone who attacks you will get burned.",
	cooldown = 0,
	target_type = "passive",
	attacked = function(self,possessor,attacker)
		if (random(1,2) == 1) then
			local dmg = attacker:damage(random(3,6),possessor,"fire")
			if dmg and dmg > 0 and player:can_see_tile(possessor.x,possessor.y) then output:out(attacker:get_name() .. " gets burnt by " .. possessor:get_name() .. "'s fire, taking " .. dmg .. " damage.") end
		end
	end
}),

veganism = Spell({
	name = "Vegan Metabolism",
	description = "Your healthy lifestyle has massively accelerated your body's healing process. You regain HP over time, as long as you stay active.",
	target_type = "passive",
	moves = function (self, possessor)
		if (random(1,10) == 1) then
			possessor:updateHP(1)
		end
	end
}),

reabsorb = Spell({
	name = "Reabsorb",
	description = "You can reabsorb a slime that split off of you, or an enemy slime that has less than half your HP.",
	target_type = "creature",
  range=1,
	cast = function(self,target,caster)
		if caster:touching(target) == false then
      output:out("You can't absorb a slime you're not touching.")
      return false
    end
    if target.master == caster or target.hp < caster.hp/2 then
      caster.max_hp = caster.max_hp + target.hp
      caster:updateHP(target.hp)
      output:out("You absorb the slime, gaining " .. target.hp .. " max HP.")
      output:sound('slime_absorb')
      target:remove()
    else
      if caster == player then output:out("You can only absorb a slime if it's friendly, or if it has less than half your HP.") end
      return false
    end
	end
}),

acid = Spell({
	name = "Throw Acid Flask",
	description = "Throw a beaker of highly corrosive acid at an area, creating a toxic spill. Why would you do this?",
  cooldown=10,
  AIcooldown = 20,
	target_type = "tile",
  projectile=true,
	flags = {aggressive=true},
	cast = function (self,target,caster)
    if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " throws an acid flask.") end
    Projectile('acid',caster,target)
    if caster.magic and caster == player then caster.magic = caster.magic-1 end
	end,
  requires = function(self,caster)
    if caster.id == "ratlingchemist" and caster.magic < 1 then
      return false,"You have no chemicals."
    end
  end,
  get_target_tiles = function(self,target,caster)
    local targets = {}
    for x=target.x-2,target.x+2,1 do
      for y=target.y-2,target.y+2,1 do
        if calc_distance(target.x,target.y,x,y) <= 2 then targets[#targets+1] = {x=x,y=y} end
      end --end fory
    end --end forx
    return targets
  end --end target draw function
}),

harvest = Spell({
	name = "Harvest Essential Humors",
	description = "Drain mysterious chemicals from a corpse, recharging your abilities.",
	target_type = "self",
  flags = {aggressive=true,defensive=true,fleeing=true,random=true},
  sound="harvesthumors",
	cast = function (self,target,caster)
		local corpse = currMap:tile_has_feature(caster.x,caster.y,"corpse")
		if corpse then
      if player:can_sense_creature(caster) then output:out(caster:get_name() .. " drains essential humors from the corpse" .. (corpse.creature and " of " .. corpse.creature:get_name() or "") .. ".") end
      caster.magic = caster.magic+1
      corpse:delete()
      return true
		end
		output:out("There's no corpse here to harvest.")
		return false
	end,
  requires = function(self,caster)
    local corpse = currMap:tile_has_feature(caster.x,caster.y,"corpse")
    if corpse then
      return true
    end
    return false,"There's no corpse here to harvest."
  end,
  decide = function(self,target,possessor)
    local cooldowns = count(possessor.cooldowns)
    if cooldowns > 0 and currMap:tile_has_feature(possessor.x,possessor.y,'corpse') then return true end --if you're standing on a corpse, awesome! harvest away!
    if cooldowns < 3 then return false end -- if not all your abilities are on cooldown, don't worry about it
    if possessor.target and possessor.target.id == "corpse" then return false end --if we're already heading towards a corpse, keep on keepin on
    --If you're not targeting a corpse, but it'd be worthwhile to, then see if there's one nearby:
    local perception = possessor:get_perception()
    local closestX,closestY = nil,nil
    local closestDist = nil
    local closestCorpse = nil
    for x=possessor.x-perception,possessor.x+perception,1 do
      for y=possessor.y-perception,possessor.y+perception,1 do
        local corpse = currMap:tile_has_feature(x,y,'corpse')
        if corpse then
          local dist = calc_distance_squared(possessor.x,possessor.y,x,y)
          if not closestDist or closestDist > dist then
            closestDist = dist
            closestX,closestY = x,y
            closestCorpse = corpse
          end
        end --end corpse if
      end --end yfor
    end --end xfor
    if not closestDist then return false end --couldn't find a corpse? never mind
    if not possessor.target or calc_distance_squared(possessor.target.x,possessor.target.y,possessor.x,possessor.y) > closestDist then
      possessor.target = closestCorpse
      return false
    end
    return false
  end
}),

molotov = Spell({
	name = "Molotov Cocktail",
	description = "What's a Revolutionary's favorite drink? A Cubre Libre of course. This, on the other hand, isn't a drink at all, it's an improvised explosive device.",
  cooldown=10,
  AIcooldown=20,
	target_type = "tile",
  projectile=true,
	flags = {aggressive=true},
	cast = function (self,target,caster)
    if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " throws a molotov cocktail.") end
    Projectile('molotov',caster,target)
    if caster.magic and caster == player then caster.magic = caster.magic-1 end
	end, --end cast function
  requires = function(self,caster)
    if caster.id == "ratlingchemist" and caster.magic < 1 then
      return false,"You have no chemicals."
    end
  end,
}),

jekyllhyde = Spell({
	name = "Consume Jekyllhyde",
	description = "Many ratlings' drug of choice is a terrible concoction known as \"Jekyllhyde.\" It causes extreme rage in the caster, but is very harmful for your health.",
  AIcooldown=40,
	target_type = "self",
  sound="jekyllhyde",
	flags={aggressive=true,defensive=true,fleeing=true},
	cast = function (self, target, caster)
		if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " downs some Jekyllhyde. " .. ucfirst(caster:get_pronoun('n')) .. " gets bigger, stronger, and meaner!") end
		caster:give_condition('jekyllhyde',tweak(25))
    if caster.magic and caster == player then caster.magic = caster.magic-1 end
	end,
  requires = function(self,caster)
    if caster.id == "ratlingchemist" and caster.magic < 1 then
      return false,"You have no chemicals."
    end
    if caster:has_condition('jekyllhyde') then
      return false,"You're already hopped up on jekyllhyde. You don't want to OD on that stuff, it's bad news."
    end
  end,
}),

golem = Spell({
	name = "Summon Golem",
	description = "Summons one of the servants of the God of Rock (not as exciting as he sounds).",
	cooldown = 250,
	target_type = "self",
	flags = {aggressive=true,defensive=true,fleeing=true},
	cast = function (self,target,caster)
		if player:can_see_tile(caster.x,caster.y) then
      output:out(caster:get_name() .. " summons a golem!")
      output:sound('summon_golem')
    end
		local done = false
		while (done == false) do
			local x,y = random(caster.x-3,caster.x+3),random(caster.y-3,caster.y+3)
			if (currMap:isClear(x,y)) then
				--[[local g = Creature('golem')
				currMap:add_creature(g,x,y)
        g:become_thrall(caster)]]
			end
			done = true
		end
	end
}),

stoneskin = Spell({
	name = "Stoneskin",
	description = "Covers your body partially in stone, blocking a great deal of damage, but slowing you down.",
	cooldown = 50,
	target_type = "self",
	flags = {aggressive=true},
  sound = "stonemagic_reverse",
	cast = function (self,target,caster)
		if player:can_sense_creature(caster) then output:out(caster:get_name() .. "'s skin hardens.") end
		caster:give_condition('stoneskin',tweak(30))
	end
}),

petrify = Spell({
	name = "Petrify",
	description = "Turns a target to stone, rendering them unable to attack or move, but also impervious to damage.",
	cooldown = 25,
	target_type = "creature",
  sound = "stonemagic",
	cast = function (self,target,caster)
		if player:can_sense_creature(target) then output:out(target:get_name() .. " turns to stone!") end
		--target:give_condition('petrified',tweak(15))
	end
}),

dash = Spell({
    name = "Dash",
    description = "Dash quickly to a nearby square.",
    cooldown = 10,
    range=5,
    projectile = true,
    target_type = "tile",
    sound="dash",
    flags={defensive=true,fleeing=true},
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " dashes!") end
      caster:flyTo(target,possibleSpells['landsafely'])
    end,
    decide = function(self,target,caster,use_type)
      if use_type == "agressive" then
        return target
      else
        local fearMap = caster:make_fear_map()
        local maxDist, maxX,maxY = nil,nil,nil
        
        for x,yTiles in pairs(fearMap) do 
          local x = x
          print("x: " .. x)
          for y,val in pairs(yTiles) do
            if type(maxDist) ~= "number" or (type(val) == "number" and val > maxDist) then
              maxDist,maxX,maxY = val,x,y
            end --end max dist if
          end --end fory
        end --end forx
        if maxX and maxY then return {x=maxX,y=maxY} else return false end
      end --end aggressive/fleeing if/else
    end --end decide function
  }),

landsafely = Spell({
    name = "Land Safely",
    description = "After a dash that's not a charge, to keep you from killing yourself running into walls.",
    cast = function(self,target,caster)
      --do nothing
    end
  }),

bash = Spell({
  name = "Bash",
  description = "What happens after you charge someone.",
  target_type = "creature",
  cast = function(self,target,caster)
    local _,dmg = calc_attack(caster,target,true)
    dmg = math.ceil(dmg*1.5)
    if target and type(target) == "table" and target.baseType == "feature" or target.baseType == "creature" then
      dmg = target:damage(dmg,caster)
      if player:can_see_tile(target.x,target.y) or player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " charges " .. target:get_name() .. ", dealing " .. dmg .. " damage.") 
        output:sound('collision_creature')
      end
      for _, condition in pairs (caster:get_hit_conditions()) do
				if (random(1,100) < condition.chance) then
					target:give_condition(condition.condition,tweak(condition.turns),caster)
				end -- end condition chance
			end	-- end condition forloop
    end
  end
}),

charge = Spell({
    name = "Charge",
    description = "Charge a nearby enemy.",
    cooldown = 10,
    range=6,
    min_range=2,
    projectile = true,
    target_type = "creature",
    sound="dash",
    flags={aggressive=true},
    cast = function(self,target,caster)
      caster:flyTo(target,possibleSpells['bash'])
    end
  }),

zombait = Spell({
    name = "Zombait",
    description = "Throw a piece of raw meat on the ground to distract nearby undead. If you throw it onto a creature instead, nearby undead will rush to attack them. Also works on animals.",
    cooldown = 20,
    projectile = true,
    target_type = "tile",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      Projectile('zombait',caster,target)
    end
  }),

bait = Spell({
    name = "Bait",
    description = "Throw a piece of raw meat on the ground to distract nearby animals (or undead). If you throw it onto a creature instead, animals or undead will rush to attack them.",
    cooldown = 20,
    projectile = true,
    target_type = "tile",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      Projectile('zombait',caster,target)
    end
  }),

undeadrepellent = Spell({
    name = "Undead Repellent",
    description = "A spray that makes the undead not want to eat you. Knowing how bad THEY smell, you have to wonder how bad this will make YOU smell.",
    cooldown = 30,
    target_type = "self",
    sound="spray_quiet",
    cast = function(self,target,caster)
      caster:give_condition('undeadrepellent',20)
      for _, c in pairs (currMap.creatures) do
          if c:is_type("undead") then
            if c.shitlist[caster] then c.shitlist[caster] = nil end
            if c.target == caster then c.target = nil end
            c:ignore(caster)
          end --end if
        end --end for
    end
  }),

slimetrail = Spell({
    name = "Slimy Secretions",
    target_type = "passive",
    description = "You leave a thick trail of slime wherever you go.",
    moves = function (self,possessor)
      local feats = currMap:get_tile_features(possessor.x,possessor.y)
      local slime = true
      for _, f in pairs(feats) do
        if f.id == "slime" or f.absorbs or f.water then slime = false break end --if there's already slime, don't reapply
      end
      if slime == true then
        local s = Feature('slime')
        currMap:add_feature(s,possessor.x,possessor.y)
        s:refresh_image_name()
        --[[for x=possessor.x-1,possessor.x+1,1 do
          for y=possessor.y-1,possessor.y+1,1 do
            local s = currMap:tile_has_feature(x,y,'slime')
            if s then s:refresh_image_name() end
          end --end fory
        end --end forx]]
      end
    end --end moves function
  }),

assassinate = Spell({
    name = "Expert Assassin",
    target_type = "passive",
    description = "When it comes to killing people, you are simply the best. If you attack a creature that doesn't know you're there, you kill them instantly.",
    attacks = function(self,possessor,target)
      if ((target:does_notice(possessor) == false or target:has_condition('asleep')) and target ~= player and target.isBoss ~= true) then
        if player:can_see_tile(possessor.x,possessor.y) then
          output:out(possessor:get_name() .. " murderstabs " .. target:get_name() .. ", killing " .. target:get_pronoun('o') .. " instantly!")
          output:sound('assassinate')
        end
        target.killer = possessor
        target:die()
        return false
      end
    end --end attacks function
  }),

smokebomb = Spell({
    name = "Smoke Bomb",
    target_type = "tile",
    cooldown = 10,
    AIcooldown=30,
    sound = "explosion_smoke",
    flags={aggressive=true,defensive=true,fleeing=true},
    description = "Throw a bomb which releases clouds of blinding smoke, making it easier for you to make an escape!",
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " throws a smoke bomb!") end
      currMap:add_effect(Effect('smoke'),target.x,target.y)
    end -- end cast function
}),

statueform = Spell({
    name = "Statue Form",
    target_type = "self",
    description = "Turn your body to a statue, rendering you immobile but also immune to damage. Or, if you're already in stone form, turn you back to flesh and blood.",
    flags={fleeing=true},
    sound="stonemagic_reverse",
    cast = function (self,target,caster)
      caster:give_condition('statueform',-1)
      caster.image_name = (caster == player and "gargoylestatueformpossessed" or "gargoylestatueform")
      caster.color={r=75,g=75,b=75,a=255}
    end
  }),

turtle = Spell({
    name = "Turtle Up!",
    target_type = "self",
    description = "Retract inside your shell,",
    flags={fleeing=true,defensive=true},
    cast = function (self,target,caster)
      caster:give_condition('inshell',10)
      caster.image_name = "tmntshell"
      caster.color={r=100,g=100,b=0,a=255}
      if caster ~= player then caster.symbol = "O" end
      if player:can_sense_creature(caster) then output:sound('turtle_hide') end
    end
  }),

brainwashed = Spell({
    name = "Brainwashed",
    target_type = "passive",
    description = "The previous inhabitant of your body was a member of a cult. Luckily for you, you're immune to the effects of the brainwashing.",
    notices = function(self,possessor,target)
      if possessor == player then return true end
      if possessor.master == nil or possessor.master.hp < 1 and not possessor.shitlist[target] then
        if (in_table('cultleader',target.spells)) then
          possessor:become_thrall(target)
          possessor.aggression=100
          possessor.bravery = nil
          possessor.fear = 0
          possessor.run_chance = 0
          return false
        end --end cultleader check
      end --end if has master
    end--end advance function
  }),

cultleader = Spell({
    name = "Cult Leader",
    target_type = "passive",
    description = "You have a magnetic personality. Unaligned cultists will be drawn to serve you."
  }),

awakenmummy = Spell({
    name = "Awaken Mummy",
    target_type = "tile",
    description = "Awaken an ancient ruler. If you awaken one this way, it will not be hostile towards you.",
    cast = function(self,target,caster)
      local sarc = currMap:tile_has_feature(target.x,target.y,'sarcophagus')
      if not sarc or sarc.activated then
        output:out("There's no mummy there to awaken.") 
        return false
      end
      local mummy = sarc.mummy
      mummy:ignore(caster)
      currMap:add_creature(mummy,sarc.x,sarc.y)
      if player:can_see_tile(target.x,target.y) then
        output:out(caster:get_name() .. " awakens an ancient mummy!")
        output:sound("mummy_awaken")
      end
      sarc.activated = true
      sarc.image_name = sarc.image_name .. "open"
      sarc.name = "Open Sarcophagus"
      sarc.description = "The former resting place of an ancient ruler."
      sarc.symbol = 0
    end
  }),

sacrifice = Spell({
    name = "Sacrifice Follower",
    target_type = "creature",
    description = "Drain the life force from one of your followers, killing them but replenishing your health and magic.",
    sound="unholydamage",
    flags={aggressive=true,defensive=true},
    cast = function(self,target,caster)
      if target.master == caster then
        output:out(caster:get_name() .. " drains the life from " .. target:get_name() .. "!")
        caster:updateHP(math.ceil(target.hp/2))
        currMap:add_effect(Effect('animation','unholydamage',5,false,{r=255,g=255,b=0}),target.x,target.y)
        target:die(false)
      else
        return false
      end
    end,
    decide = function(self,target,caster,use_type)
      if caster.hp < caster.max_hp/random(2,5) then --threshhold for using is random
        if caster.thralls and count(caster.thralls) > 0 then
          return get_random_element(caster.thralls)
        end --end thralls if
      end --end hp if
      return false
    end --end decide function
  }),

sandstorm = Spell({
  name = "Sandstorm",
  target_type = "tile",
  description = "Summon up a whirling cloud of blinding sand.",
  cooldown = 20,
  AIcooldown=30,
  flags={aggressive=true,fleeing=true,defensive=true},
  sound="snadstrom",
  cast = function(self,target,caster)
    for x = target.x-3,target.x+3,1 do
      for y = target.y-3,target.y+3,1 do
        if currMap:in_map(x,y) and calc_distance(x,y,target.x,target.y) <= 3 and currMap:isClear(x,y,nil,true) and currMap:is_line(x,y,caster.x,caster.y) then
          local sand = Effect('sandstorm')
          sand.creator = caster
          currMap:add_effect(sand,x,y)
        end --end x,y check if
      end --end fory
    end --end forx
  end,
  get_target_tiles = function(self,target,caster)
    local targets = {}
    for x=target.x-3,target.x+3,1 do
      for y=target.y-3,target.y+3,1 do
        if calc_distance(x,y,target.x,target.y) <= 3 and currMap:is_line(x,y,caster.x,caster.y) then targets[#targets+1] = {x=x,y=y} end
      end --end fory
    end --end forx
    return targets
  end --end target draw function
  }),

scarabs = Spell({
    name = "Summon Scarabs",
    target_type = "tile",
    description = "Cause a swarm of scarabs to erupt from a corpse",
    cooldown = 10,
    sound="bugswarm",
    cast = function(self,target,caster)
      local corpse = currMap:tile_has_feature(target.x,target.y,'corpse')
      if corpse then
        if player:can_see_tile(target.x,target.y) then
          output:out("A swarm of scarabs bursts from the " .. corpse.name .. "!")
          output:sound('explode')
        end
        corpse:delete()
        currMap:add_feature(Feature('chunk',corpse.creature,target.x,target.y),target.x,target.y)
        local scarabs = Effect('scarabs')
        scarabs.creator = caster
        currMap:add_effect(scarabs,target.x,target.y)
      else
        if caster == player then output:out("There's no corpse there.") end
        return false
      end
    end
}),
whiptrip = Spell({
    name = "Whip Trip",
    target_type = "creature",
    description = "Tangle your whip around an opponent's legs, tripping them.",
    range = 2,
    projectile=true,
    cooldown=5,
    AIcooldown=10,
    sound="whip1",
    flags={aggressive=true},
    cast = function(self,target,caster)
      local attack = calc_attack(caster,target)
      if (attack ~= "miss") then
        if player:can_sense_creature(target) then output:out(caster:get_name() .. " trips " .. target:get_name() .. " with their whip!") end
        target:give_condition('stunned',random(2,3))
      end
    end
  }),

whippull = Spell({
    name = "Whip Pull",
    target_type = "creature",
    description = "Pull an opponent towards you with your whip.",
    range = 2,
    projectile = true,
    flags={aggressive=true},
    cooldown=5,
    AIcooldown=10,
    sound="whip2",
    cast = function(self,target,caster)
      local attack = calc_attack(caster,target)
      if (attack ~= "miss") then
        if player:can_sense_creature(target) then output:out(caster:get_name() .. " pulls " .. target:get_name() .. " with their whip!") end
        local xMod,yMod = 0,0
        if caster.x < target.x then xMod=1
        elseif caster.x>target.x then xMod=-1 end
        if caster.y < target.y then yMod=1
        elseif caster.y>target.y then yMod=-1 end
        target:flyTo({x=caster.x+xMod,y=caster.y+yMod})
      end
    end,
    decide = function(self,target,caster)
      if caster:touching(target) then return false end
    end --end creature for
  }),

whipcrack = Spell({
    name = "Whip Crack",
    target_type = "creature",
    flags={aggressive=true},
    description = "Crack your whip loudly at an enemy, possibly spooking them and causing them to jump away from you.",
    range = 2,
    projectile=true,
    cooldown=5,
    AIcooldown=10,
    sound="whip1",
    cast = function(self,target,caster)
      local text = caster:get_name() .. " cracks their whip at " .. target:get_name() .. ". "
      local attack = calc_attack(caster,target)
      if (attack ~= "miss") then
        text = text .. ucfirst(target:get_name() .. " jumps away!")
        local xMod,yMod = 0,0
        if caster.x < target.x then xMod=2
        elseif caster.x>target.x then xMod=-2 end
        if caster.y < target.y then yMod=2
        elseif caster.y>target.y then yMod=-2 end
        target:flyTo({x=caster.x+xMod,y=caster.y+yMod})
        target:give_condition('stunned',1)
      end
      if player:can_sense_creature(target) then output:out(text) end
    end
  }),

wellkick = Spell({
    name = "Kick Down the Well",
    target_type = "creature",
    flags={aggressive=true},
    description = "Kick an opponent down the well. Provided there's a well directly behind them. If not, you just kick them backwards.",
    range = 1,
    projectile=true,
    cooldown = 10,
    AIcooldown = 20,
    cast = function(self,target,caster)
      target:give_condition('knockback',random(4,6),caster)
      if player:can_see_tile(target.x,target.y) then
        output:out(caster:get_name() .. " kicks " .. target:get_name() .. " backwards!")
        output:sound('collision_creature')
      end
    end
  }),

madness = Spell({
    name = "Blessing of Madness",
    target_type = "creature",
    cooldown=20,
    AIcooldown=30,
    sound="blessingofmadness",
    description = "Whisper the hideous secrets behind the universe to a mortal, rendering them temporarily insane! \nOnly works on intelligent (or at least semi-intelligent) creatures.",
    flags={aggressive=true,fleeing=true},
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " whispers the hideous secrets of the universe to " .. target:get_name() .. ".")
      end
      currMap:add_effect(Effect('animation','unholydamage',5,target,{r=150,g=150,b=0}),target.x,target.y)
      if (target:is_type('intelligent')) then
        target:give_condition('confused',tweak(5))
      else
        if caster == player then output:out(target:get_name() .. " isn't intelligent enough for said secrets to have any effect on " .. target:get_pronoun('p') .." psyche.") end
        return false
      end
    end,
    decide = function(self,target,caster)
      local creat = nil
      if caster.target and caster.target.baseType == "creature" and caster.target:is_type('intelligent') then return caster.target end
      
      local nearestDist = 0
      local nearest = nil
      for _, creat in pairs(caster:get_seen_creatures()) do
        if creat:is_enemy(caster) and creat:is_type('intelligent') then
          if caster:touching(creat) then nearest = creat break end
          local dist = calc_distance(caster.x,caster.y,creat.x,creat.y)
          if nearest == nil or nearestDist < dist then
            nearest = creat
            nearestDist = dist
          end --end nearest if
        end --end creature if
      end --end creature for
      
      return nearest or false
    end
  }),

guardedbyguardian = Spell({
    name = "Guarded by Guardians",
    target_type = "passive",
    description = "Eldritch guardians are genetically engineered to protect eldritch aristocrats. Guardians will never attack you, and if you get hurt near an inactive guardian, it will activate and target your attacker.",
    damaged = function(self,possessor,attacker,dmg)
      if not attacker or attacker.id == "eldritcharistocrat" then return end --even if an aristocrat attacks another one, it won't attack them
      
      for x = possessor.x-10,possessor.x+10,1 do
        for y = possessor.y-10,possessor.y+10,1 do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat.id == "eldritchguardian" and (not creat.target or creat.target.baseType ~= "creature") and creat:can_sense_creature(possessor) and creat:can_sense_creature(attacker) then
            creat:become_hostile(attacker)
            if player:can_see_tile(creat.x,creat.y) then output:out("A guardian awakens to defend " .. possessor:get_name() .. "!") end
          end
        end --end fory
      end -- end forx
    end
  }),

witnessprotection = Spell({
    name = "Witness Protection",
    target_type = "self",
    cooldown=100,
    description = "Places you far, far away, out of the reach of your enemies. Maybe.",
    flags={fleeing=true},
    cast = function(self,target,caster)
      output:out(caster:get_name() .. " starts the process of getting placed into witness protection.")
      caster:give_condition("teleportCountdown",random(2,4))
    end
  }),

bailout = Spell({
    name = "Bailout",
    target_type = "self",
    description = "You can't be held accountable for your mistakes, you're too big to fail! If you're in trouble, you can get a bailout, which will restore all your HP and give you more money. Be warned, though, you can only use this ability once. Any more and people might start questioning capitalism, and we can't have that.",
    sound="bailout",
    cast = function(self,target,caster)
      output:out(caster:get_name() .. " gets a bailout!")
      caster:updateHP(caster.max_hp)
      for spell,_ in pairs(caster.cooldowns) do
        caster.cooldowns[spell] = nil
      end
      caster.magic = caster.magic + 100
      for id,spell in pairs(caster.spells) do
        if spell == 'bailout' then caster.spells[id] = nil break end
      end
    end
  }),

throwmoney = Spell({
    name = "Throw Money",
    target_type = "tile",
    description = "Throw a bunch of money on the ground, distracting nearby intelligent enemies.",
    flags={defensive=true,fleeing=true},
    cast = function(self,target,caster)
      local coins = math.min(caster.magic or 0,15)
      if coins == 0 then
        if caster == player then output:out("You don't have any money, so you can't throw any money on the ground.") end 
        return false
      end
      
      caster.magic = caster.magic - coins
      local tries = 0
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " throws some coins!")
        output:sound('throwmoney')
      end
      while coins > 0 and tries < 50 do
        local x,y = random(target.x-3,target.x+3),random(target.y-3,target.y+3)
        if x>1 and y>1 and x<currMap.width and y<currMap.height and currMap[x][y] ~= "#" and currMap:tile_has_feature(x,y,'coins') == false then
          local makeCoin = true
          for _,feat in pairs(currMap:get_tile_features(x,y)) do
            if feat.absorbs then makeCoin = false break end
          end
          if makeCoin then
            currMap:add_effect(Effect('coinattractor',{x=x,y=y}),x,y)
            coins = coins - 1
          end
        end
        tries = tries + 1
      end
    end, -- end cast function
    get_target_tiles = function(self,target,caster)
      local targets = {}
      for x=target.x-3,target.x+3,1 do
        for y=target.y-3,target.y+3,1 do
          targets[#targets+1] = {x=x,y=y}
        end --end fory
      end --end forx
      return targets
    end, --end target draw function
    requires = function(self,caster)
      local coins = math.min(caster.magic or 0,15)
      if coins == 0 then
        return false,"You don't have any money, so you can't throw any money on the ground."
      end
    end,
    decide = function(self,caster,target)
      local creats = caster:get_seen_creatures()
      local enemies = 0
      for _,creat in pairs(creats) do
        if creat.shitlist[caster] and creat ~= caster and creat ~= player and creat:is_type('intelligent') then
          enemies = enemies+1
        end
      end --end creat for
      if enemies > 1 then return target end
      return false
    end
}),

moneyshield = Spell({
    name = "Economic Bubble",
    target_type = "self",
    description = "Bubbles eventually burst, but while you're in them, you feel invincible! This ability is a toggleable shield that causes half of the damage you take to be subtracted from your money instead of your health.",
    flags={aggressive=true,defensive=true},
    cast = function(self,target,caster)
      if caster:has_condition('moneyshield') then
        if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. "'s bubble dissipates.") end
        caster:cure_condition('moneyshield')
      else
        if player:can_see_tile(caster.x,caster.y) then
          output:out(caster:get_name() .. " is surrounded by a protective bubble.")
          output:sound('economicbubble_start')
        end
        caster:give_condition('moneyshield',-1)
        local bubble = currMap:add_effect(Effect('conditionanimation',{owner=caster,condition="moneyshield",symbol="O",image_base="moneyshield",image_max=4,speed=0.1,sequence=true,color={r=255,g=255,b=0,a=125},colors={{r=255,g=255,b=0,a=125},{r=150,g=150,b=0,a=125},{r=255,g=255,b=0,a=125},{r=150,g=150,b=0,a=125}}}),caster.x,caster.y)
      end
    end,
    requires = function(self,caster)
      if not caster.magic or caster.magic == 0 then
        return false,"You don't have any money, so you can't participate in an economic bubble."
      end
    end,
    decide = function(self,target,caster)
      local creats = caster:get_seen_creatures()
      local enemy = false
      local targeted = false
      for _,creat in pairs(creats) do
        if creat.shitlist[caster] or target == player then
          enemy = true
          if creat.target == caster then targeted=true end
        end
        if enemy == true and targeted == true then break end
      end
      if enemy == false or targeted == false then
        if caster:has_condition('moneyshield') then return true
        else return false end
      else
        if caster:has_condition('moneyshield') == false then return caster end
      end
      return false
    end
  }),

bribe = Spell({
    name = "Bribe",
    target_type = "creature",
    description = "Bribe an intelligent (or at least semi-intelligent) creature not to attack you, and possibly even to fight for you.",
    flags={defensive=true,fleeing=true},
    cost=50,
    cast = function(self,target,caster)
      if caster.magic < 50 then
        if caster == player then output:out("You don't have enough money to bribe " .. target:get_name() .. ".") end
        return false
      end
      
      if (target:is_type('intelligent')) then
        local text = caster:get_name() .. " bribes " .. target:get_name() .. "."
        currMap:add_effect(Effect('animation','rainofgold',5,target,{r=255,g=255,b=0}),target.x,target.y)
        local shitlist = target.shitlist[caster]
        if target.shitlist[caster] then target.shitlist[caster] = nil end
        if target.target == caster then target.target = nil end
        if not target.master and (not shitlist or random(1,5)) == 1 then
          target:become_thrall(caster)
          text = text .. " " .. target:get_name() .. " begins following " .. caster:get_name() .. "."
        else
          target:ignore(caster)
        end
        if player:can_see_tile(target.x,target.y) then
          output:out(text)
          output:sound('bribe')
        end
      else
        if player == caster then output:out("You can't bribe something with no interest in money.") end
        return false -- can't bribe unintelligent creatures
      end
    end,
    requires = function(self,caster)
      if not caster.magic or caster.magic < 50 then
        return false,"You don't have any money, so you can't bribe anyone."
      end
    end,
    decide = function(self,caster,target)
      local creats = caster:get_seen_creatures()
      local highestHP = 0
      local highestCreat = nil
      for _,creat in pairs(creats) do
        if creat.shitlist[caster] and creat ~= player and creat ~= self and creat:is_type('intelligent') then
          if creat.hp > highestHP then
            highestHP = creat.hp
            highestCreat = creat
          end
        end
      end --end creat for
      if highestCreat then return highestCreat end
      return false
    end
  }),

reinvest = Spell({
    name = "Reinvest Dividends",
    target_type = "passive",
    description = "You have money in blue chip investments that provide steady income over time. The best part about it is that the more money you have, the more you'll gain.",
    advance = function(self,possessor)
      if possessor == player and currGame.stats.turns % 10 == 0 and (possessor == player or possessor.magic < 1000) then
        possessor.magic = possessor.magic + math.min(100,math.max(1,math.ceil(possessor.magic/10)))
        if possessor == player then
          local p = Effect('dmgpopup',possessor.x,possessor.y)
          p.symbol = "$"
          p.image_name = "coin"
          p.use_color_with_tiles = false
          currMap:add_effect(p,possessor.x,possessor.y)
          p.color = {r=255,g=255,b=0,a=255}
          output:sound('coinstep_player')
        end
      end
    end
  }),

ratswarm = Spell({
    name = "Rat Swarm",
    description = "Loose a swarm of ravenous rodents!",
    target_type = "tile",
    projectile = true,
    cooldown = 25,
    flags={aggressive=true},
    sound="summon_ratswarm",
    cast = function(self,target,caster)
      local creat = currMap:get_tile_creature(target.x,target.y)
      if creat and (creat:is_type('ratling') or creat:is_type('rat')) then 
        if caster == player then output:out("The rat swarm won't attack other rats.") end
        return false
      end
      local rats = Projectile('ratswarm',caster,target)
      if player:can_sense_creature(caster) then
        output:out(caster:get_name() .. " releases a swarm of hungry rats!")
      end
    end
  }),

poetry = Spell({
    name = "Open Mic Night",
    description = "Recite some of your original poetry. This will cause all nearby intelligent creatures' ears to bleed, but will also cause them to become hostile towards you.",
    target_type="self",
    cost = 1,
    cast = function(self,target,caster)
      caster:give_condition('recitingpoetry',-1)
    end
  }),

lovepoem = Spell({
    name = "Compose Love Poem",
    cost = 5,
    target_type="creature",
    description = "Compose a love poem for the creature of your choice. If they're intelligent, this will cause to get incredibly creeped out and try to avoid you as much as possible.",
    sound="kiss",
    cast = function (self,target,caster)
      if target:is_type('intelligent') then
        local tname = target:get_name()
        local poemnames = {"For the Love of " .. tname,"How Do I Love " .. tname .. "? Let Me Count the Ways","Sonnet #" .. random(2,1000) .. ": "  .. tname,"How I Long For " .. tname,"Hot, Sexy " .. tname,"My Love (and Loins) Burn(s) for " .. tname,tname .. ", I Think I love You",tname .. ", My Heart","The Moon, the Stars, and " .. tname,random(9,50) .. " Reasons Why " .. tname .. " Should Love Me", "One Night in " .. tname, tname .. ", Why Won't You Love Me?",tname .. " and I Should Totally Bang"}
        output:out(caster:get_name() .. " quickly writes up and delivers a new poem, " .. poemnames[random(#poemnames)] ..". This really freaks " .. tname .. " out.")
        target:give_condition('fear',-1)
      else
        output:out(target:get_name() .. " isn't a sapient being. Writing a love poem to them would be both ineffectual, and even creepier than a regular love poem.")
        return false
      end --end intelligent if
    end
  }),

epicpoem = Spell({
    name = "Recite Epic Poem",
    target_type = "self",
    cost = 5,
    description = "Recite an epicly long epic poem. Any intelligent creatures nearby will instantly fall asleep.",
    sound="ratlingpoet_epicpoem",
    cast = function(self,target,caster)
      local poemnames = {"The Epic of","The Tale of","The Journey of","The Cycle of","The Works of","The Days of","The Story of"}
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " recites " .. poemnames[random(#poemnames)] .. " " .. namegen:generate_human_name() .. ". When " .. caster:get_pronoun('n') .. " finishes, " .. caster:get_pronoun('n') .. " looks around to realize everyone has fallen asleep.") end
      currMap:add_effect(Effect('soundwavemaker',{r=83,g=84,b=255}),caster.x,caster.y)
      for x=caster.x-10,caster.x+10,1 do
        for y=caster.y-10,caster.y+1,1 do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= caster and creat:is_type('intelligent') then
            creat:give_condition('asleep',random(10,100))
          end
        end
      end
    end --end cast function
  }),

caveabsinthe = Spell({
    name = "Drink Cave Absinthe",
    description = "Ratling poets tend to turn to the bottle to find their inspiration (and to dull the pain of the fact that nobody likes them). Hallucinogenic cave absinthe is their drink of choice. As a plus, its high alcohol content renders it very flammable, leading to many a tragicomic self-immolation.",
    target_type="self",
    cooldown=50,
    sound = "absinthe",
    cast = function(self,target,caster)
      caster.magic = caster.magic + 20
      caster:give_condition('wasted',10)
      for x = math.max(2,caster.x-10),math.min(caster.x+10,currMap.width-1) do
        for y = math.max(2,caster.y-10),math.min(caster.y+10,currMap.height-1) do
          if random(1,3) == 1 then currMap:add_effect(Effect('absinthefairy',caster),x,y) end
        end --end fory
      end --end forx
    end
  }),

circleofprotection = Spell({
    name = "Circle of Protection",
    target_type = "self",
    description = "Inscribe a divine circle of protection around yourself, which will protect you from direct attack by any demons. It won't protect against anyone or anything else, though.",
    cost=5,
    cooldown = 20,
    sound="writing",
    cast = function(self,target,caster)
      if caster.magic < self.mp_cost then
        if caster == player then output:out("You don't have enough piety to create a circle of protection.") end
        return false
      end
      local circle = Feature('pentagram')
      circle.color={r=255,g=255,b=255,a=255}
      currMap:add_feature(circle,caster.x,caster.y)
      caster.circle = circle
      caster:give_condition('circleofprotection',-1)
      currMap:add_effect(Effect('animation','holydamage',5,false,{r=255,g=255,b=0}),caster.x,caster.y)
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " draws a circle of protection.")
        output:sound('holydamage')
      end
    end,
    requires = function(self,caster)
      if caster.magic < self.mp_cost then
        return false,"You don't have enough piety to create a circle of protection."
      end
    end
  }),

holywarrior = Spell({
    name = "Holy Warrior",
    target_type = "passive",
    description = "You kick ass for the Lord! When you kill a demon or other unholy creature, you'll gain some piety.",
    kills = function(self,possessor,victim)
      if victim:is_type('demon') or victim:is_type('undead') or victim:is_type('abomination') then
        possessor.magic = possessor.magic + 5
        currMap:add_effect(Effect('animation','floatingpluses',5,possessor,{r=254,g=255,b=211,a=255},true,true),possessor.x,possessor.y)
        currMap:add_effect(Effect('animation','holydamage',5,false,{r=255,g=255,b=0}),victim.x,victim.y)
        if possessor == player then
          output:out("Killing " .. possessor:get_name() .. " grants you holy power!")
          output:sound('holydamage')
        end
      end
    end
  }),

lasso = Spell({
    name = "Lasso",
    target_type = "creature",
    cooldown=15,
    AIcooldown=25,
    range=5,
    description = "You can lasso something, tangling it up so it can't move for a while.",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " lassos " .. target:get_name() .. "! Yee-haw!")
        output:sound('throw_lasso')
      end
      target:give_condition('entangled',tweak(6))
      currMap:add_effect(Effect('conditionanimation',{owner=target,condition="entangled",symbol="~",image_base="lassotangle",image_max=2,speed=target.animation_time,color={r=255,g=164,b=100,a=255},use_color_with_tiles=false,spritesheet=true}),target.x,target.y)
    end
  }),

throwspear = Spell({
    name = "Throw Spear",
    target_type = "creature",
    projectile=true,
    description = "Toss your spear at an enemy.",
    output_sound="throw_spear",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      if player:can_sense_creature(caster) then
        output:out(caster:get_name() .. " throws a spear at " .. target:get_name() .. ".")
      end
      Projectile('spear',caster,target)
      caster:give_condition('spearless',-1)
    end,
    requires = function(self,caster)
      if caster:has_condition('spearless') then
        return false,"You already threw your spear. You'll have to go pick it up if you want to throw it again."
      end
      return true
    end
  }),

repelDemon = Spell({
    name = "Repel Demon",
    target_type = "creature",
    cooldown = 10,
    range=2,
    description = "Keeps an enemy from getting too close to you.",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      if target:is_type('demon') then
        if player:can_see_tile(caster.x,caster.y) then
          output:out(caster:get_name() .. " repels " .. target:get_name())
          currMap:add_effect(Effect('animation','holydamage',5,false,{r=255,g=255,b=0}),target.x,target.y)
          output:sound('holydamage')
        end
        target:give_condition('knockback',tweak(4),caster)
      else
        if caster == player then output:out("As repellent as you might be, you can't repel things that aren't demons.") end
        return false
      end
    end
  }),

entanglingvines = Spell({
    name = "Entangling Vines",
    target_type = "creature",
    projectile=false,
    description = "Summon vines out of the ground to grab your enemies and prevent them from moving.",
    cooldown = 10,
    flags={aggressive=true, defensive=true, fleeing=true},
    cast = function(self,target,caster)
      target:give_condition('entangled',random(4,6))
    end
  }),

awakentrees = Spell({
    name = "Awaken Wood",
    target_type="tile",
    projectile=false,
    description = "Rouse the spirits of the trees and bring them to your aid.",
    cooldown = 30,
    cast = function(self,target,caster)
      for x = target.x-1,target.x+1,1 do
        for y=target.y-1,target.y+1,1 do
          if x>1 and y>1 and x<currMap.width and y<currMap.height then
            local tree = currMap:tile_has_feature(x,y,'tree')
            if tree then
              tree:delete()
              local treant = Creature('treant')
              currMap:add_creature(treant,x,y)
              if (caster == player) then
                treant.color={r=125,g=200,b=0,a=255}
                treant.image_name = "treantally"
              end --end player if
              treant:become_thrall(caster)
            end --end tree if
          end --end bounds x
        end --end fory
      end --end forx
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
  }),

treeteleport = Spell({
    name = "Tree Teleportation",
    description = "Instantly transport yourself to a nearby tree.",
    target_type = "tile",
    projectile = "false",
    cooldown = 10,
    cast = function(self,target,caster)
      local origX,origY = caster.x,caster.y
      if currMap:tile_has_feature(target.x,target.y,'tree') then
        local line = currMap:get_line(caster.x,caster.y,target.x,target.y,true)
        if caster:can_move_to(line[#line-1][1],line[#line-1][2]) then
          caster:moveTo(line[#line-1][1],line[#line-1][2])
          output:out(caster:get_name() .. " teleports to a nearby tree!")
          currMap:add_effect(Effect('animation','magicdamage',5,{x=origX,y=origY},{r=255,g=255,b=255}),origX,origY)
        else
          --go to a random spot touching the tree
        end
      else
        output:out("There's no tree there.")
        return false
      end
    end
  }),

heal = Spell({
    name = "Heal Other",
    target_type = "creature",
    cooldown = 5,
    description = "Practice the healing arts on a nearby creature. If cast on an unfriendly creature, there's a chance they will become friendly towards you.",
    flags={friendly=true},
    cast = function(self,target,caster)
      if target == caster then output:out("You can't use this ability to heal yourself. That's too selfish for an orc.") return false end
      if target.hp < target:get_max_hp() then
        if caster:touching(target) then
          local amt = math.max(5,math.ceil(target:get_max_hp() *.05))
          if player:can_see_tile(caster.x,caster.y) then
            output:out(caster:get_name() .. " heals " .. target:get_name() .. " for amt damage.")
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
  }),

stimpack = Spell({
    name = "Stimpack",
    target_type = "creature",
    cooldown = 15,
    AIcooldown=20,
    description = "Shoot up a creature with a military-grade mixture of adrenal stimulants, causing increased strength and aggression for a short amount of time.",
    flags={friendly=true},
    cast = function(self,target,caster)
      if target == caster then output:out("You can't use this ability to buff yourself. That's too selfish for an orc.") return false end
      if caster:touching(target) then
        target:give_condition('enraged',15,caster)
      else --if not touching
        Projectile('stimsyringe',caster,target)
      end
    end,
    decide = function(self,target,caster)
      if random(1,5) ~= 1 then return false end
      local creats = caster:get_seen_creatures()
      local mostDmg, dmgedCreat = nil,nil
      local noEnemies = true
      if creats then
        for _,creat in pairs(creats) do
          if creat ~= caster then
            if creat.shitlist[caster] or creat == player then
              noEnemies = false
            else
              local hp = creat.hp
              if (mostDmg == nil or hp > mostDmg) and hp > 0 then
                mostDmg,dmgedCreat = hp,creat
              end --end damage if
            end -- end hostile if
          end --end creat ~= caster if
        end --end creature for
      end --end self sees if
      return dmgedCreat or false
    end
  }),

frogcurse = Spell({
    name = "Polymorph",
    target_type = "creature",
    cooldown = 25,
    description = "Turn an enemy into a slimy amphibian!",
    sound="frogcurse",
    flags={defensive=true,fleeing=true},
    cast = function(self,target,caster)
      if caster == player and caster == target then
        output:out("You can't turn yourself into a frog.")
        return false
      elseif target.id == "witch" then
        if caster == player then output:out("Witches don't turn each other into frogs. Professional courtesty.") end
        return false
      end
      if player:can_see_tile(target.x,target.y) then output:out(caster:get_name() .. " transforms " .. target:get_name() .. " into a frog!") end
      local froggy = Creature('froggy',0)
      froggy.originalForm = target
      froggy.max_hp = target.max_hp
      froggy.hp = target.hp
      froggy.properName = target.properName
      froggy.possession_chance = target.possession_chance
      froggy:give_condition('frogcurse',random(15,25))
      froggy.gender = target.gender
      target:remove()
      currMap:add_creature(froggy,target.x,target.y)
      currMap:add_effect(Effect('animation','magicdamage',5,target,{r=255,g=255,b=0}),target.x,target.y)
      if target == player then
        player = froggy
        froggy.isPlayer = true
        froggy.image_name = "froggypossessed"
      end
    end,
    decide = function(self,target,caster)
      local creat = nil
      if caster.target and caster.target.baseType == "creature" and caster.target.id ~="witch" then return caster.target end
      
      local nearestDist = 0
      local nearest = nil
      for _, creat in pairs(caster:get_seen_creatures()) do
        if creat:is_enemy(caster) then
          if caster:touching(creat) and creat.id ~= "witch" then nearest = creat break end
          local dist = calc_distance(caster.x,caster.y,creat.x,creat.y)
          if creat.id ~= "witch" and creat ~= caster and (nearest == nil or nearestDist < dist) then
            nearest = creat
            nearestDist = dist
          end --end nearest if
        end --end creature if
      end --end creature for
      
      return nearest or false
    end
  }),

devour = Spell({
    name = "Devour",
    target_type="creature",
    description = "Eat a creature whole! It will still be alive in your stomach as you digest it, potentially causing you damage as it fights to be free. However, if you manage to digest it entirely, you'll gain HP.",
    range=1,
    sound="chomp",
    cast = function(self,target,caster)
      if target == caster then
        output:out("Autocannibalism is not an option here. Or anywhere, really.")
        return false
      end
      output:out(caster:get_name() .. " gobbles down " .. target:get_name() .. "!")
      caster.digesting = target
      target.digestor = caster
      target:forceMove(caster.x,caster.y)
      target.noDraw = true
      caster:give_condition('digesting',target.hp)
      target:give_condition('beingdigested',target.hp)
    end
  }),

spit = Spell({
    name = "Spit Out",
    target_type = "tile",
    projectile=true,
    description = "Projectile vomit the creature you are currently digesting.",
    flags={aggressive=true},
    sound = "lizard_spit_up",
    cast = function(self,target,caster)
      if caster.digesting == nil then
        output:out("You aren't currently digesting anything, so you can't spit them up.")
        return false
      else
        if caster:touching(target) and caster.digesting:can_move_to(target.x,target.y) == false then
          output:out("There's not enough space to spit out the " .. caster.digesting:get_name() .. " there.")
          return false
        end
        caster.digesting:flyTo({x=target.x,y=target.y})
        caster.digesting.digestor = nil
        caster.digesting:cure_condition('beingdigested')
        caster.digesting.noDraw = nil
        caster.digesting = nil
      end
    end,
    requires = function(self,caster)
      if not caster:has_condition('digesting') then
        return false,"You have nothing to spit out. Try devouring something first."
      end
  end
  }),

hypnotize = Spell({
    name = "Hypnotize",
    target_type = "creature",
    AIcooldown=30,
    flags={aggressive=true},
    description = "Convert a creature to your side. Be warned that you can only hypnotize one creature at a time. If you try to hypnotize another one, the first creature will snap out of it and hate you with a passion.",
    cast = function(self,target,caster)
      if target.isPlayer then return false end
      if target:is_type('mindless') then
        output:out(target:get_name() .. " is mindless, and cannot be hypnotized.")
        return false
      end
      if target.master == caster and caster == player then
        output:out("You are already in control of that creature.")
        return false
      end
      --If none of the above are true, hypnotize the target:
      if caster.hypno then --if you've already hypnotized someone
        caster.hypno:cure_condition('hypnotized') --unhypnotize them
      end
      if target.master then target.oldmaster = target.master end --store target's old master, in case they become unhypnotized
      target:become_thrall(caster)
      target:give_condition('hypnotized',-1)
      caster.hypno = target
      if player:can_sense_creature(target) then
        output:out(caster:get_name() .. " hypnotizes " .. target:get_name() .. ".")
        currMap:add_effect(Effect('animation','spiral',4,target,{r=31,g=28,b=255},false,true),target.x,target.y)
        output:sound('hypnotize')
      end
    end,
    dies = function(self,possessor)
      if possessor.hypno then
        possessor.hypno:cure_condition('hypnotized')
      end
    end,
    decide = function(self,caster,target)
      if caster.hypno and caster.hypno.hp >= caster.hypno:get_max_hp()/2 then return false end --if you have a hypnotized creature that's still relatively healthy, don't hypnotize anyone else
      local creats = caster:get_seen_creatures()
      local highestHP = 0
      local highestCreat = nil
      for _,creat in pairs(creats) do
        if creat ~= player and creat ~= self and creat ~= caster.hypno and creat ~= caster and creat.id ~= "brainiac" and not creat:is_type('mindless') then
          if creat.hp > highestHP then
            highestHP = creat.hp
            highestCreat = creat
          end
        end
      end --end creat for
      if highestCreat then return highestCreat end
      return false
    end
  }),

brainshock = Spell({
    name = "Brainshock",
    description = "Scramble a creature's mind, confusing or stunning them.",
    target_type = "creature",
    cooldown = 20,
    AIcooldown=30,
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      if target.conditions['stunned'] or target.conditions['confused'] then
        output:out(target:get_name() .. " is already stunned or confused.")
        return false
      end
      if target:is_type('mindless') then
        output:out(target:get_name() .. " doesn't have a brain to scramble.")
        return false
      end
      
      if player:can_sense_creature(target) then
        output:out(caster:get_name() .. " scrambles " .. target:get_name() .. "'s brain!")
        output:sound('brainshock')
        currMap:add_effect(Effect('animation','electricdamage',5,target,{r=0,g=0,b=255}),target.x,target.y)
      end
      if random(1,2) == 1 then --confuse
        target:give_condition('confused',tweak(target == player and 5 or 10))
      else --stun
        target:give_condition('stunned',tweak(5))
      end
    end
  }),

wipememory = Spell({
    name = "Wipe Memory",
    description = "Wipe all memory of your presence from a creature's mind, and make you invisible to them for good measure.",
    target_type = "creature",
    cooldown = 25,
    cast = function(self,target,caster)
      if target:is_type('mindless') then
        output:out(target:get_name() .. " doesn't have a memory to blank out.")
        return false
      end
       if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " wipes " .. target:get_name() .. "'s memory!")
        output:sound('brainshock')
        currMap:add_effect(Effect('animation','spiral',4,target,{r=255,g=255,b=255},false,true),target.x,target.y)
      end
      target:ignore(caster)
      if target.target == caster then target.target = nil end
    end
  }),

psychic = Spell({
    name = "Psychic Senses",
    description = "You can sense the presence of others, even if you can't see them.",
    target_type = "passive",
    sense = function(self,possessor,target)
      if not possessor.x or not possessor.y or not target.x or not target.y or calc_distance(possessor.x,possessor.y,target.x,target.y) > possessor:get_perception() then
        return false
      end
      return true
    end
  }),

bansheescream = Spell({
    name = "Banshee Scream",
    description = "Let loose with a deafening scream, stunning and damaging all creatures in the area.",
    target_type="self",
    flags={aggressive=true,defensive=true,fleeing=true},
    cooldown=15,
    AIcooldown=30,
    sound="scream_banshee",
    cast = function(self,target,caster)
      currMap:add_effect(Effect('soundwavemaker',{r=120,g=123,b=255}),caster.x,caster.y)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " lets loose a horrible screech!") end
      for x=math.max(caster.x-10,2),math.min(currMap.width-1,caster.x+10) do
        for y=math.max(caster.y-10,2),math.min(currMap.height-1,caster.y+10) do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= caster then
            creat:notice(caster)
            local dmg = creat:damage(random(5,10),caster,"unholy")
            if player:can_see_tile(creat.x,creat.y) then
              output:out("The sonic blast hits " .. creat:get_name() .. " for " .. dmg .. " damage!")
            end
            if random(1,3) == 1 then creat:give_condition("stunned",random(1,4)) end
            creat.fear = creat.fear + tweak(25)
          end
        end --end fory
      end --end forx
    end
}),

deathwail = Spell({
    name = "Death Wail",
    description = "Banshees are able to let out a bonechilling wail, rumored to be a portent of death. This will cause most intelligent beings to experience, at best, an existential crisis; at worst, abject terror.",
    target_type = "creature",
    flags={aggressive=true,defensive=true,fleeing=true},
    cooldown=15,
    AIcooldown=30,
    sound="scream_deathwail",
    cast = function(self,target,caster)
      local wave = Projectile('soundwave',{x=caster.x,y=caster.y},{x=target.x,y=target.y},{r=66,g=66,b=66})
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " wails to " .. target:get_name() .. " of " .. target:get_pronoun('p') .. " death.") end
      if not target:is_type('mindless') and not target:is_type('undead') and target ~= player and random(1,2) == 1 then
        target:give_condition('fear',tweak(30))
      else
        target:give_condition('stunned',tweak(5))
        target.fear = target.fear + 100
      end
    end
  }),

directedscream = Spell({
    name = "Directed Scream",
    description = "By focusing the full force of their mighty voice, banshees are able to blast an unfortunate soul with a massive soundwave, which deals damage and knocks them back.",
    target_type = "creature",
    flags={aggressive=true,defensive=true,fleeing=true},
    cooldown=15,
    AIcooldown=30,
    sound="scream_directed",
    cast = function(self,target,caster)
      local wave = Projectile('soundwave',{x=caster.x,y=caster.y},{x=target.x,y=target.y},{r=150,g=66,b=66})
      local dmg = target:damage(random(10,20),caster,"unholy")
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " screams with " .. caster:get_pronoun('p') .. " sound and "  .. caster:get_pronoun('p') .. " fury at " .. target:get_name() .. ", dealing " .. dmg .. " damage.") end
      target:give_condition('stunned',random(2,4))
      target.fear = target.fear + tweak(50)
    end
  }),

rainbowblast = Spell({
    name = "Rainbow Blast",
    description = "A multicolored beam of pure magic shoots out of your horn, hitting everything in its path.",
    target_type = "tile",
    projectile = false,
    sound = "rainbowblast2",
    cooldown=5,
    AIcooldown=10,
    flags={aggressive=true},
    cast = function(self,target,caster)
      if target.x == caster.x and target.y == caster.y then return false end
      local xDist,yDist = target.x-caster.x,target.y-caster.y
      while currMap:is_line(caster.x,caster.y,target.x,target.y,false,'flyer',true) do
        target = {x=target.x+xDist,y=target.y+yDist}
      end
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " shoots a rainbow blast out of " .. caster:get_pronoun('p') .. " horn!") end
      currMap:add_effect(Effect('blaster',{x=caster.x,y=caster.y,target=target,effect='rainbowblast'}),caster.x,caster.y)
    end,
    get_target_tiles = function(self,target,caster)
      local targets = {}
      if target.x == caster.x and target.y == caster.y then return {} end
      local xDist,yDist = target.x-caster.x,target.y-caster.y
      while currMap:is_line(caster.x,caster.y,target.x,target.y,false,'flyer',true) do
        target = {x=target.x+xDist,y=target.y+yDist}
      end
      local tempLine,_ = currMap:get_line(caster.x,caster.y,target.x,target.y,false,'flyer',true)
      for _, v in ipairs(tempLine) do
        targets[#targets+1] = {x=v[1],y=v[2]}
      end --end for
      return targets
    end
  }),

tranqdart = Spell({
	name="Tranquilizer Dart",
	description="Shoot a tranquilizer dart at your enemy, slowing them down or possibly causing them to fall asleep.",
	cooldown=20,
	target_type = "creature",
  projectile = true,
	flags = {aggressive=true},
	cast = function(self,target,caster)
    if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " shoots a tranquilizer dart at " .. target:get_name() .. ".") end
    Projectile('tranqdart',caster,target)
	end --end cast function
}),

eyelaser = Spell({
    name = "Eye laser",
    description = "Shoot a giant laser from your eye.",
    target_type = "tile",
    sound="laser",
    projectile = false,
    cooldown=5,
    AIcooldown=10,
    flags={aggressive=true},
    cast = function(self,target,caster)
      if target.x == caster.x and target.y == caster.y then return false end
      local xDist,yDist = target.x-caster.x,target.y-caster.y
      while currMap:is_line(caster.x,caster.y,target.x,target.y,false,'flyer',true) do
        target = {x=target.x+xDist,y=target.y+yDist}
      end
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " shoots a massive laser out of " .. caster:get_pronoun('p') .. " eye!") end
      currMap:add_effect(Effect('blaster',{x=caster.x,y=caster.y,target=target,effect='eyelaser'}),caster.x,caster.y)
    end,
    get_target_tiles = function(self,target,caster)
      local targets = {}
      if target.x == caster.x and target.y == caster.y then return {} end
      local xDist,yDist = target.x-caster.x,target.y-caster.y
      while currMap:is_line(caster.x,caster.y,target.x,target.y,false,'flyer',true) do
        target = {x=target.x+xDist,y=target.y+yDist}
      end
      local tempLine,_ = currMap:get_line(caster.x,caster.y,target.x,target.y,false,'flyer',true)
      for _, v in ipairs(tempLine) do
        targets[#targets+1] = {x=v[1],y=v[2]}
      end --end for
      return targets
    end
  }),

bloodshield = Spell({
    name = "Like Blood from a Stone",
    target_type = "self",
    description = "One of the first things that blood mages learn is how to control their bleeding so they don't bleed to death. This spell will cause you to take 50% less damage from physical sources (except blood magic spells).\nCost: 10 HP",
    sound="bloodshield",
    cast = function(self,target,caster)
      if caster.hp > 10 then
        caster:damage(10,caster,"bloodmagic")
        caster:give_condition('bloodshield',25)
        local shield = currMap:add_effect(Effect('conditionanimation',{owner=caster,condition="bloodshield",symbol="∆",image_base="bloodshield",image_max=5,speed=0.1,sequence=true,color={r=255,g=0,b=0,a=125},colors={{r=255,g=0,b=0,a=125},nil,{r=150,g=0,b=0,a=125},nil}}),caster.x,caster.y)
      else
        if caster == player then output:out("You're not healthy enough to cast that spell. It would kill you!") end
        return false
      end
    end
  }),

bloodbond = Spell({
    name = "Blood Bond",
    target_type = "creature",
    description = "Forms a blood bond between the caster and another creature. From now on, half the damage taken by either one is instead taken by the other. The spell is cancelled when either party dies.\nCost: 10 HP",
    sound="bloodshield",
    cast = function(self,target,caster)
      if target:is_type('bloodless') then
        if caster == player then output:out("You can't cast a blood bond on something with no blood!") end
        return false
      end
      if caster.hp > 10 then
        caster:damage(10,caster,"bloodmagic")
        if caster.bloodbond then --if you're already blood bonded, cancel the original blood bond
          caster.bloodbond:cure_condition('bloodbond')
          caster.bloodbond.bloodbond = nil
        end
        caster:give_condition('bloodbond',-1)
        target:give_condition('bloodbond',-1)
        caster.bloodbond = target
        target.bloodbond = caster
      else
        if caster == player then output:out("You're not healthy enough to cast that spell. It would kill you!") end
        return false
      end
    end
  }),

bloodcurdle = Spell({
    name = "Bloodcurdling",
    target_type = "creature",
    description = "Curdle a creature's blood (which is a really gross expression if you take it literally), causing them to become terrified and run away.\nCost: 10 HP",
    sound="bleeding",
    cast = function(self,target,caster)
      if target:is_type('bloodless') then
        if caster == player then output:out("You can't curdle the blood of something with no blood!") end
        return false
      end
       if caster.hp > 10 then
        caster:damage(10,caster,"bloodmagic")
        target:give_condition('fear',tweak(50))
        if player:can_see_tile(target.x,target.y) then
          output:sound('deadlypremonition')
          output:out(caster:get_name() .. " curdles " .. target:get_name() .. "'s blood!")
        end
      else
        if caster == player then output:out("You're not healthy enough to cast that spell. It would kill you!") end
        return false
      end
    end
  }),

bloodsight = Spell({
    name = "Bloodsight",
    description = "You can sense the location of your bloodbonded creature.",
    target_type = "passive",
    sense = function(self,possessor,target)
      if possessor.bloodbond == target then return true end
      return false
    end
  }),

throwbomb = Spell({
  name = "Throw Bomb",
  target_type = "tile",
  description = "Throw a bomb at an area, dealing splash damage. It might not land quite where you aim, though...",
  projectile = true,
  AIcooldown=5,
  sound="woosh",
  flags={aggressive=true},
  cast = function(self,target,caster)
    if caster.magic > 0 then
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " throws a bomb!") end
      Projectile('bomb',caster,{x=target.x+random(-1,1),y=target.y+random(-1,1)})
      caster.magic = caster.magic - 1
    else
      if caster == player then output:out("You don't have any bombs!") end
      return false
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
  decide = function(self,target,caster,use_type)
    if caster:touching(target) then return false end --don't throw a bomb if you'll get hoisted by your own petard
    return true
  end
}),

landmine = Spell({
    name = "Place Dwarven Mine",
    target_type = "self",
    description = "Bury a dwarven mine at your current location. Dwarven mines are normally used to dig out dwarven mines, but this one is wired to explode when someone steps on it.",
    flags={defensive=true,fleeing=true,random=true},
    cast = function(self,target,caster)
      if caster.magic > 0 then
        currMap:add_feature(Feature('landmine'),caster.x,caster.y)
        caster.magic = caster.magic - 1
        if caster == player then output:sound('shovel_dig') end
      else
        if caster == player then output:out("You don't have any bombs!") end
        return false
      end
    end,
    decide = function(self,target,caster,use_type)
      if use_type == "random" then
        if caster.magic > 5 and random(1,10) == 1 and not currMap:tile_has_feature(caster.x,caster.y,'landmine') then return true end --only lay random landmines if you have more than 5 bombs remaining
      end
      return false
    end
  }),

makebombs = Spell({
    name = "Make More Bombs",
    target_type = "self",
    description = "Make some more bombs. Pretty dangerous, you'll probably (definitely) end up accidentally blowing some of them up.",
    cooldown = 50,
    flags={aggressive=true},
    sound="makebombs",
    cast = function(self,target,caster)
      caster.magic = caster.magic + random(2,10)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " makes a bunch of bombs, but accidentally causes an explosion.") end
      for x=caster.x-1,caster.x+1,1 do
        for y=caster.y-1,caster.y+1,1 do
          currMap:add_effect(Effect('explosion'),x,y)
          local creat = currMap:get_tile_creature(x,y)
          if creat then
            local dmg = creat:damage(tweak(5),caster)
            if player:can_see_tile(creat.x,creat.y) then output:out(creat:get_name() .. " gets caught in the explosion and takes " .. dmg .. " damage.") end
          end
        end --end fory
      end --end forx
    end,
    decide = function(self,target,caster)
      if caster.magic > 0 or not caster:touching(target) then
        return false
      end
      return true
    end
  }),

servedrinks = Spell({
    name = "Drinks on the House",
    target_type = "creature",
    range = 1,
    cooldown = 25,
    sound = "serve_drink",
    description = "Serve a ridiculously strong drink to a guest, getting them completely wasted. This will either make them really friendly, or really violent.",
    flags={aggressive=true,defensive=true,fleeing=true,friendly=true},
    cast = function(self,target,caster)
      if target == caster then
        output:out("You can't drink on the job or you'll get fired.")
        return false
      end
      if target:is_type('mindless') then
        output:out(target:get_name() .. " has no interest in alcohol.")
        return false
      end
      if target:is_type('undead') or target:is_type('construct') then
        output:out(target:get_name() .. " can't drink alcohol.")
        return false
      end
      target:updateHP(random(5,10))
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " serves a ridiculously strong cocktail to " .. target:get_name() .. ".")
        currMap:add_effect(Effect('animation','splash',5,target,{r=170,g=142,b=177},target.x,target.y,nil,true))
      end
      if not in_table('liverofsteel',target.spells) then
        target:give_condition('wasted',20)
        elseif player:can_see_tile(caster.x,caster.y) or caster == player then
          output:out(target:get_name() .. " has a liver of steel, so the drink doesn't get " .. target:get_pronoun('o') .. " very drunk.")
      end
      local enemy = target.shitlist[caster]
      target.shitlist[caster] = false
      if target.target == caster then target.target = nil end
      if not target.master and random(1,(enemy and 10 or 2)) then
        target:become_thrall(caster)
      else
        target:ignore(caster)
      end
    end,
    decide = function(self,target,caster)
      local creat = nil
      
      --So...this will give preference to creatures on the left and upper side of the server. But IDGAF
      for x=caster.x-1,caster.x+1,1 do
        for y=caster.y-1,caster.y+1,1 do
          local c = currMap:get_tile_creature(x,y)
          if c and c ~= caster and not c:is_type('mindless') then creat = c break end
        end
      end
      
      return creat or false
    end
  }),

serverbounce = Spell({
    name = "Bounce",
    target_type = "creature",
    flags={aggressive=true},
    description = "Orcs are big enough to take the term \"bouncer\" literally.",
    range = 1,
    projectile=true,
    cooldown = 10,
    AIcooldown=20,
    sound="bounce",
    cast = function(self,target,caster)
      if target == caster then
        output:out("You can't kick yourself out. I mean, you could, but that's just called \"leaving.\"")
      end
      if player:can_see_tile(target.x,target.y) or player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " bounces " .. target:get_name() .. " away.")
      end
      target:give_condition('knockback',random(1,4),caster)
      if random(1,3) == 1 then target:give_condition('stunned',random(2,4),caster) end
    end
  }),

  instaparty = Spell({
    name = "Instant Party",
    target_type = "creature",
    cooldown = 25,
    description = "Get a creature completely wasted!",
    sound = "serve_drink",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      if target == caster and caster == player then
        output:out("You're already drinking enough.")
        return false
      end
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " gets " .. target:get_name() .. " completely wasted with " .. caster:get_pronoun('p') .. " mind!")
      end
      target:give_condition('wasted',20)
    end
  }),

liverofsteel = Spell({
    name = "Liver of Steel",
    description = "You have a massive tolerance for alcohol. It's pretty hard for you to get more than just a buzz.",
    target_type = "passive",
  }),

  deadsummoner = Spell({
    name = "Summoner of the Dead",
    description = "The Baron's special ability, continuously resummons skellies and zombos.",
    target_type = "passive",
    advance = function(self,possessor)
      local thralls = count(possessor.thralls)
      local saidsomething = false
      if thralls < 4 then
        local zombos = 4-thralls
        while zombos > 0 do
          local dist = 1
          local newX,newY = random(possessor.x-dist,possessor.x+dist),random(possessor.y-dist,possessor.y+dist)
          while (newX < 2 or newY < 2 or newX>=currMap.width or newY>=currMap.height or currMap:is_passable_for(newX,newY) == false) and dist<5 do
            dist=dist+1
            newX,newY = random(possessor.x-dist,possessor.x+dist),random(possessor.y-dist,possessor.y+dist)
        end --end while newX/newY
        if currMap:is_passable_for(newX,newY) then
          local z = Creature((random(1,2) == 1 and 'zombie' or 'skeleton'),1)
          z:become_thrall(possessor)
          currMap:add_creature(z,newX,newY)
          currMap:add_effect(Effect('animation','unholydamage',5,z,{r=150,g=150,b=0}),newX,newY)
          if (player:can_see_tile(possessor.x,possessor.y) or player:can_see_tile(newX,newY)) and saidsomething == false then
            saidsomething=true
            output:out("The dead rise to serve The Baron!")
          end
        end --end if passable
        zombos = zombos - 1 --even if one wasn't made, decrease the count so we won't get stuck here forever
      end --end while
    end --end if thralls
  end, --end avance function
  dies = function(self,possessor)
    output:out("The Baron's undead servants crumble into dust.")
    for _, thrall in pairs(possessor.thralls) do
      thrall:die()
    end
  end --end dies function
}),

booze_fire = Spell({
    name = "Breathe Fire?",
    description = "You once saw a highly-traied street performer in a faraway land do this really cool trick with a bottle of flammable booze, and you're drunk enough to think you can replicate it.",
    target_type = "tile",
    range=2,
    AIcooldown=10,
    sound="cough",
    flags={aggressive=true},
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " tries to breathe fire using some highly flammable alcohol. " .. ucfirst(caster:get_pronoun('n')) .. " kind of succeeds, but also catches on fire.")
      end
      caster:give_condition('onfire',2)
      Projectile('boozefirebreath',caster,target)
    end
  }),

  song_wrath = Spell({
    name = "Aria of Aggravation",
    description = "Play a song of anger and war, enraging all nearby and causing them to turn on each other with murderous intent.",
    target_type="self",
    cooldown = 20,
    AIcooldown=25,
    sound = "song_anger",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      currMap:add_effect(Effect('soundwavemaker',{r=100,g=0,b=0},5),caster.x,caster.y)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " plays a war chant, getting everyone riled up!") end
      for x=math.max(caster.x-5,2),math.min(currMap.width-1,caster.x+5) do
        for y=math.max(caster.y-5,2),math.min(currMap.height-1,caster.y+5) do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= caster then
            creat:notice(caster)
            creat:give_condition('enraged',20)
          end
        end --end fory
      end --end forx
      possibleSpells['song_cooldowns']:use(caster)
    end --end cast
  }),

  song_sleep = Spell({
    name = "Madrigal of Mopiness",
    description = "Play a calming song, making everyone nearby sleepy and lethargic, possibly even causing them to fall into a deep slumber.",
    target_type="self",
    cooldown = 20,
    AIcooldown=25,
    sound = "song_sleep",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      currMap:add_effect(Effect('soundwavemaker',{r=120,g=123,b=255},5),caster.x,caster.y)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " plays a calming lullaby.") end
      for x=caster.x-5,caster.x+5,1 do
        for y=caster.y-5,caster.y+5,1 do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= caster then
            creat:notice(caster)
            if creat:has_condition('rage') then creat:cure_condition('rage') end
            creat:give_condition('lethargic',20)
            if random(1,5) == 1 then creat:give_condition('asleep',10) end
          end
        end --end fory
      end --end forx
      possibleSpells['song_cooldowns']:use(caster)
    end
  }),

song_fear = Spell({
    name = "Hymn of Horror",
    description = "Play some unnerving music, causing everyone nearby to be a little more afraid.",
    target_type="self",
    cooldown = 20,
    AIcooldown=25,
    sound = "song_fear",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      currMap:add_effect(Effect('soundwavemaker',{r=50,g=0,b=50},5),caster.x,caster.y)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " plays a scary song!") end
      for x=math.max(caster.x-5,2),math.min(currMap.width-1,caster.x+5) do
        for y=math.max(caster.y-5,2),math.min(currMap.height-1,caster.y+5) do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= caster then
            creat:notice(caster)
            creat.fear = creat.fear + random(25,50)
          end
        end --end fory
      end --end forx
      possibleSpells['song_cooldowns']:use(caster)
    end
  }),
  
  song_damage = Spell({
    name = "Toccata of Torment",
    description = "Shred a wicked solo, causing massive ear pain to everyone nearby. METAL!",
    target_type="self",
    cooldown = 20,
    AIcooldown=25,
    sound = "song_damage",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      currMap:add_effect(Effect('soundwavemaker',{r=33,g=33,b=33},5),caster.x,caster.y)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " plays a loud, discordant lute solo!") end
      for x=math.max(caster.x-5,2),math.min(currMap.width-1,caster.x+5) do
        for y=math.max(caster.y-5,2),math.min(currMap.height-1,caster.y+5) do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= caster then
            creat:notice(caster)
            local dmg = creat:damage(random(5,10),caster,"unholy")
            if player:can_see_tile(creat.x,creat.y) then
              output:out("The song offends " .. creat:get_name() .. " for " .. dmg .. " damage!")
            end
          end
        end --end fory
      end --end forx
      possibleSpells['song_cooldowns']:use(caster)
    end
  }),

  song_inspiration = Spell({
    name = "Ballad of Bravery",
    description = "Sing to an adventurer (or someone else, I guess) about their greatness, causing them to actually BECOME slightly greater, and to be friendly towards you.",
    target_type="creature",
    cooldown = 20,
    AIcooldown=25,
    sound = "song_inspiration",
    flags={friendly=true,aggressive = true},
    decide = function(self,target,caster,use_type)
      if use_type == "aggressive" and target == player then return false end --don't cast this on player if you're an NPC, because it won't make the player friendly towards you
      if target:is_type('intelligent') == false then return false end
    end,
    cast = function(self,target,caster)
      if target:is_type('intelligent') == false then
        if caster == player then output:out(target:get_name() .. " isn't intelligent. Trying to suck up to them through song won't work.") end
        return false
      end
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " plays an inspiring song to " .. target:get_name() .. " about their greatness.") end
      target:give_condition('inspired',20)
      if not target.master then
        target:become_thrall(caster)
      end
      possibleSpells['song_cooldowns']:use(caster)
    end
  }),

song_denounce = Spell({
    name = "Ditty of Denunciation",
    description = "Call out how terrible someone is, causing all the angry drunks nearby to attack them!",
    target_type="creature",
    cooldown = 20,
    AIcooldown=25,
    sound = "song_denounce",
    flags={aggressive = true},
    decide = function(self,target,caster,use_type)
      if not target:is_enemy(caster) then return false end
    end,
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " sings about how terrible " .. target:get_name() .. " is. Everyone nearby gets really mad at " .. target:get_name() .. "!") end
      target:become_hostile(caster)
      currMap:add_effect(Effect('soundwavemaker',{r=255,g=0,b=0},5),caster.x,caster.y)
      for x=math.max(caster.x-5,2),math.min(currMap.width-1,caster.x+5) do
        for y=math.max(caster.y-5,2),math.min(currMap.height-1,caster.y+5) do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= caster and creat ~= target and (creat:has_condition('drunk') or creat:has_condition('wasted') or creat:has_condition('enraged') or creat.shitlist[target]) then
            creat:notice(caster)
            creat:notice(target)
            creat:become_hostile(target)
          end
        end --end fory
      end --end forx
      possibleSpells['song_cooldowns']:use(caster)
    end
  }),

song_confusion = Spell({
    name = "Chords of Confusion",
    description = "Play a mysterious melody unheard in this European-inspired fantasy land. Rumor has it that it's from a land somewhere to the East, because Eastern lands are always mystical so their music must be too. In any case, this song makes everyone nearby confused.",
    target_type="self",
    cooldown = 20,
    AIcooldown=25,
    sound = "song_confusion",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      currMap:add_effect(Effect('soundwavemaker',{r=150,g=0,b=150},5),caster.x,caster.y)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " plays a mysterious melody.") end
      for x=caster.x-5,caster.x+5,1 do
        for y=caster.y-5,caster.y+5,1 do
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat ~= caster then
            creat:notice(caster)
            creat:give_condition('confused',10)
          end
        end --end fory
      end --end forx
      possibleSpells['song_cooldowns']:use(caster)
    end
  }),

  song_cooldowns = Spell({
      name = "Set all songs to cooldown",
      description = "Sets all songs to cooldown. You shouldn't be seeing this.",
      use = function(self,caster)
        for _,spell in pairs(caster.spells) do
          if not possibleSpells[spell].innate then
            caster.cooldowns[possibleSpells[spell].name] = (caster == player and 10 or 20)
          end
        end
      end
    }),

  tentacleGrapple = Spell({
      name = "Tentacle Grapple",
      description = "Grab onto a nearby enemy with your grossnasty tentacles. If they're out of reach, you'll pull them towards you.",
      range=2,
      cooldown=5,
      AIcooldown=15,
      flags={aggressive=true},
      target_type="creature",
      projectile = true,
      cast = function(self,target,caster)
        if target == caster and caster == player then
          output:out("You wrap your tentacles around yourself and give yourself a slimy hug.")
          return false
        end
        local text = caster:get_name() .. " wraps " .. caster:get_pronoun('p') .. " tentacles around " .. target:get_name()
        target:give_condition('grappled',-1,caster)
        currMap:add_effect(Effect('conditionanimation',{owner=target,condition="grappled",symbol="~",image_base="tentacletangle",image_max=2,speed=target.animation_time,color={r=0,g=100,b=0,a=255},use_color_with_tiles=false,spritesheet=true}),target.x,target.y)
        if not caster:touching(target) then
          local xMod,yMod = get_unit_vector(target.x,target.y,caster.x,caster.y)
          target:flyTo({x=target.x+xMod,y=target.y+yMod})
          text = text .. " and pulls " .. target:get_pronoun("o") .. " towards " .. caster:get_pronoun("o")
        end
        if player:can_see_tile(caster.x,caster.y) then
          output:out(text .. ".")
        end
      end,
      decide = function(self,target,caster)
        if caster:touching(target) then return false end
      end --end creature for
    }),
  
  rainofgold = Spell({
    name = "Rain of Gold",
    target_type = "creature",
    description = "Summon gold from thin air and buffet an enemy with it.",
    cooldown=10,
    sound="economicbubble_hit",
    flags={aggressive=true},
    cast = function(self,target,caster)
      local dmg = target:damage(random(10,13),caster)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " summons some coins out of thin air and flings them at " .. target:get_name() .. ", dealing " .. dmg .. " damage!") end
      currMap:add_effect(Effect('animation','rainofgold',5,target,{r=255,g=255,b=0}),target.x,target.y)
      currMap:add_effect(Effect('coinattractor',{x=target.x,y=target.y}),target.x,target.y)
    end -- end cast function
}),

  psychoanalyze = Spell({
      name = "Psychoanalyze",
      target_type = "creature",
      description = "Peer deep into someone's mind and/or soul or whatever, and determine their deepest, darkest fears and secrets.",
      cooldown=10,
      flags = {aggressive = true},
      sound="ratlingpsychologist_analyze",
      cast = function(self,target,caster)
        if target:is_type("intelligent") == false then
          if caster == player then output:out("Not even the most overconfident and misinformed psychology student can psycholanalyze something with no psyche.") end
          return false
        end
        
        local tname = target:get_name()
        local result = random(1,4)
        local resulttext = ""
        if result == 1 then -- rage
          resulttext = ucfirst(tname) .. " is enraged by the revelation."
          target:give_condition('enraged',random(15,25),caster)
          target:become_hostile(caster)
          target.target = caster
        elseif result == 2 then -- stunned
          resulttext = ucfirst(tname) .. " is stunned by the revelation."
          target:give_condition('stunned',random(4,6),caster)
        elseif result == 3 then -- fear
          resulttext = ucfirst(tname) .. " is shocked and horrified by the revelation."
          target:give_condition('fear',random(15,25),caster)
        elseif result == 4 then -- love
          resulttext = ucfirst(tname) .. " breaks down in tears, infinitely thankful towards " .. caster:get_name() .. " for helping them."
          target:become_thrall(caster)
        end
          
        if player:can_see_tile(caster.x,caster.y) then
          local method = {"inkblot testing","using hypnosis","using hypnotherapy","using LSD therapy","free association","using operant conditioning","using a skinner box","using talk therapy","using cognitive neuroscience","using behavioral therapy","using a client-centered approach","extensive interviews with family members","interpreting their dreams","yelling at them until they cry","making them act it out with puppets","dosing their coffee with truth serum","reading " .. tname .. "'s mind","using mindreading","using magic","doing some real woowoo nonsense","asking their spirit guide","a spiritual drug trip","getting drunk and talking about their feelings","asking embarassing personal questions","roleplaying","watching them masturbate","just asking","educated guessing","picking the first logical explanation","using occam's razor","picking something out of a psychology textbook at random","projecting " .. caster:get_pronoun('p') .. " own flaws","trepanning","using phrenology","reading " .. tname .. "'s journal","picking terms out of a hat","a process of intense self-discovery","doing absolutely nothing at all","using solid detective work","using a patented process","asking a more experienced psychologist","asking " .. tname .. " what " .. target:get_pronoun('n') .. " thinks " .. target:get_pronoun('p') .. " problem is"}
          local discovery = {"uncovers","posits","reveals","theorizes","informs " .. tname,"discovers","guesses","believes","explains","is able to see","is able to discover","clearly sees"}
          local issues = {"all of " .. tname .. "'s problems",tname .. "'s current neuroses","all the things that have ever gone wrong for " .. tname,tname .. "'s violent tendencies","quite a few of " .. tname .. "'s personality quirks","the failures of every romantic relationship that " .. tname .. " has ever been in",tname .. "'s emotional unavailability",tname .. "'s feelings of worthlessness",tname .. "'s drinking problems",tname .. "'s performance anxiety",tname .. "'s sexual perversions","absolutely none of " .. tname .. "'s problems","the voices in " .. tname .. "'s head",tname .. "'s fear of ghosts",tname .. "'s phobia of being possessed by an evil spirit",tname .. "'s fear of the dark"}
          local isFrom = {"stem from","originate from","have their roots in","can be blamed on","are due to","wouldn't be such a big deal if it weren't for","are most likely due to","could possibly be explained by","can be explained by","are because of","might be the fault of","are due to the fallout of","probably aren't due to","can't possibly be due to","can only be due to","are not caused by","are, like, defintely, probably, 99.9% sure, due to","began with"}
          local source = {"a childhood trauma","an oedipal complex","their feelings towards their mother","a pavlovian response","basic classical conditioning","a lack of self-actualization","the constraints placed upon them by society","sexual shame","basic craziness, plain and simple","the shape of their skull","not eating their vegetables as a child","violent video games","arrested development","watching too much TV","wanting to make out with everyone they see","being a raging, incurable psychopath","drugs","something totally outside the realm of current scientific understanding","brain chemistry","not enough love as a child","that time they got locked out of their house without any pants on","accidentally seeing their parents have sex when they were a kid","past-life trauma","their parents' divorce","daddy issues","talking to too many psychologists","a lack of education","capitalism","a particularly bad breakup","greed","their father not being around much","some really messed up stuff they don't really want to get into right now","seeing a bird die when they were very young","accidentally killing the family pet as a kid","the elder gods","living underground for so long","being teased too much as a child","that time they almost died","a childhood illness","having a messed-up brain","having donkey brains","that horrible secret they've been hiding for so long","evil spirits","demonic possession","their strict religious upbringing","magic","the way things are, and there's nothing anyone can do about it","drinking too much","learning Terrible Secrets Man Was Not Meant to Know (No, Nor Woman Neither)","witchcraft","an ancient curse","a family curse","a lack of faith","not praying hard enough","caring too much","poverty","a trauma in " .. target:get_pronoun('p') .." past life","that damn rap music","heavy metal","role-playing games","too much partying","masturbating too much","watching too much porn","seeing a really scary movie as a child"}
          local methodChoice = (target:has_condition('asleep') and "interpreting their dreams" or method[random(#method)])
          local text = (random(1,2) and "After " or "By ") .. methodChoice .. ", " .. caster:get_name() .. " " .. discovery[random(#discovery)] .. (random(1,2) and " " or " that ") .. issues[random(#issues)] .. (random(1,2) and " " or " totally ") .. isFrom[random(#isFrom)] .. " " .. source[random(#source)] .. "." .. (random(1,2) and "" or " Definitely.")
          output:out(text .. " " .. resulttext)
          currMap:add_effect(Effect('animation','spiral',4,target,{r=33,g=71,b=17},false,true),target.x,target.y)
        end
      end
    }),
  
  eatbrain = Spell({
    name = "Eat Brain",
    target_type = "self",
    description = "Eat the brain from dead body to gain an ability from the creature. You can only have one ability at a time from this, if you use it again the ability you gain will be lost.",
    sound = "devourcorpse",
    cast = function(self,target,caster)
      local corpse = currMap:tile_has_feature(caster.x,caster.y,'corpse')
      if corpse then
        if #corpse.creature.spells > 0 then
          local spellID = false
          local possibles = {}
          for _, spell in pairs(corpse.creature.spells) do
            if not in_table(spell,caster.spells) then
              possibles[#possibles+1] = spell
              break
            end --end if not
          end --end for
          if #possibles > 0 then spellID = get_random_element(possibles) end
          
          if not spellID then
            output:out(corpse.creature:get_name() .. " didn't have any abilities you don't already know. Eating their brain would be pointless.")
            return false
          end --end not madespell
          
          output:out("You chow down on  " .. corpse.creature:get_name() .. "'s brain. You absorb the ability \"" .. possibleSpells[spellID].name .. "\"!")
          if caster.absorbedSpell then
            output:out("Unfortunately, you lose the ability \"" .. possibleSpells[caster.absorbedSpell].name .. ".\"")
            local oldID = in_table(caster.absorbedSpell,caster.spells)
            table.remove(caster.spells,oldID)
          end
          caster.absorbedSpell = spellID
          table.insert(caster.spells,spellID)
          currMap:add_feature(Feature('chunk',corpse.creature),caster.x,caster.y)
          corpse:delete()
        else
          output:out(corpse.creature:get_name() .. " didn't have any special abilities. Eating " .. corpse.creature:get_pronoun('p') .. " brain would be pointless.")
          return false
        end
      else
        output:out("There's no corpse here to eat the brain of.")
        return false
      end
    end,
    requires = function(self,caster)
      local corpse = currMap:tile_has_feature(caster.x,caster.y,'corpse')
      if not corpse then
        return false,"There's no corpse here to eat the brain of."
      end
    end
  }),

starvation = Spell({
	name = "Insatiable Hunger",
	description = "You are driven by a hunger that can never be satisfied. No matter how much you eat, you are in a state of starvation, and will take damage over time.",
	target_type = "passive",
	advance = function (self, possessor)
    if possessor ~= player then return end
		if (currGame.stats.turns % math.max(10-(possessor.hunger or 0),1) == 0) then --every 10-hunger level turns, take damage
      if possessor == player then output:out("You are starving!") end
			possessor:damage(1)
		end
	end
}),

magicshield = Spell({
	name = "Magic Shield",
	description = "Calls a magical shield into being around you.",
	cooldown = 20,
	target_type = "self",
  sound="magicshield",
	flags = {aggressive=true,defensive=true,fleeing=true},
	cast = function (self,target,caster)
		if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " casts a magic shield around themselves.") end
		caster:give_condition('magicshield',tweak(10))
	end
}),

speedspell = Spell({
	name = "Haste",
	description = "Makes you temporarily faster.",
	cooldown = 20,
	target_type = "self",
	flags = {aggressive=true,defensive=true,fleeing=true},
  sound="haste",
	cast = function (self,target,caster)
		if player:can_see_tile(caster.x,caster.y) then
      output:out(caster:get_name() .. " starts moving really fast.")
      currMap:add_effect(Effect('animation','floatingpluses',5,caster,{r=235,g=137,b=49,a=255},true,true),caster.x,caster.y)
    end
		caster:give_condition('haste',tweak(10))
	end,
}),

divebomb = Spell({
    name = "Divebomb",
    description = "Charge at a nearby enemy, then fly back to safely.",
    cooldown = 10,
    range=7,
    min_range=3,
    projectile = true,
    target_type = "creature",
    sound="woosh",
    flags={aggressive=true},
    cast = function(self,target,caster)
      caster.diveBombFrom = {x=caster.x,y=caster.y}
      caster:flyTo(target,possibleSpells['divebombbash'])
    end
  }),

divebombbash = Spell({
  name = "Divebomb Bash",
  description = "What happens after you divebomb someone.",
  target_type = "creature",
  cast = function(self,target,caster)
    local _,dmg = calc_attack(caster,target,true)
    if target and type(target) == "table" and target.baseType == "feature" or target.baseType == "creature" then
      dmg = target:damage(dmg,caster)
      if player:can_see_tile(target.x,target.y) or player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " divebombs " .. target:get_name() .. ", dealing " .. dmg .. " damage.")
        output:sound('collision_creature')
      end
      caster:give_condition('afterdivebomb',-1)
    end
  end
}),

tornado = Spell({
    name = "Tornado",
    description = "Summons a miniature tornado to ravage the dungeon.",
    cooldown = 25,
    AIcooldown=50,
    target_type = "tile",
    sound = "tornado",
    flags = {aggressive=true},
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " summons a tornado.")
        output:sound('tornado')
      end
      currMap:add_effect(Effect('tornado'),target.x,target.y)
    end
}),

gust = Spell({
    name = "Gust",
    description = "Blows a powerful gust of wind at a target, knocking them backwards.",
    cooldown = 5,
    AIcooldown=15,
    flags = {aggressive=true},
    target_type = "creature",
    projectile=true,
    cast = function(self,target,caster)
      if target == caster then
        if caster == player then output:out("Unfortunately, no matter how hard you try, you can't blow yourself.") end
        return false
      end
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " blasts " .. target:get_name() .. " with a powerful gust of wind.")
        output:sound('gust')
      end
      Projectile('gust',caster,target)
    end
}),

summoncloud = Spell({
    name = "Personal Storm",
    description = "Causes a storm cloud to form around a creature. It will impede their view, rain on them and occasionaly even strike them with lightning.",
    cooldown = 20,
    AIcooldown=40,
    target_type = "creature",
    flags = {aggressive=true},
    cast = function(self,target,caster)
      local cloud = Effect('stormcloud')
      cloud.creator = self
      cloud.target = target
      target:give_condition('clouded',-1,caster)
      currMap:add_effect(cloud,target.x,target.y)
      if player:can_see_tile(target.x,target.y) then
        output:sound('summon_storm')
      end
    end
  }),

chainsaw = Spell({
    name = "Chainsaw",
    description = "You're wielding a chainsaw. Kills will be messy.",
    target_type = "passive",
    kills = function(self,possessor,victim)
      if not victim.bloodless then
        victim.explosiveDeath = true
        if player:can_see_tile(possessor.x,possessor.y) then output:sound('chainsaw_kill') end
      end
    end
  }),

slasherteleport = Spell({
    name = "Teleport to Victim",
    description = "If everyone around you is dead, it's time to teleport to where you're least expected.",
    target_type = "self",
    cooldown = 50,
    sound="teleport",
    cast = function(self,target,caster)
      for _, creat in pairs(currMap.creatures) do
        if creat ~= caster and creat:can_see_tile(caster.x,caster.y) then
          output:out("You can't teleport while anyone can see you.")
          return false
        end
      end
      local done = false
      local newX,newY = random(2,currMap.width-1),random(2,currMap.height-1)
      while done == false do
        while currMap:isClear(newX,newY) == false do
          newX,newY = random(2,currMap.width-1),random(2,currMap.height-1)
        end --end isclear while
        local seen = false
        for _,creat in pairs(currMap.creatures) do
          if creat ~= caster and creat:can_see_tile(newX,newY) then
            newX,newY = random(2,currMap.width-1),random(2,currMap.height-1)
            seen = true
            break
          end
        end --end creature for
        if seen == false then done = true end
      end --end done while
      output:out("You mysteriously appear somewhere your victims don't expect you to be.")
      caster:moveTo(newX,newY)
    end,
    requires = function(self,caster)
      for _, creat in pairs(currMap.creatures) do
        if creat ~= caster and creat:can_see_tile(caster.x,caster.y) then
          return false,"You can't teleport when anyone can see you."
        end
      end
    end
  }),

knightjump = Spell({
    name = "Knight Jump",
    description = "Leap over your enemies and land in a nearby square an L-shaped path away from where you started. If you land on someone's head, this will hurt them a lot.",
    cooldown = 15,
    target_type = "tile",
    sound="jump",
    flags={aggressive=true,defensive=true,fleeing=true},
    cast = function(self,target,caster)
      local xDist,yDist = math.abs(target.x-caster.x),math.abs(target.y-caster.y)
      local creat = currMap:get_tile_creature(target.x,target.y)
      if (xDist == 2 and yDist == 1) or (yDist == 2 and xDist == 1) then
        if caster:can_move_to(target.x,target.y) then --if it's clear, just leap
          caster:moveTo(target.x,target.y)
        elseif creat then --if there's a creature there, damage 'em
          local dmg = caster.strength*1.5
          creat:damage(dmg,caster)
          if player:can_see_tile(target.x,target.y) then
            output:out(caster:get_name() .. " leaps onto " .. creat:get_name() .. ", dealing " .. dmg .. " damage.")
            output:sound('collision_creature')
          end
          if creat.hp < 0 then --if the damage would kill them, they explode!
            creat:explode()
          else --push the creature out of the way if possible
            local xMod,yMod = random(-1,1),random(-1,1)
            local tries = 15
            --try to push them outta the way:
            while tries > 0 and not creat:can_move_to(target.x+xMod,target.y+yMod) do
              tries = tries -1
              xMod,yMod = random(-1,1),random(-1,1)
            end
            if creat:can_move_to(target.x+xMod,target.y+yMod) then --push them if possible
              creat:moveTo(target.x+xMod,target.y+yMod)
            else --if they're stuck and can't move, they explode anyway!
              creat:explode()
            end
          end
          caster:moveTo(target.x,target.y)
        else
          output:out("Something's blocking the way.")
          return false
        end
      else
        output:out("You can only leap in an L shape. Horseknight code of chivalry or something.")
        return false
      end
    end,
    --[[decide = function(self,target,caster,use_type)
      
    end, --end decide function]]
    get_target_tiles = function(self,target,caster)
      local targets = {}
      for x=caster.x-2,caster.x+2,1 do
        for y=caster.y-2,caster.y+2,1 do
          local xDist,yDist = math.abs(caster.x-x),math.abs(caster.y-y)
          if (xDist == 2 and yDist == 1) or (yDist == 2 and xDist == 1) then
            targets[#targets+1] = {x=x,y=y}
          end
        end --end fory
      end --end forx
      return targets
    end --end target draw function
  }),

distraction = Spell({
    name = "Throw Noisemaker",
    description = "Throw a noisemaker, which will cause nearby enemies to investigate and make them less likely to see you.",
    cooldown = 30,
    projectile=true,
    target_type="tile",
    cast = function(self,target,caster)
      if player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " throws a noisemaker.")
      end
      currMap:add_effect(Effect('noisemakerattractor',{x=target.x,y=target.y}),target.x,target.y)
    end --end cast function
  }),

remoteviewing = Spell({
    name = "Remote Viewing",
    description = "See a location far removed from your physical body.",
    cooldown = 30,
    target_type="tile",
    sound="teleport",
    cast = function(self,target,caster)
      if not caster:can_move_to(target.x,target.y) then
        output:out("You can't astrally project there.")
        return false
      end
      caster:give_condition('outofbody',-1)
      local astral = Creature('astralprojection')
      currMap:add_creature(astral,target.x,target.y)
      caster.projection = astral
      astral.body = caster
      if caster == player then
        astral.properName = player.properName
        player = astral
        astral.symbol = "@"
      end
      astral:give_condition('astralprojection',20)
    end --end cast function
  }),

returntobody = Spell({
    name = "Return to Body",
    description = "Return from your astral journey and reinhabit your physical form.",
    projectile=true,
    target_type="self",
    sound="teleport",
    cast = function(self,target,caster)
      caster:cure_condition('astralprojection')
    end,
    attacks = function(self,possessor,target)
      if possessor == player then
        output:out("You're not in a physical form, so you can't attack anyone.")
      end
      return false
    end
  }),

astralbanish = Spell({
    name = "Banish to Astral Plane",
    flags = {defensive=true},
    description = "Temporarily banish a creature to the astral plane. They won't be able to attack (or be damaged), but they can still cast spells.",
    cooldown = 20,
    AIcooldown=40,
    target_type="creature",
    sound="astralbanish",
    cast = function(self,target,caster)
      if target == caster then
        if caster == player then output:out("You can't self-banish, nasty.") end
        return false
      end
      target:give_condition('astralbanish',10)
      currMap:add_effect(Effect('animation','magicdamage',5,target,{r=255,g=255,b=0}),target.x,target.y)
    end
  }),

summonspirits = Spell({
    name = "Channel the Spirits",
    description = "Summon spirits to the mortal realm. You must remain still while channeling them, or they'll vanish.",
    target_type = "self",
    sound="summon_spirits",
    flags = {aggressive=true,defensive=true},
    cast = function(self,target,caster)
      if caster.spirits then
        if caster == player then output:out("You've already summoned some spirits.") end
        return false
      end
      local spirits = random(3,5)
      local dist = 1
      local tries = 0
      caster.spirits = {}
      while spirits > 0 and tries < 100 do
        tries = tries + 1
        dist = math.ceil(tries/10)
        local x,y = random(caster.x-dist,caster.x+dist),random(caster.y-dist,caster.y+dist)
        if currMap:isClear(x,y) then
          local spirit = Creature('summonedspirit')
          currMap:add_creature(spirit,x,y)
          spirit:become_thrall(caster)
          caster.spirits[spirit] = spirit
          spirits = spirits - 1
          currMap:add_effect(Effect('animation','magicdamage',5,spirit,{r=255,g=255,b=0}),spirit.x,spirit.y)
        end --end isclear
      end --end while
      caster:give_condition('channeling',-1)
      if player:can_sense_creature(caster) then output:out(caster:get_name() .. " summons some spirits.") end
    end,
    requires = function(self,caster)
      if caster.spirits then
        return false,"You've already summoned some spirits."
      end
    end
}),

filledwithgunpowder = Spell({
    name = "Walking Bomb",
    description = "You're filled with highly explosive materials. If you are exposed to fire or explosions, you'll blow up.",
    target_type = "passive",
    dies = function(self,possessor)
      possessor.explosiveDeath = true
    end,
    damaged = function(self,possessor,attacker,amt,dtype)
      if amt > 0 and possessor.hp > 0 and (dtype == "fire" or dtype == "explosive") then
        possessor.hp = 0 --this is done so that the move will finish, then the golem will die and explode in cleanup
      end
    end
  }),

flagellate = Spell({
    name = "Self-flagellation",
    description = "Whip yourself into a religious frenzy.",
    target_type="self",
    cooldown = 15,
    AIcooldown=30,
    sound="whip2",
    cast = function(self,target,caster)
      local dmg = caster:damage(10,caster)
      if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " whips themselves, taking " .. dmg .. " damage.") end
      caster:give_condition('fervor',10)
      currMap:add_effect(Effect('animation','bloodmagicdamage',5,caster,{r=255,g=255,b=0}),caster.x,caster.y)
    end
  }),

shieldwall = Spell({
    name = "Shield Wall",
    description = "Brace yourself behind your shield. This makes you move more slowly, deal less damage, and have a lower chance to hit, but lessens the damage you take.",
    target_type="self",
    cast = function(self,target,caster)
      if caster:has_condition('shieldwall') then
        if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " lowers " .. caster:get_pronoun('p') .. " shield.") end
        caster:cure_condition('shieldwall')
        output:sound('metal_click')
      else
        if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " raises " .. caster:get_pronoun('p') .. " shield like a wall.") end
        caster:give_condition('shieldwall',-1)
        output:sound('clank')
      end
    end
  }),

shieldbash = Spell({
    name = "Shield Bash",
    description = "Bash an enemy with your shield, knocking them back and stunning them.",
    target_type="creature",
    range=1,
    cooldown=10,
    AIcooldown=20,
    cast = function(self,target,caster)
      if target == caster then
        output:out("Don't bash yourself, I'm sure you have plenty of great qualities.")
        return false
      end
      local dmg = tweak(caster:get_damage())
      if player:can_see_tile(target.x,target.y) or player:can_see_tile(caster.x,caster.y) then
        output:out(caster:get_name() .. " bashes " .. target:get_name() .. " with " .. caster:get_pronoun('p') .. " shield, dealing " .. dmg .. " damage and knocking " .. target:get_pronoun('o') .. " back.")
      end
      target:give_condition('knockback',random(1,4),caster)
      target:give_condition('stunned',random(2,4),caster)
    end
  }),

zombieplague = Spell({
    name = "Zombie Plague",
    description = "Living enemies killed by a zombie have a 50% to return as a zombie.",
    target_type = "passive",
    kills = function(self,possessor,victim)
      if (not possessor.master or possessor.master.id ~= "samedi") and random(1,2) == 1 and not victim:is_type("undead") and not victim:is_type("construct") then
        local zpc = Effect('zombieplaguecountdown')
        zpc.creator = possessor
        currMap:add_effect(zpc,victim.x,victim.y)
      end
    end
  }),

paralyzingtouch = Spell({
    name = "Paralyzing Touch",
    description = "It is well-known that the touch of a ghoul can temporarily paralyze you. What's not well-known is WHY, but I guess it doesn't really matter.",
    target_type = "creature",
    range=1,
    cooldown=9,
    AIcooldown=18,
    sound="unholydamage",
    cast = function(self,target,caster)
      if player:can_see_tile(target.x,target.y) then
        output:out(caster:get_name() .. " paralyzes " .. target:get_name() .. " with a touch!")
        currMap:add_effect(Effect('animation','unholydamage',5,target,{r=150,g=0,b=150}),target.x,target.y)
      end
      target:give_condition('stunned',tweak(3))
    end
  }),

spitslime = Spell({
	name="Spit Slime",
	description="Spit slime at an enemy.",
	cooldown=15,
	target_type = "tile",
  projectile = true,
  sound = "spit",
	flags = {aggressive=true,defensive=true,fleeing=true},
	cast = function(self,target,caster)
    if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " spits slime" .. (target.baseType and " at " .. target:get_name() or "") .. "!") end
    Projectile('slime',caster,target)
	end, --end cast function
}),

hideinwater = Spell({
    name = "Hide Under Water",
    description = "You can sink under water, making you very hard to notice for anyone who hasn't seen you yet. It also makes you immune to spells and ranged attacks.",
    target_type="self",
    cast = function(self,target,caster)
      caster:give_condition('underwater',-1)
    end,
    requires = function(self,possessor)
      if possessor:has_condition('underwater') then return false,"You're already underwater!" end
      if type(currMap[possessor.x][possessor.y]) == "table" and currMap[possessor.x][possessor.y].water == true then return true end
      for _,feat in pairs(currMap:get_contents(possessor.x,possessor.y)) do
        if feat.water == true then return true end
      end
      return false,"There's no water here to hide in."
    end
  }),

immunetomelee = Spell({
    name = "Immune to Melee",
    description = "You're immune to melee attacks. That's useful.",
    target_type = "passive",
    dies = function(self,possessor)
      possessor.explosiveDeath = true
    end,
    damaged = function(self,possessor,attacker,amt,dtype,is_melee)
      if is_melee then
        if attacker == player then output:out("Your attack can't penetrate the elephant's thick skin! You're going to have to find another way to hurt it.") end
        return 1
      end
    end
  }),

nightterror = Spell({
    name = "Night Terror",
    description = "Inflict a terrible nightmare into a sleeping creature's dreams, causing psychic harm and scaring them immensely.",
    target_type = "creature",
    sound="deadlypremonition",
    cast = function(self,target,caster)
      if not target:has_condition('asleep') then
        if caster == player then output:out("You can only inflict night terrors on a sleeping creature.") end
        return false
      elseif target:is_type('mindless') then
        if caster == player then output:out("You can only inflict night terrors on a creature with a mind.") end
        return false
      else
        local dmg = target:damage(tweak(50),caster,"dark")
        if player:can_see_tile(target.x,target.y) then output:out(caster:get_name() .. " inflicts a horrifying night terror on " .. target:get_name() .. ".") end
        target:cure_condition('asleep')
        target:give_condition('fear')
      end
    end
  }),

sleepsense = Spell({
  name = "Nightmare Sight",
  description = "You can sense the presence of sleeping creatures, as well as creatures in supernatural darkness.",
  target_type = "passive",
  sense = function(self,possessor,target)
    if not possessor.x or not possessor.y or not target.x or not target.y or calc_distance(possessor.x,possessor.y,target.x,target.y) > math.max(possibleMonsters.nightmare.perception,possessor:get_perception()) then return false end
    if target:has_condition('asleep') then return true end
    if currMap:tile_has_effect(target.x,target.y,'darkness') then return true end
    if possessor:can_see_tile(target.x,target.y) then return true end
    return false
  end
}),

darkness = Spell({
  name = "Darkness",
  description = "You cast a blanket of supernatural darkness over an area. Any creatures who aren't already aware of you might fall asleep. Creatures trapped in the darkness will slowly become more afraid and will be unable to see.",
  target_type = "tile",
  cooldown=10,
  AIcooldown=30,
  sound="darkness",
  flags={aggressive=true,defensive=true,fleeing=true},
  cast = function(self,target,caster)
    if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " fills a nearby area with supernatural darkness.") end
    for x=target.x-3,target.x+3,1 do
      for y=target.y-3,target.y+3,1 do
        if calc_distance(x,y,target.x,target.y) <= 3 and currMap:is_line(x,y,caster.x,caster.y,true) then
          currMap:add_effect(Effect('darkness'),x,y)
          local creat = currMap:get_tile_creature(x,y)
          if creat and creat.alert < 1 and random(1,4) == 1 and creat ~= player then
            creat:give_condition('asleep',random(5,50))
          end
        end
      end --end fory
    end --end forx
  end,
  get_target_tiles = function(self,target,caster)
    local targets = {}
    for x=target.x-3,target.x+3,1 do
      for y=target.y-3,target.y+3,1 do
        if calc_distance(x,y,target.x,target.y) <= 3 and currMap:is_line(x,y,caster.x,caster.y,true) then targets[#targets+1] = {x=x,y=y} end
      end --end fory
    end --end forx
    return targets
  end --end target draw function
}),

shadowbinding = Spell({
  name = "Binding Shadow",
  description = "Entrap a creature in chains of darkness that leave them unable to move and deal damage over time. Deals more damage if the target is in supernatural darkness.",
  target_type="creature",
  cooldown=15,
  AIcooldown=25,
  sound="shadowbind",
  flags={aggressive=true,defensive=true,fleeing=true},
  cast = function(self,target,caster)
    target:give_condition('boundindarkness',tweak(5))
    currMap:add_effect(Effect('conditionanimation',{owner=target,condition="boundindarkness",symbol="~",image_base="darknesstangle",image_max=4,speed=target.animation_time,color={r=83,g=74,b=125,a=255},use_color_with_tiles=false,spritesheet=true}),target.x,target.y)
  end
}),

illusorydouble = Spell({
  name = "Illusory Doubles",
  description = "You can create illusory copies of yourself. These copies will do no damage, but may distract enemies.",
  target_type = "self",
  cooldown=25,
  AIcooldown=40,
  flags={aggressive=true,fleeing=true,defensive=true},
  sound="summon_illusion",
  cast = function(self,target,caster)
    if player:can_see_tile(caster.x,caster.y) then output:out(caster:get_name() .. " summons a bunch of illusory doubles!") end
		local ills = random(2,4)
    local tries = 15
		--[[while (ills > 1) and tries > 0 do
			local x,y = random(caster.x-3,caster.x+3),random(caster.y-3,caster.y+3)
			if (x>1 and y>1 and x< currMap.width and y< currMap.height and currMap:isClear(x,y)) then
				local illusion = Creature('illusion')
				currMap:add_creature(illusion,x,y)
        illusion:become_thrall(caster)
        illusion:give_condition('illusorydouble',tweak(15))
        illusion.properName = caster.properName
        illusion.hp = caster.hp
        illusion.gender = caster.gender
        ills = ills - 1
      else
        tries = tries-1
			end
		end]]
  end
}),

vanish = Spell({
  name = "Vanish",
  description = "You can vanish in a puff of smoke, temporarily becoming invisible. Attacking or casting any offensive spells will cause you to become visible again.",
  cooldown = 25,
  target_type = "self",
  flags={fleeing=true,defensive=true},
  cast = function(self,target,caster)
    caster:give_condition('invisible',15)
    local smoke = currMap:add_effect(Effect('smoke'),caster.x,caster.y)
    smoke.nospread = true
    smoke.strength=5
    if player:can_sense_creature(caster) then
      output:out(caster:get_name() .. " vanishes in a puff of smoke!")
      output:sound('explosion_smoke')
    end
   end
}),

}