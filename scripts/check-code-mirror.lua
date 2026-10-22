#!/usr/bin/env lua

-- check-code-mirror.lua
-- Verifies that the code samples in the English and Chinese tracks are the
-- same code.
--
-- The two tracks are allowed to differ in prose, in headings and in the
-- comments inside a sample -- that is the point of a translation. What they
-- are not allowed to differ in is the program: a sample that reads
-- require("app") in one language and require("src.http.app") in the other
-- runs differently, and a Chinese reader who copies it gets a broken script.
--
-- Three things are compared for every mirrored pair of files:
--
--   * the number of fenced code blocks
--   * the shape of each block, with comments and string literal contents
--     removed, so that a translated message or a translated comment does
--     not count as a difference
--   * the arguments of every require() call, which name real files and so
--     must survive translation untouched
--
-- Usage: lua scripts/check-code-mirror.lua

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

---------------------------------------------------------------------------
-- Code block extraction
---------------------------------------------------------------------------

-- Returns a list of { lang = "...", lines = { ... } } for every fenced block.
local function code_blocks(content)
  local blocks = {}
  local lines = {}
  for line in (content .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end

  local i = 1
  while i <= #lines do
    local fence = lines[i]:match("^%s*```(.*)$")
    if fence then
      local lang = fence:match("^%s*(%S*)") or ""
      local body = {}
      i = i + 1
      while i <= #lines and not lines[i]:match("^%s*```") do
        body[#body + 1] = lines[i]
        i = i + 1
      end
      blocks[#blocks + 1] = { lang = lang:lower(), lines = body }
    end
    i = i + 1
  end

  return blocks
end

---------------------------------------------------------------------------
-- Normalising a line of code
---------------------------------------------------------------------------

-- How each language spells a comment.
local COMMENT_STYLE = {
  lua = "dash",
  bash = "hash", sh = "hash", shell = "hash", zsh = "hash",
  python = "hash", py = "hash", ruby = "hash", rb = "hash",
  yaml = "hash", yml = "hash", toml = "hash", ini = "hash", conf = "hash",
  javascript = "slash", js = "slash", typescript = "slash", ts = "slash",
  c = "slash", cpp = "slash", java = "slash", go = "slash", rust = "slash",
  css = "slash", sql = "slash",
}

local CODE_LANGS = {
  lua = true, bash = true, sh = true, shell = true, zsh = true,
  python = true, py = true, ruby = true, rb = true,
  yaml = true, yml = true, toml = true, ini = true, conf = true,
  javascript = true, js = true, typescript = true, ts = true,
  c = true, cpp = true, java = true, go = true, rust = true,
  css = true, sql = true, json = true, html = true,
}

-- Strip the comments and the string literal contents from one line, so that
-- only the shape of the program is left.
local function shape_of(lang, line)
  local style = COMMENT_STYLE[lang]
  local out = {}
  local i = 1
  local n = #line

  while i <= n do
    local c = line:sub(i, i)

    if c == '"' or c == "'" then
      local quote = c
      i = i + 1
      while i <= n do
        local ch = line:sub(i, i)
        if ch == "\\" then
          i = i + 2
        elseif ch == quote then
          i = i + 1
          break
        else
          i = i + 1
        end
      end
      out[#out + 1] = quote .. "S" .. quote

    elseif style == "dash" and c == "-" and line:sub(i, i + 1) == "--" then
      break

    elseif style == "hash" and c == "#" then
      break

    elseif style == "slash" and c == "/" and line:sub(i, i + 1) == "//" then
      break

    elseif style == "slash" and c == "/" and line:sub(i, i + 1) == "/*" then
      local close = line:find("*/", i + 2, true)
      if not close then break end
      i = close + 1
      out[#out + 1] = "/*C*/"

    else
      out[#out + 1] = c
      i = i + 1
    end
  end

  local text = table.concat(out)
  -- Whitespace is not semantic in Lua, and the two tracks do not agree on
  -- the spacing inside table literals. Compare the token stream, not the
  -- layout.
  text = text:gsub("%s+", "")
  return text
end

-- The arguments of every require() call. These name real files, so they have
-- to be identical in both languages.
local function requires_of(lang, body)
  if lang ~= "lua" then return {} end
  local out = {}
  for _, line in ipairs(body) do
    for arg in line:gmatch('require%s*%(%s*"([^"]*)"') do
      out[#out + 1] = arg
    end
    for arg in line:gmatch("require%s*%(%s*'([^']*)'") do
      out[#out + 1] = arg
    end
  end
  table.sort(out)
  return out
end

---------------------------------------------------------------------------
-- The mirrored pairs
---------------------------------------------------------------------------

local pairs_to_check = {}

local function add_pair(en_path, zh_path)
  if read_file(zh_path) then
    pairs_to_check[#pairs_to_check + 1] = { en_path, zh_path }
  end
end

-- en/... mirrors zh/...
for _, path in ipairs(list_files("en", "*.md")) do
  add_pair(path, "zh/" .. path:sub(4))
end

-- pitfalls/en/... mirrors pitfalls/中文版/...
for _, path in ipairs(list_files("pitfalls/en", "*.md")) do
  add_pair(path, "pitfalls/中文版/" .. path:match("([^/]+)$"))
end

-- references/xxx.md mirrors references/xxx.zh-CN.md
for _, path in ipairs(list_files("references", "*.md")) do
  if not path:match("%.zh%-CN%.md$") then
    add_pair(path, path:gsub("%.md$", ".zh-CN.md"))
  end
end

-- The roadmap's stage and project READMEs.
for _, path in ipairs(list_files("lua-mastery-roadmap", "README.md")) do
  add_pair(path, path:gsub("README%.md$", "README.zh-CN.md"))
end
for _, path in ipairs(list_files("lua-mastery-roadmap", "00-overview.md")) do
  add_pair(path, path:gsub("00%-overview%.md$", "00-overview.zh-CN.md"))
end

-- The root level documents.
add_pair("README.md", "README_zh-CN.md")
add_pair("GLOSSARY.md", "GLOSSARY.zh-CN.md")

---------------------------------------------------------------------------
-- The check
---------------------------------------------------------------------------

local errors = 0
local pairs_checked = 0
local blocks_checked = 0

for _, pair in ipairs(pairs_to_check) do
  local en_path, zh_path = pair[1], pair[2]
  local en_blocks = code_blocks(read_file(en_path))
  local zh_blocks = code_blocks(read_file(zh_path))
  pairs_checked = pairs_checked + 1

  if #en_blocks ~= #zh_blocks then
    errors = errors + 1
    print(string.format("  %s <-> %s: %d code blocks in English, %d in Chinese",
      en_path, zh_path, #en_blocks, #zh_blocks))
  else
    for index = 1, #en_blocks do
      local en_block, zh_block = en_blocks[index], zh_blocks[index]
      if en_block.lang ~= zh_block.lang then
        errors = errors + 1
        print(string.format("  %s <-> %s: code block %d is %q in English but %q in Chinese",
          en_path, zh_path, index, en_block.lang, zh_block.lang))
      elseif CODE_LANGS[en_block.lang] then
        blocks_checked = blocks_checked + 1
        -- Compare the sequence of code lines, not the raw lines: the two
        -- languages may carry a different number of comment lines, and a
        -- missing comment must not shift every later line.
        local en_shape, zh_shape = {}, {}
        for _, line in ipairs(en_block.lines) do
          local s = shape_of(en_block.lang, line)
          if s ~= "" then en_shape[#en_shape + 1] = s end
        end
        for _, line in ipairs(zh_block.lines) do
          local s = shape_of(zh_block.lang, line)
          if s ~= "" then zh_shape[#zh_shape + 1] = s end
        end
        for i = 1, math.max(#en_shape, #zh_shape) do
          if en_shape[i] ~= zh_shape[i] then
            errors = errors + 1
            print(string.format("  %s <-> %s: code block %d, line %d differs",
              en_path, zh_path, index, i))
            print(string.format("    EN: %s", en_shape[i] or "(no such line)"))
            print(string.format("    ZH: %s", zh_shape[i] or "(no such line)"))
            break
          end
        end

        local en_req = requires_of(en_block.lang, en_block.lines)
        local zh_req = requires_of(zh_block.lang, zh_block.lines)
        if table.concat(en_req, ",") ~= table.concat(zh_req, ",") then
          errors = errors + 1
          print(string.format("  %s <-> %s: code block %d requires different modules",
            en_path, zh_path, index))
          print(string.format("    EN: %s", table.concat(en_req, ", ")))
          print(string.format("    ZH: %s", table.concat(zh_req, ", ")))
        end
      end
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("Mirrored files:    %d", pairs_checked))
print(string.format("Code blocks:       %d", blocks_checked))
print(string.format("Mismatched:        %d", errors))
print()

if errors > 0 then
  print("CODE MIRROR CHECK FAILED")
  os.exit(1)
end

print("CODE MIRROR CHECK PASSED")
