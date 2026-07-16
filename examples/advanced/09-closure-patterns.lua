-- Example 9: Closure Patterns
-- Chapter: 09-advanced
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: factory functions, memoize, once, debounce, throttle
-- Shows: closure-based state, upvalue lifetime, shared mutable state pitfalls

local M = {}

-- Factory function: creates objects with private state
function M.counter(start)
    local count = start or 0
    return {
        inc = function(n) count = count + (n or 1) return count end,
        dec = function(n) count = count - (n or 1) return count end,
        get = function() return count end,
        reset = function() count = start or 0 return count end,
    }
end

-- Memoize: cache function results
function M.memoize(fn)
    local cache = {}
    return function(...)
        local key = table.concat({...}, "\0")
        if cache[key] == nil then
            cache[key] = fn(...)
        end
        return cache[key]
    end
end

-- Once: run function only once
function M.once(fn)
    local called = false
    local result
    return function(...)
        if not called then
            called = true
            result = fn(...)
        end
        return result
    end
end

-- Debounce: delay execution until pause
function M.debounce(fn, delay_ms)
    local timer_id = nil
    return function(...)
        if timer_id then
            -- cancel previous (simulated with flag)
            timer_id = nil
        end
        local args = {...}
        timer_id = true
        -- In real code, use a timer library
        -- Here we simulate immediate for demo
        local function execute()
            if timer_id then
                timer_id = nil
                return fn(table.unpack(args))
            end
        end
        return execute()
    end
end

-- Throttle: limit execution rate (call count based for demo)
function M.throttle(fn, max_calls)
    local call_count = 0
    max_calls = max_calls or 1
    return function(...)
        call_count = call_count + 1
        if call_count <= max_calls then
            return fn(...)
        end
        return nil, "throttled"
    end
end

-- Stateful iterator via closure
function M.range_iterator(start, stop, step)
    local current = start - step
    step = step or 1
    return function()
        current = current + step
        if (step > 0 and current <= stop) or (step < 0 and current >= stop) then
            return current
        end
        return nil
    end
end

-- Upvalue lifetime demo
function M.make_adder(x)
    -- x is captured by closure, lives as long as the closure
    return function(y) return x + y end
end

-- Shared mutable state pitfall
function M.shared_state_pitfall()
    print("=== Shared Mutable State Pitfall ===")
    local shared = { count = 0 }

    local a = function() shared.count = shared.count + 1 end
    local b = function() shared.count = shared.count + 10 end

    a(); a(); b()
    print(string.format("Shared count (a+a+b): %d (expected 12)", shared.count))
    print("Both closures mutate the same table — order-dependent!")
    print()
end

-- Encapsulated state (safe pattern)
function M.encapsulated_state()
    print("=== Encapsulated State (Safe) ===")
    local function make_counter()
        local count = 0
        return {
            inc = function() count = count + 1 end,
            get = function() return count end,
        }
    end

    local a = make_counter()
    local b = make_counter()
    a.inc(); a.inc(); b.inc()
    print(string.format("A: %d, B: %d (independent)", a.get(), b.get()))
    print()
end

function M.main()
    print("Closure Patterns in Lua")
    print(string.rep("=", 40))
    print()

    -- Counter factory
    print("=== Counter Factory ===")
    local c = M.counter(0)
    c.inc(); c.inc(); c.inc(); c.dec()
    print(string.format("Counter: %d (expected 2)", c.get()))
    c.reset()
    print(string.format("After reset: %d", c.get()))
    print()

    -- Memoize
    print("=== Memoize ===")
    local call_count = 0
    local slow_add = M.memoize(function(a, b)
        call_count = call_count + 1
        return a + b
    end)
    print(slow_add(1, 2))  -- computes
    print(slow_add(1, 2))  -- cached
    print(slow_add(3, 4))  -- computes
    print(string.format("Calls: %d (expected 2)", call_count))
    print()

    -- Once
    print("=== Once ===")
    local init = M.once(function()
        print("  Initialization runs only once")
        return 42
    end)
    local v1 = init()
    local v2 = init()
    print(string.format("Values: %d, %d (same object)", v1, v2))
    print()

    -- Range iterator
    print("=== Range Iterator ===")
    local iter = M.range_iterator(1, 5, 1)
    local vals = {}
    for v in iter do vals[#vals + 1] = v end
    print("1..5: " .. table.concat(vals, ", "))

    local iter2 = M.range_iterator(10, 1, -2)
    vals = {}
    for v in iter2 do vals[#vals + 1] = v end
    print("10..1 by -2: " .. table.concat(vals, ", "))
    print()

    -- Adder upvalue
    print("=== Upvalue Lifetime ===")
    local add5 = M.make_adder(5)
    local add10 = M.make_adder(10)
    print(string.format("add5(3)=%d, add10(3)=%d", add5(3), add10(3)))
    print("Each closure captures its own 'x'")
    print()

    M.shared_state_pitfall()
    M.encapsulated_state()

    -- Throttle demo
    print("=== Throttle ===")
    local count = 0
    local throttled = M.throttle(function() count = count + 1 return count end, 2)
    throttled(); throttled(); throttled(); throttled()
    print(string.format("Throttled calls: %d (max 2 allowed)", count))
    print()
end

M.main()
return M
