# roguelove
Roguelike code written in Lua, based on [Possession](http://possessiongame.com/ "Possession"). Designed to be used with the [LÖVE](http://love2d.org/ "LÖVE") game framework (http://love2d.org)

Currently not a full game, but has some test content. If you want to start from scratch, rename or remove the data/ directory, and rename the data_empty/ directory to data/

Highlights:
* Supports creatures and items, as standard, but also has support for static map features (like trees, pits, or doors), fired projectiles, and dynamic effects (like poison gas clouds or fire that spreads on its own).
* Items and inventory
  * Equipment can add stat bonuses, have callbacks when various things happen, and grant abilities when worn.
  * Support for ranged weapons, with attached ranged attacks and capable of using multiple types of ammo with varying effects. Throwable items can also be created.
  * Well-defined (but optional!) crafting system.
  * Items can have proper names (including players renaming items if they want).
  * Item enchantments: Currently have effects for melee weapons and projectiles. Enchantments can add prefixes and suffixes to item's name.
    * Melee weapon enchantments: Can add hit and critical conditions to an attack, can modify a weapon's stats (damage, accuracy, etc.), can run code after either a hit or miss occurs. Can add extra elemental damage, and only apply that damage to certain creature types if desired. Can be permanent, or can last for a set number of either attacks, successful hits, or kills.
    * Projectile enchantments: Affects thrown items, or ammunition. Can add hit conditions to a projectile attack. Can modify damage done by a projectile. Can modify hit chance of a ranged attack (if applied to a thrown item only, not ammunition). Can run code after the projectile hits or misses. If a projectile leaves an item behind, the projectile's enchantments are carried over to the item left behind.
    * Armor/equipment enchantments: Can add bonuses or callbacks to the armor. Enchantments on other types of items (ranged weapons, armor).
  * TODO: Getting NPCs to use items and change equipment.
  * TODO: Auto-comparing an item's stats to your current equipment.
* NPC (and player) factions
  * Factions can determine NPCs' hostility or friendliness to the player, to other faction members, and to specific creature types.
  * Players can gain or lose favor with factions from killing specific creatures or creature types. Factions can view the player as an ally or enemy depending on their favor level.
  * You can join, learn spells from, trade items with, receive services from, learn recipes from, and get missions from factions.
* Stores
  * Stores can dynamically generate their inventory from a list of tags rather than it being pre-defined (though pre-defining store inventory is also an option).
  * Stores can also offer "services" (arbitrary chunks of code that can do whatever) and teach abilities.
  * Stores can be defined with a list of tags they'll buy (or, again, a list of specific items). You can sell items to the store matching these tags rather than having to pre-define every single item the store will buy.
  * Stores can use an item as a currency rather than money.
  * Different instances can exist of the same store with their own inventories (eg. a weapon store shows up every level, but has different items every time)
* Maps
  * Many customizable built-in map layouts, including rooms-and-cooridors, natural-looking cave-like maps, and mazes (including natural-looking cave-like mazes).
  * Map types are defined that include what sorts of creatures and items can spawn on the map.
  * Multiple "branches" can be defined in game. Each branch has its own defined number of floors which the player moves up/down along linearly.
  * Each branch has a list of map types it uses to generate its floors, and can generate them in random order or force specific map types to spawn at a given depth.
  * By default, you can return to previously-visited floors within a branch, but this can be turned off.
  * Branches can be set to ensure each floor within the branch is a different map type, so it doesn't repeat.
  * Branches and MapTypes can define the specific creatures/items that will spawn in them, or list creature/item types, factions, and tags they'll pull stuff from.
  * Room and map decorators can be defined that customize appearance and content of rooms and maps.
* Spells/abilities
  * Robust ability system, with support for active and passive abilities, as well as abilities that can be toggled on and off.
  * Active abilities can use MP, have cooldowns, have a set number of charges, or none of the above.
  * Abilities have a variety of callbacks that can run at various points in the game.
  * Abilities can appy passive buffs/debuffs.
  * Abilities' stats can be upgraded.
* Skills
  * Extremely customizable creature skill/attrbitute system. "Skills" are defined per-game, and the base engine doesn't assume any creature has any given skill.
  * The game can set given skills or stats to use as melee and ranged hit/damage, and dodging bonuses. Creature definitions and item definitions can override these to use their own skills. For example, you can have a default Melee skill for most weapons but have a magic weapon that gives extra damage based on your Magic skill instead.
  * Skills can grant spells, increase creature stats, and grant bonuses automatically when upgraded. Skills can also grant the option of purchasing spells from the character screen.
  * Skills have all the same callbacks as spells/items/conditions.
  * By default, you increase skills infinitely at 1 per point. But you can cap them, or cause them to increase by more than 1 per point. They can also be capped to 1 if you just want a skill to be "you have it or you don't" instead of having skill ranks.
  * Skills can be assigned to different categories that use their own points, so you can for example, split them into Attributes, Skills, and Feats D&D-style, or have special class or species-specific skills that level up with their own points.
* Conditions
  * Creatures can suffer/benefit from conditions, which can have callbacks that can run at various points in the game.
  * Conditions can apply passive buffs/debuffs.
* Events
  * Events are arbitrary code chunks that can run at given points during the game.
  * There are four times that events can be checked to run: Entering a map, entering a map for the first time, killing a creature, and randomly.
  * Events can be associated with a faction, and can be set to only run if the player's favor is above or below a certain level, or only if the player is a member of the faction.
  * Events can be set to only run a limited number of times during the game, have a set rarity, and can have requires() code that determines if the event can be run at the current time. They can also just be run manually, if desired.
* Missions
  * Can be given by factions.
  * Can have callbacks that runs while the mission is active.
  * Can have any amount of unique data stored and tracked as part of the mission (for example, storing the definition of a specific item that needs to be found).
  * Game setting to have all players start with given missions. Starting missions can also be set by the player's class.
  * Can be repeatable, or only occur once.
* UI/UX:
  * Save/load system.
  * Fully rebindable keys, also completely playable with only the mouse.
  * Achievement system.
  * Tutorial system.
  * Animated effects and creatures.
* Miscellaneous:
  * Customizable NPC AI enabling a range of behaviors. For example, ranged creatures prefering to keep a distance, creatures moving between patrol points or guarding certain areas, creatures with varying degrees of aggression and fear. NPC behavior also interacts with the faction system mentioned above.
  * Many game features are customizable and optional. For example, you don't have to have crafting (or even items) in the game, can disable species/class selection, bosses, etc.
  * Map features can have "actions" attached to them.
  * Many types of content can have "tags" attached to them, which are used to dynamically determine where that content can be used, rather than having to explictly define what items/creatures/etc are available where.
  * Lighting system. Entire maps can be lit or unlit. Map features, creatures, projectiles, and items can cast light in unlit maps.

[Incomplete guide to using the Roguelove engine](https://docs.google.com/document/d/1bJmuokbK8Xtd2P9K8KRQRSeGdHd78HGKuOKaZltCoE4/edit?usp=sharing)

[Trello board I'm using to keep track of tasks](https://trello.com/b/ByyPFT00/roguelove)

[Incomplete documentation of the code](https://vaughantay.github.io/roguelove/)

[Weirdfellows Discord Server, with a Roguelove development channel](https://discord.gg/2cjZ4kuFJU)

Available under the MIT license if you want to use any of the code. If you do use it, please let me know! I'd be interested to see what you make with it.
