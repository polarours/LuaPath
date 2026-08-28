-- benchmark_test.lua — Compare AoS vs SoA particle system performance
-- Run from project root with: lua lua-mastery-roadmap/42-performance/cache-friendly/tests/benchmark_test.lua

-- Add parent directory to module path
-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local AosParticles = require("aos_particles")
local SoaParticles = require("soa_particles")

local function bench_create(cls, n, iterations)
  local start = os.clock()
  for i = 1, iterations do
    cls.new(n)
  end
  return os.clock() - start
end

local function bench_update(cls, n, iterations)
  local obj = cls.new(n)
  local start = os.clock()
  for i = 1, iterations do
    obj:update(0.016)
  end
  return os.clock() - start
end

local N = 100000
local ITERATIONS = 100

print("=== Cache-friendly Layout Benchmark ===")
print("Particles: " .. N .. ", Iterations: " .. ITERATIONS)
print()

local acreate = bench_create(AosParticles, N, ITERATIONS)
local screate = bench_create(SoaParticles, N, ITERATIONS)
print("Create - AoS: " .. string.format("%.3f", acreate) .. "s, SoA: " .. string.format("%.3f", screate) .. "s")

local aupdate = bench_update(AosParticles, N, ITERATIONS)
local supdate = bench_update(SoaParticles, N, ITERATIONS)
print("Update - AoS: " .. string.format("%.3f", aupdate) .. "s, SoA: " .. string.format("%.3f", supdate) .. "s")

print()
print("Update ratio (AoS/SoA): " .. string.format("%.2f", aupdate / supdate))
print("SoA is " .. string.format("%.1f", (aupdate / supdate)) .. "x faster for update loop")
print()

print("Note: Results may vary by Lua version and runtime environment.")
print("Expected: SoA faster for sequential field access patterns")