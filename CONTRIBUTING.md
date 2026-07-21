# Contributing to LuaPath

Thank you for investing time in improving `LuaPath`. This document outlines how to contribute effectively.

## Quick Links

- [Project Philosophy](README.md#philosophy)
- [Repository Layout](README.md#repository-layout)
- [Supported Versions](README.md#supported-versions)
- [Quality Expectations](README.md#quality-expectations-for-contributions)

## Code of Conduct

This project operates under a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## What We're Looking For

### High Priority

- **Technical corrections**: Factual errors, version inaccuracies, incorrect behavior descriptions
- **Version-specific clarifications**: Differences between 5.1, 5.3, 5.4, LuaJIT
- **Better diagnostics**: Edge cases, failure modes, common pitfalls
- **Production case studies**: Real-world usage patterns and lessons learned

### Welcome Contributions

- Additional code examples with clear explanations
- Improved error messages and debugging guidance
- Performance optimization notes with benchmarks
- Cross-references between related topics
- Translations (maintain EN/ZH structure parity)

### Not a Fit

- Simplifications that remove technical depth
- Opinions without mechanism explanation
- Version-specific features without compatibility notes
- Unrunnable or untested code snippets

## Contribution Workflow

### 1. Open an Issue

Before submitting a PR, open an issue describing:

- **Scope**: Which chapters/files are affected
- **Lua versions**: Which versions your changes apply to
- **Type**: Correction, enhancement, new content, bug fix
- **Impact**: Who benefits and why

This allows maintainers to provide guidance and avoid duplicate work.

### 2. Fork and Branch

```bash
git clone https://github.com/yourusername/LuaPath.git
cd LuaPath
git checkout -b descriptive-branch-name
```

Branch naming convention:
- `fix/` for corrections (e.g., `fix/table-length-edge-case`)
- `feat/` for new content (e.g., `feat/debugging-chapter`)
- `docs/` for documentation improvements (e.g., `docs/improve-examples`)

### 3. Make Changes

**Content guidelines:**

- Maintain EN/ZH structural parity for learner-facing files
- Keep technical terms consistent (see [Terminology](#terminology))
- Include version notes where behavior differs
- All example code must be runnable and include a `-- Lua Version:` header
- Prefer examples that expose failure modes

**EN/ZH parity policy:**

- Files under `en/` and `zh/` are mirrored tracks; new learner-facing files should land in both tracks in the same PR.
- When full translation is not ready, keep section structure and exercise coverage aligned and open a follow-up issue immediately.
- Do not add English-only exercise or solution files without the matching Chinese artifact.

**Code example format:**

```lua
-- Example: Safe table iteration with nil handling
-- Lua: 5.1+
-- See: 04-tables.md

local function safe_iter(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]  -- May return nil to signal end
  end
end
```

### 4. Validate Locally

Run the validation script before committing:

```bash
make validate      # Check all code snippets
make parity        # Check EN/ZH mirrored structure
make check-links   # Validate internal links
make lint          # Run style checks
make test-examples # Test example code
```

### 5. Submit Pull Request

PR requirements:

- **Title**: Clear and specific (e.g., "Fix table length behavior in 04-tables.md")
- **Description**: 
  - What changed and why
  - Which Lua versions affected
  - Related issue numbers
- **Checklist**:
  - [ ] EN/ZH parity maintained
  - [ ] Code examples tested
  - [ ] Example files include `-- Lua Version:` metadata
  - [ ] Version notes included where needed
  - [ ] No breaking changes to existing content

### 6. Review Process

- Maintainers review within 3-5 days
- Address feedback in the same branch
- Once approved, PR is merged
- Changes appear in next release

## Terminology Consistency

Use these standard terms across EN/ZH content:

| English | 简体中文 | Notes |
|---------|----------|-------|
| metatable | 元表 | |
| metatable dispatch | 元表分派 | |
| upvalue | 上值 | |
| closure | 闭包 | |
| coroutine | 协程 | |
| userdata | 用户数据 | |
| light userdata | 轻量用户数据 | |
| full userdata | 完整用户数据 | |
| garbage collection | 垃圾回收 | |
| incremental GC | 增量 GC | |
| generational GC | 分代 GC | |
| trace (LuaJIT) | 追踪 | |
| FFI | FFI | Keep as acronym |
| JIT compiler | JIT 编译器 | |

## Version Tagging

Mark code examples and behavior notes with version applicability:

```markdown
> **Version Note (5.3+)**: Integer division `//` operator introduced.

> **Version Note (5.1)**: Uses `setfenv`/`getfenv` instead of `_ENV`.

> **LuaJIT**: FFI available without separate library import.
```

## Quality Checklist

Before submitting, verify:

- [ ] No filler content—every paragraph has signal
- [ ] Claims about behavior are accurate and version-aware
- [ ] Code examples are runnable and tested
- [ ] Example files include correct `-- Lua Version:` headers
- [ ] Trade-offs are stated explicitly
- [ ] Failure modes are documented
- [ ] Cross-references to related chapters included
- [ ] EN/ZH structure matches and mirrored learner files exist in both tracks

## Recognition

Contributors are acknowledged in:

- [CONTRIBUTORS.md](CONTRIBUTORS.md)
- Release notes for significant contributions
- GitHub contributor graph

## Questions?

Open a discussion thread or tag maintainers in issues. We're happy to help you contribute effectively.

---

**By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).**
