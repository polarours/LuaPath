# Changelog

All notable changes to `LuaPath` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### In Progress

- Chapter content expansion with more examples and case studies

### Added

- `tests/test-version-facts.lua` (`make test-version-facts`): the quick
  comparison table in `references/VERSION_DIFFERENCES.md` is checked against
  the runtime that is running it. The table is what a reader trusts when
  they ask "what is different between the Lua versions?", so a wrong cell
  is a wrong answer. The CI matrix runs it on 5.1, 5.3, 5.4, 5.5 and
  LuaJIT, which covers five of the six columns
- `scripts/check-capi-names.lua` (`make check-capi-names`): every C API
  function the documentation names has to be in the real API. The check
  carries the surface of the runtimes the project supports, taken from their
  headers, so a chapter that calls `luaL_checkintegerX` is reported rather
  than compiled
- `scripts/check-stdlib-names.lua` (`make check-stdlib-names`): every
  standard library member the documentation names has to exist in at least
  one supported runtime. The check carries the inventory of the five
  runtimes the project supports, so a chapter that calls `os.sleep` or
  `math.clamp` -- functions that are in no Lua at all -- is reported
- `scripts/check-pitfall-examples.lua` (`make check-pitfall-examples`): the
  code samples in the pitfall articles are run, in both language tracks, and
  a sample that does not run is reported with its error. A reader copies a
  pitfall sample and runs it, so a sample that dies on the first line
  teaches a stack trace instead of the lesson. The fragments that are
  deliberately not runnable on their own -- the LuaJIT FFI example and the
  server-side fragments -- are listed with the reason
- `scripts/check-stage-files.lua` (`make check-stage-files`): every file name
  a stage README mentions -- in its "How to Run" command, in its C build
  command, and in its file tree -- has to exist in the project directory. The
  check found four stage READMEs whose run command named a file that was
  renamed long ago, so a reader who copied the command got
  "No such file or directory"
- **Two new mirror gates.** `scripts/check-stage-refs.lua` (`make check-stage-refs`)
  reads the authoritative stage list from the roadmap overview and the chapter
  list from the chapter headings, then checks every `Stage NN` / `Chapter NN`
  reference in both language tracks. The roadmap has 42 stages and 18 chapters
  and both used the same labels, so "Chapter 12 -- State Machines" named a
  chapter while quoting a stage's topic; the checker finds the number whose
  titles the reference actually quotes and rejects the mismatch. It also
  verifies that a stage directory's own heading carries that directory's
  number -- which is how the renumbering drifted apart between the English
  and the Chinese track. `scripts/check-code-mirror.lua`
  (`make check-code-mirror`) compares the code of every mirrored sample:
  comments and prose may be translated, the program may not. It compares the
  block count, the token stream with comments and string contents removed,
  and the arguments of every `require()` call. Both gates run in CI
- Chinese translations for the 18 roadmap stage and project READMEs that were
  placeholders saying "translation pending": stages 1-9 and 19-27, one README
  per stage project
- **Cross-version CI matrix.** The example suite and the roadmap stage suite now
  run on Lua 5.1, 5.3, 5.4 and LuaJIT, so a `-- Lua Version:` header is a
  checked claim rather than a comment. New `make test-lua51`,
  `make test-luajit` (now covering roadmap stages as well as examples) and
  `make ci-matrix` targets
- `--runtime` option for `tests/test-roadmap-stages.lua`, with version gating
  that honours each stage's `-- Lua Version:` header. Files without a header
  are still run, so the header stays optional metadata rather than a
  mandatory one
- Chinese translations for the three reference documents that had none:
  `references/VERSION_DIFFERENCES.zh-CN.md`,
  `references/DIAGRAMS.zh-CN.md` and
  `references/playground-guide.zh-CN.md`. The ASCII diagrams in
  `DIAGRAMS.zh-CN.md` are reproduced byte-identically, since translating the
  labels inside the boxes would break their column alignment
- `scripts/parity.lua` now also covers `references/`: every English
  reference document must have a `.zh-CN.md` twin, with a matching number of
  level-two headings. Previously that asymmetry was invisible to CI, because
  the EN/ZH comparison only looked at `en/` and `zh/`
