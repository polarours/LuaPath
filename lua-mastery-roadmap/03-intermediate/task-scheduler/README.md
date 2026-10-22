# Cooperative Task Scheduler

**Stage**: 3 (Intermediate)
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

A cooperative task scheduler built entirely on coroutines. This project demonstrates how to structure concurrent tasks without OS threads — a pattern essential for event-driven systems, game loops, and network servers where deterministic scheduling matters more than parallelism.

## What It Teaches

- Coroutine lifecycle: create, yield, resume
- Cooperative multitasking (tasks yield control explicitly)
- Priority scheduling and timeout handling
- Task dependency resolution

## Prerequisites

- Chapter 08: Coroutines (create, resume, yield)
- Chapter 09: Standard Library (table.sort, os.clock)

## How to Run

```bash
lua 03-task-scheduler.lua
```

The script runs a set of example tasks with different priorities and durations.

## Key Concepts

- `coroutine.create` — wraps a function as a coroutine
- `coroutine.yield` — pauses execution, returns values to caller
- `coroutine.resume` — resumes a yielded coroutine
- `coroutine.status` — checks if a coroutine is dead, suspended, or running
- Round-robin vs priority scheduling

## Suggested Improvements

1. Add deadline scheduling with hard/soft time limits
2. Implement task groups with shared cancellation
3. Add proper error propagation across yield boundaries
4. Support async I/O integration (non-blocking file/network)
5. Benchmark against LuaJIT coroutines for performance comparison

## Files

```
03-intermediate/task-scheduler/
├── README.md
├── README.zh-CN.md
├── 03-task-scheduler.lua      — Main implementation
└── tests/
    └── task_scheduler_test.lua  — Sample tasks and scheduling patterns
```
