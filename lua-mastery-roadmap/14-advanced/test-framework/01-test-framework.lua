--[[
  Example: Test Framework
  Chapter: 14 — Advanced
  Difficulty: Advanced
  Lua Version: 5.3+
  Demonstrates: test runner, describe/it/expect, assertions, setup/teardown, nested suites
]]

local Framework = {}
Framework.__index = Framework
Framework._current = nil
Framework._results = { passed = 0, failed = 0, errors = {} }

function Framework._indent(level)
    return string.rep("  ", level)
end

function Framework.describe(name, fn, level)
    level = level or 0
    print(string.format("%s%s", Framework._indent(level), name))
    local prev = Framework._current
    Framework._current = { setup = nil, teardown = nil, level = level + 1 }
    fn()
    Framework._current = prev
end

function Framework.it(name, fn)
    local indent = Framework._indent(Framework._current and Framework._current.level or 1)
    local ok, err = pcall(function()
        if Framework._current and Framework._current.setup then
            Framework._current.setup()
        end
        fn()
        if Framework._current and Framework._current.teardown then
            Framework._current.teardown()
        end
    end)
    if ok then
        Framework._results.passed = Framework._results.passed + 1
        print(string.format("%s✓ %s", indent, name))
    else
        Framework._results.failed = Framework._results.failed + 1
        table.insert(Framework._results.errors, { name = name, error = err })
        print(string.format("%s✗ %s", indent, name))
        print(string.format("%s  Error: %s", indent, tostring(err)))
    end
end

function Framework.setup(fn)
    if Framework._current then Framework._current.setup = fn end
end

function Framework.teardown(fn)
    if Framework._current then Framework._current.teardown = fn end
end

local Expect = {}
Expect.__index = Expect

function Framework.expect(value)
    return setmetatable({ _value = value, _negated = false }, Expect)
end

function Expect:to_be(expected)
    if self._value ~= expected then
        error(string.format("Expected %s, got %s", tostring(expected), tostring(self._value)))
    end
    return self
end

function Expect:to_not_be(expected)
    if self._value == expected then
        error(string.format("Expected not %s, got %s", tostring(expected), tostring(self._value)))
    end
    return self
end

function Expect:to_be_nil()
    if self._value ~= nil then
        error(string.format("Expected nil, got %s", tostring(self._value)))
    end
    return self
end

function Expect:to_be_type(tp)
    if type(self._value) ~= tp then
        error(string.format("Expected type '%s', got '%s'", tp, type(self._value)))
    end
    return self
end

function Expect:to_be_true()
    if not self._value then
        error(string.format("Expected truthy, got %s", tostring(self._value)))
    end
    return self
end

function Expect:to_be_false()
    if self._value ~= false then
        error(string.format("Expected false, got %s", tostring(self._value)))
    end
    return self
end

function Expect:to_be_greater_than(expected)
    if not (self._value > expected) then
        error(string.format("Expected %s > %s", tostring(self._value), tostring(expected)))
    end
    return self
end

function Expect:to_equal(expected)
    if type(self._value) ~= type(expected) then
        error(string.format("Type mismatch: expected %s, got %s", type(expected), type(self._value)))
    end
    if type(self._value) == "table" then
        for k, v in pairs(expected) do
            if self._value[k] ~= v then
                error(string.format("Table mismatch at key '%s': expected %s, got %s", k, tostring(v), tostring(self._value[k])))
            end
        end
    elseif self._value ~= expected then
        error(string.format("Expected %s, got %s", tostring(expected), tostring(self._value)))
    end
    return self
end

function Framework.summary()
    local total = Framework._results.passed + Framework._results.failed
    print(string.format("\n=== Results: %d/%d passed ===", Framework._results.passed, total))
    if Framework._results.failed > 0 then
        print("Failed:")
        for _, e in ipairs(Framework._results.errors) do
            print(string.format("  - %s: %s", e.name, e.error))
        end
    end
end

-- Test suite
function main()
    print("=== Test Framework Demo ===\n")

    Framework.describe("Math operations", function()
        Framework.it("adds two numbers", function()
            Framework.expect(2 + 3):to_be(5)
        end)

        Framework.it("multiplies two numbers", function()
            Framework.expect(4 * 5):to_be(20)
        end)

        Framework.it("handles negative results", function()
            Framework.expect(3 - 7):to_be(-4)
        end)
    end)

    Framework.describe("Table utilities", function()
        local data = {}

        Framework.setup(function()
            data = { items = { 10, 20, 30 }, count = 3 }
        end)

        Framework.teardown(function()
            data = {}
        end)

        Framework.it("has correct count after setup", function()
            Framework.expect(data.count):to_be(3)
        end)

        Framework.it("sums items", function()
            local sum = 0
            for _, v in ipairs(data.items) do sum = sum + v end
            Framework.expect(sum):to_be(60)
        end)
    end)

    Framework.describe("Type checking", function()
        Framework.it("identifies strings", function()
            Framework.expect("hello"):to_be_type("string")
        end)

        Framework.it("identifies tables", function()
            Framework.expect({}):to_be_type("table")
        end)

        Framework.it("identifies nil", function()
            Framework.expect(nil):to_be_nil()
        end)
    end)

    Framework.describe("Negation", function()
        Framework.it("confirms inequality", function()
            Framework.expect(1):to_not_be(2)
        end)

        Framework.it("fails when values match", function()
            Framework.expect(false):to_be_false()
        end)
    end)

    Framework.summary()
end

main()
