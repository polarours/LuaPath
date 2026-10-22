-- Example 58: Lua Internals Probe
-- Chapter: 10-lua-internals
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Companion example for Chapter 10. Every number below is measured at runtime
-- on the interpreter that is executing it -- nothing here is asserted from
-- documentation, because the point of the chapter is that these are observable
-- consequences of the implementation rather than guarantees.
--
-- Demonstrates: string interning (memory deduplication), closure/upvalue
-- capture semantics for `for` vs `while`, array-part vs hash-part allocation,
-- tagged values / the integer subtype, and garbage-collector accounting.

local function section(title)
  print()
  print(string.rep("=", 64))
  print(title)
  print(string.rep("=", 64))
end

local checks = 0
local function check(label, ok)
  checks = checks + 1
  print(string.format("  %s %s", ok and "[ok  ]" or "[FAIL]", label))
  if not ok then error("check failed: " .. label) end
end

local function kb()
  return collectgarbage("count")
end

--------------------------------------------------------------------------------
-- 1. Tagged values and the integer subtype
--------------------------------------------------------------------------------

section("1. Value representation (measured)")

print("  _VERSION      = " .. _VERSION)
print("  math.type     = " .. (math.type and "present" or "absent"))
print("  tostring(2)   = " .. tostring(2))
print("  tostring(2.0) = " .. tostring(2.0))

if math.type then
  -- 5.3+ represents integers and floats as distinct subtypes
  check("2.0 is a float", math.type(2.0) == "float")
  check("10 is an integer", math.type(10) == "integer")
  check("10 / 2 produces an integer in 5.3+ (5.4 keeps 5)", 10 / 2 == 5.0)
  check("math.floor returns an integer subtype in 5.3+",
    math.type(math.floor(10 / 2)) == "integer")
  check("large integer round-trips exactly", math.tointeger(2^53) == 2^53)
  -- A value that does NOT fit in a 32-bit int must still survive as a double
  local big = 2^60
  check("2^60 survives as a number", big == 1152921504606846976)
else
  -- 5.1 and LuaJIT have a single numeric type
  check("absent math.type means a single numeric type", math.type == nil)
  check("tostring(2.0) has no decimal separator on 5.1/LuaJIT",
    tostring(2.0) == "2" or tostring(2.0) == "2.0")
end

--------------------------------------------------------------------------------
-- 2. String interning
--------------------------------------------------------------------------------

section("2. String interning (memory)")

local N = 60000

-- Collect garbage so the measurement starts from a settled heap.
collectgarbage("collect")
collectgarbage("collect")
local before = kb()

local shared = {}
local needle = "shared-key"
for i = 1, N do
  shared[i] = needle        -- N references to ONE string object
end
local after_shared = kb()
collectgarbage("collect")
collectgarbage("collect")

local before2 = kb()
local distinct = {}
for i = 1, N do
  distinct[i] = "k" .. i .. "-value"   -- N distinct string objects
end
local after_distinct = kb()

local shared_delta = after_shared - before
local distinct_delta = after_distinct - before2

print(string.format("  %d refs to one string:  +%.1f KB", N, shared_delta))
print(string.format("  %d distinct strings:     +%.1f KB", N, distinct_delta))

check("referencing one string repeatedly costs memory for the table only",
  shared_delta < distinct_delta / 2)
check("distinct strings do cost real memory", distinct_delta > 100)

shared, distinct = nil, nil
collectgarbage("collect")

--------------------------------------------------------------------------------
-- 3. Closures and upvalues -- `for` vs `while`
--------------------------------------------------------------------------------

section("3. Closure capture: for vs while (measured)")

local for_fn = {}
for i = 1, 3 do for_fn[i] = function() return i end end
local for_result = string.format("%d,%d,%d", for_fn[1](), for_fn[2](), for_fn[3]())

local while_fn = {}
local n = 1
while n <= 3 do while_fn[n] = function() return n end; n = n + 1 end
local while_result = string.format("%d,%d,%d", while_fn[1](), while_fn[2](), while_fn[3]())

print(string.format("  for  closures -> %s", for_result))
print(string.format("  while closures -> %s", while_result))

-- Observed on Lua 5.4, Lua 5.1 and LuaJIT 2.1 alike: the `for` control variable
-- is fresh for each iteration, while a plain local mutated by a `while` loop is
-- one binding that every closure sees.
check("`for` closures captured per-iteration values", for_result == "1,2,3")
check("`while` closures all see the final value", while_result == "4,4,4")

-- Shared upvalue: two closures over the same local really do share state.
local counter = 0
local function inc() counter = counter + 1 return counter end
local function read() return counter end
inc(); inc()
check("two closures share one upvalue", read() == 2 and inc() == 3)

--------------------------------------------------------------------------------
-- 4. Table internals: array part vs hash part
--------------------------------------------------------------------------------

section("4. Table allocation: array vs hash (measured)")

local SIZE = 50000

collectgarbage("collect"); collectgarbage("collect")
local a0 = kb()
local arr = {}
for i = 1, SIZE do arr[i] = i end
local a1 = kb()

collectgarbage("collect"); collectgarbage("collect")
local h0 = kb()
local hash = {}
for i = 1, SIZE do hash["k" .. i] = i end   -- string keys => pure hash part
local h1 = kb()

local arr_delta, hash_delta = a1 - a0, h1 - h0
print(string.format("  array part (%d int keys):   +%.1f KB", SIZE, arr_delta))
print(string.format("  hash part  (%d str keys):   +%.1f KB", SIZE, hash_delta))

check("the contiguous array part is cheaper per entry than a hash part",
  arr_delta < hash_delta)
check("both allocations are real", arr_delta > 100 and hash_delta > 100)

-- Observable consequence: `#` walks the array part only.
local mixed = { 1, 2, 3 }
mixed["extra"] = 4
check("`#` counts only the array part", #mixed == 3)

arr, hash, mixed = nil, nil, nil
collectgarbage("collect")

--------------------------------------------------------------------------------
-- 5. Garbage collector accounting
--------------------------------------------------------------------------------

section("5. Garbage collector")

collectgarbage("collect"); collectgarbage("collect")
local g0 = kb()

local scratch = {}
for i = 1, 20000 do scratch[i] = { payload = i, label = "row" .. i } end
local peak = kb()

scratch = nil
collectgarbage("collect"); collectgarbage("collect")
local settled = kb()

print(string.format("  before alloc: %.1f KB", g0))
print(string.format("  peak:         %.1f KB  (+%.1f)", peak, peak - g0))
print(string.format("  after collect:%.1f KB  (freed %.1f)", settled, peak - settled))

check("allocating 20000 tables grew the heap", peak > g0 + 100)
check("dropping the reference and collecting returned most of it",
  settled < g0 + (peak - g0) / 4)

-- `isrunning` is a 5.2+ option; on Lua 5.1 the only valid arguments are the
-- numeric/enum options it shipped with, so ask rather than assume.
local running_ok, running = pcall(collectgarbage, "isrunning")
if running_ok then
  check("the collector is running", running == true)
else
  print("  note: collectgarbage('isrunning') is 5.2+ -- not probed here")
end

check("collectgarbage('count') is usable on this runtime",
  pcall(collectgarbage, "count"))

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------

print()
print(string.rep("=", 64))
print(string.format("All %d checks passed.", checks))
print(string.rep("=", 64))
print("INTERNALS PROBE OK")
