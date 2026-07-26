# Lua Mastery Roadmap

A staged learning path from Lua fundamentals to production systems. Each stage builds on the previous, with hands-on projects that reinforce the concepts covered in the core chapters.

## Philosophy

This roadmap treats Lua as a programmable systems component. The goal is not syntax mastery — it is building reliable Lua systems that embed, scale, and perform.

## Stages

### Stage 1: Core Language Literacy
**Time**: 20–30 hours | **Chapters**: 01–04

Build a solid foundation in Lua's core mechanics. Learn how values, tables, functions, and control flow actually behave — including the traps that catch newcomers.

- Topics: types, tables, functions, control flow, string patterns
- Pitfall focus: mutable upvalues, global leaks, string concatenation costs
- Project: [INI Parser](01-beginner/ini-parser/)

### Stage 2: Meta Layer and Architecture
**Time**: 20–25 hours | **Chapters**: 05–07

Master metatables, module design, and error handling. This is where Lua becomes expressive — building abstractions that are both flexible and safe.

- Topics: metatables, metamethods, modules, error/exception patterns
- Pitfall focus: shared metatables, recursion in `__index`, module loading order
- Project: [Prototype-Based Entity Model](02-intermediate/entity-model/)

### Stage 3: Concurrency and Runtime Surfaces
**Time**: 10–15 hours | **Chapters**: 08–09

Structure cooperative scheduling and leverage the standard library effectively. Coroutines are Lua's concurrency primitive — learn to use them properly.

- Topics: coroutines, cooperative multitasking, stdlib (table, string, math, IO)
- Pitfall focus: coroutine GC, non-reentrant resumption, missing `os.exit` in embedded contexts
- Project: [Cooperative Task Scheduler](03-intermediate/task-scheduler/)

### Stage 4: Internals and Native Integration
**Time**: 30–40 hours | **Chapters**: 10–11

Understand the VM and embed Lua in host applications. This stage bridges Lua and C — essential for game engines, plugins, and system tools.

- Topics: Lua VM model, memory allocation, C API, userdata, stack discipline
- Pitfall focus: stack overflow, userdata lifetime, GC reference tracking
- Project: [Embedding Lua in C](04-advanced/embed-lua/)

### Stage 5: Performance and Production Design
**Time**: 20–30 hours | **Chapters**: 12–14

Optimize, measure, and deploy Lua in real systems. Learn profiling techniques, allocation control, and production-grade patterns.

- Topics: profiling, allocation optimization, GC tuning, system modeling, deployment
- Pitfall focus: premature optimization, hidden allocation, JIT trace-breaking patterns
- Project: [Performance Analysis](05-advanced/perf-analysis/)

### Stage 6: JSON Parsing
**Time**: 8–12 hours

Build a JSON parser from scratch using recursive descent. Understand parsing techniques, error recovery, and data serialization.

- Topics: recursive descent parsing, error handling, data serialization
- Project: [JSON Parser](06-intermediate/json-parser/)

### Stage 7: Configuration Systems
**Time**: 8–12 hours

Design robust configuration loading with validation, defaults, and environment-aware overrides.

- Topics: file I/O, validation patterns, environment variables, layered config
- Project: [Config System](07-intermediate/config-system/)

### Stage 8: Template Engines
**Time**: 8–12 hours

Build a simple template engine with variable interpolation, conditionals, and loops. Understand string processing at depth.

- Topics: string patterns, recursive processing, DSL design
- Project: [Template Engine](08-intermediate/template-engine/)

### Stage 9: CLI Frameworks
**Time**: 8–12 hours

Create a command-line argument parser with flags, options, help generation, and version output.

- Topics: argument parsing, help text generation, subcommands, exit codes
- Project: [CLI Framework](09-advanced/cli-framework/)

### Stage 10: Logging Systems
**Time**: 8–12 hours

Build a production-grade logging system with levels, formatters, and multiple outputs.

- Topics: module design, I/O patterns, formatters, log levels
- Project: [Logging System](10-advanced/logging-system/)

### Stage 11: Cache Systems
**Time**: 8–12 hours

Implement LRU caching with TTL support and eviction strategies. Learn data structure design in Lua.

- Topics: LRU eviction, TTL, memory management, callback patterns
- Project: [Cache System](11-advanced/cache-system/)

### Stage 12: State Machines
**Time**: 8–12 hours

Build generic finite state machines with guards, actions, and entry/exit callbacks.

- Topics: state transitions, guards, actions, metatable-based FSM
- Project: [State Machine](12-advanced/state-machine/)

### Stage 13: Event Systems
**Time**: 8–12 hours

