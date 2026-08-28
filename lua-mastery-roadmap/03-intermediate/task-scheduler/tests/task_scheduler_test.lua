-- tests/task_scheduler_test.lua — Unit tests for task scheduler
-- Run from project root with: lua tests/task_scheduler_test.lua

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local Scheduler = require("03-task-scheduler")

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

print("=== Task Scheduler Unit Tests ===")

print("\n1. Create scheduler")
local s = Scheduler.new()
assert_true(s ~= nil, "Scheduler created")
assert_eq(type(s.tasks), "table", "Tasks table is table")
assert_eq(s.next_id, 1, "Initial next_id is 1")
assert_eq(s.running, false, "Initial running is false")

print("\n2. Spawn task")
local id = s:spawn(function() end)
assert_true(id > 0, "Task spawned with positive id")
assert_eq(s.next_id, 2, "next_id incremented")

print("\n3. Run task (immediate completion)")
s.running = true
s:_step(nil)
-- Empty task completes immediately, so it's removed
assert_eq(s.tasks[id], nil, "Completed task removed")

print("\n4. Spawn and cancel task")
local id2 = s:spawn(function() coroutine.yield() end)
assert_true(s.tasks[id2] ~= nil, "Task exists after spawn")
s:cancel(id2)
assert_true(s.tasks[id2].cancelled, "Task marked as cancelled")

print("\n5. Cancelled task is removed on step")
s:_step(nil)
assert_eq(s.tasks[id2], nil, "Cancelled task removed after step")

print("\n6. Spawn task with sleep")
local id3 = s:spawn(function()
  Scheduler.sleep(10)
end)
assert_true(s.tasks[id3] ~= nil, "Sleeping task exists")
s:_step(nil)
-- Task should still exist (sleeping)
assert_true(s.tasks[id3] ~= nil, "Sleeping task persists")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
