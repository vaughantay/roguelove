possibleSpells = {
  
  --If you're using Creature:transform() with the active_undo flag set, this spell will be added to transformed creatures to transform them back
  possibleSpells['undotransform'] = {
    name = "Undo Transformation",
    description = "Transform back into your regular self.",
    target_type="self",
    freeSlot=true,
    cast = function(self,target,caster)
      caster:undo_transformation()
    end
  }
}
