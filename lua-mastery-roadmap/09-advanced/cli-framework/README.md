# CLI Framework

**Stage**: 9 — Advanced | **Difficulty**: Advanced

## Description

A command-line argument parser handling flags, positional arguments, options with values, automatic help generation, and version output. Teaches string parsing for building developer tools.

## Prerequisites

- Lua 5.1+ or LuaJIT
- Familiarity with command-line interfaces

## How to Run

```bash
lua 01-cli-framework.lua --help
lua 01-cli-framework.lua --name Alice --verbose file.txt
```

## Key Concepts

- Command-line argument parsing
- Automatic help text generation
- Flag vs option distinction
- Subcommand pattern

## Files

- `01-cli-framework.lua` — CLI parser with flags, options, help, and version output
