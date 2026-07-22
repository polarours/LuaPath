-- Example 11: Module Pattern
-- Chapter: 06-modules
-- Difficulty: Intermediate
-- Lua Version: 5.1+

-- Demonstrates: module design, require, encapsulation

local M = {}

-- Private state
local config = {
  debug = false,
  verbose = false,
}

-- Public API
function M.set_debug(flag)
  config.debug = flag
end

function M.set_verbose(flag)
  config.verbose = flag
end

function M.get_config()
  return {
    debug = config.debug,
    verbose = config.verbose,
  }
end

-- Private helper
local function log(level, msg)
  if config.verbose then
    print(string.format("[%s] %s", level, msg))
  end
end

function M.process(data)
  log("INFO", "Processing data")
  if config.debug then
    log("DEBUG", "Input: " .. tostring(data))
  end
  return data
end

-- Demo
print("=== Module Pattern ===")

M.set_debug(true)
M.set_verbose(true)

print("Config:", M.get_config())
M.process("test data")

print("\n=== Done ===")
