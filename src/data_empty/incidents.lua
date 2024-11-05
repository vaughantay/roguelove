possibleIncidents = {}

--Basic incidents:
local attacks = { --This is used for direct melee attacks, not ranged attacks or collateral damage from AOEs
  
}
function attacks:process(observer,actor,target,args)
  if target and target.baseType == "creature" and  actor and actor.baseType == "creature" then
    if observer:is_friend(target) then --if an attacker attacked your friend, become hostile to them
      if observer:can_sense_creature(actor) then
        observer:become_hostile(actor)
      else
        observer:cure_condition('distracted')
        observer.alert = observer.memory
      end
    end
  end
end
possibleIncidents['attacks'] = attacks

local dies = {
  
}
function dies:process(observer,actor,target,args)
  if observer.master and observer.master == actor then
    observer.fear = observer.fear + 10 --seeing your master die? scary
  elseif observer:is_friend(actor) then
    observer.fear = observer.fear + 5 -- seeing a friend die? a little scary
  elseif observer:is_enemy(actor) then 
    observer.fear = observer.fear - 5 --seeing an enemy die reduces fear
  end
end
possibleIncidents['dies'] = dies

local explodes = {
  
}
function explodes:process(observer,actor,target,args) --Remember, these stack with regular dies fear values above
  if observer.master and observer.master == actor then
    observer.fear = observer.fear + 25 --seeing your master explode? really scary
  elseif observer:is_friend(actor) then
    observer.fear = observer.fear + 10 -- seeing a friend explode? scary
  elseif not observer:is_enemy(actor) then --seeing an enemy explode is not scary
    observer.fear = observer.fear + 5  --seeing a rando explode is a little scary
  end
end
possibleIncidents['explodes'] = explodes

local kills = {
  
}
function kills:process(observer,actor,target,args)
  if target and target.baseType == "creature" and actor and actor.baseType == "creature" then
    if observer:is_friend(target) then --if an attacker attacked your friend, become hostile to them
      if observer:can_sense_creature(actor) then
        observer:become_hostile(actor)
      else
        observer:cure_condition('distracted')
        observer.alert = observer.memory
      end
    end
  end
end
possibleIncidents['kills'] = kills

local take_item = {
  
}
function take_item:process(observer,actor,target,args)
  if target.owner ~= actor and (target.owner == observer) then
    observer:become_hostile(actor)
  end
end
possibleIncidents['take_item'] = take_item