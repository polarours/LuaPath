# Intermediate Exercises

> **Scope**: Roadmap stages 7–16 — Configuration Systems through Rate Limiters  
> **Phase Focus**: B (Meta Layer), C (Concurrency), E (Production Patterns)  
> **Prerequisites**: Beginner exercises completed, chapters 01–14 read

---

## Concept Reinforcement

### Metatables and Metamethods

1. **Read-only table proxy** — `[Medium]`  
   Implement `readonly(t)` that returns a proxy table. Reads pass through; writes raise an error via `__newindex`.  
   - *Expected*: `local r = readonly({a=1}); print(r.a)` → `1`; `r.a = 2` → error  
   - *Hint*: Use a separate metatable for the proxy with upvalue referencing the original.  
   - *Stage ref*: 05 — Metatables

2. **Arithmetic operator overloading** — `[Medium]`  
   Build a `Vec2` type with `+`, `-`, `*` (scalar), and `__eq` metamethods. Ensure `__tostring` returns `(x, y)` format.  
   - *Expected*: `Vec2.new(1,2) + Vec2.new(3,4)` → `Vec2(4, 6)`  
   - *Hint*: Define `__add`, `__sub`, `__mul`, `__eq`, `__tostring` in a shared metatable.  
   - *Stage ref*: 05 — Metatables

### Module Patterns

3. **Module with private state** — `[Easy]`  
   Create a module using the revealing-module pattern. Export `get()`, `set()`, `reset()` but keep the internal table inaccessible.  
   - *Expected*: External code cannot access the backing store directly; only through API.  
   - *Hint*: Use a local table inside the module closure.  
   - *Stage ref*: 06 — Modules

4. **Circular dependency resolution** — `[Hard]`  
   Two modules `a` and `b` need each other. Refactor them so initialization completes without errors. Implement a lazy-init pattern.  
   - *Expected*: Both modules load successfully; cross-referencing functions work after first call.  
   - *Hint*: Return a table of forward references; resolve on first use.  
   - *Stage ref*: 06 — Modules

### Coroutines and Scheduling

5. **Producer-consumer pipeline** — `[Medium]`  
   Build a pipeline: a producer coroutine yields batches of data; a consumer coroutine processes them. Use `coroutine.resume` to pass values both directions.  
   - *Expected*: Producer yields 10 items; consumer prints each; pipeline completes cleanly.  
   - *Hint*: `resume(co, value)` sends data into the yielded `coroutine.yield(...)` call.  
   - *Stage ref*: 08 — Coroutines

6. **Cooperative round-robin scheduler** — `[Hard]`  
   Implement a scheduler that runs N coroutines in round-robin fashion. Each gets a time slice (yield counts). A coroutine exceeding its slice is preempted and requeued.  
   - *Expected*: 3 coroutines run fairly; output is interleaved, not sequential.  
   - *Hint*: Track remaining quanta per coroutine; yield after decrement.  
   - *Stage ref*: 08 — Coroutines

### Error Handling Patterns

7. **Error accumulator** — `[Easy]`  
   Write `pcall_accumulate(fns)` that takes a list of functions, calls each with `pcall`, and returns `{ok=bool, result=..., error=...}` for each.  
   - *Expected*: Mixed success/failure list; no function crashes the batch.  
   - *Hint*: Loop with `pcall`, collect results in an output table.  
   - *Stage ref*: 07 — Error Handling

8. **Assert-with-context** — `[Medium]`  
   Build `assertf(condition, fmt, ...)` that raises a formatted error including call site. Use `debug.getinfo` to capture source location.  
   - *Expected*: Error message includes file and line number of the failed assertion.  
   - *Hint*: `debug.getinfo(2, "Sl")` returns source and line.  
   - *Stage ref*: 07 — Error Handling

### Iterators and Generators

9. **Sliding window iterator** — `[Medium]`  
   Implement `window(xs, k)` that returns an iterator yielding successive k-sized windows over a list.  
   - *Expected*: `window({1,2,3,4,5}, 3)` yields `{1,2,3}`, `{2,3,4}`, `{3,4,5}`.  
   - *Hint*: Use a numeric for loop with index tracking; each call returns a sub-table.  
   - *Stage ref*: 09 — Standard Library

10. **Stateful generator** — `[Easy]`  
    Build `make_counter(start, step)` returning a function. Each call returns the next value.  
    - *Expected*: `c = make_counter(0, 2); c(); c(); c()` → `0, 2, 4`.  
    - *Hint*: Capture a mutable local in a closure.  
    - *Stage ref*: 03 — Functions

### String Patterns

11. **INI section parser** — `[Medium]`  
    Parse a string with `[section]` headers and `key=value` pairs. Return a nested table `{section = {key = value}}`.  
    - *Expected*: `"[db]\nhost=localhost\nport=5432"` → `{db = {host="localhost", port="5432"}}`  
    - *Hint*: Use `string.match` with `"%[(.+)%]"` for sections, `"^(%w+)%s*=%s*(.+)$"` for pairs.  
    - *Stage ref*: 13 — Patterns