- `.luacheckrc` and a real `make lint`: the linter now runs over `examples/`,
  `scripts/`, `tests/` **and the whole roadmap** and reports **zero**
  warnings across all 183 Lua files. The config documents the conventions
  the code follows on purpose — the constructor idiom, shadowing as a lesson,
  callback parameters that exist to document a contract, values created only
  to be released again, and class tables used as namespaces. The CI lint job
  is no longer `continue-on-error`
- `make lint` accepts a `LUACHECK=` override, and the Makefile now exposes
  `LINT_PATHS` so the linted scope is one variable
- `scripts/validate.lua` now understands version labels: a block that says it
  needs a newer Lua is skipped when the validator runs on an older one.
  `make validate-51` runs the whole corpus against the Lua 5.1 baseline, and
  the CI validate job is a 5.4/5.1 matrix — so a snippet that quietly needs
  5.2+ no longer passes unnoticed
- `scripts/check-anchors.lua`: verifies that the fragment of an internal link
  resolves to a real heading, using GitHub's slug rules (including full-width
  punctuation for the Chinese track). Wired into `make check-links`
- **Lua 5.5 is now in the CI matrix.** The `gh-actions-lua` action resolves
  an unaliased version to a literal tarball name
  (`https://www.lua.org/ftp/lua-<version>.tar.gz`), so the patch version has
  to be spelled out — `5.5` would ask for a tarball that does not exist,
  and the versions the action *does* alias (`5.4` -> `5.4.4`) pin an older
  patch release. The matrix now names 5.5.1, 5.4.9, 5.3.6, 5.1.5 and
  LuaJIT explicitly, and both runners accept a 5.5 runtime
- `scripts/parity.lua` now also covers the pitfall articles: every English
  article needs a Chinese counterpart with the same section structure
- `scripts/parity.lua` now compares the *shape* of the two chapter tracks, not
  just which files exist. A subsection that exists only in the English track
  is content the Chinese reader never sees, and nothing else in the build
  noticed. The check found four chapters that had drifted apart — `zh/15` was
  missing "Advanced Patterns", `zh/16` "Popular Lua Libraries", `zh/17` four
  subsections of "Advanced Embedding Patterns", and `zh/debugging-guide` three
  whole sections; all are now filled in
- The CI `build-c` job now also builds the capstone C stack host
  (`examples/projects/05-c-stack-host/host.c`) with `-Wall -Wextra`, so the
  C side of that example gets real build coverage instead of skipping when
  no compiler is on the runner
- `scripts/check-example-chapters.lua` also checks example numbering:
  every example must carry an `-- Example N:` header, and the numbers must
  be unique and contiguous
- `GLOSSARY.zh-CN.md`: the Chinese glossary, with every link pointing at the
  Chinese chapters
- `examples/advanced/26-internals-probe.lua` (Ex. 58),
  `examples/advanced/27-security-audit.lua` (Ex. 59),
  `examples/intermediate/19-test-runner.lua` (Ex. 31),
  `examples/intermediate/20-interop-boundary.lua` (Ex. 32) and
  `examples/projects/05-c-stack-host/05-c-stack-host.lua` (Ex. 64) — each
  linked from its own chapter in both EN and ZH
- `make check-chapters` CI gate (`scripts/check-example-chapters.lua`) validating
  three invariants: every example's `-- Chapter:` header names a real chapter,
  every example is linked from its own chapter in both EN and ZH, and every
  `examples/*.lua` path a chapter mentions exists on disk
- `examples/beginner/12-control-flow-patterns.lua` (Ex. 12): all four loop
  forms, the three custom-iterator forms, and the chapter's iteration pitfalls
  measured at runtime (`#` on a holed table returned 4, `ipairs` stopped at the
  hole while `pairs` saw 3, `pairs` order differed from insertion order) plus
  stable partition, chunked iteration, and retry with backoff — 20 checks,
  passing on Lua 5.4, 5.1 and LuaJIT
- "Example Code" sections for Chapters 15, 16, 17 and the debugging guide
  (EN + ZH), which previously had none
- Case study for Chapter 17 (EN + ZH) backed by
  `examples/advanced/25-sandbox-escape.lua`: four escape attempts run against a
  naive allow-list sandbox (3/4 blocked) vs a hardened one with a `__newindex`
  guard and a `debug` filter (4/4 blocked), verified on Lua 5.4, 5.1, and LuaJIT
- Quick reference cards completed in both languages:
  `references/QUICK_REFERENCE.md` + `references/QUICK_REFERENCE.zh-CN.md`
  (434 lines each)
