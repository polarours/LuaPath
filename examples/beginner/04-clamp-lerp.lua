-- Example 4: Clamp and Lerp Utilities
-- Chapter: 01-basics
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: utility functions, edge case handling

--- Clamp a value between min and max
-- @param value number to clamp
-- @param min minimum bound
-- @param max maximum bound
-- @return clamped value
local function clamp(value, min, max)
  return math.max(min, math.min(value, max))
end

--- Linear interpolation between two values
-- @param a start value
-- @param b end value
-- @param t interpolation factor (0-1)
-- @return interpolated value
local function lerp(a, b, t)
  t = clamp(t, 0, 1)  -- Ensure t is in [0, 1]
  return a + (b - a) * t
end

--- Inverse linear interpolation
-- Find t given a, b, and value
-- @param a start value
-- @param b end value
-- @param value current value
-- @return t factor (may be outside [0,1])
local function inverse_lerp(a, b, value)
  if a == b then
    return 0  -- Avoid division by zero
  end
  return (value - a) / (b - a)
end

-- Test clamp
print("Clamp tests:")
assert(clamp(5, 0, 10) == 5, "clamp within bounds")
assert(clamp(-5, 0, 10) == 0, "clamp below min")
assert(clamp(15, 0, 10) == 10, "clamp above max")
assert(clamp(0, 0, 10) == 0, "clamp at min")
assert(clamp(10, 0, 10) == 10, "clamp at max")
print("  All clamp tests passed!")

-- Test lerp
print("\nLerp tests:")
assert(lerp(0, 100, 0) == 0, "lerp at start")
assert(lerp(0, 100, 1) == 100, "lerp at end")
assert(lerp(0, 100, 0.5) == 50, "lerp at middle")
assert(lerp(0, 100, 1.5) == 100, "lerp clamped above")
assert(lerp(0, 100, -0.5) == 0, "lerp clamped below")
print("  All lerp tests passed!")

-- Test inverse_lerp
print("\nInverse lerp tests:")
assert(inverse_lerp(0, 100, 50) == 0.5, "inverse lerp middle")
assert(inverse_lerp(0, 100, 0) == 0, "inverse lerp start")
assert(inverse_lerp(0, 100, 100) == 1, "inverse lerp end")
assert(inverse_lerp(10, 10, 5) == 0, "inverse lerp same values")
print("  All inverse lerp tests passed!")

print("\n✓ All tests passed!")
