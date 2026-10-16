-- Example 27: Ecosystem Dependency Probe
-- Chapter: 16-lua-ecosystem
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Case study for Chapter 16: deciding which third-party library to depend on,
-- and making that decision safe at runtime instead of at install time.
--
-- The pattern: declare the preferred dependency, probe for it at load time,
-- and fall back to a stdlib-only implementation that always works. The
-- fallback here is a real, working JSON encoder -- not a stub -- because a
-- fallback that cannot run is a liability, not a safety net.
--
-- Demonstrates: runtime capability probing, graceful degradation,
-- dependency-selection reporting, and equivalence checks between
-- the fast path and the fallback.

--------------------------------------------------------------------------------
-- Capability probe
--------------------------------------------------------------------------------

local function probe(name)
  local ok, mod = pcall(require, name)
  if ok then
    return { available = true, module = mod }
  end
  return { available = false, reason = tostring(mod) }
end

-- Ordered by preference. Each entry is what a rockspec would declare.
local JSON_CANDIDATES = { "cjson", "dkjson", "json" }

--------------------------------------------------------------------------------
-- Fallback: stdlib-only JSON encoder (always available)
--------------------------------------------------------------------------------

local escapes = {
  ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f',
  ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
}

local function escape_string(s)
  return (s:gsub('[%z\1-\31\\"]', function(c)
    return escapes[c] or string.format("\\u%04x", string.byte(c))
  end))
end

-- Decide whether a table is a JSON array or object.
-- A table is an array when it is empty, or when it has only the keys 1..n.
local function is_array(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n == 0 or (n == #t)
end

local function encode_fallback(value, seen)
  seen = seen or {}
  local tv = type(value)

  if value == nil then
    return "null"
  elseif tv == "boolean" then
    return tostring(value)
  elseif tv == "number" then
    -- JSON has no NaN/Infinity representation
    if value ~= value or value == math.huge or value == -math.huge then
      error("cannot encode non-finite number: " .. tostring(value))
    end
    return tostring(value)
  elseif tv == "string" then
    return '"' .. escape_string(value) .. '"'
  elseif tv == "table" then
    if seen[value] then
      error("cannot encode cyclic table")
    end
    seen[value] = true

    local parts = {}
    if is_array(value) then
      for i = 1, #value do
        parts[#parts + 1] = encode_fallback(value[i], seen)
      end
      seen[value] = nil
      return "[" .. table.concat(parts, ",") .. "]"
    end

    -- Object: sort keys so output is deterministic and diffable
    local keys = {}
    for k in pairs(value) do
      if type(k) ~= "string" and type(k) ~= "number" then
        error("cannot encode key of type " .. type(k))
      end
      keys[#keys + 1] = tostring(k)
    end
    table.sort(keys)
    for i = 1, #keys do
      local k = keys[i]
      -- Numeric keys were stringified for sorting; read back as-is from the table
      local raw = value[tonumber(k) or k]
      parts[#parts + 1] = '"' .. escape_string(k) .. '":' .. encode_fallback(raw, seen)
    end
    seen[value] = nil
    return "{" .. table.concat(parts, ",") .. "}"
  end

  error("cannot encode value of type " .. tv)
end

--------------------------------------------------------------------------------
-- Selection: pick the fastest available, fall back without failing
--------------------------------------------------------------------------------

local function select_encoder(candidates)
  local report = {}

  for i = 1, #candidates do
    local name = candidates[i]
    local result = probe(name)
    report[#report + 1] = {
      name = name,
      available = result.available,
      note = result.available and "found" or "not installed",
    }
    if result.available and type(result.module.encode) == "function" then
      return {
        name = name,
        encode = function(v) return result.module.encode(v) end,
        report = report,
      }
    end
  end

  -- Nothing found: use the fallback that ships with this file
  report[#report + 1] = {
    name = "built-in fallback",
    available = true,
    note = "stdlib only, always present",
  }
  return {
    name = "built-in fallback",
    encode = function(v) return encode_fallback(v) end,
    report = report,
  }
end

local encoder = select_encoder(JSON_CANDIDATES)

--------------------------------------------------------------------------------
-- Report the decision
--------------------------------------------------------------------------------

print("Dependency probe")
print("----------------")
for i = 1, #encoder.report do
  local entry = encoder.report[i]
  print(string.format("  %-20s %-14s %s",
    entry.name,
    entry.available and "[available]" or "[missing]",
    entry.note))
end
print(string.format("\nSelected encoder: %s", encoder.name))
print()

--------------------------------------------------------------------------------
-- The decision must not change the output
--------------------------------------------------------------------------------

local document = {
  service = "billing",
  version = 3,
  enabled = true,
  replicas = 2,
  tags = { "production", "eu-west" },
  limits = { cpu = 0.5, memory_mb = 512 },
  notes = "line1\nline2\ttabbed \"quoted\" \\backslash",
  empty_list = {},
}

local encoded = encoder.encode(document)
local fallback_encoded = encode_fallback(document)
print("Encoded document")
print("----------------")
print(encoded)
print()

-- Compare the selected encoder against the shipped fallback. Key order and
-- float formatting may legitimately differ between JSON libraries, so a
-- byte difference is reported rather than treated as a failure.
if encoder.name ~= "built-in fallback" then
  local byte_identical = (encoded == fallback_encoded)
  print(string.format("Selected encoder (%s) vs fallback byte-identical: %s",
    encoder.name, tostring(byte_identical)))
  if not byte_identical then
    print("  fallback output:")
    print("  " .. fallback_encoded)
  end
  print()
end

local function check_wellformed(s)
  local depth, in_string, escaped = 0, false, false
  for i = 1, #s do
    local c = s:sub(i, i)
    if in_string then
      if escaped then
        escaped = false
      elseif c == "\\" then
        escaped = true
      elseif c == '"' then
        in_string = false
      end
    elseif c == '"' then
      in_string = true
    elseif c == "{" or c == "[" then
      depth = depth + 1
    elseif c == "}" or c == "]" then
      depth = depth - 1
      if depth < 0 then return false end
    end
  end
  return depth == 0 and not in_string
end

local wellformed = check_wellformed(encoded)
print(string.format("Structural check: %s", wellformed and "balanced" or "MALFORMED"))

-- Content guarantees are checked on every available path, including the
-- fallback, so the fallback cannot silently rot.
local checks = {
  { "service name preserved", '"service":"billing"' },
  { "array preserved",        '"tags":["production","eu-west"]' },
  { "newline escaped",        'line1\\nline2' },
  { "quote escaped",          '\\"quoted\\"' },
  { "backslash escaped",      '\\\\backslash' },
  { "empty array preserved",  '"empty_list":[]' },
}

print()
print("Content checks")
print("--------------")
local failed = 0

local function run_checks(label, output)
  for i = 1, #checks do
    local name, needle = checks[i][1], checks[i][2]
    local ok = output:find(needle, 1, true) ~= nil
    print(string.format("  [%s] %s %s", label, ok and "ok  " or "FAIL", name))
    if not ok then failed = failed + 1 end
  end
end

run_checks(encoder.name, encoded)
if encoder.name ~= "built-in fallback" then
  run_checks("fallback", fallback_encoded)
end

-- Cyclic input must be rejected, not silently truncated
local cyclic = {}
cyclic.self = cyclic
local ok_cyclic = pcall(encode_fallback, cyclic)
print(string.format("\nCyclic input rejected: %s", tostring(not ok_cyclic)))
if ok_cyclic then failed = failed + 1 end

if not wellformed or failed > 0 then
  print("\nCASE STUDY FAILED")
  os.exit(1)
end

print("\nCASE STUDY OK")
