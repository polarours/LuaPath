-- pipeline.lua
local M = {}

local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.new(source)
  return setmetatable({
    _source = source,
    _ops = {},
    _sink = nil,
    _error_handler = nil,
  }, Pipeline)
end

function Pipeline:pipe(...)
  -- TODO: add operators to _ops, set _sink, return self
  -- variadic: last arg is sink, all others are operators
end

function Pipeline:error_handler(fn)
  -- TODO: set _error_handler
end

function Pipeline:run()
  -- TODO: drive the source coroutine, feed through _ops, push to _sink
  -- yield between each value to allow backpressure
  -- on error, call _error_handler if set
end

M.Pipeline = Pipeline

return M