Design publish/subscribe systems with priority, once handlers, and wildcard topics.

- Topics: pub/sub, priority queues, error isolation, event filtering
- Project: [Event System](13-advanced/event-system/)

### Stage 14: Test Frameworks
**Time**: 8–12 hours

Create a minimal test runner with assertions, setup/teardown, and structured output.

- Topics: assertion patterns, test organization, output formatting
- Project: [Test Framework](14-advanced/test-framework/)

### Stage 15: Plugin Systems
**Time**: 8–12 hours

Build dynamic plugin loading with lifecycle hooks, discovery, and configuration.

- Topics: dynamic loading, lifecycle management, plugin discovery
- Project: [Plugin System](15-advanced/plugin-system/)

### Stage 16: Rate Limiters
**Time**: 8–12 hours

Implement token bucket and sliding window rate limiting algorithms.

- Topics: token bucket, sliding window, time-based algorithms
- Project: [Rate Limiter](16-advanced/rate-limiter/)

### Stage 17: Schema Validators
**Time**: 8–12 hours

Build data validation against schema definitions with type checking and nested object support.

- Topics: recursive validation, type systems, schema design
- Project: [Schema Validator](17-advanced/schema-validator/)

### Stage 18: Dependency Injection
**Time**: 8–12 hours

Design IoC containers with registration, resolution, and lifecycle management.

- Topics: IoC, service locator, lifecycle management, module composition
- Project: [Dependency Injection](18-advanced/dependency-injection/)

### Stage 19: Command Patterns
**Time**: 8–12 hours

Implement command execution with undo/redo stacks and macro recording.

- Topics: command encapsulation, undo/redo, macro recording, history
- Project: [Command Pattern](19-advanced/command-pattern/)

### Stage 20: Observer Patterns
**Time**: 8–12 hours

Build observable subjects with multiple observers and change notification.

- Topics: observer pattern, weak references, change notification, decoupling
- Project: [Observer Pattern](20-advanced/observer-pattern/)

### Stage 21: Object Pool
**Time**: 8–12 hours

Implement object pooling for efficient reuse of expensive objects in performance-critical systems.

- Topics: object reuse, allocation optimization, pool sizing, lifecycle management
- Project: [Object Pool](21-advanced/object-pool/)

### Stage 22: Pub-Sub System
**Time**: 8–12 hours

Design a publish/subscribe messaging system with topic-based routing and wildcard support.

- Topics: message routing, wildcard subscriptions, decoupled communication
- Project: [Pub-Sub System](22-advanced/pub-sub-system/)

### Stage 23: FSM Advanced
**Time**: 8–12 hours

Build a hierarchical finite state machine with history states and transition guards.

- Topics: hierarchical states, history states, transition guards, entry/exit actions
- Project: [FSM Advanced](23-advanced/fsm-advanced/)

### Stage 24: Data Pipeline
**Time**: 8–12 hours

Build a composable data pipeline with map, filter, reduce, and chaining operators.

- Topics: functional composition, lazy evaluation, transducers, pipeline chaining
- Project: [Data Pipeline](24-advanced/data-pipeline/)

### Stage 25: Concurrency Patterns
**Time**: 8–12 hours

Implement advanced concurrency patterns using Lua coroutines: producer-consumer, fan-out/fan-in, and work stealing.

- Topics: coroutine scheduling, work distribution, synchronization, deadlock avoidance
- Project: [Concurrency Patterns](25-advanced/concurrency-patterns/)

### Stage 26: Code Generation
**Time**: 8–12 hours

Explore metaprogramming techniques in Lua: code generation, DSLs, and runtime code construction.

- Topics: metaprogramming, code generation, DSL design, load/setmetatable
- Project: [Code Generation](26-advanced/code-generation/)

### Stage 27: Memory Management
**Time**: 8–12 hours

Deep dive into Lua's garbage collector, weak references, and memory optimization strategies.

- Topics: GC tuning, weak tables, finalizers, memory profiling, allocation strategies
- Project: [Memory Management](27-advanced/memory-management/)

### Stage 28: Deployment Patterns
**Time**: 8–12 hours

Learn production deployment patterns for Lua: sandboxing, resource limits, and hot reloading.

- Topics: sandboxing, resource limits, hot reload, production hardening, version compatibility
- Project: [Deployment Patterns](28-advanced/deployment-patterns/)

### Stage 29: Circuit Breaker
**Time**: 8–12 hours

Implement the circuit breaker fault tolerance pattern to prevent cascading failures.

- Topics: fault tolerance, state machines, failure counting, fallback strategies
- Project: [Circuit Breaker](29-advanced/circuit-breaker/)

