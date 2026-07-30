# 第 42.3 阶段：内存对齐

**级别**: 高级  
**描述**: 理解数据对齐如何影响 Lua 内部表格布局，实现按内存对齐的数据结构，通过必要的 padding 避免跨缓存线访问，从而优化 Lua 分配器和底层硬件缓存的性能。

## 前置知识

- Stage 05 — Metatables
- Stage 12 — Performance
- Stage 27 — Memory Management

## 项目结构

```
42-performance/memory-alignment/
├── README.md               # 本文件
├── README.zh-CN.md         # 中文版
└── aligned_buffer.lua      -- 使用 padding 的 aligned buffer 实现
```

## 背景

Lua 表格是哈希数组，布局可能不规则。在高吞吐量场景下，理解 Lua 如何在内存中存储值有助于避免缓存线分割并优化吞吐量。

## 实现

创建 `AlignedBuffer` 模块，使用基于 metatable 的表格确保数据元素对齐，必要时添加 padding 以避免跨缓存线访问。

```lua
-- aligned_buffer.lua — 在 Lua 中模拟对齐内存访问
local AlignedBuffer = {}
AlignedBuffer.__index = AlignedBuffer

function AlignedBuffer.new(size, align)
  align = align or 64  -- 典型缓存线大小
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

## 预估时间

8–12 小时
