#!/usr/bin/env lua
-- test-version-facts.lua
--
-- Checks the version comparison tables in the reference documents against the
-- runtime that is actually executing this script.
--
-- The tables are the repository's answer to "what is different between the
-- Lua versions?". A reader takes them at face value, so a wrong cell is a
-- wrong answer. There are two copies of that table -- the long one in
-- references/VERSION_DIFFERENCES.md and the short one on the quick reference
-- card -- and until now only the long one was checked. The short one had
-- drifted: it had no 5.5 column, it called LuaJIT's `_ENV` support
-- "partial" when LuaJIT has no `_ENV` at all, and it credited LuaJIT with
-- integer types it does not have. One cell of the long table was wrong as
-- well -- it gave LuaJIT ephemerons -- and it survived because that row was
-- on the skip list.
--
-- So the test now:
--
--   * reads every version table in the repository, in both language tracks;
--   * probes the running runtime for each row and fails when the cell for
--     this runtime disagrees with what the runtime does;
--   * fails when a row has no probe, because an unprobed row is a row that
--     can be wrong without anybody noticing;
--   * fails when a table has no column for the runtime running the test,
--     because a table that does not cover a supported version cannot answer
--     the reader's question about it;
--   * compares the tables with each other, so the two copies cannot drift
--     apart and the two languages cannot disagree about the same cell.
--
-- Usage: lua tests/test-version-facts.lua

-- The check mark and the cross, as the document writes them. Lua 5.1 has
-- no \u escape, so the bytes go in directly.
local CHECK = "\226\156\147"  -- U+2713 CHECK MARK
local CROSS = "\226\156\151" -- U+2717 BALLOT X

-- Every version table in the repository. The two documents that hold the
-- same table in the two languages, and the two places that hold it in one
-- language, are cross-checked against each other below.
local DOCS = {
  "references/VERSION_DIFFERENCES.md",
  "references/VERSION_DIFFERENCES.zh-CN.md",
  "references/QUICK_REFERENCE.md",
  "references/QUICK_REFERENCE.zh-CN.md",
}

-- The same table in the two language tracks. A row that is present in one
-- and missing in the other is a hole in the translation.
local LANGUAGE_PAIRS = {
  { "references/VERSION_DIFFERENCES.md", "references/VERSION_DIFFERENCES.zh-CN.md" },
  { "references/QUICK_REFERENCE.md", "references/QUICK_REFERENCE.zh-CN.md" },
}

-- The same table in two places of one language. The two copies have to say
-- the same thing, otherwise a reader who finds one of them gets a different
-- answer depending on which one they opened.
local SAME_LANGUAGE_PAIRS = {
  { "references/VERSION_DIFFERENCES.md", "references/QUICK_REFERENCE.md" },
  { "references/VERSION_DIFFERENCES.zh-CN.md", "references/QUICK_REFERENCE.zh-CN.md" },
}

-- The Chinese row names, mapped onto the English ones, so that both tracks
-- are checked by the same probes and can be compared cell by cell.
local ZH_ALIASES = {
  ["数值类型"] = "Number Types",
  ["整数除法"] = "Integer Division",
  ["按位运算符"] = "Bitwise Operators",
  ["_ENV"] = "_ENV",
  ["setfenv/getfenv"] = "setfenv/getfenv",
  ["分代 GC"] = "Generational GC",
  ["to-be-closed 变量"] = "To-Be-Closed Vars",
  ["Ephemeron 表"] = "Ephemeron Tables",
  ["goto 语句"] = "goto Statement",
  ["位运算库"] = "Bitwise Library",
  ["__len 元方法"] = "__len Metamethod",
  ["包机制"] = "Package System",
  ["FFI"] = "FFI",
  ["JIT 编译"] = "JIT Compilation",
}

local function read_file(path)
  local fh = io.open(path, "r")
  if not fh then return nil end
  local content = fh:read("*a")
  fh:close()
  return content
