#!/usr/bin/env lua

-- parity.lua
-- Checks EN/ZH learner-facing markdown parity for mirrored tracks.

local has_lfs, lfs = pcall(require, "lfs")
if not has_lfs then
  lfs = nil
end

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
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

local function list_markdown_files(root)
  if lfs then
    local files = {}
    list_markdown_files_with_lfs(root, files)
    table.sort(files)
    return files
  end

  local files = {}
  local process = io.popen(
    string.format("find %s -type f -name '*.md' | sort", shell_quote(root)),
    "r"
  )
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

local function relative_path(track, path)
  return path:gsub("^" .. track .. "/", "", 1)
end

local function build_track_index(track)
  local files, err = list_markdown_files(track)
  if not files then
    return nil, err
  end

  local index = {}
  for _, path in ipairs(files) do
    index[relative_path(track, path)] = path
  end
  return index
end

local function sorted_keys(map)
  local keys = {}
  for key in pairs(map) do
    table.insert(keys, key)
  end
  table.sort(keys)
  return keys
end

local function count_level_two_headings(content)
  local count = 0
  for line in (content .. "\n"):gmatch("(.-)\n") do
    if line:match("^##%s+") then
      count = count + 1
    end
  end
  return count
end

local function extract_exercise_numbers(content)
  local numbers = {}
  for line in (content .. "\n"):gmatch("(.-)\n") do
    if line:match("^##%s+") then
      local value = line:match("(%d+)")
      if value then
        table.insert(numbers, tonumber(value))
      end
    end
  end
  return numbers
end

local function same_number_list(a, b)
  if #a ~= #b then
    return false
  end
  for index = 1, #a do
    if a[index] ~= b[index] then
      return false
    end
  end
  return true
end

local en_index, en_err = build_track_index("en")
if not en_index then
  io.stderr:write("Unable to inspect en/: " .. en_err .. "\n")
  os.exit(1)
end

local zh_index, zh_err = build_track_index("zh")
if not zh_index then
  io.stderr:write("Unable to inspect zh/: " .. zh_err .. "\n")
  os.exit(1)
end

local errors = 0
local common = {}

print("lua-journey EN/ZH Parity Checker")
print("================================")
print()

for _, rel in ipairs(sorted_keys(en_index)) do
  if not zh_index[rel] then
    errors = errors + 1
    print(string.format("MISSING IN ZH: %s", rel))
  else
    common[rel] = true
  end
end

for _, rel in ipairs(sorted_keys(zh_index)) do
  if not en_index[rel] then
    errors = errors + 1
    print(string.format("MISSING IN EN: %s", rel))
  else
    common[rel] = true
  end
end

for _, rel in ipairs(sorted_keys(common)) do
  if rel:match("^exercises/") then
    local en_content = assert(read_file(en_index[rel]))
    local zh_content = assert(read_file(zh_index[rel]))

    local en_headings = count_level_two_headings(en_content)
    local zh_headings = count_level_two_headings(zh_content)
    if en_headings ~= zh_headings then
      errors = errors + 1
      print(string.format(
        "HEADING MISMATCH: %s (EN=%d, ZH=%d)",
        rel,
        en_headings,
        zh_headings
      ))
    end

    local en_numbers = extract_exercise_numbers(en_content)
    local zh_numbers = extract_exercise_numbers(zh_content)
    if (#en_numbers > 0 or #zh_numbers > 0) and not same_number_list(en_numbers, zh_numbers) then
      errors = errors + 1
      print(string.format("EXERCISE COVERAGE MISMATCH: %s", rel))
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("EN files:      %d", #sorted_keys(en_index)))
print(string.format("ZH files:      %d", #sorted_keys(zh_index)))
print(string.format("Common files:  %d", #sorted_keys(common)))
print(string.format("Errors:        %d", errors))
print()

if errors > 0 then
  print("PARITY CHECK FAILED")
  os.exit(1)
end

print("PARITY CHECK PASSED")
