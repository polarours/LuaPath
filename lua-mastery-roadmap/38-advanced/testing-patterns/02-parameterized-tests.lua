#!/usr/bin/env lua
-- Stage 38: Testing Patterns - Parameterized Tests
-- Data-driven test execution
-- Lua Version: 5.1+
--
-- Demonstrates: describe/it registry, parameter sets, per-case failure reports, suite runner

-- ---------------------------------------------------------------------------
-- The subject under test
-- ---------------------------------------------------------------------------

--- Turn a title into a URL slug: lowercase, runs of non-alphanumerics become
-- a single dash, and leading and trailing dashes are dropped.
-- @param text the source text
-- @return string the slug
local function slugify(text)
  local lowered = text:lower()
  local dashed = lowered:gsub("[^%w]+", "-")
  local trimmed = dashed:gsub("^%-+", ""):gsub("%-+$", "")
  return trimmed
end

-- ---------------------------------------------------------------------------
-- A tiny describe/it registry
-- ---------------------------------------------------------------------------

--- The registered groups of test cases.
local groups = {}

--- The group that `it` currently appends to.
local current_group = nil

--- Declare a group of related test cases.
-- @param name the group name, shown in the failure report
-- @param body function() that calls `it` to register the cases
local function describe(name, body)
  local group = { name = name, cases = {} }
  groups[#groups + 1] = group
  local previous = current_group
  current_group = group
  body()
  current_group = previous
end

--- Register one test case in the current group.
-- @param name the case name, shown in the failure report
-- @param body function() that raises when the case fails
local function it(name, body)
  assert(current_group, "it() must be called inside describe()")
  current_group.cases[#current_group.cases + 1] = { name = name, body = body }
end

-- ---------------------------------------------------------------------------
-- Running cases
-- ---------------------------------------------------------------------------

--- Run one test body against a table of parameter sets.
-- The cases are independent: a failing case is recorded and the run
-- continues, so one bad row of data does not hide the rows after it.
-- @param name the test name, used in the report
-- @param body function(case) that raises when the case fails
-- @param cases array of parameter sets
-- @return table report with `total`, `passed`, `failed` and `failures`
local function run_cases(name, body, cases)
  local report = { name = name, total = #cases, passed = 0, failed = 0, failures = {} }
  for index, case in ipairs(cases) do
    local ok, err = pcall(body, case)
    if ok then
      report.passed = report.passed + 1
    else
      report.failed = report.failed + 1
      report.failures[#report.failures + 1] = {
        index = index,
        label = string.format("%s case #%d", name, index),
        case = case,
        message = tostring(err),
      }
    end
  end
  return report
end

--- Run every registered case and collect the outcome.
-- A failing case is recorded, not raised: the runner always reaches the
-- last case, which is what makes the report trustworthy.
-- @return table results with `total`, `passed`, `failed` and `failures`
local function run_suite()
  local results = { total = 0, passed = 0, failed = 0, failures = {} }
  for _, group in ipairs(groups) do
    for _, case in ipairs(group.cases) do
      results.total = results.total + 1
      local ok, err = pcall(case.body)
      if ok then
        results.passed = results.passed + 1
      else
        results.failed = results.failed + 1
        results.failures[#results.failures + 1] = {
          label = group.name .. " > " .. case.name,
          message = tostring(err),
        }
      end
    end
  end
  return results
end

--- Render one failure as a single readable line.
-- @param failure a failure entry from a report
-- @return string the rendered failure
local function format_failure(failure)
  return string.format("%s: %s", failure.label, failure.message)
end

-- ---------------------------------------------------------------------------
-- Checks
-- ---------------------------------------------------------------------------

--- Check one slug case.
-- `error` with level 0 keeps the message free of a file and line prefix, so
-- the report shows the case and not the harness.
-- @param case table with `text` and `expected` fields
local function check_slug(case)
  local actual = slugify(case.text)
  if actual ~= case.expected then
    error(string.format("slugify(%q) = %q, expected %q", case.text, actual, case.expected), 0)
  end
end

local SLUG_CASES = {
  { text = "Hello, World!", expected = "hello-world" },
  { text = "  Lua 5.1  ", expected = "lua-5-1" },
  { text = "Already-slugged", expected = "already-slugged" },
  { text = "!!!", expected = "" },
  { text = "", expected = "" },
}

describe("slugify", function()
  it("lowercases and dashes the non-alphanumerics", function()
    assert(slugify("Hello, World!") == "hello-world")
  end)

  it("keeps the digits", function()
    assert(slugify("Lua 5.1") == "lua-5-1")
  end)
end)

describe("parameterized slugify", function()
  it("passes every case in the table", function()
    local report = run_cases("slugify", check_slug, SLUG_CASES)
    assert(report.failed == 0)
    assert(report.passed == #SLUG_CASES)
  end)
end)

local results = run_suite()
assert(results.total == 3)
assert(results.passed == 3)
assert(results.failed == 0)
assert(#results.failures == 0)

-- One expectation is wrong on purpose. The runner must name the case that
-- failed and keep going, rather than aborting the script.
local BAD_CASES = {
  { text = "Hello, World!", expected = "hello-world" },
  { text = "Lua 101", expected = "lua101" },
}

local bad_report = run_cases("slugify", check_slug, BAD_CASES)
assert(bad_report.total == 2)
assert(bad_report.passed == 1)
assert(bad_report.failed == 1)
assert(#bad_report.failures == 1)
assert(bad_report.failures[1].index == 2)
assert(bad_report.failures[1].case.text == "Lua 101")
assert(bad_report.failures[1].message:find("lua-101", 1, true) ~= nil)
assert(bad_report.failures[1].message:find("expected \"lua101\"", 1, true) ~= nil)

print("expected failure: " .. format_failure(bad_report.failures[1]))

-- A registered case that fails is recorded by the suite runner, and the
-- cases after it still run.
describe("known broken case", function()
  it("is reported instead of aborting the run", function()
    error("this case is broken on purpose", 0)
  end)

  it("does not stop the cases after it", function()
    assert(slugify("Later Case") == "later-case")
  end)
end)

local broken = run_suite()
assert(broken.total == 5)
assert(broken.passed == 4)
assert(broken.failed == 1)
assert(#broken.failures == 1)
assert(broken.failures[1].label == "known broken case > is reported instead of aborting the run")
assert(broken.failures[1].message:find("broken on purpose", 1, true) ~= nil)

print("✓ parameterized-tests tests passed")
