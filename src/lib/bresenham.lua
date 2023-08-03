-- bresenham.lua - v1.0 (2012-05)
-- Copyright (c) 2011 Enrique García Cota
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local function los(x0,y0,x1,y1, callback, object,...)
  local args = {...}
  local sx,sy,dx,dy

  if x0 < x1 then
    sx = 1
    dx = x1 - x0
  else
    sx = -1
    dx = x0 - x1
  end

  if y0 < y1 then
    sy = 1
    dy = y1 - y0
  else
    sy = -1
    dy = y0 - y1
  end

  local err, e2 = dx-dy, nil

  --if (callback and object and not callback(object,x0,y0)) or (object == false and callback and not callback(x0, y0)) then return false end

  while not(x0 == x1 and y0 == y1) do
    e2 = err + err
    if e2 > -dy then
      err = err - dy
      x0  = x0 + sx
    end
    if e2 < dx then
      err = err + dx
      y0  = y0 + sy
    end
    if ((callback and object and not callback(object,x0,y0,unpack(args))) or (object == nil and callback and not callback(x0, y0,unpack(args)))) and (x0 ~= x1 or y0 ~= y1) then return false end
  end

  return true
end

local function line(x0,y0,x1,y1,callback,object,...)
  local args = {...}
  local points = {}
  local count = 0
  local ended = false
  local result = los(x0,y0,x1,y1, function(x,y)
    if (callback and object and not callback(object,x,y,unpack(args))) or (object == nil and callback and not callback(x,y,unpack(args))) then ended = true end
    count = count + 1
    points[count] = {x,y}
    if ended == true then return false end
    return true
  end)
  return points, result
end

return {
  los = los,
  line = line,
}
