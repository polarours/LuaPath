# Deployment Patterns
**Stage:** 28 — Advanced

## Description
Learn production Lua deployment patterns including sandboxing, resource limits, script hot-reload, and version compatibility. Build infrastructure for running Lua safely in production environments.

## Prerequisites
- Stages 1–27 completed
- Understanding of Lua load() and environment tables
- Familiarity with metatables and module systems

## How to Run
```bash
lua 01-deployment-patterns.lua
```

## Key Concepts
- Sandboxing with restricted environments
- Resource limits (CPU time, memory, instruction count)
- Script hot-reload with version management
- Version compatibility checking and feature detection
- Safe code loading and execution wrappers

## Files
- `01-deployment-patterns.lua` — Sandboxing, resource limits, hot-reload, and version compatibility
