-- sink.lua
local M = {}

-- Bounded buffer sink
function M.bounded(max_size)
  -- TODO: return a Sink object with :push(value)
  -- When buffer is full, drop oldest item
  -- :flush() returns all buffered items
end

-- File sink
function M.file(path)
  -- TODO: write each value to file
end

return M
