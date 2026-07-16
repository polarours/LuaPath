# Plugin System

**Stage**: 15 — Advanced

## Description
Design a plugin loader with discovery, lifecycle hooks, and configuration. Learn how Lua's dynamic require system enables extensible architectures, and how to manage plugin states from loading through shutdown.

## Prerequisites
- Stages 01–14 completed
- Understanding of metatables and module patterns
- Familiarity with file I/O and require

## How to Run
```bash
lua 01-plugin-system.lua
```

## Key Concepts
- Dynamic plugin discovery and loading
- Lifecycle hooks (init, start, stop)
- Configuration injection
- Plugin sandboxing via metatables
- Hot-reload capability

## Files
| File | Description |
|------|-------------|
| `01-plugin-system.lua` | Plugin loader with discovery, lifecycle hooks, configuration |
