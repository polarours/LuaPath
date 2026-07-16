# Accidental Globals

## The Mistake

Forgetting `local` creates global variables that pollute the global namespace and cause subtle bugs.

## Reproduction

```lua
function compute()
  result = 42  -- BUG: creates global `result`
  return result
end

print(result)  -- 42 (global pollution!)
```

## Why It's Wrong

- Global variables are accessible from anywhere — unintended coupling
- Two unrelated functions can silently overwrite each other's state
- Hard to debug: the bug appears far from the cause

## The Fix

```lua
function compute()
  local result = 42  -- Explicit local
  return result
end

print(result)  -- nil (correct: no pollution)
```

### Detection

Use strict mode to catch accidental globals:

```lua
setmetatable(_G, {
  __newindex = function(_, name)
    error("Attempt to write to global: " .. name, 2)
  end
})
```

## Key Takeaway

Always use `local` unless you intentionally need a global. Run `luac -l` to audit your code for undeclared globals.
