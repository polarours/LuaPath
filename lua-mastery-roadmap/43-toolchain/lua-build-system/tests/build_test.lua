-- tests/build_test.lua — Test the build system implementation
-- Run from project root with: lua lua-mastery-roadmap/43-toolchain/lua-build-system/tests/build_test.lua

-- Add module path
package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/43-toolchain/lua-build-system/src/?.lua;" .. package.path

local Build = require("build")  -- The file is src/build.lua

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

function assert_error(fn, msg)
  total = total + 1
  local ok, err = pcall(fn)
  if not ok then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (expected error, got no error)")
  end
end

print("=== Build System Tests ===")

print("\n1. Basic task registration")
local b = Build.new()
b:task("hello", {}, function() return "Hello" end)
assert_true(b.tasks["hello"] ~= nil, "Task registered")
assert_eq(b.tasks["hello"].name, "hello", "Task name correct")

print("\n2. Single task execution")
local result = b:execute("hello")
assert_eq(result, "Hello", "Task returns expected value")

print("\n3. Chain of dependencies")
local b2 = Build.new()
b2:task("step1", {}, function() return 1 end)
b2:task("step2", {"step1"}, function() return 2 end)
b2:task("step3", {"step2"}, function() return 3 end)
assert_eq(b2:execute("step3"), 3, "Final step in chain returns 3")

print("\n4. Topological order")
local b3 = Build.new()
b3:task("A", {})
b3:task("B", {"A"})
b3:task("C", {"B"})
local order = b3:resolve_order()
assert_eq(order[1], "A", "First in topological order")
assert_eq(order[#order], "C", "Last in topological order")

print("\n5. Error handling")
local b4 = Build.new()
b4:task("fail", {}, function() error("intentional fail") end)
assert_error(function() b4:execute("fail") end, "Task failure throws error")

print("\n6. Cycle detection")
local b5 = Build.new()
b5:task("cycle_a", {"cycle_b"}, function() end)
b5:task("cycle_b", {"cycle_a"}, function() end)
assert_error(function() b5:resolve_order() end, "Cycle detection reports error")

print("\n7. Multiple independent chains")
local b6 = Build.new()
b6:task("chain1_a", {}, function() return "a1" end)
b6:task("chain1_b", {"chain1_a"}, function() return "b1" end)
b6:task("chain2_a", {}, function() return "a2" end)
b6:task("chain2_b", {"chain2_a"}, function() return "b2" end)
assert_eq(b6:execute("chain1_b"), "b1", "Chain 1 works")
assert_eq(b6:execute("chain2_b"), "b2", "Chain 2 works")

print("\n8. Task listing")
local tasks = b6:list_tasks()
assert_eq(#tasks, 4, "4 tasks listed")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
