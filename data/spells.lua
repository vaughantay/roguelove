possibleSpells = {

blast = Spell({
	name = "Psychic Blast",
	description = "Attack a target...with your mind!",
	cooldown = 5,
	target_type = "creature",
	flags = {aggressive=true},
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
	name = "Demon Slayer",
	description = "You know a lot about demons. Particularly, how to hurt them.",
	target_type = "passive",
  calc_damage = function(self,possessor,target,damage)
    if target:is_type('demon') then
      return math.ceil(damage * 1.5)
    end
  end
}),

summonangel = Spell({
	name = "Summon Angel",
	description = "You know a lot about demons. Particularly, how to hurt them.",
	target_type = "passive",
  calc_damage = function(self,possessor,target,damage)
    if target:is_type('demon') then
      return math.ceil(damage * 1.5)
    end
  end
}),

}
