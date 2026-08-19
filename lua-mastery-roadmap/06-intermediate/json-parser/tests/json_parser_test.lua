-- tests/json_parser_test.lua — Unit tests for JSON parser
-- Run from project root with: lua tests/json_parser_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/06-intermediate/json-parser/?.lua;" .. package.path

local json = require("01-json-parser")

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

function assert_table(actual, expected, msg)
  total = total + 1
  if type(actual) == "table" and type(expected) == "table" then
    local match = true
    for k, v in pairs(expected) do
      if actual[k] ~= v then
        match = false
        break
      end
    end
    if match then
      pass = pass + 1
    else
      fail = fail + 1
      print("FAIL: " .. msg)
    end
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (type mismatch)")
  end
end

print("=== JSON Parser Unit Tests ===")

print("\n1. Parse null")
local result = json.decode("null")
assert_true(result == nil, "null parses to nil")

print("\n2. Parse boolean true")
result = json.decode("true")
assert_true(result == true, "true parses correctly")

print("\n3. Parse boolean false")
result = json.decode("false")
assert_true(result == false, "false parses correctly")

print("\n4. Parse number (integer)")
result = json.decode("42")
assert_eq(result, 42, "Integer parses correctly")

print("\n5. Parse number (float)")
result = json.decode("3.14")
assert_eq(result, 3.14, "Float parses correctly")

print("\n6. Parse string")
result = json.decode('"hello"')
assert_eq(result, "hello", "String parses correctly")

print("\n7. Parse string with escape")
result = json.decode('"hello\\nworld"')
assert_eq(result, "hello\nworld", "Escaped string parses correctly")

print("\n8. Parse empty object")
result = json.decode("{}")
assert_table(result, {}, "Empty object")

print("\n9. Parse empty array")
result = json.decode("[]")
assert_table(result, {}, "Empty array")

print("\n10. Parse object with values")
result = json.decode('{"x":1,"y":2}')
assert_true(result.x == 1, "Object x value")
assert_true(result.y == 2, "Object y value")

print("\n11. Parse array with values")
result = json.decode('[1,2,3]')
assert_true(result[1] == 1, "Array first element")
assert_true(result[2] == 2, "Array second element")
assert_true(result[3] == 3, "Array third element")

print("\n12. Parse nested structure")
result = json.decode('{"a":[1,2],"b":{"c":3}}')
assert_true(result.a[1] == 1, "Nested array access")
assert_true(result.b.c == 3, "Nested object access")

print("\n13. Parse negative number")
result = json.decode("-42")
assert_eq(result, -42, "Negative number")

print("\n14. Parse zero")
result = json.decode("0")
assert_eq(result, 0, "Zero parses correctly")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
