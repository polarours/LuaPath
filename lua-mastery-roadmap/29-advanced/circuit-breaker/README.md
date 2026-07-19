# Stage 29: Circuit Breaker Pattern

## Title
Circuit Breaker Pattern — Fault Tolerance with Graceful Degradation

## Description
The Circuit Breaker pattern prevents cascading failures by monitoring operations and breaking the circuit when failures exceed a threshold. When the circuit is open, calls are rejected immediately with a fallback. After a timeout, the circuit enters a half-open state to test if the service has recovered.

This pattern is essential for microservices and distributed systems where remote calls can fail, timeout, or become slow.

## Prerequisites
- Lua tables and metatables
- Closures and functions as values
- Basic error handling with `pcall`/`xpcall`
- Understanding of state machines

## How to Run
```bash
lua5.4 01-circuit-breaker.lua
```

## Key Concepts
- **Three states**: Closed (normal), Open (failing), Half-Open (testing recovery)
- **Failure counting**: Track consecutive failures to trip the breaker
- **Timeout**: Duration to wait before attempting recovery
- **Fallback behavior**: Return a default or cached value when circuit is open
- **State transitions**: Closed → Open (on failure threshold), Open → Half-Open (on timeout), Half-Open → Closed (on success) / Open (on failure)
