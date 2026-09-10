# Advanced Stage

**Stage Level**: 16-20
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

This stage focuses on production-grade patterns including embedding Lua in C, advanced metaprogramming, and Lua C API integration.

## Projects

| Project | Description | Skills |
|---------|-------------|--------|
| [Embed Lua](embed-lua/) | Embed Lua in C applications | C API, userdata |
| | | |

## Prerequisites

- Understanding of Lua metatables and the C API
- Familiarity with C programming

## How to Run

```bash
cd <project-name>/
# C projects require compilation:
gcc -o embed_lua 05-embed-lua.c -l:liblua5.5.so -lm -ldl
./embed_lua
```
