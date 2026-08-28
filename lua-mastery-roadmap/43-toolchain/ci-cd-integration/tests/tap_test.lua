-- tests/tap_test.lua — Test the TAP reporter implementation
-- Run from project root with: lua tests/tap_test.lua

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../src/?.lua;" .. package.path


local TAP = require("tap")

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

function assert_contains(str, substr, msg)
  total = total + 1
  if str:find(substr, 1, true) then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (substring '" .. substr .. "' not found in '" .. str .. "')")
  end
end

print("=== TAP Reporter Tests ===")

print("\n1. Basic TAP format (test)")
local tap = TAP.new()
local output = {}
local original_print = print
print = function(s) table.insert(output, s) end
tap:pass("test-example")
print = original_print
assert_contains(table.concat(output, "\n"), "ok 1 - test-example", "TAP ok line format correct")

print("\n2. Done with plan")
local tap2 = TAP.new():plan(3)
local output2 = {}
print = function(s) table.insert(output2, s) end
tap2:pass("one")
tap2:pass("two")
tap2:pass("three")
tap2:done()
print = original_print
assert_contains(table.concat(output2, "\n"), "1..3", "Plan line present")
assert_contains(table.concat(output2, "\n"), "# Passed: 3, Failed: 0", "Summary line")

print("\n3. Fail reporting")
local tap3 = TAP.new()
local output3 = {}
print = function(s) table.insert(output3, s) end
tap3:fail("failed-test", "reason provided")
print = original_print
assert_contains(table.concat(output3, "\n"), "not ok", "not ok line")
assert_contains(table.concat(output3, "\n"), "reason provided", "Reason in comment")

print("\n4. Skip reporting")
local tap4 = TAP.new()
local output4 = {}
print = function(s) table.insert(output4, s) end
tap4:skip("test-to-skip", "skipped intentionally")
print = original_print
assert_contains(table.concat(output4, "\n"), "skip", "skip line present")

print("\n5. Pass tracking")
local tap5 = TAP.new():plan(2)
tap5:pass("first")
tap5:pass("second")
local done = tap5:done()
assert_true(done, "Done returns true when no failures")
assert_eq(tap5.passed, 2, "Passed count correct")
assert_eq(tap5.failed, 0, "Failed count zero")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
