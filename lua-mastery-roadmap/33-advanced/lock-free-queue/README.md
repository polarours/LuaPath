# Stage 33: Lock-Free Queue

## Title
Lock-Free Queue — Concurrent Data Structure with Atomic Operations

## Description
A lock-free queue uses atomic operations (compare-and-swap, load-linked/store-conditional) instead of mutexes to achieve thread-safe enqueue and dequeue. This implementation simulates atomic operations in single-threaded Lua using coroutines and cooperative scheduling, demonstrating the core concepts of lock-free algorithms without requiring actual OS threads.

Lock-free data structures are fundamental to high-performance concurrent systems, offering better scalability and avoiding deadlocks inherent to lock-based approaches.

## Prerequisites
- Lua tables and metatables
- Closures and functions as values
- Coroutine basics (`coroutine.create`, `resume`, `yield`)
- Understanding of linked lists
- Basic concurrency concepts

## How to Run
```bash
lua5.4 01-lock-free-queue.lua
```

## Key Concepts
- **Atomic operations**: Simulated CAS (compare-and-swap) operations using tables as shared state
- **ABA problem**: Detecting when a value changes A→B→A, causing incorrect success on CAS
- **Memory reclamation**: Deferred freeing to prevent use-after-free in concurrent contexts
- **Cooperative scheduling**: Coroutines interleaving to simulate concurrent producers/consumers
- **Producer-consumer pattern**: Multiple producers enqueuing and consumers dequeuing safely
- **Sentinel nodes**: Dummy head/tail nodes to simplify boundary conditions
