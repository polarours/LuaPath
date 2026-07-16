-- Example 6: Metatable Basics
-- Chapter: 06-metatables
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: __index, __newindex, __call, __tostring metamethods
-- Shows: prototype inheritance, proxy tables, callable objects

local function main()
    print("=== Metatable Basics ===\n")

    -- 1. __index: controlling field access
    local proxy = setmetatable({}, {
        __index = function(_, key)
            print("[__index] Accessing unknown key: " .. tostring(key))
            return "default_value"
        end,
    })

    print("proxy.name:", proxy.name)
    print("proxy.missing:", proxy.missing)
    print()

    -- 2. __newindex: controlling field assignment
    local watched = {}
    local watched_mt = {
        __newindex = function(t, key, value)
            print("[__newindex] Setting " .. tostring(key) .. " = " .. tostring(value))
            rawset(t, key, value)
        end,
    }
    setmetatable(watched, watched_mt)

    watched.x = 10
    watched.y = 20
    print()

    -- 3. Prototype inheritance via __index
    local Animal = {}
    Animal.__index = Animal

    function Animal:new(name)
    local obj = setmetatable({ name = name, energy = 100 }, self)
    return obj
end

    function Animal:speak()
        return self.name .. " makes a sound"
    end

    function Animal:__tostring()
        return string.format("Animal(%s, energy=%d)", self.name, self.energy)
    end

    local cat = Animal:new("Cat")
    print("Cat tostring:", tostring(cat))
    print("Cat speak:", cat:speak())
    print()

    -- 4. __call: callable objects
    local Counter = {}
    Counter.__index = Counter

    function Counter:new(start)
        return setmetatable({ value = start or 0 }, Counter)
    end

    function Counter:__call(delta)
        self.value = self.value + (delta or 1)
        return self.value
    end

    local c = Counter:new(10)
    print("Counter value:", c())
    print("Counter +5:", c(5))
    print("Counter +3:", c(3))
    print()

    -- 5. __tostring: custom string representation
    local Point = {}
    Point.__index = Point

    function Point:new(x, y)
        return setmetatable({ x = x, y = y }, Point)
    end

    function Point:__tostring()
        return string.format("(%d, %d)", self.x, self.y)
    end

    local p = Point:new(3, 7)
    print("Point:", tostring(p))

    print("\n=== Done ===")
end

main()
