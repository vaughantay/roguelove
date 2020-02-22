# roguelove
Roguelike code written in Lua, based on [Possession](http://possessiongame.com/ "Possession"). Designed to be used with the [LÖVE](http://love2d.org/ "LÖVE") game framework (http://love2d.org)

Currently not a full game, but has some test content.

Features that have been added that weren't in Possession:
* Items and inventory
  * Pretty much fully implemented on the player side, though some interface cleanup is needed and NPCs don't currently use items.
* NPC factions
  * It's possible to join and learn spells from factions. Faction stores and missions are not implemented yet.
* Stores
  * Buying from stores is implemented, but not selling to them.
* Player classes and class selection on the newgame screen.
  * Done. Classes can modify stats, give starting equipment, spells, faction membership and favor, and damage weaknesses/resistances. Classes can also automatically grant certain abilities on level up.

[Incomplete guide to using the Roguelove engine](https://docs.google.com/document/d/1bJmuokbK8Xtd2P9K8KRQRSeGdHd78HGKuOKaZltCoE4/edit?usp=sharing)

Incomplete documentation of the code is available in the doc/ directory.

Available under the MIT license if you want to use any of the code. If you do use it, please let me know! I'd be interested to see what you make with it.
