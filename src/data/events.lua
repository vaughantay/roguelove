--Event types: enter_map, enter_map_first_time, random, player_kills, boss_dies
possibleEvents = {}

local demons_demonattack = {
  event_type="random",
  faction="demons", --The faction this event is associated with
  faction_members_only=false, --The event will only occur if the player is a member of the faction
  max_reputation=-10, --This event will only occur if the player's reputation is below this value
  chance=10, --% chance that this event will actually occur when it comes up
  cooldown = 100, --If this event occurs, this many turns will pass before another event can. There are separate cooldowns for each faction, and for non-faction events
  action = function()
    local times = currGame.events_occured['demons_demonattack'] or 0
    output:out("Cackling demons suddenly materialize around you!")
    local demons = times+2
    local tries = 0
    for i=1,demons,1 do
      local placed = false
      while tries < 100 and placed == false do
        tries = tries+1
        local x,y = random(player.x-5,player.x+5),random(player.y-5,player.y+5)
        if currMap:isClear(x,y) then
          local imp = Creature('imp')
          while imp.level < math.min(player.level,imp.max_level) do
            imp:level_up(true)
          end
          currMap:add_creature(imp,x,y)
          placed = true
        else
          tries = tries +1
        end
      end
    end
  end
}
possibleEvents['demons_demonattack'] = demons_demonattack

local angels_blessing = {
  event_type="random",
  faction="angels",
  min_reputation=10, --This event will only occur if the player's reputation is above this value
  chance=10, --% chance that this event will actually occur when it comes up
  max_occurances=2, --This event will only occur this many times. Optional, if blank can occur an infinite number of times
  cooldown=50,
  ignore_cooldown=true, --The event can occur even if the cooldown hasn't cooled down yet
  requires = function()
    
  end,
  action = function()
    output:out("You're suddenly filled with a blessing from the angels.")
    player:give_condition('blessed',25)
    currMap:add_effect(Effect('animation',{image_name='holydamage',image_max=5,target={x=player.x,y=player.y},color={r=255,g=255,b=255}}),player.x,player.y)
  end
}
possibleEvents['angels_blessing'] = angels_blessing

local town_guards = {
  event_type="enter_map",
  mapTypes={"town"}, --The mapTypes this event can occur on
  branches = {}, --The branches this event can occur on
  tags={}, --The map and branch tags this event can occur on
  chance=10,
  requires = function()
    if player.reputation.town and player.reputation.town > -2 then
      return false
    end
    return true
  end,
  action = function()
    output:out("Guards were waiting in ambush for you!")
    local guards = math.max(math.ceil(math.abs((player.reputation.village or 0))/10),2)
    local tries = 0
    for i=1,guards,1 do
      local placed = false
      while tries < 100 and placed == false do
        tries = tries+1
        local x,y = random(player.x-5,player.x+5),random(player.y-5,player.y+5)
        if currMap:isClear(x,y) then
          local guard = Creature('townguard')
          while guard.level < math.min(player.level,guard.max_level) do
            guard:level_up(true)
          end
          currMap:add_creature(guard,x,y)
          placed = true
        else
          tries = tries +1
        end
      end
    end
  end
}
possibleEvents['town_guards'] = town_guards

--[[local town_clear_corpses = {
  event_type="enter_map",
  mapTypes={"town"}, --The mapTypes this event can occur on
  branches = {}, --The branches this event can occur on
  tags={}, --The map and branch tags this event can occur on
  chance=100,
  action = function()
    for x=2,currMap.width-1,1 do
      for y=2,currMap.height-1,1 do
        local contents = currMap:get_contents(x,y)
        for _,content in pairs(contents) do
          if content.id == "corpse" or content.id == "chunk" or content.id == "bloodstain" then
            content:delete()
          end
        end
      end
    end
  end
}
possibleEvents['town_clear_corpses'] = town_clear_corpses]]