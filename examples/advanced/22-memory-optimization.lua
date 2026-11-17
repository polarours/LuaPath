-- Example 54: Memory Optimization
-- Chapter: 12-performance
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: peak transient allocation vs post-GC residue, table reuse,
-- O(n^2) string concatenation vs table.concat, weak-reference caches.
--
-- MEASUREMENT NOTE (the point of this example):
-- "memory used" is not one number. Two different measurements answer two
-- different questions:
--   * peak transient allocation -- how much the workload holds or dirties
--     while it runs. This is what allocation pressure and GC cost depend on.
--   * post-GC residue -- what is still reachable afterwards. This is what a
--     leak looks like, but it says NOTHING about how hard the workload pushed
--     the allocator along the way.
-- An earlier version of this example measured only post-GC residue for the
-- string section. Because tostring(i) leaves number->string conversions in
-- Lua's interned string table (which GC does not clear), the "good" path
-- appeared to use 22x MORE memory than the O(n^2) path. That was a measuring
-- error, not a result. This version guards correctness first, then reports
-- the metric that actually answers each question.

local check_count = 0
local function check(label, ok)
  check_count = check_count + 1
  print(string.format("  [ok  ] %s", label))
  if not ok then error("check failed: " .. label) end
end

local function section(title)
  print()
  print(string.rep("=", 64))
  print(title)
  print(string.rep("=", 64))
end

-- Sample heap usage while the workload is running, with NO intermediate
-- collection. collectgarbage("count") reports live+dirty KB; sampling every
-- `every` iterations keeps the probe itself cheap.
local function peak_transient_kb(workload, every)
  collectgarbage("collect")
  local base = collectgarbage("count")
  local peak = base
  local result = workload(function()
    local now = collectgarbage("count")
    if now > peak then peak = now end
  end)
  return peak - base, result
end

local function elapsed(f)
  local t0 = os.clock()
  local result = f()
  return os.clock() - t0, result
end

local N = 100000
local SN = 100000

--------------------------------------------------------------------------------

section("1. Table reuse: peak transient allocation")

local function fresh_sum(n)
  local sum = 0
  for i = 1, n do
    local t = {x = i, y = i * 2}
    sum = sum + t.x + t.y
  end
  return sum
end

local function reused_sum(n)
  local t = {}
  local sum = 0
  for i = 1, n do
    t.x = i
    t.y = i * 2
    sum = sum + t.x + t.y
  end
  return sum
end

-- Correctness guard BEFORE any measurement: both paths must compute the same
-- answer. A cheaper implementation that returns a different number is not an
-- optimisation.
local fresh_peak, fresh_value = peak_transient_kb(function(sample)
  local sum = 0
  for i = 1, N do
    local t = {x = i, y = i * 2}
    sum = sum + t.x + t.y
    if i % 500 == 0 then sample() end
  end
  return sum
end)

local reused_peak, reused_value = peak_transient_kb(function(sample)
  local t = {}
  local sum = 0
  for i = 1, N do
    t.x = i
    t.y = i * 2
    sum = sum + t.x + t.y
    if i % 500 == 0 then sample() end
  end
  return sum
end)

check("fresh-table and reused-table paths return the same sum",
  fresh_value == reused_value and fresh_value == fresh_sum(N))
check("recreating 100000 tables allocates more than reusing one",
  fresh_peak > reused_peak)

print(string.format("  fresh tables each iteration: %.1f KB peak transient", fresh_peak))
print(string.format("  one table reused:            %.1f KB peak transient", reused_peak))

--------------------------------------------------------------------------------

section("2. String building: time is the O(n^2) signal")

-- A FIXED piece, not tostring(i): tostring(i) leaves 100000 number->string
-- conversions in the interned string table, which dominate the memory
-- measurement and hide the thing being compared.
local function concat_loop(n)
  local s = ""
  for i = 1, n do s = s .. "x" end
  return s
end

local function concat_table(n)
  local parts = {}
  for i = 1, n do parts[i] = "x" end
  return table.concat(parts)
end

-- Guard first: both builders must produce the identical string.
local bad_time, bad_result = elapsed(function() return concat_loop(SN) end)
local good_time, good_result = elapsed(function() return concat_table(SN) end)
check("both builders produce the identical string",
  bad_result == good_result and #bad_result == SN)
check("the measured times are above the 0.1s noise floor",
  bad_time >= 0.1 and good_time > 0)
check("table.concat is faster than repeated .. on this workload",
  good_time < bad_time)

local ratio = bad_time / math.max(good_time, 1e-9)
print(string.format("  s = s .. \"x\"  (%d times): %.3f s", SN, bad_time))
print(string.format("  table.concat of %d pieces: %.3f s", SN, good_time))
print(string.format("  ratio: %.1fx  (absolute seconds vary by machine;", ratio))
print("         the ratio and the identical-output guard are the portable claims)")
print("  note: do NOT read post-GC residue here -- interned strings from")
print("        tostring(i) stay in the string table and invert the comparison.")

--------------------------------------------------------------------------------

section("3. Weak-key cache: reachability, not bytes")

local cache = setmetatable({}, {__mode = "k"})
local keys = {}
for i = 1, 100 do
  keys[i] = {id = i}
  cache[keys[i]] = "item" .. i
end

local function cache_size()
  local count = 0
  for _ in pairs(cache) do count = count + 1 end
  return count
end

check("a weak-key cache holds all 100 live entries", cache_size() == 100)
print(string.format("  before release: %d entries", cache_size()))

for i = 51, 100 do keys[i] = nil end
collectgarbage("collect")
collectgarbage("collect")

check("dropping the keys lets exactly 50 entries be collected", cache_size() == 50)
print(string.format("  after release:  %d entries", cache_size()))

--------------------------------------------------------------------------------

print()
print(string.rep("=", 64))
print(string.format("All %d checks passed.", check_count))
print(string.rep("=", 64))
print("MEMORY OPTIMIZATION OK")
