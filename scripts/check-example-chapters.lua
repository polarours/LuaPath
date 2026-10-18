#!/usr/bin/env lua

-- check-example-chapters.lua
-- Verifies that every example's `-- Chapter:` header names a real chapter file,
-- and reports which chapters still have no example (coverage gaps).
--
-- The failure this guards against: examples pointing at chapter names that were
-- renamed or never existed (`07-metatables`, `09-advanced`, ...), which silently
-- breaks navigation in a docs-first project.

local has_lfs, lfs = pcall(require, "lfs")
if not has_lfs then
  -- pcall's second return on failure is the error STRING, which is truthy --
  -- without this reset the `if lfs` check below would take the lfs branch.
  lfs = nil
end

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function list_files_with_lfs(root, extension, output)
  for entry in lfs.dir(root) do
    if entry ~= "." and entry ~= ".." then
      local path = root .. "/" .. entry
      local mode = lfs.attributes(path, "mode")
      if mode == "directory" then
        list_files_with_lfs(path, extension, output)
      elseif mode == "file" and entry:match(extension .. "$") then
        table.insert(output, path)
      end
    end
  end
end

-- Returns a sorted list of paths under `root` ending in `extension`, or nil+err.
local function list_files(root, extension)
  local files = {}

  if lfs then
    list_files_with_lfs(root, extension, files)
  else
    local process = io.popen(
      string.format("find %s -type f -name '*.%s' | sort",
        shell_quote(root), extension),
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
  end

  table.sort(files)
  return files
end

local function read_file(path)
  local handle = io.open(path, "r")
  if not handle then
    return nil
  end
  local content = handle:read("*all")
  handle:close()
  return content
end

-- Chapter names come from the authoritative EN track: `en/07-error-handling.md`
-- becomes `07-error-handling`. Only top-level files count -- nested paths like
-- `en/exercises/advanced.md` are content bundles, not chapters.
local function collect_chapters()
  local files, err = list_files("en", "md")
  if not files then
    return nil, err
  end

  local chapters = {}
  for _, path in ipairs(files) do
    local name = path:match("^en/([^/]+)%.md$")
    if name then
      table.insert(chapters, name)
    end
  end
  return chapters
end

-- Extracts the first `Chapter: <name>` from the file's header region. Tolerates
-- both `-- Chapter: x` and `  Chapter:    x` (block-comment style).
local function extract_chapter_ref(content)
  for line in (content .. "\n"):gmatch("(.-)\n") do
    local value = line:match("^[%-%s]*Chapter:%s*(%S+)")
    if value then
      return value
    end
  end
  return nil
end

local chapters, chapters_err = collect_chapters()
if not chapters then
  io.stderr:write("Unable to inspect en/: " .. chapters_err .. "\n")
  os.exit(1)
end

local known = {}
for _, name in ipairs(chapters) do
  known[name] = true
end

local examples, examples_err = list_files("examples", "lua")
if not examples then
  io.stderr:write("Unable to inspect examples/: " .. examples_err .. "\n")
  os.exit(1)
end

local errors = 0
local referenced = {}

print("LuaPath Example -> Chapter Checker")
print("==================================")
print()
print(string.format("Chapters found: %d", #chapters))
print(string.format("Examples found: %d", #examples))
print()

-- Pass 1: every example must name a real chapter, and its own chapter must
-- actually point readers at it. The second half is what keeps runnable material
-- discoverable -- an example nobody links to may as well not exist.
local example_chapter = {}
for _, path in ipairs(examples) do
  local content = read_file(path)
  if not content then
    errors = errors + 1
    print(string.format("UNREADABLE: %s", path))
  else
    local ref = extract_chapter_ref(content)
    if not ref then
      errors = errors + 1
      print(string.format("NO CHAPTER HEADER: %s", path))
    elseif not known[ref] then
      errors = errors + 1
      print(string.format("BROKEN CHAPTER REF: %s -> %s", path, ref))
    else
      example_chapter[path] = ref
    end
  end
end

-- Index the example paths each chapter body mentions.
local mentions = {}
for _, path in ipairs(examples) do
  mentions[path] = {}
end
for _, name in ipairs(chapters) do
  for _, track in ipairs({ "en", "zh" }) do
    local content = read_file(track .. "/" .. name .. ".md")
    if content then
      for mentioned in content:gmatch("(examples/[%w%-_/]+%.lua)") do
        if mentions[mentioned] then
          mentions[mentioned][track] = true
        end
      end
    end
  end
end

-- Pass 2: an example must be linked from its own chapter, in both tracks.
for _, path in ipairs(examples) do
  local ref = example_chapter[path]
  if ref then
    local seen = mentions[path] or {}
    if not seen.en then
      errors = errors + 1
      print(string.format("NOT LINKED FROM CHAPTER: %s (declares %s, absent from en/%s.md)",
        path, ref, ref))
    end
    if not seen.zh then
      errors = errors + 1
      print(string.format("NOT LINKED FROM CHAPTER: %s (declares %s, absent from zh/%s.md)",
        path, ref, ref))
    end
    referenced[ref] = (referenced[ref] or 0) + 1
  end
end

-- Pass 3: any example path a chapter mentions must exist on disk.
local on_disk = {}
for _, path in ipairs(examples) do
  on_disk[path] = true
end
for _, name in ipairs(chapters) do
  for _, track in ipairs({ "en", "zh" }) do
    local content = read_file(track .. "/" .. name .. ".md")
    if content then
      local reported = {}
      for mentioned in content:gmatch("(examples/[%w%-_/]+%.lua)") do
        if not on_disk[mentioned] and not reported[mentioned] then
          reported[mentioned] = true
          errors = errors + 1
          print(string.format("MISSING EXAMPLE FILE: %s/%s.md -> %s",
            track, name, mentioned))
        end
      end
    end
  end
end

-- Reverse view: chapters nobody points at. A gap to fill, not a failure --
-- reference chapters (00-roadmap) legitimately have no example.
local orphans = {}
for _, name in ipairs(chapters) do
  if not referenced[name] then
    table.insert(orphans, name)
  end
end

print()
print("Chapter coverage")
print("----------------")
for _, name in ipairs(chapters) do
  local count = referenced[name]
  if count then
    print(string.format("  %-32s %d example%s", name, count, count == 1 and "" or "s"))
  else
    print(string.format("  %-32s -", name))
  end
end

print()
print("Summary")
print("-------")
print(string.format("Errors: %d", errors))
if #orphans > 0 then
  print(string.format("Chapters without examples: %d (%s)",
    #orphans, table.concat(orphans, ", ")))
end
print()

if errors > 0 then
  print("CHAPTER CHECK FAILED")
  os.exit(1)
end

print("CHAPTER CHECK PASSED")
