# Stage 43.2: CI/CD Integration

**Level**: Advanced  
**Description**: Integrate Lua validation and testing into CI/CD pipelines. Learn to generate TAP (Test Anything Protocol) reports, create build status hooks, and automate quality checks in continuous integration systems.

## Prerequisites

- Stage 38 — Testing Patterns
- Stage 28 — Deployment Patterns
- Basic understanding of GitHub Actions or similar CI systems

## Project Structure

```
43-toolchain/ci-cd-integration/
├── README.md
├── README.zh-CN.md
├── src/
│   └── tap.lua          — TAP reporter module
│   └── hooks.lua        — CI hook utilities
├── examples/
│   └── ci_pipeline.lua  — Complete CI pipeline example
└── tests/
    └── tap_test.lua     — TAP reporter correctness tests
```

## Background

Continuous Integration systems expect test results in standardized formats. The Test Anything Protocol (TAP) is a simple text-based protocol between test programs and a TAP harness. Lua can easily generate TAP output for use in GitHub Actions, GitLab CI, Jenkins, and other CI systems.

## Implementation

### TAP Reporter (`src/tap.lua`)

```lua
local TAP = {}
TAP.__index = TAP

function TAP.new()
  return setmetatable({
    tests = 0,
    passed = 0,
    failed = 0,
    plans = {},
  }, TAP)
end

function TAP:plan(n)
  self.plans.total = n
  return self
end

function TAP:test(name)
  self.tests = self.tests + 1
  print("ok " .. self.tests .. " - " .. name)
  return self
end

function TAP:skip(name, reason)
  print("skip " .. (self.tests or 0) .. " " .. name .. " (" .. reason .. ")")
  return self
end

function TAP:done()
  if self.plans.total then
    print("1.." .. self.plans.total)
  end
  print("# Passed: " .. self.passed .. ", Failed: " .. self.failed)
  return self.failed == 0
end

return TAP
```

### CI Pipeline Example (`examples/ci_pipeline.lua`)

```lua
local TAP = require("src.tap")

local tap = TAP():plan(5)

tap:test("Syntax validation")
-- Run syntax checks on all Lua files
assert(io.popen("lua -c src/*.lua"):read("*a") == "")

tap:test("Unit tests")
-- Run the test suite
assert(io.popen("lua tests/*.lua"):true):close()

tap:test("Dependency resolution")
-- Check all required modules load
require("src.build")

tap:test("Format checking")
-- Verify code formatting

tap:test("Documentation check")
-- Ensure all files have README

tap:done()
```

## Time Estimate

8–12 hours
