mapTypes = {}

local void = {
  
}
function void.create(map,width,height)
  for x=2,width-1,1 do
    for y=2,height-1,1 do
      map[x][y] = "."
    end
  end
end
mapTypes['void'] = void