- Case studies for Chapters 15 and 16 (EN + ZH), each backed by a runnable,
  measured example: `examples/advanced/23-schema-codegen.lua` (codegen vs
  schema-walk validator, 1.62–1.77x on Lua 5.4, 3.10x on LuaJIT) and
  `examples/advanced/24-ecosystem-probe.lua` (dependency probe with a real
  stdlib-only JSON fallback)
- Capstone project templates for each learning phase
  (`lua-mastery-roadmap/40-capstone/capstone-templates/`):
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
- `make validate` and `make validate-51` now compile the code blocks in
  `references/`, `pitfalls/` and the roadmap's stage READMEs, not only the
  chapters in `en/` and `zh/`. The reference sheets and the stage READMEs are
  where a reader copies a snippet from, and the gap was hiding real breakage:
  a `goto` sample that no interpreter could parse, and a stage README that
  called a method which does not exist. `scripts/validate.lua` grew a fix of
  its own: `--all` used to be ignored as soon as a directory was passed, so
  `validate.lua --all references` silently checked only the reference sheets
  and still reported success
- CI/CD pipeline for validation

### Fixed

- **`references/VERSION_DIFFERENCES.md` shipped a `goto` sample that no
  interpreter could parse.** A `return nil` sat in front of the `::found::`
  label, and `return` has to be the last statement of a block, so Lua 5.2 and
  later rejected the chunk with "'end' expected ... near '::'". The label also
  could not see the `for` variable, so the `return i` behind it was a global
  lookup and returned nil. The sample now carries the position out of the loop
  in a local and reaches the label without a `return` in front of it; it was
  checked on 5.3, 5.4, 5.5 and LuaJIT
- **The "writing cross-version code" sample could not run on Lua 5.1.** It put
  the 5.3-only `//` operator inside the very block that promises to work on
  every version, and a 5.1 interpreter rejects the whole chunk at parse time
  even when the branch is never taken. The API difference (`math.type`) is
  now branched on at runtime, and the `//` sample lives in its own
  version-labelled block, which the validator skips on 5.1
- **The quick reference card carried code that does not compile.** The table
  section listed `t.key` and `#t` as statements, which Lua does not accept, and
  the module section put `return M` in front of the usage code, which makes
  everything after it unreachable. Both tracks now show the same compiling code
- **Two stage READMEs showed code that could not run.** The CI/CD stage called
  `TAP()` where the module only offers `TAP.new()`, and reached for a method
  named `:true`; the package manager stage wrote
  `{ "lua-build-system": ">=1.0" }`, which is not a table constructor, and the
  resolver it documents matches versions exactly, so the `">=1.0"` constraint
  it advertised never resolved. Both READMEs, in both tracks, now show code
  that runs against the modules they document
- **The integer overflow sample in Chapter 18 had its labels the wrong way
  round.** The unbounded version was labelled SAFE and the bounded one
  DANGEROUS, which is the opposite of what the runtimes do: on 5.3 and later
  the unbounded multiplication is integer arithmetic and wraps silently, and
  on 5.1 it is a double that quietly loses precision. The `//` in the
  quick reference's `divmod` sample, which is 5.3 syntax, was also replaced
  with `math.floor` so the card stays valid on the 5.1 baseline

  CONTRIBUTING fixes the terms -- metatable is 元表, metamethod is 元方法,
  upvalue is 上值, userdata is 用户数据, coroutine is 协程 -- but the prose
  mixed the English and the Chinese spelling from paragraph to paragraph.
  114 lines across 13 files now use the house terms; the identifiers in the
  code samples are untouched
- **The exercise file called chapter references "Stage ref".** The concept
  exercises pointed at chapters and the four mini projects at roadmap
  stages, all under one label -- the exact confusion the roadmap's own
  Stage/Chapter split exists to remove. The concept labels are now "Chapter
  ref", the project labels stay "Stage ref", and two of the project titles
  were wrong: the cache project is stage 11, which is the cache system and
  not configuration systems, and the test framework project is stage 14,
  which is the test framework and not testing patterns
- **Fifteen code blocks in the chapters could not be compiled.** Nine used
  `...` as a placeholder for a function body, and `...` is not a statement in
  Lua -- it can only be read inside a vararg function -- so copying the block
  failed before the lesson started. The placeholder is now a comment. The
  other six showed two or three files in one block, or a module and its usage
  in one block, and a `return` in the middle of a chunk is a syntax error;
  they are now split into one block per file
