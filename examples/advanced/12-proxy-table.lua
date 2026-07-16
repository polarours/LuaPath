-- Example 12: Proxy Tables
-- Chapter: 07-metatables
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: read-only proxies, validation proxies, logging proxies
-- Shows: __index/__newindex interception, access control, audit trails

local unpack = unpack or table.unpack

local function main()
    print("=== Proxy Tables ===\n")

    -- 1. Read-only proxy
    print("--- Read-only Proxy ---")

    local function make_readonly(data)
        local proxy = {}
        local mt = {
            __index = data,
            __newindex = function(_, key)
                error("attempt to modify read-only field: " .. tostring(key), 2)
            end,
            __pairs = function() return pairs(data) end,
            __len = function() return #data end,
            __tostring = function()
                local parts = {}
                for k, v in pairs(data) do
                    parts[#parts + 1] = k .. "=" .. tostring(v)
                end
                return "{" .. table.concat(parts, ", ") .. "}"
            end,
        }
        return setmetatable(proxy, mt)
    end

    local config = make_readonly({ host = "localhost", port = 8080 })
    print("host:", config.host)
    print("port:", config.port)
    print("tostring:", tostring(config))
    print("pairs:", (function()
        local items = {}
        for k, v in pairs(config) do items[#items+1] = k end
        return table.concat(items, ", ")
    end)())

    local ok, err = pcall(function() config.host = "other" end)
    print("write attempt:", ok, err)

    -- 2. Validation proxy
    print("\n--- Validation Proxy ---")

    local function make_validated(schema, data)
        local proxy = {}
        local mt = {
            __index = data,
            __newindex = function(_, key, value)
                local rule = schema[key]
                if not rule then
                    error("unknown field: " .. tostring(key), 2)
                end
                if rule.type and type(value) ~= rule.type then
                    error(string.format("field '%s' expected %s, got %s",
                        key, rule.type, type(value)), 2)
                end
                if rule.min and value < rule.min then
                    error(string.format("field '%s' must be >= %s", key, rule.min), 2)
                end
                if rule.max and value > rule.max then
                    error(string.format("field '%s' must be <= %s", key, rule.max), 2)
                end
                rawset(data, key, value)
            end,
        }
        return setmetatable(proxy, mt)
    end

    local person = make_validated(
        { name = { type = "string" }, age = { type = "number", min = 0, max = 150 } },
        { name = "Alice", age = 30 }
    )

    print("name:", person.name, "age:", person.age)

    person.age = 25
    print("after age=25:", person.age)

    local ok2, err2 = pcall(function() person.age = -5 end)
    print("age=-5:", ok2, err2)

    local ok3, err3 = pcall(function() person.name = 123 end)
    print("name=123:", ok3, err3)

    local ok4, err4 = pcall(function() person.unknown = "x" end)
    print("unknown field:", ok4, err4)

    -- 3. Logging proxy
    print("\n--- Logging Proxy ---")

    local function make_logging(data, label)
        local proxy = {}
        local log = {}
        local mt = {
            __index = data,
            __newindex = function(_, key, value)
                local old = data[key]
                rawset(data, key, value)
                log[#log + 1] = string.format("[%s] %s: %s -> %s",
                    label or "log", tostring(key),
                    tostring(old), tostring(value))
            end,
        }
        return setmetatable(proxy, mt), log
    end

    local state = { hp = 100, mana = 50 }
    local game_state, log = make_logging(state, "game")

    game_state.hp = 80
    game_state.mana = 35
    game_state.hp = 60
    game_state.hp = 0

    print("Audit trail:")
    for _, entry in ipairs(log) do
        print("  " .. entry)
    end

    -- 4. Chained proxy (read-only + validation)
    print("\n--- Chained Proxy ---")

    local function make_chained(data, readonly_keys)
        local proxy = {}
        local mt = {
            __index = data,
            __newindex = function(_, key, value)
                if readonly_keys[key] then
                    error("field is read-only: " .. tostring(key), 2)
                end
                rawset(data, key, value)
            end,
        }
        return setmetatable(proxy, mt)
    end

    local user = make_chained(
        { id = 42, name = "Bob", role = "admin" },
        { id = true, role = true }
    )

    print("id:", user.id, "name:", user.name, "role:", user.role)

    user.name = "Robert"
    print("name after change:", user.name)

    local ok5, err5 = pcall(function() user.id = 99 end)
    print("id change:", ok5, err5)

    local ok6, err6 = pcall(function() user.role = "user" end)
    print("role change:", ok6, err6)

    -- 5. Proxy for method interception
    print("\n--- Method Interception ---")

    local function make_intercepted(obj, before, after)
        local proxy = {}
        local mt = {
            __index = function(_, key)
                local val = obj[key]
                if type(val) == "function" then
                    return function(self, ...)
                        before(key, ...)
                        local results = {val(self, ...)}
                        after(key, results)
                        return unpack(results)
                    end
                end
                return val
            end,
        }
        return setmetatable(proxy, mt)
    end

    local logger = { log = {} }
    local intercepted = make_intercepted(
        { greet = function(self, name) return "Hi, " .. name end },
        function(method)
            logger.log[#logger.log+1] = "calling " .. method
        end,
        function(method, results)
            logger.log[#logger.log+1] = method .. " returned " .. tostring(results[1])
        end
    )

    print(intercepted:greet("World"))
    print("Calls:", table.concat(logger.log, " -> "))

    print("\n✓ Proxy table patterns complete!")
end

main()
