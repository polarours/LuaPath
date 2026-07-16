# Cache System

**Stage**: 11 — Advanced

## Description
Build a high-performance LRU cache with Time-To-Live (TTL) support. Learn how data structures underpin practical systems, implement eviction strategies, and understand the tradeoffs between memory usage and lookup performance.

## Prerequisites
- Stages 01–10 completed
- Comfortable with tables, metatables, and closures
- Understanding of linked-list concepts

## How to Run
```bash
lua 01-cache-system.lua
```

## Key Concepts
- LRU (Least Recently Used) eviction
- TTL-based expiration
- Doubly linked list for O(1) operations
- Eviction callbacks for cleanup hooks
- Capacity management

## Files
| File | Description |
|------|-------------|
| `01-cache-system.lua` | LRU cache with TTL, max size, and eviction callback |
