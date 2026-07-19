# Stage 34: Middleware Pipeline

## Title
Middleware Pipeline — Chained Request Processing with Composable Handlers

## Description
The middleware pipeline pattern chains processing functions that each handle a part of a request before passing it to the next handler. Each middleware can modify the request/response, short-circuit the pipeline, or add cross-cutting concerns like logging, authentication, and rate limiting. This is the backbone of frameworks like Express.js, Koa, and many API gateways.

This implementation provides a composable, extensible pipeline with before/after hooks, error handling, and the ability to halt the chain.

## Prerequisites
- Lua closures and first-class functions
- Closures chaining and composition
- Metatables for object-like structures
- Error handling with `pcall`/`xpcall`
- Basic understanding of HTTP request/response concepts

## How to Run
```bash
lua5.4 01-middleware-pipeline.lua
```

## Key Concepts
- **Middleware function**: A function with signature `function(req, res, next)` that processes a request
- **Chaining**: Each middleware calls `next()` to pass control to the next handler
- **Short-circuiting**: Middleware can skip remaining handlers by not calling `next()`
- **Error middleware**: Special handlers that catch errors from upstream middleware
- **Composability**: Build complex pipelines from simple, reusable middleware functions
- **Request/response context**: Shared state that flows through the pipeline
- **Before/after hooks**: Pre-processing and post-processing around the core handler
