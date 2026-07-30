-- correctness_test.lua — Test vector operations for correctness
-- Run from project root with: lua lua-mastery-roadmap/42-performance/simd-patterns/tests/correctness_test.lua

-- Add parent directory to module path
package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/42-performance/simd-patterns/?.lua;" .. package.path

local Vector = require("vector_ops")

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
  assert_eq(val, true, msg)
end

print("=== Vector Correctness Tests ===")

print("\n1. Vector addition")
local v1 = Vector.new(1, 2, 3)
local v2 = Vector.new(4, 5, 6)
local v3 = Vector.add(v1, v2)
assert_eq(#v3, 3, "Result length correct")
assert_eq(v3[1], 5, "v1[1] + v2[1]")
assert_eq(v3[2], 7, "v1[2] + v2[2]")
assert_eq(v3[3], 9, "v1[3] + v2[3]")

print("\n2. Dot product")
local a = Vector.new(1, 2, 3)
local b = Vector.new(4, 5, 6)
local dot = Vector.dot(a, b)
assert_eq(dot, 32, "Dot product: 1*4 + 2*5 + 3*6 = 32")

print("\n3. Vector scale")
local v = Vector.new(1, 2, 3)
local scaled = Vector.scale(v, 2)
assert_eq(scaled[1], 2, "Scale by 2")
assert_eq(scaled[2], 4, "Scale by 2")
assert_eq(scaled[3], 6, "Scale by 2")

print("\n4. Vector map")
local nums = Vector.new(1, 2, 3, 4, 5)
local doubled = Vector.map(function(x) return x * 2 end, nums)
assert_eq(doubled[1], 2, "Map: 1*2")
assert_eq(doubled[5], 10, "Map: 5*2")

print("\n5. Edge cases")
local zero = Vector.new(0, 0, 0)
local neg = Vector.new(-1, -2, -3)
assert_eq(Vector.dot(zero, neg), 0, "Zero vector dot product")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
