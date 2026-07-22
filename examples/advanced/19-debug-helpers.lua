-- Example 21: Debug Helpers
-- Chapter: debugging-guide
-- Difficulty: Advanced
-- Lua Version: 5.1+

-- Demonstrates: debug library, introspection, logging

local function main()
  print("=== Debug Helpers Demo ===\n")

  -- 1. Table inspector
  local function dump(t, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    if type(t) ~= "table" then
      return prefix .. tostring(t)
    end

    local lines = {prefix .. "{"}
    for k, v in pairs(t) do
      local key = type(k) == "string" and k or "[" .. tostring(k) .. "]"
      if type(v) == "table" then
        lines[#lines + 1] = prefix .. "  " .. key .. " ="
        lines[#lines + 1] = dump(v, indent + 2)
      else
        lines[#lines + 1] = prefix .. "  " .. key .. " = " .. tostring(v)
      end
    end
    lines[#lines + 1] = prefix .. "}"
    return table.concat(lines, "\n")
  end

  local config = {
    server = {host = "localhost", port = 8080},
    debug = true,
    version = "1.0",
  }
  print("Table dump:")
  print(dump(config))

  -- 2. Function info
  local function get_func_info(fn)
    local info = debug.getinfo(fn, "nS")
    return {
      name = info.name or "<anonymous>",
      source = info.source,
      line = info.linedefined,
    }
  end

  local function my_func() end
  local info = get_func_info(my_func)
  print("\nFunction info:")
  print("  Name:", info.name)
  print("  Source:", info.source)
  print("  Line:", info.line)

  -- 3. Variable inspector
  local function inspect_locals(level)
    local locals = {}
    local i = 1
    while true do
      local name, value = debug.getlocal(level, i)
      if not name then break end
      if name ~= "(*temporary)" then
        locals[name] = value
      end
      i = i + 1
    end
    return locals
  end

  local x = 42
  local y = "hello"
  local locals = inspect_locals(2)
  print("\nLocal variables:")
  for k, v in pairs(locals) do
    print("  " .. k .. " = " .. tostring(v))
  end

  print("\n=== Done ===")
end

main()
