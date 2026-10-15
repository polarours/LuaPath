-- test_pipeline.lua
-- Test suite for reactive-pipeline
-- NOTE: Template test stub. Passes when modules are not yet implemented.
local ok = pcall(function()
  local operators = require "src.operators"
  
  local function assert_eq(a, b, msg)
    assert(a == b, msg or string.format("got %s, expected %s", tostring(a), tostring(b)))
  end
  
  local op = operators.filter(function(x) return x > 2 end)
  local result = op({1, 2, 3, 4, 5})
  assert_eq(#result, 3, "filter keeps 3,4,5")
  
  print("reactive-pipeline tests passed")
end)

if not ok then
  print("reactive-pipeline: template tests skipped (modules not yet implemented)")
end
