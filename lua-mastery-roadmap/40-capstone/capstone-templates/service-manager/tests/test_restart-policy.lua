-- test_restart-policy.lua
-- Test suite for the restart policy
--
-- The test resolves the module from this script's own location, so it works
-- regardless of the working directory it is started from.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
-- The modules are named "src.<name>", and require turns the dot into a
-- path separator, so the search path has to point at the project root.
package.path = _script_dir() .. "../?.lua;" .. package.path

local restart_policy = require "src.restart-policy"

local function assert_eq(actual, expected, msg)
  assert(actual == expected, msg or string.format("got %s, expected %s", tostring(actual), tostring(expected)))
end

local exp = restart_policy.RestartPolicy.new({ max_retries = 5, backoff = "exponential" })
assert_eq(exp:next_delay(1), 2, "exponential delay 1")
assert_eq(exp:next_delay(2), 4, "exponential delay 2")
assert_eq(exp:next_delay(3), 8, "exponential delay 3")
assert_eq(exp:next_delay(10), 30, "exponential delay is capped at 30")
assert(exp:can_restart(5), "can restart at attempt 5")
assert(not exp:can_restart(6), "cannot restart at attempt 6")

local lin = restart_policy.RestartPolicy.new({ max_retries = 3, backoff = "linear", interval = 2 })
assert_eq(lin:next_delay(1), 2, "linear delay 1")
assert_eq(lin:next_delay(3), 6, "linear delay 3")
assert(lin:can_restart(3), "can restart at attempt 3")
assert(not lin:can_restart(4), "cannot restart at attempt 4")

local dflt = restart_policy.RestartPolicy.new()
assert_eq(dflt.max_retries, 3, "default max_retries")
assert_eq(dflt.backoff, "exponential", "default backoff")

print("restart-policy tests passed")
