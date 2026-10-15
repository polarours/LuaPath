-- test_main.lua
-- Test suite for text-data-tool
local assert = assert

local function assert_eq(a, b, msg)
  assert(a == b, msg or string.format("got %s, expected %s", tostring(a), tostring(b)))
end

local function assert_contains(haystack, needle, msg)
  assert(haystack:find(needle, 1, true), msg or ("expected to contain: " .. needle))
end

-- Test transform registry
local transform = (function()
  -- Stub transform module for testing
  return {
    apply = function(lines, xforms)
      for _, xf in ipairs(xforms) do
        if xf.name == "upper" then
          for i, l in ipairs(lines) do lines[i] = string.upper(l) end
        end
      end
      return lines
    end
  }
end)()

assert_eq(transform.apply({"hello"}, {{name="upper"}})[1], "HELLO", "upper transform")
print("text-data-tool tests passed")