### Stage 30: Active Record
**Time**: 8–12 hours

Build an ORM pattern where objects encapsulate persistence logic.

- Topics: ORM, database abstraction, CRUD operations, validation
- Project: [Active Record](30-advanced/active-record/)

### Stage 31: Balking Pattern
**Time**: 8–12 hours

Implement the balking pattern that skips actions when preconditions aren't met.

- Topics: precondition checking, guard clauses, state validation
- Project: [Balking Pattern](31-advanced/balking/)

### Stage 32: Double Buffer
**Time**: 8–12 hours

Build a double buffer for smooth data transitions between producers and consumers.

- Topics: concurrent data access, smooth transitions, buffer swapping
- Project: [Double Buffer](32-advanced/double-buffer/)

### Stage 33: Lock-Free Queue
**Time**: 8–12 hours

Implement a lock-free queue using compare-and-swap operations.

- Topics: atomic operations, CAS, concurrent data structures, wait-free algorithms
- Project: [Lock-Free Queue](33-advanced/lock-free-queue/)

### Stage 34: Middleware Pipeline
**Time**: 8–12 hours

Build a composable middleware pipeline for request processing.

- Topics: middleware pattern, request/response flow, chaining, error handling
- Project: [Middleware Pipeline](34-advanced/middleware-pipeline/)

### Stage 35: Memory Pool
**Time**: 8–12 hours

Implement a memory pool for fast object allocation and reuse.

- Topics: memory management, object reuse, pool sizing, allocation strategies
- Project: [Memory Pool](35-advanced/memory-pool/)

### Stage 36: Event Sourcing
**Time**: 8–12 hours

Build an event sourcing system with event store, commands, and projections.

- Topics: event sourcing, CQRS, event store, projections, replay
- Project: [Event Sourcing](36-advanced/event-sourcing/)

### Stage 37: Error Patterns
**Time**: 8–12 hours

Implement type-safe error handling patterns including Result types and Expected patterns.

- Topics: Result types, error propagation, monadic operations, structured error codes
- Project: [Error Patterns](37-advanced/error-patterns/)

### Stage 38: Testing Patterns
**Time**: 8–12 hours

Implement testing patterns including mock objects, parameterized tests, and test fixtures.

- Topics: mock objects, test doubles, parameterized testing, test fixtures
- Project: [Testing Patterns](38-advanced/testing-patterns/)

### Stage 40: Modern Patterns
**Time**: 8–12 hours

Implement modern Lua patterns including string formatting, iterator composition, and functional programming.

- Topics: advanced string.format, custom iterators, function composition, fluent APIs
- Project: [Modern Patterns](40-advanced/modern-patterns/)

### Stage 41: Mini HTTP Server (Capstone)
**Time**: 12–16 hours

Build a complete, self-contained HTTP server framework in Lua that combines concepts from all previous stages — modules, metatables, coroutines, error handling, middleware pipelines, and production patterns.

- Topics: HTTP protocol, request/response lifecycle, routing, middleware chains, concurrent connection handling, fluent DSL API
- Project: [Lua HTTP Server](41-capstone/lua-http-server/)

## Time Investment by Stage

| Stage | Focus | Hours |
|-------|-------|-------|
| 1 | Language base | 20–30 |
| 2 | Abstraction + safety | 20–25 |
| 3 | Coroutine architecture | 10–15 |
| 4 | VM + C API | 30–40 |
| 5 | Performance + production | 20–30 |
| 6–10 | Intermediate projects | 40–60 |
| 11–20 | Advanced projects | 80–120 |
| 21–28 | Expert projects | 64–96 |
| 29–36 | Master projects | 64–96 |
| 37–40 | Expert projects | 32–48 |
| 41    | Capstone          | 12–16 |
| **Total** | | **418–660** |

## How to Use This Roadmap

1. Start with Stage 1 and the corresponding chapters
2. Complete exercises before moving to the next stage
3. Build the project at each stage before progressing
4. Review the pitfalls section for each chapter
5. Revisit Stages 4–5 before production embedding

## Lua Version Notes

- **Lua 5.1**: Baseline for LuaJIT compatibility; lacks native integers
- **Lua 5.3**: Introduces integers, bitwise operators, `//` floor division
- **Lua 5.4**: Adds to-be-closed variables, generational GC, weak tuples
- **LuaJIT**: FFI for C interop; trace-friendly patterns preferred

## Related Resources

- [Pitfalls](../pitfalls/) — Common mistakes and how to avoid them
- [Examples](../examples/) — Runnable code organized by topic
- [Glossary](../GLOSSARY.md) — Terminology reference