- **Three chapter snippets did not work as printed.** The two
  `table.create` snippets in the internals and performance chapters raise on
  Lua 5.1 to 5.4, because `table.create` arrived in 5.5; they now guard the
  call. The `goto` example in the control-flow chapter printed `i` and `j`
  after the loops, where the for variables are already out of scope -- and
  the position has to survive the jump out of both loops anyway. The callable
  table in the patterns chapter returned an object with no `check` method, so
  the chain that followed it died on the first call
- **The event bus in the patterns chapter dropped handlers.** `Bus:emit`
  iterated the handler list directly, and the "once" handler removes itself
  while it runs -- which shifts the array, so `ipairs` skipped the handler
  behind it. Measured: with three handlers registered, the third never ran
  at all. The chapter now collects the handlers before calling them, the way
  `examples/advanced/11-event-system.lua` already did
- **The "Priority Event Bus" in the same chapter redefined `Bus:on`**, so
  the plain version stopped returning an unsubscribe function and `Bus:emit`
  and `Bus:once` broke with it. It is now a self-consistent variant that
  keeps its own list
- **Three claims in the chapters did not survive measurement.** The standard
  library chapter said `table.sort` is locale dependent and may not produce
  ASCII order; Lua compares strings with `strcmp`, so the order is always the
  byte order, on every runtime and every locale. The modules chapter said
  `require` returns one value; on Lua 5.2 and later it returns the module
  *and* the loader data, and only 5.1 and LuaJIT give back a single value.
  The coroutines chapter's "BROKEN" sample was not broken -- `io.read` does
  not yield -- while the error a C boundary really produces, yielding inside
  a `pcall`, only happens on 5.1 and LuaJIT, since 5.4 made `pcall`
  yieldable
- **Two examples in the chapters could not run.** The safe sandbox sample in
  the metaprogramming chapter used a variable the sample above it never
  defined, and the sandbox sample in the production chapter used
  `user_code` without ever defining it. The basics chapter also labelled the
  `_G` strict-mode detection as "Lua 5.2+", though the trick works on 5.1
  too
- **Three chapters called functions that do not exist.** `table.create` was
  labelled "5.3+" in the internals and performance chapters, but Lua added it
  in 5.5 -- on 5.1, 5.3, 5.4 and LuaJIT the snippet that recommends it
  fails. The retry example in the control-flow chapter called `os.sleep`,
  which is in neither Lua nor LuaSocket, and blamed the missing function on
  a missing library. The metatables chapter asked the reader to overload
  `math.clamp`, which no Lua has
- **The glossary said Lua does not optimise tail calls.** It does: a call in
  tail position reuses the stack frame, so tail recursion does not grow the
  stack on any supported runtime. What the entry now says is where the rule
  stops -- `return 1 + f(x)` is not in tail position and does grow it
 It does: a call in
  tail position reuses the stack frame, so tail recursion does not grow the
  stack on any supported runtime. What the entry now says is where the rule
  stops -- `return 1 + f(x)` is not in tail position and does grow it
- **Six stage test files told the reader to run them from the repository
  root.** The other twenty-one already said to run them from the project
  directory, which is where a reader is standing when they open the project
  README
- **The ecosystem chapter's compatibility snippet raised on three of the five
  supported runtimes.** `local bit = require("bit32") or require("bit")` looks
  like a safe way to reach a bitwise library, but `require` *raises* when the
  module is missing instead of returning nil -- so the line died on LuaJIT,
  Lua 5.4 and Lua 5.5. The module is now chosen by version, and the chapter's
  version table gained a Lua 5.5 column. Its `_ENV` cell for LuaJIT said
  "Partial" where the runtime has no `_ENV` at all
- **Four pitfall articles taught a wrong lesson.** The `or`-default
  article offered `value ~= nil and value or default` as the way to keep a
  `false` value -- but that expression ends in `or`, so `false` falls through
  to the default again and the snippet prints `true`, not `false`; the
  truthiness article repeated the same claim and called it correct. The
  shared-prototype article claimed that assigning `p1.hp = 50` also changed
  `p2.hp`; in the prototype pattern an assignment writes the instance's own
  key, and only a table stored on the prototype is shared. The pairs article
  showed two consecutive calls producing different strings; within one run
  they agree -- what varies is the Lua version and any modification of the
  table
