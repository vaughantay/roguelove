possibleRecipes = {}

local uhw =
{
  results={unholywater=1},
  ingredients={holywater=1,demonblood=1},
  requires_class="demonologist",
  result_text="You mix the demon blood into the holy water, corrupting it and turning it into unholy water."
}
possibleRecipes['unholywater'] = uhw

--[[recipes['blah'] =
{
    name="Blah",
    results={item1=1,item2=1},
    ingredients={item3=1,item4=1},    
    specific_tools={item5},
    tool_tags={tag1,tag2},
    requires_class="",
    requires_spells={},
}]]