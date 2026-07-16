# Test Framework

**Stage**: 14 — Advanced

## Description
Create a minimal but functional test framework with describe/it/expect style assertions. Learn how test runners organize suites, how setup/teardown hooks manage state, and how assertion libraries give meaningful failure messages.

## Prerequisites
- Stages 01–13 completed
- Solid understanding of closures, tables, and error handling
- Familiarity with pcall/xpcall

## How to Run
```bash
lua 01-test-framework.lua
```

## Key Concepts
- Test suite organization (describe/it)
- Assertion patterns with rich error messages
- Setup/teardown lifecycle hooks
- Pass/fail counting and reporting
- Nested describe blocks

## Files
| File | Description |
|------|-------------|
| `01-test-framework.lua` | Minimal test runner with describe/it/expect, assertions, setup/teardown |
