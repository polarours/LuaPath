-- Example 5: Safe Table Copy (Shallow and Deep)
-- Chapter: 04-tables
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: table copying, recursion, type checking

--- Shallow copy of a table
-- Only copies the top-level structure
-- @param original table to copy
-- @return new table with same keys/values
local function shallow_copy(original)
  if type(original) ~= "table" then
    return original
  end
  
  local copy = {}
  for key, value in pairs(original) do
    copy[key] = value
  end
  
  return copy
end

--- Deep copy of a table
-- Recursively copies all nested tables
-- @param original table to copy
-- @param seen internal tracking table (do not pass manually)
-- @return new table with recursively copied contents
local function deep_copy(original, seen)
  if type(original) ~= "table" then
    return original
  end
  
  -- Handle circular references
  seen = seen or {}
  if seen[original] then
    return seen[original]
  end
  
  local copy = {}
  seen[original] = copy
  
  for key, value in pairs(original) do
    local key_copy = deep_copy(key, seen)
    local value_copy = deep_copy(value, seen)
    copy[key_copy] = value_copy
  end
  
  -- Copy metatable
  local mt = getmetatable(original)
  if mt then
    setmetatable(copy, deep_copy(mt, seen))
  end
  
  return copy
end

-- Test shallow copy
print("Shallow copy test:")
local original = {x = 1, nested = {y = 2}}
local shallow = shallow_copy(original)

shallow.x = 10
shallow.nested.y = 20

print(string.format("  original.x = %d (expected 1)", original.x))
print(string.format("  shallow.x = %d (expected 10)", shallow.x))
print(string.format("  original.nested.y = %d (expected 20, shared!)", original.nested.y))
print(string.format("  shallow.nested.y = %d (expected 20)", shallow.nested.y))

-- Test deep copy
print("\nDeep copy test:")
original = {x = 1, nested = {y = 2}}
local deep = deep_copy(original)

deep.x = 10
deep.nested.y = 20

print(string.format("  original.x = %d (expected 1)", original.x))
print(string.format("  deep.x = %d (expected 10)", deep.x))
print(string.format("  original.nested.y = %d (expected 2, independent!)", original.nested.y))
print(string.format("  deep.nested.y = %d (expected 20)", deep.nested.y))

-- Test circular reference handling
print("\nCircular reference test:")
local circular = {x = 1}
circular.self = circular

local circular_copy = deep_copy(circular)
print(string.format("  Original has circular ref: %s", circular.self == circular))
print(string.format("  Copy has circular ref: %s", circular_copy.self == circular_copy))
print(string.format("  Copy is not original: %s", circular_copy ~= circular))

print("\n✓ All copy tests completed!")
