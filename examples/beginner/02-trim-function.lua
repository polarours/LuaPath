-- Example 2: String Trim Function
-- Chapter: 01-basics
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: string patterns, edge cases

--- Trim whitespace from both ends of a string
-- @param s input string
-- @return trimmed string
local function trim(s)
  if type(s) ~= "string" then
    return s
  end
  
  -- Match from first non-space to last non-space
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Test cases
local tests = {
  ["  hello  "] = "hello",
  ["no_spaces"] = "no_spaces",
  ["  "] = "",
  [""] = "",
  ["\t\ntrimmed\t\n"] = "trimmed",
}

print("Running trim tests...")
local passed = 0
local failed = 0

for input, expected in pairs(tests) do
  local result = trim(input)
  if result == expected then
    passed = passed + 1
    print(string.format("✓ trim(%q) = %q", input, result))
  else
    failed = failed + 1
    print(string.format("✗ trim(%q) expected %q, got %q", input, expected, result))
  end
end

do
  local result = trim(nil)
  if result == nil then
    passed = passed + 1
    print("✓ trim(nil) = nil")
  else
    failed = failed + 1
    print(string.format("✗ trim(nil) expected nil, got %q", result))
  end
end

print(string.format("\nResults: %d passed, %d failed", passed, failed))
