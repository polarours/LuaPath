#!/usr/bin/env lua
-- test-version-facts.lua
-- Checks the quick comparison table in references/VERSION_DIFFERENCES.md
-- against the runtime that is actually executing this script.
--
-- The table is the repository's answer to "what is different between the Lua
-- versions?". A reader takes it at face value, so a wrong cell is a wrong
-- answer. This test parses the table and probes the running runtime for each
-- row: if the table says a feature is missing and the runtime has it, or the
-- other way round, the test fails.
--
-- Usage: lua tests/test-version-facts.lua

local DOC = "references/VERSION_DIFFERENCES.md"

-- The check mark and the cross, as the document writes them. Lua 5.1 has
-- no \u escape, so the bytes go in directly.
local CHECK = "\226\156\147"  -- U+2713 CHECK MARK
local CROSS = "\226\156\151"  -- U+2717 BALLOT X

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

-- Rows the table lists that cannot be decided by a cheap probe.
local SKIP = {
  ["Ephemeron Tables"] = true,
}

---------------------------------------------------------------------------
-- Read the table
---------------------------------------------------------------------------

local content = read_file(DOC)
if not content then
  io.stderr:write("cannot read " .. DOC .. "\n")
  os.exit(1)
end

local columns = nil
local rows = {}
local in_table = false

for line in content:gmatch("[^\n]+") do
  if line:match("^| Feature |") then
    columns = {}
    for name in line:gmatch("| ([^|]+)") do
      columns[#columns + 1] = name:gsub("^%s*(.-)%s*$", "%1")
    end
    in_table = true
  elseif in_table then
    -- A row starts with "| " and is not the separator line.
    local is_row = line:match("^| ") and not line:match("^|%-")
    if is_row then
      local cells = {}
      for name in line:gmatch("| ([^|]+)") do
        cells[#cells + 1] = name:gsub("^%s*(.-)%s*$", "%1")
      end
      if #cells == #columns then
        rows[#rows + 1] = cells
      end
    elseif not line:match("^|") then
      in_table = false
    end
  end
end

if not columns or #rows == 0 then
  io.stderr:write("no comparison table found in " .. DOC .. "\n")
  os.exit(1)
end

local column = current_column()
if not column then
  print("unknown runtime " .. _VERSION .. " -- nothing to check")
  os.exit(0)
end

local column_index = nil
for index, name in ipairs(columns) do
  if name == column then column_index = index end
end
if not column_index then
  print("the table has no column for " .. column .. " -- nothing to check")
  os.exit(0)
end

---------------------------------------------------------------------------
-- Check
---------------------------------------------------------------------------

local errors = 0
local checked = 0

for _, cells in ipairs(rows) do
  local feature = cells[1]:gsub("%*", ""):gsub("`", ""):gsub("^%s*(.-)%s*$", "%1")
  if not SKIP[feature] and PROBES[feature] then
    local cell = cells[column_index]
    local result = PROBES[feature]()
    checked = checked + 1

    -- The cell starts with the word: "✓", "✗", "`//`", "operators".
    local word = cell:match("^([^%s%(]+)") or cell
    local ok = (word == result)

    if not ok then
      errors = errors + 1
      print(string.format("  %s: the table says %q for %s, but this runtime says %s",
        DOC, cell, column, tostring(result)))
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("Runtime:  %s (%s)", column, _VERSION))
print(string.format("Checked:   %d", checked))
print(string.format("Mismatched:%d", errors))
print()

if errors > 0 then
  print("VERSION FACT CHECK FAILED")
  os.exit(1)
end

print("VERSION FACT CHECK PASSED")
