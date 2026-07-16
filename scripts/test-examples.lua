#!/usr/bin/env lua

-- test-examples.lua
-- Recursively runs version-compatible examples using a specified interpreter.

local has_lfs, lfs = pcall(require, "lfs")
if not has_lfs then
  lfs = nil
end

local function print_help()
  print([=[
Usage: lua scripts/test-examples.lua [options]

Options:
  --interpreter CMD  Interpreter command used to run example files
  --runtime VALUE    Runtime identifier: 5.1, 5.2, 5.3, 5.4, or luajit
  --root DIR         Examples root directory (default: examples)
  --help             Show this help
]=])
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

local function normalize_runtime(runtime)
  local value = tostring(runtime or ""):lower()
  if value == "luajit" then
    return "luajit"
  end
  if value:match("^5%.[1-4]$") then
    return value
  end
  return nil
end

local function parse_version_spec(content)
  for line in (content .. "\n"):gmatch("(.-)\n") do
    local spec = line:match("^%-%-%s*Lua Version:%s*(.-)%s*$")
    if spec then
      return spec
    end
  end
  return nil
end

local version_rank = {
  ["5.1"] = 1,
  ["5.2"] = 2,
  ["5.3"] = 3,
  ["5.4"] = 4,
}

local function is_compatible(spec, runtime)
  local normalized = spec:gsub("%s+", "")
  if normalized == "LuaJIT" then
    return runtime == "luajit"
  end

  local exact = normalized:match("^(5%.[1-4])$")
  if exact then
    if runtime == "luajit" then
      return exact == "5.1"
    end
    return runtime == exact
  end

  local minimum = normalized:match("^(5%.[1-4])%+$")
  if minimum then
    if runtime == "luajit" then
      return minimum == "5.1"
    end
    return version_rank[runtime] >= version_rank[minimum]
  end

  return false
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
  interpreter = nil,
  root = "examples",
  runtime = nil,
}

local index = 1
while index <= #args do
  local arg = args[index]
  if arg == "--interpreter" then
    options.interpreter = args[index + 1]
    index = index + 1
  elseif arg == "--runtime" then
    options.runtime = args[index + 1]
    index = index + 1
  elseif arg == "--root" then
    options.root = args[index + 1]
    index = index + 1
  elseif arg == "--help" then
    print_help()
    os.exit(0)
  else
    io.stderr:write("Unknown argument: " .. tostring(arg) .. "\n")
    os.exit(1)
  end
  index = index + 1
end

if not options.interpreter or not options.runtime then
  io.stderr:write("Both --interpreter and --runtime are required\n")
  os.exit(1)
end

local runtime = normalize_runtime(options.runtime)
if not runtime then
  io.stderr:write("Unsupported runtime: " .. tostring(options.runtime) .. "\n")
  os.exit(1)
end

local files, err = list_lua_files(options.root)
if not files then
  io.stderr:write("Unable to list examples: " .. err .. "\n")
  os.exit(1)
end

local stats = {
  total = 0,
  ran = 0,
  skipped = 0,
  failed = 0,
  metadata_errors = 0,
}

print("lua-journey Example Runner")
print("==========================")
print(string.format("Runtime: %s", runtime))
print(string.format("Interpreter: %s", options.interpreter))
print()

for _, path in ipairs(files) do
  stats.total = stats.total + 1

  local content, read_err = read_file(path)
  if not content then
    stats.failed = stats.failed + 1
    print(string.format("FAIL: %s", path))
    print(string.format("  Error: %s", read_err))
  else
    local spec = parse_version_spec(content)
    if not spec then
      stats.metadata_errors = stats.metadata_errors + 1
      print(string.format("ERROR: %s", path))
      print("  Missing required '-- Lua Version:' header")
    elseif not is_compatible(spec, runtime) then
      stats.skipped = stats.skipped + 1
      print(string.format("SKIP: %s (requires %s)", path, spec))
    else
      stats.ran = stats.ran + 1
      print(string.format("RUN:  %s", path))
      local ok, exit_code = command_succeeded(
        os.execute(string.format("%s %s", options.interpreter, shell_quote(path)))
      )
      if not ok then
        stats.failed = stats.failed + 1
        print(string.format("  FAILED with exit code %s", tostring(exit_code)))
      end
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("Discovered:      %d", stats.total))
print(string.format("Executed:        %d", stats.ran))
print(string.format("Skipped:         %d", stats.skipped))
print(string.format("Failures:        %d", stats.failed))
print(string.format("Metadata errors: %d", stats.metadata_errors))
print()

if stats.failed > 0 or stats.metadata_errors > 0 then
  print("EXAMPLE TESTS FAILED")
  os.exit(1)
end

print("EXAMPLE TESTS PASSED")
