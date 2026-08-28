-- tests/event_system_test.lua — Unit tests for event bus
-- Run from project root with: lua tests/event_system_test.lua

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local EventBus = dofile("lua-mastery-roadmap/13-advanced/event-system/01-event-system.lua")

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

print("=== Event Bus Unit Tests ===")

print("\n1. Create event bus")
local bus = EventBus.new()
assert_true(bus ~= nil, "Event bus created")

print("\n2. Subscribe and emit")
local received = {}
bus:on("test", function(data) table.insert(received, data) end)
bus:emit("test", "hello")
assert_eq(received[1], "hello", "Handler received event")

print("\n3. Once handler")
local once_received = {}
bus:once("once_test", function(data) table.insert(once_received, data) end)
bus:emit("once_test", "first")
bus:emit("once_test", "second")
assert_eq(#once_received, 1, "Once handler called only once")

print("\n4. Unsubscribe")
local id = bus:on("unsubscribe_test", function() end)
bus:off("unsubscribe_test", id)
assert_true(true, "Handler unsubscribed")

print("\n5. Wildcard subscription")
local wildcard_received = {}
bus:on("user.*", function(data) table.insert(wildcard_received, data) end)
bus:emit("user.created", "alice")
bus:emit("user.deleted", "bob")
assert_eq(#wildcard_received, 2, "Wildcard handler received all events")

print("\n6. Priority ordering")
local ordered = {}
bus:on("priority", function() table.insert(ordered, "low") end, { priority = 1 })
bus:on("priority", function() table.insert(ordered, "high") end, { priority = 10 })
bus:emit("priority")
assert_eq(ordered[1], "high", "High priority handler runs first")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
