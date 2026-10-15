-- operators.lua
local M = {}

function M.map(fn)
  -- returns an operator function: takes a value, returns fn(value)
end

function M.filter(fn)
  -- returns an operator that drops values where fn(value) is false
end

function M.reduce(fn, init)
  -- returns an operator that accumulates into a single value
end

function M.window(n)
  -- returns an operator that buffers up to n values and emits the buffer
end

return M
