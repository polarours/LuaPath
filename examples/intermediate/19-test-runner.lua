-- Example 31: A Minimal Test Runner with Doubles and Property Checks
-- Chapter: testing-strategies
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Companion example for Testing Strategies. It builds the pieces the chapter
-- describes -- a runner, the assertion set, the three kinds of test double, and
-- property-based checks -- then demonstrates them by running a real suite.
--
-- The runner's own assertion is inverted: it runs deliberately failing tests to
-- prove the runner *detects* failure, and only then reports success. A test
-- framework that never fails is indistinguishable from one that never runs.

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
-- Assertions (the module under test, used by everything below)
--------------------------------------------------------------------------------

local function fmt(v)
  if type(v) == "string" then return string.format("%q", v) end
  return tostring(v)
end

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s\n  expected: %s\n  actual:   %s",
      message or "values not equal", fmt(expected), fmt(actual)), 2)
  end
end

local function assert_near(actual, expected, tolerance, message)
  local diff = actual - expected
  if diff < 0 then diff = -diff end
  if diff > (tolerance or 1e-9) then
    error(string.format("%s\n  expected %s +/- %s, got %s",
      message or "values not near", tostring(expected),
      tostring(tolerance), tostring(actual)), 2)
  end
end

local function assert_truthy(value, message)
  if not value then
    error(message or ("expected truthy, got " .. fmt(value)), 2)
  end
end

local function assert_error(fn, pattern, message)
  local ok, err = pcall(fn)
  if ok then
    error(message or "expected an error, but the call succeeded", 2)
  end
  if pattern and not tostring(err):find(pattern, 1, true) then
    error(string.format("%s\n  wanted substring: %s\n  actual error:    %s",
      message or "error text mismatch", pattern, tostring(err)), 2)
  end
end

local function assert_deep_eq(a, b, path, message)
  path = path or "$"
  if type(a) ~= type(b) then
    error(string.format("%s: type mismatch at %s (%s vs %s)",
      message or "deep equal", path, type(a), type(b)), 2)
  end
  if type(a) ~= "table" then
    if a ~= b then
      error(string.format("%s: mismatch at %s (%s vs %s)",
        message or "deep equal", path, fmt(a), fmt(b)), 2)
    end
    return
  end
  for k, v in pairs(a) do assert_deep_eq(v, b[k], path .. "." .. tostring(k)) end
  for k in pairs(b) do
    if a[k] == nil then
      error(string.format("%s: extra key at %s.%s",
        message or "deep equal", path, tostring(k)), 2)
    end
  end
end

--------------------------------------------------------------------------------
-- Runner
--------------------------------------------------------------------------------

-- Written as closures over upvalues rather than methods, so both `runner.describe`
-- and `runner.it` can be called with a dot: method-style `self` would silently
-- become the first argument under that call shape.
local function new_runner()
  local runner = { results = {} }
  local group = nil

  function runner.describe(name, body)
    local previous = group
    group = previous and (previous .. " > " .. name) or name
    body()
    group = previous
  end

  function runner.it(name, body)
    local full = group and (group .. " :: " .. name) or name
    local ok, err = pcall(body)
    table.insert(runner.results,
      { name = full, ok = ok, error = ok and nil or tostring(err) })
    if not ok then
      print(string.format("    [FAIL] %s", full))
      print("           " .. tostring(err):gsub("\n", "\n           "))
    end
  end

  function runner.summary()
    local passed, failed = 0, 0
    for _, r in ipairs(runner.results) do
      if r.ok then passed = passed + 1 else failed = failed + 1 end
    end
    return passed, failed
  end

  return runner
end

--------------------------------------------------------------------------------
-- Test doubles: spy, stub, mock
--------------------------------------------------------------------------------

local function spy(on_call)
  local s = { calls = 0, args = {}, return_value = nil }
  function s:record(...)
    self.calls = self.calls + 1
    self.args[self.calls] = { ... }
    if on_call then return on_call(...) end
    return self.return_value
  end
  setmetatable(s, { __call = function(self, ...) return self:record(...) end })
  return s
end

local function stub(value)
  local s = { calls = 0, value = value }
  setmetatable(s, {
    __call = function(self, ...)
      self.calls = self.calls + 1
      return self.value
    end,
  })
  return s
end

local function expectation(target)
  local e = { expected_times = target.times or 1, seen = 0, args_seen = nil }
  function e:observe(...)
    self.seen = self.seen + 1
    if not self.args_seen then self.args_seen = { ... } end
    return target.and_return
  end
  function e:verify()
    assert_eq(self.seen, self.expected_times,
      string.format("call count for '%s'", target.name or "expectation"))
    if target.args then
      for i = 1, #target.args do
        assert_eq(self.args_seen[i], target.args[i],
          string.format("argument #%d for '%s'", i, target.name or "expectation"))
      end
    end
  end
  return e
