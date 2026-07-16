# Beginner Exercises

Exercises covering roadmap stages 1–8 (Core Language Literacy through Template Engines).

---

## 1. Concept Reinforcement

### 1.1 — Table Construction and Array Traversal (Stage 1) [Easy]
Implement `range(n)` returning `{1, 2, ..., n}`, then `sum(t)` returning the sum of all numeric values (skip non-numeric).
```lua
print(sum(range(5)))              --> 15
print(sum({1, "a", 3, nil, 5}))  --> 9
```
**Hint**: Use `ipairs` for range; guard with `type()` in sum.

### 1.2 — Functions and Closures (Stage 1) [Easy]
Write `make_adder(n)` returning a function that adds `n`. Chain two adders:
```lua
local add5 = make_adder(5)
local add3 = make_adder(3)
print(add5(add3(10)))  --> 18
```

### 1.3 — FizzBuzz Variant (Stage 1) [Easy]
Write `fizzbuzz(n)` returning a table of strings. Multiples of 3 → `"Fizz"`, 5 → `"Buzz"`, both → `"FizzBuzz"`, else the number as string.

### 1.4 — String Patterns: Extract Email Fields (Stage 1) [Medium]
Write `parse_name(email)` returning username and domain via `string.match`.
```lua
local user, domain = parse_name("alice@example.com")
print(user, domain)  --> alice   example.com
```
**Hint**: Use pattern `^(.+)@(.+)$`.

### 1.5 — String Patterns: CSV Parser (Stage 1) [Medium]
Write `parse_csv(line)` splitting comma-separated fields, handling quoted fields with commas inside.
```lua
local fields = parse_csv('name,age,"city, state"')
-- fields = {"name", "age", "city, state"}
```
**Hint**: Use `string.find` with `([^,]+)` and `"[^"]*"`.

### 1.6 — Word Frequency Counter (Stage 1) [Medium]
Write `word_freq(text)` returning a table of word → count (case-insensitive).
```lua
local f = word_freq("the cat and the dog")
-- f["the"] = 2, f["cat"] = 1, f["and"] = 1, f["dog"] = 1
```
**Hint**: `string.gmatch` for words; `string.lower` for normalization.

### 1.7 — Metatables: Delegation (Stage 2) [Medium]
Create `parent = {name = "default"}` and `child = setmetatable({}, {__index = parent})`. Verify `child.name` returns `"default"`, then set `child.name = "override"` and confirm parent is unchanged.

### 1.8 — Metatables: Custom `__add` (Stage 2) [Medium]
Create `Vec2.new(x, y)` with `__add` (element-wise) and `__tostring`.
```lua
print(Vec2.new(1,2) + Vec2.new(3,4))  --> Vec2(4, 6)
```

### 1.9 — Module Pattern (Stage 2) [Medium]
Write a `mathutils` module file exposing `clamp(val, lo, hi)` and `lerp(a, b, t)` using local internals and a public table return.

### 1.10 — Coroutines: Producer-Consumer (Stage 3) [Medium]
Create a coroutine yielding numbers 1–5. Resume it in a loop, collecting values into a table. Expected: `{1, 2, 3, 4, 5}`.

### 1.11 — Error Handling: Protected Parse (Stage 2) [Medium]
Write `safe_parse(s)` calling `tonumber` inside `pcall`. Return `(number, nil)` or `(nil, error_msg)`.
```lua
print(safe_parse("42"))  --> 42    nil
print(safe_parse("abc")) --> nil   "not a valid number"
```

---

## 2. Mini Projects

### 2.1 — Simple JSON Parser (Stage 6) [Medium–Hard]
Build a recursive descent JSON parser. Support strings, numbers, booleans, null, arrays, nested objects.
- Implement a tokenizer identifying `{}`, `[]`, `,`, `:`, strings, numbers, `true`/`false`/`null`
- Write recursive descent functions per grammar rule
- Return Lua tables for objects and arrays; map JSON null to a sentinel

```lua
local data = parse_json('{"name":"Alice","scores":[95,87],"active":true}')
print(data.name)       --> Alice
print(data.scores[1])  --> 95
```

**Hints**: Use `string.find` with patterns `^%s*"` and `^%s*[%d%-]` to identify next token. Track a position index. Handle escape sequences in strings.

