--[[
  Example: Memory Management
  Chapter: Stage 27 — Advanced
  Difficulty: Advanced
  Lua Version: 5.4
  Demonstrates: GC tuning, weak tables, finalizers, memory profiling, allocation tracking
]]

------------------------------------------------------------
-- 1. GC TUNING
------------------------------------------------------------
local function demo_gc_tuning()
    print("=== GC Tuning ===")
    collectgarbage("collect")
    local beforeMem = collectgarbage("count")
    print(string.format("  Memory before: %.1f KB", beforeMem))

    collectgarbage("collect")

    local t = {}
    for i = 1, 10000 do
        t[i] = string.rep("x", 100)
    end

    local midMem = collectgarbage("count")
    print(string.format("  Memory mid-allocation: %.1f KB", midMem))

    t = nil
    collectgarbage("collect")
    local afterMem = collectgarbage("count")
    print(string.format("  Memory after cleanup: %.1f KB", afterMem))
    print(string.format("  Freed: %.1f KB", midMem - afterMem))
    print()
end

------------------------------------------------------------
-- 2. WEAK TABLES
------------------------------------------------------------
local function demo_weak_tables()
    print("=== Weak Tables ===")
    local weakKeys = setmetatable({}, { __mode = "k" })
    local weakValues = setmetatable({}, { __mode = "v" })
    local ephemeral = setmetatable({}, { __mode = "kv" })

    local keyObj = { id = 1 }
    local valObj = { id = 2 }

    weakKeys[keyObj] = "stored by key"
    weakValues["byWeakVal"] = valObj
    ephemeral[keyObj] = valObj

    print(string.format("  weakKeys[keyObj] = %s", tostring(weakKeys[keyObj])))
    print(string.format("  weakValues.byWeakVal.id = %s", tostring(weakValues.byWeakVal and weakValues.byWeakVal.id)))
    print(string.format("  ephemeral[keyObj].id = %s", tostring(ephemeral[keyObj] and ephemeral[keyObj].id)))

    keyObj = nil
    valObj = nil
    collectgarbage("collect")

    print(string.format("  After GC, weakKeys has entry: %s", tostring(next(weakKeys) ~= nil)))
    print(string.format("  After GC, weakValues has entry: %s", tostring(next(weakValues) ~= nil)))
    print()
end

------------------------------------------------------------
-- 3. FINALIZERS
------------------------------------------------------------
local FinalizerTracker = { count = 0 }

function FinalizerTracker.new(id)
    local obj = { id = id }
    setmetatable(obj, {
        __gc = function(self)
            FinalizerTracker.count = FinalizerTracker.count + 1
            print(string.format("  [finalizer] object %d finalized (total: %d)",
                self.id, FinalizerTracker.count))
        end
    })
    return obj
end

local function demo_finalizers()
    print("=== Finalizers ===")
    FinalizerTracker.count = 0

    local a = FinalizerTracker.new(1)
    local b = FinalizerTracker.new(2)
    local c = FinalizerTracker.new(3)

    a = nil
    b = nil
    c = nil
    collectgarbage("collect")
    collectgarbage("collect")

    print(string.format("  Total finalizations: %d", FinalizerTracker.count))
    print()
end

------------------------------------------------------------
-- 4. MEMORY PROFILING
------------------------------------------------------------
local function profileAllocations(label, fn)
    collectgarbage("collect")
    local before = collectgarbage("count")
    local beforeObjects = collectgarbage("count", "count")
    fn()
    local after = collectgarbage("count")
    local afterObjects = collectgarbage("count", "count")
    print(string.format("  [%s] Memory: %.1f -> %.1f KB (%+.1f KB)",
        label, before, after, after - before))
end

local function demo_memory_profiling()
    print("=== Memory Profiling ===")
    profileAllocations("table creation", function()
        local t = {}
        for i = 1, 1000 do
            t[i] = { value = i, name = "item" .. i }
        end
    end)

    profileAllocations("string concat", function()
        local s = ""
        for i = 1, 1000 do
            s = s .. "x"
        end
    end)

    profileAllocations("string.rep", function()
        local s = string.rep("x", 1000)
    end)

    collectgarbage("collect")
    print(string.format("  Final heap: %.1f KB", collectgarbage("count")))
    print()
end

------------------------------------------------------------
-- 5. ALLOCATION TRACKING
------------------------------------------------------------
local function demo_allocation_tracking()
    print("=== Allocation Tracking ===")
    collectgarbage("collect")
    local snapshots = {}

    local function snapshot(label)
        local kb = collectgarbage("count")
        table.insert(snapshots, { label = label, kb = kb })
    end

    snapshot("start")
    local t = {}
    for i = 1, 500 do
        t[i] = string.rep("a", 200)
        if i == 100 then snapshot("at 100 items") end
        if i == 300 then snapshot("at 300 items") end
    end
    snapshot("all 500 items")
    t = nil
    collectgarbage("collect")
    snapshot("after cleanup")

    for _, s in ipairs(snapshots) do
        print(string.format("  [%s] Heap: %.1f KB", s.label, s.kb))
    end
    print()
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------
local function main()
    print("Memory Management in Lua")
    print("Stage 27 — Advanced")
    print("=" .. string.rep("=", 49))
    print()
    demo_gc_tuning()
    demo_weak_tables()
    demo_finalizers()
    demo_memory_profiling()
    demo_allocation_tracking()
    print("All memory management demos complete.")
end

main()
