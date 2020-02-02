playerClasses = {
  demonhunter = {
    name="Demon Hunter",
    description="Fights those pesky demons.",
    favor={lightchurch=500}, --List of favor scores the character starts with
    factions={"lightchurch"}, --List of factions the character begins as a member of
    spells={"demondamager"}, --These are spells the character will start with
    items={"holywater","holywater"}, --These items will be granted on game start
    equipment={"holydagger"}, --These items will be equipped on game start
    learns_spells={{spell="smite",level=2}}, --These spells will be automatically granted once a certain level is reached
    spell_options={{spell="summonangel",level=2,cost=5}, {spell="blessweapon",level=2,cost=5}}, --These spells will show up as options to learn (requiring spending points on them)
    weaknesses={}, --These will be added to the characters' base weaknesses
    resistances={holy=25}, --These will be added the the characters' base resistances
    stat_modifiers={strength=2,dodging=-2}, --These values will be added to the characters' base stats
  },
  beefcake = {
    name="Beefcake",
    description="A super-tough warrior.",
    items={"healthpotionminor"}, --These items will be granted on game start
    equipment={"greatsword"}, --These items will be equipped on game start
    learns_spells={}, --These spells will be automatically granted once a certain level is reached
    spell_options={}, --These spells will show up as options to learn (requiring spending points on them)
    stat_modifiers={strength=5,dodging=-10,max_hp=25,armor=1}, --These values will be added to the characters' base stats
  },
  demonologist = {
    name="Demonologist",
    description="Studies those pesky demons.",
    favor={lightchurch=-100}, --List of favor scores the character starts with
    factions={"chaos"}, --List of factions the character begins as a member of
    spells={"demondamager"}, --These are spells the character will start with
    items={"holywater"}, --These items will be granted on game start
    equipment={"dagger"}, --These items will be equipped on game start
    learns_spells={}, --These spells will be automatically granted once a certain level is reached
    spell_options={}, --These spells will show up as options to learn (requiring spending points on them)
    weaknesses={holy=10}, --These will be added to the characters' base weaknesses
    resistances={fire=10,unholy=10}, --These will be added the the characters' base resistances
    stat_modifiers={dodging=2}, --These values will be added to the characters' base stats
  },
  wimp = {
    name="Total Wimp",
    description="A scrawny nerd.",
    items={"healthpotionminor"}, --These items will be granted on game start
    stat_modifiers={strength=-5,max_hp=-25}, --These values will be added to the characters' base stats
    spells={"scrawny"}, --These are spells the character will start with
  },
}