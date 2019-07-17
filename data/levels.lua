specialLevels = {}

--Put them into an indexed table, so you can easily retrieve them by depth later
specialLevels.index = {}
for id,level in pairs(specialLevels) do
  if level.depth then
    if specialLevels.index[level.depth] then
      table.insert(specialLevels.index[level.depth],id)
    else
      specialLevels.index[level.depth] = {id}
    end --end if depth
  end --end level check
end --end for
