-- Example 7: Error Handling Patterns
-- Chapter: 07-errors
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: pcall, xpcall, assert, error propagation, structured errors
-- Shows: result-style vs exception-style, error wrapping with context

local function main()
    print("=== Error Handling Patterns ===\n")

    -- 1. Basic pcall: safe function calls
    print("--- pcall basics ---")
    local ok, result = pcall(function()
        return 42
    end)
    print("Success:", ok, result)

    ok, result = pcall(function()
        error("something went wrong")
    end)
    print("Failure:", ok, result)
    print()

    -- 2. assert: preconditions
    print("--- assert ---")
    local function divide(a, b)
        assert(type(a) == "number", "a must be a number")
        assert(type(b) == "number", "b must be a number")
        assert(b ~= 0, "division by zero")
        return a / b
    end

    local r1 = pcall(divide, 10, 3)
    print("10/3:", r1)

    local r2 = pcall(divide, 10, 0)
    print("10/0:", r2)

    local r3 = pcall(divide, "a", 3)
    print("a/3:", r3)
    print()

    -- 3. xpcall with custom error handler
    print("--- xpcall with handler ---")
    local function error_handler(err)
        return "CAUGHT: " .. tostring(err)
    end

    local ok2, err2 = xpcall(function()
        error({ code = 500, msg = "server error" })
    end, error_handler)
    print("Result:", ok2, err2)
    print()

    -- 4. Structured errors (error objects)
    print("--- Structured errors ---")
    local function parse_config(raw)
        if type(raw) ~= "string" then
            error({ type = "TypeError", field = "config", expected = "string", got = type(raw) })
        end
        if #raw == 0 then
            error({ type = "ValueError", field = "config", message = "empty string" })
        end
        return { raw = raw, len = #raw }
    end

    local test_cases = { 123, "", "valid_config" }
    for _, input in ipairs(test_cases) do
        local ok3, val = pcall(parse_config, input)
        if ok3 then
            print("Parsed:", val.raw)
        else
            print("Error:", val.type, "-", val.message or val.expected)
        end
    end
    print()

    -- 5. Error wrapping with context
    print("--- Error wrapping ---")
    local function read_file(path)
        if path == nil then
            error("path is nil")
        end
        error("file not found: " .. path)
    end

    local function load_config(filepath)
        local ok4, err4 = pcall(read_file, filepath)
        if not ok4 then
            error("load_config failed: " .. tostring(err4))
        end
        return true
    end

    local ok5, err5 = pcall(load_config, "/etc/app.conf")
    print("Wrapped error:", ok5, err5)

    local ok6, err6 = pcall(load_config, nil)
    print("Nil path error:", ok6, err6)

    print("\n=== Done ===")
end

main()
