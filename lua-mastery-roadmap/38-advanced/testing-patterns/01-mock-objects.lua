#!/usr/bin/env lua
-- Stage 38: Testing Patterns - Mock Objects
-- Test doubles for verifying interactions

local Mock = {}
Mock.__index = Mock

function Mock.new(name)
  return setmetatable({
    name = name or "mock",
    calls = {},
    stubs = {},
  }, Mock)
end

function Mock:stub(method, return_value)
  self.stubs[method] = return_value
end

function Mock:call(method, ...)
  self.calls[#self.calls + 1] = {method = method, args = {...}}
  return self.stubs[method]
end

function Mock:verify(method, times)
  local count = 0
  for _, call in ipairs(self.calls) do
    if call.method == method then
      count = count + 1
    end
  end
  if times and count ~= times then
    error(string.format("Expected %s to be called %d times, got %d", method, times, count))
  end
  return count
end

function Mock:was_called(method)
  return self:verify(method) > 0
end

function Mock:reset()
  self.calls = {}
end

-- Test fixture example
local function create_test_db()
  return {
    users = {},
    save = function(self, user)
      self.users[user.id] = user
      return true
    end,
    find = function(self, id)
      return self.users[id]
    end,
  }
end

-- Usage
local mock = Mock.new("database")
mock:stub("save", true)

local db = create_test_db()
db.save = function(self, user)
  mock:call("save", user)
  return mock:stub("save")
end

db:save({id = 1, name = "Alice"})
db:save({id = 2, name = "Bob"})

print("save called:", mock:verify("save", 2))  -- 2
print("was_called:", mock:was_called("save"))  -- true

-- Parameterized tests
local tests = {
  {input = "hello", expected = "HELLO"},
  {input = "world", expected = "WORLD"},
  {input = "lua", expected = "LUA"},
}

local function upper(s)
  return s:upper()
end

print("\n=== Parameterized Tests ===")
for _, test in ipairs(tests) do
  local result = upper(test.input)
  local status = result == test.expected and "PASS" or "FAIL"
  print(string.format("[%s] %s -> %s (expected %s)", status, test.input, result, test.expected))
end
