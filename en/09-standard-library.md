# 09 — Standard Library

> **Phase**: C (Concurrency and Runtime Surfaces)  
> **Prerequisites**: Chapter 08 — Coroutines  
> **Time Estimate**: 2–3 hours reading + 2–4 hours exercises  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT (differences noted)

---

## Learning Objectives

After completing this chapter, you will be able to:

1. **Navigate the standard library** and know which module handles each common task
2. **Use `string` library patterns** for parsing, matching, and transformation
3. **Apply `table` library operations** correctly for sorting, concatenation, and manipulation
4. **Use `math` and `utf8`** for numeric and Unicode operations
5. **Handle `io`/`os` safely** with awareness of sandboxing and platform differences

---

## Standard Library Overview

| Module | Purpose | Sandbox-safe? |
|--------|---------|---------------|
| `string` | Text manipulation, pattern matching | Yes |
| `table` | Array/map operations, sorting | Yes |
| `math` | Numeric functions, random | Yes |
| `utf8` (5.3+) | Unicode codepoint operations | Yes |
| `io` | File I/O | No (restrict in sandboxes) |
| `os` | System calls, time | No (restrict in sandboxes) |
| `debug` | Introspection, hooks | No (disable in sandboxes) |
| `package` | Module loading | No (restrict in sandboxes) |
| `coroutine` | Coroutine operations | Yes |
| `bit32` (5.1-5.2) | Bitwise operations | Yes |

---

## string Library

### Pattern Matching

Lua patterns are **not** PCRE regex. Key differences:

| Feature | Lua | PCRE |
|---------|-----|------|
| Character classes | `%d`, `%w`, `%s` | `\d`, `\w`, `\s` |
| Quantifiers | `*`, `+`, `-`, `?` | `*`, `+`, `?`, `{n}` |
| Capture groups | `()` | `()` |
| Named groups | No | `(?P<name>...)` |
| Lookahead/behind | No | `(?=...)`, `(?<=...)` |
| Alternation | No | `\|` |

```lua
-- Basic patterns
local s = "Hello, World 2024!"
print(string.match(s, "%d+"))        -- "2024" (digits)
print(string.match(s, "%a+"))        -- "Hello" (letters)
print(string.match(s, "%s+%S+"))     -- ", World" (space + non-space)

-- Capture groups
local name, domain = string.match("user@example.com", "^([^@]+)@(.+)$")
print(name, domain)          -- "user"  "example.com"

-- Captures with captures
local full, area, num = string.match("(555) 123-4567", "%((%d+)%)%s+(%d+)-(%d+)")
print(full, area, num)       -- "(555) 123-4567"  "555"  "123"  "4567"
```

### gmatch: Iterating Over Matches

```lua
-- Find all words
local s = "hello world lua"
for word in string.gmatch(s, "%a+") do
  print(word)
end
-- "hello"  "world"  "lua"

-- Find all numbers
local numbers = {}
for n in string.gmatch("item1 item2 item3", "%d+") do
  numbers[#numbers + 1] = tonumber(n)
end
```

### gsub: Global Substitution

```lua
-- Simple replacement
print(("hello world"):gsub("world", "Lua"))  -- "hello Lua"  1

-- Pattern replacement with captures
print(("abc 123 def 456"):gsub("(%d+)", "[%1]"))
-- "abc [123] def [456]"  2

-- Function replacement
local rotated = ("abc"):gsub("%a", function(c)
  return string.char((byte(c) - 65 + 1) % 26 + 65)
end)
print(rotated)  -- "bcd"
```

### string.format

```lua
-- Basic formatting
print(string.format("Name: %s, Age: %d", "Lua", 30))
-- "Name: Lua, Age: 30"

-- Floating point
print(string.format("Pi: %.4f", math.pi))  -- "Pi: 3.1416"

-- Hex, octal, binary
print(string.format("%x %X %o", 255, 255, 255))
-- "ff FF 377"

-- Padding
print(string.format("%10s", "right"))   -- "     right"
print(string.format("%-10s", "left"))   -- "left      "
print(string.format("%05d", 42))        -- "00042"
```

### string.find with Plain Search

