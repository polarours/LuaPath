-- _template.lua
-- Copy this file to create a new plugin.
-- Rename and place in plugins/ directory.

local M = {}

function M.on_init(config)
  -- Receive runtime config
end

function M.on_tick(dt)
  -- Called every frame
end

function M.on_destroy()
  -- Cleanup
end

M.name    = "my-plugin"
M.version = "0.1.0"
return M
