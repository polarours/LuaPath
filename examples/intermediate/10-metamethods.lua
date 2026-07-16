-- Example 10: Metamethods Deep Dive
-- Chapter: 09-metatables
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: arithmetic metamethods, string concatenation, comparison, length

--- Vector2D class with full arithmetic metamethods
local Vector = {}
Vector.__index = Vector

function Vector:new(x, y)
  return setmetatable({x = x or 0, y = y or 0}, Vector)
end

function Vector.__add(a, b)
  return Vector:new(a.x + b.x, a.y + b.y)
end

function Vector.__sub(a, b)
  return Vector:new(a.x - b.x, a.y - b.y)
end

function Vector.__mul(a, b)
  if type(a) == "number" then
    return Vector:new(a * b.x, a * b.y)
  elseif type(b) == "number" then
    return Vector:new(a.x * b, a.y * b)
  end
  return a.x * b.x + a.y * b.y
end

function Vector.__eq(a, b)
  return a.x == b.x and a.y == b.y
end

function Vector.__lt(a, b)
  return (a.x * a.x + a.y * a.y) < (b.x * b.x + b.y * b.y)
end

function Vector.__le(a, b)
  return (a.x * a.x + a.y * a.y) <= (b.x * b.x + b.y * b.y)
end

function Vector.__len(v)
  return math.floor(math.sqrt(v.x * v.x + v.y * v.y))
end

function Vector.__tostring(v)
  return string.format("(%g, %g)", v.x, v.y)
end

--- String builder using __concat metamethod
local StringBuilder = {}
StringBuilder.__index = StringBuilder

function StringBuilder:new()
  return setmetatable({parts = {}}, StringBuilder)
end

function StringBuilder:append(text)
  self.parts[#self.parts + 1] = text
  return self
end

function StringBuilder.__concat(a, b)
  local sb = StringBuilder:new()
  if type(a) == "table" then
    for _, p in ipairs(a.parts) do sb.parts[#sb.parts + 1] = p end
  else
    sb.parts[#sb.parts + 1] = tostring(a)
  end
  if type(b) == "table" then
    for _, p in ipairs(b.parts) do sb.parts[#sb.parts + 1] = p end
  else
    sb.parts[#sb.parts + 1] = tostring(b)
  end
  return sb
end

function StringBuilder:tostring()
  return table.concat(self.parts)
end

function StringBuilder.__tostring(sb)
  return sb:tostring()
end

--- Money class with __add, __sub, __eq, __lt, __tostring
local Money = {}
Money.__index = Money

function Money:new(amount, currency)
  return setmetatable({amount = amount, currency = currency or "USD"}, Money)
end

function Money.__add(a, b)
  assert(a.currency == b.currency, "currency mismatch")
  return Money:new(a.amount + b.amount, a.currency)
end

function Money.__sub(a, b)
  assert(a.currency == b.currency, "currency mismatch")
  return Money:new(a.amount - b.amount, a.currency)
end

function Money.__eq(a, b) return a.amount == b.amount and a.currency == b.currency end
function Money.__lt(a, b) return a.amount < b.amount end
function Money.__le(a, b) return a.amount <= b.amount end

function Money.__tostring(m)
  return string.format("%s %.2f", m.currency, m.amount)
end

local function main()
  print("=== Metamethods Deep Dive ===\n")

  -- 1. Vector arithmetic
  print("1. Vector Arithmetic:")
  local v1 = Vector:new(3, 4)
  local v2 = Vector:new(1, 2)
  print(string.format("  v1 = %s", v1))
  print(string.format("  v2 = %s", v2))
  print(string.format("  v1 + v2 = %s", v1 + v2))
  print(string.format("  v1 - v2 = %s", v1 - v2))
  print(string.format("  v1 * 2 = %s", v1 * 2))
  print(string.format("  2 * v2 = %s", 2 * v2))
  print(string.format("  v1 == v2: %s", tostring(v1 == v2)))
  print(string.format("  v2 < v1: %s", tostring(v2 < v1)))
  print(string.format("  #v1 (length): %d", #v1))

  -- 2. String builder
  print("\n2. String Builder (__concat):")
  local sb = StringBuilder:new()
  sb:append("Hello"):append(" ")
  local sb2 = StringBuilder:new()
  sb2:append("World"):append("!")
  local combined = sb .. " " .. sb2
  print(string.format("  Result: %s", combined))

  -- 3. Money class
  print("\n3. Money Class:")
  local a = Money:new(29.99, "USD")
  local b = Money:new(15.50, "USD")
  print(string.format("  a = %s", a))
  print(string.format("  b = %s", b))
  print(string.format("  a + b = %s", a + b))
  print(string.format("  a - b = %s", a - b))
  print(string.format("  a == b: %s", tostring(a == b)))
  print(string.format("  b < a: %s", tostring(b < a)))

  print("\n✓ All metamethod demos completed!")
end

main()
