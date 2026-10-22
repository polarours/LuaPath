# Stage 3: Concurrency and Runtime Surfaces

**Stage**: 3 | **Time**: 10–15 hours | **Chapters**: 08–09
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

Structure cooperative scheduling and leverage the standard library effectively. Coroutines are Lua's concurrency primitive — learn to use them properly.

- Topics: coroutines, cooperative multitasking, stdlib (table, string, math, IO)
- Pitfall focus: coroutine GC, non-reentrant resumption, missing `os.exit` in embedded contexts

## Project

| Project | Description | Skills |
|---------|-------------|--------|
| Cooperative Task Scheduler | A cooperative task scheduler built entirely on coroutines. | Coroutine lifecycle: create, yield, resume; Cooperative multitasking (tasks yield control explicitly); Priority scheduling and timeout handling |

## Prerequisites

- Completion of the previous stage
- The chapters listed above

## How to Run

```bash
cd task-scheduler
lua 03-task-scheduler.lua
```

Change into the project directory, then run the command above.
