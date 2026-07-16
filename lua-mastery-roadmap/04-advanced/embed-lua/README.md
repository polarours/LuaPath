# Embedding Lua in C

**Stage**: 4 (Advanced)
**Lua Versions**: 5.1, 5.3, 5.4

## Overview

A complete example of embedding the Lua VM in a C host application. This project teaches the C API, userdata creation, metatable binding, and proper stack discipline — skills required for building host applications that expose native functionality to Lua scripts.

## What It Teaches

- `lua_State` lifecycle management
- Pushing and popping values on the Lua stack
- Creating userdata with embedded C data
- Binding C functions and metatables to userdata
- Error handling across the Lua-C boundary

## Prerequisites

- Chapter 10: Lua Internals (VM model, memory allocation)
- Chapter 11: Lua C API (stack operations, type checking)

## How to Build

```bash
gcc -o embed_lua embed-lua.c -llua -lm
```

On macOS with Homebrew:
```bash
gcc -o embed_lua embed-lua.c -I/usr/local/include/lua5.4 -L/usr/local/lib -llua -lm
```

## How to Run

```bash
./embed_lua
```

The host application exposes a logger and metrics table to Lua scripts.

## Key Concepts

- `lua_State` — isolated Lua execution environment
- `lua_push*` family — pushing values onto the stack
- `luaL_check*` family — type-checked value extraction
- `lua_newuserdata` — allocate host-managed memory for Lua
- `luaL_setmetatable` — associate a metatable with userdata
- Stack discipline — balancing push/pop across API boundaries

## Suggested Improvements

1. Add thread-safe access with `lua_newthread` and `lua_resume`
2. Implement memory limits with custom allocator
3. Add function registration via `luaL_Reg` arrays
4. Create a reusable host library with initialization/cleanup
5. Add error recovery with `lua_pcall` and `lua_atpanic`

## Files

```
embed-lua/
├── README.md        ← This file
├── embed-lua.c      ← C host application
├── script.lua       ← Lua script loaded by the host
└── Makefile         ← Build instructions
```
