-- Example 17: Functional Composition
-- Chapter: 03-functions
-- Difficulty: Advanced
-- Lua Version: 5.1+

-- Demonstrates: function composition, currying, higher-order functions

local function main()
  print("=== Functional Composition ===\n")

  -- Basic composition
  local function compose(f, g)
    return function(...)
      return f(g(...))
    end
  end

  local double = function(x) return x * 2 end
  local add_one = function(x) return x + 1 end

  local double_then_add = compose(add_one, double)
  print("double_then_add(5):", double_then_add(5))  -- 11

  -- Multiple composition
  local function compose_multi(...)
    local funcs = {...}
    return function(...)
      local result = {...}
      for i = #funcs, 1, -1 do
        result = {funcs[i](table.unpack(result))}
      end
      return table.unpack(result)
    end
  end

  local transform = compose_multi(
    function(x) return x + 1 end,
    function(x) return x * 2 end,
    function(x) return x - 3 end
  )
  print("transform(5):", transform(5))  -- 9

  -- Currying
  local function curry(fn)
    return function(a)
      return function(b)
        return fn(a, b)
      end
    end
  end

  local add = curry(function(a, b) return a + b end)
  print("add(3)(4):", add(3)(4))  -- 7

  -- Pipeline
  local function pipeline(...)
    local funcs = {...}
    return function(data)
      local result = data
      for _, fn in ipairs(funcs) do
        result = fn(result)
      end
      return result
    end
  end

  local process = pipeline(
    function(x) return x * 2 end,
    function(x) return x + 10 end,
    function(x) return x % 3 end
  )
  print("process(5):", process(5))  -- 1

  print("\n=== Done ===")
end

main()
