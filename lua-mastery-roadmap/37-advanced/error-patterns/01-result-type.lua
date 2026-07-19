#!/usr/bin/env lua
-- Stage 37: Error Patterns - Result Type
-- Type-safe error handling without exceptions

local Result = {}
Result.__index = Result

function Result.ok(value)
  return setmetatable({ok = true, value = value}, Result)
end

function Result.err(error)
  return setmetatable({ok = false, error = error}, Result)
end

function Result:is_ok()
  return self.ok
end

function Result:is_err()
  return not self.ok
end

function Result:unwrap()
  if self.ok then
    return self.value
  else
    error("unwrap() called on Err: " .. tostring(self.error))
  end
end

function Result:unwrap_or(default)
  if self.ok then
    return self.value
  else
    return default
  end
end

function Result:map(fn)
  if self.ok then
    return Result.ok(fn(self.value))
  else
    return self
  end
end

function Result:and_then(fn)
  if self.ok then
    return fn(self.value)
  else
    return self
  end
end

-- Usage examples
local function divide(a, b)
  if b == 0 then
    return Result.err("division by zero")
  end
  return Result.ok(a / b)
end

local function sqrt(x)
  if x < 0 then
    return Result.err("negative number")
  end
  return Result.ok(math.sqrt(x))
end

-- Chaining operations
local result = divide(10, 2)
  :map(function(x) return x * 10 end)
  :and_then(sqrt)

print("Result:", result:unwrap())  -- 7.071...

-- Error propagation
local result2 = divide(10, 0)
  :map(function(x) return x * 10 end)
  :and_then(sqrt)

print("Error:", result2:unwrap_or("N/A"))  -- N/A

-- Interactive demo
print("\n=== Interactive Demo ===")
io.write("Enter a number: ")
local input = io.read("*n")
if input then
  local result = divide(100, input)
    :map(function(x) return math.floor(x) end)
  print("100 / " .. input .. " = " .. result:unwrap_or("error"))
else
  print("Invalid input")
end
