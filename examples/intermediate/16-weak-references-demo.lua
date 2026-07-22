-- Example 16: Weak References
-- Chapter: 07-weak-tables
-- Difficulty: Intermediate
-- Lua Version: 5.1+

-- Demonstrates: weak tables, __mode, GC interaction

local function main()
  print("=== Weak References Demo ===\n")

  -- Create a weak key table
  local cache = setmetatable({}, {__mode = "k"})

  -- Create objects and cache them
  local obj1 = {name = "first"}
  local obj2 = {name = "second"}
  local obj3 = {name = "third"}

  cache[obj1] = "cached1"
  cache[obj2] = "cached2"
  cache[obj3] = "cached3"

  print("Before GC:")
  for k, v in pairs(cache) do
    print("  " .. tostring(k) .. " = " .. tostring(v))
  end

  -- Release references
  obj1 = nil
  obj2 = nil

  -- Force GC
  collectgarbage()
  collectgarbage()

  print("\nAfter GC:")
  for k, v in pairs(cache) do
    print("  " .. tostring(k) .. " = " .. tostring(v))
  end

  -- Weak value table
  print("\n=== Weak Value Table ===")
  local weak_values = setmetatable({}, {__mode = "v"})

  local a = {data = "important"}
  weak_values[1] = a
  weak_values[2] = {data = "temporary"}

  print("Before:", #weak_values, "entries")

  -- Release one reference
  a = nil
  collectgarbage()
  collectgarbage()

  print("After:", #weak_values, "entries")

  print("\n=== Done ===")
end

main()
