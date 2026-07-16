-- Example 4: Iterator Patterns
-- Chapter: 04-iterators
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: stateful iterators, coroutine-based generators, iterator composition
-- Shows: range, enumerate, chain, filter iterators

local function main()
    print("=== Iterator Patterns ===\n")

    -- 1. Stateful iterator: range with step
    print("--- Range iterator ---")
    local function range(first, last, step)
        step = step or 1
        local i = first - step
        return function()
            i = i + step
            if (step > 0 and i <= last) or (step < 0 and i >= last) then
                return i
            end
        end
    end

    for v in range(1, 10, 2) do
        io.write(v .. " ")
    end
    print()
    for v in range(10, 1, -3) do
        io.write(v .. " ")
    end
    print("\n")

    -- 2. Coroutine-based generator: fibonacci
    print("--- Fibonacci generator ---")
    local function fibonacci(n)
        return coroutine.wrap(function()
            local a, b = 0, 1
            for _ = 1, n do
                coroutine.yield(a)
                a, b = b, a + b
            end
        end)
    end

    io.write("Fib(10): ")
    for v in fibonacci(10) do
        io.write(v .. " ")
    end
    print("\n")

    -- 3. Enumerate: index + value
    print("--- Enumerate ---")
    local function enumerate(tbl)
        local i = 0
        return function()
            i = i + 1
            if i <= #tbl then
                return i, tbl[i]
            end
        end
    end

    local fruits = { "apple", "banana", "cherry" }
    for idx, val in enumerate(fruits) do
        print(string.format("  %d: %s", idx, val))
    end
    print()

    -- 4. Filter iterator
    print("--- Filter iterator ---")
    local function filter(predicate, iter)
        return function()
            for v in iter do
                if predicate(v) then
                    return v
                end
            end
        end
    end

    local is_even = function(x) return x % 2 == 0 end
    local nums = range(1, 20)
    io.write("Even numbers 1-20: ")
    for v in filter(is_even, nums) do
        io.write(v .. " ")
    end
    print("\n")

    -- 5. Chain iterator: combine multiple iterables
    print("--- Chain iterator ---")
    local function chain(...)
        local iters = { ... }
        local idx = 1
        local current = iters[1]
        return function()
            while idx <= #iters do
                local v = current()
                if v ~= nil then
                    return v
                end
                idx = idx + 1
                current = iters[idx]
            end
        end
    end

    local function from_array(tbl)
        local i = 0
        return function()
            i = i + 1
            return tbl[i]
        end
    end

    local a = from_array({ 1, 2, 3 })
    local b = from_array({ 4, 5, 6 })
    local c = from_array({ 7, 8, 9 })
    io.write("Chained: ")
    for v in chain(a, b, c) do
        io.write(v .. " ")
    end
    print()

    -- 6. Compose: filter + map
    print("\n--- Composed: even squares ---")
    local function map(fn, iter)
        return function()
            local v = iter()
            if v ~= nil then
                return fn(v)
            end
        end
    end

    local squares = map(function(x) return x * x end, filter(is_even, range(1, 10)))
    io.write("Even squares 1-10: ")
    for v in squares do
        io.write(v .. " ")
    end
    print("\n")

    print("=== Done ===")
end

main()
