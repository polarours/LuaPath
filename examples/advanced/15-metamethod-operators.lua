-- Example 15: Metamethod Operators
-- Chapter: 07-metatables
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: __add, __sub, __mul, __div, __mod, __pow, __unm, __concat, __len, __eq, __lt, __le

--- Vector class demonstrating arithmetic, comparison, and length metamethods
local Vector = {}
Vector.__index = Vector

function Vector.new(x, y, z)
  return setmetatable({x = x or 0, y = y or 0, z = z or 0}, Vector)
end

function Vector:__add(other)
  return Vector.new(self.x + other.x, self.y + other.y, self.z + other.z)
end

function Vector:__sub(other)
  return Vector.new(self.x - other.x, self.y - other.y, self.z - other.z)
end

function Vector:__mul(scalar)
  if type(scalar) == "number" then
    return Vector.new(self.x * scalar, self.y * scalar, self.z * scalar)
  end
  -- Dot product if multiplying by another vector
  return self.x * scalar.x + self.y * scalar.y + self.z * scalar.z
end

function Vector:__unm()
  return Vector.new(-self.x, -self.y, -self.z)
end

function Vector:__eq(other)
  return self.x == other.x and self.y == other.y and self.z == other.z
end

function Vector:__lt(other)
  return self:mag() < other:mag()
end

function Vector:__le(other)
  return self:mag() <= other:mag()
end

function Vector:__len()
  return math.floor(self:mag())
end

function Vector:__tostring()
  return string.format("Vec(%.1f, %.1f, %.1f)", self.x, self.y, self.z)
end

function Vector:mag()
  return math.sqrt(self.x^2 + self.y^2 + self.z^2)
end

