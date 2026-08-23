-- tests/observer_pattern_test.lua — Unit tests for observer pattern
-- Run from project root with: lua tests/observer_pattern_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/20-advanced/observer-pattern/?.lua;" .. package.path

local Observable = require("01-observer-pattern")

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

print("=== Observer Pattern Unit Tests ===")

print("\n1. Create observable")
local obs = Observable.new()
assert_true(obs ~= nil, "Observable created")

print("\n2. Subscribe with observer object")
local received = {}
local observer = {
  onEvent = function(self, event, data)
    table.insert(received, { event = event, data = data })
  end
}
local id = obs:subscribe(observer)
assert_true(id > 0, "Subscription ID returned")
obs:notify("test", "hello")
assert_eq(received[1].event, "test", "Event received")
assert_eq(received[1].data, "hello", "Data received")

print("\n3. Unsubscribe")
obs:unsubscribe(id)
local before = #received
obs:notify("test", "world")
assert_eq(#received, before, "No new events after unsubscribe")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
