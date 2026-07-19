#!/usr/bin/env lua
-- Stage 40: Modern Patterns - String Format
-- Type-safe formatted output

-- Advanced string formatting patterns
local function format_table(t, indent)
  indent = indent or 0
  local parts = {}
  local prefix = string.rep("  ", indent)
  
  for k, v in pairs(t) do
    if type(v) == "table" then
      parts[#parts + 1] = prefix .. tostring(k) .. ":"
      parts[#parts + 1] = format_table(v, indent + 1)
    else
      parts[#parts + 1] = prefix .. tostring(k) .. ": " .. tostring(v)
    end
  end
  
  return table.concat(parts, "\n")
end

-- Zip iterator for parallel iteration
local function zip(...)
  local tables = {...}
  local indices = {}
  for i = 1, #tables do
    indices[i] = 1
  end
  
  return function()
    local values = {}
    local any_active = false
    
    for i, t in ipairs(tables) do
      if indices[i] <= #t then
        values[#values + 1] = t[indices[i]]
        indices[i] = indices[i] + 1
        any_active = true
      else
        values[#values + 1] = nil
      end
    end
    
    if any_active then
      return table.unpack(values)
    end
    return nil
  end
end

-- Function composition
local function compose(...)
  local funcs = {...}
  return function(...)
    local result = {...}
    for i = #funcs, 1, -1 do
      result = {funcs[i](table.unpack(result))}
    end
    return table.unpack(result)
  end
end

-- Usage examples
local names = {"Alice", "Bob", "Charlie"}
local scores = {95, 87, 92}

print("=== Zip Iterator ===")
for name, score in zip(names, scores) do
  print(string.format("%s: %d", name, score))
end

-- Functional composition
local function double(x) return x * 2 end
local function add_one(x) return x + 1 end
local function negate(x) return -x end

local transform = compose(negate, add_one, double)
print("\n=== Function Composition ===")
print("transform(5):", transform(5))  -- -11

-- Table formatting
local config = {
  database = {
    host = "localhost",
    port = 5432,
  },
  cache = {
    enabled = true,
    ttl = 300,
  },
}

print("\n=== Table Formatting ===")
print(format_table(config))

-- Fluent API
local Query = {}
Query.__index = Query

function Query.new(table_name)
  return setmetatable({table = table_name, conditions = {}, order = nil}, Query)
end

function Query:where(condition)
  self.conditions[#self.conditions + 1] = condition
  return self
end

function Query:order_by(field)
  self.order = field
  return self
end

function Query:build()
  local sql = "SELECT * FROM " .. self.table
  if #self.conditions > 0 then
    sql = sql .. " WHERE " .. table.concat(self.conditions, " AND ")
  end
  if self.order then
    sql = sql .. " ORDER BY " .. self.order
  end
  return sql
end

print("\n=== Fluent API ===")
local q = Query.new("users")
  :where("active = 1")
  :where("age > 18")
  :order_by("name")
print(q:build())
