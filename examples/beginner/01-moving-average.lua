-- Example 1: Moving Average Calculator
-- Chapter: 01-basics
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: local variables, loops, table operations

--- Calculate moving average of last n values
-- @param values array of numbers
-- @param n window size for moving average
-- @return array of moving averages
local function moving_average(values, n)
  local result = {}
  
  for i = 1, #values do
    local sum = 0
    local count = 0
    
    -- Sum values in window [i-n+1, i]
    for j = math.max(1, i - n + 1), i do
      sum = sum + values[j]
      count = count + 1
    end
    
    result[i] = sum / count
  end
  
  return result
end

-- Test
local data = {10, 20, 30, 40, 50}
local averages = moving_average(data, 3)

print("Data:", table.concat(data, ", "))
print("Moving Avg (n=3):", table.concat(averages, ", "))
-- Expected: 10, 15, 20, 30, 40
