# Changelog

All notable changes to `lua-journey` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- New chapters: Debugging Techniques, Testing Strategies, Interoperability Patterns
- Capstone project templates for each learning phase
- Automated code example validation
- Enhanced exercise system with solutions

### In Progress

- Chapter content expansion with more examples and case studies
- Quick reference cards and glossary
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

[Unreleased]: https://github.com/yourusername/lua-journey/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/yourusername/lua-journey/releases/tag/v0.2.0
