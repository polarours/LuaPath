-- tests/resolve_test.lua — Test package dependency resolution
-- Run from project root with: lua lua-mastery-roadmap/43-toolchain/lua-package-manager/tests/resolve_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/43-toolchain/lua-package-manager/src/?.lua;" .. package.path

local PackageManager = require("pkg_manager")

local pass = 0
local fail = 0
local total = 0

function assert_eq(actual, expected, msg)
  total = total + 1
  if actual == expected then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (expected=" .. tostring(expected) .. ", actual=" .. tostring(actual) .. ")")
  end
end

function assert_true(val, msg)
  total = total + 1
  if val then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (expected true)")
  end
end

function assert_contains(tbl, val, msg)
  total = total + 1
  for _, v in ipairs(tbl) do
    if v:find(val, 1, true) then
      pass = pass + 1
      return
    end
  end
  fail = fail + 1
  print("FAIL: " .. msg .. " (substring '" .. val .. "' not found in table)")
end

function assert_nil(val, msg)
  total = total + 1
  if val == nil then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (expected nil, got " .. tostring(val) .. ")")
  end
end

function empty(tbl)
  return not tbl or next(tbl) == nil
end

print("=== Package Manager Tests ===")

print("\n1. Basic registration and resolution of single package")
local pm1 = PackageManager.new()
pm1:register("pkg-a", "1.0.0", {})
local resolved1 = pm1:resolve { ["pkg-a"] = "1.0.0" }
assert_true(resolved1, "Resolution succeeds")
assert_eq(resolved1["pkg-a"].version, "1.0.0", "Version matched")

print("\n2. Dependency chain resolution")
local pm2 = PackageManager.new()
pm2:register("parent", "1.0.0", { ["child"] = "1.0.0" })
pm2:register("child", "1.0.0", {})
local resolved2 = pm2:resolve { ["parent"] = "1.0.0" }
assert_true(resolved2, "Chain resolves")
assert_eq(resolved2["child"].version, "1.0.0", "Child version correct")

print("\n3. Multiple roots with shared dependency")
local pm3 = PackageManager.new()
pm3:register("lib-core", "2.0.0", {})
pm3:register("module-a", "1.0.0", { ["lib-core"] = "2.0.0" })
pm3:register("module-b", "1.0.0", { ["lib-core"] = "2.0.0" })
local resolved3 = pm3:resolve { ["module-a"] = "1.0.0", ["module-b"] = "1.0.0" }
assert_true(resolved3, "Multiple modules resolve")
assert_eq(resolved3["lib-core"].version, "2.0.0", "Shared lib-core correctly resolved")

print("\n4. Cycle detection")
local pm4 = PackageManager.new()
pm4:register("a", "1.0.0", { ["b"] = "1.0.0" })
pm4:register("b", "1.0.0", { ["a"] = "1.0.0" })
local resolved4 = pm4:resolve { ["a"] = "1.0.0" }
assert_nil(resolved4, "Cycle causes resolution to fail")
assert_contains(pm4.conflicts, "Cycle detected", "Conflict message contains cycle text")

print("\n5. Unknown package handling")
local pm5 = PackageManager.new()
local resolved5 = pm5:resolve { ["nonexistent"] = "1.0.0" }
assert_nil(resolved5, "Unknown package returns nil")
assert_contains(pm5.conflicts, "Unknown package", "Error message contains unknown package text")

print("\n6. Version 'latest' selection")
local pm6 = PackageManager.new()
pm6:register("pkg", "1.0.0", {})
pm6:register("pkg", "2.0.0", {})
pm6:register("pkg", "3.0.0", {})
local resolved6 = pm6:resolve { ["pkg"] = "latest" }
assert_true(resolved6, "Latest version resolves")
assert_eq(resolved6["pkg"].version, "3.0.0", "Highest version selected")

print("\n7. Version constraint not met")
local pm7 = PackageManager.new()
pm7:register("dep", "1.0.0", {})
pm7:register("main", "1.0.0", { ["dep"] = "2.0.0" })
local resolved7 = pm7:resolve { ["main"] = "1.0.0" }
assert_nil(resolved7, "Unmet constraint causes failure")

print("\n8. Empty resolution")
local pm8 = PackageManager.new()
local resolved8 = pm8:resolve {}
assert_true(empty(resolved8), "Empty input gives empty output")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
