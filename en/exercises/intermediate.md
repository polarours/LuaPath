# Intermediate Exercises

## Concept Reinforcement

1. Implement read-only proxy table using `__index` + `__newindex`.
2. Build memoization helper with LRU eviction.
3. Implement iterator `window(xs, k)` for sliding windows.

## Mini Project

Build a coroutine-based job scheduler:

- Cooperative tasks (`spawn`, `yield`, `sleep`)
- Timeout and cancellation
- Structured error propagation

## Debugging Tasks

1. Fix infinite recursion in broken `__newindex` metamethod.
2. Diagnose coroutine starvation due to unfair queue.
3. Resolve circular module dependency with partial initialization.

## Open-Ended Design Questions

1. When should a module return `nil, err` versus raising error?
2. How would you design event bus API to prevent handler leaks?
3. What metrics prove scheduler health in production?
