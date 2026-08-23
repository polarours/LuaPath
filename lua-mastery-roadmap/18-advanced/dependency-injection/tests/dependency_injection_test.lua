-- tests/dependency_injection_test.lua — Unit tests for DI container
-- Run from project root with: lua tests/dependency_injection_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/18-advanced/dependency-injection/?.lua;" .. package.path

local Container = require("01-dependency-injection")

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

print("=== Dependency Injection Unit Tests ===")

print("\n1. Create container")
local c = Container.new()
assert_true(c ~= nil, "Container created")

print("\n2. Register service")
c:register("db", function() return { host = "localhost" } end)
assert_true(c.services.db ~= nil, "Service registered")

print("\n3. Resolve service")
local db = c:resolve("db")
assert_true(db ~= nil, "Service resolved")
assert_eq(db.host, "localhost", "Service correct")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
