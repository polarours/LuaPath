-- aligned_example.lua — Demonstrate aligned buffer usage
-- Shows how aligned access patterns can improve cache locality.

package.path = "?/?.lua;../?.lua;../?/?.lua;" .. package.path

local AlignedBuffer = require("../aligned_buffer")

local buf = AlignedBuffer.new(100, 64)

-- Fill buffer with sequential data
for i = 1, 100 do
  buf:set(i, i * i)
end

-- Read in blocks (simulating cache-line aligned access)
print("Reading blocks of 16 elements:")
for block_start = 1, 100, 16 do
  local block = buf:block_read(block_start, math.min(16, 100 - block_start + 1))
  print("Block", block_start .. "-" .. (block_start + #block - 1), "=", "[" .. table:block_concat(block, ", ") .. "]")
end

function table:block_concat(t, sep)
  local parts = {}
  for i = 1, #t do
    parts[i] = tostring(t[i])
  end
  return table.concat(parts, sep)
end
