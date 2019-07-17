--[[random utility functions]]

-- Checks if "needle" is in "haystack", and returns the key if so
function in_table(needle, haystack)
	for i,v in pairs(haystack) do
		if (v==needle) then 
			return i end
	end
	return false
end

-- Returns a number somewhat close to the original number
function tweak(val)
  if val == 0 then return 0 end
  if val >= 1 then
    local min = math.ceil(val*.75)
    local max = math.floor(val*1.25)
    if min == max or max - min < 1 then return val end
    return random(min,max)
  else
    local min = val*75
    local max = val*125
    if min == max or max - min < 1 then return val end
    return random(min,max)/100
  end
end

--Rounds a number up if >= .5, down if <.5
function round(val)
  local dec = val-math.floor(val)
  if dec >= .5 then
    return math.ceil(val)
  else
    return math.floor(val)
  end
end

-- Pythagorean Theorem bitches
function calc_distance(fromX,fromY,toX,toY)
	return math.sqrt(math.abs(fromX-toX)^2 + math.abs(fromY-toY)^2)
end

-- Semi-Pythagorean Theorem bitches
function calc_distance_squared(fromX,fromY,toX,toY)
	return math.abs(fromX-toX)^2 + math.abs(fromY-toY)^2
end

-- Convert the first letter of a string to upper case
function ucfirst(string)
	string = tostring(string)
	return string:gsub("%a", string.upper, 1)
end

-- Convert the first letter of every word in a string to upper case
function ucfirstall(s)
  s = tostring(s)
  local newstring = ""
  local first = true
  for word in s:gmatch("%w+") do
    if first then first = false else newstring = newstring .. " " end
    newstring = newstring .. word:gsub("%a", string.upper, 1)
  end
	return newstring
end

-- Convert the first letter of a string to lower case
function lcfirst(string)
	string = tostring(string)
	return string:gsub("%a", string.lower, 1)
end

-- Convert the first letter of every word in a string to lower case
function lcfirstall(s)
  s = tostring(s)
  local newstring = ""
  local first = true
  for word in s:gmatch("%w+") do
    if first then first = false else newstring = newstring .. " " end
    newstring = newstring .. word:gsub("%a", string.lower, 1)
  end
	return newstring
end

--"Explode" a string into an array
function explode(string,delim)
  local parts = {}
  for part in string.gmatch(string, "[^" .. delim .."]+") do
		parts[#parts+1] = part
  end
  return parts
end

--Returns true if the string starts with a vowel, false otherwise
function vowel(string)
	local s = string:sub(1,1)
	if (s == "a" or s == "e" or s=="i" or s=="o" or s=="u" or s=="sometimes y") then
		return true
	end
	return false
end

-- gets a random element from a table
-- NOTE: This will not work properly if a table has numbered AND associative keys...but why the hell would you do that?
function get_random_element(t)
	if (t[1] ~= nil) then -- if it is a sequential, numbered "array"
		return t[random(#t)]
	else
		local nt = {}
		for i, obj in pairs(t) do -- put it into a sequentially-numbered array
			nt[#nt+1] = obj
		end
		return nt[random(#nt)]
	end
end

-- gets a random key from a table
function get_random_key(t)
	if (t[1] ~= nil) then -- if it is a sequential, numbered "array"
		return random(#t)
	else
		local keys = {}
		for key, obj in pairs(t) do
			keys[#keys+1] = key
		end
		return keys[random(#keys)]
	end
end

--gets the largest value from a table
function get_largest(t)
  local largest = 0
  local largestKey = nil
  for k,v in pairs(t) do
    if type(v) == "number" and v > largest then
      largest,largestKey = v,k
    end
  end
  return largest,largestKey
end

-- copies a table
function copy_table(t)
	local newT = {}
	for key, val in pairs(t) do
		if (type(val) == "table") then
			newT[key] = copy_table(val)
		else
			newT[key] = val
		end
	end
	return newT
end

--Shuffles a table.
--Also useful at turning an associative array into a numbered array
--Note: Only use if you want resulting table to have sequentially numbered values!
function shuffle(t)
  if count(t) == 1 and #t == 1 then return t end
  local newT = {}
  while next(t) ~= nil do
    local k = get_random_key(t)
    newT[#newT+1] = t[k]
    t[k] = nil
  end
  return newT
end

--Counts values in table (even if associative array)
function count(t)
  local c = 0
  for _,__ in pairs(t) do
    c = c + 1
  end
  return c
end

--Combines multiple arrays into one and returns the result
function merge_arrays(...)
  local new = {}
  for _,t in pairs({...}) do
    for _,i in pairs(t) do
      new[#new+1] = i
    end
  end
  return new
end

function loop_through_tiles(minX,maxX,minY,maxY)
  local tiles = {}
  for x=minX,maxX,1 do
    for y=minY,maxY,1 do
      
    end
  end
end

--This is probably not actually a unit vector
function get_unit_vector(fromX,fromY,toX,toY)
  local x = (fromX == toX and 0 or (fromX > toX and -1 or 1))
  local y = (fromY == toY and 0 or (fromY > toY and -1 or 1))
  return x,y
end

-- Calculate the angle between two points
function calc_angle(fromX,fromY,toX,toY)
  local xDiff = toX-fromX
  local yDiff = toY-fromY
  local rad = math.atan2(yDiff,xDiff)+math.pi*.5
  return 2*math.pi+rad
end

--Calculate area of triangle from three points
function calc_triangle_area(x1,y1,x2,y2,x3,y3)
  local area = math.abs((x1*(y2-y3) + x2*(y3-y1) + x3*(y1-y2))/2)
  return area
end

--Determine if a point is inside a triangle
function is_in_triangle(x1,y1,x2,y2,x3,y3,checkX,checkY)
  local full = calc_triangle_area(x1,y1,x2,y2,x3,y3)
  local a1,a2,a3 = calc_triangle_area(x1,y1,x2,y2,checkX,checkY),calc_triangle_area(x1,y1,x3,y3,checkX,checkY),calc_triangle_area(x2,y2,x3,y3,checkX,checkY)
  print(a1 .. " + " .. a2 .. " + " .. a3 .. " = " .. a1+a2+a3 .. ", compared to " .. full)
  if a1 + a2 + a3 == full then
    return true
  else
    return false
  end
end