```lua
-- Plain search (no patterns)
local start, finish = string.find("hello world", "world", 1, true)
print(start, finish)  -- 7  11

-- Pattern search (default)
local start, finish = string.find("hello 123 world", "%d+")
print(start, finish)  -- 7  9
```

---

## table Library Revisited

### table.sort Stability

`table.sort` is **not guaranteed stable**. For stable sorting:

```lua
-- Add original index for stability
local items = {{name="b", score=90}, {name="a", score=90}}
for i, item in ipairs(items) do item._idx = i end

table.sort(items, function(a, b)
  if a.score == b.score then return a._idx < b._idx end
  return a.score > b.score
end)
```

### table.move (5.3+)

```lua
-- Move elements between tables
local src = {1, 2, 3, 4, 5}
local dst = {}
table.move(src, 1, 3, 1, dst)  -- dst = {1, 2, 3}

-- Shift within same table
table.move(src, 1, 3, 2, src)  -- src = {1, 1, 2, 3, 5}
```

### table.pack / table.unpack (5.2+)

```lua
-- Pack varargs
local t = table.pack(1, "two", 3.0)
print(t.n)  -- 3

-- Unpack with range
local values = {10, 20, 30, 40, 50}
print(table.unpack(values, 2, 4))  -- 20  30  40
```

### Building Functional Patterns

```lua
-- map
local function map(t, fn)
  local result = {}
  for i, v in ipairs(t) do result[i] = fn(v) end
  return result
end

-- reduce
local function reduce(t, fn, init)
  local acc = init
  for _, v in ipairs(t) do acc = fn(acc, v) end
  return acc
end

-- Usage
local doubled = map({1, 2, 3}, function(x) return x * 2 end)
-- doubled = {2, 4, 6}

local sum = reduce({1, 2, 3, 4}, function(a, b) return a + b end, 0)
-- sum = 10
```

---

## math Library

### Core Functions

```lua
print(math.abs(-5))        -- 5
print(math.ceil(3.2))      -- 4
print(math.floor(3.7))     -- 3
print(math.max(1, 5, 3))   -- 5
print(math.min(1, 5, 3))   -- 1
print(math.sqrt(16))       -- 4
print(math.log(100, 10))   -- 2 (log base 10)
print(math.exp(1))         -- 2.718...
print(math.pi)             -- 3.14159...
```

### Random Numbers

```lua
-- Seed once at program start
math.randomseed(os.time())

-- Random integer in range [1, 100]
print(math.random(100))

-- Random float in [0, 1)
print(math.random())

-- Random integer in [a, b]
local function rand_int(a, b)
  return math.random(a, b)
end
```

### Integer vs Float (5.3+)

```lua
-- Lua 5.3+ distinguishes integers and floats
print(math.type(42))      -- "integer"
print(math.type(3.14))    -- "float"
print(math.type(42.0))    -- "float" (still float!)

-- Integer division
print(7 // 2)   -- 3 (integer)
print(7 / 2)    -- 3.5 (float)

-- Integer overflow wraps (5.3+)
print(math.maxinteger)    -- 9223372036854775807
print(math.maxinteger + 1) -- -9223372036854775808 (wraps!)
```

---

## utf8 Library (5.3+)

```lua
-- Codepoint count
print(utf8.len("hello"))     -- 5
print(utf8.len("你好世界"))    -- 4

-- Get codepoint at position
print(utf8.codepoint("hello", 1))  -- 104 ('h')

-- Encode codepoint to UTF-8
print(utf8.char(72, 101, 108))  -- "Hel"

-- Offset computation
local s = "hello"
local pos = utf8.offset(s, 3)  -- Byte offset of 3rd codepoint
print(pos)  -- 3

-- Grapheme iteration (manual)
for _, cp in utf8.codes("hello") do
  print(cp)
end
```

---

## io Library

### File Operations

```lua
-- Read entire file
local f = io.open("data.txt", "r")
if f then
  local content = f:read("*a")
  f:close()
end

-- Read line by line
for line in io.lines("data.txt") do
  print(line)
end

-- Write to file
local f = io.open("output.txt", "w")
f:write("hello\n")
f:close()
```

### io.open Modes

