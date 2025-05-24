---Random utility functions

---Checks if "needle" is in "haystack", and returns the key (and value) if so
--@param needle Anything. The item to look for.
--@param haystack Table. The table to search through.
--@return Anything or False. The index of the value being searched for. If it wasn't found, then FALSE.
--@return Anything or nil. The value being searched for. If it wasn't found, then nil.
function in_table(needle, haystack)
	for i,v in pairs(haystack) do
		if (v==needle) then 
			return i,v end
	end
	return false
end

---Returns a number between -10% and +10% of the original number.
--@param val Number. The number to tweak.
--@return Number. The tweaked number.
function tweak(val)
  if val == 0 then return 0 end
  if val >= 1 then
    local min = math.floor(val*.9)
    local max = math.ceil(val*1.1)
    if min == 0 then min = 1 end
    if min == max then return val end
    return random(min,max)
  elseif val <= -1 then
    local min = math.floor(val*1.1)
    local max = math.ceil(val*.9)
    if max == 0 then max = -1 end
    if min == max then return val end
    return random(min,max)
  else --fractional number
    local min = val*90
    local max = val*110
    if min == max then return val end
    return random(min,max)/100
  end
end

---Rounds a number up if >= .5, down if <.5
--@param val number to round.
--@return Number. The rounded number.
function round(val)
  local dec = val-math.floor(val)
  if dec >= .5 then
    return math.ceil(val)
  else
    return math.floor(val)
  end
end

--- Uses the Pythagorean Theorem to calculate the distance between two points.
--@param fromX Number. The origin X-coordinate.
--@param fromY Number. The origin Y-coordinate.
--@Param toX Number. The destination X-coordinate.
--@param toY Number. The destination Y-coordinate.
--@return Number. The distance.
function calc_distance(fromX,fromY,toX,toY)
	return math.sqrt(math.abs(fromX-toX)^2 + math.abs(fromY-toY)^2)
end

---Adds the squared X and Y distances between points. Use this if you're just comparing distances to see which is farther rather than needing to know what the distances actually are, since this is faster. 
--@param fromX Number. The origin X-coordinate.
--@param fromY Number. The origin Y-coordinate.
--@Param toX Number. The destination X-coordinate.
--@param toY Number. The destination Y-coordinate.
--@return Number. The sum of the squared X and Y distances between the points.
function calc_distance_squared(fromX,fromY,toX,toY)
	return math.abs(fromX-toX)^2 + math.abs(fromY-toY)^2
end

---Convert the first letter of a string to uppercase.
--@param string String. The string to process.
--@return String. The original string, but with the first letter uppercase.
function ucfirst(string)
	string = tostring(string)
	return string:gsub("%a", string.upper, 1)
end

---Convert the first letter of every word in a string to uppercase.
--@param s String. The string to process.
--@return String. The original string, but with the first letter of every word uppercase.
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

---Convert the first letter of a string to lowercase.
--@param string String. The string to process.
--@return String. The original string, but with the first letter lowercase.
function lcfirst(string)
	string = tostring(string)
	return string:gsub("%a", string.lower, 1)
end

---Convert the first letter of every word in a string to lowercase.
--@param s String. The string to process.
--@return String. The original string, but with the first letter of every word lowercase.
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

