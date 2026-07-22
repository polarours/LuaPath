-- Example 19: Metatable Magic
-- Chapter: 05-metatables
-- Difficulty: Intermediate
-- Lua Version: 5.1+

-- Demonstrates: __index, __newindex, __call, __tostring

local function main()
  print("=== Metatable Magic ===\n")

  -- 1. Auto-vivifying table (creates missing keys automatically)
  local auto = setmetatable({}, {
    __index = function(t, k)
      rawset(t, k, {})
      return rawget(t, k)
    end
  })

  auto.users.alice = 100
  auto.users.bob = 200
  auto.config.debug = true

  print("Auto-vivified:")
  for k, v in pairs(auto) do
    print("  " .. k .. ":", v)
  end

  -- 2. Read-only table
  local function readonly(t)
    return setmetatable({}, {
      __index = t,
      __newindex = function()
        error("attempt to modify read-only table")
      end,
    })
  end

  local config = readonly({host = "localhost", port = 8080})
  print("\nRead-only config:", config.host, config.port)
  -- config.host = "other"  -- Would error!

  -- 3. Callable table (object as function)
  local counter = setmetatable({count = 0}, {
    __call = function(self, step)
      self.count = self.count + (step or 1)
      return self.count
    end,
    __tostring = function(self)
      return "Counter(" .. self.count .. ")"
    end,
  })

  print("\nCallable counter:")
  print(counter())    -- 1
  print(counter(5))   -- 6
  print(tostring(counter))  -- Counter(6)

  print("\n=== Done ===")
end

main()
