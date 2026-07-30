-- aligned_buffer.lua — Aligned buffer with padding for cache-line optimization
-- Demonstrates memory-aligned data layout patterns in Lua.

local AlignedBuffer = {}
AlignedBuffer.__index = AlignedBuffer

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

function AlignedBuffer:get(index)
  if index > self.size then return nil end
  return self.data[index]
end

function AlignedBuffer:set(index, value)
  if index > self.size then return false end
  self.data[index] = value
  return true
end

function AlignedBuffer:aligned_index(idx)
  -- Apply padding so that bulk access stays within one cache line
  return idx + self.pad_offset
end

function AlignedBuffer:block_read(start_idx, count)
  -- Read a block assuming alignment guarantees local cache locality
  local result = {}
  local actual_start = self:aligned_index(start_idx)
  for i = 1, count do
    result[i] = self.data[actual_start + i - 1]
  end
  return result
end

function AlignedBuffer:block_write(start_idx, values)
  -- Write a block with aligned access pattern
  local actual_start = self:aligned_index(start_idx)
  for i, v in ipairs(values) do
    self.data[actual_start + i - 1] = v
  end
end

return AlignedBuffer
