# Changelog

All notable changes to `LuaPath` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Quick reference cards (en + zh)

### In Progress

- Chapter content expansion with more examples and case studies
- Quick reference cards and glossary

### Added

- Case studies for Chapters 15 and 16 (EN + ZH), each backed by a runnable,
  measured example: `examples/advanced/23-schema-codegen.lua` (codegen vs
  schema-walk validator, 1.62–1.77x on Lua 5.4, 3.10x on LuaJIT) and
  `examples/advanced/24-ecosystem-probe.lua` (dependency probe with a real
  stdlib-only JSON fallback)
- Capstone project templates for each learning phase
  (`lua-mastery-roadmap/41-capstone/capstone-templates/`):
  text-data-tool, reactive-pipeline, script-runtime, service-manager
- `en/testing-strategies.md` / `zh/testing-strategies.md`: Unit testing,
  test doubles (stubs/mocks/spies), integration testing, property-based
  testing, CI integration, and exercises
- `en/interoperability-patterns.md` / `zh/interoperability-patterns.md`:
  Lua/C API fundamentals, registering C functions, calling Lua from C,
  userdata and metatables, memory management, coroutine bridging,
  async patterns, and exercises
- Stage directory READMEs for all 9 roadmap stages (`01-beginner/` …
  `09-advanced/`) — EN + ZH, each with project table and run instructions
- Object Pool full solution in `exercises/advanced.md` (replaces
  4 TODO placeholders in both EN and ZH)
- `README.md` / `README_zh-CN.md`: updated chapter count to 22, added
  entry points for Testing Strategies and Interoperability Patterns
- CI/CD pipeline for validation

---

## [0.2.0] - 2026-03-06

### Added

- Initial project structure with 15 chapters (00-14)
- Bilingual content (English and 简体中文)
- Exercise files for beginner, intermediate, advanced levels
- Learning roadmap with concept dependency graph
- Version-specific guidance for Lua 5.1, 5.3, 5.4, LuaJIT

### Content Highlights

- **Phase A (Core Language)**: Chapters 01-04 covering basics, control flow, functions, tables
- **Phase B (Meta Layer)**: Chapters 05-07 on metatables, modules, error handling
- **Phase C (Concurrency)**: Chapters 08-09 on coroutines and standard library
- **Phase D (Internals)**: Chapters 10-11 on VM internals and C API
- **Phase E (Production)**: Chapters 12-14 on performance, patterns, deployment

---

## Versioning Strategy

### Major Versions (X.0.0)

- Significant structural changes to learning path
- Addition or removal of major content sections
- Breaking changes to project organization

### Minor Versions (0.X.0)

- New chapters or major content additions
- Significant expansions to existing chapters
- New exercise sets or projects

### Patch Versions (0.0.X)

- Corrections and clarifications
- Additional examples within existing chapters
- Bug fixes in code snippets
- Translation improvements

---

## Release Process

1. **Content freeze**: No new content 3 days before release
2. **Validation run**: All code examples tested
3. **Review pass**: Technical accuracy check
4. **Tag release**: Git tag with version number
5. **Publish notes**: Update CHANGELOG and GitHub releases

---

## Contribution to Changelog

When submitting PRs, include a changelog entry suggestion:

```markdown
## [Version] - Date

### Added/Changed/Fixed

- Description of change (affects chapter XX)
```

---

[Unreleased]: https://github.com/yourusername/LuaPath/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/yourusername/LuaPath/releases/tag/v0.2.0
