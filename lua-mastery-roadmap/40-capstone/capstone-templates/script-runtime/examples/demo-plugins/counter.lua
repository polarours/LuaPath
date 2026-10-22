-- counter.lua
-- Simple counter plugin demonstrating the plugin API
local M = {}

local count = 0

function M.on_init(config)
  count = 0
  print("[counter] initialized")
end

function M.on_tick(dt)
  count = count + 1
  if count % 10 == 0 then
    print(string.format("[counter] tick %d", count))
  end
end

function M.on_destroy()
  print(string.format("[counter] destroyed after %d ticks", count))
end

M.name    = "counter"
M.version = "1.0.0"
return M
