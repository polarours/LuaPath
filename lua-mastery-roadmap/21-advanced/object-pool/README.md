# Object Pool

Stage 21: Advanced

## Description

Implement a generic object pool that reuses expensive objects to reduce allocation pressure and GC overhead.

## Prerequisites

- Stage 5 (Performance)
- Stage 11 (Cache System)

## How to Run

```bash
lua 01-object-pool.lua
```

## Key Concepts

- Object reuse and lifecycle management
- Pre-allocation strategies
- Pool statistics and monitoring
- Bounded pool with eviction

## Files

- `01-object-pool.lua` — Object pool implementation with acquire/release
