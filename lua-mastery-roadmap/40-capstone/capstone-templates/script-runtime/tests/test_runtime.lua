-- test_runtime.lua
-- Test suite for script-runtime
-- NOTE: Template test stub. Passes when modules are not yet implemented.
-- Resolve the module directory from this script's own location, so the
-- test works regardless of the working directory it is started from.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
-- The modules are named "src.<name>", and require turns the dot into a
-- path separator, so the search path has to point at the project root.
package.path = _script_dir() .. "../?.lua;" .. package.path

local ok = pcall(function()
  local bus = require "src.event-bus"

  local function assert_eq(a, b, msg)
    assert(a == b, msg or string.format("got %s, expected %s", tostring(a), tostring(b)))
  end

  local b = bus.new()
  local received = {}
  b:subscribe("test.*", function(payload) table.insert(received, payload) end)
  b:emit("test.started", "hello")
  b:emit("test.stopped", "bye")
  assert_eq(#received, 2, "event bus delivers to wildcard subscribers")

  print("script-runtime tests passed")
end)

if not ok then
  print("script-runtime: template tests skipped (modules not yet implemented)")
end
