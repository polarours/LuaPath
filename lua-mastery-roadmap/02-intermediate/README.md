# Stage 2: Meta Layer and Architecture

**Stage**: 2 | **Time**: 20–25 hours | **Chapters**: 05–07
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

Master metatables, module design, and error handling. This is where Lua becomes expressive — building abstractions that are both flexible and safe.

- Topics: metatables, metamethods, modules, error/exception patterns
- Pitfall focus: shared metatables, recursion in `__index`, module loading order

## Project

| Project | Description | Skills |
|---------|-------------|--------|
| Prototype-Based Entity Model | A prototype-based entity system inspired by game engine architectures. | Metatable-based dispatch with `__index` and `__newindex`; Prototype inheritance (no classes, just delegation); Read-only overlays for entity state protection |

## Prerequisites

- Completion of the previous stage
- The chapters listed above

## How to Run

```bash
cd entity-model
lua 02-entity-model.lua
```

Change into the project directory, then run the command above.
