possibleRecipes = {}

local uhw =
{
  results={unholywater=1},
  ingredients={holywater=1,demonblood=1},
  requires_class="demonologist",
  result_text="You mix the demon blood into the holy water, corrupting it and turning it into unholy water.",
  tags={"alchemy","unholy"}
}
function uhw:requires(crafter)
  if crafter:is_faction_member('lightchurch') then
    return false,"It would be a sin to corrupt holy water like this."
  end
end
possibleRecipes['unholywater'] = uhw

possibleRecipes['healthpotionminor'] = {
  results={healthpotionminor=1},
  ingredients={herbs=2,blood=1,alcahest=1},
  result_text="You mix the herbs and blood into the alcahest, creating a healing infusion.",
  tags={"alchemy","healing"},
}
possibleRecipes['healthpotionmoderate'] = {
  results={healthpotionmoderate=1},
  ingredients={healthpotionminor=2},
  result_text="You mix together two Potions of Minor Healing, magically concentrating the healing energy into a Potion of Moderate Healing.",
  tags={"alchemy","healing"}
}

--[[recipes['blah'] =
{
    name="Blah",
    results={item1=1,item2=1},
    ingredients={item3=1,item4=1},    
    specific_tools={item5},
    tool_tags={tag1,tag2},
    requires_class="",
    requires_spells={},
    stat_requirements={strength=100}
    required_level=0,
    no_auto_learn=true
}]]