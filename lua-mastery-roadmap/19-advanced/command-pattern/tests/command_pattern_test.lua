-- tests/command_pattern_test.lua — Unit tests for command pattern
-- Run from project root with: lua tests/command_pattern_test.lua

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local CommandExecutor = require("01-command-pattern")

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

print("=== Command Pattern Unit Tests ===")

print("\n1. Create executor")
local executor = CommandExecutor.new()
assert_true(executor ~= nil, "Executor created")

print("\n2. Check initial state")
assert_eq(#executor.undoStack, 0, "Empty undo stack")
assert_eq(#executor.redoStack, 0, "Empty redo stack")

print("\n3. Execute command")
local executed = false
local test_cmd = {
  execute = function() executed = true end,
  undo = function() executed = false end,
}
executor:execute(test_cmd)
assert_true(executed, "Command executed")
assert_eq(#executor.undoStack, 1, "Command in undo stack")

print("\n4. Undo command")
executor:undo()
assert_false(executed, "Command undone")
assert_eq(#executor.redoStack, 1, "Command in redo stack")

print("\n5. Redo command")
executor:redo()
assert_true(executed, "Command re-executed")
assert_eq(#executor.undoStack, 1, "Command back in undo stack")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
