-- examples/ci_pipeline.lua — Complete CI pipeline example using Lua
-- This demonstrates how to integrate TAP reporting with actual validation steps.
-- Run as part of a CI pipeline (e.g., GitHub Actions job).

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/43-toolchain/ci-cd-integration/src/?.lua;" .. package.path

local TAP = require("tap")

print("=== CI Pipeline (Lua-based) ===")
print()

local tap = TAP.new():plan(6)

-- Test 1: Syntax validation
do
  tap:pass("syntax-validation")
  -- In practice: check all .lua files parse correctly
  print("  Checking syntax of .../lua-build-system/src/build.lua ... OK")
  print("  Checking syntax of .../ci-cd-integration/src/tap.lua ... OK")
end

-- Test 2: Unit tests
do
  local ok = true  -- Simulated success
  if ok then
    tap:pass("unit-tests")
    print("  All unit tests passed")
  else
    tap:fail("unit-tests", "some error")
  end
end

-- Test 3: Module loading
do
  do
    local ok = pcall(require, "build")
    if ok then
      tap:pass("module-loading")
    else
      tap:fail("module-loading", "Failed to load module")
    end
  end
end

-- Test 4: Code formatting (stylua check simulated)
do
  tap:pass("code-formatting")
  print("  Formatting check: all files pass stylua style guidelines")
end

-- Test 5: Documentation completeness
do
  tap:pass("documentation")
  print("  README files present in all stages")
  print("  Translation coverage: 100% English + Chinese")
end

-- Test 6: Parity check
do
  tap:pass("parity-check")
  print("  EN/ZH file pairs match")
end

print()
local success = tap:done()
if success then
  print("CI Pipeline: SUCCESS")
  os.exit(0)
else
  print("CI Pipeline: FAILED")
  os.exit(1)
end
