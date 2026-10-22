-- operators.lua
-- The built-in operators of the pipeline.
--
-- Every operator is a function that takes a list of values and returns a
-- new list -- except reduce, which folds the list into a single value. The
-- pipeline hands a batch of values to each operator in turn, so an operator
-- never has to know where in the chain it sits.
local M = {}

--- Apply a function to every value.
-- @param fn function the function to apply
-- @return function operator taking a list and returning a list
function M.map(fn)
  return function(values)
    local out = {}
    for i, value in ipairs(values) do
      out[i] = fn(value)
    end
    return out
  end
end

--- Drop the values for which the predicate is false.
-- @param fn function the predicate
-- @return function operator taking a list and returning a list
function M.filter(fn)
  return function(values)
    local out = {}
    for _, value in ipairs(values) do
      if fn(value) then
        out[#out + 1] = value
      end
    end
    return out
  end
end

--- Accumulate the values into a single value.
-- @param fn function called as fn(accumulator, value)
-- @param init any the initial accumulator
-- @return function operator taking a list and returning the accumulator
function M.reduce(fn, init)
  return function(values)
    local acc = init
    for _, value in ipairs(values) do
      acc = fn(acc, value)
    end
    return acc
  end
end

--- Group the values into windows of at most n values.
-- The last window is shorter when the number of values is not a multiple of n.
-- @param n number the window size
-- @return function operator taking a list and returning a list of windows
function M.window(n)
  if type(n) ~= "number" or n < 1 then
    error("window size must be a positive number, got " .. tostring(n))
  end
  return function(values)
    local out = {}
    local buffer = {}
    for _, value in ipairs(values) do
      buffer[#buffer + 1] = value
      if #buffer == n then
        out[#out + 1] = buffer
        buffer = {}
      end
    end
    if #buffer > 0 then
      out[#out + 1] = buffer
    end
    return out
  end
end

return M
