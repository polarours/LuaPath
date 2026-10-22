#!/usr/bin/env lua

-- check-stage-refs.lua
-- Validates that "Stage NN" and "Chapter NN" references point at the right
-- thing.
--
-- The roadmap has two independent numberings that used to share one label:
-- 42 roadmap stages and 18 chapter numbers. A prerequisites list could say
-- "Stage 03 (Functions)" -- a chapter -- while stage 3 is actually
-- "Concurrency and Runtime Surfaces". The numbers collide, so the reader
-- cannot tell which one is meant.
--
-- How a reference is judged
-- ------------------------
-- Each reference carries a title ("Stage 12 -- State Machines"). The
-- checker knows every canonical title of every stage and every chapter, so
-- it can ask which of them the reference is pointing at. The reference is
-- accepted when the number it names is the best match for the title it
-- quotes:
--
--   * the title matches the named number exactly          -> accepted
--   * the title is a prefix of, or sits inside, a title
--     that belongs to the named number                     -> accepted
--   * some *other* number matches the title better        -> rejected
--
-- That last rule is what catches the real defect: "Chapter 12 -- State
-- Machines" names a chapter but quotes stage 12's title, so stage 12 wins
-- and the reference is reported.
--
-- A reference without a title ("(Stage 1)") is only checked for existence:
-- there is nothing to disambiguate.
--
-- The checker also verifies that a stage directory's own heading carries the
-- directory's number, which is how the roadmap renumbering silently drifted
-- apart between the English and the Chinese track.
--
-- Usage: lua scripts/check-stage-refs.lua [directories...]

local OVERVIEW = "lua-mastery-roadmap/00-overview.md"

-- Multi-byte literals never go into a Lua character class: a class matches
-- single bytes, so "[chapter]" would match any single byte of any of the
-- characters in it. These constants keep the byte sequences explicit.
local ZH_ZHANG = "\231\171\160"          -- chapter marker
local ZH_JIEDUAN = "\233\152\182\230\174\181"  -- stage marker
local ZH_COLON = "\239\188\154"          -- full width colon
local ZH_LPAREN = "\239\188\136"
local ZH_RPAREN = "\239\188\137"

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
-- Normalisation
---------------------------------------------------------------------------

-- The documents mix ASCII punctuation with em dashes, en dashes and
-- full-width punctuation. Fold the dashes first so the patterns below only
-- ever see ASCII delimiters.
local function fold(s)
  s = s:gsub("\226\128\148", "-")   -- em dash
  s = s:gsub("\226\128\147", "-")   -- en dash
  s = s:gsub("\239\188\141", "-")   -- horizontal bar
  return s
end

-- Lower-case, turn punctuation runs into spaces, and keep CJK bytes intact.
-- Bytes >= 0x80 survive so a Chinese title stays comparable with a Chinese
-- reference.
local function norm(s)
  s = fold(s):lower()
  s = s:gsub("[^%w\128-\255]+", " ")
  s = s:gsub("%s+", " ")
  s = s:gsub("^ ", ""):gsub(" $", "")
  return s
end

-- Character count, not byte count: a Chinese title must not out-score an
-- English one just because UTF-8 gives it three bytes per character.
local function ulen(s)
  local n = 0
  for i = 1, #s do
    local b = s:byte(i)
    if b < 128 or b >= 192 then n = n + 1 end
  end
  return n
end

---------------------------------------------------------------------------
-- Title catalogues
---------------------------------------------------------------------------

local stages = {}      -- number -> { title, ... }
local chapters = {}    -- number -> { title, ... }