end

-- Lua 5.1's load() only takes a function; loadstring() takes the source.
local function compiles(source)
  local loader = loadstring or load
  if not loader then return false end
  local ok, chunk = pcall(loader, source, "probe")
  return ok and chunk ~= nil
end

---------------------------------------------------------------------------
-- Which runtime is this?
---------------------------------------------------------------------------

local function current_column()
  if type(jit) == "table" then return "LuaJIT" end
  local version = _VERSION:match("(%d+%.%d+)")
  if version == "5.1" then return "5.1" end
  if version == "5.2" then return "5.2" end
  if version == "5.3" then return "5.3" end
  if version == "5.4" then return "5.4" end
  if version == "5.5" then return "5.5" end
  return nil
end

---------------------------------------------------------------------------
-- The probes
---------------------------------------------------------------------------

-- Each probe returns the word the cell has to carry. A feature that is
-- either there or not returns CHECK or CROSS; a feature that is spelled
-- differently in each version returns that spelling.
local PROBES = {
  ["Number Types"] = function()
    -- type() says "number" for both; math.type() tells them apart, and it
    -- only exists from 5.3 on.
    if type(math.type) == "function" and math.type(1) == "integer" then
      return "int"
    end
    return "float"
  end,

  ["Integer Division"] = function()
    if compiles("return 7 // 2") then return "`//`" end
    return CROSS
  end,

  ["Bitwise Operators"] = function()
    if compiles("return 7 & 3") then return CHECK end
    return CROSS
  end,

  ["_ENV"] = function()
    if type(_ENV) == "table" then return CHECK end
    return CROSS
  end,

  ["setfenv/getfenv"] = function()
    if type(setfenv) == "function" then return CHECK end
    return CROSS
  end,

  ["Generational GC"] = function()
    if pcall(collectgarbage, "generational") then return CHECK end
    return CROSS
  end,

  ["To-Be-Closed Vars"] = function()
    if compiles("local x <close> = nil") then return CHECK end
    return CROSS
  end,

  ["Ephemeron Tables"] = function()
    -- An ephemeron is observable. Put a weak-keyed entry whose value refers
    -- back to its own key: with ephemerons the value is only reachable
    -- through the weak table, so key and value go away together and the
    -- entry disappears. Without them -- 5.1 and LuaJIT -- the value keeps
    -- the key alive and the entry stays.
    local weak = setmetatable({}, { __mode = "k" })
    do
      local key = {}
      weak[key] = { key }
    end
    collectgarbage("collect")
    collectgarbage("collect")
    local left = 0
    for _ in pairs(weak) do left = left + 1 end
    if left > 0 then return CROSS end
    return CHECK
  end,

  ["goto Statement"] = function()
    if compiles("goto skip ::skip::") then return CHECK end
    return CROSS
  end,

  ["Bitwise Library"] = function()
    -- The library, not the operators: 5.2 shipped bit32, 5.3 kept it but
    -- deprecated it, 5.4 dropped it for the operators, and LuaJIT has bit.
    if pcall(require, "bit32") then return "`bit32`" end
    if pcall(require, "bit") then return "`bit.*`" end
    return CROSS
  end,

  ["__len Metamethod"] = function()
    local t = setmetatable({ 1, 2, 3 }, { __len = function() return 99 end })
    if #t == 99 then return CHECK end
    return CROSS
  end,

  ["Package System"] = function()
    -- 5.1 and LuaJIT still provide module(); everything newer does not.
    if type(module) == "function" then return "`module`" end
    return "`require`"
  end,

  ["FFI"] = function()
    if pcall(require, "ffi") then return CHECK end
    return CROSS
  end,

  ["JIT Compilation"] = function()
    if type(jit) == "table" then return CHECK end
    return CROSS
  end,
}

---------------------------------------------------------------------------
-- Reading a version table
---------------------------------------------------------------------------