- **Four pitfall samples did not run.** The shared-prototype headline
  example never set `__index`, so `rex.bones` was nil and the snippet died
  instead of printing "steak"; its reproduction example called
  `Enemy:new` on a table that had no constructor. The pairs example called
  `serialize(config)` without defining `config`, and the rawlen fix read
  `#t` without defining `t`. The GC article's example allocated about
  100 GB and never finished, so nobody could run the article's own example
- **Three cells of the version comparison table were wrong.** LuaJIT has no
  `//` operator at all -- the table listed one as an extension. LuaJIT 2.1
  *does* have the `goto` statement, which the table said it did not. And
  LuaJIT has neither `_ENV` nor a `__len` dispatch for tables, while the
  table said "Partial" and a check mark. The table also had no Lua 5.5
  column, although the CI matrix runs 5.5.1
- **The version reference taught a fact no Lua version has.** It showed
  `print(type(42)) -- "integer"` for Lua 5.3 and later. `type(42)` is
  "number" on every version; `math.type(42)` is what tells an integer from
  a float
- **The GC timing pitfall described finalizer behaviour that does not
  happen on Lua 5.1.** Its examples use a table with a `__gc` metatable, and
  in Lua 5.1 only userdata is ever finalized -- a table with `__gc` is
  never finalized at all. LuaJIT follows the same rule. The article now
  says which versions run the finalizer and which do not
- **The rawlen pitfall used a function that does not exist on the baseline.**
  `rawlen` was added in Lua 5.2, and on Lua 5.1 and LuaJIT the `__len`
  metamethod is honoured for userdata only, so a table's `#t` is the raw
  length there. The article now carries the version split and a fallback
  that works everywhere
- **The global lookup pitfall overstated the cost.** A global call is about
  a quarter to a half again as expensive as the same call through a local
  on the interpreter, and the difference all but disappears on LuaJIT,
  which hoists the lookup out of the loop. The article now carries the
  measured numbers instead of the word "significantly"
- **The nine stage-level READMEs described a roadmap that no longer exists.**
  They carried "Stage Level: 11-15" style ranges from the old 43-stage
  roadmap, listed projects that belong to other stages, carried empty table
  rows, and told the reader to run `<project-name>.lua`. All nine are now
  generated from the roadmap overview: the stage number, title, time and
  chapters come from there, the project row comes from the project itself,
  and the run command names the real file
- **Five roadmap test files only worked from the repository root.** They
  resolved their own location to set `package.path` and then ignored it,
  loading the implementation through a hard-coded repository-root path; the
  HTTP server suite hard-coded the same path into `package.path`. All of
  them now work from the project directory and from the repository root
- The stage test runners redirect stdin from `/dev/null`, so a stage script
  with an interactive demo cannot block a suite started from a terminal
- The English `lua-http-server` README called `app.use(fn)` where the
  framework defines `function App:use(fn)`, so the example in the README
  would not have worked
- The capstone templates promise three test files and two example plugins
  that were never written. `src/restart-policy.lua`, `src/event-bus.lua` and
  `src/operators.lua` were TODO stubs, and the tests that exist wrapped
  themselves in `pcall` -- so they printed "skipped" and could never fail.
  The three modules are implemented, the four test files resolve their
  modules from their own location, and two of the three suites now exercise
  real code
- **The roadmap's stage numbering had a gap and the Chinese track did not
  follow the renumbering.** The overview listed stages 1-38 and then 40-43,
  skipping 39; the stages are now numbered 1-42 with no gap, and the stage
  directories, the overview headings and the Chinese headings all agree
- **The English and Chinese tracks had drifted apart in code.** The Chinese
  `lua-http-server` README called `require("app")` where the English one and
  the actual layout use `require("src.http.app")`; the Chinese C API chapter
  used `lua_unref`, which is not a Lua C API function, where the English one
  uses `luaL_unref`; and the Chinese `lua-build-system` README dropped the
  cache time-to-live check. The Chinese solutions files still showed the
  older solutions for exercises 1.6, 1.9 and 1.12, and the Chinese pitfall
  articles still showed the older "Reproduction" sections
- **Two bugs in the English beginner solutions.** The "wrong" split example
  read an undeclared global `result`, so it failed for the wrong reason, and
  the stop-word filter stored its stop words in an array while indexing them
  as a set, so the filter never removed anything