end

--------------------------------------------------------------------------------
-- 1. Unit tests
--------------------------------------------------------------------------------

section("1. Unit tests with assertions")

local function clamp(v, lo, hi)
  assert(type(v) == "number" and type(lo) == "number" and type(hi) == "number",
    "clamp expects three numbers")
  if lo > hi then error("clamp: lo must be <= hi", 2) end
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local suite = new_runner()

suite.describe("clamp", function()
  suite.it("returns the value when inside the range", function()
    assert_eq(clamp(5, 0, 10), 5)
  end)
  suite.it("returns the low bound when below", function()
    assert_eq(clamp(-3, 0, 10), 0)
  end)
  suite.it("returns the high bound when above", function()
    assert_eq(clamp(99, 0, 10), 10)
  end)
  suite.it("rejects an inverted range", function()
    assert_error(function() clamp(1, 10, 0) end, "lo must be <= hi")
  end)
  suite.it("rejects non-numeric input", function()
    assert_error(function() clamp("x", 0, 1) end, "expects three numbers")
  end)
end)

suite.describe("trim", function()
  suite.it("strips leading and trailing whitespace", function()
    assert_eq(trim("  hello  "), "hello")
  end)
  suite.it("leaves interior whitespace alone", function()
    assert_eq(trim(" a  b "), "a  b")
  end)
  suite.it("leaves a clean string unchanged", function()
    assert_eq(trim("abc"), "abc")
  end)
  suite.it("handles an all-whitespace string", function()
    assert_eq(trim("   "), "")
  end)
end)

suite.describe("assertions", function()
  suite.it("assert_near respects tolerance", function()
    assert_near(0.1 + 0.2, 0.3, 1e-9)
  end)
  suite.it("assert_deep_eq compares nested structures", function()
    assert_deep_eq({ a = { 1, 2, b = { true } } }, { a = { 1, 2, b = { true } } })
  end)
  suite.it("assert_deep_eq detects an extra key", function()
    local ok, err = pcall(function() assert_deep_eq({ a = 1 }, { a = 1, b = 2 }) end)
    assert(not ok, "mismatched tables must be reported")
    assert(tostring(err):find("extra key", 1, true) ~= nil,
      "the message must name what differs")
  end)
end)

