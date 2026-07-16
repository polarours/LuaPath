# GLOSSARY

Technical terms and concepts used throughout lua-journey.

## A

### Array Part
The portion of a Lua table that stores values at contiguous integer keys (1, 2, 3, ...). Lua optimizes access to this section using array indexing rather than hash lookup. See: [04-tables.md](en/04-tables.md)

### Upvalue (上值)
A variable from an enclosing function's scope that is captured by a nested function (closure). Upvalues allow closures to maintain state across invocations. See: [03-functions.md](en/03-functions.md), [10-lua-internals.md](en/10-lua-internals.md)

## B

### Bytecode
The intermediate representation produced by Lua's compiler. The VM executes bytecode instructions rather than source code directly. See: [10-lua-internals.md](en/10-lua-internals.md)

## C

### Closure (闭包)
A function combined with its upvalues (captured external variables). Closures enable functional programming patterns and stateful functions. See: [03-functions.md](en/03-functions.md)

### Coroutine (协程)
A lightweight thread of execution that can yield control cooperatively. Coroutines enable asynchronous patterns without OS thread overhead. See: [08-coroutines.md](en/08-coroutines.md)

## D

### Dispatch (分派)
The process of determining which function or method to call. In Lua, metatables customize dispatch behavior through metamethods. See: [05-metatables.md](en/05-metatables.md)

## E

### ECS (Entity Component System)
An architectural pattern where entities are IDs, components are data, and systems are logic. Popular in game development for cache-friendly data layout. See: [13-patterns.md](en/13-patterns.md)

### Environment (_ENV)
The table that holds global variables for a chunk. In Lua 5.2+, `_ENV` replaces `setfenv`/`getfenv`. See: [01-basics.md](en/01-basics.md), [06-modules.md](en/06-modules.md)

## F

### FFI (Foreign Function Interface)
LuaJIT feature that allows calling C functions directly without writing C API wrapper code. See: [11-lua-c-api.md](en/11-lua-c-api.md)

### Full Userdata
A Lua object that owns a block of memory. The memory is allocated by Lua and garbage-collected with the userdata. Contrast with light userdata. See: [11-lua-c-api.md](en/11-lua-c-api.md)

## G

### Garbage Collection (垃圾回收)
Automatic memory management that reclaims memory from objects no longer in use. Lua uses incremental mark-and-sweep (and generational in 5.4). See: [10-lua-internals.md](en/10-lua-internals.md), [12-performance.md](en/12-performance.md)

#### Incremental GC
GC that alternates marking and sweeping in small steps to avoid long pauses. Default in Lua 5.1-5.4.

#### Generational GC
GC that collects young objects more frequently than old ones. Available in Lua 5.4+. Better for workloads with many short-lived allocations.

## H

### Hash Part
The portion of a Lua table that stores values at non-sequential or non-integer keys. Uses hash table lookup. See: [04-tables.md](en/04-tables.md)

## J

### JIT Compiler
Just-In-Time compiler that translates bytecode to native machine code at runtime. LuaJIT includes a JIT compiler with trace optimization. See: [12-performance.md](en/12-performance.md)

## L

### Light Userdata
A simple C pointer value stored in Lua. Does not own memory and has no metatable. Contrast with full userdata. See: [11-lua-c-api.md](en/11-lua-c-api.md)

### Local Variable
A variable declared with `local`. Locals are faster than globals because they map to VM registers or upvalues rather than table lookups. See: [01-basics.md](en/01-basics.md)

### LuaJIT
A Just-In-Time compiled implementation of Lua 5.1 with extensions. Offers significant performance improvements but has some behavioral differences from PUC Lua. See: [README.md](README.md)

## M

### Metatable (元表)
A table that defines custom behavior for another table when accessed with certain operations (indexing, arithmetic, etc.). See: [05-metatables.md](en/05-metatables.md)

### Metamethod
A function in a metatable that handles a specific operation. Examples: `__index`, `__newindex`, `__add`, `__call`. See: [05-metatables.md](en/05-metatables.md)

### Module (模块)
A reusable code unit that exports functionality. Lua modules are typically tables returned from `require`d files. See: [06-modules.md](en/06-modules.md)

## O