- **The English `lua-http-server` README called `app.use(fn)` where the
  framework defines `function App:use(fn)`**, so the example in the README
  would not have worked
- The Chinese track wrote "阶段" (stage) where the reference meant a chapter
  in the prerequisite lists of the error-patterns, modern-patterns and
  SIMD-patterns projects, and the Chinese chapter headings for tables and
  metatables used "Table" and "Metatable" where the glossary fixes the
  terms as "表" and "元表"
- `examples/advanced/02-sandbox-environment.lua` was broken end to end while
  still printing "✓ Sandbox tests completed!". The restricted environment
  was built with `__index = restricted_env` inside the very statement that
  defines `restricted_env` — a local only exists *after* its own statement,
  so the fallback silently evaluated to `nil` and the proxy resolved
  nothing. Every probe in the example failed: the safe math call, the table
  operations, the bounded computation. The fallback is now `sandbox`, the
  `create_sandbox()` call no longer truncates its two return values to one,
  `run_sandboxed` returns what the chunk actually returned instead of the
  pcall wrapper list, and the example now asserts its own expectations
- `examples/advanced/14-coroutine-channels.lua` had an abandoned draft of
  the unbuffered channel: half-written, never called, with a dead local
  left behind. It is now a working rendezvous channel and is part of the
  demo
- `examples/beginner/07-type-checking.lua` advertised "type guards" in its
  header but never called the `is_type` helper it defined. Section 4 now
  demonstrates it, and the error message names the type it actually saw
- `examples/intermediate/03-coroutine-scheduler.lua`: `spawn(fn, ...)`
  documented "arguments to pass to the function" and then dropped them —
  `coroutine.create(fn)` starts the function with no arguments at all. The
  arguments are now handed through
- `examples/advanced/18-security-in-lua.md` stage 28: the `warnings` feature
  probe compiled a string that was never valid syntax, so it reported
  "false" on every runtime; and the `generational_gc` probe tested
  `collectgarbage("isrunning")`, a 5.2 feature, so it reported "true" for
  LuaJIT, which has no generational mode. Both now probe what they claim
- `examples/beginner/11-version-compat.lua` compared versions as strings.
  `"5.10" >= "5.3"` is false, so a future two-digit minor version would be
  reported as older than 5.3. The comparison is numeric now, and the trap
  is demonstrated in the output. (`examples/intermediate/13-version-compat.lua`
  already did it correctly.)
- `examples/advanced/11-event-system.lua` read the undefined global `vim` to
  detect Neovim, on a line 148 columns long. It now looks the name up with
  `rawget(_G, "vim")` and the callback is split up
- `examples/beginner/11-version-compat.lua` read the undefined global
  `bit32` to probe for the library. Now `rawget(_G, "bit32")`
- Four examples defined `function main()` without `local`, leaking a global
  — the exact mistake `pitfalls/en/accidental-globals.md` warns about. The
  other 32 files already used `local function main()`
- `examples/intermediate/05-readonly-table.lua` discarded the error of the
  `pcall` around the *writable* field, so a write that unexpectedly failed
  was reported as nothing at all. Both outcomes are now printed
- `examples/advanced/21-sandbox-demo.lua` dropped the error of its first
  `safe_execute` call
- `scripts/extract-code.lua` used `goto` (Lua 5.2+), so the script could not
  even be parsed by Lua 5.1 — despite its deliberate pure-Lua fallback for
  environments without luafilesystem
- Example numbering was ambiguous: it restarted at 1 in every directory, had
  gaps, and "Example 11" existed three times with `intermediate/15-module-pattern.lua`
  duplicating another file's number. Numbers now run 1..64 across the whole
  tree in difficulty order, and a CI gate keeps them unique and contiguous
- **`scripts/check-links.sh` never checked a single link.** Its extraction
  pattern used `[^\]]` inside a bracket expression, which GNU grep treats as
  the end of the expression, so the pattern matched nothing and every run
  reported "LINK CHECK PASSED" vacuously. The pattern also picked up
  expressions inside code blocks and mis-parsed links whose text contains
  parentheses. With that fixed, **56 real broken links** surfaced — off-by-one
  path depths in the pitfall articles, stage directories that had moved when
  the roadmap was renumbered, and tutorial links relative to the wrong
  directory. All are fixed, and `make check-links` now scans the roadmap, the
  pitfall articles and the reference documents as well
