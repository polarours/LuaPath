-- Example 2: Safe Sandbox Environment
-- Chapter: 14-lua-in-production
-- Difficulty: Advanced
-- Lua Version: 5.2+
--
-- Demonstrates: sandboxing, environment isolation, security

--- Create a restricted sandbox environment
-- @return sandbox table, restricted global environment
local function create_sandbox()
  local sandbox = {}
  
  -- Safe base functions
  local safe_globals = {
    -- Basic functions
    print = print,
    type = type,
    tostring = tostring,
    tonumber = tonumber,
    assert = assert,
    error = error,
    pcall = pcall,
    xpcall = xpcall,
    
    -- Math (safe)
    math = {
      abs = math.abs,
      ceil = math.ceil,
      floor = math.floor,
      max = math.max,
      min = math.min,
      modf = math.modf,
      sqrt = math.sqrt,
      sin = math.sin,
      cos = math.cos,
      tan = math.tan,
      asin = math.asin,
      acos = math.acos,
      atan = math.atan,
      exp = math.exp,
      log = math.log,
      log10 = math.log10,
      pi = math.pi,
      huge = math.huge,
    },
    
    -- String (safe)
    string = {
      byte = string.byte,
      char = string.char,
      find = string.find,
      format = string.format,
      gmatch = string.gmatch,
      gsub = string.gsub,
      len = string.len,
      lower = string.lower,
      match = string.match,
      rep = string.rep,
      reverse = string.reverse,
      sub = string.sub,
      upper = string.upper,
    },
    
    -- Table (safe)
    table = {
      concat = table.concat,
      insert = table.insert,
      pack = table.pack,
      remove = table.remove,
      sort = table.sort,
      unpack = table.unpack,
    },
    
    -- Coroutine (safe)
    coroutine = {
      create = coroutine.create,
      resume = coroutine.resume,
      running = coroutine.running,
      status = coroutine.status,
      wrap = coroutine.wrap,
      yield = coroutine.yield,
    },
    
    -- Utility
    ipairs = ipairs,
    pairs = pairs,
    next = next,
    select = select,
    _VERSION = _VERSION,
  }
  
  -- Create restricted environment
  local restricted_env = setmetatable({}, {
    __index = restricted_env,
    __newindex = sandbox,  -- Writes go to sandbox
  })
  
  -- Copy safe globals
  for k, v in pairs(safe_globals) do
    restricted_env[k] = v
  end
  
  -- Remove dangerous functions from loaded modules
  if safe_globals.math then
    -- Already filtered above
  end
  
  return sandbox, restricted_env
end

--- Run code in a sandbox
-- @param code string of Lua code
-- @param sandbox sandbox table (optional)
-- @param restricted_env restricted environment (optional)
-- @return success, result or error message
local function run_sandboxed(code, sandbox, restricted_env)
  sandbox = sandbox or {}
  restricted_env = restricted_env or create_sandbox()
  
  -- Compile the code
  local func, err = load(code, "=sandbox", "t", restricted_env)
  if not func then
    return false, "Compile error: " .. err
  end
  
  -- Run with protection
  local result = {pcall(func)}
  local success = table.remove(result, 1)
  
  if not success then
    return false, "Runtime error: " .. result[1]
  end
  
  return true, result
end

-- Test
print("Safe Sandbox Environment")
print("========================")

local sandbox, restricted_env = create_sandbox()

-- Test 1: Safe code
print("\nTest 1: Safe math operations")
local code1 = [[
  local result = math.sqrt(144)
  print("sqrt(144) =", result)
  return result
]]

local success, result = run_sandboxed(code1, sandbox, restricted_env)
print(string.format("Success: %s, Result: %s", success, result))

-- Test 2: Attempt to access dangerous function
print("\nTest 2: Attempt to access os.execute")
local code2 = [[
  return os.execute("echo pwned")
]]

success, result = run_sandboxed(code2, sandbox, restricted_env)
print(string.format("Success: %s, Error: %s", success, result or "N/A"))

-- Test 3: Attempt to access file system
print("\nTest 3: Attempt to access io.open")
local code3 = [[
  local f = io.open("/etc/passwd", "r")
  return f
]]

success, result = run_sandboxed(code3, sandbox, restricted_env)
print(string.format("Success: %s, Error: %s", success, result or "N/A"))

-- Test 4: Infinite loop protection (manual timeout needed in production)
print("\nTest 4: Bounded computation")
local code4 = [[
  local sum = 0
  for i = 1, 1000 do
    sum = sum + i
  end
  return sum
]]

success, result = run_sandboxed(code4, sandbox, restricted_env)
print(string.format("Success: %s, Sum: %s", success, result))

-- Test 5: Table operations
print("\nTest 5: Table operations in sandbox")
local code5 = [[
  local t = {1, 2, 3, 4, 5}
  table.insert(t, 6)
  table.sort(t, function(a, b) return a > b end)
  return table.concat(t, ", ")
]]

success, result = run_sandboxed(code5, sandbox, restricted_env)
print(string.format("Success: %s, Result: %s", success, result))

-- Test 6: Check what's available
print("\nTest 6: Inspecting sandbox contents")
print("Available globals in restricted_env:")
for k, v in pairs(restricted_env) do
  if type(v) ~= "table" then
    print(string.format("  %s: %s", k, type(v)))
  else
    print(string.format("  %s: (table with %d entries)", k, #v))
  end
end

print("\n✓ Sandbox tests completed!")
print("\nNote: Production sandboxing requires additional measures:")
print("  - CPU time limits (via debug hook)")
print("  - Memory limits")
print("  - Careful audit of all exposed functions")
print("  - Version-specific considerations")
