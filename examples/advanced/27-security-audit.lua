-- Example 59: Security Audit for Lua Code
-- Chapter: 18-security-in-lua
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Companion example for Chapter 18. Each control below is exercised against a
-- real attempt, and the outcome is reported for the runtime doing the work --
-- notably, the bytecode guard needs a *different* mechanism on Lua 5.1 than on
-- 5.2+, and this file measures that rather than assuming it.
--
-- Demonstrates: bytecode loading rejection, sandboxed _ENV with write guard,
-- unreachable dangerous globals, payload size limits, resource guards, and
-- error hygiene in xpcall handlers.

local function section(title)
  print()
  print(string.rep("=", 64))
  print(title)
  print(string.rep("=", 64))
end

local checks = 0
local function check(label, ok)
  checks = checks + 1
  print(string.format("  %s %s", ok and "[ok  ]" or "[FAIL]", label))
  if not ok then error("check failed: " .. label) end
end

local HAS_LOADSTRING = loadstring ~= nil
print("runtime: " .. _VERSION .. (jit and (" / " .. (jit.version or "LuaJIT")) or ""))

--------------------------------------------------------------------------------
-- Control 1: reject precompiled bytecode
--------------------------------------------------------------------------------

section("1. Reject precompiled bytecode")

local bytecode = string.dump(function() return 1 end)
print(string.format("  first byte = %d (ESC=27 => it IS bytecode)",
  string.byte(bytecode, 1)))

-- 5.2+: load accepts a `mode` argument. Measured behaviour:
--   Lua 5.4  rejects bytecode with mode="t"
--   LuaJIT   rejects bytecode with mode="t" (mode is honoured)
--   Lua 5.1  has NO mode argument -- the extra argument is ignored and the
--            bytecode loads happily, which is the reason the byte check exists.
local mode_rejects = false
local mode_err
if HAS_LOADSTRING then
  local chunk = loadstring(bytecode, "=probe", "t")
  mode_rejects = (chunk == nil)
  if not chunk then mode_err = select(2, loadstring(bytecode, "=probe", "t")) end
else
  local chunk, err = load(bytecode, "=probe", "t")
  mode_rejects = (chunk == nil)
  mode_err = err
end

if mode_rejects then
  print("  mode=\"t\" rejected it: " .. tostring(mode_err))
else
  print("  mode=\"t\" was NOT available or NOT honoured on this runtime")
end

-- The portable guard: bytecode always starts with ESC (27).
local function is_bytecode(src)
  return type(src) == "string" and src:byte(1) == 27
end

check("the byte-1 guard identifies the bytecode", is_bytecode(bytecode))
check("the byte-1 guard does not flag ordinary source",
  not is_bytecode("return 1"))

local function guarded_load(src, name)
  if is_bytecode(src) then
    return nil, "bytecode rejected: precompiled chunks are not accepted"
  end
  if HAS_LOADSTRING then
    return loadstring(src, name)
  end
  return load(src, name, "t", nil)
end

local a, a_err = guarded_load(bytecode, "=evil")
check("guarded_load rejects bytecode", a == nil and tostring(a_err):find("rejected") ~= nil)
local b = guarded_load("return 1 + 1", "=good")
check("guarded_load still accepts source", b ~= nil and b() == 2)

--------------------------------------------------------------------------------
-- Control 2: sandbox with a write guard
--------------------------------------------------------------------------------

section("2. Sandbox with an _ENV write guard")

local ALLOWED = { "print", "tostring", "tonumber", "type", "string", "table", "pcall" }

local function build_sandbox()
  local env = {}
  for _, name in ipairs(ALLOWED) do
    if _G[name] ~= nil then env[name] = _G[name] end
  end
  -- any attempt to create a NEW global inside the sandbox raises
  setmetatable(env, {
    __newindex = function(_, key)
      error("sandbox: write to '" .. tostring(key) .. "' denied", 2)
    end,
    -- reads of unknown names fall through to rawget(env) => nil, never to _G
    __index = function() return nil end,
  })
  return env
end

local function sandbox_load(src, name)
  local env = build_sandbox()
  local chunk, err
  if HAS_LOADSTRING then
    chunk, err = loadstring(src, name)
    if chunk then
      if setfenv then setfenv(chunk, env) end
    end
  else
    chunk, err = load(src, name, "t", env)
  end
  if not chunk then return nil, err end
  return chunk, env
end

-- 2a. reading a dangerous global must yield nil, so type() reports "nil"
local c1 = sandbox_load("return type(os)", "=t1")
check("sandbox cannot see `os`", c1 ~= nil and c1() == "nil")