---"Explode" a string into an array
--@param string String. The string to turn into an array.
--@param delim String. The string used to delineate where each entry starts.
--@param Table. A table of strings.
function explode(string,delim)
  local parts = {}
  for part in string.gmatch(string, "[^" .. delim .."]+") do
		parts[#parts+1] = part
  end
  return parts
end

---Returns true if the string starts with a vowel, false otherwise
--@param string String.
--@return Boolean. Whether the string starts with a vowel or not.
function vowel(string)
	local s = string:sub(1,1)
	if (s == "a" or s == "e" or s=="i" or s=="o" or s=="u" or s == "A" or s == "E" or s == "I" or s == "O" or s == "U" or s=="sometimes y") then
		return true
	end
	return false
end

---Gets a random element from a table.
--NOTE: This probably will not work properly if a table has both numbered AND associative keys.
--@param t Table. The table to get an element from.
--@return Anything. A random element from the table.
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

---Gets a random key from a table.
--NOTE: This probably will not work properly if a table has both numbered AND associative keys.
--@param t Table. The table to get an element from.
--@return Anything. A random keyfrom the table.
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

---Gets the largest numerical value from a table
--@param t Table. The table to look through.
--@return Number. The largest number.
--@return Anything. The key of the largest number.
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

---Copies a table deeply (copies any sub-tables as well).
--WARNING: This will probably hang if your table contains a table that contains the original table.
--@param t Table. The table to copy.
--@return Table. A copy of the original table.
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

---Shuffles the order of table
--Also useful at turning an associative table into a numbered array
--Note: Only use if you want the resulting table to have sequentially numbered values!
--@param t Table. The table to shuffle.
--@return Table. A new version of the shuffled table.
function shuffle(t)
  if count(t) == 1 and #t == 1 then return t end
  local newT = {}
  while next(t) ~= nil do
    local k = get_random_key(t)
    newT[#newT+1] = t[k]
    t[k] = nil
  end
  for i,v in pairs(newT) do
    t[i] = v
  end
  return newT
end

---Counts the number of entries in a table (even if not sequentially numbered)
--@param t Table. The table to count.
--@return Number. The number of entries in the table, or 0 if it's not a table.
function count(t)
  if type(t) ~= "table" then
    return 0
  end
  local c = 0
  for _,__ in pairs(t) do
    c = c + 1
  end
  return c
end

---Combines multiple tables into one and returns the result. Does not respect the values of the keys - the resulting table will have sequentially-numbered keys.
--@param … Any number of tables.
--@return Table. A new table with all the other tables merged together.
function merge_tables(...)
  local new = {}
  for _,t in pairs({...}) do
    for _,i in pairs(t) do
      new[#new+1] = i
    end
  end
  return new
end

---Sorts a table
--@param t Table. The table to sort
--@param key Anything. The key to use to compare, if the table t contains subtables. Optional, if blank compares the values directly
function sort_table(t,key)
  local basicSort = function(a,b)
    return a < b
  end
  local subSort = function(a,b)
    return a[key] < b[key]
  end
  if not key then
    table.sort(t,basicSort)
  else
    table.sort(t,subSort)
  end
  return t
end

---Prints the keys and values in a table
--@param t Table. The table to print
function print_table(t,key)
  if type(t) ~= "table" then
    print(t)
    return
  end
  for i,v in pairs(t) do
    if type(v) == "table" and key then
      print(i,v[key])
    else
      print(i,v)
    end
  end
end

--Removes a given value from a numbered array
--@param t Table. The table.
--@param val Anything. The value to remove.
--@param multiple Boolean. If true, will remove all instances of val. Otherwise, only removes it once
function remove_from_array(t,val,multiple)
  local pos = 1
  local total = #t
  local removed = false
  
  for i=1,total,1 do
    if t[i] == val and (removed == false or multiple) then
      t[i] = nil
      removed = true
    else
      if i ~= pos then
        t[pos] = t[i]
        t[i] = nil
      end
      pos = pos + 1
    end
  end
  return t
end

---Determines what directions a set of coordinates is in from an origin point. Doesn't actually have anything to do with unit vectors.
--@param fromX Number. The origin X-coordinate.
--@param fromY Number. The origin Y-coordinate.
--@Param toX Number. The destination X-coordinate.
--@param toY Number. The destination Y-coordinate.
--@return Number. -1 if toX is to the left of fromX, +1 if it's to the right, 0 if they're the same.
--@return Number. -1 if toY is up from fromY, +1 if it's down, 0 if they're the same.
function get_unit_vector(fromX,fromY,toX,toY)
  local x = (fromX == toX and 0 or (fromX > toX and -1 or 1))
  local y = (fromY == toY and 0 or (fromY > toY and -1 or 1))
  return x,y
end

--- Calculate the angle between two points
--@param fromX Number. The origin X-coordinate.
--@param fromY Number. The origin Y-coordinate.
--@Param toX Number. The destination X-coordinate.
--@param toY Number. The destination Y-coordinate.
--@return Number. The angle
function calc_angle(fromX,fromY,toX,toY)
  local xDiff = toX-fromX
  local yDiff = toY-fromY
  local rad = math.atan2(yDiff,xDiff)+math.pi*.5
  return 2*math.pi+rad
end

--Calculate area of triangle from three points (don't think this is working)
function calc_triangle_area(x1,y1,x2,y2,x3,y3)
  local area = math.abs((x1*(y2-y3) + x2*(y3-y1) + x3*(y1-y2))/2)
  return area
end

--Determine if a point is inside a triangle (don't think this is working)
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