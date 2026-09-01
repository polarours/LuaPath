#!/usr/bin/env lua
-- script.lua — Lua script that drives the embed_lua C host
-- Run: ./embed_lua  (the C program loads and runs this script)
--
-- This script exercises every host API exposed by embed-lua.c:
--   host.log(level, msg)     — structured logger
--   host.time()              — host monotonic clock
--   host.Counter([init])     — userdata counter with inc()/get()
--   host.malloc(size)        — allocate memory from the host heap
--   host.free(ptr)           — free host-allocated memory

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(msg .. string.format(": got %s, expected %s", tostring(actual), tostring(expected)), 2)
  end
end

-- ============================================================
-- host.log — structured logging
-- ============================================================
host.log("INFO", "script.lua: host API test starting")

-- ============================================================
-- host.Counter userdata
-- ============================================================
local c = host.Counter(10)
assert_eq(c:get(), 10, "Counter initial value")

-- __call = inc, so c() increments
local ok, res = pcall(function() return c(5) end)
assert_eq(res, 15, "Counter after inc(5)")

-- :inc() also works explicitly
c:inc(3)
assert_eq(c:get(), 18, "Counter after second inc(3)")

-- tostring via __tostring metatable
local s = tostring(c)
assert(s:match("Counter%(%d+%)"), "Counter __tostring format")

-- type error for non-numeric init
local ok2, err2 = pcall(host.Counter, "not a number")
assert(not ok2, "Counter should reject non-numeric init")

host.log("INFO", "Counter API: all assertions passed")

-- ============================================================
-- host.time — monotonic clock
-- ============================================================
local t = host.time()
assert(type(t) == "number", "host.time() must return a number")
assert(t >= 0, "host.time() must be non-negative")
host.log("INFO", string.format("host.time(): %.6f", t))

-- ============================================================
-- host.malloc / host.free — memory allocation
-- ============================================================
local ptr = host.malloc(64)
assert(ptr ~= nil, "host.malloc(64) should succeed")
host.log("INFO", "host.malloc(64) -> " .. tostring(ptr))

host.free(ptr)
host.log("INFO", "host.free(ptr): ok")

-- malloc(0) is implementation-defined; just make sure it doesn't crash
local ptr2 = host.malloc(0)
host.free(ptr2)  -- free NULL/nil is safe
host.log("INFO", "host.malloc(0) edge case: handled")

-- ============================================================
-- Error propagation across Lua/C boundary
-- ============================================================
local ok3, err3 = pcall(function()
  error("deliberate error from Lua side")
end)
assert(not ok3, "pcall should catch Lua errors")
host.log("WARN", "Lua error correctly caught: " .. tostring(err3))

-- ============================================================
-- Summary
-- ============================================================
host.log("INFO", "All host API tests passed")
print("=== script.lua: PASSED ===")
