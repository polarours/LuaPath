-- Example 7: Type Checking and Coercion
-- Chapter: 01-basics
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: type(), tonumber(), tostring(), type guards, version differences

--- Check if a value is a specific type
-- @param val value to check
-- @param expected_type string type name
-- @return boolean, string
local function is_type(val, expected_type)
  local actual = type(val)
  return actual == expected_type, actual
end

--- Safely convert a value to a number
-- @param val value to convert
-- @return number or nil
local function safe_number(val)
  if type(val) == "number" then
    return val
  end
  if type(val) == "string" then
    local n = tonumber(val)
    return n
  end
  return nil
end

--- Build a type report for a list of values
-- @param values table of mixed values
local function type_report(values)
  for i, v in ipairs(values) do
    local t = type(v)
    local s = tostring(v)
    print(string.format("  [%d] type=%-8s value=%s", i, t, s))
  end
end

--- Main function demonstrating type checking
local function main()
  print("=== Type Checking and Coercion ===\n")

  -- 1. type() returns a string for each type
  print("1. The type() function:")
  local samples = {42, 3.14, "hello", true, nil, function() end, {}, print}
  local type_names = {"number", "string", "boolean", "nil", "function", "table"}

  for _, name in ipairs(type_names) do
    for _, v in ipairs(samples) do
      if type(v) == name then
        print(string.format("  type(%s) == %q", tostring(v), name))
      end
    end
  end

  -- 2. Type coercion with tonumber()
  print("\n2. tonumber() conversion:")
  local strings = {"100", "3.14", "0xFF", "1e3", "  42  ", "hello", "", "12abc"}
  for _, s in ipairs(strings) do
    local n = tonumber(s)
    if n then
      print(string.format("  tonumber(%q)  => %g", s, n))
    else
      print(string.format("  tonumber(%q)  => nil", s))
    end
  end

  -- 3. Type coercion with tostring()
  print("\n3. tostring() conversion:")
  local mixed = {42, 3.14, true, nil, print, {}, "already string"}
  for _, v in ipairs(mixed) do
    print(string.format("  tostring(%-20s) => %q", type(v) .. ":" .. tostring(v), tostring(v)))
  end

  -- 4. Safe input parsing with type guards
  print("\n4. Safe input parsing:")
  --
  -- A type guard answers two questions at once: does the value have the
  -- expected type, and what type did it actually have? The second answer is
  -- what makes an error message worth reading.
  local function process_input(input)
    if is_type(input, "number") then
      return string.format("  Got number: %g", input)
    end
    if is_type(input, "string") then
      local n = safe_number(input)
      if n then
        return string.format("  Got number: %g (parsed from %q)", n, input)
      end
    end
    local _, actual = is_type(input, "number")
    return string.format("  Got non-number: %s (type=%s)", tostring(input), actual)
  end

  print(process_input("42"))
  print(process_input(3.14))
  print(process_input("hello"))
  print(process_input(true))
  print(process_input(nil))

  -- 5. Implicit coercion
  print("\n5. Implicit type coercion:")
  local concat_err = tostring(pcall(function() return 42 .. 0 end))
  print(string.format("  42 .. 0       => %s (number + number via .. is error)", concat_err))
  print(string.format("  '10' + 5      => %s", 10 + 5))
  print(string.format("  '10' .. 5     => %s", "10" .. 5))
  print(string.format("  '3.14' + 0    => %s", "3.14" + 0))
  print(string.format("  'abc' + 1     => %s", tostring(pcall(function() return "abc" + 1 end))))

  -- 6. Version differences: integer vs float (5.3+)
  --
  -- `//` and math.type() are 5.3+ features. `//` is *syntax*, not a runtime
  -- feature: a 5.1 parser rejects the whole file even inside a branch that
  -- would never execute, so the 5.3-only snippet is compiled from a string.
  print("\n6. Number subtypes (Lua 5.3+):")
  local whole = 42
  local frac = 42.0
  if math.type then
    local probe = load("return 42 // 1, math.type(42), math.type(42.0)")
    local idiv, int_kind, float_kind = probe()
    print(string.format("  42   type=%s  42//1=%s  math.type=%s",
      type(whole), tostring(idiv), tostring(int_kind)))
    print(string.format("  42.0 type=%s  math.type=%s",
      type(frac), tostring(float_kind)))
  else
    print("  math.type not available (needs Lua 5.3+)")
  end

  -- In 5.1/5.2 both are "number"; in 5.3+ integers are a subtype
  local all_numbers = {0, 1, -100, 3.14, 1e10, 0xFF}
  type_report(all_numbers)

  -- 7. Building a type-safe wrapper
  print("\n7. Type-safe addition:")
  local function safe_add(a, b)
    local na = safe_number(a)
    local nb = safe_number(b)
    if na and nb then
      return na + nb
    else
      return nil, "both arguments must be numbers"
    end
  end

  local result, err = safe_add(10, "20")
  print(string.format("  safe_add(10, '20')  => %s", result))

  result, err = safe_add("abc", 5)
  print(string.format("  safe_add('abc', 5)  => nil, %q", err))

  result, err = safe_add(3.5, 2.5)
  print(string.format("  safe_add(3.5, 2.5)  => %s", result))

  print("\n✓ Type checking examples completed!")
end

-- Run the demonstration
main()
