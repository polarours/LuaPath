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

-- Version gating ------------------------------------------------------------
--
-- A stage file may declare the Lua versions it supports with a
-- "Lua Version:" line, in either the `-- Lua Version: 5.1+` comment style or
-- the block-comment style ("  Lua Version: 5.4"). When a declaration is
-- present and the current runtime does not satisfy it, the file is skipped
-- instead of counted as a failure.
--
-- Files without a declaration are run: the header is optional metadata, so
-- its absence must not silently drop a stage from the suite.

local version_rank = {
  ["5.1"] = 1,
  ["5.2"] = 2,
  ["5.3"] = 3,
  ["5.4"] = 4,
  ["5.5"] = 5,
}

local function normalize_runtime(runtime)
  local value = tostring(runtime or ""):lower()
  if value == "luajit" then
    return "luajit"
  end
  if value:match("^5%.[1-5]$") then
    return value
  end
  return nil
end

local function parse_version_spec(content)
  for line in (content .. "\n"):gmatch("(.-)\n") do
    local spec = line:match("^[%-%s]*Lua Version:%s*(.-)%s*$")
    if spec and spec ~= "" then
      return spec
    end
  end
  return nil
end

local function is_compatible(spec, runtime)
  local normalized = spec:gsub("%s+", "")
  if normalized == "LuaJIT" then
    return runtime == "luajit"
  end

  local exact = normalized:match("^(5%.[1-5])$")
  if exact then
    if runtime == "luajit" then
      return exact == "5.1"
    end
    return runtime == exact
  end

  local minimum = normalized:match("^(5%.[1-5])%+$")
  if minimum then
    if runtime == "luajit" then
      return minimum == "5.1"
    end
    return version_rank[runtime] >= version_rank[minimum]
  end

  return false
end

local args = { ... }
local options = {
  interpreter = "lua5.4",
  root = "lua-mastery-roadmap",
  runtime = "5.4",
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
  elseif arg == "--runtime" then
    options.runtime = args[index + 1]
    index = index + 1
  elseif arg == "--help" then
    print("Usage: lua test-roadmap-stages.lua [options]")
    print("Options:")
    print("  --interpreter CMD  Interpreter (default: lua5.4)")
    print("  --root DIR         Roadmap root (default: lua-mastery-roadmap)")
    print("  --runtime VALUE    Runtime identifier: 5.1, 5.2, 5.3, 5.4, or luajit")
    os.exit(0)
  end
  index = index + 1
end

local runtime = normalize_runtime(options.runtime)
if not runtime then
  io.stderr:write("Unsupported runtime: " .. tostring(options.runtime) .. "\n")
  os.exit(1)
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
  skipped = 0,
}

print("LuaPath Roadmap Stage Tester")
print("================================")
print(string.format("Runtime: %s", runtime))
print(string.format("Interpreter: %s", options.interpreter))
print(string.format("Root: %s", options.root))
print()

for _, path in ipairs(files) do
  -- Skip source modules in src/ directories (they require other modules)
  -- Skip example scripts that require a specific host environment
  if not path:find("/src/") and not path:find("/examples/") then
    local content = read_file(path)
    local spec = content and parse_version_spec(content) or nil

    if spec and not is_compatible(spec, runtime) then
      stats.total = stats.total + 1
      stats.skipped = stats.skipped + 1
      print(string.format("TEST: %s", path))
      print(string.format("  SKIPPED (requires %s)", spec))
    else
      stats.total = stats.total + 1
      print(string.format("TEST: %s", path))

      -- stdin comes from /dev/null: a stage script with an interactive demo
      -- would otherwise block the whole run when the suite is started from a
      -- terminal.
      local ok, exit_code = command_succeeded(
        os.execute(string.format("%s %s < /dev/null 2>&1", options.interpreter, shell_quote(path)))
      )

      -- A test that lives in a project has to work from that project, not
      -- only from the repository root: the stage README tells the reader to
      -- change into the project directory and run the test there. Running
      -- it from its own directory as well catches a test that quietly
      -- depends on the working directory.
      local project_dir = path:match("^(.*)/tests/[^/]+$")
      if ok and project_dir then
        local relative = path:sub(#project_dir + 2)
        local from_project = command_succeeded(
          os.execute(string.format("cd %s && %s %s < /dev/null 2>&1",
            shell_quote(project_dir), options.interpreter, shell_quote(relative)))
        )
        if not from_project then
          ok = false
          exit_code = "failed from the project directory"
        end
      end

      if ok then
        stats.passed = stats.passed + 1
        print("  PASSED")
      else
        stats.failed = stats.failed + 1
        print(string.format("  FAILED (exit code %s)", tostring(exit_code)))
      end
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("Total:   %d", stats.total))
print(string.format("Passed:  %d", stats.passed))
print(string.format("Failed:  %d", stats.failed))
print(string.format("Skipped: %d", stats.skipped))
print()

if stats.failed > 0 then
  print("ROADMAP TESTS FAILED")
  os.exit(1)
end

print("ROADMAP TESTS PASSED")
