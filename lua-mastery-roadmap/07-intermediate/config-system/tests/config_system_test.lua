-- tests/config_system_test.lua — Unit tests for config system
-- Run from project root with: lua tests/config_system_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/07-intermediate/config-system/?.lua;" .. package.path

local config = require("01-config-system")

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

print("=== Config System Unit Tests ===")

print("\n1. Module structure")
assert_true(type(config) == "table", "Config is table")
assert_true(type(config.load) == "function", "Config has load function")

print("\n2. Load config from file")
-- Create a temp config file
local tmpfile = "/tmp/test_config.ini"
local f = io.open(tmpfile, "w")
f:write("[server]\nhost = 0.0.0.0\nport = 3000\n")
f:close()

local sections = config.load(tmpfile)
assert_true(sections ~= nil, "Config loaded")
assert_eq(sections.server.host, "0.0.0.0", "Server host parsed")
assert_eq(sections.server.port, 3000, "Server port parsed")

-- Cleanup
os.remove(tmpfile)

print("\n3. Schema defaults")
local schema = { server = { host = "default_host", port = 8080 } }
sections = config.load(tmpfile or "/dev/null", schema)
-- Should have defaults applied

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
