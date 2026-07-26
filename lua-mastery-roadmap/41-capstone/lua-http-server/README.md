# Stage 41: Mini HTTP Server

**Level**: Capstone  
**Description**: Build a complete, self-contained HTTP server framework in Lua that combines concepts from all previous stages — modules, metatables, coroutines, error handling, middleware pipelines, and production patterns.

## Prerequisites

- All chapters (00–18)
- Stages 6–40 (pattern projects)
- `en/05-metatables.md`
- `en/07-error-handling.md`
- `en/08-coroutines.md`
- `en/12-performance.md`
- `en/13-patterns.md`
- `en/14-lua-in-production.md`

## Learning Objectives

- Design and implement a modular HTTP server framework
- Parse raw HTTP requests into structured data
- Implement routing with path parameters and method dispatch
- Build a middleware pipeline with request/response interception
- Use coroutines for concurrent connection handling
- Apply metaprogramming for clean DSL-style API
- Structure code as reusable Lua modules

## Architecture

```
lua-http-server/
├── README.md              # This file
├── src/http/
│   ├── request.lua        # HTTP request parser and representation
│   ├── response.lua       # HTTP response builder
│   ├── router.lua         # Method-based and parameterized routing
│   ├── middleware.lua     # Chained middleware pipeline
│   ├── server.lua         # TCP server with coroutine scheduling
│   └── app.lua            # Unified application facade (DSL)
├── examples/
│   └── simple-server.lua  # Working example combining all components
└── tests/
    └── http_server_tests.lua  # Test suite for all components
```

## Key Concepts

| Concept | Where Applied |
|---------|---------------|
| Modules | `src/http/*.lua` — each component is an independent module |
| Metatables | `request.lua`, `response.lua` — table-based objects with methods |
| Coroutines | `server.lua` — async connection handling without external libraries |
| Error Handling | `router.lua`, `middleware.lua` — structured error responses |
| Closures | Middleware pipeline — each middleware closes over handler state |
| Weak Tables | Connection tracking — allow GC of disconnected clients |

## API Overview

The framework uses a fluent, DSL-style API:

```lua
local app = require("src.http.app")

-- Middleware
app.use(function(req, res, next)
    print(req.method, req.path)
    next()
end)

-- Routes
app:get("/", function(req, res)
    return res:text("Hello, LuaPath!")
end)

app:get("/users/:id", function(req, res)
    return res:json({ id = req.params.id })
end)

app:post("/echo", function(req, res)
    return res:json({ body = req.body })
end)

-- Start server
app:run("127.0.0.1", 8080)
```

## Building and Testing

```bash
# Run the example server (simulated, no network I/O)
lua examples/simple-server.lua

# Run test suite
lua tests/http_server_tests.lua
```

## Time Estimate

12–16 hours

## Deliverables

1. **six source modules** covering request parsing, response building, routing, middleware, server, and application
2. **one working example** demonstrating all features together
3. **one test suite** validating each component
