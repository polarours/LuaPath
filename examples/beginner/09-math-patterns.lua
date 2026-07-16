-- Example 9: Math Patterns and Utilities
-- Chapter: 01-basics
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: math library functions, random numbers, rounding, clamping
-- Shows: lerp, smoothstep, distance calculation, angle conversion

local function main()
    print("=== Math Patterns ===\n")

    -- Clamping
    local function clamp(val, lo, hi)
        return math.max(lo, math.min(val, hi))
    end

    -- Linear interpolation
    local function lerp(a, b, t)
        return a + (b - a) * clamp(t, 0, 1)
    end

    -- Smoothstep (Hermite interpolation)
    local function smoothstep(edge0, edge1, x)
        local t = clamp((x - edge0) / (edge1 - edge0), 0, 1)
        return t * t * (3 - 2 * t)
    end

    -- Euclidean distance
    local function distance(x1, y1, x2, y2)
        return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
    end

    -- Degrees to radians
    local function deg_to_rad(deg)
        return deg * math.pi / 180
    end

    -- Radians to degrees
    local function rad_to_deg(rad)
        return rad * 180 / math.pi
    end

    -- Sign function
    local function sign(x)
        if x > 0 then return 1
        elseif x < 0 then return -1
        else return 0 end
    end

    -- Print section header
    print("--- Clamping ---")
    print("clamp(15, 0, 10) =", clamp(15, 0, 10))
    print("clamp(-3, 0, 10) =", clamp(-3, 0, 10))
    print("clamp(7, 0, 10)  =", clamp(7, 0, 10))

    print("\n--- Linear Interpolation ---")
    print("lerp(0, 100, 0.0) =", lerp(0, 100, 0.0))
    print("lerp(0, 100, 0.5) =", lerp(0, 100, 0.5))
    print("lerp(0, 100, 1.0) =", lerp(0, 100, 1.0))
    print("lerp(0, 100, 1.5) =", lerp(0, 100, 1.5), "(clamped)")

    print("\n--- Smoothstep ---")
    for i = 0, 10 do
        local x = i / 10
        local val = smoothstep(0, 1, x)
        print(string.format("  smoothstep(0,1,%.1f) = %.3f", x, val))
    end

    print("\n--- Distance ---")
    print(string.format("distance(0,0, 3,4) = %.2f", distance(0, 0, 3, 4)))
    print(string.format("distance(1,1, 4,5) = %.2f", distance(1, 1, 4, 5)))

    print("\n--- Angle Conversion ---")
    print("90 degrees =", deg_to_rad(90), "radians")
    print("pi radians =", rad_to_deg(math.pi), "degrees")
    print("45 degrees =", deg_to_rad(45), "radians")

    print("\n--- Sign ---")
    print("sign(5)  =", sign(5))
    print("sign(-3) =", sign(-3))
    print("sign(0)  =", sign(0))

    print("\n--- Rounding ---")
    print("math.floor(3.7) =", math.floor(3.7))
    print("math.ceil(3.2)  =", math.ceil(3.2))
    print("math.floor(-2.3)=", math.floor(-2.3))
    print("math.ceil(-2.3) =", math.ceil(-2.3))

    -- Verify assertions
    assert(distance(0, 0, 3, 4) == 5, "3-4-5 triangle")
    assert(sign(0) == 0, "sign of zero")
    assert(clamp(50, 0, 10) == 10, "clamp above max")
    assert(math.abs(deg_to_rad(180) - math.pi) < 1e-10, "180 deg = pi rad")
    print("\n✓ All math pattern tests passed!")
end

main()