- **The repository taught a bug that does not exist.** Two pitfall articles, a
  chapter section, a chapter FAQ entry, an internals chapter block, a beginner
  exercise and an intermediate debugging task all claimed that closures
  created in a `for` loop capture the same variable and all return the final
  value. Measured on Lua 5.1, 5.4, 5.5 and LuaJIT, the `for` statement has
  given every iteration its own copy of the control variable since Lua 5.1 —
  the shared behaviour is Lua 5.0's, and the Lua 5.1 manual's §2.4.5 spells
  the `local v = var` copy out. The real trap is a variable that lives
  *outside* the loop, and that is what the material now teaches. The two
  near-duplicate pitfall articles are merged into one per language
- `en/exercises/beginner-solutions.md` used its own `Exercise 1..6` numbering,
  disconnected from the exercise file's `1.6 / 1.9 / 3.1` numbering, and two
  of its solutions had no matching exercise at all. The exercise file gained
  the two missing exercises (1.12 String Split, 3.7 Off-by-One Loop Bounds),
  the solutions are keyed to the exercises they answer, and the 1.9 solution
  now builds the `mathutils` module the exercise asks for
- `en/exercises/intermediate-solutions.md` and its Chinese twin are new: the
  intermediate exercise set shipped with **no** reference solutions. It now
  covers all 13 concept exercises, the 4 mini projects, the 6 debugging tasks
  and the 6 design questions, with every code block verified on Lua 5.1,
  5.4 and LuaJIT
- `en/17-embedding-patterns.md`: the "safe" sandbox example used the
  5.2+ four-argument `load` *and* the 5.1-only `setfenv`, so it failed on
  every supported version; and it gave the sandbox environment an
  `__index = _G` fallback, which quietly undid the `os`/`io`/`debug` entries
  the same function had just removed. Both are fixed
- **`en/exercises/intermediate.md`'s "Infinite recursion in `__index`" debugging
  task did not demonstrate the bug it claimed.** `local mt = { __index = mt }`
  assigns the *global* `mt` (nil) — the local is not in scope inside its own
  initialiser — so `t.foo` simply returns `nil` and nothing loops. The
  exercise now uses the form that really recurses
  (`mt.__index = function(t, k) return t[k] end`), and says why the
  one-liner looks equivalent but is not
- `pitfalls/en/string-concat-performance.md` and
  `pitfalls/en/string-concatenation-performance.md` were two articles with the
  same title covering the same mistake; the Chinese track had the same pair.
  The "Related Concepts" section was folded into the article the README
  links to and the duplicate was removed
- The pitfall articles drifted apart between the two languages: four English
  articles were missing the "Reproduction" section their Chinese
  counterparts had, and two Chinese articles were missing the opening
  "The Mistake" and closing "Key Takeaway" sections. All six are aligned
  now, and `make parity` keeps them that way
- `make lint` no longer treats a stylua mismatch as a failure. stylua always
  puts spaces inside table braces, which this code does not, and the option to
  turn that off does not exist; reformatting the tree would be roughly 5500
  lines of pure cosmetics, so the check now reports the difference and
  explains itself instead of blocking
- `en/02-control-flow.md` used the `//` operator without a version note — a
  *syntax* error that stops a 5.1 reader from parsing the file at all
- `en/13-patterns.md`'s currying example also relied on
  `debug.getinfo(fn).nparams`, which is 5.2+
- `en/09-standard-library.md`, `en/04-tables.md` and `en/debugging-guide.md`
  used `table.pack`, `table.unpack` and the `utf8` library without saying so
- `en/15-advanced-metaprogramming.md`: the builder chain was written as
  `config(...)` followed by parenthesised continuations on the next lines,
  which is ambiguous syntax that 5.1 rejects
- 128 lines of trailing whitespace across 20 files
- **67 test helper functions leaked into the global namespace.** Every stage
  test file defined `assert_true`, `assert_eq` and friends as globals, so
  `assert_eq` existed in 25 different files at once and two test files run
  in the same process would silently overwrite each other's helpers. They
  are locals now
- `lua-mastery-roadmap/30-advanced/active-record`: the class defined a
  method called `tostring`, but Lua's `tostring()` looks for the
  `__tostring` metamethod — so the method was dead code and the demo
  printed `table: 0x...` instead of the record. It is `__tostring` now, and
  the metamethod is placed in the instance metatable directly (metamethod
  lookup is a raw get and does not follow the metatable's own `__index`
  chain). The body also called `string.startswith`, which is a Python
  method and does not exist in Lua at all
