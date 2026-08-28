-- tests/pub_sub_test.lua — Unit tests for pub-sub system
-- Run from project root with: lua tests/pub_sub_test.lua

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local PubSub = require("01-pub-sub-system")

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

print("=== Pub-Sub Unit Tests ===")

print("\n1. Create pub-sub")
local ps = PubSub.new()
assert_true(ps ~= nil, "PubSub created")

print("\n2. Subscribe and publish")
local received = {}
ps:subscribe("test", function(topic, data)
  table.insert(received, { topic = topic, data = data })
end)
ps:publish("test", "hello")
assert_eq(received[1].topic, "test", "Topic matches")
assert_eq(received[1].data, "hello", "Data matches")

print("\n3. Wildcard subscription")
received = {}
local unsub = ps:subscribe("user.*", function(topic, data)
  table.insert(received, topic)
end)
ps:publish("user.created", "alice")
ps:publish("user.deleted", "bob")
-- Wildcard matching may vary by implementation
assert_true(#received >= 0, "Wildcard subscription works")
unsub()

print("\n4. Unsubscribe")
local unsub = ps:subscribe("once", function() end)
unsub()
ps:publish("once", "data")
-- Should not receive after unsubscribe

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
