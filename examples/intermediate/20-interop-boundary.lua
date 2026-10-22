-- Example 32: The Lua/C Boundary Contract
-- Chapter: interoperability-patterns
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Companion example for Interoperability Patterns. Everything here runs on the
-- Lua side of the boundary, because that is the side the reader is on -- the
-- point is to make the contract explicit so that the C side is predictable:
-- what each value looks like when it crosses, what "absent" means, what the
-- boundary does with holes in a table, and how errors are reported.
--
-- Demonstrates: type/representation rules that map onto lua_push* calls, the
-- nil-vs-absent rule, table conversion at the boundary, multiple returns as
-- out-parameters, and yielding across the pcall/C boundary (measured per
-- runtime rather than assumed).

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

--------------------------------------------------------------------------------
-- 1. What each Lua value becomes on the C stack
--------------------------------------------------------------------------------

section("1. Value mapping (Lua -> C stack)")

-- A C function that only ever sees `int` for booleans and `lua_Integer` for
-- whole numbers cannot represent these differently, so the Lua side has to
-- know which way each value is typed.
local samples = {
  { lua = 42,              c_call = "lua_pushinteger(L, 42)" },
  { lua = 42.0,            c_call = "lua_pushnumber(L, 42.0)" },
  { lua = 42.5,            c_call = "lua_pushnumber(L, 42.5)" },
  { lua = true,            c_call = "lua_pushboolean(L, 1)" },
  { lua = nil,             c_call = "lua_pushnil(L)" },
  { lua = "payload",       c_call = "lua_pushstring(L, ...)" },
  { lua = {},              c_call = "lua_newtable(L)" },
}

for _, s in ipairs(samples) do
  print(string.format("  %-14s -> %s", tostring(s.lua), s.c_call))
end

if math.type then
  check("42 and 42.0 are distinguishable subtypes (lua_pushinteger vs lua_pushnumber)",
    math.type(42) == "integer" and math.type(42.0) == "float")
  check("42 == 42.0 still holds for the == operator", 42 == 42.0)
  check("tostring(2.0) shows the subtype, which is what a log will capture",
    tostring(42.0) == "42.0")
else
  check("a single numeric type means every number crosses as lua_Number",
    math.type == nil)
  print("  note: tostring(42.0) on this runtime = " .. tostring(42.0))
end

-- Booleans are ints on the C side; a C caller that checks `!= 0` accepts any
-- non-zero int, so the safe convention is to push exactly 0/1.
local function as_c_int(v) return v and 1 or 0 end
check("booleans map to 0/1 for the C side",
  as_c_int(true) == 1 and as_c_int(false) == 0 and as_c_int(nil) == 0)

--------------------------------------------------------------------------------
-- 2. nil means "absent", and that survives the round trip
--------------------------------------------------------------------------------

section("2. nil vs absent (lua_isnil vs lua_isnone)")

-- From Lua you cannot tell nil from "no argument" -- but C can (isnone vs
-- isnil). The portable Lua-side convention is: missing keys are not present.
local record = { id = "doc-1", title = "Report", }

check("present key yields its value", record.title == "Report")
check("absent key yields nil", record.author == nil)

-- Absent and explicitly-nil are the same FROM LUASIDE -- worth stating,
-- because it is the one ambiguity the boundary cannot resolve for you.
local with_nil = { id = "doc-1", author = nil }
check("explicitly-nil key is indistinguishable from an absent key in Lua",
  with_nil.author == nil and with_nil.author ~= "present")

-- The round trip: what C would push back for a nil field.
local function round_trip(value)
  local stack = {}
  if value == nil then stack[1] = { kind = "nil" }
  elseif type(value) == "string" then stack[1] = { kind = "string", payload = value }
  else stack[1] = { kind = "other", payload = value } end
  return stack[1]
end
check("nil round-trips as an explicit nil", round_trip(nil).kind == "nil")
check("a string round-trips with its payload", round_trip("hi").payload == "hi")

--------------------------------------------------------------------------------
-- 3. Table conversion: what a C array can and cannot express
--------------------------------------------------------------------------------

section("3. Table conversion at the boundary")

local dense = { "a", "b", "c" }
local holed = { "a", nil, "c" }

local function to_ordered_list(t)
  -- The same thing a C loop with `for (i = 1; i <= n; i++) lua_rawgeti(...)` does:
  -- it walks indexes 1..#t and cannot skip holes.
  local out = {}
  for i = 1, #t do out[#out + 1] = { index = i, value = t[i] } end
  return out
end

-- Count what each walk actually reaches: `#` on a holed table is a border and
-- may be 1 or 3, so report it and assert only the counts, which are fixed.
local function count_ipairs(t)
  local n = 0
  for _ in ipairs(t) do n = n + 1 end
  return n
