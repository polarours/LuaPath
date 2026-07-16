-- Example 8: Garbage Collection Tuning
-- Chapter: 08-advanced
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: collectgarbage modes, GC parameters, memory monitoring
-- Shows: incremental vs generational GC, pause/stepmul tuning, allocation tracking

local M = {}

function M.show_gc_modes()
    print("=== GC Modes (5.5) ===")
    print("stop/start:       control GC execution")
    print("collect:          run full GC cycle")
    print("count:            memory in KBytes")
    print("step:             run GC step, returns true if cycle finished")
    print("incremental:      switch to incremental GC (5.5)")
    print("generational:     switch to generational GC (5.5)")
    print("isrunning:        check if GC is running")
    print()
end

function M.monitor_memory(label)
    local count_kb = collectgarbage("count")
    print(string.format("[%s] Memory: %.2f KB", label, count_kb))
    return count_kb
end

function M.gc_tuning_demo()
    print("=== GC Mode Switching (5.5) ===")

    -- Lua 5.5 uses incremental and generational modes
    -- Incremental: traditional step-based GC
    collectgarbage("incremental")
    local mem1 = collectgarbage("count")
    print(string.format("Incremental mode: %.2f KB", mem1))

    -- Generational: short-lived objects collected more frequently
    local ok, mem2 = pcall(function()
        collectgarbage("generational")
        return collectgarbage("count")
    end)
    if ok then
        print(string.format("Generational mode: %.2f KB", mem2))
    else
        print("Generational mode not available")
    end

    -- Allocate to trigger collection in each mode
    local function allocate_burst(n)
        local t = {}
        for i = 1, n do t[i] = string.rep("z", 50) end
        return collectgarbage("count")
    end

    collectgarbage("collect")
    collectgarbage("incremental")
    local before_inc = collectgarbage("count")
    allocate_burst(3000)
    local after_inc = collectgarbage("count")

    collectgarbage("collect")
    local ok2, before_gen = pcall(function()
        collectgarbage("generational")
        return collectgarbage("count")
    end)
    if ok2 then
        allocate_burst(3000)
        local after_gen = collectgarbage("count")
        print(string.format("Incremental burst: %.2f -> %.2f KB (delta %.2f KB)",
            before_inc, after_inc, after_inc - before_inc))
        print(string.format("Generational burst: %.2f -> %.2f KB (delta %.2f KB)",
            before_gen, after_gen, after_gen - before_gen))
    else
        print(string.format("Incremental burst: %.2f -> %.2f KB (delta %.2f KB)",
            before_inc, after_inc, after_inc - before_inc))
        print("Generational mode comparison skipped")
    end
    print("Generational mode is optimized for short-lived objects.")
    print()
end

function M.allocation_tracking()
    print("=== Allocation Tracking ===")

    collectgarbage("collect")
    local before = collectgarbage("count")

    -- Allocate objects
    local t = {}
    for i = 1, 5000 do
        t[i] = string.rep("x", 100)
    end

    local after = collectgarbage("count")
    print(string.format("Allocated 10K strings: %.2f KB -> %.2f KB (delta: %.2f KB)",
        before, after, after - before))

    -- Free them
    t = nil
    collectgarbage("collect")
    local cleaned = collectgarbage("count")
    print(string.format("After cleanup: %.2f KB", cleaned))
    print()
end

function M.step_vs_collect()
    print("=== Step vs Full Collect ===")
    collectgarbage("collect")
    local before = collectgarbage("count")

    -- Create garbage
    local garbage = {}
    for i = 1, 2000 do
        garbage[i] = { data = string.rep("y", 50) }
    end
    garbage = nil

    local after_create = collectgarbage("count")
    print(string.format("After creating garbage: %.2f KB (was %.2f KB)", after_create, before))

    -- Step-based collection (small steps)
    local steps = 0
    while not collectgarbage("step", 10) do
        steps = steps + 1
        if steps > 10000 then break end  -- safety limit
    end
    local after_steps = collectgarbage("count")
    print(string.format("After %d steps: %.2f KB", steps, after_steps))

    -- Full collect
    collectgarbage("collect")
    local after_full = collectgarbage("count")
    print(string.format("After full collect: %.2f KB", after_full))
    print()
end

function M.weak_table_gc_interaction()
    print("=== GC + Weak Tables ===")
    local weak = setmetatable({}, { __mode = "k" })

    -- Create and register keys
    local keys = {}
    for i = 1, 100 do
        keys[i] = {}
        weak[keys[i]] = true
    end

    local before_gc = 0
    for _ in pairs(weak) do before_gc = before_gc + 1 end
    print(string.format("Before GC: %d weak entries", before_gc))

    -- Release references
    keys = nil
    collectgarbage("collect")

    local after_gc = 0
    for _ in pairs(weak) do after_gc = after_gc + 1 end
    print(string.format("After GC: %d weak entries (freed %d)", after_gc, before_gc - after_gc))
    print()
end

function M.run_finalizer_tracking()
    print("=== Finalizer Tracking ===")
    local finalizer_count = 0
    local tracked = setmetatable({}, { __mode = "v" })

    local mt = {
        __gc = function(self)
            finalizer_count = finalizer_count + 1
        end
    }

    do
        local temp = {}
        setmetatable(temp, mt)
        tracked[temp] = true
    end

    collectgarbage("collect")
    collectgarbage("collect")  -- finalizers may need two cycles
    print(string.format("Finalizers called: %d", finalizer_count))
    print()
end

function M.main()
    print("Lua GC Tuning Examples")
    print(string.rep("=", 40))
    print()

    M.show_gc_modes()
    M.monitor_memory("start")
    M.gc_tuning_demo()
    M.allocation_tracking()
    M.step_vs_collect()
    M.weak_table_gc_interaction()
    M.run_finalizer_tracking()
    M.monitor_memory("end")

    print("=== Best Practices ===")
    print("- Use generational mode for apps with many short-lived objects")
    print("- Use incremental mode for predictable pause times")
    print("- Call collectgarbage('collect') at safe points only")
    print("- Monitor count() to detect memory leaks")
    print("- Use step() for fine-grained GC control in hot loops")
    print()
end

M.main()
return M
