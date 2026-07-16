# Event System

**Stage**: 13 — Advanced

## Description
Build a publish/subscribe event bus with priority ordering, once-handlers, wildcard topic matching, and error isolation. Learn how decoupled systems communicate through events and how to contain failures in callback chains.

## Prerequisites
- Stages 01–12 completed
- Understanding of closures and error handling (pcall)
- Familiarity with variadic functions

## How to Run
```bash
lua 01-event-system.lua
```

## Key Concepts
- Pub/sub pattern
- Priority-based handler execution
- One-time handlers
- Wildcard topic matching
- Error isolation with pcall

## Files
| File | Description |
|------|-------------|
| `01-event-system.lua` | Event bus with priority, once handlers, wildcards, error isolation |
