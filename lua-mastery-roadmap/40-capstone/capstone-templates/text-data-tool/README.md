# Text Data Tool

**Level**: Beginner (Stages 1–3)
**Time**: 8–10 hours

## Overview

Build a command-line text data processing tool that:
1. Reads a text file
2. Applies a chain of transforms defined in a config table
3. Writes the result to an output file or stdout

## Architecture

```
text-data-tool/
├── src/
│   ├── config.lua        # Load and validate config table
│   ├── transform.lua     # Chain of transform functions
│   └── main.lua          # CLI entry point
├── examples/
│   └── demo-config.lua  # Example config + input data
└── tests/
    └── test_main.lua    # Test suite
```

## Requirements

- `config.lua` exports `load(path)` returning a validated config table
- `transform.lua` exports `apply(lines, transforms)` where `transforms` is a list of `{name, params}`
- Supported transforms: `filter(pattern)`, `trim()`, `upper()`, `replace(old, new)`, `reverse()`
- `main.lua` accepts: `lua main.lua <input> <config.lua> [--output <file>]`
- Use `pcall` for file errors; print structured error messages
- All functions return values (no side effects except I/O)

## Running

```bash
lua src/main.lua examples/sample.txt examples/demo-config.lua
```

## Test Suite

```bash
lua tests/test_main.lua
```