local function add(map, number, title)
  number = tonumber(number)
  if not number then return end
  title = norm(title)
  if title == "" then return end
  map[number] = map[number] or {}
  for _, existing in ipairs(map[number]) do
    if existing == title then return end
  end
  map[number][#map[number] + 1] = title
end

-- The roadmap overview lists one heading per stage. That list is the
-- authoritative numbering.
local overview = read_file(OVERVIEW)
if not overview then
  io.stderr:write("cannot read " .. OVERVIEW .. "\n")
  os.exit(1)
end

local stage_numbers = {}
for line in overview:gmatch("[^\n]+") do
  local n, title = line:match("^### Stage (%d+): (.+)$")
  if n then
    add(stages, n, title)
    stage_numbers[#stage_numbers + 1] = tonumber(n)
  end
end

-- The stages must be numbered 1..N with no gap and no duplicate, otherwise
-- a renumbering has half-landed.
do
  local seen = {}
  local max = 0
  local dupes = {}
  for _, n in ipairs(stage_numbers) do
    if seen[n] then dupes[#dupes + 1] = n end
    seen[n] = true
    if n > max then max = n end
  end
  local missing = {}
  for i = 1, max do
    if not seen[i] then missing[#missing + 1] = i end
  end
  if #dupes > 0 or #missing > 0 then
    local parts = {}
    if #dupes > 0 then
      table.sort(dupes)
      parts[#parts + 1] = "duplicate stage numbers: " .. table.concat(dupes, ", ")
    end
    if #missing > 0 then
      parts[#parts + 1] = "missing stage numbers: " .. table.concat(missing, ", ")
    end
    print("STAGE NUMBERING: " .. table.concat(parts, "; "))
    os.exit(1)
  end
end

local max_stage = 0
for n in pairs(stages) do
  if n > max_stage then max_stage = n end
end

-- The chapter titles live in the heading of each chapter file.
local function load_chapters(dir)
  for _, path in ipairs(list_files(dir, "*.md")) do
    local base = path:match("^" .. dir .. "/(%d+)%-(.+)%.md$")
    if base then
      local content = read_file(path)
      local title = content and content:match("^# ([^\n]*)\n")
      if title then
        title = fold(title)
        title = title:gsub("^Chapter%s+%d+%s*:%s*", "")
        title = title:gsub("^%d+%s*", "")
        title = title:gsub("^[-:]%s*", "")
        title = title:gsub("^" .. ZH_ZHANG .. "%s*%d+%s*" .. ZH_ZHANG .. "%s*", "")
        title = title:gsub("^" .. ZH_ZHANG .. "%s*%d+%s*", "")
        add(chapters, base, title)
      end
    end
  end
end

load_chapters("en")
load_chapters("zh")

local max_chapter = 0
for n in pairs(chapters) do
  if n > max_chapter then max_chapter = n end
end

-- Stage projects carry their own title in their heading. The directory the
-- project sits in names the stage it belongs to, so the directory number and
-- the heading together give every stage a set of titles in both languages.
-- The heading's own number is checked separately below.
for _, path in ipairs(list_files("lua-mastery-roadmap", "*.md")) do
  local want = path:match("^lua%-mastery%-roadmap/(%d+)")
  local content = read_file(path)
  local h1 = content and content:match("^# ([^\n]*)\n")
  if h1 and want then
    h1 = fold(h1)
    local title = h1
    local stripped = h1:match("^Stage%s+%d+%.?%d*:?%s*(.+)$")
    if not stripped then
      stripped = h1:match("^第%s*%d+%.?%d*%s*" .. ZH_JIEDUAN .. "%s*" .. ZH_COLON .. "%s*(.+)$")
    end
    if not stripped then
      stripped = h1:match("^第%s*%d+%.?%d*%s*" .. ZH_JIEDUAN .. "%s*:%s*(.+)$")
    end
    if stripped then title = stripped end
    add(stages, want, title)
  end
end

---------------------------------------------------------------------------
-- Matching
---------------------------------------------------------------------------

-- Score how well a quoted title matches a canonical title. The first
-- component prefers an exact match over a partial one; the second is the
-- length of the shared text.
local function score(cand, title)
  if cand == "" or title == "" then return 0, 0 end
  if cand == title then return 2, ulen(cand) end
  if title:sub(1, #cand) == cand then return 1, ulen(cand) end
  if cand:sub(1, #title) == title then return 1, ulen(title) end
  if title:find(cand, 1, true) then return 1, ulen(cand) end
  return 0, 0
end

local function best_over(titles, cand)
  local best_tier, best_len = 0, 0
  for _, t in ipairs(titles) do
    local tier, len = score(cand, t)
    if tier > best_tier or (tier == best_tier and len > best_len) then
      best_tier, best_len = tier, len
    end
  end
  return best_tier, best_len
end

-- Words that describe a stage's level rather than naming a topic. A
-- reference whose title is just a level word ("Stage 21: Advanced") says
-- nothing about which stage it means, so only its number is checked.
local LEVEL_WORDS = {
  ["advanced"] = true,
  ["intermediate"] = true,
  ["beginner"] = true,
  ["expert"] = true,
  ["capstone"] = true,
  ["production"] = true,
  ["introductory"] = true,
  ["foundation"] = true,
  ["高级"] = true,
  ["中级"] = true,
  ["初级"] = true,
  ["专家"] = true,
  ["综合应用"] = true,
  ["生产级"] = true,
}

local function first_word(s)
  return s:match("^([^ ]*)")
end

---------------------------------------------------------------------------
-- Reference scanning
---------------------------------------------------------------------------

-- Find the next reference at or after `from`. English references are
-- "Stage 07" / "Chapter 12"; Chinese ones are "第 07 章" / "第 41 阶段" and
-- the older "阶段 14" / "章 07" spellings.
local function next_reference(line, from)
  local best = nil

  local function consider(s, e, kind, num)
    if not best or s < best.s then
      best = { s = s, e = e, kind = kind, num = num }
    end
  end

  -- Lua patterns have no alternation, so each spelling gets its own search
  -- and the earliest hit wins.
  local s, e, digits = line:find("[Ss]tages?%s*(%d+%.?%d*)", from)
  if s then consider(s, e, "stage", digits) end

  s, e, digits = line:find("[Cc]hapters?%s*(%d+%.?%d*)", from)
  if s then consider(s, e, "chapter", digits) end

  s, e, digits = line:find("第%s*(%d+%.?%d*)%s*" .. ZH_ZHANG, from)
  if s then consider(s, e, "chapter", digits) end

  s, e, digits = line:find("第%s*(%d+%.?%d*)%s*" .. ZH_JIEDUAN, from)
  if s then consider(s, e, "stage", digits) end

  s, e, digits = line:find(ZH_JIEDUAN .. "%s*(%d+%.?%d*)", from)
  if s then consider(s, e, "stage", digits) end

  s, e, digits = line:find(ZH_ZHANG .. "%s*(%d+%.?%d*)", from)
  if s then consider(s, e, "chapter", digits) end

  return best
end

-- A reference inside a markdown link to another site points at that site's
-- content -- "Programming in Lua -- Chapter 7" is a book chapter, not this
-- repository's chapter 7.
local function inside_external_link(line, pos)
  local search = 1
  while true do
    local ls, le, ltarget = line:find("%[[^%]]*%]%(([^%)]*)%)", search)
    if not ls then return false end
    if ls <= pos and pos <= le and ltarget:match("^https?://") then
      return true
    end
    search = le + 1
  end
end

-- Drop the decorations a title may carry: emphasis markers, backticks and
-- a trailing bracketed tag such as "[Easy]".
local function clean_candidate(s)
  s = s:gsub("[%*`]", "")
  s = s:gsub("%s*%[[^%]]*%]%s*$", "")
  s = s:gsub("%)%s*$", "")
  s = s:gsub(ZH_RPAREN .. "%s*$", "")
  s = s:gsub("%s+$", "")
  return s
end

-- Decide whether the text that follows a reference names a topic, and if so
-- which topic it is.
--
-- The shapes that occur in this repository:
--
--   "Chapter 02 -- Control Flow"     the topic follows a delimiter
--   "Chapter 01: Basics (strings)"    the topic follows a delimiter and is
--                                     followed by a gloss
--   "Schema Validation (Stage 17)"    the topic comes *before* the number
--   "Start with Stage 1 and ..."      prose, not a topic at all
--
-- Returning nil means "this reference carries no topic", so only its number
-- can be checked.
local function extract_candidate(tail)
  local s = tail:gsub("^%s+", "")

  -- "(Stage 17)" -- the topic is the exercise name in front of it.
  if s:sub(1, 1) == ")" or s:sub(1, 3) == ZH_RPAREN then
    return nil
  end

  -- "(Tables)" or "（元表）" -- the topic is inside the brackets.
  if s:sub(1, 1) == "(" or s:sub(1, 3) == ZH_LPAREN then
    local inner = s:match("^%(([^%)]*)%)")
    if not inner then
      inner = s:match("^" .. ZH_LPAREN .. "([^" .. ZH_RPAREN .. "]*)" .. ZH_RPAREN)
    end
    if inner then return clean_candidate(inner) end
    return nil
  end

  -- The topic must be introduced by a delimiter; otherwise the number is
  -- just mentioned in running text.
  local first = s:match("^([^%s])")
  if first ~= ":" and first ~= "-" and first ~= "|" and first ~= "=" and first ~= ZH_COLON then
    return nil
  end

  s = s:gsub("^[:=|%-]+%s*", "")
  s = s:gsub("^" .. ZH_COLON .. "%s*", "")
  s = s:gsub("^%s+", "")

  -- A trailing parenthetical is a gloss, not part of the topic.
  local cut = s:find("%(")
  local cut_wide = s:find(ZH_LPAREN, 1, true)
  if cut_wide and (not cut or cut_wide < cut) then cut = cut_wide end
  if cut then s = s:sub(1, cut - 1) end

  return clean_candidate(s)
end

-- A quoted topic that matches nothing at all is only worth reporting when it
-- looks like a topic: a capitalised word or a run of Chinese characters.
-- Running prose after a number ("and the corresponding chapters") is not a
-- mistranslation, it is prose.
local function looks_like_topic(s)
  local first = s:match("^([^%s])")
  if not first then return false end
  local byte = first:byte(1)
  if byte >= 128 then return true end
  return byte >= 65 and byte <= 90
end

---------------------------------------------------------------------------
-- The check
---------------------------------------------------------------------------

local directories = { ... }
if #directories == 0 then
  directories = { "en", "zh", "lua-mastery-roadmap", "pitfalls", "references" }
end

local errors = 0
local checked = 0

local function report(path, lineno, message)
  errors = errors + 1
  print(string.format("  %s:%d: %s", path, lineno, message))
end

local CATALOGUE = { stage = stages, chapter = chapters }

for _, dir in ipairs(directories) do
  for _, path in ipairs(list_files(dir, "*.md")) do
    local content = read_file(path)
    if content then
      local lineno = 0
      local in_code = false
      for raw in content:gmatch("([^\n]*)\n") do
        lineno = lineno + 1
        local line = fold(raw)

        -- Skip fenced code blocks: a "Stage 7" inside a sample is data.
        if line:match("^%s*```") then
          in_code = not in_code
        elseif not in_code then
          -- Collect every reference on the line first: a line can name two
          -- chapters, and each one's topic stops where the next one starts.
          local refs = {}
          local r = next_reference(line, 1)
          while r do
            refs[#refs + 1] = r
            r = next_reference(line, r.e + 1)
          end

          for index, ref in ipairs(refs) do
            local raw_num = ref.num
            local integer = tonumber(raw_num:match("^(%d+)"))
            local tail_end = refs[index + 1] and (refs[index + 1].s - 1) or #line
            local tail = line:sub(ref.e + 1, tail_end)

            -- A range ("Stages 01-10", "第 6-40 阶段") names more than one
            -- thing; check the endpoints and move on.
            local range_end = tail:match("^%s*[-~]%s*(%d+)")

            if not range_end and not inside_external_link(line, ref.s) then
              local kind = ref.kind
              local limit = (kind == "stage") and max_stage or max_chapter
              local label = (kind == "stage") and "stage" or "chapter"

              if not integer or integer < 1 or integer > limit then
                report(path, lineno, string.format(
                  "%s %s does not exist (valid %ss are 1-%d)",
                  label, tostring(raw_num), label, limit))
              else
                checked = checked + 1
                local candidate = extract_candidate(tail)
                local cand_norm = candidate and norm(candidate) or ""

                if cand_norm ~= "" and not LEVEL_WORDS[first_word(cand_norm)] then
                  local own_tier = best_over(CATALOGUE[kind][integer] or {}, cand_norm)

                  if own_tier == 0 then
                    -- Find who the quoted topic actually belongs to.
                    local best_tier, best_len = 0, 0
                    local best_kind, best_num = nil, nil
                    for other_kind, table_ref in pairs(CATALOGUE) do
                      for other_num, titles in pairs(table_ref) do
                        local tier, len = best_over(titles, cand_norm)
                        if tier > best_tier or (tier == best_tier and len > best_len) then
                          best_tier, best_len = tier, len
                          best_kind, best_num = other_kind, other_num
                        end
                      end
                    end

                    -- Stage 12 and chapter 12 share the number, so the kind
                    -- has to be compared as well.
                    if best_tier > 0 and (best_kind ~= kind or best_num ~= integer) then
                      report(path, lineno, string.format(
                        "%s %d quotes %q, which belongs to %s %d, not %s %d",
                        label, integer, candidate, best_kind, best_num,
                        kind, integer))
                    elseif best_tier == 0 and looks_like_topic(cand_norm) then
                      report(path, lineno, string.format(
                        "%s %d quotes %q, which matches no known stage or chapter",
                        label, integer, candidate))
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- A stage directory's own heading must carry that directory's number
---------------------------------------------------------------------------

for _, path in ipairs(list_files("lua-mastery-roadmap", "*.md")) do
  local want = path:match("^lua%-mastery%-roadmap/(%d+)")
  if want then
    local content = read_file(path)
    local h1 = content and content:match("^# ([^\n]*)\n")
    if h1 then
      h1 = fold(h1)
      local got = h1:match("^Stage%s+(%d+)")
      if not got then got = h1:match("^第%s*(%d+)") end
      if got and tonumber(got) ~= tonumber(want) then
        -- The directory numbers are zero padded ("01-beginner") and the
        -- headings are not ("Stage 1"), so compare the numbers.
        report(path, 1, string.format(
          "heading says stage %s but the file lives in stage directory %s",
          got, want))
      end
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("References checked: %d", checked))
print(string.format("Mismatched:         %d", errors))
print()

if errors > 0 then
  print("STAGE REFERENCE CHECK FAILED")
  os.exit(1)
end

print("STAGE REFERENCE CHECK PASSED")
