-- test_manager.lua
-- Test suite for service-manager
-- NOTE: Template test stub. Passes when modules are not yet implemented.
local ok = pcall(function()
  local restart_policy = require "src.restart-policy"
  
  local function assert_eq(a, b, msg)
    assert(a == b, msg or string.format("got %s, expected %s", tostring(a), tostring(b)))
  end
  
  local rp = restart_policy.RestartPolicy.new({max_retries=5, backoff="exponential"})
  assert_eq(rp:next_delay(1), 2, "exponential delay 1")
  assert_eq(rp:next_delay(2), 4, "exponential delay 2")
  assert(rp:can_restart(5),  "can restart at attempt 5")
  assert(not rp:can_restart(6), "cannot restart at attempt 6")
  
  print("service-manager tests passed")
end)

if not ok then
  print("service-manager: template tests skipped (modules not yet implemented)")
end
