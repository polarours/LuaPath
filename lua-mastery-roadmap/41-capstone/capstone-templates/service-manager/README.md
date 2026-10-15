# Multi-Service Process Manager

**Level**: Production (Stages 5–40)
**Time**: 20–30 hours

## Overview

Build a process manager that:
- Starts, stops, and restarts named services
- Health checks every N seconds; auto-restart on failure
- Structured JSON logging to file
- In-memory status dashboard queryable via Lua
- Restart backoff: 1s, 2s, 4s, 8s (max 30s)
- Graceful shutdown on SIGTERM equivalent (via a stop signal)

## Architecture

```
service-manager/
├── src/
│   ├── service.lua       # Service definition (name, command, health_check)
│   ├── manager.lua       # Process lifecycle: start, stop, restart, status
│   ├── health.lua        # Health check scheduler (coroutine-based)
│   ├── restart-policy.lua# Exponential backoff logic
│   ├── logger.lua        # Structured JSON logger
│   └── dashboard.lua     # Query: status, uptime, error counts
├── config/
│   └── services.lua      # Define services to manage
├── examples/
│   └── demo-services.lua
└── tests/
    ├── test_manager.lua
    └── test_restart-policy.lua
```

## Service Definition

```lua
-- config/services.lua
return {
  {
    name       = "web",
    command    = "lua examples/web-server.lua",
    health_url = "http://localhost:8080/health",
    restart    = { max_retries = 5, backoff = "exponential" },
    on_start   = function(id) print("web started") end,
  },
  {
    name       = "cache",
    command    = "lua examples/cache-server.lua",
    health_url = "http://localhost:8081/health",
    restart    = { max_retries = 3, backoff = "linear", interval = 2 },
  }
}
```

## Requirements

- `Service:new(config)` — validate config, store restart policy
- `Manager:start_all()` — start all services, return status table
- `Manager:health_check_all()` — coroutine-based periodic check,
  triggers restart on failure
- `RestartPolicy:next_delay(attempt)` — exponential: min(2^attempt, 30)
- `Logger:info/warn/error(module, msg, extra)` — JSON lines to file
- `Dashboard:status(service_name)` — returns `{running, uptime, restarts, last_error}`

## Running

```bash
lua examples/demo-services.lua
lua tests/test_manager.lua
```