| Mode | Description |
|------|-------------|
| `"r"` | Read (default) |
| `"w"` | Write (truncate) |
| `"a"` | Append |
| `"r+"` | Read/write |
| `"rb"` | Read binary |
| `"wb"` | Write binary |

### io.popen (Subprocess)

```lua
-- Run command and capture output
local handle = io.popen("ls -la")
local result = handle:read("*a")
handle:close()
```

> **Sandbox warning**: `io` and `os` give access to the filesystem and system. Remove or restrict them in sandboxed environments.

---

## os Library

### Time

```lua
-- Current time (seconds since epoch)
local now = os.time()
print(now)

-- Date formatting
print(os.date("%Y-%m-%d %H:%M:%S"))  -- "2024-01-15 14:30:00"
print(os.date("!%Y-%m-%dT%H:%M:%SZ"))  -- UTC format

-- Date table
local t = os.date("*t")
print(t.year, t.month, t.day)  -- 2024  1  15

-- Difference in seconds
local start = os.time()
-- ... do work ...
local elapsed = os.difftime(os.time(), start)
```

### Execution

```lua
-- Execute shell command
os.execute("echo hello")

-- Capture exit code
local code = os.execute("exit 42")
print(code)  -- 42
```

---

## Common Pitfalls

### 1. Treating Patterns as PCRE

```lua
-- WRONG: PCRE syntax doesn't work
-- ("hello"):match("\w+")          -- Error
-- ("hello"):match("(?:hello)")    -- Error

-- RIGHT: Lua patterns
("hello"):match("%a+")             -- "hello"
```

### 2. locale-Dependent String Operations

```lua
-- Sorting is locale-dependent
local items = {"c", "a", "B", "b", "A"}
table.sort(items)
-- Result depends on locale! May not be ASCII order

-- For ASCII order, use byte comparison
table.sort(items, function(a, b) return a:byte() < b:byte() end)
```

### 3. Blocking I/O in Logic Layers

```lua
-- BAD: Direct I/O in business logic
function process_order(order)
  local data = io.open("config.txt"):read("*a")  -- Blocks!
  -- ...
end

-- GOOD: Inject I/O dependency
function process_order(order, config)
  -- config already loaded
end
```

### 4. Not Checking io.open Return

```lua
-- BAD: Assumes file exists
local f = io.open("data.txt", "r")
local content = f:read("*a")  -- Crash if f is nil!

-- GOOD: Check return
local f, err = io.open("data.txt", "r")
if not f then
  return nil, "cannot open: " .. err
end
local content = f:read("*a")
f:close()
```

### 5. UTF-8 Byte vs Codepoint

```lua
local s = "你好"
print(#s)           -- 6 (bytes, not characters!)
print(utf8.len(s))  -- 2 (codepoints)
```

---

## Best Practices

### 1. Wrap Platform APIs

```lua
-- Adapter pattern for testability
local clock = {
  now = function() return os.time() end,
  diff = function(a, b) return os.difftime(a, b) end,
}

-- In tests, inject a mock:
-- clock = { now = function() return 1000 end }
```

### 2. Keep Parsing Pure

```lua
-- Pure function: same input → same output, no side effects
local function parse_csv_line(line)
  local fields = {}
  for field in (line .. ","):gmatch("([^,]*),") do
    fields[#fields + 1] = field
  end
  return fields
end
```

### 3. Document Text Encoding

```lua
--- Parse UTF-8 string and return codepoints
-- Assumes input is valid UTF-8
-- @param s string UTF-8 encoded string
-- @return table array of codepoints
local function to_codepoints(s)
  local result = {}
  for _, cp in utf8.codes(s) do
    result[#result + 1] = cp
  end
  return result
end
```

### 4. Prefer `string.format` Over Concatenation

```lua
-- BAD: Multiple concatenations
local msg = "Hello, " .. name .. "! You have " .. count .. " items."

-- GOOD: Format string
local msg = string.format("Hello, %s! You have %d items.", name, count)
```

### 5. Use `table.concat` for Building Strings

