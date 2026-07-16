# Advanced Exercises

## Concept Reinforcement

1. Inspect bytecode for closure-heavy code; explain upvalue behavior.
2. Tune GC parameters on synthetic burst-allocation workload.
3. Refactor polymorphic table path to reduce metamethod misses.

## Mini Project

Implement a host-embedded Lua runtime:

- C host creates state and sandboxed environment
- Register native APIs (`log`, `clock`, `metrics`)
- Execute untrusted scripts with quotas and error capture

## Debugging Tasks

1. Reproduce C API stack imbalance and fix with strict stack protocol.
2. Diagnose crash from invalid userdata cast.
3. Trace and fix production latency spike caused by GC + allocations.

## Open-Ended Design Questions

1. Where should script/host trust boundary be enforced?
2. How would you version script APIs across years of deployment?
3. What patterns keep LuaJIT and stock Lua behavior aligned enough for testing?