### Table Operations

12. **Deep merge** — `[Medium]`  
    Implement `deep_merge(base, override)` that recursively merges tables. Nested tables in `override` merge into `base`, not replace.  
    - *Expected*: `deep_merge({a=1, b={c=2}}, {b={d=3}})` → `{a=1, b={c=2, d=3}}`  
    - *Hint*: Check `type(v) == "table"` recursively.  
    - *Stage ref*: 04 — Tables

### Functions and Closures

13. **Partial application** — `[Easy]`  
    Implement `partial(fn, ...)` returning a new function with pre-bound leading arguments.  
    - *Expected*: `add = partial(function(a,b) return a+b end, 10); add(5)` → `15`  
    - *Hint*: Capture args in a closure; append new args on call.  
    - *Stage ref*: 03 — Functions

---

## Mini Projects

### Project 1: Cache System with TTL — `[Medium]`

Build a key-value cache that evicts entries after a configurable time-to-live.

**Requirements:** `Cache.new(ttl_seconds)`, `cache:get(key)`, `cache:set(key, value)`, `cache:cleanup()`, `cache:keys()`.  
**Constraints:** Use `os.time()` for timestamps; store `{value=..., created=...}` per entry; no external libraries.  
**Stage ref**: 11 — Configuration Systems

### Project 2: Finite State Machine — `[Medium]`

Implement a generic FSM library.

**Requirements:** `FSM.new(states, initial)`, `fsm:transition(event)`, `fsm:current()`. Raise error on invalid transitions.  
**Test scenario:** States `idle → loading → done | error`; events `start`, `finish`, `fail`, `retry`.  
**Stage ref**: 12 — State Machines

### Project 3: Event System — `[Hard]`

Build a publish-subscribe event bus with wildcard support.

**Requirements:** `EventBus.new()`, `bus:on(pattern, handler)`, `bus:emit(event, ...)`, `bus:off(pattern, handler)`. Wildcard `*` at end: `"user.*"` matches `"user.created"`.  
**Constraints:** Subscription order preserved; no handler leaks on `off`.  
**Stage ref**: 13 — Event Systems

### Project 4: Test Framework Basics — `[Hard]`

Implement a minimal `describe`/`it`/`assert` test runner.

**Requirements:** `describe(name, fn)`, `it(name, fn)`, `assert.eq(a, b)`, `assert.truthy(v)`, `assert.errors(fn)`, `run_all()`.  
**Constraints:** Use `pcall` to isolate failures; track counts; print expected vs actual on failure.  
**Stage ref**: 14 — Testing Patterns

---

## Debugging Tasks

1. **Infinite recursion in `__index`** — `[Medium]`  
   ```lua
   local mt = { __index = mt }
   local t = setmetatable({}, mt)
   print(t.foo)  -- stack overflow
   ```
   - *Question*: Why does this loop? What is the correct pattern?

2. **Coroutine starvation** — `[Medium]`  
   A scheduler runs 3 coroutines, but one monopolizes the CPU by never yielding. Diagnose and propose a fix.  
   - *Question*: How would you detect and penalize a non-yielding coroutine?

3. **Module re-initialization bug** — `[Hard]`  
   A module stores state in a local. After `package.loaded` is cleared and `require` called again, the state resets unexpectedly.  
   - *Question*: What guarantees does `require` provide about single initialization?

4. **Shared metatable mutation** — `[Medium]`  
   Two instances share the same metatable. Mutating one's metatable affects the other. Identify the mistake and fix it.  
   - *Question*: Per-instance vs shared metatables — when to use which?

5. **Closure loop capture** — `[Easy]`  
   ```lua
   local fns = {}
   for i = 1, 5 do
     fns[i] = function() return i end
   end
   print(fns[1](), fns[3]())  -- prints 5, 5 in Lua 5.1
   ```
   - *Question*: Why does Lua 5.1 differ from 5.3/5.4? What is the fix?

6. **In-place sort side effect** — `[Easy]`  
   `table.sort` mutates the input table. A function that sorts a list silently modifies the caller's data.  
   - *Question*: How would you protect the caller's data? What is the performance tradeoff?

---

## Open-Ended Design Questions

1. **Error philosophy**: When should a module return `nil, err` versus raising `error()`? Consider API ergonomism, caller responsibility, and debuggability.

2. **Event bus memory management**: How would you design an event bus API to prevent handler leaks? What mechanisms clean up handlers when subscribers are garbage collected?

3. **Scheduler observability**: What metrics prove a coroutine scheduler is healthy in production? How would you detect starvation, excessive context switching, or unbounded queue growth?

4. **Configuration layering**: Design a system merging defaults, file, environment variables, and CLI flags. What merge semantics apply at each layer? How do you handle type conflicts?

5. **State machine scalability**: At 20+ states and 50+ transitions, the transition table becomes unwieldy. What structural patterns keep it maintainable? Consider hierarchical states and table-driven design.

6. **Test isolation**: How do you ensure Lua tests don't share state through globals or module-level locals? What patterns enforce isolation without a separate Lua state per test?