-- Split a markdown table row into its cells. The row has to start and end
-- with a bar; the empty piece after the last bar is not a cell.
local function split_cells(line)
  local cells = {}
  local first = line:find("|", 1, true)
  if not first then return cells end
  local pos = first + 1
  while true do
    local last = line:find("|", pos, true)
    if not last then break end
    cells[#cells + 1] = line:sub(pos, last - 1):gsub("^%s*(.-)%s*$", "%1")
    pos = last + 1
  end
  return cells
end

-- The name of a row, with the bold markers and the backticks removed, so
-- that "**`setfenv`/`getfenv`**" and "**setfenv/getfenv**" are the same row.
local function feature_key(raw)
  local s = raw:gsub("%*", ""):gsub("`", ""):gsub("^%s*(.-)%s*$", "%1")
  return ZH_ALIASES[s] or s
end

-- The words the Chinese track uses where the English one uses a word.
-- They are folded back onto the English spelling, so that a cell can be
-- compared with a probe that answers in English.
local CANONICAL = {
  ["整数"] = "int",
  ["浮点"] = "float",
}

-- The part of a cell a probe has to agree with: the check mark or the
-- cross when the cell starts with one, otherwise the first word.
local function cell_head(cell)
  if cell:sub(1, #CHECK) == CHECK then return CHECK end
  if cell:sub(1, #CROSS) == CROSS then return CROSS end
  local word = cell:match("^([^%s]+)") or cell
  return CANONICAL[word] or word
end

-- Find the version table in a document: the header row is the one whose
-- cells name a version, and the line below it is the separator.
local function parse_version_table(content)
  local lines = {}
  for line in content:gmatch("[^\n]+") do lines[#lines + 1] = line end

  for i = 1, #lines - 1 do
    local separator = lines[i + 1]
    if separator:match("^|%s*%-") then
      local header = split_cells(lines[i])
      local has_version = false
      for _, cell in ipairs(header) do
        if cell:match("^5%.%d$") or cell == "LuaJIT" then has_version = true end
      end
      if has_version then
        local columns = {}
        for index, name in ipairs(header) do columns[name] = index end

        local rows = {}
        local j = i + 2
        while j <= #lines and lines[j]:match("^|") do
          local cells = split_cells(lines[j])
          if #cells == #header then
            rows[#rows + 1] = { key = feature_key(cells[1]), cells = cells }
          end
          j = j + 1
        end
        return { columns = columns, header = header, rows = rows }
      end
    end
  end

  return nil
end

---------------------------------------------------------------------------
-- Load every table
---------------------------------------------------------------------------

local tables = {}
local errors = 0

for _, path in ipairs(DOCS) do
  local content = read_file(path)
  if not content then
    io.stderr:write("cannot read " .. path .. "\n")
    os.exit(1)
  end
  local parsed = parse_version_table(content)
  if not parsed then
    io.stderr:write("no version table found in " .. path .. "\n")
    os.exit(1)
  end
  tables[path] = parsed
end

local column = current_column()
if not column then
  print("unknown runtime " .. _VERSION .. " -- nothing to check")
  os.exit(0)
end

---------------------------------------------------------------------------
-- Check every table against the runtime
---------------------------------------------------------------------------

local checked = 0

for _, path in ipairs(DOCS) do
  local table_ = tables[path]

  -- A table that does not have a column for the runtime running this test
  -- cannot answer the reader's question about that runtime. Reporting
  -- "nothing to check" and exiting successfully would hide exactly the
  -- case that matters.
  local column_index = table_.columns[column]
  if not column_index then
    errors = errors + 1
    print(string.format("  %s: the table has no column for %s", path, column))
  end

  for _, row in ipairs(table_.rows) do
    local probe = PROBES[row.key]
    if not probe then
      -- Every row has to be settled by a probe. A row without one is a row
      -- that can be wrong without anybody noticing.
      errors = errors + 1
      print(string.format("  %s: the row %q has no probe", path, row.key))
    elseif column_index then
      local cell = row.cells[column_index]
      local result = probe()
      checked = checked + 1

      -- The cell starts with the word: "✓", "✗", "`//`", "operators".
      local word = cell_head(cell)
      if word ~= result then
        errors = errors + 1
        print(string.format("  %s: the table says %q for %s, but this runtime says %s",
          path, cell, column, tostring(result)))
      end
    end
  end
end

---------------------------------------------------------------------------
-- Compare the tables with each other
---------------------------------------------------------------------------

-- What two cells have to agree about when the documents are in different
-- languages: the check mark or the cross, and the names in backticks. The
-- words around them are translated, so they are not comparable.
local function cell_signature(cell)
  local tokens = {}
  for token in cell:gmatch("`([^`]*)`") do tokens[#tokens + 1] = token end
  return cell_head(cell) .. "|" .. table.concat(tokens, ",")
end

local function rows_by_key(table_)
  local by_key = {}
  for _, row in ipairs(table_.rows) do by_key[row.key] = row end
  return by_key
end

-- The same table in the two language tracks.
for _, pair in ipairs(LANGUAGE_PAIRS) do
  local left_path, right_path = pair[1], pair[2]
  local left, right = tables[left_path], tables[right_path]
  local left_rows, right_rows = rows_by_key(left), rows_by_key(right)

  for _, row in ipairs(left.rows) do
    local other = right_rows[row.key]
    if not other then
      errors = errors + 1
      print(string.format("  %s has the row %q, but %s does not",
        left_path, row.key, right_path))
    else
      local left_index = left.columns[column]
      local right_index = right.columns[column]
      if left_index and right_index then
        local a = cell_signature(row.cells[left_index])
        local b = cell_signature(other.cells[right_index])
        if a ~= b then
          errors = errors + 1
          print(string.format("  %s and %s disagree about %q for %s",
            left_path, right_path, row.key, column))
        end
      end
    end
  end

  for _, row in ipairs(right.rows) do
    if not left_rows[row.key] then
      errors = errors + 1
      print(string.format("  %s has the row %q, but %s does not",
        right_path, row.key, left_path))
    end
  end
end

-- The same table in two places of one language. Here the cells have to be
-- identical, down to the wording.
for _, pair in ipairs(SAME_LANGUAGE_PAIRS) do
  local left_path, right_path = pair[1], pair[2]
  local left, right = tables[left_path], tables[right_path]

  local left_columns, right_columns = 0, 0
  for _ in pairs(left.columns) do left_columns = left_columns + 1 end
  for _ in pairs(right.columns) do right_columns = right_columns + 1 end
  if left_columns ~= right_columns then
    errors = errors + 1
    print(string.format("  %s covers %d versions, %s covers %d",
      left_path, left_columns, right_path, right_columns))
  end

  local right_rows = rows_by_key(right)
  for _, row in ipairs(left.rows) do
    local other = right_rows[row.key]
    if other then
      for name, index in pairs(left.columns) do
        local other_index = right.columns[name]
        if not other_index then
          errors = errors + 1
          print(string.format("  %s has no column for %s, but %s does",
            right_path, name, left_path))
        elseif row.cells[index] ~= other.cells[other_index] then
          errors = errors + 1
          print(string.format("  %s says %q for %q, %s says %q",
            left_path, row.cells[index], row.key,
            right_path, other.cells[other_index]))
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Summary
---------------------------------------------------------------------------

print()
print("Summary")
print("-------")
print(string.format("Runtime:  %s (%s)", column, _VERSION))
print(string.format("Tables:    %d", #DOCS))
print(string.format("Checked:   %d", checked))
print(string.format("Mismatched:%d", errors))
print()

if errors > 0 then
  print("VERSION FACT CHECK FAILED")
  os.exit(1)
end

print("VERSION FACT CHECK PASSED")
