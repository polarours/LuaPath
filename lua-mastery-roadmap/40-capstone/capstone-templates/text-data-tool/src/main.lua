-- main.lua
-- CLI entry point
local config   = require "config"
local transform = require "transform"

local function main()
  -- Parse arguments
  -- input = arg[1], config_path = arg[2]
  -- --output flag is optional

  -- 1. Load input file (pcall + io.open)
  -- 2. Load config
  -- 3. Read all lines
  -- 4. Apply transforms
  -- 5. Write output (file or stdout)

  -- TODO: implement
end

main()
