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
lua 01-ini-parser.lua
```

The script embeds a sample INI document, parses it and prints the resulting configuration. Edit the `ini_content` string near the bottom of the script to parse your own input.

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
01-beginner/ini-parser/
├── README.md
├── README.zh-CN.md
├── 01-ini-parser.lua      — Main implementation
└── tests/
    └── ini_parser_test.lua  — Test suite
```
