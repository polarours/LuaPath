# Stage 5: Performance and Production Design

**Stage**: 5 | **Time**: 20–30 hours | **Chapters**: 12–14
**Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

## Overview

Optimize, measure, and deploy Lua in real systems. Learn profiling techniques, allocation control, and production-grade patterns.

- Topics: profiling, allocation optimization, GC tuning, system modeling, deployment
- Pitfall focus: premature optimization, hidden allocation, JIT trace-breaking patterns

## Project

| Project | Description | Skills |
|---------|-------------|--------|
| Performance Analysis | A performance analysis toolkit that demonstrates profiling techniques, allocation optimization, and GC tuning. | Profiling with `os.clock` and `collectgarbage`; String concatenation alternatives (`table.concat` vs `..`); Local vs global variable performance impact |

## Prerequisites

- Completion of the previous stage
- The chapters listed above

## How to Run

```bash
cd perf-analysis
lua 04-perf-analysis.lua
```

Change into the project directory, then run the command above.
