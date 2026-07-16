-- Example 01: INI Parser
-- Project: 01-ini-parser
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: string parsing, pattern matching, nested tables, error handling

--- Parse an INI configuration string into a structured table
-- @param ini_string the raw INI content
-- @return table with sections as keys, each containing key=value pairs
local function parse_ini(ini_string)
  local config = {}
  local current_section = nil
  local line_num = 0

  for raw_line in ini_string:gmatch("[^\r\n]+") do
    line_num = line_num + 1

    -- Strip leading/trailing whitespace
    local line = raw_line:match("^%s*(.-)%s*$")

    -- Skip empty lines and comments (# or ;)
    if line ~= "" and not line:match("^[#;]") then
      -- Check for section header: [name]
      local section_name = line:match("^%[(.+)%]$")

      if section_name then
        -- Validate section name is not empty
        if section_name == "" then
          error("Line " .. line_num .. ": empty section name")
        end
        -- Initialize nested sections via dot notation
        current_section = config
        for part in section_name:gmatch("[^%.]+") do
          if not current_section[part] then
            current_section[part] = {}
          end
          current_section = current_section[part]
        end

      else
        -- Must be inside a section
        if current_section == nil then
          error("Line " .. line_num .. ": key outside any section")
        end

        -- Parse key=value pair
        local key, value = line:match("^(.-)%s*=%s*(.-)$")
        if key == nil then
          error("Line " .. line_num .. ": invalid syntax: " .. line)
        end

        -- Warn on duplicate keys
        if current_section[key] ~= nil then
          print("Warning: duplicate key '" .. key .. "' on line " .. line_num)
        end

        current_section[key] = value
      end
    end
  end

  return config
end

--- Pretty-print a config table for display
-- @param config the parsed configuration table
-- @param indent indentation string
local function print_config(config, indent)
  indent = indent or ""
  for k, v in pairs(config) do
    if type(v) == "table" then
      print(indent .. "[" .. k .. "]")
      print_config(v, indent .. "  ")
    else
      print(indent .. k .. " = " .. v)
    end
  end
end

--- Main: demonstrate INI parsing
local function main()
  local ini_content = [[
# Database configuration
[database]
host = localhost
port = 5432
name = myapp_db

; User credentials
[database.auth]
username = admin
password = secret123

# Application settings
[app]
version = 1.0.0
debug = true
log_level = info

[app.nested]
level1 = value1
level2 = value2
]]

  print("=== Raw INI Content ===")
  print(ini_content)

  local config = parse_ini(ini_content)

  print("=== Parsed Configuration ===")
  print_config(config)

  -- Access specific values
  print("\n=== Direct Access ===")
  print("database.host:", config.database.host)
  print("database.port:", config.database.port)
  print("database.auth.username:", config.database.auth.username)
  print("app.debug:", config.app.debug)
end

main()
