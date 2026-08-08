-- unit_test.lua — Unit tests for AoS and SoA particle systems
-- Run from project root with: lua tests/unit_test.lua

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/42-performance/cache-friendly/?.lua;" .. package.path

local AosParticles = require("aos_particles")
local SoaParticles = require("soa_particles")

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

print("=== AoS/SoA Unit Tests ===")

print("\n1. AoS basic creation")
local aos = AosParticles.new(5)
assert_true(aos ~= nil, "AoS instance created")
assert_eq(#aos.particles, 5, "AoS has 5 particles")

print("\n2. AoS update")
aos:update(0.016)
assert_true(aos.particles[1].x ~= nil, "AoS position updated")

print("\n3. SoA basic creation")
local soa = SoaParticles.new(5)
assert_true(soa ~= nil, "SoA instance created")
assert_eq(#soa.x, 5, "SoA has 5 x coordinates")

print("\n4. SoA update")
soa:update(0.016)
assert_true(soa.x[1] ~= nil, "SoA position updated")

print("\n5. Compare particle counts")
local aos2 = AosParticles.new(100)
local soa2 = SoaParticles.new(100)
assert_eq(#aos2.particles, 100, "AoS count matches")
assert_eq(#soa2.x, 100, "SoA count matches")

print("\n6. AoS field access")
local p = aos.particles[1]
assert_true(p.x ~= nil, "AoS particle has x field")
assert_true(p.y ~= nil, "AoS particle has y field")
assert_true(p.vx ~= nil, "AoS particle has vx field")
assert_true(p.vy ~= nil, "AoS particle has vy field")

print("\n7. SoA field access")
assert_true(#soa.x > 0, "SoA x array not empty")
assert_true(#soa.y > 0, "SoA y array not empty")
assert_true(#soa.vx > 0, "SoA vx array not empty")
assert_true(#soa.vy > 0, "SoA vy array not empty")

print("\n8. Empty initialization")
local empty_aos = AosParticles.new(0)
local empty_soa = SoaParticles.new(0)
assert_eq(#empty_aos.particles, 0, "Empty AoS")
assert_eq(#empty_soa.x, 0, "Empty SoA")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
