# Release Guide

This document describes how `lua-journey` releases are versioned and published.

## Versioning Strategy

We use [Semantic Versioning](https://semver.org/) with the format `MAJOR.MINOR.PATCH`:

- **MAJOR** (X.0.0): Breaking structural changes, major content reorganization
- **MINOR** (0.X.0): New chapters, significant content additions
- **PATCH** (0.0.X): Corrections, clarifications, bug fixes

### Current Status: Pre-Release (0.X.X)

Until version 1.0.0, the project is considered **beta quality**:

- Content structure may change
- Chapters may be rewritten for clarity
- Examples may be updated for accuracy

## Release Schedule

### Regular Releases

- **Minor releases**: Monthly (or when significant content is ready)
- **Patch releases**: As needed for critical corrections

### Milestone Releases

| Version | Target | Scope |
|---------|--------|-------|
| 0.1.0 | Initial | Core chapters 01-14, basic exercises |
| 0.2.0 | Expansion | Enhanced examples, exercise solutions |
| 0.3.0 | Complete | All chapters expanded, capstone projects |
| 1.0.0 | Stable | Content freeze, production-ready |

## Pre-Release Checklist

Before tagging a release:

### Content Validation

- [ ] All code snippets validated (`make validate`)
- [ ] Links checked (`make check-links`)
- [ ] EN/ZH parity verified (chapter count matches)
- [ ] Version notes updated where needed

### Infrastructure

- [ ] CI pipeline passing
- [ ] Examples directory structure created
- [ ] Scripts functional and tested

### Documentation

- [ ] CHANGELOG.md updated
- [ ] CONTRIBUTORS.md updated (if applicable)
- [ ] Release notes drafted

## Release Process

### 1. Content Freeze

3 days before release:

```bash
# Create release branch
git checkout -b release/v0.X.0

# No new content from this point
```

### 2. Final Validation

```bash
# Run all checks
make validate
make lint
make check-links
make test-examples

# Verify CI passes
```

### 3. Update Changelog

Edit `CHANGELOG.md`:

```markdown
## [0.X.0] - YYYY-MM-DD

### Added
- New content or features

### Changed
- Modifications to existing content

### Fixed
- Corrections and bug fixes

### Removed
- Deprecated content
```

### 4. Tag Release

```bash
# Commit release changes
git add .
git commit -m "release: v0.X.0 - [brief description]"

# Tag the release
git tag -a v0.X.0 -m "lua-journey v0.X.0"

# Push to remote
git push origin main
git push origin v0.X.0
```

### 5. Publish Release Notes

Create GitHub release:

1. Go to Releases → Draft a new release
2. Select the tag
3. Copy release notes from CHANGELOG
4. Highlight key additions
5. Publish

## Hotfix Process

For critical errors discovered after release:

### 1. Create Hotfix Branch

```bash
git checkout -b hotfix/v0.X.1 v0.X.0
```

### 2. Fix and Validate

```bash
# Make minimal fix
# Run validation
make validate
```

### 3. Release Patch

```bash
git commit -m "fix: [brief description]"
git tag -a v0.X.1 -m "Hotfix: [description]"
git push origin main
git push origin v0.X.1
```

## Deprecation Policy

When content needs to be deprecated:

1. **Mark as deprecated** in current release
2. **Provide migration guidance** to new approach
3. **Keep deprecated content** for one minor version
4. **Remove in next minor** (not patch)

Example deprecation notice:

> **Deprecated (v0.3.0)**: This pattern is superseded by [new approach]. Will be removed in v0.4.0.

## Version Compatibility

Content in `lua-journey` targets multiple Lua versions:

| Content Type | Target Versions |
|--------------|-----------------|
| Core chapters | 5.1, 5.3, 5.4, LuaJIT |
| Advanced topics | Version-specific notes included |
| C API examples | 5.1+, noted per example |
| LuaJIT content | LuaJIT 2.x |

## Release Notes Template

```markdown
## lua-journey v0.X.0

### Highlights

[Brief overview of what's new]

### New Content

- Chapter XX: [Title] — [description]
- New section in Chapter XX: [description]

### Improvements

- Enhanced examples in Chapter XX
- Clarified [topic] in Chapter XX

### Fixes

- Corrected [error] in Chapter XX
- Fixed broken links

### Contributors

Thanks to [@contributor1], [@contributor2] for their contributions.

### Upgrade Notes

[Anything users should know when updating]
```

## Continuous Deployment

The following are automated via CI:

- **Code validation**: On every push to main
- **Link checking**: On every push
- **Example testing**: On every push
- **Release tagging**: Manual (maintainer only)

## Questions?

Contact maintainers or open an issue for release-related questions.

---

**Maintainers**: Only maintainers can create official releases. If you believe a release is needed, open an issue.

**Last updated**: 2026-03-06
