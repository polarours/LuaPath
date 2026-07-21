# LuaPath

Lua learning roadmap for practitioners who build real systems: tools, engines, firmware scripts, and language runtimes.

[中文版](README_zh-CN.md) | [English](README.md)

## Philosophy

`LuaPath` treats Lua as a programmable systems component, not only a scripting syntax.

Design principles:

- Concept-first, implementation-aware
- Minimal prose, high signal
- Runnable examples, explicit pitfalls
- Version-aware guidance (Lua 5.1, 5.3, 5.4, LuaJIT)

## Quick Stats

| Category | Count |
|----------|-------|
| Documentation | 20 chapters × 2 languages (EN + ZH) |
| Pitfalls | 15 articles × 2 languages (EN + ZH) |
| Examples | 44 runnable examples |
| Glossary | 107 terms (EN + ZH) |
| Roadmap stages | 39 (beginner → advanced) |

## Repository Layout

```
LuaPath/
├── en/                          20 English chapters (00–18)
├── zh/                          20 Chinese chapters (mirrors /en)
├── pitfalls/
│   ├── en/                      15 English gotcha articles
│   └── 中文版/                   15 Chinese gotcha articles
├── lua-mastery-roadmap/
│   ├── 00-overview.md           Staged learning path
│   ├── 01-beginner/             Stage 1 projects
│   ├── 02-intermediate/         Stage 2 projects
│   ├── ...                      Stages 3-35 projects
│   └── 36-advanced/             Stage 36 projects
├── examples/
│   ├── beginner/                10 beginner examples
│   ├── intermediate/            14 intermediate examples
│   ├── advanced/                15 advanced examples
│   └── projects/                5 stage projects (runnable)
├── exercises/                   Graded exercises (beginner → advanced)
├── references/                  Quick reference, version differences, playground guide
├── scripts/                     Validation and testing tools
├── GLOSSARY.md                  107 technical terms
├── CONTRIBUTING.md              Contribution guidelines
└── Makefile                     CI: validate, lint, check-links, parity, test
```

## Start Here

1. Read the [Roadmap Overview](lua-mastery-roadmap/00-overview.md).
2. Pick one chapter from the concept track (`en/` or `zh/`).
3. Read one related pitfall article from `pitfalls/`.
4. Finish by running an example or building a project.

### Suggested Entry Points

- **Tables and scope:**
  [01 — Basics](en/01-basics.md),
  [04 — Tables](en/04-tables.md),
  [Accidental Globals](pitfalls/en/accidental-globals.md),
  [table-length-undefined](pitfalls/en/table-length-undefined.md)

- **Metatables and OOP:**
  [05 — Metatables](en/05-metatables.md),
  [Metamethod Recursion](pitfalls/en/metamethod-recursion.md),
  [Shared Prototype Mutation](pitfalls/en/shared-prototype-mutation.md),
  [entity-model project](lua-mastery-roadmap/02-intermediate/entity-model/)

- **Coroutines and concurrency:**
  [08 — Coroutines](en/08-coroutines.md),
  [Coroutine C Boundary](pitfalls/en/coroutine-c-boundary.md),
  [task-scheduler project](lua-mastery-roadmap/03-intermediate/task-scheduler/)

- **Performance:**
  [12 — Performance](en/12-performance.md),
  [String Concatenation](pitfalls/en/string-concatenation-performance.md),
  [GC Timing](pitfalls/en/gc-timing-assumptions.md),
  [perf-analysis project](lua-mastery-roadmap/05-advanced/perf-analysis/)

## Supported Versions

- Lua 5.1
- Lua 5.3
- Lua 5.4
- LuaJIT

Notes:

- 5.1 differs in environment model (`setfenv`, `getfenv`) and lacks native bitwise operators.
- 5.3 introduces integers + bitwise operators.
- 5.4 introduces to-be-closed variables and generational GC mode.
- LuaJIT: JIT compiler + trace optimizer, FFI for C interop, baseline close to 5.1 with extensions.

## How to Use This Repository

1. Start with `00-roadmap.md` or the [Roadmap Overview](lua-mastery-roadmap/00-overview.md).
2. Study chapters in order.
3. Complete exercises per phase.
4. Build one small project at each milestone.
5. Revisit `10`–`12` before production embedding.
6. Use `pitfalls/` as a review checklist when writing or reviewing code.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

Contributions are welcome for:

- Technical corrections
- Version-specific clarifications
- Better diagnostics and edge-case examples
- Additional production case studies
- New pitfall articles (one gotcha per article)

---

If your goal is only syntax, this repository will feel strict.
If your goal is to ship reliable Lua systems, this repository is the point.
