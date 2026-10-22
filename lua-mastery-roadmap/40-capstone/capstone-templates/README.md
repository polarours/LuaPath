# Capstone Project Templates

Structured starter projects for each learning phase. Each template includes
skeleton source files, test stubs, and clear requirements to guide learners
from guided starter to full implementation.

## Phases

| Template | Phase | Focus | Time |
|----------|-------|-------|------|
| [Text Data Tool](text-data-tool/) | Beginner (1–3) | File I/O, string patterns, table manipulation, basic error handling | 8–10 h |
| [Reactive Pipeline](reactive-pipeline/) | Intermediate (2–4) | Metatables/OOP, coroutines, module design, backpressure | 12–16 h |
| [Script Runtime](script-runtime/) | Advanced (4–5) | Sandboxing, hot-reload, metaprogramming, error isolation, C API concepts | 16–20 h |
| [Service Manager](service-manager/) | Production (5–40) | Production patterns, health checks, restart policies, structured logging, GC awareness | 20–30 h |

## How to Use

1. **Pick the phase** you're ready for (check prerequisites in each template's README).
2. **Copy the template directory** to your working location:
   ```bash
   cp -r capstone-templates/text-data-tool my-first-tool/
   ```
3. **Implement the TODOs** in each `src/` file. The test stubs in `tests/` show the expected behavior.
4. **Run the tests**:
   ```bash
   lua tests/test_*.lua
   ```
5. **Run the example** to see a working demo of the finished project.

## What's Included

- **`README.md`** — full requirements and architecture overview
- **`src/*.lua`** — skeleton implementations with `TODO` markers at each step
- **`tests/*.lua`** — test stubs showing expected behavior (expand as you implement)
- **`examples/`** — demo code that runs when the project is complete
- **`config/`** *(where applicable)* — example configuration files

Each template is intentionally incomplete — the `TODO` markers are the exercises.
You fill them in; the tests verify your solution is correct.
