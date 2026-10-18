-- Example 29: Control Flow Patterns and Iteration Pitfalls
-- Chapter: 02-control-flow
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Companion example for Chapter 02. Every section below corresponds to a
-- section of the chapter, and the pitfall numbers are measured at runtime
-- rather than asserted from memory -- Lua leaves some of this unspecified, so
-- printing what actually happened on this interpreter is the honest report.
--
-- Demonstrates: numeric/generic for, while/repeat, break, the three custom
-- iterator forms, measurable iteration pitfalls, and the chapter's three
-- common patterns (stable partition, chunked iteration, retry with backoff).

local function section(title)
  print()
  print(string.rep("=", 62))
  print(title)
  print(string.rep("=", 62))
end

local checks = 0
local function check(label, ok)
  checks = checks + 1
  print(string.format("  %s %s", ok and "[ok  ]" or "[FAIL]", label))
  if not ok then
    error("check failed: " .. label)
  end
end

--------------------------------------------------------------------------------
-- 1. Loops: the four forms
--------------------------------------------------------------------------------

section("1. Loop forms")

-- numeric for
local total = 0
for i = 1, 10 do total = total + i end
check("numeric for sums 1..10 = 55", total == 55)

-- numeric for with a negative step
local countdown = {}
for i = 3, 1, -1 do countdown[#countdown + 1] = i end
check("numeric for supports negative step", table.concat(countdown, ",") == "3,2,1")

-- while
local n, steps = 27, 0        -- Collatz-like: halve until 1
while n > 1 do
  n = (n % 2 == 0) and math.floor(n / 2) or 3 * n + 1
  steps = steps + 1
end
check("while loop terminates (27 -> 1 in 111 steps)", n == 1 and steps == 111)

-- repeat-until runs its body at least once, evaluated AFTER the body
local ran = 0
repeat ran = ran + 1 until true
check("repeat-until body runs at least once", ran == 1)

--------------------------------------------------------------------------------
-- 2. Break and early return
--------------------------------------------------------------------------------

section("2. Break and early return")

local function first_negative(t)
  for i = 1, #t do
    if t[i] < 0 then return i end   -- early return leaves the loop
  end
  return nil
end
check("early return finds the first negative", first_negative({3, 5, -2, -9}) == 3)
check("early return returns nil when none match", first_negative({1, 2, 3}) == nil)

local found
for i = 1, 100 do
  if i * i > 50 then found = i; break end   -- break leaves only this loop
end
check("break exits at the first i*i > 50", found == 8)

--------------------------------------------------------------------------------
-- 3. Iteration pitfalls -- measured, not assumed
--------------------------------------------------------------------------------

section("3. Iteration pitfalls (measured)")

-- Pitfall A: removing from an array while iterating with ipairs skips elements.
-- table.remove shifts everything left, so the next index now holds an element
-- that was already passed over.
local letters = { "a", "b", "c", "d" }
local visited = {}
for i, v in ipairs(letters) do
  visited[#visited + 1] = v
  if v == "b" then table.remove(letters, i) end
end
print(string.format("  remove-during-ipairs visited: %s", table.concat(visited, ",")))
print(string.format("  table afterwards:             %s", table.concat(letters, ",")))
check("removing during ipairs skips an element (c never visited)",
  table.concat(visited, ",") == "a,b,d")

-- The safe form: iterate backwards when removing, so the left-shift can only
-- affect indexes you have already passed.
local nums = { 1, 2, 3, 4, 5, 6 }
for i = #nums, 1, -1 do
  if nums[i] % 2 == 0 then table.remove(nums, i) end
end
check("backwards iteration removes every even number",
  table.concat(nums, ",") == "1,3,5")

-- Pitfall B: `#` on a table with holes returns *a* border, not a count.
local holed = { 10, 20, nil, 40 }
print(string.format("  #holed = %d  (a border, not necessarily the count)", #holed))
local ipairs_count, pairs_count = 0, 0
for _ in ipairs(holed) do ipairs_count = ipairs_count + 1 end
for _ in pairs(holed) do pairs_count = pairs_count + 1 end
print(string.format("  ipairs visited %d, pairs visited %d", ipairs_count, pairs_count))
check("ipairs stops at the hole", ipairs_count == 2)
check("pairs still sees the elements after the hole", pairs_count == 3)

-- Pitfall C: pairs order is unspecified. Compare it against insertion order.
local ordered = {}
for _, k in ipairs({ "alpha", "beta", "gamma", "delta", "epsilon" }) do
  ordered[k] = true
end
local seen = {}
for k in pairs(ordered) do seen[#seen + 1] = k end
local matches_insertion =
  table.concat(seen, ",") == "alpha,beta,gamma,delta,epsilon"
print(string.format("  pairs order: %s", table.concat(seen, ",")))
print(string.format("  matches insertion order: %s", tostring(matches_insertion)))
check("pairs returned every key exactly once", #seen == 5)

--------------------------------------------------------------------------------
-- 4. Custom iterators: the three forms
--------------------------------------------------------------------------------

section("4. Custom iterators")

-- Form 1: a stateless iterator -- the loop state carries everything.
local function range(n)
  return function(_, last)
    if last < n then return last + 1 end
  end, nil, 0
end
local got = {}
for i in range(5) do got[#got + 1] = i end
check("stateless range iterator yields 1..5", table.concat(got, ",") == "1,2,3,4,5")

-- Form 2: multiple values per step, including a terminator.
local function chars(s)
  local i = 0
  return function()
    i = i + 1
    if i <= #s then return i, s:sub(i, i) end
  end
end
local pairsList = {}
for idx, ch in chars("lua") do pairsList[#pairsList + 1] = idx .. ch end
check("iterator can yield multiple values", table.concat(pairsList, " ") == "1l 2u 3a")

-- Form 3: a coroutine iterator -- wrap_yield drives the loop.
local function walk(t)
  return coroutine.wrap(function()
    for i, v in ipairs(t) do coroutine.yield(i, v) end
  end)
end
local walked = {}
for i, v in walk({ "x", "y" }) do walked[#walked + 1] = i .. v end
check("coroutine iterator walks the table", table.concat(walked, " ") == "1x 2y")

--------------------------------------------------------------------------------
-- 5. Common patterns from the chapter
--------------------------------------------------------------------------------

section("5. Common patterns")

-- Stable partition: keeps relative order within each group.
local function partition(t, pred)
  local yes, no = {}, {}
  for _, v in ipairs(t) do
    if pred(v) then yes[#yes + 1] = v else no[#no + 1] = v end
  end
  return yes, no
end
local evens, odds = partition({ 5, 2, 8, 1, 4 }, function(v) return v % 2 == 0 end)
check("stable partition keeps order (odds)", table.concat(odds, ",") == "5,1")
check("stable partition keeps order (evens)", table.concat(evens, ",") == "2,8,4")

-- Chunked iteration: process N items at a time.
local unpack_values = table.unpack or unpack   -- 5.2+ vs 5.1

local function chunk(t, size)
  local i = 0
  return function()
    local from = i + 1
    if from > #t then return nil end
    local to = math.min(from + size - 1, #t)
    i = to
    return unpack_values(t, from, to)
  end
end
local chunks = {}
for a, b in chunk({ 1, 2, 3, 4, 5 }, 2) do
  chunks[#chunks + 1] = tostring(a) .. tostring(b or "-")
end
check("chunked iteration groups by 2", table.concat(chunks, " ") == "12 34 5-")

-- Retry with backoff: bounded attempts, no sleeping in this example.
local function retry(max_attempts, fn)
  local attempt = 1
  local delay = 0.01
  while attempt <= max_attempts do
    local ok, result = pcall(fn, attempt)
    if ok then return true, result, attempt end
    attempt = attempt + 1
    delay = delay * 2          -- exponential backoff
  end
  return false, nil, max_attempts
end
local ok, result, attempts = retry(5, function(attempt)
  if attempt < 3 then error("transient failure " .. attempt) end
  return "succeeded"
end)
check("retry succeeds on the third attempt", ok and attempts == 3 and result == "succeeded")

local ok2, _, attempts2 = retry(3, function() error("always fails") end)
check("retry gives up after max_attempts", not ok2 and attempts2 == 3)

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------

print()
print(string.rep("=", 62))
print(string.format("All %d checks passed.", checks))
print(string.rep("=", 62))
print("CONTROL FLOW OK")
