possibleItems = {}

local money = {
  name = "$1",
  description = "A pile of coins.",
  symbol = "$",
  itemType="other",
  color={r=255,g=255,b=0,a=255},
  value=1
}
function money:new(amount)
  if type(amount) ~= "number" then
    amount = random(10,50)
  end
  self.value = amount
  self.name = "$" .. amount
end
function money:pickup(possessor)
  possessor.money = possessor.money + self.value
  self:delete()
  return false
end
possibleItems['money'] = money