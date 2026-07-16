# Performance Analysis

**Stage**: 5 (Advanced)
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

A performance analysis toolkit that demonstrates profiling techniques, allocation optimization, and GC tuning. This project teaches how to identify hot paths, measure execution time, and optimize Lua code for production workloads.

## What It Teaches

- Profiling with `os.clock` and `collectgarbage`
- String concatenation alternatives (`table.concat` vs `..`)
- Local vs global variable performance impact
- Table reuse and pre-allocation strategies

## Prerequisites

- Chapter 12: Performance (benchmarks, optimization)
- Chapter 13: Patterns (efficient pattern usage)
- Chapter 14: Lua in Production (deployment considerations)

## How to Run

```bash
lua perf-analysis.lua
```

The script runs multiple benchmarks comparing different Lua coding patterns.

## Key Concepts

- `os.clock` — high-resolution CPU time measurement
- `collectgarbage("count")` — memory usage tracking
- `collectgarbage("collect")` — force garbage collection
- `table.concat` — O(n) string building vs O(n²) concatenation
- Local variable scope — avoids global table lookup

## Suggested Improvements

1. Add LuaJIT-specific benchmarks with JIT warm-up detection
2. Implement function-level profiling with `debug.sethook`
3. Add memory allocation tracking per function
4. Create a reusable benchmark harness with statistical analysis
5. Compare Lua 5.4 generational vs incremental GC modes

## Files

```
perf-analysis/
├── README.md           ← This file
├── perf-analysis.lua   ← Main benchmarks
├── benchmarks.lua      ← Individual benchmark cases
└── results.md          ← Benchmark results and analysis
```
