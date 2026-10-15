# Reactive Data Pipeline

**Level**: Intermediate (Stages 2–4)
**Time**: 12–16 hours

## Overview

Build a reactive data pipeline that:
- Chains operators (map, filter, reduce, window)
- Supports async sources via coroutines
- Implements backpressure (bounded buffer)
- Propagates errors through the pipeline
- Clean module structure

## Architecture

```
reactive-pipeline/
├── src/
│   ├── pipeline.lua    # Core: operator chain + scheduling
│   ├── operators.lua   # Built-in operators
│   ├── source.lua      # Async source (coroutine-based)
│   └── sink.lua        # Output sink (file, callback, bounded queue)
├── examples/
│   └── weather-stream.lua  # Simulated weather data stream
└── tests/
    └── test_pipeline.lua
```

## Requirements

- `Pipeline` object with `:pipe(op1, op2, ..., sink)` method
- Operators: `map(fn)`, `filter(fn)`, `reduce(fn, init)`, `window(n)`
- `Source:create(coro_fn)` — wraps a coroutine that yields values
- `Sink:bounded(max_size)` — drops oldest items when full
- Errors in operators propagate to `pipeline:error_handler`
- Each module is a plain table with `:new()` or module-level functions
- No globals; use `local M = {} ... return M` pattern

## Running

```bash
lua examples/weather-stream.lua
lua tests/test_pipeline.lua
```
