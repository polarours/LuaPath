# Stage 1: Core Language Literacy

**Stage**: 1 | **Time**: 20–30 hours | **Chapters**: 01–04
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

Build a solid foundation in Lua's core mechanics. Learn how values, tables, functions, and control flow actually behave — including the traps that catch newcomers.

- Topics: types, tables, functions, control flow, string patterns
- Pitfall focus: mutable upvalues, global leaks, string concatenation costs

## Project

| Project | Description | Skills |
|---------|-------------|--------|
| INI Parser | A practical INI file parser that demonstrates string manipulation and table construction. | String pattern matching with `gmatch` and `gsub`; Building nested tables from parsed data; Handling whitespace, comments, and section headers |

## Prerequisites

- Completion of the previous stage
- The chapters listed above

## How to Run

```bash
cd ini-parser
lua 01-ini-parser.lua
```

Change into the project directory, then run the command above.
