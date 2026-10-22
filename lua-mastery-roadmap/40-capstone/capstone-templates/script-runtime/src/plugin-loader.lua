-- plugin-loader.lua
local M = {}

-- Scan a directory for .lua plugin files
-- @param dir  path to plugins directory
-- @return     list of file paths
function M.scan(dir)
  -- TODO: use lfs or os.execute to list dir
  -- return list of "dir/name.lua"
end

-- Load a plugin module with error isolation
function M.load(path)
  -- 1. Clear from require cache if present
  -- 2. local ok, mod = pcall(require, path)
  -- 3. If ok: validate API contract (on_init, on_tick, name fields)
  -- 4. Return mod, or nil + error
end

return M
