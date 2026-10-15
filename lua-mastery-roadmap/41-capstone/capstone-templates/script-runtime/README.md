# Pluggable Script Runtime

**Level**: Advanced (Stages 4–5)
**Time**: 16–20 hours

## Overview

Build a scripting runtime that:
- Loads plugin scripts from a `plugins/` directory
- Sandboxes each plugin (restricted `_ENV`, limited `os`, no `loadstring`)
- Supports hot-reloading without restarting the host
- Provides a typed plugin API: `on_init()`, `on_tick(dt)`, `on_destroy()`
- Tracks plugin errors and isolates them (one failing plugin doesn't break others)
- Emits events to all plugins

## Architecture

```
script-runtime/
├── src/
│   ├── runtime.lua       # Host loop: tick, dispatch, error isolation
│   ├── sandbox.lua       # Build restricted _ENV per plugin
│   ├── plugin-loader.lua # Scan dir, load modules, track state
│   └── event-bus.lua     # Publish/subscribe with wildcards
├── plugins/
│   └── _template.lua    # Plugin API template (copy for new plugins)
├── examples/
│   └── demo-plugins/
│       ├── counter.lua   # Simple state counter
│       └── event-echo.lua
└── tests/
    └── test_runtime.lua
```

## Plugin API Contract

```lua
-- plugins/my-plugin.lua
local M = {}

function M.on_init(config)
  -- called once at load; receive runtime-provided config table
end

function M.on_tick(dt)
  -- called every frame; dt = seconds since last tick
end

function M.on_destroy()
  -- cleanup; called before hot-reload or runtime shutdown
end

M.name    = "my-plugin"
M.version = "1.0.0"
return M
```

## Requirements

- `Sandbox:build(plugin_table)` — replace `_ENV` with restricted table;
  block: `os.execute`, `io`, `loadstring`, `require` outside allowlist
- `Runtime:load_plugin(path)` — call `M.on_init(config)` in pcall;
  on error, log and skip
- `Runtime:hot_reload(plugin_id)` — call `M.on_destroy()`, re-require, call `M.on_init()`
- `Runtime:tick(dt)` — iterate all live plugins, call `M.on_tick(dt)` in pcall
- `EventBus:emit(topic, payload)` — dispatch to all subscribers;
  support wildcard `topic.*` patterns
- All pcall failures are logged, never propagated

## Running

```bash
lua examples/demo-plugins/counter.lua   # run a single plugin in isolation
lua tests/test_runtime.lua
```
