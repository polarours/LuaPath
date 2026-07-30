-- memory_alignment_test.lua — Test aligned buffer basic operations
-- Run from project root with: lua lua-mastery-roadmap/42-performance/memory-alignment/tests/memory_alignment_test.lua

-- Add parent directory to module path
package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/42-performance/memory-alignment/?.lua;" .. package.path

local AlignedBuffer = require("aligned_buffer")

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

print("=== Aligned Buffer Tests ===")

print("\n1. Basic set/get")
local buf = AlignedBuffer.new(10, 64)
for i = 1, 10 do
  buf:set(i, i * 10)
end
assert_eq(buf:get(5), 50, "set/get index 5")
assert_eq(buf:get(1), 10, "set/get index 1")
assert_eq(buf:get(11), nil, "out of bounds returns nil")

print("\n2. Padding calculation")
local buf2 = AlignedBuffer.new(100, 64)
assert_eq(buf2.pad_offset, 28, "Padding for size 100 with align 64")

print("\n3. Block read/write")
local buf3 = AlignedBuffer.new(20, 64)
buf3:block_write(1, {10, 20, 30, 40})
local block = buf3:block_read(1, 4)
assert_eq(block[1], 10, "block_read index 1")
assert_eq(block[4], 40, "block_read index 4")

print("\n=== Results: " .. pass .. "/" .. total .. " passed ===")
if fail > 0 then
  print("FAILURES: " .. fail .. " tests failed")
else
  print("ALL TESTS PASSED!")
end
