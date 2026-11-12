#!/usr/bin/env lua
-- check-readme-stats.lua
-- Checks the numbers the two README files state against the repository.
--
-- The quick stats table is the first thing a reader sees, and every number in
-- it is a claim about the repository: how many chapters, how many pitfall
-- articles, how many runnable examples, how many glossary terms, how many
-- roadmap stages. A number that drifts is a small lie in the most visible
-- place in the project, and nothing else in the build notices -- the count
-- was correct when the README was written and nobody ever came back.
--
-- So the numbers are read out of the README and compared with what the
-- repository actually holds. Both the quick stats table and the repository
-- layout tree are checked, because the tree repeats the counts in prose.
--
-- Every claim has to be found: a line that no longer states the number is
-- reported too, so a rewording cannot quietly drop a fact.
--
-- Usage: lua scripts/check-readme-stats.lua

local function shell_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function read_file(path)
  local fh = io.open(path, "r")
  if not fh then return nil end
  local content = fh:read("*a")
  fh:close()
  return content
end

-- How many files sit directly in a directory.
local function count_files(dir, pattern)
  local out = {}
  local ok, pipe = pcall(io.popen, string.format("find %s -maxdepth 1 -type f -name '%s' | sort",
    shell_quote(dir), pattern))
  if not ok or not pipe then return nil end
  for path in pipe:lines() do out[#out + 1] = path end
  pipe:close()
  return #out
end

-- How many files sit anywhere below a directory.
local function count_files_recursive(dir, pattern)
  local out = {}
  local ok, pipe = pcall(io.popen, string.format("find %s -type f -name '%s' | sort",
    shell_quote(dir), pattern))
  if not ok or not pipe then return nil end
  for path in pipe:lines() do out[#out + 1] = path end
  pipe:close()
  return #out
end

-- How many directories in the roadmap carry a stage number. The overview is
-- a file, not a stage.
local function count_stages()
  local out = {}
  local ok, pipe = pcall(io.popen, "find lua-mastery-roadmap -maxdepth 1 -type d | sort")
  if not ok or not pipe then return nil end
  for path in pipe:lines() do
    local name = path:match("([^/]+)$")
    if name and name:match("^%d+%-[^%d]") then out[#out + 1] = name end
  end
  pipe:close()
  return #out
end

-- How many terms the glossary holds. A term is a level three heading.
local function count_glossary(path)
  local content = read_file(path)
  if not content then return nil end
  local count = 0
  for line in content:gmatch("[^\n]+") do
    if line:match("^###%s") then count = count + 1 end
  end
  return count
end

-- The cross-cutting chapters are the ones whose name does not start with a
-- number.
local function count_crosscutting()
  local out = {}
  local ok, pipe = pcall(io.popen, "find en -maxdepth 1 -type f -name '*.md' | sort")
  if not ok or not pipe then return nil end
  for path in pipe:lines() do
    local name = path:match("([^/]+)$")
    if name and not name:match("^%d") then out[#out + 1] = name end
  end
  pipe:close()
  return #out
end

---------------------------------------------------------------------------
-- The facts
---------------------------------------------------------------------------

local FACTS = {
  ["en-chapters"] = function() return count_files("en", "*.md") end,
  ["zh-chapters"] = function() return count_files("zh", "*.md") end,
  ["en-pitfalls"] = function() return count_files("pitfalls/en", "*.md") end,
  ["zh-pitfalls"] = function() return count_files("pitfalls/中文版", "*.md") end,
  ["examples"] = function() return count_files_recursive("examples", "*.lua") end,
  ["examples-beginner"] = function() return count_files("examples/beginner", "*.lua") end,
  ["examples-intermediate"] = function() return count_files("examples/intermediate", "*.lua") end,
  ["examples-advanced"] = function() return count_files("examples/advanced", "*.lua") end,
  ["examples-projects"] = function() return count_files_recursive("examples/projects", "*.lua") end,
  ["glossary"] = function() return count_glossary("GLOSSARY.md") end,
  ["glossary-zh"] = function() return count_glossary("GLOSSARY.zh-CN.md") end,
  ["stages"] = count_stages,
  ["cross-cutting"] = count_crosscutting,
}

---------------------------------------------------------------------------
-- Where each README states each fact
---------------------------------------------------------------------------

-- The pattern captures the number the README claims. It is matched against
-- every line of the file.
local CLAIMS = {
  ["README.md"] = {
    { fact = "en-chapters", pattern = "^| Documentation | (%d+)" },
    { fact = "en-pitfalls", pattern = "^| Pitfalls | (%d+)" },
    { fact = "examples", pattern = "^| Examples | (%d+)" },
    { fact = "glossary", pattern = "^| Glossary | (%d+)" },
    { fact = "glossary-zh", pattern = "^| Glossary | (%d+)" },
    { fact = "stages", pattern = "^| Roadmap stages | (%d+)" },
    { fact = "en-chapters", pattern = "(%d+) English chapters" },
    { fact = "zh-chapters", pattern = "(%d+) Chinese chapters" },
    { fact = "cross-cutting", pattern = "(%d+) cross%-cutting" },
    { fact = "en-pitfalls", pattern = "(%d+) English gotcha articles" },
    { fact = "zh-pitfalls", pattern = "(%d+) Chinese gotcha articles" },
    { fact = "examples-beginner", pattern = "(%d+) beginner examples" },
    { fact = "examples-intermediate", pattern = "(%d+) intermediate examples" },
    { fact = "examples-advanced", pattern = "(%d+) advanced examples" },
    { fact = "examples-projects", pattern = "(%d+) stage projects" },
    { fact = "glossary", pattern = "(%d+) technical terms" },
    { fact = "glossary-zh", pattern = "(%d+) technical terms" },
  },
  ["README_zh-CN.md"] = {
    { fact = "en-chapters", pattern = "^| 文档 | (%d+)" },
    { fact = "en-pitfalls", pattern = "^| 陷阱 | (%d+)" },
    { fact = "examples", pattern = "^| 示例 | (%d+)" },
    { fact = "glossary", pattern = "^| 术语表 | (%d+)" },
    { fact = "glossary-zh", pattern = "^| 术语表 | (%d+)" },
    { fact = "stages", pattern = "^| 路线图阶段 | (%d+)" },
    { fact = "en-chapters", pattern = "(%d+) 章英文教程" },
    { fact = "zh-chapters", pattern = "(%d+) 章中文教程" },
    { fact = "cross-cutting", pattern = "(%d+) 跨领域" },
    { fact = "en-pitfalls", pattern = "(%d+) 篇英文常见错误" },
    { fact = "zh-pitfalls", pattern = "(%d+) 篇中文常见错误" },
    { fact = "examples-beginner", pattern = "(%d+) 个入门示例" },
    { fact = "examples-intermediate", pattern = "(%d+) 个中级示例" },
    { fact = "examples-advanced", pattern = "(%d+) 个高级示例" },
    { fact = "examples-projects", pattern = "(%d+) 个阶段项目" },
    { fact = "glossary", pattern = "(%d+) 术语参考" },
    { fact = "glossary-zh", pattern = "(%d+) 术语参考" },
  },
}

---------------------------------------------------------------------------
-- The check
---------------------------------------------------------------------------

local errors = 0
local checked = 0

for _, path in ipairs({ "README.md", "README_zh-CN.md" }) do
  local content = read_file(path)
  if not content then
    io.stderr:write("cannot read " .. path .. "\n")
    os.exit(1)
  end
  local lines = {}
  for line in content:gmatch("[^\n]+") do lines[#lines + 1] = line end

  for _, claim in ipairs(CLAIMS[path]) do
    local actual = FACTS[claim.fact]()
    if not actual then
      errors = errors + 1
      print(string.format("  %s: could not work out %s", path, claim.fact))
    else
      local found = false
      for _, line in ipairs(lines) do
        local claimed = line:match(claim.pattern)
        if claimed then
          found = true
          checked = checked + 1
          local number = tonumber(claimed)
          if number ~= actual then
            errors = errors + 1
            print(string.format("  %s: the README says %d for %s, but the repository holds %d",
              path, number, claim.fact, actual))
          end
          break
        end
      end
      if not found then
        -- A line that no longer states the number is a fact that is no
        -- longer checked, and that is how the drift starts.
        errors = errors + 1
        print(string.format("  %s: no line states %s any more", path, claim.fact))
      end
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("Numbers checked: %d", checked))
print(string.format("Mismatched:      %d", errors))
print()

if errors > 0 then
  print("README STAT CHECK FAILED")
  os.exit(1)
end

print("README STAT CHECK PASSED")
