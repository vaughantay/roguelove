possibleDialogs = {}

local townsperson = {
	text = "I love our beautiful town!",
	responses = {
    {
      text="Tell me more about your town!",
      moves_to_dialog = "townsperson_more",
      requires = function(self,speaker,asker)
        if currGame.dialog_seen.townsperson_insult then
          return false,true
        end
      end,
      display_text= function(self,speaker, asker)
        if speaker.dialog_seen.townsperson_more then
          return "Tell me about your town again!"
        end
      end
    },
    {
      text="This town isn't even that beautiful.",
      moves_to_dialog = 'townsperson_insult',
      requires = function(speaker, asker)
        if currGame.dialog_seen.townsperson_more and not currGame.dialog_seen.townsperson_insult then
          return true
        else
          return false
        end
      end,
      selected = function(speaker,asker)
        asker.reputation.village = (asker.reputation.village or 0)-1
        conversation:set_text("(You lose 1 reputation with " .. currWorld.factions.village.name .. ".)")
      end
    },
		{
      text="Goodbye",
      ends_conversation=true,
      order=3
    }
	}
}
function townsperson:display_text(speaker,asker,previous)
  if currGame.dialog_seen.townsperson_insult then
		return "Oh, it's you."
	elseif speaker.dialog_seen.townsperson then
    if not previous then
      return {"Hello again!","Welcome back to our beautiful town!"}
    else
      return "I've said it before, but I love our beautiful town!"
    end
	end
end
possibleDialogs['townsperson'] = townsperson

local townsperson_afraid = {
  text = "Help! Guards!"
}
possibleDialogs['townsperson_afraid'] = townsperson_afraid

local townsperson_hostile = {
  text = "Get away from me!"
}
possibleDialogs['townsperson_hostile'] = townsperson_hostile

local townsperson_more = {
	text = "Nothing bad ever happens here, despite there being stairs to a dungeon in the middle of the town.",
	responses = {
    {
      text="Sounds great!",
      moves_to_dialog="townsperson"
    },
    {
      text="Then why are there so many guards?",
      moves_to_dialog = "townsperson_guards"
    }
	}
}
function townsperson_more:display_text(speaker,asker)
	if speaker.dialog_seen.townsperson_more then
    if speaker.dialog_seen.townsperson_more > 3 then
      return {"Haha you really love this town too, huh?","Nothing bad ever happens here, despite there being stairs to a dungeon in the middle of the town."}
    else
      return {"Like I said...","Nothing bad ever happens here, despite there being stairs to a dungeon in the middle of the town."}
    end
	end
end
possibleDialogs['townsperson_more'] = townsperson_more

local townsperson_guards = {
  text = "Hmm. I never thought about that before.",
  moves_to_dialog = "townsperson"
}
possibleDialogs['townsperson_guards'] = townsperson_guards

local townsperson_insult = {
	text = {"How rude.","If that's the way you feel, then I guess this conversation is over.","Good day."},
	ends_conversation=true
}
possibleDialogs['townsperson_insult'] = townsperson_insult
