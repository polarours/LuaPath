-- tests/schema_validator_test.lua — Unit tests for schema validator
-- Run from project root with: lua tests/schema_validator_test.lua

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local Validator = require("01-schema-validator")

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

print("=== Schema Validator Unit Tests ===")

print("\n1. Create validator")
local v = Validator.new()
assert_true(v ~= nil, "Validator created")

print("\n2. Validate string")
v:validateItem("hello", { type = "string" }, "test")
assert_eq(#v.errors, 0, "String valid")

print("\n3. Validate invalid type")
v = Validator.new()
v:validateItem(123, { type = "string" }, "test")
assert_true(#v.errors > 0, "Invalid type caught")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
