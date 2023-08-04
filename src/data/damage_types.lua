damage_types = {
  physical = function(target,noSound)
    if target.hp > 0 then
      local oldColor = target.temporaryColor
      target.temporaryColor={r=255,g=0,b=0,a=255}
      if not oldColor then
        tween(.25,target.temporaryColor,{g=255,b=255},'linear',function() target.temporaryColor = nil end)
      else
        tween(.25,target.temporaryColor,{r=oldColor.r,g=oldColor.g,b=oldColor.b,a=oldColor.a or 255},'linear')
      end
    end
  end,
  ice = function(target)
    currMap:add_effect(Effect('animation','icedamage',5,target,{r=255,g=255,b=255}),target.x,target.y)
  end,
  fire = function(target)
    currMap:add_effect(Effect('animation','firedamage',5,target,{r=255,g=0,b=0}),target.x,target.y)
  end,
  explosive = function(target) --explosive is basically "fire" except it makes things explode, and fire immune creatures aren't necessarily immune to it
    currMap:add_effect(Effect('animation','firedamage',5,target,{r=255,g=0,b=0}),target.x,target.y)
  end,
  holy = function(target)
    currMap:add_effect(Effect('animation','holydamage',5,target,{r=255,g=255,b=0}),target.x,target.y)
  end,
  unholy = function(target)
    currMap:add_effect(Effect('animation','unholydamage',5,target,{r=150,g=0,b=150}),target.x,target.y)
  end,
  electric = function(target)
    currMap:add_effect(Effect('animation','electricdamage',5,target,{r=0,g=0,b=255}),target.x,target.y)
  end,
  acid = function(target)
    currMap:add_effect(Effect('animation','aciddamage',5,target,{r=0,g=255,b=0}),target.x,target.y)
  end,
  poison = function(target)
    currMap:add_effect(Effect('animation','poisondamage',5,target,{r=0,g=150,b=0}),target.x,target.y)
  end,
  magic = function(target)
    currMap:add_effect(Effect('animation','magicdamage',5,target,{r=255,g=255,b=0}),target.x,target.y)
  end,
  bloodmagic = function(target)
    currMap:add_effect(Effect('animation','bloodmagicdamage',5,target,{r=150,g=0,b=0}),target.x,target.y)
  end,
}