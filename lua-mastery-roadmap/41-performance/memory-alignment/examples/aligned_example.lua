-- aligned_example.lua — Demonstrate aligned buffer usage
-- Shows how aligned access patterns can improve cache locality.

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../?.lua;" .. package.path


local AlignedBuffer = require("aligned_buffer")

local buf = AlignedBuffer.new(100, 64)

-- Fill buffer with sequential data
for i = 1, 100 do
  buf:set(i, i * i)
end

-- Read in blocks (simulating cache-line aligned access)
print("Reading blocks of 16 elements:")
for block_start = 1, 100, 16 do
  local block = buf:block_read(block_start, math.min(16, 100 - block_start + 1))
  local parts = {}
  for i = 1, #block do
    parts[i] = tostring(block[i])
  end
  print("Block", block_start .. "-" .. (block_start + #block - 1), "=", "[" .. table.concat(parts, ", ") .. "]")
end
