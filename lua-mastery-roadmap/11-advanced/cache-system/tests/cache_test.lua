-- tests/cache_test.lua — Unit tests for LRU cache system
-- Run from project root with: lua tests/cache_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/11-advanced/cache-system/?.lua;" .. package.path

local LRUCache = dofile("lua-mastery-roadmap/11-advanced/cache-system/01-cache-system.lua")

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

function assert_false(val, msg)
  total = total + 1
  if not val then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (expected false)")
  end
end

print("=== LRU Cache Unit Tests ===")

print("\n1. Create cache")
local cache = LRUCache.new({ max = 3 })
assert_true(cache ~= nil, "Cache created")

print("\n2. Set and get")
cache:set("a", 1)
assert_eq(cache:get("a"), 1, "Get set value")
assert_eq(cache:get("b"), nil, "Get missing key")

print("\n3. Capacity limit")
cache:set("b", 2)
cache:set("c", 3)
cache:set("d", 4)  -- should evict "a"
assert_eq(cache:get("a"), nil, "Oldest key evicted")
assert_eq(cache:get("d"), 4, "Newest key present")

print("\n4. Access updates recency")
cache:set("a", 1)  -- re-add a
cache:get("a")     -- access a, making it most recent
cache:set("b", 2)
cache:set("c", 3)
cache:set("d", 4)  -- should evict "b" (least recent)
assert_eq(cache:get("b"), nil, "Least recently used evicted")

print("\n5. Stats tracking")
local cache2 = LRUCache.new({ max = 2 })
cache2:set("x", 1)
cache2:get("x")    -- hit
cache2:get("y")    -- miss
assert_true(cache2._hits >= 1, "Hit count tracked")
assert_true(cache2._misses >= 1, "Miss count tracked")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
