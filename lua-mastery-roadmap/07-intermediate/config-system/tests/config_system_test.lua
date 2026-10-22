-- tests/config_system_test.lua — Unit tests for config system
-- Run from the project directory with: lua tests/config_system_test.lua

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local config = require("01-config-system")

local pass = 0
local fail = 0
local total = 0

local function assert_eq(actual, expected, msg)
  total = total + 1
  if actual == expected then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (expected=" .. tostring(expected) .. ", actual=" .. tostring(actual) .. ")")
  end
end

local function assert_true(val, msg)
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

print("\n3. Schema defaults")
local schema = { server = { host = "default_host", port = 8080 }, cache = { ttl = 60 } }
local with_defaults = config.load(tmpfile, schema)
-- A key the file already has keeps the file's value; a section the file does
-- not have is filled in from the schema.
assert_eq(with_defaults.server.host, "0.0.0.0", "File value wins over the schema default")
assert_eq(with_defaults.cache.ttl, 60, "Schema default fills in a missing section")

-- Cleanup
os.remove(tmpfile)

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
