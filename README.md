# roguelove
Roguelike code written in Lua, based on [Possession](http://possessiongame.com/ "Possession"). Designed to be used with the [LÖVE](http://love2d.org/ "LÖVE") game framework (http://love2d.org)

Currently not a full game, but has some test content. If you want to start from scratch, rename or remove the data/ directory, and rename the data_empty/ directory to data/

Features that have been added that weren't in Possession:
* Items and inventory
  * Players and NPCs can have, use, equip, and throw items.
  * Equipment can add stat bonuses, have callbacks when various things happen, and grant abilities.
  * Items can have "tags" attached to them, that can be used by various things throughout the game (so far, only stores look at items' tags to determine if they want to buy them).
  * Basic crafting is implemented.
  * Item enchantments: Currently have effects for melee weapons and projectiles. Enchantments can add prefixes and suffixes to item's name.
    * Melee weapon enchantments: Can add hit and critical conditions to an attack, can modify a weapon's stats (damage, accuracy, etc.), can run code after either a hit or miss occurs. Can add extra elemental damage, and only apply that damage to certain creature types if desired. Can be permanent, or can last for a set number of either attacks, successful hits, or kills.
    * Projectile enchantments: Affects thrown items, or ammunition. Can add hit conditions to a projectile attack. Can modify damage done by a projectile. Can modify hit chance of a ranged attack (if applied to a thrown item only, not ammunition). Can run code after the projectile hits or misses. If a projectile leaves an item behind, the projectile's enchantments are carried over to the item left behind.
    * Armor/equipment enchantments: Can add bonuses or callbacks to the armor. Enchantments on other types of items (ranged weapons, armor).
  * TODO: Getting NPCs to use items and change equipment.
  * TODO: Auto-comparing an item's stats to your current equipment.
* NPC factions
  * Factions can determine NPCs' hostility or friendliness to the player, to other faction members, and to specific creature types.
  * Players can gain or lose favor with factions from killing specific creatures or creature types. Factions can view the player as an ally or enemy depending on their favor level.
  * You can join, learn spells from, trade items with, receive services from, and get missions from factions.
* Stores
  * Stores can have a variety of items, and can generate with infinite or limited numbers of that item.
  * Stores can sell and buy different lists of items.
  * A "Store" feature generates during mapgen, with a store definition attached to it, and moving onto it lets you interact with the store.
  * Stores can be defined with a list of tags they'll buy. You can sell items to the store matching these tags rather than having to pre-define every single item the store will buy. The stores will use that item's defined Value attribute as the amount they'll pay for it.
  * Stores can use an item as a currency rather than money.
  * Stores can dynamically generate their inventory from a list of tags rather than it being pre-defined.
  * Stores can restock their items, and have rules defined for how that works
  * Future improvements: Different instances of the same store (eg. a weapon store shows up every level, but has different items every time)
* Player species and class selection on the newgame screen.
  * "Species" determines what creature definition to use for the player
  * Classes can modify stats, give starting items, spells, faction membership and favor, money, and damage weaknesses/resistances. Classes can also give the players initial missions.
  * Classes can automatically grant certain abilities on level up.
  * Classes can also give you the option to buy a new ability for skill points.
  * Classes can limit which player species are allowed to choose them, either by explicitly requiring/forbidding them, or by using tags.
  * Future improvements: Classes granting options to choose between abilities on level up, rather than automatically giving them.
    * Possible: Skill trees
* Dungeon Branches
  * Rather than all floors being in a linear progression, multiple "branches" can be defined in game.
  * Each branch has its own defined number of floors which the player moves up/down along linearly.
  * Each branch has a list of map types it uses to generate its floors, and can also force specific map types to spawn at a given depth, to recreate the old special levels functionality.
  * Branches can exit to other branches.
  * By default, you can return to previously-visited floors within a branch (unlike in Possession), but this can be turned off.
  * Branches can be set to ensure each floor within the branch is a different map type, so it doesn't repeat.
  * Branches and MapTypes can define the specific creatures/items that will spawn in them, or list creature/item types, factions, and tags they'll pull stuff from.
* Events
  * Events are arbitrary code chunks that can run at given points during the game.
  * There are four times that events can be checked to run: Entering a map, entering a map for the first time, killing a creature, and randomly.
  * Events can be associated with a faction, and can be set to only run if the player's favor is above or below a certain level, or only if the player is a member of the faction.
  * Events can be set to only run a limited number of times during the game, have a set rarity, and can have requires() code that determines if the event can be run at the current time. They can also just be run manually, if desired.
* Miscellaneous:
  * Features can have "actions" attached to them. There's a new keybinding used to perform a feature's action. Features can have multiple actions attached to them.

[Incomplete guide to using the Roguelove engine](https://docs.google.com/document/d/1bJmuokbK8Xtd2P9K8KRQRSeGdHd78HGKuOKaZltCoE4/edit?usp=sharing)

[Trello board I'm using to keep track of tasks](https://trello.com/b/ByyPFT00/roguelove)

Incomplete documentation of the code is available in the doc/ directory.

Available under the MIT license if you want to use any of the code. If you do use it, please let me know! I'd be interested to see what you make with it.
