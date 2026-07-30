-- vector_ops.lua — Vector operations library
-- Provides element-wise operations on Lua tables as vectors.

local Vector = {}
Vector.__index = Vector

function Vector.new(...)
  local res = {...}
  return setmetatable(res, Vector)
end

function Vector.add(a, b)
  assert(#a == #b, "Vectors must have same length")
  local res = {}
  for i = 1, #a do
    res[i] = a[i] + b[i]
  end
  return setmetatable(res, Vector)
end

function Vector.dot(a, b)
  assert(#a == #b, "Vectors must have same length")
  local sum = 0
  for i = 1, #a do
    sum = sum + a[i] * b[i]
  end
  return sum
end

function Vector.scale(v, s)
  local res = {}
  for i = 1, #v do
    res[i] = v[i] * s
  end
  return setmetatable(res, Vector)
end

function Vector.map(f, v)
  local res = {}
  for i = 1, #v do
    res[i] = f(v[i])
  end
  return setmetatable(res, Vector)
end

function Vector.tostring(v)
  local parts = {}
  for i = 1, #v do
    parts[i] = tostring(v[i])
  end
  return "[" .. table.concat(parts, ", ") .. "]"
end

return Vector
