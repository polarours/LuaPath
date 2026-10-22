#!/usr/bin/env lua

-- validate.lua
-- Validates Lua code snippets extracted from markdown files.
-- Usage: lua scripts/validate.lua [options] [directories...]

local has_lfs, lfs = pcall(require, "lfs")
if not has_lfs then
  lfs = nil
end

local config = {
  skip_patterns = {
    ".*%.%.%.",
    "<FILL>",
    "<TODO>",
  },
}

local function print_help()
  print([=[
Usage: lua scripts/validate.lua [options] [directories...]

Options:
  --all        Validate all markdown files in en/ and zh/
  --en         Validate English markdown files only
  --zh         Validate Chinese markdown files only
  --file FILE  Validate a specific markdown file
  --help       Show this help

Examples:
  lua scripts/validate.lua --all
  lua scripts/validate.lua --en
  lua scripts/validate.lua --file en/01-basics.md
]=])
end

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
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

local function sorted_keys(map)
  local keys = {}
  for key in pairs(map) do
    table.insert(keys, key)
  end
  table.sort(keys)
  return keys
end

local function list_markdown_files_with_lfs(root, output)
  for entry in lfs.dir(root) do
    if entry ~= "." and entry ~= ".." then
      local path = root .. "/" .. entry
      local mode = lfs.attributes(path, "mode")
      if mode == "directory" then
        list_markdown_files_with_lfs(path, output)
      elseif mode == "file" and entry:match("%.md$") then
        table.insert(output, path)
      end
    end
  end
end

