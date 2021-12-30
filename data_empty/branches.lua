dungeonBranches = {}

--Stairs: {branch="branch",depth=1,min_depth=1,max_depth=1,replace_upstairs=false,replace_downstairs=false,exit_depth=1,oneway=false,chance=100}

local main = {
  name = "Void",
  max_depth=1,
  mapTypes = {'void'},
}
dungeonBranches['main'] = main