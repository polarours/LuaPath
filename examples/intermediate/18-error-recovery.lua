-- Example 20: Error Recovery
-- Chapter: 07-error-handling
-- Difficulty: Intermediate
-- Lua Version: 5.1+

-- Demonstrates: pcall, xpcall, error recovery patterns

local function main()
  print("=== Error Recovery Patterns ===\n")

  -- 1. Safe function call
  local function safe_call(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then
      return result
    else
      return nil, result
    end
  end

  local function divide(a, b)
    if b == 0 then error("division by zero") end
    return a / b
  end

  local r1, e1 = safe_call(divide, 10, 2)
  print("10 / 2 =", r1)

  local r2, e2 = safe_call(divide, 10, 0)
  print("10 / 0 error:", e2)

  -- 2. Retry pattern
  local function retry(fn, max_attempts)
    local last_error
    for attempt = 1, max_attempts do
      local ok, result = pcall(fn)
      if ok then
        return result
      end
      last_error = result
    end
    error("Failed after " .. max_attempts .. " attempts: " .. tostring(last_error))
  end

  local attempts = 0
  local function unreliable()
    attempts = attempts + 1
    if attempts < 3 then
      error("transient error")
    end
    return "success"
  end

  local ok, result = pcall(retry, unreliable, 5)
  print("Retry result:", ok, result)

  -- 3. Error aggregation
  local function validate(data)
    local errors = {}
    if not data.name then
      errors[#errors + 1] = "name is required"
    end
    if not data.age or data.age < 0 then
      errors[#errors + 1] = "age must be non-negative"
    end
    if #errors > 0 then
      return nil, errors
    end
    return true
  end

  local ok, errs = validate({name = "Alice", age = -5})
  if not ok then
    print("Validation errors:")
    for _, e in ipairs(errs) do
      print("  - " .. e)
    end
  end

  print("\n=== Done ===")
end

main()
