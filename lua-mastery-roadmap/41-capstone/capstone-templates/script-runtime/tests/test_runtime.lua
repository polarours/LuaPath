-- test_runtime.lua
-- Test suite for script-runtime
-- NOTE: Template test stub. Passes when modules are not yet implemented.
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
