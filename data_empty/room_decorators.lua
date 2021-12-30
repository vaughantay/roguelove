local roomDecorators = {}

function decorate_room(room,map,roomDec,...)
  local dec = nil
  if roomDec == "random" or not roomDec then
    dec = get_random_element(roomDecorators)
  elseif roomDecorators[roomDec] then
    dec = roomDecorators[roomDec]
  elseif type(roomDec) == "table" then
    get_random_element(roomDec)
    if roomDecorators[roomDec] then
      dec = roomDecorators[roomDec]
    end
  end
  if dec then
    dec(room,map,unpack({...}))
  end
  return
end