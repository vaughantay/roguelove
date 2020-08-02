# roguelove
Roguelike code written in Lua, based on [Possession](http://possessiongame.com/ "Possession"). Designed to be used with the [LÖVE](http://love2d.org/ "LÖVE") game framework (http://love2d.org)

Currently not a full game, but has some test content.

Features that have been added that weren't in Possession:
* Items and inventory
  * Players and NPCs can have, use, equip, and throw items.
  * Equipment can add stat bonuses, have callbacks when various things happen, and grant abilities.
  * Items can have "tags" attached to them, that can be used by various things throughout the game (so far, only stores look at items' tags to determine if they want to buy them).
  * Item enchantments: Currently have effects for melee weapons and projectiles. All enchantments add prefixes and suffixes to item's name.
    * Melee weapon enchantments: Can add hit and critical conditions to an attack, can modify a weapon's stats (damage, accuracy, etc.), can run code after either a hit or miss occurs. Can be permanent, or can last for a set number of either attacks or successful hits.
    * Projectile enchantments: Affects thrown items, or ammunition. Can add hit conditions to a projectile attack. Can modify damage done by a projectile. Can modify hit chance of a ranged attack (if applied to a thrown item only, not ammunition). Can run code after the projectile hits or misses. If a projectile leaves an item behind, the projectile's enchantments are carried over to the item left behind.
    * Future Improvements: Enchantments that decrease their time left when a kill is made with the weapon. Other situations where code can be run by enchantments. Enchantments on other types of items.
  * TODO: Getting NPCs to use items and change equipment.
  * TODO: Implement a scrollbar on the inventory screen if the item list gets too long.
  * TODO: Auto-comparing an item's stats to your current equipment.
  * Future Improvements: Crafting
* NPC factions
  * Factions can determine NPCs' hostility or friendliness to the player, to other faction members, and to specific creature types.
  * Players can gain or lose favor with factions from killing specific creatures or creature types. Factions can view the player as an ally or enemy depending on their favor level.
  * It's possible to join, learn spells from, and trade items with factions.
  * TODO: Implementing faction missions (first, missions in general need to be implemented).
* Stores
  * Stores can have a variety of items, and can generate with infinite or limited numbers of that item.
  * Stores can sell and buy different lists of items.
  * A "Store" feature generates during mapgen, with a store definition attached to it, and moving onto it lets you interact with the store.
  * Stores can be defined with a list of tags they'll buy. You can sell items to the store matching these tags rather than having to pre-define every single item the store will buy. The stores will use that item's defined Value attribute as the amount they'll pay for it.
  * Stores can use an item as a currency rather than money.
  * Future improvements: Stores dynamically generating their inventory rather than it being pre-defined.
  * Future improvements: Different instances of the same store (eg. a weapon store shows up every level, but has different items every time)
* Player classes and class selection on the newgame screen.
  * Classes can modify stats, give starting items, spells, faction membership and favor, money, and damage weaknesses/resistances.
  * Classes can also automatically grant certain abilities on level up.
  * Future improvements: Classes granting options to choose between abilities on level up, rather than automatically giving them.
    * Possible: Skill trees
* Miscellaneous:
  * Features can have "actions" attached to them. There's a new keybinding used to perform a feature's action. Features can have multiple actions attached to them.

[Incomplete guide to using the Roguelove engine](https://docs.google.com/document/d/1bJmuokbK8Xtd2P9K8KRQRSeGdHd78HGKuOKaZltCoE4/edit?usp=sharing)

Incomplete documentation of the code is available in the doc/ directory.

Available under the MIT license if you want to use any of the code. If you do use it, please let me know! I'd be interested to see what you make with it.
