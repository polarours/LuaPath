-- Project 4: Performance Analysis & Optimization
-- Chapter: 12-performance
-- Difficulty: Advanced
-- Lua Version: 5.4+
--
-- Demonstrates: benchmarking, string concat, table access, allocation reuse

local function benchmark(fn, iterations)
  collectgarbage("collect")
  collectgarbage("stop")
  local t0 = os.clock()
  for _ = 1, iterations do fn() end
  local elapsed = os.clock() - t0
  collectgarbage("restart")
  return elapsed
end

local function fmt_time(s)
  if s < 0.001 then return string.format("%.3f ms", s * 1000) end
  return string.format("%.3f s", s)
end

local results = {}
local function record(op, time, baseline)
  local ratio = baseline > 0 and (baseline / time) or 1
  table.insert(results, { op = op, time = time, ratio = ratio })
end

local N = 100000
local W = 28

-- ── 1. String concatenation ──────────────────────────────────────────
print("1) String Concatenation (N = " .. N .. ")")

local function concat_naive()
  local s = ""
  for i = 1, 200 do s = s .. "x" end
end

local parts = {}
local function concat_table()
  for i = 1, 200 do parts[i] = "x" end
  local s = table.concat(parts)
end

local t_naive = benchmark(concat_naive, N)
local t_table = benchmark(concat_table, N)
record("naive ..", t_naive, t_naive)
record("table.concat", t_table, t_naive)
print(string.format("  naive ..      : %s", fmt_time(t_naive)))
print(string.format("  table.concat  : %s", fmt_time(t_table)))
print(string.format("  speedup       : %.1fx", t_naive / t_table))

-- ── 2. Table access: global vs local ─────────────────────────────────
print("\n2) Table Access: Global vs Local Cache (N = " .. N .. ")")

local global_tbl = { 1, 2, 3, 4, 5 }

local function access_global()
  local sum = 0
  for _ = 1, 300 do sum = sum + global_tbl[1] end
end

local cached = global_tbl
local function access_local()
  local sum = 0
  for _ = 1, 300 do sum = sum + cached[1] end
end

local t_global = benchmark(access_global, N)
local t_local = benchmark(access_local, N)
record("global lookup", t_global, t_global)
record("local cache", t_local, t_global)
print(string.format("  global lookup : %s", fmt_time(t_global)))
print(string.format("  local cache   : %s", fmt_time(t_local)))
print(string.format("  speedup       : %.1fx", t_global / t_local))

-- ── 3. Allocation: new tables vs reuse ───────────────────────────────
print("\n3) Allocation: New vs Reuse (N = " .. N .. ")")

local function alloc_new()
  for _ = 1, 200 do
    local t = { x = 1, y = 2, z = 3 }
  end
end

local pool = {}
for i = 1, 200 do pool[i] = { x = 0, y = 0, z = 0 } end
local function alloc_reuse()
  for i = 1, 200 do
    pool[i].x = 1
    pool[i].y = 2
    pool[i].z = 3
  end
end

local t_new = benchmark(alloc_new, N)
local t_reuse = benchmark(alloc_reuse, N)
record("new tables", t_new, t_new)
record("reuse tables", t_reuse, t_new)
print(string.format("  new tables    : %s", fmt_time(t_new)))
print(string.format("  reuse tables  : %s", fmt_time(t_reuse)))
print(string.format("  speedup       : %.1fx", t_new / t_reuse))

-- ── Summary ──────────────────────────────────────────────────────────
print("\n┌" .. string.rep("─", W + 22) .. "┐")
print("│ " .. string.format("%-" .. W .. "s %8s  %6s", "Operation", "Time", "Ratio") .. " │")
print("├" .. string.rep("─", W + 22) .. "┤")
for _, r in ipairs(results) do
  print("│ " .. string.format("%-" .. W .. "s %8s  %5.1fx",
    r.op, fmt_time(r.time), r.ratio) .. " │")
end
print("└" .. string.rep("─", W + 22) .. "┘")

print("\nKey takeaways:")
print("  • table.concat beats naive .. by avoiding quadratic realloc")
print("  • Local variable cache avoids repeated global lookups")
print("  • Object reuse reduces GC pressure and allocation cost")

return { benchmark = benchmark, fmt_time = fmt_time, results = results }
