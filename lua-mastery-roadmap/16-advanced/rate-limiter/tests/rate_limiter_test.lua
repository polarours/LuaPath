-- tests/rate_limiter_test.lua — Unit tests for rate limiter
-- Run from project root with: lua tests/rate_limiter_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/16-advanced/rate-limiter/?.lua;" .. package.path

local RateLimiter = require("01-rate-limiter")

local pass = 0
local fail = 0
local total = 0

function assert_eq(actual, expected, msg)
  total = total + 1
  if actual == expected then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (expected=" .. tostring(expected) .. ", actual=" .. tostring(actual) .. ")")
  end
end

function assert_true(val, msg)
  total = total + 1
  if val then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (expected true)")
  end
end

print("=== Rate Limiter Unit Tests ===")

print("\n1. Create token bucket")
local tb = RateLimiter.TokenBucket.new({ capacity = 5, refillRate = 1 })
assert_true(tb ~= nil, "Token bucket created")
assert_eq(tb.capacity, 5, "Capacity set")

print("\n2. Allow requests")
local allowed = tb:allow()
assert_true(allowed, "Request allowed")

print("\n3. Check status")
local status = tb:status()
assert_true(status.tokens <= 5, "Token count valid")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
