-- Example 10: Scope and Blocks
-- Chapter: 01-basics
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: do-end blocks, variable scope, shadowing, block-local variables

--- Demonstrates basic do-end blocks for isolating variables
local function demo_block_scope()
  print("=== Block Scope ===")

  do
    local x = 10
    print("  Inside block: x = " .. x)
  end
  -- x is not accessible here

  -- Nested blocks create isolated scopes
  do
    local outer = "outer"
    do
      local inner = "inner"
      print("  Nested: outer=" .. outer .. ", inner=" .. inner)
    end
    -- inner is gone, outer still lives
    print("  After inner block: outer = " .. outer)
  end
end

--- Shows variable shadowing within nested scopes
local function demo_shadowing()
  print("\n=== Variable Shadowing ===")

  local x = "global x"
  print("  Before: x = " .. x)

  do
    local x = "block x"
    print("  In block: x = " .. x)

    do
      local x = "nested x"
      print("  In nested block: x = " .. x)
    end

    print("  Back in block: x = " .. x)
  end

  print("  Back outside: x = " .. x)
end

--- Loop variables are scoped to the loop body
local function demo_loop_scope()
  print("\n=== Loop Scope ===")

  for i = 1, 3 do
    local label = "item_" .. i
    print("  Iteration " .. i .. ": " .. label)
  end

  -- i and label are not accessible here; they existed only in the loop block

  -- Capture loop variables via closure
  local funcs = {}
  for i = 1, 5 do
    funcs[i] = function() return i end
  end
  print("  Closure values: " ..
    funcs[1]() .. ", " ..
    funcs[3]() .. ", " ..
    funcs[5]() .. " (each captured its own i)")
end

--- Conditionals create implicit blocks
local function demo_conditional_scope()
  print("\n=== Conditional Scope ===")

  local status = "ok"

  if status == "ok" then
    local message = "Everything is fine"
    print("  if branch: " .. message)
  elseif status == "warn" then
    local message = "Something looks off"
    print("  elseif branch: " .. message)
  else
    local message = "Houston, we have a problem"
    print("  else branch: " .. message)
  end
  -- message is not accessible here regardless of which branch ran
end

--- Temporary variables for cleanup patterns
local function demo_cleanup_pattern()
  print("\n=== Cleanup Pattern ===")

  local function process_items(items)
    local results = {}
    for _, item in ipairs(items) do
      -- Temporary variables in inner blocks for complex logic
      local normalized
      do
        local raw = item:lower()
        local trimmed = raw:match("^%s*(.-)%s*$")
        normalized = trimmed
      end
      -- normalized survives, intermediate temps are gone
      table.insert(results, normalized)
    end
    return results
  end

  local data = {"  Hello ", "  WORLD  ", " Lua "}
  local out = process_items(data)
  for _, v in ipairs(out) do
    print("  Cleaned: '" .. v .. "'")
  end
end

--- Guard clauses using early return (block-less scoping via return)
local function demo_guard_clauses()
  print("\n=== Guard Clauses ===")

  local function divide(a, b)
    if b == 0 then return nil, "division by zero" end
    return a / b
  end

  local function describe_number(n)
    if n == nil then return "nil" end
    if n < 0 then return "negative" end
    if n == 0 then return "zero" end
    return "positive"
  end

  local q, err = divide(10, 3)
  print("  10 / 3 = " .. tostring(q))
  q, err = divide(10, 0)
  print("  10 / 0 = " .. tostring(q) .. " (" .. err .. ")")
  print("  describe_number(-5) = " .. describe_number(-5))
  print("  describe_number(0)  = " .. describe_number(0))
  print("  describe_number(7)  = " .. describe_number(7))
end

--- Practical example: parsing with scoped helpers
local function demo_practical()
  print("\n=== Practical: Config Parsing ===")

  local raw = "  host=localhost  port=8080  debug=true  "

  local function parse_config(str)
    local config = {}
    for assignment in str:gmatch("%S+") do
      local key, value = assignment:match("^(%w+)=(.+)$")
      if key then
        -- Use a block for type coercion attempts
        local coerced = value
        do
          local num = tonumber(value)
          if num then coerced = num end
        end
        config[key] = coerced
      end
    end
    return config
  end

  local cfg = parse_config(raw)
  for k, v in pairs(cfg) do
    print("  " .. k .. " = " .. tostring(v) .. " (" .. type(v) .. ")")
  end
end

function main()
  print("Scope and Blocks Examples")
  print("========================")

  demo_block_scope()
  demo_shadowing()
  demo_loop_scope()
  demo_conditional_scope()
  demo_cleanup_pattern()
  demo_guard_clauses()
  demo_practical()

  print("\nKey takeaways:")
  print("  - do-end blocks create local scopes")
  print("  - Variables live until end of their enclosing block")
  print("  - Shadowing lets inner blocks reuse names safely")
  print("  - Loop variables are per-iteration block-locals")
end

main()
