-- config.lua
-- Load and validate a config table
local M = {}

-- Load a config file and return it as a Lua table
-- @param path  file path to the config
-- @return      config table, or nil + error string
function M.load(path)
  -- TODO: implement file loading and validation
  -- 1. Open file with io.open, return nil, err on failure
  -- 2. Load the file contents using load() or dofile()
  -- 3. Validate required fields:
  --    - config.transforms: must be a list (array)
  --    - each item: { name = string, params = table (optional) }
  -- 4. Return the config table
end

return M
