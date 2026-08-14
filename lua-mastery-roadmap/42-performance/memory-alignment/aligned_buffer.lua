-- aligned_buffer.lua — Aligned buffer with padding for cache-line optimization
-- Demonstrates memory-aligned data layout patterns in Lua.
-- 
-- This module simulates cache-line aligned access patterns by adding
-- padding to ensure data blocks align to cache line boundaries (typically 64 bytes).
-- While Lua tables don't have direct memory control, this pattern illustrates
-- the principles used in high-performance systems programming.

local AlignedBuffer = {}
AlignedBuffer.__index = AlignedBuffer

--- Create a new aligned buffer.
-- @tparam number size Number of elements
-- @tparam number [align=64] Cache line alignment in bytes
-- @treturn AlignedBuffer New buffer instance
function AlignedBuffer.new(size, align)
  align = align or 64  -- Typical cache line size in bytes
  local self = setmetatable({}, AlignedBuffer)
  self.data = {}
  self.size = size
  self.align = align
  -- Calculate padding to keep next element on boundary
  self.pad_offset = (align - (size % align)) % align
  return self
end

--- Get element at index.
-- @tparam number index 1-based index
-- @treturn any Value at index, or nil if out of bounds
function AlignedBuffer:get(index)
  if index > self.size then return nil end
  return self.data[index]
end

--- Set element at index.
-- @tparam number index 1-based index
-- @tparam any value Value to set
-- @treturn boolean True if successful, false if out of bounds
function AlignedBuffer:set(index, value)
  if index > self.size then return false end
  self.data[index] = value
  return true
end

--- Calculate aligned index with padding.
-- @tparam number idx Original index
-- @treturn number Aligned index for cache-line access
function AlignedBuffer:aligned_index(idx)
  -- Apply padding so that bulk access stays within one cache line
  return idx + self.pad_offset
end

--- Read a block of elements with aligned access.
-- Simulates cache-line aligned bulk read operations.
-- @tparam number start_idx Starting index
-- @tparam number count Number of elements to read
-- @treturn table Array of values
function AlignedBuffer:block_read(start_idx, count)
  -- Read a block assuming alignment guarantees local cache locality
  local result = {}
  local actual_start = self:aligned_index(start_idx)
  for i = 1, count do
    result[i] = self.data[actual_start + i - 1]
  end
  return result
end

--- Write a block of elements with aligned access.
-- Simulates cache-line aligned bulk write operations.
-- @tparam number start_idx Starting index
-- @tparam table values Array of values to write
function AlignedBuffer:block_write(start_idx, values)
  -- Write a block with aligned access pattern
  local actual_start = self:aligned_index(start_idx)
  for i, v in ipairs(values) do
    self.data[actual_start + i - 1] = v
  end
end

return AlignedBuffer
