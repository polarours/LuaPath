# Stage 42.3: Memory Alignment

**Level**: Advanced  
**Description**: Understand how data alignment affects Lua's internal table layout and implement aligned data structures that optimize for both Lua's allocator and underlying hardware cache lines.

## Prerequisites

- Stage 05 — Metatables
- Stage 12 — Performance
- Stage 27 — Memory Management

## Project Structure

```
42-performance/memory-alignment/
├── README.md               # This file
├── README.zh-CN.md         # Chinese version
└── aligned_buffer.lua      -- Aligned buffer implementation with padding
```

## Background

Lua tables are hash arrays that may have irregular layouts. For high-throughput scenarios, understanding how Lua stores values in memory can help avoid cache-line splits and optimize throughput.

## Implementation

Create an `AlignedBuffer` module that uses a metatable-backed table to ensure proper alignment of data elements, padding where necessary to avoid cross-cache-line accesses.

```lua
-- aligned_buffer.lua — Simulates aligned memory access in Lua
local AlignedBuffer = {}
AlignedBuffer.__index = AlignedBuffer

function AlignedBuffer.new(size, align)
  align = align or 64  -- Typical cache line size in bytes
  self = setmetatable({}, AlignedBuffer)
  self.data = {}
  self.size = size
  self.align = align
  self.pad_offset = (align - (size % align)) % align
  return self
end

function AlignedBuffer:get(index)
  return self.data[index]
end

function AlignedBuffer:set(index, value)
  self.data[index] = value
end

return AlignedBuffer
```

## Time Estimate

8–12 hours
