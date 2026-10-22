-- vector_ops.lua — Vector operations library for SIMD-style patterns
-- Provides element-wise operations on Lua tables as vectors.
-- These operations can be vectorized by CPU SIMD units when implemented
-- in native code; here we demonstrate the pattern in pure Lua.

local Vector = {}
Vector.__index = Vector

--- Create a new vector from varargs.
-- @param ... Numbers to store as vector components
-- @return Vector table with metatable
function Vector.new(...)
  local res = {...}
  return setmetatable(res, Vector)
end

--- Element-wise vector addition.
-- @tparam Vector a First vector
-- @tparam Vector b Second vector
-- @treturn Vector Result vector (a + b)
-- @raise AssertionError if vectors have different lengths
function Vector.add(a, b)
  assert(#a == #b, "Vectors must have same length")
  local res = {}
  for i = 1, #a do
    res[i] = a[i] + b[i]
  end
  return setmetatable(res, Vector)
end

--- Dot product of two vectors.
-- @tparam Vector a First vector
-- @tparam Vector b Second vector
-- @treturn number Scalar dot product (a · b)
-- @raise AssertionError if vectors have different lengths
function Vector.dot(a, b)
  assert(#a == #b, "Vectors must have same length")
  local sum = 0
  for i = 1, #a do
    sum = sum + a[i] * b[i]
  end
  return sum
end

--- Scale vector by scalar.
-- @tparam Vector v Input vector
-- @tparam number s Scalar multiplier
-- @treturn Vector Result vector (v * s)
function Vector.scale(v, s)
  local res = {}
  for i = 1, #v do
    res[i] = v[i] * s
  end
  return setmetatable(res, Vector)
end

--- Apply function to each element.
-- @tparam function f Mapping function
-- @tparam Vector v Input vector
-- @treturn Vector Result vector with f applied to each element
function Vector.map(f, v)
  local res = {}
  for i = 1, #v do
    res[i] = f(v[i])
  end
  return setmetatable(res, Vector)
end

--- Convert vector to string representation.
-- @tparam Vector v Vector to format
-- @treturn string String like "[1, 2, 3]"
function Vector.tostring(v)
  local parts = {}
  for i = 1, #v do
    parts[i] = tostring(v[i])
  end
  return "[" .. table.concat(parts, ", ") .. "]"
end

return Vector
