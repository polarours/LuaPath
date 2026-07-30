-- compare_layouts.lua — Side-by-side comparison of AoS and SoA particle systems
-- Demonstrates both layout patterns in a single runnable example.

package.path = "?/?.lua;../?.lua;../?/?.lua;" .. package.path

local AosParticles = require("aos_particles")
local SoaParticles = require("soa_particles")

print("=== Cache Layout Comparison: AoS vs SoA ===")
print()

local n = 5000
local dt = 0.016

print("Initializing " .. n .. " particles...")

-- AoS version
local aos = AosParticles.new(n)
print("AoS layout initialized")

-- SoA version
local soa = SoaParticles.new(n)
print("SoA layout initialized")
print()

print("Updating positions (" .. ITERATIONS or 100 .. " frames)...")

local start = os.clock()
for i = 1, 100 do
  aos:update(dt)
end
local aos_time = os.clock() - start
print("AoS update time: " .. string.format("%.4f", aos_time) .. "s")

start = os.clock()
for i = 1, 100 do
  soa:update(dt)
end
local soa_time = os.clock() - start
print("SoA update time: " .. string.format("%.4f", soa_time) .. "s")
print()

print("Performance:")
print("  Ratio (AoS/SoA): " .. string.format("%.2f", aos_time / soa_time))
print("  SoA is " .. string.format("%.1f", (aos_time / soa_time)) .. "x faster for this loop")
print()
print("Summary: SoA (Struct-of-Arrays) is more cache-efficient when")
print("accessing individual fields across many records sequentially.")
