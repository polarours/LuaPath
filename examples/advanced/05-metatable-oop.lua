-- Example 5: Metatable OOP System
-- Chapter: 05-oop
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: full OOP system with metatables, inheritance, type checking
-- Shows: Animal -> Dog inheritance, is_a(), method overriding

local function main()
    print("=== Metatable OOP System ===\n")

    -- 1. Base class: Animal
    local Animal = {}
    Animal.__index = Animal
    Animal._type = "Animal"

    function Animal:new(name, sound)
        local obj = setmetatable({ name = name, sound = sound, energy = 100 }, self)
        return obj
    end

    function Animal:speak()
        return self.name .. " says " .. self.sound .. "!"
    end

    function Animal:rest(amount)
        self.energy = math.min(100, self.energy + (amount or 10))
        return self.energy
    end

    function Animal:__tostring()
        return string.format("[%s] %s (energy=%d)", self._type, self.name, self.energy)
    end

    -- 2. Type checking utility
    local function is_a(obj, class)
        if type(obj) ~= "table" then return false end
        local mt = getmetatable(obj)
        while mt do
            if mt == class then return true end
            mt = mt._parent
        end
        return false
    end

    -- 3. Derived class: Dog (inherits from Animal)
    local Dog = setmetatable({}, { __index = Animal })
    Dog.__index = Dog
    Dog._type = "Dog"
    Dog._parent = Animal

    function Dog:new(name, breed)
        local obj = Animal.new(self, name, "Woof")
        obj._type = "Dog"
        obj.breed = breed
        return obj
    end

    function Dog:speak()
        return self.name .. " barks: " .. self.sound .. "!"
    end

    function Dog:fetch(item)
        self.energy = math.max(0, self.energy - 15)
        return string.format("%s fetches the %s (energy=%d)", self.name, item, self.energy)
    end

    function Dog:__tostring()
        return string.format("[%s] %s the %s (energy=%d)", self._type, self.name, self.breed, self.energy)
    end

    -- 4. Another derived class: Cat (inherits from Animal)
    local Cat = setmetatable({}, { __index = Animal })
    Cat.__index = Cat
    Cat._type = "Cat"
    Cat._parent = Animal

    function Cat:new(name)
        local obj = Animal.new(self, name, "Meow")
        obj._type = "Cat"
        return obj
    end

    function Cat:speak()
        return self.name .. " purrs: " .. self.sound .. "~"
    end

    function Cat:__tostring()
        return string.format("[%s] %s (energy=%d)", self._type, self.name, self.energy)
    end

    -- 5. Demo
    local dog = Dog:new("Buddy", "Golden Retriever")
    local cat = Cat:new("Whiskers")

    print("--- Animals ---")
    print(tostring(dog))
    print(tostring(cat))
    print()

    print("--- Speak ---")
    print(dog:speak())
    print(cat:speak())
    print()

    print("--- Actions (inherited rest + override speak) ---")
    print(dog:fetch("ball"))
    print(dog:fetch("stick"))
    print("Cat before rest:", tostring(cat))
    cat:rest(20)
    print("Cat after rest:", tostring(cat))
    print()

    print("--- Inheritance check ---")
    print("dog is_a Dog:", is_a(dog, Dog))
    print("dog is_a Animal:", is_a(dog, Animal))
    print("cat is_a Dog:", is_a(cat, Dog))
    print("cat is_a Animal:", is_a(cat, Animal))
    print()

    print("--- Method override ---")
    print("Dog speak:", dog:speak())
    print("Cat speak:", cat:speak())

    print("\n=== Done ===")
end

main()
