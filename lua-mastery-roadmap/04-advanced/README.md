# Stage 4: Internals and Native Integration

**Stage**: 4 | **Time**: 30–40 hours | **Chapters**: 10–11
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

Understand the VM and embed Lua in host applications. This stage bridges Lua and C — essential for game engines, plugins, and system tools.

- Topics: Lua VM model, memory allocation, C API, userdata, stack discipline
- Pitfall focus: stack overflow, userdata lifetime, GC reference tracking

## Project

| Project | Description | Skills |
|---------|-------------|--------|
| Embedding Lua in C | A complete example of embedding the Lua VM in a C host application. | `lua_State` lifecycle management; Pushing and popping values on the Lua stack; Creating userdata with embedded C data |

## Prerequisites

- Completion of the previous stage
- The chapters listed above

## How to Run

```bash
cd embed-lua
./embed_lua
```

Change into the project directory, then run the command above.
