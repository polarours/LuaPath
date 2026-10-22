#!/usr/bin/env lua

-- check-stage-files.lua
-- Verifies that the roadmap's project READMEs describe the projects that are
-- actually on disk.
--
-- A stage README carries two promises to the reader: the command under "How
-- to Run" and the tree under "Project Structure" or "Files". Both name
-- files. When a project is renamed or a planned exercise is never written,
-- the README keeps naming the old file, and the reader who copies the
-- command gets "No such file or directory" -- or worse, believes a file
-- exists that does not.
--
-- The checker therefore reads the file names out of those two sections and
-- looks each one up in the project directory.
--
-- Usage: lua scripts/check-stage-files.lua

local ROOT = "lua-mastery-roadmap"

local function read_file(path)
  local fh = io.open(path, "r")
  if not fh then return nil end
  local content = fh:read("*a")
  fh:close()
  return content
end

local function list_files(dir, pattern)
  local out = {}
  local ok, pipe = pcall(io.popen, string.format(
    "find %s -type f -name '%s' | sort", "'" .. dir:gsub("'", "'\\''") .. "'", pattern))
  if not ok or not pipe then return out end
  for path in pipe:lines() do out[#out + 1] = path end
  pipe:close()
  return out
end

-- The files that actually live in a project directory, by base name.
local function files_in(dir)
  local out = {}
  for _, path in ipairs(list_files(dir, "*")) do
    local name = path:match("([^/]+)$")
    if name then out[name] = true end
  end
  return out
end

-- A name in a README is either a bare file name or a path relative to the
-- project directory. Both forms have to resolve.
local function resolves(dir, present, name)
  if name:find("/") then
    local fh = io.open(dir .. "/" .. name, "r")
    if fh then fh:close() return true end
    return false
  end
  return present[name] == true
end

local errors = 0
local checked = 0

local function report(path, message)
  errors = errors + 1
  print(string.format("  %s: %s", path, message))
end

-- The extensions a project file can have. Restricting the check to these
-- keeps prose like `os.clock` or `string.format` from being read as a file
-- name.
local FILE_EXTENSIONS = {
  ["lua"] = true, ["c"] = true, ["h"] = true, ["md"] = true, ["ini"] = true,
  ["json"] = true, ["yml"] = true, ["yaml"] = true, ["txt"] = true, ["cfg"] = true,
  ["sh"] = true, ["bat"] = true, ["zip"] = true, ["so"] = true,
}

-- The section headings that hold a file list, in both languages.
local SECTION_HEADINGS = {
  "Project Structure", "Files", "Projects", "Architecture", "What's Included",
  "项目结构", "文件", "项目", "架构",
}

for _, path in ipairs(list_files(ROOT, "README*.md")) do
  local dir = path:match("^(.*)/[^/]*$")
  local content = read_file(path)
  if dir and content then
    local present = files_in(dir)

    -- The "How to Run" command: `lua 01-ini-parser.lua`, and the C build
    -- command: `gcc -o embed_lua 05-embed-lua.c`.
    for target in content:gmatch("\n%s*lua[^%s]*%s+([%w%._/-]+%.lua)") do
      checked = checked + 1
      if not resolves(dir, present, target) then
        report(path, string.format("run command names %s, which does not exist", target))
      end
    end
    for target in content:gmatch("\n%s*gcc%s+[^%s]+%s+([%w%._/-]+%.c)") do
      checked = checked + 1
      if not resolves(dir, present, target) then
        report(path, string.format("build command names %s, which does not exist", target))
      end
    end

    -- The file tree or list. The names are checked as the section is
    -- collected: a later heading closes the section, so waiting until the
    -- end of the file would lose every section but the last.
    local in_section = false
    for line in (content .. "\n"):gmatch("(.-)\n") do
      -- string.match returns the captured substrings, not the whole match.
      local heading = line:match("^##%s+(.-)%s*$")
      if heading then
        in_section = false
        for _, name in ipairs(SECTION_HEADINGS) do
          if heading == name then in_section = true end
        end
      elseif in_section then
        for name in line:gmatch("[%w%._-]+%.[%a]+") do
          local extension = name:match("%.([%a]+)$")
          -- Skip placeholders and globs: `<project-name>.lua`, `test_*.lua`.
          if extension and FILE_EXTENSIONS[extension:lower()] and not name:find("[<>*%?]") then
            checked = checked + 1
            if not resolves(dir, present, name) then
              report(path, string.format("structure section names %s, which does not exist", name))
            end
          end
        end
      end
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("File names checked: %d", checked))
print(string.format("Mismatched:         %d", errors))
print()

if errors > 0 then
  print("STAGE FILE CHECK FAILED")
  os.exit(1)
end

print("STAGE FILE CHECK PASSED")
