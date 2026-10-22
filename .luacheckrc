-- luacheck configuration for LuaPath
--
-- The examples deliberately support the whole 5.1 -> 5.4 range plus LuaJIT,
-- so the standard library is the union of those versions rather than any one
-- of them. Version-specific behaviour is gated separately, by the
-- `-- Lua Version:` header and the cross-version CI matrix.

std = "lua51+lua53+lua54+luajit"

max_line_length = 120

-- `self` is an unused argument in the method-table examples by construction:
-- the method table is the point, not the receiver. Luacheck's dedicated
-- `self` option exists exactly for this case.
self = false

-- `host` is the C host API exposed to the embedding example
-- (lua-mastery-roadmap/04-advanced/embed-lua/examples/script.lua).
globals = {
    "host",
}

ignore = {
    -- The constructor idiom: `local self = setmetatable({}, Class)` inside
    -- `function Class:new()` deliberately rebinds the receiver.
    "412/self",
    -- The same rebinding, seen as an unused argument.
    "212/self",
    -- `examples/beginner/10-scope-and-blocks.lua` is a lesson on shadowing:
    -- reusing the name `x` in an inner block is the whole point.
    "421/x",
    -- A callback signature routinely declares a parameter the implementation
    -- does not read -- `dt` for a delta time, `data` for an event payload.
    -- The parameter documents the contract, so it stays.
    "212",
}

-- A value that is created, mutated and then dropped is not a mistake in
-- these examples: it is the mechanism. The memory and weak-reference
-- chapters need real objects to exist (and to be released) for the
-- measurement to mean anything, and the debug chapters declare locals
-- precisely so the debugger can show them.
files["examples/advanced/06-debug-library.lua"] = { ignore = { "211" } }
files["examples/advanced/07-weak-tables.lua"] = { ignore = { "211", "311" } }
files["examples/advanced/08-gc-tuning.lua"] = { ignore = { "241", "311" } }
files["examples/advanced/16-memory-profiling.lua"] = { ignore = { "241" } }
files["examples/advanced/19-debug-helpers.lua"] = { ignore = { "211" } }
files["examples/advanced/26-internals-probe.lua"] = { ignore = { "241", "311" } }
files["examples/advanced/27-security-audit.lua"] = { ignore = { "311" } }
files["examples/beginner/07-type-checking.lua"] = { ignore = { "311" } }
files["examples/beginner/10-scope-and-blocks.lua"] = { ignore = { "311" } }
files["examples/intermediate/02-event-bus.lua"] = { ignore = { "211" } }
files["examples/intermediate/09-coroutine-patterns.lua"] = { ignore = { "211" } }
files["examples/intermediate/14-weak-references.lua"] = { ignore = { "211", "311" } }
files["examples/intermediate/16-weak-references-demo.lua"] = { ignore = { "311" } }
files["examples/intermediate/18-error-recovery.lua"] = { ignore = { "211" } }
files["examples/projects/04-perf-analysis.lua"] = { ignore = { "211", "241" } }

-- Roadmap stages -------------------------------------------------------
--
-- The measurement chapters allocate on purpose: the object has to exist for
-- the collector to have something to collect, and the local has to be
-- released for the collection to be observable. The value is written and
-- never read -- that is the mechanism, not an oversight.
files["lua-mastery-roadmap/05-advanced/perf-analysis/04-perf-analysis.lua"] =
    { ignore = { "211", "241" } }
files["lua-mastery-roadmap/05-advanced/perf-analysis/tests/perf_analysis_test.lua"] =
    { ignore = { "211" } }
files["lua-mastery-roadmap/27-advanced/memory-management/01-memory-management.lua"] =
    { ignore = { "211", "231", "241", "311" } }

-- A class table is a namespace: it is written to (the methods are attached
-- to it) and read through its own fields, never as a value.
files["lua-mastery-roadmap/19-advanced/command-pattern/01-command-pattern.lua"] =
    { ignore = { "241" } }
files["lua-mastery-roadmap/40-capstone/capstone-templates/service-manager/src/logger.lua"] =
    { ignore = { "241" } }

-- The weak-reference demo drops its reference on purpose: that is what lets
-- the weak table drop the entry.
files["lua-mastery-roadmap/20-advanced/observer-pattern/01-observer-pattern.lua"] =
    { ignore = { "311" } }

-- An empty branch with a comment is a readable way to say "nothing to do
-- here, and that is deliberate" -- used for skipping comment lines and for
-- marking a case that is handled later.
files["lua-mastery-roadmap/07-intermediate/config-system/01-config-system.lua"] =
    { ignore = { "542" } }
files["lua-mastery-roadmap/24-advanced/data-pipeline/01-data-pipeline.lua"] =
    { ignore = { "542" } }

-- `not (x > y)` is deliberate: it also holds for NaN, where `x <= y` does
-- not. A test assertion wants the stricter reading.
files["lua-mastery-roadmap/14-advanced/test-framework/01-test-framework.lua"] =
    { ignore = { "581" } }

-- The capstone templates are scaffolds. Their modules declare the whole
-- module graph up front so the learner can see how the pieces fit together.
-- The restart policy, the event bus and the pipeline operators are
-- implemented -- their test suites exercise them for real -- while the
-- runtime, the pipeline driver and the sources and sinks are still TODO
-- stubs for the learner to fill in.
files["lua-mastery-roadmap/40-capstone/capstone-templates/script-runtime/src/runtime.lua"] =
    { ignore = { "211" } }
files["lua-mastery-roadmap/40-capstone/capstone-templates/service-manager/examples/demo-services.lua"] =
    { ignore = { "211" } }
files["lua-mastery-roadmap/40-capstone/capstone-templates/text-data-tool/src/main.lua"] =
    { ignore = { "211" } }
