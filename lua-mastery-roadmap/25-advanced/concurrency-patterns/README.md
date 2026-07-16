# Concurrency Patterns
**Stage:** 25 — Advanced

## Description
Implement coroutine-based concurrency patterns including the actor model, CSP channels, and async/await simulations. Explore how Lua's lightweight coroutines enable cooperative multitasking without OS threads.

## Prerequisites
- Stages 1–24 completed
- Solid understanding of Lua coroutines and closures
- Familiarity with metatables and metamethods

## How to Run
```bash
lua 01-concurrency-patterns.lua
```

## Key Concepts
- Actor model with message passing
- CSP (Communicating Sequential Processes) channels
- Async/await pattern using coroutine wrappers
- Cooperative scheduling and yield/resume
- Channel buffering and selection

## Files
- `01-concurrency-patterns.lua` — Actor model, CSP channels, and async/await with coroutines
