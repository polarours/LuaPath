-- Example 3: Word Frequency Counter
-- Chapter: 04-tables
-- Difficulty: Beginner
-- Lua Version: 5.1+
--
-- Demonstrates: table as map, string manipulation, iteration

--- Count word frequencies in text
-- @param text input string
-- @return table mapping words to counts
local function count_words(text)
  local counts = {}
  
  -- Simple word extraction (lowercase, alphanumeric)
  for word in text:lower():gmatch("%w+") do
    counts[word] = (counts[word] or 0) + 1
  end
  
  return counts
end

-- Test
local sample = [[
  Lua is a powerful language.
  Lua is lightweight and fast.
  Many games use Lua for scripting.
]]

local frequencies = count_words(sample)

-- Print sorted by frequency
local words = {}
for word, count in pairs(frequencies) do
  table.insert(words, {word = word, count = count})
end

table.sort(words, function(a, b)
  return a.count > b.count  -- Descending
end)

print("Word frequencies (sorted):")
for _, entry in ipairs(words) do
  print(string.format("  %s: %d", entry.word, entry.count))
end
