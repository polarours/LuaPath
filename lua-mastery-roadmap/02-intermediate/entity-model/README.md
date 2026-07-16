# Prototype-Based Entity Model

**Stage**: 2 (Intermediate)
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

A prototype-based entity system inspired by game engine architectures. This project teaches metatable dispatch, prototype inheritance chains, and read-only overlays — patterns central to building flexible, composable object systems in Lua.

## What It Teaches

- Metatable-based dispatch with `__index` and `__newindex`
- Prototype inheritance (no classes, just delegation)
- Read-only overlays for entity state protection
- The proxy pattern for validation and logging

## Prerequisites

- Chapter 04: Tables (creation, nesting, iteration)
- Chapter 05: Metatables (metamethods, dispatch chains)

## How to Run

```bash
lua entity-model.lua
```

The script creates sample entities, applies prototypes, and demonstrates read-only behavior.

## Key Concepts

- `setmetatable` — associates a metatable with a table
- `__index` — controls read behavior for missing keys
- `__newindex` — intercepts writes to enforce immutability
- `rawget` / `rawset` — bypass metatables when needed
- Proxy pattern — thin wrapper that delegates to a backing table

## Suggested Improvements

1. Add `__pairs` metamethod for ordered iteration
2. Implement deep clone with prototype chain traversal
3. Add type-safe component access with error messages
4. Benchmark prototype lookup depth vs flat tables
5. Extend to support multiple inheritance with conflict resolution

## Files

```
entity-model/
├── README.md          ← This file
├── entity-model.lua   ← Main implementation
└── examples.lua       ← Usage patterns and test cases
```
