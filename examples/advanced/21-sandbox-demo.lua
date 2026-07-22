-- Example 24: Sandbox Demo
-- Chapter: 17-embedding-patterns
-- Difficulty: Advanced
-- Lua Version: 5.1+

-- Demonstrates: sandboxing, restricted environments, safe code execution

local function main()
  print("=== Sandbox Demo ===\n")

  -- Create a sandboxed environment
  local function create_sandbox(allowed_globals)
    local env = {}
    for _, name in ipairs(allowed_globals) do
      env[name] = _G[name]
    end
    return env
  end

  -- Safe code execution
  local function safe_execute(code, env)
    local chunk, err = load(code, "sandbox", "t", env)
    if not chunk then
      return nil, "compile error: " .. err
    end

    local ok, result = pcall(chunk)
    if not ok then
      return nil, "runtime error: " .. tostring(result)
    end
    return result
  end

  -- Create restricted environment
  local sandbox = create_sandbox({"print", "tostring", "tonumber", "math", "string"})

  -- Safe code
  local result, err = safe_execute('print("Hello from sandbox!")', sandbox)
  print("Safe code:", result)

  -- Code that tries to access blocked globals
  local result2, err2 = safe_execute('os.execute("rm -rf /")', sandbox)
  print("Blocked code:", result2, err2)

  -- Code with syntax error
  local result3, err3 = safe_execute('print("unclosed', sandbox)
  print("Syntax error:", result3, err3)

  print("\n=== Done ===")
end

main()
