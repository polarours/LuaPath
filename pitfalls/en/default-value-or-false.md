# Default Value with `or` Fails for False

## The Mistake

Using `value or default` as a default-value pattern fails when `false` is a meaningful value, because `false` is falsey in Lua.

## Reproduction

```lua
local options = {debug = false}
local debug = options.debug or true
print(debug)  -- true! (should be false)

-- The user set debug=false, but the or-pattern overrides it
```

## Why It's Wrong

`or` returns the first truthy value. `false` is falsey, so `or` falls through to the default. This silently overrides intentional `false` values.

## The Fix

```lua
-- Explicit nil check preserves false
local options = {debug = false}
local debug = options.debug ~= nil and options.debug or true
print(debug)  -- false (correct!)

-- Or use a helper function
local function with_default(value, default)
  if value ~= nil then return value end
  return default
end

local debug = with_default(options.debug, true)  -- false
```

## Key Takeaway

`or` only checks truthiness. When `false` is a valid value, use explicit `nil` checks or a helper function.