local passed, failed = suite.summary()
print(string.format("  ran %d tests: %d passed, %d failed",
  #suite.results, passed, failed))
assert_eq(failed, 0, "the real suite should be green")
assert_eq(passed, #suite.results, "every registered test should have run")
check(string.format("suite under test is green (%d tests)", passed), failed == 0)

--------------------------------------------------------------------------------
-- 2. The runner must be able to fail
--------------------------------------------------------------------------------

section("2. The runner must be able to report failure")

local probe = new_runner()
probe.it("deliberately wrong assertion", function() assert_eq(1, 2, "must fail") end)
probe.it("deliberately raising test", function() error("boom") end)
probe.it("genuinely passing test", function() assert_truthy(true) end)

local pp, pf = probe.summary()
print(string.format("  ran %d tests: %d passed, %d failed", #probe.results, pp, pf))

check("runner counted the two deliberate failures", pf == 2)
check("runner counted the one genuine pass", pp == 1)
check("runner recorded every test", #probe.results == 3)

local with_reason = 0
for _, r in ipairs(probe.results) do
  if not r.ok and r.error and #r.error > 0 then with_reason = with_reason + 1 end
end
check("each failure carries a reason (needed for CI logs)", with_reason == 2)

--------------------------------------------------------------------------------
-- 3. Test doubles
--------------------------------------------------------------------------------

section("3. Test doubles: spy, stub, mock")

-- SPY: wraps the real behaviour and records calls.
local seen_by_spy = spy(function(evt) return "handled:" .. evt end)
assert_eq(seen_by_spy("save"), "handled:save", "spy delegates to the real function")
seen_by_spy("load")
check("spy counted two calls", seen_by_spy.calls == 2)
check("spy recorded the first argument of each call",
  seen_by_spy.args[1][1] == "save" and seen_by_spy.args[2][1] == "load")

-- STUB: replaces behaviour with a canned value; the test controls the answer.
local repository_find = stub(nil)          -- a miss
assert_eq(repository_find("id-1"), nil, "stub returns the canned value")
check("stub counted one call", repository_find.calls == 1)
repository_find.value = { id = "id-1", name = "chair" }   -- now a hit
local doc = repository_find("id-1")
check("stub can be reprogrammed between calls",
  type(doc) == "table" and doc.name == "chair")

-- EXPECTATION: assert on call count AND arguments.
local exp = expectation({
  name = "audit.log",
  times = 2,
  args = { "write", "document.pdf" },
  and_return = true,
})

local audit = { log = function(...) return exp:observe(...) end }

local r1 = audit.log("write", "document.pdf")
local r2 = audit.log("write", "document.pdf")

check("stubbed method returned the canned value", r1 == true and r2 == true)
local verify_ok = pcall(function() exp:verify() end)
check("expectation verified: exactly 2 calls with the expected args", verify_ok)

-- A failing expectation must be caught by the runner.
local bad = expectation({ name = "only.once", times = 3 })
bad:observe()
local vok, verr = pcall(function() bad:verify() end)
local caught = (not vok) and tostring(verr):find("call count", 1, true) ~= nil
check("a violated expectation raises with a useful message", caught)

--------------------------------------------------------------------------------
-- 4. Property-based testing
--------------------------------------------------------------------------------

section("4. Property-based checks (fixed seed => reproducible)")

-- Fixed seed keeps failures reproducible -- a random test that cannot be
-- replayed is a bug report nobody can act on.
local SEED = 20260826
math.randomseed(SEED)
local ITERATIONS = 400

local function random_list(max_len)
  local n = math.random(0, max_len)
  local t = {}
  for i = 1, n do t[i] = math.random(-50, 50) end
  return t
end

local function sorted_copy(t)
  local c = {}
  for i = 1, #t do c[i] = t[i] end
  table.sort(c)
  return c
end

local function sum(t)
  local s = 0
  for i = 1, #t do s = s + t[i] end
  return s
end

local function reverse(t)
  local r = {}
  for i = #t, 1, -1 do r[#r + 1] = t[i] end
  return r
end

local props = {
  { name = "reverse(reverse(x)) == x",
    run = function(x) return assert_deep_eq(reverse(reverse(x)), x) end },
  { name = "sorting does not change the sum (no element lost or invented)",
    run = function(x)
      assert_eq(sum(sorted_copy(x)), sum(x), "sum changed under sort")
    end },
  { name = "sorted output is non-decreasing",
    run = function(x)
      local s = sorted_copy(x)
      for i = 2, #s do
        if s[i] < s[i - 1] then
          error("not sorted at index " .. i, 2)
        end
      end
    end },
  { name = "sorting preserves the multiset of values",
    run = function(x)
      local counts = {}
      for _, v in ipairs(x) do counts[v] = (counts[v] or 0) + 1 end
      for _, v in ipairs(sorted_copy(x)) do
        assert(counts[v] and counts[v] > 0, "sorted output invented a value")
        counts[v] = counts[v] - 1
      end
      for v, n in pairs(counts) do
        assert(n == 0, "sorted output dropped value " .. tostring(v))
      end
    end },
}

local prop_failures = 0
for _, prop in ipairs(props) do
  local ran = 0
  local first_error = nil
  for _ = 1, ITERATIONS do
    local input = random_list(20)
    local ok, err = pcall(prop.run, input)
    if not ok and not first_error then
      first_error = err
    end
    ran = ran + 1
  end
  if first_error then
    prop_failures = prop_failures + 1
    print(string.format("  [FAIL] %s (after %d cases): %s",
      prop.name, ran, tostring(first_error)))
  else
    print(string.format("  [ok  ] %-58s %d cases", prop.name, ran))
  end
end

check(string.format("all %d properties held over %d inputs each",
  #props, ITERATIONS), prop_failures == 0)

-- Reproducibility: the same seed must yield the same first input, otherwise a
-- property failure cannot be replayed by anyone else.
math.randomseed(SEED)
local first_a = random_list(20)
math.randomseed(SEED)
local first_b = random_list(20)
local replay_ok, replay_err = pcall(assert_deep_eq, first_a, first_b)
check("same seed produces the same generated input (failures are replayable)",
  replay_ok)
if not replay_ok then print("    " .. tostring(replay_err)) end

--------------------------------------------------------------------------------
-- 5. CI contract
--------------------------------------------------------------------------------

section("5. CI contract")

local function ci_exit_code(suite_runner)
  local _, f = suite_runner.summary()
  return f > 0 and 1 or 0
end
check("green suite exits 0", ci_exit_code(suite) == 0)
check("red suite exits 1", ci_exit_code(probe) == 1)

--------------------------------------------------------------------------------
-- Summary
--------------------------------------------------------------------------------

print()
print(string.rep("=", 64))
print(string.format("All %d checks passed.", checks))
print(string.rep("=", 64))
print("TEST RUNNER OK")
