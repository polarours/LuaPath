-- Example 34: Safe Sandbox Environment
-- Chapter: 14-lua-in-production
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: sandboxing, environment isolation, security

-- table.unpack arrived in Lua 5.2; on 5.1 the global unpack() does the job.
local unpack_values = table.unpack or unpack

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
      pack = table.pack or function(...)
        local packed = { ... }
        packed.n = select("#", ...)
        return packed
      end,
      remove = table.remove,
      sort = table.sort,
      unpack = table.unpack or unpack,
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

  -- Create restricted environment.
  --
  -- The sandbox table is the backing store: the restricted environment is a
  -- proxy whose reads *and* writes both resolve to it, so a name that is not
  -- in the allow-list stays unreachable.
  --
  -- The fallback has to be `sandbox` and not the table being built. A local
  -- only comes into scope *after* its own statement, so naming
  -- `restricted_env` inside this constructor silently evaluates to nil --
  -- and a proxy with a nil __index resolves nothing at all.
  local restricted_env = setmetatable({}, {
    __index = sandbox,
    __newindex = sandbox,  -- Writes go to sandbox
  })

  -- Copy safe globals into the backing store
  for k, v in pairs(safe_globals) do
    restricted_env[k] = v
  end

  return sandbox, restricted_env
end

--- Run code in a sandbox
-- @param code string of Lua code
-- @param restricted_env restricted environment (optional)
-- @return success, result or error message
local function run_sandboxed(code, restricted_env)
  if not restricted_env then
    -- create_sandbox() returns two values. Keeping only the first would hand
    -- back the sandbox table instead of the restricted environment.
    local _, created_env = create_sandbox()
    restricted_env = created_env
  end

  -- Compile the code.
  --
  -- The 4-argument load(chunk, chunkname, mode, env) only arrived in 5.2; on
  -- 5.1 (and on LuaJIT, a 5.1 derivative) the equivalent is loadstring()
  -- followed by setfenv() on the compiled chunk.
  local func, err
  if loadstring then
    func, err = loadstring(code, "=sandbox")
    if func then setfenv(func, restricted_env) end
  else
    func, err = load(code, "=sandbox", "t", restricted_env)
  end
  if not func then
    return false, "Compile error: " .. tostring(err)
  end

  -- Run with protection
  local packed = {pcall(func)}
  local success = table.remove(packed, 1)

  if not success then
    return false, "Runtime error: " .. tostring(packed[1])
  end

  -- Return what the chunk actually returned, not the pcall wrapper list
  return true, unpack_values(packed)
end

-- Test
print("Safe Sandbox Environment")
print("========================")

local sandbox, restricted_env = create_sandbox()

-- Every expectation below is checked. A sandbox example that prints
-- "completed" while its own probes fail teaches the wrong lesson.
local checks, failures = 0, 0
local function check(label, ok, detail)
  checks = checks + 1
  if ok then
    print(string.format("  [ok  ] %s", label))
  else
    failures = failures + 1
    print(string.format("  [FAIL] %s%s", label, detail and (" -- " .. tostring(detail)) or ""))
  end
end

-- Test 1: Safe code
print("\nTest 1: Safe math operations")
local code1 = [[
  local result = math.sqrt(144)
  print("sqrt(144) =", result)
  return result
]]

local success, result = run_sandboxed(code1, restricted_env)
print(string.format("Success: %s, Result: %s", tostring(success), tostring(result)))
check("safe code runs and returns 12", success and result == 12, result)

-- Test 2: Attempt to access dangerous function
print("\nTest 2: Attempt to access os.execute")
local code2 = [[
  return os.execute("echo pwned")
]]

success, result = run_sandboxed(code2, restricted_env)
print(string.format("Success: %s, Error: %s", tostring(success), tostring(result or "N/A")))
check("os.execute is unreachable", not success, result)

-- Test 3: Attempt to access file system
print("\nTest 3: Attempt to access io.open")
local code3 = [[
  local f = io.open("/etc/passwd", "r")
  return f
]]

success, result = run_sandboxed(code3, restricted_env)
print(string.format("Success: %s, Error: %s", tostring(success), tostring(result or "N/A")))
check("io.open is unreachable", not success, result)

-- Test 4: Infinite loop protection (manual timeout needed in production)
print("\nTest 4: Bounded computation")
local code4 = [[
  local sum = 0
  for i = 1, 1000 do
    sum = sum + i
  end
  return sum
]]

success, result = run_sandboxed(code4, restricted_env)
print(string.format("Success: %s, Sum: %s", tostring(success), tostring(result)))
check("bounded computation returns 500500", success and result == 500500, result)

-- Test 5: Table operations
print("\nTest 5: Table operations in sandbox")
local code5 = [[
  local t = {1, 2, 3, 4, 5}
  table.insert(t, 6)
  table.sort(t, function(a, b) return a > b end)
  return table.concat(t, ", ")
]]

success, result = run_sandboxed(code5, restricted_env)
print(string.format("Success: %s, Result: %s", tostring(success), tostring(result)))
check("table operations run inside the sandbox",
  success and result == "6, 5, 4, 3, 2, 1", result)

-- Test 6: Check what's available
print("\nTest 6: Inspecting sandbox contents")
print("Globals reachable from the restricted environment:")
-- The restricted environment is a proxy: its reads and writes resolve to the
-- sandbox table, so that is where the reachable names actually live.
for k, v in pairs(sandbox) do
  if type(v) ~= "table" then
    print(string.format("  %s: %s", k, type(v)))
  else
    -- #v would report 0 here: these tables are keyed by name, so they have
    -- no array part for the length operator to find.
    local count = 0
    for _ in pairs(v) do count = count + 1 end
    print(string.format("  %s: (table with %d entries)", k, count))
  end
end
check("os is not reachable from the sandbox", sandbox.os == nil)
check("io is not reachable from the sandbox", sandbox.io == nil)
check("math is reachable from the sandbox", sandbox.math ~= nil)
check("print is reachable from the sandbox", sandbox.print ~= nil)

print()
if failures == 0 then
  print(string.format("✓ Sandbox tests completed (%d checks)", checks))
else
  print(string.format("✗ Sandbox tests FAILED (%d of %d checks failed)", failures, checks))
end
print("\nNote: Production sandboxing requires additional measures:")
print("  - CPU time limits (via debug hook)")
print("  - Memory limits")
print("  - Careful audit of all exposed functions")
print("  - Version-specific considerations")
