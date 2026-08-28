-- tests/plugin_system_test.lua — Unit tests for plugin system
-- Run from project root with: lua tests/plugin_system_test.lua

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local PluginSystem = require("01-plugin-system")

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

print("=== Plugin System Unit Tests ===")

print("\n1. Create plugin system")
local ps = PluginSystem.new()
assert_true(ps ~= nil, "Plugin system created")

print("\n2. Register plugin")
ps:register({ name = "test", version = "1.0.0" })
assert_true(ps._plugins.test ~= nil, "Plugin registered")
assert_eq(ps._plugins.test.version, "1.0.0", "Plugin version set")

print("\n3. Plugin without name should error")
local ok = pcall(function() ps:register({ version = "1.0" }) end)
assert_false(ok, "Missing name should error")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
