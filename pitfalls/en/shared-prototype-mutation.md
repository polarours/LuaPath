# Shared Prototype Mutation

All instances created from the same constructor share one prototype table — mutating it silently affects every instance.

## The Mistake

```lua
local Dog = {}
Dog.bones = {} -- shared prototype table

function Dog.new(name)
  local self = setmetatable({}, Dog)
  self.name = name
  return self
end

local rex = Dog.new("Rex")
local fido = Dog.new("Fido")

rex.bones[1] = "steak"

print(fido.bones[1]) -- "steak" — surprise!
```

## Why It's Wrong

`Dog.bones` is a table assigned once on the prototype. Every instance inherits it through the metatable chain. When `rex.bones` resolves, Lua finds the shared table on `Dog` and writes into it directly. There is no per-instance copy.

This is subtle because adding a key to a metatable-backed table **does not** trigger `__newindex` — it modifies the shared object in place.

## The Fix

Clone the table inside the constructor:

```lua
function Dog.new(name)
  local self = setmetatable({}, Dog)
  self.name = name
  self.bones = {} -- per-instance copy
  return self
end
```

For nested tables, clone recursively or initialize lazily:

```lua
function Dog.new(name)
  local self = setmetatable({}, Dog)
  self.name = name
  self.bones = {}
  self.tricks  = {}
  return self
end
```

## Key Takeaway

Primitive fields (strings, numbers, booleans) are safe to leave on the prototype — assignment creates a local shadow. Tables and other reference types must be cloned in the constructor to avoid cross-instance mutation.