```lua
-- BAD: O(n²) concatenation
local result = ""
for i = 1, 10000 do
  result = result .. i
end

-- GOOD: O(n) with table
local parts = {}
for i = 1, 10000 do
  parts[#parts + 1] = tostring(i)
end
local result = table.concat(parts)
```

---

## Version Notes

### Lua 5.1

- No `utf8` library
- `bit32` library for bitwise operations
- `string.gmatch` available
- `table.pack`/`table.unpack` not available

### Lua 5.2/5.3

- `utf8` library added (5.3+)
- `table.pack`/`table.unpack` added
- `math.type` added (5.3+)
- `bit32` removed in 5.3 (replaced by native operators)

### Lua 5.4

- `string.format` supports `%d` for integers
- `utf8.codepoint` range checking improved
- `math.random` uses better algorithm

### LuaJIT

- Standard library is compatible with Lua 5.1
- `ffi` library for C FFI (not part of standard Lua)
- Some string operations are JIT-optimized

---

## Knowledge Check

<details>
<summary>1. What's the difference between <code>string.find</code> and <code>string.match</code>?</summary>

`find` returns the start and end byte positions of the match. `match` returns the captured substrings (or the whole match if no captures).
</details>

<details>
<summary>2. Why is <code>#s</code> unreliable for UTF-8 strings?</summary>

`#s` returns the byte length, not the character count. A UTF-8 character can be 1-4 bytes. Use `utf8.len()` for codepoint count.
</details>

<details>
<summary>3. What does <code>string.gsub</code> return?</summary>

The modified string and the number of substitutions made. `("a-b-c"):gsub("-", "/")` returns `"a/b/c"` and `2`.
</details>

<details>
<summary>4. Why should you check <code>io.open</code> return value?</summary>

`io.open` returns `nil, error_message` on failure (file not found, permissions, etc.). Not checking causes a nil dereference crash.
</details>

<details>
<summary>5. How do you make <code>table.sort</code> stable?</summary>

Add an original index field to each element. In the comparator, when values are equal, compare the original indices to preserve input order.
</details>

---

## Key Takeaways

- **`string`**: patterns are Lua-specific, not PCRE; use `%d`, `%a`, `%s` classes
- **`table`**: `sort` is not stable; use `move` (5.3+) for bulk element transfer
- **`math`**: 5.3+ distinguishes integers and floats; integer overflow wraps
- **`utf8`**: use `utf8.len()` not `#s` for character count
- **`io`/`os`**: restrict in sandboxes; always check `io.open` return
- **`table.concat`** is O(n); string concatenation `..` in loops is O(n²)
- **Wrap platform APIs** for testability and portability

---

## Exercises

### Beginner (30–60 min)

1. **CSV Parser**: Write `parse_csv(line)` that handles quoted fields and escaped commas.

2. **Word Counter**: Use `gmatch` to count word frequencies in a string. Return sorted results.

3. **Template Engine**: Build `render(template, data)` that replaces `{{key}}` placeholders with values from a table.

### Intermediate (1–2 hours)

4. **Pattern Tester**: Create an interactive tool that tests Lua patterns against input strings, showing captures and match positions.

5. **File Watcher**: Use `os.execute` and `io.popen` to build a simple file change detector (poll-based).

6. **Unicode Normalizer**: Write a function that lowercases UTF-8 strings using `utf8.codepoint` and `utf8.char`.

### Advanced (2–4 hours)

7. **Regex Subset**: Implement a small regex compiler that translates a subset of PCRE syntax to Lua patterns, with clear error messages for unsupported features.

8. **Streaming Parser**: Build a CSV/JSON parser that works on chunks of data (streaming I/O) rather than loading entire files.

---

## Example Code

Runnable examples for this chapter:
- `examples/beginner/01-moving-average.lua` — String and math patterns
- `examples/beginner/03-word-frequency.lua` — gmatch-based text processing
- `examples/intermediate/04-stateful-module.lua` — Module with I/O

---

## Further Reading

- [Lua 5.4 Reference Manual — Section 6](https://www.lua.org/manual/5.4/manual.html#6)
- [Programming in Lua (4th ed.) — Chapter 10–12](https://www.lua.org/pil/)
- [Next Chapter: 10 — Lua Internals](10-lua-internals.md)
