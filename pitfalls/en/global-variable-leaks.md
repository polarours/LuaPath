# Global Variable Leaks

## The Mistake

Forgetting to use `local` creates global variables that pollute the namespace.

```lua
-- This creates a global variable!
function helper()
  result = 42  -- Global!
end

-- Check for globals
print(result)  -- 42 (leaked!)
```

## Why It Fails

Global variables are stored in `_G` and are accessible from anywhere. Accidental globals can cause naming conflicts and hard-to-find bugs.

## The Fix

```lua
-- Always use local
function helper()
  local result = 42  -- Local scope
  return result
end

-- Or use strict mode
local function strict()
  setmetatable(_G, {
    __newindex = function(_, name)
      error("attempt to create global '" .. name .. "'", 2)
    end
  })
end

-- Enable strict mode
strict()

-- Now this will error:
-- unknown_global = "test"  -- Error!
```

## Related Concepts

- [01-basics.md](../en/01-basics.md) — Variables and scope
- [06-modules.md](../en/06-modules.md) — Module system
