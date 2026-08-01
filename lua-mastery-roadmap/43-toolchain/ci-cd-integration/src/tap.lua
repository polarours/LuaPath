-- src/tap.lua — TAP (Test Anything Protocol) reporter for CI/CD integration
-- Generates TAP-compliant output for test results in continuous
-- integration systems like GitHub Actions, GitLab CI, Jenkins.

local TAP = {}
TAP.__index = TAP

--- Create a new TAP reporter.
function TAP.new()
  return setmetatable({
    tests = 0,
    passed = 0,
    failed = 0,
    plans = {},
  }, TAP)
end

--- Set the total number of tests planned.
function TAP:plan(n)
  self.plans.total = n
  return self
end

--- Report a test with a name.
function TAP:test(name)
  self.tests = self.tests + 1
  print("ok " .. self.tests .. " - " .. name)
  return self
end

--- Skip a test.
function TAP:skip(name, reason)
  print("skip " .. (self.tests or 0) .. " " .. name .. " (" .. reason .. ")")
  return self
end

--- Report test completion and summary.
function TAP:done()
  if self.plans.total then
    print("1.." .. self.plans.total)
  end
  print("# Passed: " .. self.passed .. ", Failed: " .. self.failed)
  return self.failed == 0
end

--- Mark a test as passed.
function TAP:pass(name)
  self:test(name)
  self.passed = self.passed + 1
  return self
end

--- Mark a test as failed.
function TAP:fail(name, reason)
  self.tests = self.tests + 1
  print("not ok " .. self.tests .. " - " .. name)
  if reason then
    print("# " .. reason)
  end
  self.failed = self.failed + 1
  return self
end

return TAP