local c2 = sandbox_load("return type(io), type(debug), type(require)", "=t2")
if c2 then
  local t1, t2, t3 = c2()
  check("sandbox cannot see io/debug/require",
    t1 == "nil" and t2 == "nil" and t3 == "nil")
  print(string.format("    type(io)=%s type(debug)=%s type(require)=%s",
    tostring(t1), tostring(t2), tostring(t3)))
else
  check("sandbox chunk compiles", false)
end

-- 2b. writing a new global must raise
local c3, c3err = sandbox_load("sneaky_global = 123 return sneaky_global", "=t3")
check("sandbox chunk compiles", c3 ~= nil)
local wrote = c3 ~= nil and pcall(c3) == true
check("sandbox rejects writes to new globals", not wrote)
if not c3 then print("    compile error: " .. tostring(c3err)) end

-- 2c. reading _G / _ENV must not lead back to the real globals
local c4, c4err = sandbox_load("return type(_G), type(_ENV)", "=t4")
check("sandbox chunk compiles", c4 ~= nil)
if c4 then
  local g1, g2 = c4()
  check("_G is not the real global table inside the sandbox", g1 ~= "table")
  print(string.format("    _G = %s, _ENV = %s", tostring(g1), tostring(g2)))
else
  print("    compile error: " .. tostring(c4err))
end

--------------------------------------------------------------------------------
-- Control 3: payload limits before loading
--------------------------------------------------------------------------------

section("3. Payload size limits (guard before you parse)")

local MAX_SOURCE_BYTES = 64 * 1024

local function guarded_load_size(src, name)
  if type(src) ~= "string" then
    return nil, "source must be a string"
  end
  if #src > MAX_SOURCE_BYTES then
    return nil, string.format("source too large: %d bytes (max %d)",
      #src, MAX_SOURCE_BYTES)
  end
  if is_bytecode(src) then
    return nil, "bytecode rejected"
  end
  if HAS_LOADSTRING then return loadstring(src, name) end
  return load(src, name, "t", nil)
end

-- Valid Lua: `return` must be the last statement of a block, so pad with
-- comment lines rather than repeating a return statement.
local small = string.rep("-- padding line\n", 100) .. "return 1\n"
local small_chunk = guarded_load_size(small, "=s1")
check("a payload under the limit loads",
  small_chunk ~= nil and small_chunk() == 1)

local big = string.rep("x", MAX_SOURCE_BYTES + 1)
local big_ok, big_err = guarded_load_size(big, "=big")
check("a payload over the limit is refused before parsing",
  big_ok == nil and tostring(big_err):find("too large") ~= nil)

check("non-string payloads are refused",
  select(1, guarded_load_size({ "not", "source" }, "=t")) == nil)

--------------------------------------------------------------------------------
-- Control 4: resource guard against repetition bombs
--------------------------------------------------------------------------------

section("4. Resource guard (repetition)")

-- string.rep("x", 1e9) really would try to allocate a gigabyte. The point is
-- that the guard runs BEFORE the call: no allocation happens for an attempt
-- that is refused.
local MAX_REPEAT = 1024 * 1024

local function safe_rep(s, count)
  if count > MAX_REPEAT then
    return nil, string.format("repeat count %d exceeds limit %d", count, MAX_REPEAT)
  end
  return string.rep(s, count)
end

local ok_small = safe_rep("x", 1024)
check("a bounded repetition succeeds", ok_small ~= nil and #ok_small == 1024)

local bomb_ok, bomb_err = safe_rep("x", 1000000000)
check("a repetition bomb is refused without allocating",
  bomb_ok == nil and tostring(bomb_err):find("exceeds limit") ~= nil)

--------------------------------------------------------------------------------
-- Control 5: error hygiene
--------------------------------------------------------------------------------

section("5. Error hygiene (do not leak internals)")

local function handler(err)
  -- Return something a caller may see. Deliberately does NOT include the
  -- original message, which could carry file paths, stack traces or user input.
  return "internal error: an unexpected condition occurred"
end

local ok, surfaced = xpcall(function()
  error("/home/user/private/config.lua: nil value (field 'secret_key')")
end, handler)

check("xpcall caught the failure", ok == false)
check("the surfaced message is generic", surfaced == "internal error: an unexpected condition occurred")
check("no filesystem path leaked into it",
  tostring(surfaced):find("/home", 1, true) == nil)
check("no original message text leaked", tostring(surfaced):find("secret_key", 1, true) == nil)

-- The contrast: what a bare pcall would have exposed.
local _, raw = pcall(function()
  error("/home/user/private/config.lua: nil value (field 'secret_key')")
end)
print("    raw pcall message: " .. tostring(raw))
check("the raw message did leak the path", tostring(raw):find("/home", 1, true) ~= nil)

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------

print()
print(string.rep("=", 64))
print(string.format("All %d checks passed.", checks))
print(string.rep("=", 64))
print("SECURITY AUDIT OK")
