damage_types = {
  physical = {
    name = false,
    physical=true,
    damages = function(target,attacker,amount)
      if target.hp > 0 then
        local oldColor = target.temporaryColor
        target.temporaryColor={r=255,g=0,b=0,a=255}
        if not oldColor then
          tween(.25,target.temporaryColor,{g=255,b=255},'linear',function() target.temporaryColor = nil end)
        else
          tween(.25,target.temporaryColor,{r=oldColor.r,g=oldColor.g,b=oldColor.b,a=oldColor.a or 255},'linear')
        end
      end
    end
  },
  ice = {
    name = "cold",
    elemental=true,
    damages = function(target,attacker,amount)
      currMap:add_effect(Effect('animation',{image_name='iceburst',image_max=5,target=target,color={r=255,g=255,b=255}}),target.x,target.y)
    end
  },
  fire = {
    name = "fire",
    elemental=true,
    damages = function(target,attacker,amount)
      currMap:add_effect(Effect('animation',{image_name='fireburst',image_max=5,target=target,color={r=255,g=75,b=0}}),target.x,target.y)
    end
  },
  explosive = {
    name = false,
    physical=true,
    damages = function(target,attacker,amount) --explosive is basically "fire" except it makes things explode, and fire immune creatures aren't necessarily immune to it
      currMap:add_effect(Effect('animation',{image_name='fireburst',image_max=5,target=target,color={r=255,g=0,b=0}}),target.x,target.y)
      if amount > target.hp then
        target.explosiveDeath = true
      end
    end
  },
  holy = {
    name = "holy",
    damages = function(target,attacker,amount)
      currMap:add_effect(Effect('animation',{image_name='flash',image_max=5,target=target,color={r=255,g=255,b=150}}),target.x,target.y)
    end
  },
  unholy = {
    name = "unholy",
    damages = function(target,attacker,amount)
      currMap:add_effect(Effect('animation',{image_name='skullflash',image_max=5,target=target,color={r=150,g=0,b=150}}),target.x,target.y)
    end
  },
  electric = {
    name = "electric",
    elemental=true,
    damages = function(target,attacker,amount)
      currMap:add_effect(Effect('animation',{image_name='electricshock',image_max=5,target=target,color={r=100,g=175,b=255,a=255}}),target.x,target.y)
    end
  },
  acid = {
    name = "acid",
    physical = true,
    damages = function(target,attacker,amount)
      currMap:add_effect(Effect('animation',{image_name='splash_chunky',image_max=5,target=target,color={r=0,g=255,b=0}}),target.x,target.y)
    end
  },
  poison = {
    name = "poison",
    damages = function(target,attacker,amount)
      currMap:add_effect(Effect('animation',{image_name='poison',image_max=5,target=target,color={r=0,g=150,b=0}}),target.x,target.y)
    end
  },
  magic = {
    name = "magic",
    damages = function(target,attacker,amount)
      currMap:add_effect(Effect('animation',{image_name='starburst',image_max=5,target=target,color={r=255,g=255,b=0}}),target.x,target.y)
    end
  },
  bloodmagic = {
    name = "bloodmagic",
    damages = function(target,attacker,amount)
      currMap:add_effect(Effect('animation',{image_name='drops',image_max=5,target=target,color={r=150,g=0,b=0}}),target.x,target.y)
    end
  },
  raw = {
    name = false,
    armor_piercing=true,
    damages = function(target,attacker,amount)
      if target.hp > 0 then
        local oldColor = target.temporaryColor
        target.temporaryColor={r=255,g=0,b=0,a=255}
        if not oldColor then
          tween(.25,target.temporaryColor,{g=255,b=255},'linear',function() target.temporaryColor = nil end)
        else
          tween(.25,target.temporaryColor,{r=oldColor.r,g=oldColor.g,b=oldColor.b,a=oldColor.a or 255},'linear')
        end
      end
    end
  },
}