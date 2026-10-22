-- Example 57: Sandbox Escape Attempts
-- Chapter: 17-embedding-patterns
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Case study for Chapter 17: does an allow-list sandbox actually stop
-- escape attempts? We try four known classes of escapes against two
-- sandbox designs and measure how many succeed.
--
-- Demonstrates: _ENV vs _G, pcall(require, ...), metatable-based read-only
-- environments, and why the "naive" design has one known leak vector.

-- 5.1's loadstring() takes an env in 5.2+; 5.1 uses setfenv instead
local function load_chunk(src, chunkname, env)
  local chunk, err
  if loadstring then
    chunk = loadstring(src)
    if chunk then setfenv(chunk, env) end
    err = nil
  else
    chunk, err = load(src, chunkname, "t", env)
  end
  if not chunk then return nil, err end
  return chunk
end

--------------------------------------------------------------------------------
-- Two sandbox designs
--------------------------------------------------------------------------------

-- Naive design: allow-list table, no metatable
local function build_naive_sandbox(allow)
  local env = {}
  for name in pairs(allow) do env[name] = _G[name] end
  return env
end

-- Hardened design: allow-list plus a read-only metatable that rejects
-- new globals, plus no `debug` module
local function build_hardened_sandbox(allow)
  local env = {}
  for name in pairs(allow) do
    if name ~= "debug" then          -- explicit hardening: no introspection
      env[name] = _G[name]
    end
  end
  setmetatable(env, {
    __newindex = function(_, k, _)
      error("write to new global " .. tostring(k) .. " not permitted", 2)
    end,
  })
  return env
end

--------------------------------------------------------------------------------
-- The four escape attempts, each returning (succeeded, description)
--------------------------------------------------------------------------------

local escape_attempts = {

  -- 1. Direct _G read. In 5.1+ Lua, _G is a reference to the real global
  -- table, not the env table the sandbox provides. If it is not in the
  -- allow-list, referencing it should yield nil.
  {
    name = "1. read _G.os",
    code = 'local os = _G.os return os ~= nil and "LEAKED" or "BLOCKED"',
    expected_blocked = true,
  },

  -- 2. pcall(require, ...) for a forbidden module. require is in the
  -- allow-list in the naive design (because it is harmless-looking);
  -- the escape is that it returns an error message when the module is
  -- not on the search path, but it can also return a *value* if a
  -- module happens to exist in LUA_PATH.
  {
    name = "2. pcall(require, 'cjson')",
    code = 'local ok, v = pcall(require, "cjson") return type(v)',
    expected_blocked = false,     -- "blocked" means ok is false; that is *correct* behaviour
  },

  -- 3. Attempt to write a new global through the sandbox env. Naive env
  -- has no __newindex guard, so new globals just get added. Hardened
  -- design should raise an error.
  {
    name = "3. new global assignment",
    code = 'new_global = 42 return "WROTE"',
    expected_blocked = true,
  },

  -- 4. debug.getupvalue introspection. Naive design blocks this by
  -- design (we only allow print/tostring/tonumber/math/string); the
  -- attempt should fail because debug is not in the allow-list.
  {
    name = "4. pcall(debug.getinfo)",
    code = 'local ok = pcall(function() return debug.getinfo() end) return ok',
    expected_blocked = true,
  },

}

--------------------------------------------------------------------------------
-- Run every escape attempt against both designs and report the outcome
--------------------------------------------------------------------------------

local function report(label, design_name, allow, build)
  print(string.rep("-", 60))
  print(string.format("Design: %s (%s)", label, design_name))
  print(string.rep("-", 60))

  local sandbox = build(allow)
  local blocked, leaked, total = 0, 0, #escape_attempts

  for _, attempt in ipairs(escape_attempts) do
    local chunk, load_err = load_chunk(attempt.code, attempt.name, sandbox)
    local ok, result
    if chunk then
      ok, result = pcall(chunk)
    end
    local reason = chunk and tostring(result) or ("compile: " .. tostring(load_err))

    -- For each attempt, classify the outcome as "blocked" (good) or "leaked"
    -- based on the return value and the attempt's expected_blocked flag.
    local is_blocked
    if attempt.expected_blocked then
      -- We expect these to fail. "Blocked" means they actually failed.
      is_blocked = (not ok) or (result ~= "LEAKED" and result ~= "WROTE")
    else
      -- We expect these to succeed (a correct "not found" error).
      is_blocked = (ok and type(result) == "string" and result ~= "WROTE")
    end

    if is_blocked then
      blocked = blocked + 1
      print(string.format("  [BLOCKED] %-26s -> %s", attempt.name, reason))
    else
      leaked = leaked + 1
      print(string.format("  [LEAKED ] %-26s -> %s", attempt.name, reason))
    end
  end

  print(string.rep("-", 60))
  print(string.format("%s: %d/%d escape attempts blocked", design_name, blocked, total))
  print(string.rep("-", 60))
  print()
  return blocked, total
end

--------------------------------------------------------------------------------
-- Baseline: naive design
--------------------------------------------------------------------------------

local naive_allow = {
  print = true, tostring = true, tonumber = true,
  pcall = true,                 -- core error-handling primitive; sandboxes keep it
  type = true,
  math = true, string = true,
  require = true,  -- intentionally present, since the escape is its *use*
}

local naive_blocked, naive_total =
  report("naive allow-list", "naive", naive_allow, build_naive_sandbox)

--------------------------------------------------------------------------------
-- Hardened: no debug, read-only env
--------------------------------------------------------------------------------

-- Give the hardened design a broader allow-list that INCLUDES `debug`; the
-- build function then filters it out, proving the filter actually removes it.
local hardened_allow = {
  print = true, tostring = true, tonumber = true,
  pcall = true,
  type = true,
  math = true, string = true,
  require = true,
  debug = true,                -- requested by (untrusted) script, filtered out
}

local hardened_blocked, hardened_total =
  report("hardened (readonly + no debug)", "hardened", hardened_allow,
    build_hardened_sandbox)

--------------------------------------------------------------------------------
-- Compare and exit
--------------------------------------------------------------------------------

print("Comparison")
print("----------")
print(string.format("naive    : %d/%d blocked", naive_blocked, naive_total))
print(string.format("hardened : %d/%d blocked", hardened_blocked, hardened_total))

-- Hardened design must block at least as many attempts as the naive design.
-- This is the invariant the case study exists to document.
assert(hardened_blocked >= naive_blocked,
  "hardened sandbox blocked fewer attempts than naive -- invariant violated")

print()
print("Invariant holds: hardening did not weaken the sandbox.")
print("CASE STUDY OK")
