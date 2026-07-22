# Shared Metatable Mutation

## The Mistake

Modifying a metatable that is shared between multiple objects, affecting all objects.

```lua
local MyClass = {}
MyClass.__index = MyClass

local obj1 = setmetatable({name = "Alice"}, MyClass)
local obj2 = setmetatable({name = "Bob"}, MyClass)

-- This modifies the shared metatable!
MyClass.greet = function(self)
  return "Hello, " .. self.name .. "!"
end

-- Both objects now have the greet method
print(obj1:greet())  -- Works, but may not be intended
```

## Why It Fails

All objects sharing the same metatable see changes to it. This can cause unexpected behavior when you only intend to modify one object.

## The Fix

```lua
-- Option 1: Set methods on the class before creating instances
local MyClass = {}
MyClass.__index = MyClass
MyClass.greet = function(self) return "Hello, " .. self.name end

-- Option 2: Use per-instance tables for mutable state
local obj = setmetatable({}, MyClass)
obj.custom_data = {}  -- Instance-specific data
```

## Related Concepts

- [05-metatables.md](../en/05-metatables.md) — Metatables and metamethods
- [13-patterns.md](../en/13-patterns.md) — Design patterns
