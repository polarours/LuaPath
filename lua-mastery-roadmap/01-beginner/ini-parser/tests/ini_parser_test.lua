-- tests/ini_parser_test.lua — Unit tests for INI parser
-- Run from project root with: lua lua-mastery-roadmap/01-beginner/ini-parser/tests/ini_parser_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/01-beginner/ini-parser/?.lua;" .. package.path

local ini_module = require("01-ini-parser")
local parse_ini = ini_module.parse_ini

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

function assert_error(fn, msg)
  total = total + 1
  local ok = pcall(fn)
  if not ok then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (expected error)")
  end
end

print("=== INI Parser Unit Tests ===")

print("\n1. Parse simple section")
local result = parse_ini("[database]\nhost = localhost\nport = 5432")
assert_eq(result.database.host, "localhost", "Database host")
assert_eq(result.database.port, "5432", "Database port")

print("\n2. Parse multiple sections")
result = parse_ini("[server]\nhost = 0.0.0.0\n\n[database]\nhost = localhost")
assert_eq(result.server.host, "0.0.0.0", "Server host")
assert_eq(result.database.host, "localhost", "Database host")

print("\n3. Parse nested sections")
result = parse_ini("[app.nested]\nlevel1 = value1\nlevel2 = value2")
assert_eq(result.app.nested.level1, "value1", "Nested level1")
assert_eq(result.app.nested.level2, "value2", "Nested level2")

print("\n4. Skip comments")
result = parse_ini("# This is a comment\n[section]\nkey = value")
assert_eq(result.section.key, "value", "Key after comment")

print("\n5. Skip empty lines")
result = parse_ini("\n\n[section]\nkey = value")
assert_eq(result.section.key, "value", "Key after empty lines")

print("\n6. Parse with semicolon comments")
result = parse_ini("; comment\n[section]\nkey = value")
assert_eq(result.section.key, "value", "Key after semicolon comment")

print("\n7. Handle whitespace")
result = parse_ini("[section]\n  key   =   value  ")
assert_eq(result.section.key, "value", "Value trimmed")

print("\n8. Error on key outside section")
assert_error(function() parse_ini("key = value") end, "Error on key outside section")

print("\n9. Error on empty section name")
assert_error(function() parse_ini("[]\nkey = value") end, "Error on empty section")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
