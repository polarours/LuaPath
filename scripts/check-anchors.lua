#!/usr/bin/env lua

-- check-anchors.lua
-- Validates that the anchors in internal markdown links actually exist.
-- Usage: lua scripts/check-anchors.lua [directories...]
--
-- The link checker in check-links.sh verifies that a link's *path* exists.
-- It does not look at the fragment, so a link to
-- "chapter.md#section-that-was-renamed" passes even though the reader lands
-- nowhere. This script closes that gap.
--
-- Anchors follow GitHub's rule: the heading is lowercased, punctuation is
-- dropped, and spaces become hyphens.

local args = { ... }
local directories = args
if #directories == 0 then
  directories = { "en", "zh", "lua-mastery-roadmap", "pitfalls", "references" }
end

-- Decode a UTF-8 string into code points. Lua 5.1 has no utf8 library, and
-- the anchor rules need to look at whole characters, not bytes.
local function codepoints(s)
  local out = {}
  local i, n = 1, #s
  while i <= n do
    local b = s:byte(i)
    local cp, len
    if b < 0x80 then
      cp, len = b, 1
    elseif b < 0xE0 then
      cp = (b % 0x20) * 0x40 + (s:byte(i + 1) % 0x3F)
      len = 2
    elseif b < 0xF0 then
      cp = (b % 0x10) * 0x1000 + (s:byte(i + 1) % 0x3F) * 0x40 + (s:byte(i + 2) % 0x3F)
      len = 3
    else
      cp = (b % 0x08) * 0x40000 + (s:byte(i + 1) % 0x3F) * 0x1000 +
           (s:byte(i + 2) % 0x3F) * 0x40 + (s:byte(i + 3) % 0x3F)
      len = 4
    end
    out[#out + 1] = { cp = cp, len = len }
    i = i + len
  end
  return out
end

-- Unicode ranges GitHub drops when it builds an anchor: general punctuation,
-- CJK symbols and punctuation, the fullwidth forms, and the few stray
-- symbols this repository uses. Everything else non-ASCII (CJK ideographs,
-- Greek, Cyrillic) is a letter and is kept.
local function is_dropped_punctuation(cp)
  if cp >= 0x2000 and cp <= 0x206F then return true end   -- general punctuation
  if cp >= 0x3000 and cp <= 0x303F then return true end   -- CJK punctuation
  if cp >= 0xFF00 and cp <= 0xFFEF then return true end   -- fullwidth forms
  if cp == 0x00B7 or cp == 0x2022 then return true end     -- middle dot, bullet
  return false
end

-- GitHub-style slug of a heading.
local function slug(heading)
  local s = heading:gsub("`", ""):gsub("%*", "")
  s = s:lower()
  local out = {}
  local pos = 1
  for _, ch in ipairs(codepoints(s)) do
    local piece = s:sub(pos, pos + ch.len - 1)
    pos = pos + ch.len
    local cp = ch.cp
    if cp < 128 then
      local c = piece
      if c:match("[%w_%-]") then
        out[#out + 1] = c
      elseif c == " " then
        out[#out + 1] = "-"
      end
    elseif not is_dropped_punctuation(cp) then
      out[#out + 1] = piece
    end
  end
  return table.concat(out)
end

local function read_file(path)
  local fh = io.open(path, "r")
  if not fh then return nil end
  local content = fh:read("*a")
  fh:close()
  return content
end

local function list_markdown(dir)
  local files = {}
  local ok, pipe = pcall(io.popen, string.format("find %s -type f -name '*.md' | sort",
    "'" .. dir:gsub("'", "'\\''") .. "'"))
  if not ok or not pipe then return files end
  for line in pipe:lines() do files[#files + 1] = line end
  pipe:close()
  return files
end

-- Slugs of every heading in a markdown file.
local slug_cache = {}
local function file_slugs(path)
  if slug_cache[path] then return slug_cache[path] end
  local set = {}
  local content = read_file(path)
  if content then
    for line in content:gmatch("[^\n]*") do
      local heading = line:match("^#+%s+(.*)$")
      if heading then
        set[slug(heading)] = true
      end
    end
  end
  slug_cache[path] = set
  return set
end

local function dirname(path)
  return path:match("^(.*)/[^/]*$") or "."
end

local errors = 0
local checked = 0

print("LuaPath Anchor Checker")
print("========================")
print()

for _, dir in ipairs(directories) do
  local files = list_markdown(dir)
  if #files == 0 then
    print("  (no markdown files under " .. dir .. ")")
  end
  for _, file in ipairs(files) do
    local content = read_file(file)
    if content then
      -- gmatch yields only the first capture, so the URL is the single
      -- capture here and the link text is matched without capturing.
      for url in content:gmatch("%[[^%]]*%]%(([^%)]+)%)") do
        if not url:match("^http") and not url:match("^mailto:") and url:find("#", 1, true) then
          local path, anchor = url:match("^([^#]*)#(.*)$")
          if path and path ~= "" then
            local target = dirname(file) .. "/" .. path
            -- A missing target is a broken *path*, which check-links.sh
            -- already reports; only the anchor is this script's business.
            if read_file(target) then
              checked = checked + 1
              local slugs = file_slugs(target)
              if not slugs[anchor] then
                errors = errors + 1
                print(string.format("  BROKEN ANCHOR: %s -> %s#%s", file, path, anchor))
              end
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
print(string.format("Anchors checked: %d", checked))
print(string.format("Broken anchors:  %d", errors))
print()

if errors > 0 then
  print("ANCHOR CHECK FAILED")
  os.exit(1)
end

print("ANCHOR CHECK PASSED")
