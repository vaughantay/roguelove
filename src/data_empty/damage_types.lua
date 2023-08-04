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
  end
}