### Open Upvalue
An upvalue that still references a variable on the stack (the owning function hasn't returned yet). See: [10-lua-internals.md](en/10-lua-internals.md)

### Closed Upvalue
An upvalue whose value has been moved from the stack to a heap-located structure because the owning function returned. See: [10-lua-internals.md](en/10-lua-internals.md)

## P

### Prototype Pattern
An OOP alternative where new objects are created by copying existing objects (prototypes) rather than instantiating classes. Common in Lua. See: [05-metatables.md](en/05-metatables.md), [13-patterns.md](en/13-patterns.md)

### PUC Lua
The reference implementation of Lua from Pontifical Catholic University of Rio de Janeiro. Distinguished from LuaJIT.

## R

### Register-Based VM
Lua's VM architecture where instructions reference virtual registers directly (as opposed to stack-based VMs). See: [10-lua-internals.md](en/10-lua-internals.md)

## S

### Sandboxing
Restricting a Lua script's access to dangerous functions and resources. Essential for running untrusted code. See: [14-lua-in-production.md](en/14-lua-in-production.md)

### Sequence
A table with contiguous integer keys from 1 to n. The length operator `#` is well-defined only for sequences. See: [04-tables.md](en/04-tables.md)

### SoA (Structure of Arrays)
A data layout pattern where each field is stored in a separate array. Improves cache efficiency for iteration. Contrast with AoS (Array of Structures). See: [13-patterns.md](en/13-patterns.md)

## T

### Table
Lua's primary data structure. Implements arrays, maps, objects, and more through a hybrid array/hash design. See: [04-tables.md](en/04-tables.md)

### Trace (LuaJIT)
A hot path of code that LuaJIT's JIT compiler optimizes into native machine code. See: [12-performance.md](en/12-performance.md)

### Truthiness
Lua's rules for boolean evaluation: only `false` and `nil` are falsey; everything else (including `0` and `""`) is truthy. See: [01-basics.md](en/01-basics.md)

## U

### Upvalue
See: Closure

### Userdata
A Lua type for representing opaque C data. Comes in two forms: light userdata (pointers) and full userdata (owned memory). See: [11-lua-c-api.md](en/11-lua-c-api.md)

## V

### VM (Virtual Machine)
The runtime engine that executes Lua bytecode. See: [10-lua-internals.md](en/10-lua-internals.md)

---

## Version-Specific Terms

### setfenv / getfenv (Lua 5.1)
Functions to get/set a function's environment. Replaced by `_ENV` in Lua 5.2+.

### _ENV (Lua 5.2+)
A regular variable that holds the current environment. Replaces `setfenv`/`getfenv`.

### Integer Subtype (Lua 5.3+)
Lua 5.3+ distinguishes integers from floats. Adds bitwise operators and integer division (`//`).

### To-Be-Closed Variables (Lua 5.4+)
Variables marked with `<close>` that are automatically closed when they go out of scope.

---

## F (additional)

### Finalizer
A function called when an object is garbage collected. Implemented via `__gc` metamethod. Use for cleanup, but never rely on deterministic timing. See: [10-lua-internals.md](en/10-lua-internals.md)

### Flyweight Pattern
A pattern that shares common data across many objects to reduce memory usage. See: [13-patterns.md](en/13-patterns.md)

## I (additional)

### Inspector Function
A function that examines and reports on the state of data structures without modifying them. Useful for debugging. See: [debugging-guide.md](en/debugging-guide.md)

## P (additional)

### Proxy Table
A table that intercepts operations via metatables to control access, validate inputs, or log behavior. Common in read-only patterns and validation. See: [05-metatables.md](en/05-metatables.md)

## R (additional)

### RAII (Resource Acquisition Is Initialization)
A pattern where resource lifetime is tied to object scope. Lua 5.4 `<close>` variables implement this. See: [14-lua-in-production.md](en/14-lua-in-production.md)

## Additional Terms

### Accumulator
A variable that collects results during iteration. Common in reduce/fold operations. See: [03-functions.md](en/03-functions.md)

### Adapter Pattern
A pattern that converts one interface to another, allowing incompatible interfaces to work together. See: [13-patterns.md](en/13-patterns.md)

### Assertion
A runtime check that throws an error if a condition is false. Used for precondition validation and debugging. See: [07-error-handling.md](en/07-error-handling.md)

### Backpressure
A mechanism where a slower consumer signals a faster producer to slow down. Implemented via channels or bounded queues in coroutines. See: [08-coroutines.md](en/08-coroutines.md)

### Bitwise Operations
Operations that work on individual bits of integers. Native in Lua 5.3+; available via `bit32` library in 5.1. See: [01-basics.md](en/01-basics.md)

### Builder Pattern
A pattern that constructs complex objects step by step, separating construction from representation. See: [13-patterns.md](en/13-patterns.md)

### Callback
A function passed as an argument to another function, to be invoked later. Fundamental to event-driven and asynchronous programming. See: [03-functions.md](en/03-functions.md)

### Chain of Responsibility
A pattern where a request passes through a chain of handlers, each deciding whether to process it or pass it along. See: [13-patterns.md](en/13-patterns.md)

### Chunk
A piece of Lua code that the compiler translates into bytecode. Can be a file, a string, or a function. See: [10-lua-internals.md](en/10-lua-internals.md)

### Collector
The garbage collector component that reclaims unused memory. Lua uses incremental mark-and-sweep. See: [10-lua-internals.md](en/10-lua-internals.md)

### Command Pattern
A pattern that encapsulates a request as an object, enabling undo/redo, queuing, and logging. See: [13-patterns.md](en/13-patterns.md)

### Continuation
A representation of the rest of a computation. Coroutines provide asymmetric continuations. See: [08-coroutines.md](en/08-coroutines.md)

### Deadlock
A situation where two or more coroutines are waiting for each other, preventing progress. Lua coroutines are cooperative, so deadlocks require explicit yielding. See: [08-coroutines.md](en/08-coroutines.md)

### Decorator Pattern
A pattern that wraps an object to add behavior dynamically without modifying the original. See: [13-patterns.md](en/13-patterns.md)

### Deep Copy
Creating a new table that is a complete independent copy of an original, including nested tables. Contrasts with shallow copy. See: [04-tables.md](en/04-tables.md)

### DSL (Domain-Specific Language)
A mini-language designed for a specific problem domain. Lua's syntax makes it excellent for building DSLs. See: [13-patterns.md](en/13-patterns.md)

### Dustman
A LuaJIT concept for weak reference cleanup. Not standard in PUC Lua. See: [12-performance.md](en/12-performance.md)

### Entity Component System (ECS)
An architectural pattern where entities are IDs, components are data, and systems are logic. Popular in game development. See: [13-patterns.md](en/13-patterns.md)

### Exposure
Making internal functions or data accessible from outside a module. Controlled via table returns and local scoping. See: [06-modules.md](en/06-modules.md)

### Expression
A combination of values, variables, operators, and functions that evaluates to a value. See: [01-basics.md](en/01-basics.md)

### Factory Pattern
A pattern that creates objects without specifying the exact class, delegating instantiation to subclasses or parameters. See: [13-patterns.md](en/13-patterns.md)

### Fiber
A lightweight coroutine-like execution unit. LuaJIT does not have native fibers; coroutines serve this role. See: [08-coroutines.md](en/08-coroutines.md)

### Flatten
Reducing nested tables to a single level. Common in data processing pipelines. See: [04-tables.md](en/04-tables.md)

### Garbage Collection (GC)
Automatic memory management that reclaims memory from objects no longer in use. See: [10-lua-internals.md](en/10-lua-internals.md)

### Generator
A function that produces a sequence of values on demand, typically using coroutines. See: [08-coroutines.md](en/08-coroutines.md)

### Global Environment
The default table where global variables are stored. Named `_G` in Lua 5.1+, `_ENV` in 5.2+. See: [01-basics.md](en/01-basics.md)

### Hash Table
A data structure that maps keys to values using hash functions. Lua tables use hash tables for non-sequential keys. See: [04-tables.md](en/04-tables.md)

### Hot Path
A code section executed frequently, where performance optimizations have the most impact. See: [12-performance.md](en/12-performance.md)

### Identity
The unique reference of a table in memory. Two different tables with the same content have different identities. See: [04-tables.md](en/04-tables.md)

### Immediate vs Deferred
A design choice between processing data eagerly (immediate) or lazily (deferred). Lua typically uses immediate evaluation. See: [03-functions.md](en/03-functions.md)

### Invariant
A condition that must remain true throughout execution. Used in loops and data structure operations. See: [02-control-flow.md](en/02-control-flow.md)

### IoC (Inversion of Control)
A principle where control flow is inverted — the framework calls user code, not the other way around. See: [06-modules.md](en/06-modules.md)

### Iterator
A function that returns successive elements from a collection. Lua uses `pairs` and `ipairs` as built-in iterators. See: [02-control-flow.md](en/02-control-flow.md)

### Lazy Evaluation
Deferring computation until the result is needed. Lua evaluates eagerly, but coroutine-based generators simulate laziness. See: [08-coroutines.md](en/08-coroutines.md)

### Literal
A value written directly in code (e.g., `42`, `"hello"`, `true`). See: [01-basics.md](en/01-basics.md)

### LuaJIT
A JIT-compiled implementation of Lua 5.1 with extensions. Offers FFI for C interop and significant performance gains. See: [12-performance.md](en/12-performance.md)

### Macro
A form of code transformation. Lua does not have C-style macros but uses `string.gsub` and load/eval for similar effects. See: [03-functions.md](en/03-functions.md)

### Memoization
An optimization technique that caches function results to avoid redundant computation. See: [03-functions.md](en/03-functions.md)

### Metamethod
A function in a metatable that defines behavior for specific operations (indexing, arithmetic, etc.). See: [05-metatables.md](en/05-metatables.md)

### Nil
Lua's representation of absence of value. Both `nil` and `false` are falsey; everything else is truthy. See: [01-basics.md](en/01-basics.md)

### Object
In Lua, any table can serve as an object. Objects gain behavior through metatables and methods. See: [05-metatables.md](en/05-metatables.md)

### Operator Overloading
Defining custom behavior for standard operators (+, -, *, etc.) through metamethods. See: [05-metatables.md](en/05-metatables.md)

### Pattern
A template for matching text. Lua patterns use `%d`, `%w`, `.`, `*`, `+`, `-` (not regex). See: [09-standard-library.md](en/09-standard-library.md)

### Pool
A reusable set of objects that avoids repeated allocation/deallocation. See: [12-performance.md](en/12-performance.md)

### Preprocessor
Code that transforms source before execution. Lua's `string.gsub` and `load` can serve as lightweight preprocessors. See: [06-modules.md](en/06-modules.md)

### Priority Queue
A data structure where elements are dequeued by priority, not insertion order. See: [12-performance.md](en/12-performance.md)

### Promise
A placeholder for a future value. Lua does not have native promises; coroutines and callbacks serve similar roles. See: [08-coroutines.md](en/08-coroutines.md)

### Proxy
An intermediary that controls access to another object. Used for logging, validation, and read-only protection. See: [05-metatables.md](en/05-metatables.md)

### Queue
A FIFO (first-in, first-out) data structure. Implemented using tables with head/tail indices. See: [12-performance.md](en/12-performance.md)

### Recursion
A function calling itself. Lua supports recursion but does not optimize tail calls in all cases. See: [03-functions.md](en/03-functions.md)

### Reference Type
A type where assignment copies the reference, not the data. Tables, functions, userdata, and threads are reference types. See: [01-basics.md](en/01-basics.md)

### Reflection
Examining and modifying code structure at runtime. The `debug` library provides Lua reflection capabilities. See: [debugging-guide.md](en/debugging-guide.md)

### Sandboxing
Restricting a script's access to dangerous functions and resources. Essential for running untrusted code. See: [14-lua-in-production.md](en/14-lua-in-production.md)

### Sentinel
A unique value used as a marker to distinguish "no value" from valid values. See: [04-tables.md](en/04-tables.md)

### Stack Trace
A dump of the call stack at a specific point, showing function names and line numbers. Used for debugging. See: [debugging-guide.md](en/debugging-guide.md)

### Tail Call
A function call in tail position that can be optimized to reuse the current stack frame. See: [03-functions.md](en/03-functions.md)

### Thread
In Lua, a coroutine (not an OS thread). Lua coroutines are cooperative and lightweight. See: [08-coroutines.md](en/08-coroutines.md)

### Truthiness
Lua's rules for boolean evaluation: only `false` and `nil` are falsey; `0`, `""`, `{}` are truthy. See: [01-basics.md](en/01-basics.md)

### Type Checking
Verifying that a value matches an expected type. Done via `type()` function or assert patterns. See: [01-basics.md](en/01-basics.md)

### Value Type
A type where assignment copies the value, not a reference. Numbers, booleans, and nil are value types. See: [01-basics.md](en/01-basics.md)

### Variable
A named storage location for values. Can be local (scope-limited) or global (environment-wide). See: [01-basics.md](en/01-basics.md)

### Weak Reference
A reference that does not prevent garbage collection. Implemented via `__mode` in metatables. See: [10-lua-internals.md](en/10-lua-internals.md)

### Yield
Suspending coroutine execution and returning control to the caller. See: [08-coroutines.md](en/08-coroutines.md)

## Cross-References

- **Chapter 01**: Basics, types, variables
- **Chapter 03**: Functions, closures, upvalues
- **Chapter 04**: Tables, arrays, hash parts
- **Chapter 05**: Metatables, metamethods, prototypes
- **Chapter 06**: Modules, environments
- **Chapter 08**: Coroutines, cooperative multitasking
- **Chapter 10**: VM, bytecode, GC internals
- **Chapter 11**: C API, userdata, FFI
- **Chapter 12**: Performance, optimization, JIT
- **Chapter 13**: Design patterns, ECS
- **Chapter 14**: Production, sandboxing, deployment