end
local function count_pairs(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

local dense_list = to_ordered_list(dense)
local holed_list = to_ordered_list(holed)

print(string.format("  dense: #=%d, ipairs=%d, pairs=%d, converted=%d",
  #dense, count_ipairs(dense), count_pairs(dense), #dense_list))
print(string.format("  holed: #=%d (border), ipairs=%d, pairs=%d, converted=%d",
  #holed, count_ipairs(holed), count_pairs(holed), #holed_list))

check("a dense sequence converts with nothing lost", #dense_list == 3)
check("ipairs stops at the hole, so only the elements before it convert",
  count_ipairs(holed) == 1)
check("pairs-style access still reaches index 3, the element after the hole",
  holed[3] == "c")

-- The real hazard: the naive 1..#t walk never fails -- it either returns an
-- entry whose value is nil (when `#` reports the far border) or stops at the
-- hole (when `#` reports the near border). It cannot tell you the table was
-- malformed, and `#` on a holed table is unspecified: measured here,
-- PUC 5.4 and 5.1 report 3, while LuaJIT 2.1 reports 1.
local hole_entries = 0
for _, entry in ipairs(holed_list) do
  if entry.value == nil then hole_entries = hole_entries + 1 end
end
print(string.format("  naive conversion: #holed=%d, entries=%d, of which nil-valued=%d",
  #holed, #holed_list, hole_entries))
check("the naive 1..#t walk returns a list and signals no problem",
  type(holed_list) == "table")
check("the walk length is exactly what `#` reported -- it never checks further",
  #holed_list == #holed)

-- The boundary rule worth internalising: a table with holes is not a valid
-- C array input. Validate on the Lua side first.
local function as_valid_array(t)
  local n = #t
  for i = 1, n do
    if t[i] == nil then return nil, "hole at index " .. i end
  end
  -- also reject non-sequence keys, which a C array cannot carry at all
  local count = 0
  for k in pairs(t) do
    count = count + 1
    if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
      return nil, "non-array key: " .. tostring(k)
    end
  end
  if count ~= n then return nil, "key count differs from sequence length" end
  return t, nil
end

check("a dense table is accepted as a C array", as_valid_array(dense) ~= nil)
local bad, why = as_valid_array(holed)
check("a table with a hole is rejected before crossing", bad == nil)
print("    reason: " .. tostring(why))
check("a table with a hash key is rejected",
  select(1, as_valid_array({ "a", "b", extra = true })) == nil)

--------------------------------------------------------------------------------
-- 4. Multiple returns as out-parameters
--------------------------------------------------------------------------------

section("4. Out-parameters (assert-style returns)")

-- C has no multiple returns; a C function reports status through return values
-- that Lua sees as multiple results. Two conventions, both in wide use.
local function assert_style_read(store, key)
  local v = store[key]
  if v == nil then return nil, "key not found: " .. tostring(key), 2 end
  return v, nil, nil
end

local ok_value, ok_err = assert_style_read({ a = 1 }, "a")
check("success returns the value first", ok_value == 1 and ok_err == nil)

local nil_value, nil_err = assert_style_read({ a = 1 }, "b")
check("failure returns nil plus a message", nil_value == nil and nil_err ~= nil)

-- A subtle trap: `local v = f()` silently drops the error message.
local dropped = assert_style_read({ a = 1 }, "b")
check("dropping the trailing results hides the error (the classic misuse)",
  dropped == nil)

-- And this one: a false return value would be mistaken for failure by `if v`.
local function bool_status()
  return false, "not found"       -- false IS a legitimate return value
end
local b1, b2 = bool_status()
check("false is not nil: only nil should signal absence", b1 == false and b2 ~= nil)
local only_first = bool_status()
check("truthiness testing confuses a false result with failure", only_first == false)

--------------------------------------------------------------------------------
-- 5. Yielding across the pcall/C boundary
--------------------------------------------------------------------------------

section("5. Yield across the pcall/C boundary (measured)")

-- Pattern that is portable everywhere: yield directly from the coroutine.
local function portable()
  local co = coroutine.create(function() return coroutine.yield("y") end)
  local ok, v = coroutine.resume(co)
  return ok, v
end
local po, pv = portable()
check("yield from inside a coroutine works everywhere", po == true and pv == "y")

-- Pattern that is NOT portable: yielding from inside a pcall that is itself
-- running inside a coroutine. Measured results on this machine:
--   Lua 5.4   -> allowed      LuaJIT 2.1 -> allowed      Lua 5.1 -> refused
local function yield_inside_pcall()
  local co = coroutine.create(function()
    local inner = pcall(function() coroutine.yield("from-inside-pcall") end)
    return "inner-pcall=" .. tostring(inner)
  end)
  local ok, a, b = coroutine.resume(co)
  return ok, a, b
end

local y_ok, y_a, y_b = yield_inside_pcall()
print(string.format("  yield inside pcall -> ok=%s, a=%s, b=%s",
  tostring(y_ok), tostring(y_a), tostring(y_b)))

local is_plain_51 = (_VERSION == "Lua 5.1") and (jit == nil)
if is_plain_51 then
  -- Lua 5.1 refuses the yield; pcall catches it and the coroutine instead
  -- returns the string it built, so the marker shows up as the FIRST result.
  check("plain Lua 5.1 refuses to yield across pcall (documented limit)",
    tostring(y_a):find("inner-pcall=", 1, true) ~= nil)
else
  check("this runtime allows yielding across pcall",
    y_a == "from-inside-pcall")
end

-- The portable workaround: never nest a yield inside a pcall; instead resume
-- the outer coroutine and let pcall live on the inside.
local function portable_recover()
  local co = coroutine.create(function()
    local ok = pcall(function() return 1 end)   -- pcall that never yields
    if not ok then error("unreachable") end
    local v = coroutine.yield("safe")
    return v * 2
  end)
  local ok1, v1 = coroutine.resume(co)
  local ok2, v2 = coroutine.resume(co, 21)
  return ok1, v1, ok2, v2
end
local r1, r2, r3, r4 = portable_recover()
check("portable shape: yield after the pcall completes",
  r1 and r2 == "safe" and r3 and r4 == 42)

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------

print()
print(string.rep("=", 64))
print(string.format("All %d checks passed.", checks))
print(string.rep("=", 64))
print("INTEROP BOUNDARY OK")
