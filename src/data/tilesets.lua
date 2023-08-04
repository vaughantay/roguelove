tilesets = {
  default = {
    floorColor = {r=77,g=77,b=77,a=255},
    wallColor = {r=120,g=120,b=120,a=255},
  },
  graveyard = {
    floorColor = {r=98,g=73,b=22,a=255},
    floor_tiles = 5,
    wall_tiles = 2,
    tilemap = true,
  },
  mausoleum = {
    groundColor = {r=74,g=76,b=66,a=255},
    wallColor = {r=122,g=120,b=111,a=255},
    floor_tiles = 8,
    walls_tiles = 9,
    southOnly=true,
  },
  cave = {
    floor_tiles = 4,
    tilemap = true,
    wall_tiles = 4,
  },
  mines = {
    floor_tiles = 4,
    tilemap = true,
    wall_tiles = 8,
  },
  forest = {
    floor_tiles = 5,
    tilemap = true,
    wall_tiles = 1,
    textColor = {r=98,g=73,b=22,a=255}
  },
  bricks = {
    tilemap = true
  },
  tombs = {
    floor_tiles = 7,
    southOnly = true,
    walls_tiles = 5,
    textColor = {r=194,g=189,b=128,a=255}
  },
  eldritchcity = {
    --floor_tiles = 7,
    southOnly = true,
    walls_tiles = 7,
  },
  demonruins = {
    floor_tiles = 4,
    southOnly = true,
    walls_tiles = 5,
  },
  icemaze = {
  },
  dungeon = {
    floor_tiles = 7,
    southOnly = true,
    walls_tiles= 5,
  },
  swamp = {
    textColor = {r=63,g=56,b=24,a=255},
    wall_tiles = 2,
    tilemap = true,
  },
  lostworld = {
    textColor = {r=63,g=56,b=24,a=255},
    wall_tiles = 2,
    tilemap = true,
  },
  sewer = {
    southOnly = true,
    walls_tiles= 3,
    floor_tiles = 4,
    textColor = {r=150,g=150,b=150,a=255}
  },
  tavern = {
    southOnly = true,
    walls_tiles = 5,
    floor_tiles = 3,
    floor_tile_chance = 3,
    textColor = {r=63,g=56,b=24,a=255}
  },
  temple = {
    southOnly = true
  },
  village = {
    floor_tiles = 5,
    southOnly = true,
    textColor = {r=98,g=73,b=22,a=255}
  },
}