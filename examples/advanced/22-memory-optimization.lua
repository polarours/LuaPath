-- Example 25: Memory Optimization
-- Chapter: 12-performance
-- Difficulty: Advanced
-- Lua Version: 5.1+

-- Demonstrates: memory management, table reuse, weak references

local function main()
  print("=== Memory Optimization Demo ===\n")

  -- 1. Table reuse
  print("--- Table Reuse ---")
  local function without_reuse(n)
    local sum = 0
    for i = 1, n do
      local t = {x = i, y = i * 2}
      sum = sum + t.x + t.y
    end
    return sum
  end

  local function with_reuse(n)
    local t = {}
    local sum = 0
    for i = 1, n do
      t.x = i
      t.y = i * 2
      sum = sum + t.x + t.y
    end
    return sum
  end

  local n = 100000
  collectgarbage("collect")
  local before = collectgarbage("count")
  without_reuse(n)
  collectgarbage("collect")
  local after = collectgarbage("count")
  print(string.format("Without reuse: %.2f KB", after - before))

  collectgarbage("collect")
  before = collectgarbage("count")
  with_reuse(n)
  collectgarbage("collect")
  after = collectgarbage("count")
  print(string.format("With reuse: %.2f KB", after - before))

  -- 2. String concatenation
  print("\n--- String Building ---")
  local function concat_bad(n)
    local s = ""
    for i = 1, n do
      s = s .. tostring(i)
    end
    return s
  end

  local function concat_good(n)
    local parts = {}
    for i = 1, n do
      parts[i] = tostring(i)
    end
    return table.concat(parts)
  end

  collectgarbage("collect")
  before = collectgarbage("count")
  concat_bad(10000)
  collectgarbage("collect")
  after = collectgarbage("count")
  print(string.format("Bad concat: %.2f KB", after - before))

  collectgarbage("collect")
  before = collectgarbage("count")
  concat_good(10000)
  collectgarbage("collect")
  after = collectgarbage("count")
  print(string.format("Good concat: %.2f KB", after - before))

  -- 3. Weak references
  print("\n--- Weak References ---")
  local cache = setmetatable({}, {__mode = "k"})
  local keys = {}
  for i = 1, 100 do
    keys[i] = {id = i}
    cache[keys[i]] = "item" .. i
  end

  local count = 0
  for _ in pairs(cache) do count = count + 1 end
  print("Before release:", count, "entries")

  -- Release 50 keys
  for i = 51, 100 do
    keys[i] = nil
  end
  collectgarbage()
  collectgarbage()

  count = 0
  for _ in pairs(cache) do count = count + 1 end
  print("After release:", count, "entries")

  print("\n=== Done ===")
end

main()
