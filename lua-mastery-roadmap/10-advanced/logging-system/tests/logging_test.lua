-- tests/logging_test.lua — Unit tests for logging system
-- Run from project root with: lua tests/logging_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/10-advanced/logging-system/?.lua;" .. package.path

local Logger = dofile("lua-mastery-roadmap/10-advanced/logging-system/01-logging-system.lua")

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

print("=== Logging System Unit Tests ===")

print("\n1. Create logger")
local log = Logger.new()
assert_true(log ~= nil, "Logger created")
assert_eq(log.level, 1, "Default level is DEBUG")

print("\n2. Set log level")
log:set_level("WARN")
assert_eq(log.level, 3, "Level set to WARN")

print("\n3. Add console handler")
log:add_handler(Logger.handlers.console)
assert_true(#log.handlers > 0, "Handler added")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
