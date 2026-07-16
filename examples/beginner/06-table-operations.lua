-- Example 6: Table Operations
-- Chapter: 04-tables
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: table.insert, table.remove, table.sort, table.concat, table.pack/unpack

--- Print a table's contents
-- @param t table to print
-- @param label optional label
local function print_table(t, label)
  label = label or "Table"
  io.write(string.format("%s: {", label))
  for i, v in ipairs(t) do
    io.write(tostring(v))
    if i < #t then io.write(", ") end
  end
  print("}")
end

--- Main function demonstrating table operations
local function main()
  print("=== Table Operations ===\n")

  -- 1. table.insert and table.remove
  print("1. Insert and Remove:")
  local fruits = {"apple", "banana", "cherry"}
  print_table(fruits, "  Initial")

  table.insert(fruits, "date")
  print_table(fruits, "  After insert (end)")

  table.insert(fruits, 2, "blueberry")
  print_table(fruits, "  After insert (position 2)")

  local removed = table.remove(fruits)
  print(string.format("  Removed: %s", removed))
  print_table(fruits, "  After remove (last)")

  removed = table.remove(fruits, 1)
  print(string.format("  Removed: %s", removed))
  print_table(fruits, "  After remove (first)")

  -- 2. table.sort with custom comparator
  print("\n2. Sorting:")
  local numbers = {5, 2, 8, 1, 9, 3}
  print_table(numbers, "  Before sort")

  table.sort(numbers)
  print_table(numbers, "  After sort (ascending)")

  table.sort(numbers, function(a, b) return a > b end)
  print_table(numbers, "  After sort (descending)")

  -- Sort custom objects
  print("\n  Sorting custom objects:")
  local people = {
    {name = "Alice", age = 30},
    {name = "Bob", age = 25},
    {name = "Charlie", age = 35},
  }

  table.sort(people, function(a, b) return a.age < b.age end)
  for _, p in ipairs(people) do
    print(string.format("    %s (age %d)", p.name, p.age))
  end

  -- 3. table.concat
  print("\n3. Concatenation:")
  local words = {"hello", "world", "from", "lua"}
  local sentence = table.concat(words, " ")
  print(string.format("  Joined: %s", sentence))

  local csv = table.concat({"a", "b", "c"}, ",")
  print(string.format("  CSV: %s", csv))

  local numbered = table.concat(words, " ", 2, 4)
  print(string.format("  Slice (2-4): %s", numbered))

  -- 4. table.pack and table.unpack
  print("\n4. Pack and Unpack:")
  local function multi_return()
    return 1, "two", 3.0, true
  end

  local packed = table.pack(multi_return())
  print(string.format("  Packed: %d values", packed.n))
  for i = 1, packed.n do
    print(string.format("    [%d] = %s (%s)", i, tostring(packed[i]), type(packed[i])))
  end

  local a, b, c, d = table.unpack(packed)
  print(string.format("  Unpacked: %s, %s, %s, %s", tostring(a), tostring(b), tostring(c), tostring(d)))

  -- 5. Building arrays
  print("\n5. Building Arrays:")
  local squares = {}
  for i = 1, 5 do
    squares[i] = i * i
  end
  print_table(squares, "  Squares")

  -- Filter operation
  local evens = {}
  for _, v in ipairs(squares) do
    if v % 2 == 0 then
      table.insert(evens, v)
    end
  end
  print_table(evens, "  Even squares")

  -- 6. Flattening arrays
  print("\n6. Flattening Arrays:")
  local nested = {{1, 2}, {3, 4}, {5, 6}}
  local flat = {}

  for _, sub in ipairs(nested) do
    for _, v in ipairs(sub) do
      table.insert(flat, v)
    end
  end
  print_table(flat, "  Flattened")

  -- 7. Reversing
  print("\n7. Reversing:")
  local original = {1, 2, 3, 4, 5}
  local reversed = {}
  for i = #original, 1, -1 do
    table.insert(reversed, original[i])
  end
  print_table(original, "  Original")
  print_table(reversed, "  Reversed")

  print("\n✓ Table operations examples completed!")
end

-- Run the demonstration
main()
