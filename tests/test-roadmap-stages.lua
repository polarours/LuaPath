#!/usr/bin/env lua

-- test-roadmap-stages.lua
-- Tests for roadmap stage projects

local has_lfs, lfs = pcall(require, "lfs")
if not has_lfs then
  lfs = nil
end

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function list_lua_files_with_lfs(root, output)
  for entry in lfs.dir(root) do
    if entry ~= "." and entry ~= ".." then
      local path = root .. "/" .. entry
      local mode = lfs.attributes(path, "mode")
      if mode == "directory" then
        list_lua_files_with_lfs(path, output)
      elseif mode == "file" and entry:match("%.lua$") then
        table.insert(output, path)
      end
    end
  end
end

local function list_lua_files(root)
  if lfs then
    local files = {}
    list_lua_files_with_lfs(root, files)
    table.sort(files)
    return files
  end

  local files = {}
  local command = string.format(
    "find %s -type f -name '*.lua' | sort",
    shell_quote(root)
  )
  local process = io.popen(command, "r")
  if not process then
    return nil, "failed to run find"
  end

  for line in process:lines() do
    table.insert(files, line)
  end

  local ok = process:close()
  if ok == nil or ok == false then
    return nil, "find command failed"
  end

  return files
end

local function read_file(path)
  local handle = io.open(path, "r")
  if not handle then
    return nil, "cannot open file"
  end
  local content = handle:read("*all")
  handle:close()
  return content
end

local function command_succeeded(...)
  local result = { ... }
  if type(result[1]) == "number" then
    return result[1] == 0, result[1]
  end
  if type(result[1]) == "boolean" then
    return result[1], result[3] or 0
  end
  return false, -1
end

local args = { ... }
local options = {
  interpreter = "lua5.4",
  root = "lua-mastery-roadmap",
}

local index = 1
while index <= #args do
  local arg = args[index]
  if arg == "--interpreter" then
    options.interpreter = args[index + 1]
    index = index + 1
  elseif arg == "--root" then
    options.root = args[index + 1]
    index = index + 1
  elseif arg == "--help" then
    print("Usage: lua test-roadmap-stages.lua [options]")
    print("Options:")
    print("  --interpreter CMD  Interpreter (default: lua5.4)")
    print("  --root DIR         Roadmap root (default: lua-mastery-roadmap)")
    os.exit(0)
  end
  index = index + 1
end

local files, err = list_lua_files(options.root)
if not files then
  io.stderr:write("Unable to list stages: " .. err .. "\n")
  os.exit(1)
end

local stats = {
  total = 0,
  passed = 0,
  failed = 0,
}

print("LuaPath Roadmap Stage Tester")
print("================================")
print(string.format("Runtime: %s", options.interpreter))
print(string.format("Root: %s", options.root))
print()

for _, path in ipairs(files) do
  -- Skip source modules in src/ directories (they require other modules)
  if not path:find("/src/") then
    stats.total = stats.total + 1
    print(string.format("TEST: %s", path))
  
    local ok, exit_code = command_succeeded(
      os.execute(string.format("%s %s 2>&1", options.interpreter, shell_quote(path)))
    )
  
    if ok then
      stats.passed = stats.passed + 1
      print("  PASSED")
    else
      stats.failed = stats.failed + 1
      print(string.format("  FAILED (exit code %s)", tostring(exit_code)))
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("Total:   %d", stats.total))
print(string.format("Passed:  %d", stats.passed))
print(string.format("Failed:  %d", stats.failed))
print()

if stats.failed > 0 then
  print("ROADMAP TESTS FAILED")
  os.exit(1)
end

print("ROADMAP TESTS PASSED")
