-- Example 6: Debug Library
-- Chapter: 09-advanced
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: debug.getinfo, debug.getlocal, debug.sethook, debug.traceback

local debug = debug

--- Print function information using debug.getinfo
-- @param func function to inspect
-- @param label description for output
local function inspect_function(func, label)
  local info = debug.getinfo(func, "nS")
  print(string.format("  %s:", label))
  print(string.format("    Name: %s", info.name or "(anonymous)"))
  print(string.format("    Defined: %s:%d-%d", info.short_src, info.linedefined, info.lastlinedefined))
  print(string.format("    Type: %s", info.what))
end

--- Get all local variables at a specific stack level
-- @param level stack level to inspect
-- @return table of variable names and values
local function get_locals(level)
  local locals = {}
  local i = 1
  while true do
    local name, value = debug.getlocal(level, i)
    if not name then break end
    if name:sub(1, 1) ~= "(" then  -- skip internal variables
      locals[name] = value
    end
    i = i + 1
  end
  return locals
end

--- Print local variables at current stack level
-- @param level stack level (default: 2 for caller)
local function print_locals(level)
  level = level or 2
  local locals = get_locals(level)
  print("  Local variables:")
  for name, value in pairs(locals) do
    local val_str
    if type(value) == "table" then
      val_str = string.format("table (%d items)", #value)
    elseif type(value) == "string" then
      val_str = string.format('"%s"', value:sub(1, 20))
    else
      val_str = tostring(value)
    end
    print(string.format("    %s = %s", name, val_str))
  end
end

--- Set up a call counter using debug hooks
-- @param max_calls maximum calls before triggering
-- @return function to get call count, function to reset
local function make_call_counter(max_calls)
  local count = 0
  local triggered = false

  debug.sethook(function(event)
    if event == "call" then
      count = count + 1
      if count >= max_calls and not triggered then
        triggered = true
        print(string.format("  [Hook] Reached %d function calls!", max_calls))
      end
    end
  end, "c")

  return function() return count end,
         function() count = 0; triggered = false end
end

--- Demo function with interesting locals
local function demo_function(a, b)
  local x = a + b
  local msg = "computed"
  local data = {1, 2, 3}
  return x, msg, data
end

--- Nested function to show traceback
local function level_three()
  error("intentional error for traceback demo")
end

local function level_two()
  level_three()
end

local function level_one()
  level_two()
end

--- Main function demonstrating debug library features
local function main()
  print("=== Debug Library ===\n")

  -- 1. Function introspection
  print("1. Function Introspection:")
  inspect_function(print, "print")
  inspect_function(demo_function, "demo_function")
  inspect_function(function() end, "anonymous function")

  -- 2. Local variable inspection
  print("\n2. Local Variable Inspection:")
  local my_var = "hello"
  local my_num = 42
  local my_table = {1, 2, 3}
  print_locals(2)

  -- 3. Call with return value inspection
  print("\n3. Function Execution:")
  local result, msg, data = demo_function(5, 3)
  print(string.format("  Result: %d", result))
  print(string.format("  Message: %s", msg))
  print(string.format("  Data: table with %d items", #data))

  -- 4. Traceback
  print("\n4. Stack Traceback:")
  print("  Generating traceback from level_one -> level_two -> level_three:")
  local status, err = pcall(level_one)
  if not status then
    print(string.format("  Error: %s", err))
  end

  -- 5. Call counting with hooks
  print("\n5. Call Counter with Hooks:")
  local get_count, reset = make_call_counter(5)

  -- Make some function calls
  local function noop() end
  noop()  -- 1
  noop()  -- 2
  noop()  -- 3
  noop()  -- 4
  noop()  -- 5 (triggers hook)

  print(string.format("  Total calls: %d", get_count()))
  reset()
  print(string.format("  After reset: %d", get_count()))

  -- 6. Stack level exploration
  print("\n6. Stack Level Info:")
  local function show_stack(level)
    local info = debug.getinfo(level, "n")
    if info then
      print(string.format("  Level %d: %s", level, info.name or "(anonymous)"))
    else
      print(string.format("  Level %d: (no function)", level))
    end
  end

  local function wrapper()
    show_stack(1)  -- wrapper itself
    show_stack(2)  -- caller (main)
    show_stack(3)  -- main's caller (if any)
  end
  wrapper()

  -- Reset hook to avoid interfering with other code
  debug.sethook()

  print("\n✓ Debug library examples completed!")
end

-- Run the demonstration
main()
