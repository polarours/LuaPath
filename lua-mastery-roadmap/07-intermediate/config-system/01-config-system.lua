--[[
  Example: Config System
  Chapter: Stage 7 — Intermediate
  Difficulty: Intermediate
  Lua Version: 5.1+
  Demonstrates: File I/O, INI parsing, environment overrides, schema validation
]]

local config = {}

local function parse_ini(text)
  local sections = {}
  local current = "_global"
  sections[current] = {}

  for raw_line in text:gmatch("[^\r\n]+") do
    local line = raw_line:match("^%s*(.-)%s*$") -- trim
    if line == "" or line:sub(1, 1) == ';' or line:sub(1, 1) == '#' then
      -- skip comments and empty lines
    elseif line:match("^%[(.+)%]$") then
      current = line:match("^%[(.+)%]$")
      sections[current] = sections[current] or {}
    elseif line:match("(.+)=(.+)") then
      local key, value = line:match("(.+)=(.+)")
      key = key:match("^%s*(.-)%s*$")
      value = value:match("^%s*(.-)%s*$")
      if value == "true" then value = true
      elseif value == "false" then value = false
      elseif tonumber(value) then value = tonumber(value) end
      sections[current][key] = value
    end
  end
  return sections
end

function config.load(file_path, schema)
  local sections = {}
  local f = io.open(file_path, "r")
  if f then
    local text = f:read("*a")
    f:close()
    sections = parse_ini(text)
  end

  -- Apply schema defaults
  if schema then
    for section, keys in pairs(schema) do
      sections[section] = sections[section] or {}
      for key, default in pairs(keys) do
        if sections[section][key] == nil then
          sections[section][key] = default
        end
      end
    end
  end

  -- Apply environment overrides (SECTION_KEY pattern)
  for section, keys in pairs(schema or {}) do
    for key, default in pairs(keys) do
      local env_key = section:upper() .. "_" .. key:upper()
      local env_val = os.getenv(env_key)
      if env_val then
        if type(default) == "boolean" then
          sections[section][key] = (env_val == "true" or env_val == "1")
        elseif tonumber(default) then
          sections[section][key] = tonumber(env_val)
        else
          sections[section][key] = env_val
        end
      end
    end
  end

  return sections
end

function config.save(file_path, sections)
  local f = io.open(file_path, "w")
  if not f then error("Cannot write to: " .. file_path) end

  for section, keys in pairs(sections) do
    if section ~= "_global" then
      f:write("[" .. section .. "]\n")
    end
    for k, v in pairs(keys) do
      local val = tostring(v)
      f:write(k .. "=" .. val .. "\n")
    end
    f:write("\n")
  end
  f:close()
end

function config.get(sections, section, key)
  if sections[section] then return sections[section][key] end
  return nil
end

function config.set(sections, section, key, value)
  sections[section] = sections[section] or {}
  sections[section][key] = value
end

-- Test with demo config
local function main()
  local schema = {
    database = { host = "localhost", port = 5432, name = "mydb" },
    server   = { host = "0.0.0.0", port = 8080, debug = false },
  }

  -- Save demo config
  local demo = {
    database = { host = "127.0.0.1", port = 5432, name = "testdb" },
    server   = { host = "0.0.0.0", port = 3000, debug = true },
  }
  config.save("/tmp/demo.ini", demo)

  -- Load with schema (defaults fill missing keys)
  local loaded = config.load("/tmp/demo.ini", schema)
  print("Loaded config:")
  for section, keys in pairs(loaded) do
    print("  [" .. section .. "]")
    for k, v in pairs(keys) do
      print("    " .. k .. " = " .. tostring(v))
    end
  end

  -- Validate types
  local ok = type(loaded.database.port) == "number"
  print("\nValidation: port is number? " .. tostring(ok))

  print("\n[OK] Config system working")
end

main()

return config
