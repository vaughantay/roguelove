function generate_hero_name(creature)
	local adjectives = {"Green","Horrifying","Monstrous","Good","Evil","Deadly","Fearsome","Rotting","Joyous","Happy","Blessed","Cursed","Undying","Willful","Unbelievable","Incredible","Indestructible","Unknown","Unknowable","Forgotten","All-Seeing","Unwilling","Disgusting","Irritating","Attractive","Cold","Magnetic","Red","Black","Splendored","Rich","Playful","Plastic","Destructive","Sharp","Faceless","Fearless","Powerless","Electric","Freaky","Corrupted","Pornographic","Bloody","Bleeding","Burning","Primordial","Original","Loathsome","Dead","Grateful","Psychedelic","Sexual","Pleasurable","Sleepy","Shiny","Angry","Wrathful","Unpleasant","Flying","Silly","Foolish","Famous","Infamous","Backwards","Godly","Holy","Unholy","Spirutual","Ancestral","Entertaining","Soft","Dry","Wet","Poor","Congressional","Airborne","Brown","Yellow","White","Blue","Bottled","Sweet","Defiled","Debased","Peaceful","Laughing","Revolutionary","Problematic","Caffeinated","Stoned","Drunk","Lost","Former","Future","Current","Fashionable","Contemporary","Frail","Dark","Under","Over","Uber","Schwarz"}
	local nouns = {"Death","Fear","Mustard","Meat","Flesh","Horror","Rot","Decay","Light","Evil","Good","Fish","Water","Cow","Bone","Torment","Creation","Delivery","Sadness","Brain","Intelligence","Book","Disease","Cat","Monster","Magnet","Bloodhound","Tree","Moneymaker","Billionare","Spraycan","Game","Wit","Music","Ice","Miasma","Mask","Power","Slide","Flag","Spaceship","God","Angel","Demon","Mutant","Corruption","Forgetfulness","Hell","Hall","Covering","Destroyer","Noun","Hunter","Blood","Heart","Fire","Wind","Earth","Insect","Madness","Bagel","Inventor","Spectre","Spy","Prison","Seducer","Masochist","Wrath","Flower","Pain","Breaker","Bringer","Terror","Fool","Jester","Clown","Circus","Entertainer","Spirit","Ancestor","Soda","Cola","Drink","Cup","Prophet","Preacher","Bird","Guitar","Bank","Senator","Spider","Bottle","Programmer","Writer","Doctor","Defiler","Debaser","Corruptor","Bandit","Century","Sweetheart","Lover","Disciple","Toothbrush","Terror","Merchant","Problem","Child","Confessor","Forgiver","Investor","List","Darkness","Robot","Man","Soul"}
	local concepts = {"Death","Fear","Mustard","Meat","Flesh","Horror","Rot","Decay","Light","Evil","Good","Fish","Water","Cows","Bone","Bones","Torment","Creation","Delivery","Sadness","Brains","Intelligence","Books","Disease","Cats","Monsters","Magnets","Bloodhounds","Trees","Moneymakers","Billionares","Spraycans","Games","Wit","Music","Cold","Ice","Miasma","Masks","Power","Slides","Flags","Spaceships","God","Angels","Demons","Mutants","Corruption","Forgetfulness","Hell","Hallways","Covering","Destroying","Nouns","Hunters","Blood","Heart","Fire","Wind","Earth","Insects","Madness","Bagels","Inventors","Ogres","Skeletons","Goblins","Spectres","Spies","Prison","Seducers","Masochism","Wrath","Sex","Flowers","Pain","Terror","Unpleasantness","Birds","Fools","Mirth","Movies","Mistakes","Spirits","Ancestors","Soda","Cola","Alcohol","Cups","Prophets","Gods","Banking","Politics","Spiders","Candy","Crime","Love","Peace","Laughter","Coffee","Chocolate","Beer","Communism","Revolution","Capitalism","Libertarianism","Problems","Scissors","Time","Fashion","Money","Shopping","Failure","Darkness"}
	local fnames = {}
	local lastname = ""
  
  local gender = nil
  if creature == nil or (creature.gender ~= "male" and creature.gender ~= "female") then
    if random(0,1) == 1 then gender = "male" else gender = "female" end
  else
    gender = creature.gender
  end
	if (gender == "male") then
		fnames = {"Tom","Dick","Harry","Harvey","Frank","Joseph","Joe","Sam","Gary","Taylor","Tyler","Patrick","Ray","Pat","Ahmed","Louis","John","Billy","David","Dave","Boris","Dimitri","Jamal","Arnold","Matt","Bob","Guillarme","Chris","Andrew","Ali","Ludwig","Hans","Franz","Mohammed","Moonflower","Hunter","Alistair","Nick","Walter","Jesse","Pablo","Spencer","Yoshi","Gus","Peter","Max","Xavier","Pounce","Bones","Legs","Knives","Jake","Jacob","Ed","Edward","Potter","Sylvester","Luke","George","Richard","Timmy","Irving","Evan","William","Angelo","Antonio","Cesar","Juan","Marcus","Javier","Elliot","Tetsuo","Dmitri","Daniel","Dan","Craig"}
	else
		fnames = {"Susan","Mary","Sarah","Shaquita","Lisa","Beth","Liz","Greta","Helga","Phoebe","Martha","Marsha","Kim","Dana","Diana","Christine","Danielle","Ruth","Ann","Amber","Abigail","Fran","Taylor","Morgan","Moonflower","Katie","Lynn","Linda","Alicia","Felicia","Melinda","Mila","Yolanda","Taylor","Anna","Vicky","Debbie","Cheryl","Carol","Pam","Lucy","Becca","Jennifer","Jill","Legs","Knives","Pounce","Bones","Bella","Sweetie","Georgette","Felicia","Anastasia","Maria",}
	end
	
	if (random(1,2) == 1) then
		local lastnames = {"McLovin","Andrews","Ali","Dent","Keitel","van Beethoven","Brady","Durden","Finnegan","Connor","Palmer","Schwartz","Lucas","Skywalker","Krieger","Conrad","McDonald","Moonflower","Hunter","Lynn","Manning","Jones","Johnson","White","Black","Smith","Rodriguez","Day","Skye","Jobs","Gates","Miles","Greene","Swift","Mahoney","Mohammed","Chang","Takada","Tong","Fring","Potter","Weasley","Granger","Moneypenny","Solo","Bond","Ford","Nixon","Bush","Clinton","Washington","Lincoln","McGee","Nakamora","Williams","Chavez","Vasquez","Lopez"}
		lastname = lastnames[random(#lastnames)]
	else
		lastname = adjectives[random(#adjectives)] .. lcfirst(nouns[random(#nouns)])
	end
	
	return fnames[random(#fnames)] .. " " .. lastname
end

function generate_cave_name()
  local dnames = {"Caverns","Caves","Catacombs","Cave","Cavern","Grotto","Chasm","Hell","Hole","Geological Formation","Darkness","Rocks","Mines","Mine","Mountain","Emptiness","Carvings"}
  local concepts = {"Doom","Death","Fear","Malice","Terror","Destruction","Darkness","Horror","Torture","Evil","Unease","Solitude","Eternity","Travesty","Madness","Blood","Murder","Seceration","Monsters","Desolation","Discomfort","Shadows","Insanity","Silence","Demons","Heartbreak"}
	local adjectives = {"Dark","Terrible","Horrifying","Deadly","Evil","Horrible","Fearsome","Lost","Depressing","Mystical","Unending","Eternal","Lost","Doomed","Maddening","Desecrated","Blasphemous","Unholy","Spooky","Desolate","Uncomfortable","Infinite","Pathetic","Shadowy","Hidden","Unknown","Silent","Demonic"}
  
  local dtype = random(1,3)
	if (dtype == 1) then
		return "The " .. dnames[random(#dnames)] .. " of " .. concepts[random(#concepts)]
	elseif (dtype == 2) then
		return "The " .. adjectives[random(#adjectives)] .. " " .. dnames[random(#dnames)]
  elseif (dtype == 3) then
    return "The " .. dnames[random(#dnames)] .. " of " .. adjectives[random(#adjectives)] .. " " .. concepts[random(#concepts)]
	end
end

function generate_forest_name()
  local dnames = {"Woods","Forest","Trees","Jungle","Wilds","Timberlands","Wood","Woodland","Woodlands","Jungles","Overgrowth","Thicket","Fields","Growth","Grove","Nature","Garden"}
  local concepts = {"Doom","Death","Fear","Malice","Terror","Destruction","Darkness","Horror","Torture","Evil","Unease","Solitude","Eternity","Travesty","Madness","Blood","Murder","Desecration","Monsters","Nature","Gods","Demons","Heartbreak"}
	local adjectives = {"Dark","Terrible","Horrifying","Deadly","Evil","Horrible","Fearsome","Lost","Desolate","Depressing","Mystical","Unending","Eternal","Lost","Doomed","Maddening","Desecrated","Blasphemous","Unholy","Spooky","Desolate","Uncomfortable","Infinite","Lush","Enchanted","Monstrous","Ever-Growing","Damned"}
  
  local dtype = random(1,3)
	if (dtype == 1) then
		return "The " .. dnames[random(#dnames)] .. " of " .. concepts[random(#concepts)]
	elseif (dtype == 2) then
		return "The " .. adjectives[random(#adjectives)] .. " " .. dnames[random(#dnames)]
  elseif (dtype == 3) then
    return "The " .. dnames[random(#dnames)] .. " of " .. adjectives[random(#adjectives)] .. " " .. concepts[random(#concepts)]
	end
end

function generate_dungeon_name()
	local dnames = {"Dungeon","Keep","Fortress","Castle","Palace","Halls","Dungeons","Tomb","Chamber","Chambers","Hallways","Rooms"}
	local concepts = {"Doom","Death","Fear","Malice","Terror","Destruction","Darkness","Horror","Torture","Evil","Unease","Solitude","Eternity","Travesty","Madness","Blood","Murder","Desecration","Monsters","Souls","Disease","Heartbreak","Demons"}
	local adjectives = {"Dark","Terrible","Horrifying","Deadly","Evil","Horrible","Fearsome","Lost","Desolate","Depressing","Mystical","Unending","Eternal","Lost","Doomed","Maddening","Desecrated","Blasphemous","Unholy","Spooky","Desolate","Pathetic","Infinite","Uncomfortable","Monstrous","Damned"}
	
	local dtype = random(1,3)
	if (dtype == 1) then
		return "The " .. dnames[random(#dnames)] .. " of " .. concepts[random(#concepts)]
	elseif (dtype == 2) then
		return "The " .. adjectives[random(#adjectives)] .. " " .. dnames[random(#dnames)]
  elseif (dtype == 3) then
    return "The " .. dnames[random(#dnames)] .. " of " .. adjectives[random(#adjectives)] .. " " .. concepts[random(#concepts)]
	end
end

function generate_creature_name(title)
	
end

function generate_weapon_name()
	
end

function generate_title(creature)
	local adjectives = {"Green","Horrifying","Monstrous","Good","Evil","Deadly","Fearsome","Rotting","Joyous","Happy","Blessed","Cursed","Undying","Willful","Unbelievable","Incredible","Indestructible","Unknown","Unknowable","Forgotten","All-Seeing","Unwilling","Disgusting","Irritating","Attractive","Cold","Magnetic","Red","Black","Splendored","Rich","Playful","Plastic","Destructive","Sharp","Faceless","Fearless","Powerless","Electric","Freaky","Corrupted","Pornographic","Bloody","Bleeding","Burning","Primordial","Original","Loathsome","Dead","Grateful","Psychedelic","Sexual","Pleasurable","Sleepy","Shiny","Angry","Wrathful","Unpleasant","Flying","Silly","Foolish","Famous","Infamous","Backwards","Godly","Holy","Unholy","Spirutual","Ancestral","Entertaining","Soft","Dry","Wet","Poor","Congressional","Airborne","Brown","Yellow","White","Blue","Bottled","Sweet","Defiled","Debased","Peaceful","Laughing","Revolutionary","Problematic","Caffeinated","Stoned","Drunk","Lost","Former","Future","Current","Fashionable","Contemporary","Frail","Dark"}
	local nouns = {"Death","Fear","Mustard","Meat","Flesh","Horror","Rot","Decay","Light","Evil","Good","Fish","Water","Cow","Bone","Torment","Creation","Delivery","Sadness","Brain","Intelligence","Book","Disease","Cat","Monster","Magnet","Bloodhound","Tree","Moneymaker","Billionare","Spraycan","Game","Wit","Music","Ice","Miasma","Mask","Power","Slide","Flag","Spaceship","God","Angel","Demon","Mutant","Corruption","Forgetfulness","Hell","Hall","Covering","Destroyer","Noun","Hunter","Blood","Heart","Fire","Wind","Earth","Insect","Madness","Bagel","Inventor","Spectre","Spy","Prison","Seducer","Masochist","Wrath","Flower","Pain","Breaker","Bringer","Terror","Fool","Jester","Clown","Circus","Entertainer","Spirit","Ancestor","Soda","Cola","Drink","Cup","Prophet","Preacher","Bird","Guitar","Bank","Senator","Spider","Bottle","Programmer","Writer","Doctor","Defiler","Debaser","Corruptor","Bandit","Century","Sweetheart","Lover","Disciple","Toothbrush","Horrorterror","Merchant","Problem","Child","Confessor","Forgiver","Investor","List","Darkness",ucfirst(creature.name)}
	local concepts = {"Death","Fear","Mustard","Meat","Flesh","Horror","Rot","Decay","Light","Evil","Good","Fish","Water","Cows","Bone","Bones","Torment","Creation","Delivery","Sadness","Brains","Intelligence","Books","Disease","Cats","Monsters","Magnets","Bloodhounds","Trees","Moneymakers","Billionares","Spraycans","Games","Wit","Music","Cold","Ice","Miasma","Masks","Power","Slides","Flags","Spaceships","God","Angels","Demons","Mutants","Corruption","Forgetfulness","Hell","Hallways","Covering","Destroying","Nouns","Hunters","Blood","Heart","Fire","Wind","Earth","Insects","Madness","Bagels","Inventors","Ogres","Skeletons","Goblins","Spectres","Spies","Prison","Seducers","Masochism","Wrath","Sex","Flowers","Pain","Terror","Unpleasantness","Birds","Fools","Mirth","Movies","Mistakes","Spirits","Ancestors","Soda","Cola","Alcohol","Cups","Prophets","Gods","Banking","Politics","Spiders","Candy","Crime","Love","Peace","Laughter","Coffee","Chocolate","Beer","Communism","Revolution","Capitalism","Libertarianism","Problems","Scissors","Time","Fashion","Money","Shopping","Failure","Darkness"}
			
	local titleType = random(1,4)
	
	if (titleType == 1) then
		return "The " .. nouns[random(#nouns)] .. " of " .. concepts[random(#concepts)]
	elseif titleType == 2 then
		return "The " .. adjectives[random(#adjectives)]
	elseif titleType == 3 then
		return "The " .. adjectives[random(#adjectives)] .. " " .. nouns[random(#nouns)]
	elseif titleType == 4 then
		return "The " .. nouns[random(#nouns)]
	end
end

function generate_book_name()
	local booknames = {"Grimoire","Tome","Book","Atlas","Manual","Treatise","Dictionary","Encyclopedia","Lexicon","Codex","Textbook","Tome","Grimoire","Book","Omnibus"}
	local concepts = {"Death","Fear","Mustard","Meat","Flesh","Horror","Rot","Decay","Light","Evil","Good","Fish","Water","Cows","Bone","Bones","Torment","Creation","Delivery","Sadness","Brains","Intelligence","Books","Disease","Cats","Monsters","Magnets","Bloodhounds","Trees","Moneymakers","Billionares","Games","Wit","Music","Cold","Ice","Miasma","Masks","Power","Slides","Flags","Spaceships","God","Angels","Demons","Mutants","Corruption","Forgetfulness","Hell","Hallways","Covering","Destroying","Nouns","Hunters","Blood","Heart","Fire","Wind","Earth","Insects","Madness","Bagels","Inventors","Spectres","Spies","Prison","Seducers","Masochism","Wrath","Sex","Flowers","Pain","Terror","Unpleasantness","Birds","Fools","Mirth","Movies","Mistakes","Spirits","Ancestors","Soda","Cola","Alcohol","Cups","Prophets","Gods","Banking","Politics","Spiders","Candy","Crime","Love","Peace","Laughter","Coffee","Chocolate","Beer","Communism","Revolution","Capitalism","Libertarianism","Problems","Scissors","Time","Fashion","Money","Shopping","Failure","Darkness"}
	local magic = {"Spells","Enchantments","Charms","Hexes","Witchcraft","Wizardry","Curses","Blessings","Conjurations","Illusions","Evocations","Magic","Sorcery","Sorceries","Magick","Majick","Magic Tricks","Powers","Power","Party Tricks","Illusioncraft","Spiritualism"}
	local adjectives = {"Green","Horrifying","Monstrous","Good","Evil","Deadly","Fearsome","Joyous","Happy","Unbelievable","Incredible","Indestructible","Unknown","Unknowable","Forgotten","All-Seeing","Disgusting","Irritating","Attractive","Cold","Magnetic","Red","Black","Splendored","Rich","Playful","Plastic","Destructive","Sharp","Powerless","Electric","Freaky","Corrupted","Pornographic","Bloody","Burning","Primordial","Original","Loathsome","Psychedelic","Sexual","Pleasurable","Sleepy","Shiny","Wrathful","Unpleasant","Flying","Silly","Foolish","Famous","Infamous","Backwards","Godly","Holy","Unholy","Spiritual","Ancestral","Entertaining","Soft","Dry","Wet","Poor","Congressional","Airborne","Brown","Yellow","White","Blue","Bottled","Sweet","Defiled","Debased","Peaceful","Revolutionary","Problematic","Stoned","Drunk","Lost","Former","Future","Current","Fashionable","Contemporary","Frail","Dark","Fake","Mystical","Magical"}
	
	local titleType = random(1,2)
	
	if (titleType == 1) then
		return booknames[random(#booknames)] .. " of " .. concepts[random(#concepts)]
	else
		return booknames[random(#booknames)] .. " of " .. adjectives[random(#adjectives)] .. " " .. magic[random(#magic)]
	end
end