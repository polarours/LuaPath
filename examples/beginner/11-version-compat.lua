-- Example 11: Version Compatibility
-- Chapter: 16-lua-ecosystem
-- Difficulty: Intermediate
-- Lua Version: 5.1+

-- Demonstrates: version detection, feature gating, compatibility shims

local function main()
  print("=== Version Compatibility Demo ===\n")

  -- Version detection
  --
  -- Compare versions *numerically*. A string comparison gets this wrong:
  -- "5.10" sorts before "5.3" lexicographically, so `version >= "5.3"` would
  -- report that Lua 5.10 is older than Lua 5.3.
  local major, minor = _VERSION:match("(%d+)%.(%d+)")
  local version = major .. "." .. minor

  local function at_least(want_major, want_minor)
    local have_major, have_minor = tonumber(major), tonumber(minor)
    if have_major ~= want_major then
      return have_major > want_major
    end
    return have_minor >= want_minor
  end

  print("Lua version:", _VERSION)
  print("Version number:", version)
  print("String compare '5.10' >= '5.3':", "5.10" >= "5.3",
    "(false, yet 5.10 is newer than 5.3 -- never compare versions as strings)")

  -- Feature detection
  local has_unpack = type(unpack) == "function"
  local has_table_unpack = type(table.unpack) == "function"
  -- rawget, not a bare read: bit32 is a 5.1-only library, so on 5.2+
  -- the name does not exist at all and reading it directly would be an
  -- undefined global access.
  local has_bit32 = type(rawget(_G, "bit32")) == "table"

  print("\nFeature detection:")
  print("  unpack (global):", has_unpack)
  print("  table.unpack:", has_table_unpack)
  print("  bit32 library:", has_bit32)

  -- Compatibility shim
  local unpack = unpack or table.unpack

  -- Usage
  local function first(...)
    return unpack({...}, 1, 1)
  end
  print("First of (1,2,3):", first(1, 2, 3))

  -- Version-specific behavior
  --
  -- `//` and `|` are *syntax*, not runtime features: a 5.1 parser rejects
  -- them at compile time, even inside a branch that would never run. So the
  -- 5.3+ snippet lives in a string and is compiled only when supported.
  print("\nVersion-specific:")
  if at_least(5, 3) then
    local chunk = load("return 7 // 2, 5 | 3")
    local idiv, bitwise = chunk()
    print("  Integer division: 7 // 2 =", idiv)
    print("  Bitwise: 5 | 3 =", bitwise)
  else
    print("  Integer division and bitwise not available")
  end

  print("\n=== Done ===")
end

main()
