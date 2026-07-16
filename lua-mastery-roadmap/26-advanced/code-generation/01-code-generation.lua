--[[
  Example: Code Generation
  Chapter: Stage 26 — Advanced
  Difficulty: Advanced
  Lua Version: 5.4
  Demonstrates: String-based code gen, load(), DSL construction, template expansion
]]

------------------------------------------------------------
-- 1. STRING-BASED CODE GENERATION
------------------------------------------------------------
local function generateGetterSetter(fieldName, defaultValue)
    local getter = string.format(
        "return function(self) return self._%s end",
        fieldName
    )
    local setter = string.format(
        "return function(self, val) self._%s = val end",
        fieldName
    )
    local init = string.format(
        "return function(self) self._%s = %s end",
        fieldName, defaultValue
    )
    return load(getter)(), load(setter)(), load(init)()
end

local function demo_string_codegen()
    print("=== String-Based Code Generation ===")
    local get, set, init = generateGetterSetter("x", "0")

    local obj = {}
    init(obj)
    print(string.format("  initial x = %d", get(obj)))
    set(obj, 42)
    print(string.format("  after set x = %d", get(obj)))

    local getName, setName, initName = generateGetterSetter("name", '"default"')
    local obj2 = {}
    initName(obj2)
    print(string.format("  initial name = %s", getName(obj2)))
    setName(obj2, '"hello"')
    print(string.format("  after set name = %s", setName(obj2) or "nil"))
    print()
end

------------------------------------------------------------
-- 2. DSL CONSTRUCTION
------------------------------------------------------------
local DSL = {}

function DSL.new()
    local env = {}
    env._rules = {}
    env._output = {}

    setmetatable(env, {
        __index = function(_, key)
            return function(...)
                local args = { ... }
                table.insert(env._rules, { rule = key, args = args })
                return env
            end
        end
    })

    return env
end

function DSL.build(env)
    local code = "local result = {}\n"
    for _, rule in ipairs(env._rules) do
        if rule.rule == "define" then
            local name, value = rule.args[1], rule.args[2]
            code = code .. string.format('result["%s"] = %s\n', name, value)
        elseif rule.rule == "transform" then
            local field, expr = rule.args[1], rule.args[2]
            code = code .. string.format(
                'if result["%s"] then result["%s"] = %s end\n',
                field, field, string.gsub(expr, "@(%w+)", 'result["%1"]')
            )
        elseif rule.rule == "output" then
            local field = rule.args[1]
            code = code .. string.format('print("  %s:", result["%s"])\n', field, field)
        end
    end
    code = code .. "return result"
    return load(code)()
end

local function demo_dsl()
    print("=== DSL Construction ===")
    local d = DSL.new()
    d.define("count", 10)
    d.define("label", '"items"')
    d.transform("count", "@count * 2 + 1")
    d.transform("label", 'string.upper(@label)')
    d.output("count")
    d.output("label")

    DSL.build(d)
    print()
end

------------------------------------------------------------
-- 3. TEMPLATE-BASED CODE EXPANSION
------------------------------------------------------------
local Template = {}

function Template.render(templateStr, vars)
    local result = templateStr:gsub("{{(.-)}}", function(key)
        key = key:match("^%s*(.-)%s*$")
        if vars[key] ~= nil then
            return tostring(vars[key])
        end
        return "{{" .. key .. "}}"
    end)
    return result
end

function Template.generateFunction(templateStr, vars)
    local code = Template.render(templateStr, vars)
    local fn, err = load(code, "generated", "t", {})
    if not fn then
        error("Code generation failed: " .. err)
    end
    return fn()
end

local function demo_templates()
    print("=== Template-Based Code Generation ===")
    local tmpl = [[
return function(n)
    local sum = 0
    for i = 1, n do
        sum = sum + i * {{multiplier}}
    end
    return sum
end]]

    local calcTriple = Template.generateFunction(tmpl, { multiplier = 3 })
    local result = calcTriple(5)
    print(string.format("  sum(i*3 for i=1..5) = %d", result))

    local calcSquare = Template.generateFunction(tmpl, { multiplier = 5 })
    local result2 = calcSquare(4)
    print(string.format("  sum(i*5 for i=1..4) = %d", result2))
    print()
end

------------------------------------------------------------
-- 4. DYNAMIC FUNCTION CREATION
------------------------------------------------------------
local function createFunctions(spec)
    local functions = {}
    for name, body in pairs(spec) do
        local code = string.format("return function(...) %s end", body)
        functions[name] = load(code, name, "t", setmetatable({}, {
            __index = _G
        }))()
    end
    return functions
end

local function demo_dynamic_functions()
    print("=== Dynamic Function Creation ===")
    local funcs = createFunctions({
        add = "local s = 0; for _, v in ipairs({...}) do s = s + v end; return s",
        multiply = "local p = 1; for _, v in ipairs({...}) do p = p * v end; return p",
        greet = 'return "Hello, " .. (select(1, ...) or "world") .. "!"',
    })

    print(string.format("  add(1,2,3) = %d", funcs.add(1, 2, 3)))
    print(string.format("  multiply(2,3,4) = %d", funcs.multiply(2, 3, 4)))
    print(string.format("  greet() = %s", funcs.greet()))
    print()
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------
local function main()
    print("Code Generation in Lua")
    print("Stage 26 — Advanced")
    print("=" .. string.rep("=", 49))
    print()
    demo_string_codegen()
    demo_dsl()
    demo_templates()
    demo_dynamic_functions()
    print("All code generation demos complete.")
end

main()