local function demo_vector()
  print("=== Vector Class ===")

  local a = Vector.new(1, 2, 3)
  local b = Vector.new(4, 5, 6)

  print("  a = " .. tostring(a))
  print("  b = " .. tostring(b))
  print("  a + b = " .. tostring(a + b))
  print("  a - b = " .. tostring(a - b))
  print("  a * 3 = " .. tostring(a * 3))
  print("  -a = " .. tostring(-a))
  print("  a == b = " .. tostring(a == b))
  print("  a == Vector.new(1,2,3) = " .. tostring(a == Vector.new(1, 2, 3)))
  print("  a < b = " .. tostring(a < b))
  print("  a <= a = " .. tostring(a <= a))
  print("  #a (|a|) = " .. #a)
end

--- Complex number class with division, modulus, and power
local Complex = {}
Complex.__index = Complex

function Complex.new(real, imag)
  return setmetatable({real = real or 0, imag = imag or 0}, Complex)
end

function Complex:__add(other)
  return Complex.new(self.real + other.real, self.imag + other.imag)
end

function Complex:__sub(other)
  return Complex.new(self.real - other.real, self.imag - other.imag)
end

function Complex:__mul(other)
  return Complex.new(
    self.real * other.real - self.imag * other.imag,
    self.real * other.imag + self.imag * other.real
  )
end

function Complex:__div(other)
  local denom = other.real^2 + other.imag^2
  return Complex.new(
    (self.real * other.real + self.imag * other.imag) / denom,
    (self.imag * other.real - self.real * other.imag) / denom
  )
end

function Complex:__unm()
  return Complex.new(-self.real, -self.imag)
end

function Complex:__eq(other)
  return self.real == other.real and self.imag == other.imag
end

function Complex:__pow(exp)
  -- De Moivre's theorem for integer powers
  local r = math.sqrt(self.real^2 + self.imag^2)
  local theta = math.atan(self.imag, self.real)
  local r_exp = r ^ exp
  return Complex.new(
    r_exp * math.cos(exp * theta),
    r_exp * math.sin(exp * theta)
  )
end

function Complex:__tostring()
  if self.imag == 0 then return tostring(self.real) end
  if self.real == 0 then return string.format("%gi", self.imag) end
  local sign = self.imag > 0 and "+" or ""
  return string.format("%s%s%gi", self.real, sign, self.imag)
end

function Complex:mag()
  return math.sqrt(self.real^2 + self.imag^2)
end

function Complex:conjugate()
  return Complex.new(self.real, -self.imag)
end

local function demo_complex()
  print("\n=== Complex Number Class ===")

  local z1 = Complex.new(3, 4)
  local z2 = Complex.new(1, -2)

  print("  z1 = " .. tostring(z1))
  print("  z2 = " .. tostring(z2))
  print("  z1 + z2 = " .. tostring(z1 + z2))
  print("  z1 - z2 = " .. tostring(z1 - z2))
  print("  z1 * z2 = " .. tostring(z1 * z2))
  print("  z1 / z2 = " .. tostring(z1 / z2))
  print("  -z1 = " .. tostring(-z1))
  print("  z1 == z2 = " .. tostring(z1 == z2))
  print("  z1 == Complex.new(3,4) = " .. tostring(z1 == Complex.new(3, 4)))
  print("  z1^2 = " .. tostring(z1 ^ 2))
  print("  |z1| = " .. string.format("%.2f", z1:mag()))
  print("  conj(z2) = " .. tostring(z2:conjugate()))
end

--- String builder with concat and len metamethods
local StringBuilder = {}
StringBuilder.__index = StringBuilder

function StringBuilder.new()
  return setmetatable({_parts = {}, _len = 0}, StringBuilder)
end

function StringBuilder:append(str)
  table.insert(self._parts, str)
  self._len = self._len + #str
  return self
end

function StringBuilder:__concat(other)
  if type(self) == "string" then
    return self .. tostring(other)
  elseif type(other) == "string" then
    return tostring(self) .. other
  else
    local result = StringBuilder.new()
    result:append(tostring(self))
    result:append(tostring(other))
    return result
  end
end

function StringBuilder:__len()
  return self._len
end

function StringBuilder:__tostring()
  return table.concat(self._parts)
end

function StringBuilder:__eq(other)
  return tostring(self) == tostring(other)
end

local function demo_string_builder()
  print("\n=== String Builder ===")

  local sb = StringBuilder.new()
  sb:append("Hello"):append(", "):append("World!")
  print("  sb = " .. tostring(sb))
  print("  #sb = " .. #sb)

  local sb2 = StringBuilder.new()
  sb2:append("Hello, World!")
  print("  sb == sb2 = " .. tostring(sb == sb2))
  print("  sb == 'Hello, World!' = " .. tostring(sb == "Hello, World!"))

  -- Concatenation with other types
  local sb3 = sb .. " (modified)"
  print("  sb .. ' (modified)' = " .. tostring(sb3))

  local mixed = "Prefix: " .. sb
  print("  'Prefix: ' .. sb = " .. tostring(mixed))
end

--- Demonstrating __mod for custom formatting (like Python's %)
local FormatString = {}
FormatString.__index = FormatString

function FormatString.new(template)
  return setmetatable({_template = template}, FormatString)
end

function FormatString:__mod(values)
  local result = self._template
  if type(values) == "table" then
    local i = 0
    result = result:gsub("%%([^%d])", function(c)
      i = i + 1
      if c == "s" then return tostring(values[i] or "")
      elseif c == "d" then return tostring(math.floor(tonumber(values[i]) or 0))
      elseif c == "f" then return string.format("%.2f", tonumber(values[i]) or 0)
      end
      return "%" .. c
    end)
  else
    result = result:gsub("%%([^%d])", function(c)
      return tostring(values)
    end)
  end
  return result
end

function FormatString:__tostring()
  return self._template
end

local function demo_format_string()
  print("\n=== Format String (% operator) ===")

  local fmt = FormatString.new("User: %s, Age: %d, Score: %f")
  print("  " .. (fmt % {"Alice", 30, 95.678}))

  local fmt2 = FormatString.new("Result: %s")
  print("  " .. (fmt2 % "computed"))
end

--- Demonstrating __pow for custom exponentiation
local Probability = {}
Probability.__index = Probability

function Probability.new(p)
  if p < 0 or p > 1 then error("probability must be in [0,1]") end
  return setmetatable({_p = p}, Probability)
end

function Probability:__pow(n)
  -- Independent events: P(A)^n = probability of n independent occurrences
  return Probability.new(self._p ^ n)
end

function Probability:__le(other)
  return self._p <= other._p
end

function Probability:__lt(other)
  return self._p < other._p
end

function Probability:__tostring()
  return string.format("%.1f%%", self._p * 100)
end

function Probability:not_p()
  return Probability.new(1 - self._p)
end

local function demo_probability()
  print("\n=== Probability Class ===")

  local fair = Probability.new(0.5)
  local biased = Probability.new(0.8)

  print("  fair = " .. tostring(fair))
  print("  biased = " .. tostring(biased))
  print("  fair^3 (3 heads in a row) = " .. tostring(fair ^ 3))
  print("  biased^3 = " .. tostring(biased ^ 3))
  print("  fair <= biased = " .. tostring(fair <= biased))
  print("  not fair = " .. tostring(fair:not_p()))
end

function main()
  print("Metamethod Operators Examples")
  print("=============================")

  demo_vector()
  demo_complex()
  demo_string_builder()
  demo_format_string()
  demo_probability()

  print("\nKey takeaways:")
  print("  - __add/__sub/__mul/__div/__mod/__pow: arithmetic operators")
  print("  - __unm: unary minus (negation)")
  print("  - __concat: the .. operator for concatenation")
  print("  - __len: the # operator for length")
  print("  - __eq/__lt/__le: comparison operators (require same type)")
  print("  - Metamethods let you define domain-specific operator behavior")
end

main()
