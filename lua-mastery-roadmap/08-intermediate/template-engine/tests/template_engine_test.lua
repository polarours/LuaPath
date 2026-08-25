-- tests/template_engine_test.lua — Unit tests for template engine
-- Run from project root with: lua tests/template_engine_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/08-intermediate/template-engine/?.lua;" .. package.path

local template = require("01-template-engine")

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

print("=== Template Engine Unit Tests ===")

print("\n1. Simple variable substitution")
local result = template.render("Hello {{name}}!", { name = "World" })
assert_eq(result, "Hello World!", "Variable substituted")

print("\n2. Multiple variables")
result = template.render("{{greeting}} {{name}}", { greeting = "Hello", name = "Lua" })
assert_eq(result, "Hello Lua", "Multiple variables substituted")

print("\n3. Conditional rendering")
result = template.render("{%%if show%%}visible{%%endif%%}", { show = true })
assert_true(result ~= "", "Conditional rendered when true")

print("\n4. Empty context")
result = template.render("static text")
assert_eq(result, "static text", "Static text unchanged")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
