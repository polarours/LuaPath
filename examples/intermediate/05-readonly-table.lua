-- Example 5: Read-only Table Wrapper
-- Chapter: 05-metatables
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: metatable protection, __newindex, error handling

--- Create a read-only view of a table
-- @param t table to protect
-- @param recursive also protect nested tables
-- @return read-only proxy table
local function readonly(t, recursive)
  recursive = recursive or false
  
  local proxy = {}
  local mt = {
    __index = t,
    __newindex = function(proxy, key, value)
      error(string.format("Cannot modify read-only table: %s = %s", 
        tostring(key), tostring(value)), 2)
    end,
    __pairs = function()
      return pairs(t)
    end,
    __len = function()
      return #t
    end,
    __tostring = function()
      return tostring(t) .. " (readonly)"
    end,
  }
  
  if recursive then
    -- Wrap nested tables recursively
    local function wrap_nested(orig)
      if type(orig) == "table" then
        return readonly(orig, true)
      end
      return orig
    end
    
    mt.__index = function(proxy, key)
      return wrap_nested(t[key])
    end
  end
  
  setmetatable(proxy, mt)
  return proxy
end

--- Create a protected table with selective write access
-- @param t table to protect
-- @param writable_keys set of keys that can be modified
-- @return protected table
local function protected(t, writable_keys)
  writable_keys = writable_keys or {}
  
  local proxy = {}
  local mt = {
    __index = t,
    __newindex = function(proxy, key, value)
      if not writable_keys[key] then
        error(string.format("Key '%s' is not writable", key), 2)
      end
      rawset(t, key, value)
    end,
    __pairs = function()
      return pairs(t)
    end,
  }
  
  setmetatable(proxy, mt)
  return proxy
end

-- Test
print("Read-only Table Wrapper")
print("=======================")

-- Basic read-only test
local data = {
  name = "Config",
  version = "1.0.0",
  settings = {
    debug = true,
    max_connections = 100,
  }
}

local ro_data = readonly(data, true)

print(string.format("Read access: %s = %s", "name", ro_data.name))
print(string.format("Read access: %s = %s", "version", ro_data.version))
print(string.format("Nested read: settings.debug = %s", ro_data.settings.debug))

-- Test write protection
print("\nTesting write protection:")
local success, err = pcall(function()
  ro_data.name = "Modified"  -- Should fail
end)

if not success then
  print(string.format("✓ Write blocked: %s", err))
end

-- Test nested protection
print("\nTesting nested protection:")
success, err = pcall(function()
  ro_data.settings.debug = false  -- Should fail (recursive)
end)

if not success then
  print(string.format("✓ Nested write blocked: %s", err))
end

-- Test protected with writable keys
print("\nProtected table with writable keys:")
local config = {
  readonly_field = "cannot change",
  writable_field = "can change",
}

local proto = protected(config, {writable_field = true})

print(string.format("writable_field = %s", proto.writable_field))

success, err = pcall(function()
  proto.writable_field = "new value"
  print(string.format("✓ Writable field changed to: %s", proto.writable_field))
end)

success, err = pcall(function()
  proto.readonly_field = "attempt"  -- Should fail
end)

if not success then
  print(string.format("✓ Readonly field protected: %s", err))
end

-- Test __pairs and __len
print("\nTesting __pairs and __len:")
print(string.format("Length: %d", #ro_data))
print("Keys:")
for k, v in pairs(ro_data) do
  if type(v) ~= "table" then
    print(string.format("  %s = %s", k, v))
  end
end

print("\n✓ Read-only wrapper tests completed!")
