# Stage 32: Double Buffer Pattern

## Title
Double Buffer Pattern — Smooth Data Transition with Swap

## Description
The Double Buffer pattern uses two buffers to decouple producers from consumers. One buffer is being written to while the other is being read from. When the write buffer is ready, they swap roles. This eliminates flickering in graphics and ensures data consistency in concurrent systems.

In Lua, we use table references to implement the swap efficiently without copying data.

## Prerequisites
- Lua tables and references
- Metatables for controlled access
- Understanding of producer-consumer patterns
- Basic synchronization concepts (mental model)

## How to Run
```bash
lua5.4 01-double-buffer.lua
```

## Key Concepts
- **Two buffers**: Read buffer and write buffer
- **Swap operation**: Atomically exchange buffer roles
- **Producer writes** to the back buffer
- **Consumer reads** from the front buffer
- **Consistent snapshots**: Reads never see partial writes
- **Use cases**: Display rendering, real-time data, game state, logging
