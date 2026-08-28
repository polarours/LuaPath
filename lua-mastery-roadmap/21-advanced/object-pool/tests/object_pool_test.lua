-- tests/object_pool_test.lua — Unit tests for object pool
-- Run from project root with: lua tests/object_pool_test.lua

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local Pool = require("01-object-pool")

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

print("=== Object Pool Unit Tests ===")

print("\n1. Create pool")
local pool = Pool.new(function() return { id = math.random() } end, { max_size = 5 })
assert_true(pool ~= nil, "Pool created")

print("\n2. Acquire object")
local obj = pool:acquire()
assert_true(obj ~= nil, "Object acquired")
assert_true(obj.id ~= nil, "Object has id")

print("\n3. Return object")
pool:release(obj)
assert_true(#pool.pool > 0, "Object returned to pool")

print("\n4. Reuse object")
local obj2 = pool:acquire()
assert_true(obj2 == obj, "Same object reused")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
