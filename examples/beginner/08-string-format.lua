-- Example 8: String Formatting
-- Chapter: 03-strings
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: string.format with %s, %d, %f, %x, padding, alignment, table output

--- Print a formatted header line
-- @param title string to display
local function header(title)
  print(string.format("  %s", title))
  print(string.rep("-", 50))
end

--- Main function demonstrating string formatting
local function main()
  print("=== String Formatting ===\n")

  -- 1. Basic format specifiers
  header("1. Basic specifiers")
  print(string.format("  String:  %s", "hello"))
  print(string.format("  Decimal: %d", 42))
  print(string.format("  Float:   %f", 3.14159))
  print(string.format("  Hex:     %x", 255))
  print(string.format("  Hex:     %X", 255))
  print(string.format("  Octal:   %o", 255))
  print(string.format("  Sci:     %e", 123456.789))
  print(string.format("  Short:   %g", 0.000123))

  -- 2. Width and alignment
  header("2. Width and alignment")
  print(string.format("  Right:   [%10s]", "right"))
  print(string.format("  Left:    [%-10s]", "left"))
  print(string.format("  Center:  [%-10s]", "center"))  -- Lua has no center flag
  print(string.format("  Zero:    [%010d]", 42))
  print(string.format("  Space:   [% 10d]", 42))
  print(string.format("  Plus:    [%+10d]", 42))
  print(string.format("  Neg:     [%+10d]", -42))

  -- 3. Float precision
  header("3. Float precision")
  print(string.format("  Default:  %f", 3.14159))
  print(string.format("  2 dec:    %.2f", 3.14159))
  print(string.format("  4 dec:    %.4f", 3.14159))
  print(string.format("  0 dec:    %.0f", 3.14159))
  print(string.format("  Wide:     %12.4f", 3.14159))
  print(string.format("  Left:     %-12.4f", 3.14159))

  -- 4. Hex formatting
  header("4. Hex formatting")
  local bytes = {0x48, 0x65, 0x6C, 0x6C, 0x6F}
  for _, b in ipairs(bytes) do
    io.write(string.format("  %02X ", b))
  end
  print()
  for _, b in ipairs(bytes) do
    io.write(string.format("  %02x ", b))
  end
  print()

  -- 5. Building a table with aligned columns
  header("5. Formatted table output")
  local products = {
    {name = "Widget",     price = 9.99,   qty = 42},
    {name = "Gadget",     price = 24.50,  qty = 15},
    {name = "Doohickey",  price = 3.75,   qty = 100},
    {name = "Thingamajig", price = 99.99, qty = 3},
  }

  print(string.format("  %-14s %8s %6s %10s", "Product", "Price", "Qty", "Total"))
  print(string.format("  %-14s %8s %6s %10s", "-------", "-----", "---", "-----"))

  local grand_total = 0
  for _, p in ipairs(products) do
    local total = p.price * p.qty
    grand_total = grand_total + total
    print(string.format("  %-14s %8.2f %6d %10.2f", p.name, p.price, p.qty, total))
  end

  print(string.format("  %-14s %8s %6s %10s", "", "", "", "--------"))
  print(string.format("  %-14s %8s %6s %10.2f", "Grand Total", "", "", grand_total))

  -- 6. Escape sequences in strings
  header("6. Common escape sequences")
  print(string.format("  Tab:     \t'after tab'"))
  print(string.format("  Newline: 'line1\\nline2'"))
  print(string.format("  Null:    'a\\0b' (len=%d)", #"a\0b"))
  print(string.format("  Backslash: \\\\ (literal \\)"))
  print(string.format("  Percent: %%d prints literal '%%d'"))

  -- 7. Repetition with string.rep
  header("7. String repetition")
  print(string.rep("  ==", 10))
  print(string.rep("  Lua! ", 5))
  print(string.rep("  *", 20))

  -- 8. Searching and extracting
  header("8. Substring operations")
  local text = "Hello, World!"
  print(string.format("  find:     %s", string.find(text, "World")))
  print(string.format("  sub:      %s", string.sub(text, 8, 12)))
  print(string.format("  match:    %s", string.match(text, "%w+")))
  print(string.format("  gsub:     %s", string.gsub(text, "World", "Lua")))
  print(string.format("  len:      %d", string.len(text)))

  -- 9. Building strings efficiently
  header("9. Building strings")
  local parts = {}
  for i = 1, 5 do
    parts[i] = string.format("item_%03d", i)
  end
  local csv = table.concat(parts, ", ")
  print(string.format("  Built: %s", csv))

  local repeated = string.rep("abc", 3)
  print(string.format("  Rep:   %s", repeated))

  local padded = string.format("[%20s]", "centered")
  print(string.format("  Padded:%s", padded))

  print("\n✓ String formatting examples completed!")
end

-- Run the demonstration
main()
