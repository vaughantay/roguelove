possibleRecipes = {}

local uhw = {
  results={unholywater=1},
  ingredients={holywater=1,demonblood=1},
  result_text="You mix the demon blood into the holy water, corrupting it and turning it into unholy water.",
  tags={"alchemy","unholy"},
  types = {'alchemy'}
}
function uhw:requires(crafter)
  if crafter:is_faction_member('lightchurch') then
    return false,"It would be a sin to corrupt holy water like this."
  end
end
possibleRecipes['unholywater'] = uhw

local hw = {
  results={holywater=1},
  ingredients={alcahest=1,soul=1},
  requires_faction="lightchurch",
  result_text="You mix the soul into the alcahest, blessing it and turning it into holy water.",
  tags={"alchemy","holy"},
  types = {'alchemy'}
}
possibleRecipes['holywater'] = hw

possibleRecipes['healthpotionminor'] = {
  results={healthpotionminor=1},
  ingredients={alcahest=1},
  ingredient_properties={healing=3},
  types = {'alchemy'},
  ingredient_types={'alchemy'},
  result_text="You mix healing ingredients into the alcahest, creating a healing infusion.",
  tags={"alchemy","healing"},
}
possibleRecipes['healthpotionmoderate'] = {
  results={healthpotionmoderate=1},
  ingredients={alcahest=1},
  ingredient_properties={healing=5},
  ingredient_types={'alchemy'},
  result_text="You mix together the healing ingredients, concentrating the healing energy into a Potion of Moderate Healing.",
  tags={"alchemy","healing"},
  types = {'alchemy'}
}
possibleRecipes['poisonbottle'] = {
  results={poison=1},
  ingredients={alcahest=1},
  ingredient_properties={poison=1},
  ingredient_types={'alchemy'},
  result_text="You whip up some deadly poison.",
  tags={"alchemy","poison"},
  types = {'alchemy'}
}
possibleRecipes['weaponpoison'] = {
  results={weaponpoison=1},
  ingredients={weaponoil=1},
  ingredient_properties={poison=2},
  ingredient_types={'alchemy'},
  result_text="You mix poison into your weapon oil. You can now apply it to a weapon to have it apply poison.",
  tags={"alchemy","poison"},
  types = {'alchemy'}
}
possibleRecipes['weaponfireoil'] = {
  results={weaponfireoil=1},
  ingredients={weaponoil=1},
  ingredient_properties={fire=2},
  ingredient_types={'alchemy'},
  result_text="You mix fiery substances into your weapon oil. You can now apply it to a weapon to have it deal extra fire damage.",
  tags={"alchemy","fire"},
  skill_requirements={alchemy=1,magic=100},
  types = {'alchemy'}
}

possibleRecipes['reallybigclub'] = {
  results={reallybigclub=1},
  ingredients={club=2},
  --requires_class="barbarian",
  result_text="You mash two clubs together with your incredible strength, resulting in one really big club.",
  types = {'weaponsmithing'}
}

possibleRecipes['stew'] = {
  results={stew=1},
  ingredient_properties={protein=5,vegetable=3},
  bonuses_from_ingredients=true,
  add_ingredients_to_name=true,
  single_craft_only=true
}


--[[recipes['blah'] =
{
    name="Blah",
    results={item1=1,item2=1},
    ingredients={item3=1,item4=1},    
    requires_tools={item5},
    requires_class="",
    requires_faction="",
    requires_spells={},
    skill_requirements={skill1=2}
    stat_requirements={strength=100}
    required_level=0,
    no_auto_learn=true
}]]