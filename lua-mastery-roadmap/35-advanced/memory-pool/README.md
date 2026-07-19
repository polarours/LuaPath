# Stage 35: Memory Pool

## Title
Memory Pool — Fast Object Allocation and Reuse for Performance

## Description
A memory pool pre-allocates a fixed set of objects and recycles them instead of constantly creating and garbage-collecting new objects. This dramatically reduces GC pressure and allocation overhead in performance-critical Lua applications like game engines, network servers, and real-time systems.

This implementation provides a generic pool with configurable sizing, automatic growth, statistics tracking, and lifecycle hooks for acquire/release operations.

## Prerequisites
- Lua tables and metatables
- Closures and functions as values
- `setmetatable` and `__index` metamethods
- Basic understanding of garbage collection
- Knowledge of performance profiling concepts

## How to Run
```bash
lua5.4 01-memory-pool.lua
```

## Key Concepts
- **Object pooling**: Reuse objects instead of allocating new ones each time
- **Pre-allocation**: Create objects upfront to avoid runtime allocation stalls
- **Pool sizing**: Configure min/max sizes and growth strategy
- **Acquire/release**: Borrow objects from the pool and return them when done
- **Reset semantics**: Clean object state on release for safe reuse
- **Statistics tracking**: Monitor pool utilization, hit rates, and growth events
- **Lifecycle hooks**: Execute custom logic on acquire (init) and release (cleanup)
- **Generic pools**: Pool any object type via factory functions
