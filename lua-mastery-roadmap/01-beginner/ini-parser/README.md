# INI Parser

**Stage**: 1 (Beginner)
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

A practical INI file parser that demonstrates string manipulation and table construction. This project builds foundational skills in pattern matching, data extraction, and nested table assembly — core techniques for any Lua developer working with configuration files or text processing.

## What It Teaches

- String pattern matching with `gmatch` and `gsub`
- Building nested tables from parsed data
- Handling whitespace, comments, and section headers
- Returning structured data from raw text input

## Prerequisites

- Chapter 01: Basics (string concatenation, variables)
- Chapter 02: Control Flow (if/elseif, loops)
- Chapter 03: Functions (return values, local scope)

## How to Run

```bash
lua ini-parser.lua
```

Expects an `example.ini` file in the same directory. Modify the script to use a different input path if needed.

## Key Concepts

- `string.gmatch` — iterates over pattern matches in a string
- `string.gsub` — performs global substitution
- Lua patterns vs regex — `%w+`, `%s*`, `[^%[]+` syntax
- Table construction — building hierarchical structures from flat input

## Suggested Improvements

1. Add error handling for malformed sections
2. Support quoted values and escape sequences
3. Implement `__tostring` metamethod for pretty-printing
4. Add unit tests for edge cases (empty lines, duplicate keys)
5. Extend to support `.properties` format (key=value without sections)

## Files

```
ini-parser/
├── README.md          ← This file
├── ini-parser.lua     ← Main implementation
└── example.ini        ← Sample input file
```
