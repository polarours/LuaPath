-- Example 8: String Pattern Matching
-- Chapter: 07-strings
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: Lua pattern matching, gmatch, gsub, capture groups

--- Extract all emails from a string using pattern matching
-- @param text string to search
-- @return table of email addresses
local function extract_emails(text)
  local emails = {}
  for email in text:gmatch("[%w%.%+%-]+@[%w%.]+%.%w+") do
    table.insert(emails, email)
  end
  return emails
end

--- Parse CSV line respecting quoted fields
-- @param line CSV line to parse
-- @return table of fields
local function parse_csv(line)
  local fields = {}
  local field = ""
  local in_quotes = false

  for i = 1, #line do
    local char = line:sub(i, i)
    if char == '"' then
      in_quotes = not in_quotes
    elseif char == ',' and not in_quotes then
      table.insert(fields, field)
      field = ""
    else
      field = field .. char
    end
  end
  table.insert(fields, field)
  return fields
end

--- Simple template substitution with named placeholders
-- @param template string with {name} placeholders
-- @param values table mapping names to replacement values
-- @return substituted string
local function substitute(template, values)
  return template:gsub("{(%w+)}", values)
end

--- Demonstrate capture groups for structured data
-- @param text string to parse
-- @return table of captured parts
local function parse_date(text)
  local year, month, day = text:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
  return {year = year, month = month, day = day}
end

--- Extract key-value pairs from a configuration string
-- @param config string with key = value pairs
-- @return table of key-value pairs
local function parse_config(config)
  local result = {}
  for key, value in config:gmatch("(%w+)%s*=%s*([^\n]+)") do
    result[key] = value:match("^%s*(.-)%s*$") -- trim whitespace
  end
  return result
end

--- Replace multiple patterns at once
-- @param text string to process
-- @return string with replacements
local function normalize_text(text)
  -- Collapse multiple spaces to one
  text = text:gsub("%s+", " ")
  -- Remove leading/trailing whitespace
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  -- Capitalize first letter of each sentence
  text = text:gsub("(%.)%s*(%l)", function(dot, letter)
    return dot .. " " .. letter:upper()
  end)
  return text
end

--- Main function demonstrating pattern matching
local function main()
  print("=== String Pattern Matching ===\n")

  -- 1. Email extraction
  print("1. Email Extraction:")
  local text = "Contact us at support@example.com or sales@company.org for help."
  local emails = extract_emails(text)
  for _, email in ipairs(emails) do
    print(string.format("  Found: %s", email))
  end

  -- 2. CSV parsing
  print("\n2. CSV Parsing:")
  local csv_line = 'John,"Doe, Jr.",30,"New York, NY"'
  local fields = parse_csv(csv_line)
  for i, field in ipairs(fields) do
    print(string.format("  Field %d: %s", i, field))
  end

  -- 3. Template substitution
  print("\n3. Template Substitution:")
  local template = "Hello {name}, your order #{order} is ready!"
  local result = substitute(template, {name = "Alice", order = "12345"})
  print(string.format("  Result: %s", result))

  -- 4. Capture groups
  print("\n4. Date Parsing with Captures:")
  local date_str = "2024-01-15"
  local date = parse_date(date_str)
  print(string.format("  Parsed: Year=%s, Month=%s, Day=%s", date.year, date.month, date.day))

  -- 5. Config parsing
  print("\n5. Config File Parsing:")
  local config_text = [[
host = localhost
port = 8080
debug = true
  ]]
  local config = parse_config(config_text)
  for key, value in pairs(config) do
    print(string.format("  %s = %s", key, value))
  end

  -- 6. Text normalization
  print("\n6. Text Normalization:")
  local messy = "  hello   world.   this   is   a   test.   "
  local clean = normalize_text(messy)
  print(string.format("  Before: '%s'", messy))
  print(string.format("  After:  '%s'", clean))

  -- 7. Pattern matching demos
  print("\n7. Pattern Matching Quick Reference:")
  local s = "abc123def456"
  print(string.format("  Digits only: %s", s:match("%d+")))
  print(string.format("  Letters only: %s", s:match("%a+")))
  print(string.format("  All digits: %s", s:gsub("%a+", "")))

  print("\n✓ Pattern matching examples completed!")
end

-- Run the demonstration
main()
