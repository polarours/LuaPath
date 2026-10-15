-- logger.lua
local M = {}

-- Structured JSON logger
-- Each log line: {"ts":"ISO8601","level":"info","module":"web","msg":"started","extra":{...}}
function M.new(filepath)
  -- Open file, return logger object
  -- TODO
end

local Logger = {}
Logger.__index = Logger

function Logger:info(module, msg, extra)
  -- TODO: write JSON line
end

function Logger:warn(module, msg, extra) end
function Logger:error(module, msg, extra) end

M.new = M.new
return M
