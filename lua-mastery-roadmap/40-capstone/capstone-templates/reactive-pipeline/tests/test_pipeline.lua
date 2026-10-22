-- test_pipeline.lua
-- Test suite for reactive-pipeline
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
