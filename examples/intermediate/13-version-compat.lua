-- Example 13: Version Compatibility Patterns
-- Chapter: 09-advanced
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: version detection, feature gating, _VERSION usage
-- Shows: 5.1 vs 5.3 vs 5.4 differences, portable code patterns

-- Compatibility: load() vs loadstring() across versions
local load_code = loadstring or load  -- Lua 5.1 uses loadstring, 5.2+ uses load

local function main()
    print("=== Version Compatibility Patterns ===\n")

    -- 1. Version detection
    local version = _VERSION:match("%d+%.%d+")
    local major = tonumber(_VERSION:match("%d+"))
    local minor = tonumber(_VERSION:match("%d+%.(%d+)"))

    print("--- Version Info ---")
    print("_VERSION     =", _VERSION)
    print("major        =", major)
    print("minor        =", minor)

    -- 2. Feature detection (preferred over version checking)
    print("\n--- Feature Detection ---")

    -- table.pack/unpack (5.1 has table.unpack, 5.2+ has table.pack)
    local has_table_pack = type(table.pack) == "function"
    local has_table_unpack = type(table.unpack) == "function"
    print("table.pack   =", has_table_pack)
    print("table.unpack =", has_table_unpack)

    -- Bitwise operators (5.3+)
    local has_bitwise = not not load_code("return 1 & 2")
    print("bitwise ops  =", has_bitwise)

    -- Generics (5.4+)
    local has_generics = not not load_code("local <T> = {}")
    print("generics     =", has_generics)

    -- Integer division // (5.3+)
    local has_idiv = not not load_code("return 7 // 2")
    print("integer div  =", has_idiv)

    -- Warn library (5.4+)
    local has_warn = type(warn) == "function"
    print("warn()       =", has_warn)

    -- 3. Portable patterns
    print("\n--- Portable Patterns ---")

    -- Pattern A: Selective unpack
    -- Lua 5.1: unpack(t) is global
    -- Lua 5.2+: table.unpack(t)
    local function portable_unpack(t, i, j)
        i = i or 1
        j = j or #t
        if table.unpack then
            return table.unpack(t, i, j)
        else
            return unpack(t, i, j)  -- Lua 5.1
        end
    end

    local nums = {10, 20, 30, 40, 50}
    print("unpack(2,4) =", portable_unpack(nums, 2, 4))

    -- Pattern B: Conditional feature loading
    local function portable_pack(...)
        local t = {...}
        t.n = select("#", ...)
        return t
    end

    local packed = portable_pack("a", "b", "c")
    print("pack(...)    =", table.concat(packed, ", "), "n=" .. packed.n)

    -- Pattern C: Version-gated code blocks
    local function version_gate(min_major, min_minor, fn)
        if major > min_major or (major == min_major and minor >= min_minor) then
            return true, fn()
        end
        return false, nil
    end

    -- Use version gate for bitwise operations
    local ok, result = version_gate(5, 3, function()
        return load_code("return 0xFF & 0x0F")()
    end)
    if ok then
        print("0xFF & 0x0F  =", result)
    else
        print("0xFF & 0x0F  = (not supported)")
    end

    -- 4. Backport table
    print("\n--- Backport Table ---")

    local compat = {}

    -- Backport table.pack for 5.1
    if not table.pack then
        compat.pack = function(...)
            local t = {...}
            t.n = select("#", ...)
            return t
        end
    else
        compat.pack = table.pack
    end

    -- Backport math.maxinteger for 5.1/5.2
    compat.maxinteger = math.maxinteger or 2^53 - 1
    compat.mininteger = math.mininteger or -(2^53 - 1)

    print("compat.pack works:", compat.pack("x", "y").n == 2)
    print("maxinteger:", compat.maxinteger)
    print("mininteger:", compat.mininteger)

    -- 5. Conditional require
    print("\n--- Conditional Require ---")

    local function safe_require(name)
        local ok, mod = pcall(require, name)
        if ok then
            return mod
        else
            print("  (skipped: " .. name .. ")")
            return nil
        end
    end

    -- These may or may not be available
    safe_require("bit32")  -- Lua 5.2 only
    safe_require("utf8")   -- Lua 5.3+ only

    -- 6. Summary
    print("\n--- Compatibility Summary ---")
    print(string.format(
        "Running Lua %s — supports %s%s%s",
        _VERSION,
        has_bitwise and "bitwise, " or "",
        has_idiv and "idiv, " or "",
        has_generics and "generics" or "basic features"
    ))

    print("\n✓ Version compatibility patterns complete!")
end

main()
