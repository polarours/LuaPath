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

print("LuaPath EN/ZH Parity Checker")
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

-- A chapter is a mirror pair too: the two tracks must have the same shape.
-- A subsection that exists only in the English track is content the Chinese
-- reader never sees, and nothing else in the build would notice.
local function count_headings_at_level(content, level)
  local count = 0
  local prefix = string.rep("#", level) .. "%s"
  for line in (content .. "\n"):gmatch("(.-)\n") do
    if line:match("^" .. prefix) then count = count + 1 end
  end
  return count
end

for _, rel in ipairs(sorted_keys(common)) do
  if not rel:match("^exercises/") and not rel:match("^tutorial/") then
    local en_content = assert(read_file(en_index[rel]))
    local zh_content = assert(read_file(zh_index[rel]))

    for _, level in ipairs({ 2, 3 }) do
      local en_count = count_headings_at_level(en_content, level)
      local zh_count = count_headings_at_level(zh_content, level)
      if en_count ~= zh_count then
        errors = errors + 1
        print(string.format(
          "CHAPTER STRUCTURE MISMATCH: %s (level %d: EN=%d, ZH=%d)",
          rel, level, en_count, zh_count
        ))
      end
    end
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

    -- The exercise files are organised as level-two sections with level-three
    -- subsections, so both levels have to line up.
    for _, level in ipairs({ 3 }) do
      local en_count = count_headings_at_level(en_content, level)
      local zh_count = count_headings_at_level(zh_content, level)
      if en_count ~= zh_count then
        errors = errors + 1
        print(string.format(
          "EXERCISE STRUCTURE MISMATCH: %s (level %d: EN=%d, ZH=%d)",
          rel, level, en_count, zh_count
        ))
      end
    end

    local en_numbers = extract_exercise_numbers(en_content)
    local zh_numbers = extract_exercise_numbers(zh_content)
    if (#en_numbers > 0 or #zh_numbers > 0) and not same_number_list(en_numbers, zh_numbers) then
      errors = errors + 1
      print(string.format("EXERCISE COVERAGE MISMATCH: %s", rel))
    end
  end
end

-- references/ is a separate space from the en/ + zh/ learner tracks, but it
-- follows the same mirroring rule: an English reference document has a
-- Chinese twin named "<base>.zh-CN.md". Without this check the asymmetry is
-- invisible to CI, because the en/zh comparison above never looks here.
local ref_files, ref_err = list_markdown_files("references")
if not ref_files then
  io.stderr:write("Unable to inspect references/: " .. ref_err .. "\n")
  os.exit(1)
end

local ref_en = {}
local ref_zh = {}
for _, path in ipairs(ref_files) do
  local base = path:match("^references/(.+)%.md$")
  if base then
    if base:match("%.zh%-CN$") then
      ref_zh[(base:gsub("%.zh%-CN$", "")) .. ".md"] = path
    else
      ref_en[base .. ".md"] = path
    end
  end
end

for _, rel in ipairs(sorted_keys(ref_en)) do
  local zh_path = ref_zh[rel]
  if not zh_path then
    errors = errors + 1
    print(string.format("MISSING ZH TRANSLATION: references/%s", rel))
  else
    local en_content = assert(read_file(ref_en[rel]))
    local zh_content = assert(read_file(zh_path))

    local en_headings = count_level_two_headings(en_content)
    local zh_headings = count_level_two_headings(zh_content)
    if en_headings ~= zh_headings then
      errors = errors + 1
      print(string.format(
        "REFERENCE HEADING MISMATCH: references/%s (EN=%d, ZH=%d)",
        rel,
        en_headings,
        zh_headings
      ))
    end
  end
end

for _, rel in ipairs(sorted_keys(ref_zh)) do
  if not ref_en[rel] then
    errors = errors + 1
    print(string.format("ORPHAN ZH TRANSLATION: references/%s", rel))
  end
end

-- The pitfall articles live in their own space (pitfalls/en/ and
-- pitfalls/中文版/) and follow the same mirroring rule as the chapter
-- tracks: every English article needs a Chinese counterpart, and the two
-- must have the same section structure. An article that exists only in one
-- language is a gotcha half the readers never meet.
local pitfall_en = {}
local function list_pitfalls(dir)
  local out = {}
  local ok, pipe = pcall(io.popen, string.format("ls -1 %s 2>/dev/null", dir))
  if not ok or not pipe then return out end
  for name in pipe:lines() do
    if name:match("%.md$") then out[#out + 1] = name end
  end
  pipe:close()
  table.sort(out)
  return out
end

for _, name in ipairs(list_pitfalls("pitfalls/en")) do
  pitfall_en[name] = true
  local en_path = "pitfalls/en/" .. name
  local zh_path = "pitfalls/中文版/" .. name
  local en_content = read_file(en_path)
  local zh_content = read_file(zh_path)
  if not en_content then
    errors = errors + 1
    print(string.format("UNREADABLE: %s", en_path))
  elseif not zh_content then
    errors = errors + 1
    print(string.format("MISSING ZH TRANSLATION: pitfalls/中文版/%s", name))
  else
    local en_h2 = count_headings_at_level(en_content, 2)
    local zh_h2 = count_headings_at_level(zh_content, 2)
    if en_h2 ~= zh_h2 then
      errors = errors + 1
      print(string.format(
        "PITFALL STRUCTURE MISMATCH: %s (EN=%d, ZH=%d)", name, en_h2, zh_h2
      ))
    end
    -- The subsections matter too: a subheading that exists only in the
    -- English track is a section the Chinese reader never sees.
    local en_h3 = count_headings_at_level(en_content, 3)
    local zh_h3 = count_headings_at_level(zh_content, 3)
    if en_h3 ~= zh_h3 then
      errors = errors + 1
      print(string.format(
        "PITFALL SUBSECTION MISMATCH: %s (EN=%d, ZH=%d)", name, en_h3, zh_h3
      ))
    end
  end
end

for _, name in ipairs(list_pitfalls("pitfalls/中文版")) do
  if not pitfall_en[name] then
    errors = errors + 1
    print(string.format("ORPHAN ZH TRANSLATION: pitfalls/中文版/%s", name))
  end
end

-- The roadmap's stage and project READMEs are mirrored too. A placeholder
-- stub that says "translation pending" is not a translation: it leaves the
-- Chinese reader without the prerequisites, the run command and the file
-- map for that stage.
local PLACEHOLDER = "翻译待补"

local function list_readmes(root)
  local out = {}
  local ok, pipe = pcall(io.popen, string.format(
    "find %s -name 'README.md' | sort", "'" .. root:gsub("'", "'\''") .. "'"))
  if not ok or not pipe then return out end
  for path in pipe:lines() do out[#out + 1] = path end
  pipe:close()
  return out
end

for _, en_path in ipairs(list_readmes("lua-mastery-roadmap")) do
  local dir = en_path:match("^(.*)/[^/]*$")
  local zh_path = dir .. "/README.zh-CN.md"
  local en_content = read_file(en_path)
  local zh_content = read_file(zh_path)
  if not zh_content then
    errors = errors + 1
    print(string.format("MISSING ZH TRANSLATION: %s", zh_path))
  elseif zh_content:find(PLACEHOLDER, 1, true) then
    errors = errors + 1
    print(string.format("PLACEHOLDER TRANSLATION: %s", zh_path))
  else
    local en_h2 = count_headings_at_level(en_content, 2)
    local zh_h2 = count_headings_at_level(zh_content, 2)
    if en_h2 ~= zh_h2 then
      errors = errors + 1
      print(string.format(
        "ROADMAP README MISMATCH: %s (EN=%d, ZH=%d)", zh_path, en_h2, zh_h2
      ))
    end
    local en_h3 = count_headings_at_level(en_content, 3)
    local zh_h3 = count_headings_at_level(zh_content, 3)
    if en_h3 ~= zh_h3 then
      errors = errors + 1
      print(string.format(
        "ROADMAP README SUBSECTION MISMATCH: %s (EN=%d, ZH=%d)", zh_path, en_h3, zh_h3
      ))
    end
  end
end

-- The glossary sits at the repository root rather than in a track directory.
-- It follows the same rule: GLOSSARY.md has a GLOSSARY.zh-CN.md twin, with
-- a matching number of level-two headings and the same number of terms.
local glossary_en = read_file("GLOSSARY.md")
local glossary_zh = read_file("GLOSSARY.zh-CN.md")
if glossary_en and not glossary_zh then
  errors = errors + 1
  print("MISSING ZH TRANSLATION: GLOSSARY.zh-CN.md")
elseif glossary_zh and not glossary_en then
  errors = errors + 1
  print("MISSING EN GLOSSARY: GLOSSARY.md")
elseif glossary_en and glossary_zh then
  local function count_headings(content, prefix)
    local count = 0
    for line in (content .. "\n"):gmatch("(.-)\n") do
      if line:match("^" .. prefix) then count = count + 1 end
    end
    return count
  end

  for _, prefix in ipairs({ "##%s", "###%s" }) do
    local en_count = count_headings(glossary_en, prefix)
    local zh_count = count_headings(glossary_zh, prefix)
    if en_count ~= zh_count then
      errors = errors + 1
      print(string.format(
        "GLOSSARY HEADING MISMATCH: %s (EN=%d, ZH=%d)",
        prefix, en_count, zh_count
      ))
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
