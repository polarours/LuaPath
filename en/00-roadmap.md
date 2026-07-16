# 00 — Roadmap

## Learning Phases

### Phase A: Core Language Literacy (1–2 weeks)
- Files: `01` to `04`
- Goal: write correct Lua without accidental dynamic-language traps
- Output project: text-based rules engine

### Phase B: Meta Layer and Architecture (1–2 weeks)
- Files: `05` to `07`
- Goal: design reusable abstractions and robust failure boundaries
- Output project: plugin-capable config/runtime framework

### Phase C: Concurrency and Runtime Surfaces (1 week)
- Files: `08` to `09`
- Goal: structure cooperative scheduling and standard library usage
- Output project: event loop with coroutine tasks

### Phase D: Internals and Native Integration (2–3 weeks)
- Files: `10` to `11`
- Goal: reason about VM behavior and embed Lua safely in host applications
- Output project: C host embedding Lua with bound native APIs

### Phase E: Performance and Production Design (1–2 weeks)
- Files: `12` to `14`
- Goal: optimize, model systems, and deploy Lua in real products
- Output project: ECS-like simulation sandbox with profiling notes

## Concept Dependency Graph

```text
syntax -> values -> tables -> functions
                      |         |
                      v         v
                 metatables <- modules
                      |         |
                      v         v
                error model -> coroutines -> stdlib
                      |             |
                      v             v
                 VM internals -> C API -> perf -> production patterns
```

## Estimated Time by Stage

| Stage | Focus | Estimate |
|---|---|---|
| A | Language base | 20–30 hours |
| B | Abstraction + safety | 20–25 hours |
| C | Coroutine architecture | 10–15 hours |
| D | VM + C API | 30–40 hours |
| E | Performance + production | 20–30 hours |

## Suggested Projects per Stage

- Stage A: mini INI parser + validator
- Stage B: prototype-based entity model with read-only overlays
- Stage C: cooperative task scheduler with timeouts
- Stage D: embed Lua into C app and expose host logger + metrics
- Stage E: optimize a hot path and document before/after behavior

## Common Misconceptions

1. “Lua is slow.”
   - Wrong abstraction. Lua can be fast when allocation and table-shape churn are controlled.
2. “Tables are dictionaries only.”
   - They are hybrid array/hash structures with important performance implications.
3. “Metatables are OOP syntax.”
   - They are dispatch hooks; OOP is only one usage.
4. “Coroutines are OS threads.”
   - They are cooperative and explicit; no preemptive scheduling.
5. “C API is just push/pop.”
   - It is a strict stack protocol with lifetime hazards.

## When to Move to LuaJIT

Move when:

- Hot loops dominate runtime and trace-friendly patterns exist.
- You need FFI-heavy native calls with low overhead.
- Platform constraints permit LuaJIT deployment.

Do not move yet when:

- You still rely on 5.3/5.4-only language semantics.
- You have unstable control flow that breaks tracing.
- You have no benchmark baseline in plain Lua.

## When to Embed Lua

Embed Lua when your host system needs:

- User-extensible behavior without recompiling host code
- Sandboxed scripts with controlled API surface
- Fast iteration for gameplay logic, policy rules, or automation

Avoid embedding if static host code already satisfies change rates and safety requirements with lower complexity.