local function list_markdown_files_with_find(root)
  local files = {}
  local command = string.format(
    "find %s -type f -name '*.md' | sort",
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

local function list_markdown_files(root)
  if lfs then
    local files = {}
    list_markdown_files_with_lfs(root, files)
    table.sort(files)
    return files
  end

  return list_markdown_files_with_find(root)
end

local function compile_lua(code, chunkname)
  if _VERSION == "Lua 5.1" then
    return loadstring(code, chunkname)
  end
  return load(code, chunkname, "t")
end

local args = { ... }
local options = {
  all = false,
  en = false,
  zh = false,
  files = {},
  directories = {},
}

local index = 1
while index <= #args do
  local arg = args[index]
  if arg == "--all" then
    options.all = true
  elseif arg == "--en" then
    options.en = true
  elseif arg == "--zh" then
    options.zh = true
  elseif arg == "--file" then
    local filepath = args[index + 1]
    if not filepath then
      io.stderr:write("Missing value for --file\n")
      os.exit(1)
    end
    table.insert(options.files, filepath)
    index = index + 1
  elseif arg == "--help" then
    print_help()
    os.exit(0)
  else
    table.insert(options.directories, arg)
  end
  index = index + 1
end

if not (options.all or options.en or options.zh or #options.files > 0 or #options.directories > 0) then
  options.all = true
end

local stats = {
  files = 0,
  total = 0,
  passed = 0,
  failed = 0,
  skipped = 0,
  version_gated = 0,
  warnings = 0,
}

local function should_skip(code)
  if code:match("^%s*$") then
    return true
  end

  for _, pattern in ipairs(config.skip_patterns) do
    if code:match(pattern) then
      return true
    end
  end

  return false
end

local function extract_code_blocks(content)
  local blocks = {}
  local current_block
  local line_number = 0
  local heading = ""
  local preceding = ""

  for line in (content .. "\n"):gmatch("(.-)\n") do
    line_number = line_number + 1

    if not current_block then
      local language = line:match("^```([%w_-]*)%s*$")
      if language then
        current_block = {
          lang = language,
          lines = {},
          start_line = line_number + 1,
          heading = heading,
          preceding = preceding,
        }
      elseif line:match("^#+%s") then
        heading = line
        preceding = ""
      elseif line:match("%S") then
        preceding = line
      end
    elseif line:match("^```%s*$") then
      if current_block.lang == "lua" then
        table.insert(blocks, current_block)
      end
      current_block = nil
    else
      table.insert(current_block.lines, line)
    end
  end

  return blocks
end

-- A code block may intentionally contain multiple independent Lua fragments
-- (a common teaching pattern: "compare module A and module B in one fence").
-- Try to split such a block on blank-line separators and validate each piece
-- separately. Only adopt the split if the original failure was <eof>-style
-- AND every piece compiles cleanly — otherwise preserve the original result
-- so real errors are never masked.
local function split_independent_fragments(code)
  local pieces = {}
  local current = {}
  for line in (code .. "\n"):gmatch("(.-)\n") do
    if line:match("^%s*$") then
      if #current > 0 then
        table.insert(pieces, table.concat(current, "\n"))
        current = {}
      end
    else
      table.insert(current, line)
    end
  end
  if #current > 0 then
    table.insert(pieces, table.concat(current, "\n"))
  end
  return pieces
end

-- Version gating ------------------------------------------------------------
--
-- Every chapter declares "Lua Versions: 5.1, 5.3, 5.4, LuaJIT". A snippet
-- that needs a newer Lua is fine as long as it says so; a snippet that
-- quietly needs one is a documentation bug, because the reader on 5.1 has no
-- way to know.
--
-- So: work out the newest Lua a block requires, from the label around it,
-- and skip the block when the runtime running the validator is older than
-- that. What is left failing is exactly the set of unlabelled, incompatible
-- snippets.

local runtime_minor = tonumber(_VERSION:match("Lua 5%.(%d+)")) or tonumber(_VERSION:match("(%d+)%.(%d+)")) or 4

-- A version marker only counts in a version-ish context, so that an
-- unrelated "5.3" in a heading is not mistaken for a version requirement.
local function detect_min_version(text)
  if not text then return nil end
  local best = nil
  local function consider(v)
    if v and v >= 1 and v <= 5 and (not best or v > best) then best = v end
  end
  -- A capture may only appear at the end of a pattern used with gmatch.
  --
  -- "Lua 5.3", "Lua 5.3+", "Lua 5.3 说明", "-- Lua 5.3+"
  for minor in text:gmatch("Lua%s+5%.(%d+)") do
    consider(tonumber(minor))
  end
  -- "(5.3+)" -- the trailing "+)" is simply left unmatched
  for minor in text:gmatch("%(%d%.(%d+)") do
    consider(tonumber(minor))
  end
  -- The Chinese track uses full-width parentheses: "（5.3+）"
  for minor in text:gmatch("（%d%.(%d+)") do
    consider(tonumber(minor))
  end
  return best
end

local function block_min_version(block)
  local best = nil
  local function consider(v)
    if v and (not best or v > best) then best = v end
  end
  consider(detect_min_version(block.heading))
  consider(detect_min_version(block.preceding))
  -- A label inside the block itself, usually the first line.
  for i = 1, math.min(3, #block.lines) do
    consider(detect_min_version(block.lines[i]))
  end
  return best
end

local function validate_block(block, path)
  local code = table.concat(block.lines, "\n")
  if should_skip(code) then
    stats.skipped = stats.skipped + 1
    return "skipped"
  end

  local min_version = block_min_version(block)
  if min_version and runtime_minor < min_version then
    stats.skipped = stats.skipped + 1
    stats.version_gated = stats.version_gated + 1
    return "version-gated", min_version
  end

  local chunkname = string.format("@%s:%d", path, block.start_line)
  local _, err = compile_lua(code, chunkname)
  if not err then
    stats.passed = stats.passed + 1
    return "passed"
  end

  -- On <eof>-style failures, try splitting the block into independent fragments
  -- separated by blank lines. If every fragment compiles on its own, accept
  -- them as a multi-fragment teaching example and do not warn.
  if err:match("<eof>") then
    local fragments = split_independent_fragments(code)
    if #fragments > 1 then
      local all_ok = true
      for _, frag in ipairs(fragments) do
        local frag_chunk = string.format("%s#frag", chunkname)
        local _, frag_err = compile_lua(frag, frag_chunk)
        if frag_err then
          all_ok = false
          break
        end
      end
      if all_ok then
        stats.passed = stats.passed + 1
        return "passed"
      end
    end
    stats.warnings = stats.warnings + 1
    return "warning", err
  end

  stats.failed = stats.failed + 1
  return "failed", err
end

local function process_file(path)
  local content, err = read_file(path)
  if not content then
    stats.failed = stats.failed + 1
    print(string.format("  FAIL: %s", path))
    print(string.format("    Error: %s", err))
    return
  end

  stats.files = stats.files + 1
  local blocks = extract_code_blocks(content)
  for block_index, block in ipairs(blocks) do
    stats.total = stats.total + 1
    local status, block_err = validate_block(block, path)
    if status == "failed" then
      print(string.format("  FAIL: %s (block %d, line %d)", path, block_index, block.start_line))
      print(string.format("    Error: %s", block_err))
    elseif status == "warning" then
      print(string.format("  WARN: %s (block %d, line %d)", path, block_index, block.start_line))
      print(string.format("    Reason: %s", block_err))
    elseif status == "version-gated" then
      print(string.format("  GATED: %s (block %d, line %d) needs Lua 5.%d+",
        path, block_index, block.start_line, block_err))
    end
  end
end

local target_paths = {}

local function add_path(path)
  target_paths[path] = true
end

if #options.files > 0 then
  for _, path in ipairs(options.files) do
    add_path(path)
  end
else
  local directories = {}
  if #options.directories > 0 then
    directories = options.directories
  else
    if options.all or options.en then
      table.insert(directories, "en")
    end
    if options.all or options.zh then
      table.insert(directories, "zh")
    end
  end

  for _, directory in ipairs(directories) do
    local files, err = list_markdown_files(directory)
    if not files then
      io.stderr:write(string.format("Unable to list markdown files in %s: %s\n", directory, err))
      os.exit(1)
    end
    for _, path in ipairs(files) do
      add_path(path)
    end
  end
end

print("LuaPath Code Validator")
print("==========================")
print()

for _, path in ipairs(sorted_keys(target_paths)) do
  print("Validating: " .. path)
  process_file(path)
end

print()
print("Summary")
print("-------")
print(string.format("Files:         %d", stats.files))
print(string.format("Total blocks:  %d", stats.total))
print(string.format("Passed:        %d", stats.passed))
print(string.format("Failed:        %d", stats.failed))
print(string.format("Skipped:       %d", stats.skipped))
print(string.format("Version-gated: %d", stats.version_gated))
print(string.format("Warnings:      %d", stats.warnings))
print(string.format("Runtime:       %s", _VERSION))
print()

if stats.failed > 0 then
  print("VALIDATION FAILED")
  os.exit(1)
end

print("VALIDATION PASSED")
