# Stage 31: Balking Pattern

## Title
Balking Pattern — Skip Actions When Preconditions Are Not Met

## Description
The Balking pattern prevents an operation from executing if the object is not in the right state. Unlike the Guard pattern which waits, Balking immediately returns without action. This is useful for operations that should only run under specific conditions and where waiting is unnecessary.

Common uses include: one-time initialization, idempotent saves, and operations that must be guarded by readiness checks.

## Prerequisites
- Lua functions and closures
- Metatables for object behavior
- Understanding of state management
- Basic concurrency concepts (mental model)

## How to Run
```bash
lua5.4 01-balking.lua
```

## Key Concepts
- **Balking guard**: A precondition check that short-circuits execution
- **State-dependent execution**: Only run when the object is in a valid state
- **Immediate return**: No waiting or retry — just skip
- **Idempotent operations**: Safe to call multiple times without side effects
- **Use cases**: One-time init, guarded writes, resource cleanup