### 2.2 — Config File Reader (Stage 7) [Medium]
Parse INI-style files with sections, key-value pairs, comments (`#`/`;`), and `${VAR}` env expansion.
```lua
-- config.ini: [database] host = localhost\nport = 5432\nname = ${DB_NAME}
local config = load_config("config.ini")
print(config.database.host)          --> localhost
print(config.get("database.host"))   --> localhost (dot-path)
print(config.get("missing", 42))     --> 42 (default)
```

**Hints**: `io.lines(path)` for reading; `string.match(line, "^%[(.+)%]")` for sections; `string.gsub(value, "%${([^}]+)}", os.getenv)` for env vars.

### 2.3 — Template Engine (Stage 8) [Medium–Hard]
Build a template engine with `{{var}}` interpolation, `{% if condition %}...{% end %}`, and `{% for k,v in list %}...{% end %}`.
```lua
local tmpl = "Hello {{name}}!{% if items %}\nItems:{% for _,i in ipairs(items) %}\n- {{i}}{% end %}{% end %}"
print(render(tmpl, {name="Alice", items={"a","b"}}))
-- Hello Alice!
-- Items:
-- - a
-- - b
```

**Hint**: Process conditionals/loops first, then interpolate variables. Resolve dot paths by splitting on `.`.

### 2.4 — Task Tracker CLI (Stage 1–2) [Medium]
Commands: `add <title>`, `list`, `remove <id>`, `done <id>`. Store as JSON in `tasks.json`. Separate modules: `parser.lua`, `store.lua`, `cli.lua`.

---

## 3. Debugging Tasks

### 3.1 — Global Variable Leak [Easy]
```lua
function create_user(name)
  user = { name = name, active = true }
  return user
end
local u1 = create_user("Alice")
local u2 = create_user("Bob")
print(u1.name)  --> "Bob" — WRONG
```
**Fix**: Why does this happen? Add `local` and test again.

### 3.2 — Table Length on Sparse Arrays [Easy]
```lua
local t = {1, nil, 3}
print(#t)  -- Unreliable
```
**Task**: Write `safe_length(t)` counting non-nil integer keys. Test on `{1, nil, 3}` and `{nil, 2, nil, 4}`.

### 3.3 — Dead Coroutine Resume [Medium]
```lua
local co = coroutine.create(function()
  coroutine.yield("first"); coroutine.yield("second")
end)
coroutine.resume(co)  --> true, "first"
coroutine.resume(co)  --> true, "second"
coroutine.resume(co)  --> ERROR: cannot resume dead coroutine
```
**Fix**: Write `safe_resume(co, ...)` returning `nil, "dead coroutine"` instead of crashing.

### 3.4 — Metatable Shared State [Medium]
```lua
local User = {}; User.__index = User
function User.new(name) return setmetatable({name=name}, User) end
local u1, u2 = User.new("Alice"), User.new("Bob")
u1.scores = {100}
print(#u2.scores)  --> 1 — should be 0
```
**Task**: Explain the behavior. If it's a bug, fix it. If not, document why `__index` doesn't cause shared mutable state here.

### 3.5 — Mutation During Iteration [Medium]
```lua
local t = {a=1, b=2, c=3}
for k,v in pairs(t) do
  if v == 2 then t[k] = nil end
end
```
**Fix**: Collect keys to remove first, then delete after the loop.

### 3.6 — Closure Captures Loop Variable [Easy]
```lua
local funcs = {}
for i = 1, 5 do funcs[i] = function() return i end end
print(funcs[1]())  --> 5 — WRONG
```
**Fix**: Make each function capture its own copy of `i`. Explain why the bug occurs.

---

## 4. Open-Ended Design Questions

1. **Nullable fields**: Compare `nil`, a sentinel (`cjson.null`), and a wrapper `{value=x, is_null=true}` for nullable table fields. Trade-offs for serialization and iteration?

2. **Module API style**: Returning a table of functions vs a metatable class vs exporting to `_G` — which is easiest to test and why?

3. **Error handling boundaries**: In small scripts, should each function validate inputs or should a top-level `pcall` catch everything? What changes at scale?

4. **JSON null vs Lua nil**: Why does Lua's `nil` break JSON roundtrips? Design a scheme preserving JSON null through parse → transform → serialize.

5. **Template approaches**: Pattern-based string processing vs two-phase (parse to AST, then evaluate). When does the simple approach break down?

6. **Coroutine vs callback**: When do coroutines simplify an event-driven system vs callbacks? Give one scenario for each.
