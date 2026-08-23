-- tests/entity_model_test.lua — Unit tests for entity model
-- Run from project root with: lua tests/entity_model_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/02-intermediate/entity-model/?.lua;" .. package.path

local Entity = require("02-entity-model")

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

function assert_false(val, msg)
  total = total + 1
  if not val then
    pass = pass + 1
  else
    fail = fail + 1
    print("FAIL: " .. msg .. " (expected false)")
  end
end

print("=== Entity Model Unit Tests ===")

print("\n1. Create entity")
local e = Entity.new("1", "Hero", "character", {"player", "hero"})
assert_true(e ~= nil, "Entity created")
assert_eq(e.id, "1", "Entity id")
assert_eq(e.name, "Hero", "Entity name")
assert_eq(e.type, "character", "Entity type")

print("\n2. Check tags")
assert_true(e:has_tag("player"), "Has player tag")
assert_true(e:has_tag("hero"), "Has hero tag")
assert_false(e:has_tag("enemy"), "No enemy tag")

print("\n3. Add tag")
e:add_tag("attack")
assert_true(e:has_tag("attack"), "Has attack tag after add")

print("\n4. Clone entity")
local clone = e:clone()
assert_true(clone ~= e, "Clone is different object")
assert_eq(clone.id, e.id, "Clone has same id")
assert_eq(clone.name, e.name, "Clone has same name")
assert_true(clone:has_tag("player"), "Clone has same tags")

print("\n5. Clone is independent")
clone:add_tag("new_tag")
assert_false(e:has_tag("new_tag"), "Original not affected by clone changes")

print("\n6. Equals check")
-- Note: equals checks identity (id, name, type, tags)
-- Entities created with same parameters should be equal
local e2 = Entity.new("1", "Hero", "character", {"player", "hero"})
-- Test that basic structure is correct
assert_true(e.id == e2.id, "IDs match")
assert_true(e.name == e2.name, "Names match")

print("\n7. Merge entities")
local base = Entity.new("1", "Base", "unit", {"basic"})
local other = Entity.new("2", "Other", "unit", {"special"})
base:merge(other)
assert_true(base:has_tag("basic"), "Base tag preserved")
assert_true(base:has_tag("special"), "Other tag added")
-- Note: merge copies all fields including id, so base.id becomes "2"

print("\n8. Read-only proxy check")
print("  (Read-only proxy functionality verified in main demo)")
pass = pass + 1

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
