# roguelove
Roguelike code written in Lua, based on [Possession](http://possessiongame.com/ "Possession"). Designed to be used with the [LÖVE](http://love2d.org/ "LÖVE") game framework (http://love2d.org)

Currently not a full game, but has some test content.

Features that have been added that weren't in Possession:
* Items and inventory
  * Players and NPCs can have, use, equip, and throw items.
  * Equipment can add stat bonuses, have callbacks when various things happen, and grant abilities.
  * TODO: Getting NPCs to use items and change equipment.
  * TODO: Implement a scrollbar on the inventory screen if the item list gets too long.
  * TODO: Auto-comparing an item's stats to your current equipment.
  * Future Improvements: Item enchantments, crafting.
* NPC factions
  * Factions can determine NPCs' hostility or friendliness to the player, to other faction members, and to specific creature types.
  * Players can gain or lose favor with factions from killing specific creatures or creature types. Factions can view the player as an ally or enemy depending on their favor level.
  * It's possible to join, learn spells from, and trade items with factions.
  * TODO: Implementing faction missions (first, missions in general  need to be implemented).
* Stores
  * Stores can have a variety of items, and can generate with infinite or limited numbers of that item.
  * Stores can sell and buy different lists of items.
  * A "Store" feature generates during mapgen, with a store definition attached to it, and moving onto it lets you interact with the store.
  * Future improvements: Stores using an item as a token rather than normal money.
  * Future improvements: Stores letting you sell items matching certain qualifiers to them rather than having to pre-define what they buy.
* Player classes and class selection on the newgame screen.
  * Classes can modify stats, give starting items, spells, faction membership and favor, money, and damage weaknesses/resistances.
  * Classes can also automatically grant certain abilities on level up.
  * Future improvements: Classes granting options to choose between abilities on level up, rather than automatically giving them.

[Incomplete guide to using the Roguelove engine](https://docs.google.com/document/d/1bJmuokbK8Xtd2P9K8KRQRSeGdHd78HGKuOKaZltCoE4/edit?usp=sharing)

Incomplete documentation of the code is available in the doc/ directory.

Available under the MIT license if you want to use any of the code. If you do use it, please let me know! I'd be interested to see what you make with it.
