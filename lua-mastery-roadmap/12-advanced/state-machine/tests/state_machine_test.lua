-- tests/state_machine_test.lua — Unit tests for FSM
-- Run from project root with: lua tests/state_machine_test.lua

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local FSM = dofile("lua-mastery-roadmap/12-advanced/state-machine/01-state-machine.lua")

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

print("=== FSM Unit Tests ===")

print("\n1. Create FSM")
local fsm = FSM.new("TrafficLight")
assert_true(fsm ~= nil, "FSM created")

print("\n2. Add states")
fsm:add_state("green")
fsm:add_state("yellow")
fsm:add_state("red")
assert_true(fsm._states.green ~= nil, "Green state added")

print("\n3. Add transitions")
fsm:add_transition("green", "yellow", "timer")
fsm:add_transition("yellow", "red", "timer")
fsm:add_transition("red", "green", "timer")
assert_true(fsm._transitions.green.timer ~= nil, "Transition added")

print("\n4. Set initial state")
fsm:set_initial("green")
assert_eq(fsm._current, "green", "Initial state set")

print("\n5. Fire transition")
local result = fsm:fire("timer")
assert_true(result, "Transition fired")
assert_eq(fsm._current, "yellow", "State changed to yellow")

print("\n6. Invalid transition")
result = fsm:fire("invalid")
assert_false(result, "Invalid transition rejected")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
