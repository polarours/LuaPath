-- Example 22: Version Compatibility
-- Chapter: 16-lua-ecosystem
-- Difficulty: Intermediate
-- Lua Version: 5.1+

-- Demonstrates: version detection, feature gating, compatibility shims

local function main()
  print("=== Version Compatibility Demo ===\n")

  -- Version detection
  local version = _VERSION:match("%d+%.%d+")
  print("Lua version:", _VERSION)
  print("Version number:", version)

  -- Feature detection
  local has_unpack = type(unpack) == "function"
  local has_table_unpack = type(table.unpack) == "function"
  local has_bit32 = type(bit32) == "table"

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
  print("\nVersion-specific:")
  if version >= "5.3" then
    print("  Integer division: 7 // 2 =", 7 // 2)
    print("  Bitwise: 5 | 3 =", 5 | 3)
  else
    print("  Integer division and bitwise not available")
  end

  print("\n=== Done ===")
end

main()