- `lua-mastery-roadmap/25-advanced/concurrency-patterns`: the section
  promised an "async/await simulation", but `async` and `await` were never
  called — and `await` could not have worked, since it yielded from a plain
  function. Both are implemented now and the demo drives them
- `lua-mastery-roadmap/22-advanced/pub-sub-system`: the "schema defaults"
  section of the config test deleted its temp file before loading it, so
  the schema filled in every value and nothing was asserted. The cleanup
  moved after the section, and the defaults are now actually checked
- `lua-mastery-roadmap/02-intermediate/entity-model`: the test file ended
  with a "read-only proxy check" that printed a note and then incremented
  the pass counter — a test that could not fail, and made the summary read
  "18/17 passed". The overlay is exported now and asserted for real
- `lua-mastery-roadmap/40-capstone/lua-http-server`: `server.lua` parsed
  every request twice (once itself, once again inside `handle_raw`), and
  `app.lua`, `router.lua` and `server.lua` required modules they never used
- `lua-mastery-roadmap/40-capstone/lua-http-server/examples/simple-server.lua`
  required `App` and `Server` twice each
- `lua-mastery-roadmap/40-capstone/lua-http-server/tests/http_server_tests.lua`
  built its `package.path` from the pre-rename directory, and the first
  entry was missing the dot in `?.lua`
- `lua-mastery-roadmap/42-toolchain/ci-cd-integration`: the TAP test
  replaced the global `print` to capture output, and only restored it if
  nothing raised in between. The reporter takes an output sink now
- `lua-mastery-roadmap/06-intermediate/json-parser`: `parse_object` and
  `parse_array` were globals that happened to be assigned before the
  parser ever called them. They are locals with a forward declaration
- `lua-mastery-roadmap/31-advanced/balking`: `Balking.new(opts)` accepted
  an options table that nothing read

- 14 examples declared `-- Lua Version: 5.1+` but failed on Lua 5.1, and 6
  failed on LuaJIT. The causes were `//` and bitwise operators (5.3+ *syntax*,
  which a 5.1 parser rejects even inside a branch that would never run),
  `table.pack`/`table.unpack` (5.2+), the 4-argument
  `load(code, chunkname, mode, env)` (5.2+), `goto` (5.2+),
  `collectgarbage("incremental"|"generational"|"isrunning")` (5.2+), and
  `string.format("%s", <boolean or table>)` (5.1 rejects non-string
  arguments). Every site now probes for the feature or uses a 5.1-compatible
  form
- 5 roadmap stages failed on Lua 5.1 and 2 on LuaJIT, from the same causes:
  `26-advanced/code-generation`, `27-advanced/memory-management`,
  `28-advanced/deployment-patterns`, `39-advanced/modern-patterns`, and the
  `40-capstone` HTTP server's `router.lua`
- `examples/advanced/09-closure-patterns.lua` called a bare `table.unpack`
  inside `debounce()`. The demo never invoked it, so the bug slipped past CI —
  but the code broke for anyone who copied it
- 21 over-strict `-- Lua Version:` declarations (`5.3+`, `5.4`, `5.4+`) on
  stages and examples that in fact run on 5.1. Each now declares the version
  that was actually verified
- `examples/advanced/08-gc-tuning.lua` labelled the incremental and
  generational GC modes as 5.5; they arrived in 5.2. The example now probes
  which modes the running runtime supports instead of assuming, and says so
- `README.md` / `README_zh-CN.md` statistics were stale: 59 → 64 examples,
  42 → 43 roadmap stages, and the layout tree listed a root `exercises/`
  directory that does not exist (the exercises live in `en/exercises/` and
  `zh/exercises/`)
- 26 of 58 examples declared a `-- Chapter:` header that matched no chapter file
  (`07-metatables`, `09-advanced`, `11-data-structures`, …) — leftovers from
  chapter renumbering that broke navigation. All now point at the chapter that
  actually covers the topic; the 3 files under `examples/projects/` also gained
  the `-- Chapter:` line they were missing entirely.
- 42 of the 58 examples were referenced by no chapter at all, so runnable
  material was invisible to readers. Every chapter's "Example Code" section now
  lists its own examples in both EN and ZH (keeping existing cross-references).

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
